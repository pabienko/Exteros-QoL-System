local core = require("core.init")
local mod_gui = require("mod-gui")

local M = {}

local ENABLED_SETTING = "exteros-qol-chest-limit-enabled"

local FRAME_NAME = "exteros_qol_chest_limit_frame"
local TEXTFIELD_NAME = "exteros_qol_chest_limit_text"
local UP_NAME = "exteros_qol_chest_limit_up"
local DOWN_NAME = "exteros_qol_chest_limit_down"
local RESET_NAME = "exteros_qol_chest_limit_reset"

---@type table<string, defines.inventory>
local CONTAINER_INVENTORY = {
  ["container"] = defines.inventory.chest,
  ["logistic-container"] = defines.inventory.chest,
  ["infinity-container"] = defines.inventory.chest,
  ["cargo-wagon"] = defines.inventory.cargo_wagon,
}

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

---@return table<uint, table<string, number>>
local function get_values_storage()
  storage.chest_limit_values = storage.chest_limit_values or {}
  return storage.chest_limit_values
end

---@return table<uint, string>
local function get_window_storage()
  storage.chest_limit_window = storage.chest_limit_window or {}
  return storage.chest_limit_window
end

---@param player_index uint
---@param item_name string
---@return number
local function get_value(player_index, item_name)
  local player_values = get_values_storage()[player_index]
  if not player_values then return 0 end
  return player_values[item_name] or 0
end

---@param player_index uint
---@param item_name string
---@param value number
local function set_value(player_index, item_name, value)
  local values = get_values_storage()
  if value <= 0 then
    if values[player_index] then
      values[player_index][item_name] = nil
    end
    return
  end
  values[player_index] = values[player_index] or {}
  values[player_index][item_name] = value
end

---@param stack LuaItemStack?
---@return string?, LuaEntityPrototype?
local function get_container_item(stack)
  if not stack or not stack.valid_for_read then return nil, nil end
  local place_result = stack.prototype.place_result
  if not place_result then return nil, nil end
  if not CONTAINER_INVENTORY[place_result.type] then return nil, nil end
  return stack.name, place_result
end

---@param item_name string
---@return LuaEntityPrototype?
local function get_place_result(item_name)
  local item_prototype = prototypes.item[item_name]
  if not item_prototype then return nil end
  return item_prototype.place_result
end

---@param place_result LuaEntityPrototype
---@return number
local function get_slot_count(place_result)
  local ok, size = pcall(place_result.get_inventory_size, defines.inventory.chest)
  if ok and size and size > 0 then
    return size
  end
  return 1000
end

---@param value number
---@param place_result LuaEntityPrototype
---@return number
local function clamp_value(value, place_result)
  local max = get_slot_count(place_result)
  if value < 0 then value = 0 end
  if value > max then value = max end
  return value
end

---@param player LuaPlayer
---@return LuaGuiElement?
local function get_frame(player)
  return mod_gui.get_frame_flow(player)[FRAME_NAME]
end

---@param player LuaPlayer
local function destroy_window(player)
  local frame = get_frame(player)
  if frame and frame.valid then
    frame.destroy()
  end
  get_window_storage()[player.index] = nil
end

---@param player LuaPlayer
---@param value number
local function refresh_textfield(player, value)
  local frame = get_frame(player)
  if not frame or not frame.valid then return end
  local textfield = frame[TEXTFIELD_NAME]
  if textfield and textfield.valid then
    textfield.text = tostring(value)
  end
end

---@param player LuaPlayer
---@param item_name string
---@param value number
local function build_window(player, item_name, value)
  local flow = mod_gui.get_frame_flow(player)
  if flow[FRAME_NAME] then
    flow[FRAME_NAME].destroy()
  end

  local frame = flow.add{
    type = "frame",
    name = FRAME_NAME,
    style = mod_gui.frame_style,
    direction = "horizontal",
  }

  frame.add{
    type = "label",
    style = "heading_2_label",
    caption = { "exteros-qol-chest-limit.caption" },
  }

  frame.add{
    type = "textfield",
    name = TEXTFIELD_NAME,
    style = "short_number_textfield",
    numeric = true,
    allow_decimal = false,
    allow_negative = false,
    lose_focus_on_confirm = true,
    text = tostring(value),
    tooltip = { "exteros-qol-chest-limit.textfield" },
  }

  frame.add{
    type = "sprite-button",
    name = UP_NAME,
    sprite = "utility/speed_up",
    style = "slot_sized_button",
    tooltip = { "exteros-qol-chest-limit.up" },
  }

  frame.add{
    type = "sprite-button",
    name = DOWN_NAME,
    sprite = "utility/speed_down",
    style = "slot_sized_button",
    tooltip = { "exteros-qol-chest-limit.down" },
  }

  frame.add{
    type = "sprite-button",
    name = RESET_NAME,
    sprite = "utility/reset",
    style = "slot_sized_button",
    tooltip = { "exteros-qol-chest-limit.reset" },
  }

  get_window_storage()[player.index] = item_name
end

function M.init()
  storage.chest_limit_values = storage.chest_limit_values or {}
  storage.chest_limit_window = storage.chest_limit_window or {}
end

function M.on_configuration_changed()
  storage.chest_limit_values = storage.chest_limit_values or {}
  storage.chest_limit_window = storage.chest_limit_window or {}
end

function M.on_player_cursor_stack_changed(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local item_name, place_result = get_container_item(player.cursor_stack)
  if not item_name then
    destroy_window(player)
    return
  end
  ---@cast place_result LuaEntityPrototype

  local value = get_value(player.index, item_name)
  local window_item = get_window_storage()[player.index]
  local frame = get_frame(player)

  if window_item == item_name and frame and frame.valid then
    refresh_textfield(player, value)
  else
    build_window(player, item_name, value)
  end
end

function M.on_gui_click(e)
  if not enabled() then return end
  if not e.element or not e.element.valid then return end

  local name = e.element.name
  if name ~= UP_NAME and name ~= DOWN_NAME and name ~= RESET_NAME then return end

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local item_name = get_window_storage()[player.index]
  if not item_name then return end

  local place_result = get_place_result(item_name)
  if not place_result then return end

  local current = get_value(player.index, item_name)
  local new_value
  if name == UP_NAME then
    new_value = current + 1
  elseif name == DOWN_NAME then
    new_value = current - 1
  else
    new_value = 0
  end

  new_value = clamp_value(new_value, place_result)
  set_value(player.index, item_name, new_value)
  refresh_textfield(player, new_value)
end

function M.on_gui_confirmed(e)
  if not enabled() then return end
  if not e.element or not e.element.valid then return end
  if e.element.name ~= TEXTFIELD_NAME then return end

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local item_name = get_window_storage()[player.index]
  if not item_name then return end

  local place_result = get_place_result(item_name)
  if not place_result then return end

  local typed = tonumber(e.element.text)
  local new_value = typed and math.floor(typed) or 0

  new_value = clamp_value(new_value, place_result)
  set_value(player.index, item_name, new_value)
  refresh_textfield(player, new_value)
end

function M.on_built_entity(event)
  if not enabled() then return end
  if not event.player_index then return end

  local entity = event.entity
  if not core.validation.is_entity_valid(entity) then return end

  local inventory_type = CONTAINER_INVENTORY[entity.type]
  if not inventory_type then return end

  local blocked_slots = get_value(event.player_index, entity.name)
  if blocked_slots <= 0 then return end

  local inventory = entity.get_inventory(inventory_type)
  if not inventory or not inventory.valid or not inventory.supports_bar() then return end

  local slot_count = #inventory
  local bar = slot_count - blocked_slots + 1
  if bar < 1 then bar = 1 end

  inventory.set_bar(bar)
end

return M
