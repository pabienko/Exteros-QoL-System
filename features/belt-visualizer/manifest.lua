local conflicts = require("core.conflicts")

return {
  name = "belt-visualizer",
  conflicts = conflicts.CONFLICTS["belt-visualizer"],
  runtime_global = {
    { name = "enabled", type = "bool", default = true },
  },
  runtime_per_user = {
    { name = "max-per-tick", type = "int", default = 64, min = 1, max = 1000, step = 1 },
    { name = "max-entities", type = "int", default = 10000, min = 10, max = 100000, step = 100 },
  },
}
