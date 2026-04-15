class_name CombatDirector
extends Node

const BOMB_SCENE: PackedScene = preload("res://scenes/weapons/player_bomb.tscn")
const GameConstants = preload("res://scripts/config/game_constants.gd")
const ZERO_SPEED_PROJECTILE_TTL: float = 0.1

var run_context: RunContext


func configure(p_run_context: RunContext) -> void:
	run_context = p_run_context


func fire_attack(player: PlayerCharacter, angle: float) -> bool:
	if (
		run_context == null
		or run_context.world_root == null
		or player == null
		or player.player_class == null
	):
		return false
	if not player.player_class.attack():
		return false

	var projectile_scene: PackedScene
	if (
		player.player_class.definition != null
		and not player.player_class.definition.attack_projectile_id.is_empty()
	):
		# ID-based lookup keeps class definitions data-driven while allowing scene swaps.
		var projectile_data: ProjectileData = ContentRegistry.require_projectile(
			player.player_class.definition.attack_projectile_id
		)
		if projectile_data != null:
			projectile_scene = projectile_data.projectile_scene
	if projectile_scene == null:
		# Backward-compatible fallback for classes still carrying direct scene references.
		projectile_scene = player.player_class.get_attack_scene()
	if projectile_scene == null:
		return false

	var projectile_parent: Node = run_context.get_world_entity_root()
	if projectile_parent == null:
		return false

	var projectile: Node = projectile_scene.instantiate()
	if not (projectile is Projectile):
		# Failing closed here prevents non-projectile scenes from entering combat loops.
		projectile.free()
		return false

	var stats: Stats = player.player_class.stats
	var feel_tuning: FeelTuningProfile = Common.get_feel_tuning()
	var crit_chance: float = feel_tuning.crit_chance if feel_tuning != null else 0.0
	var crit_damage_multiplier: float = (
		feel_tuning.crit_damage_multiplier if feel_tuning != null else 2.0
	)
	var is_crit: bool = randf() < crit_chance
	var damage_amount: int = stats.damage
	if is_crit:
		damage_amount = maxi(1, int(round(float(stats.damage) * crit_damage_multiplier)))
	var aim_dir: Vector2 = Vector2(cos(angle), sin(angle))
	projectile.rotation = PI + angle
	projectile.position = player.position + aim_dir * run_context.attack_displacement_magnitude
	projectile.velocity = aim_dir * stats.projectile_speed
	projectile.damage = damage_amount
	projectile.ttl = _calculate_ttl(stats)
	projectile.source_actor = player
	projectile.source_team = player.get_team()
	projectile.damage_payload = Damage.basic(
		damage_amount, player, player.get_team(), {"is_crit": is_crit}
	)
	projectile_parent.add_child(projectile)
	run_context.emit_resource_state(player)
	return true


func place_bomb(player: PlayerCharacter) -> bool:
	if (
		run_context == null
		or run_context.world_root == null
		or player == null
		or player.player_class == null
	):
		return false
	if not player.player_class.use_resource(GameConstants.RESOURCE_BOMB, 1):
		return false
	var entity_root: Node = run_context.get_world_entity_root()
	if entity_root == null:
		return false

	var bomb: Node2D = BOMB_SCENE.instantiate()
	if bomb is Node2D:
		bomb.position = player.position
	entity_root.add_child(bomb)
	run_context.emit_resource_state(player)
	return true


func resolve_projectile_hit(target: BaseCharacter, projectile: Projectile) -> bool:
	if run_context == null or target == null or projectile == null:
		return false
	var damage: Damage = projectile.build_damage()
	if damage == null:
		return false
	if not target.can_receive_damage(damage):
		return false

	projectile.call_deferred("queue_free")
	var defeated: bool = target.receive_damage(damage)
	var is_crit: bool = bool(damage.metadata.get("is_crit", false))
	run_context.request_hit_feedback(is_crit)
	run_context.spawn_damage_number(target.global_position, damage.amount, is_crit)
	if defeated:
		if target is Enemy:
			run_context.handle_enemy_defeated(target)
		target.call_deferred("queue_free")
	return defeated


func _calculate_ttl(stats: Stats) -> float:
	var feel_tuning: FeelTuningProfile = Common.get_feel_tuning()
	var life_multiplier: float = (
		feel_tuning.projectile_life_multiplier if feel_tuning != null else 1.0
	)
	if stats.projectile_speed <= 0:
		# Avoid division by zero while still allowing melee-style placeholder projectiles.
		return ZERO_SPEED_PROJECTILE_TTL * life_multiplier
	return (stats.attack_range / stats.projectile_speed) * life_multiplier
