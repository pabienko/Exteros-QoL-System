local legacy = require("core.legacy-cheats")
local M = {}

local ADDON = "Exteros-QoL-Cheats"

function M.init()
  storage.legacy_cheats_cleaned = true
end

---@param player_index uint
local function clean_player(player_index)
  local player = game.get_player(player_index)
  if not player or not player.valid or not player.character then return false end

  legacy.reset_if_applied(player)
  return true
end

local function finish_if_done()
  if not storage.legacy_cheats_pending or not next(storage.legacy_cheats_pending) then
    storage.legacy_cheats_cleaned = true
    storage.legacy_cheats_pending = nil
  end
end

function M.on_configuration_changed()
  if storage.legacy_cheats_cleaned then return end

  if script.active_mods[ADDON] then
    storage.legacy_cheats_cleaned = true
    return
  end

  storage.legacy_cheats_pending = storage.legacy_cheats_pending or {}

  for _, player in pairs(game.players) do
    if clean_player(player.index) then
      storage.legacy_cheats_pending[player.index] = nil
    else
      storage.legacy_cheats_pending[player.index] = true
    end
  end

  finish_if_done()
end

---@param event EventData.on_player_joined_game
function M.on_player_joined_game(event)
  if storage.legacy_cheats_cleaned then return end
  if not storage.legacy_cheats_pending or not storage.legacy_cheats_pending[event.player_index] then return end

  if clean_player(event.player_index) then
    storage.legacy_cheats_pending[event.player_index] = nil
  end

  finish_if_done()
end

---@param event EventData.on_player_removed
function M.on_player_removed(event)
  if storage.legacy_cheats_pending then
    storage.legacy_cheats_pending[event.player_index] = nil
    finish_if_done()
  end
end

return M
