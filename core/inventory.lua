local constants = require("core.constants")
local validation = require("core.validation")

local M = {}

local function build_inventories(target, inventory_defines)
  if not inventory_defines then
    return {}
  end
  
  local out = {}
  for _, inventory_type in pairs(inventory_defines) do
    table.insert(out, target.get_inventory(inventory_type))
  end
  return out
end

function M.get_transfer_inventories(target)
  if target.object_name == "LuaEntity" then
    return build_inventories(target, constants.entity_transfer_inventories[target.type])
  elseif target.object_name == "LuaInventory" then
    return { target }
  elseif target.object_name == "LuaPlayer" then
    return build_inventories(target, constants.player_transfer_inventories[target.controller_type])
  else
    error("Invalid transfer target type " .. target.object_name)
  end
end

function M.inventory_iterator(target)
  local inventories = M.get_transfer_inventories(target)
  local i = 0
  return function()
    i = i + 1
    return inventories[i]
  end
end

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

function M.get_player_item_count(inventory, cursor_stack, item)
  local count = inventory.get_item_count(item)
  if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == item.name and cursor_stack.quality.name == item.quality then
    count = count + cursor_stack.count
  end
  return count
end

function M.transfer(from, to, spec)
  if spec.count < 0 then
    spec.count = math.abs(spec.count)
    local temp = from
    from = to
    to = temp
  elseif spec.count == 0 then
    return 0
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

    if source_stack and not from_cursor_stack_exhausted then
      if not source_stack.valid_for_read or (source_stack.name ~= spec.name or source_stack.quality.name ~= spec.quality) then
        from_cursor_stack_exhausted = true
        goto continue
      end
    end

    if not source_stack then
      from_inventory = from_inventories()
      goto continue
    end

    local to_transfer = math.min(source_stack.count, spec.count - transferred)

    if to_cursor_stack and not to_cursor_stack_exhausted then
      if to_cursor_stack.valid_for_read then
        if to_cursor_stack.type == source_stack.type 
           and to_cursor_stack.name == source_stack.name 
           and to_cursor_stack.quality.name == source_stack.quality.name 
           and to_cursor_stack.count < to_cursor_stack.prototype.stack_size then
          
          local count_before = to_cursor_stack.count
          to_cursor_stack.transfer_stack(source_stack, to_transfer)
          transferred = transferred + to_cursor_stack.count - count_before
          
          if not source_stack.valid_for_read then
            goto continue
          end
        end
      elseif to_cursor_stack.transfer_stack(source_stack, to_transfer) then
        transferred = transferred + to_cursor_stack.count
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
      if empty_slot then
        empty_slot.transfer_stack(source_stack)
        transferred = transferred + empty_slot.count
      else
        to_inventory = to_inventories()
        goto continue
      end
    else
      local this_spec = {
        name = source_stack.name,
        quality = source_stack.quality.name,
        count = to_transfer,
        health = source_stack.health,
        durability = source_stack.type == "tool" and source_stack.durability or nil,
        ammo = source_stack.type == "ammo" and source_stack.ammo or nil,
        tags = source_stack.type == "item-with-tags" and source_stack.tags or nil,
        custom_description = source_stack.type == "item-with-tags" and source_stack.custom_description or nil,
        spoil_percent = source_stack.spoil_percent,
      }
      
      if this_spec.ammo and this_spec.ammo < 1 then
        this_spec.ammo = 1
      end
      
      local this_transferred = to_inventory.insert(this_spec)
      if this_transferred > 0 then
        source_stack.count = source_stack.count - this_transferred
        transferred = transferred + this_transferred
      else
        to_inventory = to_inventories()
        goto continue
      end
    end

    if source_stack == from_cursor_stack and not source_stack.valid_for_read then
      from_cursor_stack_exhausted = true
    end

    ::continue::
  end
  return transferred
end

return M