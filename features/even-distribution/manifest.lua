local conflicts = require("core.conflicts")

return {
  name = "even-distribution",
  conflicts = conflicts.CONFLICTS["even-distribution"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
  runtime_per_user = {
    { name = "ticks", type = "int", default = 60, min = 10, max = 600, step = 10 },
    { name = "swap-balance", type = "bool", default = false },
    { name = "fuel-limit", type = "double", default = 0.5, min = 0, max = 1000, step = 0.1 },
    { name = "fuel-limit-unit", type = "string", default = "stacks", allowed = { "stacks", "items", "mj" } },
    { name = "ammo-limit", type = "double", default = 0.5, min = 0, max = 1000, step = 0.1 },
    { name = "ammo-limit-unit", type = "string", default = "stacks", allowed = { "stacks", "items" } },
    { name = "source", type = "string", default = "inventory", allowed = { "inventory", "hand" } },
  },
}
