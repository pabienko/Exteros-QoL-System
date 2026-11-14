local conflicts = require("core.conflicts")

return {
  name = "rate-calculator",
  conflicts = conflicts.CONFLICTS["rate-calculator"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
  runtime_per_user = {
    { name = "dismiss-tool-on-selection", type = "bool", default = false },
    { name = "show-calculation-errors", type = "bool", default = true },
    { name = "show-power-consumption", type = "bool", default = false },
    { name = "default-gui-location", type = "string", default = "top-left", allowed = { "top-left", "center" } },
    {
      name = "default-timescale",
      type = "string",
      default = "per-second",
      allowed = { "per-second", "per-minute", "per-10-minutes", "per-hour", "transport-belts", "inserters" },
    },
    { name = "show-completion-checkboxes", type = "bool", default = false },
    { name = "show-intermediate-breakdowns", type = "bool", default = true },
    { name = "show-pollution", type = "bool", default = false },
  },
}
