------------------------------------------------------------------------
-- mod settings
------------------------------------------------------------------------

local const = require('lib.constants')

---@type table<FrameworkSettings.name, FrameworkSettingsGroup>
local Settings = {
    runtime = {
        [const.settings_names.use_elevator_clearance] = {
            key = const.settings.use_elevator_clearance,
            value = false
        },

        [const.settings_names.elevator_clearance_name] = {
            key = const.settings.elevator_clearance_name,
            value = '[item=se-space-elevator] Cleared'
        },

        --- LTN settings
        ['ltn-interface-console-level'] = {
            key = 'ltn-interface-console-level',
            value = 1
        },
        ['ltn-interface-debug-logfile'] = {
            key = 'ltn-interface-debug-logfile',
            value = 1
        },
        ['ltn-interface-message-gps'] = {
            key = 'ltn-interface-debug-logfile',
            value = false
        },
    }
}

return Settings
