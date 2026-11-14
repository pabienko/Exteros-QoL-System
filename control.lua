local core = require("core.init")
local lib_event = require("__exteros-lib__.event")
local lib_storage = require("__exteros-lib__.storage")
local migrate = require("__exteros-lib__.internal.migrate")
local values = require("__exteros-lib__.internal.values")
local features = require("__exteros-lib__.internal.features")
local force_insert_release = require("features.force-insert.release")

values.setup()

local exteros_flashlight_pending = lib_storage.player_table("exteros_flashlight_pending")

---@param feature string
---@return boolean
local function blocked(feature)
  return core.conflicts.is_blocked(feature, script.active_mods)
end

local modules = {}

---@param name string
---@param module table
---@return nil
local function add_feature(name, module)
  table.insert(modules, module)
  features.define(name, { events = module.events, on_enable = module.on_enable, on_disable = module.on_disable })
end

local function dispatch(callback_name, event)
  for _, module in ipairs(modules) do
    local callback = module[callback_name]
    if type(callback) == "function" then
      callback(event)
    end
  end
end

values.on_change(function(event)
  dispatch("on_qol_value_changed", event)
end)

local function init_all()
  dispatch("init")
end

---@param carry table?
---@return nil
local function apply_carry(carry)
  if not carry then return end

  if carry.player_kept and not blocked("auto-deconstruct") then
    local data = storage.auto_decon
    if data then
      for unit_number, entity in pairs(carry.player_kept) do
        if entity.valid then
          data.player_kept[unit_number] = entity
        end
      end
    end
  end

  if carry.even_distribution_ignored and not blocked("even-distribution") then
    storage.even_distribution_ignored = storage.even_distribution_ignored or {}
    for name in pairs(carry.even_distribution_ignored) do
      storage.even_distribution_ignored[name] = true
    end
  end

  if carry.flashlight_pending and next(carry.flashlight_pending) then
    for player_index in pairs(carry.flashlight_pending) do
      exteros_flashlight_pending.set(player_index, true)
    end
  end

  if carry.speed_notice then
    for _, player in pairs(game.players) do
      player.print({ "", "Exteros' QoL: game speed is ", game.speed, "." })
    end
  end
end

migrate.register({
  version = 1,
  legacy = require("legacy.release"),
  init = function(carry)
    init_all()
    apply_carry(carry)
  end,
})

lib_event.add(force_insert_release.unconditional)

add_feature("player-colors", require("features.player-colors.control"))

if not blocked("auto-alt-mode") then
  add_feature("auto-alt-mode", require("features.auto-alt-mode.control"))
end

if not blocked("copy-chest") then
  add_feature("copy-chest", require("features.copy-chest.control"))
end

if not blocked("planner-zapper") then
  add_feature("planner-zapper", require("features.planner-zapper.control"))
end

if not blocked("chest-limit") then
  add_feature("chest-limit", require("features.chest-limit.control"))
end

if not blocked("even-distribution") then
  add_feature("even-distribution", require("features.even-distribution.control"))
end

if not blocked("auto-deconstruct") then
  add_feature("auto-deconstruct", require("features.auto-deconstruct.control"))
end

if not blocked("inventory-repair") then
  add_feature("inventory-repair", require("features.inventory-repair.control"))
end

if not blocked("time-controls") then
  add_feature("time-controls", require("features.time-controls.control"))
end

if not blocked("inventory-sort") then
  add_feature("inventory-sort", require("features.inventory-sort.control"))
end

if not blocked("item-count") then
  add_feature("item-count", require("features.item-count.control"))
end

if not blocked("searchlight") then
  add_feature("searchlight", require("features.searchlight.control"))
end

if not blocked("force-insert") then
  add_feature("force-insert", require("features.force-insert.control"))
end

if not blocked("wire-shortcuts") then
  add_feature("wire-shortcuts", require("features.wire-shortcuts.control"))
end

if not blocked("belt-reverser") then
  add_feature("belt-reverser", require("features.belt-reverser.control"))
end

if not blocked("renamer") then
  add_feature("renamer", require("features.renamer.control"))
end

if not blocked("belt-brush") then
  add_feature("belt-brush", require("features.belt-brush.control"))
end

if not blocked("ghost-builder") then
  add_feature("ghost-builder", require("features.ghost-builder.control"))
end

if not blocked("planner-menu") then
  add_feature("planner-menu", require("features.planner-menu.control"))
end

if not blocked("tape-measure") then
  add_feature("tape-measure", require("features.tape-measure.control"))
end

if script.feature_flags.quality and not blocked("quality-scroll") then
  add_feature("quality-scroll", require("features.quality-scroll.control"))
end

if not blocked("rate-calculator") then
  add_feature("rate-calculator", require("features.rate-calculator.control"))
end

if not blocked("belt-visualizer") then
  add_feature("belt-visualizer", require("features.belt-visualizer.control"))
end

---@param player_index integer
---@return nil
local function retry_pending_flashlight(player_index)
  if not exteros_flashlight_pending.peek(player_index) then return end

  local player = game.get_player(player_index)
  if player and player.valid and player.controller_type == defines.controllers.character and player.character then
    player.enable_flashlight()
    exteros_flashlight_pending.clear(player_index)
  end
end

lib_event.add({
  events = {
    [defines.events.on_player_joined_game] = function(event) retry_pending_flashlight(event.player_index) end,
    [defines.events.on_player_controller_changed] = function(event) retry_pending_flashlight(event.player_index) end,
  },
})

local ALL_SHORTCUT_OWNERS = {
  ["rate-calculator"] = "exteros-qol-rcalc-get-selection-tool",
  ["belt-visualizer"] = "exteros-qol-belt-visualizer-hover-toggle",
}

local SHORTCUT_OWNERS = {}
for feature_name, shortcut_name in pairs(ALL_SHORTCUT_OWNERS) do
  if not blocked(feature_name) then
    SHORTCUT_OWNERS[feature_name] = shortcut_name
  end
end

---@param player LuaPlayer?
---@return nil
local function sync_shortcut_availability(player)
  if not player or not player.valid then return end
  for feature_name, shortcut_name in pairs(SHORTCUT_OWNERS) do
    player.set_shortcut_available(shortcut_name, features.is_enabled(feature_name))
  end
end

---@return nil
local function sync_shortcut_availability_all()
  for _, player in pairs(game.players) do
    sync_shortcut_availability(player)
  end
end

lib_event.add({
  events = {
    [defines.events.on_player_created] = function(event) sync_shortcut_availability(game.get_player(event.player_index)) end,
  },
})

local LEGACY_HUB_FRAME = "exteros_hub_frame"
local LEGACY_HUB_BUTTON = "exteros_hub_button"

---@param player LuaPlayer
---@return nil
local function destroy_legacy_hub_gui(player)
  if not player or not player.valid then return end

  local top = player.gui.top
  if top and top.valid then
    local flow = top.mod_gui_button_flow
    if flow and flow.valid then
      local button = flow[LEGACY_HUB_BUTTON]
      if button and button.valid then button.destroy() end
    end

    local top_frame = top.mod_gui_top_frame
    if top_frame and top_frame.valid then
      local inner_frame = top_frame.mod_gui_inner_frame
      if inner_frame and inner_frame.valid then
        local button = inner_frame[LEGACY_HUB_BUTTON]
        if button and button.valid then button.destroy() end
        if #inner_frame.children == 0 then top_frame.destroy() end
      end
    end
  end

  local frame = player.gui.screen[LEGACY_HUB_FRAME]
  if frame and frame.valid then
    if player.opened == frame then player.opened = nil end
    frame.destroy()
  end
end

lib_event.on_configuration_changed(function(event)
  for _, player in pairs(game.players) do
    destroy_legacy_hub_gui(player)
  end

  dispatch("on_configuration_changed", event)
end)

lib_event.on_load(function()
  dispatch("on_load")
end)

features.setup()

lib_event.on_init(sync_shortcut_availability_all)
lib_event.on_configuration_changed(sync_shortcut_availability_all)

lib_event.register()
