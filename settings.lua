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
    },
    {
      type = "bool-setting",
      name = "exteros-qol-ghost-builder-pickup",
      setting_type = "runtime-per-user",
      default_value = true,
      order = "b-gb-e"
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
