local core = require("core.init")

local M = {}

---@type table<string, number>
local ANIMATION_SCALE = {
  small = 0.06,
  medium = 0.1,
  large = 0.16,
}

---@type table<string, number>
local LIGHT_SIZE = {
  small = 1,
  medium = 1.5,
  large = 2.2,
}

local LIGHT_INTENSITY = 0.3
local LIGHT_MARGIN = 0.15

---@type string[]
local CRAFTING_MACHINE_TYPES = { "assembling-machine", "furnace", "rocket-silo" }

---@param setting_name string
---@param default string
---@return Color
local function setting_color(setting_name, default)
  local setting = settings.startup[setting_name]
  local value = setting and setting.value
  return core.color.parse_hex(value --[[@as string?]], core.color.parse_hex(default, { r = 1, g = 1, b = 1, a = 1 }))
end

---@return table
local function build_status_colors()
  local working = setting_color("exteros-qol-bottleneck-color-working", "#00FF00")
  local full_output = setting_color("exteros-qol-bottleneck-color-full-output", "#FFFF00")
  local stopped = setting_color("exteros-qol-bottleneck-color-stopped", "#FF0000")
  local low_power = setting_color("exteros-qol-bottleneck-color-low-power", "#FF8000")

  return {
    working = working,
    full_output = full_output,
    idle = stopped,
    disabled = stopped,
    no_minable_resources = stopped,
    insufficient_input = stopped,
    low_power = low_power,
    no_power = low_power,
  }
end

---@param prototype table
---@return QolPosition?
local function light_offset(prototype)
  local box = prototype.collision_box or prototype.selection_box
  if not box then return nil end

  local explicit = core.box.ensure_explicit(box)
  local half_width = (explicit.right_bottom.x - explicit.left_top.x) / 2
  local half_height = (explicit.right_bottom.y - explicit.left_top.y) / 2
  if half_width <= 0 or half_height <= 0 then return nil end

  return {
    x = -half_width + math.min(LIGHT_MARGIN, half_width),
    y = -half_height + math.min(LIGHT_MARGIN, half_height),
  }
end

---@param offset QolPosition
---@param quarter_turns integer
---@return QolPosition
local function rotate_offset(offset, quarter_turns)
  local x, y = offset.x, offset.y
  for _ = 1, quarter_turns do
    x, y = -y, x
  end
  return { x = x, y = y }
end

---@param prototype table
---@param size string
---@param glow boolean
---@return table?
local function build_working_visualisation(prototype, size, glow)
  local offset = light_offset(prototype)
  if not offset then return nil end

  local scale = ANIMATION_SCALE[size] or ANIMATION_SCALE.medium

  ---@type table
  local visualisation = {
    apply_tint = "status",
    always_draw = true,
    north_position = offset,
    east_position = rotate_offset(offset, 1),
    south_position = rotate_offset(offset, 2),
    west_position = rotate_offset(offset, 3),
    animation = {
      filename = "__core__/graphics/light-small.png",
      width = 150,
      height = 150,
      scale = scale,
      tint = { r = 1, g = 1, b = 1, a = 1 },
      draw_as_glow = false,
    },
  }

  if glow then
    visualisation.light = {
      intensity = LIGHT_INTENSITY,
      size = LIGHT_SIZE[size] or LIGHT_SIZE.medium,
      color = { r = 1, g = 1, b = 1 },
      minimum_darkness = 0.0,
    }
  end

  return visualisation
end

---@param prototype table
---@param size string
---@param glow boolean
---@param status_colors table
---@param override boolean
local function apply_to_prototype(prototype, size, glow, status_colors, override)
  if type(prototype) ~= "table" then return end
  local graphics_set = prototype.graphics_set
  if type(graphics_set) ~= "table" then return end

  if graphics_set.status_colors ~= nil and not override then return end

  local visualisation = build_working_visualisation(prototype, size, glow)
  if not visualisation then return end

  graphics_set.status_colors = status_colors
  graphics_set.working_visualisations = graphics_set.working_visualisations or {}
  table.insert(graphics_set.working_visualisations, visualisation)
end

function M.apply()
  local enabled_setting = settings.startup["exteros-qol-bottleneck-enabled"]
  if enabled_setting == nil or enabled_setting.value ~= true then return end

  local size = settings.startup["exteros-qol-bottleneck-size"].value --[[@as string]]
  local glow = settings.startup["exteros-qol-bottleneck-glow"].value == true
  local override = settings.startup["exteros-qol-bottleneck-override"].value == true
  local include_drills = settings.startup["exteros-qol-bottleneck-mining-drills"].value == true

  local status_colors = build_status_colors()

  for _, entity_type in ipairs(CRAFTING_MACHINE_TYPES) do
    for _, prototype in pairs(data.raw[entity_type] or {}) do
      apply_to_prototype(prototype, size, glow, status_colors, override)
    end
  end

  if include_drills then
    for _, prototype in pairs(data.raw["mining-drill"] or {}) do
      apply_to_prototype(prototype, size, glow, status_colors, override)
    end
  end
end

return M
