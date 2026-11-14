local conflicts = require("core.conflicts")

return {
  name = "belt-reverser",
  conflicts = conflicts.CONFLICTS["belt-reverser"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
}
