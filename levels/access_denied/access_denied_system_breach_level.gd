class_name AccessDeniedSystemBreachLevel
extends GameplayLevel

const ANCHOR_SCENE := preload("res://interactive/grapple_anchor.tscn")
const HANDLE_SCENE := preload("res://interactive/tether_pull_handle.tscn")
const ENEMY_SCENE := preload("res://enemies/security_construct.tscn")
const RELAY_SCENE := preload("res://interactive/objective_relay.tscn")
const REWIRE_SCENE := preload("res://interactive/rewire_console.tscn")
const EXIT_SCENE := preload("res://interactive/campaign_exit.tscn")
const FALL_SCENE := preload("res://interactive/fall_hazard.tscn")

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
	_spawn_gameplay()
	_apply_rewire_state(false)
	_bind_player_health.call_deferred()
	_report_progress()


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
	_spawn_at_marker(ANCHOR_SCENE, "GrappleAnchor_01", "GrappleAnchor_01_Runtime")
	_spawn_at_marker(ANCHOR_SCENE, "GrappleAnchor_02", "GrappleAnchor_02_Runtime")

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
		message = "F // RESTORE RELAY A"
	elif _relay_a_restored and not _rewired:
		message = "F // REWIRE POWER TO DOOR ROUTE"
	elif _rewired and not _relay_b_restored:
		message = "F // RESTORE RELAY B"
	elif _relay_a_restored and _relay_b_restored:
		message = "LOCKDOWN CLEARED // REACH CONTAINMENT EXIT"
	report_objective(message, completed, 2)
