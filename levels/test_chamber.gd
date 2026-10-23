extends Node3D

## Builds the Milestone 1 chamber entirely from Godot primitives.
## Each solid receives both a BoxMesh and matching BoxShape3D collision.

var charcoal: StandardMaterial3D
var dark_metal: StandardMaterial3D
var cyan: StandardMaterial3D
var magenta: StandardMaterial3D
var exit_material: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_build_floor_and_walls()
	_build_platform_course()
	_build_corridor()
	_build_decorations()
	_build_lighting()


func _create_materials() -> void:
	charcoal = _make_material(Color("202631"), 0.82, 0.18)
	dark_metal = _make_material(Color("111722"), 0.48, 0.62)
	cyan = _make_emissive_material(Color("20e7ff"), 2.2)
	magenta = _make_emissive_material(Color("ff3bbd"), 2.0)
	exit_material = _make_emissive_material(Color("55ff9a"), 2.8)


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_material(color.darkened(0.58), 0.35, 0.4)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _add_box(label: String, position: Vector3, size: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = position
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


func _add_glow_strip(position: Vector3, size: Vector3, material: Material) -> void:
	var strip := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	strip.mesh = mesh
	strip.position = position
	add_child(strip)


func _build_floor_and_walls() -> void:
	_add_box("MainFloor", Vector3(0, -0.5, 0), Vector3(30, 1, 34), charcoal)
	_add_box("NorthWall", Vector3(0, 4, -17), Vector3(30, 9, 1), dark_metal)
	_add_box("SouthWallLeft", Vector3(-9.5, 4, 17), Vector3(11, 9, 1), dark_metal)
	_add_box("SouthWallRight", Vector3(9.5, 4, 17), Vector3(11, 9, 1), dark_metal)
	_add_box("WestWall", Vector3(-15, 4, 0), Vector3(1, 9, 34), dark_metal)
	_add_box("EastWall", Vector3(15, 4, 0), Vector3(1, 9, 34), dark_metal)
	_add_glow_strip(Vector3(0, 0.03, -15.5), Vector3(20, 0.04, 0.13), cyan)
	_add_glow_strip(Vector3(-13.5, 0.03, 0), Vector3(0.13, 0.04, 24), magenta)


func _build_platform_course() -> void:
	_add_box("LowPlatform", Vector3(-7, 0.35, -6), Vector3(4.5, 0.7, 4.5), dark_metal)
	_add_box("MidPlatform", Vector3(-1.5, 0.75, -9), Vector3(4, 1.5, 3.5), charcoal)
	_add_box("HighPlatform", Vector3(4, 1.2, -11), Vector3(4.2, 2.4, 3.2), dark_metal)
	_add_box("StepOne", Vector3(6.5, 0.25, -5), Vector3(2.5, 0.5, 2.5), charcoal)
	_add_box("StepTwo", Vector3(9.2, 0.55, -7.2), Vector3(2.5, 1.1, 2.5), charcoal)
	_add_box("ObstacleA", Vector3(-7, 1.1, 4), Vector3(1.8, 2.2, 1.8), dark_metal)
	_add_box("ObstacleB", Vector3(-2.5, 1.7, 2), Vector3(2.2, 3.4, 2.2), dark_metal)
	_add_box("ObstacleC", Vector3(3, 0.75, 5), Vector3(3, 1.5, 2), charcoal)
	_add_glow_strip(Vector3(-7, 0.72, -3.73), Vector3(3.8, 0.08, 0.07), magenta)
	_add_glow_strip(Vector3(4, 2.43, -9.37), Vector3(3.5, 0.08, 0.07), cyan)


func _build_corridor() -> void:
	_add_box("CorridorFloor", Vector3(0, -0.25, 21), Vector3(8, 0.5, 9), charcoal)
	_add_box("CorridorLeft", Vector3(-4, 2.5, 21), Vector3(0.6, 5.5, 9), dark_metal)
	_add_box("CorridorRight", Vector3(4, 2.5, 21), Vector3(0.6, 5.5, 9), dark_metal)
	_add_box("CorridorCeiling", Vector3(0, 5.15, 21), Vector3(8.6, 0.5, 9), dark_metal)
	_add_box("ExitDoor", Vector3(0, 2.1, 25.2), Vector3(4.2, 4.2, 0.45), exit_material)
	_add_box("ExitHeader", Vector3(0, 4.55, 25.0), Vector3(5.6, 0.35, 0.5), magenta)
	_add_glow_strip(Vector3(-3.65, 0.08, 21), Vector3(0.09, 0.09, 7.6), cyan)
	_add_glow_strip(Vector3(3.65, 0.08, 21), Vector3(0.09, 0.09, 7.6), cyan)

	var exit_label := Label3D.new()
	exit_label.text = "EXIT // LOCKED"
	exit_label.font_size = 48
	exit_label.modulate = Color("07100b")
	exit_label.outline_size = 8
	exit_label.outline_modulate = Color("55ff9a")
	exit_label.position = Vector3(0, 3.7, 24.94)
	exit_label.rotation_degrees = Vector3(0, 180, 0)
	add_child(exit_label)


func _build_decorations() -> void:
	for z_position in [-12.0, -4.0, 4.0, 12.0]:
		_add_box("WestPillar", Vector3(-13.6, 2, z_position), Vector3(1.2, 4, 1.2), dark_metal)
		_add_box("EastPillar", Vector3(13.6, 2, z_position), Vector3(1.2, 4, 1.2), dark_metal)
	_add_box("DataCubeCyan", Vector3(8, 0.75, 4), Vector3(1.5, 1.5, 1.5), cyan)
	_add_box("DataCubeMagenta", Vector3(10.2, 0.5, 6.1), Vector3(1, 1, 1), magenta)
	_add_box("CentralBeam", Vector3(0, 6.8, -1), Vector3(27, 0.6, 0.8), dark_metal)


func _build_lighting() -> void:
	var key_light := DirectionalLight3D.new()
	key_light.name = "DirectionalLight"
	key_light.rotation_degrees = Vector3(-58, -32, 0)
	key_light.light_color = Color("9bcaff")
	key_light.light_energy = 0.72
	key_light.shadow_enabled = true
	add_child(key_light)

	_add_omni_light(Vector3(-7, 3.6, -6), Color("22eaff"), 5.0, 10.0)
	_add_omni_light(Vector3(7, 3.5, 4), Color("ff35bd"), 4.5, 9.0)
	_add_omni_light(Vector3(0, 3.6, 21), Color("43ffd1"), 5.0, 8.0)


func _add_omni_light(position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	add_child(light)
