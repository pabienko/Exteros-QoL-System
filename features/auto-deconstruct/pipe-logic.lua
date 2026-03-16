local M = {}

local function compare_tables(t1, t2)
  if #t1 ~= #t2 then return false end
  local counts = {}
  for _, v in ipairs(t1) do counts[v] = (counts[v] or 0) + 1 end
  for _, v in ipairs(t2) do
    if not counts[v] or counts[v] == 0 then return false end
    counts[v] = counts[v] - 1
  end
  return true
end

function M.cache_prototypes()
  M.pipe_categories = {}
  M.pipe_to_category = {}
  
  for name, p in pairs(prototypes.get_entity_filtered{{filter="type", type="pipe"}}) do
    if not p.hidden and p.fluidbox_prototypes and #p.fluidbox_prototypes == 1 then
      local conns = p.fluidbox_prototypes[1].pipe_connections
      if #conns == 4 and conns[1].connection_type == "normal" then
        local valid = true
        local first_cat = conns[1].connection_category
        
        for i = 2, 4 do
          if conns[i].connection_type ~= "normal" or not compare_tables(first_cat, conns[i].connection_category) then
            valid = false
            break
          end
        end
        
        if valid then
          local cat_map = {}
          for _, c in ipairs(first_cat) do cat_map[c] = true end
          M.pipe_to_category[name] = cat_map
          
          for _, c in ipairs(first_cat) do
            M.pipe_categories[c] = M.pipe_categories[c] or {}
            table.insert(M.pipe_categories[c], name)
          end
        end
      end
    end
  end
end

function M.find_pipes_to_build(drill)
  local pipes = {}
  local fluidboxes = drill.fluidbox
  if not fluidboxes or #fluidboxes == 0 then return pipes end
  
  for _, conn in pairs(fluidboxes.get_pipe_connections(1)) do
    if conn.connection_type == "normal" and conn.target then
      local target_proto = conn.target.get_prototype(conn.target_fluidbox_index)
      local conns = target_proto.object_name and target_proto.pipe_connections or {}
      
      if not target_proto.object_name then
        for _, fb in ipairs(target_proto) do
          for _, c in ipairs(fb.pipe_connections) do
            table.insert(conns, c)
          end
        end
      end
      
      local target_conn = conns[conn.target_pipe_connection_index]
      if target_conn then
        table.insert(pipes, {
          offset = {
            x = conn.position.x - drill.position.x, 
            y = conn.position.y - drill.position.y
          },
          categories = target_conn.connection_category
        })
      end
    end
  end
  return pipes
end

local function ensure_cache()
  if M.pipe_to_category then return end
  M.cache_prototypes()
end

function M.choose_pipe(drill, targets)
  ensure_cache()
  if #targets == 0 then return nil end
  
  local valid_pipes = {}
  for name, cat_map in pairs(M.pipe_to_category) do
    local match_all = true
    for _, target in ipairs(targets) do
      local match_this = false
      for _, cat in ipairs(target.categories) do
        if cat_map[cat] then
          match_this = true
          break
        end
      end
      if not match_this then
        match_all = false
        break
      end
    end
    if match_all then
      valid_pipes[name] = true
    end
  end
  
  if not next(valid_pipes) then return nil end
  
  local surface = drill.surface
  for name in pairs(valid_pipes) do
    local mask = prototypes.entity[name].collision_mask.layers
    local offset = targets[1].offset
    local tile = surface.get_tile(drill.position.x + offset.x, drill.position.y + offset.y)
    for layer in pairs(mask) do
      if tile.collides_with(layer) then
        valid_pipes[name] = nil
        break
      end
    end
  end
  
  local chosen = next(valid_pipes)
  if not chosen then return nil end
  return {name = chosen, quality = "normal"}
end

function M.build_ghosts(drill, pipe_type, targets)
  local ghosts = {}
  for _, target in ipairs(targets) do
    local x, y = target.offset.x, target.offset.y
    
    table.insert(ghosts, drill.surface.create_entity{
      name = "entity-ghost",
      position = {drill.position.x + x, drill.position.y + y},
      force = drill.force,
      inner_name = pipe_type.name,
      quality = pipe_type.quality,
      raise_built = true
    })
    
    while math.abs(x) >= 0.75 do
      x = x > 0 and x - 1 or x + 1
      table.insert(ghosts, drill.surface.create_entity{
        name = "entity-ghost",
        position = {drill.position.x + x, drill.position.y + y},
        force = drill.force,
        inner_name = pipe_type.name,
        quality = pipe_type.quality,
        raise_built = true
      })
    end
    
    while math.abs(y) >= 0.75 do
      y = y > 0 and y - 1 or y + 1
      table.insert(ghosts, drill.surface.create_entity{
        name = "entity-ghost",
        position = {drill.position.x + x, drill.position.y + y},
        force = drill.force,
        inner_name = pipe_type.name,
        quality = pipe_type.quality,
        raise_built = true
      })
    end
  end
  return ghosts
end

return M