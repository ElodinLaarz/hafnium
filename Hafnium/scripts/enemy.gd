extends CharacterBody2D 
class_name enemy

var movement = EnemyMovement.new()

var stats: Stats
var chasing_player: bool = false
var player: CharacterBody2D 

# A function to identify this as an enemy.
func is_enemy():
	pass

func handle_movement(delta: float):
	if chasing_player:
		movement.set_chase_speed()
	else:
		movement.set_idle_speed()
	var direction: Vector2 = movement.get_direction(position, player)
	# Smooth velocity between current and desired velocity.
	velocity = movement.velocity_lerp(delta, velocity, direction)
	move_and_slide()

func _physics_process(delta):
	handle_movement(delta)
