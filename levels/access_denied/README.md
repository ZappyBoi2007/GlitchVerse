# Level 1 — Access Denied

Gameplay integration around Jefin's untouched `res://levels/access_denied.tscn` environment.

## Run

Open `access_denied_preview.tscn` and press **F6** for the isolated developer preview. The normal `main.tscn` remains the regression-tested calibration chamber until Jefin's Level 2 scene is available and the final campaign list can be registered together.

## Solution

1. Follow the facility route from the start room into the western corridor.
2. Select **PHASE** (`1`) and phase the cyan restricted-access seal.
3. Continue through the upper room and cross the damaged industrial bridge. Falling below the facility triggers a recoverable failure; press `R` to retry.
4. Cross the cyan access relay on the upper exit approach.
5. The containment exit unlocks only after both the PHASE tutorial and relay traversal objectives have latched. Enter the exit to complete Level 1.

## Integration contract

The wrapper root extends `GameplayLevel`, supplies `PlayerSpawn`, reports a two-step objective, unlocks a standard `PuzzleExit`, and uses the normal completion/failure signals. Add later level `PackedScene` resources after `access_denied_level.tscn` in `Main.level_scenes`; no Level 2 replacement has been fabricated here.

The original `access_denied.tscn` remains an environment-only scene. Its visual phase placeholder is hidden and has collision disabled at runtime by the wrapper so the reusable `PhaseableBarrier` can occupy the authored location.
