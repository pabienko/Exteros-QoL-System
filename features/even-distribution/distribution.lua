-- features/even-distribution/distribution.lua

local utils = require("features.even-distribution.utils")

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
    local count = utils.get_entity_item_count(entities[i], item)
    entity_counts[i] = count
    total = total + count
  end

  -- Get even distribution and calculate deltas for each entity
  local base = math.floor(total / num_entities)
  local remainder = total % num_entities
  --- @type integer[]
  local out = {}
  for i = 1, num_entities do
    local current_count = entity_counts[i]
    local target_count = base
    if remainder > 0 then
      remainder = remainder - 1
      target_count = target_count + 1
    end
    out[i] = target_count - current_count
  end
  return out
end

--- @param total uint
--- @param num_entities integer
--- @return uint[]
function M.get_even_distribution(total, num_entities)
  local base = math.floor(total / num_entities)
  local remainder = total % num_entities
  --- @type uint[]
  local out = {}
  for i = 1, num_entities do
    local count = base
    if remainder > 0 then
      remainder = remainder - 1
      count = count + 1
    end
    out[i] = count
  end
  return out
end

return M