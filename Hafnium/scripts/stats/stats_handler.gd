extends Node
class_name Stats

const CH = preload("res://scripts/classes/class_handler.gd")

# Usually the value is 2 since 1 damage = 1/2 heart for most classes.
# An exception is the Barbarian for which 1 heart = 4 points of damage.
var health_to_damage_multiplier: int = 2
var health: int

func hp(pc: CH.PlayerClass):
	match pc:
		CH.PlayerClass.BARBARIAN:
			health_to_damage_multiplier = 4
			health = 3
		CH.PlayerClass.DRUID:
			health = 3
		CH.PlayerClass.WIZARD:
			health = 2

func _init(chosen_class: CH.PlayerClass):
	
	pass
