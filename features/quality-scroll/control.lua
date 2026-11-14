local lib_player = require("__exteros-lib__.player")
local lib_quality = require("__exteros-lib__.quality")

local M = {}

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

  local list = lib_quality.sorted()
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

function M.on_quality_cycle_next(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  try_cycle(player, 1)
end

function M.on_quality_cycle_previous(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  try_cycle(player, -1)
end

M.events = {
  ["exteros-qol-quality-cycle-next"] = M.on_quality_cycle_next,
  ["exteros-qol-quality-cycle-previous"] = M.on_quality_cycle_previous,
}

return M
