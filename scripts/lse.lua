------------------------------------------------------------------------
-- Management code
------------------------------------------------------------------------
assert(script)

local const = require('lib.constants')

local tools = require('scripts.tools')

---@class lse.Lse
local Lse = {}

------------------------------------------------------------------------
-- helpers
------------------------------------------------------------------------

---@param entity (LuaEntity|LuaTrain)?
---@return (LuaEntity|LuaTrain)? entity
local function is_valid(entity)
    if not (entity and entity.valid) then return nil end
    return entity
end

------------------------------------------------------------------------
-- create/delete
------------------------------------------------------------------------

---@param id integer
---@return lse.Elevator?
function Lse:findElevator(id)
    local lse_storage = This:storage()
    return lse_storage.elevators[id]
end

---@param elevator lse.Elevator?
function Lse:destroy(elevator)
    if not elevator then return end
end

------------------------------------------------------------------------
-- Cross-Surface delivery management
------------------------------------------------------------------------

---@param delivery ltn.Delivery
---@param callback fun(delivery: ltn.Delivery, from_stop: LuaEntity, to_stop: LuaEntity)
local function process_delivery(delivery, callback)
    local lse_storage = This:storage()

    if not (delivery and delivery.surface_connections and next(delivery.surface_connections)) then return end

    if not (delivery.train and delivery.train.valid) then return end

    local from_stop = is_valid(lse_storage.known_stops[delivery.from_id])
    local to_stop = is_valid(lse_storage.known_stops[delivery.to_id])

    if not (from_stop and to_stop) then return end


    local loco = tools.getMainLocomotive(delivery.train)
    -- train without a locomotive or intra-surface delivery
    if not loco or (loco.surface == from_stop.surface and loco.surface == to_stop.surface) then return end

    tools.printmsg(3, function()
                       return { const:locale('cross-surface-delivery'), tools.richTextForTrain(delivery.train), #delivery.surface_connections }
                   end, loco.force)

    callback(delivery, from_stop, to_stop)
end

------------------------------------------------------------------------
-- LTN Remote interface
------------------------------------------------------------------------

---@param stops table<integer, ltn.TrainStop>
function Lse:resyncKnownStops(stops)
    local lse_storage = This:storage()

    lse_storage.known_stops = {}
    for id, train_stop in pairs(stops) do
        if train_stop.entity.valid then
            lse_storage.known_stops[id] = train_stop.entity
        end
    end
end

---@param new_deliveries number[]
---@param deliveries table<number, ltn.Delivery>
function Lse:addNewDeliveries(new_deliveries, deliveries)
    for _, train_id in pairs(new_deliveries) do
        process_delivery(deliveries[train_id], function(delivery, from_stop, to_stop)
        end)
    end
end

------------------------------------------------------------------------
-- Remote API
------------------------------------------------------------------------

function Lse:clearElevators()
    local lse_storage = This:storage()
    for _, elevator in pairs(lse_storage.elevators) do
        self:destroy(elevator)
    end
end

---@param entity LuaEntity
---@param network_id integer
function Lse:connectElevator(entity, network_id)
    if not (entity and entity.valid) then return end

    local elevator = self:findElevator(entity.unit_number)
    if not elevator then return end

    elevator.config.network_id = network_id
    elevator.config.enabled = true
end

---@param entity LuaEntity
function Lse:disconnectElevator(entity)
    if not (entity and entity.valid) then return end

    local elevator = self:findElevator(entity.unit_number)
    if not elevator then return end

    elevator.config.network_id = nil
    elevator.config.enabled = false
end

return Lse
