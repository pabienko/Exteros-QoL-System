local M = {}

---@class QolPosition
---@field x number
---@field y number

---@param position MapPosition
---@return QolPosition
function M.ensure_explicit(position)
  local x = position.x or position[1] or 0
  local y = position.y or position[2] or 0
  return { x = x, y = y }
end

return M
