local M = {}

---@type table<string, string[]>
M.CONFLICTS = {
  ["even-distribution"] = { "even-distribution", "EvenDistributionLite" },
  ["squeak-through"] = { "squeak-through-2", "some-squeak-through" },
  ["auto-deconstruct"] = { "AutoDeconstruct" },
  ["inventory-repair"] = { "inventory-repair" },
  ["time-controls"] = { "TimeTools", "SpeedControl", "speed-settings", "game-speed-button", "Kux-SpeedButtons", "SetGameSpeed" },
  ["inventory-sort"] = { "manual-inventory-sort", "auto_sort_chests" },
  ["item-count"] = { "yemtositemcount" },
  ["searchlight"] = { "Searchlight_2", "flashlight-pointer" },
  ["force-insert"] = { "force-inventory-insert" },
  ["wire-shortcuts"] = { "WireShortcutX", "copper-wire-shortcut" },
  ["belt-reverser"] = { "belt-reverser-space-age", "belt-reverser2", "belt-reverserup-fixed", "belt-reverser-forked" },
  ["renamer"] = { "Renamer" },
  ["belt-brush"] = { "beltbrush2" },
}

---@param feature string
---@param active_mods table<string, any>?
---@return string?
function M.blocked_by(feature, active_mods)
  if not active_mods then return nil end

  local conflicting_mods = M.CONFLICTS[feature]
  if not conflicting_mods then return nil end

  for _, mod_name in ipairs(conflicting_mods) do
    if active_mods[mod_name] then
      return mod_name
    end
  end
  return nil
end

---@param feature string
---@param active_mods table<string, any>?
---@return boolean
function M.is_blocked(feature, active_mods)
  return M.blocked_by(feature, active_mods) ~= nil
end

return M
