local core = require("core.init")

local M = {}

local WHITE = { r = 1, g = 1, b = 1, a = 1 }
local CIRCLE_SIZE_EXPONENT = 1.6

---@param vector table
---@param factor number
---@return table
local function scale_vector(vector, factor)
  local x = vector.x or vector[1] or 0
  local y = vector.y or vector[2] or 0
  return { x * factor, y * factor }
end

function M.apply()
  local scale_setting = settings.startup["exteros-qol-searchlight-flashlight-global-scale"]
  local intensity_setting = settings.startup["exteros-qol-searchlight-flashlight-global-intensity"]
  local color_setting = settings.startup["exteros-qol-searchlight-flashlight-global-color"]
  if not scale_setting or not intensity_setting or not color_setting then return end

  local scale_mult = scale_setting.value --[[@as number]]
  local intensity_mult = intensity_setting.value --[[@as number]]
  local color_hex = color_setting.value --[[@as string]]

  if scale_mult == 1 and intensity_mult == 1 and color_hex == "" then return end

  local color = color_hex ~= "" and core.color.parse_hex(color_hex, WHITE) or nil

  for _, character in pairs(data.raw.character or {}) do
    local lights = character.light
    if type(lights) == "table" and lights[1] then
      for _, light in pairs(lights) do
        if type(light) == "table" then
          light.intensity = math.min((light.intensity or 1) * intensity_mult, 1)
          if light.type == "oriented" then
            light.size = (light.size or 1) * scale_mult
          else
            light.size = (light.size or 1) * scale_mult ^ CIRCLE_SIZE_EXPONENT
          end

          if light.shift then
            light.shift = scale_vector(light.shift, scale_mult)
          end

          if color then
            light.color = color
          end
        end
      end
    end
  end
end

return M
