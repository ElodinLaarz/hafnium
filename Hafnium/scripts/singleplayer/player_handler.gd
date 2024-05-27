extends CharacterBody2D

const Movement = preload("res://scripts/singleplayer/movement.gd")
var movement = Movement.new()

const Aim = preload("res://scripts/singleplayer/player_aim.gd")
var aim = Aim.new()

func ready_aim():
	aim.aim_sight = get_node("AnimatedSprite2D/PlayerPivot/Aim Sight")
	aim.pivot = get_node("AnimatedSprite2D/PlayerPivot")
	aim.camera = get_node("Main Camera")

func handle_movement(delta: float):
	movement.set_max_speed_walk() # Default to walking, unless running.
	if movement.check_is_running(delta, velocity.length()):
		movement.set_max_speed_run()

	var player_direction: Vector2 = movement.unit_direction() # Could pass along the body here, if ambiguous.	
	# Smooth veolcity between current and desired velocity.
	velocity = movement.velocity_lerp(delta, velocity, player_direction)
	
	move_and_slide()


func handle_attack(delta: float):
	aim.update_pivot(delta)
	if Input.is_action_just_pressed("attack"):
		print("attack!")

func _ready():
	ready_aim()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	handle_movement(delta)
	handle_attack(delta)
