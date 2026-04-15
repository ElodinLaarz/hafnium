class_name ClassHandler
extends Node

enum ClassName { NONE, BARBARIAN, DRUID, WIZARD }

enum HeartName {
	TRANSPARENT,
	EMPTY,
	RED_FULL,
	RED_HALF,
	WIZARD_FULL,
	WIZARD_HALF_FULL_HALF_MANA,
	WIZARD_HALF_MANA,
	WIZARD_FULL_MANA,
	DRUID_FULL,
	DRUID_HALF,
	BARBARIAN_FULL,
	BARBARIAN_3_4,
	BARBARIAN_HALF,
	BARBARIAN_1_4,
}

var class_sprite_lookup: Dictionary = {
	ClassName.BARBARIAN: "res://scenes/characters/sprites/barbarian_sprite.tscn",
	ClassName.DRUID: "res://scenes/characters/sprites/druid_sprite.tscn",
	ClassName.WIZARD: "res://scenes/characters/sprites/wizard_sprite.tscn",
}

var named_heart_lookup: Dictionary = {
	HeartName.TRANSPARENT: rect(0, 0),
	HeartName.EMPTY: rect(1, 0),
	HeartName.WIZARD_FULL: rect(2, 0),
	HeartName.WIZARD_HALF_FULL_HALF_MANA: rect(3, 0),
	HeartName.WIZARD_HALF_MANA: rect(4, 0),
	HeartName.WIZARD_FULL_MANA: rect(4, 1),
	HeartName.RED_FULL: rect(0, 1),
	HeartName.RED_HALF: rect(1, 1),
	HeartName.DRUID_FULL: rect(2, 1),
	HeartName.DRUID_HALF: rect(3, 1),
	HeartName.BARBARIAN_FULL: rect(0, 2),
	HeartName.BARBARIAN_3_4: rect(1, 2),
	HeartName.BARBARIAN_HALF: rect(2, 2),
	HeartName.BARBARIAN_1_4: rect(3, 2),
}

var empty_heart: Rect2i = named_heart_lookup[HeartName.EMPTY]
var health_checks: Health = Health.new()


func rect(row, col: int) -> Rect2i:
	return Rect2i(row * 16, col * 16, 16, 16)


func heart_texture(texture_rect: TextureRect, heart_name: HeartName) -> AtlasTexture:
	var at: AtlasTexture
	if texture_rect.texture is AtlasTexture:
		at = texture_rect.texture
	else:
		at = AtlasTexture.new()
		at.atlas = texture_rect.texture
		texture_rect.texture = at
	at.region = named_heart_lookup[heart_name]
	return at


func barbarian_heart_drawing_logic(stats: Stats, heart_container: Node):
	if !health_checks.bounds_ok(stats, heart_container.get_child_count()):
		print("Health bounds check failed-- using default heart drawing logic.")
		default_hearts(stats, heart_container)
		return
	if stats.health_to_damage_multiplier != 4:
		print("Barbarians should have a health to damage multiplier of 4.")
		print("Using default heart drawing logic.")
		default_hearts(stats, heart_container)
		return

	var total_hearts: int = stats.max_health / stats.health_to_damage_multiplier
	# Draw 1/4 hearts
	var full_heart_count: int = stats.current_health / stats.health_to_damage_multiplier
	var partial_heart: int = stats.current_health % stats.health_to_damage_multiplier

	for i in range(total_hearts):
		var current_heart: TextureRect = heart_container.get_child(i)
		if i < full_heart_count:
			current_heart.texture = heart_texture(current_heart, HeartName.BARBARIAN_FULL)
		elif i == full_heart_count:
			match partial_heart:
				3:
					current_heart.texture = heart_texture(current_heart, HeartName.BARBARIAN_3_4)
				2:
					current_heart.texture = heart_texture(current_heart, HeartName.BARBARIAN_HALF)
				1:
					current_heart.texture = heart_texture(current_heart, HeartName.BARBARIAN_1_4)
				_:
					current_heart.texture = heart_texture(current_heart, HeartName.EMPTY)
		else:
			current_heart.texture = heart_texture(current_heart, HeartName.EMPTY)


func druid_heart_drawing_logic(stats: Stats, heart_container: Node):
	if !health_checks.bounds_ok(stats, heart_container.get_child_count()):
		print("Health bounds check failed-- using default heart drawing logic.")
		default_hearts(stats, heart_container)
		return

	var full_heart_count: int = stats.current_health / 2
	var partial_heart: int = stats.current_health % 2

	for i in range(stats.max_health / 2):
		var current_heart: TextureRect = heart_container.get_child(i)
		if i < full_heart_count:
			current_heart.texture = heart_texture(current_heart, HeartName.DRUID_FULL)
		elif i == full_heart_count:
			match partial_heart:
				1:
					current_heart.texture = heart_texture(current_heart, HeartName.DRUID_HALF)
				_:
					current_heart.texture = heart_texture(current_heart, HeartName.EMPTY)
		else:
			current_heart.texture = heart_texture(current_heart, HeartName.EMPTY)


func wizard_heart_drawing_logic(stats: Stats, heart_container: Node):
	# Draw purple hearts, with blue reserve mana
	if !health_checks.bounds_ok(stats, heart_container.get_child_count()):
		print("Health bounds check failed-- using default heart drawing logic.")
		default_hearts(stats, heart_container)
		return

	var full_heart_count: int = stats.current_health / 2
	var partial_heart: int = stats.current_health % 2

	# Placeholder for mana logic: in the future, empty hearts should
	# show mana based on stats.resources["mana"]
	var mana_res = stats.resources.get("mana")
	var mana: int = mana_res.current_resource if mana_res is Stats.ResourceStatus else 0

	for i in range(stats.max_health / 2):
		var current_heart: TextureRect = heart_container.get_child(i)
		if i < full_heart_count:
			current_heart.texture = heart_texture(current_heart, HeartName.WIZARD_FULL)
		elif i == full_heart_count and partial_heart == 1:
			# Half-health heart: fill the other half with mana if available.
			if mana >= 1:
				current_heart.texture = heart_texture(
					current_heart, HeartName.WIZARD_HALF_FULL_HALF_MANA
				)
			else:
				current_heart.texture = heart_texture(current_heart, HeartName.RED_HALF)
		else:
			# Fully empty heart slot: fill with mana progressively.
			var slot: int = i - full_heart_count
			if mana >= (slot + 1) * 2:
				current_heart.texture = heart_texture(current_heart, HeartName.WIZARD_FULL_MANA)
			elif mana >= slot * 2 + 1:
				current_heart.texture = heart_texture(current_heart, HeartName.WIZARD_HALF_MANA)
			else:
				current_heart.texture = heart_texture(current_heart, HeartName.EMPTY)


func default_hearts(_stats: Stats, heart_container: Node):
	# Clear heart containers or set them to empty.
	if heart_container == null:
		return
	for i in range(heart_container.get_child_count()):
		var current_heart: TextureRect = heart_container.get_child(i)
		current_heart.texture = heart_texture(current_heart, HeartName.EMPTY)


func hdl(pc: PlayerClass, cn: ClassName) -> bool:
	if !setup_hp(pc, cn):
		print("trouble setting up hp for %s" % cn)
		return false
	if !setup_class_resources(pc, cn):
		print("trouble setting up resources for %s" % cn)
		return false
	if !setup_heart_drawing(pc, cn):
		print("trouble setting up heart drawing for %s" % cn)
		return false
	if !setup_attack(pc, cn):
		print("trouble setting up attack for %s" % cn)
		return false
	return true


func setup_heart_drawing(pc: PlayerClass, cn: ClassName) -> bool:
	match cn:
		ClassName.BARBARIAN:
			pc.heart_drawing_logic = barbarian_heart_drawing_logic
		ClassName.DRUID:
			pc.heart_drawing_logic = druid_heart_drawing_logic
		ClassName.WIZARD:
			pc.heart_drawing_logic = wizard_heart_drawing_logic
		_:
			print("Unexpected class: ", cn)
			print("Default heart drawing logic will be used.")
			pc.heart_drawing_logic = default_hearts
			return false
	return true


func setup_hp(pc: PlayerClass, cn: ClassName):
	match cn:
		ClassName.BARBARIAN:
			pc.stats.health_to_damage_multiplier = 4
			pc.stats.max_health = 12
		ClassName.DRUID:
			pc.stats.max_health = 6
		ClassName.WIZARD:
			pc.stats.max_health = 4
		_:
			# Unmatched class
			return false
	pc.stats.current_health = pc.stats.max_health
	return true


func wizard_attack(stats: Stats):
	# Add cooldown and stuff
	if stats.attack_cooldown > 0:
		return false
	stats.attack_cooldown = stats.attack_speed
	return true


func get_attack_projectile_path(cn: ClassName) -> String:
	match cn:
		ClassName.WIZARD:
			return "res://scenes/weapons/bullets/fireball.tscn"
		_:
			return ""


func setup_attack(pc: PlayerClass, cn: ClassName) -> bool:
	if !setup_damage(pc, cn):
		print("trouble setting up damage for %s" % cn)
		return false

	pc.attack_projectile_path = get_attack_projectile_path(cn)

	match cn:
		ClassName.WIZARD:
			pc.attack_logic = wizard_attack
		ClassName.BARBARIAN, ClassName.DRUID:
			# TODO: Implement specific attack logic for these classes
			pc.attack_logic = func(_stats): return false
		_:
			# Unmatched class
			return false
	return true


func setup_damage(pc: PlayerClass, cn: ClassName):
	match cn:
		ClassName.BARBARIAN:
			pc.stats.damage = 3
			pc.stats.attack_range = 0
			pc.stats.attack_speed = 1
		ClassName.DRUID:
			pc.stats.damage = 2
			pc.stats.attack_range = 1
			pc.stats.attack_speed = 1.2
			pc.stats.projectile_speed = 50
		ClassName.WIZARD:
			pc.stats.damage = 1
			pc.stats.attack_range = 90
			pc.stats.attack_speed = 0.8
			pc.stats.projectile_speed = 180
		_:
			# Unmatched class
			return false
	return true


func setup_class_resources(pc: PlayerClass, cn: ClassName) -> bool:
	match cn:
		ClassName.BARBARIAN:
			pc.stats.resources["bomb"] = Stats.ResourceStatus.new(Stats.ClassResource.BOMB, 3, 0)
		ClassName.DRUID:
			pc.stats.resources["bomb"] = Stats.ResourceStatus.new(Stats.ClassResource.BOMB, 2, 0)
		ClassName.WIZARD:
			pc.stats.resources["bomb"] = Stats.ResourceStatus.new(Stats.ClassResource.BOMB, 1, 0)
			pc.stats.resources["mana"] = Stats.ResourceStatus.new(Stats.ClassResource.MANA, 4, 0)
		_:
			return false
	return true


class PlayerClass:
	var class_handler := ClassHandler.new()
	var heart_drawing_logic: Callable
	var attack_logic: Callable
	var attack_projectile_path: String = ""
	var name: ClassName
	var stats: Stats
	var _attack_scene: PackedScene

	func _init(cn: ClassName):
		self.name = cn
		self.stats = Stats.new()
		# Each class has a different heart drawing logic
		# Barbarians have 1/4 hearts (rather than 1/2 hearts like
		# the other classes).

		# Druids have green hearts.

		# Wizards have purple hearts, but their missing health also
		# becomes reserve mana, which is blue.
		if class_handler.hdl(self, cn):
			print("successfully set up class %s" % ClassName.keys()[cn])
		else:
			print("failed to set up class %s" % ClassName.keys()[cn])
			# Fallback to avoid null callables
			self.attack_logic = func(_stats): return false
			self.heart_drawing_logic = class_handler.default_hearts

	func has_resource(resource: String, count: int) -> bool:
		if self.stats.resources.has(resource):
			var res = self.stats.resources[resource]
			return res.current_resource >= count
		return false

	func use_resource(resource: String, count: int) -> bool:
		if self.stats.resources.has(resource):
			var res = self.stats.resources[resource]
			if res.current_resource >= count:
				res.current_resource -= count
				return true
		return false

	func draw_hearts(heart_container: Node):
		self.heart_drawing_logic.call(self.stats, heart_container)

	func get_attack_scene() -> PackedScene:
		if _attack_scene == null and not attack_projectile_path.is_empty():
			_attack_scene = load(attack_projectile_path)
		return _attack_scene

	func attack() -> bool:
		if self.attack_logic:
			return self.attack_logic.call(self.stats)
		return false


func create_class(cn: ClassName) -> PlayerClass:
	# Create a new player character of the given class.
	return PlayerClass.new(cn)
