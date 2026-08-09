------------------------------------------------------------------------
-- settings phase
------------------------------------------------------------------------

This, Framework = require('lib.init')()

local const = require('lib.constants')

data:extend {
    {
        -- Debug mode (framework dependency)
        type = 'string-setting',
        name = Framework.PREFIX .. 'debug-mode',
        order = 'az',
        setting_type = 'startup',
        default_value = '0',
        allowed_values = { '0', '1', '2', '3' },
    },
    {
        type = 'bool-setting',
        name = const.settings.use_elevator_clearance,
        setting_type = 'runtime-global',
        default_value = false,
        order = 'a',
    },
    {
        type = 'string-setting',
        name = const.settings.elevator_clearance_name,
        setting_type = 'runtime-global',
        default_value = '[item=se-space-elevator] Cleared',
        order = 'b',
    } }

---@diagnostic disable-next-line: undefined-field
Framework.post_settings_stage()
