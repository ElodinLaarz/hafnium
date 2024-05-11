extends CharacterBody2D

const SPEED = 400 # Speed in pixels per second.

# Called every frame. 'delta' is the real time changed since last frame.
func _process(delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * SPEED
	
	move_and_slide()
	pass
