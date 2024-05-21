extends Control

signal start_game_type(object_to_free: Control, game_type: Common.GameType)
const START_GAME_TYPE: String = "start_game_type"

func _on_single_player_pressed():
	print("singleplayer enabled!")
	var signal_err: Error = emit_signal(START_GAME_TYPE, self, Common.GameType.SINGLE_PLAYER)
	print("single player signal err: %s" % signal_err)

func _on_multiplayer_pressed():
	print("multiplayer enabled!")
	var signal_err: Error = emit_signal(START_GAME_TYPE, self, Common.GameType.MULTIPLAYER)
	print("single player signal err: %s" % signal_err)

func _on_quit_pressed():
	get_tree().quit()
