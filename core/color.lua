local M = {}

---@param hex string?
---@param default Color
---@return Color
function M.parse_hex(hex, default)
  if type(hex) ~= "string" then return default end

  local clean = hex:match("^#?(%x%x%x%x%x%x%x%x)$") or hex:match("^#?(%x%x%x%x%x%x)$")
  if not clean then return default end

  local r = tonumber(clean:sub(1, 2), 16)
  local g = tonumber(clean:sub(3, 4), 16)
  local b = tonumber(clean:sub(5, 6), 16)
  local a = #clean == 8 and tonumber(clean:sub(7, 8), 16) or 255

  if not r or not g or not b or not a then return default end

  return { r = r / 255, g = g / 255, b = b / 255, a = a / 255 }
end

return M
