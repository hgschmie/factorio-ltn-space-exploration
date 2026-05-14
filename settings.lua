------------------------------------------------------------------------
-- settings phase
------------------------------------------------------------------------

require('lib.init')

local const = require('lib.constants')

data:extend({
    {
        -- Debug mode (framework dependency)
        type = "bool-setting",
        name = Framework.PREFIX .. 'debug-mode',
        order = "az",
        setting_type = "startup",
        default_value = false,
    },
})

------------------------------------------------------------------------

---@diagnostic disable-next-line: undefined-field
Framework.post_settings_stage()
