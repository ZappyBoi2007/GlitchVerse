# GlitchVerse Game-Flow Integration

## Registering Jefin's levels

Each level root should extend `GameplayLevel` (directly, or through its existing root script):

```gdscript
extends GameplayLevel
```

Set `level_id`, `level_display_name`, `par_time_seconds`, and `base_score` in the Inspector. Add a `Marker3D` named `PlayerSpawn`, or set `player_spawn_path` to another spawn marker.

In `main.tscn`, select `Main` and populate `level_scenes` with the four `PackedScene` resources in play order. The current test chamber is the only registered scene until those files arrive. Do not create placeholder level scenes.

Level scripts drive flow through the inherited API:

- `mark_puzzle_completed()` when the puzzle condition becomes true.
- `mark_exit_unlocked()` when the exit becomes traversable.
- `finish_level()` when the player crosses the unlocked exit.
- `fail_level(reason)` for a level-specific failure.
- `report_objective(text, completed_steps, total_steps)` for UI progress.

`finish_level()` intentionally does nothing until `mark_exit_unlocked()` has been called.

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

The temporary `FlowHUD` in `ui/hud.tscn` is only a signal consumer and can be replaced without changing gameplay code.

## Demonstration puzzle

`DemoPuzzleController` listens to the existing PHASE, GRAVITY, and FREEZE object signals. The exit unlocks when the barrier is phased, the crate has upward gravity, and the moving hazard is frozen simultaneously. Walking through `PuzzleExit` then calls `finish_level()`.
