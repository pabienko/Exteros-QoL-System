-- Note: Core is not available in data-final-fixes stage, so we use direct settings access
local settings = settings.startup
local mode = settings["stack-size-mode"].value
local value = settings["stack-size-value"].value

local function apply_changes(proto)
    if not proto or not proto.stack_size or proto.stack_size <= 1 then
        return
    end

    local original_stack = proto.stack_size
    local new_stack = original_stack

    if mode == "multiplier" then
        new_stack = math.floor(original_stack * value)
    elseif mode == "absolute" then
        new_stack = math.floor(value)
    end

    if new_stack < 1 then
        new_stack = 1
    end

    proto.stack_size = new_stack
end

local prototype_tables_to_modify = {
    "item", "item-with-entity-data", "item-with-inventory", "tool",
    "ammo", "capsule", "module", "rail-planner", "repair-tool"
}

for _, table_name in ipairs(prototype_tables_to_modify) do
    local prototype_table = data.raw[table_name]
    if prototype_table then
        for _, prototype in pairs(prototype_table) do
            apply_changes(prototype)
        end
    end
end