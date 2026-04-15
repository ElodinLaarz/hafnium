class_name EnemySpawner
extends Node2D

@export var encounter_definition_id: String = "encounter:slime_loop"

var enemy_resource: Resource = load("res://scenes/npcs/slime.tscn")
var last_spawn_time: float = 0.0
var spawn_rate: float = 1.0
var spawn_radius: float = 100.0


func _ready() -> void:
	_apply_encounter_defaults()


func _process(delta: Variant) -> void:
	last_spawn_time += delta
	if last_spawn_time > spawn_rate:
		spawn()
		last_spawn_time = 0.0


func spawn() -> void:
	var encounter: Variant = ContentRegistry.require_encounter(encounter_definition_id)
	if Common.run_context != null and encounter != null and not encounter.spawns.is_empty():
		var entry: Variant = encounter.spawns[0]
		for _i: Variant in range(max(entry.count, 1)):
			Common.run_context.spawn_enemy(
				entry.enemy_id, position + Common.a_little_offset(spawn_radius)
			)
		return

	var fallback_scene: PackedScene = enemy_resource
	var spawned_enemy: Variant = fallback_scene.instantiate()
	spawned_enemy.position = position + Common.a_little_offset(spawn_radius)
	get_parent().add_child(spawned_enemy)


func _apply_encounter_defaults() -> void:
	var encounter: Variant = ContentRegistry.require_encounter(encounter_definition_id)
	if encounter == null:
		return
	spawn_rate = encounter.spawn_rate
	spawn_radius = encounter.spawn_radius
