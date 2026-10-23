# GlitchVerse Game-Flow Integration

## Registering Jefin's levels

Each level root should extend `GameplayLevel` (directly, or through its existing root script):

```gdscript
extends GameplayLevel
```

Set `level_id`, `level_display_name`, `par_time_seconds`, and `base_score` in the Inspector. Add a `Marker3D` named `PlayerSpawn`, or set `player_spawn_path` to another Node3D spawn marker. It must be saved in the scene before `_ready()`; missing/empty/wrong-type paths now fail loading instead of spawning at the origin. Place its origin at the player's feet with at least 1.8 m headroom and 0.35 m radius clearance. Use yaw only and unit scale. Geometry clearance remains a level-author/playtest responsibility.

In `main.tscn`, select `Main` and populate `level_scenes` with the four `PackedScene` resources in play order. The current test chamber is the only registered scene until those files arrive. Do not create placeholder level scenes.

Level scripts drive flow through the inherited API:

- `mark_puzzle_completed()` when the puzzle condition becomes true.
- `mark_exit_unlocked()` when the exit becomes traversable.
- `finish_level()` when the player crosses the unlocked exit.
- `fail_level(reason)` for a level-specific failure.
- `report_objective(text, completed_steps, total_steps)` for UI progress.

Call `mark_puzzle_completed()` before `mark_exit_unlocked()`. `finish_level()` requires BOTH flags; completion and failure are idempotent. In a puzzle callback, unlock the actual door collision as well as the level flag. Connect `PuzzleExit.exit_reached` to `finish_level()`. The shared exit only accepts CharacterBody3D nodes in group `player`; the shared player scene already has that group. Keep the exit trigger on walkable ground with room beyond it. Monitoring areas currently use physics layer/mask 1; preserve or deliberately update this convention when integrating levels.

Do not add a second player, manager, or HUD inside each level. Keep level state inside its instantiated scene so restart resets it. Initial objective/failure signals from `_ready()` are supported. Detaching a level disconnects its manager listeners before deletion. Do not depend on old nodes after `level_loading`.

## UI integration for Anushree

Find the manager with:

```gdscript
var flow := get_tree().get_first_node_in_group("game_flow") as GameFlowManager
```

Available signals:

- `flow_state_changed(state)`
- `level_loading(level_index, level_path)`
- `level_started(level_index, level_name)`
- `puzzle_completed(level_index, elapsed_seconds)`
- `exit_unlocked(level_index)`
- `objective_updated(description, completed_steps, total_steps)`
- `time_updated(elapsed_seconds)`
- `score_updated(total_score)`
- `level_completed(level_index, elapsed_seconds, awarded_score)`
- `game_failed(reason)`
- `game_victory(total_elapsed_seconds, total_score)`
- `replay_started()`

Public controls include `start_game()`, `load_level(index)`, `restart_current_level()`, `advance_to_next_level()`, `fail_current_level(reason)`, and `replay_game()`.

`load_level(index)` queues a deferred load; await `level_started` or `game_failed`, rather than reading `current_level` immediately. It is an administrative level-selection API, not a completion command. Invalid indices, null slots, wrong root types, and missing spawns fail explicitly. `advance_to_next_level()` only works in `level_complete`; final victory requires completion of the last registered entry. Pending transitions are invalidated by restart/replay/new load. Avoid calling load/restart from every state signal: buttons should invoke commands once.

For a main menu, set `Main.auto_start = false`, connect UI signals, then call `start_game()` from Start. Default `true` preserves F5 testing. Connect signals once per UI instance and immediately read `get_snapshot()` to initialize late-mounted UI. Snapshot keys: `state`, `level_index`, `level_name`, `elapsed_seconds`, `total_elapsed_seconds`, `total_score`, `failure_reason`, `objective`, `completed_steps`, `total_steps`, and `exit_unlocked`. States are `boot` (idle/loading), `playing`, `level_complete`, `failed`, and `victory`. Menus must use the disabled player state for modal input; Esc alone only releases the cursor and does not pause the timer/world.

The current transition delay defaults to one second, then advances automatically; do not also advance from an ordinary completion animation unless deliberately taking ownership of that transition. A command that advances early is guarded against the pending timer. Failure is terminal for the attempt; retry reloads it. Character controls and debugger activation are disabled on failure/victory, but background physics is not globally paused.

Score per completed entry: `max(100, base_score + int((par_time - elapsed) * rate))`, with rate 10 under par and 5 over par. Total time counts successful attempts only. Loading/restarting entry N removes awarded results for N and later entries, retaining earlier results; replay resets everything. This prevents retry score accumulation. Tune par/base values after manual playtesting.

The temporary `FlowHUD` in `ui/hud.tscn` is only a signal consumer and can be replaced without changing gameplay code.

## Demonstration puzzle

`DemoPuzzleController` listens to the existing PHASE, GRAVITY, and FREEZE object signals. The exit unlocks when the barrier is phased, the crate has upward gravity, and the moving hazard is frozen simultaneously. Walking through `PuzzleExit` then calls `finish_level()`.

Once solved, the demonstration puzzle stays solved until restart. Keep it registered during integration, then replace only the `Main.level_scenes` list with the four final scenes when ready. The test chamber remains available for regression testing; it is not one of four fabricated final levels.

Run `pwsh -NoProfile -File .\tests\run_validation.ps1` from the project to validate import, all GDScript files, main-scene startup, and automated integration checks. Override `-Godot` for another installation. The installed engine is currently `C:\Tools\Godot\Godot.exe`; the old versioned filename is absent and its console wrapper cannot find it.
