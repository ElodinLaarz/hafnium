extends GutTest

const PLAYER_HANDLER_SCRIPT = preload("res://scripts/singleplayer/player_handler.gd")
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


func test_level_up_first_enqueue_pauses_tree_and_emits_choice() -> void:
	var run_context: RunContext = RUN_CONTEXT_SCRIPT.new()
	add_child_autofree(run_context)
	await wait_physics_frames(1)

	var emitted: Array = []
	run_context.level_up_choice_required.connect(
		func(_p: PlayerCharacter, choices: Array[int]) -> void: emitted.append(choices)
	)

	var tree: SceneTree = run_context.get_tree()
	tree.paused = false
	var player: PlayerCharacter = PLAYER_HANDLER_SCRIPT.new()
	assert_true(player.progression != null)

	run_context.enqueue_level_up_choice(player)
	assert_true(tree.paused, "First level-up choice should pause the scene tree")
	assert_eq(emitted.size(), 1, "Overlay flow should emit attribute choices once")
	assert_eq(
		emitted[0].size(),
		3,
		"Level-up choices should match GameConstants.LEVEL_UP_CHOICE_COUNT",
	)


func test_level_up_resolve_unpauses_when_queue_empty() -> void:
	var run_context: RunContext = RUN_CONTEXT_SCRIPT.new()
	add_child_autofree(run_context)
	await wait_physics_frames(1)

	var tree: SceneTree = run_context.get_tree()
	tree.paused = false
	var player: PlayerCharacter = PLAYER_HANDLER_SCRIPT.new()

	run_context.enqueue_level_up_choice(player)
	assert_true(tree.paused)

	run_context.resolve_level_up_choice(player, PlayerProgression.Attribute.CONSTITUTION)
	assert_false(tree.paused, "Resolving the only queued choice should unpause the tree")


func test_level_up_queue_stays_paused_until_last_resolve() -> void:
	var run_context: RunContext = RUN_CONTEXT_SCRIPT.new()
	add_child_autofree(run_context)
	await wait_physics_frames(1)

	var tree: SceneTree = run_context.get_tree()
	tree.paused = false
	var p1: PlayerCharacter = PLAYER_HANDLER_SCRIPT.new()
	var p2: PlayerCharacter = PLAYER_HANDLER_SCRIPT.new()

	run_context.enqueue_level_up_choice(p1)
	run_context.enqueue_level_up_choice(p2)
	assert_true(tree.paused)

	run_context.resolve_level_up_choice(p1, PlayerProgression.Attribute.DEXTERITY)
	assert_true(
		tree.paused,
		"Second player still has a pending choice; tree should remain paused",
	)

	run_context.resolve_level_up_choice(p2, PlayerProgression.Attribute.MAGIC)
	assert_false(tree.paused)


func test_pick_random_attributes_seeded_rng_is_deterministic() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 999
	var first: Array[int] = PlayerProgression.pick_random_attributes(3, rng)
	rng.seed = 999
	var replay: Array[int] = PlayerProgression.pick_random_attributes(3, rng)
	assert_eq(first, replay)
