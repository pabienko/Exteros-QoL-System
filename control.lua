local function update_all_players_crafting_speed()
  if settings.startup["exteros-cs-enabled"].value == true then
    local modifier = settings.global["exteros-cs-multiplier"].value

    for _, player in pairs(game.players) do
      player.force.manual_crafting_speed_modifier = modifier
    end
  end
end


script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "exteros-cs-multiplier" then
    update_all_players_crafting_speed()
  end
end)

script.on_event(defines.events.on_player_created, update_all_players_crafting_speed)