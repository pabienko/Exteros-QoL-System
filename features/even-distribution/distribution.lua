-- features/even-distribution/distribution.lua

local core = require("core.init")

local M = {}

--- @param entities LuaEntity[]
--- @param item ItemIDAndQualityIDPair
--- @param player_total uint
--- @return integer[]
function M.get_balanced_distribution(entities, item, player_total)
  local num_entities = #entities

  -- Determine total and individual entity contents
  --- @type uint[]
  local entity_counts = {}
  local total = player_total
  for i = 1, num_entities do
    local count = core.inventory.get_entity_item_count(entities[i], item)
    entity_counts[i] = count
    total = total + count
  end

  -- Get even distribution and calculate deltas for each entity
  local distribution = core.math.get_even_distribution(total, num_entities)
  --- @type integer[]
  local out = {}
  for i = 1, num_entities do
    local current_count = entity_counts[i]
    local target_count = distribution[i]
    out[i] = target_count - current_count
  end
  return out
end

--- @param total uint
--- @param num_entities integer
--- @return uint[]
function M.get_even_distribution(total, num_entities)
  return core.math.get_even_distribution(total, num_entities)
end

return M