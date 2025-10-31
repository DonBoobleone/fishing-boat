--prototype/entity.lua
local fishing_boat = table.deepcopy(data.raw["car"]["car"])

fishing_boat.name = "fishing-boat"
fishing_boat.icon = "__fishing-boat__/graphics/icons/fishing-boat.png"
fishing_boat.icon_size = 64
fishing_boat.collision_mask = {layers = {ground_tile = true, train = true}}--, object = true, is_object = true}}
fishing_boat.collision_box = {{-1.2, -3}, {1.2, 3}} -- TODO
fishing_boat.selection_box = {{-1.2, -3}, {1.2, 3}} -- TODO
fishing_boat.localised_description = { "entity-description.fishing-boat" }
fishing_boat.selection_priority = 60
fishing_boat.max_health = 300
fishing_boat.weight = 800
fishing_boat.braking_power = "100kW"
fishing_boat.effectivity = 0.15
fishing_boat.friction = 0.003
fishing_boat.terrain_friction_modifier = 0.2
fishing_boat.minable = { mining_time = 0.5, result = "fishing-boat" }
fishing_boat.rotation_speed = 0.008
fishing_boat.inventory_size = 10
fishing_boat.auto_sort_inventory = true -- will automatically stack spoilage
fishing_boat.energy_source = { type = "void" }
fishing_boat.guns = {}

fishing_boat.working_sound = { --TODO: check all sounds
    sound = {
        filename = "__fishing-boat__/sound/ship-sailing.ogg",
        volume = 0.7,
        min_speed = 0.6,
        max_speed = 0.9,
    },
    activate_sound = {
        filename = "__fishing-boat__/sound/boat-start.ogg",
        volume = 0.8,
        speed = 0.6,
    },
    deactivate_sound = {
        filename = "__fishing-boat__/sound/boat-stop.ogg",
        volume = 1,
        speed = 0.6,
    },
    match_speed_to_activity = true
}

fishing_boat.stop_trigger = {
    {
        type = "play-sound",
        sound = { filename = "__fishing-boat__/sound/boat-stop.ogg", volume = 0.5 }
    }
}

fishing_boat.animation = {
    layers = {
        {
            priority = "low",
            direction_count = 128,
            width = 1002,
            height = 1002,
            stripes = {
                {
                    filename = "__fishing-boat__/graphics/entity/fishing-boat/fishing-boat.png",
                    width_in_frames = 8,
                    height_in_frames = 8
                },
                {
                    filename = "__fishing-boat__/graphics/entity/fishing-boat/fishing-boat-2.png",
                    width_in_frames = 8,
                    height_in_frames = 8
                }
            },
            shift = util.by_pixel(0, 0),
            scale = 0.5,
            max_advance = 0.2
        }
    }
}

-- TODO: add fishing net, maybe underwater animation for it?
-- Water reflection: TODO: check cargo ship/ironclad function for it.

fishing_boat.light =
{
    type = "basic",
    intensity = 1,
    size = 20,
    minimum_darkness = 0.3,
    flicker_interval = 30,
    shift = {0, 0}, -- TODO: position to actual lantern on graphics
}

fishing_boat.turret_animation = nil
fishing_boat.light_animation = nil
fishing_boat.corpse = nil

data:extend({ fishing_boat })
