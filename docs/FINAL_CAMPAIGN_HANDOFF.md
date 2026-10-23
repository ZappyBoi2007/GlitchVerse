# GlitchVerse final campaign handoff

Branch: `feature/final-campaign-integration`.

Integration history:

- `795e98d` — recoverable checkpoint for the tether and Level 1 reliability fixes.
- `04bcf5d` — local merge of current `origin/main` (`51bafd9`).
- `ca9ec23` — clean local merge of Jefin's Level 3/4 contribution (`0e69a7d`).
- `33cc1f1` — clean local merge of Jefin's complete production-art branch (`db45a8e`).
- `4d8f904` — validated four-level final environment integration (last pushed campaign baseline).
- `5277b2b` — conflict-free local merge of Jefin's final Level 2 polish (`3ac16dd`).

The campaign baseline through `4d8f904` is pushed. The Level 2 polish merge remains local and has not been pushed or merged into GitHub `main`.

The `codex-pre-momentum-grapple-checkpoint` stash remains preserved and was not applied or dropped.

## Campaign controls

- WASD: move
- Shift: sprint / marked-surface VECTOR RUN
- Space: jump / wall-jump
- E: TETHER attach or release; operate tether handles
- F: interact with relays, REWIRE consoles and terminals
- Q: POLARITY on marked masses
- Left mouse: BLADE
- R: restart failed/current level; replay after victory
- Esc: release cursor; click to recapture

## Level 1 — ACCESS DENIED

Gameplay scene: `res://levels/access_denied/access_denied_system_breach_level.tscn`

F6 preview: `res://levels/access_denied/access_denied_system_breach_preview.tscn`

The wrapper instances Jefin's unchanged production environment at `res://levels/access_denied_system_breach_environment.tscn`. Runtime gameplay objects resolve its authored `InteractionMarkers`.

Solution:

1. Cross the broken route using the two TETHER anchors.
2. Tether the amber pull handle to deploy the authored bridge section.
3. Defeat the Security Construct with three BLADE hits.
4. Press F at Relay A.
5. Press F at the REWIRE console to transfer power from the cyan security route to the amber door route. This removes the real security-field and powered-door collision.
6. Press F at Relay B.
7. The real containment door becomes passable; enter the exit marker.

Restart/replay reconstructs the environment wrapper and therefore restores the bridge, enemy, relay, REWIRE, door, health, objective, timer and score state.

The latest production-art pass is active. Its two imported lobby floor inlays are hidden by the gameplay wrapper because their scaled visual bounds rise roughly two metres and one contained the spawn camera. No authored gameplay collision was removed.

## Reusable production contracts

- `InteractionController`: camera ray, 4 m range, F input, targets `player_interactable` nodes implementing `interact(player)`.
- `RewireConsole`: emits `state_changed(door_powered)`; the owning level binds real collision and visual nodes.
- `ObjectiveRelay`: locked/available/restored state with duplicate prevention and `restored` signal.
- `PolarityController`: camera ray, 12 m range, Q input, targets `polarity_target` nodes implementing `toggle_polarity(source)`.
- `PolarityMass`: constrained collision-bearing motion between authored endpoints; reset occurs by level reload.
- `CampaignExit`: lightweight exit trigger for authored doors, avoiding duplicate door geometry.

## Level 2 — INVERTED

Gameplay scene: `res://levels/inverted/inverted_level.tscn`

F6 preview: `res://levels/inverted/inverted_preview.tscn`

Production environment: `res://levels/inverted/inverted_production_environment.tscn`

Solution: use TETHER to enter the vertical reactor, aim at both amber/violet stabilizer masses and press Q. Each collision-bearing mass moves along a constrained four-metre track. When both stabilizers reach their inverted positions, the upper reactor exit activates. Use the overhead TETHER route or the marked VECTOR maintenance wall to reach it.

The production scene is instanced once at identity. Existing collision decks, catwalks, launch steps, stabilizers, TETHER anchors and VECTOR wall remain authoritative; only their obsolete primitive presentation is hidden. `FloorShell` and `FloorInset` are hidden because they visually bridged deliberate gaps without collision. The decorative exit assembly is moved from `z=-19.35` to the supported upper deck at `z=-15.7`, and the completion trigger sits beyond it at `z=-17.5`.

Jefin's final polish (`3ac16dd`) is active: the production scene uses the revised dark-alloy/painted-panel materials, stabilizer housing and expanded reactor assembly. The gameplay wrapper still creates exactly one production environment and suppresses the retired procedural reactor/core meshes, so these visual additions do not duplicate gameplay geometry or collision.

## Level 3 — CLOCK FAILURE

Gameplay scene: `res://levels/clock_failure/clock_failure_level.tscn`

F6 preview: `res://levels/clock_failure/clock_failure_preview.tscn`

Production environment: `res://levels/clock_failure_environment.tscn`

Solution:

1. Use the two production TETHER anchors to traverse the broken Timing Chamber decks.
2. Press F at the Power Routing Room REWIRE console. This disables both moving cyclic sweeps, removes the real timing-hazard collision and opens the production blocked route.
3. Defeat the Security Construct with three BLADE hits.
4. Press F at Sync A, then Sync B. The terminals remain gated until REWIRE and combat are complete, and Sync B remains gated until Sync A is restored.
5. Cross the now-open production exit door. The completion trigger is deliberately beyond the door plane, so standing at Jefin's approach marker cannot finish the level.

The production anchor housings remain visible but have wrapper-disabled CSG collision. This is required because their original collision occupied the same camera ray as the reusable `GrappleAnchor` and made a visually correct TETHER shot invalid.

## Level 4 — KERNEL PANIC

Gameplay scene: `res://levels/kernel_panic/kernel_panic_level.tscn`

F6 preview: `res://levels/kernel_panic/kernel_panic_preview.tscn`

Production environment: `res://levels/kernel_panic_environment.tscn`

Solution:

1. Press Q on both POLARITY masses. Each travels only between Jefin's authored start/end markers and enables its matching production landing platform.
2. Use the two production TETHER anchors to reach the core network.
3. Press F at the core REWIRE console to remove the real core-shield collision and switch the production power/kernel state visuals.
4. Defeat the Security Construct with three BLADE hits.
5. Press F at the shutdown terminal. This disables the kernel, opens the real victory-gate collision and unlocks extraction.
6. Cross the open gate. The final victory trigger is beyond the gate plane, not on the approach-side marker.

## Campaign startup and progression

`res://main.tscn` is the F5 entry and registers exactly:

1. ACCESS DENIED
2. INVERTED
3. CLOCK FAILURE
4. KERNEL PANIC

The existing `GameFlowManager` automatically advances after completion, preserves successful-level time/score results, enters victory after Level 4 and uses R to replay from Level 1. The current production fallback direct-starts gameplay; Anushree's reviewed main-menu scene can later call `start_game()` with `auto_start` disabled.

## UI status

Anushree's newer UI remains isolated on `origin/feature/anushree-ui` under `scenes/ui/` and `scripts/ui/`. It was not merged or overwritten. `res://ui/campaign_hud.tscn` is the fallback signal-driven campaign HUD.

## Manual testing still required

Headless checks cannot prove the swing/release feel, BLADE encounter circulation, console readability, CSG collision refresh on a rendered frame, doorway clearance under live input, mouse feel, audio balance, or visual performance.

All four levels now use Jefin's latest production art. Levels 3 and 4 instance their environments exactly once; their retired procedural greyboxes are not built. Automated physics rays confirm all documented launch/landing sightlines hit the real reusable TETHER anchors after integration. Levels 3 and 4 intentionally start close to large emissive mission displays; those openings are visually aggressive but do not add collision. Swing arcs, landing comfort, signage readability, enemy circulation, hazard fairness and route bypasses still require a full human route playtest.

Forward+ 1280×720 first-person review captures are stored locally under `.godot/final-environment-art/`:

- `level_1_access_denied.png`
- `level_2_inverted.png`
- `level_2_upper_exit.png`
- `level_3_clock_failure.png`
- `level_4_kernel_panic.png`

The post-polish Forward+ gameplay-camera capture is stored at `.godot/final-level2-polish/level_2_integrated.png` (1280×720).

## Automated validation

`res://tests/final_campaign_checks.gd` exercises actual Level 1 bridge/combat/relay/REWIRE state, Level 2 constrained POLARITY motion, Level 3 hazard failure/restart and ordered terminals, Level 4 shield/combat/shutdown gating, all four scene paths, campaign transitions, scoring, victory and replay.

Latest automated results:

- Final campaign: 163 checks, 0 failures
- Legacy GameFlow/debugger integration: 48 checks, 0 failures
- Combat mobility: 41 checks, 0 failures
- Momentum/VECTOR RUN: 35 checks, 0 failures
- Audio: 38 checks, 0 failures
- Player movement: 6 checks, 0 failures
- Reality Fragments: 25 checks, 0 failures
- NULL SPINDLE: 14 checks, 0 failures
- Legacy ACCESS DENIED: 28 checks, 0 failures
- All four production environment scenes and all four gameplay previews: independent 120-frame headless runtime smokes passed
- Production `main.tscn`: import, parse and 300-frame smoke passed

Post-polish focused validation repeated the final campaign (163/163), legacy integration (48/48), ACCESS DENIED TETHER (12/12), Momentum/VECTOR RUN (35/35), combat mobility (41/41) and movement (6/6) suites. All 61 GDScript files parsed; the polished production environment, integrated Level 2 preview and production main scene completed headless runtime smokes.

## Windows export

`res://export_presets.cfg` defines `Windows Desktop` and writes `builds/GlitchVerse.exe`. The `builds/` directory is ignored by Git.

Export is currently blocked because this machine does not have the Godot 4.7.2 export templates. Godot specifically requires:

- `C:/Users/Keith/AppData/Roaming/Godot/export_templates/4.7.2.stable/windows_debug_x86_64.exe`
- `C:/Users/Keith/AppData/Roaming/Godot/export_templates/4.7.2.stable/windows_release_x86_64.exe`

Install the matching templates through Godot's **Editor → Manage Export Templates**, then run:

```powershell
& 'C:\Tools\Godot\Godot.exe' --headless --path 'C:\GlitchVerse\glitchverse' --export-release 'Windows Desktop' 'C:\GlitchVerse\glitchverse\builds\GlitchVerse.exe'
```

The executable must then receive a physical mouse/input/audio/full-campaign smoke test; headless validation cannot substitute for that.
