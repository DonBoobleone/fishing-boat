-- settings.lua
data:extend({
    {
        type = "bool-setting",
        name = "thanks-for-all-the-fish",
        setting_type = "startup",
        default_value = true,
        localised_description = {"If enabled fish will breed in the wild on their own"}
    },
    {
        type = "int-setting",
        name = "breeding-limit",
        setting_type = "startup",
        default_value = 256,
        minimum_value = 16,
        maximum_value = 512,
        localised_description = {"Max fish in a chunk full of water."}
    },
    {
        type = "int-setting",
        name = "breeding-cycle",
        setting_type = "startup",
        default_value = 60,
        minimum_value = 30,
        maximum_value = 600,
        localised_description = {"60 tick means every second 1 random chunk has a chance to breed."}
    }
})