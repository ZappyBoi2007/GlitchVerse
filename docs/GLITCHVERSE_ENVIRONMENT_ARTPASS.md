# GLITCHVERSE Environment Art Pass

## Scope

This pass dresses the existing environment scenes without replacing their routes, markers, gameplay state nodes, or gameplay collision:

- `res://levels/access_denied_system_breach_environment.tscn`
- `res://levels/clock_failure_environment.tscn`
- `res://levels/kernel_panic_environment.tscn`

The scenes remain environment-only resources. No player, enemy, UI, wrapper, shared gameplay script, `project.godot`, or `main.tscn` file was changed.

## Imported asset source and license

Principal modular family: **Kenney Modular Space Kit 1.0**.

- Official source: <https://kenney.nl/assets/modular-space-kit>
- Downloaded archive: `kenney_modular-space-kit_1.0.zip`
- Downloaded archive size: 6,966,606 bytes
- License: Creative Commons CC0 1.0 Universal
- Local license copy: `res://assets/environment_art/KENNEY_LICENSE.txt`

Only these source assets were copied into the project:

- `res://assets/environment_art/modular/cables.glb`
- `res://assets/environment_art/modular/corridor-wide.glb`
- `res://assets/environment_art/modular/gate.glb`
- `res://assets/environment_art/modular/gate-door-window.glb`
- `res://assets/environment_art/modular/stairs-wide.glb`
- `res://assets/environment_art/modular/template-floor-layer-raised.glb`
- `res://assets/environment_art/modular/template-wall-detail-a.glb`
- `res://assets/environment_art/modular/Textures/colormap.png`

The Quaternius Modular Sci-Fi MegaKit and Sci-Fi Essentials Kit were investigated first. Their official pages identify the packs as CC0 and provide glTF formats, but the free downloads available during this pass required the interactive Itch flow. No premium or source archive was used, and no paywall was bypassed.

## Reusable art library

Shared materials:

- `res://assets/environment_art/materials/industrial_dark.tres`
- `res://assets/environment_art/materials/industrial_edge.tres`
- `res://assets/environment_art/materials/cyan_emissive.tres`
- `res://assets/environment_art/materials/amber_emissive.tres`
- `res://assets/environment_art/materials/magenta_emissive.tres`
- `res://assets/environment_art/materials/red_emissive.tres`

Reusable, editable prefabs:

- `res://assets/environment_art/prefabs/recessed_wall_panel.tscn`
- `res://assets/environment_art/prefabs/reinforced_floor_tile.tscn`
- `res://assets/environment_art/prefabs/door_frame.tscn`
- `res://assets/environment_art/prefabs/cable_tray.tscn`
- `res://assets/environment_art/prefabs/relay_console.tscn`
- `res://assets/environment_art/prefabs/machinery_housing.tscn`
- `res://assets/environment_art/prefabs/industrial_light.tscn`
- `res://assets/environment_art/prefabs/maintenance_hatch.tscn`
- `res://assets/environment_art/prefabs/safety_railing.tscn`

Each prefab combines a small number of inspectable Godot-native CSG visual pieces with selected Kenney meshes where appropriate. All prefab CSG nodes leave `use_collision` disabled, and no prefab contains a `CollisionObject3D`.

## Level 1 — Access Denied / System Breach

- Arrival Chamber: paired security machinery, reinforced floor inlays, industrial ceiling lights, recessed wall panels, and a layered threshold frame establish a containment lobby.
- Broken Crossing: suspended cable trays, safety rail fragments, and a service cabinet frame the existing grapple route without filling the 11-unit gap.
- Security Interception: wall service panel, maintenance hatch, equipment bay, and focused ceiling light stay outside the combat lane and enemy spawn clearance.
- Power Diversion: paired machinery housings, overhead conduit trays, and a physical console shell make the cyan/amber routing room read as a power-transfer facility.
- Final Containment Exit: a large mechanical frame, wall panels, status lighting, and existing state indicators produce a distinct final-door landmark.

The original bridge state nodes, powered-door state nodes, security-field state nodes, final-door state nodes, grapple markers, and combat markers remain addressable at their existing paths.

## Level 3 — Clock Failure

- Entry wall modules and a ceiling fixture reinforce the timing-sector entrance.
- Cable trays and machinery housings surround the timing chamber while leaving the central hazard route unchanged.
- Power cabinets and an overhead conduit connect visually to the existing teal/amber routing language.
- Security and exit rooms receive a service panel, maintenance hatch, lighting, and a layered exit frame.
- Ambient and key-light levels were raised modestly so structural surfaces remain legible at 1280x720. Existing emissive state colors and gameplay geometry remain intact.

## Level 4 — Kernel Panic

- Side-mounted approach panels and a ceiling fixture establish the entry chamber without occupying the route.
- Gravity and core areas use cable assemblies and machinery housings as heavy supports around the existing landmarks.
- The central kernel remains the dominant magenta silhouette, with cyan navigation and amber machinery accents.
- The final security room receives a service panel and navigation light.
- The shutdown console gains a physical shell, while the victory gate gains a layered mechanical frame and maintenance hatch.
- Ambient and key-light levels were raised modestly for route legibility while retaining the darker corrupted-sector palette.

## Preserved gameplay and collision contracts

Automated scene inspection confirmed:

| Scene | Original gameplay CSG colliders | Current gameplay CSG colliders | New prefab colliders |
| --- | ---: | ---: | ---: |
| Access Denied | 90 | 90 | 0 |
| Clock Failure | 51 | 51 | 0 |
| Kernel Panic | 41 | 41 | 0 |

- Existing `InteractionMarkers` paths and transforms were not edited.
- Existing bridge, field, door, hazard, kernel, and victory state nodes were not renamed or removed.
- Decorative art does not duplicate gameplay collision.
- No wall-run groups were added. Existing `vector_run_surface` ownership and movement behavior remain unchanged.
- The Access Denied gap, grapple anchors, landing geometry, enemy spawns, and door clearances were not moved.

## Lighting and signage

- Neutral cyan-white fixtures mark navigation and room structure.
- Cyan identifies traversal and technology routes.
- Amber identifies power transfer and machinery.
- Magenta remains reserved for kernel instability and corruption.
- Red remains reserved for locked, hostile, and emergency states.

Existing short labels remain on their original state props. This pass did not add floating instructional paragraphs.

## Actual Godot screenshots

The following screenshots were rendered from the real scenes with Godot 4.7.2 using the Compatibility renderer at 1280x720 and then inspected visually. They are local review artifacts and are not project runtime dependencies.

Level 1 baseline captures retained for comparison:

- `C:\Users\Jefin\AppData\Local\Temp\artpass_before_level1_spawn.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_before_level1_overhead.png`

Level 1:

- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l1_spawn.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l1_traversal.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l1_puzzle.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l1_exit.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l1_overview.png`

Level 3:

- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l3_spawn.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l3_traversal.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l3_puzzle.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l3_exit.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l3_overview.png`

Level 4:

- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l4_spawn.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l4_traversal.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l4_puzzle.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l4_exit.png`
- `C:\Users\Jefin\AppData\Local\Temp\artpass_final_l4_overview.png`

Compared with the Level 1 baseline, the final captures add recognizable door-frame silhouettes, paired machinery cabinets in place of isolated blocks, routed overhead cable assemblies, physical console shells, maintenance panels, safety rail detail, and directed area lighting. The Level 1 power and final-exit images show the strongest visible change.

Known capture limitation: the original Level 3 and Level 4 objective-console collision sits directly in front of each `PlayerSpawn`, and the original Level 1 spawn faces away from the route. Their route-oriented entry screenshots use nearby first-person camera positions to avoid presenting a frame fully occluded by those unchanged level elements.

## Validation performed

Godot executable: `C:\Program Files\Godot\Godot.exe` (4.7.2 stable).

- Repository validation: `tests/run_validation.ps1` — passed import, every GDScript parse check, main-scene smoke, integration checks, and `git diff --check`.
- Integration checks: 48 checks, 0 failures.
- Art-pass contract audit: all three scenes and all nine prefabs load; required markers and state nodes exist; collider counts match the base scenes; 0 failures.
- Final campaign checks: 62 checks, 0 failures.
- Combat mobility checks: 41 checks, 0 failures.
- Momentum/vector checks: 32 checks, 0 failures.
- Fifteen Compatibility-renderer screenshots were captured from the actual edited scenes and reviewed.

The editor-only screenshot runner emitted a Godot editor progress-dialog warning during an exploratory capture. Game-window captures used for the paths above completed with exit code 0 and did not emit that warning.

## Performance and integration notes

- Selected source art is approximately 1.06 MB before Godot's ignored import cache.
- The pass uses seven GLB model files, one shared color texture, six shared materials, and nine reusable prefabs.
- New decorative prefabs do not run scripts or physics and use only one small navigation light where the industrial-light prefab is placed.
- A GPU profiler benchmark and full manual campaign playthrough were not performed. Automated gameplay contract tests passed.
- Keith's wrappers should continue toggling the existing bridge, field, door, hazard, kernel, and victory state nodes. The `ProductionArtPass` children are decorative and require no gameplay API.
