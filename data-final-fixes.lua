local core = require("core.init")

if not core.conflicts.is_blocked("squeak-through", mods) then
  require("features.squeak-through.final-fixes").apply()
end

-- Snapshot prototype-stage-only fields the calc engine needs for fusion-reactor/fusion-generator/
-- thruster/mining-drill into a mod-data prototype. Not gated on Space Age: the fusion/thruster
-- loops in final-fixes.lua simply find nothing in data.raw without it, but mining-drill
-- resource_searching_offset (modded drills included) must work without Space Age too.
if
  not core.conflicts.is_blocked("rate-calculator", mods)
  and settings.startup["exteros-qol-rate-calculator-enabled"].value
then
  require("features.rate-calculator.final-fixes")
end
