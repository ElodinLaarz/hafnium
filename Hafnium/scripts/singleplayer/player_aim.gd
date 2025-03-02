extends Node2D
class_name PlayerAim

# aim_radius is how far the aim sight is drawn from the player.
const aim_radius: float = 8 # In pixels...?

# should be set when pulled into another script...
var aim_sight: Node2D
var pivot: Node2D
var camera: Camera2D

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
	var mouse_position: Vector2 = camera.get_viewport().get_mouse_position()
	
	var direction: Vector2 = mouse_position - source_position # I am already worried about negatives
	
	return direction.normalized()

func update_pivot(_delta: float):
	if not pivot:
		print("UH OH! No Pivot?? :O")
		return
	var pivot_origin: Vector2 = pivot.get_global_transform_with_canvas().get_origin()
	var pivot_position: Vector2 = pivot.position + pivot_origin
	var unit_displacement: Vector2 = unit_direction_to_mouse(pivot_position)
	aim_sight.position = pivot.position + aim_radius * unit_displacement
	
	var polar_displacement: PolarCoordinate = polar_coordinates(unit_displacement)
	aim_sight.rotation = polar_displacement.angle
	# Sync the direction of aim_sight with the intended direction of
	# a proj.
	Common.attack_spawn_angle = polar_displacement.angle
