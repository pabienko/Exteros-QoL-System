local M = {}

local function trim(n, max_trim)
  local sign = n >= 0 and 1 or -1
  n = math.abs(n)
  local base = math.floor(n * 2) / 2
  local decimal = n - base
  local new_decimal = math.min(max_trim, decimal)
  return (base + new_decimal) * sign
end

local function get_connections(prototype)
  local connections = {}
  if prototype.fluid_box then
    if prototype.fluid_box.pipe_connections then
      for _, conn in ipairs(prototype.fluid_box.pipe_connections) do
        table.insert(connections, conn.position or conn)
      end
    end
  end
  
  if prototype.fluid_boxes then
    for _, fb in ipairs(prototype.fluid_boxes) do
      if fb.pipe_connections then
        for _, conn in ipairs(fb.pipe_connections) do
          table.insert(connections, conn.position or conn)
        end
      end
    end
  end
  return connections
end

function M.apply()
  if not settings.startup["exteros-qol-squeak-through-enabled"].value then
    return
  end
  
  local character = data.raw.character.character
  if character and character.collision_box then
    local character_box = character.collision_box
    character_box[1][1] = character_box[1][1] + 1/256
    character_box[1][2] = character_box[1][2] + 1/256
    character_box[2][1] = character_box[2][1] - 1/256
    character_box[2][2] = character_box[2][2] - 1/256
  end
  
  local overrides = {
    ["pipe"] = 0.1,
    ["pipe-to-ground"] = 0.1,
    ["tree"] = 0.2,
    ["offshore-pump"] = 0.05,
    ["storage-tank"] = 0.1,
    ["pump"] = 0.1,
  }
  
  for ptype, prototypes in pairs(data.raw) do
    for name, prototype in pairs(prototypes) do
      if prototype.squeak_behaviour == false then
        goto continue
      end
      
      local collision_box = prototype.collision_box
      if not collision_box then
        goto continue
      end
      
      if prototype.flags then
        for _, flag in pairs(prototype.flags) do
          if flag == "placeable-off-grid" then
            goto continue
          end
        end
      end
      
      if prototype.collision_mask and prototype.collision_mask.colliding_with_tiles_only then
        goto continue
      end
      
      local limit = overrides[prototype.type] or 0.3
      local lt, rb = collision_box[1], collision_box[2]
      local ltx = lt.x or lt[1]
      local lty = lt.y or lt[2]
      local rbx = rb.x or rb[1]
      local rby = rb.y or rb[2]
      
      local new_ltx = trim(ltx, limit)
      local new_lty = trim(lty, limit)
      local new_rbx = trim(rbx, limit)
      local new_rby = trim(rby, limit)
      
      local connections = get_connections(prototype)
      for _, conn in ipairs(connections) do
        local cx = conn.x or conn[1]
        local cy = conn.y or conn[2]
        new_ltx = math.min(new_ltx, cx)
        new_lty = math.min(new_lty, cy)
        new_rbx = math.max(new_rbx, cx)
        new_rby = math.max(new_rby, cy)
      end
      
      if new_ltx ~= ltx or new_lty ~= lty or new_rbx ~= rbx or new_rby ~= rby then
        prototype.collision_box = {{new_ltx, new_lty}, {new_rbx, new_rby}}
      end
      
      ::continue::
    end
  end
end

return M