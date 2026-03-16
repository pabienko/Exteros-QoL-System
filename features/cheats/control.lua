local core = require("core.init")
local M = {}

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"].value then
    log("[Cheats] " .. msg)
  end
end

local function update_all_cheats(player)
  if not core.validation.is_player_valid(player) then return end
  if not settings.startup["exteros-qol-cheat-mode-enabled"].value then return end

  debug_log("Updating all cheats for " .. player.name)
  local p_settings = settings.get_player_settings(player)
  
  if not player.character then 
    debug_log("Player " .. player.name .. " has no character, skipping.")
    return 
  end

  local reach = math.min(300, p_settings["cheat-reach-distance"].value)
  player.character_reach_distance_bonus = reach
  player.character_build_distance_bonus = reach
  player.character_item_drop_distance_bonus = reach
  player.character_item_pickup_distance_bonus = reach
  player.character_loot_pickup_distance_bonus = reach
  player.character_resource_reach_distance_bonus = reach

  player.character_crafting_speed_modifier = p_settings["cheat-crafting-speed"].value
  player.character_mining_speed_modifier = p_settings["cheat-mining-speed"].value
  player.character_inventory_slots_bonus = p_settings["cheat-inventory-bonus"].value
end

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if not settings.startup["exteros-qol-cheat-mode-enabled"].value then return end
  
  local player = game.get_player(event.player_index)
  if player then
    update_all_cheats(player)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  update_all_cheats(game.get_player(event.player_index))
end)

script.on_configuration_changed(function()
  if not settings.startup["exteros-qol-cheat-mode-enabled"].value then return end
  for _, player in pairs(game.players) do
    update_all_cheats(player)
  end
end)

return M