if settings.startup["crafting-speed-enabled"].value then
  require("features.crafting-speed.control")
end

if settings.startup["even-distribution-enabled"].value then
  require("features.even-distribution.control")
end