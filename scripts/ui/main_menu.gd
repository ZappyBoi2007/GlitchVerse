class_name MainMenu
extends Control

## Experimental Research Interface - Main Menu for GlitchVerse.
## Cinematic research facility environment with integrated clinical navigation and subtle reality corruption.

signal play_requested
signal settings_requested
signal about_requested
signal how_to_play_requested
signal quit_requested

const ORIGINAL_TITLE := "GLITCHVERSE"
const GLITCH_CHARS: PackedStringArray = ["1", "_", "·", "V", "E", "X", "~", "Ø"]

const NAV_ACTIONS: Dictionary = {
	"start": {
		"code": "01",
		"name": "START SIMULATION",
		"dispatch": "INITIALIZE CONTAINMENT SIMULATION GV-01 // SECTOR ACCESS",
	},
	"how_to_play": {
		"code": "02",
		"name": "HOW TO PLAY",
		"dispatch": "EXPERIMENT PROTOCOLS // PHASE, GRAVITY & FREEZE SPECIFICATION",
	},
	"settings": {
		"code": "03",
		"name": "SETTINGS",
		"dispatch": "WORKSTATION CALIBRATION // ACOUSTIC & OPTICAL SENSOR TUNING",
	},
	"exit": {
		"code": "04",
		"name": "EXIT",
		"dispatch": "SEVER TERMINAL SESSION // RETURN OPERATOR TO HOST OS",
	},
}

@export var auto_load_gameplay_scene: bool = false

# Title Typography
@onready var title_primary: Label = %TitlePrimary
@onready var title_cyan: Label = %TitleCyan
@onready var title_magenta: Label = %TitleMagenta

# Minimal Research Navigation
@onready var start_btn: Button = %StartBtn
@onready var how_to_play_btn: Button = get_node_or_null("%HowToPlayBtn") as Button if get_node_or_null("%HowToPlayBtn") != null else get_node_or_null("%AboutBtn") as Button
@onready var about_btn: Button = how_to_play_btn
@onready var settings_btn: Button = %SettingsBtn
@onready var exit_btn: Button = %ExitBtn

# Contextual Operator Prompt
@onready var dispatch_prompt: Label = %DispatchPrompt

# Modals
@onready var settings_modal: Control = %SettingsModal
@onready var close_settings_btn: Button = %CloseSettingsBtn
@onready var how_to_play_modal: Control = get_node_or_null("%HowToPlayModal") if get_node_or_null("%HowToPlayModal") != null else get_node_or_null("%AboutModal")
@onready var about_modal: Control = how_to_play_modal
@onready var close_how_to_play_btn: Button = get_node_or_null("%CloseHowToPlayBtn") if get_node_or_null("%CloseHowToPlayBtn") != null else get_node_or_null("%CloseAboutBtn")
@onready var close_about_btn: Button = close_how_to_play_btn

# Environmental & Anomaly Elements
@onready var stasis_glow: TextureRect = %StasisGlow
@onready var anomaly_fracture: Control = %AnomalyFracture
@onready var corrupted_marker: Label = %CorruptedMarker
@onready var status_dot: Label = %StatusDot
@onready var status_text: Label = %StatusText
@onready var anomaly_scanline: ColorRect = get_node_or_null("%AnomalyScanline") as ColorRect

var _time_elapsed: float = 0.0
var _glitch_timer: float = 0.0
var _next_glitch_interval: float = 6.5
var _is_glitching: bool = false
var _glitch_duration: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if start_btn != null:
		start_btn.pressed.connect(_on_start_pressed)
	if how_to_play_btn != null:
		how_to_play_btn.pressed.connect(_on_how_to_play_pressed)
	if settings_btn != null:
		settings_btn.pressed.connect(_on_settings_pressed)
	if exit_btn != null:
		exit_btn.pressed.connect(_on_exit_pressed)

	if close_settings_btn != null:
		close_settings_btn.pressed.connect(_on_close_settings)
	if close_how_to_play_btn != null:
		close_how_to_play_btn.pressed.connect(_on_close_how_to_play)

	# Setup clinical navigation buttons
	if start_btn != null:
		_setup_nav_button(start_btn, "start", true)
	if how_to_play_btn != null:
		_setup_nav_button(how_to_play_btn, "how_to_play", false)
	if settings_btn != null:
		_setup_nav_button(settings_btn, "settings", false)
	if exit_btn != null:
		_setup_nav_button(exit_btn, "exit", false)

	if settings_modal != null:
		settings_modal.visible = false
	if how_to_play_modal != null:
		how_to_play_modal.visible = false
	if anomaly_scanline != null:
		anomaly_scanline.visible = false

	# Baseline subtle chromatic channel alignment (camera lens / CRT chromatic depth)
	if title_cyan != null:
		title_cyan.position = Vector2(-2.0, 0.5)
	if title_magenta != null:
		title_magenta.position = Vector2(2.0, -0.5)
	_next_glitch_interval = randf_range(6.0, 9.5)

	if start_btn != null:
		start_btn.grab_focus()


func _setup_nav_button(btn: Button, action_key: String, is_initial_focus: bool) -> void:
	var info: Dictionary = NAV_ACTIONS.get(action_key, {})
	var code: String = String(info.get("code", "00"))
	var label_name: String = String(info.get("name", "ACTION"))
	var dispatch_text: String = String(info.get("dispatch", ""))

	btn.text = ("▸ %s // %s" if is_initial_focus else "  %s // %s") % [code, label_name]
	if is_initial_focus:
		btn.position.x = 8.0
		_set_dispatch(dispatch_text)

	btn.focus_entered.connect(func():
		btn.text = "▸ %s // %s" % [code, label_name]
		btn.position.x = 8.0
		_set_dispatch(dispatch_text)
	)
	btn.focus_exited.connect(func():
		btn.text = "  %s // %s" % [code, label_name]
		btn.position.x = 0.0
	)
	btn.mouse_entered.connect(func():
		btn.grab_focus()
	)


func _set_dispatch(text: String) -> void:
	if dispatch_prompt != null:
		dispatch_prompt.text = ">> DISPATCH: %s" % text


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if settings_modal != null and settings_modal.visible:
			_on_close_settings()
			get_viewport().set_input_as_handled()
		elif how_to_play_modal != null and how_to_play_modal.visible:
			_on_close_how_to_play()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_time_elapsed += delta

	# Atmospheric breathing on the distant stasis core and anomaly fracture
	if stasis_glow != null:
		var pulse_stasis := (sin(_time_elapsed * 1.4) + 1.0) * 0.5
		stasis_glow.modulate.a = lerpf(0.14, 0.28, pulse_stasis)

	if anomaly_fracture != null and not _is_glitching:
		var pulse_frac := (sin(_time_elapsed * 2.0) + 1.0) * 0.5
		anomaly_fracture.modulate.a = lerpf(0.32, 0.55, pulse_frac)

	# Rare, brief glitch event (0.05-0.08s)
	_glitch_timer += delta
	if _is_glitching:
		_glitch_duration -= delta
		if _glitch_duration <= 0.0:
			_end_glitch_event()
	elif _glitch_timer >= _next_glitch_interval:
		_trigger_subtle_glitch()


func _trigger_subtle_glitch() -> void:
	_is_glitching = true
	_glitch_duration = randf_range(0.05, 0.08)
	_glitch_timer = 0.0
	_next_glitch_interval = randf_range(6.0, 10.0)

	# Chromatic channel offset flare
	if title_cyan != null:
		title_cyan.position.x = -4.5
	if title_magenta != null:
		title_magenta.position.x = 4.5

	# Single-character momentary corrupted substitution in GLITCHVERSE
	if title_primary != null:
		var glitched := ORIGINAL_TITLE
		var idx := randi() % ORIGINAL_TITLE.length()
		var glitch_char: String = GLITCH_CHARS[randi() % GLITCH_CHARS.size()]
		glitched = glitched.substr(0, idx) + glitch_char + glitched.substr(idx + 1)
		title_primary.text = glitched

	# Faint horizontal anomaly scanline flare
	if anomaly_scanline != null:
		anomaly_scanline.position.y = randf_range(120.0, 580.0)
		anomaly_scanline.color = Color(1.0, 0.169, 0.839, randf_range(0.25, 0.45))
		anomaly_scanline.visible = true

	# Anomaly flare & status desync blink
	if anomaly_fracture != null:
		anomaly_fracture.modulate.a = 0.90
	if corrupted_marker != null:
		corrupted_marker.modulate.a = 1.0
	if status_dot != null:
		status_dot.modulate = UIColors.COLOR_MAGENTA
	if status_text != null:
		status_text.text = "FIELD DESYNC"
		status_text.modulate = UIColors.COLOR_MAGENTA


func _end_glitch_event() -> void:
	_is_glitching = false
	if title_cyan != null:
		title_cyan.position = Vector2(-2.0, 0.5)
	if title_magenta != null:
		title_magenta.position = Vector2(2.0, -0.5)
	if title_primary != null:
		title_primary.text = ORIGINAL_TITLE
	if anomaly_scanline != null:
		anomaly_scanline.visible = false
	if corrupted_marker != null:
		corrupted_marker.modulate.a = 0.80
	if status_dot != null:
		status_dot.modulate = UIColors.COLOR_CONTROLLED
	if status_text != null:
		status_text.text = "NOMINAL"
		status_text.modulate = Color(0.91, 0.969, 0.973, 0.85)


func _on_start_pressed() -> void:
	play_requested.emit()
	if auto_load_gameplay_scene and ResourceLoader.exists("res://main.tscn"):
		if is_inside_tree() and get_tree() != null:
			get_tree().change_scene_to_file("res://main.tscn")


func _on_how_to_play_pressed() -> void:
	if how_to_play_modal != null:
		how_to_play_modal.visible = true
	if settings_modal != null:
		settings_modal.visible = false
	if close_how_to_play_btn != null:
		close_how_to_play_btn.grab_focus()
	how_to_play_requested.emit()
	about_requested.emit()


func _on_about_pressed() -> void:
	_on_how_to_play_pressed()


func _on_settings_pressed() -> void:
	if settings_modal != null:
		settings_modal.visible = true
	if how_to_play_modal != null:
		how_to_play_modal.visible = false
	if close_settings_btn != null:
		close_settings_btn.grab_focus()
	settings_requested.emit()


func _on_close_how_to_play() -> void:
	if how_to_play_modal != null:
		how_to_play_modal.visible = false
	if how_to_play_btn != null:
		how_to_play_btn.grab_focus()


func _on_close_about() -> void:
	_on_close_how_to_play()


func _on_close_settings() -> void:
	if settings_modal != null:
		settings_modal.visible = false
	if settings_btn != null:
		settings_btn.grab_focus()


func _on_exit_pressed() -> void:
	quit_requested.emit()
	if is_inside_tree() and get_tree() != null:
		get_tree().quit()
