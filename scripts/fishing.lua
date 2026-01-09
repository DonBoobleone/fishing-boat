-- fishing.lua

local fishing_radius = 4
local fish_item_name = "raw-fish"
local fish_entity_name = "fish"
local local_search_radius = 100
local bucket_count = 30

local is_aai_active = script.active_mods["aai-programmable-vehicles"] or false

local storage_handler_lib = require("scripts.storage-handler")
local handler = storage_handler_lib.create_storage_handler({
    entity_name = "fishing-boat",  -- dummy, we replace name_set with multi-name set
    storage_prefix = "fishing_boat",
})

local buckets_key = handler.storage_prefix .. "_buckets"

-- Unified boat name collection
local function populate_boat_names()
    storage.fishing_boat_names = {}
    storage.fishing_boat_names_set = {}
    handler.name_set = storage.fishing_boat_names_set

    for name, prototype in pairs(prototypes.entity) do
        if prototype.type == "car" and name:match("^fishing%-boat") then
            table.insert(storage.fishing_boat_names, name)
            storage.fishing_boat_names_set[name] = true
        end
    end
end

-- Add AAI-specific data if needed
local function add_aai_extras(data, entity)
    if is_aai_active and data then
        data.last_position = entity.position
        data.last_surface = entity.surface
    end
end

-- Full registration used on build/clone/revive
local function register_boat(entity)
    if not (entity and entity.valid) then return end

    handler:register(entity)

    local unit_number = entity.unit_number
    if not unit_number then return end

    local data = storage[handler.entities_key][unit_number]
    add_aai_extras(data, entity)

    -- Add to bucket immediately
    local bucket_id = (unit_number % bucket_count) + 1
    storage[buckets_key] = storage[buckets_key] or {}
    storage[buckets_key][bucket_id] = storage[buckets_key][bucket_id] or {}
    storage[buckets_key][bucket_id][unit_number] = true
end

-- Local replacement search when a boat becomes invalid (AAI only)
local function local_search_for_replacement(surface, position)
    if not is_aai_active then return end
    local area = {
        {position.x - local_search_radius, position.y - local_search_radius},
        {position.x + local_search_radius, position.y + local_search_radius}
    }
    local boats = surface.find_entities_filtered({
        area = area,
        name = storage.fishing_boat_names
    })
    for _, boat in ipairs(boats) do
        register_boat(boat)
    end
end

-- Core fishing logic (entity assumed valid)
local function perform_fishing(data)
    local entity = data.entity
    local position = entity.position
    local area = {
        {position.x - fishing_radius, position.y - fishing_radius},
        {position.x + fishing_radius, position.y + fishing_radius}
    }
    local fish_entities = entity.surface.find_entities_filtered({
        area = area,
        name = fish_entity_name,
        force = "neutral"
    })
    local inventory = entity.get_inventory(defines.inventory.car_trunk)
    if not inventory or inventory.is_full() then return end

    for _, fish in ipairs(fish_entities) do
        if fish.valid and inventory.can_insert({name = fish_item_name, count = 5}) then
            inventory.insert({name = fish_item_name, count = 5})
            fish.destroy()
        end
    end
end

-- Rebuild buckets from all currently valid entities
local function rebuild_buckets()
    storage[buckets_key] = storage[buckets_key] or {}
    local buckets = storage[buckets_key]
    for i = 1, bucket_count do
        buckets[i] = buckets[i] or {}
        for k in pairs(buckets[i]) do buckets[i][k] = nil end
    end
    for unit_number, _ in handler:iterate_valid_entities() do
        local bucket_id = (unit_number % bucket_count) + 1
        buckets[bucket_id][unit_number] = true
    end
end

-- Manual multi-name scan used in init and config_changed
local function manual_scan_and_register()
    if #storage.fishing_boat_names == 0 then return end
    for _, surface in pairs(game.surfaces) do
        local entities = surface.find_entities_filtered({name = storage.fishing_boat_names})
        for _, entity in ipairs(entities) do
            handler:register(entity)
            local unit_number = entity.unit_number
            if unit_number then
                local data = storage[handler.entities_key][unit_number]
                add_aai_extras(data, entity)
            end
        end
    end
end

-- Built handler (covers all creation cases)
local function on_built(event)
    local entity = event.created_entity or event.entity or event.destination or event.revived_entity
    if entity then
        register_boat(entity)
    end
end

-- Destroyed handler
local function on_destroyed(event)
    local entity = event.entity
    if not entity or not entity.unit_number then return end
    local unit_number = entity.unit_number

    if storage.fishing_boat_names_set[entity.name] then
        handler:unregister(unit_number)
        local bucket_id = (unit_number % bucket_count) + 1
        if storage[buckets_key] and storage[buckets_key][bucket_id] then
            storage[buckets_key][bucket_id][unit_number] = nil
        end
    end
end

-- Rolling tick update
script.on_event(defines.events.on_tick, function()
    local bucket_id = (game.tick % bucket_count) + 1
    local bucket = storage[buckets_key] and storage[buckets_key][bucket_id]
    if not bucket then return end

    for unit_number in pairs(bucket) do
        local raw_data = storage[handler.entities_key] and storage[handler.entities_key][unit_number]
        local data = nil
        local should_unregister = false

        if raw_data then
            if type(raw_data) == "table" then
                data = raw_data
            else
                -- Lazy migration from old direct-entity format
                if raw_data.valid then
                    data = {entity = raw_data}
                    add_aai_extras(data, raw_data)
                    storage[handler.entities_key][unit_number] = data
                else
                    should_unregister = true
                end
            end
        else
            should_unregister = true
        end

        if data then
            local entity = data.entity
            if entity and entity.valid then
                perform_fishing(data)
                add_aai_extras(data, entity)  -- update position every check
            else
                if is_aai_active and data.last_position and data.last_surface then
                    local_search_for_replacement(data.last_surface, data.last_position)
                end
                should_unregister = true
            end
        end

        if should_unregister then
            handler:unregister(unit_number)
            bucket[unit_number] = nil
        end
    end
end)

-- Init / config changed
script.on_init(function()
    populate_boat_names()
    handler:initialize_storage()
    manual_scan_and_register()
    rebuild_buckets()
end)

script.on_configuration_changed(function()
    populate_boat_names()
    handler:initialize_storage()
    manual_scan_and_register()
    rebuild_buckets()
end)

-- Events
script.on_event({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive,
    defines.events.on_entity_cloned,
}, on_built)

script.on_event({
    defines.events.on_entity_died,
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.script_raised_destroy,
}, on_destroyed)