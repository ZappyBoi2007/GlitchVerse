# GlitchVerse combat and mobility handoff

Milestone scope: momentum TETHER grappling, passive VECTOR RUN, BLADE melee, one SecurityConstruct, and the isolated BREACH LAB mechanics arena. No campaign level, REWIRE, gun, inventory, or additional enemy system is included.

## Run the vertical slice

Open `res://levels/experiments/breach_lab/breach_lab.tscn` and press **F6**. This preview owns its `GameFlowManager`, action-player variant, local developer HUD, and one `BreachLabLevel`. It does not alter `main.tscn` or campaign registration.

Controls:

- `WASD`: move
- `Shift`: sprint; hold with forward input beside a marked wall to VECTOR RUN
- `Space`: jump; wall-jump while VECTOR RUN is active
- `E`: attach or release TETHER; activates a targeted pull handle
- `F`: reserved for ordinary interaction and future REWIRE consoles
- Left mouse: BLADE slash
- `R`: restart after or during an attempt
- `Esc`: release mouse; left-click recaptures before attacking

## Files

- `res://player/action_player.tscn`: existing controller plus health, grapple, sword, and existing movement audio.
- `res://systems/grapple_controller.gd`: camera targeting, collision-safe pendulum constraint, momentum steering, tether rendering, and safety guards.
- `res://systems/vector_run_controller.gd`: marked-wall detection, bounded wall-run, camera roll, and wall-jump.
- `res://systems/sword_controller.gd`: camera-relative melee shape query, one-hit-per-swing guard, cooldown, animation and feedback.
- `res://player/player_health.gd`: three-segment reusable damage contract.
- `res://interactive/grapple_anchor.tscn`: traversal target.
- `res://interactive/vector_run_surface.tscn`: reusable marked VECTOR RUN wall.
- `res://interactive/tether_pull_handle.tscn`: one-shot machinery target.
- `res://interactive/retractable_bridge.tscn`: collision-bearing animated mechanism.
- `res://enemies/security_construct.tscn`: three-hit, direct-chase melee construct for simple open arenas.
- `res://levels/experiments/breach_lab/`: level, preview, and local developer HUD.

## Grapple target contract

The controller ray accepts a `CollisionObject3D`, or one of its parents, when it belongs to group `grapple_target` and implements:

```gdscript
func can_grapple() -> bool
func pulls_player() -> bool
func get_grapple_point() -> Vector3
func set_grapple_highlight(enabled: bool) -> void
```

Optional callbacks:

```gdscript
func on_grapple_attached(source: Node) -> void
func on_grapple_detached(source: Node) -> void
```

`GrappleAnchor` supplies this contract with `pulls_player() == true`. Pressing `E` stores the attachment distance as the rope length. While taut, the controller removes outward radial velocity and keeps tangential/inward velocity, so gravity and entry speed produce the swing. No position correction or teleport is used. Releasing with `E` retains current momentum at the default `1.0` multiplier. The player moves through the existing `CharacterBody3D` controller's single `move_and_slide()` call, so normal collision remains authoritative.

`TetherPullHandle` returns false from `pulls_player()`. Its `mechanism_path` is an exported path to a node implementing `activate()`. Pressing `E` while targeting it calls the handle once, shows a short tether response, and emits `pulled`; it never pulls the player or hardcodes level coordinates.

Verified default TETHER values:

- Maximum target range / maximum rope length: `22 m`
- Minimum rope length: `3 m`
- Anchor cutoff: `1.25 m`
- Swing acceleration: `8 m/s²`
- Air steering strength: `5 m/s²`
- Swing damping: `0.06 / second`
- Maximum tethered speed: `18 m/s`
- Release momentum multiplier: `1.0`
- Attachment correction responsiveness: `8`
- Gentle reel-in: `0.2 m/s`
- Collision obstruction grace: `0.45 s`; excessive extension or velocity releases safely

For Jefin's scenes:

1. Add `Marker3D` nodes named descriptively beneath an `ActionMarkers` node.
2. Instance `grapple_anchor.tscn` at traversal markers.
3. Instance `tether_pull_handle.tscn` at machinery controls and set `mechanism_path` to the authored mechanism.
4. Keep anchor-to-route distance within `22 m`; recommended authored swing gaps are `6–12 m` with the anchor `4–7 m` above the lowest part of the arc.
5. Give the approach at least `5 m` of sprint space and the receiving platform at least `3 m` of depth.
6. Leave `1.5–2 m` of clear lateral space beside a wall-run line and do not place solid geometry between the camera and an intended anchor.
7. Test the release arc at both 60 and 30 FPS; do not require a frame-perfect release.

## VECTOR RUN surface contract

Only collision objects with group `vector_run_surface` are accepted. Instance `res://interactive/vector_run_surface.tscn`, or add that group to a collision-bearing `StaticBody3D`. Ordinary walls are intentionally rejected.

The wall should be vertical, continuous, and long enough for a readable line. The controller uses left/right rays (`0.9 m`) and the physics collision normal to choose a tangent aligned with current travel. It applies a small into-wall velocity through `move_and_slide()` rather than changing position.

Verified defaults:

- Entry: airborne, holding `Shift` + forward, at least `5.5 m/s` horizontal speed
- Run speed target: `8.5 m/s`
- Maximum duration: `1.35 s`
- Gravity scale: `0.25`; maximum downward speed during run: `1.5 m/s`
- Camera roll: `5°`
- Wall-jump: `5.0 m/s` away, `5.5 m/s` upward, `75%` forward retention
- Same-wall reattachment lockout: `0.4 s`

For Jefin, recommended wall panels are `5–10 m` long and at least `3.5 m` high, with an obvious cyan/vector strip. Keep the receiving ledge at least `2.5 m` wide and avoid seams between collision shapes along the run. The action player already owns the controller; a level must only supply marked surfaces.

## Sword and damage contract

`SwordController` performs one `PhysicsDirectSpaceState3D.intersect_shape()` query per accepted attack. It walks from the collider to the first ancestor implementing:

```gdscript
func take_damage(amount: int, source: Node = null) -> bool
```

Return true only when damage was accepted. A target instance can be damaged at most once by one slash. `attack_started`, `attack_finished`, `hit_confirmed(target, damage)`, and `attack_missed` are available for replacement presentation/UI.

`PlayerHealth` implements the same method and exposes `health_changed`, `damaged`, and `player_defeated`. The current maximum is three segments with a short invulnerability interval.

## SecurityConstruct placement

For a future Level 1 integration, Jefin can provide `EnemySpawn` markers in simple open spaces. Keith's level adapter should instance `security_construct.tscn` at those transforms. Do not place it behind navigation obstacles: this milestone intentionally uses direct planar chase rather than `NavigationAgent3D`.

The construct exposes detection range, movement speed, attack range, windup, cooldown, damage, and health. Signals are `health_changed`, `attack_telegraphed`, and `deactivated`. Scene reload reconstructs its initial state.

## Level integration

`BreachLabLevel` uses the existing `GameplayLevel` contract. It unlocks its standard `PuzzleExit` only after the bridge deployment completes and the construct emits `deactivated`. Falling or losing all health calls `fail_level(reason)`, and `GameFlowManager.restart_current_level()` reloads every state.

Campaign adapters should hold exported `NodePath` references or connect component signals; they must not search for hardcoded world coordinates. Suggested marker names are `GrappleAnchor_*`, `TetherPullHandle_*`, `EnemySpawn_*`, and `ExitMarker`.

## Known limitations

- Grapple swing feel, VECTOR RUN camera comfort, tether readability, impact timing, audio balance, and final gap metrics require manual playtesting.
- TETHER is a lightweight velocity constraint, not a rigid-body rope chain; it intentionally does not wrap around corners.
- VECTOR RUN uses short side rays and is designed for continuous flat wall panels, not curved or heavily segmented geometry.
- The construct has no navigation mesh, ranged attack, group tactics, or advanced animation.
- The local HUD is developer-only and does not modify Anushree's UI.
- The original Reality Debugger remains unchanged in `player.tscn`; the action-player variant omits it so BLADE owns left-click only inside BREACH LAB.
