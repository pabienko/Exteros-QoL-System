local M = {}

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"].value then
    log("[Auto-Alt] " .. msg)
  end
end

local function enable_alt_mode(player)
  if not settings.startup["exteros-qol-auto-alt-enabled"].value then return end
  if not player or not player.valid then return end
  player.game_view_settings.show_entity_info = true
  debug_log("Alt mode enabled for " .. player.name)
end

local function on_first_tick()
  script.on_nth_tick(1, nil)
  if not settings.startup["exteros-qol-auto-alt-enabled"].value then return end
  debug_log("First tick - enabling alt mode for all connected players")
  for _, player in pairs(game.connected_players) do
    enable_alt_mode(player)
  end
end

function M.on_player_joined_game(event)
  local player = game.get_player(event.player_index)
  debug_log("Player joined: " .. (player and player.name or "nil"))
  enable_alt_mode(player)
end

script.on_event(defines.events.on_player_joined_game, M.on_player_joined_game)
script.on_init(function()
  script.on_nth_tick(1, on_first_tick)
end)
script.on_load(function()
  script.on_nth_tick(1, on_first_tick)
end)

return M
