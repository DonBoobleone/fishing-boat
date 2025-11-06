-- fishing.lua
local fishing_radius = 4
local fish_item_name = "raw-fish"
local fish_entity_name = "fish"
local check_interval = 30  -- Every 30 ticks
local local_search_radius = 100  -- Radius for local replacement search (safe for movement between checks)

local is_aai_active = script.active_mods["aai-programmable-vehicles"]

-- Ensure storage tables exist
local function initialize_storage()
    storage.fishing_boat_entities = storage.fishing_boat_entities or {}
    storage.fishing_boat_names = storage.fishing_boat_names or {}
    storage.fishing_boat_names_set = storage.fishing_boat_names_set or {}
end

-- Populate boat names based on prototypes (call only when mods/config change or lazily if missing)
local function populate_boat_names()
    storage.fishing_boat_names = {}
    storage.fishing_boat_names_set = {}
    if is_aai_active then
        for name, proto in pairs(prototypes.entity) do
            if proto.type == "car" and name:match("^fishing%-boat") then
                table.insert(storage.fishing_boat_names, name)
                storage.fishing_boat_names_set[name] = true
            end
        end
    end
end

-- Add boat to tracked list with additional data if AAI active
local function register_boat(entity)
    if not entity or not entity.valid then return end

    local is_boat = is_aai_active and storage.fishing_boat_names_set[entity.name] or entity.name == "fishing-boat"
    if is_boat then
        local data = {entity = entity}
        if is_aai_active then
            data.last_position = entity.position
            data.last_surface = entity.surface
        end
        storage.fishing_boat_entities[entity.unit_number] = data
    end
end

-- Remove boat from tracked list
local function unregister_boat(unit_number)
    if unit_number then
        storage.fishing_boat_entities[unit_number] = nil
    end
end

-- Scan all surfaces for existing boats and register them
local function scan_and_register_boats()
    local filter_name = is_aai_active and storage.fishing_boat_names or "fishing-boat"
    for _, surface in pairs(game.surfaces) do
        local boats = surface.find_entities_filtered{name = filter_name}
        for _, boat in ipairs(boats) do
            register_boat(boat)
        end
    end
end

-- Handle entity creation events
local function on_built(event)
    local entity = event.created_entity or event.entity
    if entity then
        register_boat(entity)
    end
end

-- Handle entity destruction events
local function on_destroyed(event)
    local entity = event.entity
    if entity then
        unregister_boat(entity.unit_number)
    end
end

-- Search locally for replacement boats around a position (AAI only)
local function local_search_for_replacement(surface, position)
    if not is_aai_active then return end

    local area = {
        {position.x - local_search_radius, position.y - local_search_radius},
        {position.x + local_search_radius, position.y + local_search_radius}
    }
    local boats = surface.find_entities_filtered{
        area = area,
        name = storage.fishing_boat_names
    }
    for _, boat in ipairs(boats) do
        register_boat(boat)
    end
end

-- Perform fishing check for a single boat
local function check_fishing_for_boat(unit_number, boat_data)
    -- Lazy migration: if old direct entity format, convert to table
    if type(boat_data) ~= "table" then
        if boat_data and boat_data.valid then
            local new_data = {entity = boat_data}
            if is_aai_active then
                new_data.last_position = boat_data.position
                new_data.last_surface = boat_data.surface
            end
            boat_data = new_data
            storage.fishing_boat_entities[unit_number] = boat_data
        else
            unregister_boat(unit_number)
            return
        end
    end

    local entity = boat_data.entity
    if not entity or not entity.valid then
        if is_aai_active then
            local_search_for_replacement(boat_data.last_surface, boat_data.last_position)
        end
        unregister_boat(unit_number)
        return
    end

    if is_aai_active then
        boat_data.last_position = entity.position
        boat_data.last_surface = entity.surface
    end

    local position = entity.position
    local area = {
        {position.x - fishing_radius, position.y - fishing_radius},
        {position.x + fishing_radius, position.y + fishing_radius}
    }

    local fish_entities = entity.surface.find_entities_filtered{
        area = area,
        name = fish_entity_name,
        force = "neutral"  -- Fish are neutral
    }

    local inventory = entity.get_inventory(defines.inventory.car_trunk)
    if not inventory or inventory.is_full() then return end

    for _, fish in ipairs(fish_entities) do
        if fish.valid and inventory.can_insert({name = fish_item_name, count = 5}) then
            inventory.insert({name = fish_item_name, count = 5})
            fish.destroy()
        end
    end
end

-- Global nth tick handler for all boats
local function on_nth_tick(event)
    initialize_storage()
    if is_aai_active and #storage.fishing_boat_names == 0 then
        populate_boat_names()
    end
    for unit_number, boat_data in pairs(storage.fishing_boat_entities) do
        check_fishing_for_boat(unit_number, boat_data)
    end
end

-- Register events
script.on_init(function()
    initialize_storage()
    populate_boat_names()
    scan_and_register_boats()
end)

script.on_configuration_changed(function()
    initialize_storage()
    populate_boat_names()
    scan_and_register_boats()
end)

script.on_event({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built
}, on_built)

script.on_event({
    defines.events.on_entity_died,
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.script_raised_destroy
}, on_destroyed)

script.on_nth_tick(check_interval, on_nth_tick)