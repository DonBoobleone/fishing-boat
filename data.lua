-- data.lua
require("prototypes.entity")
require("prototypes.item")
require("prototypes.recipe")
require("prototypes.technology")

if not mods["cargo-ships"] then
    require("prototypes.input")
end