local core = require("core.init")
local lib_storage = require("__exteros-lib__.storage")
local bar = core.bar

local M = {}

---@alias ForceInsertEntry { records: { inventory: LuaInventory, bar: uint }[], machines: LuaEntity[]?, tick: uint }

local force_insert_pending = lib_storage.player_table("force_insert_pending")

---@param entry ForceInsertEntry
---@return nil
local function restore_entry(entry)
  bar.close(entry.records)
  bar.restore_machines(entry.machines)
end

---@param entries ForceInsertEntry[]
---@return nil
function M.restore(entries)
  for _, entry in pairs(entries) do
    restore_entry(entry)
  end
end

---@param player_index integer
---@param entry ForceInsertEntry
---@return nil
function M.track(player_index, entry)
  local entries = force_insert_pending.peek(player_index)
  if not entries then
    entries = {}
    force_insert_pending.set(player_index, entries)
  end
  table.insert(entries, entry)
end

---@param player_index integer
---@return nil
function M.release_player(player_index)
  local entries = force_insert_pending.peek(player_index)
  if not entries then return end
  M.restore(entries)
  force_insert_pending.clear(player_index)
end

---@return nil
function M.release_everyone()
  for player_index in pairs(force_insert_pending.all()) do
    M.release_player(player_index)
  end
end

---@param tick uint
---@return nil
function M.release_expired(tick)
  for player_index, entries in pairs(force_insert_pending.all()) do
    local remaining = {}
    for _, entry in pairs(entries) do
      if entry.tick < tick then
        restore_entry(entry)
      else
        table.insert(remaining, entry)
      end
    end
    if #remaining > 0 then
      force_insert_pending.set(player_index, remaining)
    else
      force_insert_pending.clear(player_index)
    end
  end
end

M.unconditional = {
  events = {
    [defines.events.on_tick] = function(e) M.release_expired(e.tick) end,
    [defines.events.on_player_removed] = function(e) M.release_player(e.player_index) end,
  },
  on_configuration_changed = function() M.release_everyone() end,
}

return M
