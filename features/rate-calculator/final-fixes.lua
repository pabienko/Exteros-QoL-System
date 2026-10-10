---@param vector table?
---@return { x: number, y: number }?
local function normalize_vector(vector)
  if not vector then
    return nil
  end
  return { x = vector.x or vector[1], y = vector.y or vector[2] }
end

local entity_data = {}

local fusion_reactor_data = {}
for name, prototype in pairs(data.raw["fusion-reactor"] or {}) do
  fusion_reactor_data[name] = {
    max_fluid_usage = prototype.max_fluid_usage,
    input_fluid = prototype.input_fluid_box and prototype.input_fluid_box.filter,
    output_fluid = prototype.output_fluid_box and prototype.output_fluid_box.filter,
    target_temperature = prototype.target_temperature,
  }
end
if next(fusion_reactor_data) then
  entity_data["fusion-reactor"] = fusion_reactor_data
end

local fusion_generator_data = {}
for name, prototype in pairs(data.raw["fusion-generator"] or {}) do
  fusion_generator_data[name] = {
    max_fluid_usage = prototype.max_fluid_usage,
    input_fluid = prototype.input_fluid_box and prototype.input_fluid_box.filter,
    output_fluid = prototype.output_fluid_box and prototype.output_fluid_box.filter,
  }
end
if next(fusion_generator_data) then
  entity_data["fusion-generator"] = fusion_generator_data
end

local thruster_data = {}
for name, prototype in pairs(data.raw["thruster"] or {}) do
  thruster_data[name] = {
    fuel_fluid = prototype.fuel_fluid_box and prototype.fuel_fluid_box.filter,
    oxidizer_fluid = prototype.oxidizer_fluid_box and prototype.oxidizer_fluid_box.filter,
  }
end
if next(thruster_data) then
  entity_data["thruster"] = thruster_data
end

local mining_drill_data = {}
for name, prototype in pairs(data.raw["mining-drill"] or {}) do
  local offset = normalize_vector(prototype.resource_searching_offset)
  if offset then
    mining_drill_data[name] = { resource_searching_offset = offset }
  end
end
if next(mining_drill_data) then
  entity_data["mining-drill"] = mining_drill_data
end

data:extend({
  {
    type = "mod-data",
    name = "exteros-qol-rcalc-entity-data",
    data_type = "exteros-qol-rcalc-entity-data",
    data = entity_data,
  },
})
