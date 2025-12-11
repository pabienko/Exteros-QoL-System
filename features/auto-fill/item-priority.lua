-- features/auto-fill/item-priority.lua
-- Item priority and selection logic with conditional quality support

local constants = require("features.auto-fill.constants")
local mod_detection = require("features.auto-fill.mod-detection")
local blacklist_parser = require("features.auto-fill.blacklist-parser")
local entity_detection = require("features.auto-fill.entity-detection")
local item_priority = {}

-- Get best fuel from player inventory
function item_priority.get_best_fuel(player, blacklist)
  local main_inventory = player.get_main_inventory()
  if not main_inventory then
    return nil
  end
  
  if blacklist_parser.is_fuel_disabled(blacklist) then
    return nil
  end
  
  local best_item = nil
  local best_value = 0
  local is_quality_available = mod_detection.is_quality_available()
  
  -- Iterate through all items in inventory
  for i = 1, #main_inventory do
    local stack = main_inventory[i]
    if stack and stack.valid_for_read then
      local item_name = stack.name
      local item_prototype = stack.prototype
      
      -- Check if item is blacklisted
      if blacklist_parser.is_item_blacklisted(blacklist, item_name) then
        goto continue
      end
      
      -- Check if item has fuel value
      if not item_prototype or not item_prototype.fuel_value then
        goto continue
      end
      
      local fuel_value = item_prototype.fuel_value
      local quality_modifier = 1.0
      
      -- Apply quality modifier if quality is available
      -- Note: Quality multipliers are applied automatically by Factorio, so we just prioritize higher quality
      if is_quality_available and stack.quality then
        local quality_name = stack.quality.name
        if quality_name and quality_name ~= "normal" then
          -- Quality fuel values are already calculated in the stack, so we don't need to multiply
          -- We'll use quality tier as a priority boost instead
          local quality_order = { normal = 0, uncommon = 1, rare = 2, epic = 3, legendary = 4 }
          local quality_priority = quality_order[quality_name] or 0
          quality_modifier = 1.0 + (quality_priority * 0.1) -- Small boost for higher quality
        end
      end
      
      local adjusted_value = fuel_value * quality_modifier
      
      -- Prioritize higher fuel value
      if adjusted_value > best_value then
        best_value = adjusted_value
        best_item = {
          name = item_name,
          quality = (stack.quality and stack.quality.name) or "normal",
          count = stack.count,
        }
      end
      
      ::continue::
    end
  end
  
  return best_item
end

-- Get best ammo from player inventory for given turret/entity
function item_priority.get_best_ammo(player, entity, blacklist)
  local main_inventory = player.get_main_inventory()
  if not main_inventory then
    return nil
  end
  
  if blacklist_parser.is_ammo_disabled(blacklist) then
    return nil
  end
  
  -- Get ammo inventory to test what can be inserted
  local ammo_inventory = entity_detection.get_ammo_inventory(entity)
  if not ammo_inventory or not ammo_inventory.valid then
    return nil
  end
  
  local entity_type = entity.type
  local ammo_category = nil
  
  -- Try to get ammo category from entity prototype
  if entity.prototype then
    if entity_type == "ammo-turret" then
      if entity.prototype.attack_parameters and entity.prototype.attack_parameters.ammo_category then
        ammo_category = entity.prototype.attack_parameters.ammo_category
      end
    elseif entity_type == "artillery-turret" then
      if entity.prototype.attack_parameters and entity.prototype.attack_parameters.ammo_category then
        ammo_category = entity.prototype.attack_parameters.ammo_category
      end
    elseif entity_type == "artillery-wagon" then
      if entity.prototype.attack_parameters and entity.prototype.attack_parameters.ammo_category then
        ammo_category = entity.prototype.attack_parameters.ammo_category
      end
    elseif entity_type == "car" or entity_type == "tank" then
      if entity.prototype.guns and entity.prototype.guns[1] and entity.prototype.guns[1].ammo_category then
        ammo_category = entity.prototype.guns[1].ammo_category
      end
    elseif entity_type == "spidertron" then
      if entity.prototype.guns and entity.prototype.guns[1] and entity.prototype.guns[1].ammo_category then
        ammo_category = entity.prototype.guns[1].ammo_category
      end
    end
  end
  
  -- Convert ammo_category to string for comparison
  local ammo_category_str = nil
  if ammo_category then
    if type(ammo_category) == "table" and ammo_category.name then
      ammo_category_str = ammo_category.name
    elseif type(ammo_category) == "string" then
      ammo_category_str = ammo_category
    else
      ammo_category_str = tostring(ammo_category)
    end
  end
  
  local best_item = nil
  local best_damage = 0
  local is_quality_available = mod_detection.is_quality_available()
  
  -- Iterate through all items in inventory
  for i = 1, #main_inventory do
    local stack = main_inventory[i]
    if stack and stack.valid_for_read then
      local item_name = stack.name
      local item_prototype = stack.prototype
      
      -- Check if item is blacklisted
      if blacklist_parser.is_item_blacklisted(blacklist, item_name) then
        goto continue
      end
      
      -- Check if item is ammo and has ammo_type
      if not item_prototype then
        goto continue
      end
      
      -- Check if item is ammo type
      if item_prototype.type ~= "ammo" then
        goto continue
      end
      
      -- Check if item has ammo_type (not all ammo items have it accessible)
      local has_ammo_type = false
      local success = pcall(function()
        if item_prototype.ammo_type then
          has_ammo_type = true
        end
      end)
      
      if not success or not has_ammo_type then
        goto continue
      end
      
      -- Check if ammo category matches (if we have it)
      if ammo_category_str then
        if item_prototype.ammo_type.category then
          local item_category = item_prototype.ammo_type.category
          local item_category_str = nil
          
          -- Convert item category to string
          if type(item_category) == "table" and item_category.name then
            item_category_str = item_category.name
          elseif type(item_category) == "string" then
            item_category_str = item_category
          else
            item_category_str = tostring(item_category)
          end
          
          -- Compare categories
          if item_category_str ~= ammo_category_str then
            goto continue
          end
        else
          goto continue
        end
      else
        -- No ammo category from entity, test if we can insert this ammo
        local test_spec = { name = item_name, count = 1 }
        if stack.quality and stack.quality.name and stack.quality.name ~= "normal" then
          test_spec.quality = stack.quality.name
        end
        if not ammo_inventory.can_insert(test_spec) then
          goto continue
        end
      end
      
      -- Get damage value
      local damage = 0
      if item_prototype.ammo_type and item_prototype.ammo_type.action then
        local action = item_prototype.ammo_type.action
        if action.type == "direct" and action.action_delivery and action.action_delivery.target_effects then
          for _, effect in ipairs(action.action_delivery.target_effects) do
            if effect.type == "damage" and effect.damage then
              local effect_damage = effect.damage
              if effect_damage.amount then
                damage = damage + effect_damage.amount
              end
            end
          end
        end
      end
      
      -- If no explicit damage, use a default priority
      if damage == 0 then
        damage = 1
      end
      
      local quality_modifier = 1.0
      
      -- Apply quality modifier if quality is available
      if is_quality_available and stack.quality then
        local quality_name = stack.quality.name
        if quality_name and quality_name ~= "normal" then
          -- Use quality tier as priority boost for damage calculation
          local quality_order = { normal = 0, uncommon = 1, rare = 2, epic = 3, legendary = 4 }
          local quality_priority = quality_order[quality_name] or 0
          quality_modifier = 1.0 + (quality_priority * 0.1) -- Small boost for higher quality
        end
      end
      
      local adjusted_damage = damage * quality_modifier
      
      -- Prioritize higher damage
      if adjusted_damage > best_damage then
        best_damage = adjusted_damage
        best_item = {
          name = item_name,
          quality = (stack.quality and stack.quality.name) or "normal",
          count = stack.count,
        }
      end
      
      ::continue::
    end
  end
  
  return best_item
end

return item_priority

