local M = {}

function M.get_even_distribution(total, num_entities)
  if num_entities <= 0 then
    return {}
  end
  
  local base = math.floor(total / num_entities)
  local remainder = total % num_entities
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

function M.get_balanced_distribution(available, current_counts)
  local num = #current_counts
  if num == 0 then return {} end
  
  if available <= 0 then
    local out = {}
    for i = 1, num do out[i] = 0 end
    return out
  end
  
  local counts = {}
  local deltas = {}
  for i = 1, num do
    counts[i] = current_counts[i]
    deltas[i] = 0
  end
  
  local pool = available
  while pool > 0 do
    local min_val = math.huge
    for i = 1, num do
      if counts[i] < min_val then min_val = counts[i] end
    end
    
    local min_indices = {}
    local next_min = math.huge
    for i = 1, num do
      if counts[i] == min_val then
        table.insert(min_indices, i)
      elseif counts[i] < next_min then
        next_min = counts[i]
      end
    end
    
    local diff = (next_min == math.huge) and math.huge or (next_min - min_val)
    local num_min = #min_indices
    
    if diff * num_min <= pool then
      local change = diff
      for _, idx in ipairs(min_indices) do
        counts[idx] = counts[idx] + change
        deltas[idx] = deltas[idx] + change
      end
      pool = pool - (change * num_min)
    else
      local base = math.floor(pool / num_min)
      local remainder = pool % num_min
      for _, idx in ipairs(min_indices) do
        local change = base
        if remainder > 0 then
          change = change + 1
          remainder = remainder - 1
        end
        counts[idx] = counts[idx] + change
        deltas[idx] = deltas[idx] + change
      end
      pool = 0
    end
    
    if next_min == math.huge then break end
  end
  
  return deltas
end

function M.clamp(value, min, max)
  if value < min then
    return min
  elseif value > max then
    return max
  else
    return value
  end
end

function M.round(value)
  return math.floor(value + 0.5)
end

return M