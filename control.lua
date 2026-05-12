require("core.init")

local modules = {
  require("features.cheats.control"),
  require("features.even-distribution.control"),
  require("features.auto-alt-mode.control"),
  require("features.auto-deconstruct.control"),
  require("features.inventory-repair.control"),
  require("features.time-controls.control"),
  require("features.inventory-sort.control"),
  require("features.item-count.control"),
  require("features.searchlight.control"),
  require("hub.control"),
}

local function dispatch(callback_name, event)
  for _, module in ipairs(modules) do
    local callback = module[callback_name]
    if callback then
      callback(event)
    end
  end
end

script.on_init(function()
  dispatch("init")
end)

script.on_load(function()
  dispatch("on_load")
end)

script.on_configuration_changed(function(event)
  dispatch("on_configuration_changed", event)
end)

local event_handlers = {
  [defines.events.on_tick] = "on_tick",
  [defines.events.on_selected_entity_changed] = "on_selected_entity_changed",
  [defines.events.on_player_cursor_stack_changed] = "on_player_cursor_stack_changed",
  [defines.events.on_runtime_mod_setting_changed] = "on_runtime_mod_setting_changed",
  [defines.events.on_gui_click] = "on_gui_click",
  [defines.events.on_player_joined_game] = "on_player_joined_game",
  [defines.events.on_player_created] = "on_player_created",
  [defines.events.on_resource_depleted] = "on_resource_depleted",
  [defines.events.on_player_fast_transferred] = "on_player_fast_transferred",
  [defines.events.on_player_driving_changed_state] = "on_player_driving_changed_state",
  [defines.events.on_player_main_inventory_changed] = "on_player_main_inventory_changed",
  [defines.events.on_player_ammo_inventory_changed] = "on_player_ammo_inventory_changed",
  [defines.events.on_player_respawned] = "on_player_respawned",
  [defines.events.on_gui_opened] = "on_gui_opened",
  [defines.events.on_gui_closed] = "on_gui_closed",
  [defines.events.on_gui_checked_state_changed] = "on_gui_checked_state_changed",
  [defines.events.on_gui_value_changed] = "on_gui_value_changed",
  [defines.events.on_gui_confirmed] = "on_gui_confirmed",
  [defines.events.on_gui_selection_state_changed] = "on_gui_selection_state_changed",
}

for event_id, callback_name in pairs(event_handlers) do
  local name = callback_name
  script.on_event(event_id, function(event)
    dispatch(name, event)
  end)
end

local custom_inputs = {
  ["exteros-qol-open-hub"] = "on_open_hub",
  ["exteros-qol-speed-up"] = "on_speed_up",
  ["exteros-qol-speed-down"] = "on_speed_down",
  ["exteros-qol-speed-reset"] = "on_speed_reset",
  ["exteros-qol-speed-pause"] = "on_speed_pause",
  ["exteros-qol-manual-inventory-sort"] = "on_manual_inventory_sort",
}

for input_name, callback_name in pairs(custom_inputs) do
  local name = callback_name
  script.on_event(input_name, function(event)
    dispatch(name, event)
  end)
end
