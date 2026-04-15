extends Control


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
