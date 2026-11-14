local conflicts = require("core.conflicts")

return {
  name = "tape-measure",
  conflicts = conflicts.CONFLICTS["tape-measure"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
}
