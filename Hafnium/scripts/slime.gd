extends enemy 

@onready var _slime_animated_sprite = $SlimeSprite

var slime_reward = {
    # 50% of the time, you get a ruby!
    50: [load("res://scenes/items/Ruby.tscn"), 1],
    # 50% of the time, you get 2 rubies!
    100: [load("res://scenes/items/Ruby.tscn"), 2]
};

var slime_params: Stats.EnemyStatsParams = Stats.EnemyStatsParams.new(
2, # health
1, # damage
90, # speed
2, # attack_cooldown
1, # attack_range
)

func _ready():
    self._animated_sprite = _slime_animated_sprite

func _init():
    self.chasing_player = false
    self.player = null
    self.stats = Stats.new()
    self.stats.enemy_init(slime_params)
    self.reward = slime_reward

func _on_detection_body_entered(body: CharacterBody2D):
    self.player = body
    self.chasing_player = true

func _on_detection_body_exited(body):
    self.player = null
    self.chasing_player = false

func _on_hitbox_body_entered(body:Node2D):
    if body.has_method("is_projectile"):
        var hp: int = self.stats.current_health
        Common.projectile_resolve(self, body)
        if hp != self.stats.current_health:
            is_invincible = true
            _animated_sprite.play("damaged")
