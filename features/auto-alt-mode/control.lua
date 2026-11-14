local core = require("core.init")
local values = require("__exteros-lib__.internal.values")

local M = {}

local PLAYER_SETTING = "exteros-qol-auto-alt-mode-player"

local function enable_alt_mode(player)
  if not player or not player.valid then return end
  if not values.get_player(player, PLAYER_SETTING) then return end
  player.game_view_settings.show_entity_info = true
  core.debug.log("Alt mode enabled for " .. player.name, "Auto-Alt")
end

function M.on_player_joined_game(event)
  local player = game.get_player(event.player_index)
  core.debug.log("Player joined: " .. (player and player.name or "nil"), "Auto-Alt")
  enable_alt_mode(player)
end

function M.on_player_created(event)
  local player = game.get_player(event.player_index)
  core.debug.log("Player created: " .. (player and player.name or "nil"), "Auto-Alt")
  enable_alt_mode(player)
end

---@param event EventData.on_cutscene_cancelled
function M.on_cutscene_cancelled(event)
  local player = game.get_player(event.player_index)
  core.debug.log("Cutscene cancelled for " .. (player and player.name or "nil"), "Auto-Alt")
  enable_alt_mode(player)
end

---@param event EventData.on_cutscene_finished
function M.on_cutscene_finished(event)
  local player = game.get_player(event.player_index)
  core.debug.log("Cutscene finished for " .. (player and player.name or "nil"), "Auto-Alt")
  enable_alt_mode(player)
end

function M.on_enable()
  for _, player in pairs(game.players) do
    enable_alt_mode(player)
  end
end

M.events = {
  [defines.events.on_player_joined_game] = M.on_player_joined_game,
  [defines.events.on_player_created] = M.on_player_created,
  [defines.events.on_cutscene_cancelled] = M.on_cutscene_cancelled,
  [defines.events.on_cutscene_finished] = M.on_cutscene_finished,
}

return M
