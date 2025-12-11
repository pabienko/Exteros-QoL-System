local function update_all_players_crafting_speed()
  local modifier = settings.global["crafting-speed-multiplier"].value

  -- manual_crafting_speed_modifier is per-force, not per-player
  -- Collect unique forces to avoid redundant assignments
  local forces_updated = {}
  for _, player in pairs(game.players) do
    local force = player.force
    if not forces_updated[force.index] then
      force.manual_crafting_speed_modifier = modifier
      forces_updated[force.index] = true
    end
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