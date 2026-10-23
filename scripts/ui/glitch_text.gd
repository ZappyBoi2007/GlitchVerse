class_name GlitchText
extends RefCounted

## Utility for technical research typography.
## Keeps all functional UI text (buttons, objectives, timer, score, abilities) clean and readable.
## Glitch effects are reserved for the GLITCHVERSE logo, decorative telemetry, and anomaly states.

const GLITCH_GLYPHS_TITLE: PackedStringArray = ["1", "X", "_", "·", "V", "E", "Ø", "~"]


## Glitches the GLITCHVERSE title / logo during brief anomaly events.
static func glitch_title(title: String, intensity: float = 0.5) -> String:
	if intensity <= 0.0 or title.is_empty():
		return title

	var glitched := title
	var count := mini(2, clampi(int(intensity * 3.0), 1, 2))
	for _i in range(count):
		var idx := randi() % title.length()
		var replacement: String = GLITCH_GLYPHS_TITLE[randi() % GLITCH_GLYPHS_TITLE.size()]
		glitched = glitched.substr(0, idx) + replacement + glitched.substr(idx + 1)
	return glitched


## Formats simulation timer cleanly, with intermittent stutter only in Level 3/4.
static func format_simulation_timer(seconds: float, level_id: int) -> String:
	var total_sec := int(seconds)
	var millis := int((seconds - total_sec) * 100.0)
	var mins := total_sec / 60
	var secs := total_sec % 60

	match level_id:
		1, 2: # Clean and readable
			return "%02d:%02d.%02d" % [mins, secs, millis]
		3: # Clock Failure: intermittent desync stutter
			if int(seconds * 6.0) % 7 == 0:
				return "00:??.ERR"
			return "%02d:%02d.%02d" % [mins, secs, millis]
		4: # Kernel Panic: periodic anomaly flicker
			if int(seconds * 4.0) % 8 == 0:
				return "0x%02X:%02X" % [mins, secs]
			return "%02d:%02d.%02d" % [mins, secs, millis]
		_:
			return "%02d:%02d.%02d" % [mins, secs, millis]
