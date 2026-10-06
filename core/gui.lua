local M = {}

---@type table<string, fun(e: table)>
local registry = {}

---@param handler string|table<defines.events, string>
---@return table<string, string>
local function normalize_handler(handler)
  if type(handler) == "string" then
    return { [tostring(defines.events.on_gui_click)] = handler }
  end
  local out = {}
  for event_id, name in pairs(handler) do
    out[tostring(event_id)] = name
  end
  return out
end

---@param parent LuaGuiElement
---@param defs table[]
---@param elems table<string, LuaGuiElement>
---@param pending_drag { element: LuaGuiElement, target: string }[]
---@return LuaGuiElement? first
local function add_list(parent, defs, elems, pending_drag)
  local first
  for i = 1, #defs do
    local def = defs[i]

    local children = def.children
    local elem_mods = def.elem_mods
    local handler = def.handler
    local style_mods = def.style_mods
    local drag_target = def.drag_target

    local has_array_children = false
    if def[1] then
      if children then
        error("Cannot define children in both the array portion and the children field")
      end
      has_array_children = true
      children = {}
      for j = 1, #def do
        children[j] = def[j]
        def[j] = nil
      end
    end

    def.children = nil
    def.elem_mods = nil
    def.handler = nil
    def.style_mods = nil
    def.drag_target = nil

    if handler then
      local tags = def.tags or {}
      tags.exteros_qol_handler = normalize_handler(handler)
      def.tags = tags
    end

    local elem = parent.add(def)

    if not first then
      first = elem
    end
    if def.name then
      elems[def.name] = elem
    end

    if style_mods then
      for key, value in pairs(style_mods) do
        elem.style[key] = value
      end
    end
    if elem_mods then
      for key, value in pairs(elem_mods) do
        elem[key] = value
      end
    end
    if drag_target then
      table.insert(pending_drag, { element = elem, target = drag_target })
    end
    if children then
      add_list(elem, children, elems, pending_drag)
    end

    if has_array_children then
      for j = 1, #children do
        def[j] = children[j]
      end
    else
      def.children = children
    end
    def.elem_mods = elem_mods
    def.handler = handler
    def.style_mods = style_mods
    def.drag_target = drag_target
  end
  return first
end

---@param parent LuaGuiElement
---@param def table
---@param elems table<string, LuaGuiElement>?
---@return table<string, LuaGuiElement> elems
---@return LuaGuiElement? first
function M.add(parent, def, elems)
  elems = elems or {}
  local defs = def.type and { def } or def
  local pending_drag = {}

  local first = add_list(parent, defs, elems, pending_drag)

  for _, pending in ipairs(pending_drag) do
    local target = elems[pending.target]
    if not target then
      error("Drag target '" .. pending.target .. "' not found.")
    end
    pending.element.drag_target = target
  end

  return elems, first
end

---@param prefix string
---@param handlers table<string, fun(e: table)>
function M.add_handlers(prefix, handlers)
  for name, fn in pairs(handlers) do
    registry[prefix .. ":" .. name] = fn
  end
end

---@param e table
---@param prefix string
---@return boolean handled
function M.dispatch(e, prefix)
  local elem = e.element
  if not elem or not elem.valid then return false end

  local tags = elem.tags
  local handler_def = tags and tags.exteros_qol_handler --[[@as table<string, string>?]]
  if not handler_def then return false end

  local name = handler_def[tostring(e.name)]
  if not name then return false end
  if name:sub(1, #prefix + 1) ~= prefix .. ":" then return false end

  local fn = registry[name]
  if not fn then return false end

  fn(e)
  return true
end

return M
