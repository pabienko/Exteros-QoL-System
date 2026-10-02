-- adapted from Rate Calculator by raiguard (MIT, © 2020-2023 Caleb Heuer)
data:extend({
  {
    type = "shortcut",
    name = "exteros-qol-rcalc-get-selection-tool",
    order = "d[tools]-r[rate-calculator]",
    icon = "__Exteros-QoL-System__/graphics/rate-calculator/shortcut-x32-black.png",
    disabled_icon = "__Exteros-QoL-System__/graphics/rate-calculator/shortcut-x32-white.png",
    small_icon = "__Exteros-QoL-System__/graphics/rate-calculator/shortcut-x24-black.png",
    disabled_small_icon = "__Exteros-QoL-System__/graphics/rate-calculator/shortcut-x24-white.png",
    icon_size = 32,
    small_icon_size = 24,
    action = "lua",
    associated_control_input = "exteros-qol-rcalc-get-selection-tool",
  },
})
