--------------------------------------------------------------------------------
-- Logistics Train Network
--------------------------------------------------------------------------------

local Event = require('stdlib.event.event')

---@param event ltn.EventData.on_dispatcher_updated
local function dispatcher_updated(event)
    if #event.new_deliveries == 0 then return end
    This.Lse:addNewDeliveries(event.new_deliveries, event.deliveries)
end

---@param event ltn.EventData.on_stops_updated
local function stops_updated(event)
    This.Lse:resyncKnownStops(event.logistic_train_stops)
end

local function ltn_init()
    if not remote.interfaces['logistic-train-network'] then return end

    assert(remote.interfaces['logistic-train-network']['on_dispatcher_updated'], 'LTN present but no on_dispatcher_updated event')
    assert(remote.interfaces['logistic-train-network']['on_stops_updated'], 'LTN present but no on_stops_updated event')

    Event.on_event(remote.call('logistic-train-network', 'on_dispatcher_updated'), dispatcher_updated)
    Event.on_event(remote.call('logistic-train-network', 'on_stops_updated'), stops_updated)
end

local LogisticsTrainNetwork = {
    on_init = ltn_init,
    on_load = ltn_init,
}

return LogisticsTrainNetwork
