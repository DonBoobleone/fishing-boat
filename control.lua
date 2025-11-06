-- control.lua
require("scripts.enter-exit")
require("scripts.fishing")

if settings.startup["thanks-for-all-the-fish"].value then
    require("scripts.breeding-fish")
end