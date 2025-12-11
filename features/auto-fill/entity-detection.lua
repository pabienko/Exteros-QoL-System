-- features/auto-fill/entity-detection.lua
-- Entity detection and validation

local constants = require("features.auto-fill.constants")
local blacklist_parser = require("features.auto-fill.blacklist-parser")
local entity_detection = {}

-- Check if entity needs fuel
function entity_detection.needs_fuel(entity)
  if not entity or not entity.valid then
    return false
  end
  
  local entity_type = entity.type
  
  -- Check predefined list first
  if constants.fuel_entities[entity_type] then
    return true
  end
  
  -- Dynamic check: try to get fuel inventory for any entity
  -- This catches Space Age entities and modded entities
  local fuel_inventory = entity.get_inventory(defines.inventory.fuel)
  if fuel_inventory and fuel_inventory.valid then
    return true
  end
  
  return false
end

-- Check if entity needs ammo
function entity_detection.needs_ammo(entity)
  if not entity or not entity.valid then
    return false
  end
  
  local entity_type = entity.type
  return constants.ammo_entities[entity_type] ~= nil
end

-- Get fuel inventory for entity
function entity_detection.get_fuel_inventory(entity)
  if not entity or not entity.valid then
    return nil
  end
  
  local entity_type = entity.type
  local inventory_id = constants.fuel_entities[entity_type]
  
  -- If not in predefined list, try default fuel inventory
  if not inventory_id then
    inventory_id = defines.inventory.fuel
  end
  
  local inventory = entity.get_inventory(inventory_id)
  if inventory and inventory.valid then
    return inventory
  end
  
  return nil
end

-- Get ammo inventory for entity
function entity_detection.get_ammo_inventory(entity)
  if not entity or not entity.valid then
    return nil
  end
  
  local entity_type = entity.type
  local inventory_id = constants.ammo_entities[entity_type]
  if not inventory_id then
    return nil
  end
  
  return entity.get_inventory(inventory_id)
end

-- Check if entity is blacklisted
function entity_detection.is_blacklisted(entity, blacklist)
  if not entity or not entity.valid then
    return true
  end
  
  return blacklist_parser.is_entity_blacklisted(blacklist, entity.type)
end

-- Validate entity and player before processing
function entity_detection.validate(entity, player)
  if not entity or not entity.valid then
    return false
  end
  
  if not player or not player.valid then
    return false
  end
  
  return true
end

return entity_detection

