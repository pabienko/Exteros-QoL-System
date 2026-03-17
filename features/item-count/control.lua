local GUI_NAME = "exteros_itemcount"

local function get_or_create_itemcount_gui(player)
  local center = player.gui.center
  if not center then return nil end

  local gui = center[GUI_NAME]
  if not gui then
    gui = center.add{ type = "label", name = GUI_NAME, caption = "0" }
    gui.style.font = "default-bold"
  end
  return gui
end

local function update_itemcount(player)

  local gui = get_or_create_itemcount_gui(player)
  if not gui then return end

  local enabled = settings.get_player_settings(player)["exteros-qol-item-count-enabled"].value
  local stack = player.cursor_stack.valid_for_read and player.cursor_stack or nil

  gui.visible = enabled and stack ~= nil

  if stack and (stack.prototype.stackable or stack.prototype.stack_size > 1) then
    local filter = { name = stack.name }
    if stack.quality then filter.quality = stack.quality end
    local inventory_count = player.get_item_count(filter)

    local vehicle_count = nil
    if player.vehicle then
      local trunk = player.vehicle.get_inventory(defines.inventory.car_trunk)
      if trunk then
        vehicle_count = trunk.get_item_count(stack.name)
      end
    end

    gui.caption = tostring(inventory_count)
    if vehicle_count and vehicle_count > 0 then
      gui.caption = gui.caption .. " (" .. vehicle_count .. ")"
    end
  else
    gui.caption = ""
  end
end

local function on_setting_changed(event)
  if event.setting ~= "exteros-qol-item-count-enabled" then return end

  local player = game.get_player(event.player_index)
  if not player or not player.valid then return end

  local gui = get_or_create_itemcount_gui(player)
  if gui then
    local enabled = settings.get_player_settings(player)["exteros-qol-item-count-enabled"].value
    gui.visible = enabled and player.cursor_stack.valid_for_read
  end
end

local function on_itemcount_event(e)
  local player = game.get_player(e.player_index)
  if player and player.valid then
    update_itemcount(player)
  end
end

script.on_event(defines.events.on_player_cursor_stack_changed, on_itemcount_event)
script.on_event(defines.events.on_player_driving_changed_state, on_itemcount_event)
script.on_event(defines.events.on_player_main_inventory_changed, on_itemcount_event)
script.on_event(defines.events.on_player_ammo_inventory_changed, on_itemcount_event)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_setting_changed)
