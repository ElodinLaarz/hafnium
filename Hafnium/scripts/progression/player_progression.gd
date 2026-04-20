class_name PlayerProgression
extends RefCounted

signal xp_changed(current_xp: int, xp_for_next_level: int)
signal level_changed(new_level: int)

enum Attribute {
	CONSTITUTION,
	DEXTERITY,
	MAGIC,
	LUCK,
	WILLPOWER,
}

const ATTRIBUTE_NAMES: Dictionary = {
	Attribute.CONSTITUTION: "Constitution",
	Attribute.DEXTERITY: "Dexterity",
	Attribute.MAGIC: "Magic",
	Attribute.LUCK: "Luck",
	Attribute.WILLPOWER: "Willpower",
}

var level: int = 1
var current_xp: int = 0
var attributes: Dictionary = {}


func _init() -> void:
	for attr_key: int in _all_attribute_keys():
		attributes[attr_key] = 0


static func _all_attribute_keys() -> Array[int]:
	return [
		Attribute.CONSTITUTION,
		Attribute.DEXTERITY,
		Attribute.MAGIC,
		Attribute.LUCK,
		Attribute.WILLPOWER,
	]


func get_attribute(attribute: Attribute) -> int:
	return int(attributes.get(attribute, 0))


func increment_attribute(attribute: Attribute) -> void:
	var next: int = get_attribute(attribute) + 1
	attributes[attribute] = next


static func xp_required_to_advance_from(current_level: int) -> int:
	return 40 + maxi(current_level - 1, 0) * 25


func xp_for_next_level() -> int:
	return PlayerProgression.xp_required_to_advance_from(level)


func add_xp(amount: int) -> int:
	if amount <= 0:
		return 0
	current_xp += amount
	xp_changed.emit(current_xp, xp_for_next_level())
	var levels_gained: int = 0
	while current_xp >= xp_for_next_level():
		current_xp -= xp_for_next_level()
		level += 1
		levels_gained += 1
		level_changed.emit(level)
		xp_changed.emit(current_xp, xp_for_next_level())
	return levels_gained


static func attribute_display_name(attribute: Attribute) -> String:
	return str(ATTRIBUTE_NAMES.get(attribute, "Unknown"))


static func attribute_from_int(value: int) -> Attribute:
	var keys: Array[int] = _all_attribute_keys()
	if not keys.has(value):
		return Attribute.CONSTITUTION
	return value as Attribute


static func pick_random_attributes(count: int, rng: RandomNumberGenerator = null) -> Array[int]:
	var pool: Array[int] = _all_attribute_keys()
	if rng == null:
		pool.shuffle()
	else:
		for i: int in range(pool.size() - 1, 0, -1):
			var j: int = rng.randi_range(0, i)
			var tmp: int = pool[i]
			pool[i] = pool[j]
			pool[j] = tmp
	return pool.slice(0, mini(count, pool.size()))
