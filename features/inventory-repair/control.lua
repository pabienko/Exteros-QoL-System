local M = {}

local function debug_log(msg)
  if settings.startup["exteros-qol-debug"].value then
    log("[Inv-Repair] " .. msg)
  end
end

local function index_tools()
  debug_log("Indexing repair tools...")
  local order = settings.global["exteros-qol-inventory-repair-order"].value
  local tools = {}
  
  for name, proto in pairs(prototypes.get_item_filtered({{filter="type", type="repair-tool"}})) do
    table.insert(tools, {
      name = name,
      speed = proto.speed,
      infinite = proto.infinite
    })
  end
  
  table.sort(tools, function(a, b)
    if a.infinite ~= b.infinite then return a.infinite end
    if order == "low-first" then
      return a.speed < b.speed
    else
      return a.speed > b.speed
    end
  end)
  
  storage.repair_tools = tools
end

local function repair_item(repair_pack, damaged_item, ticks)
  local place_result = damaged_item.prototype.place_result
  if not place_result then return false end
  
  local max_health = place_result.get_max_health(damaged_item.quality)
  local current_health = damaged_item.health * max_health
  local speed = repair_pack.prototype.speed * place_result.repair_speed_modifier / damaged_item.count
  if speed == 0 then return false end
  
  local repair_needed = (max_health - current_health) / speed
  local amount = math.min(ticks, math.ceil(repair_needed))
  
  local durability = repair_pack.prototype.infinite and math.huge or repair_pack.durability
  if durability < amount then
    amount = durability
  end
  
  debug_log("Repairing " .. damaged_item.name .. " (health: " .. damaged_item.health .. ") with " .. repair_pack.name)
  repair_pack.drain_durability(amount)
  damaged_item.health = math.min(1.0, (current_health + amount * speed) / max_health)
  
  return true
end

local function find_damaged_item(inventory)
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack.valid_for_read and stack.health < 1.0 and stack.prototype.place_result then
      return stack
    end
  end
  return nil
end

local function process_player(player, ticks)
  local inv = player.get_main_inventory()
  if not inv then return end
  
  local repair_pack
  for _, tool in ipairs(storage.repair_tools or {}) do
    repair_pack = inv.find_item_stack(tool.name)
    if repair_pack then break end
  end
  
  if not repair_pack then return end
  
  local damaged = find_damaged_item(inv)
  if not damaged then return end
  
  if repair_item(repair_pack, damaged, ticks) then
    if damaged.health == 1.0 then
      debug_log("Item " .. damaged.name .. " fully repaired for player " .. player.name)
      if player.auto_sort_main_inventory then
        inv.sort_and_merge()
      end
    end
    player.play_sound({path="utility/confirm", position=player.position})
  end
end

function M.on_tick(event)
  if not settings.startup["exteros-qol-inventory-repair-enabled"].value then return end
  
  local interval = settings.global["exteros-qol-inventory-repair-interval"].value
  if event.tick % interval ~= 0 then return end
  
  for _, player in pairs(game.connected_players) do
    if player.character and player.character.valid then
      process_player(player, interval)
    end
  end
end

function M.init()
  index_tools()
end

function M.on_configuration_changed()
  index_tools()
end

function M.on_runtime_mod_setting_changed(e)
  if e.setting == "exteros-qol-inventory-repair-order" then
    index_tools()
  end
end

return M
