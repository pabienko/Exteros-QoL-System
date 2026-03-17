local atan2, pi, floor = math.atan2, math.pi, math.floor

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

  local ppos, spos = player.position, player.selected.position
  local dx = ppos.x - spos.x
  local dy = spos.y - ppos.y
  local orientation = (atan2(dx, dy) / pi + 1) / 2
  character.direction = floor(orientation * 16 + 0.5) % 16
  set_last_tick(event.player_index, game.tick)
end

script.on_init(function()
  storage.searchlight_last_tick = storage.searchlight_last_tick or {}
end)

script.on_configuration_changed(function()
  storage.searchlight_last_tick = storage.searchlight_last_tick or {}
end)

script.on_event(defines.events.on_selected_entity_changed, orient_player)
