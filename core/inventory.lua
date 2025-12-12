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

  local from_cursor_stack, to_cursor_stack
  local from_cursor_stack_exhausted, to_cursor_stack_exhausted
  if from.object_name == "LuaPlayer" then
    from_cursor_stack = from.cursor_stack
  end
  if to.object_name == "LuaPlayer" then
    to_cursor_stack = to.cursor_stack
  end

  local transferred = 0
  local id = { name = spec.name, quality = spec.quality }

  local from_inventory = from_inventories()
  local to_inventory = to_inventories()
  while from_inventory and to_inventory and transferred < spec.count do
    local source_stack
    if from_cursor_stack and not from_cursor_stack_exhausted then
      source_stack = from_cursor_stack
    else
      source_stack = from_inventory.find_item_stack(id)
    end

    if
      source_stack
      and not from_cursor_stack_exhausted
      and (
        not source_stack.valid_for_read or (source_stack.name ~= spec.name or source_stack.quality.name ~= spec.quality)
      )
    then
      from_cursor_stack_exhausted = true
      goto continue
    end

    if not source_stack then
      from_inventory = from_inventories()
      goto continue
    end

    if to_cursor_stack and not to_cursor_stack_exhausted then
      if not to_cursor_stack.valid_for_read then
        to_cursor_stack.transfer_stack(source_stack)
        to_cursor_stack_exhausted = true
        if source_stack == from_cursor_stack and not source_stack.valid_for_read then
          from_cursor_stack_exhausted = true
        end
        goto continue
      end
    end

    if not to_inventory.can_insert(id) then
      to_inventory = to_inventories()
      goto continue
    end

    if constants.complex_items[source_stack.type] then
      local empty_slot = to_inventory.find_empty_stack(id)
      if not empty_slot then
        to_inventory = to_inventories()
        goto continue
      end
      assert(empty_slot.transfer_stack(source_stack), "Transfer of full stack failed")
      transferred = transferred + empty_slot.count
    else
      --- @type SimpleItemStack
      local this_spec = {
        name = source_stack.name,
        quality = source_stack.quality.name,
        count = math.min(source_stack.count, spec.count - transferred),
        health = source_stack.health,
        durability = source_stack.type == "tool" and source_stack.durability or nil,
        ammo = source_stack.type == "ammo" and source_stack.ammo or nil,
        tags = source_stack.type == "item-with-tags" and source_stack.tags or nil,
        custom_description = source_stack.type == "item-with-tags" and source_stack.custom_description or nil,
        spoil_percent = source_stack.spoil_percent,
      }
      local this_transferred = to_inventory.insert(this_spec)
      source_stack.count = source_stack.count - this_transferred
      transferred = transferred + this_transferred
    end

    if source_stack == from_cursor_stack and not source_stack.valid_for_read then
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
