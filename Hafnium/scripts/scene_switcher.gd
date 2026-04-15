extends Node

const MULTIPLAYER_OVERLAY: String = "MultiplayerOverlay"
const RUN_CONTEXT_SCRIPT = preload("res://scripts/run/run_context.gd")

const PLAYER_SPRITE_NAME: String = "PlayerSprite"

var character_select = load("res://scenes/character_select.tscn")

var curret_game_type: Common.GameType = Common.GameType.SINGLE_PLAYER
var active_run_context


func _ready():
	Common.start_game_type.connect(handle_game_start)


func main_scene_start(menu_caller: Control, game_type: Common.GameType, player_name: String):
	if game_type == Common.GameType.LOAD_GAME:
		var menu_to_load: Control = character_select.instantiate()
		menu_caller.queue_free()
		add_child(menu_to_load)
		return
	if player_name == "":
		print("Player name is empty, defaulting to wizard")
		player_name = "wizard"

	active_run_context = RUN_CONTEXT_SCRIPT.new()
	add_child(active_run_context)
	Common.set_run_context(active_run_context)
	active_run_context.begin_run(Time.get_unix_time_from_system())

	var level_to_load: Node2D = active_run_context.instantiate_start_room()
	if level_to_load == null:
		print("Unable to create starting room")
		return

	active_run_context.attach_world_root(level_to_load)

	var ui: CanvasLayer = level_to_load.get_node("UI")
	var multiplayer_overlay: Control = ui.get_node(MULTIPLAYER_OVERLAY)
	match game_type:
		Common.GameType.SINGLE_PLAYER:
			multiplayer_overlay.visible = false
		Common.GameType.MULTIPLAYER:
			multiplayer_overlay.visible = true

	var player_character: Node2D = load("res://scenes/player_character.tscn").instantiate()
	if not (player_character is PlayerCharacter):
		print("Loaded player is not a PlayerCharacter")
		return
	if !player_character.load_player_data(player_name):
		print("Unable to load player character: %s" % player_name)
		return
	var player_class: ClassHandler.PlayerClass = Common.player_class
	if player_class == null or player_class.definition == null:
		print("Player class definition missing for %s" % player_name)
		return
	if player_class.definition.sprite_scene == null:
		print("Player sprite scene missing for %s" % player_name)
		return
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
	add_child(level_to_load)
	menu_caller.queue_free()


func update_menu_options(main_menu: Control, new_options: Dictionary):
	# This does not work yet...
	var buttons: Array = main_menu.get_node("Buttons").get_children()
	for i in range(buttons.size()):
		buttons[i].text = new_options[new_options.keys()[i]]
		buttons[i].text = new_options[new_options.values()[i]]


func handle_game_start(main_menu: Control, game_type: Common.GameType, player_name: String):
	print("Game start: %s" % game_type)
	main_scene_start(main_menu, game_type, player_name)
