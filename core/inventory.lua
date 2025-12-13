--[[
  CORE/INVENTORY.LUA - Inventory Utilities
  
  Common functions for working with inventories, transfers, and items.
  Extracted from even-distribution for reuse across features.
]]

local constants = require("core.constants")
local validation = require("core.validation")

local M = {}

--- @alias TransferTarget LuaPlayer|LuaEntity

--- Get transfer inventories for a target (entity or player)
--- @param target TransferTarget
--- @return defines.inventory[]?
function M.get_transfer_inventories(target)
  if target.object_name == "LuaEntity" then
    return constants.entity_transfer_inventories[target.type]
  elseif target.object_name == "LuaPlayer" then
    return constants.player_transfer_inventories[target.controller_type]
  else
    error("Invalid transfer target type " .. target.object_name)
  end
end

--- Create an iterator for inventories of a target
--- @param target TransferTarget
--- @return fun(): LuaInventory?
function M.inventory_iterator(target)
  local inventories = M.get_transfer_inventories(target) or {}
  local i = 0
  return function()
    i = i + 1
    local inventory_type = inventories[i]
    if not inventory_type then
      return nil
    end
    return target.get_inventory(inventory_type)
  end
end

--- Transfer items between two targets
--- @param from TransferTarget
--- @param to TransferTarget
--- @param spec ItemStackDefinition
--- @return uint transferred
function M.transfer(from, to, spec)
  if spec.count < 0 then
    spec.count = math.abs(spec.count)
    local temp = from
    from = to
    to = temp
  end

  local from_inventories = M.inventory_iterator(from)
  local to_inventories = M.inventory_iterator(to)

  local from_cursor_stack
  local from_cursor_stack_exhausted = false
  if from.object_name == "LuaPlayer" then
    from_cursor_stack = from.cursor_stack
  end
  
  -- Pre-fetch target cursor stack logic (keep existing logic for simplicity or improve)
  local to_cursor_stack
  if to.object_name == "LuaPlayer" then
    to_cursor_stack = to.cursor_stack
  end

  local transferred = 0
  local id = { name = spec.name, quality = spec.quality }

  local from_inventory = from_inventories()
  local to_inventory = to_inventories()

  while (from_inventory or (from_cursor_stack and not from_cursor_stack_exhausted)) and to_inventory and transferred < spec.count do
    -- 1. Identify Source Stack
    local source_stack
    local is_cursor_source = false

    if from_cursor_stack and not from_cursor_stack_exhausted then
      source_stack = from_cursor_stack
      is_cursor_source = true
      
      -- Validate cursor content matches request
      if not source_stack.valid_for_read or source_stack.name ~= id.name or source_stack.quality.name ~= id.quality then
        from_cursor_stack_exhausted = true
        goto continue
      end
    elseif from_inventory then
      source_stack = from_inventory.find_item_stack(id)
    end

    -- 2. Validate Source Stack Availability
    if not source_stack or not source_stack.valid_for_read then
      if is_cursor_source then
         from_cursor_stack_exhausted = true
      elseif from_inventory then
         -- Current inventory exhausted, move to next
         from_inventory = from_inventories()
      end
      goto continue
    end

    -- 3. Handle Target Cursor (Player Destination)
    -- If target is player cursor and valid/empty, try to put there first
    if to_cursor_stack and to_cursor_stack.valid and not to_cursor_stack.valid_for_read then
      if to_cursor_stack.transfer_stack(source_stack) then
        -- transfer_stack returns boolean, update tracking based on result
        if to_cursor_stack.valid_for_read then
          local cursor_count = to_cursor_stack.count
          local max_transfer = spec.count - transferred
          local actual_transferred = math.min(cursor_count, max_transfer)
          transferred = transferred + actual_transferred
          
          -- If cursor source was exhausted, mark it
          if is_cursor_source and not source_stack.valid_for_read then
            from_cursor_stack_exhausted = true
          end
          goto continue
        end
      end
    end

    -- 4. Target Inventory Validation
    if not to_inventory.can_insert(id) then
      to_inventory = to_inventories()
      goto continue
    end

    -- 5. Execute Transfer
    local count_to_transfer = math.min(source_stack.count, spec.count - transferred)
    local actual_transferred = 0

    if constants.complex_items[source_stack.type] then
      local empty_slot = to_inventory.find_empty_stack(id)
      if not empty_slot then
        to_inventory = to_inventories()
        goto continue
      end
      if empty_slot.transfer_stack(source_stack) then
         -- For complex items, transfer_stack usually transfers 1 item
         -- Check the slot count after transfer to get accurate count
         actual_transferred = empty_slot.count
         transferred = transferred + actual_transferred
         
         -- If cursor source was exhausted, mark it
         if is_cursor_source and not source_stack.valid_for_read then
           from_cursor_stack_exhausted = true
         end
      end
    else
      local insert_spec = {
        name = source_stack.name,
        quality = source_stack.quality.name,
        count = count_to_transfer,
        health = source_stack.health,
        durability = source_stack.type == "tool" and source_stack.durability or nil,
        ammo = source_stack.type == "ammo" and source_stack.ammo or nil,
        tags = source_stack.type == "item-with-tags" and source_stack.tags or nil,
        custom_description = source_stack.type == "item-with-tags" and source_stack.custom_description or nil,
        spoil_percent = source_stack.spoil_percent,
      }
      
      actual_transferred = to_inventory.insert(insert_spec)
      
      if actual_transferred > 0 then
        source_stack.count = source_stack.count - actual_transferred
        transferred = transferred + actual_transferred
        
        -- If cursor source was exhausted, mark it
        if is_cursor_source and not source_stack.valid_for_read then
          from_cursor_stack_exhausted = true
        end
      else
        -- Inventory said can_insert=true but inserted 0 (Full or Limited).
        -- Move to next inventory to prevent infinite loop.
        to_inventory = to_inventories()
      end
    end

    -- 6. Post-Transfer Cleanup
    if is_cursor_source and (not source_stack.valid_for_read) then
      from_cursor_stack_exhausted = true
    end

    ::continue::
  end

  return transferred
end

--- Get item count from an entity across all transfer inventories
--- @param entity LuaEntity
--- @param item ItemIDAndQualityIDPair
--- @return uint
function M.get_entity_item_count(entity, item)
  local total = 0
  local inventories = constants.entity_transfer_inventories[entity.type]
  if not inventories then
    return 0
  end
  for _, inventory_type in pairs(inventories) do
    local inventory = entity.get_inventory(inventory_type)
    if inventory then
      total = total + inventory.get_item_count(item)
    end
  end
  return total
end

--- Get item count from an inventory including cursor stack
--- @param inventory LuaInventory
--- @param cursor_stack LuaItemStack
--- @param item ItemIDAndQualityIDPair
--- @return uint
function M.get_item_count(inventory, cursor_stack, item)
  local count = inventory.get_item_count(item)
  if cursor_stack.valid_for_read and cursor_stack.name == item.name and cursor_stack.quality.name == item.quality then
    count = count + cursor_stack.count
  end
  return count
end

return M
