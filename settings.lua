data:extend({
  {
    type = "bool-setting",
    name = "exteros-qol-even-distribution-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-a"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-squeak-through-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-b"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-auto-deconstruct-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-c"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-inventory-repair-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-d"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-time-controls-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-e"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-cheat-mode-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-f"
  },
  {
    type = "int-setting",
    name = "even-distribution-ticks",
    setting_type = "runtime-per-user",
    default_value = 60,
    minimum_value = 10,
    maximum_value = 600,
    order = "b-a"
  },
  {
    type = "bool-setting",
    name = "even-distribution-swap-balance",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "b-b"
  },
  {
    type = "int-setting",
    name = "exteros-qol-inventory-repair-interval",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 1,
    maximum_value = 600,
    order = "b-c"
  },
  {
    type = "string-setting",
    name = "exteros-qol-inventory-repair-order",
    setting_type = "runtime-global",
    allowed_values = {"low-first", "high-first"},
    default_value = "low-first",
    order = "b-d"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-cheat-productivity-unlocked",
    setting_type = "startup",
    default_value = false,
    order = "c-a"
  },
  {
    type = "int-setting",
    name = "exteros-qol-cheat-productivity-cap",
    setting_type = "startup",
    default_value = 300,
    minimum_value = 0,
    maximum_value = 1000000,
    order = "c-b"
  },
  {
    type = "string-setting",
    name = "exteros-qol-cheat-stack-size-mode",
    setting_type = "startup",
    default_value = "multiplier",
    allowed_values = {"multiplier", "absolute"},
    order = "c-c"
  },
  {
    type = "double-setting",
    name = "exteros-qol-cheat-stack-size-value",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 100000.0,
    order = "c-d"
  },
  {
    type = "int-setting",
    name = "cheat-reach-distance",
    setting_type = "runtime-per-user",
    default_value = 10,
    minimum_value = 0,
    maximum_value = 300,
    order = "c-e"
  },
  {
    type = "double-setting",
    name = "cheat-crafting-speed",
    setting_type = "runtime-per-user",
    default_value = 0.0,
    minimum_value = 0.0,
    maximum_value = 1000000.0,
    order = "c-f"
  },
  {
    type = "double-setting",
    name = "cheat-mining-speed",
    setting_type = "runtime-per-user",
    default_value = 0.0,
    minimum_value = 0.0,
    maximum_value = 1000000.0,
    order = "c-g"
  },
  {
    type = "int-setting",
    name = "cheat-inventory-bonus",
    setting_type = "runtime-per-user",
    default_value = 0,
    minimum_value = 0,
    maximum_value = 1000,
    order = "c-h"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-debug",
    setting_type = "startup",
    default_value = false,
    hidden = true,
    order = "z-z"
  }
})