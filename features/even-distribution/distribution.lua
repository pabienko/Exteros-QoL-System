local core = require("core.init")
local M = {}

local function sort_by_count(a, b)
  return a.count < b.count
end

function M.get_even_distribution(total, entities)
  local num_entities = #entities
  if num_entities == 0 then return {} end
  
  local base = math.floor(total / num_entities)
  local remainder = total % num_entities
  local out = {}
  
  for i = 1, num_entities do
    local count = base
    if remainder > 0 then
      remainder = remainder - 1
      count = count + 1
    end
    out[i] = { entity = entities[i], count = count }
  end
  
  table.sort(out, sort_by_count)
  return out
end

function M.get_balanced_distribution(entities, item, player_total)
  local num_entities = #entities
  if num_entities == 0 then return {} end
  
  local entity_counts = {}
  local total = player_total
  
  for i = 1, num_entities do
    local count = core.inventory.get_entity_item_count(entities[i], item)
    entity_counts[i] = count
    total = total + count
  end
  
  local balanced = math.floor(total / num_entities)
  local remainder = total % num_entities
  local out = {}
  
  for i = 1, num_entities do
    local entity_count = entity_counts[i]
    local target_count = balanced
    if remainder > 0 then
      remainder = remainder - 1
      target_count = target_count + 1
    end
    out[i] = { entity = entities[i], count = target_count - entity_count }
  end
  
  table.sort(out, sort_by_count)
  return out
end

return M