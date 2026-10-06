local M = {}

local NEW_KEY = "underground_belt_neighbour"
local OLD_KEY = "neighbours"

local underground_neighbour_key = nil

---@param entity LuaEntity
---@return LuaEntity?
function M.underground_partner(entity)
  if entity.type ~= "underground-belt" then return nil end

  local raw = entity --[[@as table]]

  if underground_neighbour_key then
    local success, result = pcall(function()
      return raw[underground_neighbour_key]
    end)
    if not success then return nil end
    return result --[[@as LuaEntity?]]
  end

  local success_new, result_new = pcall(function()
    return raw[NEW_KEY]
  end)
  if success_new then
    underground_neighbour_key = NEW_KEY
    return result_new --[[@as LuaEntity?]]
  end

  local success_old, result_old = pcall(function()
    return raw[OLD_KEY]
  end)
  if success_old then
    underground_neighbour_key = OLD_KEY
    return result_old --[[@as LuaEntity?]]
  end

  return nil
end

local fluidbox_api = nil

---@param entity LuaEntity
---@return string
local function detect_fluidbox_api(entity)
  if fluidbox_api then return fluidbox_api end
  local raw = entity --[[@as table]]
  local success = pcall(function()
    return raw.get_fluid_box_pipe_connections
  end)
  fluidbox_api = success and "2.1" or "2.0"
  return fluidbox_api
end

---@param entity LuaEntity
---@return integer
function M.fluidbox_count(entity)
  return entity.fluids_count or 0
end

---@param entity LuaEntity
---@param index integer
---@return PipeConnection[]
function M.pipe_connections(entity, index)
  if M.fluidbox_count(entity) < index then return {} end

  local raw = entity --[[@as table]]
  if detect_fluidbox_api(entity) == "2.1" then
    return raw.get_fluid_box_pipe_connections(index) or {}
  end

  local box = raw.fluidbox
  if not box or #box < index then return {} end
  return box.get_pipe_connections(index)
end

---@param target any
---@param index integer
---@return any
function M.connection_fluidbox_prototype(target, index)
  if not target or not index then return nil end

  local raw = target --[[@as table]]
  if fluidbox_api == "2.1" then
    return raw.get_fluid_box_prototype(index)
  end
  return raw.get_prototype(index)
end

---@param entity LuaEntity
---@param index integer
---@return { name: string, amount: number, temperature: number }?
function M.fluid(entity, index)
  if index > M.fluidbox_count(entity) then return nil end
  return entity.get_fluid(index)
end

---@param entity LuaEntity
---@param index integer
---@return string?
function M.fluid_filter_name(entity, index)
  local raw = entity --[[@as table]]
  local filter
  if detect_fluidbox_api(entity) == "2.1" then
    filter = raw.get_fluid_filter(index)
  else
    local box = raw.fluidbox
    filter = box and box.get_filter(index)
  end
  if not filter then return nil end
  return filter.name or (filter.fluid and filter.fluid.name)
end

---@param entity LuaEntity
---@param index integer
---@return any
function M.fluid_box_prototype(entity, index)
  local raw = entity --[[@as table]]
  local prototype
  if detect_fluidbox_api(entity) == "2.1" then
    prototype = raw.get_fluid_box_prototype(index)
  else
    local box = raw.fluidbox
    prototype = box and box.get_prototype(index)
  end
  if type(prototype) == "table" then
    prototype = prototype[1]
  end
  return prototype
end

---@param product any
---@return number
function M.product_chance(product)
  return product.probability
    or ((product.independent_probability or 1)
      * (product.shared_probability and (product.shared_probability.max - product.shared_probability.min) or 1))
end

---@param product any
---@return number
function M.product_expected_amount(product)
  local base = product.amount or ((product.amount_min + product.amount_max) / 2)
  return (base + (product.extra_count_fraction or 0)) * M.product_chance(product)
end

---@param item_prototype LuaItemPrototype
---@return number
function M.science_pack_durability(item_prototype)
  local success, durability = pcall(function() return item_prototype.get_durability() end)
  if not success or not durability then return 1 end
  return durability
end

return M
