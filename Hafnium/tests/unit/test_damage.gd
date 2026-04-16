extends GutTest


func test_resolve_attack_element_prefers_projectile_data() -> void:
	var pdata: ProjectileData = ProjectileData.new()
	pdata.damage_type = Damage.DamageType.FIRE
	var cdata: CharacterData = CharacterData.new()
	cdata.attack_element = Damage.DamageType.PHYSICAL
	assert_eq(
		Damage.resolve_attack_element(pdata, cdata, Damage.DamageType.BASIC),
		Damage.DamageType.FIRE,
		"Registry projectile should define the hit element when present",
	)


func test_resolve_attack_element_falls_back_to_character() -> void:
	var cdata: CharacterData = CharacterData.new()
	cdata.attack_element = Damage.DamageType.NATURE
	assert_eq(
		Damage.resolve_attack_element(null, cdata, Damage.DamageType.BASIC),
		Damage.DamageType.NATURE,
		"Character data should supply the element when no projectile resource is used",
	)


func test_resolve_attack_element_uses_projectile_scene_fallback() -> void:
	assert_eq(
		Damage.resolve_attack_element(null, null, Damage.DamageType.ICE),
		Damage.DamageType.ICE,
		"Projectile scene export should be used when no character or registry row applies",
	)


func test_typed_payload_carries_damage_type() -> void:
	var d: Damage = Damage.typed(5, Damage.DamageType.PHYSICAL, null, -1, {})
	assert_eq(d.damage_type, Damage.DamageType.PHYSICAL)
	assert_eq(d.amount, 5)


func test_damage_type_label_covers_enum() -> void:
	assert_eq(Damage.damage_type_label(Damage.DamageType.FIRE), "FIRE")
	assert_eq(Damage.damage_type_label(Damage.DamageType.ICE), "ICE")
