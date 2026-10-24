# GlitchVerse — Production UI Delivery & Campaign Wayfinding Handoff

* **Branch:** `feature/anushree-ui`
* **Engine:** Godot 4.7.2 (`v4.7.2.stable.official.ed1daf0bf`)
* **Target Resolution:** 1280×720 (Scalable Canvas Item mode)
* **Primary Integration Document for:** Keith / Gameplay & Campaign Integration Team

---

## 1. Actual Scene and Script Paths

### Production UI Scenes (`scenes/ui/`)
* **`scenes/ui/in_game_hud.tscn`**: Modular tactical gameplay HUD featuring dynamic mission wayfinding hints, step-by-step objective progress, survival integrity monitoring, grapple/interaction reticle, 5-slot tactical equipment loadout (Tether, Blade, Polarity, Rewire, Vector), timer, score, and transient notification banner.
* **`scenes/ui/main_menu.tscn`**: Clinical research facility entrance screen with glitch title effects, sector dispatch prompts, verified control guide modal, audio/sensor calibration modal, and exit flow.
* **`scenes/ui/pause_menu.tscn`**: In-game observation pause overlay with chamber status, resume, chamber recalibration, workstation settings calibration modal, and abort to terminal options.
* **`scenes/ui/level_complete.tscn`**: Sector clearance summary reporting runtime, par time score evaluation, and advance to next sector request.
* **`scenes/ui/game_over.tscn`**: Containment breach / matrix collapse failure modal with detailed exception reason and retry request.
* **`scenes/ui/final_victory.tscn`**: Dedicated campaign completion screen reporting total campaign runtime, final score, all 4 sectors restored, simulation replay, and return to main menu requests.
* **`scenes/ui/ui_preview.tscn`**: Standalone F6 developer simulation harness supporting instant testing across all 6 screens and all 4 campaign levels with full mock control docks.

### Production UI Scripts (`scripts/ui/`)
* **`scripts/ui/in_game_hud.gd`**: Full controller for the in-game HUD. Implements all public callable APIs, neutral production defaults, contextual wayfinding heuristics, and safe automatic binding to `GameFlowManager` and `action_player` components.
* **`scripts/ui/main_menu.gd`**: Main menu controller and button dispatcher with updated controls documentation.
* **`scripts/ui/pause_menu.gd`**: Pause menu controller with in-place audio/sensor calibration settings.
* **`scripts/ui/level_complete.gd`**: Completion metrics formatter and progression signal dispatcher.
* **`scripts/ui/game_over.gd`**: Failure screen formatter and retry signal dispatcher.
* **`scripts/ui/final_victory.gd`**: Campaign victory screen formatter and replay/menu dispatcher.
* **`scripts/ui/ui_preview.gd`**: Standalone test harness providing isolated simulation controls across all 4 levels and 6 screens.
* **`scripts/ui/ui_colors.gd`**: Palette constants (Charcoal base, Teal frame, Cold white text, Cyan/Amber/Violet/Green tools, Critical red).
* **`scripts/ui/glitch_text.gd`**: Procedural glitch typography generator.
* **`scripts/ui/crt_overlay.gd`**: Visual CRT scanline and distortion overlay shader.

### Shared Assets & Theme (`assets/ui/`)
* **`assets/ui/research_theme.tres`**: Thin-bordered dark-industrial research theme (`SystemFont_mono` fallback font stack: Consolas, Courier New, monospace).

---

## 2. Public UI Method Signatures & Argument Types

The `InGameHUD` (`scripts/ui/in_game_hud.gd`) exposes the following callable API:

### Mission & Wayfinding
```gdscript
func set_level(level_id: int) -> void
```
Updates current sector ID (1–4), default chamber code (`GV-01` to `GV-04`), name, baseline corruption, and default wayfinding hints.

```gdscript
func set_level_name(level_name: String, code: String = "") -> void
```
Sets custom level title and optional chamber code (e.g., `set_level_name("SYSTEM BREACH", "GV-01")`).

```gdscript
func set_objective(text: String) -> void
```
Updates the primary objective display label and automatically refreshes contextual wayfinding hints.

```gdscript
func set_objective_progress(completed: int, total: int, step_desc: String = "") -> void
```
Updates numerical progress and progress bar (e.g., `completed = 1, total = 2, step_desc = "RELAYS"` renders `RELAYS: 1/2`). Hides the progress row when `total <= 0`.

```gdscript
func set_objective_hint(hint_text: String) -> void
```
Displays or updates the compact contextual wayfinding hint label under the main objective (e.g. `">> HINT: TETHER across broken crossing using overhead anchors"`). If `hint_text` is empty, the hint row is cleanly hidden.

### Performance
```gdscript
func set_timer_seconds(seconds: float) -> void
```
Updates simulation timer readout (`MM:SS.ss`). When called externally, internal HUD timer calculation is automatically bypassed.

```gdscript
func set_score(points: int) -> void
```
Updates formatted score counter (`SCORE: %05d`).

### Survival & Vitals
```gdscript
func set_health(current: float, max_health: float = -1.0) -> void
```
Updates the integrity bar and readout (`%d / %d HP`). In production, the HUD starts in a neutral uninitialized state (`-- / -- HP`, 0 bar value, alert hidden). Works seamlessly with continuous health (0–100) or discrete 3-segment health from `PlayerHealth`. If `current <= 1.0` (for segmented health) or `current / max_health <= 0.30`, displays the critical low-health warning (`! CRITICAL INTEGRITY LEVEL !`) and emits `health_warning_triggered`.

### Tactical Equipment Loadout
```gdscript
func set_tether_status(status_text: String, is_active: bool = false) -> void
```
Updates TETHER loadout indicator (`STANDBY`, `READY`, `ATTACHED`, `RELEASED`).

```gdscript
func set_blade_status(status_text: String, is_active: bool = false) -> void
```
Updates BLADE loadout indicator (`STANDBY`, `READY`, `STRIKE`, `COOLDOWN`).

```gdscript
func set_polarity_status(status_text: String, is_active: bool = false) -> void
```
Updates POLARITY loadout indicator (`STANDBY`, `READY`, `INVERT`, `ACTIVE`).

```gdscript
func set_rewire_status(status_text: String, is_active: bool = false) -> void
```
Updates REWIRE loadout indicator (`STANDBY`, `READY`, `DIVERTED`, `ONLINE`).

```gdscript
func set_vector_status(status_text: String, is_active: bool = false) -> void
```
Updates VECTOR RUN loadout indicator (`STANDBY`, `WALL-RUN`, `WALL-JUMP`).

```gdscript
func set_equipped_tool(tool_id: String, tool_name: String = "", status_text: String = "ACTIVE", color: Color = Color.WHITE) -> void
```
Configures the auxiliary loadout slot dynamically with custom tool names and palette colors.

```gdscript
func set_ability(ability_name: String) -> void
```
Backwards-compatible ability setter for legacy `PHASE`, `GRAVITY`, and `FREEZE` mechanics.

### Targeting & Reticle
```gdscript
func set_grapple_target(has_target: bool, is_valid: bool = false, target_name: String = "") -> void
```
Controls crosshair grapple brackets. If `is_valid` is true, renders brackets in cyan with prompt `E // TETHER`. If `is_valid` is false and `has_target` is true, displays brackets in warning red with `CANNOT ATTACH // OUT OF RANGE`.

```gdscript
func set_reticle_state(color: Color, show_grapple: bool = false) -> void
```
Overrides reticle dot color and bracket visibility.

```gdscript
func show_interaction_prompt(prompt_text: String, is_available: bool = true) -> void
```
Displays contextual interaction prompt below reticle (e.g. `F // RESTORE RELAY A`, `Q // INVERT POLARITY`).

```gdscript
func hide_interaction_prompt() -> void
```
Clears and hides contextual interaction prompt.

### Notifications & Control Hints
```gdscript
func show_notification(message: String, is_alert: bool = false, duration: float = 2.5) -> void
```
Presents animated transient notification banner at top-center. Uses cold white / cyan for confirmations and warning red for alerts.

```gdscript
func set_control_hints(hints_text: String) -> void
```
Sets the bottom-left control guide line (defaults to: `E TETHER | F INTERACT | Q POLARITY | LMB BLADE | SHIFT VECTOR | SPACE JUMP`).

---

## 3. Emitted Signals & Arguments

### `InGameHUD` (`scripts/ui/in_game_hud.gd`)
* `signal notification_displayed(message: String, is_alert: bool)`
* `signal health_warning_triggered(current: float, max_health: float)`
* `signal tool_selected(tool_id: String)`
* `signal objective_hint_updated(hint_text: String)`

### `MainMenu` (`scripts/ui/main_menu.gd`)
* `signal play_requested`
* `signal settings_requested`
* `signal how_to_play_requested`
* `signal quit_requested`

### `PauseMenu` (`scripts/ui/pause_menu.gd`)
* `signal resumed`
* `signal restarted`
* `signal settings_requested`
* `signal aborted_to_menu`

### `LevelComplete` (`scripts/ui/level_complete.gd`)
* `signal next_level_requested(next_level_id: int)`
* `signal retry_requested(current_level_id: int)`
* `signal menu_requested`

### `GameOver` (`scripts/ui/game_over.gd`)
* `signal retry_requested(current_level_id: int)`
* `signal menu_requested`

### `FinalVictory` (`scripts/ui/final_victory.gd`)
* `signal replay_requested`
* `signal menu_requested`

---

## 4. Verified Gameplay Integrations & Autoconnection

`InGameHUD` automatically detects and connects to existing nodes on `_ready()` via groups and node hierarchies using defensive `has_signal` and `is_connected` checks:

1. **`GameFlowManager` (group `"game_flow"` or `"game_flow_manager"`):**
   * `level_started(level_index, level_name)` $\rightarrow$ updates sector title, chamber code (`GV-01`–`GV-04`), and default hint.
   * `objective_updated(desc, completed, total)` $\rightarrow$ updates objective text, progress bar, and derives wayfinding hints.
   * `time_updated(seconds)` $\rightarrow$ updates timer readout.
   * `score_updated(points)` $\rightarrow$ updates score readout.
   * `puzzle_completed(index, elapsed)` $\rightarrow$ notification `"OBJECTIVES CLEAR // ACCESS UNLOCKED"`.
   * `exit_unlocked(index)` $\rightarrow$ updates hint to `"CONTAINMENT EXIT UNLOCKED // PROCEED TO EXTRACTION GATE"` and fires banner.
   * `game_failed(reason)` $\rightarrow$ alert notification `"CRITICAL FAILURE: <REASON>"`.
   * `game_victory(time, score)` $\rightarrow$ notification `"SIMULATION COMPLETE // ALL SECTORS CLEARED"`.

2. **`action_player` (group `"action_player"` or `"player"`):**
   * **`PlayerHealth` (group `"player_health"` or child):** `health_changed(cur, max)` $\rightarrow$ updates integrity bar and HP label.
   * **`GrappleController`:** `target_changed` $\rightarrow$ updates reticle grapple brackets; `grapple_attached` $\rightarrow$ sets tether status to `ATTACHED`; `grapple_detached` $\rightarrow$ sets tether status to `READY`.
   * **`SwordController`:** `attack_started` $\rightarrow$ sets blade status to `STRIKE`; `attack_finished` $\rightarrow$ sets blade status to `READY`; `hit_confirmed` $\rightarrow$ fires damage impact notification.
   * **`InteractionController`:** `target_changed` $\rightarrow$ displays prompt (e.g. `F // RESTORE RELAY A`); `interaction_result` $\rightarrow$ fires action notification.
   * **`PolarityController`:** `target_changed` $\rightarrow$ displays prompt `Q // INVERT POLARITY`; `polarity_result` $\rightarrow$ fires polarity notification.
   * **`VectorRunController`:** `wall_run_started` $\rightarrow$ sets vector status to `WALL-RUN` and displays `"VECTOR RUN ACTIVE // SPACE TO WALL-JUMP"`; `wall_jumped` $\rightarrow$ sets vector status to `WALL-JUMP`; `wall_run_ended` $\rightarrow$ returns vector status to `STANDBY`.

---

## 5. Actual vs. Provisional Mechanics

| Mechanic | Implementation Status | UI Representation | Notes |
| :--- | :--- | :--- | :--- |
| **Mission / Wayfinding** | **Verified Production** | Level title, main objective, progress bar, hint label | Contextual hints for L1–L4 |
| **Performance Metrics** | **Verified Production** | Digital timer (`MM:SS.ss`) and score | 10Hz updates supported |
| **Survival / Health** | **Verified Production** | Integrity bar + HP label + critical warning | Handles 3-segment or 100 HP |
| **TETHER (Grapple)** | **Verified Production** | Reticle brackets + Loadout slot | E attach/release & pull handle |
| **BLADE (Melee)** | **Verified Production** | Loadout slot | LMB strike & cooldown feedback |
| **POLARITY** | **Verified Production** | Loadout slot + Interaction prompt | Q inversion on marked masses |
| **REWIRE** | **Verified Production** | Loadout slot + Interaction prompt | F power diversion at consoles |
| **VECTOR RUN** | **Verified Production** | Loadout slot + Notification banners | Passive wall-run & wall-jump |
| **PHASE / GRAV / FREEZE** | **Verified Legacy** | Supported via `set_ability()` | Backwards-compatible |

---

## 6. Standalone Developer Preview Instructions

To launch the standalone UI preview harness in Godot:
1. Open the project in Godot 4.7.2.
2. Open `res://scenes/ui/ui_preview.tscn`.
3. Press **`F6`** (Run Current Scene).

### Interactive Test Controls (via Docked Toolbar)
* **Screen Selector (Top Bar):** Instant switching between `[ MAIN MENU ]`, `[ HUD ]`, `[ PAUSE ]`, `[ LEVEL COMPLETE ]`, `[ GAME OVER ]`, `[ VICTORY ]`.
* **Level Selector (Row 1):** `L1 ACCESS`, `L2 INVERT`, `L3 CLOCK`, `L4 KERNEL`.
* **Health Controls (Row 1):** `-25 DMG`, `+25 HEAL`, `CRIT 15%`.
* **Score (Row 1):** `+250 SCORE`.
* **Objective Progression (Row 2):** `STEP 0`, `STEP 1`, `STEP 2`, `STEP 3 (EXIT)` (advances objectives and wayfinding hints across all 4 levels).
* **Targeting (Row 2):** `ANCHOR VALID` (cyan brackets), `ANCHOR OUT-OF-RANGE` (red brackets), `NO ANCHOR`, `PROMPT [F]`, `PROMPT [Q]`, `CLEAR PROMPT`.
* **Loadout (Row 3):** `TETHER READY`, `ATTACHED`, `RELEASED`, `BLADE READY`, `STRIKE`, `VECTOR RUN`, `WALL JUMP`, `POLARITY [Q]`, `REWIRE [F]`.
* **Notifications & Triggers (Row 4):** `BREACH ALERT`, `RELAY RESTORED`, `EXIT UNLOCKED`, `TRIGGER FAIL`, `TRIGGER VICTORY`.

### Input Architecture & Focus Isolation
* **Pause-Proof Developer Toolbars:** `UIPreview` and `DevSelectorLayer` are configured with `process_mode = PROCESS_MODE_ALWAYS` (mode 3) ensuring developer preview buttons remain interactive and never freeze when previewing paused states or when `get_tree().paused = true`.
* **Container Pass-Through:** `ScreensContainer` and `UIPreview` utilize `mouse_filter = MOUSE_FILTER_IGNORE` (mode 2) so full-screen transparent container bounds do not stop clicks.
* **Keyboard Focus Isolation:** All developer toolbar buttons are configured with `focus_mode = FOCUS_NONE` (mode 0) and programmatically sanitized via `_sanitize_developer_toolbars()` so they never intercept Tab or Arrow keys from the screen under test.
* **Closed-Loop Menu Navigation:** `MainMenu` buttons (`StartBtn`, `HowToPlayBtn`, `SettingsBtn`, `ExitBtn`) are wired with explicit circular `focus_neighbor_top`, `focus_neighbor_bottom`, `focus_previous`, and `focus_next` NodePaths, enabling seamless Tab/Shift-Tab and Up/Down navigation with Enter/Space activation.
* **Modal Clean Slate:** `LevelComplete`, `GameOver`, `PauseMenu`, and `FinalVictory` strictly call `hide()` in `_ready()` for clean initial isolation.

---

## 7. Production Game Loop & Main Scene Wiring

The production UI is now fully connected into the live game loop:

### A. Boot Scene (`res://project.godot`)
* `run/main_scene` is set to `res://scenes/ui/main_menu.tscn`.
* The game boots into the research terminal Main Menu with autoplaying atmospheric menu music (`music_menu_the_surreal_truth.mp3`), mechanical button audio feedback, and live Master & SFX sliders.
* Clicking **"01 // START SIMULATION"** emits a confirmation chime, stops menu music, and transitions seamlessly to `res://main.tscn`.

### B. Live Gameplay Scene (`res://main.tscn`)
* Replaced Keith's temporary fallback `CampaignHUD` with `res://scenes/ui/in_game_hud.tscn`.
* Added `UIOverlay` (`res://scripts/ui/gameplay_ui_mediator.gd`, layer 50, `process_mode = PROCESS_MODE_ALWAYS`) hosting:
  * **`PauseMenu` (`res://scenes/ui/pause_menu.tscn`):** Accessible via ESC key during gameplay; unpauses, recalibrates level, or aborts back to Main Menu.
  * **`GameOver` (`res://scenes/ui/game_over.tscn`):** Triggers on player death/fall failure; provides retry and abort to menu options.
  * **`FinalVictory` (`res://scenes/ui/final_victory.tscn`):** Triggers upon campaign completion (clearing Sector 04); displays total time, final score, replay simulation, and return to menu options.

---

## 8. Verified Audio Architecture & UI Sound Integration

### A. Engine AudioManager Integration
* **Autoload Singleton:** `AudioManager` (`res://audio/audio_manager.gd`).
* **Verified Audio Buses:** `Master`, `Music`, `Ambience`, `SFX`, `UI`, `Voice`.
* **Curated Audio Location:** `res://assets/audio/ui_curated/` (11 CC0 assets).
* **Stream Registration:** `UIAudio.initialize_audio_service()` registers curated `.ogg` and `.mp3` assets into `AudioManager` via `AudioManager.register_event(name, stream, true)` replacing synthetic tone placeholders with real sector ambience and mechanical UI clicks without modifying `audio_manager.gd`.

### B. UI Sound Events & Cues
* **Hover & Focus:** `ui_hover_tick.ogg` (subtle tactile tick, rate-limited to prevent stuttering).
* **Click & Select:** `ui_click_mechanical.ogg` (clean mechanical switch).
* **Confirmation & Step Complete:** `ui_confirmation_chime.ogg` (positive resolution).
* **Error & Critical Warning:** `ui_error_alarm.ogg` (short electronic rejection).
* **Exit Unlocked Event:** `env_containment_door_open.ogg` (heavy pneumatic chamber unsealing).
* **Relay Restored Event:** `env_relay_terminal.ogg` (data routing computation tone).
* **Menu Music & Ambience:** Loopable ambient tracks for Main Menu (`music_menu_the_surreal_truth.mp3`) and Sectors 1–4 (`ambience_level1_sector.mp3` through `music_level4_urgent.mp3`).

### C. Settings & Audio Bus Controls
* **Main Menu (`main_menu.tscn`):** Live `%MasterSlider` and `%SFXSlider` directly controlling `AudioServer` volume with instant audible feedback.
* **Pause Menu (`pause_menu.tscn`):** Live `%MasterSlider`, `%SFXSlider`, and `%MusicSlider` with direct `AudioServer` volume mapping and mute thresholds.
