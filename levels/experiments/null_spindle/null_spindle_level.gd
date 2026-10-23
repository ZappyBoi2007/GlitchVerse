class_name NullSpindleLevel
extends GameplayLevel

## Experimental layered facility built from inexpensive Godot primitives.
## The route descends from observation level into maintenance, then climbs to containment.

@onready var puzzle_controller: NullSpindlePuzzle = $NullSpindlePuzzle
@onready var puzzle_exit: PuzzleExit = $PuzzleExit

var floor_material: StandardMaterial3D
var steel_material: StandardMaterial3D
var panel_material: StandardMaterial3D
var beam_material: StandardMaterial3D
var cyan_material: StandardMaterial3D
var amber_material: StandardMaterial3D
var violet_material: StandardMaterial3D
var warning_material: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_build_facility_shell()
	_build_observation_level()
	_build_lower_maintenance()
	_build_containment_route()
	_build_null_spindle()
	_build_structural_details()
	_build_guidance()
	_build_lighting()
	puzzle_controller.puzzle_solved.connect(_on_puzzle_solved)
	puzzle_controller.progress_changed.connect(report_objective)
	puzzle_exit.exit_reached.connect(_on_exit_reached)


func _create_materials() -> void:
	floor_material = _make_material(Color("303a45"), 0.9, 0.16)
	steel_material = _make_material(Color("141b25"), 0.52, 0.7)
	panel_material = _make_material(Color("222d39"), 0.72, 0.38)
	beam_material = _make_material(Color("0d121a"), 0.45, 0.78)
	cyan_material = _make_emissive_material(Color("55e8e2"), 1.7)
	amber_material = _make_emissive_material(Color("f6b857"), 1.65)
	violet_material = _make_emissive_material(Color("bb8dfa"), 1.7)
	warning_material = _make_emissive_material(Color("ff476f"), 1.45)


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_material(color.darkened(0.66), 0.32, 0.42)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _add_box(
	label: String,
	position: Vector3,
	size: Vector3,
	material: Material,
	rotation_degrees_value := Vector3.ZERO
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = position
	body.rotation_degrees = rotation_degrees_value
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


func _add_visual_box(
	label: String,
	position: Vector3,
	size: Vector3,
	material: Material,
	rotation_degrees_value := Vector3.ZERO
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	mesh_instance.position = position
	mesh_instance.rotation_degrees = rotation_degrees_value
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
	return mesh_instance


func _add_cylinder(
	label: String,
	position: Vector3,
	radius: float,
	height: float,
	material: Material,
	solid := false
) -> Node3D:
	var parent: Node3D
	if solid:
		var body := StaticBody3D.new()
		body.name = label
		body.position = position
		add_child(body)
		parent = body
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		body.add_child(collision)
	else:
		parent = Node3D.new()
		parent.name = label
		parent.position = position
		add_child(parent)

	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	mesh.material = material
	mesh_instance.mesh = mesh
	parent.add_child(mesh_instance)
	return parent


func _add_label(label_name: String, position: Vector3, text: String, color: Color, size := 28) -> void:
	var label := Label3D.new()
	label.name = label_name
	label.position = position
	label.text = text
	label.font_size = size
	label.outline_size = 8
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _build_facility_shell() -> void:
	_add_box("LowerFacilityFloor", Vector3(0, -0.45, 0), Vector3(28, 0.9, 24), floor_material)
	_add_box("WestOuterWall", Vector3(-14, 4, 0), Vector3(0.8, 8, 24), steel_material)
	_add_box("EastOuterWall", Vector3(14, 4, 0), Vector3(0.8, 8, 24), steel_material)
	_add_box("SouthOuterWall", Vector3(0, 4, -12), Vector3(28, 8, 0.8), steel_material)
	# North wall contains two deliberate openings: observation entry and containment exit.
	_add_box("NorthWallWest", Vector3(-8.5, 4, 12), Vector3(11, 8, 0.8), steel_material)
	_add_box("NorthWallMiddle", Vector3(5, 4, 12), Vector3(4, 8, 0.8), steel_material)
	_add_box("NorthWallEast", Vector3(12.5, 4, 12), Vector3(3, 8, 0.8), steel_material)
	_add_box("LowerCeilingBeam", Vector3(0, 8.2, -4), Vector3(27, 0.45, 0.65), beam_material)


func _build_observation_level() -> void:
	_add_box("ObservationCorridorFloor", Vector3(0, 3.75, 18), Vector3(6, 0.5, 12), panel_material)
	_add_box("ObservationCorridorWest", Vector3(-3.25, 6, 18), Vector3(0.5, 4.5, 12), steel_material)
	_add_box("ObservationCorridorEast", Vector3(3.25, 6, 18), Vector3(0.5, 4.5, 12), steel_material)
	_add_box("ObservationCorridorCeiling", Vector3(0, 8.1, 18), Vector3(7, 0.45, 12), beam_material)
	_add_box("ObservationRearWall", Vector3(0, 6, 24), Vector3(7, 4.5, 0.5), steel_material)

	_add_box("NorthObservationDeck", Vector3(0, 3.75, 8.5), Vector3(12, 0.5, 7), panel_material)
	_add_box("WestConnector", Vector3(-7.5, 3.75, 7.2), Vector3(3, 0.5, 2.6), panel_material)
	_add_box("WestCatwalk", Vector3(-10, 3.75, 3.7), Vector3(4, 0.5, 7.2), panel_material)

	_add_box("ObservationRailWest", Vector3(-5.85, 4.55, 9), Vector3(0.16, 1.35, 5.8), beam_material)
	_add_box("ObservationRailEast", Vector3(5.85, 4.55, 9), Vector3(0.16, 1.35, 5.8), beam_material)
	_add_box("ObservationFrontRail", Vector3(2.7, 4.55, 5.1), Vector3(6.3, 1.35, 0.16), beam_material)
	_add_box("WestCatwalkRailOuter", Vector3(-12, 4.55, 3.8), Vector3(0.16, 1.35, 7), beam_material)
	# Stop before the connector so the observation deck has a full-width entrance.
	_add_box("WestCatwalkRailInner", Vector3(-8, 4.55, 2.9), Vector3(0.16, 1.35, 5.2), beam_material)

	_add_box(
		"WestMaintenanceRamp",
		Vector3(-10, 2, -3.25),
		Vector3(3, 0.4, 9),
		floor_material,
		Vector3(-26.5, 0, 0)
	)
	_add_box(
		"WestRampRailOuter",
		Vector3(-11.45, 2.62, -3.25),
		Vector3(0.16, 1.3, 9),
		beam_material,
		Vector3(-26.5, 0, 0)
	)
	_add_box(
		"WestRampRailInner",
		Vector3(-8.55, 2.62, -3.25),
		Vector3(0.16, 1.3, 9),
		beam_material,
		Vector3(-26.5, 0, 0)
	)

	for index in range(10):
		_add_visual_box(
			"ObservationGrate%02d" % index,
			Vector3(0, 4.02, 13.7 + index),
			Vector3(5.6, 0.035, 0.08),
			cyan_material
		)


func _build_lower_maintenance() -> void:
	_add_box("MaintenanceNorthWall", Vector3(-5.2, 1.65, -6), Vector3(12.8, 3.3, 0.5), steel_material)
	_add_box("MaintenanceSouthWall", Vector3(-5.2, 1.65, -10), Vector3(12.8, 3.3, 0.5), steel_material)
	_add_box("MaintenanceCeiling", Vector3(-5.2, 5.2, -8), Vector3(12.8, 0.4, 4.5), beam_material)
	_add_visual_box("MaintenancePath", Vector3(-4.5, 0.035, -8), Vector3(13, 0.05, 2.6), panel_material)

	# A narrow gate prevents squeezing past the gravity crate at floor level.
	_add_box("CrateGateNorth", Vector3(-4, 1.5, -9.3), Vector3(0.55, 3, 0.9), beam_material)
	_add_box("CrateGateSouth", Vector3(-4, 1.5, -6.7), Vector3(0.55, 3, 0.9), beam_material)
	_add_box("CrateGateHeader", Vector3(-4, 4.65, -8), Vector3(0.55, 0.5, 3.5), amber_material)

	_add_box("EastMaintenanceWestWall", Vector3(7.25, 1.6, -3.2), Vector3(0.45, 3.2, 9.6), steel_material)
	_add_box("EastMaintenanceEastWall", Vector3(10.75, 1.6, -3.2), Vector3(0.45, 3.2, 9.6), steel_material)
	_add_visual_box("EastMaintenancePath", Vector3(9, 0.035, -3.2), Vector3(3, 0.05, 9.4), panel_material)

	for index in range(12):
		_add_visual_box(
			"MaintenanceGrate%02d" % index,
			Vector3(-9.5 + index, 0.07, -8),
			Vector3(0.08, 0.04, 2.45),
			amber_material
		)
	for index in range(8):
		_add_visual_box(
			"HazardLaneGrate%02d" % index,
			Vector3(9, 0.07, -7 + index),
			Vector3(2.7, 0.04, 0.08),
			violet_material
		)


func _build_containment_route() -> void:
	_add_box(
		"EastContainmentRamp",
		Vector3(9, 2, 5.1),
		Vector3(3, 0.4, 9),
		floor_material,
		Vector3(-26.5, 0, 0)
	)
	_add_box(
		"EastRampRailWest",
		Vector3(7.55, 2.62, 5.1),
		Vector3(0.16, 1.3, 9),
		beam_material,
		Vector3(-26.5, 0, 0)
	)
	_add_box(
		"EastRampRailEast",
		Vector3(10.45, 2.62, 5.1),
		Vector3(0.16, 1.3, 9),
		beam_material,
		Vector3(-26.5, 0, 0)
	)
	_add_box("ContainmentDeck", Vector3(9, 3.75, 10.2), Vector3(6, 0.5, 4), panel_material)
	_add_box("ContainmentRailWest", Vector3(6.05, 4.55, 9.8), Vector3(0.16, 1.35, 3.6), beam_material)
	_add_box("ContainmentRailEast", Vector3(11.95, 4.55, 9.8), Vector3(0.16, 1.35, 3.6), beam_material)

	_add_box("ExitVestibuleFloor", Vector3(9, 3.75, 14), Vector3(5, 0.5, 4), floor_material)
	_add_box("ExitVestibuleWest", Vector3(6.5, 6, 14), Vector3(0.45, 4.5, 4), steel_material)
	_add_box("ExitVestibuleEast", Vector3(11.5, 6, 14), Vector3(0.45, 4.5, 4), steel_material)
	_add_box("ExitVestibuleCeiling", Vector3(9, 8.1, 14), Vector3(5.5, 0.45, 4), beam_material)
	_add_box("ExitVestibuleBack", Vector3(9, 6, 16), Vector3(5.5, 4.5, 0.45), steel_material)
	_add_visual_box("ContainmentThreshold", Vector3(9, 4.04, 11.4), Vector3(4.2, 0.05, 0.16), warning_material)


func _build_null_spindle() -> void:
	_add_cylinder("CorePlinth", Vector3(0, 0.45, 0), 2.4, 0.9, steel_material, true)
	_add_cylinder("EnergySpindle", Vector3(0, 4.65, 0), 1.15, 7.5, cyan_material, true)
	_add_cylinder("LowerContainmentRing", Vector3(0, 2, 0), 3.2, 0.65, panel_material)
	_add_cylinder("MidContainmentRing", Vector3(0, 4.7, 0), 3.4, 0.75, steel_material)
	_add_cylinder("UpperContainmentRing", Vector3(0, 7.35, 0), 3.1, 0.7, panel_material)
	_add_cylinder("VioletAnomalyBand", Vector3(0, 5.6, 0), 1.3, 0.3, violet_material)

	for index in range(4):
		var angle := deg_to_rad(45.0 + index * 90.0)
		var strut_position := Vector3(cos(angle) * 2.75, 4.7, sin(angle) * 2.75)
		_add_box(
			"CoreStrut%d" % index,
			strut_position,
			Vector3(0.38, 6.6, 0.38),
			beam_material,
			Vector3(0, -rad_to_deg(angle), 7 if index % 2 == 0 else -7)
		)

	_add_box("CoreSuspensionNorth", Vector3(0, 8.1, 4.8), Vector3(0.55, 0.55, 7.5), beam_material)
	_add_box("CoreSuspensionSouth", Vector3(0, 8.1, -4.8), Vector3(0.55, 0.55, 7.5), beam_material)
	_add_visual_box("CoreCyanBarNorth", Vector3(0, 6.1, 3.3), Vector3(0.18, 3.8, 0.18), cyan_material)
	_add_visual_box("CoreAmberBarSouth", Vector3(0, 4.5, -3.45), Vector3(0.18, 2.8, 0.18), amber_material)


func _build_structural_details() -> void:
	for x_position in [-12.5, 12.5]:
		for z_position in [-9.5, -3.0, 4.0, 10.0]:
			_add_box(
				"Pillar_%s_%s" % [str(x_position), str(z_position)],
				Vector3(x_position, 4, z_position),
				Vector3(0.7, 8, 0.7),
				beam_material
			)
	_add_box("OverheadCrossBeamNorth", Vector3(0, 7.8, 8.5), Vector3(26, 0.45, 0.55), beam_material)
	_add_box("OverheadCrossBeamSouth", Vector3(0, 7.8, -8.5), Vector3(26, 0.45, 0.55), beam_material)

	for index in range(5):
		_add_visual_box(
			"ObservationWindowLight%d" % index,
			Vector3(-2.9 + index * 1.45, 7.55, 17.5),
			Vector3(0.65, 0.12, 0.1),
			cyan_material
		)
	for index in range(4):
		_add_visual_box(
			"MaintenanceMachine%d" % index,
			Vector3(12.7, 0.7 + index * 0.85, -8.8 + index * 1.3),
			Vector3(1.2, 1.1, 0.9),
			panel_material
		)


func _build_guidance() -> void:
	_add_label(
		"EntryDirective",
		Vector3(0, 6.35, 13.3),
		"NULL SPINDLE // OBSERVATION ACCESS\nDESCEND VIA WEST MAINTENANCE",
		Color("b8fffb"),
		30
	)
	_add_label(
		"CoreIdentifier",
		Vector3(0, 8.85, 0),
		"SIMULATION CORE // CONTAINMENT UNSTABLE",
		Color("f6b857"),
		26
	)
	_add_label(
		"MaintenanceDirective",
		Vector3(-7.2, 2.6, -7.65),
		"MAINTENANCE GATE // LIFT OBSTRUCTION",
		Color("f6b857"),
		23
	)
	_add_label(
		"ContainmentDirective",
		Vector3(9, 3.1, 0.25),
		"CONTAINMENT ASCENT // HALT ANOMALY",
		Color("bb8dfa"),
		23
	)


func _build_lighting() -> void:
	var key_light := DirectionalLight3D.new()
	key_light.name = "IndustrialKeyLight"
	key_light.rotation_degrees = Vector3(-58, -28, 0)
	key_light.light_color = Color("b9d2e7")
	key_light.light_energy = 0.78
	key_light.shadow_enabled = true
	add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.name = "IndustrialFillLight"
	fill_light.rotation_degrees = Vector3(-35, 145, 0)
	fill_light.light_color = Color("7796ad")
	fill_light.light_energy = 0.24
	fill_light.shadow_enabled = false
	add_child(fill_light)

	_add_omni_light(Vector3(0, 6.5, 17), Color("55e8e2"), 2.7, 9.0)
	_add_omni_light(Vector3(-9, 3.2, -5), Color("f6b857"), 2.4, 8.0)
	_add_omni_light(Vector3(0, 5.2, 0), Color("55e8e2"), 3.2, 10.0)
	_add_omni_light(Vector3(9, 2.8, -2.5), Color("bb8dfa"), 2.6, 8.0)
	_add_omni_light(Vector3(9, 6.2, 12.5), Color("ff476f"), 2.0, 7.0)


func _add_omni_light(position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	add_child(light)


func _on_puzzle_solved() -> void:
	mark_puzzle_completed()
	puzzle_exit.unlock_exit()
	mark_exit_unlocked()


func _on_exit_reached() -> void:
	finish_level()
