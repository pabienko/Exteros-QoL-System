require("core.init")

local util = require("util")

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
  },
  {
    type = "custom-input",
    name = "exteros-qol-wire-cycle",
    key_sequence = "ALT + W",
    consuming = "none"
  }
})

local force_insert_controls = {
  "fast-entity-transfer",
  "fast-entity-split",
  "stack-transfer",
  "stack-split",
  "inventory-transfer",
  "inventory-split",
}

for _, control in pairs(force_insert_controls) do
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-force-insert-" .. control,
      key_sequence = "",
      linked_game_control = control,
      include_selected_prototype = true
    }
  })
end

local base_planner_explosion = data.raw.explosion and data.raw.explosion.explosion

if base_planner_explosion then
  local drop_planner_explosion = util.table.deepcopy(base_planner_explosion)
  drop_planner_explosion.name = "exteros-qol-drop-planner"

  if drop_planner_explosion.animations then
    for _, animation in pairs(drop_planner_explosion.animations) do
      animation.scale = 0.5
    end
  end

  if drop_planner_explosion.sound and drop_planner_explosion.sound.variations then
    for _, variation in pairs(drop_planner_explosion.sound.variations) do
      variation.filename = "__base__/sound/fight/laser-1.ogg"
      variation.volume = 0.5
    end
  end

  data:extend({ drop_planner_explosion })
end

if feature_flags.quality then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-quality-cycle-next",
      key_sequence = "CONTROL + SHIFT + mouse-wheel-up"
    },
    {
      type = "custom-input",
      name = "exteros-qol-quality-cycle-previous",
      key_sequence = "CONTROL + SHIFT + mouse-wheel-down"
    }
  })
end