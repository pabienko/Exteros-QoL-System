local M = {}

---@type table<string, Color>
M.colors = {
  red = { r = 1, g = 0, b = 0 },
  white = { r = 1, g = 1, b = 1 },
  yellow = { r = 1, g = 1, b = 0 },
  green = { r = 0, g = 1, b = 0 },
  blue = { r = 0, g = 0, b = 1 },
}

---@type table<string, defines.inventory[]>
M.entity_transfer_inventories = {
  ["agricultural-tower"] = {
    defines.inventory.fuel,
    defines.inventory.agricultural_tower_input,
  },
  ["ammo-turret"] = { defines.inventory.turret_ammo },
  ["artillery-turret"] = { defines.inventory.artillery_turret_ammo },
  ["artillery-wagon"] = { defines.inventory.artillery_wagon_ammo },
  ["assembling-machine"] = {
    defines.inventory.fuel,
    defines.inventory.crafter_input,
    defines.inventory.crafter_modules,
  },
  ["asteroid-collector"] = { defines.inventory.asteroid_collector_output },
  ["beacon"] = { defines.inventory.fuel, defines.inventory.beacon_modules },
  ["boiler"] = { defines.inventory.fuel },
  ["burner-generator"] = { defines.inventory.fuel },
  ["car"] = { defines.inventory.fuel, defines.inventory.car_ammo, defines.inventory.car_trunk },
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
    defines.inventory.fuel,
    defines.inventory.crafter_input,
    defines.inventory.crafter_modules,
  },
  ["fusion-reactor"] = { defines.inventory.fuel },
  ["inserter"] = { defines.inventory.fuel },
  ["lab"] = {
    defines.inventory.fuel,
    defines.inventory.lab_input,
    defines.inventory.lab_modules,
  },
  ["infinity-container"] = { defines.inventory.chest },
  ["linked-container"] = { defines.inventory.linked_container_main },
  ["locomotive"] = { defines.inventory.fuel },
  ["logistic-container"] = { defines.inventory.chest },
  ["mining-drill"] = { defines.inventory.fuel, defines.inventory.mining_drill_modules },
  ["reactor"] = { defines.inventory.fuel },
  ["roboport"] = {
    defines.inventory.fuel,
    defines.inventory.roboport_material,
    defines.inventory.roboport_robot,
  },
  ["rocket-silo"] = {
    defines.inventory.fuel,
    defines.inventory.crafter_input,
    defines.inventory.crafter_modules,
    defines.inventory.rocket_silo_rocket,
  },
  ["space-platform-hub"] = { defines.inventory.hub_main },
  ["spider-vehicle"] = { defines.inventory.fuel, defines.inventory.spider_ammo, defines.inventory.spider_trunk },
  ["temporary-container"] = { defines.inventory.chest },
}

---@type table<defines.controllers, defines.inventory[]>
M.player_transfer_inventories = {
  [defines.controllers.character] = { defines.inventory.character_main },
  [defines.controllers.cutscene] = {},
  [defines.controllers.editor] = { defines.inventory.editor_main },
  [defines.controllers.ghost] = {},
  [defines.controllers.god] = { defines.inventory.god_main },
  [defines.controllers.remote] = {},
  [defines.controllers.spectator] = {},
}

---@type table<string, boolean>
M.complex_items = {
  ["item-with-entity-data"] = true,
  ["armor"] = true,
  ["spidertron-remote"] = true,
  ["blueprint"] = true,
  ["blueprint-book"] = true,
  ["upgrade-item"] = true,
  ["deconstruction-item"] = true,
  ["item-with-inventory"] = true,
  ["item-with-label"] = true,
}

return M