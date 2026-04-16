extends Control

const LEVEL_STANDARD_RUN: String = "standard_run"
const LEVEL_STANDARD_RUN_SCENE_PATH: String = ""
const LEVEL_DPS_TRAINING: String = "dps_training"
const LEVEL_ELEMENT_TRAINING: String = "element_training"

const _TEST_SCENES: String = "res://scenes/test_scenes/"
const LEVEL_DPS_TRAINING_SCENE_PATH: String = _TEST_SCENES + "dps_training_room.tscn"
const LEVEL_ELEMENT_TRAINING_SCENE_PATH: String = _TEST_SCENES + "element_training_room.tscn"

@onready var _default_options: VBoxContainer = %DefaultOptions
@onready var _level_select: VBoxContainer = %LevelSelect
@onready var _options_menu: VBoxContainer = %OptionsMenu
@onready var _screen_shake_toggle: CheckButton = %ScreenShakeToggle


func _ready() -> void:
	if _screen_shake_toggle != null:
		_screen_shake_toggle.button_pressed = Common.player_screen_shake_enabled
	_show_default_menu()


func _on_single_player_pressed(save_file: String = "") -> void:
	if save_file == "":
		print("save file is empty, defaulting to wizard")
		save_file = "wizard"
	print("singleplayer enabled!")
	Common.start_game_type.emit(self, Common.GameType.SINGLE_PLAYER, save_file)


func _on_load_pressed() -> void:
	print("load enabled!")
	Common.start_game_type.emit(self, Common.GameType.LOAD_GAME, "")


func _on_multiplayer_pressed() -> void:
	print("multiplayer enabled!")
	Common.start_game_type.emit(self, Common.GameType.MULTIPLAYER, "")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_wizard_pressed() -> void:
	print("wizard enabled!")
	Common.start_game_type.emit(self, Common.GameType.SINGLE_PLAYER, "wizard")


func _on_druid_pressed() -> void:
	print("druid enabled!")
	Common.start_game_type.emit(self, Common.GameType.SINGLE_PLAYER, "druid")


func _on_barbarian_pressed() -> void:
	print("barbarian enabled!")
	Common.start_game_type.emit(self, Common.GameType.SINGLE_PLAYER, "barbarian")


func _on_new_game_pressed() -> void:
	_show_level_select()


func _on_level_standard_pressed() -> void:
	_start_single_player_for_level(LEVEL_STANDARD_RUN)


func _on_level_dps_pressed() -> void:
	_start_single_player_for_level(LEVEL_DPS_TRAINING)


func _on_level_element_training_pressed() -> void:
	_start_single_player_for_level(LEVEL_ELEMENT_TRAINING)


func _on_level_back_pressed() -> void:
	_show_default_menu()


func _on_options_pressed() -> void:
	_show_options_menu()


func _on_options_back_pressed() -> void:
	_show_default_menu()


func _on_screen_shake_toggled(enabled: bool) -> void:
	Common.set_player_screen_shake_enabled(enabled)


func _show_default_menu() -> void:
	if _default_options != null:
		_default_options.visible = true
	if _level_select != null:
		_level_select.visible = false
	if _options_menu != null:
		_options_menu.visible = false


func _show_level_select() -> void:
	if _default_options != null:
		_default_options.visible = false
	if _level_select != null:
		_level_select.visible = true
	if _options_menu != null:
		_options_menu.visible = false


func _show_options_menu() -> void:
	if _default_options != null:
		_default_options.visible = false
	if _level_select != null:
		_level_select.visible = false
	if _options_menu != null:
		_options_menu.visible = true


func _start_single_player_for_level(level_id: String) -> void:
	var selected_scene_path: String = LEVEL_STANDARD_RUN_SCENE_PATH
	match level_id:
		LEVEL_DPS_TRAINING:
			selected_scene_path = LEVEL_DPS_TRAINING_SCENE_PATH
		LEVEL_ELEMENT_TRAINING:
			selected_scene_path = LEVEL_ELEMENT_TRAINING_SCENE_PATH
		_:
			pass
	Common.set_next_level_scene_path(selected_scene_path)
	_on_single_player_pressed("wizard")
