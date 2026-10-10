local mod_gui = require("mod-gui")
local core = require("core.init")
local M = {}

local function is_admin(player)
  return player ~= nil and player.valid and player.admin
end

---@param player LuaPlayer
---@return LuaGuiElement?
local function find_button_flow(player)
  local top = player.gui.top
  if top.mod_gui_button_flow then
    return top.mod_gui_button_flow
  end
  local frame = top.mod_gui_top_frame
  if frame then
    return frame.mod_gui_inner_frame
  end
  return nil
end

local function update_buttons()
  local speed = game.speed
  local number = speed ~= 1 and speed or nil

  for _, player in pairs(game.connected_players) do
    local flow = find_button_flow(player)
    local button = flow and flow.exteros_ptc_reset
    if button then
      button.number = number
    end
  end
end

function M.speed_up(player)
  if not is_admin(player) then return end
  core.debug.log("Speeding up... New speed will be " .. (game.speed * 2), "Time-Ctrl")
  game.speed = math.min(64, game.speed * 2)
  update_buttons()
end

function M.speed_down(player)
  if not is_admin(player) then return end
  core.debug.log("Speeding down... New speed will be " .. (game.speed / 2), "Time-Ctrl")
  game.speed = math.max(0.25, game.speed / 2)
  update_buttons()
end

function M.reset_speed(player)
  if not is_admin(player) then return end
  core.debug.log("Resetting speed to 1.0", "Time-Ctrl")
  game.speed = 1
  update_buttons()
end

function M.toggle_pause(player)
  if not is_admin(player) then return end
  core.debug.log("Toggling pause. Previous state: " .. tostring(game.tick_paused), "Time-Ctrl")
  game.tick_paused = not game.tick_paused
end

local function destroy_gui(player)
  if not player or not player.valid then return end
  local flow = find_button_flow(player)
  if not flow then return end
  if flow.exteros_ptc_down then flow.exteros_ptc_down.destroy() end
  if flow.exteros_ptc_reset then flow.exteros_ptc_reset.destroy() end
  if flow.exteros_ptc_up then flow.exteros_ptc_up.destroy() end
end

local function setup_gui(player)
  if not player or not player.valid then return end
  if not settings.startup["exteros-qol-time-controls-enabled"].value then
    return
  end

  if not is_admin(player) then
    destroy_gui(player)
    return
  end

  local flow = mod_gui.get_button_flow(player)
  if flow.exteros_ptc_up then
    return
  end

  core.debug.log("Creating GUI for " .. player.name, "Time-Ctrl")

  flow.add{
    type = "sprite-button",
    name = "exteros_ptc_down",
    style = "slot_sized_button",
    sprite = "utility/speed_down",
    tooltip = {"exteros-qol-gui.speed-down"}
  }

  flow.add{
    type = "sprite-button",
    name = "exteros_ptc_reset",
    style = "slot_sized_button",
    sprite = "utility/reset",
    tooltip = {"exteros-qol-gui.speed-reset"}
  }.number = (game.speed ~= 1 and game.speed or nil)

  flow.add{
    type = "sprite-button",
    name = "exteros_ptc_up",
    style = "slot_sized_button",
    sprite = "utility/speed_up",
    tooltip = {"exteros-qol-gui.speed-up"}
  }
end

local function refresh_gui_all()
  for _, player in pairs(game.players) do
    destroy_gui(player)
    setup_gui(player)
  end
end

function M.init()
  refresh_gui_all()
end

function M.on_configuration_changed()
  refresh_gui_all()
end

function M.on_player_created(e)
  setup_gui(game.get_player(e.player_index))
end

function M.on_player_joined_game(e)
  setup_gui(game.get_player(e.player_index))
end

function M.on_player_promoted(e)
  setup_gui(game.get_player(e.player_index))
end

function M.on_player_demoted(e)
  destroy_gui(game.get_player(e.player_index))
end

function M.on_gui_click(e)
  if not e.element or not e.element.valid then return end
  local player = game.get_player(e.player_index)
  if e.element.name == "exteros_ptc_up" then
    M.speed_up(player)
  elseif e.element.name == "exteros_ptc_down" then
    M.speed_down(player)
  elseif e.element.name == "exteros_ptc_reset" then
    M.reset_speed(player)
  end
end

function M.on_speed_up(e)
  M.speed_up(game.get_player(e.player_index))
end

function M.on_speed_down(e)
  M.speed_down(game.get_player(e.player_index))
end

function M.on_speed_reset(e)
  M.reset_speed(game.get_player(e.player_index))
end

function M.on_speed_pause(e)
  M.toggle_pause(game.get_player(e.player_index))
end

return M
