local core = require("core.init")
local bar = core.bar

local M = {}

local ENABLED_SETTING = "exteros-qol-force-insert-enabled"
local ALWAYS_SETTING = "exteros-qol-force-insert-always"
local WINDOW_SETTING = "exteros-qol-force-insert-window"
local FALLBACK_WINDOW = 20

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"].value then
    log("[Force-Insert] " .. msg)
  end
end

local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value
end

local function window(player)
  return settings.get_player_settings(player)[WINDOW_SETTING].value
end

local function init_storage()
  storage.force_insert = storage.force_insert or {}
  storage.force_insert.pending = storage.force_insert.pending or {}
  storage.force_insert.drag = storage.force_insert.drag or {}
  storage.force_insert.probe = storage.force_insert.probe or {}
end

local function release_all(player_index)
  local pending = storage.force_insert.pending[player_index]
  if not pending then return end

  for _, entry in pairs(pending) do
    bar.close(entry.records)
    bar.restore_machines(entry.machines)
  end
  storage.force_insert.pending[player_index] = nil
end

---@param player LuaPlayer
---@param entity LuaEntity
---@param item { name: string, quality: string }
---@param always boolean
---@return boolean
function M.open_for(player, entity, item, always)
  init_storage()

  local records = bar.collect_limited(entity)
  if not records then return false end

  if not always then
    local room = 0
    for _, record in pairs(records) do
      room = room + record.inventory.get_insertable_count(item)
    end
    if room > 0 then
      return false
    end
  end

  bar.open(records)

  local room = 0
  for _, record in pairs(records) do
    room = room + record.inventory.get_insertable_count(item)
  end
  if room == 0 then
    bar.close(records)
    return false
  end

  local machines = bar.suppress_machines(entity)

  local pending = storage.force_insert.pending[player.index]
  if not pending then
    pending = {}
    storage.force_insert.pending[player.index] = pending
  end
  table.insert(pending, { records = records, machines = machines, tick = game.tick })

  debug_log("Opened bar for " .. player.name .. " on " .. entity.name)
  return true
end

---@param player_index uint
function M.release(player_index)
  init_storage()
  release_all(player_index)
end

function M.init()
  init_storage()
end

function M.on_configuration_changed()
  init_storage()
end

function M.on_force_insert_entity(e)
  if not enabled() then return end
  init_storage()

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local selected = player.selected
  if not core.validation.is_entity_valid(selected) then return end
  ---@cast selected LuaEntity

  local cursor_stack = player.cursor_stack
  if not cursor_stack or not cursor_stack.valid_for_read then return end

  local item = { name = cursor_stack.name, quality = cursor_stack.quality.name }
  local p_settings = settings.get_player_settings(player)
  M.open_for(player, selected, item, p_settings[ALWAYS_SETTING].value)

  storage.force_insert.drag[e.player_index] = { name = item.name, quality = item.quality, tick = game.tick }
end

function M.on_selected_entity_changed(e)
  if not enabled() then return end
  init_storage()

  local drag = storage.force_insert.drag[e.player_index]
  if not drag then return end

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack or not cursor_stack.valid_for_read or cursor_stack.name ~= drag.name or cursor_stack.quality.name ~= drag.quality then
    storage.force_insert.drag[e.player_index] = nil
    return
  end

  local selected = player.selected
  if core.validation.is_entity_valid(selected) then
    ---@cast selected LuaEntity
    local p_settings = settings.get_player_settings(player)
    M.open_for(player, selected, { name = drag.name, quality = drag.quality }, p_settings[ALWAYS_SETTING].value)
  end
end

function M.on_player_fast_transferred(e)
  if not enabled() then return end
  if not e.from_player then return end
  init_storage()

  local drag = storage.force_insert.drag[e.player_index]
  if drag then
    drag.tick = game.tick
  end
end

function M.on_force_insert_gui(e)
  if not enabled() then return end
  init_storage()

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  if player.opened_gui_type ~= defines.gui_type.entity then return end

  local entity = player.opened --[[@as LuaEntity]]
  if not core.validation.is_entity_valid(entity) then return end

  local selected_prototype = e.selected_prototype
  if not selected_prototype or selected_prototype.base_type ~= "item" then return end

  local p_settings = settings.get_player_settings(player)
  local force = p_settings[ALWAYS_SETTING].value

  if not force then
    if storage.force_insert.probe[e.player_index] then
      force = true
    else
      storage.force_insert.probe[e.player_index] = game.tick
    end
  end

  local item = { name = selected_prototype.name, quality = selected_prototype.quality or "normal" }
  M.open_for(player, entity, item, force)
end

function M.on_player_cursor_stack_changed(e)
  init_storage()
  release_all(e.player_index)
end

function M.on_player_main_inventory_changed(e)
  init_storage()
  release_all(e.player_index)
end

function M.on_gui_closed(e)
  init_storage()
  release_all(e.player_index)
  storage.force_insert.probe[e.player_index] = nil
end

function M.on_tick(e)
  init_storage()

  for player_index, pending in pairs(storage.force_insert.pending) do
    local remaining = {}
    for _, entry in pairs(pending) do
      if entry.tick < e.tick then
        bar.close(entry.records)
        bar.restore_machines(entry.machines)
      else
        table.insert(remaining, entry)
      end
    end
    storage.force_insert.pending[player_index] = #remaining > 0 and remaining or nil
  end

  for player_index, drag in pairs(storage.force_insert.drag) do
    local player = game.get_player(player_index)
    local limit = (player and player.valid) and window(player) or FALLBACK_WINDOW
    if e.tick - drag.tick >= limit then
      storage.force_insert.drag[player_index] = nil
    end
  end

  for player_index, probe_tick in pairs(storage.force_insert.probe) do
    local player = game.get_player(player_index)
    local limit = (player and player.valid) and window(player) or FALLBACK_WINDOW
    if e.tick - probe_tick >= limit then
      storage.force_insert.probe[player_index] = nil
    end
  end
end

return M
