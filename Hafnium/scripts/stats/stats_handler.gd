class_name Stats
extends Node

signal health_changed(new_health: int, max_health: int)
signal resource_changed(resource_name: String, current_value: int, max_value: int)

enum ClassResource {
	HEALTH,
	MANA,
	BOMB,
}

# Usually the value is 2 for players since 1 damage = 1/2 heart for
# most classes.
# Exceptions to this are (1) the Barbarian for which 1 heart = 4
# points of damage, and (2) Enemies which have a 1:1 ratio.
var health_to_damage_multiplier: int = 2
var current_health: int:
	set(value):
		current_health = value
		health_changed.emit(current_health, max_health)

var max_health: int:
	set(value):
		max_health = value
		health_changed.emit(current_health, max_health)

var damage: int
var speed: int
var attack_range: int
var attack_speed: float
var projectile_speed: float

var attack_cooldown: float

var resources: Dictionary


class ResourceStatus:
	var resource_type: ClassResource
	var current_resource: int
	var max_resource: int
	var recovery_progress: float
	var recovery_rate: float

	func _init(p_resource_type: ClassResource, p_max_resource: int, p_recovery_rate: float):
		self.resource_type = p_resource_type
		self.max_resource = p_max_resource
		self.current_resource = p_max_resource
		self.recovery_rate = p_recovery_rate
		self.recovery_progress = 0

	func update(delta: float):
		if current_resource < max_resource:
			recovery_progress += delta * recovery_rate
			while recovery_progress >= 1 and current_resource < max_resource:
				current_resource += 1
				recovery_progress -= 1
		else:
			recovery_progress = 0


class EnemyStatsParams:
	var max_health: int
	var damage: int
	var speed: int
	var attack_speed: float
	var attack_range: int

	func _init(
		p_max_health: int, p_damage: int, p_speed: int, p_attack_speed: float, p_attack_range: int
	):
		self.max_health = p_max_health
		self.damage = p_damage
		self.speed = p_speed
		self.attack_speed = p_attack_speed
		self.attack_range = p_attack_range


func _init():
	current_health = 0
	max_health = 0
	damage = 0
	speed = 0
	attack_range = 0
	attack_speed = 0
	projectile_speed = 0
	attack_cooldown = 0
	resources = {
		"bomb": ResourceStatus.new(ClassResource.BOMB, 0, 0),
	}


# If damage is DOT, etc.
# func bonus_effect()


# Return if the health has reached zero. Returns false if already dead.
func take_damage(d: int) -> bool:
	if current_health <= 0:
		return false
	current_health -= d
	if current_health <= 0:
		current_health = 0
		return true
	return false


func enemy_init(params: EnemyStatsParams):
	max_health = params.max_health
	current_health = max_health
	damage = params.damage
	speed = params.speed
	attack_range = params.attack_range
	attack_speed = params.attack_speed


func update(delta: float):
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown < 0:
			attack_cooldown = 0
	for resource_name in resources.keys():
		var resource: ResourceStatus = resources[resource_name]
		var before := resource.current_resource
		resource.update(delta)
		if resource.current_resource != before:
			resource_changed.emit(resource_name, resource.current_resource, resource.max_resource)
