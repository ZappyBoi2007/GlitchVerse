# GlitchVerse final campaign handoff

Branch: `feature/keith-final-campaign`, based on verified `origin/main` `e3d6a65`.

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

## Reusable production contracts

- `InteractionController`: camera ray, 4 m range, F input, targets `player_interactable` nodes implementing `interact(player)`.
- `RewireConsole`: emits `state_changed(door_powered)`; the owning level binds real collision and visual nodes.
- `ObjectiveRelay`: locked/available/restored state with duplicate prevention and `restored` signal.
- `PolarityController`: camera ray, 12 m range, Q input, targets `polarity_target` nodes implementing `toggle_polarity(source)`.
- `PolarityMass`: constrained collision-bearing motion between authored endpoints; reset occurs by level reload.
- `CampaignExit`: lightweight exit trigger for authored doors, avoiding duplicate door geometry.

## UI status

Anushree's newer UI remains isolated on `origin/feature/anushree-ui` under `scenes/ui/` and `scripts/ui/`. It was not merged or overwritten. `res://ui/campaign_hud.tscn` is the fallback signal-driven campaign HUD.

## Manual testing still required

Headless checks cannot prove the two swing arcs, bridge sightline, BLADE encounter circulation, console readability, CSG collision refresh on a rendered frame, containment-door clearance, mouse feel, audio balance, or visual performance.
