local compat = require("core.compat")
local box = require("core.box")
local state = require("features.auto-deconstruct.state")
local pipe_logic = require("features.auto-deconstruct.pipes")
local belt_logic = require("features.auto-deconstruct.belts")
local pole_logic = require("features.auto-deconstruct.poles")
local scan_logic = require("features.auto-deconstruct.scan")

local M = {}

local CONTAINER_TYPES = {
  ["container"] = true,
  ["logistic-container"] = true
}

local BELT_TYPES = {
  ["transport-belt"] = true,
  ["underground-belt"] = true,
  ["splitter"] = true,
  ["loader"] = true,
  ["loader-1x1"] = true
}

local DROPPER_TYPES = {
  ["mining-drill"] = true,
  ["inserter"] = true,
  ["loader"] = true,
  ["loader-1x1"] = true,
  ["assembling-machine"] = true,
  ["furnace"] = true
}

---@param entity LuaEntity
---@return integer
local function uid(entity)
  return entity.unit_number --[[@as integer]]
end

---@param entity LuaEntity?
---@return boolean
local function passes_guards(entity)
  if not state.is_valid(entity) then return false end
  ---@cast entity LuaEntity

  if entity.to_be_deconstructed() then return false end
  if not entity.minable then return false end
  if entity.prototype.has_flag("not-deconstructable") then return false end
  if not entity.prototype.selectable_in_game then return false end
  if state.is_sandbox_surface(entity.surface.name) then return false end
  if state.has_circuit_wires(entity) then return false end
  return true
end

---@param entry AutoDeconQueueEntry
---@return boolean
local function drain_satisfied(entry)
  local drill = entry.drill
  if not state.is_valid(drill) then return true end
  ---@cast drill LuaEntity

  local target = drill.drop_target
  if not state.is_valid(target) then return true end
  ---@cast target LuaEntity

  if BELT_TYPES[target.type] then
    local line_count = target.type == "splitter" and 8 or 2
    for i = 1, line_count do
      local line = target.get_transport_line(i)
      if line and #line > 0 then return false end
    end
    return true
  end

  if CONTAINER_TYPES[target.type] then
    local inventory = target.get_inventory(defines.inventory.chest)
    return not inventory or inventory.is_empty()
  end

  if not entry.flat_deadline then entry.flat_deadline = game.tick + 30 end
  return game.tick >= entry.flat_deadline
end

---@param drill LuaEntity
local function mark_fuel_inserters(drill)
  if not state.setting_enabled("exteros-qol-auto-deconstruct-inserters") then return end

  local area = box.expand(drill.bounding_box, 3)
  for _, inserter in ipairs(drill.surface.find_entities_filtered{ area = area, type = "inserter" }) do
    if state.is_valid(inserter) and inserter.drop_target == drill and not inserter.to_be_deconstructed()
      and not state.has_circuit_wires(inserter) then
      inserter.order_deconstruction(drill.force)
    end
  end
end

---@param drill LuaEntity
local function mark_chest(drill)
  if not state.setting_enabled("exteros-qol-auto-deconstruct-chests") then return end

  local target = drill.drop_target
  if not state.is_valid(target) then return end
  ---@cast target LuaEntity
  if not CONTAINER_TYPES[target.type] or target.to_be_deconstructed() then return end
  if state.has_circuit_wires(target) then return end

  local area = box.expand(target.bounding_box, state.max_drop_reach())
  for _, entity in ipairs(target.surface.find_entities_filtered{ area = area }) do
    if state.is_valid(entity) and uid(entity) ~= uid(drill) and not entity.to_be_deconstructed() then
      if DROPPER_TYPES[entity.type] and entity.drop_target == target then
        return
      end
      if (entity.type == "loader" or entity.type == "loader-1x1")
        and entity.loader_type == "input" and entity.loader_container == target then
        return
      end
    end
  end

  target.order_deconstruction(drill.force)
end

---@param drill LuaEntity
local function mark_beacons(drill)
  if not state.setting_enabled("exteros-qol-auto-deconstruct-beacons") then return end

  local beacons = drill.get_beacons()
  if not beacons then return end

  for _, beacon in ipairs(beacons) do
    if state.is_valid(beacon) and not beacon.to_be_deconstructed() then
      local receivers = beacon.get_beacon_effect_receivers() or {}
      local in_use = false
      for _, receiver in ipairs(receivers) do
        if state.is_valid(receiver) and not receiver.to_be_deconstructed() then
          in_use = true
          break
        end
      end
      if not in_use and not state.has_circuit_wires(beacon) then
        beacon.order_deconstruction(beacon.force)
      end
    end
  end
end

---@param data AutoDeconStorage
---@param drill LuaEntity
---@param entry AutoDeconQueueEntry?
local function process_drill(data, drill, entry)
  local ghosts = {}

  local needed_fluid = (entry and entry.needs_fluid) or compat.fluid(drill, 1) ~= nil
  if state.setting_enabled("exteros-qol-auto-deconstruct-pipes") and compat.fluidbox_count(drill) == 1 and needed_fluid then
    local neighbours = pipe_logic.find_neighbours(drill, data)
    local pipe_type = pipe_logic.choose_pipe(drill, neighbours)
    if pipe_type then
      ghosts = pipe_logic.build_ghosts(drill, pipe_type, neighbours)
    end
  end

  if not drill.order_deconstruction(drill.force) then
    for _, ghost in ipairs(ghosts) do
      if state.is_valid(ghost) then ghost.destroy() end
    end
    return
  end

  mark_fuel_inserters(drill)
  mark_chest(drill)
  mark_beacons(drill)

  if state.setting_enabled("exteros-qol-auto-deconstruct-belts") then belt_logic.seed(data, drill) end
  if state.setting_enabled("exteros-qol-auto-deconstruct-poles") then pole_logic.seed(data, drill) end
end

---@param data AutoDeconStorage
---@param drill LuaEntity
---@param needs_fluid boolean?
local function queue_check(data, drill, needs_fluid)
  if not state.is_valid(drill) or not drill.unit_number then return end
  local id = uid(drill)
  if data.player_kept[id] then return end

  if data.queued[id] then
    if needs_fluid then
      for _, entry in ipairs(data.queue) do
        if entry.unit_number == id then
          entry.needs_fluid = true
          break
        end
      end
    end
    return
  end

  data.queued[id] = true
  ---@type AutoDeconQueueEntry
  local entry = {
    unit_number = id,
    drill = drill,
    stage = "check",
    tick = game.tick + state.RESOURCE_CHECK_DELAY,
    needs_fluid = needs_fluid or nil
  }
  table.insert(data.queue, entry)
end

---@param data AutoDeconStorage
---@param budget integer
---@return integer remaining_budget
local function process_queue(data, budget)
  local queue = data.queue
  for i = #queue, 1, -1 do
    if budget <= 0 then break end
    local entry = queue[i]
    local drill = entry.drill

    if not drill or not state.is_valid(drill) or drill.to_be_deconstructed() then
      table.remove(queue, i)
      data.queued[entry.unit_number] = nil
      budget = budget - 1
    elseif game.tick >= entry.tick then
      ---@cast drill LuaEntity
      budget = budget - 1

      if entry.stage == "check" then
        if not passes_guards(drill) then
          table.remove(queue, i)
          data.queued[entry.unit_number] = nil
        elseif state.is_drill_depleted(drill) then
          entry.stage = "drain"
          entry.drain_deadline = game.tick + state.DRAIN_MAX_TICKS
          entry.tick = game.tick + 30
        else
          table.remove(queue, i)
          data.queued[entry.unit_number] = nil
        end
      elseif entry.stage == "drain" then
        if drain_satisfied(entry) or game.tick >= (entry.drain_deadline or 0) then
          process_drill(data, drill, entry)
          budget = budget - 9
          table.remove(queue, i)
          data.queued[entry.unit_number] = nil
        else
          entry.tick = game.tick + 30
        end
      end
    end
  end
  return budget
end

function M.init()
  local data = state.ensure()
  data.max_reach = state.update_max_reach()
  data.max_drop_reach = state.update_max_drop_reach()
  pipe_logic.cache_pipe_prototypes()
  scan_logic.start(data)
end

function M.on_load()
end

function M.on_configuration_changed()
  local data = state.ensure()
  data.max_reach = state.update_max_reach()
  data.max_drop_reach = state.update_max_drop_reach()
  pipe_logic.cache_pipe_prototypes()
  scan_logic.start(data)
end

function M.on_resource_depleted(event)
  if not settings.startup["exteros-qol-auto-deconstruct-enabled"].value then return end

  local resource = event.entity
  if not state.is_valid(resource) then return end

  local data = state.ensure()
  if resource.prototype.infinite_resource and not state.setting_enabled("exteros-qol-auto-deconstruct-pumpjacks") then
    return
  end

  local needs_fluid = resource.prototype.mineable_properties.required_fluid ~= nil

  local reach = data.max_reach or 10
  local pos = resource.position --[[@as MapPosition.struct]]
  local candidates = resource.surface.find_entities_filtered{
    area = { { pos.x - reach, pos.y - reach }, { pos.x + reach, pos.y + reach } },
    type = "mining-drill"
  }

  for _, drill in ipairs(candidates) do
    local area = drill.mining_area --[[@as BoundingBox.struct]]
    if pos.x >= area.left_top.x and pos.x <= area.right_bottom.x
      and pos.y >= area.left_top.y and pos.y <= area.right_bottom.y then
      queue_check(data, drill, needs_fluid)
    end
  end
end

local PLAYER_CANCEL_REQUEUE_COOLDOWN = 600

function M.on_cancelled_deconstruction(event)
  if not settings.startup["exteros-qol-auto-deconstruct-enabled"].value then return end

  local entity = event.entity
  if not state.is_valid(entity) or entity.type ~= "mining-drill" then return end

  local data = state.ensure()
  local id = uid(entity)

  if event.player_index then
    data.player_kept[id] = entity
    return
  end

  local last_requeue = data.requeue_tick[id]
  if last_requeue and game.tick - last_requeue < PLAYER_CANCEL_REQUEUE_COOLDOWN then return end
  data.requeue_tick[id] = game.tick

  queue_check(data, entity)
end

local PLAYER_KEPT_CLEANUP_INTERVAL = 3600

---@param data AutoDeconStorage
local function cleanup_player_kept(data)
  for unit_number, entity in pairs(data.player_kept) do
    if type(entity) ~= "table" or not entity.valid then
      data.player_kept[unit_number] = nil
    end
  end
  for unit_number, tick in pairs(data.requeue_tick) do
    if game.tick - tick >= PLAYER_CANCEL_REQUEUE_COOLDOWN then
      data.requeue_tick[unit_number] = nil
    end
  end
end

function M.on_tick()
  if not settings.startup["exteros-qol-auto-deconstruct-enabled"].value then return end
  local data = state.ensure()

  if data.pending_rescan then
    data.pending_rescan = false
    scan_logic.start(data)
  end

  if game.tick % PLAYER_KEPT_CLEANUP_INTERVAL == 0 then
    cleanup_player_kept(data)
  end

  local budget = state.TICK_BUDGET

  if data.scan then
    for _, drill in ipairs(scan_logic.process(data)) do
      if not data.player_kept[uid(drill)] and passes_guards(drill) and state.is_drill_depleted(drill) then
        queue_check(data, drill)
      end
    end
  end

  budget = process_queue(data, budget)
  if budget <= 0 then return end

  budget = belt_logic.process(data, budget)
  if budget <= 0 then return end

  pole_logic.process(data, budget)
end

commands.add_command("exteros-scan", "Scans for all depleted mining drills and marks them for deconstruction.", function(command)
  if not settings.startup["exteros-qol-auto-deconstruct-enabled"].value then
    if command.player_index then
      local player = game.get_player(command.player_index)
      if player then
        player.print({ "exteros-qol-auto-deconstruct.scan-disabled" })
      end
    end
    return
  end

  if not game.player or game.player.admin then
    scan_logic.start(state.ensure())
  end
end)

return M
