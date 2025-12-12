--[[
  DATA-FINAL-FIXES.LUA - Data Final Fixes Stage Modifications
  
  This file is loaded during the data-final-fixes stage, which is the last stage
  before the game starts. Use this stage for modifications that need to run after
  all other mods have made their changes, ensuring compatibility with mods that
  modify the same prototypes.
  
  Features loaded here:
  - squeak-through: Modifies collision boxes (needs to run last for compatibility with other mods)
  - stack-size: Modifies item stack sizes (needs to run last to override other mods' changes)
]]

-- Načítání funkcí
if settings.startup["squeak-through-enabled"].value then
  require("features.squeak-through.data-final-fixes")
end

if settings.startup["stack-size-enabled"].value then
  require("features.stack-size.data-final-fixes")
end