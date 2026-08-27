local M = {}

---@param player LuaPlayer?
---@return boolean
function M.is_player_valid(player)
  return player ~= nil and player.valid and player.connected
end

---@param entity LuaEntity?
---@return boolean
function M.is_entity_valid(entity)
  return entity ~= nil and entity.valid
end

---@param entities LuaEntity[]
---@return LuaEntity[]
function M.filter_valid_entities(entities)
  local valid_entities = {}
  for i = 1, #entities do
    local entity = entities[i]
    if M.is_entity_valid(entity) then
      table.insert(valid_entities, entity)
    end
  end
  return valid_entities
end

return M
