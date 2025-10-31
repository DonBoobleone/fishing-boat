--prototype/technology.lua
data:extend({
    {
        type = "technology",
        name = "fishing-boat",
        icon = "__fishing-boat__/graphics/technology/fishing-boat.png",
        icon_size = 256,
        effects =
        {
            { type = "unlock-recipe", recipe = "fishing-boat" }
        },
        prerequisites = {},
        research_trigger = {
            type = "mine-entity",
            entity = "fish"
        },
        order = "c-g-d"
    }
})
