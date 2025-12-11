--[[
  DATA.LUA - Data Stage Modifications
  
  This file is loaded during the data stage and modifies base game prototypes.
  Use this stage for modifications that don't depend on other mods' changes.
  
  Features loaded here:
  - far-reach: Modifies character reach distances (simple prototype modification)
]]

if settings.startup["far-reach-enabled"].value then
  require("features.far-reach.data")
end