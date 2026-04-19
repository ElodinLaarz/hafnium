extends GutTest

const CLASS_HANDLER_SCRIPT = preload("res://scripts/classes/class_handler.gd")
const GameConstants = preload("res://scripts/config/game_constants.gd")
const HEARTS_ATLAS: Texture2D = preload("res://sprites/aseprite_files/random/Hearts.png")

# test_class_handler.gd
# Tests for Hafnium/scripts/classes/class_handler.gd (class_name ClassHandler)


func test_class_stats_wizard() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	assert_eq(pc.stats.max_health, 4, "Wizard should have 4 max health")
	assert_eq(pc.stats.damage, 1, "Wizard should have 1 damage")
	assert_eq(pc.stats.resources["mana"].current_resource, 4, "Wizard should have 4 mana")


func test_class_stats_barbarian() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.BARBARIAN)
	assert_eq(pc.stats.max_health, 12, "Barbarian should have 12 max health")
	assert_eq(pc.stats.health_to_damage_multiplier, 4, "Barbarian multiplier should be 4")
	assert_eq(pc.stats.damage, 3, "Barbarian damage should be 3")


func test_get_attack_projectile_path() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var wizard_path: String = ch.get_attack_projectile_path(ClassHandler.ClassName.WIZARD)
	assert_eq(
		wizard_path, "res://scenes/weapons/bullets/fireball.tscn", "Wizard should use fireball"
	)

	var none_path: String = ch.get_attack_projectile_path(ClassHandler.ClassName.NONE)
	assert_eq(none_path, "", "None class should have no projectile path")


func test_wizard_attack_logic() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)

	# Initial attack
	var success: bool = pc.attack()
	assert_true(success, "First attack should succeed")
	assert_eq(pc.stats.resources["mana"].current_resource, 3, "Primary spell should cost 1 mana")
	assert_eq(pc.stats.attack_cooldown, pc.stats.attack_speed, "Cooldown should be set")

	# Immediate second attack
	var second_success: bool = pc.attack()
	assert_false(second_success, "Attack should fail during cooldown")


func test_has_resource_with_resource_status() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	assert_true(pc.has_resource("bomb", 1), "Wizard should have at least 1 bomb")
	assert_false(pc.has_resource("bomb", 99), "Wizard should not have 99 bombs")
	assert_false(pc.has_resource("nonexistent", 1), "Missing key should return false")


func test_use_resource_decrements_resource_status() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	var bombs_before: int = pc.stats.resources["bomb"].current_resource
	var used: bool = pc.use_resource("bomb", 1)
	assert_true(used, "use_resource should succeed when resource is available")
	assert_eq(
		pc.stats.resources["bomb"].current_resource, bombs_before - 1, "Bomb count should decrease"
	)


func test_use_resource_fails_when_insufficient() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	var used: bool = pc.use_resource("bomb", 99)
	assert_false(used, "use_resource should fail when count exceeds available")


func test_barbarian_attack_logic() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.BARBARIAN)
	assert_true(pc.attack(), "Barbarian attack should succeed with placeholder melee setup")
	assert_eq(pc.stats.attack_cooldown, pc.stats.attack_speed, "Cooldown should be set")


func test_build_attack_logic_rejects_unresolved_projectile_id() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	var data: CharacterData = CharacterData.new()
	data.attack_projectile_id = "weapon:nonexistent"
	var attack: Callable = ch.build_attack_logic(data)
	assert_false(
		attack.call(pc),
		"Attack should fail when projectile id does not resolve in ContentRegistry",
	)


func test_build_attack_logic_uses_mana_cost_from_character_data_snapshot() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var data: CharacterData = CharacterData.new()
	data.attack_projectile_id = "weapon:fireball"
	data.primary_spell_mana_cost = 2
	var attack: Callable = ch.build_attack_logic(data)
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	pc.attack_logic = attack
	pc.stats.resources["mana"].current_resource = 4
	assert_true(pc.attack(), "Mana-gated attack should succeed")
	assert_eq(
		pc.stats.resources["mana"].current_resource,
		2,
		"Callable should spend mana from build-time CharacterData, not pc.definition",
	)


func test_wizard_partial_health_empty_mana_slots_start_at_first_fully_empty_heart() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var stats: Stats = Stats.new()
	stats.max_health = 4
	stats.current_health = 1
	stats.health_to_damage_multiplier = 2
	stats.resources[GameConstants.RESOURCE_MANA] = Stats.ResourceStatus.new(
		Stats.ClassResource.MANA, 4, 0.0
	)
	stats.resources[GameConstants.RESOURCE_MANA].current_resource = 2

	var container: Node = Node.new()
	var shared_atlas: AtlasTexture = AtlasTexture.new()
	shared_atlas.atlas = HEARTS_ATLAS
	shared_atlas.region = Rect2i(0, 0, 16, 16)
	for _heart_idx: int in range(2):
		var heart: TextureRect = TextureRect.new()
		heart.texture = shared_atlas
		container.add_child(heart)

	ch.wizard_heart_drawing_logic(stats, container)

	var expected: Rect2i = ch.named_heart_lookup[ClassHandler.HeartName.WIZARD_FULL_MANA]
	var second: TextureRect = container.get_child(1) as TextureRect
	assert_true(second.texture is AtlasTexture)
	assert_eq((second.texture as AtlasTexture).region, Rect2(expected))


func test_heart_texture_unique_atlas_per_rect_when_scene_subresource_shared() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var shared: AtlasTexture = AtlasTexture.new()
	shared.atlas = HEARTS_ATLAS
	shared.region = Rect2i(0, 0, 16, 16)
	var a: TextureRect = TextureRect.new()
	var b: TextureRect = TextureRect.new()
	a.texture = shared
	b.texture = shared
	ch.heart_texture(a, ClassHandler.HeartName.EMPTY)
	ch.heart_texture(b, ClassHandler.HeartName.WIZARD_FULL)
	assert_ne(a.texture, b.texture)
	assert_ne((a.texture as AtlasTexture).region, (b.texture as AtlasTexture).region)
