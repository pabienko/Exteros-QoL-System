local core = require("core.init")

local M = {}

local ENABLED_SETTING = "exteros-qol-planner-menu-enabled"
local COLUMNS_SETTING = "exteros-qol-planner-menu-columns"

local FRAME_NAME = "exteros_qol_planner_menu_window"
local SCROLL_NAME = "exteros_qol_planner_menu_scroll"
local TABLE_NAME = "exteros_qol_planner_menu_table"

---@type table<string, boolean>
local MENU_TYPES = {
  ["blueprint"] = true,
  ["blueprint-book"] = true,
  ["deconstruction-item"] = true,
  ["upgrade-item"] = true,
  ["selection-tool"] = true,
  ["spidertron-remote"] = true,
}

--- Belt-and-suspenders on top of MENU_TYPES: a copy/cut-paste tool would never
--- match MENU_TYPES in the first place (its prototype type is "copy-paste-tool"),
--- but both checks are kept so the exclusion holds even if that assumption turns
--- out to be wrong on some Factorio version.
---@type table<string, boolean>
local SKIP_NAMES = {
  ["copy-paste-tool"] = true,
  ["cut-paste-tool"] = true,
}

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

--- Derived only from prototypes (identical on every peer, never changes at
--- runtime), so a plain module-level cache is safe - this must never be
--- confused with `storage`, which is the only place state may differ or needs
--- to survive a save.
---@type LuaItemPrototype[]?
local item_list_cache = nil

---@return LuaItemPrototype[]
local function build_item_list()
  local list = {}
  for name, item_prototype in pairs(prototypes.item) do
    if MENU_TYPES[item_prototype.type] and item_prototype.type ~= "copy-paste-tool" and not SKIP_NAMES[name] then
      table.insert(list, item_prototype)
    end
  end

  table.sort(list, function(a, b)
    if a.group.order ~= b.group.order then return a.group.order < b.group.order end
    if a.subgroup.order ~= b.subgroup.order then return a.subgroup.order < b.subgroup.order end
    if a.order ~= b.order then return a.order < b.order end
    return a.name < b.name
  end)

  return list
end

---@return LuaItemPrototype[]
local function get_item_list()
  if not item_list_cache then
    item_list_cache = build_item_list()
  end
  return item_list_cache
end

---@param name string
---@return integer?
local function item_index(name)
  local list = get_item_list()
  for i = 1, #list do
    if list[i].name == name then return i end
  end
  return nil
end

---@return table<uint, { excluded: table<string, boolean>, last: string? }>
local function get_storage()
  storage.planner_menu = storage.planner_menu or {}
  return storage.planner_menu
end

---@param player_index uint
---@return { excluded: table<string, boolean>, last: string? }
local function get_player_data(player_index)
  local store = get_storage()
  store[player_index] = store[player_index] or { excluded = {} }
  return store[player_index]
end

---@param player_index uint
---@param name string
---@return boolean
local function is_excluded(player_index, name)
  return get_player_data(player_index).excluded[name] == true
end

---@param player_index uint
---@param current_index integer
---@param direction integer 1 or -1
---@return LuaItemPrototype?
local function next_non_excluded(player_index, current_index, direction)
  local list = get_item_list()
  local count = #list
  if count == 0 then return nil end

  for step = 1, count do
    local index = ((current_index - 1 + direction * step) % count) + 1
    local item_prototype = list[index]
    if item_prototype and not is_excluded(player_index, item_prototype.name) then
      return item_prototype
    end
  end
  return nil
end

---@param player LuaPlayer
---@param item_prototype LuaItemPrototype
local function flying_text(player, item_prototype)
  player.create_local_flying_text({
    text = item_prototype.localised_name,
    create_at_cursor = true,
  })
end

---@param player LuaPlayer
---@return integer
local function columns_for(player)
  return settings.get_player_settings(player)[COLUMNS_SETTING].value --[[@as integer]]
end

---@param player LuaPlayer
---@return table[]
local function build_item_button_defs(player)
  local list = get_item_list()
  local defs = {}
  for i, item_prototype in ipairs(list) do
    local excluded = is_excluded(player.index, item_prototype.name)
    defs[i] = {
      type = "sprite-button",
      style = excluded and "red_slot_button" or "slot_button",
      sprite = "item/" .. item_prototype.name,
      tooltip = item_prototype.localised_name,
      tags = { item_name = item_prototype.name },
      handler = "planner_menu:on_item_button_click",
    }
  end
  return defs
end

---@param player LuaPlayer
---@return table<string, LuaGuiElement>
local function build_gui(player)
  local table_def = { type = "table", name = TABLE_NAME, column_count = columns_for(player) }
  local item_defs = build_item_button_defs(player)
  for i = 1, #item_defs do
    table_def[i] = item_defs[i]
  end

  local elems = core.gui.add(player.gui.screen, {
    type = "frame",
    name = FRAME_NAME,
    direction = "vertical",
    auto_center = true,
    handler = { [defines.events.on_gui_closed] = "planner_menu:on_window_closed" },
    {
      type = "flow",
      direction = "horizontal",
      drag_target = FRAME_NAME,
      { type = "label", style = "frame_title", caption = { "exteros-qol-planner-menu.title" } },
      { type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true },
      {
        type = "sprite-button",
        style = "frame_action_button",
        sprite = "utility/close",
        tooltip = { "gui.close" },
        mouse_button_filter = { "left" },
        handler = "planner_menu:on_close_button_click",
      },
    },
    {
      type = "frame",
      style = "inside_shallow_frame",
      direction = "vertical",
      {
        type = "scroll-pane",
        name = SCROLL_NAME,
        table_def,
      },
    },
  })

  return elems
end

---@param player LuaPlayer
local function destroy_window(player)
  local frame = player.gui.screen[FRAME_NAME]
  if frame and frame.valid then
    if player.opened == frame then player.opened = nil end
    frame.destroy()
  end
end

---@param player LuaPlayer
local function open_window(player)
  destroy_window(player)
  local elems = build_gui(player)
  player.opened = elems[FRAME_NAME]
end

---@param player LuaPlayer
local function toggle_window(player)
  local frame = player.gui.screen[FRAME_NAME]
  if frame and frame.valid then
    destroy_window(player)
    return
  end
  open_window(player)
end

---@param player LuaPlayer
---@param item_name string
---@return boolean equipped
local function equip_item(player, item_name)
  local cursor_stack = player.cursor_stack
  if not cursor_stack then return false end

  if cursor_stack.valid_for_read then
    if not player.clear_cursor() then return false end
  end

  cursor_stack.set_stack({ name = item_name, count = 1 })
  if cursor_stack.valid_for_read then
    player.cursor_stack_temporary = true
  end
  return true
end

---@param e table
local function on_item_button_click(e)
  local elem = e.element
  if not elem or not elem.valid then return end
  local item_name = elem.tags and elem.tags.item_name --[[@as string?]]
  if not item_name then return end

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  if e.button == defines.mouse_button_type.right then
    local player_data = get_player_data(player.index)
    local newly_excluded = not player_data.excluded[item_name]
    player_data.excluded[item_name] = newly_excluded or nil
    elem.style = newly_excluded and "red_slot_button" or "slot_button"
    return
  end

  if e.button ~= defines.mouse_button_type.left then return end

  if equip_item(player, item_name) then
    destroy_window(player)
  end
end

---@param e table
local function on_close_button_click(e)
  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  destroy_window(player)
end

---@param e table
local function on_window_closed(e)
  local elem = e.element
  if elem and elem.valid then
    elem.destroy()
  end
end

core.gui.add_handlers("planner_menu", {
  on_item_button_click = on_item_button_click,
  on_close_button_click = on_close_button_click,
  on_window_closed = on_window_closed,
})

---@param event EventData.CustomInputEvent
function M.on_planner_menu_toggle(event)
  if not enabled() then return end
  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer
  toggle_window(player)
end

---@param player LuaPlayer
---@param cursor_stack LuaItemStack
---@return boolean
local function may_replace_cursor(player, cursor_stack)
  if player.cursor_stack_temporary then return true end

  local item_type = cursor_stack.type
  if item_type == "blueprint" then
    return not cursor_stack.is_blueprint_setup()
  end
  if item_type == "selection-tool" or item_type == "spidertron-remote" then
    return true
  end

  -- deconstruction-item / upgrade-item / blueprint-book: checking whether they carry filters or
  -- contents is awkward, so the cursor is only replaced when it already holds a temporary stack.
  return false
end

---@param event EventData.CustomInputEvent
---@param direction integer 1 for next, -1 for previous
local function do_cycle(event, direction)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end

  local player_index = player.index

  if cursor_stack.valid_for_read then
    local current_index = item_index(cursor_stack.name)
    if not current_index then return end
    if not may_replace_cursor(player, cursor_stack) then return end

    local next_item = next_non_excluded(player_index, current_index, direction)
    if not next_item then return end

    if not player.clear_cursor() then return end
    cursor_stack.set_stack({ name = next_item.name, count = 1 })
    player.cursor_stack_temporary = true
    get_player_data(player_index).last = next_item.name
    flying_text(player, next_item)
    return
  end

  local player_data = get_player_data(player_index)
  local chosen
  if player_data.last and item_index(player_data.last) and not is_excluded(player_index, player_data.last) then
    chosen = prototypes.item[player_data.last]
  else
    chosen = next_non_excluded(player_index, 0, 1)
  end
  if not chosen then return end

  cursor_stack.set_stack({ name = chosen.name, count = 1 })
  player.cursor_stack_temporary = true
  player_data.last = chosen.name
  flying_text(player, chosen)
end

---@param event EventData.CustomInputEvent
function M.on_planner_cycle(event)
  do_cycle(event, 1)
end

---@param event EventData.CustomInputEvent
function M.on_planner_cycle_back(event)
  do_cycle(event, -1)
end

function M.on_gui_click(e)
  core.gui.dispatch(e, "planner_menu")
end

function M.on_gui_closed(e)
  core.gui.dispatch(e, "planner_menu")
end

function M.init()
  storage.planner_menu = storage.planner_menu or {}
end

function M.on_configuration_changed()
  storage.planner_menu = storage.planner_menu or {}
  item_list_cache = nil

  for _, player in pairs(game.players) do
    destroy_window(player)
  end

  for _, player_data in pairs(storage.planner_menu) do
    for name in pairs(player_data.excluded) do
      if not prototypes.item[name] then
        player_data.excluded[name] = nil
      end
    end
    if player_data.last and not prototypes.item[player_data.last] then
      player_data.last = nil
    end
  end
end

---@param event EventData.on_player_removed
function M.on_player_removed(event)
  if storage.planner_menu then
    storage.planner_menu[event.player_index] = nil
  end
end

return M
