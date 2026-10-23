class_name UIColors
extends RefCounted

## GlitchVerse Experimental Research Interface - Standardized Color Palette
## 60% Charcoal / 30% Dark Teal / 10% Anomaly Accent + Standardized Abilities

# 60% Dominant Base
const COLOR_CHARCOAL := Color("0d1117")
const COLOR_CHARCOAL_DARK := Color("070a0e")
const COLOR_CHARCOAL_PANEL := Color(0.051, 0.067, 0.09, 0.85)

# 30% Structural Frame
const COLOR_TEAL := Color("17383d")
const COLOR_TEAL_BORDER := Color(0.11, 0.27, 0.29, 0.9)
const COLOR_TEAL_HAIRLINE := Color(0.09, 0.22, 0.239, 0.5)

# 10% World Anomaly Accent (Glitch / Corruption ONLY - NOT an ability color)
const COLOR_MAGENTA := Color("ff2bd6")
const COLOR_MAGENTA_FAINT := Color(1.0, 0.169, 0.839, 0.15)

# Functional Typography & System State
const COLOR_TEXT_PRIMARY := Color("e8f7f8")    # Cold White: primary readable text
const COLOR_TEXT_MUTED := Color("8ea5aa")      # Muted Cyan-Gray: secondary info
const COLOR_CONTROLLED := Color("39f5ff")      # Cyan: system-understood / controlled state
const COLOR_CRITICAL := Color("ff4057")        # Red: ONLY danger / error / critical failure
const COLOR_CONFIRMED := Color("38ef7d")       # Green: calibration confirmed

# Standardized Ability Instrument Colors (Standardized Everywhere)
const COLOR_ABILITY_PHASE := Color("39f5ff")     # Cyan
const COLOR_ABILITY_GRAVITY := Color("ffb830")   # Amber / Warm Yellow
const COLOR_ABILITY_FREEZE := Color("a259ff")    # Violet / Purple

# Four Research Levels Metadata
const LEVELS: Array[Dictionary] = [
	{
		"id": 1,
		"code": "GV-01",
		"name": "ACCESS DENIED",
		"section": "SEC // 04.9A",
		"state": "CLEAN / STABLE",
		"objective": "Restore access to the containment chamber.",
		"status": "SIMULATION ACTIVE // EQUILIBRIUM NOMINAL",
		"corruption": 0.0,
		"target_prompt": "PHASEABLE BARRIER",
	},
	{
		"id": 2,
		"code": "GV-02",
		"name": "INVERTED",
		"section": "SEC // 08.2B",
		"state": "SUBTLY STRANGE",
		"objective": "Counteract spatial inversion and neutralize vector drift.",
		"status": "GRAVITATIONAL POLARITY REVERSED [-1.0G]",
		"corruption": 0.25,
		"target_prompt": "GRAVITY CRATE",
	},
	{
		"id": 3,
		"code": "GV-03",
		"name": "CLOCK FAILURE",
		"section": "SEC // 12.4C",
		"state": "UNSTABLE",
		"objective": "Stabilize temporal calibration before cycle collapse.",
		"status": "TEMPORAL DESYNC // FRAME BUFFER DECAY",
		"corruption": 0.60,
		"target_prompt": "MOVING HAZARD",
	},
	{
		"id": 4,
		"code": "GV-04",
		"name": "KERNEL PANIC",
		"section": "SEC // 16.0X",
		"state": "HEAVILY CORRUPTED",
		"objective": "Purge anomalous core dump and force reality restoration.",
		"status": "CRITICAL REALITY COLLAPSE // CORE DUMP",
		"corruption": 0.95,
		"target_prompt": "CORRUPTED CORE",
	},
]


static func get_level_data(level_id: int) -> Dictionary:
	var index := clampi(level_id - 1, 0, LEVELS.size() - 1)
	return LEVELS[index]


static func get_ability_color(ability_name: String) -> Color:
	match ability_name.to_upper():
		"PHASE":
			return COLOR_ABILITY_PHASE
		"GRAVITY":
			return COLOR_ABILITY_GRAVITY
		"FREEZE":
			return COLOR_ABILITY_FREEZE
		_:
			return COLOR_ABILITY_PHASE
