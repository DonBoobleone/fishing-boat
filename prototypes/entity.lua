--prototype/entity.lua
local fishing_boat = table.deepcopy(data.raw["car"]["car"])

fishing_boat.name = "fishing-boat"
fishing_boat.icon = "__fishing-boat__/graphics/icons/fishing-boat.png"
fishing_boat.icon_size = 64
fishing_boat.collision_mask = { layers = { ground_tile = true, train = true, object = true } }
--TODO: check if changed to collision_mask = {layers = {item = true, meltable = true, object = true, player = true, ground_tile = true, is_object = true, is_lower_object = true}}
fishing_boat.collision_box = { { -0.9, -1.1 }, { 0.9, 1.3 } }
fishing_boat.selection_box = { { -0.9, -1.1 }, { 0.9, 1.3 } }
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

fishing_boat.working_sound = {
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
            width = 512,
            height = 512,
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
        },
        {
            priority = "low",
            direction_count = 128,
            width = 512,
            height = 512,
            stripes = {
                {
                    filename = "__fishing-boat__/graphics/entity/fishing-boat/fishing-boat-shadow.png",
                    width_in_frames = 8,
                    height_in_frames = 8
                },
                {
                    filename = "__fishing-boat__/graphics/entity/fishing-boat/fishing-boat-2-shadow.png",
                    width_in_frames = 8,
                    height_in_frames = 8
                }
            },
            shift = util.by_pixel(0, 0),
            scale = 0.5,
            max_advance = 0.2,
            draw_as_shadow = true
        }
    }
}

fishing_boat.water_reflection = {
    pictures = {
        filename = "__fishing-boat__/graphics/entity/fishing-boat/fishing-boat-reflection-sheet.png",
        line_length = 8,
        width = 276,
        height = 276,
        frame_count = 128,
        variation_count = 128,
        shift = util.by_pixel(0, 36),
        scale = 1
    },
    rotate = false,
    orientation_to_variation = true
}

-- TODO ideas
-- TODO: Add color mask to the sails or cabin
-- TODO: add smoke to make waves on water like cargo ships

-- Positioned to match lantern graphics in triangle formation: one front, two rear sides
fishing_boat.light = {
    {
        type = "basic",
        intensity = 1,
        size = 10,
        minimum_darkness = 0.31,
        flicker_interval = 15,
        shift = {0, -2.0} -- front
    },
    {
        type = "basic",
        intensity = 1,
        size = 7,
        minimum_darkness = 0.35,
        flicker_interval = 13,
        shift = {-1.3, 1.5} -- rear left
    },
    {
        type = "basic",
        intensity = 1,
        size = 7,
        minimum_darkness = 0.35,
        flicker_interval = 11,
        shift = {1.3, 1.5} -- rear right
    }
}

fishing_boat.turret_animation = {
    layers = {
        {
            animation_speed = 1,
            direction_count = 1,
            frame_count = 1,
            height = 1,
            width = 1,
            max_advance = 0.2,
            stripes = {
                {
                    filename = "__core__/graphics/empty.png",
                    height_in_frames = 1,
                    width_in_frames = 1
                }
            }
        }
    }
}
fishing_boat.light_animation = nil
fishing_boat.corpse = nil
fishing_boat.create_ghost_on_death = false
fishing_boat.allow_remote_driving =true
-- fishing_boat.minimap_representation = {} -- TODO: fishing net icon?
-- fishing_boat.dying_explosion = nil -- TODO repalce with wood sprinkels?

data:extend({ fishing_boat })