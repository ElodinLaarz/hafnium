extends GutTest

# test_player_progression.gd


func test_xp_required_to_advance_from_matches_formula() -> void:
	assert_eq(PlayerProgression.xp_required_to_advance_from(1), 40)
	assert_eq(PlayerProgression.xp_required_to_advance_from(2), 65)
	assert_eq(PlayerProgression.xp_required_to_advance_from(10), 40 + 9 * 25)


func test_add_xp_zero_returns_zero_and_no_level_change() -> void:
	var p: PlayerProgression = PlayerProgression.new()
	assert_eq(p.add_xp(0), 0)
	assert_eq(p.level, 1)
	assert_eq(p.current_xp, 0)


func test_add_xp_levels_up_once() -> void:
	var p: PlayerProgression = PlayerProgression.new()
	var gained: int = p.add_xp(40)
	assert_eq(gained, 1)
	assert_eq(p.level, 2)
	assert_eq(p.current_xp, 0)


func test_add_xp_multi_level_carryover() -> void:
	var p: PlayerProgression = PlayerProgression.new()
	var gained: int = p.add_xp(120)
	assert_eq(gained, 2)
	assert_eq(p.level, 3)
	assert_eq(p.current_xp, 15)


func test_pick_random_attributes_caps_at_pool_size() -> void:
	var picks: Array[int] = PlayerProgression.pick_random_attributes(10)
	assert_eq(picks.size(), 5)
	var seen: Dictionary = {}
	for v: int in picks:
		assert_false(seen.has(v), "Choices should be unique")
		seen[v] = true


func test_attribute_from_int_defaults_out_of_range() -> void:
	assert_eq(
		PlayerProgression.attribute_from_int(-1),
		PlayerProgression.Attribute.CONSTITUTION,
	)
	assert_eq(
		PlayerProgression.attribute_from_int(99),
		PlayerProgression.Attribute.CONSTITUTION,
	)


func test_attribute_from_int_preserves_known_values() -> void:
	assert_eq(
		PlayerProgression.attribute_from_int(PlayerProgression.Attribute.MAGIC),
		PlayerProgression.Attribute.MAGIC,
	)
