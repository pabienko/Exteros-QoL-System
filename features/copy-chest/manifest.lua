local conflicts = require("core.conflicts")

return {
  name = "copy-chest",
  conflicts = conflicts.CONFLICTS["copy-chest"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
    { name = "between-surfaces", type = "bool", default = false },
  },
}
