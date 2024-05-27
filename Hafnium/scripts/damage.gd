class_name Damage extends Node

enum DamageType {BASIC, FIRE}

var damage_type: DamageType
var damage_generator: Callable 

func basic_damage(min_damage: int, max_damage: int) -> Callable:
	var rng = RandomNumberGenerator.new()
	return func(): return rng.randi_range(min_damage, max_damage)

func _init(dt: DamageType, dg: Callable):
	self.damage_type = dt 
	self.damage_generator = dg 

func get_damage() -> int:
	if not damage_generator:
		print("No damage generator set for this damage object")
		return 0
	return damage_generator.call()
