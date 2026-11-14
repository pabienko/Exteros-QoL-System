local conflicts = require("core.conflicts")

return {
  name = "renamer",
  conflicts = conflicts.CONFLICTS["renamer"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
}
