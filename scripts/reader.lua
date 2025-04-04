local mod_gui = require("mod-gui")


local tracing = true
local log_index = 1

local frequency = settings.startup["reader-frequency"].value

local function debug(msg)
    if not tracing then return end
    msg = "[" .. log_index .. "] " .. msg
    log_index = log_index + 1
    for _, player in pairs(game.players) do
        player.print(msg)
        log(msg)
    end
end


---@param e LuaEntity
local function add_to_reader_map(e)
    local index = e.unit_number % 20
    local reader_map = storage.reader_map
    local index_map = reader_map[index]
    if not index_map then
        index_map = {}
        reader_map[index] = index_map
    end
    index_map[e.unit_number] = e
end


---@param evt EventData.on_built_entity
local function on_built(evt)
    local e = evt.entity
    if not e or not e.valid then return end

    if e.name == "container_reader" then
        add_to_reader_map(e)
    end
end

---@param reader LuaEntity
local function clear(reader) 

    local cb = reader.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
    if not cb then return end
    if cb.sections_count > 0 then
        cb.remove_section(1)
    end
end


---@type {[string]:defines.inventory | integer}
local entities_inventory = {
    ["agricultural-tower"] = 3 
    ,["linked-container"] = defines.inventory.chest
    ,["logistic-container"] = defines.inventory.chest
    ,["container"] = defines.inventory.chest
    ,["infinity-container"] = defines.inventory.chest
    ,["cargo-landing-pad"] = defines.inventory.cargo_landing_pad_main
    ,["space-platform-hub"] = defines.inventory.hub_main
}

local entities_to_scan = {}
for name in pairs(entities_inventory) do
    table.insert(entities_to_scan, name)
end

---@param reader LuaEntity
local function process_reader(reader)
    local chest = storage.reader_chest[reader.unit_number] --[[@as LuaEntity?]]
    local direction = reader.direction
    local pos = reader.position
    local x, y = pos.x, pos.y

    if direction == defines.direction.north then
        y = y + 1
    elseif direction == defines.direction.south then
        y = y - 1
    elseif direction == defines.direction.east then
        x = x - 1
    elseif direction == defines.direction.west then
        x = x + 1
    end

    if chest and not chest.valid then
        storage.reader_chest[reader.unit_number] = nil
        chest = nil
    elseif chest then
        local chest_pos = chest.position
        local tile_width = chest.tile_width
        local tile_height = chest.tile_height
        local w, h
        if direction == defines.direction.north or direction == defines.direction.south then
            w, h = tile_width, tile_height
        else
            h, w = tile_width, tile_height
        end
        if (math.abs(chest_pos.x - x) > w / 2) or (math.abs(chest_pos.y - y) > h / 2) then
            storage.reader_chest[reader.unit_number] = nil
            chest = nil
        end
    end

    if not chest then
        local entities = reader.surface.find_entities_filtered {
            position = pos,
            radius = 0.25,
            type = entities_to_scan
        }
        local found
        if #entities == 0 then
            entities = reader.surface.find_entities_filtered {
                position = { x = x, y = y },
                radius = 5,
                type = entities_to_scan
            }
            if #entities == 0 then
                clear(reader)
                return
            end
            for _, container in pairs(entities) do
                local container_pos = container.position
                local tile_width = container.tile_width
                local tile_height = container.tile_height
                local w, h
                if direction == defines.direction.north or direction == defines.direction.south then
                    w, h = tile_width, tile_height
                else
                    h, w = tile_width, tile_height
                end
                if (math.abs(container_pos.x - x) <= w / 2) and (math.abs(container_pos.y - y) <= h / 2) then
                    found = container
                    break
                end
            end
            if not found then
                clear(reader)
                return
            end
        else
            found = entities[1]
        end
        chest = found
        storage.reader_chest[reader.unit_number] = chest
    end

    local inv
    inv = chest.get_inventory(entities_inventory[chest.type])

    if not inv then
        clear(reader)
        return
    end
    local content = inv.get_contents()
    local cb = reader.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
    if not cb then return end

    ---@type LogisticFilter[]
    local filters = {}

    for _, item in pairs(content) do
        table.insert(filters, {
            value = { type = "item", name = item.name, quality = item.quality, comparator = "=" },
            min = item.count
        })
    end
    local free_count = inv.count_empty_stacks(false, false);
    table.insert(filters, {
        value = { type = "virtual", name = "signal-F", quality = "normal", comparator = "=" },
        min = free_count
    })

    local section = cb.get_section(1)
    if not section then
        section = cb.add_section("");
    end
    section.filters = filters
end

local function on_tick()
    local index = game.tick % frequency
    local readers = storage.reader_map[index]

    if readers then
        for id, reader in pairs(readers) do
            if not reader.valid then
                readers[id] = nil
                storage.reader_chest[id] = nil
                if next(readers) == nil then
                    storage.reader_map[index] = nil
                end
                return
            end
            process_reader(reader)
        end
    end
end


local entity_filter = {}
table.insert(entity_filter, { filter = 'name', name = "container_reader" })

script.on_event(defines.events.on_built_entity, on_built, entity_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, entity_filter)
script.on_event(defines.events.script_raised_built, on_built, entity_filter)
script.on_event(defines.events.script_raised_revive, on_built, entity_filter)
script.on_event(defines.events.on_space_platform_built_entity, on_built, entity_filter)

script.on_event(defines.events.on_tick, on_tick)

local function on_init()
    storage.reader_chest = {}
    storage.reader_map = {}
end

script.on_init(on_init)
