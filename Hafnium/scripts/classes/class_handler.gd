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

const GameConstants = preload("res://scripts/config/game_constants.gd")
const HEART_ATLAS_TILE_SIZE: int = 16
## Set on each heart TextureRect once we replace a shared scene SubResource with a unique atlas.
const HEART_UNIQUE_ATLAS_META: StringName = &"_class_handler_heart_unique_atlas"

const CHARACTER_IDS_BY_ENUM: Dictionary = {
	ClassName.BARBARIAN: GameConstants.CLASS_ID_BARBARIAN,
	ClassName.DRUID: GameConstants.CLASS_ID_DRUID,
	ClassName.WIZARD: GameConstants.CLASS_ID_WIZARD,
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


func rect(row: int, col: int) -> Rect2i:
	return Rect2i(
		row * HEART_ATLAS_TILE_SIZE,
		col * HEART_ATLAS_TILE_SIZE,
		HEART_ATLAS_TILE_SIZE,
		HEART_ATLAS_TILE_SIZE
	)


func heart_texture(texture_rect: TextureRect, heart_name: HeartName) -> AtlasTexture:
	# Each TextureRect must own its AtlasTexture (scene SubResources can be shared; mutating
	# region would affect every heart). First draw duplicates the scene atlas or builds one;
	# later draws only update region on the unique resource.
	var source: Texture2D = texture_rect.texture
	var atlas_image: Texture2D
	if source is AtlasTexture:
		atlas_image = (source as AtlasTexture).atlas
	else:
		atlas_image = source
	var at: AtlasTexture = texture_rect.texture as AtlasTexture
	if texture_rect.has_meta(HEART_UNIQUE_ATLAS_META):
		if at == null or at.atlas != atlas_image:
			at = AtlasTexture.new()
			at.atlas = atlas_image
			texture_rect.texture = at
	else:
		if source is AtlasTexture:
			at = (source as AtlasTexture).duplicate() as AtlasTexture
		else:
			at = AtlasTexture.new()
			at.atlas = atlas_image
		texture_rect.texture = at
		texture_rect.set_meta(HEART_UNIQUE_ATLAS_META, true)
	at.region = named_heart_lookup[heart_name]
	return at


func barbarian_heart_drawing_logic(stats: Stats, heart_container: Node) -> void:
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

	for i: int in range(total_hearts):
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


func druid_heart_drawing_logic(stats: Stats, heart_container: Node) -> void:
	if !health_checks.bounds_ok(stats, heart_container.get_child_count()):
		print("Health bounds check failed-- using default heart drawing logic.")
		default_hearts(stats, heart_container)
		return

	var mult: int = stats.health_to_damage_multiplier
	if mult <= 0:
		default_hearts(stats, heart_container)
		return
	var full_heart_count: int = stats.current_health / mult
	var partial_heart: int = stats.current_health % mult

	for i: int in range(stats.max_health / mult):
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


func wizard_heart_drawing_logic(stats: Stats, heart_container: Node) -> void:
	# Draw purple hearts, with blue reserve mana
	if !health_checks.bounds_ok(stats, heart_container.get_child_count()):
		print("Health bounds check failed-- using default heart drawing logic.")
		default_hearts(stats, heart_container)
		return

	var mult: int = stats.health_to_damage_multiplier
	if mult <= 0:
		default_hearts(stats, heart_container)
		return
	var full_heart_count: int = stats.current_health / mult
	var partial_heart: int = stats.current_health % mult
	# When a slot shows partial HP, it is not an "empty" mana vessel; shift mana slot index down.
	var empty_mana_origin: int = full_heart_count + (1 if partial_heart > 0 else 0)

	# Placeholder for mana logic: in the future, empty hearts should
	# show mana based on stats.resources["mana"]
	var mana_res: Stats.ResourceStatus = stats.resources.get(GameConstants.RESOURCE_MANA)
	var mana: int = mana_res.current_resource if mana_res is Stats.ResourceStatus else 0

	for i: int in range(stats.max_health / mult):
		var current_heart: TextureRect = heart_container.get_child(i)
		if i < full_heart_count:
			current_heart.texture = heart_texture(current_heart, HeartName.WIZARD_FULL)
		elif i == full_heart_count and partial_heart > 0:
			# Half-health heart (mult==2 assets): fill the other half with mana if available.
			if mult == 2 and partial_heart == 1:
				if mana >= 1:
					current_heart.texture = heart_texture(
						current_heart, HeartName.WIZARD_HALF_FULL_HALF_MANA
					)
				else:
					current_heart.texture = heart_texture(current_heart, HeartName.RED_HALF)
			else:
				current_heart.texture = heart_texture(current_heart, HeartName.RED_HALF)
		else:
			# Fully empty heart slot: fill with mana progressively.
			var slot: int = i - empty_mana_origin
			if mana >= (slot + 1) * mult:
				current_heart.texture = heart_texture(current_heart, HeartName.WIZARD_FULL_MANA)
			elif mana >= slot * mult + 1:
				current_heart.texture = heart_texture(current_heart, HeartName.WIZARD_HALF_MANA)
			else:
				current_heart.texture = heart_texture(current_heart, HeartName.EMPTY)


func default_hearts(_stats: Stats, heart_container: Node) -> void:
	# Clear heart containers or set them to empty.
	if heart_container == null:
		return
	for i: int in range(heart_container.get_child_count()):
		var current_heart: TextureRect = heart_container.get_child(i)
		current_heart.texture = heart_texture(current_heart, HeartName.EMPTY)


func hdl(pc: PlayerClass, cn: ClassName) -> bool:
	var data: CharacterData = get_character_data(cn)
	if data == null:
		print("No character data found for %s" % cn)
		return false
	return setup_from_data(pc, data)


func get_character_data(cn: ClassName) -> CharacterData:
	if not CHARACTER_IDS_BY_ENUM.has(cn):
		return null
	return ContentRegistry.require_character(CHARACTER_IDS_BY_ENUM[cn])


func setup_from_data(pc: PlayerClass, data: CharacterData) -> bool:
	pc.definition = data
	# Stats come from content resources so class tuning does not require code edits.
	data.apply_to_stats(pc.stats)
	pc.stats.speed = data.speed
	if not setup_heart_drawing_from_style(pc, data.heart_style):
		return false
	pc.attack_projectile_path = get_projectile_path_from_definition(data)
	# Keep a direct scene handle when present to avoid repeated `load()` during combat.
	pc._attack_scene = data.attack_projectile_scene
	pc.attack_logic = build_attack_logic(data)
	return true


func setup_heart_drawing_from_style(pc: PlayerClass, heart_style: String) -> bool:
	match heart_style:
		GameConstants.HEART_STYLE_BARBARIAN:
			pc.heart_drawing_logic = barbarian_heart_drawing_logic
		GameConstants.HEART_STYLE_DRUID:
			pc.heart_drawing_logic = druid_heart_drawing_logic
		GameConstants.HEART_STYLE_WIZARD:
			pc.heart_drawing_logic = wizard_heart_drawing_logic
		GameConstants.HEART_STYLE_DEFAULT:
			pc.heart_drawing_logic = default_hearts
		_:
			print("Unexpected heart style: ", heart_style)
			pc.heart_drawing_logic = default_hearts
			return false
	return true


func get_attack_projectile_path(cn: ClassName) -> String:
	var data: CharacterData = get_character_data(cn)
	return get_projectile_path_from_definition(data)


func get_projectile_path_from_definition(data: CharacterData) -> String:
	if data == null:
		return ""
	if not data.attack_projectile_id.is_empty():
		# Prefer registry IDs so projectile implementations can be swapped centrally.
		var projectile_data: ProjectileData = ContentRegistry.get_projectile(
			data.attack_projectile_id
		)
		if projectile_data != null and projectile_data.projectile_scene != null:
			return projectile_data.projectile_scene.resource_path
	if data.attack_projectile_scene == null:
		return ""
	return data.attack_projectile_scene.resource_path


func build_attack_logic(data: CharacterData) -> Callable:
	if data == null:
		return func(_pc: PlayerClass) -> bool: return false
	if data.attack_projectile_scene == null and data.attack_projectile_id.is_empty():
		return func(_pc: PlayerClass) -> bool: return false
	if get_projectile_path_from_definition(data).is_empty():
		return func(_pc: PlayerClass) -> bool: return false
	if data.primary_spell_mana_cost > 0:
		var mana_cost: int = data.primary_spell_mana_cost
		return func(pc: PlayerClass) -> bool: return _primary_attack_with_mana_cost(pc, mana_cost)
	return func(pc: PlayerClass) -> bool:
		if pc.stats.attack_cooldown > 0:
			return false
		pc.stats.attack_cooldown = pc.stats.attack_speed
		return true


func _primary_attack_with_mana_cost(pc: PlayerClass, mana_cost: int) -> bool:
	if pc.stats.attack_cooldown > 0:
		return false
	if mana_cost > 0:
		if not pc.use_resource(GameConstants.RESOURCE_MANA, mana_cost):
			return false
	pc.stats.attack_cooldown = pc.stats.attack_speed
	return true


## Blood Mana (Wizard): max mana increases as current health falls; current is clamped.
func recompute_wizard_blood_mana(pc: PlayerClass, extra_base_mana_max: int = 0) -> void:
	if pc == null or pc.name != ClassName.WIZARD or pc.definition == null:
		return
	var def: CharacterData = pc.definition
	var mana_res: Stats.ResourceStatus = pc.stats.resources.get(GameConstants.RESOURCE_MANA)
	if mana_res == null:
		return
	if def.mana_max <= 0 and extra_base_mana_max <= 0:
		return

	var blood_bonus: int = 0
	if def.blood_mana_bonus_pool > 0:
		var max_h: int = maxi(pc.stats.max_health, 1)
		var missing: int = maxi(0, pc.stats.max_health - pc.stats.current_health)
		var missing_ratio: float = float(missing) / float(max_h)
		blood_bonus = int(round(missing_ratio * float(def.blood_mana_bonus_pool)))

	var new_max: int = def.mana_max + extra_base_mana_max + blood_bonus
	if new_max < 0:
		new_max = 0
	var old_max: int = mana_res.max_resource
	var old_current: int = mana_res.current_resource
	mana_res.max_resource = new_max
	if mana_res.current_resource > new_max:
		mana_res.current_resource = new_max
	if old_max != new_max or old_current != mana_res.current_resource:
		pc.stats.resource_changed.emit(
			GameConstants.RESOURCE_MANA, mana_res.current_resource, mana_res.max_resource
		)


## Barbarian Battle Hardened and future class-specific incoming-damage rules.
func _modify_incoming_damage(pc: PlayerClass, player: PlayerCharacter, incoming_damage: int) -> int:
	if pc == null or player == null:
		return incoming_damage
	if pc.name != ClassName.BARBARIAN:
		return incoming_damage
	if incoming_damage <= 0:
		return incoming_damage
	if player.is_invincible or player.stats == null or player.stats.current_health <= 0:
		return incoming_damage
	var reduced_damage: int = maxi(0, incoming_damage - pc.battle_hardened_counter)
	if reduced_damage <= 0:
		pc.battle_hardened_counter = 0
		return 0
	pc.battle_hardened_counter += 1
	return reduced_damage


class PlayerClass:
	var attack_logic: Callable
	var attack_projectile_path: String = ""
	var battle_hardened_counter: int = 0
	var class_handler: ClassHandler = ClassHandler.new()
	var definition: CharacterData
	var heart_drawing_logic: Callable
	var name: ClassName
	var stats: Stats
	var _attack_scene: PackedScene

	func _init(cn: ClassName) -> void:
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
			_post_init_class()
		else:
			print("failed to set up class %s" % ClassName.keys()[cn])
			# Fallback to avoid null callables
			self.attack_logic = func(_pc: PlayerClass) -> bool: return false
			self.heart_drawing_logic = class_handler.default_hearts

	func _post_init_class() -> void:
		if self.name == ClassName.WIZARD:
			if not self.stats.health_changed.is_connected(_on_wizard_health_blood_mana):
				self.stats.health_changed.connect(_on_wizard_health_blood_mana)
			class_handler.recompute_wizard_blood_mana(self)

	func attack() -> bool:
		if self.attack_logic:
			return self.attack_logic.call(self)
		return false

	func draw_hearts(heart_container: Node) -> void:
		self.heart_drawing_logic.call(self.stats, heart_container)

	func get_attack_scene() -> PackedScene:
		if (
			_attack_scene == null
			and definition != null
			and definition.attack_projectile_scene != null
		):
			_attack_scene = definition.attack_projectile_scene
		if _attack_scene == null and not attack_projectile_path.is_empty():
			# Lazy loading preserves compatibility for legacy classes using only paths.
			_attack_scene = load(attack_projectile_path)
		return _attack_scene

	func has_resource(resource: String, count: int) -> bool:
		if self.stats.resources.has(resource):
			var res: Stats.ResourceStatus = self.stats.resources[resource]
			return res.current_resource >= count
		return false

	func modify_incoming_damage(player: PlayerCharacter, incoming_damage: int) -> int:
		return class_handler._modify_incoming_damage(self, player, incoming_damage)

	func use_resource(resource: String, count: int) -> bool:
		if self.stats.resources.has(resource):
			var res: Stats.ResourceStatus = self.stats.resources[resource]
			if res.current_resource >= count:
				res.current_resource -= count
				self.stats.resource_changed.emit(resource, res.current_resource, res.max_resource)
				return true
		return false

	func _on_wizard_health_blood_mana(_new_health: int, _max_health: int) -> void:
		class_handler.recompute_wizard_blood_mana(self)


func create_class(cn: ClassName) -> PlayerClass:
	# Create a new player character of the given class.
	return PlayerClass.new(cn)
