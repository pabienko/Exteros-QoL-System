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

data:extend({
  {
    type = "bool-setting",
    name = "exteros-qol-auto-alt-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-e2"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-cheat-mode-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-g"
  }
})

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

data:extend({
  {
    type = "bool-setting",
    name = "exteros-qol-planner-zapper-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-f3"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-copy-chest-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-f5"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-player-colors-enabled",
    setting_type = "startup",
    default_value = false,
    order = "a-f7"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-hub-button-visible",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "b-0"
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

data:extend({
  {
    type = "bool-setting",
    name = "exteros-qol-copy-chest-between-surfaces",
    setting_type = "runtime-global",
    default_value = false,
    order = "b-k"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-cheat-productivity-unlocked",
    setting_type = "startup",
    default_value = false,
    order = "c-a"
  },
  {
    type = "int-setting",
    name = "exteros-qol-cheat-productivity-cap",
    setting_type = "startup",
    default_value = 300,
    minimum_value = 0,
    maximum_value = 1000000,
    order = "c-b"
  },
  {
    type = "string-setting",
    name = "exteros-qol-cheat-stack-size-mode",
    setting_type = "startup",
    default_value = "multiplier",
    allowed_values = {"multiplier", "absolute"},
    order = "c-c"
  },
  {
    type = "double-setting",
    name = "exteros-qol-cheat-stack-size-value",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 100000.0,
    order = "c-d"
  },
  {
    type = "int-setting",
    name = "cheat-reach-distance",
    setting_type = "runtime-per-user",
    default_value = 10,
    minimum_value = 0,
    maximum_value = 300,
    order = "c-e"
  },
  {
    type = "double-setting",
    name = "cheat-crafting-speed",
    setting_type = "runtime-per-user",
    default_value = 0.0,
    minimum_value = 0.0,
    maximum_value = 1000000.0,
    order = "c-f"
  },
  {
    type = "double-setting",
    name = "cheat-mining-speed",
    setting_type = "runtime-per-user",
    default_value = 0.0,
    minimum_value = 0.0,
    maximum_value = 1000000.0,
    order = "c-g"
  },
  {
    type = "int-setting",
    name = "cheat-inventory-bonus",
    setting_type = "runtime-per-user",
    default_value = 0,
    minimum_value = 0,
    maximum_value = 1000,
    order = "c-h"
  },
  {
    type = "bool-setting",
    name = "exteros-qol-debug",
    setting_type = "startup",
    default_value = false,
    hidden = true,
    order = "z-z"
  }
})

if feature_flags.quality then
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
