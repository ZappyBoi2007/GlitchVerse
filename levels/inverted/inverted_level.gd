class_name InvertedLevel
extends CampaignLevelBase

const EXIT_ART_OFFSET := Vector3(0.0, 0.0, 3.65)
const VISIBLE_EXIT_PLANE_Z := -15.7
const EXIT_TRIGGER_POSITION := Vector3(0.0, 4.05, -17.5)

@onready var environment: Node3D = $InvertedProductionEnvironment
@onready var markers: Node3D = $InvertedProductionEnvironment/IntegrationMarkers

var stabilizer_a: PolarityMass
var stabilizer_b: PolarityMass
var campaign_exit: CampaignExit
var _a_online := false
var _b_online := false


func _ready() -> void:
	configure_palette(Color("54e7ff"), Color("b668ff"), Color("ffb33d"))
	if not _validate_environment_contract():
		fail_level("INVERTED PRODUCTION ENVIRONMENT MARKERS ARE INCOMPLETE")
		return
	_build_environment()
	_spawn_puzzle()
	_integrate_production_art()
	add_fall_failure(Vector3(0, -8, 0), "INVERTED // LOST IN GRAVITY WELL")
	bind_player_health.call_deferred("INVERTED // PLAYER INTEGRITY DEPLETED")
	_report_progress()


func _validate_environment_contract() -> bool:
	for path in [
		"PlayerSpawn", "StabilizerA", "StabilizerB", "EntryGrappleAnchor",
		"ExitGrappleAnchor", "MaintenanceVectorWall", "CampaignExit"
	]:
		if markers.get_node_or_null(path) == null:
			return false
	for path in [
		"Environment/Architecture/FloorShell",
		"Environment/Architecture/FloorInset",
		"Environment/ExitAssembly/UpperExitFrame"
	]:
		if environment.get_node_or_null(path) == null:
			return false
	return true


func _build_environment() -> void:
	add_box("ArrivalDeck", Vector3(0, -0.5, 14), Vector3(12, 1, 10), floor_material)
	add_box("ReactorDeck", Vector3(0, -0.5, 0), Vector3(20, 1, 12), floor_material)
	add_box("UpperExitDeck", Vector3(0, 3.5, -14), Vector3(12, 1, 8), floor_material)
	add_box("LeftCatwalk", Vector3(-8, 1.5, -7), Vector3(3, 0.5, 10), structural_material)
	add_box("RightCatwalk", Vector3(8, 1.5, -7), Vector3(3, 0.5, 10), structural_material)
	for x in [-9.5, 9.5]:
		add_box("ReactorPillar_%s" % x, Vector3(x, 4, 0), Vector3(0.7, 8, 0.7), structural_material)
	add_core("UnstableGravityCore", Vector3(0, 5.0, 0), 2.4, 10.0, secondary_material)
	add_core("CoreRingLower", Vector3(0, 1.0, 0), 3.8, 0.35, primary_material)
	add_core("CoreRingUpper", Vector3(0, 8.5, 0), 3.8, 0.35, primary_material)
	add_box("CyanRoute", Vector3(0, 0.04, 8.5), Vector3(3.5, 0.08, 0.22), primary_material, false)
	add_box("VioletRoute", Vector3(0, 4.04, -10.5), Vector3(3.5, 0.08, 0.22), secondary_material, false)
	# A stepped launch perch makes the intended upper route readable and gives
	# the player a forgiving, repeatable takeoff without bridging the gap.
	add_box("ExitLaunchStepA", Vector3(0, 0.3, -4.6), Vector3(4.0, 0.6, 1.0), structural_material)
	add_box("ExitLaunchStepB", Vector3(0, 0.85, -5.6), Vector3(4.0, 1.7, 1.0), structural_material)
	add_box("ExitLaunchStepC", Vector3(0, 1.4, -6.6), Vector3(4.0, 2.8, 1.0), structural_material)
	add_box("ExitLaunchGlow", Vector3(0, 2.82, -6.6), Vector3(3.4, 0.08, 0.65), primary_material, false)
	add_box("UpperLandingGlow", Vector3(0, 4.04, -10.65), Vector3(5.0, 0.08, 0.85), secondary_material, false)
	place_scene_at_marker(
		ANCHOR_SCENE, "EntryGrappleAnchor", markers.get_node("EntryGrappleAnchor") as Node3D
	)
	place_scene_at_marker(
		ANCHOR_SCENE, "ExitGrappleAnchor", markers.get_node("ExitGrappleAnchor") as Node3D
	)
	place_scene_at_marker(
		VECTOR_WALL_SCENE, "MaintenanceVectorWall", markers.get_node("MaintenanceVectorWall") as Node3D
	)
	add_label("LevelTitle", Vector3(0, 3.3, 16), "INVERTED // GRAVITY REACTOR", Color("8cefff"))
	var stabilizer_guide := add_label(
		"StabilizerRouteGuide",
		Vector3(0, 2.35, 10.5),
		"Q // ACTIVATE STABILIZERS A + B\nLEFT + RIGHT OF REACTOR",
		Color("ffbf5a")
	)
	stabilizer_guide.font_size = 18
	var tether_guide := add_label(
		"TetherRouteGuide",
		Vector3(0, 3.65, -6.2),
		"UPPER ROUTE // E TETHER",
		Color("8cefff")
	)
	tether_guide.font_size = 18
	var portal_guide := add_label(
		"PortalRouteGuide",
		Vector3(0, 5.55, -13.0),
		"EXIT // BEYOND VIOLET DECK",
		Color("c792ff")
	)
	portal_guide.font_size = 18
	var exit_guide := add_label("ExitGuide", Vector3(0, 6.4, -15.2), "EXIT DECK", Color("c792ff"))
	exit_guide.font_size = 20
	add_box("ExitPortalLeft", Vector3(-2.35, 5.2, -15.7), Vector3(0.22, 2.4, 0.22), secondary_material, false)
	add_box("ExitPortalRight", Vector3(2.35, 5.2, -15.7), Vector3(0.22, 2.4, 0.22), secondary_material, false)
	add_box("ExitPortalTop", Vector3(0, 6.35, -15.7), Vector3(4.9, 0.22, 0.22), secondary_material, false)
	# The production environment owns the WorldEnvironment and practical lights.
	# Retaining these procedural lights would wash out Jefin's authored pass.
	if environment == null:
		add_directional(Color("b9d7e8"), 0.78)
		add_omni(Vector3(0, 6, 2), Color("9b55ff"), 2.5, 18.0)
		add_omni(Vector3(0, 6.5, -12.5), Color("55ddff"), 2.3, 13.0)
		add_omni(Vector3(0, 3.8, -6.5), Color("55ddff"), 1.2, 7.0)


func _spawn_puzzle() -> void:
	stabilizer_a = place_scene_at_marker(
		POLARITY_SCENE, "StabilizerA", markers.get_node("StabilizerA") as Node3D
	) as PolarityMass
	stabilizer_a.travel_offset = Vector3(0, 4.0, 0)
	stabilizer_a.state_changed.connect(_on_stabilizer_a)
	stabilizer_a.get_node("Label3D").text = "STABILIZER A\nQ // INVERT"
	stabilizer_b = place_scene_at_marker(
		POLARITY_SCENE, "StabilizerB", markers.get_node("StabilizerB") as Node3D
	) as PolarityMass
	stabilizer_b.travel_offset = Vector3(0, 4.0, 0)
	stabilizer_b.state_changed.connect(_on_stabilizer_b)
	stabilizer_b.get_node("Label3D").text = "STABILIZER B\nQ // INVERT"
	campaign_exit = place_scene_at_marker(
		EXIT_SCENE, "CampaignExit", markers.get_node("CampaignExit") as Node3D
	) as CampaignExit
	# Jefin's marker records the former gameplay coordinate. The trigger belongs
	# beyond the aligned visible doorway, while remaining on UpperExitDeck's real
	# collision, so approaching the portal cannot complete the level early.
	campaign_exit.global_position = EXIT_TRIGGER_POSITION
	campaign_exit.exit_reached.connect(finish_level)


func _integrate_production_art() -> void:
	# FloorShell/FloorInset span deliberate traversal gaps and have no collision.
	# Hiding them prevents a visually walkable but physically unsupported floor.
	(environment.get_node("Environment/Architecture/FloorShell") as Node3D).visible = false
	(environment.get_node("Environment/Architecture/FloorInset") as Node3D).visible = false

	# Preserve every procedural StaticBody3D and CollisionShape3D, hiding only
	# their obsolete primitive meshes where production deck art is aligned.
	for path in [
		"ArrivalDeck/Mesh", "ReactorDeck/Mesh", "UpperExitDeck/Mesh",
		"LeftCatwalk/Mesh", "RightCatwalk/Mesh", "ReactorPillar_-9_5/Mesh",
		"ReactorPillar_9_5/Mesh"
	]:
		(get_node(path) as Node3D).visible = false

	for path in [
		"UnstableGravityCore", "CoreRingLower", "CoreRingUpper", "CyanRoute/Mesh",
		"VioletRoute/Mesh", "LevelTitle", "ExitGuide"
	]:
		(get_node(path) as Node3D).visible = false

	# Art fixtures replace only the sphere/text presentation. Gameplay collision,
	# GrapplePoint and Highlight remain on both reusable GrappleAnchor nodes.
	for anchor_name in ["EntryGrappleAnchor", "ExitGrappleAnchor"]:
		(get_node("%s/Mesh" % anchor_name) as Node3D).visible = false
		(get_node("%s/Label3D" % anchor_name) as Node3D).visible = false

	campaign_exit.beacon.visible = false

	# Bring the production doorway onto the supported upper deck. Its source
	# transform is z=-19.35 while the authored collision deck ends at z=-18.
	# Moving only the decorative assembly keeps Jefin's source scene untouched.
	var exit_assembly := environment.get_node("Environment/ExitAssembly") as Node3D
	exit_assembly.position += EXIT_ART_OFFSET


func _on_stabilizer_a(inverted: bool) -> void:
	_a_online = inverted
	_evaluate()


func _on_stabilizer_b(inverted: bool) -> void:
	_b_online = inverted
	_evaluate()


func _evaluate() -> void:
	_report_progress()
	if _a_online and _b_online and not is_puzzle_complete():
		mark_puzzle_completed()
		campaign_exit.unlock_exit()
		mark_exit_unlocked()


func _report_progress() -> void:
	var completed := int(_a_online) + int(_b_online)
	var message := "Q // INVERT BOTH GRAVITY STABILIZERS"
	if completed == 1:
		message = "ONE STABILIZER ONLINE // LOCATE THE SECOND"
	elif completed == 2:
		message = "GRAVITY STABLE // FOLLOW VIOLET BEACONS // E TETHER"
	report_objective(message, completed, 2)
