extends Node

const MULTIPLAYER_OVERLAY: String = "MultiplayerOverlay"

var curret_game_type: Common.GameType = Common.GameType.SINGLE_PLAYER

func main_scene_start(main_menu: Control, game_type: Common.GameType):
	var level_to_load: Node2D = load("res://scenes/main_scene.tscn").instantiate()
	var multiplayer_overlay: Control = level_to_load.get_node("UI").get_node(MULTIPLAYER_OVERLAY)
	match game_type:
		Common.GameType.SINGLE_PLAYER:
			multiplayer_overlay.visible = false
		Common.GameType.MULTIPLAYER:
			multiplayer_overlay.visible = true
	add_child(level_to_load)
	main_menu.queue_free()

func update_menu_options(main_menu: Control, new_options: Dictionary):
	# This does not work yet...
	var buttons: Array = main_menu.get_node("Buttons").get_children()
	for i in range(buttons.size()):
		buttons[i].text = new_options[new_options.keys()[i]]
		buttons[i].text = new_options[new_options.values()[i]]

func handle_game_start(main_menu: Control, game_type: Common.GameType):
	main_scene_start(main_menu, game_type)