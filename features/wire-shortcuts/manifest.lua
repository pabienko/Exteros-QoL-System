local conflicts = require("core.conflicts")

return {
  name = "wire-shortcuts",
  conflicts = conflicts.CONFLICTS["wire-shortcuts"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
  runtime_per_user = {
    { name = "cycle-copper", type = "bool", default = false },
  },
}
