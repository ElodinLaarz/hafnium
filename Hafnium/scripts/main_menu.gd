extends Control


func _on_single_player_pressed():
	get_tree().change_scene_to_file("res://scenes/main_scene.tscn")

func _on_coming_soon_pressed():
	pass # Replace with function body.

func _on_quit_pressed():
	get_tree().quit()
