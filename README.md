# LTN - Space Exploration integration

[Space Exploration](https://mods.factorio.com/mod/space-exploration) is one of the most popular, user-contributed expansions for Factorio. It expands the game into space, even before Space Age.

Trains are important in Space Exploration. And they can move between surfaces. To make this work with the [Logistic Train Network (LTN)](https://mods.factorio.com/mod/LogisticTrainNetwork),
a [glue mod](https://mods.factorio.com/mod/se-ltn-glue) has existed for a long time, but has not been upgraded for newer LTN versions, which led to compatibility problems.

This mod is an alternative solution for integrating LTN and SE. It owes a debt of gratitude to [Harag](https://steamcommunity.com/id/harag/) who maintained [Space Exploration LTN integration](https://mods.factorio.com/mod/se-ltn-glue) for a long time. If that mod works for you, there is no need
to switch.

It supports all newer versions of LTN and the features that exist in those versions (Delivery ends at requester, advanced delivery etc.).

![image1](https://raw.githubusercontent.com/hgschmie/factorio-ltn-space-exploration/main/.portal/ltn-se-1.png)

## Settings

### Use Elevator Clearance station (use_elevator_clearance) - boolean, runtime, default is `false`

If true, trains will be sent to a "clearance stop" first before going to their actual destination. This helps with destinations that have train limits and are temporarily not available; otherwise the train would be "stuck" in the elevator until the destination station frees up.

If your space elevators are very busy and move a lot of trains to different destinations, then this setting can help with throughput.

### Clearance station name (elevator_clearance_name) - string, runtime, default is `[item=se-space-elevator] Cleared`

Sets the name of clearance stations when in use. Clearance stations must exist on each surface that has a space elevator endpoint.

## Known problems

When constructing a space elevator, it should be added automatically to LTN at construction time. However, due to [a bug in Space Exploration](https://github.com/EarendelDevelopers/factorio-mods/issues/393), not all orientations of a space elevator are added automatically.
If the Space Elevator GUI does not show the LTN addon at the top of the UI before construction has finished, it will be added when construction of the Space Elevator is complete.

## Legal

(C) 2026 Henning Schmiedehausen (hgschmie). Released under the [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) license.

Inspired by [Space Exploration LTN Integration](https://mods.factorio.com/mod/se-ltn-glue) by [Harag](https://steamcommunity.com/id/harag/), licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
