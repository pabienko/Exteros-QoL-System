local core = require("core.init")

if not core.conflicts.is_blocked("squeak-through", mods) then
  require("features.squeak-through.final-fixes").apply()
end

if not core.conflicts.is_blocked("bottleneck", mods) then
  require("features.bottleneck.final-fixes").apply()
end

if not core.conflicts.is_blocked("searchlight", mods) then
  require("features.searchlight.final-fixes").apply()
end

if not core.conflicts.is_blocked("rate-calculator", mods) then
  require("features.rate-calculator.final-fixes")
end
