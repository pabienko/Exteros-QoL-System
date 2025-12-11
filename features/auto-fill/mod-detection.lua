-- features/auto-fill/mod-detection.lua
-- Mod detection and caching for Space Age and quality system

local mod_detection = {}

-- Cache results at module load time
local is_space_age_available = false
local is_quality_available = false

-- Check if Space Age is available
if mods and mods["space-age"] then
  is_space_age_available = true
end

-- Check if quality system is available
if prototypes and prototypes.quality then
  is_quality_available = true
end

-- Function to check if quality system is available
function mod_detection.is_quality_available()
  return is_quality_available
end

-- Function to check if Space Age is available
function mod_detection.is_space_age_available()
  return is_space_age_available
end

return mod_detection

