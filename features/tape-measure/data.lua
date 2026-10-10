data:extend({
  {
    type = "selection-tool",
    name = "exteros-qol-tape-measure",
    order = "d[tools]-t[tape-measure]",
    icon = "__Exteros-QoL-System__/graphics/tape-measure/tape-measure.png",
    icon_size = 64,
    select = {
      border_color = { r = 0.3, g = 0.8, b = 1 },
      cursor_box_type = "copy",
      mode = { "nothing" },
    },
    alt_select = {
      border_color = { r = 0.3, g = 0.8, b = 1 },
      cursor_box_type = "copy",
      mode = { "nothing" },
    },
    stack_size = 1,
    flags = { "only-in-cursor", "spawnable", "not-stackable" },
    hidden = true,
  },
})
