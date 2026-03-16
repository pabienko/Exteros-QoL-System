local mod_gui = require("mod-gui")
local M = {}

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"].value then
    log("[Time-Ctrl] " .. msg)
  end
end

local function update_buttons()
  local speed = game.speed
  local number = speed ~= 1 and speed or nil
  
  for _, player in pairs(game.connected_players) do
    local flow = mod_gui.get_button_flow(player)
    local button = flow.exteros_ptc_reset
    if button then
      button.number = number
    end
  end
end

function M.speed_up()
  debug_log("Speeding up... New speed will be " .. (game.speed * 2))
  game.speed = math.min(64, game.speed * 2)
  update_buttons()
end

function M.speed_down()
  debug_log("Speeding down... New speed will be " .. (game.speed / 2))
  game.speed = math.max(0.25, game.speed / 2)
  update_buttons()
end

function M.reset_speed()
  debug_log("Resetting speed to 1.0")
  game.speed = 1
  update_buttons()
end

function M.toggle_pause()
  debug_log("Toggling pause. Previous state: " .. tostring(game.tick_paused))
  game.tick_paused = not game.tick_paused
end

local function setup_gui(player)
  if not settings.startup["exteros-qol-time-controls-enabled"].value then 
    return 
  end
  
  local flow = mod_gui.get_button_flow(player)
  if flow.exteros_ptc_up then 
    return 
  end
  
  debug_log("Creating GUI for " .. player.name)
  
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

local function destroy_gui(player)
  local flow = mod_gui.get_button_flow(player)
  if flow.exteros_ptc_down then flow.exteros_ptc_down.destroy() end
  if flow.exteros_ptc_reset then flow.exteros_ptc_reset.destroy() end
  if flow.exteros_ptc_up then flow.exteros_ptc_up.destroy() end
end

local function refresh_gui_all()
  for _, player in pairs(game.players) do
    destroy_gui(player)
    setup_gui(player)
  end
end

script.on_init(refresh_gui_all)
script.on_configuration_changed(refresh_gui_all)

local session_refreshed = false
script.on_event(defines.events.on_tick, function(e)
  if not session_refreshed then
    session_refreshed = true
    refresh_gui_all()
  end
  
  if e.tick % 300 == 0 then
    for _, player in pairs(game.connected_players) do
      setup_gui(player)
    end
  end
end)

script.on_event(defines.events.on_player_created, function(e)
  setup_gui(game.get_player(e.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(e)
  setup_gui(game.get_player(e.player_index))
end)

script.on_event(defines.events.on_gui_click, function(e)
  if e.element.name == "exteros_ptc_up" then
    M.speed_up()
  elseif e.element.name == "exteros_ptc_down" then
    M.speed_down()
  elseif e.element.name == "exteros_ptc_reset" then
    M.reset_speed()
  end
end)

script.on_event("exteros-qol-speed-up", M.speed_up)
script.on_event("exteros-qol-speed-down", M.speed_down)
script.on_event("exteros-qol-speed-reset", M.reset_speed)
script.on_event("exteros-qol-speed-pause", M.toggle_pause)

return M