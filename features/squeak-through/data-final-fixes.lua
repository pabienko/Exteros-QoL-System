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

    -- Analyzovat fluid_boxes, aby nedošlo ke smrštění boxu mimo pozice přípojek potrubí
    local max_lt_x = -min_dist_from_center
    local max_lt_y = -min_dist_from_center
    local min_rb_x = min_dist_from_center
    local min_rb_y = min_dist_from_center

    if entity.fluid_boxes then
        for k, fb in pairs(entity.fluid_boxes) do
            if type(fb) == "table" and fb.pipe_connections then
                for _, pc in pairs(fb.pipe_connections) do
                    -- Zpracovat jak pc.position, tak i pc.positions (v novém API)
                    local positions = pc.positions or (pc.position and {pc.position}) or {}
                    for _, pos in pairs(positions) do
                        local px = pos[1] or pos.x
                        local py = pos[2] or pos.y
                        if px and py then
                            -- Pokud je přípojka na levé/horní straně (záporné hodnoty), nesmíme zmenšit okraj víc než k této přípojce
                            if px < 0 then max_lt_x = math.min(max_lt_x, px) end
                            if py < 0 then max_lt_y = math.min(max_lt_y, py) end
                            -- Pokud je přípojka na pravé/spodní straně (kladné hodnoty), nesmíme zmenšit okraj víc než k této přípojce
                            if px > 0 then min_rb_x = math.max(min_rb_x, px) end
                            if py > 0 then min_rb_y = math.max(min_rb_y, py) end
                        end
                    end
                end
            end
        end
    end

    -- Logika: Posuneme hranu směrem ke středu o 'shrink', ale zastavíme se na 'max_lt_x' apod.
    
    -- Levá hrana (X < 0) -> posouváme doprava (+), max do max_lt_x
    if new_lt[1] < max_lt_x then
        new_lt[1] = math.min(new_lt[1] + shrink, max_lt_x)
    end

    -- Horní hrana (Y < 0) -> posouváme dolů (+), max do max_lt_y
    if new_lt[2] < max_lt_y then
        new_lt[2] = math.min(new_lt[2] + shrink, max_lt_y)
    end

    -- Pravá hrana (X > 0) -> posouváme doleva (-), min do min_rb_x
    if new_rb[1] > min_rb_x then
        new_rb[1] = math.max(new_rb[1] - shrink, min_rb_x)
    end

    -- Spodní hrana (Y > 0) -> posouváme nahoru (-), min do min_rb_y
    if new_rb[2] > min_rb_y then
        new_rb[2] = math.max(new_rb[2] - shrink, min_rb_y)
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
