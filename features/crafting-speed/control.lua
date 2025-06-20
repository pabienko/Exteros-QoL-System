local function update_all_players_crafting_speed()

  local modifier = settings.global["crafting-speed-multiplier"].value

  for _, player in pairs(game.players) do
    player.force.manual_crafting_speed_modifier = modifier
  end
end

script.on_configuration_changed(function()
    update_all_players_crafting_speed()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "crafting-speed-multiplier" then
    update_all_players_crafting_speed()
  end
end)

script.on_event(defines.events.on_player_created, update_all_players_crafting_speed)