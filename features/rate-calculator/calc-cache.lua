-- Adapted from Rate Calculator by raiguard (MIT, © 2020-2023 Caleb Heuer) and RateCalculatorPlus by Kesha.

-- require() only works during control.lua's initial parsing, never from inside a function body
-- (confirmed: "Require can't be used outside of control.lua parsing" at runtime) - so this has to
-- be a top-level require, not a lazy one inside M.ensure_limited_rates. limiter.lua only requires
-- calc-util.lua (never calc.lua), so this does not close a cycle: calc.lua requires calc-cache.lua
-- requires limiter.lua requires calc-util.lua, and calc-util.lua requires nothing from this feature.
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
