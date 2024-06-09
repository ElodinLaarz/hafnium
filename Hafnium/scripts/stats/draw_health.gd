extends Node

const PLAYER_HEART = preload("res://scenes/interface/lifebar/heart.tscn")

func set_num_hearts(heart_container: Node, num_hearts: int):
	if heart_container.get_child_count() != num_hearts:
		heart_container.remove_all_children()
		for i in range(num_hearts):
			var heart: Node = PLAYER_HEART.instance()
			heart_container.add_child(heart)

func check_and_create_hearts(parent_node: Node, player_character: PlayerCharacter):
	var stats: Stats = player_character.player_stats
	var max_health: int = stats.get_max_health()
	if max_health % stats.health_to_damage_multiplier != 0:
		print("Warning: Max health %d is not a multiple of the health to damage multiplier %d.", max_health, stats.health_to_damage_multiplier)
		print("Warning: Value will be truncated.")
	var heart_counter: int = max_health / stats.health_to_damage_multiplier
	var heart_container: Node = parent_node.get_node("HeartContainer")
	# TODO(ElodinLaarz): Need to add error handling at some point...
	set_num_hearts(heart_container, heart_counter)

	# Draw appropriate hearts based on the current health.
	var pc: ClassHandler.PlayerClass = player_character.player_class
	var current_health: int = stats.current_health
	# Update the icon for each heart based on the current status.
	# TODO(ElodinLaarz): Could probably ask each class for a map
	# to draw their health...
	update_health(player_character)

func update_health(player_character: PlayerCharacter):
	var stats: Stats = player_character.player_stats
	var pc: ClassHandler.PlayerClass = player_character.player_class
	# Make sure you have the right number of child components with 
	# hearts.
	# Update the icon for each heart based on the current status.
	# TODO(ElodinLaarz): Could probably ask each class for a map
	# to draw their health...
