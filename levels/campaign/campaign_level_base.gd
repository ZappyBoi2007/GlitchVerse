class_name CampaignLevelBase
extends GameplayLevel

const ANCHOR_SCENE := preload("res://interactive/grapple_anchor.tscn")
const VECTOR_WALL_SCENE := preload("res://interactive/vector_run_surface.tscn")
const RELAY_SCENE := preload("res://interactive/objective_relay.tscn")
const REWIRE_SCENE := preload("res://interactive/rewire_console.tscn")
const POLARITY_SCENE := preload("res://interactive/polarity_mass.tscn")
const EXIT_SCENE := preload("res://interactive/campaign_exit.tscn")
const ENEMY_SCENE := preload("res://enemies/security_construct.tscn")
const FALL_SCENE := preload("res://interactive/fall_hazard.tscn")

var structural_material: StandardMaterial3D
var floor_material: StandardMaterial3D
var primary_material: StandardMaterial3D
var secondary_material: StandardMaterial3D
var warning_material: StandardMaterial3D


func configure_palette(primary: Color, secondary: Color, warning: Color) -> void:
	structural_material = _material(Color("111821"), 0.72, 0.55)
	floor_material = _material(Color("252f3a"), 0.82, 0.35)
	primary_material = _emissive(primary, 1.25)
	secondary_material = _emissive(secondary, 1.2)
	warning_material = _emissive(warning, 1.35)


func add_box(node_name: String, position_value: Vector3, size: Vector3, material: Material, collision := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position_value
	add_child(body)
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


func add_core(node_name: String, position_value: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = position_value
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.material = material
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	return mesh_instance


func add_label(node_name: String, position_value: Vector3, text_value: String, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.position = position_value
	label.text = text_value
	label.font_size = 26
	label.outline_size = 8
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	return label


func add_omni(position_value: Vector3, color: Color, energy := 1.8, range_value := 12.0) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = position_value
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	add_child(light)
	return light


func add_directional(color := Color("b8d6e8"), energy := 0.75) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-58, -35, 0)
	light.light_color = color
	light.light_energy = energy
	light.shadow_enabled = true
	add_child(light)
	return light


func place_scene(scene: PackedScene, node_name: String, position_value: Vector3, rotation_value := Vector3.ZERO) -> Node3D:
	var instance := scene.instantiate() as Node3D
	instance.name = node_name
	instance.position = position_value
	instance.rotation_degrees = rotation_value
	add_child(instance)
	return instance


func place_scene_at_marker(scene: PackedScene, node_name: String, marker: Node3D) -> Node3D:
	var instance := scene.instantiate() as Node3D
	instance.name = node_name
	# Configure the local transform before entering the active SceneTree. Area3D
	# nodes must never spend a physics tick at the wrapper origin, where they can
	# emit a false player overlap before being moved to their authored marker.
	instance.transform = global_transform.affine_inverse() * marker.global_transform
	add_child(instance)
	return instance


func set_csg_state(shape: CSGShape3D, visible_state: bool, collision_state := false) -> void:
	shape.visible = visible_state
	shape.use_collision = collision_state


func add_fall_failure(position_value := Vector3(0, -7, 0), reason := "PLAYER LOST OUTSIDE THE SIMULATION") -> FallHazard:
	var hazard := place_scene(FALL_SCENE, "FallFailure", position_value) as FallHazard
	hazard.failure_reason = reason
	hazard.failure_requested.connect(fail_level)
	return hazard


func bind_player_health(reason: String) -> void:
	var health := get_tree().get_first_node_in_group("player_health") as PlayerHealth
	if health != null:
		health.player_defeated.connect(func() -> void: fail_level(reason))


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := _material(color.darkened(0.68), 0.3, 0.55)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
