local lib_constants = require("__exteros-lib__.constants")
local lib_box = require("__exteros-lib__.box")

local M = {}

---@param entity LuaEntity
---@return { inventory: LuaInventory, bar: uint }[]?
function M.collect_limited(entity)
  local inventory_types = lib_constants.ENTITY_TRANSFER_INVENTORIES[entity.type] or { defines.inventory.chest }

  local records = {}
  local seen = {}
  for _, inventory_type in pairs(inventory_types) do
    local inventory = entity.get_inventory(inventory_type)
    if inventory and inventory.valid and inventory.supports_bar() and not seen[inventory.index] then
      seen[inventory.index] = true
      local bar = inventory.get_bar()
      if bar <= #inventory then
        table.insert(records, { inventory = inventory, bar = bar })
      end
    end
  end

  if #records == 0 then
    return nil
  end
  return records
end

---@param records { inventory: LuaInventory, bar: uint }[]
function M.open(records)
  for _, record in pairs(records) do
    if record.inventory.valid then
      record.inventory.set_bar()
    end
  end
end

---@param records { inventory: LuaInventory, bar: uint }[]
function M.close(records)
  for _, record in pairs(records) do
    local inventory = record.inventory
    if inventory.valid then
      inventory.set_bar(math.min(record.bar, #inventory + 1))
    end
  end
end

---@param entity LuaEntity
---@return LuaEntity[]?
function M.suppress_machines(entity)
  local area = lib_box.snap_outward(lib_box.expand(entity.bounding_box, 3))

  local candidates = entity.surface.find_entities_filtered({
    area = area,
    type = { "inserter", "loader", "loader-1x1" },
  })

  local machines = {}
  for _, machine in pairs(candidates) do
    if machine.active then
      table.insert(machines, machine)
      machine.disabled_by_script = true
    end
  end

  if #machines == 0 then
    return nil
  end
  return machines
end

---@param machines LuaEntity[]?
function M.restore_machines(machines)
  if not machines then return end
  for _, machine in pairs(machines) do
    if machine.valid then
      machine.disabled_by_script = false
    end
  end
end

return M
