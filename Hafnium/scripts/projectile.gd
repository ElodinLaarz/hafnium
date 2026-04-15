class_name Projectile
extends CharacterBody2D

var ttl: float = 1.0  # Seconds to live.
var damage: int = 1
# Implement this later...
# var damage_type: DamageType = DamageType.PHYSICAL
# var damage_area: float = 1 # Other characters within this area will also take damage.


func _physics_process(delta: float):
	decrement_time(delta)
	move_and_slide()


func is_projectile() -> bool:
	return true


func decrement_time(delta: float):
	ttl -= delta
	if ttl <= 0:
		queue_free()
