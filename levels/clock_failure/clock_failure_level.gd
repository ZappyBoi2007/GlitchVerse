class_name ClockFailureLevel
extends CampaignLevelBase

const CYCLE_HAZARD_SCENE := preload("res://interactive/cycle_hazard.tscn")

var rewire_console: RewireConsole
var cycle_hazard: CycleHazard
var security_construct: SecurityConstruct
var sync_a: ObjectiveRelay
var sync_b: ObjectiveRelay
var campaign_exit: CampaignExit

var _rewired := false
var _security_cleared := false
var _sync_a_online := false
var _sync_b_online := false


func _ready() -> void:
	configure_palette(Color("ffb13d"), Color("ff4d63"), Color("ff243f"))
	_build_environment()
	_spawn_puzzle()
	add_fall_failure(Vector3(0, -8, 0), "CLOCK FAILURE // TRANSIT ROUTE LOST")
	bind_player_health.call_deferred("CLOCK FAILURE // PLAYER INTEGRITY DEPLETED")
	_report_progress()


func _build_environment() -> void:
	add_box("EntryPlatform", Vector3(0, -0.5, 15), Vector3(11, 1, 8), floor_material)
	add_box("InterceptionFloor", Vector3(0, -0.5, 4), Vector3(15, 1, 10), floor_material)
	add_box("HazardCorridor", Vector3(0, -0.5, -6), Vector3(9, 1, 9), structural_material)
	add_box("ExitPlatform", Vector3(0, -0.5, -16), Vector3(11, 1, 8), floor_material)
	for z in [15.0, 5.0, -5.0, -15.0]:
		add_box("FrameLeft_%s" % z, Vector3(-5.2, 2.5, z), Vector3(0.5, 5, 0.5), structural_material)
		add_box("FrameRight_%s" % z, Vector3(5.2, 2.5, z), Vector3(0.5, 5, 0.5), structural_material)
		add_box("FrameTop_%s" % z, Vector3(0, 5, z), Vector3(11, 0.5, 0.5), structural_material)
	add_box("WarningStripA", Vector3(-3.7, 0.04, -3), Vector3(0.2, 0.08, 6), warning_material, false)
	add_box("WarningStripB", Vector3(3.7, 0.04, -3), Vector3(0.2, 0.08, 6), warning_material, false)
	place_scene(ANCHOR_SCENE, "TransitGrappleAnchor", Vector3(0, 6.5, 9.5))
	place_scene(VECTOR_WALL_SCENE, "ClockVectorWall", Vector3(5.4, 2.5, -8))
	add_label("LevelTitle", Vector3(0, 3.3, 17), "CLOCK FAILURE // SYNCHRONIZATION SECTOR", Color("ffc35a"))
	add_label("HazardLabel", Vector3(0, 3.5, -3), "CYCLIC MACHINERY // REWIRE REQUIRED", Color("ff6373"))
	add_directional(Color("ffd0b0"), 0.68)
	add_omni(Vector3(0, 4, 5), Color("ff9b38"), 2.0, 13.0)
	add_omni(Vector3(0, 4, -8), Color("ff344f"), 2.1, 13.0)


func _spawn_puzzle() -> void:
	security_construct = place_scene(ENEMY_SCENE, "ClockSecurity", Vector3(0, 0.05, 4)) as SecurityConstruct
	security_construct.deactivated.connect(_on_security_cleared)
	rewire_console = place_scene(REWIRE_SCENE, "HazardRewire", Vector3(-5.5, 0.9, 3), Vector3(0, 90, 0)) as RewireConsole
	rewire_console.state_changed.connect(_on_rewired)
	cycle_hazard = place_scene(CYCLE_HAZARD_SCENE, "CycleHazard", Vector3(0, 1.4, -5)) as CycleHazard
	cycle_hazard.player_hit.connect(func() -> void: fail_level("CLOCK FAILURE // CAUGHT IN SYNCHRONIZATION SWEEP"))
	sync_a = place_scene(RELAY_SCENE, "SyncTerminalA", Vector3(-2.5, 1.1, -10)) as ObjectiveRelay
	sync_a.relay_label = "SYNC A"
	sync_a.set_available(false)
	sync_a.restored.connect(_on_sync_a)
	sync_b = place_scene(RELAY_SCENE, "SyncTerminalB", Vector3(2.5, 1.1, -14)) as ObjectiveRelay
	sync_b.relay_label = "SYNC B"
	sync_b.set_available(false)
	sync_b.restored.connect(_on_sync_b)
	campaign_exit = place_scene(EXIT_SCENE, "CampaignExit", Vector3(0, 0.05, -18)) as CampaignExit
	campaign_exit.exit_reached.connect(finish_level)


func _on_security_cleared() -> void:
	_security_cleared = true
	_update_terminal_gate()


func _on_rewired(door_powered: bool) -> void:
	_rewired = door_powered
	if door_powered:
		cycle_hazard.disable_hazard()
	_update_terminal_gate()
	_report_progress()


func _update_terminal_gate() -> void:
	sync_a.set_available(_security_cleared and _rewired)
	_report_progress()


func _on_sync_a() -> void:
	_sync_a_online = true
	sync_b.set_available(true)
	_report_progress()


func _on_sync_b() -> void:
	_sync_b_online = true
	_report_progress()
	mark_puzzle_completed()
	campaign_exit.unlock_exit()
	mark_exit_unlocked()


func _report_progress() -> void:
	var completed := int(_rewired) + int(_sync_a_online) + int(_sync_b_online)
	var message := "DISABLE SECURITY // F REWIRE HAZARD POWER"
	if _rewired and not _security_cleared:
		message = "HAZARD OFFLINE // DISABLE SECURITY CONSTRUCT"
	elif _rewired and _security_cleared and not _sync_a_online:
		message = "F // ACTIVATE SYNC A"
	elif _sync_a_online and not _sync_b_online:
		message = "F // ACTIVATE SYNC B"
	elif _sync_b_online:
		message = "SECTOR SYNCHRONIZED // REACH EXIT"
	report_objective(message, completed, 3)
