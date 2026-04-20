class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var actor_scene: PackedScene
@export var max_health: int = 1
@export var damage: int = 1
@export var speed: int = 50
@export var attack_speed: float = 1.0
@export var attack_range: int = 1
@export var experience_reward: int = 10
@export var loot_table: Resource


func build_stats() -> Stats.EnemyStatsParams:
	return Stats.EnemyStatsParams.new(max_health, damage, speed, attack_speed, attack_range)
