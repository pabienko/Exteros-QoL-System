local conflicts = require("core.conflicts")

return {
  name = "searchlight",
  conflicts = conflicts.CONFLICTS["searchlight"],
  runtime_global = {
    { name = "enabled", type = "bool", default = true },
  },
  startup = {
    { name = "flashlight-global-scale", type = "double", default = 1, min = 0.1, max = 5 },
    { name = "flashlight-global-intensity", type = "double", default = 1, min = 0.1, max = 1.6667 },
    { name = "flashlight-global-color", type = "string", default = "", allow_blank = true },
  },
  runtime_per_user = {
    { name = "player-enabled", type = "bool", default = false },
  },
}
