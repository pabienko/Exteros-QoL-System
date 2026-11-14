local conflicts = require("core.conflicts")

return {
  name = "chest-limit",
  conflicts = conflicts.CONFLICTS["chest-limit"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
  runtime_per_user = {
    { name = "player", type = "bool", default = true },
  },
}
