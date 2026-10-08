local core = require("core.init")

local GUI_NAME = "exteros_itemcount"
local ENABLED_SETTING = "exteros-qol-item-count-enabled"
local FORMAT_SETTING = "exteros-qol-item-count-format"
local FEATURE_SETTING = "exteros-qol-item-count-feature-enabled"

---@return boolean
local function feature_enabled()
  local setting = settings.startup[FEATURE_SETTING]
  return setting ~= nil and setting.value == true
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
  local format = settings.get_player_settings(player)[FORMAT_SETTING].value

  if format == "short" then
    return core.format.number(amount, true)
  end

  local separator = ","
  if format == "dot" then
    separator = "."
  elseif format == "space" then
    separator = " "
  elseif format == "none" then
    separator = ""
  end
  return core.format.grouped(amount, separator)
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
    if not index then return nil end

    current = inventory[index]
  end
  return nil
end

---@param player LuaPlayer
---@param gui LuaGuiElement
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
local function update_itemcount(player)
  if not feature_enabled() then
    local center = player.gui.center
    local gui = center and center[GUI_NAME]
    if gui and gui.valid then gui.destroy() end
    return
  end

  local gui = get_or_create_itemcount_gui(player)
  if not gui then return end

  if not settings.get_player_settings(player)[ENABLED_SETTING].value then
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
      if player.vehicle then
        local trunk = player.vehicle.get_inventory(defines.inventory.car_trunk)
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
    local count = (not record.is_preview) and buildable_count(player, record.cost_to_build) or nil
    show_build_count(player, gui, count)
    return
  end

  local ghost = player.cursor_ghost
  if ghost and ghost.name then
    local quality = ghost.quality and ghost.quality.name or "normal"
    local count = player.get_item_count({ name = ghost.name.name, quality = quality })
    gui.visible = true
    gui.caption = format_amount(player, count)
    return
  end

  gui.visible = false
  gui.caption = ""
end

---@param event EventData.on_runtime_mod_setting_changed
local function on_setting_changed(event)
  if event.setting ~= ENABLED_SETTING and event.setting ~= FORMAT_SETTING then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  update_itemcount(player)
end

local function on_itemcount_event(e)
  local player = game.get_player(e.player_index)
  if core.validation.is_player_valid(player) then
    ---@cast player LuaPlayer
    update_itemcount(player)
  end
end

M.on_player_cursor_stack_changed = on_itemcount_event
M.on_player_driving_changed_state = on_itemcount_event
M.on_player_main_inventory_changed = on_itemcount_event
M.on_player_ammo_inventory_changed = on_itemcount_event
M.on_runtime_mod_setting_changed = on_setting_changed

return M
