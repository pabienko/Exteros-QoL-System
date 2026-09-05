local core = require("core.init")

local M = {}

local ENABLED_SETTING = "exteros-qol-copy-chest-enabled"
local BETWEEN_SURFACES_SETTING = "exteros-qol-copy-chest-between-surfaces"

---@type string[]
local CONTAINER_TYPES = { "container", "logistic-container", "infinity-container", "cargo-wagon" }

---@type table<string, defines.inventory>
local CONTAINER_INVENTORY = {
  ["container"] = defines.inventory.chest,
  ["logistic-container"] = defines.inventory.chest,
  ["infinity-container"] = defines.inventory.chest,
  ["cargo-wagon"] = defines.inventory.cargo_wagon,
}

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

---@return boolean
local function between_surfaces_allowed()
  return settings.global[BETWEEN_SURFACES_SETTING].value == true
end

local function get_storage()
  storage.copy_chest_source = storage.copy_chest_source or {}
  return storage.copy_chest_source
end

---@param player_index uint
local function forget_source(player_index)
  get_storage()[player_index] = nil
end

---@param entity LuaEntity
---@return LuaInventory?
local function get_container_inventory(entity)
  local inventory_type = CONTAINER_INVENTORY[entity.type]
  if not inventory_type then return nil end
  return entity.get_inventory(inventory_type)
end

---@param player LuaPlayer
---@param force LuaForce
---@return boolean
local function force_allowed(player, force)
  if force == player.force then return true end
  if force.name == "neutral" then return true end
  ---@cast force LuaForce
  local get_friend = player.force.get_friend
  return get_friend ~= nil and get_friend(force) == true
end

---@param source_data { unit_number: number?, surface_index: number, position: { x: number, y: number } }
---@return LuaEntity?
local function resolve_source(source_data)
  local surfaces = game.surfaces --[[@as table<number, LuaSurface>]]
  local surface = surfaces[source_data.surface_index]
  if not surface or not surface.valid then return nil end

  local candidates = surface.find_entities_filtered({
    position = source_data.position,
    type = CONTAINER_TYPES,
  })

  for _, candidate in pairs(candidates) do
    if core.validation.is_entity_valid(candidate) and candidate.unit_number == source_data.unit_number then
      return candidate
    end
  end

  return nil
end

---@param player LuaPlayer
---@param entity LuaEntity
---@param key string
local function show_message(player, entity, key)
  player.create_local_flying_text({
    text = { key },
    position = entity.position,
  })
end

function M.init()
  storage.copy_chest_source = storage.copy_chest_source or {}
end

function M.on_configuration_changed()
  storage.copy_chest_source = storage.copy_chest_source or {}
end

function M.on_copy_chest(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local selected = player.selected
  if not selected or not core.validation.is_entity_valid(selected) then
    forget_source(event.player_index)
    return
  end

  if not CONTAINER_INVENTORY[selected.type] then
    show_message(player, selected, "exteros-qol-chest.not-container")
    return
  end

  if not force_allowed(player, selected.force --[[@as LuaForce]]) then
    show_message(player, selected, "exteros-qol-chest.from-enemy")
    return
  end

  local inventory = get_container_inventory(selected)
  if not inventory or inventory.is_empty() then
    show_message(player, selected, "exteros-qol-chest.nothing-to-copy")
    return
  end

  local position = core.position.ensure_explicit(selected.position)
  get_storage()[event.player_index] = {
    unit_number = selected.unit_number,
    surface_index = selected.surface.index,
    position = { x = position.x, y = position.y },
    tick = event.tick,
  }

  show_message(player, selected, "exteros-qol-chest.source-picked")
end

function M.on_paste_chest(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local selected = player.selected
  if not selected or not core.validation.is_entity_valid(selected) then return end

  local source_data = get_storage()[event.player_index]
  if not source_data then return end

  if source_data.tick == event.tick then return end

  if not CONTAINER_INVENTORY[selected.type] then
    show_message(player, selected, "exteros-qol-chest.not-container")
    return
  end

  if not force_allowed(player, selected.force --[[@as LuaForce]]) then
    show_message(player, selected, "exteros-qol-chest.to-enemy")
    return
  end

  local source_entity = resolve_source(source_data)
  local source_inventory = source_entity and get_container_inventory(source_entity)

  if not source_inventory or source_inventory.is_empty() then
    forget_source(event.player_index)
    show_message(player, selected, "exteros-qol-chest.no-source")
    return
  end
  ---@cast source_entity LuaEntity

  if source_entity == selected then
    show_message(player, selected, "exteros-qol-chest.same-container")
    return
  end

  if not between_surfaces_allowed() then
    if source_entity.surface.index ~= selected.surface.index then
      show_message(player, selected, "exteros-qol-chest.not-same-surface")
      return
    end
    if player.surface.index ~= selected.surface.index then
      show_message(player, selected, "exteros-qol-chest.player-not-same-surface")
      return
    end
  end

  local target_inventory = get_container_inventory(selected) --[[@as LuaInventory]]
  local count_before = target_inventory.get_item_count()

  for i = 1, #source_inventory do
    local stack = source_inventory[i]
    if stack.valid_for_read then
      local inserted = target_inventory.insert(stack)
      if inserted > 0 then
        stack.count = stack.count - inserted
      end
    end
  end

  local count_after = target_inventory.get_item_count()

  if source_inventory.is_empty() then
    forget_source(event.player_index)
    show_message(player, selected, "exteros-qol-chest.all-moved")
  elseif count_after == count_before then
    show_message(player, selected, "exteros-qol-chest.none-moved")
  else
    show_message(player, selected, "exteros-qol-chest.some-moved")
  end
end

return M
