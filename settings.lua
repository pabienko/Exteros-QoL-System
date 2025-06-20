data:extend({
  -- Squeak Through
  { type = "bool-setting", name = "squeak-through-enabled", setting_type = "startup", default_value = true, order = "a-1" },

  -- Far Reach
  { type = "bool-setting", name = "far-reach-enabled", setting_type = "startup", default_value = true, order = "b-1" },

  -- Crafting Speed
  { type = "bool-setting", name = "crafting-speed-enabled", setting_type = "startup", default_value = true, order = "c-1" },
  { type = "int-setting", name = "crafting-speed-multiplier", setting_type = "runtime-global", default_value = 0, minimum_value = 0, maximum_value = 1000000000, order = "c-2" },

  -- Productivity Limit
  { type = "bool-setting", name = "productivity-limit-enabled", setting_type = "startup", default_value = true, order = "d-1" },
  { type = "int-setting", name = "productivity-limit-maximum", setting_type = "startup", default_value = 300, minimum_value = 0, maximum_value = 1000000000, order = "d-2" }
})