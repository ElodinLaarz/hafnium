class_name LootDirector
extends Node

var run_context


func configure(p_run_context) -> void:
	run_context = p_run_context


func spawn_drop(drop, spawn_position: Vector2) -> void:
	if (
		drop == null
		or drop.item_scene == null
		or run_context == null
		or run_context.world_root == null
	):
		return

	for _i in range(drop.count):
		var item = drop.item_scene.instantiate()
		if item is Node2D:
			item.position = spawn_position + run_context.random_offset(5.0)
		run_context.world_root.call_deferred("add_child", item)
