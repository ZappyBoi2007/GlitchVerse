# Jefin Milestone 1 — System Breach Environment Handoff

## Scene

`res://levels/access_denied_system_breach_environment.tscn`

This is an environment-only Level 1 scene. It contains no player, gameplay wrapper, enemy, TETHER logic, BLADE logic, REWIRE logic, damage system, HUD, or campaign progression. The current repository does not contain TETHER or REWIRE contracts, so all interaction points are descriptive markers for Keith.

## Intended route

1. **Arrival Chamber** — spawn safely, read `0/2 CIRCUITS RESTORED`, view the final containment exit through the east observation pane, then follow cyan conduits west.
2. **Broken Crossing** — use the two visible overhead anchors across the physical gap, reach the destination ledge, and use the marked pull mechanism when TETHER exists.
3. **Security Interception** — enter the medium combat room, clear the two future enemy positions, and reach Relay A at the southwest terminal.
4. **Power Diversion** — inspect cyan channel A and amber channel B, then use the future REWIRE console and Relay B before following the east service route.
5. **Final Containment Exit** — enter from the north service route, handle the final encounter position, and approach the major east containment door and exit.

## Marker NodePaths

- `InteractionMarkers/PlayerSpawn` — `(-2, 0.4, 35)`, 1.8 m headroom, unit scale.
- `InteractionMarkers/GrappleAnchor_01` — `(-24, 7.2, 30)`.
- `InteractionMarkers/GrappleAnchor_02` — `(-30, 8.4, 27)`.
- `InteractionMarkers/TetherPullHandle_01` — `(-39, 1.45, 26)`.
- `InteractionMarkers/EnemySpawn_01` — `(-54, 0.4, 9)`.
- `InteractionMarkers/EnemySpawn_02` — `(-44, 0.4, 8)`.
- `InteractionMarkers/RelayA_Marker` — `(-57, 0.4, 2)`.
- `InteractionMarkers/PowerConsole_Marker` — `(-18, 0.4, -6)`.
- `InteractionMarkers/RelayB_Marker` — `(-18, 0.4, -16)`.
- `InteractionMarkers/FinalEnemySpawn` — `(23, 0.4, 30)`.
- `InteractionMarkers/ExitMarker` — `(31.5, 0.4, 30)`.

Additional integration markers: `FallRecoveryMarker`, `FallZoneMarker`, `SecurityField_Marker`, `PoweredDoorMechanism_Marker`, `FinalRelayStatusLeft_Marker`, and `FinalRelayStatusRight_Marker`.

## Crossing dimensions

- Start ledge east/west bounds: `x = -21` to `-11`.
- Destination ledge east/west bounds: `x = -42` to `-32`.
- Clear horizontal gap between ledges: **11 m**.
- Anchor 01 is approximately 7.8 m from the start ledge edge in three-dimensional distance.
- Anchor spacing is approximately 7.0 m.
- Anchor 02 is approximately 8.9 m from the destination ledge center.
- The retracted bridge is visibly stored 1.25 m below floor height and does not cover the gap.

The existing controller walks at 5 m/s, sprints at 8 m/s, jumps at 5.2 m/s, and has a 1.8 m by 0.7 m capsule. The 11 m gap is intended to exceed ordinary jump traversal, but final bypass and TETHER comfort require Keith's actual mechanic and manual playtesting.

## Collision and editable state pieces

All primary floors, walls, ledges, corridor rails, cover, console housings, and the locked containment door use collision-enabled native CSG nodes. Anchor rings, energy panes, screens, conduits, warning strips, and status indicators are separate visual nodes.

`Environment/FinalContainmentExit/ContainmentDoor` includes separate `LockedDoorPanel`, hidden `UnlockingDoorLeft`, hidden `UnlockingDoorRight`, and hidden `OpenDoorPocket` pieces for Keith to animate. No state controller is included.

## Integration blockers

- TETHER and REWIRE do not exist in the inspected repository, so the crossing and power-routing interactions cannot be functionally tested yet.
- Enemy AI and BLADE combat are Keith-owned and intentionally absent.
- The current `levels/access_denied/access_denied_level.tscn` wrapper still depends on the preserved legacy PHASE environment. Keith must create or update a gameplay wrapper after reviewing this environment; this milestone does not change that file.
- `PreviewCamera` is saved non-current so it cannot take control from the player camera.
