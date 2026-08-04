-----------------------------------------------------------------------
-- tools
-----------------------------------------------------------------------

require('stdlib.utils.string')

---@class lse.Tools
local Tools = {}

-----------------------------------------------------------------------
-- rich text formatting
-----------------------------------------------------------------------

---@param entity LuaEntity
---@return string?
function Tools.gpsTextForEntity(entity)
    if not Tools.isValid(entity) then return '<unknown>' end
    return ('[gps=%s,%s,%s]'):format(entity.position.x, entity.position.y, entity.surface.name)
end

---@param train LuaTrain
---@param train_name string?
function Tools.richTextForTrain(train, train_name)
    local loco = Tools.getMainLocomotive(train)
    if Tools.isValid(loco) then
        ---@diagnostic disable-next-line: need-check-nil
        return string.format('[train=%d] %s', train.id, train_name or loco.backer_name)
    else
        return string.format('[train=%d] %s', train.id, train_name)
    end
end

local function add_result(result, left, idx)
    if not left then return end
    result[#result + 1] = (left == idx) and tostring(left) or tostring(left) .. '-' .. tostring(idx)
end

---@param network_id integer
---@return string network_list
function Tools.networkList(network_id)
    local result = {}
    local mask = 1
    local left = nil
    for idx = 1, 32 do
        if bit32.band(network_id, mask) == mask then
            if not left then left = idx end
        else
            add_result(result, left, idx - 1)
            left = nil
        end
        mask = bit32.lshift(mask, 1)
    end
    add_result(result, left, 32)

    return (', '):join(result)
end

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

---@param entity (LuaEntity|LuaTrain)?
---@return (LuaEntity|LuaTrain)? entity
function Tools.isValid(entity)
    if not (entity and entity.valid) then return nil end
    return entity
end

-----------------------------------------------------------------------
-- Locomotives and Wagons
-----------------------------------------------------------------------

--- Get the main locomotive in a given train. -- from flib
--- @param train LuaTrain
--- @return LuaEntity? locomotive The primary locomotive entity or `nil` when no locomotive was found
function Tools.getMainLocomotive(train)
    if not Tools.isValid(train) then return end
    return train.locomotives.front_movers and train.locomotives.front_movers[1] or train.locomotives.back_movers[1]
end

--- Get the backer_name of the main locomotive in a given train (which is the main train name). -- from flib
--- @param train LuaTrain
--- @return string backer_name The backer_name of the primary locomotive or '' when no locomotive was found
function Tools.getTrainName(train)
    local loco = Tools.getMainLocomotive(train)
    return loco and loco.backer_name or ''
end

return Tools
