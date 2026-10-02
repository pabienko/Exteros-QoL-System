-- Rate Calculator, adapted from Rate Calculator by raiguard (MIT, © 2020-2023 Caleb Heuer) and RateCalculatorPlus by Kesha.

local core = require("core.init")
local calc = require("features.rate-calculator.calc")
local gui = require("features.rate-calculator.gui")
local gui_util = require("features.rate-calculator.gui-util")

local SELECTION_TOOL = "exteros-qol-rcalc-selection-tool"
local SHORTCUT = "exteros-qol-rcalc-get-selection-tool"
local SETTING_PREFIX = "exteros-qol-rcalc-"

local M = {}

--- C3: create/repair storage and rebuild the divisor filters. Shared by init and
--- on_configuration_changed (the latter also covers a save where the feature was just switched on
--- and storage.rate_calculator never existed).
local function init_storage()
  storage.rate_calculator = storage.rate_calculator or { gui = {}, translations = {}, pending = {} }
  gui_util.build_divisor_filters()
  for _, player in pairs(game.players) do
    gui.destroy(player)
  end
end

function M.init()
  init_storage()
end

function M.on_configuration_changed()
  init_storage()
end

--- @param entities LuaEntity[]?
--- @return boolean
local function has_any_entities(entities)
  return entities ~= nil and next(entities) ~= nil
end

--- @param e EventData.on_player_selected_area
function M.on_player_selected_area(e)
  if e.item ~= SELECTION_TOOL or not has_any_entities(e.entities) then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local set = calc.select(player, e.entities, e.area)
  gui.build_and_show(player, set, true)
  if player.mod_settings["exteros-qol-rcalc-dismiss-tool-on-selection"].value then
    player.clear_cursor()
  end
end

--- @param e EventData.on_player_alt_selected_area
function M.on_player_alt_selected_area(e)
  if e.item ~= SELECTION_TOOL or not has_any_entities(e.entities) then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local set = gui.get_current_set(player)
  if not set then
    set = calc.select(player, e.entities, e.area)
  else
    calc.add_entities(set, e.entities)
  end
  gui.build_and_show(player, set, false)
end

--- @param e EventData.on_player_alt_reverse_selected_area
function M.on_player_alt_reverse_selected_area(e)
  if e.item ~= SELECTION_TOOL or not has_any_entities(e.entities) then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local set = gui.get_current_set(player)
  if not set then
    set = calc.select(player, {}, e.area)
  end
  calc.remove_entities(set, e.entities)
  gui.build_and_show(player, set, false)
end

--- C3: every on_gui_* callback is exactly a dispatch - RC elements that must react carry their own
--- handler tag (set by core.gui.add when building the window), so nothing else reacts.
function M.on_gui_click(e)
  core.gui.dispatch(e, "rcalc")
end

function M.on_gui_closed(e)
  core.gui.dispatch(e, "rcalc")
end

function M.on_gui_text_changed(e)
  core.gui.dispatch(e, "rcalc")
end

function M.on_gui_elem_changed(e)
  core.gui.dispatch(e, "rcalc")
end

function M.on_gui_selection_state_changed(e)
  core.gui.dispatch(e, "rcalc")
end

function M.on_gui_checked_state_changed(e)
  core.gui.dispatch(e, "rcalc")
end

function M.on_gui_hover(e)
  core.gui.dispatch(e, "rcalc")
end

function M.on_gui_leave(e)
  core.gui.dispatch(e, "rcalc")
end

--- @param player LuaPlayer
local function toggle_tool_in_cursor(player)
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == SELECTION_TOOL then
    gui.reshow(player)
    return
  end
  if not cursor_stack or not player.clear_cursor() then
    return
  end
  cursor_stack.set_stack({ name = SELECTION_TOOL, count = 1 })
end

--- @param e EventData.on_lua_shortcut
function M.on_lua_shortcut(e)
  if e.prototype_name ~= SHORTCUT then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  toggle_tool_in_cursor(player)
end

--- @param e EventData.CustomInputEvent
function M.on_rcalc_get_tool(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  toggle_tool_in_cursor(player)
end

--- @param e EventData.CustomInputEvent
function M.on_rcalc_focus_search(e)
  gui.toggle_search(game.get_player(e.player_index))
end

--- @param e EventData.on_runtime_mod_setting_changed
function M.on_runtime_mod_setting_changed(e)
  if e.setting:sub(1, #SETTING_PREFIX) ~= SETTING_PREFIX then
    return
  end
  gui.on_mod_setting_changed(e)
end

--- @param e EventData.on_string_translated
function M.on_string_translated(e)
  gui.on_string_translated(e)
end

--- @param e EventData.on_player_locale_changed
function M.on_player_locale_changed(e)
  gui.on_player_locale_changed(e)
end

--- @param e EventData.on_player_removed
function M.on_player_removed(e)
  gui.on_player_removed(e)
end

return M
