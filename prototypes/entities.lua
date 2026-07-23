---@namespace data

------------------------------------------------------------------------
-- entity definitions
------------------------------------------------------------------------

local const = require('lib.constants')

local collision_mask_util = require('collision-mask-util')
local util = require('util')

-- This is a marker entity to connect LTN to a space elevator. When the mod gets removed,
-- these entities become invalid which in turn breaks the LTN connections between the different
-- surfaces. Theoretically this could be the two ends of the space elevator itself but then
-- removing the ltn-space-exploration mod would retain the existing LTN connections indefinitely.

---@type SimpleEntityWithOwnerPrototype
local entity = {
    -- PrototypeBase
    type = 'simple-entity-with-owner',
    name = const.lse_name,
    hidden = true,
    hidden_in_factoriopedia = true,

    -- SimpleEntityWithOwnerPrototype
    picture = util.empty_sprite() --[[@as Sprite ]],

    -- EntityWithHealthPrototype
    max_health = 1,

    -- EntityPrototype
    icons = { util.empty_icon() --[[@as IconData ]], },
    collision_box = { { -0.01, -0.01 }, { 0.01, 0.01 } },
    collision_mask = collision_mask_util.new_mask(),
    selection_box = { { -0.01, -0.01 }, { 0.01, 0.01 } },
    flags = {
        'placeable-off-grid',
        'not-on-map',
        'not-deconstructable',
        'hide-alt-info',
        'not-selectable-in-game',
        'not-upgradable',
        'no-automated-item-removal',
        'no-automated-item-insertion',
        'not-in-kill-statistics',
        'placeable-neutral',
        'player-creation',
    },
    minable = nil,
    allow_copy_paste = false,
    selectable_in_game = false,
    selection_priority = 1,
}

data:extend { entity }
