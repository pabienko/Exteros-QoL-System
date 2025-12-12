-- ============================================
-- SEKCE A: SKRÝVÁNÍ NASTAVENÍ
-- ============================================
-- Pokud je hlavní funkce vypnutá, skryjeme všechny podrobné kategorie
if not settings.startup["squeak-through-enabled"].value then
  local sub_settings = {
    "squeak-through-pipes",
    "squeak-through-solar",
    "squeak-through-production",
    "squeak-through-mining",
    "squeak-through-energy",
    "squeak-through-logistics",
    "squeak-through-defense",
    "squeak-through-trees-rocks",
    "squeak-through-space-age"
  }
  
  for _, setting_name in ipairs(sub_settings) do
    local setting = data.raw["bool-setting"][setting_name]
    if setting then
      setting.hidden = true
    end
  end
  
  -- Ukončíme provádění, aby se neaplikovaly žádné změny kolizí
  return
end

-- ============================================
-- SEKCE B: APLIKACE LOGIKY
-- ============================================
-- Pomocná funkce pro kontrolu, zda má entita pipe_connections
local function has_pipe_connections(entity)
  if not entity then return false end
  
  if entity.fluid_boxes then
    for _, fluid_box in pairs(entity.fluid_boxes) do
      if fluid_box.pipe_connections and #fluid_box.pipe_connections > 0 then
        return true
      end
    end
  elseif entity.fluid_box and entity.fluid_box.pipe_connections and #entity.fluid_box.pipe_connections > 0 then
    return true
  end
  
  return false
end

-- Funkce pro shromáždění všech entit v upgrade řetězci
local function collect_upgrade_chain(entity)
  local chain = {}
  local current = entity
  while current do
    table.insert(chain, current)
    if current.next_upgrade then
      current = data.raw[current.type] and data.raw[current.type][current.next_upgrade]
    else
      break
    end
  end
  return chain
end


-- Funkce pro shromáždění všech upgrade řetězců pro daný typ entity
local function collect_all_upgrade_chains(entity_type)
  local chains = {}
  local processed = {}
  
  if not data.raw[entity_type] then
    return chains
  end
  
  -- Projdeme všechny entity daného typu
  for entity_name, entity in pairs(data.raw[entity_type]) do
    -- Pokud už byla entita zpracována (je součástí jiného řetězce), přeskočíme ji
    local entity_key = entity_type .. ":" .. entity_name
    if not processed[entity_key] then
      -- Shromáždíme celý upgrade řetězec od této entity
      local chain = collect_upgrade_chain(entity)
      
      -- Označíme všechny entity v řetězci jako zpracované
      for _, chain_entity in ipairs(chain) do
        local chain_entity_name = chain_entity.name
        local chain_key = chain_entity.type .. ":" .. chain_entity_name
        processed[chain_key] = true
      end
      
      -- Přidáme řetězec do seznamu
      table.insert(chains, chain)
    end
  end
  
  return chains
end

-- Funkce pro aplikaci squeak through na všechny upgrade řetězce najednou
local function apply_squeak_through_to_all_chains(chains)
  for _, chain in ipairs(chains) do
    -- Zkontrolujeme, zda má některá entita v řetězci pipe_connections
    local chain_has_pipe_connections = false
    for _, chain_entity in ipairs(chain) do
      if has_pipe_connections(chain_entity) then
        chain_has_pipe_connections = true
        break
      end
    end
    
    -- Pokud řetězec nemá pipe_connections, zmenšíme collision_box u všech entit v řetězci
    -- Pokud má, nezmenšíme u žádné, aby měly všechny stejný bounding box
    if not chain_has_pipe_connections then
      for _, chain_entity in ipairs(chain) do
        if chain_entity.collision_box then
          local box = chain_entity.collision_box
          local shrink_amount = 0.1
          box[1][1] = box[1][1] + shrink_amount
          box[1][2] = box[1][2] + shrink_amount
          box[2][1] = box[2][1] - shrink_amount
          box[2][2] = box[2][2] - shrink_amount
        end
      end
    end
  end
end


-- Mapování kategorií na typy entit
local category_mapping = {
  ["pipes"] = {
    ["pipe"] = { "pipe", "pipe-to-ground" },
    ["pump"] = {} -- Všechny pumpy
  },
  ["solar"] = {
    ["solar-panel"] = {}, -- Všechny solární panely
    ["accumulator"] = {} -- Všechny akumulátory
  },
  ["production"] = {
    ["assembling-machine"] = {}, -- Všechny montovny
    ["furnace"] = {}, -- Všechny pece
    ["chemical-plant"] = {}, -- Všechny chemické továrny
    ["centrifuge"] = {}, -- Všechny centrifugy
    ["oil-refinery"] = {} -- Všechny rafinerie
  },
  ["mining"] = {
    ["mining-drill"] = {}, -- Všechny těžební vrtačky
    ["pumpjack"] = {} -- Všechny pumpjacks
  },
  ["energy"] = {
    ["boiler"] = {}, -- Všechny kotle
    ["generator"] = {}, -- Všechny generátory (parní motory, turbíny)
    ["reactor"] = {} -- Všechny reaktory
  },
  ["logistics"] = {
    ["container"] = {}, -- Všechny truhly
    ["logistic-container"] = {}, -- Všechny logistické truhly
    ["roboport"] = {} -- Všechny roboporty
  },
  ["defense"] = {
    ["turret"] = {}, -- Všechny věže
    ["radar"] = {}, -- Všechny radary
    ["wall"] = {} -- Všechny zdi
  },
  ["trees-rocks"] = {
    ["tree"] = {} -- Všechny stromy (kameny jsou zpracovány zvlášť)
  },
  ["space-age"] = {} -- Bude naplněno dynamicky
}

-- Dynamické přidání Space Age entit (pokud je mód aktivní)
if mods["space-age"] then
  -- Velké budovy ze Space Age (příklad - může být potřeba upravit podle skutečných názvů)
  category_mapping["space-age"] = {
    ["assembling-machine"] = {}, -- Velké montovny ze Space Age
    ["furnace"] = {}, -- Velké pece ze Space Age
    ["chemical-plant"] = {}, -- Velké chemické továrny ze Space Age
    ["oil-refinery"] = {} -- Velké rafinerie ze Space Age
  }
end

-- Aplikace logiky podle povolených kategorií
local function is_category_enabled(category_name)
  return settings.startup["squeak-through-" .. category_name].value
end

-- Procházení kategorií a aplikace změn
for category_name, entity_types in pairs(category_mapping) do
  -- Pro space-age kontrolujeme, zda je mód načten
  if category_name == "space-age" and not mods["space-age"] then
    -- Přeskočíme, pokud mód není načten
  elseif is_category_enabled(category_name) then
    for entity_type, entity_names in pairs(entity_types) do
      if #entity_names == 0 then
        -- Pokud je seznam prázdný, shromáždíme všechny upgrade řetězce pro daný typ
        local all_chains = collect_all_upgrade_chains(entity_type)
        -- Aplikujeme změny na všechny řetězce najednou
        apply_squeak_through_to_all_chains(all_chains)
      else
        -- Pro konkrétní entity ze seznamu shromáždíme jejich upgrade řetězce
        local all_chains = {}
        for _, entity_name in ipairs(entity_names) do
          local entity = data.raw[entity_type] and data.raw[entity_type][entity_name]
          if entity then
            local chain = collect_upgrade_chain(entity)
            table.insert(all_chains, chain)
          end
        end
        -- Aplikujeme změny na všechny řetězce najednou
        apply_squeak_through_to_all_chains(all_chains)
      end
    end
  end
end

-- Speciální případ: Kameny (stromy jsou zpracovány v hlavní smyčce)
if is_category_enabled("trees-rocks") then
  -- Kameny (simple-entity s názvem obsahujícím "rock", "stone" nebo "boulder")
  if data.raw["simple-entity"] then
    for entity_name, entity in pairs(data.raw["simple-entity"]) do
      -- Aplikujeme na entity, které vypadají jako kameny
      if entity_name:find("rock") or entity_name:find("stone") or entity_name:find("boulder") then
        -- Kameny nemají upgrade řetězce, takže můžeme přímo zmenšit collision_box
        if entity.collision_box and not has_pipe_connections(entity) then
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
end

-- Úprava kolizního boxu hráče (vždy aplikováno, pokud je hlavní funkce zapnutá)
local player_character = data.raw.character.character
if player_character then
  player_character.collision_box = {{-0.05, -0.05}, {0.05, 0.05}}
end


