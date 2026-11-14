local conflicts = require("core.conflicts")

return {
  name = "squeak-through",
  conflicts = conflicts.CONFLICTS["squeak-through"],
  startup = {
    { name = "enabled", type = "bool", default = false },
  },
}
