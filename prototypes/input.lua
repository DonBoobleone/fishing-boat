-- prototypes/input.lua
data:extend({
    {
        type = "custom-input",
        name = "enter-vehicle",
        enabled_while_spectating = true,
        order = "a",
        key_sequence = "",
        linked_game_control = "toggle-driving",
        -- consuming = "game-only" -- would prevent "vehicle is unaccesible message", but disables normal car behavior
        -- When Cargo-ships are enabled this bug doesn't exist
    }
})