local M = {}

---@type table<string, defines.inventory>
local AMMO_INVENTORY_BY_TYPE = {
  ["ammo-turret"] = defines.inventory.turret_ammo,
  ["car"] = defines.inventory.car_ammo,
  ["spider-vehicle"] = defines.inventory.spider_ammo,
  ["artillery-turret"] = defines.inventory.artillery_turret_ammo,
  ["artillery-wagon"] = defines.inventory.artillery_wagon_ammo,
}

---@type table<string, defines.inventory>
local INPUT_INVENTORY_BY_TYPE = {
  ["assembling-machine"] = defines.inventory.crafter_input,
  ["furnace"] = defines.inventory.crafter_input,
  ["rocket-silo"] = defines.inventory.crafter_input,
  ["agricultural-tower"] = defines.inventory.agricultural_tower_input,
  ["lab"] = defines.inventory.lab_input,
}

---@type table<string, boolean>
local CRAFTING_MACHINE_TYPES = {
  ["assembling-machine"] = true,
  ["furnace"] = true,
  ["rocket-silo"] = true,
}

---@type table<string, defines.inventory>
local MAIN_INVENTORY_BY_TYPE = {
  ["container"] = defines.inventory.chest,
  ["logistic-container"] = defines.inventory.chest,
  ["infinity-container"] = defines.inventory.chest,
  ["temporary-container"] = defines.inventory.chest,
  ["cargo-wagon"] = defines.inventory.cargo_wagon,
  ["car"] = defines.inventory.car_trunk,
  ["spider-vehicle"] = defines.inventory.spider_trunk,
  ["linked-container"] = defines.inventory.linked_container_main,
  ["space-platform-hub"] = defines.inventory.hub_main,
  ["cargo-landing-pad"] = defines.inventory.cargo_landing_pad_main,
  ["rocket-silo"] = defines.inventory.rocket_silo_rocket,
}

---@param inventory LuaInventory?
---@param item ItemIDAndQualityIDPair|ItemWithQualityID
---@return boolean
local function accepts(inventory, item)
  if not inventory or not inventory.valid then return false end
  return inventory.can_insert(item) or inventory.get_item_count(item) > 0
end

---@param entity LuaEntity
---@param item_name string
---@return boolean
local function recipe_uses_item(entity, item_name)
  if not CRAFTING_MACHINE_TYPES[entity.type] then return false end

  local recipe = entity.get_recipe()
  if not recipe then return false end

  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.name == item_name then return true end
  end
  return false
end

---@param entity LuaEntity
---@param item ItemIDAndQualityIDPair|ItemWithQualityID
---@return { role: string, inventories: LuaInventory[] }?
function M.resolve(entity, item)
  if not entity or not entity.valid then return nil end

  local item_prototype = prototypes.item[item.name]
  if not item_prototype then return nil end

  local burner = entity.burner
  local fuel_category = item_prototype.fuel_category
  if fuel_category and burner and burner.fuel_categories[fuel_category] then
    if recipe_uses_item(entity, item.name) then
      local input_inventory_type = INPUT_INVENTORY_BY_TYPE[entity.type]
      local input_inventory = input_inventory_type and entity.get_inventory(input_inventory_type)
      if accepts(input_inventory, item) then
        return { role = "input", inventories = { input_inventory } }
      end
    end

    local inventory = entity.get_fuel_inventory()
    if inventory then
      return { role = "fuel", inventories = { inventory } }
    end
  end

  local ammo_inventory_type = AMMO_INVENTORY_BY_TYPE[entity.type]
  if ammo_inventory_type then
    local inventory = entity.get_inventory(ammo_inventory_type)
    if accepts(inventory, item) then
      return { role = "ammo", inventories = { inventory } }
    end
  end

  local input_inventory_type = INPUT_INVENTORY_BY_TYPE[entity.type]
  if input_inventory_type then
    local inventory = entity.get_inventory(input_inventory_type)
    if accepts(inventory, item) then
      return { role = "input", inventories = { inventory } }
    end
  end

  local modules_inventory = entity.get_module_inventory()
  if accepts(modules_inventory, item) then
    return { role = "modules", inventories = { modules_inventory } }
  end

  if entity.type == "roboport" then
    local robot_inventory = entity.get_inventory(defines.inventory.roboport_robot)
    if accepts(robot_inventory, item) then
      return { role = "roboport", inventories = { robot_inventory } }
    end

    local material_inventory = entity.get_inventory(defines.inventory.roboport_material)
    if accepts(material_inventory, item) then
      return { role = "roboport", inventories = { material_inventory } }
    end
  end

  local main_inventory_type = MAIN_INVENTORY_BY_TYPE[entity.type]
  if main_inventory_type then
    local inventory = entity.get_inventory(main_inventory_type)
    if accepts(inventory, item) then
      return { role = "main", inventories = { inventory } }
    end
  end

  return nil
end

---@param inventory LuaInventory
---@param item ItemIDAndQualityIDPair|ItemWithQualityID
---@param limit { value: number, unit: string }
---@return number
local function fuel_room(inventory, item, limit)
  local insertable = inventory.get_insertable_count(item)
  if limit.value <= 0 then return insertable end

  local item_prototype = prototypes.item[item.name]
  local fuel_value = item_prototype.fuel_value
  if not fuel_value or fuel_value <= 0 then return insertable end

  local limit_j
  if limit.unit == "stacks" then
    limit_j = limit.value * item_prototype.stack_size * fuel_value
  elseif limit.unit == "mj" then
    limit_j = limit.value * 1000000
  else
    limit_j = limit.value * fuel_value
  end

  local existing_j = 0
  for _, stack in pairs(inventory.get_contents()) do
    local stack_prototype = prototypes.item[stack.name]
    local stack_fuel_value = stack_prototype and stack_prototype.fuel_value or 0
    existing_j = existing_j + stack.count * stack_fuel_value
  end

  local room_j = math.max(0, limit_j - existing_j)
  local room_items = math.ceil(room_j / fuel_value)
  return math.min(room_items, insertable)
end

---@param inventory LuaInventory
---@param item ItemIDAndQualityIDPair|ItemWithQualityID
---@param limit { value: number, unit: string }
---@return number
local function ammo_room(inventory, item, limit)
  local insertable = inventory.get_insertable_count(item)
  if limit.value <= 0 then return insertable end

  local item_prototype = prototypes.item[item.name]
  if item_prototype.type ~= "ammo" then return insertable end
  local item_category = item_prototype.ammo_category

  local limit_items
  if limit.unit == "stacks" then
    limit_items = math.ceil(limit.value * item_prototype.stack_size)
  else
    limit_items = math.ceil(limit.value)
  end

  local existing = 0
  for _, stack in pairs(inventory.get_contents()) do
    local stack_prototype = prototypes.item[stack.name]
    if stack_prototype and stack_prototype.type == "ammo" and stack_prototype.ammo_category == item_category then
      existing = existing + stack.count
    end
  end

  local room_items = math.max(0, limit_items - existing)
  return math.min(room_items, insertable)
end

---@param role string
---@param inventories LuaInventory[]
---@param item ItemIDAndQualityIDPair|ItemWithQualityID
---@param fuel_limit { value: number, unit: string }?
---@param ammo_limit { value: number, unit: string }?
---@return number
function M.capacity(role, inventories, item, fuel_limit, ammo_limit)
  local total = 0
  for _, inventory in pairs(inventories) do
    if inventory and inventory.valid then
      if role == "fuel" and fuel_limit then
        total = total + fuel_room(inventory, item, fuel_limit)
      elseif role == "ammo" and ammo_limit then
        total = total + ammo_room(inventory, item, ammo_limit)
      else
        total = total + inventory.get_insertable_count(item)
      end
    end
  end
  return total
end

return M
