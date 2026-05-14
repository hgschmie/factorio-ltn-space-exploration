------------------------------------------------------------------------
-- runtime code
------------------------------------------------------------------------

require('lib.init')

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')

--------------------------------------------------------------------------------
-- other mods remote API integration
--------------------------------------------------------------------------------

---@param event se.EventData.on_train_teleport_started
local function on_train_teleport_started(event)
    game.print(('[LSE] [%s] %s'):format('on_train_teleport_started', serpent.line(event)))
end

---@param event ltn.EventData.on_stops_updated
local function on_stops_updated(event)
    game.print(('[LSE] [%s] %s'):format('on_stops_updated', serpent.line(event)))
end

---@param event ltn.EventData.on_dispatcher_updated
local function on_dispatcher_updated(event)
    game.print(('[LSE] [%s] %s'):format('on_dispatcher_updated', serpent.line(event)))
end

--------------------------------------------------------------------------------
-- remote API
--------------------------------------------------------------------------------

local function remote_reset()
    game.print(('[LSE] [%s]'):format('remote_reset'))
end

local function remote_connect_elevator(elevator, network_id)
    game.print(('[LSE] [%s] %s %s'):format('on_train_teleport_started', serpent.line(elevator), tostring(network_id)))
end

local function remote_disconnect_elevator(elevator)
    game.print(('[LSE] [%s] %s'):format('on_train_teleport_started', serpent.line(elevator)))
end

--------------------------------------------------------------------------------
-- event handling
--------------------------------------------------------------------------------

---@param event EventData.on_object_destroyed
local function on_object_destroyed(event)
    game.print(('[LSE] [%s] %s'):format('on_train_teleport_started', serpent.line(event)))
end

---@param event EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(event)
    game.print(('[LSE] [%s] %s'):format('on_train_teleport_started', serpent.line(event)))
end

---@param event ConfigurationChangedData
local function on_configuration_changed(event)
    game.print(('[LSE] [%s] %s'):format('on_train_teleport_started', serpent.line(event)))
end

--------------------------------------------------------------------------------
-- event registration and management
--------------------------------------------------------------------------------

local function register_events()
    Event.register(remote.call('space-exploration', 'get_on_train_teleport_started_event'), on_train_teleport_started)
    Event.register(remote.call('logistic-train-network', 'on_stops_updated'), on_stops_updated)
    Event.register(remote.call('logistic-train-network', 'on_dispatcher_updated'), on_dispatcher_updated)

    -- Configuration changes (startup)
    Event.on_configuration_changed(on_configuration_changed)

    -- entity destroy (can't filter on that)
    Event.register(defines.events.on_object_destroyed, on_object_destroyed)

    Event.register(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
end

local function register_apis()
    Framework.remote_api.reset = remote_reset
    Framework.remote_api.connect_elevator = remote_connect_elevator
    Framework.remote_api.disconnect_elevator = remote_disconnect_elevator
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_init()
    This.Lse:init()
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

------------------------------------------------------------------------

---@diagnostic disable-next-line: undefined-field
Framework.post_runtime_stage()
