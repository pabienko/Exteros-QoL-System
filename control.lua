if not settings.startup["exteros-cs-enabled"].value then
  return
end


local function update_all_players_crafting_speed()
  local multiplier = settings.global["exteros-cs-multiplier"].value

  for _, player in pairs(game.players) do
    player.force.manual_crafting_speed_modifier = multiplier
  end
end

-- Událost, která se spustí, když se změní nastavení modu za běhu hry
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "exteros-cs-multiplier" then
    update_all_players_crafting_speed()
  end
end)

-- Zajistíme, aby se rychlost správně nastavila i při načtení hry a připojení nového hráče
script.on_load(update_all_players_crafting_speed)
script.on_event(defines.events.on_player_created, update_all_players_crafting_speed)