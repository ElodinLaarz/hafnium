extends Control

func _on_single_player_pressed(save_file: String = ""):
    if save_file == "":
        print("save file is empty, defaulting to wizard")
        save_file = "wizard"
    print("singleplayer enabled!")
    Common.start_game_type.emit(Common.START_GAME_TYPE, self, Common.GameType.SINGLE_PLAYER, save_file)

func _on_load_pressed():
    print("load enabled!")
    Common.start_game_type.emit(self, Common.GameType.LOAD_GAME, "")

func _on_multiplayer_pressed():
    print("multiplayer enabled!")
    Common.start_game_type.emit(self, Common.GameType.MULTIPLAYER, "")

func _on_quit_pressed():
    get_tree().quit()

func _on_wizard_pressed():
    print("wizard enabled!")
    Common.start_game_type.emit(Common.START_GAME_TYPE, self, Common.GameType.SINGLE_PLAYER, "wizard")

func _on_druid_pressed():
    print("druid enabled!")
    Common.start_game_type.emit(Common.START_GAME_TYPE, self, Common.GameType.SINGLE_PLAYER, "druid")

func _on_barbarian_pressed():
    print("barbarian enabled!")
    Common.start_game_type.emit(Common.START_GAME_TYPE, self, Common.GameType.SINGLE_PLAYER, "barbarian")