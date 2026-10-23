# GlitchVerse gameplay expansion plan

This plan protects the shipped PHASE, GRAVITY, FREEZE, `GameplayLevel`, and `GameFlowManager` contracts. It proposes a small action layer for a four-level hackathon build; it is not approval to start a combat subsystem.

## Hackathon-feasible additions

1. **Polished traversal.** Keep current walk/sprint speeds. Use faster falling, jump-release shortening, small jump buffering/coyote time, and useful but bounded air steering. Tune against ordinary gaps rather than precision platforming.
2. **Environmental failure volumes.** Add reusable `Area3D` kill/damage zones below pits, around exposed reactor energy, and beneath collapsing routes. Every danger needs visible color, sound, motion, or warning signage before it can fail the player.
3. **One stationary sentinel pattern.** Use one reusable turret/sensor, not navigation AI. It watches a defined cone, confirms line of sight with a ray, displays an amber acquisition beam for roughly one second, turns red, then fires. Cover, PHASE geometry, or FREEZE should interrupt acquisition. Start with a level failure on a confirmed hit; add health only if playtesting shows one-hit failure is unfair.
4. **Short timed sequences.** Use a visible countdown only after the player deliberately triggers an escape. Routes remain readable, hazards have fixed timing, and failure offers immediate `restart_current_level()` recovery.
5. **Clear presentation.** A low-poly camera-mounted Reality Debugger, three ability indicators, level timer, current objective, and short operator messages reinforce action without adding mechanics.
6. **Compact retries.** Keep levels short enough for full-level restart during the hackathon. Add one checkpoint only to the final escape if repeated full-level attempts become frustrating in testing.

## Movement implementation and tuning

The controller now exposes:

- ground and air acceleration;
- air target-speed and no-input braking multipliers;
- rising, falling, and released-jump gravity multipliers;
- terminal fall speed;
- coyote time and jump-buffer duration.

The default intent is grounded tactical movement: normal top speeds are unchanged, held jumps retain approximately the previous height, releasing Space cuts the ascent, descent is faster, and opposite input can arrest bad horizontal momentum without allowing instant midair turns. Level authors should use broad landings and ramps; none of the four levels should require exploiting coyote time.

Manual tuning target: a player sprinting into a mistaken jump should be able to reduce or redirect the landing, but should not be able to reverse a full sprint instantly. Test at 30, 60, and uncapped frame rates.

## Minimal failure and enemy proposal

### Observation Sentinel

A stationary `Node3D` with a detection `Area3D`, one line-of-sight `RayCast3D`, a visible rotating head, and a simple state machine:

`IDLE -> ACQUIRING -> FIRING -> COOLDOWN`

- **IDLE:** slow scan with a visible cyan lens.
- **ACQUIRING:** amber beam and rising audio tone for 0.9–1.4 seconds depending on difficulty.
- **FIRING:** brief red flash; if line of sight still exists, call the level's failure/damage interface.
- **COOLDOWN:** two seconds in which the player can move.

PHASE can remove blocking cover, creating a risk/reward decision. FREEZE can stop the sentinel locally if the team explicitly decides it is a compatible target. GRAVITY should not affect it unless a level provides a separate gravity-controlled shield or crate. This keeps the debugger central and avoids a weapon dependency.

For the first implementation, use one sentinel in a controlled arena and failure followed by a retry prompt. Do not add pathfinding, patrol squads, projectile ballistics, loot, or enemy inventories.

### Fair-failure rules

- Never fail the player on the same frame a hazard becomes visible.
- Use consistent cyan/amber/violet/red language: interactable, warning, anomaly, lethal.
- Place safe observation space before every new hazard pattern.
- Restart must reconstruct all puzzle and hazard state through the existing scene reload.
- Checkpoints must never restore a player behind a newly solid barrier or beneath a raised gravity crate.

If a checkpoint is necessary, store only a checkpoint identifier. On reload, the level applies a deliberate authored snapshot for that identifier and then places the player at its marker. Do not serialize arbitrary physics state. This needs a small future extension to the flow contract and should be limited to Level 4.

## Difficulty options

Use one shared difficulty resource/config selected before `start_game()`. Puzzle solutions and geometry do not change.

| Setting | Story | Challenge |
| --- | --- | --- |
| Objective help | Persistent contextual hints | Hints delayed or compact |
| Sentinel acquisition | About 1.4 seconds | About 0.9 seconds |
| Moving hazards | 80–90% authored speed | 110–120% authored speed |
| Escape timer | Generous, with warning thresholds | Tighter, still validated by ordinary play |
| Failure recovery | Immediate retry prompt | Same recovery; challenge must not add downtime |
| Score | Standard | Optional clearly disclosed multiplier |

Avoid changing movement physics by difficulty; inconsistent controls make failure feel unfair.

## First-person presentation

### Recommended

- A simple built-in-mesh forearm/device viewmodel parented to the camera, rendered close to the player with restrained bob and a short activation pulse.
- Device color and display driven by `RealityDebugger.ability_changed`.
- Three bottom ability indicators driven by existing ability/target signals.
- Timer and objective from `GameFlowManager` signals or `get_snapshot()`.
- Two or three integrity pips only if multi-hit hazards are implemented.
- Short radio text/audio at level entry, first encounter, puzzle completion, and escape trigger.

The device should communicate tool state, not obscure the crosshair. It needs no reload animation, inventory, weapon switching, or elaborate hands rig for the hackathon.

### Postpone

- Pistol and ammunition economy. A gun introduces aiming balance, damage ownership, enemy reactions, animation, audio, and UI work while competing with the Reality Debugger.
- Multiple weapons, grenades, elemental effects, multiplayer, advanced enemy navigation, stealth scoring, and combat upgrades.
- Full-body first-person animation or imported character rigs.

If a weapon is later required, prototype one infinite-ammo low-damage sidearm against a single robot type only after the sentinel/debugger loop is proven fun. Do not bind it to the debugger's existing left-click interaction without an explicit mode design.

## Four-level progression

### Level 1 — Access Denied

Controlled cyan research wing. Teach movement and one ability at a time with safe observation spaces. The anomaly is mostly environmental. Introduce a clearly disabled sentinel as foreshadowing; failure comes primarily from obvious pits or energy fields.

### Level 2 — Inverted

Amber machinery and violet gravity fractures. Use elevation, suspended architecture, and constrained gravity crates that clear routes rather than requiring the player to ride them. Add the first active sentinel behind dependable cover.

### Level 3 — Clock Failure

FREEZE-focused moving machinery, sweeping beams, and timed doors. Teach each hazard slowly before combining it with navigation. A short timed section can end the level, but restart remains quick.

### Level 4 — Kernel Panic

Red emergency lighting and collapsing facility silhouettes. Combine all three abilities in familiar forms, then trigger a final escape using sprint, jump, and debugger actions. Reuse known hazards with faster presentation instead of introducing a new mechanic. This is the only level likely to justify one midpoint escape checkpoint.

NULL SPINDLE can inform Level 2 composition or remain an experimental candidate; its layered route already demonstrates a phase gate, constrained gravity obstruction, moving freeze target, and visible upper exit.

## Team integration implications

### Jefin

- Keep level roots on `GameplayLevel`; do not add players, managers, or HUDs inside campaign levels.
- Author hazard telegraphs and safe observation positions directly in each level.
- Place failure volumes beneath real fall routes and call `fail_level(reason)` through level-owned logic.
- Use broad traversal metrics with the revised movement defaults. Do not design mandatory crate riding or precision air turns.
- Expose difficulty multipliers on hazards instead of duplicating Story/Challenge scenes.

### Anushree

- Continue using `GameFlowManager` signals and `get_snapshot()` for time, objective, score, failure, and replay.
- Use `RealityDebugger.ability_changed`, `target_changed`, and `target_context_changed` for the three ability indicators and contextual target feedback.
- A future sentinel/health system should expose signals such as `integrity_changed` and `threat_changed`; UI should not poll enemy nodes.
- Story/Challenge selection belongs in the menu and should create/set one shared config before gameplay starts.
- Keep gameplay mouse capture separate from interactive menu controls.

## Recommended order

1. Manually tune and approve the revised jump in the calibration chamber and NULL SPINDLE.
2. Add reusable kill volumes and consistent failure messaging.
3. Prototype one telegraphed sentinel in a developer scene.
4. Decide through playtesting whether health adds value; otherwise retain clear single-hit failure.
5. Add the small device viewmodel and connect final HUD signals.
6. Build and manually complete all four levels before considering a pistol or additional enemies.
