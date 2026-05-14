------------------------------------------------------------------------
-- Management code
------------------------------------------------------------------------
assert(script)

---@class lse.Lse
local Lse = {}

------------------------------------------------------------------------
-- init setup
------------------------------------------------------------------------

--- Setup the global data structures
function Lse:init()
    if not storage.lse_data then
        ---@type lse.Storage
        storage.lse_data = {
        }
    end
end

return Lse
