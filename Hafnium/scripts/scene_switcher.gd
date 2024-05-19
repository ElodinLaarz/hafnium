extends Node

@onready var current_level = $MainMenu
const MULTIPLAYER_OVERLAY: String = "MultiplayerOverlay"

var curret_game_type: Common.GameType = Common.GameType.SINGLE_PLAYER

func handle_level_changed(game_type: Common.GameType):
	var level_to_load: Node2D = load("res://scenes/main_scene.tscn").instantiate()
	var multiplayer_overlay: Control = level_to_load.get_node(MULTIPLAYER_OVERLAY)
	match game_type:
		Common.GameType.SINGLE_PLAYER:
			multiplayer_overlay.visible = false
		Common.GameType.MULTIPLAYER:
			multiplayer_overlay.visible = true
	add_child(level_to_load)
	current_level.queue_free()
	current_level = level_to_load
