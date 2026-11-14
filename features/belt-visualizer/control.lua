local lib_player = require("__exteros-lib__.player")
local lib_entity = require("__exteros-lib__.entity")
local lib_position = require("__exteros-lib__.position")
local lib_render = require("__exteros-lib__.render")
local lib_storage = require("__exteros-lib__.storage")
local values = require("__exteros-lib__.internal.values")

local M = {}

local SHORTCUT = "exteros-qol-belt-visualizer-hover-toggle"

---@type table<string, boolean>
local HANDLED_TYPES = {
  ["transport-belt"] = true,
  ["underground-belt"] = true,
  ["splitter"] = true,
  ["loader"] = true,
  ["loader-1x1"] = true,
  ["linked-belt"] = true,
}

---@type string[]
local LANE_SEQUENCE = { "both", "left", "right" }

local HIGHLIGHT_COLOR = { r = 0.3, g = 0.9, b = 1, a = 1 }
local LANE_OFFSET = 0.2

---@type table<defines.direction, QolPosition>
local DIRECTION_VECTOR = {
  [defines.direction.north] = { x = 0, y = -1 },
  [defines.direction.east] = { x = 1, y = 0 },
  [defines.direction.south] = { x = 0, y = 1 },
  [defines.direction.west] = { x = -1, y = 0 },
}

---@alias BeltVisualizerDirection "upstream"|"downstream"

---@class BeltVisualizerQueueEntry
---@field entity LuaEntity
---@field direction BeltVisualizerDirection

---@class BeltVisualizerWalk
---@field queue BeltVisualizerQueueEntry[]
---@field head integer
---@field visited table<string, boolean>
---@field entities table<number, LuaEntity>
---@field root number
---@field mode string
---@field per_tick integer
---@field max_entities integer
---@field count integer

local belt_visualizer_ns = lib_storage.namespace("belt_visualizer", {
  walks = {},
  entities = {},
  renders = {},
  lane_mode = {},
  current_root = {},
  hover_mode = {},
  hover_last = {},
})

---@return table
local function get_storage()
  return belt_visualizer_ns.get()
end

---@param player LuaPlayer
---@return boolean
local function hover_mode_on(player)
  return get_storage().hover_mode[player.index] == true
end

---@param entity LuaEntity?
---@return boolean
local function is_handled(entity)
  if not lib_entity.is_valid(entity) then return false end
  ---@cast entity LuaEntity
  return HANDLED_TYPES[entity.type] == true
end

---@param entity LuaEntity
---@return LuaEntity[]
local function downstream_neighbours_of(entity)
  local list = {}

  local belt_neighbours = entity.belt_neighbours
  if belt_neighbours then
    for _, e in ipairs(belt_neighbours.outputs or {}) do table.insert(list, e) end
  end

  if entity.type == "underground-belt" and entity.belt_to_ground_type == "input" then
    local other = entity.underground_belt_neighbour
    if other then table.insert(list, other) end
  end

  if entity.type == "linked-belt" and entity.linked_belt_type == "input" then
    local linked = entity.linked_belt_neighbour
    if linked then table.insert(list, linked) end
  end

  return list
end

---@param entity LuaEntity
---@return LuaEntity[]
local function upstream_neighbours_of(entity)
  local list = {}

  local belt_neighbours = entity.belt_neighbours
  if belt_neighbours then
    for _, e in ipairs(belt_neighbours.inputs or {}) do table.insert(list, e) end
  end

  if entity.type == "underground-belt" and entity.belt_to_ground_type == "output" then
    local other = entity.underground_belt_neighbour
    if other then table.insert(list, other) end
  end

  if entity.type == "linked-belt" and entity.linked_belt_type == "output" then
    local linked = entity.linked_belt_neighbour
    if linked then table.insert(list, linked) end
  end

  return list
end

---@param direction BeltVisualizerDirection
---@param entity LuaEntity
---@return LuaEntity[]
local function neighbours_of(direction, entity)
  if direction == "downstream" then return downstream_neighbours_of(entity) end
  return upstream_neighbours_of(entity)
end

---@param player_index uint
local function destroy_renders(player_index)
  local renders = get_storage().renders[player_index]
  if not renders then return end
  lib_render.destroy(renders)
  get_storage().renders[player_index] = nil
end

---@param player_index uint
local function clear_player(player_index)
  destroy_renders(player_index)
  local store = get_storage()
  store.walks[player_index] = nil
  store.entities[player_index] = nil
  store.lane_mode[player_index] = nil
  store.current_root[player_index] = nil
end

---@param entity LuaEntity
---@return number
local function perpendicular_half_length(entity)
  if (entity.tile_width or 1) > 1 or (entity.tile_height or 1) > 1 then
    return 0.75
  end
  return 0.5
end

---@param player LuaPlayer
---@param entity LuaEntity
---@param mode string
---@return LuaRenderObject[]
local function draw_entity_lanes(player, entity, mode)
  if not entity.valid then return {} end

  local direction = entity.direction
  local vector = DIRECTION_VECTOR[direction]
  if not vector then return {} end

  local perpendicular = { x = -vector.y, y = vector.x }
  local position = lib_position.ensure_explicit(entity.position)
  local half = perpendicular_half_length(entity)

  local ids = {}

  ---@param offset number
  local function draw_lane(offset)
    local center = {
      x = position.x + perpendicular.x * offset,
      y = position.y + perpendicular.y * offset,
    }
    local from = { x = center.x - vector.x * half, y = center.y - vector.y * half }
    local to = { x = center.x + vector.x * half, y = center.y + vector.y * half }

    local line = rendering.draw_line({
      color = HIGHLIGHT_COLOR,
      width = 2,
      from = from,
      to = to,
      surface = entity.surface,
      players = { player },
      draw_on_ground = true,
    })
    table.insert(ids, line)
  end

  if mode == "both" or mode == "left" then
    draw_lane(-LANE_OFFSET)
  end
  if mode == "both" or mode == "right" then
    draw_lane(LANE_OFFSET)
  end

  return ids
end

---@param player LuaPlayer
---@param walk { entities: table<number, LuaEntity>, mode: string }
local function redraw_walk(player, walk)
  destroy_renders(player.index)
  local ids = {}
  for _, entity in pairs(walk.entities) do
    for _, id in ipairs(draw_entity_lanes(player, entity, walk.mode)) do
      table.insert(ids, id)
    end
  end
  get_storage().renders[player.index] = ids
end

---@param player LuaPlayer
---@param entity LuaEntity
---@param mode string
local function start_walk(player, entity, mode)
  clear_player(player.index)

  local per_tick = values.get_player(player, "exteros-qol-belt-visualizer-max-per-tick") --[[@as integer]]
  local max_entities = values.get_player(player, "exteros-qol-belt-visualizer-max-entities") --[[@as integer]]

  ---@type BeltVisualizerWalk
  local walk = {
    queue = {
      { entity = entity, direction = "upstream" },
      { entity = entity, direction = "downstream" },
    },
    head = 1,
    visited = {
      [entity.unit_number .. ":upstream"] = true,
      [entity.unit_number .. ":downstream"] = true,
    },
    entities = { [entity.unit_number] = entity },
    root = entity.unit_number,
    mode = mode,
    per_tick = per_tick,
    max_entities = max_entities,
    count = 1,
  }

  get_storage().walks[player.index] = walk
  get_storage().current_root[player.index] = entity.unit_number
  get_storage().lane_mode[player.index] = mode
end

---@param walk BeltVisualizerWalk
---@return boolean finished
local function advance_walk(walk)
  local processed = 0
  while processed < walk.per_tick and walk.head <= #walk.queue do
    local current = walk.queue[walk.head]
    walk.head = walk.head + 1

    if current and current.entity and current.entity.valid then
      for _, neighbour in ipairs(neighbours_of(current.direction, current.entity)) do
        if is_handled(neighbour) and neighbour.unit_number then
          local key = neighbour.unit_number .. ":" .. current.direction
          if not walk.visited[key] then
            walk.visited[key] = true
            if not walk.entities[neighbour.unit_number] then
              if walk.count >= walk.max_entities then
                return true
              end
              walk.entities[neighbour.unit_number] = neighbour
              walk.count = walk.count + 1
            end
            table.insert(walk.queue, { entity = neighbour, direction = current.direction })
          end
        end
      end
    end

    processed = processed + 1
  end

  return walk.head > #walk.queue
end

---@param e EventData.CustomInputEvent
function M.on_belt_visualizer_highlight(e)
  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local selected = player.selected
  if not is_handled(selected) then
    clear_player(player.index)
    return
  end
  ---@cast selected LuaEntity

  local store = get_storage()
  local current_root = store.current_root[player.index]
  local active_walk = store.walks[player.index]
  local has_highlight = store.entities[player.index] ~= nil or active_walk ~= nil

  if has_highlight and current_root == selected.unit_number then
    local current_mode = store.lane_mode[player.index] or "both"
    local next_index
    for i, mode in ipairs(LANE_SEQUENCE) do
      if mode == current_mode then next_index = i + 1 break end
    end

    if not next_index or next_index > #LANE_SEQUENCE then
      clear_player(player.index)
      return
    end

    local next_mode = LANE_SEQUENCE[next_index]
    if active_walk then
      active_walk.mode = next_mode
      store.lane_mode[player.index] = next_mode
      redraw_walk(player, active_walk)
    else
      store.lane_mode[player.index] = next_mode
      redraw_walk(player, { entities = store.entities[player.index], mode = next_mode })
    end
    return
  end

  start_walk(player, selected, "both")
end

---@param e EventData.on_lua_shortcut
function M.on_lua_shortcut(e)
  if e.prototype_name ~= SHORTCUT then return end

  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local store = get_storage()
  local new_state = not hover_mode_on(player)
  store.hover_mode[player.index] = new_state
  player.set_shortcut_toggled(SHORTCUT, new_state)

  if not new_state then
    clear_player(player.index)
    store.hover_last[player.index] = nil
  end
end

---@param e EventData.on_selected_entity_changed
function M.on_selected_entity_changed(e)
  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  if not hover_mode_on(player) then return end

  local store = get_storage()
  local selected = player.selected

  if not is_handled(selected) then
    if store.hover_last[player.index] then
      clear_player(player.index)
      store.hover_last[player.index] = nil
    end
    return
  end
  ---@cast selected LuaEntity

  if store.hover_last[player.index] == selected.unit_number then return end

  store.hover_last[player.index] = selected.unit_number
  start_walk(player, selected, "both")
end

function M.on_tick()
  local store = storage.belt_visualizer
  if not store or not next(store.walks) then return end

  for player_index, walk in pairs(store.walks) do
    local player = game.get_player(player_index)
    local pending = walk.queue[walk.head]
    if not lib_player.is_connected(player) or (pending and pending.object_name ~= nil) then
      store.walks[player_index] = nil
    else
      ---@cast player LuaPlayer
      local finished = advance_walk(walk)

      if finished then
        store.entities[player_index] = walk.entities
        store.walks[player_index] = nil
        redraw_walk(player, walk)
      end
    end
  end
end

function M.init()
  get_storage()
end

---@param player_index uint
local function full_reset(player_index)
  clear_player(player_index)
  get_storage().hover_last[player_index] = nil
end

function M.on_configuration_changed()
  get_storage()
  for _, player in pairs(game.players) do
    full_reset(player.index)
  end
end

function M.on_enable()
  for _, player in pairs(game.players) do
    player.set_shortcut_available(SHORTCUT, true)
  end
end

function M.on_disable()
  local store = get_storage()
  for _, player in pairs(game.players) do
    full_reset(player.index)
    store.hover_mode[player.index] = nil
    player.set_shortcut_available(SHORTCUT, false)
  end
end

---@param e EventData.on_player_removed
function M.on_player_removed(e)
  full_reset(e.player_index)
  get_storage().hover_mode[e.player_index] = nil
end

---@param e EventData.on_player_left_game
function M.on_player_left_game(e)
  full_reset(e.player_index)
end

---@param e EventData.on_player_died
function M.on_player_died(e)
  full_reset(e.player_index)
end

---@param e EventData.on_player_changed_surface
function M.on_player_changed_surface(e)
  full_reset(e.player_index)
end

M.events = {
  [defines.events.on_lua_shortcut] = M.on_lua_shortcut,
  [defines.events.on_selected_entity_changed] = M.on_selected_entity_changed,
  [defines.events.on_tick] = M.on_tick,
  [defines.events.on_player_removed] = M.on_player_removed,
  [defines.events.on_player_left_game] = M.on_player_left_game,
  [defines.events.on_player_died] = M.on_player_died,
  [defines.events.on_player_changed_surface] = M.on_player_changed_surface,
  ["exteros-qol-belt-visualizer-highlight"] = M.on_belt_visualizer_highlight,
}

return M
