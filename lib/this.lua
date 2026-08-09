----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

local const = require('lib.constants')

---@class lse.Mod
---@field other_mods table<string, string>
---@field settings ff2.ModSettings
---@field Lse lse.Lse
---@field Elevator lse.SpaceElevator
---@field Gui lse.Gui
local This = {
    remote_apis = {
        ['logistic-train-network'] = 'ltn',
        ['space-exploration'] = 'se',
    },
    settings = require('lib.settings'),
}

if (script) then
    This.Lse = require('scripts.lse')
    This.Elevator = require('scripts.elevator')
    This.Gui = require('scripts.gui')
end

--------------------------------------------------------------------------------
-- Framework initializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function This.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = const.prefix,
        -- prefix for log messages
        log_prefix = const.log_prefix,
        -- name is a human readable name
        name = const.name,
        -- The filesystem root.
        root = const.root,
        -- remote API
        exported_api_name = const.lse_name,
    }
end

------------------------------------------------------------------------
-- init setup
------------------------------------------------------------------------

--- Setup the global data structures
function This:init()
    if storage.lse_data then return end

    ---@type lse.Storage
    storage.lse_data = {
        known_stops = {},
        elevators = {},
    }
end

------------------------------------------------------------------------
-- Storage Management
------------------------------------------------------------------------

---@return lse.Storage
function This:storage()
    return assert(storage.lse_data)
end

return This
