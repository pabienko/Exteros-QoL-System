local core = require("core.init")

local M = {}

local ENABLED_SETTING = "exteros-qol-renamer-enabled"

local FRAME_NAME = "exteros_qol_renamer_frame"
local TITLEBAR_NAME = "exteros_qol_renamer_titlebar"
local CONTENT_NAME = "exteros_qol_renamer_content"
local CLOSE_NAME = "exteros_qol_renamer_close"
local RANDOM_NAME = "exteros_qol_renamer_random"
local RESET_NAME = "exteros_qol_renamer_reset"
local TEXTFIELD_NAME = "exteros_qol_renamer_textfield"
local COMMIT_NAME = "exteros_qol_renamer_commit"

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

local function get_storage()
  storage.renamer_target = storage.renamer_target or {}
  return storage.renamer_target
end

---@param target { unit_number: number, surface_index: number, position: { x: number, y: number } }
---@return LuaEntity?
local function resolve_entity(target)
  local surfaces = game.surfaces --[[@as table<number, LuaSurface>]]
  local surface = surfaces[target.surface_index]
  if not surface or not surface.valid then return nil end

  local candidates = surface.find_entities_filtered({
    position = target.position,
  })

  for _, candidate in pairs(candidates) do
    if core.validation.is_entity_valid(candidate) and candidate.unit_number == target.unit_number then
      return candidate
    end
  end

  return nil
end

---@param player LuaPlayer
---@return LuaGuiElement?
local function get_textfield(player)
  local frame = player.gui.screen[FRAME_NAME]
  if not frame or not frame.valid then return nil end

  local content = frame[CONTENT_NAME]
  if not content or not content.valid then return nil end

  local textfield = content[TEXTFIELD_NAME]
  if not textfield or not textfield.valid then return nil end

  return textfield
end

---@param player LuaPlayer
local function close_window(player)
  if not player or not player.valid then return end

  local frame = player.gui.screen[FRAME_NAME]
  if frame and frame.valid then
    if player.opened == frame or (player.opened and player.opened.valid and player.opened.name == TEXTFIELD_NAME) then
      player.opened = nil
    end
    frame.destroy()
  end

  get_storage()[player.index] = nil
end

---@param player LuaPlayer
---@param entity LuaEntity
local function build_window(player, entity)
  local screen = player.gui.screen

  local frame = screen.add{
    type = "frame",
    name = FRAME_NAME,
    direction = "vertical",
  }
  frame.style.padding = 8

  local titlebar = frame.add{
    type = "flow",
    name = TITLEBAR_NAME,
    direction = "horizontal",
  }
  titlebar.style.vertical_align = "center"
  titlebar.style.bottom_padding = 4

  local title_label = titlebar.add{
    type = "label",
    style = "frame_title",
    caption = { "exteros-qol-renamer.title" },
  }
  title_label.drag_target = frame

  local filler = titlebar.add{
    type = "empty-widget",
    style = "draggable_space_header",
  }
  filler.style.horizontally_stretchable = true
  filler.drag_target = frame

  titlebar.add{
    type = "sprite-button",
    name = CLOSE_NAME,
    sprite = "utility/close",
    style = "frame_action_button",
    tooltip = { "exteros-qol-renamer.cancel" },
  }

  local content = frame.add{
    type = "flow",
    name = CONTENT_NAME,
    direction = "horizontal",
  }
  content.style.vertical_align = "center"
  content.style.horizontal_spacing = 4

  content.add{
    type = "sprite-button",
    name = RANDOM_NAME,
    sprite = "utility/shuffle",
    style = "tool_button",
    tooltip = { "exteros-qol-renamer.random" },
  }

  content.add{
    type = "sprite-button",
    name = RESET_NAME,
    sprite = "utility/refresh",
    style = "tool_button",
    tooltip = { "exteros-qol-renamer.reset" },
  }

  local textfield = content.add{
    type = "textfield",
    name = TEXTFIELD_NAME,
    style = "stretchable_textfield",
    icon_selector = true,
    text = entity.backer_name or "",
  }

  content.add{
    type = "sprite-button",
    name = COMMIT_NAME,
    sprite = "utility/enter",
    style = "item_and_count_select_confirm",
    tooltip = { "exteros-qol-renamer.commit" },
  }

  frame.force_auto_center()
  textfield.select_all()
  textfield.focus()
  player.opened = textfield
end

---@param player LuaPlayer
local function handle_reset(player)
  local target = get_storage()[player.index]
  if not target then return end

  local entity = resolve_entity(target)
  if not entity or not core.validation.is_entity_valid(entity) or not entity.supports_backer_name() then
    close_window(player)
    return
  end

  local textfield = get_textfield(player)
  if not textfield then return end

  textfield.text = entity.backer_name or ""
  textfield.select_all()
  textfield.focus()
end

---@param player LuaPlayer
local function handle_random(player)
  local names = game.backer_names
  if not names or #names == 0 then return end

  local textfield = get_textfield(player)
  if not textfield then return end

  textfield.text = names[math.random(#names)]
  textfield.select_all()
  textfield.focus()
end

---@param player LuaPlayer
local function handle_commit(player)
  local target = get_storage()[player.index]
  if target then
    local entity = resolve_entity(target)
    if entity and core.validation.is_entity_valid(entity) and entity.supports_backer_name() then
      local textfield = get_textfield(player)
      if textfield then
        entity.backer_name = textfield.text
      end
    end
  end

  close_window(player)
end

function M.init()
  storage.renamer_target = storage.renamer_target or {}
end

function M.on_configuration_changed()
  storage.renamer_target = storage.renamer_target or {}
end

function M.on_rename_entity(event)
  if not enabled() then return end

  local player = game.get_player(event.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  close_window(player)

  local selected = player.selected
  if not selected or not core.validation.is_entity_valid(selected) then return end
  if not selected.supports_backer_name() then return end

  local position = core.position.ensure_explicit(selected.position)
  get_storage()[player.index] = {
    unit_number = selected.unit_number,
    surface_index = selected.surface.index,
    position = { x = position.x, y = position.y },
  }

  build_window(player, selected)
end

function M.on_gui_click(e)
  if not enabled() then return end
  if not e.element or not e.element.valid then return end

  local name = e.element.name
  if name ~= CLOSE_NAME and name ~= RANDOM_NAME and name ~= RESET_NAME and name ~= COMMIT_NAME then return end

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  if name == CLOSE_NAME then
    close_window(player)
  elseif name == RESET_NAME then
    handle_reset(player)
  elseif name == RANDOM_NAME then
    handle_random(player)
  elseif name == COMMIT_NAME then
    handle_commit(player)
  end
end

function M.on_gui_confirmed(e)
  if not enabled() then return end
  if not e.element or not e.element.valid then return end
  if e.element.name ~= TEXTFIELD_NAME then return end

  local player = game.get_player(e.player_index)
  if not core.validation.is_player_valid(player) then return end
  ---@cast player LuaPlayer

  handle_commit(player)
end

function M.on_gui_closed(e)
  if not e.element or not e.element.valid then return end

  local name = e.element.name
  if name ~= FRAME_NAME and name ~= TEXTFIELD_NAME then return end

  local player = e.player_index and game.get_player(e.player_index)
  if not player or not player.valid then return end

  close_window(player)
end

return M
