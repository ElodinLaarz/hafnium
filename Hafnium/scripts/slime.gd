extends "res://scripts/enemy.gd"

const GameConstants = preload("res://scripts/config/game_constants.gd")
const RUBY_SCENE: PackedScene = preload("res://scenes/items/ruby.tscn")
const DEFAULT_ENEMY_ID: String = GameConstants.ENEMY_ID_SLIME_BASIC

const DEFAULT_SLIME_HEALTH: int = 2
const DEFAULT_SLIME_DAMAGE: int = 1
const DEFAULT_SLIME_SPEED: int = 90
const DEFAULT_SLIME_ATTACK_COOLDOWN: int = 2
const DEFAULT_SLIME_ATTACK_RANGE: int = 1

const REWARD_THRESHOLD_NO_DROP: int = 25
const REWARD_THRESHOLD_SINGLE_DROP: int = 50
const REWARD_THRESHOLD_DOUBLE_DROP: int = 100
const SINGLE_RUBY_DROP_COUNT: int = 1
const DOUBLE_RUBY_DROP_COUNT: int = 2

var slime_reward: Dictionary = {
	# 25% of the time, you get nothing! :(
	REWARD_THRESHOLD_NO_DROP: [],
	# 25% of the time, you get a ruby!
	REWARD_THRESHOLD_SINGLE_DROP: [RUBY_SCENE, SINGLE_RUBY_DROP_COUNT],
	# 50% of the time, you get 2 rubies!
	REWARD_THRESHOLD_DOUBLE_DROP: [RUBY_SCENE, DOUBLE_RUBY_DROP_COUNT]
}

var slime_params: Stats.EnemyStatsParams = (
	Stats
	. EnemyStatsParams
	. new(
		DEFAULT_SLIME_HEALTH,  # health
		DEFAULT_SLIME_DAMAGE,  # damage
		DEFAULT_SLIME_SPEED,  # speed
		DEFAULT_SLIME_ATTACK_COOLDOWN,  # attack_cooldown
		DEFAULT_SLIME_ATTACK_RANGE,  # attack_range
	)
)

@onready var _slime_animated_sprite: AnimatedSprite2D = $SlimeSprite


func _init() -> void:
	self.chasing_player = false
	self.player = null
	self.stats = Stats.new()
	var enemy_data: EnemyData = ContentRegistry.require_enemy(DEFAULT_ENEMY_ID)
	if enemy_data != null:
		apply_definition(enemy_data)
	else:
		self.stats.enemy_init(slime_params)
		self.reward = slime_reward


func _ready() -> void:
	self._animated_sprite = _slime_animated_sprite


func _on_detection_body_entered(body: CharacterBody2D) -> void:
	self.player = body
	self.chasing_player = true


func _on_detection_body_exited(body: CharacterBody2D) -> void:
	if self.player == body:
		self.player = null
		self.chasing_player = false


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("is_projectile"):
		var hp: int = self.stats.current_health
		if Common.run_context == null:
			push_error(
				"Projectile hit on slime requires Common.run_context (CombatDirector pipeline)."
			)
			return
		Common.run_context.resolve_projectile_hit(self, body)
		if hp != self.stats.current_health:
			is_invincible = true
			_animated_sprite.play("damaged")
