extends CharacterBody2D 
class_name projectile 

var ttl: float = 1.0 # Seconds to live.
var damage: int = 1
# Implement this later...
# var damage_type: DamageType = DamageType.PHYSICAL
# var damage_area: float = 1 # Other characters within this area will also take damage. 

func is_projectile():
    pass

func decrement_time(delta):
    ttl -= delta
    if ttl <= 0:
        queue_free()

func _physics_process(delta):
    decrement_time(delta)
    move_and_slide()