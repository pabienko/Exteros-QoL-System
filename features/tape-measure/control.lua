local lib_player = require("__exteros-lib__.player")
local lib_box = require("__exteros-lib__.box")
local lib_render = require("__exteros-lib__.render")
local lib_storage = require("__exteros-lib__.storage")

local M = {}

local TOOL_NAME = "exteros-qol-tape-measure"

local MEASURE_COLOR = { r = 0.3, g = 0.8, b = 1 }
local LABEL_COLOR = { r = 1, g = 1, b = 1 }
local TIME_TO_LIVE = 600

local tape_measure = lib_storage.player_table("tape_measure")

---@param player_index uint
local function clear_persistent(player_index)
  local renders = tape_measure.peek(player_index)
  if not renders then return end

  lib_render.destroy(renders)
  tape_measure.clear(player_index)
end

---@param area BoundingBox
---@return QolBoundingBox box
---@return number width
---@return number height
---@return number count
local function measure(area)
  local box = lib_box.snap_outward(area)
  local width = math.max(1, box.right_bottom.x - box.left_top.x)
  local height = math.max(1, box.right_bottom.y - box.left_top.y)
  return box, width, height, width * height
end

---@param player LuaPlayer
---@param box QolBoundingBox
---@param width number
---@param height number
---@param count number
---@param persistent boolean
local function draw_measurement(player, box, width, height, count, persistent)
  local time_to_live = nil
  if not persistent then
    time_to_live = TIME_TO_LIVE
  end

  local rectangle = rendering.draw_rectangle({
    color = MEASURE_COLOR,
    surface = player.surface,
    left_top = box.left_top,
    right_bottom = box.right_bottom,
    players = { player },
    time_to_live = time_to_live,
  })

  local text = rendering.draw_text({
    text = width .. " × " .. height .. " (" .. count .. ")",
    surface = player.surface,
    target = { x = (box.left_top.x + box.right_bottom.x) / 2, y = box.left_top.y - 0.5 },
    color = LABEL_COLOR,
    scale = 1.5,
    alignment = "center",
    players = { player },
    time_to_live = time_to_live,
  })

  if persistent then
    tape_measure.set(player.index, { rectangle = rectangle, text = text })
  end
end

---@param player LuaPlayer
---@param box QolBoundingBox
---@param width number
---@param height number
---@param count number
local function report(player, box, width, height, count)
  player.print({
    "exteros-qol-tape-measure.result",
    width, height, count,
    box.left_top.x, box.left_top.y,
    box.right_bottom.x, box.right_bottom.y,
    (box.left_top.x + box.right_bottom.x) / 2,
    (box.left_top.y + box.right_bottom.y) / 2,
  })
end

---@param e EventData.on_player_selected_area
function M.on_player_selected_area(e)
  if e.item ~= TOOL_NAME then return end

  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  clear_persistent(e.player_index)
  local box, width, height, count = measure(e.area)
  draw_measurement(player, box, width, height, count, false)
  report(player, box, width, height, count)
end

---@param e EventData.on_player_alt_selected_area
function M.on_player_alt_selected_area(e)
  if e.item ~= TOOL_NAME then return end

  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  clear_persistent(e.player_index)
  local box, width, height, count = measure(e.area)
  draw_measurement(player, box, width, height, count, true)
  report(player, box, width, height, count)
end

---@param event EventData.CustomInputEvent
function M.on_tape_measure_get_tool(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end
  if cursor_stack.valid_for_read then
    if not player.clear_cursor() then return end
  end

  cursor_stack.set_stack({ name = TOOL_NAME, count = 1 })
  player.cursor_stack_temporary = true
end

---@param event EventData.on_player_removed
function M.on_player_removed(event)
  clear_persistent(event.player_index)
end

function M.on_disable()
  for _, player in pairs(game.players) do
    clear_persistent(player.index)
  end
end

M.events = {
  [defines.events.on_player_selected_area] = M.on_player_selected_area,
  [defines.events.on_player_alt_selected_area] = M.on_player_alt_selected_area,
  [defines.events.on_player_removed] = M.on_player_removed,
  ["exteros-qol-tape-measure"] = M.on_tape_measure_get_tool,
}

return M
