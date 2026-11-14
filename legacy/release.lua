local mod_gui = require("mod-gui")
local force_insert_release = require("features.force-insert.release")

local TOP_NAMES = { "exteros_ptc_down", "exteros_ptc_reset", "exteros_ptc_up", "exteros_hub_button" }
local LEFT_NAMES = { "exteros_qol_chest_limit_frame", "exteros_qol_belt_brush_frame" }
local SCREEN_NAMES = { "exteros_hub_frame", "exteros_qol_renamer_frame", "exteros_qol_planner_menu_window", "exteros_qol_rcalc_window" }
local CENTER_NAME = "exteros_itemcount"
local SHORTCUTS = { "exteros-qol-belt-visualizer-hover-toggle" }
local BELT_BRUSH_LABEL_PREFIX = "Belt Brush"
local RENDER_FILTER = "Exteros-QoL-System"

---@param old table
---@param player_index integer
---@return nil
local function release_force_insert(old, player_index)
  local force_insert = old.force_insert
  if not force_insert or not force_insert.pending then return end
  local pending = force_insert.pending[player_index]
  if not pending then return end
  force_insert_release.restore(pending)
end

---@param old table
---@return boolean
local function searchlight_was_active(old)
  return old.searchlight_flashlight ~= nil or old.searchlight_last_tick ~= nil
end

---@param player LuaPlayer
---@param flashlight_pending table<integer, boolean>
---@return nil
local function release_flashlight(player, flashlight_pending)
  if player.controller_type ~= defines.controllers.character or not player.character then
    flashlight_pending[player.index] = true
    return
  end
  if not player.is_flashlight_enabled() then
    player.enable_flashlight()
  end
end

---@param player LuaPlayer
---@return nil
local function release_belt_brush_cursor(player)
  local stack = player.cursor_stack
  if not stack or not stack.valid_for_read then return end
  if stack.is_blueprint and stack.label and stack.label:find("^" .. BELT_BRUSH_LABEL_PREFIX) ~= nil
      and not stack.allow_manual_label_change then
    stack.clear()
    player.cursor_stack_temporary = false
  end
end

---@param player LuaPlayer
---@param names string[]
---@return nil
local function destroy_top_names(player, names)
  local top = player.gui.top
  if not top or not top.valid then return end

  local flow = top.mod_gui_button_flow
  if flow and flow.valid then
    for _, name in ipairs(names) do
      local element = flow[name]
      if element and element.valid then element.destroy() end
    end
  end

  local top_frame = top.mod_gui_top_frame
  if top_frame and top_frame.valid then
    local inner = top_frame.mod_gui_inner_frame
    if inner and inner.valid then
      for _, name in ipairs(names) do
        local element = inner[name]
        if element and element.valid then element.destroy() end
      end
      if #inner.children == 0 then
        top_frame.destroy()
      end
    end
  end
end

---@param player LuaPlayer
---@param names string[]
---@return nil
local function destroy_left_names(player, names)
  local left = player.gui.left
  if not left or not left.valid then return end
  local flow = left.mod_gui_frame_flow
  if not flow or not flow.valid then return end

  for _, name in ipairs(names) do
    local element = flow[name]
    if element and element.valid then element.destroy() end
  end
  if #flow.children == 0 then
    flow.destroy()
  end
end

---@param player LuaPlayer
---@return nil
local function destroy_screen_frames(player)
  local screen = player.gui.screen
  for _, name in ipairs(SCREEN_NAMES) do
    local element = screen[name]
    if element and element.valid then
      if player.opened == element then player.opened = nil end
      element.destroy()
    end
  end
end

---@param player LuaPlayer
---@return nil
local function destroy_center(player)
  local element = player.gui.center[CENTER_NAME]
  if element and element.valid then element.destroy() end
end

---@param player LuaPlayer
---@return nil
local function release_shortcuts(player)
  for _, name in ipairs(SHORTCUTS) do
    if prototypes.shortcut[name] then
      player.set_shortcut_toggled(name, false)
    end
  end
end

---@param old table
---@return table<integer, LuaEntity>
local function collect_player_kept(old)
  local kept = {}
  local auto_decon = old.auto_decon
  if auto_decon and auto_decon.player_kept then
    for unit_number, entity in pairs(auto_decon.player_kept) do
      if entity and entity.valid then
        kept[unit_number] = entity
      end
    end
  end
  return kept
end

---@param old table
---@return table<string, boolean>
local function collect_even_distribution_ignored(old)
  local ignored = {}
  if old.even_distribution_ignored then
    for name in pairs(old.even_distribution_ignored) do
      ignored[name] = true
    end
  end
  return ignored
end

---@param old table
---@param changes ConfigurationChangedData
---@return table carry
return function(old, changes)
  local carry = {
    flashlight_pending = {},
    player_kept = collect_player_kept(old),
    even_distribution_ignored = collect_even_distribution_ignored(old),
  }

  if game.speed ~= 1 then
    carry.speed_notice = true
  end

  local release_searchlight = searchlight_was_active(old)

  for player_index, player in pairs(game.players) do
    if player and player.valid then
      release_force_insert(old, player_index)
      if release_searchlight then
        release_flashlight(player, carry.flashlight_pending)
      end
    end
  end

  rendering.clear(RENDER_FILTER)

  for _, player in pairs(game.players) do
    if player and player.valid then
      release_belt_brush_cursor(player)
      destroy_top_names(player, TOP_NAMES)
      destroy_left_names(player, LEFT_NAMES)
      destroy_screen_frames(player)
      destroy_center(player)
      release_shortcuts(player)
    end
  end

  return carry
end
