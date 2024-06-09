extends Node
class_name Stats

# Usually the value is 2 since 1 damage = 1/2 heart for most classes.
# An exception is the Barbarian for which 1 heart = 4 points of damage.
var health_to_damage_multiplier: int = 2
var current_health: int
var max_health: int

# Should probably have each class hold this info...
func hp(pc: ClassHandler.ClassName):
	match pc:
		ClassHandler.ClassName.BARBARIAN:
			health_to_damage_multiplier = 4
			max_health = 3
		ClassHandler.ClassName.DRUID:
			max_health = 3
		ClassHandler.ClassName.WIZARD:
			max_health = 2

func _init(chosen_class: ClassHandler.ClassName):
	hp(chosen_class)
	pass
