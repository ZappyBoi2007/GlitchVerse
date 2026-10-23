extends Node

## Event-driven audio service. Current streams are synthesized placeholders so the
## project remains audible without external assets; event callers stay unchanged
## when licensed WAV/OGG resources replace them later.

signal atmosphere_profile_changed(profile: StringName)
signal bus_volume_changed(bus_name: StringName, normalized_volume: float)

const SAMPLE_RATE := 22050
const MAX_2D_ONE_SHOTS := 16
const MAX_3D_ONE_SHOTS := 20
const BUS_NAMES: Array[StringName] = [
	&"Master", &"Music", &"Ambience", &"SFX", &"UI", &"Voice"
]
const ATMOSPHERE_PROFILES: Array[StringName] = [
	&"level_1", &"level_2", &"level_3", &"level_4"
]

var _streams: Dictionary = {}
var _active_2d: Array[AudioStreamPlayer] = []
var _active_3d: Array[AudioStreamPlayer3D] = []
var _world_loops: Dictionary = {}
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _atmosphere_tween: Tween
var _current_profile: StringName = &""
var _last_invalid_sound_msec := -1000
var _last_loading_index := -1
var _has_loaded_level := false
var _victory_played := false
var _playback_enabled := true
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_playback_enabled = DisplayServer.get_name() != "headless"
	_rng.randomize()
	_ensure_audio_buses()
	_build_placeholder_streams()
	_create_atmosphere_players()
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_bind_existing_tree")


func _exit_tree() -> void:
	if is_instance_valid(_atmosphere_tween):
		_atmosphere_tween.kill()
	stop_all_world_audio()
	if is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null
	if is_instance_valid(_ambience_player):
		_ambience_player.stop()
		_ambience_player.stream = null
	_streams.clear()


func has_event(event_name: StringName) -> bool:
	return _streams.has(event_name)


func register_event(event_name: StringName, stream: AudioStream, replace_existing := false) -> bool:
	if event_name.is_empty() or stream == null:
		return false
	if _streams.has(event_name) and not replace_existing:
		return false
	_streams[event_name] = stream
	return true


func get_atmosphere_profiles() -> Array[StringName]:
	return ATMOSPHERE_PROFILES.duplicate()


func get_current_atmosphere_profile() -> StringName:
	return _current_profile


func get_active_world_loop_count() -> int:
	_prune_world_loops()
	return _world_loops.size()


func play_sfx(
	event_name: StringName,
	volume_db := 0.0,
	pitch_scale := 1.0,
	bus_name: StringName = &"SFX"
) -> AudioStreamPlayer:
	var stream := _streams.get(event_name) as AudioStream
	if stream == null:
		push_warning("Unknown audio event: %s" % event_name)
		return null
	return _play_2d_stream(stream, event_name, volume_db, pitch_scale, bus_name)


func play_voice(stream: AudioStream, volume_db := 0.0, pitch_scale := 1.0) -> AudioStreamPlayer:
	if stream == null:
		return null
	return _play_2d_stream(stream, &"voice", volume_db, pitch_scale, &"Voice")


func _play_2d_stream(
	stream: AudioStream,
	event_name: StringName,
	volume_db: float,
	pitch_scale: float,
	bus_name: StringName
) -> AudioStreamPlayer:
	_prune_one_shots()
	if _active_2d.size() >= MAX_2D_ONE_SHOTS:
		return null
	var player := AudioStreamPlayer.new()
	player.name = "OneShot_%s" % event_name
	player.stream = stream
	player.bus = String(bus_name)
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	_active_2d.append(player)
	player.finished.connect(_release_2d.bind(player), CONNECT_ONE_SHOT)
	if _playback_enabled:
		player.play()
	return player


func play_3d(
	event_name: StringName,
	world_position: Vector3,
	volume_db := 0.0,
	pitch_scale := 1.0,
	max_distance := 24.0
) -> AudioStreamPlayer3D:
	var stream := _streams.get(event_name) as AudioStream
	if stream == null:
		push_warning("Unknown positional audio event: %s" % event_name)
		return null
	_prune_one_shots()
	if _active_3d.size() >= MAX_3D_ONE_SHOTS:
		return null
	var player := AudioStreamPlayer3D.new()
	player.name = "WorldOneShot_%s" % event_name
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = max_distance
	player.unit_size = 3.0
	add_child(player)
	player.global_position = world_position
	_active_3d.append(player)
	player.finished.connect(_release_3d.bind(player), CONNECT_ONE_SHOT)
	if _playback_enabled:
		player.play()
	return player


func play_ui_cue(cue: StringName) -> AudioStreamPlayer:
	var event_name: StringName
	match cue:
		&"hover":
			event_name = &"ui_hover"
		&"click":
			event_name = &"ui_click"
		&"confirm":
			event_name = &"ui_confirm"
		&"back":
			event_name = &"ui_back"
		&"error":
			event_name = &"ui_error"
		_:
			push_warning("Unknown UI audio cue: %s" % cue)
			return null
	return play_sfx(event_name, -5.0, 1.0, &"UI")


func start_world_loop(
	owner: Node3D,
	slot: StringName,
	event_name: StringName,
	volume_db := -12.0,
	max_distance := 20.0
) -> AudioStreamPlayer3D:
	if not is_instance_valid(owner):
		return null
	var stream := _streams.get(event_name) as AudioStream
	if stream == null:
		push_warning("Unknown loop audio event: %s" % event_name)
		return null
	var key := _get_world_loop_key(owner, slot)
	var existing := _world_loops.get(key) as AudioStreamPlayer3D
	if is_instance_valid(existing):
		return existing
	_world_loops.erase(key)
	var player := AudioStreamPlayer3D.new()
	player.name = "AudioLoop_%s" % slot
	player.stream = stream
	player.bus = "Ambience"
	player.volume_db = volume_db
	player.max_distance = max_distance
	player.unit_size = 3.0
	owner.add_child(player)
	_world_loops[key] = player
	player.tree_exiting.connect(_forget_world_loop.bind(key), CONNECT_ONE_SHOT)
	if _playback_enabled:
		player.play()
	return player


func stop_world_loop(owner: Node3D, slot: StringName) -> void:
	if not is_instance_valid(owner):
		return
	var key := _get_world_loop_key(owner, slot)
	var player := _world_loops.get(key) as AudioStreamPlayer3D
	_world_loops.erase(key)
	if is_instance_valid(player):
		player.stop()
		player.queue_free()


func set_atmosphere_profile(profile: StringName) -> bool:
	if profile not in ATMOSPHERE_PROFILES:
		push_warning("Unknown atmosphere profile: %s" % profile)
		return false
	if profile == _current_profile:
		return true
	if is_instance_valid(_atmosphere_tween):
		_atmosphere_tween.kill()
	if _music_player.playing or _ambience_player.playing:
		_atmosphere_tween = create_tween().set_parallel(true)
		_atmosphere_tween.tween_property(_music_player, "volume_db", -48.0, 0.4)
		_atmosphere_tween.tween_property(_ambience_player, "volume_db", -48.0, 0.4)
		_atmosphere_tween.finished.connect(_apply_atmosphere_profile.bind(profile), CONNECT_ONE_SHOT)
	else:
		_apply_atmosphere_profile(profile)
	return true


func set_bus_volume(bus_name: StringName, normalized_volume: float) -> bool:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return false
	var safe_volume := clampf(normalized_volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(safe_volume, 0.0001)))
	AudioServer.set_bus_mute(bus_index, is_zero_approx(safe_volume))
	bus_volume_changed.emit(bus_name, safe_volume)
	return true


func get_bus_volume(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0 or AudioServer.is_bus_mute(bus_index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))


func stop_all_world_audio() -> void:
	for player in _world_loops.values():
		if is_instance_valid(player):
			player.queue_free()
	_world_loops.clear()
	for player in _active_3d:
		if is_instance_valid(player):
			player.queue_free()
	_active_3d.clear()
	for player in _active_2d:
		if is_instance_valid(player):
			player.queue_free()
	_active_2d.clear()


func _create_atmosphere_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	_music_player.volume_db = -48.0
	add_child(_music_player)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "Ambience"
	_ambience_player.volume_db = -48.0
	add_child(_ambience_player)


func _apply_atmosphere_profile(profile: StringName) -> void:
	_current_profile = profile
	_music_player.stream = _streams.get(StringName("music_%s" % profile)) as AudioStream
	_ambience_player.stream = _streams.get(StringName("ambience_%s" % profile)) as AudioStream
	if _playback_enabled:
		_music_player.play()
		_ambience_player.play()
	_atmosphere_tween = create_tween().set_parallel(true)
	_atmosphere_tween.tween_property(_music_player, "volume_db", -9.0, 0.8)
	_atmosphere_tween.tween_property(_ambience_player, "volume_db", -11.0, 0.8)
	atmosphere_profile_changed.emit(profile)


func _on_node_added(node: Node) -> void:
	call_deferred("_bind_node", node)


func _bind_existing_tree() -> void:
	_bind_subtree(get_tree().root)


func _bind_subtree(node: Node) -> void:
	_bind_node(node)
	for child in node.get_children():
		_bind_subtree(child)


func _bind_node(node: Node) -> void:
	if not is_instance_valid(node) or node == self or node.has_meta("glitchverse_audio_bound"):
		return
	if node is PhaseableBarrier:
		node.set_meta("glitchverse_audio_bound", true)
		node.state_changed.connect(_on_phase_state_changed.bind(node))
		_sync_phase_loop(node)
	elif node is GravityCrate:
		node.set_meta("glitchverse_audio_bound", true)
		node.state_changed.connect(_on_gravity_state_changed.bind(node))
		if node.gravity_inverted:
			start_world_loop(node, &"gravity", &"gravity_hum_loop", -15.0)
	elif node is FreezableHazard:
		node.set_meta("glitchverse_audio_bound", true)
		node.state_changed.connect(_on_freeze_state_changed.bind(node))
		if not node.is_frozen:
			start_world_loop(node, &"hazard", &"hazard_loop", -18.0)
	elif node is RealityDebugger:
		node.set_meta("glitchverse_audio_bound", true)
		node.feedback_changed.connect(_on_debugger_feedback)
		node.ability_changed.connect(_on_ability_changed)
	elif node is GameFlowManager:
		node.set_meta("glitchverse_audio_bound", true)
		_bind_game_flow(node)


func _bind_game_flow(flow: GameFlowManager) -> void:
	flow.level_loading.connect(_on_level_loading)
	flow.level_started.connect(_on_level_started)
	flow.puzzle_completed.connect(_on_puzzle_completed)
	flow.exit_unlocked.connect(_on_exit_unlocked)
	flow.level_completed.connect(_on_level_completed)
	flow.game_failed.connect(_on_game_failed)
	flow.game_victory.connect(_on_game_victory)
	flow.replay_started.connect(_on_replay_started)


func _on_phase_state_changed(is_phased: bool, source: PhaseableBarrier) -> void:
	stop_world_loop(source, &"phase")
	if is_phased:
		play_3d(&"phase_glitch", source.global_position, -5.0, _rng.randf_range(0.96, 1.04))
		play_3d(&"phase_mechanical", source.global_position, -9.0, 1.0)
		start_world_loop(source, &"phase", &"phase_active_loop", -18.0)
	else:
		play_3d(&"phase_restore", source.global_position, -6.0, 1.0)
		start_world_loop(source, &"phase", &"phase_idle_loop", -23.0)


func _sync_phase_loop(source: PhaseableBarrier) -> void:
	start_world_loop(
		source,
		&"phase",
		&"phase_active_loop" if source.is_phased else &"phase_idle_loop",
		-18.0 if source.is_phased else -23.0
	)


func _on_gravity_state_changed(is_inverted: bool, source: GravityCrate) -> void:
	if is_inverted:
		play_3d(&"gravity_pulse", source.global_position, -4.0, 1.0)
		play_3d(&"gravity_rise", source.global_position, -8.0, 1.0)
		start_world_loop(source, &"gravity", &"gravity_hum_loop", -16.0)
	else:
		stop_world_loop(source, &"gravity")
		play_3d(&"gravity_restore", source.global_position, -5.0, 1.0)


func _on_freeze_state_changed(is_frozen: bool, source: FreezableHazard) -> void:
	if is_frozen:
		stop_world_loop(source, &"hazard")
		play_3d(&"freeze_interrupt", source.global_position, -4.0, 1.0)
		play_3d(&"freeze_clock", source.global_position, -9.0, 1.0)
	else:
		play_3d(&"freeze_resume", source.global_position, -5.0, 1.0)
		start_world_loop(source, &"hazard", &"hazard_loop", -18.0)


func _on_debugger_feedback(_message: String, is_error: bool) -> void:
	if not is_error:
		return
	var now := Time.get_ticks_msec()
	if now - _last_invalid_sound_msec < 300:
		return
	_last_invalid_sound_msec = now
	play_sfx(&"invalid_target", -9.0, 1.0)


func _on_ability_changed(_label: String, _color: Color) -> void:
	play_sfx(&"ability_select", -10.0, _rng.randf_range(0.97, 1.03))


func _on_level_loading(level_index: int, _level_path: String) -> void:
	var is_restart := _has_loaded_level and level_index == _last_loading_index
	stop_all_world_audio()
	if is_restart:
		play_sfx(&"restart", -5.0)
	_last_loading_index = level_index
	_has_loaded_level = true


func _on_level_started(level_index: int, _level_name: String) -> void:
	set_atmosphere_profile(StringName("level_%d" % clampi(level_index + 1, 1, 4)))


func _on_puzzle_completed(_level_index: int, _elapsed_seconds: float) -> void:
	play_sfx(&"puzzle_complete", -4.0)


func _on_exit_unlocked(_level_index: int) -> void:
	play_sfx(&"exit_unlock", -4.0)


func _on_level_completed(_level_index: int, _elapsed_seconds: float, _score: int) -> void:
	play_sfx(&"level_complete", -5.0)


func _on_game_failed(_reason: String) -> void:
	play_sfx(&"failure", -4.0)


func _on_game_victory(_elapsed_seconds: float, _score: int) -> void:
	if _victory_played:
		return
	_victory_played = true
	play_sfx(&"victory", -3.0)


func _on_replay_started() -> void:
	_victory_played = false


func _release_2d(player: AudioStreamPlayer) -> void:
	_active_2d.erase(player)
	if is_instance_valid(player):
		player.queue_free()


func _release_3d(player: AudioStreamPlayer3D) -> void:
	_active_3d.erase(player)
	if is_instance_valid(player):
		player.queue_free()


func _prune_one_shots() -> void:
	_active_2d = _active_2d.filter(func(player: AudioStreamPlayer) -> bool: return is_instance_valid(player))
	_active_3d = _active_3d.filter(func(player: AudioStreamPlayer3D) -> bool: return is_instance_valid(player))


func _prune_world_loops() -> void:
	for key in _world_loops.keys():
		if not is_instance_valid(_world_loops[key]):
			_world_loops.erase(key)


func _forget_world_loop(key: StringName) -> void:
	_world_loops.erase(key)


func _get_world_loop_key(owner: Node3D, slot: StringName) -> StringName:
	return StringName("%d:%s" % [owner.get_instance_id(), slot])


func _ensure_audio_buses() -> void:
	for bus_name in BUS_NAMES:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var bus_index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, &"Master")


func _build_placeholder_streams() -> void:
	_streams[&"phase_glitch"] = _make_tone(0.2, 920.0, 190.0, 0.34, 0.22, 26.0)
	_streams[&"phase_mechanical"] = _make_tone(0.34, 150.0, 82.0, 0.25, 0.05)
	_streams[&"phase_restore"] = _make_tone(0.28, 260.0, 860.0, 0.28, 0.08, 10.0)
	_streams[&"gravity_pulse"] = _make_tone(0.4, 72.0, 46.0, 0.42, 0.02)
	_streams[&"gravity_rise"] = _make_tone(0.58, 105.0, 430.0, 0.25, 0.04)
	_streams[&"gravity_restore"] = _make_tone(0.4, 310.0, 68.0, 0.31, 0.03)
	_streams[&"freeze_interrupt"] = _make_tone(0.18, 1320.0, 75.0, 0.36, 0.2, 30.0)
	_streams[&"freeze_clock"] = _make_tone(0.42, 780.0, 420.0, 0.22, 0.03, 14.0)
	_streams[&"freeze_resume"] = _make_tone(0.42, 120.0, 620.0, 0.27, 0.05)
	_streams[&"invalid_target"] = _make_tone(0.12, 510.0, 330.0, 0.18, 0.02, 18.0)
	_streams[&"ability_select"] = _make_tone(0.09, 360.0, 620.0, 0.14)
	_streams[&"footstep"] = _make_tone(0.11, 105.0, 48.0, 0.24, 0.18)
	_streams[&"jump"] = _make_tone(0.16, 160.0, 270.0, 0.18, 0.05)
	_streams[&"land"] = _make_tone(0.24, 98.0, 42.0, 0.3, 0.16)
	_streams[&"ui_hover"] = _make_tone(0.05, 520.0, 610.0, 0.1)
	_streams[&"ui_click"] = _make_tone(0.07, 340.0, 240.0, 0.14)
	_streams[&"ui_confirm"] = _make_tone(0.14, 360.0, 760.0, 0.16)
	_streams[&"ui_back"] = _make_tone(0.12, 520.0, 260.0, 0.14)
	_streams[&"ui_error"] = _make_tone(0.15, 240.0, 150.0, 0.17, 0.02, 12.0)
	_streams[&"puzzle_complete"] = _make_tone(0.65, 220.0, 740.0, 0.2, 0.02)
	_streams[&"exit_unlock"] = _make_tone(0.72, 110.0, 520.0, 0.24, 0.04)
	_streams[&"level_complete"] = _make_tone(0.85, 260.0, 880.0, 0.2)
	_streams[&"failure"] = _make_tone(0.75, 260.0, 54.0, 0.25, 0.06)
	_streams[&"restart"] = _make_tone(0.35, 150.0, 460.0, 0.16, 0.03)
	_streams[&"victory"] = _make_tone(1.25, 180.0, 920.0, 0.22, 0.02)
	_streams[&"fragment_pickup"] = _make_tone(0.34, 420.0, 1180.0, 0.19, 0.03, 12.0)
	_streams[&"fragment_requirement"] = _make_tone(0.7, 260.0, 920.0, 0.18, 0.01)
	_streams[&"grapple_attach"] = _make_tone(0.22, 260.0, 980.0, 0.2, 0.03)
	_streams[&"grapple_detach"] = _make_tone(0.16, 620.0, 190.0, 0.15, 0.02)
	_streams[&"grapple_invalid"] = _make_tone(0.11, 230.0, 170.0, 0.14, 0.01)
	_streams[&"vector_run_start"] = _make_tone(0.16, 180.0, 440.0, 0.12, 0.04)
	_streams[&"vector_wall_jump"] = _make_tone(0.18, 240.0, 680.0, 0.15, 0.03)
	_streams[&"sword_swing"] = _make_tone(0.2, 190.0, 850.0, 0.18, 0.04)
	_streams[&"sword_hit"] = _make_tone(0.16, 1180.0, 310.0, 0.22, 0.08)
	_streams[&"sword_miss"] = _make_tone(0.1, 420.0, 260.0, 0.1, 0.02)
	_streams[&"construct_alert"] = _make_tone(0.28, 180.0, 520.0, 0.17, 0.02)
	_streams[&"construct_attack"] = _make_tone(0.3, 480.0, 95.0, 0.24, 0.04)
	_streams[&"construct_hurt"] = _make_tone(0.14, 740.0, 240.0, 0.18, 0.07)
	_streams[&"construct_death"] = _make_tone(0.55, 310.0, 52.0, 0.25, 0.09)
	_streams[&"player_hurt"] = _make_tone(0.2, 170.0, 70.0, 0.24, 0.05)
	_streams[&"bridge_deploy"] = _make_tone(0.65, 85.0, 210.0, 0.2, 0.05, 7.0)
	_streams[&"rewire_switch"] = _make_tone(0.5, 150.0, 640.0, 0.2, 0.03, 6.0)
	_streams[&"relay_restore"] = _make_tone(0.55, 260.0, 920.0, 0.18, 0.02)
	_streams[&"polarity_shift"] = _make_tone(0.65, 90.0, 520.0, 0.22, 0.04)
	_streams[&"shutdown"] = _make_tone(1.1, 420.0, 48.0, 0.24, 0.05, 5.0)

	_streams[&"phase_idle_loop"] = _make_tone(4.0, 220.0, 220.0, 0.08, 0.0, 5.0, true)
	_streams[&"phase_active_loop"] = _make_tone(4.0, 330.0, 330.0, 0.11, 0.0, 7.0, true)
	_streams[&"gravity_hum_loop"] = _make_tone(4.0, 55.0, 55.0, 0.18, 0.0, 2.0, true)
	_streams[&"hazard_loop"] = _make_tone(4.0, 88.0, 88.0, 0.12, 0.0, 4.0, true)

	_build_atmosphere_streams()


func _build_atmosphere_streams() -> void:
	var music_frequencies := [55.0, 46.0, 72.0, 60.0]
	var ambience_frequencies := [110.0, 69.0, 144.0, 90.0]
	var gates := [0.5, 1.5, 6.0, 3.0]
	for index in range(4):
		var profile := "level_%d" % (index + 1)
		_streams[StringName("music_%s" % profile)] = _make_tone(
			4.0, music_frequencies[index], music_frequencies[index], 0.07, 0.0, 0.0, true
		)
		_streams[StringName("ambience_%s" % profile)] = _make_tone(
			4.0, ambience_frequencies[index], ambience_frequencies[index], 0.055, 0.0, gates[index], true
		)


func _make_tone(
	duration: float,
	start_frequency: float,
	end_frequency: float,
	amplitude: float,
	noise_amount := 0.0,
	gate_rate := 0.0,
	looped := false
) -> AudioStreamWAV:
	var frame_count := maxi(1, int(duration * SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var phase := 0.0
	var noise := RandomNumberGenerator.new()
	noise.seed = int(start_frequency * 1000.0 + end_frequency * 37.0 + duration * 101.0)
	for frame in range(frame_count):
		var time := float(frame) / SAMPLE_RATE
		var progress := float(frame) / maxf(1.0, float(frame_count - 1))
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / SAMPLE_RATE
		var envelope := 1.0
		if not looped:
			envelope = minf(1.0, time / 0.012) * minf(1.0, (duration - time) / 0.08)
		var gate := 1.0
		if gate_rate > 0.0:
			gate = 0.35 + 0.65 * maxf(0.0, sin(TAU * gate_rate * time))
		var sample := sin(phase) * 0.72 + sin(phase * 0.5) * 0.18
		sample += noise.randf_range(-1.0, 1.0) * noise_amount
		var encoded := clampi(roundi(sample * amplitude * envelope * gate * 32767.0), -32768, 32767)
		data.encode_s16(frame * 2, encoded)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = frame_count
	return stream
