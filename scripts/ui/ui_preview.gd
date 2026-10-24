class_name UIPreview
extends Control


## Standalone UI Preview & Development Testing Harness for GlitchVerse.
## Completely isolated from 3D gameplay, player controller, and GameFlowManager.
## Starts on MAIN MENU by default and allows instant switching between all screens:
##   [ MAIN MENU ] [ HUD ] [ PAUSE ] [ LEVEL COMPLETE ] [ GAME OVER ] [ VICTORY ]

# Packed Scenes for Dynamic Instantiation Fallback
@export var main_menu_scene: PackedScene = preload("res://scenes/ui/main_menu.tscn")
@export var hud_scene: PackedScene = preload("res://scenes/ui/in_game_hud.tscn")
@export var pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
@export var level_complete_scene: PackedScene = preload("res://scenes/ui/level_complete.tscn")
@export var game_over_scene: PackedScene = preload("res://scenes/ui/game_over.tscn")
@export var victory_scene: PackedScene = preload("res://scenes/ui/final_victory.tscn")

# Screen Instances
@export var main_menu_instance: MainMenu
@export var hud_instance: InGameHUD
@export var pause_menu_instance: PauseMenu
@export var level_complete_instance: LevelComplete
@export var game_over_instance: GameOver
@export var victory_instance: Control

# Node holding the screens
@onready var screens_container: Control = get_node_or_null("ScreensContainer") as Control

# Developer Preview Selector Buttons (Layer 100)
@onready var btn_main_menu: Button = get_node_or_null("%BtnMainMenu") as Button
@onready var btn_hud: Button = get_node_or_null("%BtnHUD") as Button
@onready var btn_pause: Button = get_node_or_null("%BtnPause") as Button
@onready var btn_complete: Button = get_node_or_null("%BtnComplete") as Button
@onready var btn_game_over: Button = get_node_or_null("%BtnGameOver") as Button
@onready var btn_victory: Button = get_node_or_null("%BtnVictory") as Button

# Developer Sub-Bar Container
@onready var dev_sub_bar: PanelContainer = get_node_or_null("%DevSubBar") as PanelContainer

# Row 1: Level, Health, Score
@onready var btn_l1: Button = get_node_or_null("%BtnL1") as Button
@onready var btn_l2: Button = get_node_or_null("%BtnL2") as Button
@onready var btn_l3: Button = get_node_or_null("%BtnL3") as Button
@onready var btn_l4: Button = get_node_or_null("%BtnL4") as Button
@onready var btn_dmg: Button = get_node_or_null("%BtnDmg") as Button
@onready var btn_heal: Button = get_node_or_null("%BtnHeal") as Button
@onready var btn_crit_health: Button = get_node_or_null("%BtnCritHealth") as Button
@onready var btn_add_score: Button = get_node_or_null("%BtnAddScore") as Button

# Row 2: Objective Progress & Wayfinding
@onready var btn_obj0: Button = get_node_or_null("%BtnObj0") as Button
@onready var btn_obj1: Button = get_node_or_null("%BtnObj1") as Button
@onready var btn_obj2: Button = get_node_or_null("%BtnObj2") as Button
@onready var btn_obj3: Button = get_node_or_null("%BtnObj3") as Button
@onready var btn_grapple_valid: Button = get_node_or_null("%BtnGrappleValid") as Button
@onready var btn_grapple_invalid: Button = get_node_or_null("%BtnGrappleInvalid") as Button
@onready var btn_grapple_none: Button = get_node_or_null("%BtnGrappleNone") as Button
@onready var btn_prompt_interact: Button = get_node_or_null("%BtnPromptInteract") as Button
@onready var btn_prompt_polarity: Button = get_node_or_null("%BtnPromptPolarity") as Button
@onready var btn_target_none: Button = get_node_or_null("%BtnTargetNone") as Button

# Row 3: Tether, Blade, Vector Run
@onready var btn_tether_ready: Button = get_node_or_null("%BtnTetherReady") as Button
@onready var btn_tether_attached: Button = get_node_or_null("%BtnTetherAttached") as Button
@onready var btn_tether_released: Button = get_node_or_null("%BtnTetherReleased") as Button
@onready var btn_blade_ready: Button = get_node_or_null("%BtnBladeReady") as Button
@onready var btn_blade_strike: Button = get_node_or_null("%BtnBladeStrike") as Button
@onready var btn_vector_run: Button = get_node_or_null("%BtnVectorRun") as Button
@onready var btn_vector_jump: Button = get_node_or_null("%BtnVectorJump") as Button

# Row 4: Mock Tools & Notifications
@onready var btn_tool_polarity: Button = get_node_or_null("%BtnToolPolarity") as Button
@onready var btn_tool_rewire: Button = get_node_or_null("%BtnToolRewire") as Button
@onready var btn_notif_breach: Button = get_node_or_null("%BtnNotifBreach") as Button
@onready var btn_notif_relay: Button = get_node_or_null("%BtnNotifRelay") as Button
@onready var btn_notif_unlocked: Button = get_node_or_null("%BtnNotifUnlocked") as Button
@onready var btn_trigger_fail: Button = get_node_or_null("%BtnTriggerFail") as Button
@onready var btn_trigger_victory: Button = get_node_or_null("%BtnTriggerVictory") as Button

# Simulation State (Kept strictly isolated in preview harness)
var current_level_id: int = 1
var current_view: String = "menu"
var simulated_score: int = 1450
var simulated_health: float = 100.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dev_layer := get_node_or_null("DevSelectorLayer")
	if dev_layer != null:
		dev_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	UIAudio.initialize_audio_service(self)

	_ensure_screen_instances()
	_setup_screen_interlinks()
	_setup_preview_selector()
	_setup_preview_tools()
	_sanitize_developer_toolbars()

	UIAudio.attach_all_buttons(self)

	_apply_level(1)
	_apply_preview_mock_state()

	# Start on MAIN MENU by default
	_switch_view("menu")


func _apply_preview_mock_state() -> void:
	if hud_instance == null:
		return
	hud_instance.set_health(simulated_health, 100.0)
	hud_instance.set_score(simulated_score)
	hud_instance.set_tether_status("READY", true)
	hud_instance.set_blade_status("READY", true)
	hud_instance.set_polarity_status("READY", true)
	hud_instance.set_rewire_status("STANDBY", false)
	hud_instance.set_vector_status("STANDBY", false)
	hud_instance.set_equipped_tool("POLARITY", "POLARITY (MOCK)", "STANDBY", UIColors.COLOR_TOOL_POLARITY)
	_update_mock_level_objectives(current_level_id, 0)


func _update_mock_level_objectives(level_id: int, step: int) -> void:
	if hud_instance == null:
		return
	match level_id:
		1:
			var steps := [
				{"obj": "DEPLOY CROSSING BRIDGE WITH TETHER", "comp": 0, "tot": 2, "hint": "TETHER anchors across gap // Pull amber latch to extend bridge"},
				{"obj": "DISABLE SECURITY CONSTRUCT", "comp": 0, "tot": 2, "hint": "Use BLADE [LMB] to strike and disable Security Construct"},
				{"obj": "F // RESTORE RELAY A & REWIRE POWER", "comp": 1, "tot": 2, "hint": "Approach cyan Relay A [F] then divert power at Rewire console [F]"},
				{"obj": "LOCKDOWN CLEARED // REACH CONTAINMENT EXIT", "comp": 2, "tot": 2, "hint": "Containment exit unlocked! Enter eastern extraction gate"},
			]
			var idx := clampi(step, 0, steps.size() - 1)
			var s: Dictionary = steps[idx]
			hud_instance.set_objective(s["obj"])
			hud_instance.set_objective_progress(s["comp"], s["tot"], "RELAYS")
			hud_instance.set_objective_hint(s["hint"])
		2:
			var steps := [
				{"obj": "Q // INVERT BOTH GRAVITY STABILIZERS", "comp": 0, "tot": 2, "hint": "Aim directly at stabilizer masses and press [Q] to invert polarity"},
				{"obj": "ONE STABILIZER ONLINE // LOCATE SECOND", "comp": 1, "tot": 2, "hint": "One stabilizer inverted! Locate second mass across the reactor deck"},
				{"obj": "GRAVITY STABLE // TETHER TO UPPER EXIT", "comp": 2, "tot": 2, "hint": "Both stabilizers online! Tether overhead or Vector Run to upper exit"},
				{"obj": "EXTRACTION GATE REACHED", "comp": 2, "tot": 2, "hint": "Upper reactor exit unlocked // Step into gateway"},
			]
			var idx := clampi(step, 0, steps.size() - 1)
			var s: Dictionary = steps[idx]
			hud_instance.set_objective(s["obj"])
			hud_instance.set_objective_progress(s["comp"], s["tot"], "STABILIZERS")
			hud_instance.set_objective_hint(s["hint"])
		3:
			var steps := [
				{"obj": "DISABLE SECURITY // F REWIRE HAZARD POWER", "comp": 0, "tot": 3, "hint": "Defeat construct with Blade // Press [F] at console to disable sweep"},
				{"obj": "F // ACTIVATE SYNC A", "comp": 1, "tot": 3, "hint": "Sweep offline! Proceed forward to Sync Terminal A [F]"},
				{"obj": "F // ACTIVATE SYNC B", "comp": 2, "tot": 3, "hint": "Sync A online! Proceed across platform to Sync Terminal B [F]"},
				{"obj": "SECTOR SYNCHRONIZED // REACH EXIT", "comp": 3, "tot": 3, "hint": "Sector synchronized! Proceed through corridor to exit gate"},
			]
			var idx := clampi(step, 0, steps.size() - 1)
			var s: Dictionary = steps[idx]
			hud_instance.set_objective(s["obj"])
			hud_instance.set_objective_progress(s["comp"], s["tot"], "SYNCS")
			hud_instance.set_objective_hint(s["hint"])
		4:
			var steps := [
				{"obj": "Q // RAISE KERNEL POWER COMPONENT", "comp": 0, "tot": 4, "hint": "Press [Q] on power component to invert mass"},
				{"obj": "F // REWIRE CORE SHIELD POWER", "comp": 1, "tot": 4, "hint": "Component raised! Use Rewire console [F] to drop core shield"},
				{"obj": "DISABLE KERNEL SECURITY // EXECUTE SHUTDOWN", "comp": 2, "tot": 4, "hint": "Strike security construct [LMB] then approach shutdown console [F]"},
				{"obj": "KERNEL OFFLINE // ENTER EXTRACTION GATE", "comp": 4, "tot": 4, "hint": "Kernel shutdown confirmed! Escape through the extraction gate"},
			]
			var idx := clampi(step, 0, steps.size() - 1)
			var s: Dictionary = steps[idx]
			hud_instance.set_objective(s["obj"])
			hud_instance.set_objective_progress(s["comp"], s["tot"], "SHUTDOWN")
			hud_instance.set_objective_hint(s["hint"])


func _ensure_screen_instances() -> void:
	if screens_container == null:
		return

	if main_menu_instance == null and main_menu_scene != null:
		main_menu_instance = main_menu_scene.instantiate() as MainMenu
		screens_container.add_child(main_menu_instance)
	if main_menu_instance != null:
		main_menu_instance.auto_load_gameplay_scene = false

	if hud_instance == null and hud_scene != null:
		hud_instance = hud_scene.instantiate() as InGameHUD
		screens_container.add_child(hud_instance)

	if pause_menu_instance == null and pause_menu_scene != null:
		pause_menu_instance = pause_menu_scene.instantiate() as PauseMenu
		screens_container.add_child(pause_menu_instance)

	if level_complete_instance == null and level_complete_scene != null:
		level_complete_instance = level_complete_scene.instantiate() as LevelComplete
		screens_container.add_child(level_complete_instance)

	if game_over_instance == null and game_over_scene != null:
		game_over_instance = game_over_scene.instantiate() as GameOver
		screens_container.add_child(game_over_instance)

	if victory_instance == null and victory_scene != null:
		victory_instance = victory_scene.instantiate() as Control
		screens_container.add_child(victory_instance)


func _setup_screen_interlinks() -> void:
	if main_menu_instance != null:
		main_menu_instance.play_requested.connect(func():
			_apply_preview_mock_state()
			_switch_view("hud")
		)

	if pause_menu_instance != null:
		pause_menu_instance.resumed.connect(func():
			_switch_view("hud")
		)
		pause_menu_instance.restarted.connect(func():
			_apply_level(current_level_id)
			_switch_view("hud")
		)
		pause_menu_instance.aborted_to_menu.connect(func():
			_switch_view("menu")
		)

	if level_complete_instance != null:
		level_complete_instance.next_level_requested.connect(func(next_id: int):
			_apply_level(next_id)
			_apply_preview_mock_state()
			_switch_view("hud")
		)
		level_complete_instance.retry_requested.connect(func(retry_id: int):
			_apply_level(retry_id)
			_apply_preview_mock_state()
			_switch_view("hud")
		)
		level_complete_instance.menu_requested.connect(func():
			_switch_view("menu")
		)

	if game_over_instance != null:
		game_over_instance.retry_requested.connect(func(retry_id: int):
			_apply_level(retry_id)
			simulated_health = 100.0
			_apply_preview_mock_state()
			_switch_view("hud")
		)
		game_over_instance.menu_requested.connect(func():
			_switch_view("menu")
		)

	if victory_instance != null:
		victory_instance.replay_requested.connect(func():
			_apply_level(1)
			simulated_health = 100.0
			_apply_preview_mock_state()
			_switch_view("hud")
		)
		victory_instance.menu_requested.connect(func():
			_switch_view("menu")
		)


func _setup_preview_selector() -> void:
	if btn_main_menu != null:
		btn_main_menu.pressed.connect(func(): _switch_view("menu"))
	if btn_hud != null:
		btn_hud.pressed.connect(func():
			_apply_preview_mock_state()
			_switch_view("hud")
		)
	if btn_pause != null:
		btn_pause.pressed.connect(func(): _switch_view("pause"))
	if btn_complete != null:
		btn_complete.pressed.connect(func(): _switch_view("complete"))
	if btn_game_over != null:
		btn_game_over.pressed.connect(func(): _switch_view("game_over"))
	if btn_victory != null:
		btn_victory.pressed.connect(func(): _switch_view("victory"))


func _sanitize_developer_toolbars() -> void:
	var dev_layer := get_node_or_null("DevSelectorLayer")
	if dev_layer == null:
		return
	dev_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_set_dev_buttons_non_focusable(dev_layer)


func _set_dev_buttons_non_focusable(node: Node) -> void:
	if node is Button:
		var btn := node as Button
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
	for child in node.get_children():
		_set_dev_buttons_non_focusable(child)


func _setup_preview_tools() -> void:
	# Level Switchers
	if btn_l1 != null:
		btn_l1.pressed.connect(func(): _apply_level(1); _update_mock_level_objectives(1, 0))
	if btn_l2 != null:
		btn_l2.pressed.connect(func(): _apply_level(2); _update_mock_level_objectives(2, 0))
	if btn_l3 != null:
		btn_l3.pressed.connect(func(): _apply_level(3); _update_mock_level_objectives(3, 0))
	if btn_l4 != null:
		btn_l4.pressed.connect(func(): _apply_level(4); _update_mock_level_objectives(4, 0))

	# Health Controls
	if btn_dmg != null:
		btn_dmg.pressed.connect(func():
			simulated_health = maxf(0.0, simulated_health - 25.0)
			if hud_instance != null:
				hud_instance.set_health(simulated_health, 100.0)
				hud_instance.show_notification("HEALTH -25 [SIM]", true, 1.0)
		)
	if btn_heal != null:
		btn_heal.pressed.connect(func():
			simulated_health = minf(100.0, simulated_health + 25.0)
			if hud_instance != null:
				hud_instance.set_health(simulated_health, 100.0)
		)
	if btn_crit_health != null:
		btn_crit_health.pressed.connect(func():
			simulated_health = 15.0
			if hud_instance != null:
				hud_instance.set_health(15.0, 100.0)
		)

	# Score
	if btn_add_score != null:
		btn_add_score.pressed.connect(func():
			simulated_score += 250
			if hud_instance != null:
				hud_instance.set_score(simulated_score)
		)

	# Objective Progress & Steps
	if btn_obj0 != null:
		btn_obj0.pressed.connect(func(): _update_mock_level_objectives(current_level_id, 0))
	if btn_obj1 != null:
		btn_obj1.pressed.connect(func(): _update_mock_level_objectives(current_level_id, 1))
	if btn_obj2 != null:
		btn_obj2.pressed.connect(func(): _update_mock_level_objectives(current_level_id, 2))
	if btn_obj3 != null:
		btn_obj3.pressed.connect(func(): _update_mock_level_objectives(current_level_id, 3))

	# Grapple Reticle States
	if btn_grapple_valid != null:
		btn_grapple_valid.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_grapple_target(true, true, "E // TETHER [HOLD]")
		)
	if btn_grapple_invalid != null:
		btn_grapple_invalid.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_grapple_target(true, false, "INVALID ANCHOR // OUT OF RANGE")
		)
	if btn_grapple_none != null:
		btn_grapple_none.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_grapple_target(false, false)
		)

	# Interaction Prompts
	if btn_prompt_interact != null:
		btn_prompt_interact.pressed.connect(func():
			if hud_instance != null:
				hud_instance.show_interaction_prompt("F // RESTORE RELAY A", true)
		)
	if btn_prompt_polarity != null:
		btn_prompt_polarity.pressed.connect(func():
			if hud_instance != null:
				hud_instance.show_interaction_prompt("Q // INVERT POLARITY", true)
		)
	if btn_target_none != null:
		btn_target_none.pressed.connect(func():
			if hud_instance != null:
				hud_instance.hide_interaction_prompt()
		)

	# Tether States
	if btn_tether_ready != null:
		btn_tether_ready.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_tether_status("READY", true)
		)
	if btn_tether_attached != null:
		btn_tether_attached.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_tether_status("ATTACHED", true)
				hud_instance.show_notification("TETHER LOCKED // BUILD MOMENTUM", false, 1.8)
		)
	if btn_tether_released != null:
		btn_tether_released.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_tether_status("RELEASED", false)
				hud_instance.show_notification("TETHER DETACHED", false, 1.0)
		)

	# Blade States
	if btn_blade_ready != null:
		btn_blade_ready.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_blade_status("READY", true)
		)
	if btn_blade_strike != null:
		btn_blade_strike.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_blade_status("STRIKE", true)
				hud_instance.show_notification("BLADE IMPACT // DAMAGE CONFIRMED", false, 1.2)
		)

	# Vector Run
	if btn_vector_run != null:
		btn_vector_run.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_vector_status("WALL-RUN", true)
				hud_instance.show_notification("VECTOR RUN ACTIVE // SPACE TO WALL-JUMP", false, 1.8)
		)
	if btn_vector_jump != null:
		btn_vector_jump.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_vector_status("WALL-JUMP", true)
				hud_instance.show_notification("VECTOR IMPULSE // MOMENTUM RETAINED", false, 1.5)
		)

	# Mock Tools
	if btn_tool_polarity != null:
		btn_tool_polarity.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_polarity_status("INVERT", true)
				hud_instance.set_equipped_tool("POLARITY", "POLARITY [Q]", "ACTIVE", UIColors.COLOR_TOOL_POLARITY)
				hud_instance.show_notification("POLARITY INVERTED // STABILIZER ALIGNED", false, 2.0)
		)
	if btn_tool_rewire != null:
		btn_tool_rewire.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_rewire_status("DIVERTED", true)
				hud_instance.set_equipped_tool("REWIRE", "REWIRE [F]", "ACTIVE", UIColors.COLOR_TOOL_REWIRE)
				hud_instance.show_notification("POWER ROUTE DIVERTED // DOOR OPENED", false, 2.0)
		)

	# Notifications
	if btn_notif_breach != null:
		btn_notif_breach.pressed.connect(func():
			if hud_instance != null:
				hud_instance.show_notification("SECURITY BREACH // SYSTEM DESYNC DETECTED", true, 3.5)
		)
	if btn_notif_relay != null:
		btn_notif_relay.pressed.connect(func():
			if hud_instance != null:
				hud_instance.show_notification("RELAY A RESTORED // LOCKDOWN RECONFIGURED", false, 3.0)
		)
	if btn_notif_unlocked != null:
		btn_notif_unlocked.pressed.connect(func():
			if hud_instance != null:
				hud_instance.show_notification("CONTAINMENT EXIT UNLOCKED // PROCEED TO EXIT", false, 3.5)
		)

	# Simulation Triggers
	if btn_trigger_fail != null:
		btn_trigger_fail.pressed.connect(func():
			_switch_view("game_over")
		)
	if btn_trigger_victory != null:
		btn_trigger_victory.pressed.connect(func():
			_switch_view("victory")
		)


func _switch_view(view_name: String) -> void:
	current_view = view_name
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Strict mutual exclusion
	if main_menu_instance != null:
		main_menu_instance.visible = (view_name == "menu")
	if hud_instance != null:
		hud_instance.visible = (view_name == "hud")
	if pause_menu_instance != null:
		pause_menu_instance.visible = (view_name == "pause")
	if level_complete_instance != null:
		level_complete_instance.visible = (view_name == "complete")
	if game_over_instance != null:
		game_over_instance.visible = (view_name == "game_over")
	if victory_instance != null:
		victory_instance.visible = (view_name == "victory")

	# Developer secondary toolbar: active in HUD view
	if dev_sub_bar != null:
		dev_sub_bar.visible = (view_name == "hud")

	# Highlight active button on top bar
	if btn_main_menu != null:
		btn_main_menu.modulate = UIColors.COLOR_CONTROLLED if view_name == "menu" else UIColors.COLOR_TEXT_PRIMARY
	if btn_hud != null:
		btn_hud.modulate = UIColors.COLOR_CONTROLLED if view_name == "hud" else UIColors.COLOR_TEXT_PRIMARY
	if btn_pause != null:
		btn_pause.modulate = UIColors.COLOR_CONTROLLED if view_name == "pause" else UIColors.COLOR_TEXT_PRIMARY
	if btn_complete != null:
		btn_complete.modulate = UIColors.COLOR_CONTROLLED if view_name == "complete" else UIColors.COLOR_TEXT_PRIMARY
	if btn_game_over != null:
		btn_game_over.modulate = UIColors.COLOR_CRITICAL if view_name == "game_over" else UIColors.COLOR_TEXT_PRIMARY
	if btn_victory != null:
		btn_victory.modulate = UIColors.COLOR_CONFIRMED if view_name == "victory" else UIColors.COLOR_TEXT_PRIMARY

	# Initialize view state
	if view_name == "menu" and main_menu_instance != null:
		var start_btn := main_menu_instance.get_node_or_null("%StartBtn") as Button
		if start_btn != null and start_btn.is_visible_in_tree():
			start_btn.grab_focus()
	elif view_name == "pause" and pause_menu_instance != null:
		pause_menu_instance.open(current_level_id)
	elif view_name == "complete" and level_complete_instance != null:
		level_complete_instance.show_completion(current_level_id, 47.23, simulated_score, false)
	elif view_name == "game_over" and game_over_instance != null:
		var reason := "CONTAINMENT BREACH // ANOMALOUS OVERFLOW" if current_level_id > 2 else "SPATIAL DISINTEGRATION"
		game_over_instance.show_game_over(current_level_id, reason, "0x%03X_SYS_HALT" % randi_range(100, 999))
	elif view_name == "victory" and victory_instance != null:
		victory_instance.show_victory(184.50, simulated_score)


func _apply_level(level_id: int) -> void:
	current_level_id = level_id
	if hud_instance != null:
		hud_instance.set_level(level_id)

	if btn_l1 != null:
		btn_l1.modulate = UIColors.COLOR_CONTROLLED if level_id == 1 else UIColors.COLOR_TEXT_PRIMARY
	if btn_l2 != null:
		btn_l2.modulate = UIColors.COLOR_CONTROLLED if level_id == 2 else UIColors.COLOR_TEXT_PRIMARY
	if btn_l3 != null:
		btn_l3.modulate = UIColors.COLOR_MAGENTA if level_id == 3 else UIColors.COLOR_TEXT_PRIMARY
	if btn_l4 != null:
		btn_l4.modulate = UIColors.COLOR_CRITICAL if level_id == 4 else UIColors.COLOR_TEXT_PRIMARY

	if current_view == "pause" and pause_menu_instance != null:
		pause_menu_instance.open(level_id)
	elif current_view == "complete" and level_complete_instance != null:
		level_complete_instance.show_completion(level_id, 47.23, simulated_score, false)
	elif current_view == "game_over" and game_over_instance != null:
		game_over_instance.show_game_over(level_id)
	elif current_view == "victory" and victory_instance != null:
		victory_instance.show_victory(184.50, simulated_score)
