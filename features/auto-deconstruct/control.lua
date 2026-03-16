local core = require("core.init")
local belt_logic = require("features.auto-deconstruct.belt-logic")
local pipe_logic = require("features.auto-deconstruct.pipe-logic")

local M = {}

local TICK_INTERVAL = 17
local RESOURCE_CHECK_DELAY = 60
local DECONSTRUCT_TIMEOUT = 1800

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"].value then
    log("[Auto-Decon] " .. msg)
  end
end

function M.update_max_mining_radius()
  local max_rad = 2
  for _, p in pairs(prototypes.get_entity_filtered{{filter="type", type="mining-drill"}}) do
    if p.mining_drill_radius and p.mining_drill_radius > max_rad then
      max_rad = p.mining_drill_radius
    end
  end
  return math.ceil(max_rad)
end

local function is_drill_empty(drill)
  if not drill.valid then return false end
  
  debug_log("Checking if drill is empty: " .. drill.name .. " at " .. drill.position.x .. "," .. drill.position.y)
  
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

local function find_target(entity)
  if not entity.valid then return nil end
  if entity.drop_target then return entity.drop_target end
  local found = entity.surface.find_entities_filtered{position = entity.drop_position, limit = 1}
  return found[1]
end

local function order_deconstruction(drill)
  if not drill.valid or drill.to_be_deconstructed() then return end
  
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
      local receivers = beacon.get_beacon_effect_receivers()
      local in_use = false
      for _, receiver in ipairs(receivers) do
        if receiver ~= drill and not receiver.to_be_deconstructed() then
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

local function queue_deconstruction(drill)
  if not drill.valid or drill.to_be_deconstructed() then return end
  
  for _, entry in ipairs(storage.auto_decon.queue) do
    if entry.drill == drill then return end
  end

  debug_log("Queuing final empty check for " .. drill.name .. " at " .. drill.position.x .. "," .. drill.position.y)
  
  local target = find_target(drill)
  local target_line = belt_logic.find_target_line(drill, target)
  
  table.insert(storage.auto_decon.queue, {
    drill = drill,
    target = not target_line and target or nil,
    target_line = target_line,
    timeout = game.tick + DECONSTRUCT_TIMEOUT,
    tick = game.tick + TICK_INTERVAL
  })
end

function M.scan_all_drills()
  debug_log("Scanning all surfaces for depleted drills...")
  local count = 0
  for _, surface in pairs(game.surfaces) do
    local drills = surface.find_entities_filtered{type = "mining-drill"}
    for _, drill in ipairs(drills) do
      if is_drill_empty(drill) then
        queue_deconstruction(drill)
        count = count + 1
      end
    end
  end
  debug_log("Scan finished. Found " .. count .. " depleted drills.")
end

function M.init()
  storage.auto_decon = storage.auto_decon or {}
  storage.auto_decon.queue = storage.auto_decon.queue or {}
  storage.auto_decon.max_radius = M.update_max_mining_radius()
  
  pipe_logic.cache_prototypes()
  
  storage.auto_decon.pending_scan = true
end

function M.on_resource_depleted(event)
  if not settings.startup["exteros-qol-auto-deconstruct-enabled"].value then return end
  
  local res = event.entity
  if not res.valid or res.prototype.infinite_resource then return end
  
  debug_log("Resource depleted: " .. res.name .. " at " .. res.position.x .. "," .. res.position.y)
  
  local radius = storage.auto_decon.max_radius or 10
  local drills = res.surface.find_entities_filtered{
    area = {{res.position.x - radius, res.position.y - radius}, {res.position.x + radius, res.position.y + radius}},
    type = "mining-drill"
  }
  
  for _, drill in ipairs(drills) do
    table.insert(storage.auto_decon.queue, {
      check_drill = drill,
      tick = game.tick + RESOURCE_CHECK_DELAY
    })
  end
end

local session_scanned = false

function M.on_tick()
  if not storage.auto_decon or not storage.auto_decon.queue then return end
  
  if not session_scanned then
    session_scanned = true
    debug_log("First tick of session - triggering load scan")
    if settings.startup["exteros-qol-auto-deconstruct-enabled"].value then
      M.scan_all_drills()
    end
  end

  if storage.auto_decon.pending_scan then
    storage.auto_decon.pending_scan = false
    M.scan_all_drills()
  end

  local queue = storage.auto_decon.queue
  for i = #queue, 1, -1 do
    local entry = queue[i]
    
    if entry.check_drill then
      if not entry.check_drill.valid then
        table.remove(queue, i)
      elseif game.tick >= entry.tick then
        if is_drill_empty(entry.check_drill) then
          queue_deconstruction(entry.check_drill)
        end
        table.remove(queue, i)
      end
      
    elseif entry.drill then
      if not entry.drill.valid or entry.drill.to_be_deconstructed() then
        table.remove(queue, i)
      else
        local ready = false
        if game.tick >= entry.timeout then
          ready = true
        elseif game.tick >= entry.tick then
          if entry.target_line then
            if not entry.target_line.valid or #entry.target_line == 0 then
              ready = true
            end
          elseif entry.target then
            if not entry.target.valid then
              ready = true
            else
              local inv = entry.target.get_inventory(defines.inventory.chest)
              if not inv or inv.is_empty() then
                ready = true
              end
            end
          else
            ready = true
          end
        end
        
        if ready then
          order_deconstruction(entry.drill)
          table.remove(queue, i)
        end
      end
    end
  end
end

if settings.startup["exteros-qol-auto-deconstruct-enabled"].value then
  script.on_nth_tick(TICK_INTERVAL, M.on_tick)
end

script.on_init(M.init)
script.on_configuration_changed(M.init)
script.on_event(defines.events.on_resource_depleted, M.on_resource_depleted)

commands.add_command("exteros-scan", "Scans for all depleted mining drills and marks them for deconstruction.", function()
  if not game.player or game.player.admin then
    M.scan_all_drills()
  end
end)

return M