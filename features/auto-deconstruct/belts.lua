local compat = require("core.compat")
local box = require("core.box")
local position = require("core.position")
local state = require("features.auto-deconstruct.state")

local M = {}

local BELT_TYPES = {
  ["transport-belt"] = true,
  ["underground-belt"] = true,
  ["splitter"] = true,
  ["loader"] = true,
  ["loader-1x1"] = true
}

---@class AutoDeconBeltJob
---@field id integer
---@field surface_index integer
---@field force LuaForce
---@field origin { x: number, y: number }
---@field distance_limit number
---@field frontier LuaEntity[]
---@field visited table<integer, boolean>
---@field dead table<integer, boolean>
---@field dead_pending LuaEntity[]
---@field live_memo table<integer, boolean>
---@field started_tick integer
---@field last_progress_tick integer

---@param belt LuaEntity
---@return LuaEntity[]
local function get_outputs(belt)
  local outputs = {}
  local neighbours = belt.belt_neighbours
  if neighbours and neighbours.outputs then
    for _, neighbour in pairs(neighbours.outputs) do
      table.insert(outputs, neighbour)
    end
  end
  if belt.type == "underground-belt" and belt.belt_to_ground_type == "input" then
    local partner = compat.underground_partner(belt)
    if partner then table.insert(outputs, partner) end
  end
  return outputs
end

---@param belt LuaEntity
---@return LuaEntity[]
local function get_inputs(belt)
  local inputs = {}
  local neighbours = belt.belt_neighbours
  if neighbours and neighbours.inputs then
    for _, neighbour in pairs(neighbours.inputs) do
      table.insert(inputs, neighbour)
    end
  end
  if belt.type == "underground-belt" and belt.belt_to_ground_type == "output" then
    local partner = compat.underground_partner(belt)
    if partner then table.insert(inputs, partner) end
  end
  return inputs
end

---@param belt LuaEntity?
---@return boolean
local function is_belt_empty(belt)
  if not state.is_valid(belt) then return true end
  ---@cast belt LuaEntity

  if belt.type == "splitter" then
    for i = 1, 8 do
      local line = belt.get_transport_line(i)
      if line and #line > 0 then return false end
    end
  else
    for i = 1, 2 do
      local line = belt.get_transport_line(i)
      if line and #line > 0 then return false end
    end
  end
  return true
end

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

---@param vector { x: number, y: number }
---@param direction defines.direction
---@return { x: number, y: number }
local function rotate_north_vector(vector, direction)
  local quarter = math.floor((direction or 0) / 4) % 4
  local x, y = vector.x, vector.y
  for _ = 1, quarter do
    x, y = -y, x
  end
  return { x = x, y = y }
end

---@param belt LuaEntity
---@param ghost LuaEntity
---@return boolean
local function ghost_inserter_drops_onto(belt, ghost)
  if ghost.ghost_type ~= "inserter" then return false end
  local proto = ghost.ghost_prototype
  local success, drop = pcall(function() return proto.inserter_drop_position end)
  if not success or not drop then return false end

  local rel = rotate_north_vector(position.ensure_explicit(drop), ghost.direction)
  local gpos = position.ensure_explicit(ghost.position)
  local point = { x = gpos.x + rel.x, y = gpos.y + rel.y }
  local bbox = box.ensure_explicit(belt.bounding_box)
  return point.x >= bbox.left_top.x and point.x <= bbox.right_bottom.x
    and point.y >= bbox.left_top.y and point.y <= bbox.right_bottom.y
end

local DROPPER_SEARCH_TYPES = { "inserter", "mining-drill", "assembling-machine", "furnace", "entity-ghost" }

---@param belt LuaEntity
---@return boolean
local function has_live_dropper(belt)
  local area = box.expand(belt.bounding_box, state.max_drop_reach())
  local nearby = belt.surface.find_entities_filtered{ area = area, type = DROPPER_SEARCH_TYPES }
  for _, entity in ipairs(nearby) do
    if state.is_valid(entity) and not entity.to_be_deconstructed() then
      if entity.drop_target == belt then return true end
      if entity.type == "entity-ghost" and ghost_inserter_drops_onto(belt, entity) then return true end
    end
  end
  return false
end

---@param loader LuaEntity
---@return boolean
local function is_live_output_loader(loader)
  if loader.type ~= "loader" and loader.type ~= "loader-1x1" then return false end
  if loader.loader_type ~= "output" then return false end
  if loader.to_be_deconstructed() then return false end
  return state.is_valid(loader.loader_container)
end

---@class AutoDeconLiveCtx
---@field cut boolean

---@type fun(job: AutoDeconBeltJob, belt: LuaEntity, visiting: table<integer, boolean>?, ctx: AutoDeconLiveCtx?): boolean
local is_belt_live

---@param job AutoDeconBeltJob
---@param belt LuaEntity
---@param visiting table<integer, boolean>
---@param ctx AutoDeconLiveCtx
---@return boolean
local function upstream_live(job, belt, visiting, ctx)
  local id = uid(belt)
  if visiting[id] then
    ctx.cut = true
    return false
  end
  visiting[id] = true

  if job.dead[id] then return false end
  if job.live_memo[id] ~= nil then return job.live_memo[id] end
  if chebyshev(belt.position, job.origin) > job.distance_limit then return true end

  return is_belt_live(job, belt, visiting, ctx)
end

---@param job AutoDeconBeltJob
---@param belt LuaEntity
---@param visiting table<integer, boolean>?
---@param ctx AutoDeconLiveCtx?
---@return boolean
is_belt_live = function(job, belt, visiting, ctx)
  local id = uid(belt)
  if job.live_memo[id] ~= nil then return job.live_memo[id] end
  visiting = visiting or {}
  ctx = ctx or { cut = false }

  local live = is_live_output_loader(belt) or has_live_dropper(belt)
  if not live then
    for _, upstream in ipairs(get_inputs(belt)) do
      if state.is_valid(upstream) and upstream_live(job, upstream, visiting, ctx) then
        live = true
        break
      end
    end
  end

  if live or not ctx.cut then
    job.live_memo[id] = live
  end
  return live
end

---@param job AutoDeconBeltJob
---@param belt LuaEntity
---@return boolean
local function keeps_shape_of_survivor(job, belt)
  for _, output in ipairs(get_outputs(belt)) do
    if state.is_valid(output) and output.type == "transport-belt" and not job.dead[uid(output)]
      and output.belt_shape == "straight" then
      local others_alive = false
      for _, input in ipairs(get_inputs(output)) do
        if uid(input) ~= uid(belt) and state.is_valid(input) and not job.dead[uid(input)] then
          others_alive = true
          break
        end
      end
      if others_alive and #get_inputs(output) >= 2 then
        return true
      end
    end
  end
  return false
end

---@param data AutoDeconStorage
---@param drill LuaEntity
local function new_job(data, drill)
  ---@type AutoDeconBeltJob
  local job = {
    id = data.next_job_id,
    surface_index = drill.surface.index,
    force = drill.force,
    origin = { x = drill.position.x, y = drill.position.y },
    distance_limit = state.setting_number("exteros-qol-auto-deconstruct-belt-distance"),
    frontier = {},
    visited = {},
    dead = {},
    dead_pending = {},
    live_memo = {},
    started_tick = game.tick,
    last_progress_tick = game.tick
  }
  data.next_job_id = data.next_job_id + 1
  data.belt_jobs[job.id] = job
  return job
end

---@param data AutoDeconStorage
---@param drill LuaEntity
function M.seed(data, drill)
  if not state.setting_enabled("exteros-qol-auto-deconstruct-belts") then return end

  local seed_belt = drill.drop_target
  if not state.is_valid(seed_belt) then return end
  ---@cast seed_belt LuaEntity
  if not BELT_TYPES[seed_belt.type] then return end

  local seed_id = uid(seed_belt)
  local job_id = data.belt_job_of[seed_id]
  local job = job_id and data.belt_jobs[job_id]
  if not job then
    job = new_job(data, drill)
  else
    for unit_number in pairs(job.visited) do
      if not job.dead[unit_number] then
        job.visited[unit_number] = nil
        job.live_memo[unit_number] = nil
      end
    end
  end

  table.insert(job.frontier, seed_belt)
  data.belt_job_of[seed_id] = job.id
end

---@param data AutoDeconStorage
---@param job AutoDeconBeltJob
---@param belt LuaEntity?
local function visit(data, job, belt)
  if not state.is_valid(belt) then return end
  ---@cast belt LuaEntity
  local id = uid(belt)
  if job.visited[id] then return end
  job.visited[id] = true
  data.belt_job_of[id] = job.id

  if chebyshev(belt.position, job.origin) > job.distance_limit then return end
  if state.has_circuit_wires(belt) then return end
  if not belt.minable then return end

  if belt.type == "splitter" then
    for _, input in ipairs(get_inputs(belt)) do
      if state.is_valid(input) and is_belt_live(job, input) then
        return
      end
    end
  end

  if is_belt_live(job, belt) then return end
  if keeps_shape_of_survivor(job, belt) then return end

  job.dead[id] = true
  table.insert(job.dead_pending, belt)
  job.last_progress_tick = game.tick

  for _, output in ipairs(get_outputs(belt)) do
    if state.is_valid(output) and BELT_TYPES[output.type] and not job.visited[uid(output)] then
      table.insert(job.frontier, output)
    end
  end

  for _, input in ipairs(get_inputs(belt)) do
    if state.is_valid(input) and BELT_TYPES[input.type] and not job.visited[uid(input)] then
      table.insert(job.frontier, input)
    end
  end
end

---@param job AutoDeconBeltJob
---@param force_all boolean
local function drain_pending(job, force_all)
  local remaining = {}
  for _, belt in ipairs(job.dead_pending) do
    if state.is_valid(belt) then
      local ready = force_all
      if not ready then
        ready = true
        for _, input in ipairs(get_inputs(belt)) do
          if state.is_valid(input) and not input.to_be_deconstructed() and not job.dead[uid(input)] then
            ready = false
            break
          end
        end
        ready = ready and is_belt_empty(belt)
      end
      if ready then
        belt.order_deconstruction(job.force)
      else
        table.insert(remaining, belt)
      end
    end
  end
  job.dead_pending = remaining
end

---@param data AutoDeconStorage
---@param budget integer
---@return integer remaining_budget
function M.process(data, budget)
  local drain_due = game.tick % 30 == 0

  for id, job in pairs(data.belt_jobs) do
    local force_all = (game.tick - job.last_progress_tick) > state.NO_PROGRESS_TIMEOUT

    while budget > 0 and #job.frontier > 0 do
      local belt = table.remove(job.frontier)
      visit(data, job, belt)
      budget = budget - 1
    end

    if drain_due or force_all then
      drain_pending(job, force_all)
    end

    if #job.frontier == 0 and #job.dead_pending == 0 then
      for unit_number in pairs(job.visited) do
        if data.belt_job_of[unit_number] == id then data.belt_job_of[unit_number] = nil end
      end
      data.belt_jobs[id] = nil
    end

    if budget <= 0 then break end
  end
  return budget
end

return M
