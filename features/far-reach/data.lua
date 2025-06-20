local player_character = data.raw.character.character
if player_character then
  local new_reach = 120
  player_character.reach_distance = new_reach
  player_character.build_distance = new_reach
  player_character.reach_resource_distance = new_reach + 5
end