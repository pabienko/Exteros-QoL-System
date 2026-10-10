local M = {}

local DRILLS_PER_TICK = 50

---@class AutoDeconScanState
---@field surface_indices integer[]
---@field surface_pos integer
---@field drills LuaEntity[]?
---@field drill_pos integer

---@param data AutoDeconStorage
function M.start(data)
  local indices = {}
  for _, surface in pairs(game.surfaces) do
    table.insert(indices, surface.index)
  end
  data.scan = {
    surface_indices = indices,
    surface_pos = 1,
    drills = nil,
    drill_pos = 1
  }
end

---@param data AutoDeconStorage
---@return LuaEntity[]
function M.process(data)
  local scan = data.scan --[[@as AutoDeconScanState]]
  if not scan then return {} end

  local surface_index = scan.surface_indices[scan.surface_pos] --[[@as uint]]
  local surface = game.surfaces[surface_index]
  if not surface then
    scan.surface_pos = scan.surface_pos + 1
    scan.drills = nil
    if scan.surface_pos > #scan.surface_indices then data.scan = nil end
    return {}
  end

  if not scan.drills then
    scan.drills = surface.find_entities_filtered{ type = "mining-drill" }
    scan.drill_pos = 1
  end

  local found = {}
  local n = 0
  while n < DRILLS_PER_TICK and scan.drill_pos <= #scan.drills do
    local drill = scan.drills[scan.drill_pos]
    if drill.valid then table.insert(found, drill) end
    scan.drill_pos = scan.drill_pos + 1
    n = n + 1
  end

  if scan.drill_pos > #scan.drills then
    scan.drills = nil
    scan.surface_pos = scan.surface_pos + 1
    if scan.surface_pos > #scan.surface_indices then data.scan = nil end
  end

  return found
end

return M
