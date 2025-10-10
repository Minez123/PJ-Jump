extends Node3D

@export var water_scene: PackedScene
@onready var player = get_tree().get_first_node_in_group("player")

var water_tiles = {}
var chunk_size = 100
var render_distance = 2  # number of chunks around player

func _ready():
	_update_water()

func _process(_delta):
	_update_water()

func _update_water():
	if not player:
		return
	var player_chunk = Vector2(
		floor(player.global_position.x / chunk_size),
		floor(player.global_position.z / chunk_size)
	)

	# Spawn nearby chunks
	for x in range(-render_distance, render_distance + 1):
		for z in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector2(player_chunk.x + x, player_chunk.y + z)
			if not water_tiles.has(chunk_pos):
				var instance = water_scene.instantiate()
				add_child(instance)
				instance.global_position = Vector3(chunk_pos.x * chunk_size, 0, chunk_pos.y * chunk_size)
				water_tiles[chunk_pos] = instance

	# Remove far chunks
	for key in water_tiles.keys():
		if key.distance_to(player_chunk) > render_distance:
			water_tiles[key].queue_free()
			water_tiles.erase(key)
