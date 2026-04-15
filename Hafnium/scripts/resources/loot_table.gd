class_name LootTable
extends Resource

@export var id: String = ""
@export var drops: Array = []
@export var nothing_weight: int = 0


func roll_drop(rng: Variant) -> Variant:
	if drops.is_empty():
		return null

	var total_weight: Variant = int(max(nothing_weight, 0))
	for drop: Variant in drops:
		total_weight += max(drop.weight, 0)

	if total_weight <= 0:
		return null

	var roll: Variant = rng.randi_range(1, total_weight)
	var cumulative: Variant = int(max(nothing_weight, 0))
	if roll <= cumulative:
		return null
	for drop: Variant in drops:
		cumulative += max(drop.weight, 0)
		if roll <= cumulative:
			return drop

	return null
