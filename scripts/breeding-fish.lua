-- breeding-fish.lua
local is_debug_active = script.active_mods["debugadapter"] ~= nil

local breeding_cycle = settings.startup["breeding-cycle"].value
local breeding_limit = settings.startup["breeding-limit"].value
local breeding_space_ratio = 1024 / breeding_limit

-- New: Scaling parameters; adjust divisor for desired growth rate
local max_chunks_per_cycle = 128
local chunks_scale_divisor = 1000 -- e.g., N ~ total_chunks / 1000, min 1

-- New: Track generated chunks per surface
storage.generated_chunks = storage.generated_chunks or {}

local function get_chunk_area(chunk_pos)
    local left_top = { x = chunk_pos.x * 32, y = chunk_pos.y * 32 }
    return { left_top, { x = left_top.x + 32, y = left_top.y + 32 } }
end

local function calculate_breeding_probability(fish_count, max_viable)
    if fish_count < 2 or fish_count >= max_viable then
        return 0
    end

    local mu = max_viable / 2
    if mu <= 2 then
        return 0
    end

    if fish_count <= mu then
        return 0.2 + 0.7 * (fish_count - 2) / (mu - 2)
    else
        return 0.9 * (max_viable - fish_count) / (max_viable - mu)
    end
end

local function breed_in_chunk(surface, chunk_pos)
    local area = get_chunk_area(chunk_pos)

    local fish = surface.find_entities_filtered { area = area, type = "fish" }
    local fish_count = #fish
    if fish_count < 2 or fish_count > breeding_limit then
        return
    end

    local water_filter = { collision_mask = { "water_tile" }, collision_mask_mode = "contains" }
    local water_count = surface.count_tiles_filtered { area = area, collision_mask = water_filter.collision_mask, collision_mask_mode = water_filter.collision_mask_mode }

    if water_count == 0 then
        return
    end

    local max_viable = math.floor(water_count / breeding_space_ratio)
    if fish_count >= max_viable then
        return
    end

    local prob = calculate_breeding_probability(fish_count, max_viable)
    if math.random() < prob then
        local water_tiles = surface.find_tiles_filtered { area = area, collision_mask = water_filter.collision_mask, collision_mask_mode = water_filter.collision_mask_mode }
        if #water_tiles == 0 then
            return
        end

        local tile = water_tiles[math.random(1, #water_tiles)]
        local entity = surface.create_entity { name = "fish", position = tile.position }
    end
end

local function on_breeding_tick(event)
    for _, surface in pairs(game.surfaces) do
        if surface.planet then
            local total_chunks = storage.generated_chunks[surface.index] or 1
            local num_chunks = math.max(1, math.min(max_chunks_per_cycle, math.ceil(total_chunks / chunks_scale_divisor)))

            for i = 1, num_chunks do
                local chunk = surface.get_random_chunk()
                if chunk then
                    breed_in_chunk(surface, chunk)
                end
            end
        end
    end
end

local function on_chunk_generated(event)
    local surface = event.surface
    local surface_id = surface.index
    storage.generated_chunks[surface_id] = (storage.generated_chunks[surface_id] or 0) + 1
end

local function initialize_generated_chunks()
    for _, surface in pairs(game.surfaces) do
        if surface.planet then
            if not storage.generated_chunks[surface.index] then
                local count = 0
                for _ in surface.get_chunks() do
                    count = count + 1
                end
                storage.generated_chunks[surface.index] = count > 0 and count or 1
            end
        end
    end
end

script.on_init(function()
    storage.generated_chunks = {}
    initialize_generated_chunks()
end)

script.on_configuration_changed(function(data)
    if data.mod_changes["fishing-boat"] then
        storage.generated_chunks = storage.generated_chunks or {}
        initialize_generated_chunks()
    end
end)

script.on_event(defines.events.on_chunk_generated, on_chunk_generated)
script.on_nth_tick(breeding_cycle, on_breeding_tick)
