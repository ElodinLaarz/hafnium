class_name LootDirector
extends Node

const LOOT_SCATTER_RADIUS: float = 5.0

var run_context: RunContext


func configure(p_run_context: RunContext) -> void:
	run_context = p_run_context


func spawn_drop(drop: LootDropData, spawn_position: Vector2) -> void:
	if drop == null or drop.item_scene == null or run_context == null:
		return
	var entity_root: Node = run_context.get_world_entity_root()
	if entity_root == null:
		return

	for _i: int in range(drop.count):
		var item: Node = drop.item_scene.instantiate()
		if item is Node2D:
			item.position = spawn_position + run_context.random_offset(LOOT_SCATTER_RADIUS)
		entity_root.call_deferred("add_child", item)
