-- prototypes/input.lua
data:extend({
    {
        type = "custom-input",
        name = "enter-vehicle",
        enabled_while_spectating = true,
        order = "a",
        key_sequence = "",
        linked_game_control = "toggle-driving",
        --consuming = "game-only" -- would prevent vehicle is unaccesible message, but disables normal car behavior
        -- does work when cargo ships are enabled
    }
})