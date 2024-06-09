extends Node
class_name ClassHandler

enum ClassName {BARBARIAN, DRUID, WIZARD}

func barbarian_heart_drawing_logic():
	# Draw 1/4 hearts
	pass

func druid_heart_drawing_logic():
	# Draw green hearts
	pass

func wizard_heart_drawing_logic():
	# Draw purple hearts, with blue reserve mana
	pass

func default_hearts():
	# Draw 1/2 hearts
	pass

func hdl(cn: ClassName) -> Callable:
	match cn:
		ClassName.BARBARIAN:
			return barbarian_heart_drawing_logic
		ClassName.DRUID:
			return druid_heart_drawing_logic
		ClassName.WIZARD:
			return wizard_heart_drawing_logic
		_:
			return default_hearts

class PlayerClass:
	var class_handler: ClassHandler = ClassHandler.new()
	var name: ClassName
	var stats: Stats
	func _init(cn: ClassName):
		self.name = cn 
		self.stats = Stats.new(cn)
		# Each class has a different heart drawing logic
		# Barbarians have 1/4 hearts (rather than 1/2 hearts like
		# the other classes).

		# Druids have green hearts.

		# Wizards have purple hearts, but their missing health also
		# becomes reserve mana, which is blue.
		self.heart_drawing_logic = class_handler.hdl(cn)

func create_class(cn: ClassName) -> PlayerClass :
	# Create a new player character of the given class.
	return PlayerClass.new(cn)