local lib_position = require("__exteros-lib__.position")
local lib_storage = require("__exteros-lib__.storage")
local values = require("__exteros-lib__.internal.values")

local atan2, pi, floor = math.atan2, math.pi, math.floor
local M = {}

local searchlight_last_tick = lib_storage.player_table("searchlight_last_tick")

local function get_last_tick(player_index)
  return searchlight_last_tick.peek(player_index) or 0
end

local function set_last_tick(player_index, tick)
  searchlight_last_tick.set(player_index, tick)
end

local function orient_player(event)
  local player = game.get_player(event.player_index)
  if not player or not player.valid then return end

  local character = player.character
  if not character then return end

  local last_tick = get_last_tick(event.player_index)
  if last_tick > (game.tick - 10) then return end

  if not player.selected then return end
  if player.vehicle then return end
  if player.walking_state.walking then return end

  if not values.get_player(player, "exteros-qol-searchlight-player-enabled") then
    return
  end

  local ppos = lib_position.ensure_explicit(player.position)
  local spos = lib_position.ensure_explicit(player.selected.position)
  local dx = ppos.x - spos.x
  local dy = spos.y - ppos.y
  local orientation = (atan2(dx, dy) / pi + 1) / 2
  local dir = floor(orientation * 16 + 0.5) % 16
  character.direction = dir --[[@as defines.direction]]
  set_last_tick(event.player_index, game.tick)
end

M.on_selected_entity_changed = orient_player

M.events = {
  [defines.events.on_selected_entity_changed] = M.on_selected_entity_changed,
}

return M
