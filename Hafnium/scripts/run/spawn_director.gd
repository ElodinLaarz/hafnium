class_name SpawnDirector
extends Node

var run_context


func configure(p_run_context) -> void:
	run_context = p_run_context


func spawn_enemy(enemy_id: String, spawn_parent: Node, spawn_position: Vector2):
	var enemy_data = ContentRegistry.require_enemy(enemy_id)
	if enemy_data == null or enemy_data.actor_scene == null:
		return null

	var enemy = enemy_data.actor_scene.instantiate()
	if enemy is Enemy:
		enemy.apply_definition(enemy_data)
		enemy.position = spawn_position
		spawn_parent.add_child(enemy)
		return enemy
	return null
