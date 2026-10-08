local core = require("core.init")

local atan2, pi, floor = math.atan2, math.pi, math.floor
local M = {}

local FEATURE_SETTING = "exteros-qol-searchlight-feature-enabled"
local OPT_IN_SETTING = "exteros-qol-searchlight-custom-flashlight"
local SCALE_SETTING = "exteros-qol-searchlight-flashlight-scale"
local INTENSITY_SETTING = "exteros-qol-searchlight-flashlight-intensity"
local COLOR_SETTING = "exteros-qol-searchlight-flashlight-color"
local SETTING_PREFIX = "exteros-qol-searchlight-flashlight-"

local WHITE = { r = 1, g = 1, b = 1, a = 1 }
local CONE_SPRITE = "utility/light_cone"
local CIRCLE_SPRITE = "utility/light_medium"

local CONE_BASE_SCALE = 4
local CONE_BASE_SHIFT = { 0, -13 }
local CONE_BASE_INTENSITY = 0.6
local CIRCLE_BASE_SCALE = 5.33
local CIRCLE_BASE_INTENSITY = 0.4
local INTENSITY_CAP = 1

---@return boolean
local function feature_enabled()
  local setting = settings.startup[FEATURE_SETTING]
  return setting ~= nil and setting.value == true
end

local function get_storage()
  storage.searchlight_last_tick = storage.searchlight_last_tick or {}
  return storage.searchlight_last_tick
end

local function get_last_tick(player_index)
  local data = get_storage()
  return data[player_index] or 0
end

local function set_last_tick(player_index, tick)
  get_storage()[player_index] = tick
end

local function orient_player(event)
  if not feature_enabled() then return end

  local player = game.get_player(event.player_index)
  if not player or not player.valid then return end

  local character = player.character
  if not character then return end

  local last_tick = get_last_tick(event.player_index)
  if last_tick > (game.tick - 10) then return end

  if not player.selected then return end
  if player.vehicle then return end
  if player.walking_state.walking then return end

  if not settings.get_player_settings(player)["exteros-qol-searchlight-enabled"].value then
    return
  end

  local ppos = core.position.ensure_explicit(player.position)
  local spos = core.position.ensure_explicit(player.selected.position)
  local dx = ppos.x - spos.x
  local dy = spos.y - ppos.y
  local orientation = (atan2(dx, dy) / pi + 1) / 2
  local dir = floor(orientation * 16 + 0.5) % 16
  character.direction = dir --[[@as defines.direction]]
  set_last_tick(event.player_index, game.tick)
end

---@return table<uint, { cone: LuaRenderObject, circle: LuaRenderObject, base_offset: number[], last_orientation: number }>
local function get_render_storage()
  storage.searchlight_flashlight = storage.searchlight_flashlight or {}
  return storage.searchlight_flashlight
end

---@param player LuaPlayer
---@return { scale: number, intensity: number, color: Color, is_vanilla: boolean }
local function read_flashlight_settings(player)
  local player_settings = settings.get_player_settings(player)
  local opt_in = player_settings[OPT_IN_SETTING].value == true
  local scale = player_settings[SCALE_SETTING].value --[[@as number]]
  local intensity = player_settings[INTENSITY_SETTING].value --[[@as number]]
  local color_hex = player_settings[COLOR_SETTING].value --[[@as string]]

  local color = WHITE
  if color_hex ~= "" then
    color = core.color.parse_hex(color_hex, WHITE)
  end

  return {
    scale = scale,
    intensity = intensity,
    color = color,
    is_vanilla = not opt_in or (scale == 1 and intensity == 1 and color_hex == ""),
  }
end

---@param player_index uint
local function clear_flashlight_render(player_index)
  local render = get_render_storage()[player_index]
  if render then
    if render.cone and render.cone.valid then render.cone.destroy() end
    if render.circle and render.circle.valid then render.circle.destroy() end
  end
  get_render_storage()[player_index] = nil
end

---@param player LuaPlayer
local function restore_vanilla_flashlight(player)
  clear_flashlight_render(player.index)
  if player.controller_type == defines.controllers.character and player.character then
    pcall(function() player.enable_flashlight() end)
  end
end

---@param vector number[]
---@param orientation number
---@return number[]
local function rotate_offset(vector, orientation)
  local theta = orientation * 2 * pi
  local cos_t, sin_t = math.cos(theta), math.sin(theta)
  local x, y = vector[1] or 0, vector[2] or 0
  return { x * cos_t - y * sin_t, x * sin_t + y * cos_t }
end

---@param player LuaPlayer
local function apply_flashlight(player)
  if not core.validation.is_player_valid(player) then return end

  if not feature_enabled() then
    restore_vanilla_flashlight(player)
    return
  end

  local flashlight = read_flashlight_settings(player)
  if flashlight.is_vanilla then
    restore_vanilla_flashlight(player)
    return
  end

  local character = player.character
  if player.controller_type ~= defines.controllers.character or not character or player.vehicle then
    clear_flashlight_render(player.index)
    return
  end

  pcall(function() player.disable_flashlight() end)
  clear_flashlight_render(player.index)

  local base_offset = { CONE_BASE_SHIFT[1] * flashlight.scale, CONE_BASE_SHIFT[2] * flashlight.scale }
  local orientation = character.orientation or 0

  local cone = rendering.draw_light({
    sprite = CONE_SPRITE,
    target = { entity = character, offset = rotate_offset(base_offset, orientation) },
    oriented = true,
    scale = CONE_BASE_SCALE * flashlight.scale,
    intensity = math.min(CONE_BASE_INTENSITY * flashlight.intensity, INTENSITY_CAP),
    color = flashlight.color,
    surface = character.surface,
    players = { player },
  })

  local circle = rendering.draw_light({
    sprite = CIRCLE_SPRITE,
    target = character,
    scale = CIRCLE_BASE_SCALE * flashlight.scale,
    intensity = math.min(CIRCLE_BASE_INTENSITY * flashlight.intensity, INTENSITY_CAP),
    color = flashlight.color,
    surface = character.surface,
    players = { player },
  })

  get_render_storage()[player.index] = {
    cone = cone,
    circle = circle,
    base_offset = base_offset,
    last_orientation = orientation,
  }
end

M.on_selected_entity_changed = orient_player

function M.on_tick()
  local store = storage.searchlight_flashlight
  if not store or not next(store) then return end

  for player_index, render in pairs(store) do
    local player = game.get_player(player_index)
    if core.validation.is_player_valid(player) and render.cone and render.cone.valid then
      ---@cast player LuaPlayer
      local character = player.character
      if character and character.valid then
        local orientation = character.orientation or 0
        if orientation ~= render.last_orientation then
          render.cone.target = { entity = character, offset = rotate_offset(render.base_offset, orientation) }
          render.last_orientation = orientation
        end
      end
    end
  end
end

---@param event EventData.on_runtime_mod_setting_changed
function M.on_runtime_mod_setting_changed(event)
  local is_flashlight_setting = event.setting:sub(1, #SETTING_PREFIX) == SETTING_PREFIX
    or event.setting == OPT_IN_SETTING
  if not is_flashlight_setting then return end
  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  apply_flashlight(player)
end

---@param event EventData.on_player_created
function M.on_player_created(event)
  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  apply_flashlight(player)
end

---@param event EventData.on_player_respawned
function M.on_player_respawned(event)
  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  apply_flashlight(player)
end

---@param event EventData.on_player_driving_changed_state
function M.on_player_driving_changed_state(event)
  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  apply_flashlight(player)
end

---@param event EventData.on_player_controller_changed
function M.on_player_controller_changed(event)
  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  apply_flashlight(player)
end

---@param event EventData.on_player_changed_surface
function M.on_player_changed_surface(event)
  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  apply_flashlight(player)
end

---@param event EventData.on_cutscene_cancelled
function M.on_cutscene_cancelled(event)
  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  apply_flashlight(player)
end

---@param event EventData.on_cutscene_finished
function M.on_cutscene_finished(event)
  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  apply_flashlight(player)
end

---@param event EventData.on_player_removed
function M.on_player_removed(event)
  clear_flashlight_render(event.player_index)
end

function M.init()
  storage.searchlight_last_tick = storage.searchlight_last_tick or {}
  get_render_storage()
end

function M.on_configuration_changed()
  storage.searchlight_last_tick = storage.searchlight_last_tick or {}
  get_render_storage()
  for _, player in pairs(game.players) do
    restore_vanilla_flashlight(player)
  end
end

return M
