--[[
  CORE/DEBUG.LUA - Debug System
  
  Centralized debugging utilities for the mod.
  Provides logging functions that respect the debug setting.
]]

local M = {}

-- Cache for debug setting to avoid repeated lookups
local debug_enabled = nil

--- Check if debug mode is enabled
--- @return boolean
local function is_debug_enabled()
  if debug_enabled == nil then
    -- Try to get the setting, but handle cases where settings might not be available yet
    local success, result = pcall(function()
      return settings.startup["exteros-qol-debug"].value
    end)
    debug_enabled = success and result or false
  end
  return debug_enabled
end

--- Convert a value to a string representation
--- @param value any
--- @return string
local function value_to_string(value)
  if type(value) == "table" then
    local parts = {}
    for k, v in pairs(value) do
      table.insert(parts, tostring(k) .. "=" .. value_to_string(v))
    end
    return "{" .. table.concat(parts, ", ") .. "}"
  else
    return tostring(value)
  end
end

--- Log a debug message
--- @param message string|LocalisedString
--- @param category string?
function M.log(message, category)
  if not is_debug_enabled() then
    return
  end
  
  local prefix = "[Exteros QoL"
  if category then
    prefix = prefix .. ":" .. category
  end
  prefix = prefix .. "] "
  
  log(prefix .. tostring(message))
end

--- Log a debug message with table data
--- @param message string|LocalisedString
--- @param data table
--- @param category string?
function M.log_data(message, data, category)
  if not is_debug_enabled() then
    return
  end
  
  local prefix = "[Exteros QoL"
  if category then
    prefix = prefix .. ":" .. category
  end
  prefix = prefix .. "] "
  
  local msg = prefix .. tostring(message)
  if data then
    msg = msg .. " | Data: " .. value_to_string(data)
  end
  log(msg)
end

--- Log an error (always logged, regardless of debug setting)
--- @param message string|LocalisedString
--- @param category string?
function M.error(message, category)
  local prefix = "[Exteros QoL ERROR"
  if category then
    prefix = prefix .. ":" .. category
  end
  prefix = prefix .. "] "
  
  log(prefix .. tostring(message))
end

--- Reset debug cache (call when settings change)
function M.reset_cache()
  debug_enabled = nil
end

return M
