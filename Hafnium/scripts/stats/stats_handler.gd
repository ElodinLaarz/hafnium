extends Node
class_name Stats

# Usually the value is 2 for players since 1 damage = 1/2 heart for
# most classes.
# Exceptions to this are (1) the Barbarian for which 1 heart = 4
# points of damage, and (2) Enemies which have a 1:1 ratio.
var health_to_damage_multiplier: int = 2
var current_health: int
var max_health: int

var damage: int
var attack_range: int
var attack_speed: float

class EnemyStatsParams:
	var max_health: int
	var damage: int
	var speed: int
	var attack_speed: float
	var attack_range: int
	func _init(max_health: int, damage: int, speed: int, attack_speed: float, attack_range: int):
		self.max_health = max_health
		self.damage = damage
		self.speed = speed
		self.attack_speed = attack_speed
		self.attack_range = attack_range

enum ClassResource {
	HEALTH,
	MANA,
}

class ResourceStatus:
	var resource_type: ClassResource
	var current_resource: int
	var max_resource: int
	var recovery_progress: float
	var recovery_rate: float

	func _init(resource_type: ClassResource, max_resource: int, recovery_rate: float):
		self.resource_type = resource_type
		self.max_resource = max_resource
		self.current_resource = max_resource
		self.recovery_rate = recovery_rate
		self.recovery_progress = 0
	
	func update(delta: float):
		if current_resource < max_resource:
			recovery_progress += delta * recovery_rate
			if recovery_progress >= 1:
				current_resource += 1
				recovery_progress -= 1
		else:
			recovery_progress = 0

# Should probably have each class hold this info...
func handle_hp(pc: ClassHandler.ClassName):
	match pc:
		ClassHandler.ClassName.BARBARIAN:
			health_to_damage_multiplier = 4
			max_health = 12 
		ClassHandler.ClassName.DRUID:
			max_health = 6
		ClassHandler.ClassName.WIZARD:
			max_health = 4 
	current_health = max_health

func handle_damage(pc: ClassHandler.ClassName):
	match pc:
		ClassHandler.ClassName.BARBARIAN:
			damage = 3
			attack_range = 0
			attack_speed = 1
		ClassHandler.ClassName.DRUID:
			damage = 2
			attack_range = 1
			attack_speed = 1.2
		ClassHandler.ClassName.WIZARD:
			damage = 1
			attack_range = 2
			attack_speed = 0.8

# If damage is DOT, etc.
# func bonus_effect()

# Return if the health has reached zero.
func take_damage(d: int) -> bool:
	current_health -= d 
	if current_health < 0:
		current_health = 0
		return true
	return false

func enemy_init(params: EnemyStatsParams):
	max_health = params.max_health
	current_health = max_health

func _init(chosen_class: ClassHandler.ClassName):
	if not chosen_class:
		return
	handle_hp(chosen_class)
	handle_damage(chosen_class)
