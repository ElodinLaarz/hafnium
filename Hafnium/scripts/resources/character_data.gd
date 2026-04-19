class_name CharacterData
extends Resource

const GameConstants = preload("res://scripts/config/game_constants.gd")

@export var id: String = ""
@export var display_name: String = ""
@export var legacy_class_name: int = -1
@export var heart_style: String = GameConstants.HEART_STYLE_DEFAULT
@export var sprite_scene: PackedScene
@export var attack_projectile_id: String = ""
@export var attack_projectile_scene: PackedScene

@export_group("Combat")
@export var attack_element: Damage.DamageType = Damage.DamageType.BASIC

@export_group("Stats")
@export var max_health: int = 10
@export var damage: int = 1
@export var speed: int = 100
@export var attack_speed: float = 1.0
@export var attack_range: int = 50
@export var projectile_speed: float = 0.0
@export var health_to_damage_multiplier: int = 2

@export_group("Resources")
@export var starting_currency: int = 0
@export var bomb_max: int = 0
@export var bomb_recovery_rate: float = 0.0
@export var mana_max: int = 0
@export var mana_recovery_rate: float = 0.0
## Wizard — extra mana capacity when injured (linear from full HP to empty).
@export var blood_mana_bonus_pool: int = 0
## Mana spent per primary spell cast when > 0 (Wizard); 0 means no mana gate on primary.
@export var primary_spell_mana_cost: int = 0


func apply_to_stats(stats: Stats) -> void:
	stats.max_health = max_health
	stats.current_health = max_health
	stats.damage = damage
	stats.attack_speed = attack_speed
	stats.attack_range = attack_range
	stats.projectile_speed = projectile_speed
	stats.health_to_damage_multiplier = health_to_damage_multiplier

	stats.resources[GameConstants.RESOURCE_BOMB] = Stats.ResourceStatus.new(
		Stats.ClassResource.BOMB, bomb_max, bomb_recovery_rate
	)
	if mana_max > 0:
		stats.resources[GameConstants.RESOURCE_MANA] = Stats.ResourceStatus.new(
			Stats.ClassResource.MANA, mana_max, mana_recovery_rate
		)
