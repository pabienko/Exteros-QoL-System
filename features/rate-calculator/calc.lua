
local calc_util = require("features.rate-calculator.calc-util")
local calc_cache = require("features.rate-calculator.calc-cache")

--- @class Set<T>: { [T]: boolean }

--- @alias CalculationError
--- | "incompatible-science-packs"
--- | "invalid-rate"
--- | "limit-not-converged"
--- | "no-active-research"
--- | "no-input-fluid"
--- | "no-fuel"
--- | "no-mineable-resources"
--- | "no-plants"
--- | "no-power"
--- | "no-recipe"
--- | "unpredictable-input"

--- @class CalculationSet
--- @field completed Set<string>
--- @field entities table<string, LuaEntity>
--- @field entity_rates table<string, table<string, Rates>>
--- @field errors Set<CalculationError>
--- @field fully_limited_rates table<string, Rates>?
--- @field limited_rates table<string, Rates>?
--- @field player LuaPlayer
--- @field rates table<string, Rates>
--- @field selection_area_tiles uint?
--- @field selection_area_width uint?
--- @field selection_area_height uint?
--- @field research_data ResearchData?
--- @field pollutant string
--- @field primary_surface_index uint?
--- @field selection_area_box BoundingBox?

--- @alias MachineCounts table<string, double>

--- @class Rate
--- @field machine_counts MachineCounts
--- @field machines double
--- @field rate double

--- @class Rates
--- @field type string
--- @field name string
--- @field quality string?
--- @field temperature double?
--- @field output Rate
--- @field input Rate

--- @class ResearchData
--- @field ingredients Ingredient[]
--- @field multiplier double
--- @field speed_modifier double

--- @class Calc
local M = {}

local entity_blacklist = {
  ["buffer-depot"] = true,
  ["fluid-depot"] = true,
  ["fuel-depot"] = true,
  ["request-depot"] = true,
}

local rolling_stock_types = {
  ["locomotive"] = true,
  ["cargo-wagon"] = true,
  ["fluid-wagon"] = true,
  ["artillery-wagon"] = true,
}

--- @type table<string, fun(set: CalculationSet, entity: LuaEntity, invert: boolean)>?
local space_age_handlers = nil
if script.active_mods["space-age"] then
  space_age_handlers = {
    ["agricultural-tower"] = calc_util.process_agricultural_tower,
    ["asteroid-collector"] = calc_util.process_asteroid_collector,
    ["fusion-reactor"] = calc_util.process_fusion_reactor,
    ["fusion-generator"] = calc_util.process_fusion_generator,
    ["thruster"] = calc_util.process_thruster,
  }
end

local supports_override_pollution_type = nil

--- @param entity LuaEntity
--- @return string
local function surface_pollutant(entity)
  if supports_override_pollution_type == nil then
    supports_override_pollution_type = pcall(function()
      return entity.prototype.override_pollution_type
    end)
  end
  if supports_override_pollution_type then
    local success, override = pcall(function()
      return entity.prototype.override_pollution_type
    end)
    if success and override then
      return override.name
    end
  end
  local pollutant_prototype = entity.surface.pollutant_type
  return pollutant_prototype and pollutant_prototype.name or ""
end

--- @param player LuaPlayer
--- @return ResearchData?
local function compute_research_data(player)
  local force = player.force
  local current_research = force.current_research
  if not current_research then
    return nil
  end
  return {
    ingredients = current_research.research_unit_ingredients,
    multiplier = 1 / (current_research.research_unit_energy / 60),
    speed_modifier = force.laboratory_speed_modifier,
  }
end

--- @param set CalculationSet
--- @param entity LuaEntity
local function process_entity(set, entity)
  if entity_blacklist[entity.name] then
    return
  end

  local emissions_per_second = entity.prototype.emissions_per_second[set.pollutant] or 0
  local entity_type = entity.type

  if entity_type == "burner-generator" then
    calc_util.add_rate(
      set,
      "output",
      "item",
      calc_util.POWER_ITEM,
      "normal",
      entity.prototype.get_max_power_output(entity.quality) * 60,
      false,
      entity.name
    )
  elseif entity_type == "accumulator" then
  elseif entity_type == "fusion-generator" then
  elseif entity_type ~= "burner-generator" and entity_type ~= "generator" and entity.prototype.electric_energy_source_prototype then
    emissions_per_second = calc_util.process_electric_energy_source(set, entity, false, emissions_per_second)
  elseif entity.prototype.fluid_energy_source_prototype then
    emissions_per_second = calc_util.process_fluid_energy_source(set, entity, false, emissions_per_second)
  elseif entity.prototype.heat_energy_source_prototype then
    calc_util.process_heat_energy_source(set, entity, false)
  end

  if entity.burner then
    emissions_per_second = calc_util.process_burner(set, entity, false, emissions_per_second)
  end

  if entity_type == "assembling-machine" or entity_type == "furnace" or entity_type == "rocket-silo" then
    emissions_per_second = calc_util.process_crafter(set, entity, false, emissions_per_second)
  elseif entity_type == "beacon" then
    calc_util.process_beacon(set, entity)
  elseif entity_type == "boiler" then
    calc_util.process_boiler(set, entity, false)
  elseif entity_type == "lab" then
    calc_util.process_lab(set, entity, false)
    emissions_per_second = emissions_per_second * (1 + entity.pollution_bonus)
  elseif entity_type == "generator" then
    calc_util.process_generator(set, entity, false)
  elseif entity_type == "mining-drill" then
    calc_util.process_mining_drill(set, entity, false)
    emissions_per_second = emissions_per_second * (1 + entity.pollution_bonus)
  elseif entity_type == "offshore-pump" then
    calc_util.process_offshore_pump(set, entity, false)
  elseif entity_type == "reactor" then
    calc_util.process_reactor(set, entity, false)
  elseif space_age_handlers and space_age_handlers[entity_type] then
    space_age_handlers[entity_type](set, entity, false)
  end

  if emissions_per_second > 0 then
    calc_util.add_rate(set, "output", "item", calc_util.POLLUTION_ITEM, "normal", emissions_per_second, false, entity.name)
  elseif emissions_per_second < 0 then
    calc_util.add_rate(set, "input", "item", calc_util.POLLUTION_ITEM, "normal", -emissions_per_second, false, entity.name)
  end
end

--- @param entity LuaEntity
--- @return string
local function get_entity_key(entity)
  local unit_number = entity.unit_number
  if unit_number then
    return "u/" .. unit_number
  end
  local position = entity.position
  return string.format("p/%d/%d/%s/%.3f/%.3f", entity.surface.index, entity.force.index, entity.name, position.x, position.y)
end

--- @param set CalculationSet
--- @param entities LuaEntity[]
--- @param invert boolean
local function update_selected_entities(set, entities, invert)
  local selected_entities = set.entities
  for _, entity in pairs(entities) do
    local key = get_entity_key(entity)
    if invert then
      selected_entities[key] = nil
    else
      selected_entities[key] = entity
    end
  end
end

--- @param set CalculationSet
local function update_selection_area(set)
  local min_x, min_y
  local max_x, max_y
  for entity_key, entity in pairs(set.entities) do
    if not entity.valid then
      set.entities[entity_key] = nil
      goto continue
    end
    if set.primary_surface_index and entity.surface.index ~= set.primary_surface_index then
      goto continue
    end
    if rolling_stock_types[entity.type] then
      goto continue
    end

    local selection_box = entity.selection_box or entity.bounding_box
    local left_top = selection_box.left_top
    local right_bottom = selection_box.right_bottom
    min_x = min_x and math.min(min_x, left_top.x) or left_top.x
    min_y = min_y and math.min(min_y, left_top.y) or left_top.y
    max_x = max_x and math.max(max_x, right_bottom.x) or right_bottom.x
    max_y = max_y and math.max(max_y, right_bottom.y) or right_bottom.y

    ::continue::
  end

  if not min_x or not min_y or not max_x or not max_y then
    set.selection_area_width = 0
    set.selection_area_height = 0
    set.selection_area_tiles = 0
    return
  end

  local width = math.max(math.ceil(max_x) - math.floor(min_x), 0)
  local height = math.max(math.ceil(max_y) - math.floor(min_y), 0)
  set.selection_area_width = width
  set.selection_area_height = height
  set.selection_area_tiles = width * height
end

--- @param set CalculationSet
local function recalculate_set(set)
  set.entity_rates = {}
  set.errors = {}
  set.rates = {}
  calc_cache.invalidate(set)

  update_selection_area(set)

  set.research_data = compute_research_data(set.player)

  for entity_key, entity in pairs(set.entities) do
    if not entity.valid then
      goto continue
    end

    --- @type CalculationSet
    local entity_set = {
      completed = {},
      entities = {},
      entity_rates = {},
      errors = set.errors,
      fully_limited_rates = nil,
      limited_rates = nil,
      player = set.player,
      rates = {},
      research_data = set.research_data,
      pollutant = surface_pollutant(entity),
    }
    process_entity(entity_set, entity)
    set.entity_rates[entity_key] = entity_set.rates
    calc_util.merge_rates(set.rates, entity_set.rates)

    ::continue::
  end
end

--- @param set CalculationSet
--- @param entities LuaEntity[]
--- @param invert boolean
local function update_set(set, entities, invert)
  if not set.primary_surface_index then
    local first = entities[1]
    if first then
      set.primary_surface_index = first.surface.index
    end
  end
  update_selected_entities(set, entities, invert)
  recalculate_set(set)
end

--- @param player LuaPlayer
--- @return CalculationSet
function M.new_set(player)
  return {
    completed = {},
    entities = {},
    entity_rates = {},
    errors = {},
    fully_limited_rates = nil,
    limited_rates = nil,
    player = player,
    rates = {},
    selection_area_tiles = 0,
    selection_area_width = 0,
    selection_area_height = 0,
    research_data = nil,
    pollutant = "",
    primary_surface_index = nil,
    selection_area_box = nil,
  }
end

--- @param player LuaPlayer
--- @param entities LuaEntity[]
--- @param area BoundingBox?
--- @return CalculationSet
function M.select(player, entities, area)
  local set = M.new_set(player)
  set.selection_area_box = area
  update_set(set, entities, false)
  return set
end

--- @param set CalculationSet
--- @param entities LuaEntity[]
--- @return CalculationSet
function M.add_entities(set, entities)
  update_set(set, entities, false)
  return set
end

--- @param set CalculationSet
--- @param entities LuaEntity[]
--- @return CalculationSet
function M.remove_entities(set, entities)
  update_set(set, entities, true)
  return set
end

M.merge_rates = calc_util.merge_rates

return M
