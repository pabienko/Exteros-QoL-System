local conflicts = require("core.conflicts")

return {
  name = "auto-deconstruct",
  conflicts = conflicts.CONFLICTS["auto-deconstruct"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
    { name = "chests", type = "bool", default = true },
    { name = "inserters", type = "bool", default = true },
    { name = "beacons", type = "bool", default = true },
    { name = "pipes", type = "bool", default = true },
    { name = "belts", type = "bool", default = false },
    { name = "belt-distance", type = "int", default = 32, min = 4, max = 256, step = 4 },
    { name = "poles", type = "bool", default = false },
    { name = "pole-distance", type = "int", default = 32, min = 4, max = 256, step = 4 },
    { name = "pumpjacks", type = "bool", default = false },
  },
}
