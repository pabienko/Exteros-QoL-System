-- features/auto-fill/blacklist-parser.lua
-- Parses user blacklist settings into structured blacklist

local constants = require("features.auto-fill.constants")
local blacklist_parser = {}

-- Special keywords for blacklist
local SPECIAL_KEYWORDS = {
  ["spoilable-fuel"] = true,
  ["all-fuel"] = true,
  ["all-ammo"] = true,
}

-- Parse blacklist string into structured table
function blacklist_parser.parse(blacklist_string)
  local blacklist = {
    entities = {},
    items = {},
    spoilable_fuel = false,
    all_fuel = false,
    all_ammo = false,
  }
  
  if not blacklist_string or blacklist_string == "" then
    return blacklist
  end
  
  -- Split by comma and trim whitespace
  for item in blacklist_string:gmatch("([^,]+)") do
    item = item:match("^%s*(.-)%s*$") -- Trim whitespace
    
    if item == "" then
      goto continue
    end
    
    -- Check for special keywords
    if SPECIAL_KEYWORDS[item] then
      if item == "spoilable-fuel" then
        blacklist.spoilable_fuel = true
      elseif item == "all-fuel" then
        blacklist.all_fuel = true
      elseif item == "all-ammo" then
        blacklist.all_ammo = true
      end
    else
      -- Check if it's a known entity type or item name
      -- We'll validate this during runtime, for now just add it
      blacklist.entities[item] = true
      blacklist.items[item] = true
    end
    
    ::continue::
  end
  
  return blacklist
end

-- Check if entity type is blacklisted
function blacklist_parser.is_entity_blacklisted(blacklist, entity_type)
  if not blacklist then return false end
  return blacklist.entities[entity_type] == true
end

-- Check if item is blacklisted
function blacklist_parser.is_item_blacklisted(blacklist, item_name)
  if not blacklist then return false end
  
  -- Check explicit item blacklist
  if blacklist.items[item_name] then
    return true
  end
  
  -- Check spoilable fuel
  if blacklist.spoilable_fuel and constants.spoilable_fuel[item_name] then
    return true
  end
  
  return false
end

-- Check if fuel filling is disabled
function blacklist_parser.is_fuel_disabled(blacklist)
  if not blacklist then return false end
  return blacklist.all_fuel == true
end

-- Check if ammo filling is disabled
function blacklist_parser.is_ammo_disabled(blacklist)
  if not blacklist then return false end
  return blacklist.all_ammo == true
end

return blacklist_parser

