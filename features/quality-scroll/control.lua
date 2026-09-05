local core = require("core.init")

local M = {}

local ENABLED_SETTING = "exteros-qol-quality-scroll-enabled"

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

local function build_quality_list()
  local qualities = {}
  for name, quality in pairs(prototypes.quality) do
    table.insert(qualities, { name = name, level = quality.level })
  end

  table.sort(qualities, function(a, b) return a.level < b.level end)

  local list = {}
  for i, quality in ipairs(qualities) do
    list[i] = { name = quality.name, level = quality.level }
  end

  storage.quality_scroll_list = list
end

---@param list { name: string, level: uint }[]
---@param quality_name string
---@return integer?
local function index_of_quality(list, quality_name)
  for i, entry in ipairs(list) do
    if entry.name == quality_name then
      return i
    end
  end
  return nil
end

---@param player LuaPlayer
---@param direction integer
local function try_cycle(player, direction)
  local cursor_stack = player.cursor_stack
  if not cursor_stack or not cursor_stack.valid_for_read then return end

  local list = storage.quality_scroll_list or {}
  local count = #list
  if count == 0 then return end

  local current_index = index_of_quality(list, cursor_stack.quality.name)
  if not current_index then return end

  local main_inventory = player.get_main_inventory()
  if not main_inventory then return end

  local item_name = cursor_stack.name
  local index = current_index

  for _ = 1, count do
    index = index + direction
    if index > count then
      index = 1
    elseif index < 1 then
      index = count
    end
    if index == current_index then break end

    local candidate_stack = main_inventory.find_item_stack({ name = item_name, quality = list[index].name })
    if candidate_stack then
      cursor_stack.swap_stack(candidate_stack)
      return
    end
  end
end

function M.init()
  build_quality_list()
end

function M.on_configuration_changed()
  build_quality_list()
end

function M.on_quality_cycle_next(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  try_cycle(player, 1)
end

function M.on_quality_cycle_previous(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  try_cycle(player, -1)
end

return M
