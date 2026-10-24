extends SceneTree

var checks := 0
var failures: Array[String] = []


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("FAIL: %s" % description)


func settle(frames := 8) -> void:
	for frame in range(frames):
		await process_frame


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	check(
		ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/main_menu.tscn",
		"F5 starts the production main menu"
	)

	var menu_scene := load("res://scenes/ui/main_menu.tscn") as PackedScene
	check(menu_scene != null, "production main menu resource loads")
	var menu := menu_scene.instantiate() as MainMenu
	menu.auto_load_gameplay_scene = false
	root.add_child(menu)
	await settle(3)
	var start_button := menu.get_node_or_null("%StartBtn") as Button
	check(start_button != null, "main menu exposes its Start button")
	check(start_button != null and start_button.mouse_filter == Control.MOUSE_FILTER_STOP, "Start button accepts mouse input")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "main menu releases the mouse cursor")
	var play_requests := [0]
	menu.play_requested.connect(func() -> void: play_requests[0] += 1)
	if start_button != null:
		start_button.pressed.emit()
	await settle(2)
	check(play_requests[0] == 1, "Start button dispatches exactly one gameplay request")
	menu.queue_free()
	await settle(2)

	var campaign_scene := load("res://main.tscn") as PackedScene
	check(campaign_scene != null, "four-level campaign scene loads")
	var flow := campaign_scene.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(16)
	check(flow.level_scenes.size() == 4, "campaign still registers exactly four levels")
	check(flow.get_node_or_null("CampaignHUD") != null, "proven campaign HUD remains available as the sole gameplay HUD")
	check(flow.get_node_or_null("InGameHUD") == null, "release does not instance a duplicate experimental HUD")
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "campaign enters playable state")

	var health := flow.player.find_child("PlayerHealth", true, false) as PlayerHealth
	check(health != null, "persistent action player exposes PlayerHealth")
	if health != null:
		check(health.take_damage(1), "player accepts test damage before restart")
		check(health.current_health < health.maximum_health, "test damage reduces health")
	flow.restart_current_level()
	await settle(16)
	health = flow.player.find_child("PlayerHealth", true, false) as PlayerHealth
	check(health != null and health.current_health == health.maximum_health, "level restart restores persistent player health")
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "restart returns to playable state")

	flow.queue_free()
	await settle(3)
	print("FINAL TEAM SYNC CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
