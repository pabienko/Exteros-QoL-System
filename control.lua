local core = require("core.init")

---@param feature string
---@return boolean
local function blocked(feature)
  return core.conflicts.is_blocked(feature, script.active_mods)
end

local modules = {
  require("features.cheats.control"),
  require("features.auto-alt-mode.control"),
  require("features.copy-chest.control"),
  require("features.planner-zapper.control"),
  require("hub.control"),
}

if not blocked("even-distribution") then
  table.insert(modules, require("features.even-distribution.control"))
end

if not blocked("auto-deconstruct") then
  table.insert(modules, require("features.auto-deconstruct.control"))
end

if not blocked("inventory-repair") then
  table.insert(modules, require("features.inventory-repair.control"))
end

if not blocked("time-controls") then
  table.insert(modules, require("features.time-controls.control"))
end

if not blocked("inventory-sort") then
  table.insert(modules, require("features.inventory-sort.control"))
end

if not blocked("item-count") then
  table.insert(modules, require("features.item-count.control"))
end

if not blocked("searchlight") then
  table.insert(modules, require("features.searchlight.control"))
end

if not blocked("force-insert") then
  table.insert(modules, require("features.force-insert.control"))
end

if not blocked("wire-shortcuts") then
  table.insert(modules, require("features.wire-shortcuts.control"))
end

if script.feature_flags.quality then
  table.insert(modules, require("features.quality-scroll.control"))
end

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
  [defines.events.on_player_dropped_item] = "on_player_dropped_item",
}

for event_id, callback_name in pairs(event_handlers) do
  local name = callback_name
  script.on_event(event_id, function(event)
    dispatch(name, event)
  end)
end

local custom_inputs = {
  ["exteros-qol-open-hub"] = "on_open_hub",
  ["exteros-qol-copy-chest"] = "on_copy_chest",
  ["exteros-qol-paste-chest"] = "on_paste_chest",
}

if not blocked("inventory-sort") then
  custom_inputs["exteros-qol-manual-inventory-sort"] = "on_manual_inventory_sort"
end

if not blocked("time-controls") then
  custom_inputs["exteros-qol-speed-up"] = "on_speed_up"
  custom_inputs["exteros-qol-speed-down"] = "on_speed_down"
  custom_inputs["exteros-qol-speed-reset"] = "on_speed_reset"
  custom_inputs["exteros-qol-speed-pause"] = "on_speed_pause"
end

if not blocked("force-insert") then
  custom_inputs["exteros-qol-force-insert-fast-entity-transfer"] = "on_force_insert_entity"
  custom_inputs["exteros-qol-force-insert-fast-entity-split"] = "on_force_insert_entity"
  custom_inputs["exteros-qol-force-insert-stack-transfer"] = "on_force_insert_gui"
  custom_inputs["exteros-qol-force-insert-stack-split"] = "on_force_insert_gui"
  custom_inputs["exteros-qol-force-insert-inventory-transfer"] = "on_force_insert_gui"
  custom_inputs["exteros-qol-force-insert-inventory-split"] = "on_force_insert_gui"
end

if not blocked("wire-shortcuts") then
  custom_inputs["exteros-qol-wire-cycle"] = "on_wire_cycle"
end

if script.feature_flags.quality then
  custom_inputs["exteros-qol-quality-cycle-next"] = "on_quality_cycle_next"
  custom_inputs["exteros-qol-quality-cycle-previous"] = "on_quality_cycle_previous"
end

for input_name, callback_name in pairs(custom_inputs) do
  local name = callback_name
  script.on_event(input_name, function(event)
    dispatch(name, event)
  end)
end
