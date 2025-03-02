extends Node2D

# aim_radius is how far the aim sight is drawn from the player.
const aim_radius: float = 8 # In pixels...?

@onready var pivot: Node2D = %MultiplayerPivotPoint

class PolarCoordinate:
	var radius: float
	var angle: float
	
	func _init(r:float, a:float):
		radius = r
		angle = a

# Convert (x,y) coordinates to (r, theta) coordinates.
# https://en.wikipedia.org/wiki/Polar_coordinate_system
func polar_coordinates(cartesian: Vector2) -> PolarCoordinate:
	var x: float = cartesian.x
	var y: float = cartesian.y
	
	var radius: float = sqrt(pow(x,2) + pow(y,2))
	var angle = atan2(y,x)
	
	return PolarCoordinate.new(radius, angle)

# Returns a unit vector whose angle represents the angle between the pivot
# point (which should be at "the center" of the player) and the mouse.
func unit_direction_to_mouse(source_position: Vector2) -> Vector2:
	var mouse_position: Vector2 = get_global_mouse_position()

	var direction: Vector2 = mouse_position - source_position # I am already worried about negatives
	
	return direction.normalized()

# Called every frame. '_delta' is the elapsed time since the previous frame.
func _process(_delta: float):
	var pivot_position: Vector2 = pivot.global_position
	var unit_displacement: Vector2 = unit_direction_to_mouse(pivot_position)
	position = pivot.position + aim_radius * unit_displacement
	
	var polar_displacement: PolarCoordinate = polar_coordinates(unit_displacement)
	rotation = polar_displacement.angle
