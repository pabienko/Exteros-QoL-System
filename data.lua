-- Squeak Through
if settings.startup["exteros-st-enabled"].value then
  local entities_to_modify = { ["pipe"] = { "pipe", "pipe-to-ground" }, ["solar-panel"] = { "solar-panel" }, ["accumulator"] = { "accumulator" }, ["beacon"] = { "beacon" } }
  for entity_type, entity_names in pairs(entities_to_modify) do
    if data.raw[entity_type] then
      for _, entity_name in ipairs(entity_names) do
        local entity = data.raw[entity_type][entity_name]
        if entity and entity.collision_box then
          local box = entity.collision_box
          local shrink_amount = 0.1
          box[1][1] = box[1][1] + shrink_amount; box[1][2] = box[1][2] + shrink_amount; box[2][1] = box[2][1] - shrink_amount; box[2][2] = box[2][2] - shrink_amount
        end
      end
    end
  end
  local player_character = data.raw.character.character
  if player_character then
    player_character.collision_box = {{-0.05, -0.05}, {0.05, 0.05}}
  end
end

-- Far Reach
if settings.startup["exteros-fr-enabled"].value then
  local player_character = data.raw.character.character
  if player_character then
    local new_reach = 120
    player_character.reach_distance = new_reach
    player_character.build_distance = new_reach
    player_character.reach_resource_distance = new_reach + 5
  end
end