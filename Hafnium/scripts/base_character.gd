class_name BaseCharacter
extends CharacterBody2D

signal damage_received(payload: Damage, remaining_health: int)
signal actor_died(actor: BaseCharacter, payload: Damage)

enum Team { NEUTRAL, PLAYER, ENEMY }

var stats: Stats
var team: Team = Team.NEUTRAL
var actor_definition_id: String = ""
var run_context: RunContext
var is_invincible: bool = false
var invincibility_frame_timer: float = 0.0
var invincibility_frame_length: float = 0.5

var _animated_sprite: AnimatedSprite2D


func _process(delta: float) -> void:
	handle_timers(delta)


func handle_timers(delta: float) -> void:
	if is_invincible:
		invincibility_frame_timer += delta
		if invincibility_frame_timer >= invincibility_frame_length:
			is_invincible = false
			invincibility_frame_timer = 0.0
			_on_invincibility_ended()


func _on_invincibility_ended() -> void:
	if _animated_sprite:
		_animated_sprite.play("idle")


func set_run_context(p_run_context: RunContext) -> void:
	run_context = p_run_context


func get_team() -> Team:
	return team


func can_receive_damage(payload: Damage) -> bool:
	return payload == null or payload.source_team != team


func receive_damage(payload: Damage) -> bool:
	if payload == null:
		return false
	var is_dead: bool = take_damage(payload.amount)
	damage_received.emit(payload, stats.current_health if stats != null else 0)
	return is_dead


func take_damage(d: int) -> bool:
	if is_invincible:
		return false

	if stats == null:
		push_error(
			(
				"BaseCharacter.take_damage() called before stats was initialized for actor_definition_id='%s'"
				% actor_definition_id
			)
		)
		return false

	if _animated_sprite:
		_animated_sprite.play("invincibility_frames")

	var is_dead: bool = stats.take_damage(d)
	if is_dead:
		die()
	elif stats.current_health > 0:
		is_invincible = true
	return is_dead


func die() -> void:
	actor_died.emit(self, Damage.basic(0, self, team))
