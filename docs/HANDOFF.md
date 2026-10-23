# GlitchVerse Game Progression Handoff

## Integration preflight update (2026-10-23)

Audit and validation details are in `docs/INTEGRATION_AUDIT.md`. Work remains on `feature/integration-preflight`; no merge, push, Git configuration change, or teammate scene edit was performed.

Shared fixes: invalid registrations fail instead of winning; progression requires completed puzzle/exit state; loading is deferred and validates the saved spawn; obsolete transition timers are cancelled; retries remove the retried entry's previous score/time; camera pitch resets; initial level signals are captured; exits recognize only the `player` group and handle a player already in their trigger when unlocked.

Integration additions: `Main.auto_start` supports the future main menu and `GameFlowManager.get_snapshot()` initializes UI that connects late. The detailed contract in `systems/GAME_FLOW_INTEGRATION.md` now documents asynchronous loads, spawn placement, input ownership, scoring, and transition behavior.

Preflight files changed: `systems/game_flow_manager.gd`, `systems/gameplay_level.gd`, `interactive/puzzle_exit.gd`, `player/player.tscn` (group only), this handoff, and `systems/GAME_FLOW_INTEGRATION.md`. Added `docs/INTEGRATION_AUDIT.md`, `tests/integration_checks.gd`, `tests/ready_level_fixture.gd`, `tests/run_validation.ps1`, and generated test script UIDs. The earlier milestone file inventory below is historical.

Validation: Godot 4.7.2 import and 300-frame startup passed; all 14 GDScript files parsed; 44 automated checks passed; whitespace check passed. Commands and limits are recorded in the audit. Run the manual demonstration steps below, including restart after looking steeply upward/downward, before integrating final levels.

## Implemented features

- `GameFlowManager` starts a run, loads registered `PackedScene` levels, places the persistent player at each level's spawn, restarts the current level, advances in sequence, and supports replay after victory.
- `GameplayLevel` provides a reusable contract for puzzle completion, exit unlocking, objective progress, level completion, and level-specific failure.
- Level time is tracked while the flow state is `playing` and emitted to UI ten times per second.
- Each completed level awards at least 100 points. The score starts from `base_score`, gains 10 points per second under par, and loses 5 points per second over par.
- Falling below the manager's `failure_height` triggers failure. Levels can also call `fail_level(reason)` for their own hazards or conditions.
- `R` restarts during gameplay/failure and replays from the configured starting level after victory.
- The existing test chamber contains a functional demonstration puzzle. The player must phase the barrier, invert the gravity crate, and freeze the moving hazard simultaneously. This unlocks the physical exit; crossing it finishes the level.
- The FPS controller and Reality Debugger remain reusable and were not replaced.

## Files created

- `systems/game_flow_manager.gd`
- `systems/gameplay_level.gd`
- `systems/GAME_FLOW_INTEGRATION.md`
- `levels/demo_puzzle_controller.gd`
- `interactive/puzzle_exit.gd`
- `interactive/puzzle_exit.tscn`
- `ui/game_flow_hud.gd`
- `docs/HANDOFF.md`

Godot also generated matching `.gd.uid` files for new GDScript resources.

## Files changed

- `main.tscn`: attaches `GameFlowManager`, adds `LevelContainer`, and registers the test chamber.
- `project.godot`: adds the `restart_level` input action on `R`.
- `levels/test_chamber.gd`: implements the `GameplayLevel` contract and connects puzzle/exit events.
- `levels/test_chamber.tscn`: adds the spawn marker, three puzzle objects, puzzle controller, and functional exit.
- `interactive/phaseable_barrier.gd`: emits its phase state.
- `interactive/gravity_crate.gd`: emits its gravity state.
- `interactive/moving_hazard.gd`: emits its freeze state.
- `ui/hud.tscn`: adds a temporary signal-driven flow display. It contains no progression logic.

## Level integration contract for Jefin

Do not duplicate the player or flow manager inside a level. The root of every playable level should extend `GameplayLevel`:

```gdscript
extends GameplayLevel
```

Configure `level_id`, `level_display_name`, `par_time_seconds`, and `base_score`. Add a `Marker3D` named `PlayerSpawn`, or assign another marker to `player_spawn_path`.

Call the inherited methods from the level's puzzle logic:

```gdscript
report_objective("Objective description", completed_steps, total_steps)
mark_puzzle_completed()
mark_exit_unlocked()
finish_level() # ignored until the exit has been unlocked
fail_level("Reason shown to the player")
```

When the four scenes arrive, select `Main` in `main.tscn` and place their `PackedScene` resources in `level_scenes` in the intended order. Remove the test chamber from that list only when it is no longer part of the shipped sequence. No replacement level scenes have been fabricated.

## UI integration contract for Anushree

The final UI can locate the manager without depending on `main.tscn` paths:

```gdscript
var flow := get_tree().get_first_node_in_group("game_flow") as GameFlowManager
```

Signals available to UI:

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

Public commands are `start_game()`, `load_level(index)`, `restart_current_level()`, `advance_to_next_level()`, `fail_current_level(reason)`, and `replay_game()`.

The current `FlowHUD` is a temporary subscriber and can be deleted or replaced without modifying gameplay systems.

## Manual demonstration test

1. Run the project with F5.
2. Use `1` and left-click to phase the cyan corridor barrier, then pass through it.
3. Use `2` and left-click to invert the labelled gravity crate.
4. Use `3` and left-click to freeze the moving hazard.
5. Confirm the objective reaches `3/3` and the exit changes from locked red to open green.
6. Walk through the open exit and confirm the victory summary appears with elapsed time and score.
7. Press `R` on the victory screen to replay.
8. Press `R` during gameplay to confirm that the chamber and all puzzle states reset.

## Remaining integration tasks

- Register Jefin's four final level scenes in `Main.level_scenes` in play order.
- Ensure each final level implements `GameplayLevel` and has a valid spawn marker and completion trigger.
- Connect real level hazards to `fail_level(reason)` where a loss condition is intended.
- Replace the temporary `FlowHUD` with Anushree's final UI and connect the documented signals.
- Tune each level's par time and base score after playtesting.
- Decide whether the demonstration chamber remains in the final level sequence or becomes a developer-only test scene.

## Known limitations and bugs

- No known parser or startup errors are present in the implemented files.
- The demonstration moving hazard retains collision but does not damage the player; it is a puzzle obstacle, not yet a failure trigger.
- Only the test chamber is registered because the four teammate level scenes are not present on this branch.
- Headless testing cannot verify physical input feel, visual clarity, collision comfort, or doorway traversal from a player's perspective.
- Total run time currently sums successful level attempts; time spent in abandoned/restarted attempts is not added to the final total.

## Next development steps

1. Manually playtest the demonstration sequence and tune object positions if needed.
2. Merge and register the four final level scenes.
3. Connect each level's puzzle state and exit to the shared contract.
4. Integrate the final UI through the manager signals.
5. Add level-specific failure conditions and test restart recovery.
6. Perform a complete four-level playthrough and balance par times and scoring.
