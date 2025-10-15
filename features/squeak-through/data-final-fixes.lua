-- ZMĚNA ZAČÁTEK
-- Původní kód byl rozšířen o explicitní podporu pro jiné módy.
-- Tento přístup je robustnější a umožňuje cíleně řešit kompatibilitu.

-- Tato rekurzivní funkce zůstává, je ideální pro standardní upgrade řetězce.
local function apply_squeak_through_recursively(entity)
  if not entity then
    return
  end

  if entity.collision_box then
    local box = entity.collision_box
    local shrink_amount = 0.1
    box[1][1] = box[1][1] + shrink_amount
    box[1][2] = box[1][2] + shrink_amount
    box[2][1] = box[2][1] - shrink_amount
    box[2][2] = box[2][2] - shrink_amount
  end

  if entity.next_upgrade then
    local next_upgrade_prototype = data.raw[entity.type][entity.next_upgrade]
    if next_upgrade_prototype then
      apply_squeak_through_recursively(next_upgrade_prototype)
    end
  end
end

-- Seznam základních entit, které vždy upravujeme.
local entities_to_modify = {
  ["pipe"] = { "pipe", "pipe-to-ground" },
  ["solar-panel"] = { "solar-panel" },
  ["accumulator"] = { "accumulator" },
  ["beacon"] = { "beacon" }
}

for entity_type, entity_names in pairs(entities_to_modify) do
  if data.raw[entity_type] then
    for _, entity_name in ipairs(entity_names) do
      local entity = data.raw[entity_type][entity_name]
      if entity then
        apply_squeak_through_recursively(entity)
      end
    end
  end
end

-- PŘIDÁNO ZAČÁTEK
-- === BLOK PRO PODPORU EXTERNÍCH MÓDŮ ===

-- Zkontrolujeme, zda je mód "Advanced-Solar" aktivní.
-- Globální tabulka 'mods' je k dispozici během načítání a obsahuje názvy všech aktivních módů.
if mods["Advanced-Solar"] then
  -- Seznam entit z cizího módu, které chceme upravit.
  -- I když 'advanced-solar' je v řetězci vylepšení, explicitní úprava je bezpečnější.
  local advanced_solar_entities = { "advanced-solar", "advanced-solar-2", "advanced-solar-3" }

  for _, entity_name in ipairs(advanced_solar_entities) do
    if data.raw["solar-panel"][entity_name] then
      -- Na tyto entity není třeba volat rekurzivní funkci, protože je upravujeme všechny přímo.
      local entity = data.raw["solar-panel"][entity_name]
      if entity.collision_box then
        local box = entity.collision_box
        local shrink_amount = 0.1
        box[1][1] = box[1][1] + shrink_amount
        box[1][2] = box[1][2] + shrink_amount
        box[2][1] = box[2][1] - shrink_amount
        box[2][2] = box[2][2] - shrink_amount
      end
    end
  end
end
-- PŘIDÁNO KONEC
-- ZMĚNA KONEC

local player_character = data.raw.character.character
if player_character then
  player_character.collision_box = {{-0.05, -0.05}, {0.05, 0.05}}
end