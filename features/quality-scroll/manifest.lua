local conflicts = require("core.conflicts")

return {
  name = "quality-scroll",
  conflicts = conflicts.CONFLICTS["quality-scroll"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
}
