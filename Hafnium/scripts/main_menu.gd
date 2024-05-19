extends Control

signal start_single_player(level_name)
signal start_multiplayer(level_name)

@export var class_choice: String = ""

var main_scene: Resource = preload("res://scenes/main_scene.tscn")

func _on_single_player_pressed() -> Error:
	emit_signal("start_single_player", class_choice)
	GameManager.multiplayer_enabled = false
	print("singleplayer enabled!")
	var change_scene_err: Error = get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
	return change_scene_err

func _on_multiplayer_pressed():
	GameManager.multiplayer_enabled = true
	print("multiplayer enabled!")
	var change_scene_err: Error = get_tree().change_scene_to_file("res://scenes/main_scene.tscn")
	# TODO(ElodinLaarz): Handle the error...

func _on_quit_pressed():
	get_tree().quit()
