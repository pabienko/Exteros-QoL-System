local core = require("core.init")

local M = {}

local ENABLED_SETTING = "exteros-qol-belt-reverser-enabled"
local MAX_WALK_STEPS = 10000

---@type table<string, boolean>
local HANDLED_TYPES = {
  ["transport-belt"] = true,
  ["underground-belt"] = true,
  ["loader"] = true,
  ["loader-1x1"] = true,
}

---@type string[]
local HANDLED_TYPE_LIST = { "transport-belt", "underground-belt", "loader", "loader-1x1" }

---@type table<defines.direction, QolPosition>
local DIRECTION_VECTOR = {
  [defines.direction.north] = { x = 0, y = -1 },
  [defines.direction.east] = { x = 1, y = 0 },
  [defines.direction.south] = { x = 0, y = 1 },
  [defines.direction.west] = { x = -1, y = 0 },
}

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

---@param entity LuaEntity
---@return string
local function effective_type(entity)
  if entity.type == "entity-ghost" then
    return entity.ghost_type
  end
  return entity.type
end

---@param entity LuaEntity?
---@return boolean
local function is_handled(entity)
  if not core.validation.is_entity_valid(entity) then return false end
  ---@cast entity LuaEntity
  return HANDLED_TYPES[effective_type(entity)] == true
end

---@param direction defines.direction
---@return defines.direction
local function opposite_direction(direction)
  return ((direction + 8) % 16) --[[@as defines.direction]]
end

---@param entity LuaEntity
---@param direction defines.direction
---@param distance number
---@return QolPosition
local function offset_position(entity, direction, distance)
  local position = core.position.ensure_explicit(entity.position)
  local vector = DIRECTION_VECTOR[direction]
  return { x = position.x + vector.x * distance, y = position.y + vector.y * distance }
end

---@param entity LuaEntity
---@return number
local function step_distance(entity)
  if (entity.tile_width or 1) > 1 or (entity.tile_height or 1) > 1 then
    return 1.5
  end
  return 1
end

---@param surface LuaSurface
---@param position QolPosition
---@return LuaEntity?
local function find_handled_at(surface, position)
  local real_entities = surface.find_entities_filtered({ position = position, type = HANDLED_TYPE_LIST })
  for i = 1, #real_entities do
    if real_entities[i].valid then return real_entities[i] end
  end

  local ghost_entities = surface.find_entities_filtered({ position = position, ghost_type = HANDLED_TYPE_LIST })
  for i = 1, #ghost_entities do
    if ghost_entities[i].valid then return ghost_entities[i] end
  end

  return nil
end

---@param entity LuaEntity
---@return string?
local function get_belt_to_ground_type(entity)
  if entity.type == "underground-belt" then
    return entity.belt_to_ground_type
  end

  if entity.type == "entity-ghost" and entity.ghost_type == "underground-belt" then
    local success, result = pcall(function()
      return entity.belt_to_ground_type
    end)
    if success then return result end
  end

  return nil
end

---@param entity LuaEntity
---@param upstream boolean
---@return LuaEntity?
local function find_neighbour(entity, upstream)
  local direction = entity.direction
  local entity_type = effective_type(entity)

  if entity_type == "underground-belt" then
    local ground_type = get_belt_to_ground_type(entity)
    if not ground_type then return nil end

    local through_ground = (ground_type == "input" and not upstream) or (ground_type == "output" and upstream)
    if through_ground then
      return core.compat.underground_partner(entity)
    end
  end

  if not upstream then
    local position = offset_position(entity, direction, step_distance(entity))
    local candidate = find_handled_at(entity.surface, position)
    if not candidate then return nil end
    if candidate.direction == opposite_direction(direction) then return nil end
    return candidate
  end

  local behind_position = offset_position(entity, opposite_direction(direction), step_distance(entity))
  local behind_candidate = find_handled_at(entity.surface, behind_position)
  if behind_candidate and behind_candidate.direction == direction then
    return behind_candidate
  end

  local feeder = nil
  local feeder_count = 0
  for side_direction in pairs(DIRECTION_VECTOR) do
    local position = offset_position(entity, side_direction, step_distance(entity))
    local candidate = find_handled_at(entity.surface, position)
    if candidate and candidate.direction == opposite_direction(side_direction) then
      feeder = candidate
      feeder_count = feeder_count + 1
    end
  end

  if feeder_count == 1 then return feeder end
  return nil
end

---@param start_entity LuaEntity
---@return LuaEntity[]
local function collect_line(start_entity)
  local visited = {}
  visited[start_entity.unit_number] = true

  local upstream_list = {}
  local head = start_entity
  for _ = 1, MAX_WALK_STEPS do
    local neighbour = find_neighbour(head, true)
    if not neighbour or not is_handled(neighbour) then break end
    if visited[neighbour.unit_number] then break end
    visited[neighbour.unit_number] = true
    table.insert(upstream_list, neighbour)
    head = neighbour
  end

  local downstream_list = {}
  local tail = start_entity
  for _ = 1, MAX_WALK_STEPS do
    local neighbour = find_neighbour(tail, false)
    if not neighbour or not is_handled(neighbour) then break end
    if visited[neighbour.unit_number] then break end
    visited[neighbour.unit_number] = true
    table.insert(downstream_list, neighbour)
    tail = neighbour
  end

  local line = {}
  for i = #upstream_list, 1, -1 do
    table.insert(line, upstream_list[i])
  end
  table.insert(line, start_entity)
  for i = 1, #downstream_list do
    table.insert(line, downstream_list[i])
  end

  return line
end

---@param from LuaEntity
---@param to LuaEntity
---@return defines.direction
local function direction_between(from, to)
  local from_position = core.position.ensure_explicit(from.position)
  local to_position = core.position.ensure_explicit(to.position)
  local dx = to_position.x - from_position.x
  local dy = to_position.y - from_position.y

  if math.abs(dx) >= math.abs(dy) then
    if dx >= 0 then return defines.direction.east end
    return defines.direction.west
  end

  if dy >= 0 then return defines.direction.south end
  return defines.direction.north
end

---@param line LuaTransportLine
---@return { position: number, stack: table }[]
local function snapshot_line(line)
  local out = {}
  for _, item in ipairs(line.get_detailed_contents()) do
    local stack = item.stack
    local entry = { name = stack.name, count = stack.count }
    if stack.quality then entry.quality = stack.quality.name end
    out[#out + 1] = { position = item.position, stack = entry }
  end
  return out
end

local function swap_lanes(entity)
  local max_index = entity.get_max_transport_line_index()
  for index = 1, max_index, 2 do
    local line_a = entity.get_transport_line(index)
    local line_b = entity.get_transport_line(index + 1)
    if line_a and line_b then
      local contents_a = snapshot_line(line_a)
      local contents_b = snapshot_line(line_b)

      line_a.clear()
      line_b.clear()

      for _, item in ipairs(contents_b) do
        line_a.force_insert_at(item.position, item.stack)
      end
      for _, item in ipairs(contents_a) do
        line_b.force_insert_at(item.position, item.stack)
      end
    end
  end
end

---@param entity LuaEntity
---@param target_direction defines.direction
local function reverse_transport_belt(entity, target_direction)
  local current_direction = entity.direction
  local delta = (target_direction - current_direction) % 16
  if delta == 0 then return end

  if delta == 4 then
    entity.rotate()
  elseif delta == 12 then
    entity.rotate({ reverse = true })
  else
    entity.rotate()
    entity.rotate()
    if entity.type ~= "entity-ghost" then
      swap_lanes(entity)
    end
  end
end

---@param entity LuaEntity
---@param handled table<number, boolean>
local function reverse_underground_belt(entity, handled)
  if entity.unit_number and handled[entity.unit_number] then return end

  local partner = core.compat.underground_partner(entity)
  if entity.unit_number then handled[entity.unit_number] = true end
  if partner and partner.valid and partner.unit_number then
    handled[partner.unit_number] = true
  end

  local input_side = entity
  if get_belt_to_ground_type(entity) == "output" and partner and partner.valid then
    input_side = partner
  end

  if get_belt_to_ground_type(input_side) == "input" then
    input_side.rotate()
  end
end

---@param entity LuaEntity
local function reverse_loader(entity)
  entity.rotate()
end

---@param line LuaEntity[]
local function reverse_line(line)
  local handled_undergrounds = {}
  for i = 1, #line do
    local entity = line[i]
    if entity.valid then
      local entity_type = effective_type(entity)
      if entity_type == "underground-belt" then
        reverse_underground_belt(entity, handled_undergrounds)
      elseif entity_type == "loader" or entity_type == "loader-1x1" then
        reverse_loader(entity)
      elseif entity_type == "transport-belt" then
        local target_direction
        if i > 1 then
          target_direction = direction_between(entity, line[i - 1])
        else
          target_direction = opposite_direction(entity.direction)
        end
        reverse_transport_belt(entity, target_direction)
      end
    end
  end
end

function M.on_reverse_belts(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local selected = player.selected
  if not is_handled(selected) then return end
  ---@cast selected LuaEntity

  local line = collect_line(selected)
  reverse_line(line)
end

return M
