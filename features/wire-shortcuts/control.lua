local lib_player = require("__exteros-lib__.player")
local lib_notify = require("__exteros-lib__.notify")
local lib_storage = require("__exteros-lib__.storage")
local values = require("__exteros-lib__.internal.values")

local M = {}

local COPPER_SETTING = "exteros-qol-wire-shortcuts-cycle-copper"

local WIRE_NAMES = {
  ["red-wire"] = true,
  ["green-wire"] = true,
  ["copper-wire"] = true,
}

---@param player LuaPlayer
---@return string[]
local function get_cycle(player)
  if values.get_player(player, COPPER_SETTING) then
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

local wire_shortcuts_last_wire = lib_storage.player_table("wire_shortcuts_last_wire")

---@param player_index uint
---@return string?
local function get_last_wire(player_index)
  return wire_shortcuts_last_wire.peek(player_index)
end

---@param player_index uint
---@param wire_name string
local function set_last_wire(player_index, wire_name)
  wire_shortcuts_last_wire.set(player_index, wire_name)
end

function M.on_wire_cycle(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
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
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack or not cursor_stack.valid_for_read then return end

  local wire_name = cursor_stack.name
  if not WIRE_NAMES[wire_name] then return end

  local cycle = get_cycle(player)
  if index_of(cycle, wire_name) then
    set_last_wire(event.player_index, wire_name)
  end

  lib_notify.flying(player, { "item-name." .. wire_name }, { create_at_cursor = true })
end

M.events = {
  [defines.events.on_player_cursor_stack_changed] = M.on_player_cursor_stack_changed,
  ["exteros-qol-wire-cycle"] = M.on_wire_cycle,
}

return M
