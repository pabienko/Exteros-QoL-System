local M = {}

M.colors = {
  red = { r = 1, g = 0, b = 0 },
  white = { r = 1, g = 1, b = 1 },
  yellow = { r = 1, g = 1, b = 0 },
  green = { r = 0, g = 1, b = 0 },
  blue = { r = 0, g = 0, b = 1 },
}

M.entity_transfer_inventories = {
  ["agricultural-tower"] = {
    defines.inventory.crafter_input,
    defines.inventory.crafter_modules,
    defines.inventory.fuel,
  },
  ["ammo-turret"] = { defines.inventory.turret_ammo },
  ["artillery-turret"] = { defines.inventory.artillery_turret_ammo },
  ["artillery-wagon"] = { defines.inventory.artillery_wagon_ammo },
  ["assembling-machine"] = {
    defines.inventory.crafter_input,
    defines.inventory.crafter_modules,
    defines.inventory.fuel,
  },
  ["asteroid-collector"] = { defines.inventory.asteroid_collector_output },
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
  ["furnace"] = { 
    defines.inventory.crafter_input, 
    defines.inventory.crafter_modules, 
    defines.inventory.fuel 
  },
  ["fusion-reactor"] = { defines.inventory.fuel },
  ["inserter"] = { defines.inventory.fuel },
  ["lab"] = { 
    defines.inventory.lab_input, 
    defines.inventory.lab_modules, 
    defines.inventory.fuel 
  },
  ["locomotive"] = { defines.inventory.fuel },
  ["logistic-container"] = { defines.inventory.chest },
  ["mining-drill"] = { defines.inventory.mining_drill_modules, defines.inventory.fuel },
  ["roboport"] = { 
    defines.inventory.roboport_material, 
    defines.inventory.roboport_robot, 
    defines.inventory.fuel 
  },
  ["rocket-silo"] = {
    defines.inventory.crafter_input,
    defines.inventory.crafter_modules,
    defines.inventory.fuel,
    defines.inventory.rocket_silo_rocket,
  },
  ["space-platform-hub"] = { defines.inventory.hub_main },
  ["spidertron"] = { defines.inventory.spider_ammo, defines.inventory.spider_trunk, defines.inventory.fuel },
}

M.player_transfer_inventories = {
  [defines.controllers.character] = {
    defines.inventory.character_armor,
    defines.inventory.character_guns,
    defines.inventory.character_main,
    defines.inventory.character_vehicle,
  },
  [defines.controllers.cutscene] = {},
  [defines.controllers.editor] = {
    defines.inventory.editor_armor,
    defines.inventory.editor_guns,
    defines.inventory.editor_main,
  },
  [defines.controllers.ghost] = {},
  [defines.controllers.god] = { defines.inventory.god_main },
  [defines.controllers.remote] = {},
  [defines.controllers.spectator] = {},
}

M.complex_items = {
  ["item-with-entity-data"] = true,
  ["armor"] = true,
  ["spidertron-remote"] = true,
  ["blueprint"] = true,
  ["blueprint-book"] = true,
  ["upgrade-planner"] = true,
  ["deconstruction-planner"] = true,
}

return M