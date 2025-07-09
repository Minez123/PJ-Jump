extends Node3D

#can custom
@export var platform_count: int = 50
@export var spacing_min: Vector3 = Vector3(-10, 2, -10)
@export var spacing_max: Vector3 = Vector3(10, 6, 10)
@export var custom_seed: int = -1  # -1 means random seed 
@export var collectible_scene: PackedScene
@export var item_spawn_chance: float = 0.5  #  chance to spawn item
@export var struc_scene: PackedScene
@export var scene_spawn_chance: float = 0.5  #


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

		var platform_size = Vector3(5, 0.5, 5)

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.mesh.size = platform_size
		mesh_instance.transform.origin = current_position
		mesh_instance.rotation.y = rng.randf_range(0, TAU)

		var material = StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(rng.randf(), 0.7, 0.9)
		mesh_instance.material_override = material

		var static_body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		collision.shape = BoxShape3D.new()
		collision.shape.size = platform_size
		static_body.add_child(collision)
		mesh_instance.add_child(static_body)
		add_child(mesh_instance)

		# Spawn collectible
		if rng.randf() < item_spawn_chance and collectible_scene:
			var collectible = collectible_scene.instantiate()
			collectible.global_position = current_position + Vector3(0, platform_size.y / 2 + 0.5, 0)
			add_child(collectible)

		# Spawn random scene
		if rng.randf() < scene_spawn_chance and struc_scene:
			var structure = struc_scene.instantiate()
			structure.scale = Vector3(2, 2, 2) 
			structure.global_position = current_position + Vector3(0, 0, 5)
			add_child(structure)



		
	
