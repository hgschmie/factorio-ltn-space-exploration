------------------------------------------------------------------------
-- GUI code
------------------------------------------------------------------------
assert(script)

local util = require('util')

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')

local Matchers = require('framework.matchers')

local const = require('lib.constants')

local tools = require('scripts.tools')

---@class lse.Gui
local Gui = {
    AUX_GUI_NAME = 'ltn-se-space-elevator',
}

local function get_gui_event_definition()
    ---@type framework.gui_manager.event_definition
    return {
        events = {
            onToggleConnection = Gui.onToggleConnection,
            onConfirmNetworkId = Gui.onConfirmNetworkId,
        },
        callback = Gui.guiUpdater,
    }
end

---@param gui framework.gui
---@return framework.gui.element_definition? ui
function Gui.getUi(gui)
    local gui_events = gui.gui_events

    local elevator = This.Elevator:findElevator(gui.entity_id)
    local elevator_enabled = elevator and elevator.config.enabled or false
    local elevator_working = (elevator and elevator.state.constructed and elevator.state.powered) or false

    return {
        type = 'frame',
        name = 'aux_gui_root',
        direction = 'vertical',
        style_mods = {
            width = 600,
        },
        anchor = {
            gui = defines.relative_gui_type.assembling_machine_gui,
            position = defines.relative_gui_position.top,
        },
        children = {
            { -- Title Bar
                type = 'flow',
                style = 'frame_header_flow',
                children = {
                    {
                        type = 'label',
                        style = 'frame_title',
                        caption = { const:locale('logistic_train_network') },
                    },
                    {
                        type = 'empty-widget',
                        style = 'framework_titlebar_drag_handle',
                    },
                },
            }, -- Title Bar End
            {
                type = 'frame',
                style = 'entity_frame',
                children = {
                    {
                        type = 'flow',
                        direction = 'vertical',
                        style = 'two_module_spacing_vertical_flow',
                        children = {
                            {
                                type = 'flow',
                                direction = 'horizontal',
                                style_mods = {
                                    vertical_align = 'center',
                                },
                                children = {
                                    {
                                        type = 'checkbox',
                                        caption = { '', { const:locale('connect') }, ' [img=info]' },
                                        tooltip = { const:locale('connect_tooltip') },
                                        name = 'connect',
                                        state = elevator_enabled,
                                        enabled = elevator_working,
                                        handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onToggleConnection },
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = {
                                            horizontally_stretchable = true,
                                            horizontally_squashable = true,
                                        },
                                    },
                                    {
                                        type = 'label',
                                        caption = '[img=virtual-signal/ltn-network-id]',
                                        tooltip = { const:locale('network_id_tooltip') },
                                    },
                                    {
                                        type = 'textfield',
                                        name = 'network_id',
                                        numeric = true,
                                        allow_negative = true,
                                        lose_focus_on_confirm = true,
                                        text = elevator and tostring(elevator.config.network_id) or "0",
                                        handler = { [defines.events.on_gui_confirmed] = gui_events.onConfirmNetworkId },
                                        enabled = elevator_enabled and elevator_working
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

--------------------------------------------------------------------------------
-- Callbacks
--------------------------------------------------------------------------------

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onToggleConnection(event, gui)
    local elevator = This.Elevator:findElevator(gui.entity_id)
    if not elevator then return false end
    if not (elevator.state.powered and elevator.state.constructed) then return end

    local element = event.element
    elevator.config.enabled = element.state

    This.Elevator:updateElevatorConnection(elevator)
end

---@param event EventData.on_gui_confirmed
---@param gui framework.gui
function Gui.onConfirmNetworkId(event, gui)
    local elevator = This.Elevator:findElevator(gui.entity_id)
    if not elevator then return false end
    if not (elevator.state.powered and elevator.state.constructed) then return end

    local element = event.element
    local text = element.text
    elevator.config.network_id = (#text == 0) and 0 or tonumber(text)

    This.Elevator:updateElevatorConnection(elevator)
end

--------------------------------------------------------------------------------
-- Gui Updater
--------------------------------------------------------------------------------

---@param gui framework.gui
---@param elevator lse.Elevator
local function update_gui(gui, elevator)

    local connect = assert(gui:findElement('connect'))
    connect.state = elevator.config.enabled
    connect.enabled = (elevator.state.constructed and elevator.state.powered) or false

    local network_id = assert(gui:findElement('network_id'))
    network_id.text = tostring(elevator.config.network_id or 0)
    network_id.enabled = connect.state and connect.enabled
end


---@param gui framework.gui
---@return boolean
function Gui.guiUpdater(gui)
    local elevator = This.Elevator:findElevator(gui.entity_id)
    if not elevator then return false end

    ---@type lse.GuiContext
    local context = gui.context

    local refresh_config = not (context.last_elevator_config and table.compare(context.last_elevator_config, elevator.config))
    local refresh_state = not (context.last_elevator_state and table.compare(context.last_elevator_state, elevator.state))

    if refresh_config or refresh_state then
        update_gui(gui, elevator)
        context.last_elevator_config = util.copy(elevator.config)
        context.last_elevator_state = util.copy(elevator.state)
    end

    return true
end

--------------------------------------------------------------------------------
-- Event management
--------------------------------------------------------------------------------

---@param event EventData.on_gui_opened
local function on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if not tools.isValid(event.entity) then return end

    local elevator = This.Elevator:findElevator(event.entity.unit_number)
    if not elevator then return end

    local player = Player.get(event.player_index)
    if not player then return end

    ---@class lse.GuiContext
    ---@field last_elevator_config lse.ElevatorConfig?
    ---@field last_elevator_state lse.ElevatorState?
    local gui_state = {
        last_elevator_config = nil,
        last_elevator_state = nil,
    }

    Framework.gui_manager:createGui {
        type = Gui.AUX_GUI_NAME,
        player_index = event.player_index,
        parent = player.gui.relative,
        ui_tree_provider = Gui.getUi,
        context = gui_state,
        entity_id = event.entity.unit_number,
    }
end

---@param event EventData.on_gui_closed
local function on_gui_closed(event)
    if not tools.isValid(event.entity) then return end

    Framework.gui_manager:destroyGui(event.player_index, Gui.AUX_GUI_NAME)
end

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local function register_events()
    local se_entity_filter = Matchers:matchEventEntityName { 'se-space-elevator' }

    -- Gui updates / sync inserters
    Event.register(defines.events.on_gui_opened, on_gui_opened, se_entity_filter)
    Event.register(defines.events.on_gui_closed, on_gui_closed, se_entity_filter)

    Framework.gui_manager:registerGuiType(Gui.AUX_GUI_NAME, get_gui_event_definition())
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_load()
    register_events()
end

local function on_init()
    register_events()
end

Event.on_init(on_init)
Event.on_load(on_load)

return Gui
