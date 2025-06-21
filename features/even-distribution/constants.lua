-- features/even-distribution/constants.lua

--- @type table<string, Color>
local colors = {
  red = { r = 1 },
  white = { r = 1, g = 1, b = 1 },
  yellow = { r = 1, g = 1 },
}

--- @type table<string, defines.inventory[]>
local entity_transfer_inventories = {
  ["ammo-turret"] = { defines.inventory.turret_ammo },
  ["artillery-turret"] = { defines.inventory.artillery_turret_ammo },
  ["artillery-wagon"] = { defines.inventory.artillery_wagon_ammo },
  ["assembling-machine"] = {
    defines.inventory.assembling_machine_input,
    defines.inventory.assembling_machine_modules,
    defines.inventory.fuel,
  },
  ["beacon"] = { defines.inventory.beacon_modules, defines.inventory.fuel },
  ["boiler"] = { defines.inventory.fuel },
  ["burner-generator"] = { defines.inventory.fuel },
  ["car"] = { defines.inventory.car_ammo, defines.inventory.car_trunk, defines.inventory.fuel },
  ["cargo-landing-pad"] = { defines.inventory.cargo_landing_pad_main },
  ["cargo-wagon"] = { defines.inventory.cargo_wagon },
  ["character"] = {
    defines.inventory.character_ammo,
    defines.inventory.character_armor,
    defines.inventory.character_guns,
    defines.inventory.character_main,
    defines.inventory.character_vehicle,
  },
  ["container"] = { defines.inventory.chest },
  ["furnace"] = { defines.inventory.furnace_source, defines.inventory.furnace_modules, defines.inventory.fuel },
  ["fusion-reactor"] = { defines.inventory.fuel },
  ["lab"] = { defines.inventory.lab_input, defines.inventory.lab_modules, defines.inventory.fuel },
  ["locomotive"] = { defines.inventory.fuel },
  ["logistic-container"] = { defines.inventory.chest },
  ["mining-drill"] = { defines.inventory.mining_drill_modules, defines.inventory.fuel },
  ["roboport"] = { defines.inventory.roboport_material, defines.inventory.roboport_robot, defines.inventory.fuel },
  ["rocket-silo"] = {
    defines.inventory.rocket_silo_input,
    defines.inventory.rocket_silo_rocket,
    defines.inventory.rocket_silo_modules,
    defines.inventory.fuel,
  },
  ["space-platform-hub"] = { defines.inventory.hub_main },
  ["spidertron"] = { defines.inventory.spider_ammo, defines.inventory.spider_trunk, defines.inventory.fuel },
}

--- @type table<defines.controllers, defines.inventory[]>
local player_transfer_inventories = {
  [defines.controllers.character] = {
    -- defines.inventory.character_ammo,
    defines.inventory.character_armor,
    defines.inventory.character_guns,
    defines.inventory.character_main,
    defines.inventory.character_vehicle,
  },
  [defines.controllers.cutscene] = {},
  [defines.controllers.editor] = {
    -- defines.inventory.editor_ammo,
    defines.inventory.editor_armor,
    defines.inventory.editor_guns,
    defines.inventory.editor_main,
  },
  [defines.controllers.ghost] = {},
  [defines.controllers.god] = { defines.inventory.god_main },
  [defines.controllers.remote] = {},
  [defines.controllers.spectator] = {},
}

local complex_items = {
  ["item-with-entity-data"] = true,
  ["armor"] = true,
  ["spidertron-remote"] = true,
  ["blueprint"] = true,
  ["blueprint-book"] = true,
  ["upgrade-planner"] = true,
  ["deconstruction-planner"] = true,
}

return {
  colors = colors,
  entity_transfer_inventories = entity_transfer_inventories,
  player_transfer_inventories = player_transfer_inventories,
  complex_items = complex_items,
}