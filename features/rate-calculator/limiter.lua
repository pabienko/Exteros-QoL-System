local calc_util = require("features.rate-calculator.calc-util")

---@class Limiter
local M = {}

local MAX_ITERATIONS = 500
local CONVERGENCE_EPSILON = 1e-9

local excluded_paths = {
  [calc_util.POWER_PATH] = true,
  [calc_util.HEAT_PATH] = true,
  [calc_util.POLLUTION_PATH] = true,
}

---@param rates Rates?
---@return double
local function net_output(rates)
  if not rates then
    return 0
  end
  return math.max(0, rates.output.rate - rates.input.rate)
end

---@param rates Rates?
---@return double
local function net_input(rates)
  if not rates then
    return 0
  end
  return math.max(0, rates.input.rate - rates.output.rate)
end

---@param rate Rate
---@param factor double
---@return Rate
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

---@param rates Rates
---@param factor double
---@return Rates
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

---@param set CalculationSet
---@param entity_keys string[]
---@return string[]
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

---@param set CalculationSet
---@param entity_keys string[]
---@param paths string[]
---@return string[]
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

---@param set CalculationSet
---@param entity_keys string[]
---@param paths string[]
---@param limited string[]
---@return table<string, double>, boolean converged
local function iterate(set, entity_keys, paths, limited)
  ---@type table<string, double>
  local u = {}
  for _, key in ipairs(entity_keys) do
    u[key] = 1
  end

  local converged = false
  for _ = 1, MAX_ITERATIONS do
    ---@type table<string, double>, table<string, double>
    local supply, demand = {}, {}
    for _, path in ipairs(paths) do
      supply[path] = 0
      demand[path] = 0
    end
    for _, key in ipairs(entity_keys) do
      local entity_rates = set.entity_rates[key]
      local u_e = u[key] --[[@as double]]
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

---@param set CalculationSet
---@return table<string, Rates>
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
