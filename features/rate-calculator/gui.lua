-- Adapted from Rate Calculator by raiguard (MIT, © 2020-2023 Caleb Heuer) and RateCalculatorPlus by Kesha.

local core = require("core.init")
local gui_rates = require("features.rate-calculator.gui-rates")
local gui_util = require("features.rate-calculator.gui-util")

local WINDOW = "exteros_qol_rcalc_window"

--- @class GuiData
--- @field elems table<string, LuaGuiElement>
--- @field inserter_divisor EntityWithQualityID
--- @field limit_final_products boolean
--- @field manual_multiplier double
--- @field materials_divisor string?
--- @field pinned boolean
--- @field player LuaPlayer
--- @field search_open boolean
--- @field search_query string
--- @field selected_set_index integer
--- @field selected_timescale Timescale
--- @field show_density_column boolean
--- @field sets CalculationSet[]
--- @field transport_belt_divisor EntityWithQualityID
--- @field display_data_lookup DisplayDataLookup

--- @type GuiLocation
local top_left_location = { x = 15, y = 58 + 15 }

--- @param self GuiData
local function reset_location(self)
  local value = self.player.mod_settings["exteros-qol-rcalc-default-gui-location"].value
  local window = self.elems[WINDOW]
  if value == "top-left" then
    -- C2: flib_position.mul inlined.
    local scale = self.player.display_scale
    window.location = { x = top_left_location.x * scale, y = top_left_location.y * scale }
  else
    window.auto_center = true
  end
end

--- C4.1: `rate_caption`/the self-healing titlebar code from RCP (lines 61-153) is gone - our GUIs
--- are always destroyed and rebuilt from scratch on a configuration change, so there is nothing to
--- heal. This only updates values on the elements build_gui already created.
--- @param self GuiData
local function update_gui(self)
  local sets = self.sets
  local selected_set_index = self.selected_set_index
  local set = sets[selected_set_index]
  if not set then
    return
  end

  local elems = self.elems
  if self.show_density_column == nil then
    self.show_density_column = false
  end
  if self.limit_final_products == nil then
    self.limit_final_products = false
  end

  local nav_backward_button = elems.exteros_qol_rcalc_nav_backward_button
  local at_back = selected_set_index == 1
  nav_backward_button.enabled = not at_back
  nav_backward_button.tooltip = { "exteros-qol-rcalc.previous-set", selected_set_index, #sets }

  local nav_forward_button = elems.exteros_qol_rcalc_nav_forward_button
  local at_front = selected_set_index == #sets
  nav_forward_button.enabled = not at_front
  nav_forward_button.tooltip = { "exteros-qol-rcalc.next-set", selected_set_index, #sets }

  local timescale = self.selected_timescale
  local timescale_data = gui_util.timescale_data[timescale]

  local timescale_divisor_chooser = elems.exteros_qol_rcalc_timescale_divisor_chooser
  local divisor_source = timescale_data.divisor_source
  if divisor_source then
    timescale_divisor_chooser.visible = true
    timescale_divisor_chooser.elem_filters = storage.rate_calculator.elem_filters[divisor_source]
    timescale_divisor_chooser.elem_value = self[divisor_source]
  else
    timescale_divisor_chooser.visible = false
  end
  elems.exteros_qol_rcalc_timescale_dropdown.selected_index = core.table.find(gui_util.ordered_timescales, timescale) --[[@as uint]]
  elems.exteros_qol_rcalc_multiplier_textfield.text = tostring(self.manual_multiplier)
  local selection_area_tiles = set.selection_area_tiles or 0
  local selection_area_width = set.selection_area_width or 0
  local selection_area_height = set.selection_area_height or 0
  elems.exteros_qol_rcalc_selection_area_label.caption = {
    "exteros-qol-rcalc.selection-area-caption",
    selection_area_tiles,
    selection_area_width,
    selection_area_height,
  }
  elems.exteros_qol_rcalc_toggle_density_column_button.toggled = self.show_density_column
  elems.exteros_qol_rcalc_toggle_limit_mode_button.toggled = self.limit_final_products

  set.errors["inserter-rates-estimates"] = divisor_source == "inserter_divisor" and true or nil

  local show_checkboxes = self.player.mod_settings["exteros-qol-rcalc-show-completion-checkboxes"].value --[[@as boolean]]
  local show_intermediate_breakdowns = self.player.mod_settings["exteros-qol-rcalc-show-intermediate-breakdowns"].value --[[@as boolean]]
  elems.exteros_qol_rcalc_rates_scroll_pane.style.minimal_width = 500
    + (self.show_density_column and 100 or 0)
    + (show_checkboxes and 44 or 0)
    + (show_intermediate_breakdowns and 50 or 0)

  local category_display_data = gui_rates.update_display_data(self, set)
  gui_rates.update_gui(self, category_display_data)

  local errors_frame = elems.exteros_qol_rcalc_errors_frame
  errors_frame.clear()
  local visible = false
  if self.player.mod_settings["exteros-qol-rcalc-show-calculation-errors"].value then
    for error in pairs(set.errors) do
      visible = true
      errors_frame.add({
        type = "label",
        style = "bold_label",
        caption = { "", "[img=warning-white]  ", { "exteros-qol-rcalc.error-" .. error } },
        tooltip = { "?", { "exteros-qol-rcalc.error-" .. error .. "-description" }, "" },
      })
    end
  end
  errors_frame.visible = visible
end

--- C5: request a translation for every rate in the set whose `type/name` has not been requested
--- yet. The dictionary key never carries quality/temperature (unlike `path`), which is the bug
--- RCP had - it compared against `path` and so never matched anything.
--- @param self GuiData
--- @param set CalculationSet
local function request_missing_translations(self, set)
  local player = self.player
  if not player.connected then
    return
  end
  local player_index = player.index
  local translations = storage.rate_calculator.translations[player_index]
  if not translations then
    translations = {}
    storage.rate_calculator.translations[player_index] = translations
  end
  local pending = storage.rate_calculator.pending[player_index]
  if not pending then
    pending = {}
    storage.rate_calculator.pending[player_index] = pending
  end

  --- @type LocalisedString[]
  local to_request = {}
  --- @type string[]
  local keys = {}
  for _, rates in pairs(set.rates) do
    local key = rates.type .. "/" .. rates.name
    if translations[key] == nil then
      -- false = "requested, still waiting" so we don't ask again on every update.
      translations[key] = false
      local prototype_group = prototypes[rates.type]
      local prototype = prototype_group and prototype_group[rates.name]
      if prototype then
        to_request[#to_request + 1] = prototype.localised_name
        keys[#keys + 1] = key
      end
    end
  end
  if #to_request == 0 then
    return
  end
  local ids = player.request_translations(to_request)
  if not ids then
    return
  end
  for i, id in ipairs(ids) do
    pending[id] = keys[i]
  end
end

--- @param self GuiData
local function do_toggle_search(self)
  local search_open = not self.search_open
  self.search_open = search_open
  local button = self.elems.exteros_qol_rcalc_search_button
  button.toggled = search_open
  local textfield = self.elems.exteros_qol_rcalc_search_textfield
  textfield.visible = search_open
  if search_open then
    textfield.focus()
    textfield.select_all()
  else
    textfield.text = ""
    self.search_query = ""
    update_gui(self)
  end
end

--- @param e EventData.on_gui_closed
local function on_window_closed(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self or self.pinned then
    return
  end
  if self.search_open then
    do_toggle_search(self)
    self.player.opened = self.elems[WINDOW]
    return
  end
  self.elems.exteros_qol_rcalc_timescale_dropdown.close_dropdown()
  self.elems[WINDOW].visible = false
end

--- @param e EventData.on_gui_click
local function on_titlebar_click(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self or e.button ~= defines.mouse_button_type.middle then
    return
  end
  reset_location(self)
end

--- @param e EventData.on_gui_click
local function on_close_button_click(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  self.elems[WINDOW].visible = false
  if self.player.opened == self.elems[WINDOW] then
    self.player.opened = nil
  end
end

--- @param e EventData.on_gui_click
local function on_pin_button_click(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  local pinned = not self.pinned
  self.pinned = pinned
  e.element.toggled = pinned
  if pinned then
    self.player.opened = nil
    self.elems.exteros_qol_rcalc_close_button.tooltip = { "gui.close" }
    self.elems.exteros_qol_rcalc_search_button.tooltip = { "gui.search" }
  else
    self.player.opened = self.elems[WINDOW]
    self.elems.exteros_qol_rcalc_close_button.tooltip = { "gui.close-instruction" }
    self.elems.exteros_qol_rcalc_search_button.tooltip = { "exteros-qol-rcalc.search-instruction" }
  end
end

--- @param e EventData.on_gui_click
local function on_nav_backward_button_click(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  self.selected_set_index = math.max(self.selected_set_index - 1, 1)
  update_gui(self)
end

--- @param e EventData.on_gui_click
local function on_nav_forward_button_click(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  self.selected_set_index = math.min(self.selected_set_index + 1, #self.sets)
  update_gui(self)
end

--- @param e EventData.on_gui_click
local function on_search_button_click(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  do_toggle_search(self)
end

--- @param e EventData.on_gui_text_changed
local function on_search_text_changed(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  self.search_query = string.lower(e.text)
  update_gui(self)
end

--- @param e EventData.on_gui_elem_changed
local function on_divisor_elem_changed(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  local entity_id = e.element.elem_value --[[@as SignalID?]]
  local timescale = self.selected_timescale
  local timescale_data = gui_util.timescale_data[timescale]
  if timescale_data.divisor_required and not entity_id then
    e.element.elem_value = self[timescale_data.divisor_source]
    return
  end
  self[timescale_data.divisor_source] = entity_id
  update_gui(self)
end

--- @param e EventData.on_gui_selection_state_changed
local function on_timescale_dropdown_changed(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  local new_timescale = gui_util.ordered_timescales[e.element.selected_index]
  self.selected_timescale = new_timescale
  update_gui(self)
end

--- @param e EventData.on_gui_text_changed
local function on_multiplier_textfield_changed(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  local text = e.text
  -- Don't prevent insertion of a decimal point or zeroes
  local last_char = string.sub(text, #text)
  if last_char == "." or (string.match(text, "%.") and last_char == "0") then
    return
  end
  local new_value = tonumber(text)
  if not new_value or new_value == 0 then
    return
  end
  self.manual_multiplier = new_value
  update_gui(self)
end

--- @param e EventData.on_gui_click
local function on_multiplier_nudge_clicked(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  self.manual_multiplier = math.max(1, math.floor(self.manual_multiplier) + e.element.tags.delta)
  update_gui(self)
end

--- @param e EventData.on_gui_click
local function on_toggle_density_column_button_click(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  self.show_density_column = not self.show_density_column
  update_gui(self)
end

--- @param e EventData.on_gui_click
local function on_toggle_limit_mode_button_click(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  self.limit_final_products = not self.limit_final_products
  update_gui(self)
end

core.gui.add_handlers("rcalc", {
  on_close_button_click = on_close_button_click,
  on_divisor_elem_changed = on_divisor_elem_changed,
  on_multiplier_nudge_clicked = on_multiplier_nudge_clicked,
  on_multiplier_textfield_changed = on_multiplier_textfield_changed,
  on_nav_backward_button_click = on_nav_backward_button_click,
  on_nav_forward_button_click = on_nav_forward_button_click,
  on_pin_button_click = on_pin_button_click,
  on_search_button_click = on_search_button_click,
  on_search_text_changed = on_search_text_changed,
  on_toggle_density_column_button_click = on_toggle_density_column_button_click,
  on_toggle_limit_mode_button_click = on_toggle_limit_mode_button_click,
  on_timescale_dropdown_changed = on_timescale_dropdown_changed,
  on_titlebar_click = on_titlebar_click,
  on_window_closed = on_window_closed,
})

--- @param name string
--- @param sprite SpritePath
--- @param tooltip LocalisedString
--- @param handler_name string
--- @return table
local function frame_action_button(name, sprite, tooltip, handler_name)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite,
    tooltip = tooltip,
    mouse_button_filter = { "left" },
    handler = { [defines.events.on_gui_click] = "rcalc:" .. handler_name },
  }
end

--- @param player LuaPlayer
local function destroy_gui(player)
  local self = storage.rate_calculator.gui[player.index]
  if not self then
    return
  end
  storage.rate_calculator.gui[player.index] = nil
  local window = self.elems[WINDOW]
  if not window.valid then
    return
  end
  window.destroy()
end

--- @param player LuaPlayer
--- @return GuiData
local function build_gui(player)
  destroy_gui(player)

  local elems = core.gui.add(player.gui.screen, {
    type = "frame",
    name = WINDOW,
    direction = "vertical",
    visible = false,
    handler = { [defines.events.on_gui_closed] = "rcalc:on_window_closed" },
    {
      type = "flow",
      name = "exteros_qol_rcalc_titlebar_flow",
      style = "exteros_qol_rcalc_titlebar_flow",
      drag_target = WINDOW,
      handler = { [defines.events.on_gui_click] = "rcalc:on_titlebar_click" },
      {
        type = "label",
        style = "exteros_qol_rcalc_frame_title",
        caption = { "exteros-qol-rcalc.title" },
        ignored_by_interaction = true,
      },
      { type = "empty-widget", style = "exteros_qol_rcalc_titlebar_drag_handle", ignored_by_interaction = true },
      {
        type = "textfield",
        name = "exteros_qol_rcalc_search_textfield",
        style = "exteros_qol_rcalc_titlebar_search_textfield",
        visible = false,
        clear_and_focus_on_right_click = true,
        lose_focus_on_confirm = true,
        handler = { [defines.events.on_gui_text_changed] = "rcalc:on_search_text_changed" },
      },
      frame_action_button(
        "exteros_qol_rcalc_search_button",
        "utility/search",
        { "exteros-qol-rcalc.search-instruction" },
        "on_search_button_click"
      ),
      frame_action_button(
        "exteros_qol_rcalc_nav_backward_button",
        "exteros_qol_rcalc_nav_backward_white",
        { "exteros-qol-rcalc.previous-set" },
        "on_nav_backward_button_click"
      ),
      frame_action_button(
        "exteros_qol_rcalc_nav_forward_button",
        "exteros_qol_rcalc_nav_forward_white",
        { "exteros-qol-rcalc.next-set" },
        "on_nav_forward_button_click"
      ),
      frame_action_button(
        "exteros_qol_rcalc_toggle_limit_mode_button",
        "exteros_qol_rcalc_toggle_limit_white",
        { "exteros-qol-rcalc.toggle-limit-mode-description" },
        "on_toggle_limit_mode_button_click"
      ),
      frame_action_button(
        "exteros_qol_rcalc_toggle_density_column_button",
        "exteros_qol_rcalc_toggle_density_white",
        { "exteros-qol-rcalc.toggle-density-column-description" },
        "on_toggle_density_column_button_click"
      ),
      frame_action_button("exteros_qol_rcalc_pin_button", "exteros_qol_rcalc_pin_white", { "exteros-qol-rcalc.keep-open" }, "on_pin_button_click"),
      frame_action_button("exteros_qol_rcalc_close_button", "utility/close", { "gui.close-instruction" }, "on_close_button_click"),
    },
    {
      type = "frame",
      style = "inside_shallow_frame",
      direction = "vertical",
      {
        type = "frame",
        style = "subheader_frame",
        { type = "label", style = "subheader_caption_label", caption = { "exteros-qol-rcalc.timescale" } },
        { type = "empty-widget", style = "exteros_qol_rcalc_horizontal_pusher" },
        {
          type = "choose-elem-button",
          name = "exteros_qol_rcalc_timescale_divisor_chooser",
          style = "exteros_qol_rcalc_units_choose_elem_button",
          elem_type = "entity-with-quality",
          tooltip = { "exteros-qol-rcalc.capacity-divisor-description" },
          handler = { [defines.events.on_gui_elem_changed] = "rcalc:on_divisor_elem_changed" },
        },
        {
          type = "drop-down",
          name = "exteros_qol_rcalc_timescale_dropdown",
          items = core.table.map(gui_util.ordered_timescales, function(timescale)
            return { "string-mod-setting.exteros-qol-rcalc-default-timescale-" .. timescale }
          end),
          handler = { [defines.events.on_gui_selection_state_changed] = "rcalc:on_timescale_dropdown_changed" },
        },
        { type = "label", caption = "[img=quantity-multiplier]" },
        {
          type = "flow",
          style = "exteros_qol_rcalc_multiplier_holder_flow",
          {
            type = "textfield",
            name = "exteros_qol_rcalc_multiplier_textfield",
            style = "exteros_qol_rcalc_multiplier_textfield",
            numeric = true,
            allow_decimal = true,
            clear_and_focus_on_right_click = true,
            lose_focus_on_confirm = true,
            tooltip = { "exteros-qol-rcalc.manual-multiplier-description" },
            text = "1",
            handler = { [defines.events.on_gui_text_changed] = "rcalc:on_multiplier_textfield_changed" },
          },
          {
            type = "flow",
            style = "exteros_qol_rcalc_multiplier_nudge_buttons_flow",
            direction = "vertical",
            {
              type = "sprite-button",
              style = "exteros_qol_rcalc_multiplier_nudge_button",
              sprite = "exteros_qol_rcalc_nudge_increase",
              tooltip = "+1",
              tags = { delta = 1 },
              handler = { [defines.events.on_gui_click] = "rcalc:on_multiplier_nudge_clicked" },
            },
            {
              type = "sprite-button",
              style = "exteros_qol_rcalc_multiplier_nudge_button",
              sprite = "exteros_qol_rcalc_nudge_decrease",
              tooltip = "-1",
              tags = { delta = -1 },
              handler = { [defines.events.on_gui_click] = "rcalc:on_multiplier_nudge_clicked" },
            },
          },
        },
        {
          type = "label",
          name = "exteros_qol_rcalc_selection_area_label",
          style = "caption_label",
          caption = { "exteros-qol-rcalc.selection-area-caption", 0, 0, 0 },
          tooltip = { "exteros-qol-rcalc.selection-area-description" },
        },
      },
      {
        type = "scroll-pane",
        name = "exteros_qol_rcalc_rates_scroll_pane",
        style = "exteros_qol_rcalc_rates_table_scroll_pane",
        { type = "flow", name = "exteros_qol_rcalc_rates_flow", style = "exteros_qol_rcalc_rates_table_horizontal_flow" },
      },
      {
        type = "frame",
        name = "exteros_qol_rcalc_errors_frame",
        style = "exteros_qol_rcalc_negative_subfooter_frame",
        direction = "vertical",
        visible = false,
      },
    },
  })

  player.opened = elems[WINDOW]

  local default_timescale = player.mod_settings["exteros-qol-rcalc-default-timescale"].value --[[@as Timescale]]
  --- @type GuiData
  local self = {
    display_data_lookup = {},
    elems = elems,
    inserter_divisor = gui_util.get_first_prototype(storage.rate_calculator.elem_filters.inserter_divisor),
    manual_multiplier = 1,
    pinned = false,
    player = player,
    search_open = false,
    search_query = "",
    selected_set_index = 0,
    selected_timescale = default_timescale,
    show_density_column = false,
    limit_final_products = false,
    sets = {},
    transport_belt_divisor = gui_util.get_first_prototype(storage.rate_calculator.elem_filters.transport_belt_divisor),
  }
  storage.rate_calculator.gui[player.index] = self

  reset_location(self)

  return self
end

--- @param self GuiData
local function show(self)
  update_gui(self)
  self.elems[WINDOW].visible = true
  if not self.pinned then
    self.player.opened = self.elems[WINDOW]
  end
  self.elems[WINDOW].bring_to_front()
end

local gui = {}

--- @param player LuaPlayer
--- @return CalculationSet?
function gui.get_current_set(player)
  local self = storage.rate_calculator.gui[player.index]
  if self then
    return self.sets[self.selected_set_index]
  end
end

--- @param player LuaPlayer
--- @param set CalculationSet?
--- @param new_selection boolean?
function gui.build_and_show(player, set, new_selection)
  local self = storage.rate_calculator.gui[player.index]
  if not self or not self.elems[WINDOW].valid then
    self = build_gui(player)
  end
  local sets = self.sets
  if set and (new_selection or not sets[1]) then
    sets[#sets + 1] = set
    if #sets > 10 then
      table.remove(sets, 1)
    end
    self.selected_set_index = #sets
  end
  if not sets[self.selected_set_index] then
    return
  end
  if new_selection then
    self.manual_multiplier = 1
  end
  if set then
    request_missing_translations(self, set)
  end
  show(self)
end

--- Re-shows the player's existing window without changing its contents, for the shortcut/custom
--- input being pressed again while the tool is already in the cursor.
--- @param player LuaPlayer
function gui.reshow(player)
  local self = storage.rate_calculator.gui[player.index]
  if self and self.elems[WINDOW].valid then
    show(self)
  end
end

--- @param player LuaPlayer?
function gui.toggle_search(player)
  if not player then
    return
  end
  local self = storage.rate_calculator.gui[player.index]
  if not self or not self.elems[WINDOW].valid or self.pinned or not self.elems[WINDOW].visible then
    return
  end
  do_toggle_search(self)
end

--- C3: on_runtime_mod_setting_changed is filtered by prefix in control.lua; this is what RCP's
--- handler did once it knew the setting was one of ours.
--- @param e EventData.on_runtime_mod_setting_changed
function gui.on_mod_setting_changed(e)
  local self = storage.rate_calculator.gui[e.player_index]
  if not self then
    return
  end
  update_gui(self)
  if e.setting == "exteros-qol-rcalc-default-gui-location" then
    reset_location(self)
  end
end

--- C5: filtered by control.lua's on_string_translated dispatch? No - `on_string_translated` has no
--- element to dispatch on, so control.lua forwards every one here and we filter by whether the id
--- is one we are waiting on.
--- @param e EventData.on_string_translated
function gui.on_string_translated(e)
  local pending = storage.rate_calculator.pending[e.player_index]
  if not pending then
    return
  end
  local key = pending[e.id]
  if not key then
    return
  end
  pending[e.id] = nil
  if not e.translated then
    return
  end
  local translations = storage.rate_calculator.translations[e.player_index]
  if not translations then
    return
  end
  translations[key] = string.lower(e.result)
end

--- @param e EventData.on_player_locale_changed
function gui.on_player_locale_changed(e)
  storage.rate_calculator.translations[e.player_index] = nil
  storage.rate_calculator.pending[e.player_index] = nil
end

--- @param e EventData.on_player_removed
function gui.on_player_removed(e)
  storage.rate_calculator.gui[e.player_index] = nil
  storage.rate_calculator.translations[e.player_index] = nil
  storage.rate_calculator.pending[e.player_index] = nil
end

--- @param player LuaPlayer
function gui.destroy(player)
  destroy_gui(player)
end

return gui
