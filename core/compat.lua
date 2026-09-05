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

-- Factorio 2.1 removed LuaFluidBox. Everything it offered now lives as flat
-- methods on LuaEntity, and PipeConnection::target is a LuaEntity instead of a
-- LuaFluidBox. Reading a key an object does not have raises, so the API in use
-- is probed once and cached.
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

--- How many fluid storages the entity actually has right now. The prototype is
--- the wrong source: an electric mining drill declares an input fluidbox but
--- carries no storage until it mines a resource that needs one, and asking for
--- a storage it does not have raises on 2.1.
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

--- Prototype behind PipeConnection::target, whatever that target is on this
--- version. May be nil, or an array when a crafting machine merged several.
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

return M
