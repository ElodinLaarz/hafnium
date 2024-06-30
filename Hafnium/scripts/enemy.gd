extends CharacterBody2D 
class_name enemy

var _animated_sprite: AnimatedSprite2D 

var movement = EnemyMovement.new()

var stats: Stats
var chasing_player: bool = false
var player: CharacterBody2D 

var is_invincible: bool = false
var invincibility_frame_timer: float = 0.0
var invincibility_frame_length: float = 0.5

# Keys are probability of the reward dropping and the value is the
# packed resource and the quantity. For convenience, the keys
# sum to 100 because I fear floats.
var reward: Dictionary = {}

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

func drop_reward() -> Array:
    # Randomly choose a reward based on probabilities of each reward.
    # Select random integer between 0 and 100 and choose the smallest
    # key greater than or equal to the random integer.
    var got_reward: Array = [] 
    var rand_int = randi_range(0, 100)
    # Sort keys -- in the future, we should sort the keys from the
    # start.
    reward.keys().sort()
    for key in reward.keys():
        if key >= rand_int:
            got_reward = reward[key]
            break
    return got_reward 

func _physics_process(delta):
    handle_movement(delta)

func handle_timers(delta: float):
    if is_invincible:
        invincibility_frame_timer += delta
        if invincibility_frame_timer >= invincibility_frame_length:
            is_invincible = false
            invincibility_frame_timer = 0.0
            _animated_sprite.play("idle")

func _process(delta: float):
    handle_timers(delta)

