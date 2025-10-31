--prototype/recipe.lua
data:extend({
    {
        type = "recipe",
        name = "fishing-boat",
        icon = "__fishing-boat__/graphics/icons/fishing-boat.png",
        icon_size = 64,
        category = "crafting",
        subgroup = "transport",
        order = "b[personal-transport]-f[fishing-boat]",
        enabled = false,
        auto_recycle = false,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "wood", amount = 20 }
        },
        always_show_made_in = false,
        allow_productivity = false,
        results = {{ type = "item", name = "fishing-boat", amount = 1 }}
    }
})
