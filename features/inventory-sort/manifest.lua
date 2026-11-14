local conflicts = require("core.conflicts")

return {
  name = "inventory-sort",
  conflicts = conflicts.CONFLICTS["inventory-sort"],
  runtime_global = {
    { name = "enabled", type = "bool", default = true },
  },
  runtime_per_user = {
    { name = "player-enabled", type = "bool", default = false },
  },
}
