local conflicts = require("core.conflicts")

return {
  name = "auto-alt-mode",
  conflicts = conflicts.CONFLICTS["auto-alt-mode"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
  runtime_per_user = {
    { name = "player", type = "bool", default = true },
  },
}
