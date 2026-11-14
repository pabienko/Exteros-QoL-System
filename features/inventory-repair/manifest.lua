local conflicts = require("core.conflicts")

return {
  name = "inventory-repair",
  conflicts = conflicts.CONFLICTS["inventory-repair"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
    { name = "interval", type = "int", default = 60, min = 1, max = 600, step = 1 },
    { name = "order", type = "string", default = "low-first", allowed = { "low-first", "high-first" } },
  },
}
