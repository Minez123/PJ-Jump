extends Node3D

#can custom
@export var platform_count: int = 50
@export var spacing_min: Vector3 = Vector3(10, 0, 10)
@export var spacing_max: Vector3 = Vector3(10, 2, 10)
@export var custom_seed: int = -1  # -1 means random seed 
@export var collectible_scene: PackedScene
@export var item_spawn_chance: float = 0.5  #  chance to spawn item
@export var plat_up_scene: PackedScene
@export var scene_spawn_chance: float = 0.2  #
@export var NavLevel_scene: PackedScene
@export var Navscene_spawn_chance: float = 0.2  #
@export var platform_scene: PackedScene

var jump_stats = get_max_jump_distance(9.0,1.5, 9.8 * 2.0) #jump_power: float, jump_hight: float, gravity: float
var max_jump_distance = jump_stats["horizontal"]
var max_vertical_step = jump_stats["vertical"]
var rng := RandomNumberGenerator.new()
var last_platform_pos: Vector3 = Vector3.ZERO  # to track for nav-level bridging
var spawned_positions: Array[Vector3] = []
var platform_size: Vector3
var plat_up_size: Vector3
var nav_size: Vector3
var last_spawned_size: Vector3 = Vector3.ZERO
var platforms_created = 0
var batch_phase = 0  # 0 = green batch, 1 = orange batch

func _ready():
	if custom_seed == -1:
		custom_seed = Time.get_unix_time_from_system()
	rng.seed = custom_seed
	$CanvasLayer/SeedLabel.text = "Seed: %d" % custom_seed
	platform_size = get_scene_size(platform_scene)
	plat_up_size = get_scene_size(plat_up_scene)
	nav_size = get_scene_size(NavLevel_scene)

	print("Platform size:", platform_size)
	print("Structure size:", plat_up_size)
	print("Nav size:", nav_size)


	generate_platform_batch(Vector3.ZERO)

func generate_platform_batch(start_position: Vector3):
	var last_post = start_position   # this will store the top position
	var local_created = 0

	while local_created < platform_count:
		var offset = get_random_offset(platform_size, 1.0)
		var next_position = last_post + offset   # use top position

		var vertical_distance = abs(next_position.y - last_post.y)
		var total_distance = last_post.distance_to(next_position)

		if local_created < platform_count:
			last_post = spawn_platform(next_position)  # update with top position
			platforms_created += 1
			local_created += 1
			last_platform_pos = last_post

		await get_tree().process_frame

	# After finishing first batch
	if batch_phase == 0:
		batch_phase = 1
		await get_tree().create_timer(0.2).timeout
		generate_platform_batch(last_platform_pos)


# === Spawn a single platform batch object ===
func spawn_platform(pos: Vector3) -> Vector3:
	# Avoid overlap
	for existing_pos in spawned_positions:
		if pos.distance_to(existing_pos) < 2.0:
			return pos
	spawned_positions.append(pos)

	var top_pos: Vector3
	var current_size: Vector3

	if rng.randf() < scene_spawn_chance and plat_up_scene:
		var result = spawn_structure(pos)
		top_pos = result[0]
		current_size = result[1]
	else:
		var result = spawn_normal_platform(pos, last_spawned_size)
		top_pos = result[0]
		current_size = result[1]

	last_spawned_size = current_size

	# Spawn collectible slightly above the top of this object
	spawn_collectible(top_pos, 0.0)

	# Spawn nav-level if in batch phase 1
	if batch_phase == 1 and rng.randf() < Navscene_spawn_chance and NavLevel_scene:
		var result = spawn_nav_level(top_pos, current_size)
		top_pos = result[0]
		current_size = result[1]

	return top_pos




# === Spawn a normal platform ===
func spawn_normal_platform(pos: Vector3, last_size: Vector3) -> Array:
	var platform_instance = platform_scene.instantiate()
	var platform_pos = pos


	platform_instance.position = platform_pos
	platform_instance.rotation.y = rng.randf_range(0, TAU)

	# Material recolor
	var mesh_instance = platform_instance.get_node_or_null("MeshInstance3D/square_forest_detail") as MeshInstance3D
	if mesh_instance:
		var mat = mesh_instance.mesh.surface_get_material(0)
		if mat:
			mat = mat.duplicate()
			if batch_phase != 0:
				mat.albedo_color = Color.ORANGE
			mesh_instance.set_surface_override_material(0, mat)

	add_child(platform_instance)

	var top_pos = Vector3(platform_pos.x, platform_pos.y + platform_size.y, platform_pos.z)
	return [top_pos, platform_size]


# === Spawn a structure ===
func spawn_structure(pos: Vector3) -> Array:
	var instance = plat_up_scene.instantiate()
	instance.position = pos
	add_child(instance)

	var top_pos = Vector3(pos.x, pos.y + plat_up_size.y, pos.z)
	return [top_pos, plat_up_size]


# === Spawn collectible ===
func spawn_collectible(top_pos: Vector3, offset: float ) -> void:
	if collectible_scene and rng.randf() < item_spawn_chance:
		var collectible = collectible_scene.instantiate()
		collectible.position = Vector3(top_pos.x, top_pos.y + offset, top_pos.z)
		add_child(collectible)


# === Spawn nav-level with bridging ===
func spawn_nav_level(pos: Vector3, parent_size: Vector3) ->  Array:
	var nav_pos = pos + get_random_offset(nav_size, 1.0, parent_size.length() + 1.0)
	nav_pos.y=pos.y
	var nav_instance = NavLevel_scene.instantiate()
	nav_instance.position = nav_pos
	add_child(nav_instance)

	# Call bridge logic
	if batch_phase == 1:
		spawn_bridge(pos, nav_pos, parent_size,nav_size)
	var top_pos = Vector3(nav_pos.x, nav_pos.y + nav_size.y, nav_pos.z)
	return [top_pos, nav_size]



func spawn_bridge(start_pos: Vector3, end_pos: Vector3, start_size: Vector3, end_size: Vector3) -> void:
	# Find direction from start to end
	var dir = (end_pos - start_pos).normalized()

	# Offset each position toward its nearest edge
	var adjusted_start = start_pos + dir * (max(start_size.x, start_size.z) * 0.5)
	var adjusted_end   = end_pos - dir * (max(end_size.x, end_size.z) * 0.5)

	var distance = adjusted_start.distance_to(adjusted_end)
	if distance <= max_jump_distance:
		return  # No bridge needed

	var steps = ceil(distance / max_jump_distance)
	for i in range(1, int(steps)):
		var t = float(i) / steps
		var bridge_pos = adjusted_start.lerp(adjusted_end, t)

		var too_close := false
		for existing_pos in spawned_positions:
			if bridge_pos.distance_to(existing_pos) < 5.0:
				too_close = true
				break

		if not too_close:
			spawn_normal_platform(bridge_pos, start_size)






		






func get_max_jump_distance(jump_power: float, jump_hight: float, gravity: float) -> Dictionary:
	var v = jump_power * jump_hight
	var g = gravity
	var t = (2 * v) / g  # time in air
	var horizontal_distance = jump_power * t  # forward velocity * time
	var vertical_distance = (v * v) / (2 * g)  # max height
	return {
		"horizontal": horizontal_distance,
		"vertical": vertical_distance
	}


# Apply a Transform3D to an AABB
func aabb_transformed(aabb: AABB, transform: Transform3D) -> AABB:
	var corners = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0, 0),
		aabb.position + Vector3(0, aabb.size.y, 0),
		aabb.position + Vector3(0, 0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
		aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
		aabb.position + aabb.size
	]

	var new_aabb = AABB(corners[0], Vector3.ZERO)
	for corner in corners:
		var world_corner = transform * corner  # Apply transform
		new_aabb = new_aabb.merge(AABB(world_corner, Vector3.ZERO))

	return new_aabb

# Recursively collect all MeshInstance3D AABBs transformed into world space
func collect_mesh_aabb(node: Node, parent_transform: Transform3D) -> AABB:
	var total_aabb = AABB(Vector3.ZERO, Vector3.ZERO)
	var first = true

	var current_transform = parent_transform
	if node is Node3D:
		current_transform = parent_transform * node.transform

	if node is MeshInstance3D and node.mesh:
		var mesh_aabb = node.mesh.get_aabb()
		var world_aabb = aabb_transformed(mesh_aabb, current_transform)
		total_aabb = world_aabb
		first = false

	for child in node.get_children():
		var child_aabb = collect_mesh_aabb(child, current_transform)
		if child_aabb.size != Vector3.ZERO:
			if first:
				total_aabb = child_aabb
				first = false
			else:
				total_aabb = total_aabb.merge(child_aabb)

	return total_aabb


# Get the dynamic size of a PackedScene
func get_scene_size(scene: PackedScene) -> Vector3:
	if not scene:
		return Vector3.ONE

	var instance = scene.instantiate()
	var aabb = collect_mesh_aabb(instance, Transform3D.IDENTITY)
	instance.queue_free()
	return aabb.size



func get_random_offset(base_size: Vector3, scaleoff: float, padding: float = 2.0) -> Vector3:
	# Horizontal spread radius (based on platform size & scale)
	var base_radius = max(base_size.x, base_size.z)
	var min_radius = base_radius + padding
	var max_radius = base_radius * scaleoff + padding
	
	# Random angle + radius for XZ spread
	var radius = rng.randf_range(min_radius, max_radius)
	var theta = rng.randf_range(0, TAU)

	# Random Y, but limited
	var y_offset = rng.randf_range(0.5, max_vertical_step)

	return Vector3(
		radius * cos(theta) * 1.2,  # X spread
		y_offset,                   # ✅ capped Y
		radius * sin(theta) * 1.2   # Z spread
	)
