local core = require("core.init")

local M = {}

local HUB_FRAME = "exteros_hub_frame"
local SHORTCUT = "exteros-qol-open-hub"
local LEGACY_HUB_BUTTON = "exteros_hub_button"

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
    name = "even-distribution-fuel-limit",
    type = "double",
    min = 0,
    max = 1000,
    step = 0.1,
    require_startup = "exteros-qol-even-distribution-enabled"
  },
  {
    name = "even-distribution-fuel-limit-unit",
    type = "string",
    allowed_values = { "stacks", "items", "mj" },
    require_startup = "exteros-qol-even-distribution-enabled"
  },
  {
    name = "even-distribution-ammo-limit",
    type = "double",
    min = 0,
    max = 1000,
    step = 0.1,
    require_startup = "exteros-qol-even-distribution-enabled"
  },
  {
    name = "even-distribution-ammo-limit-unit",
    type = "string",
    allowed_values = { "stacks", "items" },
    require_startup = "exteros-qol-even-distribution-enabled"
  },
  {
    name = "even-distribution-source",
    type = "string",
    allowed_values = { "inventory", "hand" },
    require_startup = "exteros-qol-even-distribution-enabled"
  },
  {
    name = "exteros-qol-force-insert-always",
    type = "bool",
    require_startup = "exteros-qol-force-insert-enabled"
  },
  {
    name = "exteros-qol-force-insert-window",
    type = "int",
    min = 1,
    max = 600,
    step = 5,
    require_startup = "exteros-qol-force-insert-enabled"
  },
  {
    name = "exteros-qol-auto-sort-inventory",
    type = "bool",
    group = "inventory-sort",
    require_startup = "exteros-qol-inventory-sort-enabled"
  },
  {
    name = "exteros-qol-item-count-enabled",
    type = "bool",
    group = "item-count",
    require_startup = "exteros-qol-item-count-feature-enabled"
  },
  {
    name = "exteros-qol-item-count-format",
    type = "string",
    allowed_values = { "comma", "dot", "space", "none", "short" },
    group = "item-count",
    require_startup = "exteros-qol-item-count-feature-enabled"
  },
  {
    name = "exteros-qol-auto-alt-player",
    type = "bool",
    require_startup = "exteros-qol-auto-alt-enabled"
  },
  {
    name = "exteros-qol-chest-limit-player",
    type = "bool",
    require_startup = "exteros-qol-chest-limit-enabled"
  },
  {
    name = "exteros-qol-searchlight-enabled",
    type = "bool",
    group = "searchlight",
    require_startup = "exteros-qol-searchlight-feature-enabled"
  },
  {
    name = "exteros-qol-searchlight-custom-flashlight",
    type = "bool",
    group = "searchlight",
    require_startup = "exteros-qol-searchlight-feature-enabled"
  },
  {
    name = "exteros-qol-searchlight-flashlight-scale",
    type = "double",
    min = 0.1,
    max = 5,
    step = 0.1,
    group = "searchlight",
    require_startup = "exteros-qol-searchlight-feature-enabled"
  },
  {
    name = "exteros-qol-searchlight-flashlight-intensity",
    type = "double",
    min = 0.1,
    max = 1.6667,
    step = 0.1,
    group = "searchlight",
    require_startup = "exteros-qol-searchlight-feature-enabled"
  },
  {
    name = "exteros-qol-searchlight-flashlight-color",
    type = "string",
    group = "searchlight",
    require_startup = "exteros-qol-searchlight-feature-enabled"
  },
  {
    name = "exteros-qol-wire-cycle-copper",
    type = "bool",
    require_startup = "exteros-qol-wire-shortcuts-enabled"
  },
  {
    name = "exteros-qol-character-color",
    type = "string",
    allowed_values = {
      "default", "custom", "white", "black", "grey", "red", "orange", "yellow",
      "green", "cyan", "blue", "purple", "pink", "brown"
    },
    require_startup = "exteros-qol-player-colors-enabled"
  },
  {
    name = "exteros-qol-character-color-hex",
    type = "string",
    require_startup = "exteros-qol-player-colors-enabled"
  },
  {
    name = "exteros-qol-chat-color",
    type = "string",
    allowed_values = {
      "default", "custom", "white", "black", "grey", "red", "orange", "yellow",
      "green", "cyan", "blue", "purple", "pink", "brown"
    },
    require_startup = "exteros-qol-player-colors-enabled"
  },
  {
    name = "exteros-qol-chat-color-hex",
    type = "string",
    require_startup = "exteros-qol-player-colors-enabled"
  },
  {
    name = "exteros-qol-rcalc-dismiss-tool-on-selection",
    type = "bool",
    require_startup = "exteros-qol-rate-calculator-enabled"
  },
  {
    name = "exteros-qol-rcalc-show-calculation-errors",
    type = "bool",
    require_startup = "exteros-qol-rate-calculator-enabled"
  },
  {
    name = "exteros-qol-rcalc-show-power-consumption",
    type = "bool",
    require_startup = "exteros-qol-rate-calculator-enabled"
  },
  {
    name = "exteros-qol-rcalc-default-gui-location",
    type = "string",
    allowed_values = { "top-left", "center" },
    require_startup = "exteros-qol-rate-calculator-enabled"
  },
  {
    name = "exteros-qol-rcalc-default-timescale",
    type = "string",
    allowed_values = { "per-second", "per-minute", "per-10-minutes", "per-hour", "transport-belts", "inserters" },
    require_startup = "exteros-qol-rate-calculator-enabled"
  },
  {
    name = "exteros-qol-rcalc-show-completion-checkboxes",
    type = "bool",
    require_startup = "exteros-qol-rate-calculator-enabled"
  },
  {
    name = "exteros-qol-rcalc-show-intermediate-breakdowns",
    type = "bool",
    require_startup = "exteros-qol-rate-calculator-enabled"
  },
  {
    name = "exteros-qol-rcalc-show-pollution",
    type = "bool",
    require_startup = "exteros-qol-rate-calculator-enabled"
  },
  {
    name = "exteros-qol-ghost-builder-entities",
    type = "bool",
    require_startup = "exteros-qol-ghost-builder-enabled"
  },
  {
    name = "exteros-qol-ghost-builder-upgrades",
    type = "bool",
    require_startup = "exteros-qol-ghost-builder-enabled"
  },
  {
    name = "exteros-qol-ghost-builder-tiles",
    type = "bool",
    require_startup = "exteros-qol-ghost-builder-enabled"
  },
  {
    name = "exteros-qol-ghost-builder-modules",
    type = "bool",
    require_startup = "exteros-qol-ghost-builder-enabled"
  },
  {
    name = "exteros-qol-planner-menu-columns",
    type = "int",
    min = 4,
    max = 16,
    step = 1,
    require_startup = "exteros-qol-planner-menu-enabled"
  },
  {
    name = "exteros-qol-belt-visualizer-max-per-tick",
    type = "int",
    min = 1,
    max = 1000,
    step = 1,
    require_startup = "exteros-qol-belt-visualizer-enabled"
  },
  {
    name = "exteros-qol-belt-visualizer-max-entities",
    type = "int",
    min = 10,
    max = 100000,
    step = 100,
    require_startup = "exteros-qol-belt-visualizer-enabled"
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
  },
  {
    name = "exteros-qol-copy-chest-between-surfaces",
    type = "bool",
    require_startup = "exteros-qol-copy-chest-enabled"
  },
  {
    name = "exteros-qol-auto-deconstruct-chests",
    type = "bool",
    require_startup = "exteros-qol-auto-deconstruct-enabled"
  },
  {
    name = "exteros-qol-auto-deconstruct-inserters",
    type = "bool",
    require_startup = "exteros-qol-auto-deconstruct-enabled"
  },
  {
    name = "exteros-qol-auto-deconstruct-beacons",
    type = "bool",
    require_startup = "exteros-qol-auto-deconstruct-enabled"
  },
  {
    name = "exteros-qol-auto-deconstruct-pipes",
    type = "bool",
    require_startup = "exteros-qol-auto-deconstruct-enabled"
  },
  {
    name = "exteros-qol-auto-deconstruct-belts",
    type = "bool",
    require_startup = "exteros-qol-auto-deconstruct-enabled"
  },
  {
    name = "exteros-qol-auto-deconstruct-belt-distance",
    type = "int",
    min = 4,
    max = 256,
    step = 4,
    require_startup = "exteros-qol-auto-deconstruct-enabled"
  },
  {
    name = "exteros-qol-auto-deconstruct-poles",
    type = "bool",
    require_startup = "exteros-qol-auto-deconstruct-enabled"
  },
  {
    name = "exteros-qol-auto-deconstruct-pole-distance",
    type = "int",
    min = 4,
    max = 256,
    step = 4,
    require_startup = "exteros-qol-auto-deconstruct-enabled"
  },
  {
    name = "exteros-qol-auto-deconstruct-pumpjacks",
    type = "bool",
    require_startup = "exteros-qol-auto-deconstruct-enabled"
  }
}

---@param def { name: string, require_startup: string? }
---@param scope string
---@param player LuaPlayer
---@return boolean
local function requirement_met(def, scope, player)
  if def.require_startup then
    local startup = settings.startup[def.require_startup]
    if startup == nil or startup.value ~= true then return false end
  end

  if scope == "per_user" then
    return settings.get_player_settings(player)[def.name] ~= nil
  end
  return settings.global[def.name] ~= nil
end

local function get_setting_value(scope, player, name)
  if scope == "per_user" then
    return settings.get_player_settings(player)[name].value
  else
    return settings.global[name].value
  end
end

local ADDON_PREFIX = "exteros-qol-addon-"

---@return string[]
local function external_interfaces()
  local names = {}
  for name, functions in pairs(remote.interfaces) do
    if name:sub(1, #ADDON_PREFIX) == ADDON_PREFIX and functions.hub_settings then
      table.insert(names, name)
    end
  end
  table.sort(names)
  return names
end

---@class HubAddonGroup
---@field iface string
---@field key string
---@field title LocalisedString
---@field per_user table[]
---@field global table[]
---@field color string?

---@return HubAddonGroup[]
local function external_group_descriptors()
  local out = {}
  for _, iface in ipairs(external_interfaces()) do
    ---@diagnostic disable-next-line: generic-constraint-mismatch
    local s = remote.call(iface, "hub_settings") --[[@as { per_user: table[]?, global: table[]?, title: LocalisedString?, color: string?, groups: table[]? }?]]
    if s then
      if s.groups then
        for _, group in ipairs(s.groups) do
          table.insert(out, {
            iface = iface,
            key = iface .. ":" .. group.key,
            title = group.title,
            per_user = group.per_user or {},
            global = group.global or {},
            color = s.color,
          })
        end
      else
        table.insert(out, {
          iface = iface,
          key = iface,
          title = s.title or iface:sub(#ADDON_PREFIX + 1),
          per_user = s.per_user or {},
          global = s.global or {},
          color = s.color,
        })
      end
    end
  end
  return out
end

---@param setting_name string
---@return table?, string?, string?
local function find_def(setting_name)
  for _, def in ipairs(RUNTIME_PER_USER) do
    if def.name == setting_name then return def, "per_user", nil end
  end
  for _, def in ipairs(RUNTIME_GLOBAL) do
    if def.name == setting_name then return def, "global", nil end
  end
  for _, group in ipairs(external_group_descriptors()) do
    for _, def in ipairs(group.per_user) do
      if def.name == setting_name then return def, "per_user", group.iface end
    end
    for _, def in ipairs(group.global) do
      if def.name == setting_name then return def, "global", group.iface end
    end
  end
  return nil
end

local function set_setting_value(scope, player, name, value, iface)
  if scope == "global" and not player.admin then return end

  if iface then
    if remote.interfaces[iface] and remote.interfaces[iface].set_hub_setting then
      remote.call(iface, "set_hub_setting", player.index, name, value, scope)
    end
    return
  end

  if scope == "per_user" then
    settings.get_player_settings(player)[name] = { value = value }
  else
    settings.global[name] = { value = value }
  end
end

local function add_setting_row(parent, def, scope, player)
  local flow = parent.add{ type = "flow", direction = "horizontal" }
  flow.style.horizontal_spacing = 8
  flow.style.vertical_align = "center"

  local label = flow.add{
    type = "label",
    caption = {"exteros-qol-hub-setting." .. def.name},
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
  elseif def.type == "string" and def.allowed_values then
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
  elseif def.type == "string" then
    local current_val = get_setting_value(scope, player, def.name)

    local textfield = flow.add{
      type = "textfield",
      name = "exteros_hub_text_" .. def.name,
      text = current_val,
      numeric = false,
      lose_focus_on_confirm = true,
      tooltip = {"exteros-qol-hub.textfield-tooltip"}
    }
    textfield.style.minimal_width = 120
    textfield.style.maximal_width = 160
  end

  return flow
end

---@param def { group: string?, require_startup: string? }
---@return string
local function core_group_key(def)
  if def.group then return def.group end
  if def.require_startup then
    local feature = def.require_startup:match("^exteros%-qol%-(.+)%-enabled$")
    if feature then return feature end
  end
  return "general"
end

---@return string[]
local function core_group_order()
  local order = {}
  local seen = {}
  for _, def in ipairs(RUNTIME_PER_USER) do
    local key = core_group_key(def)
    if not seen[key] then
      seen[key] = true
      table.insert(order, key)
    end
  end
  for _, def in ipairs(RUNTIME_GLOBAL) do
    local key = core_group_key(def)
    if not seen[key] then
      seen[key] = true
      table.insert(order, key)
    end
  end
  return order
end

---@param defs table[]
---@param scope string
---@param player LuaPlayer
---@return boolean
local function any_visible(defs, scope, player)
  for _, def in ipairs(defs) do
    if requirement_met(def, scope, player) then return true end
  end
  return false
end

local CORE_GROUP_COLOR = "#84CDEC"

---@class HubGroup
---@field key string
---@field title LocalisedString
---@field per_user_defs table[]
---@field global_defs table[]
---@field per_user_visible boolean
---@field global_visible boolean
---@field iface string?
---@field color string?

---@param player LuaPlayer
---@return HubGroup[]
local function build_groups(player)
  local groups = {}

  for _, key in ipairs(core_group_order()) do
    local per_user_defs, global_defs = {}, {}
    for _, def in ipairs(RUNTIME_PER_USER) do
      if core_group_key(def) == key then table.insert(per_user_defs, def) end
    end
    for _, def in ipairs(RUNTIME_GLOBAL) do
      if core_group_key(def) == key then table.insert(global_defs, def) end
    end

    local per_user_visible = any_visible(per_user_defs, "per_user", player)
    local global_visible = any_visible(global_defs, "global", player) and player.admin

    if per_user_visible or global_visible then
      table.insert(groups, {
        key = key,
        title = {"exteros-qol-hub.group-" .. key},
        per_user_defs = per_user_defs,
        global_defs = global_defs,
        per_user_visible = per_user_visible,
        global_visible = global_visible,
        iface = nil,
        color = CORE_GROUP_COLOR
      })
    end
  end

  for _, group in ipairs(external_group_descriptors()) do
    local per_user_visible = any_visible(group.per_user, "per_user", player)
    local global_visible = any_visible(group.global, "global", player) and player.admin

    if per_user_visible or global_visible then
      table.insert(groups, {
        key = group.key,
        title = group.title,
        per_user_defs = group.per_user,
        global_defs = group.global,
        per_user_visible = per_user_visible,
        global_visible = global_visible,
        iface = group.iface,
        color = group.color
      })
    end
  end

  return groups
end

---@param body LuaGuiElement
---@param player LuaPlayer
---@param groups HubGroup[]
---@param selected_key string
local function build_right_pane(body, player, groups, selected_key)
  local existing = body.exteros_hub_right_pane
  if existing and existing.valid then existing.destroy() end

  local group
  for _, g in ipairs(groups) do
    if g.key == selected_key then group = g break end
  end
  group = group or groups[1]
  if not group then return end

  local right = body.add{
    type = "frame",
    name = "exteros_hub_right_pane",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  local content = right.add{ type = "scroll-pane", name = "exteros_hub_content" }
  content.style.maximal_height = 400
  content.style.minimal_width = 420

  local inner = content.add{ type = "flow", direction = "vertical" }
  inner.style.vertical_spacing = 16

  local heading = inner.add{ type = "label", caption = group.title, style = "subheader_caption_label" }
  heading.style.font_color = { r = 0x84 / 255, g = 0xCD / 255, b = 0xEC / 255 }

  local show_section_captions = group.per_user_visible and group.global_visible

  if group.per_user_visible then
    if show_section_captions then
      local caption = inner.add{ type = "label", caption = {"exteros-qol-hub.section-per-user"} }
      caption.style.font = "default-bold"
      caption.style.bottom_padding = 4
    end
    local settings_flow = inner.add{ type = "flow", direction = "vertical" }
    settings_flow.style.vertical_spacing = 8
    for _, def in ipairs(group.per_user_defs) do
      if requirement_met(def, "per_user", player) then
        add_setting_row(settings_flow, def, "per_user", player)
      end
    end
  end

  if group.global_visible then
    if show_section_captions then
      local caption = inner.add{ type = "label", caption = {"exteros-qol-hub.section-global"} }
      caption.style.font = "default-bold"
      caption.style.bottom_padding = 4
    end
    local settings_flow = inner.add{ type = "flow", direction = "vertical" }
    settings_flow.style.vertical_spacing = 8
    for _, def in ipairs(group.global_defs) do
      if requirement_met(def, "global", player) then
        add_setting_row(settings_flow, def, "global", player)
      end
    end
  end
end

local function build_hub_content(frame, player)
  local groups = build_groups(player)

  if #groups == 0 then
    local msg = frame.add{ type = "label", caption = {"exteros-qol-hub.no-runtime-settings"} }
    msg.style.single_line = false
    return
  end

  storage.hub_selected_group = storage.hub_selected_group or {}
  local selected_key = storage.hub_selected_group[player.index]
  local selected_valid = false
  if selected_key then
    for _, g in ipairs(groups) do
      if g.key == selected_key then selected_valid = true break end
    end
  end
  if not selected_valid then
    selected_key = (groups[1] --[[@as HubGroup]]).key
  end
  storage.hub_selected_group[player.index] = selected_key

  local body = frame.add{ type = "flow", name = "exteros_hub_body", direction = "horizontal" }
  body.style.horizontal_spacing = 8

  local items = {}
  local selected_index = 1
  for i, g in ipairs(groups) do
    items[i] = g.color and { "", "[color=" .. g.color .. "]", g.title, "[/color]" } or g.title
    if g.key == selected_key then selected_index = i end
  end

  local list = body.add{
    type = "list-box",
    name = "exteros_hub_group_list",
    items = items,
    selected_index = selected_index
  }
  list.style.width = 200
  list.style.height = 400

  build_right_pane(body, player, groups, selected_key)
end

---@param player LuaPlayer
---@param state boolean
local function set_toggled(player, state)
  if not player or not player.valid then return end
  player.set_shortcut_toggled(SHORTCUT, state)
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
    set_toggled(player, false)
    core.debug.log("Hub closed for " .. player.name, "Hub")
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
  set_toggled(player, true)
  core.debug.log("Hub opened for " .. player.name, "Hub")
end

function M.on_gui_closed(e)
  if not e.element or not e.element.valid then return end
  if e.element.name ~= HUB_FRAME then return end
  local player = e.player_index and game.get_player(e.player_index)
  if player and player.valid then
    player.opened = nil
    set_toggled(player, false)
  end
  e.element.destroy()
  core.debug.log("Hub closed via Escape", "Hub")
end

---@param player LuaPlayer
local function remove_legacy_button(player)
  if not player or not player.valid then return end
  local top = player.gui.top
  if not top or not top.valid then return end

  local legacy_flow = top.mod_gui_button_flow
  if legacy_flow and legacy_flow.valid then
    local button = legacy_flow[LEGACY_HUB_BUTTON]
    if button and button.valid then button.destroy() end
  end

  local top_frame = top.mod_gui_top_frame
  if not top_frame or not top_frame.valid then return end
  local inner_frame = top_frame.mod_gui_inner_frame
  if not inner_frame or not inner_frame.valid then return end

  local button = inner_frame[LEGACY_HUB_BUTTON]
  if button and button.valid then
    button.destroy()
  end

  if #inner_frame.children == 0 then
    top_frame.destroy()
  end
end

local function get_setting_def_from_element_name(name)
  local prefix = "exteros_hub_"
  if not name:find("^" .. prefix) then return nil end
  local setting_name = name:sub(#prefix + 1)
  return find_def(setting_name)
end

function M.on_open_hub(e)
  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  open_hub(player)
end

function M.on_lua_shortcut(e)
  if e.prototype_name ~= SHORTCUT then return end
  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  open_hub(player)
end

function M.on_configuration_changed()
  for _, player in pairs(game.players) do
    remove_legacy_button(player)
    local frame = player.gui.screen[HUB_FRAME]
    if frame and frame.valid then
      player.opened = nil
      frame.destroy()
      set_toggled(player, false)
    end
  end
end

function M.on_gui_checked_state_changed(e)
  if not e.element or not e.element.valid then return end
  local def, scope, iface = get_setting_def_from_element_name(e.element.name)
  if not def or def.type ~= "bool" then return end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  if scope == "global" and not player.admin then return end

  set_setting_value(scope, player, def.name, e.element.state, iface)
  core.debug.log("Setting " .. def.name .. " = " .. tostring(e.element.state), "Hub")
end

function M.on_gui_value_changed(e)
  if not e.element or not e.element.valid then return end
  local def, scope, iface = get_setting_def_from_element_name(e.element.name)
  if not def or (def.type ~= "int" and def.type ~= "double") then return end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  if scope == "global" and not player.admin then return end

  local value = e.element.slider_value
  if def.type == "int" then value = math.floor(value + 0.5) end
  set_setting_value(scope, player, def.name, value, iface)

  local textfield = e.element.parent["exteros_hub_text_" .. def.name]
  if textfield and textfield.valid then
    textfield.text = tostring(value)
  end
  core.debug.log("Setting " .. def.name .. " = " .. tostring(value), "Hub")
end

local function get_setting_def_from_text_name(name)
  local prefix = "exteros_hub_text_"
  if not name:find("^" .. prefix) then return nil end
  local setting_name = name:sub(#prefix + 1)
  return find_def(setting_name)
end

function M.on_gui_confirmed(e)
  if not e.element or not e.element.valid then return end
  local def, scope, iface = get_setting_def_from_text_name(e.element.name)
  local is_string_def = def and def.type == "string" and not def.allowed_values
  if not def or not (def.type == "int" or def.type == "double" or is_string_def) then return end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  if scope == "global" and not player.admin then return end

  if is_string_def then
    local value = e.element.text:match("^%s*(.-)%s*$")
    set_setting_value(scope, player, def.name, value, iface)
    e.element.text = value
    core.debug.log("Setting " .. def.name .. " = " .. tostring(value), "Hub")
    return
  end

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

  set_setting_value(scope, player, def.name, value, iface)

  local slider = e.element.parent["exteros_hub_" .. def.name]
  if slider and slider.valid then
    local slider_max = slider.get_slider_maximum()
    if value > slider_max then
      slider.set_slider_minimum_maximum(slider.get_slider_minimum(), math.min(effective_max, value))
    end
    slider.slider_value = value
  end
  e.element.text = tostring(value)
  core.debug.log("Setting " .. def.name .. " = " .. tostring(value), "Hub")
end

function M.on_gui_selection_state_changed(e)
  if not e.element or not e.element.valid then return end

  if e.element.name == "exteros_hub_group_list" then
    local player = game.get_player(e.player_index)
    if not player or not player.valid then return end

    local frame = player.gui.screen[HUB_FRAME]
    if not frame or not frame.valid then return end
    local body = frame.exteros_hub_body
    if not body or not body.valid then return end

    local groups = build_groups(player)
    local group = groups[e.element.selected_index]
    if not group then return end

    storage.hub_selected_group = storage.hub_selected_group or {}
    storage.hub_selected_group[player.index] = group.key

    build_right_pane(body, player, groups, group.key)
    return
  end

  local def, scope, iface = get_setting_def_from_element_name(e.element.name)
  if not def or def.type ~= "string" then return end

  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end
  if scope == "global" and not player.admin then return end

  if not def.allowed_values then return end

  local value = def.allowed_values[e.element.selected_index]
  set_setting_value(scope, player, def.name, value, iface)
  core.debug.log("Setting " .. def.name .. " = " .. tostring(value), "Hub")
end

---@param e EventData.on_player_removed
function M.on_player_removed(e)
  if storage.hub_selected_group then
    storage.hub_selected_group[e.player_index] = nil
  end
end

M.open = open_hub
M.build_groups = build_groups

return M
