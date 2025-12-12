--[[
  CORE/MATH.LUA - Mathematical Utilities
  
  Common mathematical functions used across features.
  Includes distribution algorithms, rounding, clamping, etc.
]]

local M = {}

--- Calculate even distribution of items across entities
--- @param total uint
--- @param num_entities integer
--- @return uint[]
function M.get_even_distribution(total, num_entities)
  if num_entities <= 0 then
    return {}
  end
  
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

--- Clamp a value between min and max
--- @param value number
--- @param min number
--- @param max number
--- @return number
function M.clamp(value, min, max)
  if value < min then
    return min
  elseif value > max then
    return max
  else
    return value
  end
end

--- Round a number to the nearest integer
--- @param value number
--- @return integer
function M.round(value)
  return math.floor(value + 0.5)
end

--- Calculate percentage
--- @param part number
--- @param total number
--- @return number
function M.percentage(part, total)
  if total == 0 then
    return 0
  end
  return (part / total) * 100
end

return M
