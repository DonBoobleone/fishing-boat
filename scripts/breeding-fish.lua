-- breeding-fish.lua
local is_debug_active = script.active_mods["debugadapter"] ~= nil

local breeding_cycle = settings.startup["breeding-cycle"].value
local breeding_limit = settings.startup["breeding-limit"].value
local breeding_space_ratio = 1024 / breeding_limit

local function get_chunk_area(chunk_pos)
    local left_top = {x = chunk_pos.x * 32, y = chunk_pos.y * 32}
    return {left_top, {x = left_top.x + 32, y = left_top.y + 32}}
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

    local fish = surface.find_entities_filtered{area = area, type = "fish"}
    local fish_count = #fish
    if fish_count < 2 or fish_count > breeding_limit then
        return
    end

    local water_filter = {collision_mask = {"water_tile"}, collision_mask_mode = "contains"}
    local water_count = surface.count_tiles_filtered{area = area, collision_mask = water_filter.collision_mask, collision_mask_mode = water_filter.collision_mask_mode}

    if water_count == 0 then
        return
    end

    local max_viable = math.floor(water_count / breeding_space_ratio)
    if fish_count >= max_viable then
        return
    end

    local prob = calculate_breeding_probability(fish_count, max_viable)
    if math.random() < prob then
        local water_tiles = surface.find_tiles_filtered{area = area, collision_mask = water_filter.collision_mask, collision_mask_mode = water_filter.collision_mask_mode}
        if #water_tiles == 0 then
            return
        end

        local tile = water_tiles[math.random(1, #water_tiles)]
        local entity = surface.create_entity{name = "fish", position = tile.position}
    end
end

local function on_breeding_tick(event)
    for _, surface in pairs(game.surfaces) do
        if surface.planet then
            local chunk = surface.get_random_chunk()
            if chunk then
                breed_in_chunk(surface, chunk)
            end
        end
    end
end

script.on_nth_tick(breeding_cycle, on_breeding_tick)