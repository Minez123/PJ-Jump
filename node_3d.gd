extends Node3D

#can custom
@export var platform_count: int = 50
@export var spacing_min: Vector3 = Vector3(-10, 2, -10)
@export var spacing_max: Vector3 = Vector3(10, 6, 10)
@export var custom_seed: int = -1  # -1 means random seed 

var rng := RandomNumberGenerator.new()

func _ready():
	var current_position = Vector3.ZERO
	if custom_seed == -1:
		custom_seed = Time.get_unix_time_from_system()  # Get a random seed based on time
		rng.seed = custom_seed
	$CanvasLayer/SeedLabel.text = "Seed: %d" % custom_seed

	for i in range(platform_count):
		var random_spacing = Vector3(
			rng.randf_range(spacing_min.x, spacing_max.x),
			rng.randf_range(spacing_min.y, spacing_max.y),
			rng.randf_range(spacing_min.z, spacing_max.z)
		)
		current_position += random_spacing

		# Create mesh instance
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.mesh.size = Vector3(5, 0.5, 5)
		mesh_instance.transform.origin = current_position

		# Create static body with collision
		var static_body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		collision.shape = BoxShape3D.new()
		collision.shape.size = Vector3(5, 0.5, 5)

		static_body.add_child(collision)
		mesh_instance.add_child(static_body)
		add_child(mesh_instance)
		
	
