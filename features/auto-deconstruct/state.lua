local validation = require("core.validation")
local position = require("core.position")

local M = {}

M.RESOURCE_CHECK_DELAY = 15
M.DRAIN_MAX_TICKS = 1800
M.EJECT_DELAY = 30
M.NO_PROGRESS_TIMEOUT = 3600
M.TICK_BUDGET = 50

---@type string[]
M.SANDBOX_SURFACE_PATTERNS = { "^BPL_TheLab", "^bpsb%-lab" }

---@class AutoDeconStorage
---@field max_reach number?
---@field max_drop_reach number?
---@field queue AutoDeconQueueEntry[]
---@field queued table<integer, boolean>
---@field player_kept table<integer, LuaEntity>
---@field requeue_tick table<integer, integer>
---@field belt_jobs table<integer, AutoDeconBeltJob>
---@field belt_job_of table<integer, integer>
---@field pole_jobs table<integer, AutoDeconPoleJob>
---@field pole_job_of table<integer, integer>
---@field next_job_id integer
---@field scan AutoDeconScanState?
---@field pipe_prototypes table[]?
---@field old_queue_migrated boolean?
---@field pending_rescan boolean?

---@class AutoDeconQueueEntry
---@field unit_number integer
---@field tick integer
---@field stage "check"|"drain"
---@field drill LuaEntity?
---@field drain_deadline integer?
---@field flat_deadline integer?
---@field needs_fluid boolean?

---@return AutoDeconStorage
function M.ensure()
  storage.auto_decon = storage.auto_decon or {}
  local data = storage.auto_decon --[[@as AutoDeconStorage]]

  if data.old_queue_migrated ~= true then
    data.queue = nil
    data.queued = nil
    data.old_queue_migrated = true
    data.pending_rescan = true
  end

  data.queue = data.queue or {}
  data.queued = data.queued or {}
  data.player_kept = data.player_kept or {}
  data.requeue_tick = data.requeue_tick or {}
  data.belt_jobs = data.belt_jobs or {}
  data.belt_job_of = data.belt_job_of or {}
  data.pole_jobs = data.pole_jobs or {}
  data.pole_job_of = data.pole_job_of or {}
  data.next_job_id = data.next_job_id or 1
  return data
end

---@param prototype LuaEntityPrototype
---@return number
local function radius_visualisation_pad(prototype)
  local success, spec = pcall(function() return prototype.radius_visualisation_specification end)
  if not success or not spec then return 0 end
  local offset = position.ensure_explicit(spec.offset)
  return math.max(math.abs(offset.x), math.abs(offset.y))
end

---@return number
function M.update_max_reach()
  local max_reach = 2
  for _, p in pairs(prototypes.get_entity_filtered{{filter="type", type="mining-drill"}}) do
    local pad = radius_visualisation_pad(p)
    local radius = 0
    if p.quality_affects_mining_radius then
      for _, quality in pairs(prototypes.quality) do
        radius = math.max(radius, p.get_mining_drill_radius(quality) or 0)
      end
    else
      radius = p.get_mining_drill_radius() or p.mining_drill_radius or 0
    end
    if radius + pad > max_reach then max_reach = radius + pad end
  end
  return math.ceil(max_reach) + 2
end

---@return number
function M.update_max_drop_reach()
  local max_reach = 1
  for _, p in pairs(prototypes.get_entity_filtered{{filter="type", type="inserter"}}) do
    local success, drop = pcall(function() return p.inserter_drop_position end)
    if success and drop then
      local pos = position.ensure_explicit(drop)
      local length = math.sqrt(pos.x * pos.x + pos.y * pos.y)
      if length > max_reach then max_reach = length end
    end
  end
  return math.ceil(max_reach) + 1
end

---@param entity LuaEntity?
---@return boolean
function M.is_valid(entity)
  return validation.is_entity_valid(entity)
end

---@param surface_name string
---@return boolean
function M.is_sandbox_surface(surface_name)
  for _, pattern in ipairs(M.SANDBOX_SURFACE_PATTERNS) do
    if surface_name:find(pattern) then return true end
  end
  return false
end

local COPPER_WIRE_CONNECTOR_IDS = {
  [defines.wire_connector_id.pole_copper] = true,
  [defines.wire_connector_id.power_switch_left_copper] = true,
  [defines.wire_connector_id.power_switch_right_copper] = true
}

---@param entity LuaEntity?
---@return boolean
function M.has_circuit_wires(entity)
  if not M.is_valid(entity) then return false end
  ---@cast entity LuaEntity

  local success, connectors = pcall(function() return entity.get_wire_connectors(false) end)
  if not success or not connectors then return false end

  for id, connector in pairs(connectors) do
    if not COPPER_WIRE_CONNECTOR_IDS[id] and connector.connection_count > 0 then
      return true
    end
  end
  return false
end

---@param entity LuaEntity?
---@return LuaEntity[]
function M.copper_neighbours(entity)
  local neighbours = {}
  if not M.is_valid(entity) then return neighbours end
  ---@cast entity LuaEntity

  local success, connectors = pcall(function() return entity.get_wire_connectors(false) end)
  if not success or not connectors then return neighbours end

  local connector = connectors[defines.wire_connector_id.pole_copper]
  if not connector then return neighbours end

  for _, connection in pairs(connector.real_connections) do
    local owner = connection.target.owner
    if owner.valid then
      table.insert(neighbours, owner)
    end
  end
  return neighbours
end

---@return number
function M.max_drop_reach()
  local data = storage.auto_decon --[[@as AutoDeconStorage?]]
  return (data and data.max_drop_reach) or 2
end

---@param drill LuaEntity
---@return boolean
function M.is_drill_depleted(drill)
  local categories = drill.prototype.resource_categories or {}
  local resources = drill.surface.find_entities_filtered{ area = drill.mining_area, type = "resource" }
  local relevant = {}
  for _, resource in ipairs(resources) do
    if categories[resource.prototype.resource_category] then
      table.insert(relevant, resource)
    end
  end

  if #relevant == 0 then
    return not (drill.mining_target and drill.mining_target.valid)
  end

  if not M.setting_enabled("exteros-qol-auto-deconstruct-pumpjacks") then return false end

  for _, resource in ipairs(relevant) do
    if not resource.prototype.infinite_resource then return false end
    if resource.amount > resource.prototype.minimum_resource_amount then return false end
  end
  return true
end

---@param setting string
---@return boolean
function M.setting_enabled(setting)
  return settings.global[setting].value --[[@as boolean]]
end

---@param setting string
---@return number
function M.setting_number(setting)
  return settings.global[setting].value --[[@as number]]
end

return M
