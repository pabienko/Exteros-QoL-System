local styles = data.raw["gui-style"].default

-- adapted from flib (MIT, © raiguard)
styles.exteros_qol_rcalc_slot_button_default = {
  type = "button_style",
  parent = "slot_button",
  size = 40,
  clicked_vertical_offset = 0,
  default_graphical_set = {
    base = { border = 4, position = { 240, 0 }, size = 80, filename = "__Exteros-QoL-System__/graphics/rate-calculator/slots.png" },
    shadow = offset_by_2_rounded_corners_glow(default_dirt_color), --- @diagnostic disable-line: undefined-global
  },
  hovered_graphical_set = {
    base = { border = 4, position = { 320, 0 }, size = 80, filename = "__Exteros-QoL-System__/graphics/rate-calculator/slots.png" },
    shadow = offset_by_2_rounded_corners_glow(default_dirt_color), --- @diagnostic disable-line: undefined-global
    glow = offset_by_2_rounded_corners_glow(default_glow_color), --- @diagnostic disable-line: undefined-global
  },
  clicked_graphical_set = {
    base = { border = 4, position = { 400, 0 }, size = 80, filename = "__Exteros-QoL-System__/graphics/rate-calculator/slots.png" },
    shadow = offset_by_2_rounded_corners_glow(default_dirt_color), --- @diagnostic disable-line: undefined-global
  },
  disabled_graphical_set = { -- identical to default graphical set
    base = { border = 4, position = { 240, 0 }, size = 80, filename = "__Exteros-QoL-System__/graphics/rate-calculator/slots.png" },
    shadow = offset_by_2_rounded_corners_glow(default_dirt_color), --- @diagnostic disable-line: undefined-global
  },
}

-- adapted from flib (MIT, © raiguard)
styles.exteros_qol_rcalc_naked_scroll_pane = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  padding = 12,
  graphical_set = {
    shadow = default_inner_shadow, --- @diagnostic disable-line: undefined-global
  },
}

-- adapted from flib (MIT, © raiguard)
styles.exteros_qol_rcalc_titlebar_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 8,
}

-- adapted from flib (MIT, © raiguard)
styles.exteros_qol_rcalc_frame_title = {
  type = "label_style",
  parent = "frame_title",
  bottom_padding = 3,
  top_margin = -3,
}

-- adapted from flib (MIT, © raiguard)
styles.exteros_qol_rcalc_titlebar_drag_handle = {
  type = "empty_widget_style",
  parent = "draggable_space",
  left_margin = 4,
  right_margin = 4,
  height = 24,
  horizontally_stretchable = "on",
}

-- adapted from flib (MIT, © raiguard)
styles.exteros_qol_rcalc_titlebar_search_textfield = {
  type = "textbox_style",
  top_margin = -2,
  bottom_margin = 1,
  width = 150,
}

-- adapted from flib (MIT, © raiguard)
styles.exteros_qol_rcalc_horizontal_pusher = {
  type = "empty_widget_style",
  horizontally_stretchable = "on",
}

-- adapted from RateCalculatorPlus by Kesha (MIT, © 2020-2023 Caleb Heuer)

styles.exteros_qol_rcalc_units_choose_elem_button = {
  type = "button_style",
  parent = "exteros_qol_rcalc_slot_button_default",
  height = 30,
  width = 30,
}

styles.exteros_qol_rcalc_multiplier_holder_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 2,
}

styles.exteros_qol_rcalc_multiplier_textfield = {
  type = "textbox_style",
  parent = "short_number_textfield",
  width = 40,
  horizontal_align = "center",
}

styles.exteros_qol_rcalc_multiplier_nudge_buttons_flow = {
  type = "vertical_flow_style",
  vertical_spacing = 0,
  top_margin = 2,
}

styles.exteros_qol_rcalc_multiplier_nudge_button = {
  type = "button_style",
  parent = "tool_button",
  width = 20,
  height = 14,
  padding = -1,
}

styles.exteros_qol_rcalc_rates_table_scroll_pane = {
  type = "scroll_pane_style",
  parent = "exteros_qol_rcalc_naked_scroll_pane",
  maximal_height = 600,
  top_padding = 8,
  bottom_padding = 8,
  minimal_height = 36,
  vertical_flow_style = {
    type = "vertical_flow_style",
    horizontal_align = "center",
    vertical_align = "center",
  },
}

styles.exteros_qol_rcalc_rates_table_horizontal_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 8,
}

styles.exteros_qol_rcalc_rates_table_vertical_flow = {
  type = "vertical_flow_style",
  vertical_spacing = 8,
}

styles.exteros_qol_rcalc_rates_table_row_flow = {
  type = "horizontal_flow_style",
  vertical_align = "center",
  horizontal_spacing = 8,
  top_padding = 4,
  bottom_padding = 4,
}

styles.exteros_qol_rcalc_completion_checkbox = {
  type = "checkbox_style",
  right_margin = 8,
}

styles.exteros_qol_rcalc_transparent_slot = {
  type = "button_style",
  parent = "transparent_slot",
  right_margin = 8,
}

styles.exteros_qol_rcalc_transparent_slot_no_shadow = {
  type = "button_style",
  parent = "exteros_qol_rcalc_transparent_slot",
  draw_shadow_under_picture = false,
}

styles.exteros_qol_rcalc_machines_label = {
  type = "label_style",
  font = "default-semibold",
  vertical_align = "center",
  height = 32,
}

styles.exteros_qol_rcalc_intermediate_breakdown_label = {
  type = "label_style",
  parent = "exteros_qol_rcalc_rate_label",
  font = "default-small-semibold",
  top_padding = 2,
  width = 95,
}

styles.exteros_qol_rcalc_rate_label = {
  type = "label_style",
  parent = "exteros_qol_rcalc_machines_label",
  horizontal_align = "right",
  width = 71,
}

styles.exteros_qol_rcalc_density_label = {
  type = "label_style",
  parent = "exteros_qol_rcalc_rate_label",
  width = 96,
}

styles.exteros_qol_rcalc_negative_subfooter_frame = {
  type = "frame_style",
  parent = "subfooter_frame",
  graphical_set = {
    base = {
      center = { position = { 411, 25 }, size = { 1, 1 } },
      top = { position = { 411, 17 }, size = { 1, 8 } },
    },
    shadow = top_shadow, --- @diagnostic disable-line: undefined-global
  },
  left_padding = 12,
  bottom_padding = 4,
  horizontally_stretchable = "on",
  height = 0,
}
