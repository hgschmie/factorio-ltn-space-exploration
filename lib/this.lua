----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class lse.Mod
---@field other_mods table<string, string>
---@field Gui lse.Gui?
local This = {
    other_mods = {
    },
}

if (script) then
    This.Gui = require('scripts.gui')
end

----------------------------------------------------------------------------------------------------

return This
