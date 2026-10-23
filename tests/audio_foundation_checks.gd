extends SceneTree

## Configuration/lifecycle checks for the audio foundation. These validate nodes and
## event routing; they cannot prove perceived loudness or sound quality headlessly.

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		print("FAIL: ", description)


func settle() -> void:
	for _frame in range(4):
		await process_frame


func _run() -> void:
	await settle()
	var audio := root.get_node_or_null("AudioManager")
	check(audio != null, "AudioManager autoload exists")
	for bus_name in [&"Master", &"Music", &"Ambience", &"SFX", &"UI", &"Voice"]:
		check(AudioServer.get_bus_index(bus_name) >= 0, "%s audio bus exists" % bus_name)

	for event_name in [
		&"phase_glitch", &"gravity_pulse", &"freeze_interrupt", &"invalid_target",
		&"footstep", &"jump", &"land", &"puzzle_complete", &"victory",
		&"fragment_pickup", &"fragment_requirement", &"grapple_attach",
		&"vector_run_start", &"vector_wall_jump",
		&"sword_swing", &"sword_hit", &"construct_attack", &"bridge_deploy",
		&"rewire_switch", &"relay_restore", &"polarity_shift", &"shutdown"
	]:
		check(bool(audio.call("has_event", event_name)), "%s event is registered" % event_name)

	var ui_player := audio.call("play_ui_cue", &"hover") as AudioStreamPlayer
	check(ui_player != null and ui_player.bus == "UI" and ui_player.stream != null, "UI cue routes to UI bus")
	var world_player := audio.call("play_3d", &"gravity_pulse", Vector3(2, 1, 3)) as AudioStreamPlayer3D
	check(world_player != null and world_player.bus == "SFX" and world_player.max_distance > 0.0, "3D cue is spatial and attenuated")

	var loop_owner := Node3D.new()
	loop_owner.name = "AudioLoopTestOwner"
	root.add_child(loop_owner)
	var first_loop := audio.call("start_world_loop", loop_owner, &"test", &"gravity_hum_loop") as AudioStreamPlayer3D
	var duplicate_loop := audio.call("start_world_loop", loop_owner, &"test", &"gravity_hum_loop") as AudioStreamPlayer3D
	check(first_loop != null and first_loop == duplicate_loop, "duplicate loop request reuses existing player")
	check(int(audio.call("get_active_world_loop_count")) == 1, "loop registry contains one keyed loop")
	audio.call("stop_world_loop", loop_owner, &"test")
	check(int(audio.call("get_active_world_loop_count")) == 0, "stopped loop leaves registry")

	check(bool(audio.call("set_atmosphere_profile", &"level_3")), "clock-failure atmosphere profile is accepted")
	check(audio.call("get_current_atmosphere_profile") == &"level_3", "selected atmosphere profile is retained")
	var original_sfx_volume := float(audio.call("get_bus_volume", &"SFX"))
	check(bool(audio.call("set_bus_volume", &"SFX", 0.5)), "SFX volume can be set through public API")
	check(is_equal_approx(float(audio.call("get_bus_volume", &"SFX")), 0.5), "SFX volume API round-trips")
	audio.call("set_bus_volume", &"SFX", original_sfx_volume)

	audio.call("stop_all_world_audio")
	loop_owner.queue_free()
	await settle()
	print("AUDIO FOUNDATION CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
