-- features/auto-fill/fill-logic.lua
-- Main logic for filling fuel and ammo into entities

local constants = require("features.auto-fill.constants")
local entity_detection = require("features.auto-fill.entity-detection")
local item_priority = require("features.auto-fill.item-priority")
local fill_logic = {}

-- Calculate how many items to insert based on max percent
-- For fuel slots, this calculates items per slot (based on stack size)
-- For ammo slots, this calculates number of slots to fill
function fill_logic.calculate_insert_count(inventory, max_percent, item_prototype, is_fuel)
  if not inventory or not inventory.valid then
    return 0
  end
  
  local inventory_size = #inventory
  
  -- Try to get bar size if it exists (some inventories have a bar that limits usable slots)
  local success, bar_size = pcall(function() return inventory.get_bar() end)
  if success and bar_size and bar_size > 0 then
    inventory_size = math.min(bar_size, inventory_size)
  end
  
  -- For fuel: always calculate based on stack size percentage (even if multiple slots)
  if is_fuel and item_prototype and item_prototype.stack_size then
    local stack_size = item_prototype.stack_size
    local insert_count = math.ceil(stack_size * max_percent / 100)
    return math.max(insert_count, 1)
  end
  
  -- For ammo: calculate number of slots to fill
  if not is_fuel then
    local slots_to_fill = math.ceil(inventory_size * max_percent / 100)
    slots_to_fill = math.max(slots_to_fill, 1)
    -- For ammo, we typically want to fill each slot with a stack
    if item_prototype and item_prototype.stack_size then
      return slots_to_fill * item_prototype.stack_size
    end
    return slots_to_fill
  end
  
  -- Fallback: just return 1
  return 1
end

-- Fill fuel into entity
function fill_logic.fill_fuel(entity, player, max_percent, blacklist)
  if not entity_detection.needs_fuel(entity) then
    return false
  end
  
  local fuel_inventory = entity_detection.get_fuel_inventory(entity)
  if not fuel_inventory or not fuel_inventory.valid then
    return false
  end
  
  local best_fuel = item_priority.get_best_fuel(player, blacklist)
  if not best_fuel then
    return false
  end
  
  -- Get item prototype from player inventory for stack size calculation
  local main_inventory = player.get_main_inventory()
  local item_prototype = nil
  if main_inventory then
    -- Find the item in inventory to get its prototype
    for i = 1, #main_inventory do
      local stack = main_inventory[i]
      if stack and stack.valid_for_read and stack.name == best_fuel.name then
        item_prototype = stack.prototype
        break
      end
    end
  end
  
  local insert_count = fill_logic.calculate_insert_count(fuel_inventory, max_percent, item_prototype, true)
  insert_count = math.min(insert_count, best_fuel.count)
  
  if insert_count <= 0 then
    return false
  end
  
  -- Try to insert fuel
  local insert_spec = { name = best_fuel.name, count = insert_count }
  if best_fuel.quality and best_fuel.quality ~= "normal" then
    insert_spec.quality = best_fuel.quality
  end
  local inserted = fuel_inventory.insert(insert_spec)
  
  if inserted > 0 then
    -- Remove from player inventory
    local main_inventory = player.get_main_inventory()
    if main_inventory then
      local remove_spec = { name = best_fuel.name, count = inserted }
      if best_fuel.quality and best_fuel.quality ~= "normal" then
        remove_spec.quality = best_fuel.quality
      end
      main_inventory.remove(remove_spec)
    end
    return true
  end
  
  return false
end

-- Fill ammo into entity
function fill_logic.fill_ammo(entity, player, max_percent, blacklist)
  if not entity_detection.needs_ammo(entity) then
    return false
  end
  
  local ammo_inventory = entity_detection.get_ammo_inventory(entity)
  if not ammo_inventory or not ammo_inventory.valid then
    return false
  end
  
  local best_ammo = item_priority.get_best_ammo(player, entity, blacklist)
  if not best_ammo then
    return false
  end
  
  -- Get item prototype from player inventory for stack size calculation
  local main_inventory = player.get_main_inventory()
  local item_prototype = nil
  if main_inventory then
    -- Find the item in inventory to get its prototype
    for i = 1, #main_inventory do
      local stack = main_inventory[i]
      if stack and stack.valid_for_read and stack.name == best_ammo.name then
        item_prototype = stack.prototype
        break
      end
    end
  end
  
  if not item_prototype then
    return false
  end
  
  -- Calculate how many slots to fill
  local inventory_size = #ammo_inventory
  local success, bar_size = pcall(function() return ammo_inventory.get_bar() end)
  if success and bar_size and bar_size > 0 then
    inventory_size = math.min(bar_size, inventory_size)
  end
  
  local slots_to_fill = math.ceil(inventory_size * max_percent / 100)
  slots_to_fill = math.max(slots_to_fill, 1)
  
  local stack_size = item_prototype.stack_size or 1
  local total_inserted = 0
  local remaining_to_fill = math.min(slots_to_fill * stack_size, best_ammo.count)
  
  -- Insert ammo stack by stack until we've filled enough slots
  for slot = 1, slots_to_fill do
    if remaining_to_fill <= 0 then
      break
    end
    
    local to_insert = math.min(stack_size, remaining_to_fill)
    local insert_spec = { name = best_ammo.name, count = to_insert }
    if best_ammo.quality and best_ammo.quality ~= "normal" then
      insert_spec.quality = best_ammo.quality
    end
    
    local inserted = ammo_inventory.insert(insert_spec)
    if inserted > 0 then
      total_inserted = total_inserted + inserted
      remaining_to_fill = remaining_to_fill - inserted
      
      -- Remove from player inventory
      local main_inventory = player.get_main_inventory()
      if main_inventory then
        local remove_spec = { name = best_ammo.name, count = inserted }
        if best_ammo.quality and best_ammo.quality ~= "normal" then
          remove_spec.quality = best_ammo.quality
        end
        main_inventory.remove(remove_spec)
      end
    else
      -- Can't insert more, inventory might be full
      break
    end
  end
  
  return total_inserted > 0
end

-- Fill both fuel and ammo into entity
function fill_logic.fill_entity(entity, player, max_percent, blacklist, fuel_only, ammo_only)
  if not entity_detection.validate(entity, player) then
    return false
  end
  
  -- Check if entity is blacklisted
  if entity_detection.is_blacklisted(entity, blacklist) then
    return false
  end
  
  local filled = false
  
  -- Fill fuel if not ammo-only
  if not ammo_only then
    if fill_logic.fill_fuel(entity, player, max_percent, blacklist) then
      filled = true
    end
  end
  
  -- Fill ammo if not fuel-only
  if not fuel_only then
    if fill_logic.fill_ammo(entity, player, max_percent, blacklist) then
      filled = true
    end
  end
  
  return filled
end

return fill_logic

