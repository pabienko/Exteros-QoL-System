local lib_player = require("__exteros-lib__.player")
local lib_entity = require("__exteros-lib__.entity")
local lib_box = require("__exteros-lib__.box")
local lib_math = require("__exteros-lib__.math")
local lib_position = require("__exteros-lib__.position")
local lib_quality = require("__exteros-lib__.quality")
local lib_storage = require("__exteros-lib__.storage")
local mod_gui = require("mod-gui")
local balancers = require("features.belt-brush.balancers")

local M = {}

local LABEL_PREFIX = "Belt Brush"

local FRAME_NAME = "exteros_qol_belt_brush_frame"
local FLOW_NAME = "exteros_qol_belt_brush_flow"
local LABEL_NAME = "exteros_qol_belt_brush_label"
local TEXT_NAME = "exteros_qol_belt_brush_text"
local UP_NAME = "exteros_qol_belt_brush_up"
local DOWN_NAME = "exteros_qol_belt_brush_down"
local RESET_NAME = "exteros_qol_belt_brush_reset"

---@type table<string, boolean>
local BRUSHABLE_TYPES = {
  ["transport-belt"] = true,
  ["underground-belt"] = true,
  ["loader"] = true,
  ["loader-1x1"] = true,
  ["pipe-to-ground"] = true,
  ["pipe"] = true,
  ["wall"] = true,
  ["heat-pipe"] = true,
  ["inserter"] = true,
}

local refreshing = false

local belt_brush_state = lib_storage.player_table("belt_brush", function() return { lanes = 1, mode = "straight" } end)
local belt_brush_tick = lib_storage.player_table("belt_brush_tick")

---@param x number
---@param y number
---@param flip_horizontal boolean
---@param flip_vertical boolean
---@return number, number
local function apply_flip(x, y, flip_horizontal, flip_vertical)
  if flip_horizontal then x = -x end
  if flip_vertical then y = -y end
  return x, y
end

---@param x number
---@param y number
---@param direction defines.direction
---@return number, number
local function apply_rotation(x, y, direction)
  if direction == defines.direction.east then
    return -y, x
  elseif direction == defines.direction.south then
    return -x, -y
  elseif direction == defines.direction.west then
    return y, -x
  end
  return x, y
end

---@param player_index uint
---@return table?
local function peek_state(player_index)
  return belt_brush_state.peek(player_index)
end

---@param player_index uint
---@return table
local function get_state(player_index)
  return belt_brush_state.get(player_index)
end

---@param player_index uint
local function clear_state(player_index)
  belt_brush_state.clear(player_index)
end

---@param stack LuaItemStack?
---@return boolean
local function is_our_blueprint(stack)
  return stack ~= nil and stack.valid_for_read and stack.is_blueprint and stack.label ~= nil
    and stack.label:find("^" .. LABEL_PREFIX) ~= nil and not stack.allow_manual_label_change
end

---@param cursor_stack LuaItemStack?
---@return table?
local function get_matched(cursor_stack)
  if not cursor_stack or not cursor_stack.valid_for_read then return nil end

  if is_our_blueprint(cursor_stack) then
    local entities = cursor_stack.get_blueprint_entities()
    if not entities then return nil end
    for _, entity in ipairs(entities) do
      local proto = prototypes.entity[entity.name]
      if proto and BRUSHABLE_TYPES[proto.type] then
        return { name = entity.name, quality = entity.quality or "normal" }
      end
    end
    return nil
  end

  local place_result = cursor_stack.prototype.place_result
  if not place_result or not BRUSHABLE_TYPES[place_result.type] then return nil end

  local quality = lib_quality.name_of(cursor_stack)
  return { name = place_result.name, quality = quality }
end

---@param name string
---@return number
local function collision_width(name)
  local proto = prototypes.entity[name]
  if not proto then return 1 end
  local box = lib_box.ensure_explicit(proto.collision_box)
  return math.ceil(box.right_bottom.x - box.left_top.x)
end

---@param entity table
---@param quality string
---@return table
local function apply_quality(entity, quality)
  if quality and quality ~= "normal" then
    entity.quality = quality
  end
  return entity
end

---@param name string
---@param quality string
---@param lanes integer
---@return table[]
local function build_straight(name, quality, lanes)
  local width = collision_width(name)
  local half = math.ceil(lanes / 2)
  local entities = {}
  for i = 1, lanes do
    entities[i] = apply_quality({
      entity_number = i,
      name = name,
      position = { x = (i - half) * width - width / 2, y = -0.5 },
      direction = 0,
    }, quality)
  end
  return entities
end

---@param name string
---@param quality string
---@param lanes integer
---@return table[]
local function build_corner_left(name, quality, lanes)
  local half = math.ceil(lanes / 2)
  local entities = {}
  local index = 0
  for ix = 1, lanes do
    for iy = 1, lanes do
      index = index + 1
      local cx = ix - 0.5
      local cy = iy - 0.5
      local direction = (cx + cy <= lanes) and 12 or 0
      entities[index] = apply_quality({
        entity_number = index,
        name = name,
        position = { x = cx - half, y = cy - half },
        direction = direction,
      }, quality)
    end
  end
  return entities
end

---@param name string
---@param quality string
---@param lanes integer
---@return table[]
local function build_corner_right(name, quality, lanes)
  local entities = build_corner_left(name, quality, lanes)
  for _, entity in ipairs(entities) do
    entity.direction = (0 - (entity.direction or 0)) % 16
    entity.position.x = -entity.position.x
  end
  return entities
end

---@param name string
---@param quality string
---@param lanes integer
---@param max number
---@return table[]
local function build_underground(name, quality, lanes, max)
  local half = math.ceil(lanes / 2)
  local half_max = math.ceil(max / 2)
  local entities = {}
  local index = 0
  for i = 1, lanes do
    index = index + 1
    entities[index] = apply_quality({
      entity_number = index,
      name = name,
      direction = 0,
      type = "input",
      position = { x = i - 0.5 - half, y = -0.5 + half_max },
    }, quality)

    index = index + 1
    entities[index] = apply_quality({
      entity_number = index,
      name = name,
      direction = 0,
      type = "output",
      position = { x = i - 0.5 - half, y = -(0.5 + max) + half_max },
    }, quality)
  end
  return entities
end

---@param name string
---@param quality string
---@param lanes integer
---@param max number
---@return table[]
local function build_pipe(name, quality, lanes, max)
  local half = math.ceil(lanes / 2)
  local half_max = math.ceil(max / 2)
  local entities = {}
  local index = 0
  for i = 1, lanes do
    index = index + 1
    entities[index] = apply_quality({
      entity_number = index,
      name = name,
      direction = 0,
      position = { x = i - 0.5 - half, y = 0.5 - half_max },
    }, quality)

    index = index + 1
    entities[index] = apply_quality({
      entity_number = index,
      name = name,
      direction = 8,
      position = { x = i - 0.5 - half, y = (0.5 + max) - half_max },
    }, quality)
  end
  return entities
end

---@param name string
---@param quality string
---@param lanes integer
---@param max number
---@return table[]
local function build_cascade(name, quality, lanes, max)
  local half = math.ceil(lanes / 2)
  local half_max = math.ceil(max / 2)
  local entities = {}
  local index = 0
  for r = 0, lanes - 1 do
    local row_y = 0.5 + r * (max + 1)
    for c = 0, lanes - r - 1 do
      local x = 0.5 + c - half

      index = index + 1
      entities[index] = apply_quality({
        entity_number = index,
        name = name,
        direction = 8,
        type = "input",
        position = { x = x, y = row_y - half_max },
      }, quality)

      index = index + 1
      entities[index] = apply_quality({
        entity_number = index,
        name = name,
        direction = 8,
        type = "output",
        position = { x = x, y = row_y + max - half_max },
      }, quality)
    end
  end
  return entities
end

---@param name string
---@param quality string
---@param mode string
---@param lanes integer
---@param max_underground number?
---@return table[]
local function build_entities_for_mode(name, quality, mode, lanes, max_underground)
  if mode == "corner_left" then return build_corner_left(name, quality, lanes) end
  if mode == "corner_right" then return build_corner_right(name, quality, lanes) end
  if mode == "underground" and max_underground and max_underground > 0 then
    return build_underground(name, quality, lanes, max_underground)
  end
  if mode == "pipe" and max_underground and max_underground > 0 then
    return build_pipe(name, quality, lanes, max_underground)
  end
  if mode == "cascade" and max_underground and max_underground > 0 then
    return build_cascade(name, quality, lanes, max_underground)
  end
  return build_straight(name, quality, lanes)
end

---@param lanes integer
---@return integer[]
local function build_output_list(lanes)
  local list = {}
  if balancers[lanes .. "x" .. lanes] then
    table.insert(list, lanes)
  end
  for m = 1, 32 do
    if m ~= lanes and balancers[lanes .. "x" .. m] then
      table.insert(list, m)
    end
  end
  return list
end

---@param cursor_stack LuaItemStack
---@param belt_name string
---@param quality string
---@param lanes integer
---@param output integer?
---@return boolean
local function apply_balancer(cursor_stack, belt_name, quality, lanes, output)
  if not output then return false end

  local key = lanes .. "x" .. output
  local blueprint_string = balancers[key]
  if not blueprint_string then return false end

  cursor_stack.clear_blueprint()
  local import_result = cursor_stack.import_stack(blueprint_string)
  if import_result ~= 0 then return false end

  local belt_proto = prototypes.entity[belt_name]
  local underground_name = belt_proto and belt_proto.related_underground_belt
    and belt_proto.related_underground_belt.name
  if not underground_name then
    underground_name = belt_name:gsub("transport%-belt$", "") .. "underground-belt"
  end
  local splitter_name = belt_name:gsub("transport%-belt$", "") .. "splitter"

  if not prototypes.entity[underground_name] or not prototypes.entity[splitter_name] then
    return false
  end

  local entities = cursor_stack.get_blueprint_entities()
  if not entities then return false end

  for _, entity in ipairs(entities) do
    local entity_proto = prototypes.entity[entity.name]
    if entity_proto then
      if entity_proto.type == "transport-belt" then
        entity.name = belt_name
      elseif entity_proto.type == "underground-belt" then
        entity.name = underground_name
      elseif entity_proto.type == "splitter" then
        entity.name = splitter_name
      end
    end
    if quality ~= "normal" then
      entity.quality = quality
    end
  end

  cursor_stack.set_blueprint_entities(entities)
  cursor_stack.label = LABEL_PREFIX .. " Balancers " .. lanes .. "x" .. output
  cursor_stack.allow_manual_label_change = false
  return true
end

---@param player LuaPlayer
---@return LuaGuiElement?
local function get_frame(player)
  return mod_gui.get_frame_flow(player)[FRAME_NAME]
end

---@param player LuaPlayer
local function destroy_window(player)
  local frame = get_frame(player)
  if frame and frame.valid then
    frame.destroy()
  end
end

---@param player LuaPlayer
---@param state table
local function build_window(player, state)
  local root = mod_gui.get_frame_flow(player)
  if root[FRAME_NAME] then
    root[FRAME_NAME].destroy()
  end

  local frame = root.add{
    type = "frame",
    name = FRAME_NAME,
    style = mod_gui.frame_style,
    direction = "horizontal",
  }

  local flow = frame.add{
    type = "flow",
    name = FLOW_NAME,
    direction = "horizontal",
  }

  flow.add{
    type = "label",
    name = LABEL_NAME,
    style = "heading_2_label",
    caption = { "exteros-qol-belt-brush.caption" },
  }

  flow.add{
    type = "textfield",
    name = TEXT_NAME,
    style = "short_number_textfield",
    numeric = true,
    lose_focus_on_confirm = true,
    clear_and_focus_on_right_click = true,
    text = tostring(state.lanes or 1),
    tooltip = { "exteros-qol-belt-brush.textfield" },
  }

  flow.add{
    type = "button",
    name = UP_NAME,
    style = "tool_button",
    caption = "+",
    tooltip = { "exteros-qol-belt-brush.up" },
  }

  flow.add{
    type = "button",
    name = DOWN_NAME,
    style = "tool_button",
    caption = "-",
    tooltip = { "exteros-qol-belt-brush.down" },
  }

  flow.add{
    type = "sprite-button",
    name = RESET_NAME,
    style = "tool_button_red",
    sprite = "utility/reset",
    tooltip = { "exteros-qol-belt-brush.reset" },
    enabled = (state.lanes or 1) ~= 1,
  }
end

---@param player LuaPlayer
---@param state table
local function update_window(player, state)
  local frame = get_frame(player)
  if not frame or not frame.valid then
    build_window(player, state)
    return
  end

  local flow = frame[FLOW_NAME]
  if not flow or not flow.valid then
    build_window(player, state)
    return
  end

  local textfield = flow[TEXT_NAME]
  if textfield and textfield.valid then
    textfield.text = tostring(state.lanes or 1)
  end

  local reset = flow[RESET_NAME]
  if reset and reset.valid then
    reset.enabled = (state.lanes or 1) ~= 1
  end
end

---@param player LuaPlayer
local function refresh_cursor(player)
  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end

  refreshing = true
  local temp = game.create_inventory(1)
  temp[1].set_stack(cursor_stack)
  player.cursor_stack_temporary = true
  player.clear_cursor()

  local refreshed_stack = player.cursor_stack
  if refreshed_stack then
    refreshed_stack.set_stack(temp[1])
    player.cursor_stack_temporary = true
  end

  temp.destroy()
  refreshing = false
end

---@param player LuaPlayer
---@param cursor_stack LuaItemStack
---@param state table
local function apply_mode(player, cursor_stack, state)
  local mode = state.mode or "straight"
  local name = state.name
  local quality = state.quality or "normal"
  local lanes = state.lanes or 1

  if mode == "balancer" then
    if apply_balancer(cursor_stack, name, quality, lanes, state.output) then
      refresh_cursor(player)
      return
    end
    state.mode = "straight"
    state.output = nil
    mode = "straight"
  end

  local proto = prototypes.entity[name]
  local max_underground = proto and proto.max_underground_distance
  local entities = build_entities_for_mode(name, quality, mode, lanes, max_underground)

  cursor_stack.set_blueprint_entities(entities)
  cursor_stack.label = LABEL_PREFIX
  cursor_stack.allow_manual_label_change = false

  refresh_cursor(player)
end

---@param player LuaPlayer
---@param state table
local function return_item(player, state)
  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end

  local proto = prototypes.entity[state.name]
  local place_item = proto and proto.items_to_place_this and proto.items_to_place_this[1]
  local item_name = place_item and place_item.name

  cursor_stack.clear()
  player.cursor_stack_temporary = false

  if item_name then
    local inventory = player.get_main_inventory()
    local found = inventory and inventory.valid and inventory.find_item_stack({ name = item_name, quality = state.quality })
    if found and found.valid_for_read then
      cursor_stack.set_stack(found)
      found.clear()
    else
      player.cursor_ghost = { name = item_name, quality = state.quality }
    end
  end

  state.mode = "straight"
end

---@param state table
---@param entity_type string?
local function normalize_mode(state, entity_type)
  local mode = state.mode
  if mode == "corner_left" or mode == "corner_right" then
    if entity_type ~= "transport-belt" then state.mode = "straight" end
  elseif mode == "balancer" then
    if entity_type ~= "transport-belt" then
      state.mode = "straight"
      state.output = nil
    end
  elseif mode == "underground" then
    if entity_type ~= "underground-belt" then state.mode = "straight" end
  elseif mode == "cascade" then
    if entity_type ~= "underground-belt" then state.mode = "straight" end
  elseif mode == "pipe" then
    if entity_type ~= "pipe-to-ground" then state.mode = "straight" end
  elseif not mode then
    state.mode = "straight"
  end
end

---@param player LuaPlayer
---@param lanes integer
local function build_or_clear(player, lanes)
  if not lib_player.is_connected(player) then return end

  local cursor_stack = player.cursor_stack
  local matched = get_matched(cursor_stack)
  if not matched then
    destroy_window(player)
    clear_state(player.index)
    return
  end

  local state = get_state(player.index)
  lanes = lib_math.clamp(math.floor(lanes), 1, 32)
  state.lanes = lanes
  state.name = matched.name
  state.quality = matched.quality

  local proto = prototypes.entity[matched.name]
  normalize_mode(state, proto and proto.type)

  if lanes <= 1 and is_our_blueprint(cursor_stack) then
    return_item(player, state)
  elseif lanes >= 2 then
    if not is_our_blueprint(cursor_stack) then
      if not player.clear_cursor() then
        update_window(player, state)
        return
      end

      cursor_stack = player.cursor_stack
      if not cursor_stack then
        update_window(player, state)
        return
      end

      cursor_stack.set_stack("blueprint")
      cursor_stack.clear_blueprint()
    end
    apply_mode(player, cursor_stack, state)
  end

  update_window(player, state)
end

---@param player LuaPlayer
---@return table?, LuaEntityPrototype?
local function get_matched_state(player)
  local matched = get_matched(player.cursor_stack)
  if not matched then return nil, nil end

  local proto = prototypes.entity[matched.name]
  if not proto then return nil, nil end

  local state = get_state(player.index)
  state.name = matched.name
  state.quality = matched.quality
  return state, proto
end

function M.on_player_cursor_stack_changed(event)
  if refreshing then return end

  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local existing = peek_state(player.index)
  build_or_clear(player, existing and existing.lanes or 1)
end

function M.on_gui_click(e)
  if not e.element or not e.element.valid then return end

  local name = e.element.name
  if name ~= UP_NAME and name ~= DOWN_NAME and name ~= RESET_NAME then return end

  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local state = peek_state(player.index)
  local lanes = (state and state.lanes) or 1

  if name == UP_NAME then
    lanes = lanes + 1
  elseif name == DOWN_NAME then
    lanes = lanes - 1
  else
    lanes = 1
  end

  build_or_clear(player, lanes)
end

function M.on_gui_confirmed(e)
  if not e.element or not e.element.valid then return end
  if e.element.name ~= TEXT_NAME then return end

  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local state = peek_state(player.index)
  local fallback = (state and state.lanes) or 1
  local typed = tonumber(e.element.text)
  local lanes = typed and math.floor(typed) or fallback

  build_or_clear(player, lanes)
end

function M.on_belt_brush_increase(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local state = peek_state(player.index)
  build_or_clear(player, ((state and state.lanes) or 1) + 1)
end

function M.on_belt_brush_decrease(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local state = peek_state(player.index)
  build_or_clear(player, ((state and state.lanes) or 1) - 1)
end

function M.on_belt_brush_clear(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  destroy_window(player)
  clear_state(player.index)
end

function M.on_belt_brush_corners(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local state, proto = get_matched_state(player)
  if not state or not proto then return end

  if proto.type == "transport-belt" then
    if state.mode == "corner_left" then
      state.mode = "corner_right"
    elseif state.mode == "corner_right" then
      state.mode = "straight"
    else
      state.mode = "corner_left"
    end
  elseif proto.type == "underground-belt" then
    state.mode = (state.mode == "underground") and "straight" or "underground"
  elseif proto.type == "pipe-to-ground" then
    state.mode = (state.mode == "pipe") and "straight" or "pipe"
  else
    return
  end

  build_or_clear(player, state.lanes or 1)
end

function M.on_belt_brush_balancers(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local state, proto = get_matched_state(player)
  if not state or not proto then return end

  if proto.type == "transport-belt" then
    local lanes = state.lanes or 1
    local list = build_output_list(lanes)

    if #list == 0 then
      state.mode = "straight"
      state.output = nil
    else
      local next_index = 1
      if state.mode == "balancer" and state.output then
        for i, output in ipairs(list) do
          if output == state.output then
            next_index = i + 1
            break
          end
        end
      end

      if next_index > #list then
        state.mode = "straight"
        state.output = nil
      else
        state.mode = "balancer"
        state.output = list[next_index]
      end
    end
  elseif proto.type == "underground-belt" then
    state.mode = (state.mode == "cascade") and "straight" or "cascade"
  else
    return
  end

  build_or_clear(player, state.lanes or 1)
end

function M.on_built_entity(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local entity = event.entity
  if not lib_entity.is_valid(entity) then return end
  if entity.type ~= "entity-ghost" then return end
  if not is_our_blueprint(player.cursor_stack) then return end

  local ghost_type = entity.ghost_type
  if not (BRUSHABLE_TYPES[ghost_type] or ghost_type == "splitter") then return end
  if entity.surface ~= player.physical_surface then return end

  local ghost_position = lib_position.ensure_explicit(entity.position)
  local player_position = lib_position.ensure_explicit(player.physical_position)
  local dx = ghost_position.x - player_position.x
  local dy = ghost_position.y - player_position.y
  if (dx * dx + dy * dy) > (player.build_distance ^ 2) then return end

  local ghost_proto = entity.ghost_prototype
  local place_item = ghost_proto and ghost_proto.items_to_place_this and ghost_proto.items_to_place_this[1]
  if not place_item then return end

  local quality = lib_quality.name_of(entity)
  local count = place_item.count or 1

  local inventory = player.get_main_inventory()
  if not inventory or not inventory.valid then return end
  if inventory.get_item_count({ name = place_item.name, quality = quality }) < count then return end

  local revived = entity.silent_revive({ raise_revive = true, overflow = inventory })
  if revived then
    inventory.remove({ name = place_item.name, quality = quality, count = count })
  end
end

function M.on_pre_build(event)
  local player = game.get_player(event.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end
  if not is_our_blueprint(cursor_stack) then return end

  local state = peek_state(player.index)
  if not state or not state.mode or state.mode == "straight" then return end

  local last_tick = belt_brush_tick.peek(player.index)
  if last_tick and (game.tick - last_tick) < 2 then return end
  belt_brush_tick.set(player.index, game.tick)

  local entities = cursor_stack.get_blueprint_entities()
  if not entities or #entities == 0 then return end

  local min_x, min_y, max_x, max_y
  for _, entity in ipairs(entities) do
    local position = lib_position.ensure_explicit(entity.position)
    if not min_x or position.x < min_x then min_x = position.x end
    if not min_y or position.y < min_y then min_y = position.y end
    if not max_x or position.x > max_x then max_x = position.x end
    if not max_y or position.y > max_y then max_y = position.y end
  end

  local corners = {
    { x = min_x, y = min_y },
    { x = max_x, y = min_y },
    { x = min_x, y = max_y },
    { x = max_x, y = max_y },
  }

  local t_min_x, t_min_y, t_max_x, t_max_y
  for _, corner in ipairs(corners) do
    local x, y = apply_flip(corner.x, corner.y, event.flip_horizontal, event.flip_vertical)
    x, y = apply_rotation(x, y, event.direction)
    if not t_min_x or x < t_min_x then t_min_x = x end
    if not t_min_y or y < t_min_y then t_min_y = y end
    if not t_max_x or x > t_max_x then t_max_x = x end
    if not t_max_y or y > t_max_y then t_max_y = y end
  end

  local expanded = lib_box.expand({ left_top = { x = t_min_x, y = t_min_y }, right_bottom = { x = t_max_x, y = t_max_y } }, 0.5)

  local offset_x = math.floor(event.position.x) + 0.5
  local offset_y = math.floor(event.position.y) + 0.5

  local area = {
    left_top = { x = expanded.left_top.x + offset_x, y = expanded.left_top.y + offset_y },
    right_bottom = { x = expanded.right_bottom.x + offset_x, y = expanded.right_bottom.y + offset_y },
  }

  local ghosts = player.surface.find_entities_filtered({ area = area, type = "entity-ghost", force = player.force })
  for _, ghost in ipairs(ghosts) do
    if ghost.valid then
      local ghost_type = ghost.ghost_type
      if BRUSHABLE_TYPES[ghost_type] or ghost_type == "splitter" then
        ghost.destroy()
      end
    end
  end
end

function M.on_disable()
  for _, player in pairs(game.players) do
    destroy_window(player)
    clear_state(player.index)
  end
end

M.events = {
  [defines.events.on_player_cursor_stack_changed] = M.on_player_cursor_stack_changed,
  [defines.events.on_gui_click] = M.on_gui_click,
  [defines.events.on_gui_confirmed] = M.on_gui_confirmed,
  [defines.events.on_built_entity] = M.on_built_entity,
  [defines.events.on_pre_build] = M.on_pre_build,
  ["exteros-qol-belt-brush-corners"] = M.on_belt_brush_corners,
  ["exteros-qol-belt-brush-balancers"] = M.on_belt_brush_balancers,
  ["exteros-qol-belt-brush-increase"] = M.on_belt_brush_increase,
  ["exteros-qol-belt-brush-decrease"] = M.on_belt_brush_decrease,
  ["exteros-qol-belt-brush-clear"] = M.on_belt_brush_clear,
}

return M
