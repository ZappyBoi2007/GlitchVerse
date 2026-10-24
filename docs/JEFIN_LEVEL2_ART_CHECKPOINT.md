# JEFIN — Level 2 Production Art Checkpoint

## Git state and dependency

- Branch: `feature/jefin-level2-art`
- Base commit: `333f0815dc950fb2c3d42bb30a593c35f37ce698`
- Dependency: this branch includes the environment-art library from draft PR #16, which is stacked on the still-open PR #15.
- Milestone state: local visual-review checkpoint; not committed or pushed.

No gameplay scripts, existing Level 2 scenes, player code, campaign code, project settings, or UI files were modified.

## Preview scene

Independent environment scene:

`res://levels/inverted/inverted_production_environment.tscn`

This scene is an environment-only visual replacement aligned at world origin. It contains no scripts and no collision objects. It can be opened directly in Godot or instanced under `InvertedLevel` at an identity transform.

## Preserved Level 2 coordinates

The scene duplicates Keith's current runtime coordinates as editor markers under `IntegrationMarkers`:

| Contract | Preview NodePath | Position |
| --- | --- | --- |
| Player spawn | `IntegrationMarkers/PlayerSpawn` | `(0, 0.05, 16)` |
| Stabilizer A | `IntegrationMarkers/StabilizerA` | `(-5, 0.9, 2)` |
| Stabilizer B | `IntegrationMarkers/StabilizerB` | `(5, 0.9, -2)` |
| Entry TETHER anchor | `IntegrationMarkers/EntryGrappleAnchor` | `(0, 7, 7)` |
| Exit TETHER anchor | `IntegrationMarkers/ExitGrappleAnchor` | `(0, 9, -8)` |
| VECTOR wall | `IntegrationMarkers/MaintenanceVectorWall` | `(9.5, 3.5, -5)` |
| Campaign exit | `IntegrationMarkers/CampaignExit` | `(0, 4.05, -15.5)` |

## Visual direction completed for this checkpoint

- Enclosed 26-by-40-metre research chamber with side walls, arrival and exit bulkheads, ceiling shell, five ceiling crossbeams, and six structural columns.
- Detailed reactor prefab with layered foundation, glass containment vessel, restrained gravity column, five ring/coil layers, four structural struts, four coil banks, crown, fasteners, and a dedicated reactor light.
- Two stabilizer housings with service pads, coil frames, towers, status lamps, and local consoles. The open centers are aligned to the existing dynamic `PolarityMass` nodes.
- Mounted TETHER fixtures with mechanical backplates, four clamps, visible target rings, and ceiling braces.
- Arrival, reactor, catwalk, and upper-exit deck dressings aligned with the existing procedural collision geometry.
- Observation windows, monitoring consoles, machinery cabinets, overhead cable trays, floor guidance, safety rails, practical fixtures, and upper-exit architecture.
- Neutral facility fill with cyan navigation, amber machinery, and restrained magenta gravity energy.

## New reusable resources

Prefabs:

- `res://assets/environment_art/prefabs/gravity_reactor.tscn`
- `res://assets/environment_art/prefabs/gravity_stabilizer_housing.tscn`
- `res://assets/environment_art/prefabs/tether_fixture.tscn`
- `res://assets/environment_art/prefabs/observation_window.tscn`

Materials:

- `res://assets/environment_art/materials/brushed_steel.tres`
- `res://assets/environment_art/materials/structural_black.tres`
- `res://assets/environment_art/materials/gravity_core.tres`
- `res://assets/environment_art/materials/gravity_glass.tres`
- `res://assets/environment_art/materials/hazard_yellow.tres`

No new external archive was downloaded. The scene reuses the existing CC0 Kenney asset library from PR #16 through the cable-tray, door-frame, wall-panel, machinery, console, light, and railing prefabs.

## Visual proof

Actual Godot 4.7.2 Compatibility-renderer captures at 1280x720:

- Spawn: `C:\Users\Jefin\AppData\Local\Temp\level2_art_spawn.png`
- Reactor close-up: `C:\Users\Jefin\AppData\Local\Temp\level2_art_reactor_closeup.png`
- Interior overhead: `C:\Users\Jefin\AppData\Local\Temp\level2_art_overhead.png`

These images are review artifacts and are not runtime dependencies.

## Exact Keith-side integration requirements

1. Instance `res://levels/inverted/inverted_production_environment.tscn` under the `InvertedLevel` root at position, rotation, and scale identity.
2. Keep every existing procedural `StaticBody3D` and `CollisionShape3D`. Hide only these primitive mesh children:
   - `ArrivalDeck/Mesh`
   - `ReactorDeck/Mesh`
   - `UpperExitDeck/Mesh`
   - `LeftCatwalk/Mesh`
   - `RightCatwalk/Mesh`
   - `ReactorPillar_-9_5/Mesh`
   - `ReactorPillar_9_5/Mesh`
3. Hide these collision-free procedural visuals:
   - `UnstableGravityCore`
   - `CoreRingLower`
   - `CoreRingUpper`
   - `CyanRoute/Mesh`
   - `VioletRoute/Mesh`
   - `LevelTitle`
   - `ExitGuide`
4. Retain both gameplay anchors, their scripts, collision shapes, `GrapplePoint`, and `Highlight`. To use the mounted art fixtures without duplicate spheres/text, hide only:
   - `EntryGrappleAnchor/Mesh`
   - `EntryGrappleAnchor/Label3D`
   - `ExitGrappleAnchor/Mesh`
   - `ExitGrappleAnchor/Label3D`
5. Retain `StabilizerA` and `StabilizerB` completely. Their existing meshes, collision, labels, highlights, signals, and four-metre travel remain the functional moving cores inside the new open housings.
6. Retain `CampaignExit`, its script, collision, and state label. Hide only `CampaignExit/Beacon` if the original floor disc overlaps the new exit deck.
7. Retain `MaintenanceVectorWall` and its existing collision/group contract. The preview scene does not replace its gameplay surface.
8. Suppress the three procedural lights created by the final `add_directional` and two `add_omni` calls in `_build_environment()` when the production environment is present. Those lights receive generated `@...` runtime names, so skip/store them in code instead of depending on those unstable names.
9. Keep `FallFailure`, player health binding, puzzle state, stabilizer movement, exit unlocking, TETHER behavior, VECTOR behavior, and campaign completion unchanged.

## Validation performed

- Godot 4.7.2 import and scene load: passed.
- All seven integration markers exist at the exact current gameplay coordinates.
- Decorative CSG nodes with collision enabled: 0.
- `CollisionObject3D` nodes in the preview: 0.
- Four new prefabs load successfully.
- Spawn, close-up, and overhead captures were rendered and inspected from the actual scene.

This checkpoint intentionally stops before gameplay integration, further room expansion, commit, push, or pull-request creation.
