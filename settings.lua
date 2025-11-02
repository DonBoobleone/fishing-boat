-- settings.lua
data:extend({
    {
        type = "bool-setting",
        name = "thanks-for-all-the-fish",
        setting_type = "startup",
        default_value = true,
        order = "a",
        localised_description = {"", "If enabled fish will breed in the wild on their own"}
    },
    {
        type = "int-setting",
        name = "breeding-limit",
        setting_type = "startup",
        default_value = 256,
        minimum_value = 16,
        maximum_value = 512,
        order = "b",
        localised_description = {"", "Max fish in a chunk full of water. Only applies if 'Thanks for all the fish' is enabled."}
    },
    {
        type = "int-setting",
        name = "breeding-cycle",
        setting_type = "startup",
        default_value = 60,
        minimum_value = 30,
        maximum_value = 600,
        order = "c",
        localised_description = {"", "In ticks, 1 random chunk at a time. Only applies if 'Thanks for all the fish' is enabled."}
    }
})