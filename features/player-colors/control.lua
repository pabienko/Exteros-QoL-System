local M = {}

local ENABLED_SETTING = "exteros-qol-player-colors-enabled"
local CHARACTER_COLOR_SETTING = "exteros-qol-character-color"
local CHARACTER_COLOR_HEX_SETTING = "exteros-qol-character-color-hex"
local CHAT_COLOR_SETTING = "exteros-qol-chat-color"
local CHAT_COLOR_HEX_SETTING = "exteros-qol-chat-color-hex"

---@type table<string, table>
local PALETTE = {
  ["white"] = { r = 1.00, g = 1.00, b = 1.00 },
  ["black"] = { r = 0.10, g = 0.10, b = 0.10 },
  ["grey"] = { r = 0.55, g = 0.55, b = 0.55 },
  ["red"] = { r = 0.85, g = 0.25, b = 0.25 },
  ["orange"] = { r = 0.88, g = 0.54, b = 0.18 },
  ["yellow"] = { r = 0.90, g = 0.82, b = 0.30 },
  ["green"] = { r = 0.30, g = 0.69, b = 0.31 },
  ["cyan"] = { r = 0.25, g = 0.76, b = 0.79 },
  ["blue"] = { r = 0.29, g = 0.50, b = 0.85 },
  ["purple"] = { r = 0.61, g = 0.35, b = 0.71 },
  ["pink"] = { r = 0.89, g = 0.50, b = 0.69 },
  ["brown"] = { r = 0.54, g = 0.40, b = 0.26 },
}

local SETTING_NAMES = {
  [CHARACTER_COLOR_SETTING] = true,
  [CHARACTER_COLOR_HEX_SETTING] = true,
  [CHAT_COLOR_SETTING] = true,
  [CHAT_COLOR_HEX_SETTING] = true,
}

---@return boolean
local function enabled()
  local setting = settings.startup[ENABLED_SETTING]
  return setting ~= nil and setting.value == true
end

---@param text string
---@return table?
local function parse_hex(text)
  if type(text) ~= "string" then return nil end

  local trimmed = text:match("^%s*(.-)%s*$")
  if not trimmed then return nil end

  local digits = trimmed:match("^#?(%x%x%x%x%x%x)$")
  if not digits then return nil end

  local r = tonumber(digits:sub(1, 2), 16)
  local g = tonumber(digits:sub(3, 4), 16)
  local b = tonumber(digits:sub(5, 6), 16)
  if not r or not g or not b then return nil end

  return { r = r / 255, g = g / 255, b = b / 255, a = 1 }
end

---@param player LuaPlayer
---@param picker_setting string
---@param hex_setting string
---@return table?
local function resolve_color(player, picker_setting, hex_setting)
  local player_settings = settings.get_player_settings(player)
  local picker = player_settings[picker_setting].value

  if picker == "default" then return nil end

  if picker == "custom" then
    return parse_hex(player_settings[hex_setting].value)
  end

  return PALETTE[picker]
end

---@param player LuaPlayer
local function apply_colors(player)
  if not enabled() then return end
  if not player or not player.valid then return end

  local character_color = resolve_color(player, CHARACTER_COLOR_SETTING, CHARACTER_COLOR_HEX_SETTING)
  if character_color then
    player.color = character_color
  end

  local chat_color = resolve_color(player, CHAT_COLOR_SETTING, CHAT_COLOR_HEX_SETTING)
  if chat_color then
    player.chat_color = chat_color
  end
end

function M.on_player_created(event)
  apply_colors(game.get_player(event.player_index))
end

function M.on_runtime_mod_setting_changed(event)
  if not event.player_index then return end
  if not SETTING_NAMES[event.setting] then return end
  apply_colors(game.get_player(event.player_index))
end

return M
