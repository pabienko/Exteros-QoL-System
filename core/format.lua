local M = {}

---@type { [1]: string, [2]: number }[]
local SI_SUFFIXES = {
  { "E", 1e18 },
  { "P", 1e15 },
  { "T", 1e12 },
  { "G", 1e9 },
  { "M", 1e6 },
  { "k", 1e3 },
}

--- Format a number for display: thousands separator always, optional SI suffix.
---@param amount number
---@param append_suffix boolean?
---@return string
function M.number(amount, append_suffix)
  local suffix = ""
  if append_suffix then
    for _, entry in ipairs(SI_SUFFIXES) do
      if math.abs(amount) >= entry[2] then
        amount = amount / entry[2]
        suffix = " " .. entry[1]
        break
      end
    end
    amount = math.floor(amount * 10) / 10
  end

  local formatted = tostring(amount)
  while true do
    local new_formatted, count = formatted:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
    formatted = new_formatted
    if count == 0 then break end
  end
  return formatted .. suffix
end

return M
