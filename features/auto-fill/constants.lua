-- features/auto-fill/constants.lua
-- Constants and entity inventory mappings for auto-fill

local constants = {}

-- Entity types that can accept fuel
constants.fuel_entities = {
  ["assembling-machine"] = defines.inventory.fuel,
  ["beacon"] = defines.inventory.fuel,
  ["boiler"] = defines.inventory.fuel,
  ["burner-generator"] = defines.inventory.fuel,
  ["car"] = defines.inventory.fuel,
  ["furnace"] = defines.inventory.fuel,
  ["fusion-reactor"] = defines.inventory.fuel,
  ["lab"] = defines.inventory.fuel,
  ["locomotive"] = defines.inventory.fuel,
  ["mining-drill"] = defines.inventory.fuel,
  ["roboport"] = defines.inventory.fuel,
  ["rocket-silo"] = defines.inventory.fuel,
  ["spidertron"] = defines.inventory.fuel,
}

-- Entity types that can accept ammo
constants.ammo_entities = {
  ["ammo-turret"] = defines.inventory.turret_ammo,
  ["artillery-turret"] = defines.inventory.artillery_turret_ammo,
  ["artillery-wagon"] = defines.inventory.artillery_wagon_ammo,
  ["car"] = defines.inventory.car_ammo,
  ["spidertron"] = defines.inventory.spider_ammo,
}

-- Spoilable fuel items (these can rot/spoil)
constants.spoilable_fuel = {
  ["raw-fish"] = true,
  ["raw-wood"] = true,
}

-- Default maximum fill percentage
constants.default_max_percent = 12

return constants

