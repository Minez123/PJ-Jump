extends Node3D

@export var pathable_platforms: Array[PackedScene]  # index 0 group
@export var decoration_platforms: Array[PackedScene]  # other random objects
@export var number_of_platforms: int = 20
@export var spawn_range: Vector3 = Vector3(50, 0, 50)
@export var pathable_ratio := 0.4


var spawned_pathable_platforms: Array[Node3D] = []

func _ready():
	randomize()
	spawn_platforms()
	connect_pathable_platforms()

func spawn_platforms():
	for i in number_of_platforms:
		var is_pathable = randf() < pathable_ratio
		var scene: PackedScene

		if is_pathable:
			scene = pathable_platforms[randi() % pathable_platforms.size()]
		else:
			scene = decoration_platforms[randi() % decoration_platforms.size()]

		var instance = scene.instantiate() as Node3D
		var x = randf_range(-spawn_range.x, spawn_range.x)
		var y = randf_range(0, 5)
		var z = randf_range(-spawn_range.z, spawn_range.z)
		instance.global_position = Vector3(x, y, z)

		add_child(instance)

		if is_pathable:
			spawned_pathable_platforms.append(instance)


func connect_pathable_platforms():
	for platform in spawned_pathable_platforms:
		var closest: Node3D = null
		var closest_distance = INF

		for other in spawned_pathable_platforms:
			if other == platform:
				continue

			var dist = platform.global_position.distance_to(other.global_position)
			if dist < closest_distance:
				closest = other
				closest_distance = dist

		if closest:
			create_path_between(platform.global_position, closest.global_position)

func create_path_between(start: Vector3, end: Vector3):
	var path = Path3D.new()
	var curve = Curve3D.new()
	curve.add_point(start)
	curve.add_point((start + end) / 2 + Vector3.UP * 2)  # optional mid-arch
	curve.add_point(end)
	path.curve = curve
	add_child(path)
