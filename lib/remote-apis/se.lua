--------------------------------------------------------------------------------
-- Space Exploration
--------------------------------------------------------------------------------

local Event = require('stdlib.event.event')

local const = require('lib.constants')
local tools = require('scripts.tools')

--------------------------------------------------------------------------------
-- SE events
--------------------------------------------------------------------------------

---@param event se.EventData.on_train_teleport_started
local function on_train_teleport_started(event)
   This.Lse:startElevatorTravel(event.old_train_id_1, event.train)
end

---@param event se.EventData.on_train_teleport_finished
local function on_train_teleport_finished(event)
   This.Lse:endElevatorTravel(event.old_train_id_1, event.train)

   if event.stranded then
      tools.printmsg(0, function()
         return { const:locale('train_stranded'), event.stranded.id, tools.gpsTextForEntity(event.teleporter) }
      end)
   end
end

---@param event se.EventData.on_space_elevator_changed_state
local function on_space_elevator_changed_state(event)
   if not tools.isValid(event.primary) then return end
   local elevator = This.Elevator:findElevator(event.primary.unit_number)

   if not elevator then
      elevator = This.Elevator:registerSpaceElevator(event.primary)
      if not elevator then return end
   end

   This.Elevator:updateElevatorState(elevator, event.constructed, event.powered)
end

local function se_init()
   if not remote.interfaces['space-exploration'] then return end

   ---@diagnostic disable-next-line: undefined-field
   assert(defines.events.se_on_train_teleport_started, 'SE present but no get_on_train_teleport_started_event event')
   ---@diagnostic disable-next-line: undefined-field
   assert(defines.events.se_on_train_teleport_finished, 'SE present but no get_on_train_teleport_finished_event event')
   ---@diagnostic disable-next-line: undefined-field
   assert(defines.events.se_on_space_elevator_changed_state, 'SE present but no get_on_space_elevator_changed_state_event event')

   ---@diagnostic disable-next-line: undefined-field
   Event.register(defines.events.se_on_train_teleport_started, on_train_teleport_started)
   ---@diagnostic disable-next-line: undefined-field
   Event.register(defines.events.se_on_train_teleport_finished, on_train_teleport_finished)
   ---@diagnostic disable-next-line: undefined-field
   Event.register(defines.events.se_on_space_elevator_changed_state, on_space_elevator_changed_state)
end

return {
   on_init = se_init,
   on_load = se_init,
}
