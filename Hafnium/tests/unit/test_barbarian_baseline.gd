extends GutTest

const CLASS_HANDLER_SCRIPT = preload("res://scripts/classes/class_handler.gd")
const COMBAT_DIRECTOR_SCRIPT = preload("res://scripts/combat/combat_director.gd")
const PLAYER_HANDLER_SCRIPT = preload("res://scripts/singleplayer/player_handler.gd")
const PROJECTILE_SCRIPT = preload("res://scripts/projectile.gd")


func test_battle_hardened_counter_progression_and_reset() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var barbarian_class: ClassHandler.PlayerClass = ch.create_class(
		ClassHandler.ClassName.BARBARIAN
	)
	var player: PlayerCharacter = PLAYER_HANDLER_SCRIPT.new()
	player.player_class = barbarian_class
	player.stats = barbarian_class.stats

	var applied_hits: Array[int] = []
	for _i: int in range(7):
		applied_hits.append(barbarian_class.modify_incoming_damage(player, 5))

	assert_eq(
		applied_hits,
		[5, 4, 3, 2, 1, 0, 5],
		"Battle Hardened should reduce repeated 5-damage hits to 5,4,3,2,1,0,5",
	)


func test_battle_hardened_does_not_modify_non_barbarian_damage() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var wizard_class: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	var player: PlayerCharacter = PLAYER_HANDLER_SCRIPT.new()
	player.player_class = wizard_class
	player.stats = wizard_class.stats

	assert_eq(
		wizard_class.modify_incoming_damage(player, 5),
		5,
		"Non-Barbarian classes should not reduce damage"
	)
	assert_eq(
		wizard_class.battle_hardened_counter,
		0,
		"Counter should not change for non-Barbarian classes",
	)


func test_barbarian_projectile_knockback_applies_velocity() -> void:
	var director: CombatDirector = COMBAT_DIRECTOR_SCRIPT.new()
	var target: PlayerCharacter = PLAYER_HANDLER_SCRIPT.new()
	var projectile: Projectile = PROJECTILE_SCRIPT.new()
	var damage: Damage = Damage.typed(
		3, Damage.DamageType.PHYSICAL, null, 0, {"knockback_force": 180.0}
	)

	target.velocity = Vector2.ZERO
	projectile.velocity = Vector2.RIGHT * 100.0
	director._apply_knockback(target, projectile, damage)

	assert_gt(target.velocity.x, 0.0, "Knockback should push in projectile direction")
