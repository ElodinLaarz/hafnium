extends Control


func _on_wizard_pressed() -> void:
	print("wizard enabled!")
	Common.start_game_type.emit(self, Common.GameType.SINGLE_PLAYER, "wizard")


func _on_druid_pressed() -> void:
	print("druid enabled!")
	Common.start_game_type.emit(self, Common.GameType.SINGLE_PLAYER, "druid")


func _on_barbarian_pressed() -> void:
	print("barbarian enabled!")
	Common.start_game_type.emit(self, Common.GameType.SINGLE_PLAYER, "barbarian")


func _on_character_select_back_pressed() -> void:
	var switcher: Node = get_parent()
	if switcher != null and switcher.has_method("return_from_character_select"):
		switcher.return_from_character_select(self)
