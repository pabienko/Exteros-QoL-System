local conflicts = require("core.conflicts")

return {
  name = "planner-menu",
  conflicts = conflicts.CONFLICTS["planner-menu"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
  runtime_per_user = {
    { name = "columns", type = "int", default = 8, min = 4, max = 16, step = 1 },
  },
}
