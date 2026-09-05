local core = require("core.init")

local M = {}

local ENABLED_SETTING = "exteros-qol-wire-shortcuts-enabled"
local COPPER_SETTING = "exteros-qol-wire-cycle-copper"

local WIRE_NAMES = {
  ["red-wire"] = true,
  ["green-wire"] = true,
  ["copper-wire"] = true,
}

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

---@param player LuaPlayer
---@return string[]
local function get_cycle(player)
  if settings.get_player_settings(player)[COPPER_SETTING].value then
    return { "red-wire", "green-wire", "copper-wire" }
  end
  return { "red-wire", "green-wire" }
end

---@param list string[]
---@param value string
---@return integer?
local function index_of(list, value)
  for i, v in ipairs(list) do
    if v == value then
      return i
    end
  end
  return nil
end

local function get_storage()
  storage.wire_shortcuts_last_wire = storage.wire_shortcuts_last_wire or {}
  return storage.wire_shortcuts_last_wire
end

---@param player_index uint
---@return string?
local function get_last_wire(player_index)
  return get_storage()[player_index]
end

---@param player_index uint
---@param wire_name string
local function set_last_wire(player_index, wire_name)
  get_storage()[player_index] = wire_name
end

function M.init()
  storage.wire_shortcuts_last_wire = storage.wire_shortcuts_last_wire or {}
end

function M.on_configuration_changed()
  storage.wire_shortcuts_last_wire = storage.wire_shortcuts_last_wire or {}
end

function M.on_wire_cycle(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end

  local cycle = get_cycle(player)
  local next_wire

  if cursor_stack.valid_for_read then
    local current_index = index_of(cycle, cursor_stack.name)
    if current_index then
      next_wire = cycle[(current_index % #cycle) + 1]
    end
  end

  if not next_wire then
    local last_wire = get_last_wire(event.player_index)
    if last_wire and index_of(cycle, last_wire) then
      next_wire = last_wire
    else
      next_wire = "red-wire"
    end
  end

  if not player.clear_cursor() then return end

  cursor_stack.set_stack({ name = next_wire, count = 1 })
end

function M.on_player_cursor_stack_changed(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack or not cursor_stack.valid_for_read then return end

  local wire_name = cursor_stack.name
  if not WIRE_NAMES[wire_name] then return end

  local cycle = get_cycle(player)
  if index_of(cycle, wire_name) then
    set_last_wire(event.player_index, wire_name)
  end

  player.create_local_flying_text({
    text = { "item-name." .. wire_name },
    create_at_cursor = true,
  })
end

return M
