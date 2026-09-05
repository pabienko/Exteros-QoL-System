local core = require("core.init")

local M = {}

local ENABLED_SETTING = "exteros-qol-planner-zapper-enabled"

local ZAPPED_TYPES = {
  ["blueprint"] = true,
  ["blueprint-book"] = true,
  ["deconstruction-item"] = true,
  ["selection-tool"] = true,
  ["upgrade-item"] = true,
}

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

function M.on_player_dropped_item(event)
  if not enabled() then return end

  local entity = event.entity
  if not core.validation.is_entity_valid(entity) then return end

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

return M
