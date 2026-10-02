-- Adapted from Rate Calculator by raiguard (MIT, © 2020-2023 Caleb Heuer) and RateCalculatorPlus by Kesha.

local core = require("core.init")
local compat = core.compat

-- Space Age (B4 follow-up). features/rate-calculator/final-fixes.lua snapshots prototype-stage-
-- only fields (max_fluid_usage, fuel/oxidizer/input/output fluid identities,
-- resource_searching_offset) into this mod-data prototype at data-final-fixes time, because they
-- have no runtime accessor in the API definitions available for this port. Memoized: static
-- prototype data, identical on every peer, same spirit as core.compat's probe-once-and-cache.
--- @type table<string, table<string, table>>
local entity_data_cache = nil

---@return table<string, table<string, table>>
local function get_entity_data()
  if entity_data_cache then
    return entity_data_cache
  end
  local mod_data = prototypes.mod_data["exteros-qol-rcalc-entity-data"]
  entity_data_cache = (mod_data and mod_data.data) or {}
  return entity_data_cache
end

--- @alias RateCategory
--- | "output"
--- | "input"

--- @class ResourceData
--- @field occurrences uint
--- @field products Product[]
--- @field required_fluid Product?
--- @field mining_time double

--- @alias Timescale
--- | "per-second",
--- | "per-minute",
--- | "per-10-minutes",
--- | "per-hour",
--- | "transport-belts",
--- | "inserters",

--- @class CalcUtil
local M = {}

--- Item name constants for the three dummy items that stand in for power, heat and pollution
--- rows. Stage C (gui-rates) reads these instead of hard-coding the item name.
M.POWER_ITEM = "exteros-qol-rcalc-power-dummy"
M.HEAT_ITEM = "exteros-qol-rcalc-heat-dummy"
M.POLLUTION_ITEM = "exteros-qol-rcalc-pollution-dummy"

--- Path constants (`"item/<name>/normal"`) for the same three dummies.
M.POWER_PATH = "item/" .. M.POWER_ITEM .. "/normal"
M.HEAT_PATH = "item/" .. M.HEAT_ITEM .. "/normal"
M.POLLUTION_PATH = "item/" .. M.POLLUTION_ITEM .. "/normal"

--- @param set CalculationSet
--- @param error CalculationError
function M.add_error(set, error)
  set.errors[error] = true
end

--- @param set CalculationSet
--- @param category RateCategory
--- @param value_type string
--- @param name string
--- @param quality string
--- @param amount double
--- @param invert boolean
--- @param machine_name string?
--- @param temperature double?
function M.add_rate(set, category, value_type, name, quality, amount, invert, machine_name, temperature)
  -- B3.3: a negative or NaN amount must never reach a row - the original clamped the ROW total to
  -- zero (`rate = max(rate + amount, 0)`), which silently ate into whatever other machines had
  -- already contributed to that row. Record it as an error instead and discard it.
  if amount ~= amount or amount < 0 then
    M.add_error(set, "invalid-rate")
    return
  end

  local set_rates = set.rates
  -- B3.8: the path must not fork on temperature - a crafter's hot product and a cold consumer of
  -- the same fluid belong in the same row. The temperature is kept on the row as information only.
  local path = value_type .. "/" .. name .. "/" .. quality
  local rates = set_rates[path]
  if not rates then
    if invert then
      return -- Don't remove from rates that don't exist.
    end
    --- @type Rates
    rates = {
      type = value_type,
      name = name,
      quality = quality,
      temperature = temperature,
      output = { machines = 0, machine_counts = {}, rate = 0 },
      input = { machines = 0, machine_counts = {}, rate = 0 },
    }
    set_rates[path] = rates
  elseif temperature and (not rates.temperature or temperature > rates.temperature) then
    -- B3.8: several temperatures can merge into one row; keep the highest seen.
    rates.temperature = temperature
  end
  if invert then
    amount = -amount
  end
  --- @type Rate
  local rate = rates[category]
  if machine_name then
    local counts = rate.machine_counts
    -- Don't remove a machine that doesn't exist
    if not counts[machine_name] and invert then
      goto no_rate
    end
    counts[machine_name] = (counts[machine_name] or 0) + (invert and -1 or 1)
    if counts[machine_name] == 0 then
      counts[machine_name] = nil
    end
  end
  rate.rate = rate.rate + amount
  rate.machines = rate.machines + (invert and -1 or 1)
  -- Account for floating-point imprecision
  if rate.rate < 0.00001 then
    rate.rate = 0
  end

  ::no_rate::
  if rates.input.machines == 0 and rates.output.machines == 0 then
    set_rates[path] = nil
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
--- @param emissions_per_second double
--- @return double
function M.process_burner(set, entity, invert, emissions_per_second)
  local entity_prototype = entity.prototype
  local burner_prototype = entity_prototype.burner_prototype --[[@as LuaBurnerPrototype]]
  local burner = entity.burner --[[@as LuaBurner]]

  local currently_burning = burner.currently_burning
  if not currently_burning then
    local item = burner.inventory.get_contents()[1]
    if item then
      currently_burning = { name = prototypes.item[item.name], quality = prototypes.quality[item.quality] }
    end
  end
  if not currently_burning then
    M.add_error(set, "no-fuel")
    return emissions_per_second
  end

  local currently_burning_prototype = currently_burning.name

  local max_energy_usage = entity_prototype.get_max_energy_usage(entity.quality) * (entity.consumption_bonus + 1)
  local burns_per_second = 1
    / (currently_burning_prototype.fuel_value / (max_energy_usage / burner_prototype.effectivity) / 60)

  M.add_rate(set, "input", "item", currently_burning_prototype.name, currently_burning.quality.name, burns_per_second, invert, entity.name)

  local burnt_result = currently_burning_prototype.burnt_result
  if burnt_result then
    M.add_rate(set, "output", "item", burnt_result.name, currently_burning.quality.name, burns_per_second, invert, entity.name)
  end

  local emissions = (burner_prototype.emissions_per_joule[set.pollutant] or 0)
    * 60
    * max_energy_usage
    * currently_burning_prototype.fuel_emissions_multiplier
  return emissions_per_second + emissions
end

--- Fluid name occupying a fluid box, looking at the filter first (design intent) and falling back
--- to whatever is actually in the box (B2: 2.0/2.1 fluidbox access goes through core.compat).
--- @param entity LuaEntity
--- @param index integer
--- @return string?
local function get_fluid_name(entity, index)
  local name = compat.fluid_filter_name(entity, index)
  if name then
    return name
  end
  local fluid = compat.fluid(entity, index)
  return fluid and fluid.name
end

--- @param set CalculationSet
--- @param entity LuaEntity
function M.process_beacon(set, entity)
  if entity.status == defines.entity_status.no_power then
    M.add_error(set, "no-power")
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_boiler(set, entity, invert)
  local entity_prototype = entity.prototype

  local input_fluid_name = get_fluid_name(entity, 1)
  if not input_fluid_name then
    M.add_error(set, "no-input-fluid")
    return
  end
  local input_fluid = prototypes.fluid[input_fluid_name]

  local input_prototype = compat.fluid_box_prototype(entity, 1)
  local minimum_temperature = (input_prototype and input_prototype.minimum_temperature) or input_fluid.default_temperature

  -- B3.2: 2.0 renamed "heat-water-inside" to "heat-fluid-inside"; both must be recognised.
  local heats_in_place = entity_prototype.boiler_mode == "heat-water-inside" or entity_prototype.boiler_mode == "heat-fluid-inside"

  local heating_target
  if heats_in_place then
    -- B3.2 (measured): entity_prototype.target_temperature reads 0 in this mode, which made the
    -- original formula produce a NEGATIVE fluid usage. The fluid is heated in place, so its own
    -- max_temperature is the design target instead.
    heating_target = input_fluid.max_temperature
  else
    heating_target = entity_prototype.target_temperature
  end
  local energy_per_amount = (heating_target - minimum_temperature) * input_fluid.heat_capacity
  local fluid_usage = entity_prototype.get_max_energy_usage(entity.quality) / energy_per_amount * 60
  M.add_rate(set, "input", "fluid", input_fluid_name, "normal", fluid_usage, invert, entity.name)

  if heats_in_place then
    -- B3.2: skip the output-box branch entirely in this mode, same fluid comes back out hot.
    M.add_rate(set, "output", "fluid", input_fluid_name, "normal", fluid_usage, invert, entity.name, input_fluid.max_temperature)
    return
  end

  local output_fluid_name = get_fluid_name(entity, 2)
  if not output_fluid_name then
    return
  end
  local output_fluid = prototypes.fluid[output_fluid_name]

  local output_prototype = compat.fluid_box_prototype(entity, 2)
  local output_minimum_temperature = (output_prototype and output_prototype.minimum_temperature) or output_fluid.default_temperature
  local output_energy_per_amount = (entity_prototype.target_temperature - output_minimum_temperature) * output_fluid.heat_capacity
  local output_fluid_usage = entity_prototype.get_max_energy_usage(entity.quality) / output_energy_per_amount * 60
  M.add_rate(set, "output", "fluid", output_fluid_name, "normal", output_fluid_usage, invert, entity.name, entity_prototype.target_temperature)
end

-- B2: get_product_quality / get_ingredient_quality exist on 2.1 only; probed once and cached.
local has_product_quality_api = nil

--- @param recipe LuaRecipe
--- @return boolean
local function detect_product_quality_api(recipe)
  if has_product_quality_api ~= nil then
    return has_product_quality_api
  end
  local success, value = pcall(function()
    return recipe.prototype.get_product_quality
  end)
  has_product_quality_api = success and value ~= nil
  return has_product_quality_api
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
--- @param emissions_per_second double
--- @return double
function M.process_crafter(set, entity, invert, emissions_per_second)
  local recipe, quality = entity.get_recipe()
  if not recipe and entity.type == "furnace" then
    local prev = entity.previous_recipe
    if prev then
      -- B3.11: look the recipe up on the entity's OWN force, not the calculating player's force -
      -- they can differ (e.g. a captured enemy furnace, or a player looking at another force's base).
      recipe = entity.force.recipes[prev.name.name]
      quality = prev.quality --[[@as LuaQualityPrototype]]
    end
  end
  if not recipe then
    M.add_error(set, "no-recipe")
    return emissions_per_second
  end
  --- @cast quality -?

  local recipe_duration = recipe.energy / entity.crafting_speed
  local use_quality_api = detect_product_quality_api(recipe)

  for index, ingredient in ipairs(recipe.ingredients) do
    local amount = ingredient.amount / recipe_duration
    local ingredient_quality
    if ingredient.type == "item" then
      if use_quality_api then
        ingredient_quality = recipe.prototype.get_ingredient_quality(index, quality).name
      else
        ingredient_quality = quality.name
      end
    else
      ingredient_quality = "normal"
    end
    M.add_rate(set, "input", ingredient.type, ingredient.name, ingredient_quality, amount, invert, entity.name)
  end

  local productivity = 1
    + math.min(entity.productivity_bonus + recipe.productivity_bonus, recipe.prototype.maximum_productivity)

  for index, product in ipairs(recipe.products) do
    if product.type == "research-progress" then
      goto continue
    end

    -- B3.1-style precedence fix via core.compat: expected amount BEFORE productivity, chance applied.
    local expected_amount = compat.product_expected_amount(product)
    local productivity_base_complement = math.min(expected_amount, product.ignored_by_productivity or 0)
    local productivity_base = expected_amount - productivity_base_complement

    local amount = (productivity_base_complement + productivity_base * productivity) / recipe_duration

    local product_quality
    if product.type == "item" then
      if use_quality_api then
        product_quality = recipe.prototype.get_product_quality(index, quality).name
      else
        product_quality = quality.name
      end
    else
      product_quality = "normal"
    end

    M.add_rate(set, "output", product.type, product.name, product_quality, amount, invert, entity.name, product.temperature)

    ::continue::
  end

  return emissions_per_second * recipe.prototype.emissions_multiplier * (1 + entity.pollution_bonus)
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
--- @param emissions_per_second double
--- @return double
function M.process_electric_energy_source(set, entity, invert, emissions_per_second)
  local entity_prototype = entity.prototype

  -- Electric energy interfaces can have their settings adjusted at runtime, so checking the energy source is pointless.
  if entity.type == "electric-energy-interface" then
    local production = entity.power_production * 60
    if production > 0 then
      M.add_rate(set, "output", "item", M.POWER_ITEM, "normal", production, invert, entity.name)
    end
    local usage = entity.power_usage * 60
    if usage > 0 then
      M.add_rate(set, "input", "item", M.POWER_ITEM, "normal", usage, invert, entity.name)
    end
    return emissions_per_second
  end

  local electric_energy_source_prototype = entity_prototype.electric_energy_source_prototype --[[@as LuaElectricEnergySourcePrototype]]

  local added_emissions = 0
  local max_energy_usage = entity_prototype.get_max_energy_usage(entity.quality) or 0
  if max_energy_usage > 0 and max_energy_usage < core.math.MAX_INT53 then
    local consumption_bonus = (entity.consumption_bonus + 1)
    local drain = electric_energy_source_prototype.drain
    local amount = max_energy_usage * consumption_bonus
    if max_energy_usage ~= drain then
      amount = amount + drain
    end
    M.add_rate(set, "input", "item", M.POWER_ITEM, "normal", amount * 60, invert, entity.name)
    if entity.status == defines.entity_status.no_power then
      M.add_error(set, "no-power")
    end
    added_emissions = (electric_energy_source_prototype.emissions_per_joule[set.pollutant] or 0)
      * (max_energy_usage * consumption_bonus)
      * 60
  end

  local max_energy_production = entity_prototype.get_max_energy_production(entity.quality)
  if max_energy_production > 0 and max_energy_production < core.math.MAX_INT53 then
    if entity.type == "solar-panel" then
      max_energy_production = max_energy_production
        * entity.surface.solar_power_multiplier
        * entity.surface.get_property("solar-power")
        / prototypes.surface_property["solar-power"].default_value
    end
    M.add_rate(set, "output", "item", M.POWER_ITEM, "normal", max_energy_production * 60, invert, entity.name)
  end

  return emissions_per_second + added_emissions
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
--- @param emissions_per_second double
--- @return double
function M.process_fluid_energy_source(set, entity, invert, emissions_per_second)
  --- @type LuaEntityPrototype
  local entity_prototype = entity.prototype
  local fluid_energy_source_prototype = entity_prototype.fluid_energy_source_prototype --[[@as LuaFluidEnergySourcePrototype]]

  -- B3.5: type AND temperature must come from the SAME fluid box index. The energy source
  -- fluidbox is always the first one, except for boilers where it is the last one.
  local fluid_index = entity.type == "boiler" and compat.fluidbox_count(entity) or 1
  local fluid_name = get_fluid_name(entity, fluid_index)
  if not fluid_name then
    M.add_error(set, "no-input-fluid")
    return emissions_per_second
  end
  local fluid_prototype = prototypes.fluid[fluid_name]
  local max_energy_usage = entity_prototype.get_max_energy_usage(entity.quality) * (entity.consumption_bonus + 1)

  local value
  if fluid_energy_source_prototype.scale_fluid_usage then
    if fluid_energy_source_prototype.burns_fluid and fluid_prototype.fuel_value > 0 then
      value = max_energy_usage / (fluid_prototype.fuel_value / 60) / fluid_energy_source_prototype.effectivity
    else
      local fluid = compat.fluid(entity, fluid_index)
      if not fluid then
        M.add_error(set, "no-input-fluid")
        return emissions_per_second
      end
      -- If the fluid is equal to its default temperature, then nothing will happen
      local temperature_value = fluid.temperature - fluid_prototype.default_temperature
      if temperature_value > 0 then
        value = max_energy_usage
          / (temperature_value * fluid_prototype.heat_capacity)
          / fluid_energy_source_prototype.effectivity
          * 60
      end
    end
  else
    -- B3.4 (measured): no division by effectivity here - the fixed-rate burn is the usage itself.
    value = fluid_energy_source_prototype.fluid_usage_per_tick * 60
  end
  if not value then
    return emissions_per_second -- No error, but not rate either
  end

  M.add_rate(set, "input", "fluid", fluid_name, "normal", value, invert, entity.name)

  return (fluid_energy_source_prototype.emissions_per_joule[set.pollutant] or 0) * max_energy_usage * 60
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_generator(set, entity, invert)
  local entity_prototype = entity.prototype
  local fluid_name = get_fluid_name(entity, 1)
  if not fluid_name then
    M.add_error(set, "no-input-fluid")
    return
  end
  local fluid_prototype = prototypes.fluid[fluid_name]
  local fluid_usage_per_tick = entity_prototype.get_fluid_usage_per_tick(entity.quality)
  M.add_rate(set, "input", "fluid", fluid_name, "normal", fluid_usage_per_tick * 60, invert, entity.name)

  -- B3.7 (measured): the original used get_max_power_output(), the NAMEPLATE value at
  -- maximum_temperature regardless of what the fluid box is actually receiving (165C steam
  -- measured ~1.8MW, nameplate showed 5.82MW). Formula from LuaEntityPrototype/GeneratorPrototype
  -- docs: energy = fluid_amount * (fluid_temperature - fluid_default_temperature) * fluid_heat_capacity * effectivity,
  -- with burns_fluid entities using fuel_value instead of temperature.
  local effectivity = entity_prototype.effectivity or 1
  local power
  if entity_prototype.burns_fluid then
    power = fluid_usage_per_tick * 60 * fluid_prototype.fuel_value * effectivity
  else
    local fluid = compat.fluid(entity, 1)
    -- Fall back to the design maximum when the box is empty, so the number shown is meaningful.
    local temperature = (fluid and fluid.temperature) or entity_prototype.maximum_temperature
    temperature = math.min(temperature, entity_prototype.maximum_temperature)
    power = fluid_usage_per_tick * 60 * math.max(temperature - fluid_prototype.default_temperature, 0) * fluid_prototype.heat_capacity * effectivity
  end
  -- get_max_power_output, like get_max_energy_usage elsewhere in this file, returns J PER TICK -
  -- `power` above is already W (J/s), so the cap needs the same *60 everything else in this file
  -- applies before comparing/adding a per-tick prototype figure to a per-second rate.
  local max_power_output = entity_prototype.get_max_power_output(entity.quality)
  if max_power_output and max_power_output > 0 then
    power = math.min(power, max_power_output * 60)
  end
  if power > 0 then
    M.add_rate(set, "output", "item", M.POWER_ITEM, "normal", power, invert, entity.name)
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_heat_energy_source(set, entity, invert)
  M.add_rate(
    set,
    "input",
    "item",
    M.HEAT_ITEM,
    "normal",
    entity.prototype.get_max_energy_usage(entity.quality) * (1 + entity.consumption_bonus) * 60,
    invert,
    entity.name
  )
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_lab(set, entity, invert)
  local research_data = set.research_data
  if not research_data then
    M.add_error(set, "no-active-research")
    return
  end

  local science_pack_drain = entity.prototype.science_pack_drain_rate_percent / 100
  local research_multiplier = research_data.multiplier
  local researching_speed = entity.prototype.get_researching_speed(entity.quality)
  local speed_modifier = research_data.speed_modifier
  -- XXX: Due to a bug with entity_speed_bonus, we must subtract the force's lab speed bonus and convert it to a
  -- multiplicative relationship
  local lab_multiplier = research_multiplier
    * ((entity.speed_bonus + 1 - speed_modifier) * (speed_modifier + 1))
    * researching_speed
    * science_pack_drain

  local inputs = core.table.invert(entity.prototype.lab_inputs)
  for _, ingredient in pairs(research_data.ingredients) do
    if not inputs[ingredient.name] then
      M.add_error(set, "incompatible-science-packs")
      return
    end
  end

  for _, ingredient in ipairs(research_data.ingredients) do
    -- TODO: Select quality
    local amount = (ingredient.amount * lab_multiplier) / compat.science_pack_durability(prototypes.item[ingredient.name])
    M.add_rate(set, "input", "item", ingredient.name, "normal", amount, invert, entity.name)
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_mining_drill(set, entity, invert)
  local entity_prototype = entity.prototype
  local entity_productivity_bonus = entity.productivity_bonus
  local entity_speed_bonus = entity.speed_bonus

  -- B3.13: use the per-quality radius method when it exists, respecting resource_searching_offset.
  local radius
  local success, result = pcall(function()
    return entity_prototype.get_mining_drill_radius(entity.quality)
  end)
  if success and result then
    radius = result
  else
    radius = entity_prototype.mining_drill_radius
  end
  radius = radius + 0.01

  -- B4 follow-up: resource_searching_offset is a prototype-stage-only field with no runtime
  -- accessor in the API definitions available for this port; read it from the mod-data snapshot
  -- (features/rate-calculator/final-fixes.lua) instead of the (nonexistent) runtime field.
  local center = entity.position
  local drill_data = get_entity_data()["mining-drill"]
  local drill_entry = drill_data and drill_data[entity.name]
  local offset = drill_entry and drill_entry.resource_searching_offset
  if offset then
    center = { x = center.x + offset.x, y = center.y + offset.y }
  end
  local box = {
    left_top = { x = center.x - radius, y = center.y - radius },
    right_bottom = { x = center.x + radius, y = center.y + radius },
  }
  local resource_entities = entity.surface.find_entities_filtered({ area = box })
  local resource_entities_len = #resource_entities
  if resource_entities_len == 0 then
    M.add_error(set, "no-mineable-resources")
    return
  end

  --- @type table<string, ResourceData>
  local resources = {}
  local num_resource_entities = 0
  local has_fluidbox = next(entity_prototype.fluidbox_prototypes) and true or false
  local resource_categories = entity_prototype.resource_categories or {}
  for i = 1, resource_entities_len do
    local resource = resource_entities[i]
    local resource_name = resource.name

    -- If this resource has already been processed
    local resource_data = resources[resource_name]
    if resource_data then
      resource_data.occurrences = resource_data.occurrences + 1
      num_resource_entities = num_resource_entities + 1
      goto continue
    end

    local resource_prototype = resource.prototype
    if not resource_categories[resource_prototype.resource_category] then
      goto continue
    end
    local mineable_properties = resource_prototype.mineable_properties
    local required_fluid = mineable_properties.required_fluid
    -- B3.14: a resource the drill cannot mine (needs a fluid input it doesn't have) must not
    -- inflate the occurrence denominator either - exclude it before counting, not after.
    if required_fluid and not has_fluidbox then
      goto continue
    end
    num_resource_entities = num_resource_entities + 1

    resource_data = {
      occurrences = 1,
      products = mineable_properties.products,
      mining_time = mineable_properties.mining_time,
    }

    if resource_prototype.infinite_resource then
      resource_data.mining_time = resource_data.mining_time
        / (resource.amount / resource_prototype.normal_resource_amount)
    end

    if required_fluid then
      resource_data.required_fluid = {
        type = "fluid",
        name = required_fluid,
        amount = mineable_properties.fluid_amount / 10, -- Ten mining operations per fluid consumed
        probability = 1,
      }
    end

    resources[resource_name] = resource_data

    ::continue::
  end

  if num_resource_entities == 0 then
    M.add_error(set, "no-mineable-resources")
    return
  end

  -- Process resource entities

  local adjusted_mining_speed = entity_prototype.mining_speed
    * (entity_speed_bonus + 1)
    * (entity_productivity_bonus + 1)

  for _, resource_data in pairs(resources) do
    local resource_multiplier = (adjusted_mining_speed / resource_data.mining_time)
      * (resource_data.occurrences / num_resource_entities)

    -- Add required fluid to inputs
    local required_fluid = resource_data.required_fluid
    if required_fluid then
      -- Productivity does not apply to ingredients
      local fluid_per_second = required_fluid.amount * resource_multiplier / (entity_productivity_bonus + 1)

      -- Add to inputs table
      M.add_rate(set, "input", "fluid", required_fluid.name, "normal", fluid_per_second, invert, entity.name)
    end

    -- Iterate each product
    for _, product in pairs(resource_data.products or {}) do
      -- B3.1 (measured, precedence bug): the original computed
      -- `amount_max - (amount_max - amount_min) / 2 * resource_multiplier`, which only scaled the
      -- half-range term by resource_multiplier instead of the whole expected amount.
      local expected_amount = compat.product_expected_amount(product)
      local adjusted_product_per_second = expected_amount * resource_multiplier

      -- Add to outputs table
      M.add_rate(set, "output", product.type, product.name, "normal", adjusted_product_per_second, invert, entity.name, product.temperature)
    end
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_offshore_pump(set, entity, invert)
  local fluid = compat.fluid(entity, 1)
  local fluid_name = fluid and fluid.name
  if not fluid_name then
    -- B2: no more flib migration/version check - get_pumping_speed exists on both versions.
    -- A pcall-probed fallback method name, mirroring the style used elsewhere for 2.0/2.1 gaps.
    local success, source = pcall(function()
      return entity.get_fluid_source_fluid and entity.get_fluid_source_fluid()
    end)
    if success and source then
      -- get_fluid_source_fluid() returns the fluid NAME (a string), not a table.
      fluid_name = type(source) == "table" and source.name or source
    end
  end
  if not fluid_name then
    -- The original silently returned here without a rate or an error; we surface it instead so a
    -- pump placed over nothing isn't mistaken for a pump that produces 0/s by design.
    M.add_error(set, "no-input-fluid")
    return
  end

  local pumping_speed = entity.prototype.get_pumping_speed(entity.quality)
  M.add_rate(set, "output", "fluid", fluid_name, "normal", pumping_speed * 60, invert, entity.name)
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_reactor(set, entity, invert)
  -- B3.12: heat output already includes (1 + neighbour_bonus); fuel use (handled generically via
  -- process_burner) is intentionally left alone.
  M.add_rate(
    set,
    "output",
    "item",
    M.HEAT_ITEM,
    "normal",
    entity.prototype.get_max_energy_usage(entity.quality)
      * (1 + entity.neighbour_bonus)
      * (1 + entity.consumption_bonus)
      * 60,
    invert,
    entity.name
  )
end

-- Space Age (B4). Memoized because prototype data is static for the session; same probe-once-and-
-- cache spirit as core.compat, just for a different lookup (there is no reverse plant->seed link
-- on the plant prototype itself).
--- @type table<string, string|false>
local seed_item_cache = {}

--- @param plant_name string
--- @return string?
local function seed_item_for_plant(plant_name)
  local cached = seed_item_cache[plant_name]
  if cached ~= nil then
    return cached or nil
  end
  local found = nil
  for item_name, item_prototype in pairs(prototypes.item) do
    local plant_result = item_prototype.plant_result
    if plant_result and plant_result.name == plant_name then
      found = item_name
      break
    end
  end
  seed_item_cache[plant_name] = found or false
  return found
end

--- Space Age. Electric power usage is handled generically (process_electric_energy_source) via
--- process_entity's dispatch. Each owned plant contributes its harvest (mineable_properties.products,
--- scaled to a rate by growth_ticks) and one seed per cycle.
--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_agricultural_tower(set, entity, invert)
  local plants = entity.owned_plants
  if not plants or #plants == 0 then
    M.add_error(set, "no-plants")
    return
  end
  for _, plant in pairs(plants) do
    if plant.valid then
      local plant_prototype = plant.prototype
      local growth_ticks = plant_prototype.growth_ticks
      if growth_ticks and growth_ticks > 0 then
        local cycle_seconds = growth_ticks / 60
        local mineable = plant_prototype.mineable_properties
        if mineable and mineable.products then
          for _, product in pairs(mineable.products) do
            local amount = compat.product_expected_amount(product) / cycle_seconds
            M.add_rate(set, "output", product.type, product.name, "normal", amount, invert, entity.name, product.temperature)
          end
        end
        local seed_name = seed_item_for_plant(plant_prototype.name)
        if seed_name then
          M.add_rate(set, "input", "item", seed_name, "normal", 1 / cycle_seconds, invert, entity.name)
        end
      end
    end
  end
end

--- Space Age. Intake depends on passing asteroids and cannot be computed; power usage is handled
--- generically via process_electric_energy_source.
--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_asteroid_collector(set, entity, invert)
  M.add_error(set, "unpredictable-input")
end

--- Space Age (B4 follow-up). Electric input (energy_source) and fuel-cell burn (burner) are
--- handled generically via process_electric_energy_source / process_burner through process_entity's
--- dispatch. The fluid conversion (input_fluid_box -> output_fluid_box, scaled by max_fluid_usage)
--- and its target_temperature need the mod-data snapshot (final-fixes.lua): max_fluid_usage has no
--- runtime accessor at all, and target_temperature - though documented as a valid runtime read on
--- a FusionReactor - raises "Entity is not reactor" in practice, so it must never be read via
--- entity.prototype here. neighbour_bonus IS a live runtime field, read directly.
--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_fusion_reactor(set, entity, invert)
  local entry = get_entity_data()["fusion-reactor"]
  entry = entry and entry[entity.name]
  if not entry or not entry.max_fluid_usage or not entry.input_fluid then
    M.add_error(set, "unpredictable-input")
    return
  end
  -- max_fluid_usage is stored per-tick as declared (vanilla uses `4/second`, i.e. 4/60); B3.12-
  -- style neighbour bonus, same as the heat reactor.
  -- UNVERIFIED: whether the fluid conversion itself actually scales with (1 + neighbour_bonus) for
  -- this prototype type (unlike the plain heat "reactor", which is confirmed) has not been
  -- measured in game - a verifier should check this against a real fusion-reactor with neighbours.
  -- Reading entity.neighbour_bonus on a fusion-reactor raises "Entity is not reactor." (observed),
  -- so the bonus is only applied where the engine exposes it.
  local has_bonus, neighbour_bonus = pcall(function() return entity.neighbour_bonus end)
  local flow = entry.max_fluid_usage * 60 * (1 + (has_bonus and neighbour_bonus or 0))
  M.add_rate(set, "input", "fluid", entry.input_fluid, "normal", flow, invert, entity.name)
  if entry.output_fluid then
    -- entry.target_temperature comes from the data-stage snapshot (see final-fixes.lua); nil means
    -- the engine uses the output fluid's own default_temperature (vanilla fusion-reactor leaves it
    -- unset) - add_rate's temperature parameter is informational only either way (B3.8).
    local output_temperature = entry.target_temperature or prototypes.fluid[entry.output_fluid].default_temperature
    M.add_rate(set, "output", "fluid", entry.output_fluid, "normal", flow, invert, entity.name, output_temperature)
  end
end

--- Space Age (B4 follow-up). The generic electric_energy_source_prototype path is skipped for this
--- type in process_entity: it would report the nameplate output_flow_limit instead of what the
--- current input fluid actually supports - the same defect B3.7 fixes for regular generators.
--- Fluid identity/flow come from the mod-data snapshot (max_fluid_usage has no runtime accessor);
--- burns_fluid/effectivity/get_max_energy_production ARE live runtime fields/methods, read directly.
--- Formula from FusionGeneratorPrototype docs (burns_fluid doc text, verbatim):
---   burns_fluid:      energy = fluid_amount * fluid.fuel_value * effectivity
---   not burns_fluid:  energy = fluid_amount * fluid_temperature * fluid_heat_capacity * effectivity
--- (the FULL temperature, not a delta against default_temperature - matches vanilla's own design
--- figure: 2 plasma/s * 1,000,000 * 25J(heat_capacity) * 1(effectivity) = 50MW = output_flow_limit).
--- Capped at get_max_energy_production(quality) - like get_max_power_output/get_max_energy_usage
--- elsewhere in this file, that is J PER TICK, so the cap needs *60 before comparing against
--- `power`, which is already W (J/s); the same per-tick/per-second mixup B3.7's generator fix
--- covers for get_max_power_output.
--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_fusion_generator(set, entity, invert)
  local entry = get_entity_data()["fusion-generator"]
  entry = entry and entry[entity.name]
  if not entry or not entry.max_fluid_usage or not entry.input_fluid then
    M.add_error(set, "unpredictable-input")
    return
  end
  local entity_prototype = entity.prototype
  local flow = entry.max_fluid_usage * 60
  M.add_rate(set, "input", "fluid", entry.input_fluid, "normal", flow, invert, entity.name)
  if entry.output_fluid then
    M.add_rate(set, "output", "fluid", entry.output_fluid, "normal", flow, invert, entity.name)
  end

  local fluid_prototype = prototypes.fluid[entry.input_fluid]
  local effectivity = entity_prototype.effectivity or 1
  local power
  if entity_prototype.burns_fluid then
    power = flow * fluid_prototype.fuel_value * effectivity
  else
    local fluid = compat.fluid(entity, 1)
    -- An empty box falls back to the input fluid's own default_temperature - the design value a
    -- feeding fusion-reactor would supply, since vanilla's fusion-reactor leaves target_temperature
    -- unset (so its output defaults to the fluid's default_temperature too). This way an
    -- unconnected fusion-generator shows its real design output (50MW, see above) instead of 0.
    local temperature = (fluid and fluid.temperature) or fluid_prototype.default_temperature
    power = flow * temperature * fluid_prototype.heat_capacity * effectivity
  end
  local max_energy_production = entity_prototype.get_max_energy_production and entity_prototype.get_max_energy_production(entity.quality)
  if max_energy_production and max_energy_production > 0 then
    power = math.min(power, max_energy_production * 60)
  end
  if power > 0 then
    M.add_rate(set, "output", "item", M.POWER_ITEM, "normal", power, invert, entity.name)
  end
end

--- Space Age (B4 follow-up). Fuel + oxidizer fluid consumption at max performance; no outputs.
--- max_performance IS a live runtime field (confirmed on LuaEntityPrototype), used directly; only
--- which fluid box is fuel vs which is oxidizer needs the mod-data snapshot, because both boxes
--- are production_type "input" and so indistinguishable through the generic runtime
--- fluidbox_prototypes array.
--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function M.process_thruster(set, entity, invert)
  local entry = get_entity_data()["thruster"]
  entry = entry and entry[entity.name]
  local max_performance = entity.prototype.max_performance
  if not entry or not max_performance or not max_performance.fluid_usage then
    M.add_error(set, "unpredictable-input")
    return
  end
  local usage = max_performance.fluid_usage * 60
  if entry.fuel_fluid then
    M.add_rate(set, "input", "fluid", entry.fuel_fluid, "normal", usage, invert, entity.name)
  end
  if entry.oxidizer_fluid then
    M.add_rate(set, "input", "fluid", entry.oxidizer_fluid, "normal", usage, invert, entity.name)
  end
end

--- @param source Rate
--- @return Rate
local function copy_rate(source)
  local machine_counts = {}
  for machine_name, count in pairs(source.machine_counts) do
    machine_counts[machine_name] = count
  end
  return {
    machine_counts = machine_counts,
    machines = source.machines,
    rate = source.rate,
  }
end

--- @param source Rates
--- @return Rates
local function copy_rates(source)
  return {
    type = source.type,
    name = source.name,
    quality = source.quality,
    temperature = source.temperature,
    output = copy_rate(source.output),
    input = copy_rate(source.input),
  }
end

-- Moved here from calc.lua so limiter.lua can reuse it without requiring calc.lua at all (calc.lua
-- requires calc-cache.lua, which requires limiter.lua - a limiter -> calc require would close that
-- cycle back onto calc.lua before it has finished loading). calc-util.lua has no dependents of its
-- own, so this is a safe common home for both calc.lua and limiter.lua to require.
--- @param target table<string, Rates>
--- @param source table<string, Rates>
function M.merge_rates(target, source)
  for path, source_rates in pairs(source) do
    local target_rates = target[path]
    if not target_rates then
      target[path] = copy_rates(source_rates)
      goto continue
    end

    target_rates.output.rate = target_rates.output.rate + source_rates.output.rate
    target_rates.output.machines = target_rates.output.machines + source_rates.output.machines
    for machine_name, count in pairs(source_rates.output.machine_counts) do
      target_rates.output.machine_counts[machine_name] = (target_rates.output.machine_counts[machine_name] or 0) + count
    end

    target_rates.input.rate = target_rates.input.rate + source_rates.input.rate
    target_rates.input.machines = target_rates.input.machines + source_rates.input.machines
    for machine_name, count in pairs(source_rates.input.machine_counts) do
      target_rates.input.machine_counts[machine_name] = (target_rates.input.machine_counts[machine_name] or 0) + count
    end

    ::continue::
  end
end

return M
