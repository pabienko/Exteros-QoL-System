local ENTITY_INVENTORY_TYPES = {
  ["car"] = defines.inventory.car_trunk,
  ["cargo-wagon"] = defines.inventory.cargo_wagon,
  ["container"] = defines.inventory.chest,
  ["logistic-container"] = defines.inventory.chest,
  ["spider-vehicle"] = defines.inventory.spider_trunk
}

local M = {}

local function sort_container_inventory(player)
  if not player.opened or player.opened_gui_type ~= defines.gui_type.entity then
    return
  end
  local inv_type = ENTITY_INVENTORY_TYPES[player.opened.type] or 255
  local inventory = player.opened.get_inventory(inv_type)
  if inventory and not inventory.is_empty() then
    inventory.sort_and_merge()
  end
end


function M.on_manual_inventory_sort(e)
  local player = game.get_player(e.player_index)
  if player and player.valid then
    sort_container_inventory(player)
  end
end


function M.on_gui_opened(e)
  if e.gui_type ~= defines.gui_type.entity then return end
  local player = game.get_player(e.player_index)
  if not player or not player.valid then return end

  if not settings.get_player_settings(player)["exteros-qol-auto-sort-inventory"].value then
    return
  end
  sort_container_inventory(player)
end

return M
