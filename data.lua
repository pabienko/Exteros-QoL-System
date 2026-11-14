local core = require("core.init")

local util = require("util")

local manifest = require("manifest")

---@return ExterosLibManifest
local function manifest_for_data()
  if feature_flags.quality then
    return manifest
  end

  local filtered = {}
  for key, value in pairs(manifest) do
    filtered[key] = value
  end

  local features = {}
  for _, feature in ipairs(manifest.features) do
    if feature.name ~= "quality-scroll" then
      table.insert(features, feature)
    end
  end
  filtered.features = features

  return filtered
end

require("__exteros-lib__.internal.family").register(manifest_for_data())

---@param feature string
---@return boolean
local function blocked(feature)
  return core.conflicts.is_blocked(feature, mods)
end

if not blocked("copy-chest") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-copy-chest",
      key_sequence = "SHIFT + C",
      consuming = "none"
    },
    {
      type = "custom-input",
      name = "exteros-qol-paste-chest",
      key_sequence = "SHIFT + V",
      consuming = "none"
    }
  })
end

if not blocked("inventory-sort") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-manual-inventory-sort",
      key_sequence = "SHIFT + I",
      consuming = "none"
    }
  })
end

if not blocked("time-controls") then
  data:extend({
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
end

if not blocked("wire-shortcuts") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-wire-cycle",
      key_sequence = "ALT + W",
      consuming = "none"
    }
  })
end

if not blocked("belt-reverser") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-reverse-belts",
      key_sequence = "CONTROL + R",
      consuming = "none"
    }
  })
end

if not blocked("renamer") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-rename-entity",
      key_sequence = "CONTROL + SHIFT + R",
      consuming = "none"
    }
  })
end

if not blocked("belt-brush") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-belt-brush-corners",
      key_sequence = "CONTROL + SHIFT + B",
      consuming = "none"
    },
    {
      type = "custom-input",
      name = "exteros-qol-belt-brush-balancers",
      key_sequence = "CONTROL + SHIFT + N",
      consuming = "none"
    },
    {
      type = "custom-input",
      name = "exteros-qol-belt-brush-increase",
      key_sequence = "CONTROL + mouse-wheel-up",
      alternative_key_sequence = "KP_PLUS",
      consuming = "none"
    },
    {
      type = "custom-input",
      name = "exteros-qol-belt-brush-decrease",
      key_sequence = "CONTROL + mouse-wheel-down",
      alternative_key_sequence = "KP_MINUS",
      consuming = "none"
    },
    {
      type = "custom-input",
      name = "exteros-qol-belt-brush-clear",
      key_sequence = "",
      linked_game_control = "clear-cursor"
    }
  })
end

if not blocked("chest-limit") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-chest-limit-increase",
      key_sequence = "CONTROL + mouse-wheel-up",
      alternative_key_sequence = "KP_PLUS",
      consuming = "none"
    },
    {
      type = "custom-input",
      name = "exteros-qol-chest-limit-decrease",
      key_sequence = "CONTROL + mouse-wheel-down",
      alternative_key_sequence = "KP_MINUS",
      consuming = "none"
    }
  })
end

if not blocked("force-insert") then
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
end

local base_planner_explosion = not blocked("planner-zapper")
  and data.raw.explosion and data.raw.explosion.explosion

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

if feature_flags.quality and not blocked("quality-scroll") then
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

if not blocked("ghost-builder") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-ghost-builder-toggle",
      key_sequence = "CONTROL + SHIFT + G",
      consuming = "none"
    }
  })
end

if not blocked("planner-menu") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-planner-menu-toggle",
      key_sequence = "CONTROL + B",
      consuming = "none"
    },
    {
      type = "custom-input",
      name = "exteros-qol-planner-cycle",
      key_sequence = "ALT + Q",
      consuming = "none"
    },
    {
      type = "custom-input",
      name = "exteros-qol-planner-cycle-back",
      key_sequence = "ALT + SHIFT + Q",
      consuming = "none"
    }
  })
end

if not blocked("tape-measure") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-tape-measure",
      key_sequence = "CONTROL + SHIFT + M",
      consuming = "none"
    }
  })
end

if not blocked("rate-calculator") then
  require("features.rate-calculator.data")
end

if not blocked("tape-measure") then
  require("features.tape-measure.data")
end

if not blocked("belt-visualizer") then
  data:extend({
    {
      type = "custom-input",
      name = "exteros-qol-belt-visualizer-highlight",
      key_sequence = "CONTROL + G",
      consuming = "none"
    },
    {
      type = "shortcut",
      name = "exteros-qol-belt-visualizer-hover-toggle",
      order = "e[exteros-qol]-b[belt-visualizer]",
      action = "lua",
      localised_name = {"shortcut-name.exteros-qol-belt-visualizer-hover-toggle"},
      toggleable = true,
      icon = "__base__/graphics/icons/transport-belt.png",
      icon_size = 64,
      small_icon = "__base__/graphics/icons/transport-belt.png",
      small_icon_size = 64
    }
  })
end