class_name Damage
extends RefCounted

enum DamageType { BASIC, FIRE, ICE, NATURE, PHYSICAL }

var amount: int = 0
var damage_type: DamageType = DamageType.BASIC
var source: Node
var source_team: int = -1
var metadata: Dictionary = {}


func _init(
	p_amount: int = 0,
	p_damage_type: DamageType = DamageType.BASIC,
	p_source: Node = null,
	p_source_team: int = -1,
	p_metadata: Dictionary = {}
) -> void:
	amount = p_amount
	damage_type = p_damage_type
	source = p_source
	source_team = p_source_team
	metadata = p_metadata.duplicate(true)


static func basic(
	p_amount: int, p_source: Node = null, p_source_team: int = -1, p_metadata: Dictionary = {}
) -> Damage:
	return Damage.new(p_amount, DamageType.BASIC, p_source, p_source_team, p_metadata)


static func typed(
	p_amount: int,
	p_damage_type: DamageType,
	p_source: Node = null,
	p_source_team: int = -1,
	p_metadata: Dictionary = {}
) -> Damage:
	return Damage.new(p_amount, p_damage_type, p_source, p_source_team, p_metadata)


static func resolve_attack_element(
	p_projectile_data: ProjectileData, p_character: CharacterData, p_projectile_fallback: DamageType
) -> DamageType:
	if p_projectile_data != null:
		return p_projectile_data.damage_type
	if p_character != null:
		return p_character.attack_element
	return p_projectile_fallback


static func damage_type_label(t: DamageType) -> String:
	match t:
		DamageType.BASIC:
			return "BASIC"
		DamageType.FIRE:
			return "FIRE"
		DamageType.ICE:
			return "ICE"
		DamageType.NATURE:
			return "NATURE"
		DamageType.PHYSICAL:
			return "PHYSICAL"
		_:
			return "UNKNOWN"
