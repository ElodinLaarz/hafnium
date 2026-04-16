extends Node

const MULTIPLAYER_OVERLAY: String = "MultiplayerOverlay"
const RUN_CONTEXT_SCRIPT = preload("res://scripts/run/run_context.gd")
const UI_SCENE: PackedScene = preload("res://scenes/interface/ui.tscn")

const PLAYER_SPRITE_NAME: String = "PlayerSprite"

var character_select: PackedScene = load("res://scenes/character_select.tscn")

var curret_game_type: Common.GameType = Common.GameType.SINGLE_PLAYER
var active_run_context: RunContext


func _ready() -> void:
	Common.start_game_type.connect(handle_game_start)


func main_scene_start(
	menu_caller: Control, game_type: Common.GameType, player_name: String
) -> void:
	if game_type == Common.GameType.LOAD_GAME:
		var menu_to_load: Control = character_select.instantiate()
		menu_caller.queue_free()
		add_child(menu_to_load)
		return
	if player_name == "":
		print("Player name is empty, defaulting to wizard")
		player_name = "wizard"
	var selected_level_scene_path: String = Common.consume_next_level_scene_path()
	if (
		not selected_level_scene_path.is_empty()
		and _start_selected_level(menu_caller, selected_level_scene_path)
	):
		return
	_start_default_run(menu_caller, game_type, player_name)


func _start_selected_level(menu_caller: Control, level_scene_path: String) -> bool:
	var selected_level_scene: PackedScene = load(level_scene_path)
	if selected_level_scene == null:
		print("Unable to load selected level scene: %s" % level_scene_path)
		return false
	var selected_level_root: Node = selected_level_scene.instantiate()
	if selected_level_root == null:
		print("Unable to instantiate selected level scene: %s" % level_scene_path)
		return false
	add_child(selected_level_root)
	menu_caller.queue_free()
	return true


func _start_default_run(
	menu_caller: Control, game_type: Common.GameType, player_name: String
) -> void:
	active_run_context = RUN_CONTEXT_SCRIPT.new()
	add_child(active_run_context)
	Common.set_run_context(active_run_context)
	active_run_context.begin_run(Time.get_unix_time_from_system())

	var level_to_load: Node2D = active_run_context.instantiate_start_room()
	if level_to_load == null:
		print("Unable to create starting room")
		return

	active_run_context.attach_world_root(level_to_load)

	var ui: CanvasLayer = _ensure_level_ui(level_to_load)
	if ui == null:
		print("Unable to locate or create UI for level")
		return

	var multiplayer_overlay: Control = ui.get_node_or_null(MULTIPLAYER_OVERLAY)
	match game_type:
		Common.GameType.SINGLE_PLAYER:
			if multiplayer_overlay != null:
				multiplayer_overlay.visible = false
		Common.GameType.MULTIPLAYER:
			if multiplayer_overlay != null:
				multiplayer_overlay.visible = true

	if not _spawn_player_for_level(level_to_load, ui, player_name):
		return
	add_child(level_to_load)
	menu_caller.queue_free()


func _ensure_level_ui(level_to_load: Node2D) -> CanvasLayer:
	var ui: CanvasLayer = level_to_load.get_node_or_null("UI")
	if ui != null:
		return ui
	var fallback_ui: Node = UI_SCENE.instantiate()
	level_to_load.add_child(fallback_ui)
	return fallback_ui as CanvasLayer


func _spawn_player_for_level(level_to_load: Node2D, ui: CanvasLayer, player_name: String) -> bool:
	var player_character: Node2D = load("res://scenes/player_character.tscn").instantiate()
	if not (player_character is PlayerCharacter):
		print("Loaded player is not a PlayerCharacter")
		return false
	if !player_character.load_player_data(player_name):
		print("Unable to load player character: %s" % player_name)
		return false
	var player_class: ClassHandler.PlayerClass = Common.player_class
	if player_class == null or player_class.definition == null:
		print("Player class definition missing for %s" % player_name)
		return false
	if player_class.definition.sprite_scene == null:
		print("Player sprite scene missing for %s" % player_name)
		return false
	var player_sprite_scene: PackedScene = player_class.definition.sprite_scene
	var player_sprite: AnimatedSprite2D = player_sprite_scene.instantiate()
	player_sprite.name = PLAYER_SPRITE_NAME  # For reference by other scripts.
	player_character.add_child(player_sprite)
	level_to_load.add_child(player_character)
	active_run_context.register_player(player_character)
	# Load data about player.
	# Draw UI and attach.
	if ui.get_node_or_null("Interface") == null:
		var interface_to_draw: Control = load("res://scenes/interface/interface.tscn").instantiate()
		ui.add_child(interface_to_draw)
	return true


func update_menu_options(main_menu: Control, new_options: Dictionary) -> void:
	# This does not work yet...
	var buttons: Array = main_menu.get_node("Buttons").get_children()
	for i: int in range(buttons.size()):
		buttons[i].text = new_options[new_options.keys()[i]]
		buttons[i].text = new_options[new_options.values()[i]]


func handle_game_start(main_menu: Control, game_type: Common.GameType, player_name: String) -> void:
	print("Game start: %s" % game_type)
	main_scene_start(main_menu, game_type, player_name)
