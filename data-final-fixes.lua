local core = require("core.init")

if not core.conflicts.is_blocked("squeak-through", mods) then
  require("features.squeak-through.final-fixes").apply()
end

if
  not core.conflicts.is_blocked("rate-calculator", mods)
  and settings.startup["exteros-qol-rate-calculator-enabled"].value
then
  require("features.rate-calculator.final-fixes")
end
