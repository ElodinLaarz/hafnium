class_name CombatDirector
extends Node

const BOMB_SCENE: PackedScene = preload("res://scenes/weapons/player_bomb.tscn")

var run_context


func configure(p_run_context) -> void:
	run_context = p_run_context


func fire_attack(player, angle: float) -> bool:
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
		var projectile_data = ContentRegistry.require_projectile(
			player.player_class.definition.attack_projectile_id
		)
		if projectile_data != null:
			projectile_scene = projectile_data.projectile_scene
	if projectile_scene == null:
		projectile_scene = player.player_class.get_attack_scene()
	if projectile_scene == null:
		return false

	var projectile_parent: Node = run_context.get_world_entity_root()
	if projectile_parent == null:
		return false

	var projectile = projectile_scene.instantiate()
	if not (projectile is Projectile):
		projectile.free()
		return false

	var stats: Stats = player.player_class.stats
	var aim_dir := Vector2(cos(angle), sin(angle))
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


func place_bomb(player) -> bool:
	if (
		run_context == null
		or run_context.world_root == null
		or player == null
		or player.player_class == null
	):
		return false
	if not player.player_class.use_resource("bomb", 1):
		return false
	var entity_root: Node = run_context.get_world_entity_root()
	if entity_root == null:
		return false

	var bomb = BOMB_SCENE.instantiate()
	if bomb is Node2D:
		bomb.position = player.position
	entity_root.add_child(bomb)
	run_context.emit_resource_state(player)
	return true


func resolve_projectile_hit(target, projectile) -> bool:
	if run_context == null or target == null or projectile == null:
		return false
	var damage: Damage = projectile.build_damage()
	if damage == null:
		return false
	if not target.can_receive_damage(damage):
		return false

	projectile.call_deferred("queue_free")
	var defeated = target.receive_damage(damage)
	if defeated:
		if target is Enemy:
			run_context.handle_enemy_defeated(target)
		target.call_deferred("queue_free")
	return defeated


func _calculate_ttl(stats: Stats) -> float:
	if stats.projectile_speed <= 0:
		return 0.1
	return stats.attack_range / stats.projectile_speed
