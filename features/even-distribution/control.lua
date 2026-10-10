local core = require("core.init")
local distribution = require("features.even-distribution.distribution")
local routing = require("features.even-distribution.routing")
local bar = require("core.bar")

local M = {}

local VEHICLE_TYPES = { car = true, ["spider-vehicle"] = true }

local function destroy_render_pair(pair)
  if pair.object_name == "LuaRenderObject" then
    if pair.valid then
      pair.destroy()
    end
    return
  end

  if pair.sprite and pair.sprite.valid then
    pair.sprite.destroy()
  end
  if pair.text and pair.text.valid then
    pair.text.destroy()
  end
end

local function destroy_labels(drag_state)
  for _, pair in pairs(drag_state.labels) do
    destroy_render_pair(pair)
  end
end

local function validate_drag_entities(drag_state)
  if core.debug.is_enabled() then
    core.debug.log("Validating drag entities for player " .. drag_state.player.name, "Even-Dist")
  end
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

local function entity_in_list(list, entity)
  for _, e in ipairs(list) do
    if e == entity then return true end
  end
  return false
end

---@param entity LuaEntity
---@param item ItemIDAndQualityIDPair|ItemWithQualityID
---@return table<uint, { inventory: LuaInventory, count: number }>
local function snapshot_entity_inventories(entity, item)
  local snapshot = {}
  local inventory_defines = core.constants.entity_transfer_inventories[entity.type] or {}
  local has_fuel_define = false

  for _, inventory_define in pairs(inventory_defines) do
    local inventory = entity.get_inventory(inventory_define)
    if inventory then
      snapshot[inventory.index] = { inventory = inventory, count = inventory.get_item_count(item) }
    end
    if inventory_define == defines.inventory.fuel then
      has_fuel_define = true
    end
  end

  if not has_fuel_define then
    local fuel_inventory = entity.get_fuel_inventory()
    if fuel_inventory then
      snapshot[fuel_inventory.index] = { inventory = fuel_inventory, count = fuel_inventory.get_item_count(item) }
    end
  end

  return snapshot
end

---@param player LuaPlayer
---@param main_inventory LuaInventory
---@param item ItemIDAndQualityIDPair|ItemWithQualityID
---@param target_count number
local function restore_cursor(player, main_inventory, item, target_count)
  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end

  local current = 0
  if cursor_stack.valid_for_read and cursor_stack.name == item.name and cursor_stack.quality.name == item.quality then
    current = cursor_stack.count
  end

  if current > target_count then
    core.inventory.transfer(player, main_inventory, { name = item.name, quality = item.quality, count = current - target_count })
  elseif current < target_count then
    core.inventory.transfer(main_inventory, player, { name = item.name, quality = item.quality, count = target_count - current })
  end
end

local function is_force_insert_enabled()
  local setting = settings.startup["exteros-qol-force-insert-enabled"]
  return setting ~= nil and setting.value == true
end

---@param entity LuaEntity
---@param item ItemIDAndQualityIDPair|ItemWithQualityID
---@param role string
---@param inventories LuaInventory[]
---@param p_settings LuaCustomTable
---@param force_insert_enabled boolean
---@return number
local function get_capacity(entity, item, role, inventories, p_settings, force_insert_enabled)
  local records = force_insert_enabled and bar.collect_limited(entity) or nil
  if records then bar.open(records) end

  local fuel_limit = role == "fuel" and {
    value = p_settings["even-distribution-fuel-limit"].value,
    unit = p_settings["even-distribution-fuel-limit-unit"].value,
  } or nil
  local ammo_limit = role == "ammo" and {
    value = p_settings["even-distribution-ammo-limit"].value,
    unit = p_settings["even-distribution-ammo-limit-unit"].value,
  } or nil

  local capacity = routing.capacity(role, inventories, item, fuel_limit, ammo_limit)

  if records then bar.close(records) end
  return capacity
end

---@param drag_state table
---@return { key: integer, entity: LuaEntity, role: string, inventories: LuaInventory[], cap: number, current: number, cap_total: number }[]
local function build_entries(drag_state)
  local p_settings = settings.get_player_settings(drag_state.player)
  local force_insert_enabled = is_force_insert_enabled()

  local entries = {}
  local valid_entities = {}
  drag_state.roles = {}

  for _, entity in pairs(drag_state.entities) do
    if entity.valid then
      local resolved = routing.resolve(entity, drag_state.item)
      if resolved then
        local unit_number = entity.unit_number
        if unit_number then
          drag_state.roles[unit_number] = resolved.role

          local current = 0
          for _, inventory in pairs(resolved.inventories) do
            current = current + inventory.get_item_count(drag_state.item)
          end

          local cap = get_capacity(entity, drag_state.item, resolved.role, resolved.inventories, p_settings, force_insert_enabled)

          table.insert(entries, {
            key = unit_number,
            entity = entity,
            role = resolved.role,
            inventories = resolved.inventories,
            cap = cap,
            current = current,
            cap_total = current + cap,
          })
          table.insert(valid_entities, entity)
        end
      end
    end
  end

  drag_state.entities = valid_entities
  return entries
end

---@param drag_state table
---@param player_total number
---@return { entity: LuaEntity, count: number }[], table[]
local function compute_distribution(drag_state, player_total)
  local entries = build_entries(drag_state)
  local dist = {}

  if drag_state.balance then
    local balance_entries = {}
    for i, entry in ipairs(entries) do
      balance_entries[i] = { key = entry.key, current = entry.current, cap_total = entry.cap_total }
    end
    local deltas = distribution.balance(balance_entries, player_total)
    for _, entry in ipairs(entries) do
      table.insert(dist, { entity = entry.entity, count = deltas[entry.key] or 0 })
    end
  else
    local even_entries = {}
    for i, entry in ipairs(entries) do
      even_entries[i] = { key = entry.key, cap = entry.cap }
    end
    local gives = distribution.even(player_total, even_entries)
    for _, entry in ipairs(entries) do
      table.insert(dist, { entity = entry.entity, count = gives[entry.key] or 0 })
    end
  end

  table.sort(dist, function(a, b) return a.count < b.count end)
  return dist, entries
end

local function prune_labels(drag_state, dist)
  local present = {}
  for _, data in ipairs(dist) do
    local unit_number = data.entity.unit_number
    if unit_number then present[unit_number] = true end
  end

  for unit_number, pair in pairs(drag_state.labels) do
    if not present[unit_number] then
      destroy_render_pair(pair)
      drag_state.labels[unit_number] = nil
    end
  end
end

local function update_markers(drag_state, dist, player_index)
  prune_labels(drag_state, dist)
  local labels = drag_state.labels

  for _, data in ipairs(dist) do
    local this_entity = data.entity
    local this_unit_number = this_entity.unit_number
    if this_unit_number then
      local pair = labels[this_unit_number]

      if not pair or not pair.sprite.valid or not pair.text.valid then
        local box = this_entity.selection_box
        local width = box.right_bottom.x - box.left_top.x
        local height = box.right_bottom.y - box.left_top.y
        local scale = 0.6 * math.min(width, height)

        local sprite = rendering.draw_sprite({
          sprite = "item/" .. drag_state.item.name,
          target = this_entity,
          x_scale = scale,
          y_scale = scale,
          players = { player_index },
          surface = this_entity.surface,
        })
        local text = rendering.draw_text({
          color = core.constants.colors.white,
          players = { player_index },
          surface = this_entity.surface,
          target = this_entity,
          text = "",
          alignment = "center",
          vertical_alignment = "middle",
          scale = 1.2,
        })
        pair = { sprite = sprite, text = text }
        labels[this_unit_number] = pair
      end

      local color = core.constants.colors.white
      if data.count == 0 then
        color = core.constants.colors.red
      elseif drag_state.balance then
        color = core.constants.colors.yellow
      end
      pair.text.color = color
      pair.text.text = tostring(data.count)
    end
  end
end

local function finish_drag(drag_state)
  destroy_labels(drag_state)

  if not core.validation.is_player_valid(drag_state.player) then
    return
  end

  local player = drag_state.player
  local controller_type = player.controller_type
  if controller_type ~= defines.controllers.character
     and controller_type ~= defines.controllers.god
     and controller_type ~= defines.controllers.editor then
    return
  end

  validate_drag_entities(drag_state)
  local entities = drag_state.entities
  if core.debug.is_enabled() then
    core.debug.log("Finishing drag for " .. player.name .. ". Entities count: " .. #entities, "Even-Dist")
  end
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

  local p_settings = settings.get_player_settings(player)
  local source = p_settings["even-distribution-source"].value

  local player_total
  if source == "hand" then
    player_total = (cursor_stack.valid_for_read and cursor_stack.name == item.name and cursor_stack.quality.name == item.quality)
      and cursor_stack.count or 0
  else
    player_total = core.inventory.get_player_item_count(main_inventory, cursor_stack, item)
  end

  if player_total == 0 and not drag_state.balance then return end

  local dist, entries = compute_distribution(drag_state, player_total)
  if #entries == 0 then return end

  local inventories_by_key = {}
  for _, entry in ipairs(entries) do
    inventories_by_key[entry.key] = entry.inventories
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

  local force_insert_enabled = is_force_insert_enabled()

  for _, data in pairs(dist) do
    local entity = data.entity
    local to_insert = data.count
    if to_insert ~= 0 then
      local item_spec = { name = item.name, count = to_insert, quality = item.quality }
      local inventories = entity.unit_number and inventories_by_key[entity.unit_number]
      local inventory = inventories and inventories[1]

      local transferred = 0
      if inventory then
        local records = to_insert > 0 and force_insert_enabled and bar.collect_limited(entity) or nil
        if records then bar.open(records) end
        transferred = core.inventory.transfer(work_inventory, inventory, item_spec)
        if records then bar.close(records) end
      end

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
    local to_main = core.inventory.transfer(work_inventory, main_inventory, { name = item.name, quality = item.quality, count = remainder })
    local still_remaining = remainder - to_main
    if still_remaining > 0 then
      local to_player = core.inventory.transfer(work_inventory, player, { name = item.name, quality = item.quality, count = still_remaining })
      if to_player < still_remaining then
        player.physical_surface.spill_inventory({
          position = player.physical_position,
          inventory = work_inventory,
          allow_belts = false,
        })
      end
    end
  end
  work_inventory.destroy()
end

local function init_storage()
  storage.drag = storage.drag or {}
  storage.last_selected = storage.last_selected or {}
  storage.even_distribution_ignored = storage.even_distribution_ignored or {}
end

local function ensure_storage()
  init_storage()
end

function M.init()
  ensure_storage()
end

function M.on_configuration_changed()
  ensure_storage()
  for _, drag_state in pairs(storage.drag) do
    destroy_labels(drag_state)
  end
  storage.drag = {}
  storage.last_selected = {}
end

function M.on_selected_entity_changed(e)
  if not settings.startup["exteros-qol-even-distribution-enabled"].value then return end
  ensure_storage()

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local selected = player.selected
  local cursor_stack = player.cursor_stack

  if not selected
     or selected.type == "loader"
     or selected.type == "loader-1x1"
     or selected.type == "character"
     or storage.even_distribution_ignored[selected.name]
     or not cursor_stack
     or not cursor_stack.valid_for_read then
    storage.last_selected[e.player_index] = nil
    return
  end

  local main_inventory = player.get_main_inventory()
  if not main_inventory then return end

  if core.debug.is_enabled() then
    core.debug.log("Selected entity changed for " .. player.name .. ": " .. (selected and selected.name or "nil"), "Even-Dist")
  end

  local item_pair = { name = cursor_stack.name, quality = cursor_stack.quality.name }

  storage.last_selected[e.player_index] = {
    cursor_count = cursor_stack.count,
    entity = selected,
    item = {
      name = item_pair.name,
      quality = item_pair.quality,
      count = core.inventory.get_player_item_count(main_inventory, cursor_stack, item_pair),
    },
    inventories = snapshot_entity_inventories(selected, item_pair),
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
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end

  local main_inventory = player.get_main_inventory()
  if not main_inventory then return end

  local item_pair = { name = selected_state.item.name, quality = selected_state.item.quality }
  local new_count = core.inventory.get_player_item_count(main_inventory, cursor_stack, item_pair)
  local inserted = selected_state.item.count - new_count

  if inserted > 0 then
    if selected_state.inventories then
      for _, snapshot in pairs(selected_state.inventories) do
        if snapshot.inventory.valid then
          local now = snapshot.inventory.get_item_count(item_pair)
          local delta = now - snapshot.count
          if delta > 0 then
            core.inventory.transfer(snapshot.inventory, player, { name = item_pair.name, quality = item_pair.quality, count = delta })
          end
        end
      end
    end
    restore_cursor(player, main_inventory, item_pair, selected_state.cursor_count)
  elseif core.inventory.get_entity_item_count(entity, item_pair) == 0 then
    return
  end

  local p_settings = settings.get_player_settings(player)
  local drag_state = storage.drag[e.player_index]

  if drag_state and (drag_state.item.name ~= item_pair.name or drag_state.item.quality ~= item_pair.quality) then
    storage.drag[e.player_index] = nil
    finish_drag(drag_state)
    drag_state = nil
  end

  local resolved = routing.resolve(entity, item_pair)
  if not resolved then return end

  if drag_state then
    validate_drag_entities(drag_state)
    local first_entity = drag_state.entities[1]
    if first_entity and not entity_in_list(drag_state.entities, entity) then
      local first_is_vehicle = VEHICLE_TYPES[first_entity.type] or false
      local this_is_vehicle = VEHICLE_TYPES[entity.type] or false
      if first_is_vehicle ~= this_is_vehicle then
        return
      end
    end
  end

  if not drag_state then
    if core.debug.is_enabled() then
      core.debug.log("Starting new drag for " .. player.name .. " with " .. item_pair.name, "Even-Dist")
    end
    drag_state = {
      balance = e.is_split ~= p_settings["even-distribution-swap-balance"].value,
      entities = {},
      item = item_pair,
      last_tick = game.tick,
      labels = {},
      roles = {},
      player = player,
    }
    storage.drag[e.player_index] = drag_state
  end

  drag_state.last_tick = game.tick
  player.clear_local_flying_texts()
  validate_drag_entities(drag_state)

  local unit_number = entity.unit_number
  if not unit_number then return end

  if not entity_in_list(drag_state.entities, entity) then
    table.insert(drag_state.entities, entity)
  end

  local total = p_settings["even-distribution-source"].value == "hand" and selected_state.cursor_count or selected_state.item.count
  local dist = compute_distribution(drag_state, total)
  update_markers(drag_state, dist, e.player_index)
end

function M.on_player_cursor_stack_changed(e)
  if not settings.startup["exteros-qol-even-distribution-enabled"].value then return end
  ensure_storage()
  local drag_state = storage.drag[e.player_index]
  if not drag_state then return end

  local cursor_stack = drag_state.player.cursor_stack
  local cursor_valid = cursor_stack and cursor_stack.valid_for_read

  if cursor_valid and cursor_stack.name == drag_state.item.name and cursor_stack.quality.name == drag_state.item.quality then
    return
  end

  storage.drag[e.player_index] = nil
  finish_drag(drag_state)
end

local function check_distribution_timer()
  ensure_storage()

  for player_index, drag_state in pairs(storage.drag) do
    if not core.validation.is_player_valid(drag_state.player) then
      destroy_labels(drag_state)
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
  if not settings.startup["exteros-qol-even-distribution-enabled"].value then return end
  check_distribution_timer()
end

function M.on_player_left_game(e)
  if not settings.startup["exteros-qol-even-distribution-enabled"].value then return end
  ensure_storage()

  local drag_state = storage.drag[e.player_index]
  if drag_state then
    destroy_labels(drag_state)
  end

  storage.drag[e.player_index] = nil
  storage.last_selected[e.player_index] = nil
end

function M.on_player_died(e)
  if not settings.startup["exteros-qol-even-distribution-enabled"].value then return end
  ensure_storage()

  local drag_state = storage.drag[e.player_index]
  if drag_state then
    destroy_labels(drag_state)
  end

  storage.drag[e.player_index] = nil
  storage.last_selected[e.player_index] = nil
end

function M.on_player_removed(e)
  ensure_storage()

  local drag_state = storage.drag[e.player_index]
  if drag_state then
    destroy_labels(drag_state)
  end

  storage.drag[e.player_index] = nil
  storage.last_selected[e.player_index] = nil
end

local function is_enabled()
  local setting = settings.startup["exteros-qol-even-distribution-enabled"]
  return setting ~= nil and setting.value == true
end

remote.add_interface("exteros-qol-even-distribution", {
  version = function() return 1 end,

  add_ignored_entity = function(name)
    if not is_enabled() or type(name) ~= "string" then return end
    ensure_storage()
    storage.even_distribution_ignored[name] = true
  end,

  remove_ignored_entity = function(name)
    if not is_enabled() or type(name) ~= "string" then return end
    ensure_storage()
    storage.even_distribution_ignored[name] = nil
  end,

  get_ignored_entities = function()
    if not is_enabled() then return {} end
    local out = {}
    for name in pairs(storage.even_distribution_ignored or {}) do
      out[name] = true
    end
    return out
  end,

  get_fuel_limit = function(player_index)
    if not is_enabled() or type(player_index) ~= "number" then return nil end
    local player = game.get_player(player_index)
    if not player then return nil end
    local p_settings = settings.get_player_settings(player)
    return {
      limit = p_settings["even-distribution-fuel-limit"].value,
      type = p_settings["even-distribution-fuel-limit-unit"].value,
    }
  end,

  get_ammo_limit = function(player_index)
    if not is_enabled() or type(player_index) ~= "number" then return nil end
    local player = game.get_player(player_index)
    if not player then return nil end
    local p_settings = settings.get_player_settings(player)
    return {
      limit = p_settings["even-distribution-ammo-limit"].value,
      type = p_settings["even-distribution-ammo-limit-unit"].value,
    }
  end,
})

return M
