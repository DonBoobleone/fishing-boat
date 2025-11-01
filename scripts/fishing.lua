-- fishing.lua
local fishing_radius = 4
local fish_item_name = "raw-fish"
local fish_entity_name = "fish"
local boat_entity_name = "fishing-boat"
local check_interval = 30  -- Every 30 ticks

-- Track active fishing boats in prefixed global storage
local function initialize_storage()
    storage.fishing_boat_entities = storage.fishing_boat_entities or {}
end

-- Add boat to tracked list
local function register_boat(entity)
    if entity and entity.valid and entity.name == boat_entity_name then
        storage.fishing_boat_entities[entity.unit_number] = entity
    end
end

-- Remove boat from tracked list
local function unregister_boat(entity)
    if entity and entity.unit_number then
        storage.fishing_boat_entities[entity.unit_number] = nil
    end
end

-- Scan all surfaces for existing boats and register them
local function scan_and_register_boats()
    for _, surface in pairs(game.surfaces) do
        local boats = surface.find_entities_filtered{name = boat_entity_name}
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
        unregister_boat(entity)
    end
end

-- Perform fishing check for a single boat
local function check_fishing_for_boat(boat)
    if not boat or not boat.valid then return end

    local surface = boat.surface
    local position = boat.position
    local area = {
        {position.x - fishing_radius, position.y - fishing_radius},
        {position.x + fishing_radius, position.y + fishing_radius}
    }

    local fish_entities = surface.find_entities_filtered{
        area = area,
        name = fish_entity_name,
        force = "neutral"  -- Fish are neutral
    }

    local inventory = boat.get_inventory(defines.inventory.car_trunk)
    if not inventory or inventory.is_full() then return end  -- Skip if no inventory or full

    for _, fish in ipairs(fish_entities) do
        if fish.valid and inventory.can_insert({name = fish_item_name, count = 5}) then
            inventory.insert({name = fish_item_name, count = 5})
            fish.destroy()
        end
    end
end

-- Global nth tick handler for all boats
local function on_nth_tick(event)
    for _, boat in pairs(storage.fishing_boat_entities) do
        check_fishing_for_boat(boat)
    end
end

-- Register events
script.on_init(function()
    initialize_storage()
    scan_and_register_boats()
end)
script.on_configuration_changed(function()
    initialize_storage()
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