extends Node
class_name Health

func bounds_ok(stats: Stats) -> bool:
	if stats.current_health > stats.max_health:
		return false
	if stats.current_health < 0:
		return false
	return true

