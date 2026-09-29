local M = {}

local REACH_FIELDS = {
  "character_reach_distance_bonus",
  "character_build_distance_bonus",
  "character_item_drop_distance_bonus",
  "character_item_pickup_distance_bonus",
  "character_loot_pickup_distance_bonus",
  "character_resource_reach_distance_bonus"
}

---@param player LuaPlayer
---@return boolean
function M.looks_applied(player)
  if not player or not player.valid or not player.character then return false end

  local first = player[REACH_FIELDS[1]]
  if first <= 0 then return false end

  for i = 2, #REACH_FIELDS do
    if player[REACH_FIELDS[i]] ~= first then return false end
  end

  return true
end

---@param player LuaPlayer
function M.reset(player)
  if not player or not player.valid or not player.character then return end

  for _, field in ipairs(REACH_FIELDS) do
    player[field] = 0
  end

  player.character_crafting_speed_modifier = 0
  player.character_mining_speed_modifier = 0
  player.character_inventory_slots_bonus = 0
end

---@param player LuaPlayer
---@return boolean
function M.reset_if_applied(player)
  if M.looks_applied(player) then
    M.reset(player)
    return true
  end
  return false
end

return M
