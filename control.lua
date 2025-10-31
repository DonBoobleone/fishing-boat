-- control.lua
-- This code is adapted from the Cargo Ships mod[](https://mods.factorio.com/mod/cargo-ships) by schnurrebutz and rudegrass, licensed under GPLv3.
-- Original code from AAI Vehicles: Ironclad by Earendel[](https://mods.factorio.com/mod/aai-vehicles-ironclad).

local math2d = require("math2d")

local enter_ship_distance = 5

local enter_ship_entities = {["fishing-boat"] = true}

-- Shared functions
local function vehicle_exit(player, position)
    local character = player.character
    if character.vehicle.get_driver() == character then
        character.vehicle.set_driver(nil)
    else
        character.vehicle.set_passenger(nil)
    end
    character.teleport(position)
end

local function vehicle_enter(player, vehicle)
    local character = player.character
    if not vehicle.get_driver() then
        vehicle.set_driver(character)
    elseif vehicle.type == "car" and not vehicle.get_passenger() then
        vehicle.set_passenger(character)
    end
end

local function disable_this_tick(player_index)
    storage.fishing_boat_disable_this_tick = storage.fishing_boat_disable_this_tick or {}
    storage.fishing_boat_disable_this_tick[player_index] = game.tick
end

-- Entering/exiting logic always active, but isolated to fishing-boat
local function on_enter_vehicle_keypress(event)
    local player = game.players[event.player_index]
    local character = player.character
    if not character then return end
    if player.controller_type == defines.controllers.remote then return end

    storage.fishing_boat_disable_this_tick = storage.fishing_boat_disable_this_tick or {}
    if storage.fishing_boat_disable_this_tick[player.index] and storage.fishing_boat_disable_this_tick[player.index] == event.tick then
        return
    end

    storage.fishing_boat_driving_state_locks = storage.fishing_boat_driving_state_locks or {}
    if character.vehicle then
        if enter_ship_entities[character.vehicle.name] then
            local position = character.surface.find_non_colliding_position(character.name, character.position, enter_ship_distance, 0.25, true)
            if position then
                storage.fishing_boat_driving_state_locks[player.index] = {valid_time = game.tick + 1, position = position}
                vehicle_exit(player, position)
            end
        end
    else
        local enter_vehicle_distance = character.prototype.enter_vehicle_distance + 1.5
        local vehicles = character.surface.find_entities_filtered{
            type = {"car", "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon", "spider-vehicle"},
            position = character.position,
            radius = math.max(enter_ship_distance, enter_vehicle_distance)
        }
        local closest_vehicle
        local closest_distance = 1000
        for _, vehicle in pairs(vehicles) do
            local distance = math2d.position.distance(vehicle.position, character.position)
            if distance < closest_distance then
                if distance < enter_vehicle_distance or (enter_ship_entities[vehicle.name] and distance < enter_ship_distance) then
                    closest_vehicle = vehicle
                    closest_distance = distance
                end
            end
        end
        if closest_vehicle and enter_ship_entities[closest_vehicle.name] then
            storage.fishing_boat_driving_state_locks[player.index] = {valid_time = game.tick + 1, vehicle = closest_vehicle}
            vehicle_enter(player, closest_vehicle)
        end
    end
end

local function on_player_driving_changed_state(event)
    local player = game.players[event.player_index]
    local character = player.character
    if not character then return end

    storage.fishing_boat_disable_this_tick = storage.fishing_boat_disable_this_tick or {}
    if storage.fishing_boat_disable_this_tick[player.index] and storage.fishing_boat_disable_this_tick[player.index] == event.tick then
        return
    end

    storage.fishing_boat_driving_state_locks = storage.fishing_boat_driving_state_locks or {}
    if storage.fishing_boat_driving_state_locks[player.index] then
        if storage.fishing_boat_driving_state_locks[player.index].valid_time >= game.tick then
            local lock = storage.fishing_boat_driving_state_locks[player.index]
            if lock.vehicle then
                if not lock.vehicle.valid then
                    storage.fishing_boat_driving_state_locks[player.index] = nil
                else
                    if not character.vehicle then
                        vehicle_enter(player, lock.vehicle)
                    elseif character.vehicle ~= lock.vehicle then
                        if character.vehicle.get_driver() == character then
                            character.vehicle.set_driver(nil)
                        else
                            character.vehicle.set_passenger(nil)
                        end
                        vehicle_enter(player, lock.vehicle)
                    end
                end
            else
                if character.vehicle then
                    vehicle_exit(player, lock.position)
                end
            end
        else
            storage.fishing_boat_driving_state_locks[player.index] = nil
        end
    end
end

script.on_event("enter-vehicle", on_enter_vehicle_keypress)
script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)

-- Fishing mechanics
-- TODO: Check for max inventory full and stop fishing or stop destroying fish
-- TODO: Register/unregister/track built, destroyed or mined boats
-- TODO: Every nth tick (30) check for entities named fish in 4 tile radius
-- TODO: For every fish found, if inventory of ship is not full, add 5 raw-fish to boat trunk, destroy the fish entity; fill up to max, catch if space
require("fishing")