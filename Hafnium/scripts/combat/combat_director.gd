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
	var aim_dir: Vector2 = Vector2(cos(angle), sin(angle))
	projectile.rotation = PI + angle
	projectile.position = player.position + aim_dir * run_context.attack_displacement_magnitude
	projectile.velocity = aim_dir * stats.projectile_speed
	projectile.damage = stats.damage
	projectile.ttl = _calculate_ttl(stats)
	projectile.source_actor = player
	projectile.source_team = player.get_team()
	projectile.damage_payload = Damage.basic(stats.damage, player, player.get_team())
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
	if defeated:
		if target is Enemy:
			run_context.handle_enemy_defeated(target)
		target.call_deferred("queue_free")
	return defeated


func _calculate_ttl(stats: Stats) -> float:
	if stats.projectile_speed <= 0:
		# Avoid division by zero while still allowing melee-style placeholder projectiles.
		return ZERO_SPEED_PROJECTILE_TTL
	return stats.attack_range / stats.projectile_speed
