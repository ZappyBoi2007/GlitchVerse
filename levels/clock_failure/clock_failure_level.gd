class_name ClockFailureLevel
extends CampaignLevelBase

const CYCLE_HAZARD_SCENE := preload("res://interactive/cycle_hazard.tscn")

const EXIT_DOOR_PLANE_Z := -36.7
const EXIT_TRIGGER_POSITION := Vector3(0.0, 0.4, -38.4)

@onready var environment: Node3D = $ClockFailureEnvironment
@onready var markers: Node3D = $ClockFailureEnvironment/InteractionMarkers

var rewire_console: RewireConsole
var cycle_hazard: CycleHazard
var cycle_hazards: Array[CycleHazard] = []
var grapple_anchor_a: GrappleAnchor
var grapple_anchor_b: GrappleAnchor
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
	if not _validate_environment_contract():
		fail_level("CLOCK FAILURE PRODUCTION ENVIRONMENT MARKERS ARE INCOMPLETE")
		return
	_spawn_traversal()
	_build_exit_vestibule()
	_spawn_puzzle()
	_apply_power_route_state(false)
	_apply_exit_state(false)
	add_fall_failure(Vector3(0, -8, 0), "CLOCK FAILURE // TRANSIT ROUTE LOST")
	bind_player_health.call_deferred("CLOCK FAILURE // PLAYER INTEGRITY DEPLETED")
	_report_progress()


func _validate_environment_contract() -> bool:
	for path in [
		"PlayerSpawn", "TetherAnchor_01", "TetherAnchor_02", "TimingHazard_Marker_01",
		"TimingHazard_Marker_02", "PowerConsole_Marker", "SecurityConstructSpawn",
		"SyncTerminalA_Marker", "SyncTerminalB_Marker", "ExitMarker"
	]:
		if markers.get_node_or_null(path) == null:
			return false
	for path in [
		"Environment/PowerRoutingRoom/StateVisuals/TimingHazard_Active",
		"Environment/PowerRoutingRoom/StateVisuals/BlockedRoute_Locked",
		"Environment/ExitChamber/ExitDoorStates/Exit_Locked",
		"Environment/TimingChamber/TetherVisuals/AnchorMount_01",
		"Environment/TimingChamber/TetherVisuals/AnchorMount_02"
	]:
		if environment.get_node_or_null(path) == null:
			return false
	return true


func _spawn_traversal() -> void:
	# The production anchor mounts are visual housings. Their CSG collision sits
	# directly in front of the reusable grapple targets and otherwise wins the
	# camera raycast, making a correctly aimed TETHER attempt invalid.
	var tether_visuals := environment.get_node("Environment/TimingChamber/TetherVisuals")
	set_csg_state(tether_visuals.get_node("AnchorMount_01") as CSGShape3D, true, false)
	set_csg_state(tether_visuals.get_node("AnchorMount_02") as CSGShape3D, true, false)
	grapple_anchor_a = place_scene_at_marker(
		ANCHOR_SCENE, "TimingAnchorA", markers.get_node("TetherAnchor_01") as Node3D
	) as GrappleAnchor
	grapple_anchor_b = place_scene_at_marker(
		ANCHOR_SCENE, "TimingAnchorB", markers.get_node("TetherAnchor_02") as Node3D
	) as GrappleAnchor
	grapple_anchor_a.preferred_travel_direction = Vector3.FORWARD
	grapple_anchor_b.preferred_travel_direction = Vector3.FORWARD


func _build_exit_vestibule() -> void:
	add_box("ExitVestibuleFloor", Vector3(0.0, -0.5, -38.3), Vector3(7.0, 1.0, 2.6), floor_material)
	add_box("ExitVestibuleWestRail", Vector3(-3.5, 1.0, -38.3), Vector3(0.4, 2.0, 2.6), structural_material)
	add_box("ExitVestibuleEastRail", Vector3(3.5, 1.0, -38.3), Vector3(0.4, 2.0, 2.6), structural_material)


func _spawn_puzzle() -> void:
	security_construct = place_scene_at_marker(
		ENEMY_SCENE, "ClockSecurity", markers.get_node("SecurityConstructSpawn") as Node3D
	) as SecurityConstruct
	security_construct.deactivated.connect(_on_security_cleared)
	rewire_console = place_scene_at_marker(
		REWIRE_SCENE, "HazardRewire", markers.get_node("PowerConsole_Marker") as Node3D
	) as RewireConsole
	rewire_console.global_position += Vector3.UP * 0.9
	rewire_console.state_changed.connect(_on_rewired)
	for marker_name in ["TimingHazard_Marker_01", "TimingHazard_Marker_02"]:
		var hazard := place_scene_at_marker(
			CYCLE_HAZARD_SCENE, "CycleHazard_%s" % marker_name.right(2), markers.get_node(marker_name) as Node3D
		) as CycleHazard
		hazard.travel_axis = Vector3.RIGHT if cycle_hazards.is_empty() else Vector3.LEFT
		hazard.travel_distance = 4.0
		hazard.player_hit.connect(func() -> void: fail_level("CLOCK FAILURE // CAUGHT IN SYNCHRONIZATION SWEEP"))
		cycle_hazards.append(hazard)
	cycle_hazard = cycle_hazards[0]
	sync_a = place_scene_at_marker(
		RELAY_SCENE, "SyncTerminalA", markers.get_node("SyncTerminalA_Marker") as Node3D
	) as ObjectiveRelay
	sync_a.global_position += Vector3.UP * 1.1
	sync_a.relay_label = "SYNC A"
	sync_a.set_available(false)
	sync_a.restored.connect(_on_sync_a)
	sync_b = place_scene_at_marker(
		RELAY_SCENE, "SyncTerminalB", markers.get_node("SyncTerminalB_Marker") as Node3D
	) as ObjectiveRelay
	sync_b.global_position += Vector3.UP * 1.1
	sync_b.relay_label = "SYNC B"
	sync_b.set_available(false)
	sync_b.restored.connect(_on_sync_b)
	campaign_exit = place_scene_at_marker(
		EXIT_SCENE, "CampaignExit", markers.get_node("ExitMarker") as Node3D
	) as CampaignExit
	# Jefin's marker identifies the gate approach. Completion belongs beyond the
	# actual locked CSG door so proximity cannot finish the level early.
	campaign_exit.global_position = EXIT_TRIGGER_POSITION
	campaign_exit.exit_reached.connect(finish_level)


func _apply_power_route_state(rerouted: bool) -> void:
	var states := environment.get_node("Environment/PowerRoutingRoom/StateVisuals")
	set_csg_state(states.get_node("ChannelA_Active") as CSGShape3D, not rerouted)
	set_csg_state(states.get_node("ChannelA_Inactive") as CSGShape3D, rerouted)
	set_csg_state(states.get_node("ChannelB_Active") as CSGShape3D, rerouted)
	set_csg_state(states.get_node("ChannelB_Inactive") as CSGShape3D, not rerouted)
	set_csg_state(states.get_node("TimingHazard_Active") as CSGShape3D, not rerouted, not rerouted)
	set_csg_state(states.get_node("TimingHazard_Disabled") as CSGShape3D, rerouted)
	set_csg_state(states.get_node("BlockedRoute_Locked") as CSGShape3D, not rerouted, not rerouted)
	set_csg_state(states.get_node("BlockedRoute_Open") as CSGShape3D, rerouted)


func _apply_exit_state(unlocked: bool) -> void:
	var states := environment.get_node("Environment/ExitChamber/ExitDoorStates")
	set_csg_state(states.get_node("Exit_Locked") as CSGShape3D, not unlocked, not unlocked)
	set_csg_state(states.get_node("Exit_OpenLeft") as CSGShape3D, unlocked)
	set_csg_state(states.get_node("Exit_OpenRight") as CSGShape3D, unlocked)
	set_csg_state(states.get_node("Exit_OpenGlow") as CSGShape3D, unlocked)


func _on_security_cleared() -> void:
	_security_cleared = true
	_update_terminal_gate()


func _on_rewired(door_powered: bool) -> void:
	_rewired = door_powered
	if door_powered:
		for hazard in cycle_hazards:
			hazard.disable_hazard()
	_apply_power_route_state(door_powered)
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
	_apply_exit_state(true)
	campaign_exit.unlock_exit()
	mark_exit_unlocked()


func _report_progress() -> void:
	var completed := int(_rewired) + int(_security_cleared) + int(_sync_a_online) + int(_sync_b_online)
	var message := "TETHER THROUGH TIMING CHAMBER // F REWIRE HAZARD POWER"
	if _rewired and not _security_cleared:
		message = "HAZARD OFFLINE // DISABLE SECURITY CONSTRUCT"
	elif _rewired and _security_cleared and not _sync_a_online:
		message = "F // ACTIVATE SYNC A"
	elif _sync_a_online and not _sync_b_online:
		message = "F // ACTIVATE SYNC B"
	elif _sync_b_online:
		message = "SECTOR SYNCHRONIZED // REACH EXIT"
	report_objective(message, completed, 4)
