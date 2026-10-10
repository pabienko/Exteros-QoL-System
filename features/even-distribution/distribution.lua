local M = {}

local function sort_by_cap_then_key(a, b)
  if a.cap == b.cap then return a.key < b.key end
  return a.cap < b.cap
end

---@param pool number
---@param entries { key: any, cap: number }[]
---@return table<any, number>
function M.even(pool, entries)
  local sorted = {}
  for i, entry in ipairs(entries) do
    sorted[i] = entry
  end
  table.sort(sorted, sort_by_cap_then_key)

  local remaining = pool
  local count = #sorted
  local out = {}

  for i = 1, count do
    local entry = sorted[i]
    local entries_left = count - i + 1
    local share = math.ceil(remaining / entries_left)
    local give = math.min(entry.cap, share)
    out[entry.key] = give
    remaining = remaining - give
  end

  return out
end

---@param entries { key: any, current: number, cap_total: number }[]
---@param player_amount number
---@return table<any, number>
function M.balance(entries, player_amount)
  local pool = player_amount or 0
  local cap_entries = {}
  for i, entry in ipairs(entries) do
    pool = pool + entry.current
    cap_entries[i] = { key = entry.key, cap = entry.cap_total }
  end

  local targets = M.even(pool, cap_entries)
  local out = {}
  for _, entry in ipairs(entries) do
    out[entry.key] = (targets[entry.key] or 0) - entry.current
  end
  return out
end

return M
