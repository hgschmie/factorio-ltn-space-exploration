---@meta
----------------------------------------------------------------------------------------------------
-- class definitions
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--- LTN Types
----------------------------------------------------------------------------------------------------

--- typed string for the item identifiers
---@alias ltn.ItemIdentifier string

--- A shipment, consisting of comma-separated description strings and an amount.
---@alias ltn.Shipment table<ltn.ItemIdentifier, number>

---@class ltn.SurfaceConnection
---@field entity1    LuaEntity
---@field entity2    LuaEntity
---@field network_id number

--- A scheduled delivery
---@class ltn.Delivery
---@field force                LuaForce
---@field train                LuaTrain
---@field from                 string
---@field from_id              number
---@field to                   string
---@field to_id                number
---@field network_id           number
---@field started              number
---@field surface_connections  ltn.SurfaceConnection[]
---@field shipment             ltn.Shipment
---@field pickupDone           boolean?

--- LTN stop information
---@class ltn.TrainStop
---@field active_deliveries           number[]   List of train ids that are either requesting or providing to this stop
---@field entity                      LuaEntity  The Train stop entity itself
---@field input                       LuaEntity  The Lamp entity (input) of the Train stop
---@field output                      LuaEntity  The combinator entity (output) of the Train stop
---@field lamp_control                LuaEntity  Hidden combinator that controls the input lamp
---@field error_code                  number     Current error state of the stop
---@field is_depot                    boolean    True if the stop is a depot
---@field is_fuel_station             boolean    True if the stop is a fuel station
---@field depot_priority              number     Depot priority value
---@field network_id                  number     Encoded network id for the stop
---@field min_carriages               number     minimum train length for this stop
---@field max_carriages               number     maximum train length for this stop
---@field max_trains                  number     maximum number of trains allowed to this stop
---@field providing_threshold         number     Provider threshold value (items and fluids)
---@field providing_threshold_stacks  number     Provider stack threshold value (for items only)
---@field provider_priority           number     Provider priority value
---@field requesting_threshold        number     Requester threshold value (items and fluids)
---@field requesting_threshold_stacks number     Requester stack threshold value (for items only)
---@field requester_priority          number     Requester priority value
---@field locked_slots                number     Locked slots per wagon for this stop
---@field no_warnings                 boolean    If true, warnings are disabled for this stop
---@field parked_train                LuaTrain?  The currently parked train at this stop
---@field parked_train_id             number?    The train id of the currently parked train
---@field parked_train_faces_stop     boolean?   True if the train faces the stop, false otherwise
---@field fuel_signals                (CircuitCondition[])? Fuel Signals for a fuel station, used to create refuel interrupt condition

--- LTN Train information
---@class ltn.Train
---@field train             LuaTrain
---@field force             LuaForce
---@field capacity          number
---@field fluid_capacity    number
---@field surface           LuaSurface
---@field depot_priority    number
---@field network_id        number
---@field select_count      number     How often the train was selected for a delivery

---@class ltn.EventData.on_dispatcher_updated
---@field update_interval       number time in ticks LTN needed to run all updates, varies depending on number of stops and requests
---@field provided_by_stop      table<number, ltn.Shipment>
---@field requests_by_stop      table<number, ltn.Shipment>
---@field new_deliveries        number[]
---@field deliveries            table<number, ltn.Delivery>
---@field available_trains      table<number, ltn.Train>

---@class ltn.EventData.on_stops_updated
---@field logistic_train_stops  table<integer, ltn.TrainStop> All train stops known to LTN

----------------------------------------------------------------------------------------------------
--- SE Types
----------------------------------------------------------------------------------------------------

---@class se.EventData.on_train_teleport_started
---@field train             LuaTrain
---@field old_train_id_1    integer
---@field old_surface_index integer
---@field teleporter        LuaEntity

---@class se.EventData.on_train_teleport_finished
---@field train             LuaTrain
---@field old_train_id_1    integer
---@field stranded          LuaTrain?
---@field old_surface_index integer
---@field teleporter        LuaEntity

---@class se.ZoneType
---@field type         string
---@field orbit_index  integer?
---@field parent_index integer?
---@field surface_index integer

----------------------------------------------------------------------------------------------------
--- scripts/lse
----------------------------------------------------------------------------------------------------

---@class lse.ElevatorConfig
---@field enabled boolean
---@field network_id integer?

---@class lse.ElevatorState
---@field connected boolean
---@field network_id integer?

---@class lse.ElevatorEnd
---@field elevator LuaEntity
---@field stop LuaEntity
---@field connector LuaEntity?

---@class lse.Elevator
---@field ids table<string, integer>
---@field config lse.ElevatorConfig
---@field state lse.ElevatorState
---@field ground lse.ElevatorEnd
---@field orbit lse.ElevatorEnd

---@class lse.Storage
---@field known_stops LuaEntity[]
---@field elevators lse.Elevator[]
