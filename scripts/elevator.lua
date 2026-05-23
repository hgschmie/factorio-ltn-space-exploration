------------------------------------------------------------------------
-- Manages elevator connections
------------------------------------------------------------------------
assert(script)

local const = require('lib.constants')

local tools = require('scripts.tools')

local Position = require('stdlib.area.position')
local table = require('stdlib.utils.table')


---@class lse.SpaceElevator
local Elevator = {}

------------------------------------------------------------------------
-- Helper Code
------------------------------------------------------------------------

local ENTITY_MAP = {
    [const.lse_name] = 'connector',            -- connector entity
    ['se-space-elevator-train-stop'] = 'stop', -- space elevator stop (used for temp stops)
}

local REQUESTED_ENTITIES = table.keys(ENTITY_MAP)

---@param entity LuaEntity
---@return lse.ElevatorEnd?
local function create_elevator_end(entity)
    local found_entities = entity.surface.find_entities_filtered {
        area = Position.new(entity.position):expand_to_area(12),
        name = REQUESTED_ENTITIES,
    }

    local elevator_end = {
        elevator = entity
    }

    for _, found_entity in pairs(found_entities) do
        elevator_end[ENTITY_MAP[found_entity.name]] = found_entity
    end

    if not (tools.isValid(elevator_end.elevator) and tools.isValid(elevator_end.stop)) then return nil end

    -- if the elevator goes away, make this end go away as well
    script.register_on_object_destroyed(elevator_end.elevator)

    if not tools.isValid(elevator_end.connector) then
        elevator_end.connector = assert(elevator_end.elevator.surface.create_entity {
            name = const.lse_name,
            position = elevator_end.elevator.position,
            force = elevator_end.elevator.force,
            create_build_effect_smoke = false,
        })

        elevator_end.connector.operable = false
        elevator_end.connector.destructible = false

        script.register_on_object_destroyed(elevator_end.connector)
    end

    return elevator_end
end

---@param elevator lse.Elevator
---@param key string
local function clear_elevator_id(elevator, key)
    local id = elevator.ids[key]
    if not id then return end
    elevator.ids[id] = nil

    local lse_storage = This:storage()
    lse_storage.elevators[id] = nil
end

---@param elevator lse.Elevator
---@param key ('ground'|'orbit')
local function destroy_connector(elevator, key)
    local connector = elevator[key]
    if connector then
        if connector.connector then connector.connector.destroy() end

        clear_elevator_id(elevator, key)
        clear_elevator_id(elevator, 'se_' .. key)

        connector.connector = nil
        connector.elevator = nil
        connector.stop = nil
    end
end

---@param elevator lse.Elevator
---@return boolean can_connect
local function can_connect(elevator)
    if not elevator.config.enabled then return false end
    if not (elevator.state.powered and elevator.state.constructed) then return false end

    return true
end

------------------------------------------------------------------------
-- State Management
------------------------------------------------------------------------

---@param id integer
---@return lse.Elevator?
function Elevator:findElevator(id)
    local lse_storage = This:storage()
    return lse_storage.elevators[id]
end

------------------------------------------------------------------------
-- Create / Delete
------------------------------------------------------------------------

---@param elevator lse.Elevator
function Elevator:destroyElevator(elevator)
    elevator.config.enabled = false

    self:updateElevatorConnection(elevator)

    destroy_connector(elevator, 'ground')
    destroy_connector(elevator, 'orbit')
end

function Elevator:clearElevators()
    local lse_storage = This:storage()
    for _, elevator in pairs(lse_storage.elevators) do
        if elevator then
            self:destroyElevator(elevator)
        end
    end
end

---@param entity LuaEntity
---@return lse.Elevator? elevator
function Elevator:registerSpaceElevator(entity)
    if not tools.isValid(entity) then return nil end

    ---@type se.ElevatorInfo
    local elevator_info = remote.call('space-exploration', 'get_space_elevator_info', {
        unit_number = entity.unit_number,
    })

    local constructed = elevator_info and elevator_info.constructed or false
    local powered = elevator_info and elevator_info.powered or false

    local elevator = This.Elevator:findElevator(entity.unit_number)
    if elevator then
        self:updateElevatorState(elevator, constructed, powered)
        return elevator
    end

    ---@type se.ZoneType?
    local main_zone = remote.call('space-exploration', 'get_zone_from_surface_index', { surface_index = elevator_info.main.surface_index })
    if not main_zone then return nil end

    ---@type se.ZoneType?
    local other_zone = remote.call('space-exploration', 'get_zone_from_zone_index', { zone_index = elevator_info.opposite.surface_index })
    if not other_zone then return nil end

    local main_is_orbit = (main_zone.type == 'orbit')
    local other_is_orbit = (other_zone.type == 'orbit')

    --- One end must be a surface (planet, moon), other must be orbit
    if main_is_orbit == other_is_orbit then return nil end

    local main_end = create_elevator_end(elevator_info.main)
    if not main_end then return nil end

    local other_end = create_elevator_end(elevator_info.opposite)
    if not other_end then return nil end

    local ground = main_is_orbit and other_end or main_end
    local orbit = other_is_orbit and other_end or main_end


    elevator = {
        ids = {
            se_ground = ground.elevator.unit_number,
            ground = ground.connector.unit_number,

            se_orbit = orbit.elevator.unit_number,
            orbit = orbit.connector.unit_number,
        },
        config = {
            enabled = true,
            network_id = -1,
        },
        state = {
            connected = false,
            powered = powered,
            constructed = constructed,
        },
        ground = ground,
        orbit = orbit,
    }


    local lse_storage = This:storage()
    for _, id in pairs(elevator.ids) do
        lse_storage.elevators[id] = elevator
    end

    self:updateElevatorConnection(elevator)

    return elevator
end

--- Called by SE on_space_elevator_changed_state
---
---@param elevator lse.Elevator
---@param constructed boolean?
---@param powered boolean?
function Elevator:updateElevatorState(elevator, constructed, powered)
    elevator.state.constructed = constructed or false
    elevator.state.powered = powered or false

    self:updateElevatorConnection(elevator)
end

---@param elevator lse.Elevator
function Elevator:updateElevatorConnection(elevator)

    if (not can_connect(elevator)) or elevator.config.network_id == 0 then
        if not elevator.state.connected then return end

        tools.printmsg(2, function()
            return { const:locale('elevator_disconnected'), tools.gpsTextForEntity(elevator.ground.connector) }
        end, tools.isValid(elevator.ground.connector) and elevator.ground.connector.force or nil)

        remote.call('logistic-train-network', 'disconnect_surfaces', elevator.ground.connector, elevator.orbit.connector, elevator.config.network_id)
        elevator.state.network_id = nil
    else
        if elevator.state.connected and elevator.state.network_id == elevator.config.network_id then return end

        remote.call('logistic-train-network', 'connect_surfaces', elevator.ground.connector, elevator.orbit.connector, elevator.config.network_id)
        elevator.state.network_id = elevator.config.network_id

        tools.printmsg(2, function()
            local msg = elevator.config.network_id == -1 and const:locale('elevator_connected_all') or const:locale('elevator_connected')
            return { msg, tools.gpsTextForEntity(elevator.ground.connector), tools.networkList(elevator.config.network_id) }
        end, tools.isValid(elevator.ground.connector) and elevator.ground.connector.force or nil)
    end
end

return Elevator
