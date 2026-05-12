local core = require("core.init")
local distribution = require("features.even-distribution.distribution")

local M = {}

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"].value then
    log("[Even-Dist] " .. msg)
  end
end

local function validate_drag_entities(drag_state)
  debug_log("Validating drag entities for player " .. drag_state.player.name)
  local entities = {}
  local i = 0
  for _, entity in pairs(drag_state.entities) do
    if entity.valid then
      i = i + 1
      entities[i] = entity
    end
  end
  drag_state.entities = entities
end

local function finish_drag(drag_state)
  if not core.validation.is_player_valid(drag_state.player) then
    return
  end
  
  local player = drag_state.player
  for _, label in pairs(drag_state.labels) do
    if label.valid then
      label.destroy()
    end
  end
  
  validate_drag_entities(drag_state)
  local entities = drag_state.entities
  debug_log("Finishing drag for " .. player.name .. ". Entities count: " .. #entities)
  if #entities == 0 then return end
  
  local item = drag_state.item
  local item_localised_name = prototypes.item[item.name].localised_name
  if item.quality ~= "normal" then
    item_localised_name = { "", item_localised_name, " (", prototypes.quality[item.quality].localised_name, ")" }
  end
  
  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end
  
  local main_inventory = player.get_main_inventory()
  if not main_inventory then return end
  
  local dist
  local player_total = core.inventory.get_player_item_count(main_inventory, cursor_stack, item)
  if player_total == 0 and not drag_state.balance then return end
  
  if drag_state.balance then
    dist = distribution.get_balanced_distribution(entities, item, player_total)
  else
    dist = distribution.get_even_distribution(player_total, entities)
  end
  
  local max_total = player_total
  for _, data in pairs(dist) do
    if data.count < 0 then
      max_total = max_total + -data.count
    end
  end
  
  local required_stacks = math.ceil(max_total / prototypes.item[item.name].stack_size) * 2
  if required_stacks <= 0 then return end
  
  local work_inventory = game.create_inventory(required_stacks)
  core.inventory.transfer(player, work_inventory, { name = item.name, quality = item.quality, count = player_total })
  
  for _, data in pairs(dist) do
    local entity = data.entity
    local to_insert = data.count
    if to_insert ~= 0 then
      local item_spec = { name = item.name, count = to_insert, quality = item.quality }
      local transferred = core.inventory.transfer(work_inventory, entity, item_spec)
      
      local color = core.constants.colors.white
      if transferred == 0 then
        color = core.constants.colors.red
      elseif transferred ~= math.abs(to_insert) then
        color = core.constants.colors.yellow
      end
      
      player.create_local_flying_text({
        text = { "", to_insert > 0 and "-" or "+", transferred, " [item=", item_spec.name, "] ", item_localised_name },
        position = entity.position,
        color = color,
      })
    end
  end
  
  local remainder = work_inventory.get_item_count(item)
  if remainder > 0 then
    local transferred = core.inventory.transfer(work_inventory, player, { name = item.name, quality = item.quality, count = remainder })
    if transferred < remainder then
      player.surface.spill_inventory({
        position = player.physical_position,
        inventory = work_inventory,
        force = player.force,
        allow_belts = false,
      })
    end
  end
  work_inventory.destroy()
end

local function init_storage()
  storage.drag = storage.drag or {}
  storage.last_selected = storage.last_selected or {}
end

local function ensure_storage()
  init_storage()
end

function M.init()
  ensure_storage()
end

function M.on_configuration_changed()
  ensure_storage()
end

function M.on_selected_entity_changed(e)
  ensure_storage()

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  
  local selected = player.selected
  local cursor_stack = player.cursor_stack
  
  if not selected or selected.type == "loader" or selected.type == "loader-1x1" or not cursor_stack or not cursor_stack.valid_for_read then
    storage.last_selected[e.player_index] = nil
    return
  end
  
  local main_inventory = player.get_main_inventory()
  if not main_inventory then return end
  
  debug_log("Selected entity changed for " .. player.name .. ": " .. (selected and selected.name or "nil"))
  
  storage.last_selected[e.player_index] = {
    cursor_count = cursor_stack.count,
    entity = selected,
    hand_location = player.hand_location,
    item = {
      name = cursor_stack.name,
      quality = cursor_stack.quality.name,
      count = core.inventory.get_player_item_count(main_inventory, cursor_stack, { name = cursor_stack.name, quality = cursor_stack.quality.name }),
    },
    tick = game.tick,
  }
end

function M.on_player_fast_transferred(e)
  if not settings.startup["exteros-qol-even-distribution-enabled"].value then return end
  if not e.from_player then return end

  ensure_storage()

  local entity = e.entity
  if not core.validation.is_entity_valid(entity) then return end
  
  local selected_state = storage.last_selected[e.player_index]
  if not selected_state or selected_state.tick ~= game.tick or not selected_state.entity.valid or selected_state.entity ~= entity then
    return
  end
  
  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  
  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end
  
  local main_inventory = player.get_main_inventory()
  if not main_inventory then return end
  
  local item_pair = { name = selected_state.item.name, quality = selected_state.item.quality }
  local new_count = core.inventory.get_player_item_count(main_inventory, cursor_stack, item_pair)
  local inserted = selected_state.item.count - new_count
  
  if inserted > 0 then
    local spec = { name = item_pair.name, quality = item_pair.quality, count = inserted }
    core.inventory.transfer(entity, player, spec)
  elseif core.inventory.get_entity_item_count(entity, item_pair) == 0 then
    return
  end
  
  local p_settings = settings.get_player_settings(player)
  local drag_state = storage.drag[e.player_index]
  
  if not drag_state then
    debug_log("Starting new drag for " .. player.name .. " with " .. item_pair.name)
    drag_state = {
      balance = e.is_split ~= p_settings["even-distribution-swap-balance"].value,
      entities = {},
      item = item_pair,
      last_tick = game.tick,
      labels = {},
      player = player,
    }
    storage.drag[e.player_index] = drag_state
  end
  
  drag_state.last_tick = game.tick
  player.clear_local_flying_texts()
  validate_drag_entities(drag_state)
  
  local entities = drag_state.entities
  local labels = drag_state.labels
  local unit_number = entity.unit_number
  
  if not labels[unit_number] then
    table.insert(entities, entity)
  end
  
  local total = selected_state.item.count
  if drag_state.balance then
    for i = 1, #entities do
      total = total + core.inventory.get_entity_item_count(entities[i], drag_state.item)
    end
  end
  
  local dist = distribution.get_even_distribution(total, entities)
  for _, data in pairs(dist) do
    local this_entity = data.entity
    local this_unit_number = this_entity.unit_number
    local label = labels[this_unit_number]
    
    if not label or not label.valid then
      local color = drag_state.balance and core.constants.colors.yellow or core.constants.colors.white
      label = rendering.draw_text({
        color = color,
        players = { e.player_index },
        surface = this_entity.surface,
        target = this_entity,
        text = "",
        alignment = "center",
        vertical_alignment = "middle"
      })
      labels[this_unit_number] = label
    end
    label.text = tostring(data.count)
  end
end

function M.on_player_cursor_stack_changed(e)
  ensure_storage()
  local drag_state = storage.drag[e.player_index]
  if not drag_state then return end
  
  local cursor_stack = drag_state.player.cursor_stack
  local cursor_item = cursor_stack and cursor_stack.valid_for_read and cursor_stack.name
  
  if drag_state.item.name == cursor_item then
    return
  end
  
  storage.drag[e.player_index] = nil
  finish_drag(drag_state)
end

local function check_distribution_timer()
  ensure_storage()

  for player_index, drag_state in pairs(storage.drag) do
    if not core.validation.is_player_valid(drag_state.player) then
      storage.drag[player_index] = nil
    else
      local p_settings = settings.get_player_settings(drag_state.player)
      local ticks = p_settings["even-distribution-ticks"].value
      if drag_state.last_tick and (drag_state.last_tick + ticks <= game.tick) then
        storage.drag[player_index] = nil
        finish_drag(drag_state)
      end
    end
  end
end

function M.on_tick()
  check_distribution_timer()
end

return M
