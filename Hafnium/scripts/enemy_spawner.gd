extends Node2D
class_name enemy_spawner

var enemy_resource: Resource = load("res://scenes/npcs/slime.tscn")

var last_spawn_time: float = 0.0
var spawn_rate: float = 1.0
var spawn_radius: float = 100.0

func spawn(e: PackedScene) -> void:
    var spawned_enemy = e.instantiate()
    spawned_enemy.position = position + Common.a_little_offset(spawn_radius)
    get_parent().add_child(spawned_enemy)

func _process(delta):
    last_spawn_time += delta
    if last_spawn_time > spawn_rate:
        spawn(enemy_resource)
        last_spawn_time = 0.0