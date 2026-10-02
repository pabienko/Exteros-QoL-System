-- Adapted from Rate Calculator by raiguard (MIT, © 2020-2023 Caleb Heuer) and RateCalculatorPlus by Kesha.
--
-- Stage D replacement for the fork's LP "limit by ingredients" (RCP calc-util.lua 661-1003,
-- 1989-2463). The fork's simplex maximised the plain sum of final-product rates and landed on a
-- vertex solution - a shared intermediate went 100% to whichever consumer yielded more raw "units",
-- starving the others completely - and had no iteration cap (possible freeze) with dense tableaux
-- (seconds of freeze on big selections). This file does not port that algorithm at all; see the
-- stage-D plan for the model this replaces it with.
--
-- NET rates, not gross: a recipe that both consumes and produces the same item (kovarex-
-- enrichment-process: uranium-238 in 5, out 2; any catalyst-style recipe in general) must not
-- throttle itself on its own byproduct. A single such entity, selected alone, has nowhere for the
-- "missing" 3/unit of uranium-238 to come from except outside the selection - in reality it does
-- come from outside, so gross per-entity input/output would wrongly treat the entity as its own
-- bottleneck and drive its utilisation towards 0. Every step below therefore works on each
-- entity's NET rate per path (output minus input, and vice versa, each floored at 0): a path only
-- counts as internal if some entity has a positive NET output on it, S_p/D_p are sums of NET
-- rates, and only entities with a positive NET input on an internal path are ever throttled. Only
-- the final merge step scales and emits the entities' original GROSS rates (by the same u_e), so a
-- shortage still reduces both displayed input and output together, and self-cycling byproducts
-- stay off the hook entirely.

-- Only calc-util, never calc.lua: calc.lua requires calc-cache.lua, which requires this file at
-- its own top level - a require of calc.lua here would close that cycle back onto calc.lua before
-- it has finished loading. calc-util.lua has no dependents of its own, so M.merge_rates lives
-- there (calc.lua just aliases it as M.merge_rates for backward compatibility/tests).
local calc_util = require("features.rate-calculator.calc-util")

--- @class Limiter
local M = {}

local MAX_ITERATIONS = 500
local CONVERGENCE_EPSILON = 1e-9

local excluded_paths = {
  [calc_util.POWER_PATH] = true,
  [calc_util.HEAT_PATH] = true,
  [calc_util.POLLUTION_PATH] = true,
}

--- @param rates Rates?
--- @return double
local function net_output(rates)
  if not rates then
    return 0
  end
  return math.max(0, rates.output.rate - rates.input.rate)
end

--- @param rates Rates?
--- @return double
local function net_input(rates)
  if not rates then
    return 0
  end
  return math.max(0, rates.input.rate - rates.output.rate)
end

--- @param rate Rate
--- @param factor double
--- @return Rate
local function scale_rate(rate, factor)
  local machine_counts = {}
  for machine_name, count in pairs(rate.machine_counts) do
    machine_counts[machine_name] = count * factor
  end
  return {
    machine_counts = machine_counts,
    machines = rate.machines * factor,
    rate = rate.rate * factor,
  }
end

--- @param rates Rates
--- @param factor double
--- @return Rates
local function scale_rates(rates, factor)
  return {
    type = rates.type,
    name = rates.name,
    quality = rates.quality,
    temperature = rates.temperature,
    output = scale_rate(rates.output, factor),
    input = scale_rate(rates.input, factor),
  }
end

--- The paths that at least one selected entity produces a positive NET amount of (excluding the
--- power/heat/pollution dummies, which are never limiting). Everything else is treated as an
--- external, unlimited input - same as the fork did. Using the NET output (not gross) is what
--- keeps a lone catalyst-style entity (produces and consumes the same path) from counting its own
--- byproduct as something that needs balancing against itself.
--- @param set CalculationSet
--- @param entity_keys string[] sorted ascending
--- @return string[] sorted ascending
local function internal_paths(set, entity_keys)
  local found = {}
  for _, key in ipairs(entity_keys) do
    for path, rates in pairs(set.entity_rates[key]) do
      if not found[path] and not excluded_paths[path] and net_output(rates) > 0 then
        found[path] = true
      end
    end
  end
  local paths = {}
  for path in pairs(found) do
    paths[#paths + 1] = path
  end
  table.sort(paths)
  return paths
end

--- Entities with a positive NET input on at least one internal path - only these can ever be
--- throttled; everyone else (including an entity that merely produces an internal path, or one
--- whose own byproduct of that path already covers its own use of it) keeps u_e = 1 forever.
--- @param set CalculationSet
--- @param entity_keys string[] sorted ascending
--- @param paths string[] sorted ascending
--- @return string[] sorted ascending (a subsequence of entity_keys)
local function limited_entity_keys(set, entity_keys, paths)
  local limited = {}
  for _, key in ipairs(entity_keys) do
    local entity_rates = set.entity_rates[key]
    for _, path in ipairs(paths) do
      if net_input(entity_rates[path]) > 0 then
        limited[#limited + 1] = key
        break
      end
    end
  end
  return limited
end

--- Multiplicative fair-share iteration (stage-D plan). Consumers of a scarce intermediate share it
--- in proportion to their demand; when one of them is held back by a different input, its unused
--- share flows to the others on later iterations.
--- @param set CalculationSet
--- @param entity_keys string[] sorted ascending
--- @param paths string[] sorted ascending
--- @param limited string[] sorted ascending (a subsequence of entity_keys)
--- @return table<string, double>, boolean converged
local function iterate(set, entity_keys, paths, limited)
  local u = {}
  for _, key in ipairs(entity_keys) do
    u[key] = 1
  end

  local converged = false
  for _ = 1, MAX_ITERATIONS do
    --- @type table<string, double>, table<string, double>
    local supply, demand = {}, {}
    for _, path in ipairs(paths) do
      supply[path] = 0
      demand[path] = 0
    end
    for _, key in ipairs(entity_keys) do
      local entity_rates = set.entity_rates[key]
      local u_e = u[key]
      for _, path in ipairs(paths) do
        local rates = entity_rates[path]
        if rates then
          supply[path] = supply[path] + net_output(rates) * u_e
          demand[path] = demand[path] + net_input(rates) * u_e
        end
      end
    end

    local max_delta = 0
    for _, key in ipairs(limited) do
      local entity_rates = set.entity_rates[key]
      -- Start at +inf, not 1: the plan's r = min over inputs of S/D can legitimately be > 1 (a
      -- previously-scarce input has since freed up), and starting at 1 would silently discard any
      -- such path_ratio > 1 (1 < ratio is never true), permanently preventing u from ever growing
      -- back - it could only shrink. The final math.min(1, ...) below still caps u itself at 1.
      local ratio = math.huge
      for _, path in ipairs(paths) do
        local rates = entity_rates[path]
        if net_input(rates) > 0 then
          local d = demand[path]
          local path_ratio = d > 0 and (supply[path] / d) or 1
          if path_ratio < ratio then
            ratio = path_ratio
          end
        end
      end
      local new_u = math.min(1, u[key] * ratio)
      local delta = math.abs(new_u - u[key])
      if delta > max_delta then
        max_delta = delta
      end
      u[key] = new_u
    end

    if max_delta < CONVERGENCE_EPSILON then
      converged = true
      break
    end
  end

  return u, converged
end

--- @param set CalculationSet
--- @return table<string, Rates>
function M.calculate(set)
  local entity_keys = {}
  for key in pairs(set.entity_rates) do
    entity_keys[#entity_keys + 1] = key
  end
  table.sort(entity_keys)

  local paths = internal_paths(set, entity_keys)
  local limited = limited_entity_keys(set, entity_keys, paths)

  local u, converged = iterate(set, entity_keys, paths, limited)
  if not converged then
    calc_util.add_error(set, "limit-not-converged")
  end

  local limited_rates = {}
  for _, key in ipairs(entity_keys) do
    local entity_rates = set.entity_rates[key]
    local u_e = u[key]
    if u_e == 1 then
      calc_util.merge_rates(limited_rates, entity_rates)
    else
      local scaled = {}
      for path, rates in pairs(entity_rates) do
        scaled[path] = scale_rates(rates, u_e)
      end
      calc_util.merge_rates(limited_rates, scaled)
    end
  end

  return limited_rates
end

return M
