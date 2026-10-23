class_name BreachLabLevel
extends GameplayLevel

## Isolated action/traversal vertical slice. Campaign scenes do not depend on it.

@onready var bridge: RetractableBridge = $RetractableBridge
@onready var pull_handle: TetherPullHandle = $TetherPullHandle
@onready var security_construct: SecurityConstruct = $SecurityConstruct
@onready var puzzle_exit: PuzzleExit = $PuzzleExit
@onready var fall_hazard: FallHazard = $FallHazard

var floor_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var cyan_material: StandardMaterial3D
var amber_material: StandardMaterial3D
var _bridge_ready := false
var _construct_defeated := false


func _ready() -> void:
	_create_materials()
	_build_geometry()
	_build_lighting()
	bridge.deployment_completed.connect(_on_bridge_deployed)
	security_construct.deactivated.connect(_on_construct_deactivated)
	puzzle_exit.exit_reached.connect(finish_level)
	fall_hazard.failure_requested.connect(fail_level)
	call_deferred("_bind_player_health")
	call_deferred("_report_progress")


func _create_materials() -> void:
	floor_material = _make_material(Color("252f3a"), 0.78, 0.38)
	wall_material = _make_material(Color("101720"), 0.62, 0.58)
	cyan_material = _make_emissive(Color("45dce7"), 1.45)
	amber_material = _make_emissive(Color("f6a83d"), 1.35)


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _make_emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_material(color.darkened(0.68), 0.32, 0.42)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _add_box(label: String, position_value: Vector3, size: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = position_value
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body


func _add_label(label_name: String, position_value: Vector3, text_value: String, color: Color) -> void:
	var label := Label3D.new()
	label.name = label_name
	label.position = position_value
	label.text = text_value
	label.font_size = 26
	label.outline_size = 8
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _build_geometry() -> void:
	_add_box("StartPlatform", Vector3(0, -0.5, 15), Vector3(12, 1, 8), floor_material)
	_add_box("CombatPlatform", Vector3(0, -0.5, -1), Vector3(18, 1, 10), floor_material)
	_add_box("ExitPlatform", Vector3(0, -0.5, -17), Vector3(12, 1, 8), floor_material)

	# Structural silhouettes and side rails leave deliberate openings only at the route.
	_add_box("StartBackWall", Vector3(0, 2.5, 19.2), Vector3(12, 5, 0.45), wall_material)
	_add_box("StartRailLeft", Vector3(-5.75, 0.75, 13.8), Vector3(0.25, 1.5, 9.5), wall_material)
	_add_box("StartRailRight", Vector3(5.75, 0.75, 15.5), Vector3(0.25, 1.5, 5.5), wall_material)
	_add_box("CombatRailLeft", Vector3(-8.75, 0.75, -1), Vector3(0.25, 1.5, 10), wall_material)
	_add_box("CombatRailRight", Vector3(8.75, 0.75, -1), Vector3(0.25, 1.5, 10), wall_material)
	_add_box("ExitRailLeft", Vector3(-5.75, 0.75, -17), Vector3(0.25, 1.5, 8), wall_material)
	_add_box("ExitRailRight", Vector3(5.75, 0.75, -17), Vector3(0.25, 1.5, 8), wall_material)

	_add_box("StartCyanGuide", Vector3(0, 0.03, 12), Vector3(5, 0.06, 0.16), cyan_material)
	_add_box("VectorLaunchGuide", Vector3(4.3, 0.04, 11.3), Vector3(2.4, 0.08, 0.22), cyan_material)
	_add_box("VectorLandingGuide", Vector3(5.6, 0.04, 3.8), Vector3(3.2, 0.08, 0.22), cyan_material)
	_add_box("CombatAmberGuide", Vector3(4.5, 0.03, -3), Vector3(3.5, 0.06, 0.16), amber_material)
	_add_box("ExitCyanGuide", Vector3(0, 0.03, -15), Vector3(5, 0.06, 0.16), cyan_material)

	_add_label(
		"EntryInstructions",
		Vector3(0, 3.2, 11.4),
		"BREACH LAB // MOMENTUM TRIAL\nPRESS E TO ATTACH / RELEASE",
		Color("8defff")
	)
	_add_label(
		"VectorInstructions",
		Vector3(5.2, 4.4, 9.7),
		"OPTIONAL VECTOR LINE\nSWING // RELEASE // HOLD SHIFT + W // SPACE",
		Color("8defff")
	)
	_add_label(
		"CombatInstructions",
		Vector3(0, 3.25, -4.8),
		"PULL AMBER HANDLE // LMB BLADE\nDISABLE SECURITY CONSTRUCT",
		Color("ffc36a")
	)
	_add_label(
		"GapWarning",
		Vector3(0, 1.8, 7.3),
		"STRUCTURAL VOID // TETHER REQUIRED",
		Color("ff6f79")
	)


func _build_lighting() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-58, -32, 0)
	key.light_color = Color("bad8e8")
	key.light_energy = 0.8
	key.shadow_enabled = true
	add_child(key)
	_add_omni(Vector3(0, 4, 14), Color("45dce7"), 2.2, 12.0)
	_add_omni(Vector3(0, 4, -1), Color("f6a83d"), 2.4, 13.0)
	_add_omni(Vector3(0, 4, -17), Color("45dce7"), 2.0, 10.0)


func _add_omni(position_value: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position_value
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	add_child(light)


func _bind_player_health() -> void:
	var health := get_tree().get_first_node_in_group("player_health") as PlayerHealth
	if health == null:
		fail_level("BREACH LAB REQUIRES ACTION PLAYER HEALTH")
		return
	health.player_defeated.connect(_on_player_defeated)


func _on_player_defeated() -> void:
	fail_level("PLAYER INTEGRITY DEPLETED BY SECURITY CONSTRUCT")


func _on_bridge_deployed() -> void:
	_bridge_ready = true
	_evaluate_completion()


func _on_construct_deactivated() -> void:
	_construct_defeated = true
	_evaluate_completion()


func _evaluate_completion() -> void:
	_report_progress()
	if _bridge_ready and _construct_defeated and not is_puzzle_complete():
		mark_puzzle_completed()
		puzzle_exit.unlock_exit()
		mark_exit_unlocked()


func _report_progress() -> void:
	var complete_count := int(_bridge_ready) + int(_construct_defeated)
	var message: String
	if not _bridge_ready:
		message = "TETHER ACROSS GAP // PULL AMBER BRIDGE HANDLE"
	elif not _construct_defeated:
		message = "BRIDGE ONLINE // DISABLE SECURITY CONSTRUCT WITH BLADE"
	else:
		message = "LAB SECURED // CROSS DEPLOYED BRIDGE TO EXIT"
	report_objective(message, complete_count, 2)
