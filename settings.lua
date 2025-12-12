data:extend({
  -- Core Debug (hidden from players - for developers only)
  -- { type = "bool-setting", name = "exteros-qol-debug", setting_type = "startup", default_value = false, order = "z-0" },
  
  -- Squeak Through
  { type = "bool-setting", name = "squeak-through-enabled", setting_type = "startup", default_value = false, order = "a-1" },
  { type = "bool-setting", name = "squeak-through-pipes", setting_type = "startup", default_value = false, order = "a-2" },
  { type = "bool-setting", name = "squeak-through-solar", setting_type = "startup", default_value = false, order = "a-3" },
  { type = "bool-setting", name = "squeak-through-production", setting_type = "startup", default_value = false, order = "a-4" },
  { type = "bool-setting", name = "squeak-through-mining", setting_type = "startup", default_value = false, order = "a-5" },
  { type = "bool-setting", name = "squeak-through-energy", setting_type = "startup", default_value = false, order = "a-6" },
  { type = "bool-setting", name = "squeak-through-logistics", setting_type = "startup", default_value = false, order = "a-7" },
  { type = "bool-setting", name = "squeak-through-defense", setting_type = "startup", default_value = false, order = "a-8" },
  { type = "bool-setting", name = "squeak-through-trees-rocks", setting_type = "startup", default_value = false, order = "a-9" },
  { type = "bool-setting", name = "squeak-through-space-age", setting_type = "startup", default_value = false, order = "a-10" },

  -- Far Reach
  { type = "bool-setting", name = "far-reach-enabled", setting_type = "startup", default_value = false, order = "b-1" },

  -- Crafting Speed
  { type = "bool-setting", name = "crafting-speed-enabled", setting_type = "startup", default_value = false, order = "c-1" },
  { type = "int-setting", name = "crafting-speed-multiplier", setting_type = "runtime-global", default_value = 0, minimum_value = 0, maximum_value = 1000000000, order = "c-2" },

  -- Productivity Limit
  { type = "bool-setting", name = "productivity-limit-enabled", setting_type = "startup", default_value = false, order = "d-1" },
  { type = "int-setting", name = "productivity-limit-maximum", setting_type = "startup", default_value = 300, minimum_value = 0, maximum_value = 1000000000, order = "d-2" },

    -- Even Distribution
  { type = "bool-setting", name = "even-distribution-enabled", setting_type = "startup", default_value = false, order = "e-1"},
  { type = "int-setting", name = "even-distribution-ticks", setting_type = "runtime-per-user", default_value = 60, minimum_value = 1, order = "e-2"},
  { type = "bool-setting", name = "even-distribution-swap-balance", setting_type = "runtime-per-user", default_value = false, order = "e-3"},
  { type = "bool-setting", name = "even-distribution-clear-cursor", setting_type = "runtime-per-user", default_value = false, order = "e-4"},

  -- Stack Size Manager
  { type = "bool-setting", name = "stack-size-enabled", setting_type = "startup", default_value = false, order = "f-01" },
  { type = "string-setting", name = "stack-size-mode", setting_type = "startup", default_value = "multiplier", allowed_values = {"multiplier", "absolute"}, order = "f-02" },
  { type = "double-setting", name = "stack-size-value", setting_type = "startup", default_value = 1.0, minimum_value = 0.1, maximum_value = 20000, order = "f-03" }
})