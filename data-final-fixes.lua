local core = require("core.init")

if not core.conflicts.is_blocked("squeak-through", mods) then
  require("features.squeak-through.final-fixes").apply()
end

require("features.cheats.final-fixes").apply()
