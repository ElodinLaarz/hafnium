extends GutTest

const RUN_CONTEXT_SCRIPT = preload("res://scripts/run/run_context.gd")


func test_run_context_builds_floor_and_emits_state() -> void:
	var run_context: RunContext = RUN_CONTEXT_SCRIPT.new()
	add_child_autofree(run_context)
	await wait_physics_frames(1)

	run_context.begin_run(123)

	assert_eq(run_context.floor_seed, 123)
	assert_eq(run_context.floor_graph.size(), 3, "RunContext should build a seeded floor graph")
	assert_ne(run_context.get_start_room_id(), "", "RunContext should expose a starting room id")


func test_random_offset_stays_within_requested_radius() -> void:
	var run_context: RunContext = RUN_CONTEXT_SCRIPT.new()
	add_child_autofree(run_context)
	await wait_physics_frames(1)

	for _i: int in range(20):
		var offset: Vector2 = run_context.random_offset(5.0)
		assert_lte(offset.length(), 5.001, "Offsets should stay within the requested radius")


func test_apply_hit_stop_restores_engine_time_scale() -> void:
	Engine.time_scale = 1.0
	var run_context: RunContext = RUN_CONTEXT_SCRIPT.new()
	add_child_autofree(run_context)
	await wait_physics_frames(1)

	run_context.apply_hit_stop(0.06, 0.4)
	assert_almost_eq(Engine.time_scale, 0.4, 0.0001, "Hit stop should clamp engine time scale")

	for _i: int in range(200):
		run_context._process(1.0 / 60.0)
		if Engine.time_scale >= 0.999:
			break

	assert_almost_eq(
		Engine.time_scale, 1.0, 0.001, "Hit stop should restore time scale when elapsed"
	)
	Engine.time_scale = 1.0


func test_spawn_damage_number_sets_global_position_after_parenting() -> void:
	var world: Node2D = Node2D.new()
	world.position = Vector2(40, 30)
	world.scale = Vector2(2, 2)
	add_child_autofree(world)

	var run_context: RunContext = RUN_CONTEXT_SCRIPT.new()
	add_child_autofree(run_context)
	await wait_physics_frames(1)

	run_context.world_root = world
	var target_global: Vector2 = Vector2(200, 110)
	run_context.spawn_damage_number(target_global, 7, false)

	assert_eq(world.get_child_count(), 1, "Damage number should be parented under the world root")
	var spawned: Node = world.get_child(0)
	assert_true(spawned is Node2D, "Floating damage number should be a Node2D")
	var marker: Node2D = spawned as Node2D
	assert_almost_eq(marker.global_position.x, target_global.x, 0.05)
	assert_almost_eq(marker.global_position.y, target_global.y, 0.05)
