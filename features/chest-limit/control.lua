local lib_player = require("__exteros-lib__.player")
local lib_entity = require("__exteros-lib__.entity")
local lib_quality = require("__exteros-lib__.quality")
local lib_notify = require("__exteros-lib__.notify")
local lib_storage = require("__exteros-lib__.storage")
local mod_gui = require("mod-gui")
local values = require("__exteros-lib__.internal.values")

local M = {}

local PLAYER_SETTING = "exteros-qol-chest-limit-player"

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

---@param player LuaPlayer
---@return boolean
local function player_enabled(player)
  return values.get_player(player, PLAYER_SETTING) == true
end

local chest_limit_values = lib_storage.player_table("chest_limit_values")
local chest_limit_window = lib_storage.player_table("chest_limit_window")

---@param player_index uint
---@param entity_name string
---@return number
local function get_value(player_index, entity_name)
  local player_values = chest_limit_values.peek(player_index)
  if not player_values then return 0 end
  return player_values[entity_name] or 0
end

---@param player_index uint
---@param entity_name string
---@param value number
local function set_value(player_index, entity_name, value)
  if value <= 0 then
    local player_values = chest_limit_values.peek(player_index)
    if player_values then
      player_values[entity_name] = nil
    end
    return
  end
  chest_limit_values.get(player_index)[entity_name] = value
end

---@param player LuaPlayer
---@return string?, LuaEntityPrototype?, string
local function get_container_item(player)
  local stack = player.cursor_stack
  if stack and stack.valid_for_read then
    local place_result = stack.prototype.place_result
    if not place_result or not CONTAINER_INVENTORY[place_result.type] then return nil, nil, "normal" end
    return stack.name, place_result, stack.quality.name
  end

  local ghost = player.cursor_ghost
  if ghost and ghost.name then
    local place_result = ghost.name.place_result
    if not place_result or not CONTAINER_INVENTORY[place_result.type] then return nil, nil, "normal" end
    local quality = lib_quality.name_of(ghost)
    return ghost.name.name, place_result, quality
  end

  return nil, nil, "normal"
end

---@param entity_name string
---@return LuaEntityPrototype?
local function get_entity_prototype(entity_name)
  return prototypes.entity[entity_name]
end

---@param place_result LuaEntityPrototype
---@param quality string
---@return number
local function get_slot_count(place_result, quality)
  local size = place_result.get_inventory_size(defines.inventory.chest, quality)
  if size and size > 0 then
    return size
  end
  return 1000
end

---@param value number
---@param place_result LuaEntityPrototype
---@param quality string
---@return number
local function clamp_value(value, place_result, quality)
  local max = get_slot_count(place_result, quality)
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
  chest_limit_window.clear(player.index)
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
---@param entity_name string
---@param quality string
---@param value number
local function build_window(player, item_name, entity_name, quality, value)
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

  chest_limit_window.set(player.index, { item_name = item_name, entity_name = entity_name, quality = quality })
end

function M.on_player_cursor_stack_changed(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  if not player_enabled(player) then
    destroy_window(player)
    return
  end

  local item_name, place_result, quality = get_container_item(player)
  if not item_name then
    destroy_window(player)
    return
  end
  ---@cast place_result LuaEntityPrototype

  local entity_name = place_result.name
  local value = get_value(player.index, entity_name)
  local window = chest_limit_window.peek(player.index)
  local frame = get_frame(player)

  if window and window.item_name == item_name and window.quality == quality and frame and frame.valid then
    refresh_textfield(player, value)
  else
    build_window(player, item_name, entity_name, quality, value)
  end
end

function M.on_gui_click(e)
  if not e.element or not e.element.valid then return end

  local name = e.element.name
  if name ~= UP_NAME and name ~= DOWN_NAME and name ~= RESET_NAME then return end

  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer
  if not player_enabled(player) then return end

  local window = chest_limit_window.peek(player.index)
  if not window then return end
  local entity_name = window.entity_name
  if not entity_name then return end

  local place_result = get_entity_prototype(entity_name)
  if not place_result then return end

  local current = get_value(player.index, entity_name)
  local new_value
  if name == UP_NAME then
    new_value = current + 1
  elseif name == DOWN_NAME then
    new_value = current - 1
  else
    new_value = 0
  end

  new_value = clamp_value(new_value, place_result, window.quality)
  set_value(player.index, entity_name, new_value)
  refresh_textfield(player, new_value)
end

function M.on_gui_confirmed(e)
  if not e.element or not e.element.valid then return end
  if e.element.name ~= TEXTFIELD_NAME then return end

  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer
  if not player_enabled(player) then return end

  local window = chest_limit_window.peek(player.index)
  if not window then return end
  local entity_name = window.entity_name
  if not entity_name then return end

  local place_result = get_entity_prototype(entity_name)
  if not place_result then return end

  local typed = tonumber(e.element.text)
  local new_value = typed and math.floor(typed) or 0

  new_value = clamp_value(new_value, place_result, window.quality)
  set_value(player.index, entity_name, new_value)
  refresh_textfield(player, new_value)
end

---@param player_index uint
---@param entity LuaEntity
local function apply_limit_to_entity(player_index, entity)
  if not lib_entity.is_valid(entity) then return end

  local inventory_type = CONTAINER_INVENTORY[entity.type]
  if not inventory_type then return end

  local blocked_slots = get_value(player_index, entity.name)
  if blocked_slots <= 0 then return end

  local inventory = entity.get_inventory(inventory_type)
  if not inventory or not inventory.valid or not inventory.supports_bar() then return end

  local slot_count = #inventory
  local bar = slot_count - blocked_slots + 1
  if bar < 1 then bar = 1 end

  inventory.set_bar(bar)
end

function M.on_built_entity(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer
  if not player_enabled(player) then return end

  apply_limit_to_entity(event.player_index, event.entity)
end

---@param event EventData.on_robot_built_entity
function M.on_robot_built_entity(event)
  local entity = event.entity
  if not lib_entity.is_valid(entity) then return end

  local player = entity.last_user
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer
  if not player_enabled(player) then return end

  apply_limit_to_entity(player.index, entity)
end

---@param event EventData.CustomInputEvent
---@param delta integer
local function adjust_from_hotkey(event, delta)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer
  if not player_enabled(player) then return end

  local item_name, place_result, quality = get_container_item(player)
  if not item_name then return end
  ---@cast place_result LuaEntityPrototype

  local entity_name = place_result.name
  local new_value = clamp_value(get_value(player.index, entity_name) + delta, place_result, quality)
  set_value(player.index, entity_name, new_value)
  refresh_textfield(player, new_value)

  lib_notify.flying(player, { "exteros-qol-chest-limit.flying-text", tostring(new_value) }, { create_at_cursor = true })
end

---@param event EventData.CustomInputEvent
function M.on_chest_limit_increase(event)
  adjust_from_hotkey(event, 1)
end

---@param event EventData.CustomInputEvent
function M.on_chest_limit_decrease(event)
  adjust_from_hotkey(event, -1)
end

function M.on_disable()
  for _, player in pairs(game.players) do
    destroy_window(player)
  end
end

M.events = {
  [defines.events.on_player_cursor_stack_changed] = M.on_player_cursor_stack_changed,
  [defines.events.on_gui_click] = M.on_gui_click,
  [defines.events.on_gui_confirmed] = M.on_gui_confirmed,
  [defines.events.on_built_entity] = M.on_built_entity,
  [defines.events.on_robot_built_entity] = M.on_robot_built_entity,
  ["exteros-qol-chest-limit-increase"] = M.on_chest_limit_increase,
  ["exteros-qol-chest-limit-decrease"] = M.on_chest_limit_decrease,
}

return M
