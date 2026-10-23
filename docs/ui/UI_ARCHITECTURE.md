# GlitchVerse UI/UX Architecture & Research Interface

## Branch: `feature/anushree-ui`

---

## 1. Visual & Interactive Identity: Polished Indie Simulation

GLITCHVERSE balances a dark industrial, experimental research, horror-inspired atmosphere with the responsiveness and crisp legibility of an intentionally-designed indie title.

*   **Clean Functional Typography**: All buttons, objectives, timers, scores, abilities, and prompts are rendered crisply without heavy glitch distortion so the game remains completely playable and responsive.
*   **Glitch as an Event**: Glitch effects are strictly reserved for the `GLITCHVERSE` logo, environmental background anomaly traces, and world corruption states.
*   **Rectangular Outlined Buttons**: Every menu button features a clean, thin-bordered rectangular outline with a dark/transparent interior, glowing hover border, and clear selection indicators.
*   **Spacious & Minimal**: Large amounts of empty breathing space; no bulky card boxes or rounded modern-app pill containers.

---

## 2. Standardized Color Palette

| Role | Color | Hex Code | Description |
| :--- | :--- | :--- | :--- |
| **Base Canvas (60%)** | Deep Charcoal | `#0D1117` | Near-black void and environmental simulation backdrop |
| **Structural Frame (30%)** | Dark Teal | `#17383D` | Thin 1px outlines, calibration marks, dividers |
| **World Anomaly (10%)** | Magenta | `#FF2BD6` | World anomaly and glitch interference (NOT an ability color) |
| **Primary Text** | Cold White | `#E8F7F8` | Primary readable labels, objectives, timers |
| **Secondary Text** | Muted Cyan-Gray | `#8EA5AA` | Secondary descriptors and metadata |
| **Ability: Phase** | Cyan | `#39F5FF` | Active Phase vector state |
| **Ability: Gravity** | Amber / Yellow | `#FFB830` | Active Gravity vector state |
| **Ability: Freeze** | Violet / Purple | `#A259FF` | Active Freeze vector state |
| **Critical Failure / Error** | Red | `#FF4057` | ONLY used for danger, errors, and containment breach |
| **Confirmation** | Calibrated Green | `#38EF7D` | Confirmed calibration / rewrite |

---

## 3. Four-Level Visual Escalation

1.  **Level 1 — ACCESS DENIED (Clean / Stable)**:
    Cleanest clinical interface. Neutral framing, stable timer, zero baseline corruption.
2.  **Level 2 — INVERTED (Subtly Strange)**:
    Gravitational polarity reversed (`-1.0G`). Subtle coordinate shifts and rare character anomalies.
3.  **Level 3 — CLOCK FAILURE (Unstable)**:
    Temporal calibration loop decaying. Intermittent clock stutter (`00:??.ERR`), slight scanline interference. Functional text remains 100% readable.
4.  **Level 4 — KERNEL PANIC (Heavily Corrupted)**:
    Strongest corruption state. Background anomaly interference, emergency red/magenta alerts, but critical prompts and objectives remain clearly legible.

---

## 4. Gameplay HUD Architecture

The revised compact in-game HUD balances high-speed traversal, survival metrics, and experimental puzzle solving:

```
[ TOP-LEFT ]                                                      [ TOP-RIGHT ]
GV-01 // ACCESS DENIED                                                 00:47.23
OBJECTIVE: Restore access to containment chamber.                  SCORE: 01450
CIRCUITS: 0/2 [ ■ ■ □ ]

                           [ NOTIFICATION BANNER ]
                        TETHER ATTACHED // VECTOR OK

                                  [ CENTER ]
                                   [ + ]
                         [E] TETHER // CONDUIT ANCHOR

[ BOTTOM-LEFT ]                                                [ BOTTOM-RIGHT ]
VITALS // INTEGRITY                                         EQUIPMENT // LOADOUT
[=========|==] 100 / 100 HP                                     ▪ TETHER: READY
! CRITICAL INTEGRITY !                                          ▪ BLADE:  READY
[E] TETHER  [F] INTERACT  [LMB] BLADE  [SHIFT] VECTOR RUN       ▪ POLARITY: ACT
```

### Public Callable API (`InGameHUD`)
*   `set_level(level_id: int)`: Updates chamber code, name, and baseline corruption.
*   `set_level_name(level_name: String, code: String = "")`: Updates level title and code dynamically.
*   `set_objective(text: String)`: Updates the active objective string.
*   `set_objective_progress(completed: int, total: int, step_desc: String = "")`: Updates progress steps and bar.
*   `set_health(current: float, max_health: float = -1.0)`: Updates health bar, numerical readout, and low-health alert threshold. Starts uninitialized (`-- / -- HP`) until integration layer supplies actual data.
*   `set_grapple_target(has_target: bool, is_valid: bool = false, anchor_label: String = "")`: Displays targeting crosshair brackets and valid/invalid status.
*   `show_interaction_prompt(prompt_text: String, key_hint: String = "F")`: Contextual interaction prompt.
*   `hide_interaction_prompt()`: Clears interaction prompt.
*   `set_tether_status(status_text: String, is_attached: bool = false)`: Updates TETHER indicator.
*   `set_blade_status(status_text: String, is_ready: bool = true)`: Updates BLADE indicator.
*   `set_equipped_tool(tool_id: String, tool_label: String = "", tool_status: String = "READY", tool_color: Color = Color.WHITE)`: Updates auxiliary vector / tool.
*   `set_ability(mode: String)`: Legacy backward-compatible adapter.
*   `show_notification(message: String, is_alert: bool = false, duration: float = 2.5)`: Transient notification banner with tween animation.
*   `set_control_hints(hints_text: String)`: Updates bottom-left keybind legend.
*   `set_score(points: int)`: Updates score readout (`SCORE: %05d`).
*   `set_timer_seconds(seconds: float)`: Updates HUD simulation clock.

---

## 5. Integration Points

### 1. `RealityDebugger` (Connected)
`InGameHUD` looks for the group `"reality_debugger"` and connects to:
*   `ability_changed(ability_label, ability_color)` -> calls `set_ability(ability_label)`
*   `target_changed(target_label, compatible, has_target)` -> updates `set_target_prompt()` and `set_grapple_target()`
*   `feedback_changed(message, is_error)` -> calls `show_notification(message, is_error)`

### 2. `GameFlowManager` (Connected via group `"game_flow"`)
`InGameHUD` automatically detects `GameFlowManager` in group `"game_flow"` and connects to:
*   `level_started(level_id, level_name)` -> calls `set_level_name()` and announces level
*   `objective_updated(text, completed, total)` -> calls `set_objective()` and `set_objective_progress()`
*   `time_updated(seconds)` -> calls `set_timer_seconds(seconds)`
*   `score_updated(points)` -> calls `set_score(points)`
*   `puzzle_completed(level_id, elapsed)` -> triggers `"PUZZLE SOLVED // EXIT UNLOCKED"` notification
*   `exit_unlocked(level_id)` -> triggers `"CONTAINMENT EXIT UNLOCKED"` notification
*   `game_failed(reason)` -> triggers alert notification `"CRITICAL FAILURE: <REASON>"`
*   `game_victory(time, points)` -> triggers `"SIMULATION COMPLETE"` notification

---

## 6. How to Test (Standalone F6 Harness)

Open Godot and run **`res://scenes/ui/ui_preview.tscn`** (Press **`F6`**):

1.  **Pure Simulated Viewport**: Upper 88% of screen displays the exact in-game screen without contamination.
2.  **Docked Developer Bar**:
    *   **Screens**: Toggle `[ HUD ]`, `[ MAIN MENU ]`, `[ PAUSE ]`, `[ COMPLETE ]`, `[ FAILURE ]`, and `[ VICTORY ]`.
    *   **Progression**: Click `L1: ACCESS DENIED`, `L2: INVERTED`, `L3: CLOCK FAILURE`, `L4: KERNEL PANIC`.
    *   **Ability Colors**: Test `▪ PHASE (CYAN)`, `▪ GRAVITY (AMBER)`, `▪ FREEZE (VIOLET)`.
    *   **Score Simulation**: Click `+250 PTS` to increment HUD score.
    *   **Target Prompts**: Click `COMPATIBLE`, `INERT`, or `NONE`.
3.  **Toggle Dev Controls**: Press **`TAB`** to collapse the developer bar for a 100% full-screen view.
