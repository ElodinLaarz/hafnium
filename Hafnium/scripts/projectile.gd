class_name Projectile
extends CharacterBody2D

@export var projectile_id: String = "weapon:fireball"

var ttl: float = 1.0  # Seconds to live.
var damage: int = 1
var damage_payload: Damage
var source_actor: Node
var source_team: int = 0
# Implement this later...
# var damage_type: DamageType = DamageType.PHYSICAL
# var damage_area: float = 1 # Other characters within this area will also take damage.


func _physics_process(delta: float) -> void:
	decrement_time(delta)
	move_and_slide()


func is_projectile() -> bool:
	return true


func decrement_time(delta: float) -> void:
	ttl -= delta
	if ttl <= 0:
		queue_free()


func build_damage() -> Damage:
	if damage_payload != null:
		return damage_payload
	return Damage.basic(damage, source_actor, source_team)
