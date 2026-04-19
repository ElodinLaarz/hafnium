extends Node

@export var noise_height_texture: NoiseTexture2D

var noise: Noise
var width: int = 500
var height: int = 500
var source_id: int = 0
var water_atlas: Vector2i = Vector2i(1, 0)
var sand_height: float = 0.5
var sand_atlas: Vector2i = Vector2i(3, 0)
var mountain_height: float = 0.7
var mountain_atlas: Vector2i = Vector2i(2, 0)

@onready var tile_map: TileMap = $TileMap


func _ready() -> void:
	noise = noise_height_texture.noise
	generate_world()


func standardize_height_perlin(val: float) -> float:
	return val + 0.5


# Standardize between 0 and 1
func standardize_height_cellular(val: float) -> float:
	#var cellular_noise_max = 0
	#var cellular_noise_min = -1
	return val + 1


func generate_world() -> void:
	# var noise_vals = []
	for x: int in range(width):
		for y: int in range(height):
			var standard_noise_val: float = standardize_height_perlin(noise.get_noise_2d(x, y))
			var current_location: Vector2 = Vector2(x - width / 2, y - height / 2)
			var atlas_choice: Vector2i = water_atlas
			if standard_noise_val >= mountain_height:
				atlas_choice = mountain_atlas
			elif standard_noise_val >= sand_height:
				atlas_choice = sand_atlas
			tile_map.set_cell(0, current_location, source_id, atlas_choice)
			#noise_vals.append(standard_noise_val)
	#print("max: %f" % noise_vals.max())
	#print("min: %f" % noise_vals.min())
