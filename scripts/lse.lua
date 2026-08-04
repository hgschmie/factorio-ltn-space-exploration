------------------------------------------------------------------------
-- Manages trains stops
------------------------------------------------------------------------
assert(script)

local const = require('lib.constants')

local tools = require('scripts.tools')

local table = require('stdlib.utils.table')

---@class lse.Lse
local Lse = {}

------------------------------------------------------------------------
-- Cross-Surface delivery management
------------------------------------------------------------------------

---@param delivery ltn.Delivery
---@param callback fun(delivery: ltn.Delivery, from_stop: LuaEntity, to_stop: LuaEntity)
local function process_delivery(delivery, callback)
    if not (delivery and delivery.surface_connections and next(delivery.surface_connections)) then return end

    if not tools.isValid(delivery.train) then return end

    local lse_storage = This:storage()
    local from_stop = tools.isValid(lse_storage.known_stops[delivery.from_id])
    local to_stop = tools.isValid(lse_storage.known_stops[delivery.to_id])

    if not (from_stop and to_stop) then return end

    local loco = tools.getMainLocomotive(delivery.train)
    -- train without a locomotive or intra-surface delivery
    if not loco or (loco.surface == from_stop.surface and loco.surface == to_stop.surface) then return end

    Framework.logger.print(3, function()
        return { const:locale('cross_surface_delivery'), tools.richTextForTrain(delivery.train), #delivery.surface_connections }
    end, loco.force)

    callback(delivery, from_stop, to_stop)
end

---@param number1 integer
---@param number2 integer
---@return string
local function sort_pair(number1, number2)
    return (number1 < number2) and (number1 .. '|' .. number2) or (number2 .. '|' .. number1)
end

---@param surface_connection ltn.SurfaceConnection
---@param current_surface_index integer
---@return LuaEntity? stop the elevator stop on the current surface, or nil if unavailable
local function get_elevator_stop_for_surface(surface_connection, current_surface_index)
    if not tools.isValid(surface_connection.entity1) then return nil end

    local elevator = This.Elevator:findElevator(surface_connection.entity1.unit_number)
    if not elevator then return nil end

    if not (elevator.state.connected and elevator.state.constructed and elevator.state.powered) then return nil end

    local ground_stop = tools.isValid(elevator.ground.stop) and elevator.ground.stop or nil
    local orbit_stop = tools.isValid(elevator.orbit.stop) and elevator.orbit.stop or nil
    if not (ground_stop and orbit_stop) then return nil end

    local entity = (ground_stop.surface_index == current_surface_index) and ground_stop or orbit_stop
    if entity.surface_index ~= current_surface_index then return nil end

    return entity
end

---@param train LuaTrain
---@param current_stop LuaEntity?
---@param current_schedule_index integer
---@param current_surface_index integer
---@param surface_connections ltn.SurfaceConnection[]
---@return boolean found_stop
local function add_temp_stop(train, current_stop, current_schedule_index, current_surface_index, surface_connections)
    local possible_stops = {}
    for _, surface_connection in pairs(surface_connections) do
        local entity = get_elevator_stop_for_surface(surface_connection, current_surface_index)
        if entity then
            table.insert(possible_stops, entity)
        end
    end

    if #possible_stops == 0 then return false end

    local result

    if current_stop then
        result = game.train_manager.request_train_path {
            type = 'path',
            goals = possible_stops,
            starts = {
                {
                    rail = current_stop.connected_rail,
                    direction = defines.rail_direction.back,
                },
                {
                    rail = current_stop.connected_rail,
                    direction = defines.rail_direction.front,
                },
            },
        }
    else
        result = game.train_manager.request_train_path {
            type = 'path',
            goals = possible_stops,
            train = train,
        }
    end

    if not result.found_path then return false end

    local schedule = assert(train.get_schedule())

    if Framework.settings:runtime_setting(const.settings_names.use_elevator_clearance) then
        schedule.add_record {
            station = Framework.settings:runtime_setting(const.settings_names.elevator_clearance_name),
            temporary = true,
            index = { schedule_index = current_schedule_index },
        }
    end

    schedule.add_record {
        station = possible_stops[result.goal_index].backer_name,
        temporary = true,
        index = { schedule_index = current_schedule_index },
    }

    if schedule.current > current_schedule_index then
        schedule.go_to_station(current_schedule_index)
    end

    return true
end

---@param delivery ltn.Delivery
---@param provider_stop LuaEntity
---@param requester_stop LuaEntity
local function add_space_elevator_stops(delivery, provider_stop, requester_stop)
    local train = delivery.train

    local surface_connections = {}

    for _, surface_connection in pairs(delivery.surface_connections) do
        local entity_key = sort_pair(surface_connection.entity1.surface_index, surface_connection.entity2.surface_index)
        surface_connections[entity_key] = surface_connections[entity_key] or {}
        table.insert(surface_connections[entity_key], surface_connection)
    end

    -- assumption: The train is about to leave a depot. So the train surface is the depot surface
    local train_surface_index = assert(train.carriages[1]).surface_index
    local provider_surface_index = provider_stop.surface_index
    local requester_surface_index = requester_stop.surface_index

    local provider_schedule_index, _, provider_stop_type = remote.call('logistic-train-network', 'get_next_logistic_stop', train)
    if provider_stop_type ~= 'provider' then
        Framework.logger.log(1, 'add_space_elevator_stops', 'could not find provider stop for train %d', function() return train.id end)
        return
    end

    local requester_schedule_index, _, requester_stop_type = remote.call('logistic-train-network', 'get_next_logistic_stop', train, provider_schedule_index + 1)
    if requester_stop_type ~= 'requester' then
        Framework.logger.log(1, 'add_space_elevator_stops', 'could not find requester stop for train %d', function() return train.id end)
        return
    end

    -- go in reverse order, schedule index does not change.

    -- return from requester to depot
    if requester_surface_index ~= train_surface_index then
        local key = sort_pair(requester_surface_index, train_surface_index)
        if surface_connections[key] then
            if not add_temp_stop(train, requester_stop, requester_schedule_index + 1, requester_surface_index, surface_connections[key]) then
                Framework.logger.print(1, function()
                    return ('Could not add a elevator stop to move from %s to %s'):format(tools.gpsTextForEntity(requester_stop), game.surfaces[train_surface_index].name)
                end)
            end
        end
    end

    -- transition between provider and requester
    if provider_surface_index ~= requester_surface_index then
        local key = sort_pair(provider_surface_index, requester_surface_index)
        if surface_connections[key] then
            if not add_temp_stop(train, provider_stop, provider_schedule_index + 1, provider_surface_index, surface_connections[key]) then
                Framework.logger.print(1, function()
                    return ('Could not add a elevator stop to move from %s to %s'):format(tools.gpsTextForEntity(provider_stop), tools.gpsTextForEntity(requester_stop))
                end)
            end
        end
    end

    -- transition between depot and provider
    if train_surface_index ~= provider_surface_index then
        local key = sort_pair(train_surface_index, provider_surface_index)
        if surface_connections[key] then
            if not add_temp_stop(train, nil, provider_schedule_index, train_surface_index, surface_connections[key]) then
                Framework.logger.print(1, function()
                    return ('Could not add a elevator stop to move from %s to %s'):format(game.surfaces[train_surface_index].name, tools.gpsTextForEntity(provider_stop))
                end)
            end
        end
    end
end

------------------------------------------------------------------------
-- LTN Remote interface
------------------------------------------------------------------------

---@param old_train_id integer
---@param new_train LuaTrain
function Lse:startElevatorTravel(old_train_id, new_train)
    remote.call('logistic-train-network', 'reassign_delivery', old_train_id, new_train)
end

---@param old_train_id integer
---@param new_train LuaTrain
function Lse:endElevatorTravel(old_train_id, new_train)
    local insert_index = remote.call('logistic-train-network', 'get_or_create_next_temp_stop', new_train)

    if insert_index ~= nil then
        local schedule = new_train.get_schedule()
        if schedule.current > insert_index then
            schedule.go_to_station(insert_index)
        end
    end

    Framework.logger.print(3, function()
        return { const:locale('train_arrival'), new_train.id, tools.getTrainName(new_train) }
    end)
end

---@param stops table<integer, ltn.TrainStop>
function Lse:resyncKnownStops(stops)
    local lse_storage = This:storage()

    lse_storage.known_stops = {}
    for id, train_stop in pairs(stops) do
        if tools.isValid(train_stop.entity) then
            lse_storage.known_stops[id] = train_stop.entity
        end
    end
end

---@param new_deliveries number[]
---@param deliveries table<number, ltn.Delivery>
function Lse:addNewDeliveries(new_deliveries, deliveries)
    for _, train_id in pairs(new_deliveries) do
        process_delivery(deliveries[train_id], add_space_elevator_stops)
    end
end

return Lse
