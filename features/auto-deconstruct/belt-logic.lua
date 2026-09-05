local compat = require("core.compat")

local M = {}

M.belt_types = {
  ["transport-belt"] = true,
  ["underground-belt"] = true,
  ["splitter"] = true,
  ["loader"] = true,
  ["loader-1x1"] = true
}

---@param belt LuaEntity
---@param exclude table<number, boolean>?
---@return LuaEntity[]
function M.get_outputs(belt, exclude)
  local outputs = {}
  local neighbors = belt.belt_neighbours
  if not neighbors then return outputs end
  
  for _, neighbor in pairs(neighbors.outputs) do
    if not (exclude and exclude[neighbor.unit_number]) then
      table.insert(outputs, neighbor)
    end
  end
  
  if belt.type == "underground-belt" and belt.belt_to_ground_type == "input" then
    local neighbor = compat.underground_partner(belt)
    if neighbor and not (exclude and exclude[neighbor.unit_number]) then
      table.insert(outputs, neighbor)
    end
  end
  return outputs
end

---@param belt LuaEntity
---@param exclude table<number, boolean>?
---@return LuaEntity[]
function M.get_inputs(belt, exclude)
  local inputs = {}
  local neighbors = belt.belt_neighbours
  if not neighbors then return inputs end
  
  for _, neighbor in pairs(neighbors.inputs) do
    if not (exclude and exclude[neighbor.unit_number]) then
      table.insert(inputs, neighbor)
    end
  end
  
  if belt.type == "underground-belt" and belt.belt_to_ground_type == "output" then
    local neighbor = compat.underground_partner(belt)
    if neighbor and not (exclude and exclude[neighbor.unit_number]) then
      table.insert(inputs, neighbor)
    end
  end
  return inputs
end

---@param drill LuaEntity
---@param target LuaEntity?
---@return LuaTransportLine?
function M.find_target_line(drill, target)
  if not target or not M.belt_types[target.type] then return nil end
  
  local belt_pos = target.position --[[@as MapPosition.struct]]
  local drop_pos = drill.drop_position --[[@as MapPosition.struct]]
  local belt_dir = target.direction
  ---@type defines.transport_line?
  local line_index = nil
  
  if target.type == "transport-belt" then
    if target.belt_shape == "left" then
      line_index = defines.transport_line.right_line
    elseif target.belt_shape == "right" then
      line_index = defines.transport_line.left_line
    end
  end
  
  if not line_index and (target.type == "transport-belt" or target.type == "underground-belt") then
    if belt_dir == defines.direction.north then
      line_index = drop_pos.x < belt_pos.x and defines.transport_line.left_line or defines.transport_line.right_line
    elseif belt_dir == defines.direction.south then
      line_index = drop_pos.x > belt_pos.x and defines.transport_line.left_line or defines.transport_line.right_line
    elseif belt_dir == defines.direction.east then
      line_index = drop_pos.y < belt_pos.y and defines.transport_line.left_line or defines.transport_line.right_line
    elseif belt_dir == defines.direction.west then
      line_index = drop_pos.y > belt_pos.y and defines.transport_line.left_line or defines.transport_line.right_line
    end
  end
  
  if not line_index and target.type == "splitter" then
    if belt_dir == defines.direction.north then
      if drop_pos.y < belt_pos.y then
        if drop_pos.x < belt_pos.x - 0.5 then 
          line_index = defines.transport_line.left_split_line
        elseif drop_pos.x < belt_pos.x then 
          line_index = defines.transport_line.right_split_line
        elseif drop_pos.x < belt_pos.x + 0.5 then 
          line_index = defines.transport_line.secondary_left_split_line
        else 
          line_index = defines.transport_line.secondary_right_split_line 
        end
      else
        if drop_pos.x < belt_pos.x - 0.5 then 
          line_index = defines.transport_line.left_line
        elseif drop_pos.x < belt_pos.x then 
          line_index = defines.transport_line.right_line
        elseif drop_pos.x < belt_pos.x + 0.5 then 
          line_index = defines.transport_line.secondary_left_line
        else 
          line_index = defines.transport_line.secondary_right_line 
        end
      end
    end
  end
  
  if not line_index then return nil end
  return target.get_transport_line(line_index --[[@as defines.transport_line]])
end

---@param belt LuaEntity?
---@return boolean
function M.is_belt_empty(belt)
  if not belt or not belt.valid then return true end
  
  if belt.type == "splitter" then
    for i = 1, 8 do
      local line = belt.get_transport_line(i)
      if line and #line > 0 then return false end
    end
  else
    local l1 = belt.get_transport_line(1)
    local l2 = belt.get_transport_line(2)
    if (l1 and #l1 > 0) or (l2 and #l2 > 0) then return false end
  end
  return true
end

return M