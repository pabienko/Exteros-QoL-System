-- features/even-distribution/control.lua

local constants = require("features.even-distribution.constants")
local utils = require("features.even-distribution.utils")
local distribution = require("features.even-distribution.distribution")

--- @class DragState
--- @field balance boolean
--- @field entities LuaEntity[]
--- @field item {name: string, quality: string}
--- @field labels table<uint, LuaRenderObject>
--- @field last_tick uint
--- @field player LuaPlayer

--- @class LastSelectedState
--- @field cursor_count uint
--- @field entity LuaEntity
--- @field hand_location ItemStackLocation
--- @field item ItemStackDefinition
--- @field tick uint

local function validate_entities(drag_state)
  local entities = drag_state.entities
  local valid_entities = {}
  local valid_count = 0
  for i = 1, #entities do
    local entity = entities[i]
    if entity.valid then
      valid_count = valid_count + 1
      valid_entities[valid_count] = entity
    end
  end
  drag_state.entities = valid_entities
end

local function finish_drag(drag_state)
  if not drag_state.player.valid then
    return
  end

  -- Destroy labels
  for _, label in pairs(drag_state.labels) do
    if label.valid then
      label.destroy()
    end
  end

  validate_entities(drag_state)

  local entities = drag_state.entities
  local num_entities = #entities
  if num_entities == 0 then return end

  local item = drag_state.item
  local item_localised_name = prototypes.item[item.name].localised_name
  if item.quality ~= "normal" then
    item_localised_name = { "", item_localised_name, " (", prototypes.quality[item.quality].localised_name, ")" }
  end

  local player = drag_state.player
  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end
  
  local main_inventory = player.get_main_inventory()
  if not main_inventory then return end

  -- Calculate entity deltas
  local counts
  local player_total = utils.get_item_count(main_inventory, cursor_stack, item)
  if drag_state.balance then
    counts = distribution.get_balanced_distribution(entities, item, player_total)
  else
    counts = distribution.get_even_distribution(player_total, num_entities)
  end

  for i = 1, num_entities do
    local entity = entities[i]
    local to_insert = counts[i]

    local item_spec = { name = item.name, count = to_insert, quality = item.quality }
    local transferred = utils.transfer(player, entity, item_spec)

    -- Show flying text
    local color = constants.colors.white
    if transferred == 0 then
      color = constants.colors.red
    elseif transferred ~= math.abs(to_insert) then
      color = constants.colors.yellow
    end
    player.create_local_flying_text({
      text = { "", to_insert > 0 and "-" or "+", transferred, " [item=", item.name, "] ", item_localised_name },
      position = entity.position,
      color = color,
    })
  end
end

-- Event Handlers
script.on_init(function()
  storage.drag = {}
  storage.last_selected = {}
end)

script.on_configuration_changed(function()
  -- Tento blok zajistí migraci a inicializaci dat pro staré savy.
  -- Pokud v perzistentním úložišti neexistují tabulky, vytvoří je.
  if storage.drag == nil then
    storage.drag = {}
  end
  if storage.last_selected == nil then
    storage.last_selected = {}
  end
end)

script.on_event(defines.events.on_selected_entity_changed, function(e)
  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end

  local selected = player.selected
  local cursor_stack = player.cursor_stack
  if not selected or selected.type == "loader" or selected.type == "loader-1x1" or not cursor_stack or not cursor_stack.valid_for_read then
    storage.last_selected[e.player_index] = nil
    return
  end
  
  local main_inventory = player.get_main_inventory()
  if not main_inventory then return end

  storage.last_selected[e.player_index] = {
    cursor_count = cursor_stack.count,
    entity = selected,
    hand_location = player.hand_location,
    item = {
      name = cursor_stack.name,
      quality = cursor_stack.quality.name,
      count = utils.get_item_count(main_inventory, cursor_stack, { name = cursor_stack.name, quality = cursor_stack.quality.name }),
    },
    tick = game.tick,
  }
end)

script.on_event(defines.events.on_player_fast_transferred, function(e)
  if not e.from_player then return end

  local entity = e.entity
  if not entity.valid then return end

  local selected_state = storage.last_selected[e.player_index]
  if not selected_state or selected_state.tick ~= game.tick or not selected_state.entity.valid or selected_state.entity ~= entity then
    return
  end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end

  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end

  local main_inventory = player.get_main_inventory()
  if not main_inventory then return end

  local new_count = utils.get_item_count(main_inventory, cursor_stack, selected_state.item)
  local inserted = selected_state.item.count - new_count
  if inserted > 0 then
    local item = { name = selected_state.item.name, quality = selected_state.item.quality, count = inserted }
    utils.transfer(entity, player, item)
  elseif utils.get_entity_item_count(entity, { name = selected_state.item.name, quality = selected_state.item.quality }) == 0 then
    return
  end

  local drag_state = storage.drag[e.player_index]
  if not drag_state then
    local player_settings = settings.get_player_settings(player)
    drag_state = {
      balance = e.is_split ~= player_settings["even-distribution-swap-balance"].value,
      entities = {},
      item = { name = selected_state.item.name, quality = selected_state.item.quality },
      last_tick = game.tick,
      labels = {},
      player = player,
      clear_cursor_setting = player.mod_settings["even-distribution-clear-cursor"],
      ticks_setting = player.mod_settings["even-distribution-ticks"],
    }
    storage.drag[e.player_index] = drag_state
  end

  drag_state.last_tick = game.tick
  player.clear_local_flying_texts()

  local entities = drag_state.entities
  local labels = drag_state.labels
  local unit_number = entity.unit_number
  
  -- Only validate and add if we're adding a new entity
  if not labels[unit_number] then
    validate_entities(drag_state)
    -- Refresh reference after validation (creates new array)
    entities = drag_state.entities
    table.insert(entities, entity)
  end

  local total = selected_state.item.count
  if drag_state.balance then
    for i = 1, #entities do
      total = total + utils.get_entity_item_count(entities[i], drag_state.item)
    end
  end
  local counts = distribution.get_even_distribution(total, #entities)
  for i = 1, #entities do
    local current_entity = entities[i]
    local current_unit_number = current_entity.unit_number
    local label = labels[current_unit_number]
    if not label or not label.valid then
      local color = constants.colors.white
      if drag_state.balance then color = constants.colors.yellow end
      label = rendering.draw_text({
        color = color,
        players = { e.player_index },
        surface = current_entity.surface,
        target = current_entity,
        text = "",
      })
      labels[current_unit_number] = label
    end
    label.text = counts[i]
  end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(e)
  local drag_state = storage.drag[e.player_index]
  if not drag_state then return end

  local cursor_stack = drag_state.player.cursor_stack
  local cursor_item = cursor_stack and cursor_stack.valid_for_read and cursor_stack.name
  if drag_state.item.name == cursor_item then return end

  storage.drag[e.player_index] = nil
  finish_drag(drag_state)
end)

script.on_event(defines.events.on_tick, function()
  -- Early return if no active drag states
  local drag = storage.drag
  if not drag or next(drag) == nil then
    return
  end
  
  -- Collect indices to remove to avoid modifying table during iteration
  local to_remove = {}
  for player_index, drag_state in pairs(drag) do
    if not drag_state.player.valid then
        to_remove[#to_remove + 1] = { index = player_index, finish = false }
    else
        -- Use cached settings if available, otherwise fall back to direct access
        local clear_cursor_setting = drag_state.clear_cursor_setting or drag_state.player.mod_settings["even-distribution-clear-cursor"]
        local clear_cursor = clear_cursor_setting.value
        if not clear_cursor then
            local ticks_setting = drag_state.ticks_setting or drag_state.player.mod_settings["even-distribution-ticks"]
            local ticks = ticks_setting.value
            if drag_state.last_tick + ticks <= game.tick then
                to_remove[#to_remove + 1] = { index = player_index, finish = true, state = drag_state }
            end
        end
    end
  end
  
  -- Remove collected entries
  for _, entry in ipairs(to_remove) do
    drag[entry.index] = nil
    if entry.finish and entry.state then
      finish_drag(entry.state)
    end
  end
end)