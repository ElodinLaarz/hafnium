class_name EnemyMovement
extends Node

@export var idle_speed: int = 0
@export var chase_speed: int = 50
@export var accel: float = 8.0

var is_running: bool = false
var enemy_speed: int = idle_speed


func set_idle_speed() -> void:
	enemy_speed = idle_speed


func set_chase_speed() -> void:
	enemy_speed = chase_speed


func velocity_lerp(delta: float, v: Vector2, direction: Vector2) -> Vector2:
	return lerp(v, direction * enemy_speed, delta * accel)


func get_direction(position: Vector2, player: CharacterBody2D) -> Vector2:
	if player == null:
		return Vector2(0, 0)
	var unit_direction: Vector2 = player.position - position
	return unit_direction.normalized()
