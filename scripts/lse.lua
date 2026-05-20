------------------------------------------------------------------------
-- Management code
------------------------------------------------------------------------
assert(script)

local const = require('lib.constants')

local tools = require('scripts.tools')

local Position = require('stdlib.area.position')
local table = require('stdlib.utils.table')

---@class lse.Lse
local Lse = {}

------------------------------------------------------------------------
-- helpers
------------------------------------------------------------------------

---@param entity (LuaEntity|LuaTrain)?
---@return (LuaEntity|LuaTrain)? entity
local function is_valid(entity)
    if not (entity and entity.valid) then return nil end
    return entity
end

------------------------------------------------------------------------
-- create/delete
------------------------------------------------------------------------

---@param id integer
---@return lse.Elevator?
function Lse:findElevator(id)
    local lse_storage = This:storage()
    return lse_storage.elevators[id]
end

local ENTITY_MAP = {
    [const.lse_name] = 'connector',            -- connector entity
    ['se-space-elevator-train-stop'] = 'stop', -- space elevator stop (used for temp stops)
    ['se-space-elevator'] = 'elevator',        -- space elevator
}

local REQUESTED_ENTITIES = table.keys(ENTITY_MAP)

---@param zone se.ZoneType
---@return boolean? is_orbit
---@return integer? connected_index
local function is_orbit(zone)
    if not zone then return nil, nil end

    if (zone.type == 'planet' or zone.type == 'moon') then
        return false, zone.orbit_index
    elseif zone.type == 'orbit' then
        return true, zone.parent_index
    end
    return nil, nil
end

---@param entity LuaEntity
---@param surface_index integer?
---@return lse.ElevatorEnd?
local function create_elevator_end(entity, surface_index)
    local surface = surface_index and game.surfaces[surface_index] or entity.surface

    local found_entities = surface.find_entities_filtered {
        area = Position.new(entity.position):expand_to_area(12),
        name = REQUESTED_ENTITIES,
    }

    local elevator_end = {}
    for _, found_entity in pairs(found_entities) do
        elevator_end[ENTITY_MAP[found_entity.name]] = found_entity
    end

    if not (is_valid(elevator_end.elevator) and is_valid(elevator_end.stop)) then return nil end

    -- if the elevator goes away, make this go away as well
    script.register_on_object_destroyed(elevator_end.elevator)

    return elevator_end
end

---@param entity LuaEntity
---@return lse.Elevator? elevator
function Lse:findOrCreateElevator(entity)
    if not (entity and entity.valid) then return nil end

    local elevator = self:findElevator(entity.unit_number)
    if elevator then return elevator end

    ---@type se.ZoneType?
    local this_zone = remote.call('space-exploration', 'get_zone_from_surface_index', { surface_index = entity.surface_index })
    if not this_zone then return nil end

    local this_is_orbit, other_zone_index = is_orbit(this_zone)
    if not other_zone_index then return nil end

    ---@type se.ZoneType?
    local other_zone = remote.call('space-exploration', 'get_zone_from_zone_index', { zone_index = other_zone_index })
    if not other_zone then return nil end

    local other_is_orbit = is_orbit(other_zone)

    --- One end must be a surface (planet, moon), other must be orbit
    if this_is_orbit == other_is_orbit then return nil end

    local this_end = create_elevator_end(entity)
    if not this_end then return nil end

    local other_end = create_elevator_end(entity, other_zone.surface_index)
    if not other_end then return nil end

    elevator = {
        ids = {
        },
        config = {
            enabled = false,
        },
        state = {
            connected = false,
        },
        ground = this_is_orbit and other_end or this_end,
        orbit = other_is_orbit and other_end or this_end,
    }

    elevator.ids.se_ground = elevator.ground.elevator.unit_number
    elevator.ids.se_orbit = elevator.orbit.elevator.unit_number

    if is_valid(elevator.ground.connector) then elevator.ids.ground = elevator.ground.connector.unit_number end
    if is_valid(elevator.orbit.connector) then elevator.ids.orbit = elevator.orbit.connector.unit_number end

    if elevator.ids.ground and elevator.ids.orbit then
        elevator.config = {
            enabled = true,
            network_id = -1,
        }
    end

    local lse_storage = This:storage()
    for _, id in pairs(elevator.ids) do
        lse_storage.elevators[id] = elevator
    end

    return elevator
end

---@param elevator lse.Elevator
---@param key ('ground'|'orbit')
local function destroy_connector(elevator, key)
    local lse_storage = This:storage()

    local connector = elevator[key]
    if connector then
        if connector.connector then connector.connector.destroy() end

        if elevator.ids[key] then
            lse_storage.elevators[elevator.ids[key]] = nil
            elevator.ids[key] = nil
        end

        if ((not connector.elevator) or connector.elevator.valid) then return end

        -- clean up elevator if elevator was deleted
        connector.elevator = nil
        local se_key = 'se_' .. key
        lse_storage.elevators[elevator.ids[se_key]] = nil
        elevator.ids[se_key] = nil
    end
end

---@param elevator lse.Elevator?
function Lse:disconnect(elevator)
    if not elevator then return end

    destroy_connector(elevator, 'ground')
    destroy_connector(elevator, 'orbit')

    elevator.state.connected = false
end

---@param connector lse.ElevatorEnd
---@return integer connector_id
local function connect_elevator_end(connector)
    if (connector.connector and connector.connector.valid) then return connector.connector.unit_number end

    connector.connector = assert(connector.elevator.surface.create_entity {
        name = const.lse_name,
        position = connector.elevator.position,
        force = connector.elevator.force,
        create_build_effect_smoke = false,
    })

    connector.connector.operable = false
    connector.connector.destructible = false

    script.register_on_object_destroyed(connector.connector)

    return connector.connector.unit_number
end

------------------------------------------------------------------------
-- Cross-Surface delivery management
------------------------------------------------------------------------

---@param delivery ltn.Delivery
---@param callback fun(delivery: ltn.Delivery, from_stop: LuaEntity, to_stop: LuaEntity)
local function process_delivery(delivery, callback)
    local lse_storage = This:storage()

    if not (delivery and delivery.surface_connections and next(delivery.surface_connections)) then return end

    if not (delivery.train and delivery.train.valid) then return end

    local from_stop = is_valid(lse_storage.known_stops[delivery.from_id])
    local to_stop = is_valid(lse_storage.known_stops[delivery.to_id])

    if not (from_stop and to_stop) then return end

    local loco = tools.getMainLocomotive(delivery.train)
    -- train without a locomotive or intra-surface delivery
    if not loco or (loco.surface == from_stop.surface and loco.surface == to_stop.surface) then return end

    tools.printmsg(3, function()
        return { const:locale('cross-surface-delivery'), tools.richTextForTrain(delivery.train), #delivery.surface_connections }
    end, loco.force)

    callback(delivery, from_stop, to_stop)
end

------------------------------------------------------------------------
-- LTN Remote interface
------------------------------------------------------------------------

---@param stops table<integer, ltn.TrainStop>
function Lse:resyncKnownStops(stops)
    local lse_storage = This:storage()

    lse_storage.known_stops = {}
    for id, train_stop in pairs(stops) do
        if train_stop.entity.valid then
            lse_storage.known_stops[id] = train_stop.entity
        end
    end
end

---@param new_deliveries number[]
---@param deliveries table<number, ltn.Delivery>
function Lse:addNewDeliveries(new_deliveries, deliveries)
    for _, train_id in pairs(new_deliveries) do
        process_delivery(deliveries[train_id], function(delivery, from_stop, to_stop)
        end)
    end
end

------------------------------------------------------------------------
-- Remote API
------------------------------------------------------------------------

function Lse:clearElevators()
    local lse_storage = This:storage()
    for _, elevator in pairs(lse_storage.elevators) do
        self:disconnect(elevator)
    end
end

---@param elevator lse.Elevator
function Lse:connectElevator(elevator)
    if not elevator.config.enabled or elevator.state.connected then return end

    local lse_storage = This:storage()

    local ground_id = connect_elevator_end(elevator.ground)
    elevator.ids['ground'] = ground_id
    lse_storage.elevators[ground_id] = elevator

    local orbit_id = connect_elevator_end(elevator.orbit)
    elevator.ids['orbit'] = orbit_id
    lse_storage.elevators[orbit_id] = elevator

    self:updateElevator(elevator)
end

---@param elevator lse.Elevator
function Lse:disconnectElevator(elevator)
    if elevator.config.enabled then return end

    self:disconnect(elevator)

    self:updateElevator(elevator)
end

function Lse:updateElevator(elevator)
    if (not elevator.config.enabled) or (elevator.config.network_id == 0) then
        remote.call('logistic-train-network', 'disconnect_surfaces', elevator.ground.connector, elevator.orbit.connector, elevator.config.network_id)
        elevator.state.connected = false
        elevator.state.network_id = nil

        tools.printmsg(1, function()
            return { const:locale('elevator_disconnected'), tools.gpsTextForEntity(elevator.ground.elevator) }
        end, elevator.ground.elevator.force)
    else
        if elevator.state.network_id ~= elevator.config.network_id then
            remote.call('logistic-train-network', 'connect_surfaces', elevator.ground.connector, elevator.orbit.connector, elevator.config.network_id)
            elevator.state.connected = true
            elevator.state.network_id = elevator.config.network_id

            tools.printmsg(1, function()
                local msg = elevator.config.network_id == -1 and const:locale('elevator_connected_all') or const:locale('elevator_connected')
                return { msg, tools.gpsTextForEntity(elevator.ground.elevator), tools.networkList(elevator.config.network_id) }
            end, elevator.ground.elevator.force)
        end
    end
end

return Lse
