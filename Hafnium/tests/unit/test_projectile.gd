extends GutTest


func test_projectile_stays_opaque_outside_warning_window() -> void:
	var projectile: Projectile = Projectile.new()
	projectile.ttl = 1.0
	projectile._ready()
	projectile.decrement_time(0.5)
	assert_almost_eq(
		projectile.modulate.a,
		1.0,
		0.001,
		"Projectile should remain fully visible before expiry warning window",
	)


func test_projectile_blinks_during_warning_window() -> void:
	var projectile: Projectile = Projectile.new()
	projectile.ttl = 1.0
	projectile._ready()
	projectile.decrement_time(0.875)  # Leaves ttl at 0.125, midpoint of 0.25 warning window.
	assert_lt(projectile.modulate.a, 1.0, "Projectile alpha should blink/fade in warning window")
	assert_gt(projectile.modulate.a, 0.15, "Mid-window alpha should remain above terminal minimum")


func test_short_lived_projectile_telegraphs_before_expiry() -> void:
	var projectile: Projectile = Projectile.new()
	projectile.ttl = 0.1
	projectile._ready()
	projectile.decrement_time(0.02)
	assert_lt(
		projectile.modulate.a,
		1.0,
		"Short-lived projectiles should also begin telegraphing before expiration",
	)


func test_projectile_telegraph_intensity_accelerates_near_expiry() -> void:
	var projectile: Projectile = Projectile.new()
	projectile.ttl = 1.0
	projectile._ready()

	projectile.ttl = 0.23
	projectile._update_expiry_telegraph()
	var early_alpha_a: float = projectile.modulate.a
	projectile.ttl = 0.22
	projectile._update_expiry_telegraph()
	var early_alpha_b: float = projectile.modulate.a
	var early_delta: float = absf(early_alpha_a - early_alpha_b)

	projectile.ttl = 0.05
	projectile._update_expiry_telegraph()
	var late_alpha_a: float = projectile.modulate.a
	projectile.ttl = 0.04
	projectile._update_expiry_telegraph()
	var late_alpha_b: float = projectile.modulate.a
	var late_delta: float = absf(late_alpha_a - late_alpha_b)

	assert_gt(
		late_delta,
		early_delta,
		"Blink/fade variation should intensify as projectile approaches expiration",
	)
