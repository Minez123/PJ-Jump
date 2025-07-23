extends Node3D

#can custom
@export var platform_count: int = 50
@export var spacing_min: Vector3 = Vector3(-20, 2, -20)
@export var spacing_max: Vector3 = Vector3(20, 6, 20)
@export var custom_seed: int = -1  # -1 means random seed 
@export var collectible_scene: PackedScene
@export var item_spawn_chance: float = 0.5  #  chance to spawn item
@export var struc_scene: PackedScene
@export var scene_spawn_chance: float = 0.2  #
@export var NavLevel_scene: PackedScene
@export var Navscene_spawn_chance: float = 0.2  #
@export var max_jump_distance: float = 15.0  # maximum jumpable distance between platforms
@export var max_vertical_step: float = 4.0
var rng := RandomNumberGenerator.new()



func _ready():
	await get_tree().process_frame
	var current_position = Vector3.ZERO
	if custom_seed == -1:
		custom_seed = Time.get_unix_time_from_system()
	rng.seed = custom_seed
	$CanvasLayer/SeedLabel.text = "Seed: %d" % custom_seed

	var last_position = current_position
	var platforms_created = 0

	while platforms_created < platform_count:
		var random_spacing = Vector3(
			rng.randf_range(spacing_min.x, spacing_max.x),
			rng.randf_range(spacing_min.y, spacing_max.y),
			rng.randf_range(spacing_min.z, spacing_max.z)
		)

		var next_position = last_position + random_spacing
		var horizontal_distance = Vector2(
			next_position.x - last_position.x,
			next_position.z - last_position.z
		).length()

		var vertical_distance = abs(next_position.y - last_position.y)
		var total_distance = last_position.distance_to(next_position)

		# If platform too high or too far, add extra steps
		if vertical_distance > max_vertical_step or total_distance > max_jump_distance:
			var steps = ceil(total_distance / max_jump_distance)

			for j in range(1, int(steps)):
				# Use linear interpolation, but keep Y the same as last_platform
				var t = float(j) / steps
				var step_pos = last_position.lerp(next_position, t)
				step_pos.y = last_position.y  # flatten Y for step
				spawn_platform(step_pos)
				platforms_created += 1
				if platforms_created >= platform_count:
					break

		# Now spawn the main next platform
		if platforms_created < platform_count:
			spawn_platform(next_position)
			platforms_created += 1
			last_position = next_position





func spawn_platform(pos: Vector3) -> void:
	var platform_size = Vector3(5, 0.5, 5)

	# First check: will structure spawn?
	var spawn_structure = rng.randf() < scene_spawn_chance and struc_scene

	if spawn_structure:
		var structure = struc_scene.instantiate()
		structure.scale = Vector3(2, 2, 2)
		structure.global_position = pos
		add_child(structure)
		return  # ⛔ Stop here: don't spawn the platform or other elements

	# Now continue with platform spawn if no structure is placed
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = platform_size
	mesh_instance.transform.origin = pos
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

	await get_tree().process_frame

	# Spawn collectible
	if rng.randf() < item_spawn_chance and collectible_scene:
		var collectible = collectible_scene.instantiate()
		collectible.global_position = pos + Vector3(0, platform_size.y / 2 + 0.5, 0)
		add_child(collectible)

	# Spawn nav level
	if rng.randf() < Navscene_spawn_chance and NavLevel_scene:
		var nav_structure = NavLevel_scene.instantiate()
		nav_structure.scale = Vector3(2, 2, 2)
		nav_structure.global_position = pos
		add_child(nav_structure)

	
	


func _on_character_ready() -> void:
	pass # Replace with function body.
