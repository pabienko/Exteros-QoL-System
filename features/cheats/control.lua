local M = {}

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"] and settings.startup["exteros-qol-debug"].value then
    log("[Cheats] " .. msg)
  end
end

local function update_all_cheats(player)
  if not player or not player.valid then return end
  if not settings.startup["exteros-qol-cheat-mode-enabled"].value then return end

  debug_log("Updating all cheats for " .. player.name)
  local p_settings = settings.get_player_settings(player)
  if not p_settings then return end

  local reach_setting = p_settings["cheat-reach-distance"]
  local crafting_setting = p_settings["cheat-crafting-speed"]
  local mining_setting = p_settings["cheat-mining-speed"]
  local inv_setting = p_settings["cheat-inventory-bonus"]
  if not reach_setting or not crafting_setting or not mining_setting or not inv_setting then return end

  if not player.character then
    debug_log("Player " .. player.name .. " has no character, skipping.")
    return
  end

  local reach = math.min(300, reach_setting.value)
  player.character_reach_distance_bonus = reach
  player.character_build_distance_bonus = reach
  player.character_item_drop_distance_bonus = reach
  player.character_item_pickup_distance_bonus = reach
  player.character_loot_pickup_distance_bonus = reach
  player.character_resource_reach_distance_bonus = reach

  player.character_crafting_speed_modifier = crafting_setting.value
  player.character_mining_speed_modifier = mining_setting.value
  player.character_inventory_slots_bonus = inv_setting.value
end

function M.apply_to_player(player)
  update_all_cheats(player)
end

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if not settings.startup["exteros-qol-cheat-mode-enabled"].value then return end

  local player = event.player_index and game.get_player(event.player_index)
  if player then
    update_all_cheats(player)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  update_all_cheats(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player_index = event.player_index
  update_all_cheats(game.get_player(player_index))
  
  local tick = game.tick + 1
  script.on_nth_tick(tick, function()
    script.on_nth_tick(tick, nil)
    update_all_cheats(game.get_player(player_index))
  end)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  update_all_cheats(game.get_player(event.player_index))
end)

script.on_configuration_changed(function()
  if not settings.startup["exteros-qol-cheat-mode-enabled"].value then return end
  for _, player in pairs(game.players) do
    update_all_cheats(player)
  end
end)

return M
