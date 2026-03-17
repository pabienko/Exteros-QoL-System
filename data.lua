require("core.init")

data:extend({
  {
    type = "custom-input",
    name = "exteros-qol-open-hub",
    key_sequence = "SHIFT + E",
    consuming = "none"
  },
  {
    type = "custom-input",
    name = "exteros-qol-manual-inventory-sort",
    key_sequence = "SHIFT + I",
    consuming = "none"
  },
  {
    type = "custom-input",
    name = "exteros-qol-speed-up",
    key_sequence = "",
    linked_game_control = "editor-speed-up"
  },
  {
    type = "custom-input",
    name = "exteros-qol-speed-down",
    key_sequence = "",
    linked_game_control = "editor-speed-down"
  },
  {
    type = "custom-input",
    name = "exteros-qol-speed-reset",
    key_sequence = "",
    linked_game_control = "editor-reset-speed"
  },
  {
    type = "custom-input",
    name = "exteros-qol-speed-pause",
    key_sequence = "",
    linked_game_control = "editor-toggle-pause"
  }
})