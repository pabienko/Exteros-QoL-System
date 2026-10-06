
local limiter = require("features.rate-calculator.limiter")

--- @class CalcCache
local M = {}

--- @param set CalculationSet
function M.invalidate(set)
  set.limited_rates = nil
  set.fully_limited_rates = nil
end

--- @param set CalculationSet
--- @return table<string, Rates>
function M.ensure_limited_rates(set)
  if not set.limited_rates then
    set.limited_rates = limiter.calculate(set)
  end
  return set.limited_rates
end

--- @param set CalculationSet
--- @param limit_final_products boolean
--- @return table<string, Rates>
function M.get_rates_table(set, limit_final_products)
  if limit_final_products then
    return M.ensure_limited_rates(set)
  end
  return set.rates
end

return M
