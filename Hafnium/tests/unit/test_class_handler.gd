extends GutTest

const CLASS_HANDLER_SCRIPT = preload("res://scripts/classes/class_handler.gd")

# test_class_handler.gd
# Tests for Hafnium/scripts/classes/class_handler.gd (class_name ClassHandler)


func test_class_stats_wizard():
	var ch = CLASS_HANDLER_SCRIPT.new()
	var pc = ch.create_class(ClassHandler.ClassName.WIZARD)
	assert_eq(pc.stats.max_health, 4, "Wizard should have 4 max health")
	assert_eq(pc.stats.damage, 1, "Wizard should have 1 damage")
	assert_eq(pc.stats.resources["mana"].current_resource, 4, "Wizard should have 4 mana")


func test_class_stats_barbarian():
	var ch = CLASS_HANDLER_SCRIPT.new()
	var pc = ch.create_class(ClassHandler.ClassName.BARBARIAN)
	assert_eq(pc.stats.max_health, 12, "Barbarian should have 12 max health")
	assert_eq(pc.stats.health_to_damage_multiplier, 4, "Barbarian multiplier should be 4")
	assert_eq(pc.stats.damage, 3, "Barbarian damage should be 3")


func test_get_attack_projectile_path():
	var ch = CLASS_HANDLER_SCRIPT.new()
	var wizard_path = ch.get_attack_projectile_path(ClassHandler.ClassName.WIZARD)
	assert_eq(
		wizard_path, "res://scenes/weapons/bullets/fireball.tscn", "Wizard should use fireball"
	)

	var none_path = ch.get_attack_projectile_path(ClassHandler.ClassName.NONE)
	assert_eq(none_path, "", "None class should have no projectile path")


func test_wizard_attack_logic():
	var ch = CLASS_HANDLER_SCRIPT.new()
	var pc = ch.create_class(ClassHandler.ClassName.WIZARD)

	# Initial attack
	var success = pc.attack()
	assert_true(success, "First attack should succeed")
	assert_eq(pc.stats.attack_cooldown, pc.stats.attack_speed, "Cooldown should be set")

	# Immediate second attack
	var second_success = pc.attack()
	assert_false(second_success, "Attack should fail during cooldown")


func test_has_resource_with_resource_status():
	var ch = CLASS_HANDLER_SCRIPT.new()
	var pc = ch.create_class(ClassHandler.ClassName.WIZARD)
	assert_true(pc.has_resource("bomb", 1), "Wizard should have at least 1 bomb")
	assert_false(pc.has_resource("bomb", 99), "Wizard should not have 99 bombs")
	assert_false(pc.has_resource("nonexistent", 1), "Missing key should return false")


func test_use_resource_decrements_resource_status():
	var ch = CLASS_HANDLER_SCRIPT.new()
	var pc = ch.create_class(ClassHandler.ClassName.WIZARD)
	var bombs_before = pc.stats.resources["bomb"].current_resource
	var used = pc.use_resource("bomb", 1)
	assert_true(used, "use_resource should succeed when resource is available")
	assert_eq(
		pc.stats.resources["bomb"].current_resource, bombs_before - 1, "Bomb count should decrease"
	)


func test_use_resource_fails_when_insufficient():
	var ch = CLASS_HANDLER_SCRIPT.new()
	var pc = ch.create_class(ClassHandler.ClassName.WIZARD)
	var used = pc.use_resource("bomb", 99)
	assert_false(used, "use_resource should fail when count exceeds available")


func test_barbarian_druid_attack_unimplemented():
	var ch = CLASS_HANDLER_SCRIPT.new()
	for cn in [ClassHandler.ClassName.BARBARIAN, ClassHandler.ClassName.DRUID]:
		var pc = ch.create_class(cn)
		assert_false(
			pc.attack(),
			"%s attack should return false until implemented" % ClassHandler.ClassName.keys()[cn]
		)
