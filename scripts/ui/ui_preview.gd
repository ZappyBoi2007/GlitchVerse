class_name UIPreview
extends Control

## Standalone UI Preview & Development Testing Harness for GlitchVerse.
## Completely isolated from 3D gameplay, player controller, and GameFlowManager.
## Starts on MAIN MENU by default and allows instant switching between all 5 screens:
##   [ MAIN MENU ] [ HUD ] [ PAUSE ] [ LEVEL COMPLETE ] [ GAME OVER ]

# Packed Scenes for Dynamic Instantiation Fallback
@export var main_menu_scene: PackedScene = preload("res://scenes/ui/main_menu.tscn")
@export var hud_scene: PackedScene = preload("res://scenes/ui/in_game_hud.tscn")
@export var pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
@export var level_complete_scene: PackedScene = preload("res://scenes/ui/level_complete.tscn")
@export var game_over_scene: PackedScene = preload("res://scenes/ui/game_over.tscn")

# Screen Instances
@export var main_menu_instance: MainMenu
@export var hud_instance: InGameHUD
@export var pause_menu_instance: PauseMenu
@export var level_complete_instance: LevelComplete
@export var game_over_instance: GameOver

# Node holding the screens
@onready var screens_container: Control = get_node_or_null("ScreensContainer") as Control

# Developer Preview Selector Buttons (Layer 100)
@onready var btn_main_menu: Button = get_node_or_null("%BtnMainMenu") as Button
@onready var btn_hud: Button = get_node_or_null("%BtnHUD") as Button
@onready var btn_pause: Button = get_node_or_null("%BtnPause") as Button
@onready var btn_complete: Button = get_node_or_null("%BtnComplete") as Button
@onready var btn_game_over: Button = get_node_or_null("%BtnGameOver") as Button

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

# Row 2: Objective Progress & Grapple Targeting
@onready var btn_obj0: Button = get_node_or_null("%BtnObj0") as Button
@onready var btn_obj1: Button = get_node_or_null("%BtnObj1") as Button
@onready var btn_obj2: Button = get_node_or_null("%BtnObj2") as Button
@onready var btn_grapple_valid: Button = get_node_or_null("%BtnGrappleValid") as Button
@onready var btn_grapple_invalid: Button = get_node_or_null("%BtnGrappleInvalid") as Button
@onready var btn_grapple_none: Button = get_node_or_null("%BtnGrappleNone") as Button
@onready var btn_target_compat: Button = get_node_or_null("%BtnTargetCompat") as Button
@onready var btn_target_none: Button = get_node_or_null("%BtnTargetNone") as Button

# Row 3: Tether, Blade, Vector Run
@onready var btn_tether_ready: Button = get_node_or_null("%BtnTetherReady") as Button
@onready var btn_tether_attached: Button = get_node_or_null("%BtnTetherAttached") as Button
@onready var btn_tether_released: Button = get_node_or_null("%BtnTetherReleased") as Button
@onready var btn_blade_ready: Button = get_node_or_null("%BtnBladeReady") as Button
@onready var btn_blade_strike: Button = get_node_or_null("%BtnBladeStrike") as Button
@onready var btn_vector_run: Button = get_node_or_null("%BtnVectorRun") as Button

# Row 4: Mock Tools & Notifications
@onready var btn_tool_polarity: Button = get_node_or_null("%BtnToolPolarity") as Button
@onready var btn_tool_rewire: Button = get_node_or_null("%BtnToolRewire") as Button
@onready var btn_phase: Button = get_node_or_null("%BtnPhase") as Button
@onready var btn_gravity: Button = get_node_or_null("%BtnGravity") as Button
@onready var btn_freeze: Button = get_node_or_null("%BtnFreeze") as Button
@onready var btn_notif_breach: Button = get_node_or_null("%BtnNotifBreach") as Button
@onready var btn_notif_relay: Button = get_node_or_null("%BtnNotifRelay") as Button
@onready var btn_notif_unlocked: Button = get_node_or_null("%BtnNotifUnlocked") as Button

# Simulation State (Kept strictly isolated in preview harness)
var current_level_id: int = 1
var current_view: String = "menu"
var simulated_score: int = 1450
var simulated_health: float = 100.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_ensure_screen_instances()
	_setup_screen_interlinks()
	_setup_preview_selector()
	_setup_preview_tools()

	_apply_level(1)
	_apply_preview_mock_state()

	# Start on MAIN MENU by default
	_switch_view("menu")


func _apply_preview_mock_state() -> void:
	if hud_instance == null:
		return
	hud_instance.set_health(simulated_health, 100.0)
	hud_instance.set_tether_status("READY", false)
	hud_instance.set_blade_status("READY", true)
	hud_instance.set_equipped_tool("POLARITY", "POLARITY (MOCK)", "STANDBY", UIColors.COLOR_TOOL_POLARITY)
	hud_instance.set_control_hints("[E] TETHER  [F] INTERACT  [LMB] BLADE  [SHIFT] VECTOR RUN  [SPACE] JUMP")
	hud_instance.set_objective_progress(0, 2, "CIRCUITS")


func _ensure_screen_instances() -> void:
	if screens_container == null:
		screens_container = get_node_or_null("ScreensContainer") as Control
		if screens_container == null:
			screens_container = Control.new()
			screens_container.name = "ScreensContainer"
			screens_container.set_anchors_preset(PRESET_FULL_RECT)
			screens_container.grow_horizontal = GROW_DIRECTION_BOTH
			screens_container.grow_vertical = GROW_DIRECTION_BOTH
			screens_container.mouse_filter = MOUSE_FILTER_IGNORE
			add_child(screens_container)
			var dev_layer := get_node_or_null("DevSelectorLayer")
			if dev_layer != null:
				move_child(screens_container, dev_layer.get_index())

	# 1. Main Menu
	if main_menu_instance == null:
		main_menu_instance = get_node_or_null("%MainMenu") as MainMenu
		if main_menu_instance == null and screens_container != null:
			main_menu_instance = screens_container.get_node_or_null("MainMenu") as MainMenu
		if main_menu_instance == null and main_menu_scene != null:
			main_menu_instance = main_menu_scene.instantiate() as MainMenu
			if main_menu_instance != null:
				main_menu_instance.name = "MainMenu"
				main_menu_instance.unique_name_in_owner = true
				screens_container.add_child(main_menu_instance)

	# 2. In-Game HUD
	if hud_instance == null:
		hud_instance = get_node_or_null("%InGameHUD") as InGameHUD
		if hud_instance == null and screens_container != null:
			hud_instance = screens_container.get_node_or_null("InGameHUD") as InGameHUD
		if hud_instance == null and hud_scene != null:
			hud_instance = hud_scene.instantiate() as InGameHUD
			if hud_instance != null:
				hud_instance.name = "InGameHUD"
				hud_instance.unique_name_in_owner = true
				hud_instance.visible = false
				screens_container.add_child(hud_instance)

	# 3. Pause Menu
	if pause_menu_instance == null:
		pause_menu_instance = get_node_or_null("%PauseMenu") as PauseMenu
		if pause_menu_instance == null and screens_container != null:
			pause_menu_instance = screens_container.get_node_or_null("PauseMenu") as PauseMenu
		if pause_menu_instance == null and pause_menu_scene != null:
			pause_menu_instance = pause_menu_scene.instantiate() as PauseMenu
			if pause_menu_instance != null:
				pause_menu_instance.name = "PauseMenu"
				pause_menu_instance.unique_name_in_owner = true
				pause_menu_instance.visible = false
				screens_container.add_child(pause_menu_instance)

	# 4. Level Complete
	if level_complete_instance == null:
		level_complete_instance = get_node_or_null("%LevelComplete") as LevelComplete
		if level_complete_instance == null and screens_container != null:
			level_complete_instance = screens_container.get_node_or_null("LevelComplete") as LevelComplete
		if level_complete_instance == null and level_complete_scene != null:
			level_complete_instance = level_complete_scene.instantiate() as LevelComplete
			if level_complete_instance != null:
				level_complete_instance.name = "LevelComplete"
				level_complete_instance.unique_name_in_owner = true
				level_complete_instance.visible = false
				screens_container.add_child(level_complete_instance)

	# 5. Game Over
	if game_over_instance == null:
		game_over_instance = get_node_or_null("%GameOver") as GameOver
		if game_over_instance == null and screens_container != null:
			game_over_instance = screens_container.get_node_or_null("GameOver") as GameOver
		if game_over_instance == null and game_over_scene != null:
			game_over_instance = game_over_scene.instantiate() as GameOver
			if game_over_instance != null:
				game_over_instance.name = "GameOver"
				game_over_instance.unique_name_in_owner = true
				game_over_instance.visible = false
				screens_container.add_child(game_over_instance)


func _unhandled_input(event: InputEvent) -> void:
	if dev_sub_bar != null and event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		dev_sub_bar.visible = not dev_sub_bar.visible
		get_viewport().set_input_as_handled()


func _setup_preview_selector() -> void:
	if btn_main_menu != null:
		btn_main_menu.pressed.connect(func(): _switch_view("menu"))
	if btn_hud != null:
		btn_hud.pressed.connect(func(): _switch_view("hud"))
	if btn_pause != null:
		btn_pause.pressed.connect(func(): _switch_view("pause"))
	if btn_complete != null:
		btn_complete.pressed.connect(func(): _switch_view("complete"))
	if btn_game_over != null:
		btn_game_over.pressed.connect(func(): _switch_view("game_over"))


func _setup_screen_interlinks() -> void:
	if main_menu_instance != null:
		main_menu_instance.play_requested.connect(func(): _switch_view("hud"))

	if pause_menu_instance != null:
		pause_menu_instance.resumed.connect(func(): _switch_view("hud"))
		pause_menu_instance.restarted.connect(func(): _switch_view("hud"))
		pause_menu_instance.aborted_to_menu.connect(func(): _switch_view("menu"))

	if level_complete_instance != null:
		level_complete_instance.next_level_requested.connect(func(lvl: int):
			_apply_level(lvl)
			_switch_view("hud")
		)
		level_complete_instance.retry_requested.connect(func(_lvl: int): _switch_view("hud"))
		level_complete_instance.menu_requested.connect(func(): _switch_view("menu"))

	if game_over_instance != null:
		game_over_instance.retry_requested.connect(func(_lvl: int): _switch_view("hud"))
		game_over_instance.menu_requested.connect(func(): _switch_view("menu"))


func _setup_preview_tools() -> void:
	# Level buttons
	if btn_l1 != null:
		btn_l1.pressed.connect(func(): _apply_level(1))
	if btn_l2 != null:
		btn_l2.pressed.connect(func(): _apply_level(2))
	if btn_l3 != null:
		btn_l3.pressed.connect(func(): _apply_level(3))
	if btn_l4 != null:
		btn_l4.pressed.connect(func(): _apply_level(4))

	# Health simulation
	if btn_dmg != null:
		btn_dmg.pressed.connect(func():
			simulated_health = maxf(0.0, simulated_health - 25.0)
			if hud_instance != null:
				hud_instance.set_health(simulated_health, 100.0)
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
				hud_instance.set_health(simulated_health, 100.0)
		)

	# Score
	if btn_add_score != null:
		btn_add_score.pressed.connect(func():
			simulated_score += 250
			if hud_instance != null:
				hud_instance.set_score(simulated_score)
		)

	# Objective progress
	if btn_obj0 != null:
		btn_obj0.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_objective_progress(0, 2, "CIRCUITS")
		)
	if btn_obj1 != null:
		btn_obj1.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_objective_progress(1, 2, "CIRCUITS")
		)
	if btn_obj2 != null:
		btn_obj2.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_objective_progress(2, 2, "CIRCUITS")
				hud_instance.show_notification("CIRCUITS 2/2 RESTORED // EXIT READY", false)
		)

	# Grapple targeting
	if btn_grapple_valid != null:
		btn_grapple_valid.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_grapple_target(true, true, "CONDUIT ANCHOR")
		)
	if btn_grapple_invalid != null:
		btn_grapple_invalid.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_grapple_target(true, false, "OBSTRUCTED")
		)
	if btn_grapple_none != null:
		btn_grapple_none.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_grapple_target(false)
		)

	# Interaction target (legacy / general)
	if btn_target_compat != null:
		btn_target_compat.pressed.connect(func():
			var data: Dictionary = UIColors.get_level_data(current_level_id)
			if hud_instance != null:
				hud_instance.set_target_prompt(String(data.get("target_prompt", "BARRIER")), true)
		)
	if btn_target_none != null:
		btn_target_none.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_target_prompt("", false)
		)

	# Tether states
	if btn_tether_ready != null:
		btn_tether_ready.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_tether_status("READY", false)
				hud_instance.show_notification("TETHER READY", false)
		)
	if btn_tether_attached != null:
		btn_tether_attached.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_tether_status("ATTACHED", true)
				hud_instance.show_notification("TETHER ATTACHED", false)
		)
	if btn_tether_released != null:
		btn_tether_released.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_tether_status("RELEASED", false)
				hud_instance.show_notification("TETHER RELEASED", false)
		)

	# Blade states
	if btn_blade_ready != null:
		btn_blade_ready.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_blade_status("READY", true)
		)
	if btn_blade_strike != null:
		btn_blade_strike.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_blade_status("STRIKE", true)
				hud_instance.show_notification("BLADE STRIKE", false, 1.2)
		)

	# Vector Run (simulated)
	if btn_vector_run != null:
		btn_vector_run.pressed.connect(func():
			if hud_instance != null:
				hud_instance.show_notification("WALL RUN ACTIVE // MOMENTUM VECTOR", false, 2.5)
		)

	# Mock Tools & Environmental Vectors
	if btn_tool_polarity != null:
		btn_tool_polarity.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_equipped_tool("POLARITY", "POLARITY (MOCK)", "ACTIVE", UIColors.COLOR_TOOL_POLARITY)
				hud_instance.show_notification("TOOL: POLARITY [MOCK DEMO]", false)
		)
	if btn_tool_rewire != null:
		btn_tool_rewire.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_equipped_tool("REWIRE", "REWIRE (MOCK)", "ACTIVE", UIColors.COLOR_TOOL_REWIRE)
				hud_instance.show_notification("TOOL: REWIRE [MOCK DEMO]", false)
		)
	if btn_phase != null:
		btn_phase.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_ability("PHASE")
		)
	if btn_gravity != null:
		btn_gravity.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_ability("GRAVITY")
		)
	if btn_freeze != null:
		btn_freeze.pressed.connect(func():
			if hud_instance != null:
				hud_instance.set_ability("FREEZE")
		)

	# Notifications
	if btn_notif_breach != null:
		btn_notif_breach.pressed.connect(func():
			if hud_instance != null:
				hud_instance.show_notification("SECURITY BREACH // CONTAINMENT ALERT", true, 3.5)
		)
	if btn_notif_relay != null:
		btn_notif_relay.pressed.connect(func():
			if hud_instance != null:
				hud_instance.show_notification("RELAY A RESTORED // POWER ROUTE SWITCHED", false, 3.0)
		)
	if btn_notif_unlocked != null:
		btn_notif_unlocked.pressed.connect(func():
			if hud_instance != null:
				hud_instance.show_notification("EXIT UNLOCKED // PROCEED TO SECTOR EXIT", false, 3.0)
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

	# Initialize view state
	if view_name == "pause" and pause_menu_instance != null:
		pause_menu_instance.open(current_level_id)
	elif view_name == "complete" and level_complete_instance != null:
		level_complete_instance.show_completion(current_level_id, 47.23, simulated_score, false)
	elif view_name == "game_over" and game_over_instance != null:
		var reason := "CONTAINMENT BREACH // ANOMALOUS OVERFLOW" if current_level_id > 2 else "SPATIAL DISINTEGRATION"
		game_over_instance.show_game_over(current_level_id, reason, "0x%03X_SYS_HALT" % randi_range(100, 999))


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
