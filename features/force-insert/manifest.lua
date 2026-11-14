local conflicts = require("core.conflicts")

return {
  name = "force-insert",
  conflicts = conflicts.CONFLICTS["force-insert"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
  runtime_per_user = {
    { name = "always", type = "bool", default = false },
    { name = "window", type = "int", default = 20, min = 1, max = 600, step = 5 },
  },
}
