--[[
  CORE/SETTINGS.LUA - Settings Utilities
  
  Helper functions for working with mod settings.
  Provides type-safe access and caching.
]]

local M = {}

--- Get a startup setting value
--- @param name string
--- @return any
function M.get_startup(name)
  return settings.startup[name].value
end

--- Get a runtime-global setting value
--- @param name string
--- @return any
function M.get_global(name)
  return settings.global[name].value
end

--- Get a runtime-per-user setting value for a player
--- @param player LuaPlayer
--- @param name string
--- @return any
function M.get_player(player, name)
  local player_settings = settings.get_player_settings(player)
  return player_settings[name].value
end

--- Check if a startup setting is enabled
--- @param name string
--- @return boolean
function M.is_enabled(name)
  return M.get_startup(name) == true
end

return M
