--------------------------------------------------------------------------------
-- Logistics Train Network
--------------------------------------------------------------------------------

local LogisticsTrainNetwork = {}

---@param event ltn.EventData.on_dispatcher_updated
local function dispatcher_updated(event)
    if #event.new_deliveries == 0 then return end
    This.Lse:addNewDeliveries(event.new_deliveries, event.deliveries)
end

---@param event ltn.EventData.on_stops_updated
local function stops_updated(event)
    This.Lse:resyncKnownStops(event.logistic_train_stops)
end

LogisticsTrainNetwork.runtime = function()
    assert(script)

    local Event = require('stdlib.event.event')

    local ltn_init = function()
        if not remote.interfaces['logistic-train-network'] then return end

        assert(remote.interfaces['logistic-train-network']['on_dispatcher_updated'], 'LTN present but no on_dispatcher_updated event')
        assert(remote.interfaces['logistic-train-network']['on_stops_updated'], 'LTN present but no on_stops_updated event')

        Event.on_event(remote.call('logistic-train-network', 'on_dispatcher_updated'), dispatcher_updated)
        Event.on_event(remote.call('logistic-train-network', 'on_stops_updated'), stops_updated)
    end

    Event.on_init(ltn_init)
    Event.on_load(ltn_init)
end

return LogisticsTrainNetwork
