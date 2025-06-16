data:extend({
  -- Squeak Through
  { type = "bool-setting", name = "exteros-st-enabled", setting_type = "startup", default_value = true, order = "a" },
  -- Far Reach
  { type = "bool-setting", name = "exteros-fr-enabled", setting_type = "startup", default_value = true, order = "b" },
  -- Craftin Speed
  { type = "bool-setting", name = "exteros-cs-enabled", setting_type = "startup", default_value = true, order = "c" },
  -- Crafting Speed Multipliear
  { type = "int-setting", name = "exteros-cs-multiplier", setting_type = "runtime-global", default_value = 0, minimum_value = 0, maximum_value = 1000000000, order = "a" },
  -- Productivity Limit
  { type = "bool-setting", name = "exteros-pl-enabled", setting_type = "startup", default_value = true, order = "d" },
  -- Productivity Limit Value
  { type = "int-setting", name = "exteros-pl-maximum", setting_type = "startup", default_value = 300, minimum_value = 0, maximum_value = 1000000000, order = "d-a" }
})