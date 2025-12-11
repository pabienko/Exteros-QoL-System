--[[
  DATA-UPDATES.LUA - Data Updates Stage Modifications
  
  This file is loaded during the data-updates stage, after the data stage.
  Use this stage for modifications that should happen after base game data is loaded
  but before data-final-fixes, allowing compatibility with other mods that modify
  the same prototypes in the data stage.
  
  Features loaded here:
  - productivity-limit: Modifies recipe productivity limits (needs to run after recipes are defined)
]]

if settings.startup["productivity-limit-enabled"].value then
  require("features.productivity-limit.data-updates")
end