------------------------------------------------------------------------
-- runtime code
------------------------------------------------------------------------

This, Framework = require('lib.init')()

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')

local Matchers = require('framework.matchers')

local tools = require('scripts.tools')

--------------------------------------------------------------------------------
-- Remote API
--------------------------------------------------------------------------------

local function remote_reset()
    This.Elevator:clearElevators()
end

---@param entity LuaEntity
---@param network_id integer
local function remote_connect_elevator(entity, network_id)
    if not tools.isValid(entity) then return end

    local elevator = This.Elevator:findElevator(entity.unit_number)
    if not elevator then return end

    elevator.config.network_id = network_id
    elevator.config.enabled = true

    This.Elevator:updateElevatorConnection(elevator)
end

---@param entity LuaEntity
local function remote_disconnect_elevator(entity)
    if not tools.isValid(entity) then return end

    local elevator = This.Elevator:findElevator(entity.unit_number)
    if not elevator then return end

    elevator.config.enabled = false

    This.Elevator:updateElevatorConnection(elevator)
end

--------------------------------------------------------------------------------
-- event handling
--------------------------------------------------------------------------------

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.on_space_platform_built_entity | EventData.script_raised_revive | EventData.script_raised_built
local function on_se_created(event)
    local entity = event and event.entity
    if not tools.isValid(entity) then return end

    This.Elevator:registerSpaceElevator(entity)
end

---@param event EventData.on_object_destroyed
local function on_object_destroyed(event)
    if not (event and event.type == defines.target_type.entity) then return end

    -- either a connector or the elevator itself was destroyed.
    -- disconnect the elevator
    local elevator = This.Elevator:findElevator(event.useful_id)
    if not elevator then return end
    This.Elevator:destroyElevator(elevator)
end

local function on_configuration_changed()
    This:init()
    This.Elevator:removeStaleElevators()

    for _, surface in pairs(game.surfaces) do
        local space_elevators = surface.find_entities_filtered {
            name = 'se-space-elevator',
        }

        for _, space_elevator in pairs(space_elevators) do
            if tools.isValid(space_elevator) then
                This.Elevator:registerSpaceElevator(space_elevator)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- event registration and management
--------------------------------------------------------------------------------

local function register_events()

    -- Configuration changes (startup)
    Event.on_configuration_changed(on_configuration_changed)

    -- entity destroy (can't filter on that)
    Event.register(defines.events.on_object_destroyed, on_object_destroyed)

    Event.register(Matchers.CREATION_EVENTS, on_se_created, Matchers:matchEventEntityName('se-space-elevator'))
end

local function register_apis()
    Framework.ExportedApis.reset = remote_reset
    Framework.ExportedApis.connect_elevator = remote_connect_elevator
    Framework.ExportedApis.disconnect_elevator = remote_disconnect_elevator
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_init()
    This:init()

    register_events()
    register_apis()
end

local function on_load()
    register_events()
    register_apis()
end

-- setup player management
Player.register_events(true)

Event.on_init(on_init)
Event.on_load(on_load)

---@diagnostic disable-next-line: undefined-field
Framework.post_runtime_stage()
