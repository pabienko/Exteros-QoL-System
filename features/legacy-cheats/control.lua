local legacy = require("core.legacy-cheats")
local M = {}

local ADDON = "Exteros-QoL-Cheats"

function M.init()
  storage.legacy_cheats_cleaned = true
end

function M.on_configuration_changed()
  if storage.legacy_cheats_cleaned then return end
  storage.legacy_cheats_cleaned = true

  if script.active_mods[ADDON] then return end

  for _, player in pairs(game.players) do
    legacy.reset_if_applied(player)
  end
end

return M
