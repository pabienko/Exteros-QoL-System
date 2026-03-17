local mod_gui = require("mod-gui")
local cheats = require("features.cheats.control")

local HUB_FRAME = "exteros_hub_frame"
local HUB_BUTTON = "exteros_hub_button"

local RUNTIME_PER_USER = {
  {
    name = "even-distribution-ticks",
    type = "int",
    min = 10,
    max = 600,
    step = 10,
    require_startup = "exteros-qol-even-distribution-enabled"
  },
  {
    name = "even-distribution-swap-balance",
    type = "bool",
    require_startup = "exteros-qol-even-distribution-enabled"
  },
  {
    name = "exteros-qol-auto-sort-inventory",
    type = "bool"
  },
  {
    name = "exteros-qol-item-count-enabled",
    type = "bool"
  },
  {
    name = "exteros-qol-searchlight-enabled",
    type = "bool"
  },
  {
    name = "cheat-reach-distance",
    type = "int",
    min = 0,
    max = 300,
    step = 1,
    require_startup = "exteros-qol-cheat-mode-enabled"
  },
  {
    name = "cheat-crafting-speed",
    type = "double",
    min = 0,
    max = 1000,
    step = 100,
    setting_max = 1000000,
    require_startup = "exteros-qol-cheat-mode-enabled"
  },
  {
    name = "cheat-mining-speed",
    type = "double",
    min = 0,
    max = 1000,
    step = 100,
    setting_max = 1000000,
    require_startup = "exteros-qol-cheat-mode-enabled"
  },
  {
    name = "cheat-inventory-bonus",
    type = "int",
    min = 0,
    max = 1000,
    step = 10,
    require_startup = "exteros-qol-cheat-mode-enabled"
  }
}

local RUNTIME_GLOBAL = {
  {
    name = "exteros-qol-inventory-repair-interval",
    type = "int",
    min = 1,
    max = 600,
    step = 1,
    require_startup = "exteros-qol-inventory-repair-enabled"
  },
  {
    name = "exteros-qol-inventory-repair-order",
    type = "string",
    allowed_values = { "low-first", "high-first" },
    require_startup = "exteros-qol-inventory-repair-enabled"
  }
}

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"] and settings.startup["exteros-qol-debug"].value then
    log("[Hub] " .. msg)
  end
end

local function get_setting_value(scope, player, name)
  if scope == "per_user" then
    return settings.get_player_settings(player)[name].value
  else
    return settings.global[name].value
  end
end

local CHEAT_SETTINGS = {
  ["cheat-reach-distance"] = true,
  ["cheat-crafting-speed"] = true,
  ["cheat-mining-speed"] = true,
  ["cheat-inventory-bonus"] = true,
}

local function set_setting_value(scope, player, name, value)
  if scope == "per_user" then
    settings.get_player_settings(player)[name] = { value = value }
  else
    if player.admin then
      settings.global[name] = { value = value }
    end
  end
  if scope == "per_user" and CHEAT_SETTINGS[name] then
    cheats.apply_to_player(player)
  end
end

local function add_setting_row(parent, def, scope, player)
  local flow = parent.add{ type = "flow", direction = "horizontal" }
  flow.style.horizontal_spacing = 8
  flow.style.vertical_align = "center"

  local label = flow.add{
    type = "label",
    caption = {"mod-setting-name." .. def.name},
    tooltip = {"mod-setting-description." .. def.name}
  }
  label.style.width = 220

  if def.type == "bool" then
    local cb = flow.add{
      type = "checkbox",
      name = "exteros_hub_" .. def.name,
      state = get_setting_value(scope, player, def.name)
    }
    cb.style.left_margin = 4
  elseif def.type == "int" or def.type == "double" then
    local current_val = get_setting_value(scope, player, def.name)
    local effective_max = def.setting_max or def.max
    local slider_max = math.min(effective_max, math.max(def.max, current_val))

    local slider = flow.add{
      type = "slider",
      name = "exteros_hub_" .. def.name,
      minimum_value = def.min,
      maximum_value = slider_max,
      value = math.max(def.min, math.min(slider_max, current_val)),
      value_step = def.step,
      discrete_slider = (def.type == "int")
    }
    slider.style.minimal_width = 120
    slider.style.maximal_width = 160

    local textfield = flow.add{
      type = "textfield",
      name = "exteros_hub_text_" .. def.name,
      text = tostring(current_val),
      numeric = true,
      allow_decimal = (def.type == "double"),
      allow_negative = (def.min < 0),
      lose_focus_on_confirm = true,
      tooltip = {"exteros-qol-hub.textfield-tooltip"}
    }
    textfield.style.minimal_width = 70
    textfield.style.maximal_width = 90
  elseif def.type == "string" then
    local items = {}
    for i, v in ipairs(def.allowed_values) do
      items[i] = {"exteros-qol-hub.option-" .. v}
    end
    local current = get_setting_value(scope, player, def.name)
    local selected = 1
    for i, v in ipairs(def.allowed_values) do
      if v == current then selected = i break end
    end
    local dd = flow.add{
      type = "drop-down",
      name = "exteros_hub_" .. def.name,
      items = items,
      selected_index = selected
    }
    dd.style.minimal_width = 120
  end

  return flow
end

local function build_hub_content(frame, player)
  local content = frame.add{ type = "scroll-pane", name = "exteros_hub_content" }
  content.style.maximal_height = 400
  content.style.minimal_width = 420

  local inner = content.add{ type = "flow", direction = "vertical" }
  inner.style.vertical_spacing = 16

  local per_user_visible = false
  for _, def in ipairs(RUNTIME_PER_USER) do
    if not def.require_startup or settings.startup[def.require_startup].value then
      per_user_visible = true
      break
    end
  end

  if per_user_visible then
    local section = inner.add{ type = "frame", name = "exteros_hub_section_per_user", direction = "vertical" }
    section.style.padding = 8
    local title = section.add{ type = "label", caption = {"exteros-qol-hub.section-per-user"} }
    title.style.font = "default-bold"
    title.style.bottom_padding = 4
    local settings_flow = section.add{ type = "flow", direction = "vertical" }
    settings_flow.style.vertical_spacing = 8

    for _, def in ipairs(RUNTIME_PER_USER) do
      if not def.require_startup or settings.startup[def.require_startup].value then
        add_setting_row(settings_flow, def, "per_user", player)
      end
    end
  end

  local inv_repair_enabled = settings.startup["exteros-qol-inventory-repair-enabled"].value
  if inv_repair_enabled and player.admin then
    local section = inner.add{ type = "frame", name = "exteros_hub_section_global", direction = "vertical" }
    section.style.padding = 8
    local title = section.add{ type = "label", caption = {"exteros-qol-hub.section-global"} }
    title.style.font = "default-bold"
    title.style.bottom_padding = 4
    local settings_flow = section.add{ type = "flow", direction = "vertical" }
    settings_flow.style.vertical_spacing = 8

    for _, def in ipairs(RUNTIME_GLOBAL) do
      if not def.require_startup or settings.startup[def.require_startup].value then
        add_setting_row(settings_flow, def, "global", player)
      end
    end
  end

  if not per_user_visible and not (inv_repair_enabled and player.admin) then
    local msg = inner.add{ type = "label", caption = {"exteros-qol-hub.no-runtime-settings"} }
    msg.style.single_line = false
  end
end

local function open_hub(player)
  if not player or not player.valid then return end
  local gui = player.gui
  if not gui then return end
  local screen = gui.screen
  if not screen then return end

  local existing = screen[HUB_FRAME]
  if existing and existing.valid then
    player.opened = nil
    existing.destroy()
    debug_log("Hub closed for " .. player.name)
    return
  end

  local frame = screen.add{
    type = "frame",
    name = HUB_FRAME,
    direction = "vertical"
  }
  if not frame or not frame.valid then return end
  frame.style.padding = 8
  frame.force_auto_center()
  
  local flow_title_bar = frame.add{ type = "flow", direction = "horizontal" }
  flow_title_bar.drag_target = frame
  flow_title_bar.style.vertical_align = "center"
  flow_title_bar.style.bottom_padding = 8

  flow_title_bar.add{
    type = "label",
    caption = {"exteros-qol-hub.title"}
  }.style.font = "default-bold"

  flow_title_bar.add{
    type = "empty-widget"
  }.style.horizontally_stretchable = true

  build_hub_content(frame, player)
  player.opened = frame
  debug_log("Hub opened for " .. player.name)
end

script.on_event(defines.events.on_gui_closed, function(e)
  if not e.element or not e.element.valid then return end
  if e.element.name ~= HUB_FRAME then return end
  local player = e.player_index and game.get_player(e.player_index)
  if player and player.valid then
    player.opened = nil
  end
  e.element.destroy()
  debug_log("Hub closed via Escape")
end)

local function setup_button(player)
  local flow = mod_gui.get_button_flow(player)
  if flow[HUB_BUTTON] then return end

  flow.add{
    type = "sprite-button",
    name = HUB_BUTTON,
    sprite = "utility/settings",
    tooltip = {"controls.exteros-qol-open-hub"}
  }
end

local function get_setting_def_from_element_name(name)
  local prefix = "exteros_hub_"
  if not name:find("^" .. prefix) then return nil end
  local setting_name = name:sub(#prefix + 1)
  for _, def in ipairs(RUNTIME_PER_USER) do
    if def.name == setting_name then return def, "per_user" end
  end
  for _, def in ipairs(RUNTIME_GLOBAL) do
    if def.name == setting_name then return def, "global" end
  end
  return nil
end

script.on_event("exteros-qol-open-hub", function(e)
  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  open_hub(player)
end)

script.on_event(defines.events.on_player_created, setup_button)
script.on_event(defines.events.on_player_joined_game, setup_button)

script.on_init(function()
  for _, player in pairs(game.players) do
    setup_button(player)
  end
end)

script.on_configuration_changed(function()
  for _, player in pairs(game.players) do
    setup_button(player)
    local screen = player.gui and player.gui.screen
    if screen and screen[HUB_FRAME] then
      local frame = screen[HUB_FRAME]
      if frame.valid then
        player.opened = nil
        frame.destroy()
      end
    end
  end
end)

script.on_event(defines.events.on_gui_click, function(e)
  if not e.element or not e.element.valid then return end
  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end

  if e.element.name == HUB_BUTTON then
    open_hub(player)
  end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(e)
  local def, scope = get_setting_def_from_element_name(e.element.name)
  if not def or def.type ~= "bool" then return end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  if scope == "global" and not player.admin then return end

  set_setting_value(scope, player, def.name, e.element.state)
  debug_log("Setting " .. def.name .. " = " .. tostring(e.element.state))
end)

script.on_event(defines.events.on_gui_value_changed, function(e)
  local def, scope = get_setting_def_from_element_name(e.element.name)
  if not def or (def.type ~= "int" and def.type ~= "double") then return end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  if scope == "global" and not player.admin then return end

  local value = e.element.slider_value
  if def.type == "int" then value = math.floor(value + 0.5) end
  set_setting_value(scope, player, def.name, value)

  local textfield = e.element.parent["exteros_hub_text_" .. def.name]
  if textfield and textfield.valid then
    textfield.text = tostring(value)
  end
  debug_log("Setting " .. def.name .. " = " .. tostring(value))
end)

local function get_setting_def_from_text_name(name)
  local prefix = "exteros_hub_text_"
  if not name:find("^" .. prefix) then return nil end
  local setting_name = name:sub(#prefix + 1)
  for _, def in ipairs(RUNTIME_PER_USER) do
    if def.name == setting_name then return def, "per_user" end
  end
  for _, def in ipairs(RUNTIME_GLOBAL) do
    if def.name == setting_name then return def, "global" end
  end
  return nil
end

script.on_event(defines.events.on_gui_confirmed, function(e)
  local def, scope = get_setting_def_from_text_name(e.element.name)
  if not def or (def.type ~= "int" and def.type ~= "double") then return end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  if scope == "global" and not player.admin then return end

  local text = e.element.text
  if text == "" or text == "-" then return end

  local value = tonumber(text)
  if not value or value ~= value then
    e.element.text = tostring(get_setting_value(scope, player, def.name))
    return
  end

  local effective_max = def.setting_max or def.max
  value = math.max(def.min, math.min(effective_max, value))
  if def.type == "int" then value = math.floor(value + 0.5) end

  set_setting_value(scope, player, def.name, value)

  local slider = e.element.parent["exteros_hub_" .. def.name]
  if slider and slider.valid then
    local slider_max = slider.get_slider_maximum()
    if value > slider_max then
      slider.set_slider_minimum_maximum(slider.get_slider_minimum(), math.min(effective_max, value))
    end
    slider.slider_value = value
  end
  e.element.text = tostring(value)
  debug_log("Setting " .. def.name .. " = " .. tostring(value))
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(e)
  local def, scope = get_setting_def_from_element_name(e.element.name)
  if not def or def.type ~= "string" then return end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  if scope == "global" and not player.admin then return end

  local value = def.allowed_values[e.element.selected_index]
  set_setting_value(scope, player, def.name, value)
  debug_log("Setting " .. def.name .. " = " .. tostring(value))
end)

return {
  open = open_hub
}
