class_name AccessDeniedSystemBreachLevel
extends GameplayLevel

const ANCHOR_SCENE := preload("res://interactive/grapple_anchor.tscn")
const HANDLE_SCENE := preload("res://interactive/tether_pull_handle.tscn")
const ENEMY_SCENE := preload("res://enemies/security_construct.tscn")
const RELAY_SCENE := preload("res://interactive/objective_relay.tscn")
const REWIRE_SCENE := preload("res://interactive/rewire_console.tscn")
const EXIT_SCENE := preload("res://interactive/campaign_exit.tscn")
const FALL_SCENE := preload("res://interactive/fall_hazard.tscn")

const DOOR_PLANE_X := 33.0
const EXIT_TRIGGER_POSITION := Vector3(35.8, 0.4, 30.0)

@onready var environment: Node3D = $Environment
@onready var markers: Node3D = $Environment/InteractionMarkers

var bridge: SystemBreachBridge
var pull_handle: TetherPullHandle
var enemy: SecurityConstruct
var relay_a: ObjectiveRelay
var relay_b: ObjectiveRelay
var rewire_console: RewireConsole
var campaign_exit: CampaignExit

var _relay_a_restored := false
var _relay_b_restored := false
var _bridge_deployed := false
var _rewired := false


func _ready() -> void:
	if not _validate_environment_contract():
		fail_level("SYSTEM BREACH ENVIRONMENT MARKERS ARE INCOMPLETE")
		return
	_apply_production_art_safety()
	_repair_power_approach_alignment()
	_add_route_readability()
	_build_exit_vestibule()
	_spawn_gameplay()
	_apply_rewire_state(false)
	_bind_player_health.call_deferred()
	_report_progress()


func _apply_production_art_safety() -> void:
	# The imported raised-floor model is roughly two metres tall at the authored
	# 1.3 scale. Both lobby inlays overlap the arrival volume, and the left one
	# contains the spawned first-person camera. Keep the production art pass but
	# suppress only these collision-free decorative obstructions at runtime.
	for path in [
		"Environment/ArrivalChamber/ProductionArtPass/LobbyFloorInlayA",
		"Environment/ArrivalChamber/ProductionArtPass/LobbyFloorInlayB",
	]:
		var inlay := environment.get_node_or_null(path) as Node3D
		if inlay != null:
			inlay.visible = false


func _validate_environment_contract() -> bool:
	for path in [
		"PlayerSpawn", "GrappleAnchor_01", "GrappleAnchor_02", "TetherPullHandle_01",
		"BridgeExtendedTarget", "EnemySpawn_01", "RelayA_Marker", "PowerConsole_Marker",
		"RelayB_Marker", "ExitMarker", "FallZoneMarker"
	]:
		if markers.get_node_or_null(path) == null:
			return false
	return true


func _spawn_gameplay() -> void:
	var primary_anchor := _spawn_at_marker(ANCHOR_SCENE, "GrappleAnchor_01", "GrappleAnchor_01_Runtime") as GrappleAnchor
	primary_anchor.maximum_initial_rope_length = 7.0
	primary_anchor.automatic_reel_in_speed = 4.5
	primary_anchor.attachment_assist_multiplier = 1.2
	primary_anchor.preferred_travel_direction = Vector3.LEFT
	var secondary_anchor := _spawn_at_marker(ANCHOR_SCENE, "GrappleAnchor_02", "GrappleAnchor_02_Runtime") as GrappleAnchor
	secondary_anchor.maximum_initial_rope_length = 5.0
	secondary_anchor.automatic_reel_in_speed = 3.5
	secondary_anchor.attachment_assist_multiplier = 1.05
	secondary_anchor.preferred_travel_direction = Vector3.LEFT

	var bridge_shape := environment.get_node("Environment/BrokenCrossing/Platforms/RetractableBridgeSection") as CSGShape3D
	bridge = SystemBreachBridge.new()
	bridge.name = "SystemBreachBridge"
	add_child(bridge)
	bridge.configure(bridge_shape, markers.get_node("BridgeExtendedTarget") as Node3D)
	bridge.deployment_completed.connect(_on_bridge_deployed)

	pull_handle = _spawn_at_marker(HANDLE_SCENE, "TetherPullHandle_01", "TetherPullHandle_01_Runtime") as TetherPullHandle
	pull_handle.pulled.connect(bridge.activate)

	enemy = _spawn_at_marker(ENEMY_SCENE, "EnemySpawn_01", "SecurityConstruct_01") as SecurityConstruct
	enemy.deactivated.connect(_on_enemy_deactivated)

	relay_a = _spawn_at_marker(RELAY_SCENE, "RelayA_Marker", "RelayA") as ObjectiveRelay
	relay_a.position.y += 1.1
	relay_a.relay_label = "RELAY A"
	relay_a.set_available(false)
	relay_a.restored.connect(_on_relay_a_restored)

	rewire_console = _spawn_at_marker(REWIRE_SCENE, "PowerConsole_Marker", "PowerConsole") as RewireConsole
	rewire_console.position.y += 0.9
	rewire_console.set_available(false)
	rewire_console.state_changed.connect(_on_rewire_changed)

	relay_b = _spawn_at_marker(RELAY_SCENE, "RelayB_Marker", "RelayB") as ObjectiveRelay
	relay_b.position.y += 1.1
	relay_b.relay_label = "RELAY B"
	relay_b.set_available(false)
	relay_b.restored.connect(_on_relay_b_restored)

	campaign_exit = _spawn_at_marker(EXIT_SCENE, "ExitMarker", "CampaignExit") as CampaignExit
	# Jefin's marker is on the approach side of the door. The runtime exit lives
	# beyond the door so proximity to the exterior wall cannot complete the level.
	campaign_exit.global_position = EXIT_TRIGGER_POSITION
	campaign_exit.exit_reached.connect(finish_level)

	var fall := _spawn_at_marker(FALL_SCENE, "FallZoneMarker", "SystemBreachFallZone") as FallHazard
	fall.failure_reason = "SYSTEM BREACH // PLAYER LOST IN BROKEN CROSSING"
	fall.failure_requested.connect(fail_level)


func _spawn_at_marker(scene: PackedScene, marker_name: String, node_name: String) -> Node3D:
	var instance := scene.instantiate() as Node3D
	instance.name = node_name
	add_child(instance)
	instance.global_transform = (markers.get_node(marker_name) as Node3D).global_transform
	return instance


func _build_exit_vestibule() -> void:
	# The environment intentionally remains untouched. These wrapper-owned pieces
	# close the two open seams beside the authored door and provide a safe floor
	# behind it for the correctly positioned completion trigger.
	var geometry := Node3D.new()
	geometry.name = "ExitSafetyGeometry"
	add_child(geometry)
	var structure := _runtime_material(Color("17212b"), 0.78, 0.45)
	var clearance := _runtime_emissive(Color("55ff9a"), 1.2)
	_add_runtime_box(geometry, "NorthDoorSeal", Vector3(DOOR_PLANE_X, 2.75, 22.75), Vector3(0.8, 5.5, 5.5), structure)
	_add_runtime_box(geometry, "SouthDoorSeal", Vector3(DOOR_PLANE_X, 2.75, 37.25), Vector3(0.8, 5.5, 5.5), structure)
	_add_runtime_box(geometry, "VestibuleFloor", Vector3(35.4, 0.0, 30.0), Vector3(4.8, 0.5, 9.0), structure)
	_add_runtime_box(geometry, "VestibuleNorthWall", Vector3(35.4, 2.75, 25.5), Vector3(4.8, 5.5, 0.7), structure)
	_add_runtime_box(geometry, "VestibuleSouthWall", Vector3(35.4, 2.75, 34.5), Vector3(4.8, 5.5, 0.7), structure)
	_add_runtime_box(geometry, "VestibuleEndWall", Vector3(37.8, 2.75, 30.0), Vector3(0.7, 5.5, 9.0), structure)
	_add_runtime_box(geometry, "ExitClearanceStrip", Vector3(35.4, 0.31, 30.0), Vector3(3.8, 0.08, 0.32), clearance, false)


func _repair_power_approach_alignment() -> void:
	# Jefin's source scene remains untouched. The authored diagonal floor enters
	# through the combat-room wall, while its rails use unrotated world-X offsets.
	# Correct those transforms in the integration wrapper so visuals and collision
	# form one readable corridor between the two authored wall openings.
	var approach := environment.get_node("Environment/SecurityInterception/PowerApproach")
	var floor := approach.get_node("ApproachFloor") as CSGBox3D
	var left_rail := approach.get_node("ApproachLeftRail") as CSGBox3D
	var right_rail := approach.get_node("ApproachRightRail") as CSGBox3D
	floor.position = Vector3(-37.7, 0.0, -7.2)
	floor.rotation_degrees = Vector3(0.0, -48.0, 0.0)
	var local_right := Basis.from_euler(Vector3(0.0, deg_to_rad(-48.0), 0.0)) * Vector3.RIGHT
	var rail_offset := local_right * 2.5
	left_rail.position = floor.position - rail_offset + Vector3(0.0, 0.75, 0.0)
	right_rail.position = floor.position + rail_offset + Vector3(0.0, 0.75, 0.0)
	for rail in [left_rail, right_rail]:
		rail.rotation_degrees = floor.rotation_degrees
		rail.size = Vector3(0.28, 1.0, 18.0)
		rail.use_collision = true

	var props := environment.get_node("Environment/SecurityInterception/SecurityProps")
	var threshold_left := props.get_node("OnwardThresholdLeft") as CSGBox3D
	var threshold_right := props.get_node("OnwardThresholdRight") as CSGBox3D
	threshold_left.position = Vector3(-45.5, 0.35, -1.8)
	threshold_right.position = Vector3(-43.8, 0.35, -2.9)
	threshold_left.rotation_degrees = Vector3(0.0, -48.0, 0.0)
	threshold_right.rotation_degrees = Vector3(0.0, -48.0, 0.0)
	threshold_left.size = Vector3(1.1, 0.08, 0.24)
	threshold_right.size = Vector3(1.1, 0.08, 0.24)
	var route_sign := props.get_node("PowerRouteSign") as Label3D
	route_sign.position = Vector3(-46.2, 3.2, -1.75)
	route_sign.text = "POWER DIVERSION // FOLLOW AMBER"


func _add_route_readability() -> void:
	var guides := Node3D.new()
	guides.name = "IntegrationRouteGuides"
	add_child(guides)
	var amber := _runtime_emissive(Color("ff9b2f"), 1.05)
	var cyan := _runtime_emissive(Color("45dfff"), 1.0)
	for index in range(4):
		var guide := _add_runtime_box(
			guides,
			"PowerApproachGuide_%02d" % (index + 1),
			Vector3(-43.7 + index * 3.35, 0.29, -2.2 - index * 3.0),
			Vector3(1.6, 0.06, 0.22),
			amber,
			false
		)
		guide.rotation_degrees = Vector3(0.0, -48.0, 0.0)
	_add_runtime_box(guides, "RelayAGuide", Vector3(-54.5, 0.29, 2.0), Vector3(4.2, 0.06, 0.24), cyan, false)

	var lighting := environment.get_node("Lighting")
	_add_fill_light(lighting, "SecurityFill", Vector3(-50.0, 3.0, 3.0), Color("77cfff"), 0.8, 11.0)
	_add_fill_light(lighting, "PowerApproachFill", Vector3(-38.0, 3.0, -7.0), Color("ffb05a"), 1.15, 13.0)


func _add_fill_light(parent: Node, node_name: String, position_value: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = position_value
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	parent.add_child(light)


func _add_runtime_box(
	parent: Node3D,
	node_name: String,
	position_value: Vector3,
	size: Vector3,
	material: Material,
	collision := true
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position_value
	parent.add_child(body)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)
	if collision:
		var collision_shape := CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = size
		collision_shape.shape = shape
		body.add_child(collision_shape)
	return body


func _runtime_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _runtime_emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := _runtime_material(color.darkened(0.68), 0.3, 0.5)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _on_bridge_deployed() -> void:
	_bridge_deployed = true
	_report_progress()


func _on_enemy_deactivated() -> void:
	relay_a.set_available(true)
	_report_progress()


func _on_relay_a_restored() -> void:
	_relay_a_restored = true
	rewire_console.set_available(true)
	_report_progress()


func _on_rewire_changed(door_powered: bool) -> void:
	_rewired = door_powered
	_apply_rewire_state(door_powered)
	relay_b.set_available(door_powered)
	_report_progress()


func _on_relay_b_restored() -> void:
	_relay_b_restored = true
	_report_progress()
	if _relay_a_restored and _relay_b_restored:
		_open_containment_exit()


func _apply_rewire_state(door_powered: bool) -> void:
	var machinery := environment.get_node("Environment/PowerDiversion/Machinery")
	_set_visible(machinery, "ChannelA_ActiveIndicator", not door_powered)
	_set_visible(machinery, "ChannelA_ActiveBranchIndicator", not door_powered)
	_set_visible(machinery, "ChannelB_ActiveIndicator", door_powered)
	_set_visible(machinery, "ChannelB_ActiveBranchIndicator", door_powered)
	_set_csg_state(machinery, "SecurityField_Energized", not door_powered, not door_powered)
	_set_visible(machinery, "SecurityField_Disabled", door_powered)
	_set_csg_state(machinery, "PoweredDoor_Locked", not door_powered, not door_powered)
	_set_visible(machinery, "PoweredDoor_LockedIndicator", not door_powered)
	_set_visible(machinery, "PoweredDoor_Open", door_powered)


func _open_containment_exit() -> void:
	var door := environment.get_node("Environment/FinalContainmentExit/ContainmentDoor")
	_set_csg_state(door, "LockedDoorPanel", false, false)
	_set_visible(door, "LockedDoorSeam", false)
	_set_visible(door, "LockingBolt01", false)
	_set_visible(door, "LockingBolt02", false)
	_set_visible(door, "OpenDoorPocket", true)
	_set_visible(door, "OpenDoorLeftParked", true)
	_set_visible(door, "OpenDoorRightParked", true)
	_set_visible(door, "OpenDoorClearanceGlow", true)
	var exit_label := door.get_node_or_null("ContainmentExitLabel") as Label3D
	if exit_label != null:
		exit_label.text = "CONTAINMENT EXIT // OPEN"
		exit_label.modulate = Color("55ff9a")
	mark_puzzle_completed()
	campaign_exit.unlock_exit()
	mark_exit_unlocked()


func _set_visible(parent: Node, child_name: String, value: bool) -> void:
	var node := parent.get_node_or_null(child_name) as Node3D
	if node != null:
		node.visible = value


func _set_csg_state(parent: Node, child_name: String, visible_value: bool, collision_value: bool) -> void:
	var shape := parent.get_node_or_null(child_name) as CSGShape3D
	if shape != null:
		shape.visible = visible_value
		shape.use_collision = collision_value


func _bind_player_health() -> void:
	var health := get_tree().get_first_node_in_group("player_health") as PlayerHealth
	if health != null:
		health.player_defeated.connect(func() -> void: fail_level("SYSTEM BREACH // PLAYER INTEGRITY DEPLETED"))


func _report_progress() -> void:
	var completed := int(_relay_a_restored) + int(_relay_b_restored)
	var message := "DEPLOY CROSSING BRIDGE WITH TETHER"
	if _bridge_deployed and not enemy.is_deactivated():
		message = "DISABLE SECURITY CONSTRUCT"
	elif enemy.is_deactivated() and not _relay_a_restored:
		message = "F // RESTORE RELAY A // WEST CYAN BEACON"
	elif _relay_a_restored and not _rewired:
		message = "F // REWIRE POWER TO DOOR ROUTE"
	elif _rewired and not _relay_b_restored:
		message = "F // RESTORE RELAY B"
	elif _relay_a_restored and _relay_b_restored:
		message = "LOCKDOWN CLEARED // REACH CONTAINMENT EXIT"
	report_objective(message, completed, 2)
