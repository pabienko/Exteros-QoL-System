local M = {}

---@generic K, V, R
---@param tbl table<K, V>
---@param fn fun(value: V, key: K): R
---@return table<K, R>
function M.map(tbl, fn)
  local out = {}
  for key, value in pairs(tbl) do
    out[key] = fn(value, key)
  end
  return out
end

---@generic K, V
---@param tbl table<K, V>
---@param value V
---@return K?
function M.find(tbl, value)
  for key, candidate in pairs(tbl) do
    if candidate == value then
      return key
    end
  end
  return nil
end

---@generic K, V
---@param tbl table<K, V>
---@return table<V, K>
function M.invert(tbl)
  local out = {}
  for key, value in pairs(tbl) do
    out[value] = key
  end
  return out
end

return M
