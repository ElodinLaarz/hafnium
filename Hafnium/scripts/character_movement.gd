extends CharacterBody2D

# (ElodinLaarz): Values randomly chosen-- feel free to play around for something more fun. 
const SPEED = 400 # Speed in pixels per second.
const ACCEL = 10.0

# Crate unit vector in direction determined by currently pressed keys.
func unit_direction() -> Vector2:
	var input: Vector2
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up") # Yo, down is up?
	return input.normalized() # Do we need to handle 0 vector?

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var playerDirection: Vector2 = unit_direction() # Could pass along the body here, if ambiguous.
	
	# Smooth veolcity between current and desired velocity.
	velocity = lerp(velocity, playerDirection * SPEED, delta * ACCEL)
	
	move_and_slide()
