class_name KernelPanicLevel
extends CampaignLevelBase

const VICTORY_GATE_PLANE_Z := -34.0
const VICTORY_TRIGGER_POSITION := Vector3(0.0, 0.4, -36.0)

@onready var environment: Node3D = $KernelPanicEnvironment
@onready var markers: Node3D = $KernelPanicEnvironment/InteractionMarkers

var polarity_component: PolarityMass
var polarity_component_b: PolarityMass
var grapple_anchor_a: GrappleAnchor
var grapple_anchor_b: GrappleAnchor
var rewire_console: RewireConsole
var security_construct: SecurityConstruct
var shutdown_terminal: ObjectiveRelay
var campaign_exit: CampaignExit
var core_shield: CSGShape3D

var _polarity_online := false
var _polarity_a_online := false
var _polarity_b_online := false
var _shield_disabled := false
var _security_cleared := false
var _shutdown_complete := false


func _ready() -> void:
	configure_palette(Color("ff3658"), Color("bc59ff"), Color("ff9d32"))
	if not _validate_environment_contract():
		fail_level("KERNEL PANIC PRODUCTION ENVIRONMENT MARKERS ARE INCOMPLETE")
		return
	_spawn_traversal()
	_build_victory_vestibule()
	_spawn_puzzle()
	_apply_polarity_route_state(0, false)
	_apply_polarity_route_state(1, false)
	_apply_core_power_state(false)
	_apply_kernel_state(&"active")
	_apply_shutdown_console_state(&"active")
	_apply_victory_gate_state(false)
	add_fall_failure(Vector3(0, -9, 0), "KERNEL PANIC // CORE ROUTE COLLAPSED")
	bind_player_health.call_deferred("KERNEL PANIC // PLAYER INTEGRITY DEPLETED")
	_report_progress()


func _validate_environment_contract() -> bool:
	for path in [
		"PlayerSpawn", "PolarityTarget_01", "PolarityTarget_01_End", "PolarityTarget_02",
		"PolarityTarget_02_End", "TetherAnchor_01", "TetherAnchor_02", "RewireConsole_Marker",
		"SecurityConstructSpawn", "KernelShutdownConsole_Marker", "FinalVictoryMarker"
	]:
		if markers.get_node_or_null(path) == null:
			return false
	for path in [
		"Environment/GravityDistortion/Platforms/PolarityPlatformA_Target",
		"Environment/GravityDistortion/Platforms/PolarityPlatformB_Target",
		"Environment/CorePowerNetwork/Machinery/CoreShield_Active",
		"Environment/KernelShutdown/VictoryGateStates/VictoryGate_Locked",
		"Environment/GravityDistortion/TetherVisuals/AnchorMount_01",
		"Environment/GravityDistortion/TetherVisuals/AnchorMount_02"
	]:
		if environment.get_node_or_null(path) == null:
			return false
	return true


func _spawn_traversal() -> void:
	# Keep Jefin's authored mounts visible, but let the actual GrappleAnchor own
	# targeting collision at each marker. Otherwise the decorative CSG body
	# intercepts the camera ray and TETHER reports an invalid target.
	var tether_visuals := environment.get_node("Environment/GravityDistortion/TetherVisuals")
	set_csg_state(tether_visuals.get_node("AnchorMount_01") as CSGShape3D, true, false)
	set_csg_state(tether_visuals.get_node("AnchorMount_02") as CSGShape3D, true, false)
	grapple_anchor_a = place_scene_at_marker(
		ANCHOR_SCENE, "KernelAnchorA", markers.get_node("TetherAnchor_01") as Node3D
	) as GrappleAnchor
	grapple_anchor_b = place_scene_at_marker(
		ANCHOR_SCENE, "KernelAnchorB", markers.get_node("TetherAnchor_02") as Node3D
	) as GrappleAnchor
	grapple_anchor_a.preferred_travel_direction = Vector3.FORWARD
	grapple_anchor_b.preferred_travel_direction = Vector3.FORWARD


func _build_victory_vestibule() -> void:
	add_box("VictoryVestibuleFloor", Vector3(0.0, -0.5, -36.0), Vector3(7.0, 1.0, 3.0), floor_material)
	add_box("VictoryVestibuleWestRail", Vector3(-3.5, 1.0, -36.0), Vector3(0.4, 2.0, 3.0), structural_material)
	add_box("VictoryVestibuleEastRail", Vector3(3.5, 1.0, -36.0), Vector3(0.4, 2.0, 3.0), structural_material)


func _spawn_puzzle() -> void:
	var polarity_a_start := markers.get_node("PolarityTarget_01") as Node3D
	var polarity_a_end := markers.get_node("PolarityTarget_01_End") as Node3D
	var polarity_b_start := markers.get_node("PolarityTarget_02") as Node3D
	var polarity_b_end := markers.get_node("PolarityTarget_02_End") as Node3D
	polarity_component = place_scene_at_marker(
		POLARITY_SCENE, "KernelPolarityA", polarity_a_start
	) as PolarityMass
	polarity_component.travel_offset = polarity_a_end.global_position - polarity_a_start.global_position
	polarity_component.state_changed.connect(_on_polarity_changed.bind(0))
	polarity_component_b = place_scene_at_marker(
		POLARITY_SCENE, "KernelPolarityB", polarity_b_start
	) as PolarityMass
	polarity_component_b.travel_offset = polarity_b_end.global_position - polarity_b_start.global_position
	polarity_component_b.state_changed.connect(_on_polarity_changed.bind(1))
	rewire_console = place_scene_at_marker(
		REWIRE_SCENE, "KernelRewire", markers.get_node("RewireConsole_Marker") as Node3D
	) as RewireConsole
	rewire_console.global_position += Vector3.UP * 0.9
	rewire_console.set_available(false)
	rewire_console.state_changed.connect(_on_rewire_changed)
	core_shield = environment.get_node("Environment/CorePowerNetwork/Machinery/CoreShield_Active") as CSGShape3D
	security_construct = place_scene_at_marker(
		ENEMY_SCENE, "KernelSecurity", markers.get_node("SecurityConstructSpawn") as Node3D
	) as SecurityConstruct
	security_construct.deactivated.connect(_on_security_cleared)
	shutdown_terminal = place_scene_at_marker(
		RELAY_SCENE, "ShutdownTerminal", markers.get_node("KernelShutdownConsole_Marker") as Node3D
	) as ObjectiveRelay
	shutdown_terminal.global_position += Vector3.UP * 1.1
	shutdown_terminal.relay_label = "KERNEL SHUTDOWN"
	shutdown_terminal.set_available(false)
	shutdown_terminal.restored.connect(_on_shutdown)
	campaign_exit = place_scene_at_marker(
		EXIT_SCENE, "CampaignExit", markers.get_node("FinalVictoryMarker") as Node3D
	) as CampaignExit
	# The authored marker is on the approach side of the gate. Victory must occur
	# after crossing the real open doorway, never from standing near the console.
	campaign_exit.global_position = VICTORY_TRIGGER_POSITION
	campaign_exit.exit_reached.connect(finish_level)


func _apply_polarity_route_state(index: int, enabled: bool) -> void:
	var platforms := environment.get_node("Environment/GravityDistortion/Platforms")
	var target_name := "PolarityPlatformA_Target" if index == 0 else "PolarityPlatformB_Target"
	set_csg_state(platforms.get_node(target_name) as CSGShape3D, enabled, enabled)


func _apply_core_power_state(disabled: bool) -> void:
	var machinery := environment.get_node("Environment/CorePowerNetwork/Machinery")
	set_csg_state(machinery.get_node("CyanChannel_Active") as CSGShape3D, not disabled)
	set_csg_state(machinery.get_node("CyanChannel_Inactive") as CSGShape3D, disabled)
	set_csg_state(machinery.get_node("MagentaChannel_Active") as CSGShape3D, not disabled)
	set_csg_state(machinery.get_node("MagentaChannel_Inactive") as CSGShape3D, disabled)
	set_csg_state(machinery.get_node("CoreShield_Active") as CSGShape3D, not disabled, not disabled)
	set_csg_state(machinery.get_node("CoreShield_Disabled") as CSGShape3D, disabled)


func _apply_kernel_state(state: StringName) -> void:
	var landmark := environment.get_node("Environment/CorePowerNetwork/KernelLandmark")
	set_csg_state(landmark.get_node("KernelCore_Active") as CSGShape3D, state == &"active")
	set_csg_state(landmark.get_node("KernelCore_Destabilized") as CSGShape3D, state == &"destabilized")
	set_csg_state(landmark.get_node("KernelCore_Disabled") as CSGShape3D, state == &"disabled")


func _apply_shutdown_console_state(state: StringName) -> void:
	var machinery := environment.get_node("Environment/KernelShutdown/ShutdownMachinery")
	set_csg_state(machinery.get_node("ShutdownConsole_Active") as CSGShape3D, state == &"active")
	set_csg_state(machinery.get_node("ShutdownConsole_Destabilized") as CSGShape3D, state == &"destabilized")
	set_csg_state(machinery.get_node("ShutdownConsole_Disabled") as CSGShape3D, state == &"disabled")


func _apply_victory_gate_state(unlocked: bool) -> void:
	var states := environment.get_node("Environment/KernelShutdown/VictoryGateStates")
	set_csg_state(states.get_node("VictoryGate_Locked") as CSGShape3D, not unlocked, not unlocked)
	set_csg_state(states.get_node("VictoryGate_OpenLeft") as CSGShape3D, unlocked)
	set_csg_state(states.get_node("VictoryGate_OpenRight") as CSGShape3D, unlocked)
	set_csg_state(states.get_node("VictoryGate_OpenGlow") as CSGShape3D, unlocked)


func _on_polarity_changed(inverted: bool, index: int) -> void:
	if index == 0:
		_polarity_a_online = inverted
	else:
		_polarity_b_online = inverted
	_apply_polarity_route_state(index, inverted)
	_polarity_online = _polarity_a_online and _polarity_b_online
	rewire_console.set_available(_polarity_online)
	_update_shutdown_gate()
	_report_progress()


func _on_rewire_changed(door_powered: bool) -> void:
	_shield_disabled = door_powered
	_apply_core_power_state(door_powered)
	if door_powered:
		_apply_kernel_state(&"destabilized")
	_update_shutdown_gate()
	_report_progress()


func _on_security_cleared() -> void:
	_security_cleared = true
	_update_shutdown_gate()
	_report_progress()


func _update_shutdown_gate() -> void:
	var available := _polarity_online and _shield_disabled and _security_cleared
	shutdown_terminal.set_available(available)
	if available and not _shutdown_complete:
		_apply_shutdown_console_state(&"destabilized")


func _on_shutdown() -> void:
	_shutdown_complete = true
	_apply_kernel_state(&"disabled")
	_apply_shutdown_console_state(&"disabled")
	_apply_victory_gate_state(true)
	_report_progress()
	mark_puzzle_completed()
	campaign_exit.unlock_exit()
	mark_exit_unlocked()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"shutdown", -2.0)


func _report_progress() -> void:
	var completed := (
		int(_polarity_a_online) + int(_polarity_b_online) + int(_shield_disabled)
		+ int(_security_cleared) + int(_shutdown_complete)
	)
	var message := "Q // ALIGN BOTH POLARITY PLATFORMS"
	if _polarity_a_online != _polarity_b_online:
		message = "Q // ALIGN SECOND POLARITY PLATFORM"
	elif _polarity_online and not _shield_disabled:
		message = "TETHER TO CORE NETWORK // F REWIRE CORE SHIELD"
	elif _shield_disabled and not _security_cleared:
		message = "DISABLE KERNEL SECURITY CONSTRUCT"
	elif _polarity_online and _shield_disabled and _security_cleared and not _shutdown_complete:
		message = "F // EXECUTE KERNEL SHUTDOWN"
	elif _shutdown_complete:
		message = "KERNEL OFFLINE // CROSS OPEN VICTORY GATE"
	report_objective(message, completed, 5)
