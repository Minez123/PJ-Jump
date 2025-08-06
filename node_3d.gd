extends Node3D

#can custom
@export var platform_count: int = 50
@export var spacing_min: Vector3 = Vector3(-10, 1, -10)
@export var spacing_max: Vector3 = Vector3(10, 2, 10)
@export var custom_seed: int = -1  # -1 means random seed 
@export var collectible_scene: PackedScene
@export var item_spawn_chance: float = 0.5  #  chance to spawn item
@export var struc_scene: PackedScene
@export var scene_spawn_chance: float = 0.2  #
@export var NavLevel_scene: PackedScene
@export var Navscene_spawn_chance: float = 0.2  #

var jump_stats = get_max_jump_distance(9.0,2.0, 9.8 * 2.0, 8.0) #jump_power: float, jump_hight: float, gravity: float, move_speed: float
var max_jump_distance = jump_stats["horizontal"]
var max_vertical_step = jump_stats["vertical"]
var rng := RandomNumberGenerator.new()
var last_platform_pos: Vector3 = Vector3.ZERO  # to track for nav-level bridging
var spawned_positions: Array[Vector3] = []

var platforms_created = 0
var batch_phase = 0  # 0 = green batch, 1 = orange batch

func _ready():
	if custom_seed == -1:
		custom_seed = Time.get_unix_time_from_system()
	rng.seed = custom_seed
	$CanvasLayer/SeedLabel.text = "Seed: %d" % custom_seed

	generate_platform_batch(Vector3.ZERO)

func generate_platform_batch(start_position: Vector3):
	var last_position = start_position
	var local_created = 0

	while local_created < platform_count:
		
		var radius = rng.randf_range(spacing_min.length(), spacing_max.length())
		var theta = rng.randf_range(0, TAU)       
		var phi = rng.randf_range(0, PI/2)          

		var offset = Vector3(
			radius * sin(phi) * cos(theta),
			radius * cos(phi),
			radius * sin(phi) * sin(theta)
		)

		var next_position = last_position + offset


		var vertical_distance = abs(next_position.y - last_position.y)
		var total_distance = last_position.distance_to(next_position)



		# Reject if vertical or flat distance exceeds what player can reach
		var horizontal_vector = Vector3(next_position.x, last_position.y, next_position.z)
		var horizontal_distance = last_position.distance_to(horizontal_vector)

		if vertical_distance > max_vertical_step or horizontal_distance > max_jump_distance:
			continue  # skip this platform placement and try again
			var steps = ceil(total_distance / max_jump_distance)

			for j in range(1, int(steps)):
				var t = float(j) / steps
				var step_pos = last_position.lerp(next_position, t)
				step_pos.y = last_position.y
				spawn_platform(step_pos)
				platforms_created += 1
				local_created += 1
				if local_created >= platform_count:
					break

		if local_created < platform_count:
			spawn_platform(next_position)
			platforms_created += 1
			local_created += 1
			last_position = next_position
			last_platform_pos = next_position

		await get_tree().process_frame

	# After finishing first batch
	if batch_phase == 0:
		batch_phase = 1
		await get_tree().create_timer(0.2).timeout  # small pause
		var upward_start = last_platform_pos + Vector3(0, 0, 0)
		generate_platform_batch(upward_start)







func spawn_platform(pos: Vector3) -> void:
	var platform_size = Vector3(5, 0.5, 5)
	for existing_pos in spawned_positions:
		if pos.distance_to(existing_pos) < 2.0:
			return 

	spawned_positions.append(pos)

	# First check: will structure spawn?
	var spawn_structure = rng.randf() < scene_spawn_chance and struc_scene

	if spawn_structure:
		var structure = struc_scene.instantiate()
		structure.scale = Vector3(1, 1, 1)
		structure.position = pos
		add_child(structure)
		return  

	# Now continue with platform spawn if no structure is placed
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = platform_size
	mesh_instance.transform.origin = pos
	mesh_instance.rotation.y = rng.randf_range(0, TAU)

	var material = StandardMaterial3D.new()
	if batch_phase == 0:
		material.albedo_color = Color.GREEN
	else:
		material.albedo_color = Color.ORANGE

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
		collectible.position = pos + Vector3(0, platform_size.y / 2 + 0.5, 0)
		add_child(collectible)

	# Spawn nav level
	if batch_phase == 1 and rng.randf() < Navscene_spawn_chance and NavLevel_scene:
		var offset = Vector3(
			rng.randf_range(-80, 80),
			rng.randf_range(0, 0),
			rng.randf_range(-80, 80)
		)

		if offset.length() < 40:
			offset = offset.normalized() * 40

		var nav_pos = pos + offset
		var nav_structure = NavLevel_scene.instantiate()
		nav_structure.scale = Vector3(1, 1, 1)
		nav_structure.position = nav_pos
		add_child(nav_structure)


		# Bridge with platforms if too far
		var distance = pos.distance_to(nav_pos)
		if distance > max_jump_distance:
			var steps = ceil(distance / max_jump_distance)
			for i in range(1, int(steps)):
				var t = float(i) / steps
				var bridge_pos = pos.lerp(nav_pos, t)
				bridge_pos.y = pos.y  # flatten the path

				# Only spawn if not overlapping
				var too_close := false
				for existing_pos in spawned_positions:
					if bridge_pos.distance_to(existing_pos) < 5.0:
						too_close = true
						break
				if not too_close:
					spawn_platform(bridge_pos)


func get_max_jump_distance(jump_power: float, jump_hight: float, gravity: float, move_speed: float) -> Dictionary:
	var v = jump_power * jump_hight
	var g = gravity
	var t = (2 * v) / g  # time in air
	var horizontal_distance = jump_power * t  # forward velocity * time
	var vertical_distance = (v * v) / (2 * g)  # max height
	return {
		"horizontal": horizontal_distance,
		"vertical": vertical_distance
	}

	
	
