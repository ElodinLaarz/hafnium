extends Node2D

func spawn(e: PackedScene) -> void:
	var enemy = e.instance()
	add_child(enemy)
