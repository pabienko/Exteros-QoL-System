-- Načtení hlavního nastavení
local st_enabled = settings.startup["squeak-through-enabled"].value
local trees_enabled = settings.startup["squeak-through-trees"].value

-- Načtení seznamu entit
local entities = require("features.squeak-through.entities")

-- === ČÁST 1: SKRÝVÁNÍ NASTAVENÍ ===
if not st_enabled then
    -- Pokud je funkce vypnutá, schováme nastavení pro stromy/kameny
    local setting_proto = data.raw["bool-setting"]["squeak-through-trees"]
    if setting_proto then
        setting_proto.hidden = true
    end
    -- Ukončíme skript, žádné změny kolizí se neprovedou
    return
end

-- === ČÁST 2: ÚPRAVA KOLIZNÍCH BOXŮ ===

-- Funkce pro bezpečné zmenšení boxu pomocí reverzní metody
-- Vytváří nový collision_box místo modifikace existujícího, aby se zachovala kompatibilita s jinými módy
local function apply_squeeze(entity)
    if not entity.collision_box then return end
    
    local box = entity.collision_box
    -- Normalizace boxu (pro jistotu, kdyby byl definován jako objekt left_top/right_bottom)
    local lt = box[1] or box.left_top
    local rb = box[2] or box.right_bottom
    
    if not lt or not rb then return end

    -- Vytvoření kopie hodnot pro reverzní metodu (zachování kompatibility s jinými módy)
    local new_lt = {lt[1], lt[2]}
    local new_rb = {rb[1], rb[2]}

    local shrink = 0.15
    -- Minimální vzdálenost od středu, kterou musíme zachovat, aby box obsahoval [0,0]
    local min_dist_from_center = 0.05 

    -- Logika: Posuneme hranu směrem ke středu o 'shrink', ale zastavíme se na 'min_dist_from_center'
    
    -- Levá hrana (X < 0) -> posouváme doprava (+), max do -0.05
    if new_lt[1] < -min_dist_from_center then
        new_lt[1] = math.min(new_lt[1] + shrink, -min_dist_from_center)
    end

    -- Horní hrana (Y < 0) -> posouváme dolů (+), max do -0.05
    if new_lt[2] < -min_dist_from_center then
        new_lt[2] = math.min(new_lt[2] + shrink, -min_dist_from_center)
    end

    -- Pravá hrana (X > 0) -> posouváme doleva (-), min do 0.05
    if new_rb[1] > min_dist_from_center then
        new_rb[1] = math.max(new_rb[1] - shrink, min_dist_from_center)
    end

    -- Spodní hrana (Y > 0) -> posouváme nahoru (-), min do 0.05
    if new_rb[2] > min_dist_from_center then
        new_rb[2] = math.max(new_rb[2] - shrink, min_dist_from_center)
    end

    -- Reverzní metoda: vytvoření nového collision_box místo modifikace existujícího
    entity.collision_box = {{new_lt[1], new_lt[2]}, {new_rb[1], new_rb[2]}}
end

-- Funkce pro aplikaci změn na seznam typů entit
local function apply_to_entity_types(types)
    for _, type_name in ipairs(types) do
        local prototypes = data.raw[type_name]
        if prototypes then
            for name, entity in pairs(prototypes) do
                apply_squeeze(entity)
            end
        end
    end
end

-- Aplikace na vanilla entity (vždy když je hlavní spínač zapnutý)
apply_to_entity_types(entities.vanilla)

-- Aplikace na stromy/kameny (pouze když je nastavení zapnuté)
if trees_enabled then
    apply_to_entity_types(entities.trees_stones)
end

-- Aplikace na Space Age entity (pouze pokud je Space Age mod aktivní)
-- Kontrola existence Space Age módu přes kontrolu existence některé z jeho entit
local space_age_active = false
for _, entity_type in ipairs(entities.space_age) do
    if data.raw[entity_type] then
        space_age_active = true
        break
    end
end
if space_age_active then
    apply_to_entity_types(entities.space_age)
end

-- Specifická úprava pro hráče
local player = data.raw.character.character
if player then
    player.collision_box = {{-0.05, -0.05}, {0.05, 0.05}}
end
