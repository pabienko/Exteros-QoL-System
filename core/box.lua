local position = require("core.position")

local M = {}

---@class QolBoundingBox
---@field left_top QolPosition
---@field right_bottom QolPosition

---@param box BoundingBox
---@return QolBoundingBox
function M.ensure_explicit(box)
  local left_top = box.left_top or box[1]
  local right_bottom = box.right_bottom or box[2]
  return {
    left_top = position.ensure_explicit(left_top),
    right_bottom = position.ensure_explicit(right_bottom),
  }
end

---@param box BoundingBox
---@param amount number
---@return QolBoundingBox
function M.expand(box, amount)
  local explicit = M.ensure_explicit(box)
  return {
    left_top = { x = explicit.left_top.x - amount, y = explicit.left_top.y - amount },
    right_bottom = { x = explicit.right_bottom.x + amount, y = explicit.right_bottom.y + amount },
  }
end

---@param box BoundingBox
---@return QolBoundingBox
function M.snap_outward(box)
  local explicit = M.ensure_explicit(box)
  return {
    left_top = { x = math.floor(explicit.left_top.x), y = math.floor(explicit.left_top.y) },
    right_bottom = { x = math.ceil(explicit.right_bottom.x), y = math.ceil(explicit.right_bottom.y) },
  }
end

return M
