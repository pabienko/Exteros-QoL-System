local lib_player = require("__exteros-lib__.player")
local lib_format = require("__exteros-lib__.format")
local lib_quality = require("__exteros-lib__.quality")
local values = require("__exteros-lib__.internal.values")
local features = require("__exteros-lib__.internal.features")

local GUI_NAME = "exteros_itemcount"
local ENABLED_SETTING = "exteros-qol-item-count-player-enabled"
local FORMAT_SETTING = "exteros-qol-item-count-format"

---@return boolean
local function feature_enabled()
  return features.is_enabled("item-count")
end

---@type table<string, boolean>
local HIDDEN_TYPES = {
  ["deconstruction-item"] = true,
  ["upgrade-item"] = true,
  ["selection-tool"] = true,
  ["copy-paste-tool"] = true,
  ["spidertron-remote"] = true,
}

local M = {}

---@param player LuaPlayer
---@return LuaGuiElement?
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

---@param player LuaPlayer
---@param amount number
---@return string
local function format_amount(player, amount)
  local format = values.get_player(player, FORMAT_SETTING)

  if format == "short" then
    return lib_format.number(amount, true)
  end

  local separator = ","
  if format == "dot" then
    separator = "."
  elseif format == "space" then
    separator = " "
  elseif format == "none" then
    separator = ""
  end
  return lib_format.grouped(amount, separator)
end

---@param prototype LuaItemPrototype
---@return boolean
local function is_hidden(prototype)
  if HIDDEN_TYPES[prototype.type] then return true end
  return prototype.has_flag("only-in-cursor")
end

---@param player LuaPlayer
---@param cost_to_build { name: string, count: number, quality: string }[]?
---@return integer?
local function buildable_count(player, cost_to_build)
  if not cost_to_build or #cost_to_build == 0 then return nil end

  local inventory = player.get_main_inventory()
  if not inventory then return nil end

  local min_count
  for _, entry in ipairs(cost_to_build) do
    if entry.count > 0 then
      local have = inventory.get_item_count({ name = entry.name, quality = entry.quality })
      local possible = math.floor(have / entry.count)
      if not min_count or possible < min_count then min_count = possible end
    end
  end
  return min_count
end

---@param stack LuaItemStack
---@return LuaItemStack?
local function resolve_active_blueprint(stack)
  local current = stack
  for _ = 1, 16 do
    if not current or not current.valid_for_read then return nil end
    if current.is_blueprint then return current end
    if not current.is_blueprint_book then return nil end

    local inventory = current.get_inventory(defines.inventory.item_main)
    if not inventory then return nil end
    local index = current.active_index
    if not index or index < 1 or index > #inventory then return nil end

    current = inventory[index]
  end
  return nil
end

---@param player LuaPlayer
---@param gui LuaGuiElement
---@param count integer?
local function show_build_count(player, gui, count)
  if not count then
    gui.visible = false
    gui.caption = ""
    return
  end
  gui.visible = true
  gui.caption = "×" .. format_amount(player, count)
end

---@param player LuaPlayer
local function destroy_gui(player)
  if not player or not player.valid then return end
  local center = player.gui.center
  local gui = center and center[GUI_NAME]
  if gui and gui.valid then gui.destroy() end
end

---@param player LuaPlayer
local function update_itemcount(player)
  if not feature_enabled() then
    destroy_gui(player)
    return
  end

  local gui = get_or_create_itemcount_gui(player)
  if not gui then return end

  if not values.get_player(player, ENABLED_SETTING) then
    gui.visible = false
    gui.caption = ""
    return
  end

  local cursor_stack = player.cursor_stack
  local stack = (cursor_stack and cursor_stack.valid_for_read) and cursor_stack or nil

  if stack then
    if stack.is_blueprint or stack.is_blueprint_book then
      local blueprint = resolve_active_blueprint(stack)
      show_build_count(player, gui, blueprint and buildable_count(player, blueprint.cost_to_build))
      return
    end

    if is_hidden(stack.prototype) then
      gui.visible = false
      gui.caption = ""
      return
    end

    if stack.prototype.stackable or stack.prototype.stack_size > 1 then
      local filter = { name = stack.name, quality = stack.quality }
      local inventory_count = player.get_item_count(filter)

      local vehicle_count = nil
      local vehicle = player.vehicle
      if vehicle then
        local trunk_inventory
        if vehicle.type == "car" then
          trunk_inventory = defines.inventory.car_trunk
        elseif vehicle.type == "spider-vehicle" then
          trunk_inventory = defines.inventory.spider_trunk
        end
        local trunk = trunk_inventory and vehicle.get_inventory(trunk_inventory)
        if trunk then
          vehicle_count = trunk.get_item_count(filter)
        end
      end

      gui.visible = true
      gui.caption = format_amount(player, inventory_count)
      if vehicle_count and vehicle_count > 0 then
        gui.caption = gui.caption .. " (" .. format_amount(player, vehicle_count) .. ")"
      end
    else
      gui.visible = false
      gui.caption = ""
    end
    return
  end

  local record = player.cursor_record
  if record then
    local count = record.type == "blueprint" and (not record.is_preview) and buildable_count(player, record.cost_to_build) or nil
    show_build_count(player, gui, count)
    return
  end

  local ghost = player.cursor_ghost
  if ghost and ghost.name then
    local quality = lib_quality.name_of(ghost)
    local count = player.get_item_count({ name = ghost.name.name, quality = quality })
    gui.visible = true
    gui.caption = format_amount(player, count)
    return
  end

  gui.visible = false
  gui.caption = ""
end

---@param event ExterosLibValuesChange
local function on_setting_changed(event)
  if event.name ~= ENABLED_SETTING and event.name ~= FORMAT_SETTING then return end

  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  update_itemcount(player)
end

local function on_itemcount_event(e)
  local player = game.get_player(e.player_index)
  if lib_player.is_connected(player) then
    ---@cast player LuaPlayer
    update_itemcount(player)
  end
end

function M.on_enable()
  for _, player in pairs(game.players) do
    update_itemcount(player)
  end
end

function M.on_disable()
  for _, player in pairs(game.players) do
    destroy_gui(player)
  end
end

M.on_player_cursor_stack_changed = on_itemcount_event
M.on_player_driving_changed_state = on_itemcount_event
M.on_player_main_inventory_changed = on_itemcount_event
M.on_player_ammo_inventory_changed = on_itemcount_event
M.on_qol_value_changed = on_setting_changed

M.events = {
  [defines.events.on_player_cursor_stack_changed] = M.on_player_cursor_stack_changed,
  [defines.events.on_player_driving_changed_state] = M.on_player_driving_changed_state,
  [defines.events.on_player_main_inventory_changed] = M.on_player_main_inventory_changed,
  [defines.events.on_player_ammo_inventory_changed] = M.on_player_ammo_inventory_changed,
}

return M
