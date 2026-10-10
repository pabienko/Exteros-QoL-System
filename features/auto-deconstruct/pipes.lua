local compat = require("core.compat")
local position = require("core.position")
local state = require("features.auto-deconstruct.state")

local M = {}

local GHOST_SEARCH_RADIUS = 0.4
local GHOST_MATCH_DISTANCE = 0.6

---@param t1 table<string, boolean>
---@param t2 string[]
---@return boolean
local function categories_equal(t1, t2)
  local count = 0
  for _ in pairs(t1) do count = count + 1 end
  if count ~= #t2 then return false end
  for _, c in ipairs(t2) do
    if not t1[c] then return false end
  end
  return true
end

---@return { name: string, categories: table<string, boolean> }[]
function M.cache_pipe_prototypes()
  local candidates = {}
  for name, p in pairs(prototypes.get_entity_filtered{{filter="type", type="pipe"}}) do
    if not p.hidden and p.fluidbox_prototypes and #p.fluidbox_prototypes == 1 then
      local conns = p.fluidbox_prototypes[1].pipe_connections
      if conns and #conns == 4 and conns[1].connection_type == "normal" then
        local first_cat = {}
        for _, c in ipairs(conns[1].connection_category) do first_cat[c] = true end

        local valid = true
        for i = 2, 4 do
          local conn = conns[i]
          if not conn or conn.connection_type ~= "normal" or not categories_equal(first_cat, conn.connection_category) then
            valid = false
            break
          end
        end

        if valid then
          table.insert(candidates, { name = name, categories = first_cat, order = p.order })
        end
      end
    end
  end
  table.sort(candidates, function(a, b) return a.order < b.order end)
  storage.auto_decon.pipe_prototypes = candidates
  return candidates
end

---@return { name: string, categories: table<string, boolean> }[]
local function ensure_pipe_prototypes()
  if storage.auto_decon.pipe_prototypes then return storage.auto_decon.pipe_prototypes end
  return M.cache_pipe_prototypes()
end

---@param ghost LuaEntity
---@param point MapPosition.struct
---@return string[]?
local function ghost_connection_categories_at(ghost, point)
  local proto = ghost.ghost_prototype
  if not proto or not proto.object_name or proto.object_name ~= "LuaEntityPrototype" then return nil end

  local success, boxes = pcall(function() return proto.fluidbox_prototypes end)
  if not success or not boxes then return nil end

  local dir_index = math.floor((ghost.direction or 0) / 4) + 1
  local gpos = ghost.position --[[@as MapPosition.struct]]

  for _, fb in pairs(boxes) do
    for _, conn in pairs(fb.pipe_connections) do
      if conn.connection_type == "normal" and conn.positions then
        local rel = position.ensure_explicit(conn.positions[dir_index] or conn.positions[1])
        local abs_x = gpos.x + rel.x
        local abs_y = gpos.y + rel.y
        local dx, dy = abs_x - point.x, abs_y - point.y
        if (dx * dx + dy * dy) < (GHOST_MATCH_DISTANCE * GHOST_MATCH_DISTANCE) then
          return conn.connection_category
        end
      end
    end
  end
  return nil
end

---@class AutoDeconPipeNeighbour
---@field offset { x: number, y: number }
---@field categories string[]

---@param neighbour_drill LuaEntity
---@param data AutoDeconStorage
---@return boolean
local function skip_depleted_drill_neighbour(neighbour_drill, data)
  if neighbour_drill.to_be_deconstructed() then return true end
  if data.queued[neighbour_drill.unit_number] then return true end
  if state.is_drill_depleted(neighbour_drill) then return true end
  return false
end

---@param drill LuaEntity
---@param data AutoDeconStorage
---@return AutoDeconPipeNeighbour[]
function M.find_neighbours(drill, data)
  local neighbours = {}
  if compat.fluidbox_count(drill) ~= 1 then return neighbours end

  local dpos = drill.position --[[@as MapPosition.struct]]
  local surface = drill.surface

  for _, conn in pairs(compat.pipe_connections(drill, 1)) do
    if conn.connection_type == "normal" then
      local cpos = conn.position --[[@as MapPosition.struct]]
      local offset = { x = cpos.x - dpos.x, y = cpos.y - dpos.y }

      local neighbour_entity = conn.target and compat.connection_target_entity(conn.target)
      local skip = neighbour_entity and neighbour_entity.type == "mining-drill"
        and skip_depleted_drill_neighbour(neighbour_entity, data)

      if not skip then
        if conn.target then
          local target_proto = compat.connection_fluidbox_prototype(conn.target, conn.target_fluidbox_index)
          local target_conns = target_proto and target_proto.pipe_connections
          local target_conn = conn.target_pipe_connection_index and target_conns and target_conns[conn.target_pipe_connection_index]
          if target_conn then
            table.insert(neighbours, { offset = offset, categories = target_conn.connection_category })
          end
        elseif conn.target_position then
          local tpos = conn.target_position --[[@as MapPosition.struct]]
          local ghosts = surface.find_entities_filtered{
            area = { { tpos.x - GHOST_SEARCH_RADIUS, tpos.y - GHOST_SEARCH_RADIUS }, { tpos.x + GHOST_SEARCH_RADIUS, tpos.y + GHOST_SEARCH_RADIUS } },
            name = "entity-ghost"
          }
          for _, ghost in ipairs(ghosts) do
            local categories = ghost_connection_categories_at(ghost, tpos)
            if categories then
              table.insert(neighbours, { offset = offset, categories = categories })
              break
            end
          end
        end
      end
    end
  end

  return neighbours
end

---@param drill LuaEntity
---@param name string
---@return string quality, number count
local function pick_best_quality(drill, name)
  local best_quality, best_count = "normal", -1
  local pos = position.ensure_explicit(drill.position)
  local networks = drill.surface.find_logistic_networks_by_construction_area(pos, drill.force)
  for _, network in pairs(networks) do
    if network.valid then
      local stationary = true
      for _, cell in pairs(network.cells) do
        if cell.mobile then
          stationary = false
          break
        end
      end
      if stationary then
        for _, item in pairs(network.get_contents()) do
          if item.name == name and item.count > best_count then
            best_count = item.count
            best_quality = item.quality or "normal"
          end
        end
      end
    end
  end
  return best_quality, math.max(best_count, 0)
end

---@param drill LuaEntity
---@param neighbours AutoDeconPipeNeighbour[]
---@return { name: string, quality: string }?
function M.choose_pipe(drill, neighbours)
  if #neighbours < 2 then return nil end

  local candidates = ensure_pipe_prototypes()
  local matching = {}
  for _, candidate in ipairs(candidates) do
    local match_all = true
    for _, neighbour in ipairs(neighbours) do
      local match_this = false
      for _, cat in ipairs(neighbour.categories) do
        if candidate.categories[cat] then
          match_this = true
          break
        end
      end
      if not match_this then
        match_all = false
        break
      end
    end
    if match_all then
      table.insert(matching, candidate)
    end
  end
  if #matching == 0 then return nil end

  local dpos = drill.position --[[@as MapPosition.struct]]
  local surface = drill.surface
  local fitting = {}
  for _, candidate in ipairs(matching) do
    local mask = prototypes.entity[candidate.name].collision_mask.layers
    local fits = true
    for _, neighbour in ipairs(neighbours) do
      local tile = surface.get_tile(dpos.x + neighbour.offset.x, dpos.y + neighbour.offset.y)
      for layer in pairs(mask) do
        if tile.collides_with(layer) then
          fits = false
          break
        end
      end
      if not fits then break end
    end
    if fits then
      table.insert(fitting, candidate)
    end
  end
  if #fitting == 0 then return nil end

  ---@type string?, string, number
  local best_name, best_quality, best_count = nil, "normal", 0
  for _, candidate in ipairs(fitting) do
    local quality, count = pick_best_quality(drill, candidate.name)
    if count > best_count then
      best_name, best_quality, best_count = candidate.name, quality, count
    end
  end
  if best_name then return { name = best_name, quality = best_quality } end

  for _, candidate in ipairs(fitting) do
    if candidate.name == "pipe" then
      return { name = "pipe", quality = "normal" }
    end
  end

  local fallback = fitting[1] --[[@as { name: string, categories: table<string, boolean> }]]
  return { name = fallback.name, quality = "normal" }
end

---@param drill LuaEntity
---@param pipe_type { name: string, quality: string }
---@param neighbours AutoDeconPipeNeighbour[]
---@return LuaEntity[]
function M.build_ghosts(drill, pipe_type, neighbours)
  local ghosts = {}
  local placed = {}
  local surface = drill.surface
  local dpos = drill.position --[[@as MapPosition.struct]]

  local function place(x, y)
    local key = x .. ":" .. y
    if placed[key] then return end

    local existing = surface.find_entities_filtered{
      area = { { dpos.x + x - 0.1, dpos.y + y - 0.1 }, { dpos.x + x + 0.1, dpos.y + y + 0.1 } },
      name = { pipe_type.name, "entity-ghost" }
    }
    for _, entity in ipairs(existing) do
      if entity.name == pipe_type.name or (entity.type == "entity-ghost" and entity.ghost_name == pipe_type.name) then
        placed[key] = true
        return
      end
    end

    local ghost = surface.create_entity{
      name = "entity-ghost",
      position = { dpos.x + x, dpos.y + y },
      force = drill.force,
      inner_name = pipe_type.name,
      quality = pipe_type.quality,
      raise_built = true
    }
    placed[key] = true
    if ghost then table.insert(ghosts, ghost) end
  end

  for _, neighbour in ipairs(neighbours) do
    local x, y = neighbour.offset.x, neighbour.offset.y
    place(x, y)

    while math.abs(x) >= 0.75 do
      x = x > 0 and x - 1 or x + 1
      place(x, y)
    end

    while math.abs(y) >= 0.75 do
      y = y > 0 and y - 1 or y + 1
      place(x, y)
    end
  end

  return ghosts
end

return M
