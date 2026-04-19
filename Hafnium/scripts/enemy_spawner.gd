class_name EnemySpawner
extends Node2D

const DEFAULT_SPAWN_RATE: float = 1.0
const DEFAULT_SPAWN_RADIUS: float = 100.0
const PRIMARY_ENCOUNTER_ENTRY_INDEX: int = 0
const MIN_ENEMY_COUNT: int = 1

@export var encounter_definition_id: String = "encounter:slime_loop"

var enemy_resource: Resource = load("res://scenes/npcs/slime.tscn")
var last_spawn_time: float = 0.0
var spawn_rate: float = DEFAULT_SPAWN_RATE
var spawn_radius: float = DEFAULT_SPAWN_RADIUS


func _ready() -> void:
	_apply_encounter_defaults()


func _process(delta: float) -> void:
	last_spawn_time += delta
	if last_spawn_time > spawn_rate:
		spawn()
		last_spawn_time = 0.0


func spawn() -> void:
	var encounter: EncounterData = ContentRegistry.require_encounter(encounter_definition_id)
	if Common.run_context != null and encounter != null and not encounter.spawns.is_empty():
		var entry: EncounterSpawnData = encounter.spawns[PRIMARY_ENCOUNTER_ENTRY_INDEX]
		for _i: int in range(max(entry.count, MIN_ENEMY_COUNT)):
			Common.run_context.spawn_enemy(
				entry.enemy_id, position + Common.a_little_offset(spawn_radius)
			)
		return

	var fallback_scene: PackedScene = enemy_resource
	var spawned_enemy: Node2D = fallback_scene.instantiate()
	spawned_enemy.position = position + Common.a_little_offset(spawn_radius)
	get_parent().add_child(spawned_enemy)


func _apply_encounter_defaults() -> void:
	var encounter: EncounterData = ContentRegistry.require_encounter(encounter_definition_id)
	if encounter == null:
		return
	spawn_rate = encounter.spawn_rate
	spawn_radius = encounter.spawn_radius
