local position = require("core.position")
local box = require("core.box")
local state = require("features.auto-deconstruct.state")

local M = {}

---@class AutoDeconPoleJob
---@field id integer
---@field force LuaForce
---@field origin { x: number, y: number }
---@field distance_limit number
---@field frontier LuaEntity[]
---@field in_range table<integer, boolean>
---@field dead table<integer, boolean>
---@field explored table<integer, boolean>
---@field started_tick integer
---@field last_progress_tick integer

---@param pos1 { x: number, y: number }
---@param pos2 { x: number, y: number }
---@return number
local function chebyshev(pos1, pos2)
  return math.max(math.abs(pos1.x - pos2.x), math.abs(pos1.y - pos2.y))
end

---@param entity LuaEntity
---@return integer
local function uid(entity)
  return entity.unit_number --[[@as integer]]
end

---@param a QolBoundingBox
---@param b QolBoundingBox
---@return boolean
local function boxes_intersect(a, b)
  return a.left_top.x <= b.right_bottom.x and a.right_bottom.x >= b.left_top.x
    and a.left_top.y <= b.right_bottom.y and a.right_bottom.y >= b.left_top.y
end

---@param pole LuaEntity
---@return boolean
local function supplies_live_consumer(pole)
  local distance = pole.prototype.get_supply_area_distance(pole.quality)
  local pos = pole.position --[[@as MapPosition.struct]]
  local area = { { pos.x - distance, pos.y - distance }, { pos.x + distance, pos.y + distance } }
  local nearby = pole.surface.find_entities_filtered{ area = area, force = pole.force }

  for _, entity in ipairs(nearby) do
    if state.is_valid(entity) and uid(entity) ~= uid(pole) and not entity.to_be_deconstructed() then
      if entity.type == "entity-ghost" then
        local success, source = pcall(function() return entity.ghost_prototype.electric_energy_source_prototype end)
        if success and source then return true end
      else
        local success, source = pcall(function() return entity.prototype.electric_energy_source_prototype end)
        if success and source and entity.electric_network_id == pole.electric_network_id then
          return true
        end
      end
    end
  end
  return false
end

---@param pole LuaEntity
---@return boolean
local function is_guarded_candidate(pole)
  if pole.to_be_deconstructed() then return false end
  if not pole.minable or pole.prototype.has_flag("not-deconstructable") then return false end
  if state.is_sandbox_surface(pole.surface.name) then return false end
  if state.has_circuit_wires(pole) then return false end

  for _, neighbour in ipairs(state.copper_neighbours(pole)) do
    if neighbour.type ~= "electric-pole" then return false end
  end

  return not supplies_live_consumer(pole)
end

---@param data AutoDeconStorage
---@param drill LuaEntity
local function new_job(data, drill)
  ---@type AutoDeconPoleJob
  local job = {
    id = data.next_job_id,
    force = drill.force,
    origin = { x = drill.position.x, y = drill.position.y },
    distance_limit = state.setting_number("exteros-qol-auto-deconstruct-pole-distance"),
    frontier = {},
    in_range = {},
    dead = {},
    explored = {},
    started_tick = game.tick,
    last_progress_tick = game.tick
  }
  data.next_job_id = data.next_job_id + 1
  data.pole_jobs[job.id] = job
  return job
end

---@param data AutoDeconStorage
---@param drill LuaEntity
function M.seed(data, drill)
  if not state.setting_enabled("exteros-qol-auto-deconstruct-poles") then return end

  local distance_limit = state.setting_number("exteros-qol-auto-deconstruct-pole-distance")
  local drill_pos = position.ensure_explicit(drill.position)
  local area = {
    { drill_pos.x - distance_limit, drill_pos.y - distance_limit },
    { drill_pos.x + distance_limit, drill_pos.y + distance_limit }
  }
  local candidates = drill.surface.find_entities_filtered{ area = area, type = "electric-pole", force = drill.force }
  if #candidates == 0 then return end

  local drill_box = box.ensure_explicit(drill.bounding_box)

  local job
  for _, pole in ipairs(candidates) do
    local supply = pole.prototype.get_supply_area_distance(pole.quality)
    local pole_pos = position.ensure_explicit(pole.position)
    local supply_box = {
      left_top = { x = pole_pos.x - supply, y = pole_pos.y - supply },
      right_bottom = { x = pole_pos.x + supply, y = pole_pos.y + supply }
    }
    if boxes_intersect(supply_box, drill_box) then
      local pole_id = uid(pole)
      local job_id = data.pole_job_of[pole_id]
      job = job_id and data.pole_jobs[job_id] or job or new_job(data, drill)
      if not job.in_range[pole_id] then
        job.in_range[pole_id] = true
        table.insert(job.frontier, pole)
      end
      data.pole_job_of[pole_id] = job.id
    end
  end
end

---@param data AutoDeconStorage
---@param job AutoDeconPoleJob
---@param neighbours LuaEntity[]
local function enqueue_copper_neighbours(data, job, neighbours)
  for _, neighbour in ipairs(neighbours) do
    local neighbour_id = uid(neighbour)
    if neighbour.type == "electric-pole" and not job.dead[neighbour_id]
      and chebyshev(neighbour.position, job.origin) <= job.distance_limit then
      job.in_range[neighbour_id] = true
      data.pole_job_of[neighbour_id] = job.id
      table.insert(job.frontier, neighbour)
    end
  end
end

---@param data AutoDeconStorage
---@param job AutoDeconPoleJob
---@param pole LuaEntity?
local function visit(data, job, pole)
  if not state.is_valid(pole) then return end
  ---@cast pole LuaEntity
  local id = uid(pole)
  if job.dead[id] then return end

  if chebyshev(pole.position, job.origin) > job.distance_limit then return end
  if not is_guarded_candidate(pole) then return end

  local neighbours = state.copper_neighbours(pole)
  local unmarked_neighbours = 0
  for _, neighbour in ipairs(neighbours) do
    if not job.dead[uid(neighbour)] then
      unmarked_neighbours = unmarked_neighbours + 1
    end
  end

  if unmarked_neighbours <= 1 then
    job.dead[id] = true
    job.last_progress_tick = game.tick
    pole.order_deconstruction(job.force)
    enqueue_copper_neighbours(data, job, neighbours)
  elseif not job.explored[id] then
    job.explored[id] = true
    enqueue_copper_neighbours(data, job, neighbours)
  end
end

---@param data AutoDeconStorage
---@param budget integer
---@return integer remaining_budget
function M.process(data, budget)
  for id, job in pairs(data.pole_jobs) do
    while budget > 0 and #job.frontier > 0 do
      local pole = table.remove(job.frontier)
      visit(data, job, pole)
      budget = budget - 1
    end

    if #job.frontier == 0 then
      for unit_number in pairs(job.in_range) do
        if data.pole_job_of[unit_number] == id then data.pole_job_of[unit_number] = nil end
      end
      data.pole_jobs[id] = nil
    end

    if budget <= 0 then break end
  end
  return budget
end

return M
