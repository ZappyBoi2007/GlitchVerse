# Jefin Level Environment Handoff

## Level 1 — Access Denied

The environment and sci-fi presentation are already merged into `main`. Keith's gameplay wrapper is under `levels/access_denied/`. No Level 1 file was changed on `feature/jefin-remaining-levels`.

## Level 2 — Inverted

- Environment: `res://levels/inverted.tscn`
- Structure: 29-room neon labyrinth with a central five-exit hub, western and eastern loops, a misleading northern dead end, a winding northern maze and a pink final room.
- Spawn: `Markers/PlayerSpawn` at `(0, 0.4, 25)`.
- Exit: `Markers/ExitMarker` at `(0, 0.4, -78)`.
- Connectivity: all 29 rooms connected; shortest start-to-finish path is 12 graph transitions; six intentional dead ends.
- Collision: native collision on every room floor, retained room wall and corridor floor/wall.
- Gameplay: no player, manager, HUD, ability implementation, hazard implementation or completion logic is included.
- Integration markers: `GravityCratePlacement01`, `GravityCratePlacement02`, `PhaseGatePlacement`, `FreezeHazardPlacement`, `SentinelPlacement`, and `OptionalCachePlacement`.
- Visual inheritance: reuses the merged panel/star shaders and hover script without modifying them.

### Integration notes for Keith

Create a Level 2 `GameplayLevel` wrapper around the environment. Use the persistent player and shared flow manager. Attach actual puzzle actors only at the supplied markers after validating line of sight and clearance. Keep the direct-looking `NorthBlockedApproach` as a deliberate maze dead end. The final pink room is reachable only through the authored northern route.

## Remaining levels

Level 3 `CLOCK FAILURE` and Level 4 `KERNEL PANIC` have not been authored in this milestone.
