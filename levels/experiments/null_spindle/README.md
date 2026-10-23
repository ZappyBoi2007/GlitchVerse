# Null Spindle — The Observation Chamber

Experimental `GameplayLevel` candidate built entirely from Godot primitives. It does not change the normal startup scene or registered campaign levels.

## Preview

Open `null_spindle_preview.tscn` and use **Run Current Scene (F6)**. The preview instantiates the existing player, HUD, `GameFlowManager`, and this level as its only registered scene.

## Intended route and solution

1. Walk down the observation corridor and follow the elevated west catwalk around the suspended core.
2. Select **PHASE** (`1`) and phase the cyan maintenance seal. Continue down the west ramp.
3. In the lower maintenance tunnel, select **GRAVITY** (`2`) and invert the amber crate. Its constrained upward travel clears the narrow gate; the crate is not intended as a rideable platform.
4. Follow the lower route east. Select **FREEZE** (`3`) and freeze the violet containment sweeper.
5. Collect at least **2 of 3 Reality Fragments**. One marks the entry, one rewards the maintenance route beyond the gravity gate, and one is an optional observation-deck detour.
6. Climb the east ramp. The exit unlocks only after all three debugger states and the fragment threshold are complete. Walk through the open exit.

Press `R` to restart the level. `Esc` releases the mouse and left-click recaptures it.

## Progression integration

When the level is approved, add `res://levels/experiments/null_spindle/null_spindle.tscn` to `Main.level_scenes` in the desired play order. Do not register the preview scene; it is a developer-only wrapper.

The root already extends `GameplayLevel`, has a valid `PlayerSpawn`, reports objective progress, unlocks its `PuzzleExit` through the standard contracts, and supplies par time/base score values.

## Fragment integration contract

`RealityFragment` is reusable and emits `fragment_collected(fragment_id)` exactly once after validating a `CharacterBody3D` in the `player` group. NULL SPINDLE owns its threshold logic through `NullSpindleFragments`; other levels can use the pickup without inheriting this prototype's rules.

The NULL SPINDLE level root emits `fragment_progress_changed(collected, required, total)` and exposes `get_fragment_snapshot()` for late-binding UI. The standalone preview's fragment panel consumes this API; no shared or teammate-owned HUD scene is changed. Reloading the level reconstructs the controller and all three pickups, resetting collection state naturally.

## Limitations and playtest focus

- Primitive geometry and procedural materials are deliberate greybox-quality assets.
- Human testing is still required for route readability, label scale, lighting on the target display, collision seams on both ramps, and whether the moving sweeper feels fair at different frame rates.
- The puzzle is state-based like the calibration chamber: after the three required states are simultaneously achieved, unlocking is permanent for that attempt.
