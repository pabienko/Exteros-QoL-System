local conflicts = require("core.conflicts")

return {
  name = "debug",
  conflicts = conflicts.CONFLICTS["debug"],
  startup = {
    { name = "enabled", type = "bool", default = false, hidden = true },
  },
}
