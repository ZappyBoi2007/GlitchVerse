class_name PauseMenu
extends Control


## Emergency Protocol Suspension (Pause Menu) for GlitchVerse.
## Restrained, floating typography with rectangular buttons and calibration settings.

signal resumed
signal restarted
signal settings_requested
signal aborted_to_menu

@export var auto_reload_scene: bool = false

@onready var chamber_label: Label = %PauseChamber
@onready var status_label: Label = %PauseStatus
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var settings_button: Button = get_node_or_null("%SettingsButton") as Button
@onready var abort_button: Button = %AbortButton

# In-Place Settings Modal
@onready var settings_modal: Control = get_node_or_null("%SettingsModal") as Control
@onready var close_settings_btn: Button = get_node_or_null("%CloseSettingsBtn") as Button
@onready var master_slider: HSlider = get_node_or_null("%MasterSlider") as HSlider
@onready var sfx_slider: HSlider = get_node_or_null("%SFXSlider") as HSlider
@onready var music_slider: HSlider = get_node_or_null("%MusicSlider") as HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIAudio.initialize_audio_service(self)

	if resume_button != null:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button != null:
		restart_button.pressed.connect(_on_restart_pressed)
	if settings_button != null:
		settings_button.pressed.connect(_on_settings_pressed)
	if abort_button != null:
		abort_button.pressed.connect(_on_abort_pressed)
	if close_settings_btn != null:
		close_settings_btn.pressed.connect(_on_close_settings)

	UIAudio.attach_all_buttons(self)

	if settings_modal != null:
		settings_modal.visible = false

	_init_sliders()
	hide()


func _init_sliders() -> void:
	if master_slider != null:
		var bus_idx := AudioServer.get_bus_index("Master")
		var cur := 85.0
		if bus_idx >= 0 and not AudioServer.is_bus_mute(bus_idx):
			cur = db_to_linear(AudioServer.get_bus_volume_db(bus_idx)) * 100.0
		master_slider.value = cur
		if not master_slider.value_changed.is_connected(_on_volume_changed.bind("Master")):
			master_slider.value_changed.connect(_on_volume_changed.bind("Master"))

	if sfx_slider != null:
		var bus_idx := AudioServer.get_bus_index("SFX")
		var cur := 90.0
		if bus_idx >= 0 and not AudioServer.is_bus_mute(bus_idx):
			cur = db_to_linear(AudioServer.get_bus_volume_db(bus_idx)) * 100.0
		sfx_slider.value = cur
		if not sfx_slider.value_changed.is_connected(_on_volume_changed.bind("SFX")):
			sfx_slider.value_changed.connect(_on_volume_changed.bind("SFX"))

	if music_slider != null:
		var bus_idx := AudioServer.get_bus_index("Music")
		var cur := 75.0
		if bus_idx >= 0 and not AudioServer.is_bus_mute(bus_idx):
			cur = db_to_linear(AudioServer.get_bus_volume_db(bus_idx)) * 100.0
		music_slider.value = cur
		if not music_slider.value_changed.is_connected(_on_volume_changed.bind("Music")):
			music_slider.value_changed.connect(_on_volume_changed.bind("Music"))


func _on_volume_changed(val: float, bus_name: String) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		var linear := val / 100.0
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear) if linear > 0.001 else -80.0)
		AudioServer.set_bus_mute(bus_idx, linear <= 0.001)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if settings_modal != null and settings_modal.visible:
			_on_close_settings()
			get_viewport().set_input_as_handled()
		elif visible:
			close()
			get_viewport().set_input_as_handled()
		else:
			open()
			get_viewport().set_input_as_handled()


func open(level_id: int = 1) -> void:
	var data: Dictionary = UIColors.get_level_data(level_id)
	if chamber_label != null:
		chamber_label.text = "%s // %s" % [data.get("code", "GV-01"), data.get("name", "ACCESS DENIED")]
	if status_label != null:
		status_label.text = String(data.get("status", "SIMULATION ACTIVE"))
	if settings_modal != null:
		settings_modal.visible = false
	show()
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if resume_button != null:
		resume_button.grab_focus()


func close() -> void:
	UIAudio.play_click(self)
	if settings_modal != null:
		settings_modal.visible = false
	hide()
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resumed.emit()


func _on_resume_pressed() -> void:
	close()


func _on_restart_pressed() -> void:
	UIAudio.play_click(self)
	if settings_modal != null:
		settings_modal.visible = false
	hide()
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
	restarted.emit()
	if auto_reload_scene and is_inside_tree() and get_tree() != null and get_tree().current_scene != null:
		get_tree().reload_current_scene()


func _on_settings_pressed() -> void:
	UIAudio.play_click(self)
	if settings_modal != null:
		settings_modal.visible = true
		if close_settings_btn != null:
			close_settings_btn.grab_focus()
	settings_requested.emit()


func _on_close_settings() -> void:
	UIAudio.play_back(self)
	if settings_modal != null:
		settings_modal.visible = false
	if settings_button != null:
		settings_button.grab_focus()


func _on_abort_pressed() -> void:
	UIAudio.play_click(self)
	if settings_modal != null:
		settings_modal.visible = false
	hide()
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	aborted_to_menu.emit()
