# GlitchVerse integration engineering audit

Date: 2026-10-23. Branch: `feature/integration-preflight`.
Baseline: `1b66f98` (merged game-flow milestone); working tree was clean when inspection began.
Engine tested: `4.7.2.stable.official.ed1daf0bf` at `C:\Tools\Godot\Godot.exe`.

## Scope and evidence

Read the player, debugger, all interactable/flow/puzzle scripts, all scenes, project settings, prototype HUD scripts, and both handoff documents. No four final level scenes or teammate final UI scenes are present in this checkout. Their other branches were not inspected or modified. This report assesses the PS01 requirements supplied in the conversation, not an independently obtained competition rubric.

The initial five-check regression run reproduced four failures on the unmodified implementation: advancing without completing, pitch surviving restart, invalid index reporting victory, and completing an unsolved puzzle via the level contract. After fixes, the expanded suite passes 44 checks. Other defects below were identified from explicit source paths and covered with targeted regression cases where listed.

## Confirmed working systems

- FPS source retains delta-based acceleration/gravity, normalized WASD input, separate body yaw/head pitch, +/-85 degree clamp, and `screen_relative` mouse handling in `_input`. The controller code was not changed. Physical mouse feel was manually verified by the user earlier, not reverified in this audit.
- Camera raycasts activate the actual PHASE, GRAVITY, and FREEZE objects in the loaded chamber under headless physics. Incompatible targets have an explicit status/feedback path.
- PHASE disables its solid shape while a separate sensor remains targetable; settled occupancy prevents restoration over the player.
- GRAVITY uses RigidBody3D gravity inversion; the test observes upward movement staying inside the configured vertical bounds.
- FREEZE stops only the chosen hazard and leaves its collision shape enabled.
- All three interactions together unlock the existing chamber exit. Simulated player movement through its real Area3D transitions to the next registered scene. Tests do not call the exit callback to stand in for that successful traversal.
- Restart recreates puzzle objects and exit, resets velocity/view/spawn/time, and keeps exactly one manager completion connection on the new level.
- Successful attempts award the intended formula once; failure/completion stop attempt time; retry preserves earlier entries; replay resets run results.
- Import, all GDScript resources, and production main-scene startup pass with no reported parser/missing-resource/runtime errors.

## Confirmed defects fixed

| Defect / trigger | Change and verification |
| --- | --- |
| `load_level(-1)` or an empty registry called victory | Invalid index/empty/null registration fails explicitly. Tests cover all three and wrong root type. |
| Public advance skipped an unfinished level | Advance requires `level_complete`; normal final victory occurs only after the last registered entry completes. |
| Level contract accepted exit unlock/completion before puzzle completion | Both puzzle and exit flags are required; terminal events are idempotent; failure blocks later completion. Baseline reproduction and final tests cover these guards. |
| Persistent Head pitch remained after reload | Spawn reset also resets Head rotation. Reproduced before fix and checked after. |
| Missing spawn silently placed player at level origin | Manager validates a saved Node3D spawn before replacing the level, and reports a configuration failure. Test fixture omits the marker. It does not test or automatically repair geometry clearance. |
| Level `_ready()` objective/failure emissions were missed because listeners connected afterward | Connect before entering tree, retain objective state, publish it after start, expose a snapshot. Test-only fixtures emit objective and failure in `_ready()`. |
| Old completion coroutine could advance a newly completed retry | A generation token invalidates obsolete loads/timers. Test completes, restarts while timer pending, completes again, and checks only the current timer advances. |
| Restarting a just-completed entry could keep its old award and accumulate another | Keep one result per registry entry; loading N removes N and later results. Tests check rollback and earlier-score preservation. |
| Zero-delay transitions could mutate physics bodies during an Area callback | Loads are deferred. Actual Area-triggered traversal with zero transition delay passes without physics-flush errors. |
| Any CharacterBody3D could trigger the exit | Require the `player` group, added to the existing player scene. Non-player character test is rejected. |
| Unlocking while already in the trigger never completed until leaving/re-entering | Deferred overlap check after unlock; tested with a real overlapping player, locked/unlocked state, and duplicate unlock. |

Disconnection of manager signals before old-level removal prevents outgoing scenes from reporting stale events. Normal repeated reloads did not show duplicate connections. No changes were made to PHASE/GRAVITY/FREEZE implementations or player movement code.

## Validation and repeatable commands

From the project in PowerShell 7:

```powershell
pwsh -NoProfile -File .\tests\run_validation.ps1
```

The runner explicitly waits for the Windows GUI executable, captures stderr, rejects nonzero exits and reported errors, and imposes a 30-second timeout per invocation. Logs remain ignored under `.godot/audit-validation/`.

| Check | Exact engine arguments / result |
| --- | --- |
| Import/global class scan | `--headless --path C:\GlitchVerse\glitchverse --editor --quit`: exit 0 |
| Explicit script parsing | `--headless --path ... --check-only --script res://<script>` for all 14 `.gd` files: exit 0 each |
| Main scene smoke | `--headless --path ... --quit-after 300`: exit 0 |
| Integration suite | `--headless --path ... --script res://tests/integration_checks.gd`: 44 checks, 0 failures, exit 0 |
| Whitespace | `git diff --check`: exit 0 |

The suite uses the existing chamber twice in memory for transition testing; it creates no replacement level scenes. `ready_level_fixture.gd` is a minimal test-only lifecycle fixture, never registered in Main. The first extended test run had three clock assertions assuming zero elapsed time despite startup frames; explicitly initializing the deterministic test clock resolved those test errors.

The requested versioned executable path does not exist. Its console launcher still expects the old name and is unusable. Direct `Godot.exe` is the tested engine; no installation files were changed.

## Untested behavior and remaining risks

- Headless checks prove scripted state/physics behavior, not visible playability, lighting, UI layout, physical mouse input, audio, frame pacing, or performance on the submission machine.
- PHASE occupancy is based on Area3D's latest physics overlap list. Ordinary settled overlap is covered; restoration on the exact frame of entering a barrier remains a race risk to manually test. No speculative physics rewrite was made.
- Gravity bounds are a vertical tether to the initial world position. Rotated/nonuniformly scaled rigid-body parents and player crushing/pushing comfort are not tested. Keep physics roots unscaled and test each placement.
- The corridor floor ends at z=25.5; the exit trigger is centered at z=26.1. Headless forward traversal succeeds, but edge footing is tight and the door is narrower than the corridor. Check slow/diagonal traversal manually before shipping; do not infer comfortable geometry from the test.
- Solving the demo is latched. Reversing an ability afterward does not relock the exit; restart resets it. This is current demo behavior, not a four-level puzzle design.
- Prototype HUD still says M2, does not list R in its normal controls, and retains solved-objective color after a current-level restart. These are confirmed cosmetic issues left to final UI integration; no teammate UI was changed.
- Esc releases the cursor but does not pause play/time. Failure/victory disable player/debugger input; background world physics continues. A pause-menu feature is not implemented here.
- UI/level code must not emit completion directly or use administrative `load_level` as a gameplay exit. Use the documented contract. Spawn obstruction/headroom must be checked by level authors.
- Timers exclude loading, transitions, and abandoned attempts; final total is the sum of successful attempts. Confirm this scoring policy with the team.

## Remaining PS01 requirements

Based on the supplied checklist: the FPS foundation, three mechanics, one interactive puzzle, scoring/timer, restart, and win/failure framework exist. FOUR distinct playable levels are still absent. Final main menu/HUD/result screens are pending. Level-specific reachable loss conditions are pending (the current hazard does not damage; falling below -20 triggers failure). A complete four-level progression, difficulty/score balance, manual playthrough, and exported Windows build remain unverified. No claim of a complete PS01 submission is made.

## Compatibility for Jefin

1. Read `systems/GAME_FLOW_INTEGRATION.md`. Retain his actual scenes and existing root logic; adapt each root to inherit `GameplayLevel`.
2. Save a feet-position Node3D/Marker3D spawn in each scene. Do not include duplicate player, manager, or HUD instances. Keep root scale 1 and author collision clearance.
3. Use actual object state signals/puzzle logic, then call `mark_puzzle_completed()`, unlock the physical exit, and `mark_exit_unlocked()`. Connect the player-only exit trigger to `finish_level()`. Report real failure with `fail_level(reason)`.
4. Register the four actual PackedScenes in `Main.level_scenes` only when present; preserve the developer chamber as an unregistered regression scene if it is no longer in the final sequence.
5. Check collision masks, line of sight/range (12 m), phased sensor targeting, spawn location, exit trigger ground coverage, and ability compatibility in each scene. Tune par/base values after playtesting.

## Compatibility for Anushree

- Use the `game_flow` group and existing signals; initialize late-mounted UI from `get_snapshot()` after connecting once. Detailed keys, timing, and methods are in the integration guide.
- Set `Main.auto_start=false` for menu-controlled startup; Start invokes `start_game()`. Default true preserves developer F5 launch.
- Restart invokes `restart_current_level()` and replay invokes `replay_game()`. Loading is asynchronous; wait for `level_started`/`game_failed`. Avoid duplicate automatic progression: the manager already advances after its configured delay.
- Only decorative Controls should ignore mouse input. Interactive menus consume clicks normally and must run while gameplay input is disabled. Do not route mouse-look through GUI callbacks.
- Existing debugger signals remain separate from flow signals. Replace the prototype HUD only when the final UI is ready; this audit changes no UI scripts/scenes.

## Git integration risks and order

No branch switching, Git configuration changes, merges, pushes, or teammate-branch edits were performed. Current changes are uncommitted on `feature/integration-preflight`.

1. Review/commit these shared flow fixes and tests on this feature branch through the team's normal process.
2. Have level/UI authors integrate the documented shared API first. They should resolve any existing root-script inheritance intentionally rather than overwrite scenes.
3. Integrate Jefin's real scene/assets changes; one designated integrator updates `main.tscn` registration.
4. Integrate Anushree's UI and connect signals. Assign ownership of `main.tscn` and `project.godot` to avoid concurrent conflicting edits.
5. Run validation and one full manual run after each integration. Keep script `.uid` files with their scripts; do not commit `.godot` caches/logs. The player scene's new group is a small likely merge-conflict point; retain it if another branch changes that root.

## Recommended next tasks by urgency

1. P0: Team member manually completes the current demo: F5, 1/phase and pass barrier, 2/invert crate, 3/freeze hazard, traverse green exit, verify victory, R/replay. Also R while looking up/down and while partway through puzzle; verify all state resets. Try failure/retry and each exit approach.
2. P0: Bring in the actual four scenes and validate all spawn/puzzle/exit/failure contracts, then test their real sequence. No fabricated scene can substitute for this.
3. P0: Integrate final menu/HUD/results with auto-start disabled and late-state snapshot; manually test cursor/menu click ownership and retry/replay.
4. P1: Check phase entry-edge timing, crate/player contact, frozen-hazard passage, doorway footing, and all level boundaries for softlocks.
5. P1: Tune par times/score and approve the successful-attempt time policy.
6. P0 before submission: Export Windows build, run it outside the editor on the intended machine, and complete all four levels including failure/restart. Confirm the official rubric and submission requirements with the organizers.
