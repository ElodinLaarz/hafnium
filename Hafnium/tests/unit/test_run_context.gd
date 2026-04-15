extends GutTest

const RUN_CONTEXT_SCRIPT = preload("res://scripts/run/run_context.gd")


func test_run_context_builds_floor_and_emits_state():
	var run_context = RUN_CONTEXT_SCRIPT.new()
	add_child_autofree(run_context)
	await wait_physics_frames(1)

	run_context.begin_run(123)

	assert_eq(run_context.floor_seed, 123)
	assert_eq(run_context.floor_graph.size(), 3, "RunContext should build a seeded floor graph")
	assert_ne(run_context.get_start_room_id(), "", "RunContext should expose a starting room id")


func test_random_offset_stays_within_requested_radius():
	var run_context = RUN_CONTEXT_SCRIPT.new()
	add_child_autofree(run_context)
	await wait_physics_frames(1)

	for _i in range(20):
		var offset = run_context.random_offset(5.0)
		assert_lte(offset.length(), 5.001, "Offsets should stay within the requested radius")
