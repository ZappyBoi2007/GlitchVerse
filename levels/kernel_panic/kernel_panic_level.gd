class_name KernelPanicLevel
extends CampaignLevelBase

var polarity_component: PolarityMass
var rewire_console: RewireConsole
var security_construct: SecurityConstruct
var shutdown_terminal: ObjectiveRelay
var campaign_exit: CampaignExit
var core_shield: StaticBody3D

var _polarity_online := false
var _shield_disabled := false
var _security_cleared := false
var _shutdown_complete := false


func _ready() -> void:
	configure_palette(Color("ff3658"), Color("bc59ff"), Color("ff9d32"))
	_build_environment()
	_spawn_puzzle()
	add_fall_failure(Vector3(0, -9, 0), "KERNEL PANIC // CORE ROUTE COLLAPSED")
	bind_player_health.call_deferred("KERNEL PANIC // PLAYER INTEGRITY DEPLETED")
	_report_progress()


func _build_environment() -> void:
	add_box("EntryDeck", Vector3(0, -0.5, 15), Vector3(12, 1, 8), floor_material)
	add_box("KernelDeck", Vector3(0, -0.5, 2), Vector3(22, 1, 14), floor_material)
	add_box("LeftBypass", Vector3(-8, 2.5, -7), Vector3(4, 0.6, 12), structural_material)
	add_box("RightBypass", Vector3(8, 4.5, -7), Vector3(4, 0.6, 12), structural_material)
	add_box("ShutdownDeck", Vector3(0, -0.5, -15), Vector3(12, 1, 8), floor_material)
	add_core("CorruptedKernel", Vector3(0, 6, 0), 3.0, 12.0, primary_material)
	add_core("KernelRingA", Vector3(0, 2.0, 0), 4.5, 0.35, secondary_material)
	add_core("KernelRingB", Vector3(0, 9.5, 0), 4.5, 0.35, warning_material)
	for x in [-10.5, 10.5]:
		add_box("KernelSpine_%s" % x, Vector3(x, 5, 0), Vector3(0.8, 10, 0.8), structural_material)
	place_scene(ANCHOR_SCENE, "KernelAnchorEntry", Vector3(-3, 8, 8))
	place_scene(ANCHOR_SCENE, "KernelAnchorExit", Vector3(3, 10, -8))
	place_scene(VECTOR_WALL_SCENE, "KernelVectorWall", Vector3(-10.5, 4, -6), Vector3(0, 180, 0))
	add_box("EmergencyStrip", Vector3(0, 0.04, 8), Vector3(4, 0.08, 0.25), primary_material, false)
	add_box("ShutdownStrip", Vector3(0, 0.04, -11), Vector3(4, 0.08, 0.25), warning_material, false)
	add_label("LevelTitle", Vector3(0, 3.3, 17), "KERNEL PANIC // CORE SHUTDOWN", Color("ff6378"))
	add_label("KernelWarning", Vector3(0, 7, -2), "SAFEGUARDS ACTIVE", Color("ff9a40"))
	add_directional(Color("ffd0d4"), 0.62)
	add_omni(Vector3(0, 7, 0), Color("ff264c"), 3.2, 21.0)
	add_omni(Vector3(0, 4, -14), Color("b849ff"), 2.1, 12.0)


func _spawn_puzzle() -> void:
	polarity_component = place_scene(POLARITY_SCENE, "KernelPowerComponent", Vector3(-6, 0.9, 4)) as PolarityMass
	polarity_component.travel_offset = Vector3(0, 5.0, 0)
	polarity_component.state_changed.connect(_on_polarity_changed)
	rewire_console = place_scene(REWIRE_SCENE, "KernelRewire", Vector3(6, 0.9, 1), Vector3(0, -90, 0)) as RewireConsole
	rewire_console.set_available(false)
	rewire_console.state_changed.connect(_on_rewire_changed)
	core_shield = add_box("CoreShield", Vector3(0, 2.0, -7.5), Vector3(8, 4, 0.35), secondary_material)
	security_construct = place_scene(ENEMY_SCENE, "KernelSecurity", Vector3(0, 0.05, -4)) as SecurityConstruct
	security_construct.deactivated.connect(_on_security_cleared)
	shutdown_terminal = place_scene(RELAY_SCENE, "ShutdownTerminal", Vector3(0, 1.1, -14)) as ObjectiveRelay
	shutdown_terminal.relay_label = "KERNEL SHUTDOWN"
	shutdown_terminal.set_available(false)
	shutdown_terminal.restored.connect(_on_shutdown)
	campaign_exit = place_scene(EXIT_SCENE, "CampaignExit", Vector3(0, 0.05, -18)) as CampaignExit
	campaign_exit.exit_reached.connect(finish_level)


func _on_polarity_changed(inverted: bool) -> void:
	_polarity_online = inverted
	rewire_console.set_available(inverted)
	_update_shutdown_gate()
	_report_progress()


func _on_rewire_changed(door_powered: bool) -> void:
	_shield_disabled = door_powered
	if door_powered:
		core_shield.visible = false
		var collision := core_shield.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision != null:
			collision.set_deferred("disabled", true)
	_update_shutdown_gate()
	_report_progress()


func _on_security_cleared() -> void:
	_security_cleared = true
	_update_shutdown_gate()
	_report_progress()


func _update_shutdown_gate() -> void:
	shutdown_terminal.set_available(_polarity_online and _shield_disabled and _security_cleared)


func _on_shutdown() -> void:
	_shutdown_complete = true
	_report_progress()
	mark_puzzle_completed()
	campaign_exit.unlock_exit()
	mark_exit_unlocked()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"shutdown", -2.0)


func _report_progress() -> void:
	var completed := int(_polarity_online) + int(_shield_disabled) + int(_security_cleared) + int(_shutdown_complete)
	var message := "Q // RAISE KERNEL POWER COMPONENT"
	if _polarity_online and not _shield_disabled:
		message = "F // REWIRE CORE SHIELD POWER"
	elif _shield_disabled and not _security_cleared:
		message = "DISABLE KERNEL SECURITY CONSTRUCT"
	elif _polarity_online and _shield_disabled and _security_cleared and not _shutdown_complete:
		message = "F // EXECUTE KERNEL SHUTDOWN"
	elif _shutdown_complete:
		message = "KERNEL OFFLINE // ENTER EXTRACTION GATE"
	report_objective(message, completed, 4)
