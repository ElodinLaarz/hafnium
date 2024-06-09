extends Node
class_name Health

func bounds_ok(stats: Stats, heart_container: Node) -> bool:
	if stats.max_health % stats.health_to_damage_multiplier != 0:
		print("Max health is not a multiple of health to damage multiplier.")
		return false
	var num_hearts = stats.max_health / stats.health_to_damage_multiplier
	if heart_container.get_child_count() != num_hearts:
		print("Number of children in the heart container does not match, expecation.")
		return false
	if stats.current_health > stats.max_health:
		print("Current health is greater than max health.")
		return false
	if stats.current_health < 0:
		print("Health is negative: %d, expected positive value" % stats.current_health)
		return false
	return true

