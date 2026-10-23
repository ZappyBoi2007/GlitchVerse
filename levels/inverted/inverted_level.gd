class_name InvertedLevel
extends CampaignLevelBase

var stabilizer_a: PolarityMass
var stabilizer_b: PolarityMass
var campaign_exit: CampaignExit
var _a_online := false
var _b_online := false


func _ready() -> void:
	configure_palette(Color("54e7ff"), Color("b668ff"), Color("ffb33d"))
	_build_environment()
	_spawn_puzzle()
	add_fall_failure(Vector3(0, -8, 0), "INVERTED // LOST IN GRAVITY WELL")
	bind_player_health.call_deferred("INVERTED // PLAYER INTEGRITY DEPLETED")
	_report_progress()


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
	place_scene(ANCHOR_SCENE, "EntryGrappleAnchor", Vector3(0, 7, 7))
	place_scene(ANCHOR_SCENE, "ExitGrappleAnchor", Vector3(0, 9, -8))
	place_scene(VECTOR_WALL_SCENE, "MaintenanceVectorWall", Vector3(9.5, 3.5, -5))
	add_label("LevelTitle", Vector3(0, 3.3, 16), "INVERTED // GRAVITY REACTOR", Color("8cefff"))
	add_label("ExitGuide", Vector3(0, 7.2, -13), "UPPER REACTOR EXIT", Color("c792ff"))
	add_directional(Color("b9d7e8"), 0.78)
	add_omni(Vector3(0, 6, 2), Color("9b55ff"), 2.5, 18.0)
	add_omni(Vector3(0, 7, -14), Color("55ddff"), 2.0, 12.0)


func _spawn_puzzle() -> void:
	stabilizer_a = place_scene(POLARITY_SCENE, "StabilizerA", Vector3(-5, 0.9, 2)) as PolarityMass
	stabilizer_a.travel_offset = Vector3(0, 4.0, 0)
	stabilizer_a.state_changed.connect(_on_stabilizer_a)
	stabilizer_a.get_node("Label3D").text = "STABILIZER A\nQ // INVERT"
	stabilizer_b = place_scene(POLARITY_SCENE, "StabilizerB", Vector3(5, 0.9, -2)) as PolarityMass
	stabilizer_b.travel_offset = Vector3(0, 4.0, 0)
	stabilizer_b.state_changed.connect(_on_stabilizer_b)
	stabilizer_b.get_node("Label3D").text = "STABILIZER B\nQ // INVERT"
	campaign_exit = place_scene(EXIT_SCENE, "CampaignExit", Vector3(0, 4.05, -15.5)) as CampaignExit
	campaign_exit.exit_reached.connect(finish_level)


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
		message = "GRAVITY STABLE // TETHER TO UPPER EXIT"
	report_objective(message, completed, 2)
