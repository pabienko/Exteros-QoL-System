local M = {}

local debug_enabled = nil

local function is_debug_enabled()
  if debug_enabled == nil then
    local success, result = pcall(function()
      return settings.startup["exteros-qol-debug"].value
    end)
    debug_enabled = success and result or false
  end
  return debug_enabled
end

function M.log(message, category)
  if not is_debug_enabled() then return end
  local prefix = "[Exteros QoL" .. (category and (":" .. category) or "") .. "] "
  log(prefix .. tostring(message))
end

function M.dump(tbl, category)
  if not is_debug_enabled() then return end
  local success, result = pcall(function() 
    return serpent.line(tbl) 
  end)
  M.log(success and result or "Failed to dump table", category)
end

function M.error(message)
  log("[Exteros QoL ERROR] " .. tostring(message))
end

function M.reset_cache()
  debug_enabled = nil
end

return M