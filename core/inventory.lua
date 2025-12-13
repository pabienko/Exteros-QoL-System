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

  local transferred = 0
  local id = { name = spec.name, quality = spec.quality }
  
  -- Iterate through all available inventories on the Target (e.g. Fuel -> Input)
  local to_iter = M.inventory_iterator(to)
  local to_inventory = to_iter()
  while to_inventory do
    if transferred >= spec.count then break end
    if to_inventory.valid then
      
      -- Attempt to fill this specific inventory
      while transferred < spec.count do
        -- Optimization: Quick check if this inventory accepts the item
        if not to_inventory.can_insert(id) then break end

        -- 1. Locate Source Stack (Priority: Cursor > Inventory)
        local source_stack
        
        -- Check Player Cursor
        if from.object_name == "LuaPlayer" and from.cursor_stack 
           and from.cursor_stack.valid_for_read 
           and from.cursor_stack.name == spec.name 
           and from.cursor_stack.quality.name == spec.quality then
            source_stack = from.cursor_stack
        else
            -- Check Inventories
            local from_iter = M.inventory_iterator(from)
            local from_inv = from_iter()
            while from_inv do
              if from_inv.valid then
                 local found = from_inv.find_item_stack(id)
                 if found then
                    source_stack = found
                    break
                 end
              end
              from_inv = from_iter()
            end
        end

        -- If source is empty, we are done
        if not source_stack then return transferred end

        -- 2. Calculate Amount
        local limit = spec.count - transferred
        local available = source_stack.count
        local to_move = available < limit and available or limit

        -- 3. Execute Insert
        local insert_spec = {
          name = source_stack.name,
          quality = source_stack.quality.name,
          count = to_move,
          health = source_stack.health,
          durability = source_stack.type == "tool" and source_stack.durability or nil,
          ammo = source_stack.type == "ammo" and source_stack.ammo or nil,
          tags = source_stack.type == "item-with-tags" and source_stack.tags or nil,
          custom_description = source_stack.type == "item-with-tags" and source_stack.custom_description or nil,
          spoil_percent = source_stack.spoil_percent,
        }

        local actually_transferred = 0
        if constants.complex_items[source_stack.type] then
           if to_inventory.insert(insert_spec) > 0 then
              actually_transferred = to_move
           end
        else
           actually_transferred = to_inventory.insert(insert_spec)
        end

        -- 4. Handle Result
        if actually_transferred > 0 then
           source_stack.count = source_stack.count - actually_transferred
           transferred = transferred + actually_transferred
        else
           -- This specific inventory is full or refused the item. 
           -- BREAK inner loop to try the next inventory (e.g. switch from Fuel to Input).
           break 
        end
      end
    end
    to_inventory = to_iter()
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
