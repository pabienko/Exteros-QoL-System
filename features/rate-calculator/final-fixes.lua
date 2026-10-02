-- Adapted from Rate Calculator by raiguard (MIT, © 2020-2023 Caleb Heuer) and RateCalculatorPlus by Kesha.
--
-- calc-util needs a few fields that exist only at the PROTOTYPE stage with no (working) runtime
-- accessor on LuaEntityPrototype in the API definitions available for this port:
--   - max_fluid_usage (fusion-reactor, fusion-generator) - no generic runtime getter at all.
--   - which fluid box is fuel vs oxidizer on a thruster - both are production_type "input", so the
--     generic runtime fluidbox_prototypes array can't tell them apart; only the prototype-stage
--     named fields (fuel_fluid_box / oxidizer_fluid_box) can.
--   - resource_searching_offset (mining-drill, B3.13) - prototype-stage-only field, needed for
--     modded mining drills too, independent of Space Age.
--   - target_temperature on a fusion-reactor - documented as a valid runtime read ("Can only be
--     used if this is Boiler or FusionReactor"), but confirmed to raise "Entity is not reactor" in
--     practice on a real fusion-reactor; read at the data stage instead, where there is no runtime
--     type check. (On a plain Boiler it is fine and still read live in calc-util.)
-- Everything else calc-util needs for the Space Age types (neighbour_bonus, burner, effectivity,
-- burns_fluid, max_performance, get_max_energy_usage/production) already has a live, quality-aware
-- runtime accessor, so it is read directly there instead of being duplicated here.
--
-- fusion-reactor/fusion-generator/thruster simply don't exist in data.raw without Space Age, so
-- those loops are no-ops in that case; only mining-drill (not Space-Age-specific) is expected to
-- ever find anything without it. Sub-tables are only added to the snapshot when non-empty.
--
-- Snapshotted into a mod-data prototype, read back at runtime via prototypes.mod_data[...].data -
-- confirmed in prototype-api/ModData.lua (data stage) and runtime-api/LuaModData.lua +
-- LuaPrototypes.mod_data (runtime stage).

---@param vector table?
---@return { x: number, y: number }?
local function normalize_vector(vector)
  if not vector then
    return nil
  end
  return { x = vector.x or vector[1], y = vector.y or vector[2] }
end

local entity_data = {}

-- All entries, not just vanilla's "fusion-reactor"/"fusion-generator"/"thruster" names, so modded
-- machines of these types work too.
local fusion_reactor_data = {}
for name, prototype in pairs(data.raw["fusion-reactor"] or {}) do
  fusion_reactor_data[name] = {
    max_fluid_usage = prototype.max_fluid_usage,
    input_fluid = prototype.input_fluid_box and prototype.input_fluid_box.filter,
    output_fluid = prototype.output_fluid_box and prototype.output_fluid_box.filter,
    -- target_temperature is documented as readable on a FusionReactor's LuaEntityPrototype too, but
    -- that raises "Entity is not reactor" in practice (confirmed on a real fusion-reactor) - read it
    -- here at the data stage instead, where there is no runtime type check at all.
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

-- B3.13: not Space-Age-specific - any mining drill (vanilla or modded) that sets this is covered.
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
