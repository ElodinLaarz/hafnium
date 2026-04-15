class_name Projectile
extends CharacterBody2D

const EXPIRY_TELEGRAPH_WINDOW: float = 0.25
const TELEGRAPH_START_MIN_ALPHA: float = 0.55
const TELEGRAPH_END_MIN_ALPHA: float = 0.03
const TELEGRAPH_START_BLINKS: float = 3.0
const TELEGRAPH_END_BLINKS: float = 12.0

@export var projectile_id: String = "weapon:fireball"

var ttl: float = 1.0  # Seconds to live.
var damage: int = 1
var damage_payload: Damage
var source_actor: Node
var source_team: int = 0
var _initial_ttl: float = 1.0
# Implement this later...
# var damage_type: DamageType = DamageType.PHYSICAL
# var damage_area: float = 1 # Other characters within this area will also take damage.


func _ready() -> void:
	_initial_ttl = max(ttl, 0.001)


func _physics_process(delta: float) -> void:
	decrement_time(delta)
	move_and_slide()


func is_projectile() -> bool:
	return true


func decrement_time(delta: float) -> void:
	ttl -= delta
	_update_expiry_telegraph()
	if ttl <= 0:
		queue_free()


func build_damage() -> Damage:
	if damage_payload != null:
		return damage_payload
	return Damage.basic(damage, source_actor, source_team)


func _update_expiry_telegraph() -> void:
	if ttl <= 0:
		return
	var warning_window: float = min(EXPIRY_TELEGRAPH_WINDOW, _initial_ttl)
	if warning_window <= 0:
		return
	if ttl > warning_window:
		modulate.a = 1.0
		return
	var progress: float = 1.0 - (ttl / warning_window)
	var intensity_curve: float = progress * progress
	var blink_cycles: float = lerpf(TELEGRAPH_START_BLINKS, TELEGRAPH_END_BLINKS, intensity_curve)
	var blink_phase: float = sin(progress * TAU * blink_cycles)
	var blink_strength: float = 0.5 * (blink_phase + 1.0)
	var min_alpha: float = lerpf(
		TELEGRAPH_START_MIN_ALPHA, TELEGRAPH_END_MIN_ALPHA, intensity_curve
	)
	modulate.a = lerpf(min_alpha, 1.0, blink_strength)
