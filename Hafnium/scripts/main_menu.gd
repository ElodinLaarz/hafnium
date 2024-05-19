extends Control

signal start_game_type(game_type: Common.GameType)
const START_GAME_TYPE: String = "start_game_type"

func _on_single_player_pressed():
	print("singleplayer enabled!")
	emit_signal(START_GAME_TYPE, Common.GameType.SINGLE_PLAYER)

func _on_multiplayer_pressed():
	print("multiplayer enabled!")
	emit_signal(START_GAME_TYPE, Common.GameType.MULTIPLAYER)

func _on_quit_pressed():
	get_tree().quit()
