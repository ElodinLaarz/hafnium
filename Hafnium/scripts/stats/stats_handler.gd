extends Node
class_name Stats

# Usually the value is 2 since 1 damage = 1/2 heart for most classes.
# An exception is the Barbarian for which 1 heart = 4 points of damage.
var health_to_damage_multiplier: int = 2
var current_health: int
var max_health: int

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
func hp(pc: ClassHandler.ClassName):
	match pc:
		ClassHandler.ClassName.BARBARIAN:
			health_to_damage_multiplier = 4
			max_health = 12 
		ClassHandler.ClassName.DRUID:
			max_health = 6
		ClassHandler.ClassName.WIZARD:
			max_health = 4 
	current_health = max_health

func _init(chosen_class: ClassHandler.ClassName):
	hp(chosen_class)
	pass
