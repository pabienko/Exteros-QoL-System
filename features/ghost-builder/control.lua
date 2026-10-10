local core = require("core.init")

local M = {}

local ENABLED_SETTING = "exteros-qol-ghost-builder-enabled"
local ENTITIES_SETTING = "exteros-qol-ghost-builder-entities"
local UPGRADES_SETTING = "exteros-qol-ghost-builder-upgrades"
local TILES_SETTING = "exteros-qol-ghost-builder-tiles"
local MODULES_SETTING = "exteros-qol-ghost-builder-modules"

---@type table<string, boolean>
local HOLDING_BLUEPRINT_LIKE_TYPES = {
  ["blueprint"] = true,
  ["blueprint-book"] = true,
  ["deconstruction-item"] = true,
  ["upgrade-item"] = true,
  ["selection-tool"] = true,
}

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

---@return table<uint, boolean>
local function get_off_storage()
  storage.ghost_builder_off = storage.ghost_builder_off or {}
  return storage.ghost_builder_off
end

---@param player_index uint
---@return boolean
local function is_off(player_index)
  return get_off_storage()[player_index] == true
end

---@param player LuaPlayer
---@param setting_name string
---@return boolean
local function player_setting(player, setting_name)
  return settings.get_player_settings(player)[setting_name].value == true
end

---@param player LuaPlayer
---@return boolean
local function holding_blueprint_like(player)
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and HOLDING_BLUEPRINT_LIKE_TYPES[cursor_stack.type] then
    return true
  end
  if player.cursor_record then
    return true
  end
  return false
end

---@param player LuaPlayer?
---@return boolean
local function player_ready(player)
  if not core.validation.is_player_valid(player) then return false end
  ---@cast player LuaPlayer
  if player.controller_type ~= defines.controllers.character then return false end
  if not player.character or not player.character.valid then return false end
  if is_off(player.index) then return false end
  if holding_blueprint_like(player) then return false end
  return true
end

---@param player LuaPlayer
---@param target LuaEntity
---@return boolean
local function in_build_range(player, target)
  local character = player.character
  if not character then return false end

  local player_position = core.position.ensure_explicit(character.position)
  local box = core.box.ensure_explicit(target.selection_box or target.bounding_box)

  local dx = 0
  if player_position.x < box.left_top.x then
    dx = box.left_top.x - player_position.x
  elseif player_position.x > box.right_bottom.x then
    dx = player_position.x - box.right_bottom.x
  end

  local dy = 0
  if player_position.y < box.left_top.y then
    dy = box.left_top.y - player_position.y
  elseif player_position.y > box.right_bottom.y then
    dy = player_position.y - box.right_bottom.y
  end

  local distance = math.sqrt(dx * dx + dy * dy)
  return distance <= player.build_distance
end

---@param player LuaPlayer
---@param selected LuaEntity?
---@return boolean
local function selection_ready(player, selected)
  if not core.validation.is_entity_valid(selected) then return false end
  ---@cast selected LuaEntity
  if selected.force ~= player.force then return false end
  if not in_build_range(player, selected) then return false end
  return true
end

---@param player LuaPlayer
---@param items_to_place_this { name: string, count: number }[]?
---@param quality string
---@return string?, number?
local function find_available_item(player, items_to_place_this, quality)
  if not items_to_place_this then return nil end
  local inventory = player.get_main_inventory()
  if not inventory then return nil end
  for _, entry in ipairs(items_to_place_this) do
    if inventory.get_item_count({ name = entry.name, quality = quality }) >= entry.count then
      return entry.name, entry.count
    end
  end
  return nil
end

---@param player LuaPlayer
---@param position MapPosition
---@param name string
---@param quality string
---@param count number
local function refund(player, position, name, quality, count)
  if not name or count <= 0 then return end

  local inventory = player.get_main_inventory()
  local inserted = 0
  if inventory then
    inserted = inventory.insert({ name = name, quality = quality, count = count })
  end

  local leftover = count - inserted
  if leftover > 0 then
    player.surface.spill_item_stack({
      position = position,
      stack = { name = name, quality = quality, count = leftover },
      enable_looted = false,
      force = player.force,
    })
  end
end

---@param entity LuaEntity
---@param player LuaPlayer
---@return boolean any_inserted
local function fulfil_modules(entity, player)
  local proxy = entity.item_request_proxy
  if not proxy or not proxy.valid then return false end

  local module_inventory = entity.get_module_inventory()
  if not module_inventory then return false end

  local plan = proxy.insert_plan
  if not plan then return false end

  local main_inventory = player.get_main_inventory()
  if not main_inventory then return false end

  local any_inserted = false
  local remaining_plan = {}

  for _, request in ipairs(plan) do
    local item_name = request.id and request.id.name
    local quality = (request.id and request.id.quality) or "normal"
    local remaining_positions = {}

    for _, position in ipairs((request.items and request.items.in_inventory) or {}) do
      local filled = false

      if position.inventory == module_inventory.index then
        local slot = module_inventory[position.stack + 1]
        if slot and not slot.valid_for_read and item_name
            and main_inventory.get_item_count({ name = item_name, quality = quality }) > 0 then
          player.remove_item({ name = item_name, quality = quality, count = 1 })
          slot.set_stack({ name = item_name, quality = quality, count = 1 })
          any_inserted = true
          filled = true
        end
      end

      if not filled then
        table.insert(remaining_positions, position)
      end
    end

    local kept_items = {
      grid_count = request.items and request.items.grid_count,
      in_inventory = #remaining_positions > 0 and remaining_positions or nil,
    }

    if kept_items.grid_count or kept_items.in_inventory then
      table.insert(remaining_plan, { id = request.id, items = kept_items })
    end
  end

  if any_inserted then
    if #remaining_plan == 0 then
      proxy.destroy()
    else
      local ok = pcall(function() proxy.insert_plan = remaining_plan end)
      if not ok then
        local target = proxy.proxy_target
        proxy.destroy()
        if target and target.valid then
          target.surface.create_entity({
            name = "item-request-proxy",
            position = target.position,
            force = target.force,
            target = target,
            modules = remaining_plan,
          })
        end
      end
    end
  end

  return any_inserted
end

---@param player LuaPlayer
---@param ghost LuaEntity
---@param options { entities: boolean, modules: boolean }
local function try_build_entity_ghost(player, ghost, options)
  if not options.entities then return end

  local ghost_prototype = ghost.ghost_prototype --[[@as LuaEntityPrototype?]]
  if not ghost_prototype then return end

  local quality = ghost.quality and ghost.quality.name or "normal"
  local item_name, item_count = find_available_item(player, ghost_prototype.items_to_place_this, quality)
  if not item_name then return end
  ---@cast item_count number

  local position = ghost.position
  local removed = player.remove_item({ name = item_name, quality = quality, count = item_count })
  if removed < item_count then
    refund(player, position, item_name, quality, removed)
    return
  end

  local _, revived_entity = ghost.revive({ raise_revive = true, overflow = player.get_main_inventory() })

  if not revived_entity then
    refund(player, position, item_name, quality, item_count)
    return
  end

  if options.modules then
    fulfil_modules(revived_entity, player)
  end
end

---@param player LuaPlayer
---@param entity LuaEntity
---@param options { upgrades: boolean }
local function try_apply_upgrade(player, entity, options)
  if not options.upgrades then return end
  if not entity.to_be_upgraded() then return end

  local target_prototype, target_quality_prototype = entity.get_upgrade_target()
  if not target_prototype then return end
  local target_quality = target_quality_prototype and target_quality_prototype.name or "normal"

  local item_name, item_count = find_available_item(player, target_prototype.items_to_place_this, target_quality)
  if not item_name then return end
  ---@cast item_count number

  local old_items_to_place = entity.prototype.items_to_place_this
  local old_item = old_items_to_place and old_items_to_place[1]
  local old_quality = entity.quality and entity.quality.name or "normal"

  local position = entity.position
  local removed = player.remove_item({ name = item_name, quality = target_quality, count = item_count })
  if removed < item_count then
    refund(player, position, item_name, target_quality, removed)
    return
  end

  local new_entity = entity.apply_upgrade()

  if not new_entity then
    refund(player, position, item_name, target_quality, item_count)
    return
  end

  if old_item then
    refund(player, position, old_item.name, old_quality, old_item.count)
  end
end

---@param old_tile LuaTile
---@return { name: string, quality: string, count: number }[]?
local function mined_tile_products(old_tile)
  local mineable = old_tile.prototype.mineable_properties
  if not mineable or not mineable.minable then return nil end

  local products = {}
  for _, product in ipairs(mineable.products or {}) do
    if product.type == "item" then
      local amount = math.floor(core.compat.product_expected_amount(product) + 0.5)
      if amount > 0 then
        table.insert(products, { name = product.name, quality = "normal", count = amount })
      end
    end
  end

  if #products == 0 then return nil end
  return products
end

---@param player LuaPlayer
---@param ghost LuaEntity
---@param options { tiles: boolean }
local function try_build_tile_ghost(player, ghost, options)
  if not options.tiles then return end

  local ghost_prototype = ghost.ghost_prototype --[[@as LuaTilePrototype?]]
  if not ghost_prototype then return end

  local quality = ghost.quality and ghost.quality.name or "normal"
  local item_name, item_count = find_available_item(player, ghost_prototype.items_to_place_this, quality)
  if not item_name then return end
  ---@cast item_count number

  local position = ghost.position
  local old_tile = ghost.surface.get_tile(position.x, position.y)
  local replaced_products
  if old_tile and old_tile.valid and old_tile.prototype.name ~= ghost_prototype.name then
    replaced_products = mined_tile_products(old_tile)
  end

  local removed = player.remove_item({ name = item_name, quality = quality, count = item_count })
  if removed < item_count then
    refund(player, position, item_name, quality, removed)
    return
  end

  ghost.revive({ raise_revive = true, overflow = player.get_main_inventory() })

  if ghost.valid then
    refund(player, position, item_name, quality, item_count)
    return
  end

  if replaced_products then
    for _, product in ipairs(replaced_products) do
      refund(player, position, product.name, product.quality, product.count)
    end
  end
end

---@param event EventData.on_selected_entity_changed
function M.on_selected_entity_changed(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not player_ready(player) then return end
  ---@cast player LuaPlayer

  local selected = player.selected
  if not selection_ready(player, selected) then return end
  ---@cast selected LuaEntity

  local p_settings = settings.get_player_settings(player)
  local options = {
    entities = p_settings[ENTITIES_SETTING].value == true,
    upgrades = p_settings[UPGRADES_SETTING].value == true,
    tiles = p_settings[TILES_SETTING].value == true,
    modules = p_settings[MODULES_SETTING].value == true,
  }

  if selected.type == "entity-ghost" then
    try_build_entity_ghost(player, selected, options)
  elseif selected.type == "tile-ghost" then
    try_build_tile_ghost(player, selected, options)
  elseif selected.to_be_upgraded() then
    try_apply_upgrade(player, selected, options)
  elseif options.modules and selected.item_request_proxy then
    fulfil_modules(selected, player)
  end
end

---@param event EventData.on_built_entity
function M.on_built_entity(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  if is_off(player.index) then return end
  if not player_setting(player, MODULES_SETTING) then return end

  local entity = event.entity
  if not core.validation.is_entity_valid(entity) then return end
  ---@cast entity LuaEntity
  if not entity.item_request_proxy then return end

  fulfil_modules(entity, player)
end

---@param event EventData.CustomInputEvent
function M.on_ghost_builder_toggle(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local off_storage = get_off_storage()
  local turning_off = not off_storage[player.index]
  off_storage[player.index] = turning_off or nil

  player.create_local_flying_text({
    text = { turning_off and "exteros-qol-ghost-builder.off" or "exteros-qol-ghost-builder.on" },
    create_at_cursor = true,
  })
end

function M.init()
  storage.ghost_builder_off = storage.ghost_builder_off or {}
end

function M.on_configuration_changed()
  storage.ghost_builder_off = storage.ghost_builder_off or {}
end

---@param event EventData.on_player_removed
function M.on_player_removed(event)
  get_off_storage()[event.player_index] = nil
end

return M
