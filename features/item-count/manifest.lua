local conflicts = require("core.conflicts")

return {
  name = "item-count",
  conflicts = conflicts.CONFLICTS["item-count"],
  runtime_global = {
    { name = "enabled", type = "bool", default = true },
  },
  runtime_per_user = {
    { name = "player-enabled", type = "bool", default = false },
    { name = "format", type = "string", default = "comma", allowed = { "comma", "dot", "space", "none", "short" } },
  },
}
