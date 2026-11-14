local core = require("core.init")
local lib_player = require("__exteros-lib__.player")
local lib_entity = require("__exteros-lib__.entity")
local lib_storage = require("__exteros-lib__.storage")
local values = require("__exteros-lib__.internal.values")
local release = require("features.force-insert.release")
local bar = core.bar

local M = {}

local ALWAYS_SETTING = "exteros-qol-force-insert-always"
local WINDOW_SETTING = "exteros-qol-force-insert-window"
local FALLBACK_WINDOW = 20

local force_insert_drag = lib_storage.player_table("force_insert_drag")
local force_insert_probe = lib_storage.player_table("force_insert_probe")

local function window(player)
  return values.get_player(player, WINDOW_SETTING)
end

---@param player LuaPlayer
---@param entity LuaEntity
---@param item { name: string, quality: string }
---@param always boolean
---@return boolean
function M.open_for(player, entity, item, always)
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

  release.track(player.index, { records = records, machines = machines, tick = game.tick })

  core.debug.log("Opened bar for " .. player.name .. " on " .. entity.name, "Force-Insert")
  return true
end

function M.on_force_insert_entity(e)
  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local selected = player.selected
  if not lib_entity.is_valid(selected) then return end
  ---@cast selected LuaEntity

  local cursor_stack = player.cursor_stack
  if not cursor_stack or not cursor_stack.valid_for_read then return end

  local item = { name = cursor_stack.name, quality = cursor_stack.quality.name }
  M.open_for(player, selected, item, values.get_player(player, ALWAYS_SETTING))

  force_insert_drag.set(e.player_index, { name = item.name, quality = item.quality, tick = game.tick })
end

function M.on_selected_entity_changed(e)
  local drag = force_insert_drag.peek(e.player_index)
  if not drag then return end

  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack or not cursor_stack.valid_for_read or cursor_stack.name ~= drag.name or cursor_stack.quality.name ~= drag.quality then
    force_insert_drag.clear(e.player_index)
    return
  end

  local selected = player.selected
  if lib_entity.is_valid(selected) then
    ---@cast selected LuaEntity
    M.open_for(player, selected, { name = drag.name, quality = drag.quality }, values.get_player(player, ALWAYS_SETTING))
  end
end

function M.on_player_fast_transferred(e)
  if not e.from_player then return end

  local drag = force_insert_drag.peek(e.player_index)
  if drag then
    drag.tick = game.tick
  end
end

function M.on_force_insert_gui(e)
  local player = game.get_player(e.player_index)
  if not lib_player.is_connected(player) then return end
  ---@cast player LuaPlayer

  if player.opened_gui_type ~= defines.gui_type.entity then return end

  local entity = player.opened --[[@as LuaEntity]]
  if not lib_entity.is_valid(entity) then return end

  local selected_prototype = e.selected_prototype
  if not selected_prototype or selected_prototype.base_type ~= "item" then return end

  local force = values.get_player(player, ALWAYS_SETTING)

  if not force then
    if force_insert_probe.peek(e.player_index) then
      force = true
    else
      force_insert_probe.set(e.player_index, game.tick)
    end
  end

  local item = { name = selected_prototype.name, quality = selected_prototype.quality or "normal" }
  M.open_for(player, entity, item, force)
end

function M.on_player_cursor_stack_changed(e)
  release.release_player(e.player_index)
end

function M.on_player_main_inventory_changed(e)
  release.release_player(e.player_index)
end

function M.on_gui_closed(e)
  release.release_player(e.player_index)
  force_insert_probe.clear(e.player_index)
end

function M.on_tick(e)
  for player_index, drag in pairs(force_insert_drag.all()) do
    local player = game.get_player(player_index)
    local limit = (player and player.valid) and window(player) or FALLBACK_WINDOW
    if e.tick - drag.tick >= limit then
      force_insert_drag.clear(player_index)
    end
  end

  for player_index, probe_tick in pairs(force_insert_probe.all()) do
    local player = game.get_player(player_index)
    local limit = (player and player.valid) and window(player) or FALLBACK_WINDOW
    if e.tick - probe_tick >= limit then
      force_insert_probe.clear(player_index)
    end
  end
end

function M.on_disable()
  release.release_everyone()
  for player_index in pairs(force_insert_drag.all()) do
    force_insert_drag.clear(player_index)
  end
  for player_index in pairs(force_insert_probe.all()) do
    force_insert_probe.clear(player_index)
  end
end

M.events = {
  [defines.events.on_selected_entity_changed] = M.on_selected_entity_changed,
  [defines.events.on_player_fast_transferred] = M.on_player_fast_transferred,
  [defines.events.on_player_cursor_stack_changed] = M.on_player_cursor_stack_changed,
  [defines.events.on_player_main_inventory_changed] = M.on_player_main_inventory_changed,
  [defines.events.on_gui_closed] = M.on_gui_closed,
  [defines.events.on_tick] = M.on_tick,
  ["exteros-qol-force-insert-fast-entity-transfer"] = M.on_force_insert_entity,
  ["exteros-qol-force-insert-fast-entity-split"] = M.on_force_insert_entity,
  ["exteros-qol-force-insert-stack-transfer"] = M.on_force_insert_gui,
  ["exteros-qol-force-insert-stack-split"] = M.on_force_insert_gui,
  ["exteros-qol-force-insert-inventory-transfer"] = M.on_force_insert_gui,
  ["exteros-qol-force-insert-inventory-split"] = M.on_force_insert_gui,
}

return M
