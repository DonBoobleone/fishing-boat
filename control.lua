-- control.lua
require("scripts.enter-exit")

if script.active_mods["aai-programmable-vehicles"] then
    require("scripts.fishing-aai-compa")
else
    require("scripts.fishing")
end

if settings.startup["thanks-for-all-the-fish"].value then
    require("scripts.breeding-fish")
end
