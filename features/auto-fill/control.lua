-- features/auto-fill/control.lua
-- Event handlers for auto-fill feature

local blacklist_parser = require("features.auto-fill.blacklist-parser")
local entity_detection = require("features.auto-fill.entity-detection")
local fill_logic = require("features.auto-fill.fill-logic")

-- Cache parsed blacklist to avoid parsing every time
local cached_blacklist = nil
local last_blacklist_string = ""

-- Get or parse blacklist
local function get_blacklist()
  local blacklist_string = settings.startup["auto-fill-blacklist"].value
  if blacklist_string ~= last_blacklist_string then
    cached_blacklist = blacklist_parser.parse(blacklist_string)
    last_blacklist_string = blacklist_string
  end
  return cached_blacklist or blacklist_parser.parse(blacklist_string)
end

-- Handle entity placement
local function handle_entity_built(event)
  local entity = event.created_entity or event.entity
  if not entity or not entity.valid then
    return
  end
  
  local player = nil
  if event.player_index then
    player = game.get_player(event.player_index)
  elseif event.robot then
    -- For script_raised_built, we might not have a player
    -- In that case, skip auto-fill (blueprints should be handled by on_built_entity)
    return
  end
  
  if not player or not player.valid then
    return
  end
  
  -- Check if auto-fill is enabled
  if not settings.startup["auto-fill-enabled"].value then
    return
  end
  
  -- Get player settings
  local player_settings = settings.get_player_settings(player)
  local max_percent = player_settings["auto-fill-max-percent"].value
  local fuel_only = player_settings["auto-fill-fuel-only"].value
  local ammo_only = player_settings["auto-fill-ammo-only"].value
  
  -- Get blacklist
  local blacklist = get_blacklist()
  
  -- Validate entity and player
  if not entity_detection.validate(entity, player) then
    return
  end
  
  -- Fill entity
  fill_logic.fill_entity(entity, player, max_percent, blacklist, fuel_only, ammo_only)
end

-- Event handlers
script.on_event(defines.events.on_built_entity, function(event)
  handle_entity_built(event)
end)

script.on_event(defines.events.script_raised_built, function(event)
  -- Handle blueprint placement by robots
  local entity = event.entity
  if not entity or not entity.valid then
    return
  end
  
  -- Check if auto-fill is enabled
  if not settings.startup["auto-fill-enabled"].value then
    return
  end
  
  -- Check if blueprint auto-fill is enabled (requires a player check)
  -- script_raised_built doesn't have player_index, so we need to find nearby players
  -- For now, we'll iterate through all players and use the first one who has the setting enabled
  -- In practice, blueprints placed by players manually trigger on_built_entity instead
  local robot = event.robot
  if robot and robot.valid then
    -- Try to find a player to fill from (closest player or force owner)
    local force = robot.force
    if force then
      for _, player in pairs(game.players) do
        if player and player.valid and player.force == force then
          local player_settings = settings.get_player_settings(player)
          if player_settings["auto-fill-blueprint-enabled"].value then
            -- Get player settings
            local max_percent = player_settings["auto-fill-max-percent"].value
            local fuel_only = player_settings["auto-fill-fuel-only"].value
            local ammo_only = player_settings["auto-fill-ammo-only"].value
            
            -- Get blacklist
            local blacklist = get_blacklist()
            
            -- Validate entity and player
            if entity_detection.validate(entity, player) then
              -- Fill entity
              fill_logic.fill_entity(entity, player, max_percent, blacklist, fuel_only, ammo_only)
            end
            break
          end
        end
      end
    end
  end
end)

-- Refresh blacklist cache when settings change
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "auto-fill-blacklist" then
    cached_blacklist = nil
    last_blacklist_string = ""
  end
end)

