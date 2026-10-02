-- Adapted from Rate Calculator by raiguard (MIT, © 2020-2023 Caleb Heuer) and RateCalculatorPlus by Kesha.

local core = require("core.init")

--- @alias DivisorSource
--- | "inserter_divisor"
--- | "materials_divisor",
--- | "transport_belt_divisor"

--- @class TimescaleData
--- @field divisor_required boolean?
--- @field divisor_source DivisorSource
--- @field multiplier double?
--- @field prefer_si boolean?
--- @field type_filter string?
--- @field suffix LocalisedString?

--- @class GuiUtil
local gui_util = {}

--- C2/C3: storage.elem_filters -> storage.rate_calculator.elem_filters. flib.dictionary is gone
--- (C5 replaces it with per-rate translation requests in gui.lua/gui-rates.lua); there is no
--- dictionary-building step here any more.
function gui_util.build_divisor_filters()
  --- @type EntityPrototypeFilter[]
  local materials = {}
  for _, entity in
    pairs(prototypes.get_entity_filtered({
      { filter = "type", type = "container" },
      { filter = "type", type = "logistic-container" },
    }))
  do
    local stacks = entity.get_inventory_size(defines.inventory.chest)
    if stacks and stacks > 0 and entity.group.name ~= "other" and entity.group.name ~= "environment" then
      materials[#materials + 1] = { filter = "name", name = entity.name }
    end
  end
  for _, entity in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "cargo-wagon" } })) do
    local stacks = entity.get_inventory_size(defines.inventory.cargo_wagon)
    if stacks > 0 and entity.group.name ~= "other" and entity.group.name ~= "environment" then
      materials[#materials + 1] = { filter = "name", name = entity.name }
    end
  end
  for _, entity in
    pairs(prototypes.get_entity_filtered({
      { filter = "type", type = "storage-tank" },
      { filter = "type", type = "fluid-wagon" },
    }))
  do
    local capacity = entity.fluid_capacity
    if capacity > 0 and entity.group.name ~= "other" and entity.group.name ~= "environment" then
      materials[#materials + 1] = { filter = "name", name = entity.name }
    end
  end

  --- @type table<DivisorSource, EntityPrototypeFilter[]>
  storage.rate_calculator.elem_filters = {
    inserter_divisor = { { filter = "type", type = "inserter" } },
    materials_divisor = materials,
    transport_belt_divisor = { { filter = "type", type = "transport-belt" } },
  }
end

--- @param inserter LuaEntityPrototype
--- @param quality QualityID
--- @return double
function gui_util.calc_inserter_cycles_per_second(inserter, quality)
  local pickup_vector = inserter.inserter_pickup_position --[[@as Vector]]
  local drop_vector = inserter.inserter_drop_position --[[@as Vector]]
  local pickup_x, pickup_y, drop_x, drop_y = pickup_vector[1], pickup_vector[2], drop_vector[1], drop_vector[2]
  local pickup_length = math.sqrt(pickup_x * pickup_x + pickup_y * pickup_y)
  local drop_length = math.sqrt(drop_x * drop_x + drop_y * drop_y)
  -- Get angle from the dot product
  -- XXX: Imprecision can make this return slightly outside the allowed bounds for acos, so clamp it
  local norm_dot = core.math.clamp((pickup_x * drop_x + pickup_y * drop_y) / (pickup_length * drop_length), -1, 1)
  local angle = math.acos(norm_dot)
  -- Rotation speed is in full circles per tick
  local rotation_speed = inserter.get_inserter_rotation_speed(quality)
  local ticks_per_cycle = 2 * math.ceil(angle / (math.pi * 2) / rotation_speed)
  local extension_speed = inserter.get_inserter_extension_speed(quality)
  local extension_time = 2 * math.ceil(math.abs(pickup_length - drop_length) / extension_speed)
  if ticks_per_cycle < extension_time then
    ticks_per_cycle = extension_time
  end
  return 60 / ticks_per_cycle -- 60 = ticks per second
end

--- @param self GuiData
--- @return double|uint?, string?, boolean?, uint?
function gui_util.get_divisor(self)
  local timescale_data = gui_util.timescale_data[self.selected_timescale]
  local type_filter

  --- @type double|uint?
  local divisor
  --- @type string?
  local divisor_source = timescale_data.divisor_source
  if not divisor_source then
    return
  end

  -- C2: RCP had a `divisor_required and not divisor_id` fallback here that picked a default
  -- divisor entity - but it ran AFTER an identical `if not divisor_id then return end`, so it was
  -- unreachable, and in practice self[divisor_source] is never nil anyway (build_gui seeds
  -- inserter_divisor/transport_belt_divisor with gui_util.get_first_prototype). Dropped rather
  -- than "fixed" - per the stage-C plan.
  --- @type {name: string, quality: string}?
  local divisor_id = self[divisor_source]
  if not divisor_id then
    return
  end

  local inserter_stack_size = 0
  local divide_stacks = false
  --- @type LuaEntityPrototype
  local prototype = prototypes.entity[divisor_id.name]
  if prototype.type == "container" or prototype.type == "logistic-container" then
    -- C4.3: the divisor must respect the chosen quality, not just the base prototype capacity.
    divisor = prototype.get_inventory_size(defines.inventory.chest, divisor_id.quality)
    type_filter = "item"
    divide_stacks = true
  elseif prototype.type == "cargo-wagon" then
    divisor = prototype.get_inventory_size(defines.inventory.cargo_wagon, divisor_id.quality)
    type_filter = "item"
    divide_stacks = true
  elseif prototype.type == "storage-tank" or prototype.type == "fluid-wagon" then
    divisor = prototype.get_fluid_capacity(divisor_id.quality)
    type_filter = "fluid"
  elseif prototype.type == "transport-belt" then
    divisor = prototype.belt_speed * 480
    type_filter = "item"
  elseif prototype.type == "inserter" then
    local cycles_per_second = gui_util.calc_inserter_cycles_per_second(prototype, divisor_id.quality)
    if prototype.bulk then
      inserter_stack_size = 1 + prototype.inserter_stack_size_bonus + self.player.force.bulk_inserter_capacity_bonus
    else
      inserter_stack_size = 1 + prototype.inserter_stack_size_bonus + self.player.force.inserter_stack_size_bonus
    end
    -- C4.2: the divisor is just the cycle rate; the per-item min(stack) division happens once,
    -- in gui-rates, instead of being baked in here AND applied again there.
    divisor = cycles_per_second
    type_filter = "item"
  end

  return divisor, type_filter, divide_stacks, inserter_stack_size
end

--- @param filters EntityPrototypeFilter[]
--- @return EntityWithQualityID?
function gui_util.get_first_prototype(filters)
  -- XXX: next() doesn't work on LuaCustomTable
  for name in pairs(prototypes.get_entity_filtered(filters)) do
    return { name = name, quality = "normal" }
  end
end

--- @type table<Timescale, TimescaleData>
gui_util.timescale_data = {
  ["per-second"] = { divisor_source = "materials_divisor", multiplier = 1 },
  ["per-minute"] = { divisor_source = "materials_divisor", multiplier = 60 },
  ["per-10-minutes"] = { divisor_source = "materials_divisor", multiplier = 60 * 10 },
  ["per-hour"] = { divisor_source = "materials_divisor", multiplier = 60 * 60 },
  ["transport-belts"] = { divisor_required = true, divisor_source = "transport_belt_divisor", type_filter = "item" },
  ["inserters"] = { divisor_required = true, divisor_source = "inserter_divisor", type_filter = "item" },
}

--- @type Timescale[]
gui_util.ordered_timescales = {
  "per-second",
  "per-minute",
  "per-10-minutes",
  "per-hour",
  "transport-belts",
  "inserters",
}

return gui_util
