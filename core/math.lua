local M = {}

function M.clamp(value, min, max)
  if value < min then
    return min
  elseif value > max then
    return max
  else
    return value
  end
end

---@type integer
M.MAX_INT53 = 0x1FFFFFFFFFFFFF

---@param num number
---@param divisor number?
---@return number
function M.round_to(num, divisor)
  divisor = divisor or 1
  if num >= 0 then
    return divisor * math.floor(num / divisor + 0.5)
  else
    return divisor * math.ceil(num / divisor - 0.5)
  end
end

return M