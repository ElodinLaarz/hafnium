extends enemy 

var slime_params: Stats.EnemyStatsParams = Stats.EnemyStatsParams.new(
10, # health
1, # damage
90, # speed
2, # attack_cooldown
1, # attack_range
)

func _init():
    self.chasing_player = false
    self.player = null
    self.stats = Stats.new()
    self.stats.enemy_init(slime_params)

func _on_detection_body_entered(body: CharacterBody2D):
    self.player = body
    self.chasing_player = true

func _on_detection_body_exited(body):
    self.player = null
    self.chasing_player = false
