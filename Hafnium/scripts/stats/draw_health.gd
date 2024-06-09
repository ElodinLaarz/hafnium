extends Node

const PLAYER_HEART = preload("res://scenes/interface/lifebar/heart.tscn")

func dequeue_children(parent: Node):
	while parent.get_child_count() > 0:
		parent.get_child(0).queue_free()

func set_num_hearts(heart_container: Node, num_hearts: int):
	if heart_container.get_child_count() != num_hearts:
		dequeue_children(heart_container)
		for i in range(num_hearts):
			var heart: Node = PLAYER_HEART.instantiate()
			heart_container.add_child(heart)

func check_and_create_hearts(parent_node: Node, player_character: PlayerCharacter):
	var pc: ClassHandler.PlayerClass = player_character.player_class
	var stats: Stats = pc.stats
	var max_health: int = stats.max_health
	print("Max health: %d" % max_health)
	if max_health % stats.health_to_damage_multiplier != 0:
		print("Warning: Max health %d is not a multiple of the health to damage multiplier %d." % max_health, stats.health_to_damage_multiplier)
		print("Warning: Value will be truncated.")
	var heart_counter: int = max_health / stats.health_to_damage_multiplier
	var heart_container: Node = parent_node.get_node("HeartContainer")
	# TODO(ElodinLaarz): Need to add error handling at some point...
	set_num_hearts(heart_container, heart_counter)

	# Draw appropriate hearts based on the current health.
	print("Calling heart drawing logic...")
	pc.heart_drawing_logic.call(player_character.player_class.stats, heart_container)

func update_health(player_character: PlayerCharacter):
	check_and_create_hearts(self, player_character)

func _ready():
	var example_pc: PlayerCharacter = PlayerCharacter.new(ClassHandler.ClassName.DRUID)
	update_health(example_pc)