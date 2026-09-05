local M = {}

local NEW_KEY = "underground_belt_neighbour"
local OLD_KEY = "neighbours"

local underground_neighbour_key = nil

---@param entity LuaEntity
---@return LuaEntity?
function M.underground_partner(entity)
  if entity.type ~= "underground-belt" then return nil end

  local raw = entity --[[@as table]]

  if underground_neighbour_key then
    local success, result = pcall(function()
      return raw[underground_neighbour_key]
    end)
    if not success then return nil end
    return result --[[@as LuaEntity?]]
  end

  local success_new, result_new = pcall(function()
    return raw[NEW_KEY]
  end)
  if success_new then
    underground_neighbour_key = NEW_KEY
    return result_new --[[@as LuaEntity?]]
  end

  local success_old, result_old = pcall(function()
    return raw[OLD_KEY]
  end)
  if success_old then
    underground_neighbour_key = OLD_KEY
    return result_old --[[@as LuaEntity?]]
  end

  return nil
end

return M
