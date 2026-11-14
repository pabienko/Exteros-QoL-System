local lib_entity = require("__exteros-lib__.entity")

local M = {}

local ZAPPED_TYPES = {
  ["blueprint"] = true,
  ["blueprint-book"] = true,
  ["deconstruction-item"] = true,
  ["selection-tool"] = true,
  ["upgrade-item"] = true,
}

function M.on_player_dropped_item(event)
  local entity = event.entity
  if not lib_entity.is_valid(entity) then return end

  local stack = entity.stack
  if not stack or not stack.valid_for_read then return end
  if not ZAPPED_TYPES[stack.type] then return end

  local surface = entity.surface
  local position = entity.position

  surface.create_entity({
    name = "exteros-qol-drop-planner",
    position = position,
  })

  entity.destroy()
end

M.events = {
  [defines.events.on_player_dropped_item] = M.on_player_dropped_item,
}

return M
