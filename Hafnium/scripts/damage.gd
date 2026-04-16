class_name Damage
extends RefCounted

enum DamageType { BASIC, FIRE }

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
