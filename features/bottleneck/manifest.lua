local conflicts = require("core.conflicts")

return {
  name = "bottleneck",
  conflicts = conflicts.CONFLICTS["bottleneck"],
  startup = {
    { name = "enabled", type = "bool", default = false },
    { name = "mining-drills", type = "bool", default = true },
    { name = "size", type = "string", default = "medium", allowed = { "small", "medium", "large" } },
    { name = "glow", type = "bool", default = true },
    { name = "override", type = "bool", default = false },
    { name = "color-working", type = "string", default = "#00FF00" },
    { name = "color-full-output", type = "string", default = "#FFFF00" },
    { name = "color-stopped", type = "string", default = "#FF0000" },
    { name = "color-low-power", type = "string", default = "#FF8000" },
  },
}
