--[[
  CORE/VALIDATION.LUA - Validation Utilities
  
  Common validation functions for entities, players, and other game objects.
]]

local M = {}

--- Check if an entity is valid
--- @param entity LuaEntity?
--- @return boolean
function M.is_entity_valid(entity)
  return entity ~= nil and entity.valid
end

--- Check if a player is valid
--- @param player LuaPlayer?
--- @return boolean
function M.is_player_valid(player)
  return player ~= nil and player.valid
end

--- Check if an inventory is valid
--- @param inventory LuaInventory?
--- @return boolean
function M.is_inventory_valid(inventory)
  return inventory ~= nil and inventory.valid
end

--- Validate and filter an array of entities, removing invalid ones
--- @param entities LuaEntity[]
--- @return LuaEntity[]
function M.filter_valid_entities(entities)
  local valid_entities = {}
  local valid_count = 0
  for i = 1, #entities do
    local entity = entities[i]
    if M.is_entity_valid(entity) then
      valid_count = valid_count + 1
      valid_entities[valid_count] = entity
    end
  end
  return valid_entities
end

--- Validate a transfer target (player or entity)
--- @param target LuaPlayer|LuaEntity
--- @return boolean
function M.is_transfer_target_valid(target)
  if not target then
    return false
  end
  if target.object_name == "LuaEntity" then
    return M.is_entity_valid(target)
  elseif target.object_name == "LuaPlayer" then
    return M.is_player_valid(target)
  end
  return false
end

return M
