--[[
  CONTROL.LUA - Runtime Control Scripts
  
  This file is loaded during the control stage and handles runtime event handlers
  for features that need to respond to in-game events.
  
  Only features that require runtime event handling are loaded here.
  Features that only modify data prototypes are loaded in data.lua, data-updates.lua,
  or data-final-fixes.lua instead.
  
  Features loaded here:
  - crafting-speed: Requires runtime updates when settings change or players are created
  - even-distribution: Requires runtime event handlers for drag-and-drop distribution
]]

-- Initialize core library (available for all features)
local core = require("core.init")

-- Reset debug cache when settings change
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "exteros-qol-debug" then
    core.debug.reset_cache()
  end
end)

if settings.startup["crafting-speed-enabled"].value then
  require("features.crafting-speed.control")
end

if settings.startup["even-distribution-enabled"].value then
  require("features.even-distribution.control")
end