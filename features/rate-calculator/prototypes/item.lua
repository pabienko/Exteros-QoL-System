-- adapted from Rate Calculator by raiguard (MIT, © 2020-2023 Caleb Heuer)

local type_filters = {
  "accumulator",
  "ammo-turret",
  "arithmetic-combinator",
  "artillery-turret",
  "assembling-machine",
  "beacon",
  "boiler",
  "burner-generator",
  "constant-combinator",
  "decider-combinator",
  "electric-energy-interface",
  "electric-turret",
  "fluid-turret",
  "furnace",
  "generator",
  "heat-interface",
  "inserter",
  "lab",
  "lamp",
  "loader",
  "loader-1x1",
  "locomotive",
  "mining-drill",
  "offshore-pump",
  "pipe",
  "pipe-to-ground",
  "programmable-speaker",
  "pump",
  "radar",
  "reactor",
  "roboport",
  "rocket-silo",
  "splitter",
  "solar-panel",
  "transport-belt",
  "turret",
  "underground-belt",
}

-- Space Age machines (B4): only registered when Space Age is active, so the selection tool does
-- not reference entity types that do not exist without the expansion.
if mods["space-age"] then
  table.insert(type_filters, "agricultural-tower")
  table.insert(type_filters, "asteroid-collector")
  table.insert(type_filters, "fusion-reactor")
  table.insert(type_filters, "fusion-generator")
  table.insert(type_filters, "thruster")
end

data:extend({
  {
    type = "selection-tool",
    name = "exteros-qol-rcalc-selection-tool",
    order = "d[tools]-r[rate-calculator]",
    icons = {
      { icon = "__Exteros-QoL-System__/graphics/rate-calculator/black.png", icon_size = 1, scale = 64 },
      { icon = "__Exteros-QoL-System__/graphics/rate-calculator/shortcut-x32-white.png", icon_size = 32, mipmap_count = 2 },
    },
    select = {
      border_color = { r = 1, g = 1 },
      mode = { "buildable-type", "friend" },
      cursor_box_type = "entity",
      entity_type_filters = type_filters,
    },
    alt_select = {
      border_color = { r = 1, g = 0.5 },
      mode = { "buildable-type", "friend" },
      cursor_box_type = "entity",
      entity_type_filters = type_filters,
    },
    reverse_select = {
      border_color = { r = 1 },
      mode = { "buildable-type", "friend" },
      cursor_box_type = "not-allowed",
      entity_type_filters = type_filters,
    },
    alt_reverse_select = {
      border_color = { r = 1 },
      mode = { "buildable-type", "friend" },
      cursor_box_type = "not-allowed",
      entity_type_filters = type_filters,
    },
    stack_size = 1,
    flags = { "only-in-cursor", "not-stackable", "spawnable" },
    hidden = true,
  },
  {
    type = "item",
    name = "exteros-qol-rcalc-power-dummy",
    icon = "__Exteros-QoL-System__/graphics/rate-calculator/power.png",
    icon_size = 64,
    stack_size = 1,
    hidden = true,
  },
  {
    type = "item",
    name = "exteros-qol-rcalc-heat-dummy",
    icon = "__core__/graphics/arrows/heat-exchange-indication.png",
    icon_size = 48,
    stack_size = 1,
    hidden = true,
  },
  {
    type = "item",
    name = "exteros-qol-rcalc-pollution-dummy",
    icon = "__Exteros-QoL-System__/graphics/rate-calculator/pollution.png",
    icon_size = 64,
    icon_mipmaps = 2,
    stack_size = 1,
    hidden = true,
  },
})
