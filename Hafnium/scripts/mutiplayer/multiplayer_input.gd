extends MultiplayerSynchronizer

var input_direction: Vector2 = Vector2(0, 0)

func _ready():
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)

# Create unit vector in direction determined by currently pressed keys.
func unit_direction() -> Vector2:
	var input: Vector2
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up") # Yo, down is up?
	return input.normalized() # Do we need to handle 0 vector?

func _physics_process(delta):
	# Update input direction.
	input_direction = unit_direction()
