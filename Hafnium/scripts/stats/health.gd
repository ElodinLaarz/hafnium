class_name Health
extends Node


func bounds_ok(stats: Stats, num_hearts: int) -> bool:
	if stats.max_health % stats.health_to_damage_multiplier != 0:
		print("Max health is not a multiple of health to damage multiplier.")
		return false
	var expected_num_hearts: Variant = stats.max_health / stats.health_to_damage_multiplier
	if num_hearts != expected_num_hearts:
		print("Number of children in the heart container does not match expectation.")
		return false
	if stats.current_health > stats.max_health:
		print("Current health is greater than max health.")
		return false
	if stats.current_health < 0:
		print("Health is negative: %d, expected positive value" % stats.current_health)
		return false
	return true
