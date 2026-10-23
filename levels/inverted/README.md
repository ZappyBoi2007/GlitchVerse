# Level 2 — Inverted environment

Editable environment blockout based on the supplied updated neon-labyrinth reference.

## Scene

`res://levels/inverted.tscn`

## Layout contract

- 29 connected rooms across Central, Western, Eastern, Northern and Final zones.
- Central hub has five exits.
- Six intentional non-finish dead ends: NorthBlockedApproach, NorthEastDeadEnd, NorthSideDeadEnd, WestDeadEnd, WestMaintenanceDeadEnd, WestObservationDeadEnd.
- Shortest graph route from `CentralHub` to `InversionCore`: 12 transitions.
- Main floors, room walls and corridor walls use native `CSGBox3D` collision.
- `PlayerSpawn` and `ExitMarker` are serialized under `Markers`.
- Mechanic placement markers are descriptive only; no gameplay mechanic is instantiated.

## Intended shortest route

`CentralHub -> EastJunction -> EastGallery -> EastRelay -> NorthMazeEntry -> NorthMazeTurnA -> NorthMazeTurnB -> NorthMazeJunction -> NorthPuzzleRoom -> NorthCrossing -> NorthWestTurn -> FinalApproach -> InversionCore`

The northern direct-looking route terminates at `NorthBlockedApproach`. Western and eastern branches provide loops and optional dead ends without bypassing the intended route.

## Keith integration

Wrap this environment in a `GameplayLevel` scene, place the persistent player at `Markers/PlayerSpawn`, and connect the future Level 2 objective and standard exit to the shared flow contract. The authored markers identify suggested PHASE, GRAVITY, FREEZE and sentinel placements. This environment contains no player, HUD, manager, puzzle script or completion logic.
