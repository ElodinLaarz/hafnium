class_name ProjectileData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var projectile_scene: PackedScene
@export var damage_type: Damage.DamageType = Damage.DamageType.BASIC
## When positive, applied as Damage.metadata knockback_force on hits from this projectile.
@export var knockback_force: float = 0.0
