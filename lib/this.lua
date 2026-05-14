----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class lse.Mod
---@field ltn_message_level integer
---@field ltn_debug_log integer
---@field Lse lse.Lse?
---@field Gui lse.Gui?
local This = {
    ltn_message_level = script and tonumber(settings.global["ltn-interface-console-level"].value) or 0,
    debug_log = script and settings.global["ltn-interface-debug-logfile"].value or 0,
}

if (script) then
    This.Lse = require('scripts.lse')
    This.Gui = require('scripts.gui')
end

----------------------------------------------------------------------------------------------------

return This
