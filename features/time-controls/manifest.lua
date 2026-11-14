local conflicts = require("core.conflicts")

return {
  name = "time-controls",
  conflicts = conflicts.CONFLICTS["time-controls"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
}
