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

return M
