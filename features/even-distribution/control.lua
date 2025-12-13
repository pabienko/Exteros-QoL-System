-- features/even-distribution/control.lua

local core = require("core.init")
local distribution = require("features.even-distribution.distribution")

-- Helper to validate entities
local function validate_entities(drag_state)
  drag_state.entities = core.validation.filter_valid_entities(drag_state.entities)
end

-- Core logic to finish drag
local function finish_drag(drag_state)
  if not core.validation.is_player_valid(drag_state.player) then return end

  -- Cleanup labels
  for _, label in pairs(drag_state.labels) do
    if label.valid then label.destroy() end
  end

  validate_entities(drag_state)
  local entities = drag_state.entities
  local num_entities = #entities
  if num_entities == 0 then return end

  local item = drag_state.item
  local player = drag_state.player
  local cursor_stack = player.cursor_stack
  local main_inventory = player.get_main_inventory()
  
  if not cursor_stack or not main_inventory then return end

  -- Calculate distribution
  local player_total = core.inventory.get_item_count(main_inventory, cursor_stack, item)
  local counts
  
  if drag_state.balance then
    counts = distribution.get_balanced_distribution(entities, item, player_total)
  else
    counts = distribution.get_even_distribution(player_total, num_entities)
  end

  -- Execute transfer
  local item_localised_name = prototypes.item[item.name].localised_name
  if item.quality and item.quality ~= "normal" then
     item_localised_name = {"", item_localised_name, " (", prototypes.quality[item.quality].localised_name, ")"}
  end

  for i = 1, num_entities do
    local entity = entities[i]
    local to_insert = counts[i]
    local item_spec = { name = item.name, count = to_insert, quality = item.quality }
    local transferred = core.inventory.transfer(player, entity, item_spec)

    -- Visual feedback
    local color = core.constants.colors.white
    if transferred == 0 then color = core.constants.colors.red
    elseif transferred ~= math.abs(to_insert) then color = core.constants.colors.yellow end
    
    player.create_local_flying_text({
      text = { "", to_insert > 0 and "-" or "+", transferred, " [item=", item.name, "] ", item_localised_name },
      position = entity.position,
      color = color,
    })
  end
end

-- Dynamic Tick Handler Logic
local function on_tick(event)
  local drag = storage.drag
  if not drag or next(drag) == nil then
    script.on_event(defines.events.on_tick, nil)
    return
  end

  local tick = event.tick
  local to_remove = {}

  for player_index, state in pairs(drag) do
    if not core.validation.is_player_valid(state.player) then
       to_remove[#to_remove+1] = {index = player_index, finish = false}
    else
       -- Check settings
       local clear_cursor_setting = state.clear_cursor_setting or state.player.mod_settings["even-distribution-clear-cursor"]
       if not clear_cursor_setting.value then
          local ticks_setting = state.ticks_setting or state.player.mod_settings["even-distribution-ticks"]
          local limit = ticks_setting.value or 60
          if (state.last_tick + limit) <= tick then
             to_remove[#to_remove+1] = {index = player_index, finish = true, state = state}
          end
       end
    end
  end

  for _, entry in ipairs(to_remove) do
    drag[entry.index] = nil
    if entry.finish then finish_drag(entry.state) end
  end
  
  if next(drag) == nil then
    script.on_event(defines.events.on_tick, nil)
  end
end

local function update_tick_handler()
  if storage.drag and next(storage.drag) then
    script.on_event(defines.events.on_tick, on_tick)
  else
    script.on_event(defines.events.on_tick, nil)
  end
end

-- Event Handlers
script.on_init(function()
  storage.drag = {}
  storage.last_selected = {}
  update_tick_handler()
end)

script.on_load(function()
  update_tick_handler()
end)

script.on_configuration_changed(function()
  if not storage.drag then storage.drag = {} end
  if not storage.last_selected then storage.last_selected = {} end
  update_tick_handler()
end)

script.on_event(defines.events.on_selected_entity_changed, function(e)
  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  
  local selected = player.selected
  local cursor = player.cursor_stack
  
  if not selected or selected.type == "loader" or selected.type == "loader-1x1" or not cursor or not cursor.valid_for_read then
     storage.last_selected[e.player_index] = nil
     return
  end
  
  local main_inv = player.get_main_inventory()
  if not main_inv then return end
  
  storage.last_selected[e.player_index] = {
    cursor_count = cursor.count,
    entity = selected,
    hand_location = player.hand_location,
    item = {
      name = cursor.name,
      quality = cursor.quality.name,
      count = core.inventory.get_item_count(main_inv, cursor, {name=cursor.name, quality=cursor.quality.name})
    },
    tick = game.tick
  }
end)

script.on_event(defines.events.on_player_fast_transferred, function(e)
  if not e.from_player then return end
  local entity = e.entity
  if not core.validation.is_entity_valid(entity) then return end
  
  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  
  local cursor = player.cursor_stack
  local main_inv = player.get_main_inventory()
  if not cursor or not cursor.valid_for_read or not main_inv then return end
  
  -- Get current item from cursor
  local current_item = {
    name = cursor.name,
    quality = cursor.quality.name
  }
  
  -- Check if we have a recent selection that matches (for inventory correction)
  local last_sel = storage.last_selected[e.player_index]
  local use_last_sel = last_sel and last_sel.entity == entity and 
                       last_sel.item.name == current_item.name and 
                       last_sel.item.quality == current_item.quality and
                       (last_sel.tick == game.tick or (game.tick - last_sel.tick) <= 1)
  
  if use_last_sel then
    -- Inventory correction logic (pull back items that were auto-inserted)
    local new_count = core.inventory.get_item_count(main_inv, cursor, last_sel.item)
    local inserted = last_sel.item.count - new_count
    
    if inserted > 0 then
      local item_spec = {name=last_sel.item.name, quality=last_sel.item.quality, count=inserted}
      core.inventory.transfer(entity, player, item_spec)
    elseif core.inventory.get_entity_item_count(entity, {name=last_sel.item.name, quality=last_sel.item.quality}) == 0 then
      -- Entity doesn't have this item and nothing was inserted, might be wrong target
      return
    end
  end
  
  -- Get current total count for the item
  local current_total = core.inventory.get_item_count(main_inv, cursor, current_item)
  
  -- Initialize or update drag state
  local drag_state = storage.drag[e.player_index]
  if not drag_state or drag_state.item.name ~= current_item.name or drag_state.item.quality ~= current_item.quality then
     local p_settings = settings.get_player_settings(player)
     drag_state = {
       balance = e.is_split ~= p_settings["even-distribution-swap-balance"].value,
       entities = {},
       item = {name=current_item.name, quality=current_item.quality},
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
  local uid = entity.unit_number
  
  if not labels[uid] then
    validate_entities(drag_state)
    entities = drag_state.entities -- refresh ref
    table.insert(entities, entity)
    
    -- Create label
    local color = drag_state.balance and core.constants.colors.yellow or core.constants.colors.white
    labels[uid] = rendering.draw_text({
      color = color,
      players = {e.player_index},
      surface = entity.surface,
      target = entity,
      text = "..."
    })
  end
  
  -- Update labels preview
  local total = current_total
  if drag_state.balance then
     for i=1, #entities do
       total = total + core.inventory.get_entity_item_count(entities[i], drag_state.item)
     end
  end
  
  local counts
  if drag_state.balance then
    counts = distribution.get_balanced_distribution(entities, drag_state.item, total) -- pass total for preview
  else
    counts = distribution.get_even_distribution(total, #entities)
  end
  
  for i=1, #entities do
    local lbl = labels[entities[i].unit_number]
    if lbl and lbl.valid then lbl.text = tostring(counts[i]) end
  end
  
  update_tick_handler()
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(e)
  local drag_state = storage.drag[e.player_index]
  if not drag_state then return end
  
  local cursor = drag_state.player.cursor_stack
  local cursor_name = cursor and cursor.valid_for_read and cursor.name
  
  -- If cursor changed (item cleared or swapped), finish drag
  if drag_state.item.name ~= cursor_name then
    storage.drag[e.player_index] = nil
    finish_drag(drag_state)
    update_tick_handler()
  end
end)
