# GlitchVerse — Anushree UI Architecture & Gameplay HUD Handoff

**Branch:** `feature/anushree-ui`
**Engine:** Godot 4.7.2 (`v4.7.2.stable.official.ed1daf0bf`)
**Target Resolution:** 1280×720 (Scalable Canvas Item mode)
**Primary Integration Document for:** Keith / Gameplay Integration Team

---

## 1. Actual Scene and Script Paths

### Production UI Scenes (`scenes/ui/`)
* **`scenes/ui/in_game_hud.tscn`**: Modular tactical gameplay HUD with survival integrity bar, grapple/target reticle, equipment loadout, mission objectives, timer, score, and transient notification banner.
* **`scenes/ui/main_menu.tscn`**: Primary menu with industrial glitch identity, sector selection, settings modal, and exit flow.
* **`scenes/ui/pause_menu.tscn`**: Modal overlay for pausing gameplay, restarting chambers, or returning to mainframe.
* **`scenes/ui/level_complete.tscn`**: Summary screen reporting clearance time, par evaluation, and progression to next sector.
* **`scenes/ui/game_over.tscn`**: Containment breach / spatial disintegration failure modal with retry support.
* **`scenes/ui/ui_preview.tscn`**: Standalone F6 development harness for simulating all gameplay states and screen flows.

### Production UI Scripts (`scripts/ui/`)
* **`scripts/ui/in_game_hud.gd`**: Controller for in-game HUD, public API methods, signal listeners, and auto-connection to `GameFlowManager` and `RealityDebugger`.
* **`scripts/ui/main_menu.gd`**: Main menu controller and button signal dispatcher.
* **`scripts/ui/pause_menu.gd`**: Pause menu controller with modal state handling.
* **`scripts/ui/level_complete.gd`**: Completion screen metrics and score calculation display.
* **`scripts/ui/game_over.gd`**: Failure reason formatting and retry signal emitter.
* **`scripts/ui/ui_preview.gd`**: Test harness controller providing interactive simulation buttons.
* **`scripts/ui/ui_colors.gd`**: Standardized palette constants (Base charcoal, Dark teal frame, Cold white text, Cyan/Amber/Violet abilities, Tool accents, Critical red).
* **`scripts/ui/glitch_text.gd`**: Procedural glitch label generator for titles and headers.
* **`scripts/ui/crt_overlay.gd`**: Scanline and subtle screen curvature overlay shader.

### Shared Assets & Theme (`assets/ui/`)
* **`assets/ui/research_theme.tres`**: Thin-bordered dark-industrial research theme (`SystemFont_mono` fallback font stack: Consolas, Courier New, monospace).

---

## 2. Public UI Method Signatures & Argument Types

The `InGameHUD` (`scripts/ui/in_game_hud.gd`) exposes the following callable API:

### Mission & Progression
```gdscript
func set_level(level_id: int) -> void
```
Updates chamber ID (1–4), default chamber code (`GV-01` to `GV-04`), name, and baseline corruption.

```gdscript
func set_level_name(level_name: String, code: String = "") -> void
```
Sets custom level title and optional chamber code (e.g., `set_level_name("SYSTEM BREACH", "GV-01")`).

```gdscript
func set_objective(text: String) -> void
```
Updates the primary objective display label.

```gdscript
func set_objective_progress(completed: int, total: int, step_desc: String = "") -> void
```
Updates numerical progress and progress bar (e.g., `completed = 1, total = 2, step_desc = "CIRCUITS"` renders `CIRCUITS: 1/2`). Hides the progress bar if `total <= 0`.

### Performance
```gdscript
func set_timer_seconds(seconds: float) -> void
```
Updates simulation timer readout (`MM:SS.ss`). When called externally, internal HUD timer calculation is automatically disabled.

```gdscript
func set_score(points: int) -> void
```
Updates formatted score counter (`SCORE: %05d`).

### Survival & Vitals
```gdscript
func set_health(current: float, max_health: float = -1.0) -> void
```
Updates the integrity bar and readout (`%d / %d HP`). In production, the HUD starts in a neutral uninitialized state (`-- / -- HP`, 0 bar value, alert hidden) and does NOT assume a default health value. On the first call, `max_health` should be provided by the gameplay caller (if omitted, `current` is used as initial baseline). If `current / max_health <= 0.30`, displays the critical low-health warning (`! CRITICAL INTEGRITY LEVEL !`), shifts bar and label to warning red (`#FF4057`), and emits `health_warning_triggered`.

### Targeting & Interaction
```gdscript
func set_grapple_target(has_target: bool, is_valid: bool = false, anchor_label: String = "") -> void
```
Toggles the targeting crosshair grapple brackets. If `is_valid` is true, displays brackets in cyan/green with prompt `[E] TETHER // <ANCHOR_LABEL>`. If `is_valid` is false, displays brackets in warning red with `INVALID ANCHOR // OUT OF RANGE`.

```gdscript
func show_interaction_prompt(prompt_text: String, key_hint: String = "F") -> void
```
Displays a contextual prompt below the reticle (e.g. `[F] OPERATE CONSOLE`).

```gdscript
func hide_interaction_prompt() -> void
```
Clears and hides contextual interaction prompt.

```gdscript
func set_target_prompt(prompt_text: String, is_compatible: bool = true) -> void
```
*Backward-compatible adapter* for `RealityDebugger.target_changed`.

### Equipment & Loadout
```gdscript
func set_tether_status(status_text: String, is_attached: bool = false) -> void
```
Updates TETHER indicator in bottom-right loadout (`READY`, `ATTACHED`, `COOLDOWN`). Attached status is rendered in calibrated green (`#38EF7D`).

```gdscript
func set_blade_status(status_text: String, is_ready: bool = true) -> void
```
Updates BLADE status indicator (`READY`, `STRIKE`, `COOLDOWN`) in tactical amber (`#FFB830`).

```gdscript
func set_equipped_tool(tool_id: String, tool_label: String = "", tool_status: String = "READY", tool_color: Color = Color.WHITE) -> void
```
Updates active environmental vector or auxiliary tool slot (e.g. `POLARITY`, `REWIRE`, or legacy `PHASE`).

```gdscript
func set_ability(mode: String) -> void
```
*Backward-compatible adapter* for legacy ability switching (`PHASE`, `GRAVITY`, `FREEZE`).

### Transient Notifications & Hints
```gdscript
func show_notification(message: String, is_alert: bool = false, duration: float = 2.5) -> void
```
Displays a sleek transient banner at upper-center with smooth fade-in and fade-out tweening. Alert messages are tinted red (`#FF4057`), standard messages are cold cyan (`#39F5FF`).

```gdscript
func set_control_hints(hints_text: String) -> void
```
Updates bottom-left keybind helper text (default: `[E] TETHER  [F] INTERACT  [LMB] BLADE  [SHIFT] VECTOR RUN  [SPACE] JUMP`).

---

## 3. UI Signals

* `signal notification_displayed(message: String, is_alert: bool)`: Emitted whenever a notification is triggered.
* `signal health_warning_triggered(current: float, max_health: float)`: Emitted when health falls to or below 30%.
* `signal tool_selected(tool_id: String)`: Emitted when an equipment slot or tool is activated.

---

## 4. Automatic Gameplay Connections

`InGameHUD` automatically detects and connects to existing nodes on `_ready()` via groups:

1. **`GameFlowManager` (group `"game_flow"` or `"game_flow_manager"`):**
   * `level_started(level_index, level_name)` $\rightarrow$ calls `set_level_name()` and triggers level start notification.
   * `objective_updated(desc, completed, total)` $\rightarrow$ calls `set_objective()` and `set_objective_progress()`.
   * `time_updated(seconds)` $\rightarrow$ calls `set_timer_seconds()`.
   * `score_updated(points)` $\rightarrow$ calls `set_score()`.
   * `puzzle_completed(index, elapsed)` $\rightarrow$ triggers notification `"PUZZLE SOLVED // EXIT UNLOCKED"`.
   * `exit_unlocked(index)` $\rightarrow$ triggers notification `"CONTAINMENT EXIT UNLOCKED"`.
   * `game_failed(reason)` $\rightarrow$ triggers alert notification `"CRITICAL FAILURE: <REASON>"`.
   * `game_victory(time, score)` $\rightarrow$ triggers notification `"SIMULATION COMPLETE // ALL SECTORS CLEARED"`.

2. **`RealityDebugger` (group `"reality_debugger"`):**
   * `ability_changed(label, color)` $\rightarrow$ calls `set_ability(label)`.
   * `target_changed(label, compatible, has_target)` $\rightarrow$ updates `set_target_prompt()` and `set_grapple_target()`.
   * `feedback_changed(message, is_error)` $\rightarrow$ triggers transient notification.

---

## 5. Verified vs. Provisional Mechanics

| Mechanic | Implementation Status | UI Representation | Notes |
| :--- | :--- | :--- | :--- |
| **Mission / Objective** | **Verified (GameFlowManager)** | Top-left title, objective string, progress bar | Fully connected to `GameFlowManager` signals |
| **Timer & Score** | **Verified (GameFlowManager)** | Top-right digital readout | 10Hz updates supported |
| **Survival / Health** | **UI Implemented; Gameplay Pending** | Bottom-left health bar + critical alert | Driven via `set_health()`; default 100/100 |
| **TETHER (Grapple)** | **UI Implemented; Movement In-Progress** | Crosshair brackets + loadout status | `READY`, `ATTACHED`, `RELEASED` states verified |
| **BLADE (Melee)** | **UI Implemented; Initial Prototype** | Loadout slot | Amber indicator for readiness / strike |
| **VECTOR RUN** | **Provisional (Simulated Feedback)** | Notification banner / hints | Simulated via `"WALL RUN ACTIVE"` event |
| **POLARITY** | **Provisional (Mock Demonstration)** | Auxiliary tool slot | Configurable loadout demonstration |
| **REWIRE** | **Provisional (Mock Demonstration)** | Auxiliary tool slot | Configurable loadout demonstration |
| **PHASE / GRAV / FREEZE** | **Verified Legacy** | Supported via `set_ability()` | Backwards-compatible |

---

## 6. Standalone Preview Instructions & Controls

To launch the preview harness in Godot:
1. Open the project in Godot 4.7.2.
2. Open `res://scenes/ui/ui_preview.tscn`.
3. Press **`F6`** (Run Current Scene).

### Interactive Test Controls (via Docked Toolbar)
* **Screen Selector (Top Bar):** Switch instantly between `[ MAIN MENU ]`, `[ HUD ]`, `[ PAUSE ]`, `[ LEVEL COMPLETE ]`, `[ GAME OVER ]`.
* **Level Escalation (Row 1):** `L1: ACCESS`, `L2: INVERTED`, `L3: CLOCK`, `L4: PANIC`.
* **Health Simulation (Row 1):** `-25 HP`, `+25 HP`, `15 HP [CRIT]` (demonstrates red pulse warning).
* **Score (Row 1):** `+250 PTS`.
* **Objective Steps (Row 2):** `OBJ 0/2`, `OBJ 1/2`, `OBJ 2/2` (demonstrates completion event).
* **Grapple Target (Row 2):** `ANCHOR VALID` (cyan brackets), `ANCHOR INVALID` (red brackets), `NO ANCHOR`.
* **Tether State (Row 3):** `READY`, `ATTACHED` (green), `RELEASED`.
* **Blade State (Row 3):** `READY`, `STRIKE`.
* **Vector Run (Row 3):** `WALL RUN [SIM]` (fires transient notification).
* **Mock Tools (Row 4):** `POLARITY (MOCK)`, `REWIRE (MOCK)`, `PHASE`, `GRAV`, `FREEZE`.
* **Notifications (Row 4):** `BREACH`, `RELAY`, `UNLOCKED`.
* **Toggle Toolbar:** Press **`TAB`** at any time to hide/show the developer simulation dock.

---

## 7. Integration Responsibilities for Keith

1. **Player Health Wiring:** When damage or environmental hazards are connected to player integrity, call:
   ```gdscript
   hud.set_health(player.current_health, player.max_health)
   ```
2. **Grapple Anchor Raycast:** When the tether raycast detects a grapple anchor, emit or call:
   ```gdscript
   hud.set_grapple_target(has_target, is_within_range_and_valid, anchor_name)
   ```
3. **Tether State Changes:** On grapple attachment/release:
   ```gdscript
   hud.set_tether_status("ATTACHED", true)
   # and on release:
   hud.set_tether_status("READY", false)
   ```
4. **Contextual Interactions:** For interactable machinery / levers:
   ```gdscript
   hud.show_interaction_prompt("ACTIVATE CIRCUIT CONSOLE", "F")
   # and on looking away:
   hud.hide_interaction_prompt()
   ```
5. **No Production Code Editing Needed:** The HUD is fully self-contained in `scenes/ui/` and `scripts/ui/`. No changes to `project.godot`, `player_controller.gd`, or `game_flow_manager.gd` are required for UI operation.
