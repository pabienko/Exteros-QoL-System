--[[
  ENTITIES.LUA - Entity Definitions for Squeak Through
  
  This file contains all entity types that can have their collision boxes modified.
  Separated into a separate file to make it easier to add entities from other mods.
]]

local entities = {
  -- Vanilla entities
  vanilla = {
    "container",
    "infinity-container",
    "linked-container",
    "logistic-container",
    "arithmetic-combinator",
    "constant-combinator",
    "decider-combinator",
    "lamp",
    "power-switch",
    "programmable-speaker",
    "mining-drill",
    "assembling-machine",
    "furnace",
    "lab",
    "rocket-silo",
    "heat-interface",
    "heat-pipe",
    "infinity-pipe",
    "offshore-pump",
    "pipe",
    "pipe-to-ground",
    "pump",
    "storage-tank",
    "accumulator",
    "electric-energy-interface",
    "solar-panel",
    "boiler",
    "burner-generator",
    "generator",
    "reactor",
    "artillery-turret",
    "ammo-turret",
    "electric-turret",
    "fluid-turret",
    "beacon",
    "electric-pole",
    "inserter",
    "radar",
    "roboport",
    "train-stop"
  },
  
  -- Trees and stones
  trees_stones = {
    "tree",
    "simple-entity"
  },
  
  -- Space Age DLC entities (only if Space Age mod is active)
  space_age = {
    "fusion-reactor",
    "fusion-generator",
    "agricultural-tower",
    "lightning-attractor",
    "cargo-landing-pad",
    "cargo-bay",
    "asteroid-collector",
    "thruster",
    "space-platform-hub"
  }
}

return entities

