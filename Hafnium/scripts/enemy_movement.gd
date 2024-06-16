extends Node
class_name EnemyMovement

@export var IDLE_SPEED: int = 0 
@export var CHASE_SPEED: int = 50 
@export var ACCEL: float = 8.0
var is_running: bool = false
var enemy_speed: int = IDLE_SPEED

func set_idle_speed():
	enemy_speed = IDLE_SPEED
	
func set_chase_speed():
	enemy_speed = CHASE_SPEED

func velocity_lerp(delta: float, v: Vector2, direction: Vector2) -> Vector2:
	return lerp(v, direction * enemy_speed, delta * ACCEL)

func get_direction(position: Vector2, player: CharacterBody2D) -> Vector2:
	if player == null:
		return Vector2(0,0)
	var unit_direction: Vector2 = player.position - position
	return unit_direction.normalized()
