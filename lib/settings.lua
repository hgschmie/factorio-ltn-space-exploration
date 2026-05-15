------------------------------------------------------------------------
-- mod settings
------------------------------------------------------------------------

local const = require('lib.constants')

---@type table<FrameworkSettings.name, FrameworkSettingsGroup>
local Settings = {
    runtime = {
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
            key = 'ltn-interface-message-gps',
            value = false
        },
    }
}

return Settings
