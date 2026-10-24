class_name UIAudio
extends RefCounted

## Centralized UI Audio Service for GlitchVerse.
## Registers verified CC0 curated audio streams with the engine's AudioManager
## and provides safe, rate-limited audio feedback for native Godot UI controls.

const STREAM_HOVER := "res://assets/audio/ui_curated/ui_hover_tick.ogg"
const STREAM_CLICK := "res://assets/audio/ui_curated/ui_click_mechanical.ogg"
const STREAM_CONFIRM := "res://assets/audio/ui_curated/ui_confirmation_chime.ogg"
const STREAM_ERROR := "res://assets/audio/ui_curated/ui_error_alarm.ogg"
const STREAM_RELAY := "res://assets/audio/ui_curated/env_relay_terminal.ogg"
const STREAM_DOOR := "res://assets/audio/ui_curated/env_containment_door_open.ogg"
const STREAM_MENU_MUSIC := "res://assets/audio/ui_curated/music_menu_the_surreal_truth.mp3"
const STREAM_L1_AMBIENCE := "res://assets/audio/ui_curated/ambience_level1_sector.mp3"
const STREAM_L2_AMBIENCE := "res://assets/audio/ui_curated/ambience_level2_airy.mp3"
const STREAM_L3_AMBIENCE := "res://assets/audio/ui_curated/ambience_level3_pulse.mp3"
const STREAM_L4_MUSIC := "res://assets/audio/ui_curated/music_level4_urgent.mp3"

static var _initialized: bool = false
static var _registered_events: bool = false
static var _last_hover_msec: int = 0
static var _cached_streams: Dictionary = {}
static var _fallback_players: Dictionary = {}


static func initialize_audio_service(caller_node: Node = null) -> void:
	if not _initialized:
		_initialized = true
		_get_or_load_stream(STREAM_HOVER)
		_get_or_load_stream(STREAM_CLICK)
		_get_or_load_stream(STREAM_CONFIRM)
		_get_or_load_stream(STREAM_ERROR)
		_get_or_load_stream(STREAM_RELAY)
		_get_or_load_stream(STREAM_DOOR)

	register_curated_streams(caller_node)


static func register_curated_streams(caller_node: Node = null) -> void:
	var am := _get_audio_manager(caller_node)
	if am != null and am.has_method("register_event"):
		var h := _get_or_load_stream(STREAM_HOVER)
		if h:
			am.call("register_event", &"ui_hover", h, true)
		var c := _get_or_load_stream(STREAM_CLICK)
		if c:
			am.call("register_event", &"ui_click", c, true)
			am.call("register_event", &"ui_back", c, true)
		var cf := _get_or_load_stream(STREAM_CONFIRM)
		if cf:
			am.call("register_event", &"ui_confirm", cf, true)
		var er := _get_or_load_stream(STREAM_ERROR)
		if er:
			am.call("register_event", &"ui_error", er, true)
		var dr := _get_or_load_stream(STREAM_DOOR)
		if dr:
			am.call("register_event", &"exit_unlock", dr, true)
		var rl := _get_or_load_stream(STREAM_RELAY)
		if rl:
			am.call("register_event", &"relay_restore", rl, true)
		var l1 := _get_or_load_stream(STREAM_L1_AMBIENCE)
		if l1:
			am.call("register_event", &"music_level_1", l1, true)
		var l2 := _get_or_load_stream(STREAM_L2_AMBIENCE)
		if l2:
			am.call("register_event", &"music_level_2", l2, true)
		var l3 := _get_or_load_stream(STREAM_L3_AMBIENCE)
		if l3:
			am.call("register_event", &"music_level_3", l3, true)
		var l4 := _get_or_load_stream(STREAM_L4_MUSIC)
		if l4:
			am.call("register_event", &"music_level_4", l4, true)
		_registered_events = true


static func attach_button_sounds(button: Button, caller_node: Node = null) -> void:
	if button == null:
		return
	initialize_audio_service(caller_node if caller_node != null else button)

	if not button.has_meta("ui_audio_bound"):
		button.set_meta("ui_audio_bound", true)
		button.mouse_entered.connect(func():
			play_hover(caller_node if caller_node != null else button)
		)
		button.focus_entered.connect(func():
			play_hover(caller_node if caller_node != null else button)
		)
		button.pressed.connect(func():
			play_click(caller_node if caller_node != null else button)
		)


static func attach_all_buttons(root: Node) -> void:
	if root == null:
		return
	if root is Button:
		attach_button_sounds(root as Button, root)
	for child in root.get_children():
		attach_all_buttons(child)


static func play_hover(caller_node: Node = null) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_hover_msec < 45:
		return
	_last_hover_msec = now

	if not _registered_events:
		register_curated_streams(caller_node)

	var am := _get_audio_manager(caller_node)
	if am != null and am.has_method("play_ui_cue"):
		am.call("play_ui_cue", &"hover")
	else:
		_play_fallback(caller_node, STREAM_HOVER, -14.0, "UI")


static func play_click(caller_node: Node = null) -> void:
	if not _registered_events:
		register_curated_streams(caller_node)

	var am := _get_audio_manager(caller_node)
	if am != null and am.has_method("play_ui_cue"):
		am.call("play_ui_cue", &"click")
	else:
		_play_fallback(caller_node, STREAM_CLICK, -8.0, "UI")


static func play_confirm(caller_node: Node = null) -> void:
	if not _registered_events:
		register_curated_streams(caller_node)

	var am := _get_audio_manager(caller_node)
	if am != null and am.has_method("play_ui_cue"):
		am.call("play_ui_cue", &"confirm")
	else:
		_play_fallback(caller_node, STREAM_CONFIRM, -6.0, "UI")


static func play_back(caller_node: Node = null) -> void:
	if not _registered_events:
		register_curated_streams(caller_node)

	var am := _get_audio_manager(caller_node)
	if am != null and am.has_method("play_ui_cue"):
		am.call("play_ui_cue", &"back")
	else:
		_play_fallback(caller_node, STREAM_CLICK, -10.0, "UI")


static func play_error(caller_node: Node = null) -> void:
	if not _registered_events:
		register_curated_streams(caller_node)

	var am := _get_audio_manager(caller_node)
	if am != null and am.has_method("play_ui_cue"):
		am.call("play_ui_cue", &"error")
	else:
		_play_fallback(caller_node, STREAM_ERROR, -8.0, "UI")


static func play_level_complete(caller_node: Node = null) -> void:
	var am := _get_audio_manager(caller_node)
	if am != null and am.has_method("play_sfx") and am.call("has_event", &"level_complete"):
		am.call("play_sfx", &"level_complete", -5.0)
	else:
		play_confirm(caller_node)


static func play_game_over(caller_node: Node = null) -> void:
	var am := _get_audio_manager(caller_node)
	if am != null and am.has_method("play_sfx") and am.call("has_event", &"failure"):
		am.call("play_sfx", &"failure", -4.0)
	else:
		play_error(caller_node)


static func play_victory(caller_node: Node = null) -> void:
	var am := _get_audio_manager(caller_node)
	if am != null and am.has_method("play_sfx") and am.call("has_event", &"victory"):
		am.call("play_sfx", &"victory", -3.0)
	else:
		play_confirm(caller_node)


static func _get_or_load_stream(path: String) -> AudioStream:
	if _cached_streams.has(path):
		return _cached_streams[path] as AudioStream
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path) as AudioStream
		if res != null:
			_cached_streams[path] = res
			return res
	return null


static func _get_audio_manager(caller_node: Node = null) -> Node:
	if caller_node != null and is_instance_valid(caller_node) and caller_node.is_inside_tree():
		var tree := caller_node.get_tree()
		if tree != null and tree.root != null:
			return tree.root.get_node_or_null("AudioManager")
	return null


static func _play_fallback(caller_node: Node, path: String, volume_db: float, bus: String = "UI") -> void:
	if caller_node == null or not is_instance_valid(caller_node) or not caller_node.is_inside_tree():
		return
	var stream := _get_or_load_stream(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
	caller_node.add_child(player)
	player.finished.connect(func():
		if is_instance_valid(player):
			player.queue_free()
	)
	player.play()
