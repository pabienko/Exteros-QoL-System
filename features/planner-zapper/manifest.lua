local conflicts = require("core.conflicts")

return {
  name = "planner-zapper",
  conflicts = conflicts.CONFLICTS["planner-zapper"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
}
