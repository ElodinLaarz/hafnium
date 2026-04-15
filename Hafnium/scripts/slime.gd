extends "res://scripts/enemy.gd"

const RUBY_SCENE = preload("res://scenes/items/ruby.tscn")
const DEFAULT_ENEMY_ID := "enemy:slime_basic"

var slime_reward = {
	# 25% of the time, you get nothing! :(
	25: [],
	# 25% of the time, you get a ruby!
	50: [RUBY_SCENE, 1],
	# 50% of the time, you get 2 rubies!
	100: [RUBY_SCENE, 2]
}

var slime_params: Stats.EnemyStatsParams = (
	Stats
	. EnemyStatsParams
	. new(
		2,  # health
		1,  # damage
		90,  # speed
		2,  # attack_cooldown
		1,  # attack_range
	)
)

@onready var _slime_animated_sprite = $SlimeSprite


func _init():
	self.chasing_player = false
	self.player = null
	self.stats = Stats.new()
	var enemy_data = ContentRegistry.require_enemy(DEFAULT_ENEMY_ID)
	if enemy_data != null:
		apply_definition(enemy_data)
	else:
		self.stats.enemy_init(slime_params)
		self.reward = slime_reward


func _ready():
	self._animated_sprite = _slime_animated_sprite


func _on_detection_body_entered(body: CharacterBody2D):
	self.player = body
	self.chasing_player = true


func _on_detection_body_exited(body):
	if self.player == body:
		self.player = null
		self.chasing_player = false


func _on_hitbox_body_entered(body: Node2D):
	if body.has_method("is_projectile"):
		var hp: int = self.stats.current_health
		if Common.run_context != null:
			Common.run_context.resolve_projectile_hit(self, body)
		else:
			Common.projectile_resolve(self, body)
		if hp != self.stats.current_health:
			is_invincible = true
			_animated_sprite.play("damaged")
