-----------------------------------------------------------------------
-- tools
-----------------------------------------------------------------------

---@class lse.Tools
local Tools = {}

-----------------------------------------------------------------------
-- print messages
-----------------------------------------------------------------------

---@type PrintSettings
local settings = {
    sound = defines.print_sound.use_player_settings,
    skip = defines.print_skip.if_visible,
}

---@alias msg_func fun():LocalisedString

--- write msg to console for all member of force or all players
---@param level number
---@param msg_func msg_func
---@param force LuaForce?
function Tools.printmsg(level, msg_func, force)
    if tonumber(Framework.settings:runtime_setting('ltn-interface-console-level')) < level then return end

    if force and force.valid then
        force.print(msg_func(), settings)
    else
        game.print(msg_func(), settings)
    end
end

-----------------------------------------------------------------------
-- logging
-----------------------------------------------------------------------

---@alias log_func fun():...

---@param level number
---@param name string
---@param msg string
---@param log_func log_func?
function Tools.log(level, name, msg, log_func)
    if tonumber(Framework.settings:runtime_setting('ltn-interface-debug-logfile')) < level then return end
    log(('[LSE] (%s) [%d] - %s'):format(name, level, log_func and msg:format(log_func()) or msg))
end

-----------------------------------------------------------------------
-- rich text formatting
-----------------------------------------------------------------------

---@param entity LuaEntity
---@return string?
function Tools.gpsTextForEntity(entity)
    if not (entity and entity.valid) then return '<unknown>' end
    return ('[gps=%s,%s,%s]'):format(entity.position.x, entity.position.y, entity.surface.name)
end

---@param train LuaTrain
---@param train_name string?
function Tools.richTextForTrain(train, train_name)
    local loco = Tools.getMainLocomotive(train)
    if loco and loco.valid then
        return string.format('[train=%d] %s', train.id, train_name or loco.backer_name)
    else
        return string.format('[train=%d] %s', train.id, train_name)
    end
end

local function print_left(left, idx)
    if left then
        if left == idx then
            return tostring(left) .. ','
        else
            return tostring(left) .. '-' .. tostring(idx) .. ', '
        end
    else
        return ''
    end
end

---@param network_id integer
---@return string network_list
function Tools.networkList(network_id)
    local result = ''
    local mask = 1
    local left = nil
    for idx = 1, 32 do
        if bit32.band(network_id, mask) == mask then
            if not left then left = idx end
        else
            result = result .. print_left(left, idx - 1)
            left = nil
        end
        mask = bit32.lshift(mask, 1)
    end
    result = result .. print_left(left, 32)
    return result
end

-----------------------------------------------------------------------
-- Locomotives and Wagons
-----------------------------------------------------------------------

--- Get the main locomotive in a given train. -- from flib
--- @param train LuaTrain
--- @return LuaEntity? locomotive The primary locomotive entity or `nil` when no locomotive was found
function Tools.getMainLocomotive(train)
    if not (train and train.valid) then return end
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
