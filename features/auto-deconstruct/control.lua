local core = require("core.init")
local pipe_logic = require("features.auto-deconstruct.pipe-logic")

local M = {}

local TICK_INTERVAL = 17
local RESOURCE_CHECK_DELAY = 15
local RESOURCE_EJECT_DELAY = 30

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"].value then
    log("[Auto-Decon] " .. msg)
  end
end

local function is_valid_surface(surface)
  return surface and (surface.valid == nil or surface.valid)
end

local function is_valid_force(force)
  return force and (force.valid == nil or force.valid)
end

local function is_valid_entity(entity)
  return entity and entity.valid and is_valid_surface(entity.surface)
end

local rebuild_queue_index

function M.update_max_mining_radius()
  local max_rad = 2
  for _, p in pairs(prototypes.get_entity_filtered{{filter="type", type="mining-drill"}}) do
    if p.mining_drill_radius and p.mining_drill_radius > max_rad then
      max_rad = p.mining_drill_radius
    end
  end
  return math.ceil(max_rad)
end

function M.ensure_storage()
  storage.auto_decon = storage.auto_decon or {}
  storage.auto_decon.queue = storage.auto_decon.queue or {}
  storage.auto_decon.queued = storage.auto_decon.queued or {}
  storage.auto_decon.max_radius = storage.auto_decon.max_radius or M.update_max_mining_radius()
  if rebuild_queue_index and not storage.auto_decon.queue_index_built then
    rebuild_queue_index(storage.auto_decon)
  end
  return storage.auto_decon
end

local function get_drill_key(drill)
  if not is_valid_entity(drill) then return nil end
  if drill.unit_number then
    return "unit:" .. drill.unit_number
  end
  return "pos:" .. drill.surface.index .. ":" .. drill.name .. ":" .. drill.position.x .. ":" .. drill.position.y
end

rebuild_queue_index = function(data)
  local changed = false
  data.queued = {}
  for i = #data.queue, 1, -1 do
    local entry = data.queue[i]
    local key = entry.key or get_drill_key(entry.drill or entry.check_drill)
    if key and not data.queued[key] then
      entry.key = key
      data.queued[key] = true
    else
      table.remove(data.queue, i)
      changed = true
    end
  end
  data.queue_index_built = true
  return changed
end

local function is_drill_empty(drill)
  if not is_valid_entity(drill) then return false end

  if drill.mining_target and drill.mining_target.valid then return false end
  
  if drill.status == defines.entity_status.no_minable_resources then return true end
  
  local radius = drill.prototype.mining_drill_radius or 0
  local count = drill.surface.count_entities_filtered{
    area = {
      {drill.position.x - radius - 0.1, drill.position.y - radius - 0.1},
      {drill.position.x + radius + 0.1, drill.position.y + radius + 0.1}
    },
    type = "resource",
    limit = 1
  }
  return count == 0
end

local function order_deconstruction(drill)
  if not is_valid_entity(drill) or not is_valid_force(drill.force) or drill.to_be_deconstructed() then return end
  
  debug_log("Ordering deconstruction for " .. drill.name .. " at " .. drill.position.x .. "," .. drill.position.y)
  
  local targets = pipe_logic.find_pipes_to_build(drill)
  local pipe_type = pipe_logic.choose_pipe(drill, targets)
  
  if pipe_type then
    pipe_logic.build_ghosts(drill, pipe_type, targets)
  end
  
  drill.order_deconstruction(drill.force)
  
  local beacons = drill.get_beacons()
  if beacons then
    for _, beacon in ipairs(beacons) do
      if is_valid_entity(beacon) and is_valid_force(beacon.force) then
        local receivers = beacon.get_beacon_effect_receivers()
        local in_use = false
        for _, receiver in ipairs(receivers) do
          if is_valid_entity(receiver) and receiver ~= drill and not receiver.to_be_deconstructed() then
            in_use = true
            break
          end
        end
        if not in_use then
          beacon.order_deconstruction(beacon.force)
        end
      end
    end
  end
end

local function remove_queue_entry(queue, i)
  local entry = queue[i]
  if entry and entry.key then
    M.ensure_storage().queued[entry.key] = nil
  end
  table.remove(queue, i)
end

local function insert_queue_entry(entry)
  local data = M.ensure_storage()
  if not entry.key then return false end
  if data.queued[entry.key] then return false end

  data.queued[entry.key] = true
  table.insert(data.queue, entry)
  return true
end

local function queue_deconstruction(drill)
  if not is_valid_entity(drill) or drill.to_be_deconstructed() then return end
  local key = get_drill_key(drill)
  if not key then return end

  -- This module does not deconstruct output belts/chests, so only wait long enough
  -- for the miner to eject its last item instead of waiting for busy belts to empty.
  if insert_queue_entry({
    key = key,
    drill = drill,
    tick = game.tick + RESOURCE_EJECT_DELAY
  }) then
    debug_log("Queuing final empty check for " .. drill.name .. " at " .. drill.position.x .. "," .. drill.position.y)
  end
end

local function queue_drill_check(drill)
  if not is_valid_entity(drill) then return end
  local key = get_drill_key(drill)
  if not key then return end

  insert_queue_entry({
    key = key,
    check_drill = drill,
    tick = game.tick + RESOURCE_CHECK_DELAY
  })
end

function M.scan_all_drills()
  M.ensure_storage()
  debug_log("Scanning all surfaces for depleted drills...")
  local count = 0
  for _, surface in pairs(game.surfaces) do
    if is_valid_surface(surface) then
      local drills = surface.find_entities_filtered{type = "mining-drill"}
      for _, drill in ipairs(drills) do
        if is_drill_empty(drill) then
          queue_deconstruction(drill)
          count = count + 1
        end
      end
    end
  end
  debug_log("Scan finished. Found " .. count .. " depleted drills.")
end

function M.init()
  local data = M.ensure_storage()
  data.max_radius = M.update_max_mining_radius()
  
  pipe_logic.cache_prototypes()
  
  data.pending_scan = true
end

function M.on_configuration_changed()
  M.init()
end

function M.on_resource_depleted(event)
  if not settings.startup["exteros-qol-auto-deconstruct-enabled"].value then return end
  local data = M.ensure_storage()
  
  local res = event.entity
  if not is_valid_entity(res) or res.prototype.infinite_resource then return end
  
  debug_log("Resource depleted: " .. res.name .. " at " .. res.position.x .. "," .. res.position.y)
  
  local radius = data.max_radius or 10
  local drills = res.surface.find_entities_filtered{
    area = {{res.position.x - radius, res.position.y - radius}, {res.position.x + radius, res.position.y + radius}},
    type = "mining-drill"
  }
  
  for _, drill in ipairs(drills) do
    queue_drill_check(drill)
  end
end

function M.on_tick(event)
  if event.tick % TICK_INTERVAL ~= 0 then return end
  local data = M.ensure_storage()
  if not settings.startup["exteros-qol-auto-deconstruct-enabled"].value then return end

  if data.pending_scan then
    data.pending_scan = false
    M.scan_all_drills()
  end

  local queue = data.queue
  for i = #queue, 1, -1 do
    local entry = queue[i]
    
    if entry.check_drill then
      if not is_valid_entity(entry.check_drill) then
        remove_queue_entry(queue, i)
      elseif game.tick >= entry.tick then
        local drill = entry.check_drill
        remove_queue_entry(queue, i)
        if is_drill_empty(drill) then
          queue_deconstruction(drill)
        end
      end
      
    elseif entry.drill then
      if not is_valid_entity(entry.drill) or entry.drill.to_be_deconstructed() then
        remove_queue_entry(queue, i)
      else
        if game.tick >= entry.tick then
          order_deconstruction(entry.drill)
          remove_queue_entry(queue, i)
        end
      end
    else
      remove_queue_entry(queue, i)
    end
  end
end

commands.add_command("exteros-scan", "Scans for all depleted mining drills and marks them for deconstruction.", function()
  if not game.player or game.player.admin then
    M.scan_all_drills()
  end
end)

return M
