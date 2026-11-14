local lib_settings = require("__exteros-lib__.internal.settings")
local manifest = require("manifest")

---@return ExterosLibManifest
local function manifest_for_startup()
  if feature_flags.quality then
    return manifest
  end

  local filtered = {}
  for key, value in pairs(manifest) do
    filtered[key] = value
  end

  local features = {}
  for _, feature in ipairs(manifest.features) do
    if feature.name ~= "quality-scroll" then
      table.insert(features, feature)
    end
  end
  filtered.features = features

  return filtered
end

lib_settings.extend(manifest_for_startup())
