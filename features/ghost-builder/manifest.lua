local conflicts = require("core.conflicts")

return {
  name = "ghost-builder",
  conflicts = conflicts.CONFLICTS["ghost-builder"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
  runtime_per_user = {
    { name = "entities", type = "bool", default = true },
    { name = "upgrades", type = "bool", default = true },
    { name = "tiles", type = "bool", default = true },
    { name = "modules", type = "bool", default = true },
  },
}
