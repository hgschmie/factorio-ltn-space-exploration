------------------------------------------------------------------------
-- GUI code
------------------------------------------------------------------------
assert(script)

local util = require('util')

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')

local Matchers = require('framework.matchers')

local const = require('lib.constants')

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
                                        state = false,
                                        enabled = true,
                                        handler = { [defines.events.on_gui_switch_state_changed] = gui_events.onToggleConnection },
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
                                        text = '12345', -- tostring(elevator_data.network_id),
                                        handler = { [defines.events.on_gui_confirmed] = gui_events.onConfirmNetworkId },
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
    local element = event.element
end

---@param event EventData.on_gui_confirmed
---@param gui framework.gui
function Gui.onConfirmNetworkId(event, gui)
    local element = event.element
end

--------------------------------------------------------------------------------
-- Gui Updater
--------------------------------------------------------------------------------

---@param gui framework.gui
---@return boolean
function Gui.guiUpdater(gui)
    ---@type lse.GuiContext
    local context = gui.context

    --    local refresh_config = not (context.last_inserter_config and table.compare(context.last_inserter_config, ml_entity.config.inserter_config))

    -- if refresh_config then
    --     if This.Lse.spoiling then update_spoilage(gui, ml_entity) end
    --     context.last_inserter_config = util.copy(ml_entity.config.inserter_config)
    -- end

    return true
end

--------------------------------------------------------------------------------
-- Event management
--------------------------------------------------------------------------------

---@param event EventData.on_gui_opened
local function on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if not (event.entity and event.entity.valid) then return end

    local player = Player.get(event.player_index)
    if not player then return end

    ---@class lse.GuiContext
    local gui_state = {
    }

    Framework.gui_manager:createGui {
        type = Gui.AUX_GUI_NAME,
        player_index = event.player_index,
        parent = player.gui.relative,
        ui_tree_provider = Gui.getUi,
        context = gui_state,
        --         entity_id = ml_entity.main.unit_number,
    }

    --    game.players[event.player_index].opened = ml_entity.loader
end

---@param event EventData.on_gui_closed
local function on_gui_closed(event)
    if not (event.entity and event.entity.valid) then return end

    -- local ml_entity = This.MiniLoader:getEntity(event.entity.unit_number)

    Framework.gui_manager:destroyGui(event.player_index, Gui.AUX_GUI_NAME)
end

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local function register_events()
    local se_entity_filter = Matchers:matchEventEntityName({ 'se-space-elevator' })

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
