local core = require("core.init")

local M = {}

local PLAYER_SETTING = "exteros-qol-auto-alt-player"

local function enable_alt_mode(player)
  if not settings.startup["exteros-qol-auto-alt-enabled"].value then return end
  if not player or not player.valid then return end
  if not settings.get_player_settings(player)[PLAYER_SETTING].value then return end
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

return M
