local conflicts = require("core.conflicts")

---@param feature string
---@return boolean
local function blocked(feature)
  return conflicts.is_blocked(feature, mods)
end

if not blocked("even-distribution") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-even-distribution-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-a"
    }
  })
end

if not blocked("squeak-through") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-squeak-through-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-b"
    }
  })
end

if not blocked("auto-deconstruct") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-auto-deconstruct-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-c"
    }
  })
end

if not blocked("inventory-repair") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-inventory-repair-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-d"
    }
  })
end

if not blocked("time-controls") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-time-controls-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-e"
    }
  })
end

if not blocked("auto-alt-mode") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-auto-alt-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-e2"
    }
  })
end

if not blocked("force-insert") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-force-insert-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-f"
    }
  })
end

if not blocked("wire-shortcuts") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-wire-shortcuts-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-f2"
    }
  })
end

if not blocked("planner-zapper") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-planner-zapper-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-f3"
    }
  })
end

if not blocked("copy-chest") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-copy-chest-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-f5"
    }
  })
end

data:extend({
  {
    type = "bool-setting",
    name = "exteros-qol-player-colors-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-f7"
  }
})

if not blocked("belt-reverser") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-belt-reverser-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-f6"
    }
  })
end

if not blocked("belt-brush") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-belt-brush-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-g0"
    }
  })
end

if not blocked("renamer") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-renamer-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-f8"
    }
  })
end

if not blocked("chest-limit") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-chest-limit-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-f9"
    }
  })
end

if not blocked("rate-calculator") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-rate-calculator-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-g1"
    }
  })
end

if not blocked("ghost-builder") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-ghost-builder-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-g2"
    }
  })
end

if not blocked("planner-menu") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-planner-menu-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-g3"
    }
  })
end

if not blocked("tape-measure") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-tape-measure-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-g4"
    }
  })
end

if not blocked("bottleneck") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-bottleneck-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-g5"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-bottleneck-mining-drills",
      setting_type = "startup",
      default_value = true,
      order = "a-g5-a"
    },
    {
      type = "string-setting",
      name = "exteros-qol-bottleneck-size",
      setting_type = "startup",
      allowed_values = { "small", "medium", "large" },
      default_value = "medium",
      order = "a-g5-b"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-bottleneck-glow",
      setting_type = "startup",
      default_value = true,
      order = "a-g5-c"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-bottleneck-override",
      setting_type = "startup",
      default_value = false,
      order = "a-g5-d"
    },
    {
      type = "string-setting",
      name = "exteros-qol-bottleneck-color-working",
      setting_type = "startup",
      default_value = "#00FF00",
      order = "a-g5-e"
    },
    {
      type = "string-setting",
      name = "exteros-qol-bottleneck-color-full-output",
      setting_type = "startup",
      default_value = "#FFFF00",
      order = "a-g5-f"
    },
    {
      type = "string-setting",
      name = "exteros-qol-bottleneck-color-stopped",
      setting_type = "startup",
      default_value = "#FF0000",
      order = "a-g5-g"
    },
    {
      type = "string-setting",
      name = "exteros-qol-bottleneck-color-low-power",
      setting_type = "startup",
      default_value = "#FF8000",
      order = "a-g5-h"
    }
  })
end

if not blocked("belt-visualizer") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-belt-visualizer-enabled",
      setting_type = "startup",
      default_value = true,
      order = "a-g6"
    }
  })
end

if not blocked("searchlight") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-searchlight-feature-enabled",
      setting_type = "startup",
      default_value = true,
      order = "a-g7"
    },
    {
      type = "double-setting",
      name = "exteros-qol-searchlight-flashlight-global-scale",
      setting_type = "startup",
      default_value = 1,
      minimum_value = 0.1,
      maximum_value = 5,
      order = "a-g7-a"
    },
    {
      type = "double-setting",
      name = "exteros-qol-searchlight-flashlight-global-intensity",
      setting_type = "startup",
      default_value = 1,
      minimum_value = 0.1,
      maximum_value = 1.6667,
      order = "a-g7-b"
    },
    {
      type = "string-setting",
      name = "exteros-qol-searchlight-flashlight-global-color",
      setting_type = "startup",
      default_value = "",
      allow_blank = true,
      order = "a-g7-c"
    }
  })
end

if not blocked("item-count") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-item-count-feature-enabled",
      setting_type = "startup",
      default_value = true,
      order = "a-g8"
    }
  })
end

if not blocked("inventory-sort") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-inventory-sort-enabled",
      setting_type = "startup",
      default_value = true,
      order = "a-g9"
    }
  })
end

if not blocked("even-distribution") then
  data:extend({
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
    }
  })
end

if not blocked("inventory-sort") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-auto-sort-inventory",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-e"
    }
  })
end

if not blocked("item-count") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-item-count-enabled",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-f"
    },
    {
      type = "string-setting",
      name = "exteros-qol-item-count-format",
      setting_type = "runtime-per-user",
      default_value = "comma",
      allowed_values = { "comma", "dot", "space", "none", "short" },
      order = "b-f1"
    }
  })
end

if not blocked("searchlight") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-searchlight-enabled",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-g"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-searchlight-custom-flashlight",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-g0"
    },
    {
      type = "double-setting",
      name = "exteros-qol-searchlight-flashlight-scale",
      setting_type = "runtime-per-user",
      default_value = 1,
      minimum_value = 0.1,
      maximum_value = 5,
      order = "b-g1"
    },
    {
      type = "double-setting",
      name = "exteros-qol-searchlight-flashlight-intensity",
      setting_type = "runtime-per-user",
      default_value = 1,
      minimum_value = 0.1,
      maximum_value = 1.6667,
      order = "b-g2"
    },
    {
      type = "string-setting",
      name = "exteros-qol-searchlight-flashlight-color",
      setting_type = "runtime-per-user",
      default_value = "",
      allow_blank = true,
      order = "b-g3"
    }
  })
end

if not blocked("force-insert") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-force-insert-always",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-h"
    },
    {
      type = "int-setting",
      name = "exteros-qol-force-insert-window",
      setting_type = "runtime-per-user",
      default_value = 20,
      minimum_value = 1,
      maximum_value = 600,
      order = "b-i"
    }
  })
end

if not blocked("wire-shortcuts") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-wire-cycle-copper",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-j"
    }
  })
end

if not blocked("auto-alt-mode") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-auto-alt-player",
      setting_type = "runtime-per-user",
      default_value = true,
      order = "b-aa"
    }
  })
end

if not blocked("chest-limit") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-chest-limit-player",
      setting_type = "runtime-per-user",
      default_value = true,
      order = "b-cl"
    }
  })
end

if not blocked("ghost-builder") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-ghost-builder-entities",
      setting_type = "runtime-per-user",
      default_value = true,
      order = "b-gb-a"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-ghost-builder-upgrades",
      setting_type = "runtime-per-user",
      default_value = true,
      order = "b-gb-b"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-ghost-builder-tiles",
      setting_type = "runtime-per-user",
      default_value = true,
      order = "b-gb-c"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-ghost-builder-modules",
      setting_type = "runtime-per-user",
      default_value = true,
      order = "b-gb-d"
    }
  })
end

if not blocked("planner-menu") then
  data:extend({
    {
      type = "int-setting",
      name = "exteros-qol-planner-menu-columns",
      setting_type = "runtime-per-user",
      default_value = 8,
      minimum_value = 4,
      maximum_value = 16,
      order = "b-pm-a"
    }
  })
end

if not blocked("belt-visualizer") then
  data:extend({
    {
      type = "int-setting",
      name = "exteros-qol-belt-visualizer-max-per-tick",
      setting_type = "runtime-per-user",
      default_value = 64,
      minimum_value = 1,
      maximum_value = 1000,
      order = "b-bv-a"
    },
    {
      type = "int-setting",
      name = "exteros-qol-belt-visualizer-max-entities",
      setting_type = "runtime-per-user",
      default_value = 10000,
      minimum_value = 10,
      maximum_value = 100000,
      order = "b-bv-b"
    }
  })
end

if not blocked("rate-calculator") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-rcalc-dismiss-tool-on-selection",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-rcalc-a"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-rcalc-show-calculation-errors",
      setting_type = "runtime-per-user",
      default_value = true,
      order = "b-rcalc-b"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-rcalc-show-power-consumption",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-rcalc-c"
    },
    {
      type = "string-setting",
      name = "exteros-qol-rcalc-default-gui-location",
      setting_type = "runtime-per-user",
      default_value = "top-left",
      allowed_values = { "top-left", "center" },
      order = "b-rcalc-d"
    },
    {
      type = "string-setting",
      name = "exteros-qol-rcalc-default-timescale",
      setting_type = "runtime-per-user",
      default_value = "per-second",
      allowed_values = { "per-second", "per-minute", "per-10-minutes", "per-hour", "transport-belts", "inserters" },
      order = "b-rcalc-e"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-rcalc-show-completion-checkboxes",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-rcalc-f"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-rcalc-show-intermediate-breakdowns",
      setting_type = "runtime-per-user",
      default_value = true,
      order = "b-rcalc-g"
    },
    {
      type = "bool-setting",
      name = "exteros-qol-rcalc-show-pollution",
      setting_type = "runtime-per-user",
      default_value = false,
      order = "b-rcalc-h"
    }
  })
end

local COLOR_PALETTE_NAMES = {
  "default", "custom", "white", "black", "grey", "red", "orange", "yellow",
  "green", "cyan", "blue", "purple", "pink", "brown"
}

data:extend({
  {
    type = "string-setting",
    name = "exteros-qol-character-color",
    setting_type = "runtime-per-user",
    allowed_values = COLOR_PALETTE_NAMES,
    default_value = "default",
    order = "b-l"
  },
  {
    type = "string-setting",
    name = "exteros-qol-character-color-hex",
    setting_type = "runtime-per-user",
    default_value = "",
    allow_blank = true,
    order = "b-m"
  },
  {
    type = "string-setting",
    name = "exteros-qol-chat-color",
    setting_type = "runtime-per-user",
    allowed_values = COLOR_PALETTE_NAMES,
    default_value = "default",
    order = "b-n"
  },
  {
    type = "string-setting",
    name = "exteros-qol-chat-color-hex",
    setting_type = "runtime-per-user",
    default_value = "",
    allow_blank = true,
    order = "b-o"
  }
})

if not blocked("inventory-repair") then
  data:extend({
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
    }
  })
end

if not blocked("copy-chest") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-copy-chest-between-surfaces",
      setting_type = "runtime-global",
      default_value = false,
      order = "b-k"
    }
  })
end

data:extend({
  {
    type = "bool-setting",
    name = "exteros-qol-debug",
    setting_type = "startup",
    default_value = false,
    hidden = true,
    order = "z-z"
  }
})

if feature_flags.quality and not blocked("quality-scroll") then
  data:extend({
    {
      type = "bool-setting",
      name = "exteros-qol-quality-scroll-enabled",
      setting_type = "startup",
      default_value = false,
      order = "a-f4"
    }
  })
end
