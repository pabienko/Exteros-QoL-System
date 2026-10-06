local core = require("core.init")

local M = {}

local ENABLED_SETTING = "exteros-qol-tape-measure-enabled"
local TOOL_NAME = "exteros-qol-tape-measure"

local MEASURE_COLOR = { r = 0.3, g = 0.8, b = 1 }
local LABEL_COLOR = { r = 1, g = 1, b = 1 }
local TIME_TO_LIVE = 600

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

---@return table<uint, { rectangle: LuaRenderObject, text: LuaRenderObject }>
local function get_render_storage()
  storage.tape_measure = storage.tape_measure or {}
  return storage.tape_measure
end

---@param player_index uint
local function clear_persistent(player_index)
  local store = get_render_storage()
  local renders = store[player_index]
  if not renders then return end

  if renders.rectangle and renders.rectangle.valid then renders.rectangle.destroy() end
  if renders.text and renders.text.valid then renders.text.destroy() end
  store[player_index] = nil
end

---@param area BoundingBox
---@return QolBoundingBox box
---@return number width
---@return number height
---@return number count
local function measure(area)
  local box = core.box.snap_outward(area)
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
  local time_to_live = persistent and nil or TIME_TO_LIVE

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
    get_render_storage()[player.index] = { rectangle = rectangle, text = text }
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
  if not enabled() then return end
  if e.item ~= TOOL_NAME then return end

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  clear_persistent(e.player_index)
  local box, width, height, count = measure(e.area)
  draw_measurement(player, box, width, height, count, false)
  report(player, box, width, height, count)
end

---@param e EventData.on_player_alt_selected_area
function M.on_player_alt_selected_area(e)
  if not enabled() then return end
  if e.item ~= TOOL_NAME then return end

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  clear_persistent(e.player_index)
  local box, width, height, count = measure(e.area)
  draw_measurement(player, box, width, height, count, true)
  report(player, box, width, height, count)
end

---@param event EventData.CustomInputEvent
function M.on_tape_measure_get_tool(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end
  if cursor_stack.valid_for_read then
    if not player.clear_cursor() then return end
  end

  cursor_stack.set_stack({ name = TOOL_NAME, count = 1 })
  player.cursor_stack_temporary = true
end

function M.init()
  storage.tape_measure = storage.tape_measure or {}
end

function M.on_configuration_changed()
  storage.tape_measure = storage.tape_measure or {}
end

---@param event EventData.on_player_removed
function M.on_player_removed(event)
  clear_persistent(event.player_index)
end

return M
