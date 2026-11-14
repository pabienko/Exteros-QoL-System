local conflicts = require("core.conflicts")

return {
  name = "belt-brush",
  conflicts = conflicts.CONFLICTS["belt-brush"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
}
