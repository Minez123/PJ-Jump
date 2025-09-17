extends Node3D

#can custom
@export var platform_count: int = 50
@export var spacing_min: Vector3 = Vector3(10, 0, 10)
@export var spacing_max: Vector3 = Vector3(10, 2, 10)
@export var custom_seed: int = -1  # -1 means random seed 
@export var collectible_scene: PackedScene
@export var re_collectible_scene: PackedScene
@export var item_spawn_chance: float = 0.5  #  chance to spawn item
@export var plat_up_scene: PackedScene
@export var scene_spawn_chance: float = 0.05  #
@export var NavLevel_scene: PackedScene
@export var NavLevel2_scene: PackedScene
@export var Navscene_spawn_chance: float = 0.1  #
@export var platform_scene: PackedScene
@export var plat_side_scene: PackedScene
@export var sidescene_spawn_chance: float = 0.05  #
@export var shop_scene: PackedScene
@export var goal_scene: PackedScene
var jump_stats = get_max_jump_distance(9.0,1.5, 9.8 * 2.0) #jump_power: float, jump_hight: float, gravity: float
var max_jump_distance = jump_stats["horizontal"]
var max_vertical_step = jump_stats["vertical"]
var rng := RandomNumberGenerator.new()
var last_platform_pos: Vector3 = Vector3.ZERO  # to track for nav-level bridging
var spawned_positions: Array[Vector3] = []
var platform_size: Vector3
var plat_up_size: Vector3
var plat_side_size: Vector3
var nav_size: Vector3
var last_spawned_size: Vector3 = Vector3.ZERO
var platforms_created = 0
var batch_phase = 0  # 0 = green batch, 1 = orange batch
var did_branch := false
var shop_size: Vector3
var collectible
func _ready():
	if custom_seed == -1:
		custom_seed = Time.get_unix_time_from_system()
	rng.seed = custom_seed
	$CanvasLayer/SeedLabel.text = "Seed: %d" % custom_seed
	platform_size = get_scene_size(platform_scene)
	plat_up_size = get_scene_size(plat_up_scene)
	nav_size = get_scene_size(NavLevel_scene)
	plat_side_size = get_scene_size(plat_side_scene)
	shop_size = get_scene_size(shop_scene)
	print("Shop size:", shop_size)
	print("Platform size:", platform_size)
	print("Structure size:", plat_up_size)
	print("Nav size:", nav_size)
	print("side size:", plat_side_size)


	generate_platform_batch(Vector3.ZERO, 0)  


func generate_platform_batch(start_position: Vector3, branch_id: int = 0):
	var last_post = start_position
	var local_created = 0

	while local_created < platform_count:
		var offset = get_random_offset(platform_size, 1.0)
		var next_position = last_post + offset

		last_post = spawn_platform(next_position, branch_id)
		platforms_created += 1
		local_created += 1
		last_platform_pos = last_post

		await get_tree().process_frame

	# Spawn goal at the end of each branch
	if branch_id in [1, 2] and batch_phase == 2:
		spawn_goal(last_post, last_spawned_size, branch_id)

	# First split (Batch 1)
	if not did_branch and branch_id == 0:
		did_branch = true
		await get_tree().create_timer(0.3).timeout
		generate_platform_batch(last_post, 1)  # branch 1
		batch_phase = 1
		generate_platform_batch(last_post, 2)  # branch 2

	# After Batch 1, continue each branch into Batch 2
	elif branch_id in [1, 2] and batch_phase == 1:
		batch_phase = 2
		await get_tree().create_timer(0.3).timeout
		generate_platform_batch(last_post, branch_id)  # continue same branch

func spawn_platform(pos: Vector3, branch_id: int = 0) -> Vector3:
	var roll = rng.randf()
	var next_pos: Vector3
	var current_size: Vector3

	# === Normal structure spawn logic ===
	if roll < scene_spawn_chance and plat_up_scene:
		var spawn_pos = get_structure_position(pos, plat_up_size)
		next_pos = spawn_structure(spawn_pos, branch_id)
		current_size = plat_up_size

	elif roll < scene_spawn_chance + sidescene_spawn_chance and plat_side_scene:
		var spawn_pos = get_moveplatform_position(pos, plat_side_size)
		next_pos = spawn_moveplatform(spawn_pos, branch_id)
		current_size = plat_side_size

	elif batch_phase == 1 and rng.randf() < Navscene_spawn_chance and NavLevel_scene:
		var spawn_pos = get_nav_level_position(pos, nav_size)
		next_pos = spawn_nav_level(spawn_pos, branch_id)
		current_size = nav_size

		# bridge logic stays here
		spawn_bridge(pos, spawn_pos, last_spawned_size, nav_size, branch_id)

	else:
		var spawn_pos = get_normal_platform_position(pos, platform_size)
		next_pos = spawn_normal_platform(spawn_pos, branch_id)
		current_size = platform_size

	# === Spawn collectibles ===
	spawn_collectible(next_pos, 1.0)

	# === Shop logic (only once, at batch 1) ===
	if batch_phase == 1 and not shop_spawned:
		var shop_pos = get_nav_level_position(pos, shop_size)
		spawn_shop(shop_pos, shop_size, branch_id)
		spawn_bridge(pos, shop_pos, last_spawned_size, shop_size, branch_id)

	# Store last size
	last_spawned_size = current_size
	return next_pos


func _apply_branch_color(mesh_instance: MeshInstance3D, branch_id: int) -> void:
	if not mesh_instance:
		return
	var mat = mesh_instance.mesh.surface_get_material(0)
	if not mat:
		return
	mat = mat.duplicate()
	match branch_id:
		1: mat.albedo_color = Color.RED
		2: mat.albedo_color = Color.BLUE
	mesh_instance.set_surface_override_material(0, mat)

# === Normal Platform ===
func spawn_normal_platform(pos: Vector3, branch_id: int) -> Vector3:
	var platform_instance = platform_scene.instantiate()
	platform_instance.position = pos
	platform_instance.rotation.y = rng.randf_range(0, TAU)

	var mesh_instance = platform_instance.get_node_or_null("MeshInstance3D/square_forest_detail") as MeshInstance3D
	_apply_branch_color(mesh_instance, branch_id)

	add_child(platform_instance)

	# return top position
	return Vector3(pos.x, pos.y + platform_size.y, pos.z)


func get_normal_platform_position(pos: Vector3, current_size: Vector3) -> Vector3:
	var offset = get_random_offset(current_size, 1.0)
	return pos + offset


# === Structure ===
func spawn_structure(pos: Vector3, branch_id: int) -> Vector3:
	var instance = plat_up_scene.instantiate()
	instance.position = pos
	instance.rotation.y = rng.randf_range(0, TAU)

	var mesh_instance = instance.get_node_or_null("AnimatableBody3D/square_forest_detail") as MeshInstance3D
	_apply_branch_color(mesh_instance, branch_id)

	add_child(instance)

	return Vector3(pos.x, pos.y + plat_up_size.y, pos.z)


func get_structure_position(pos: Vector3, current_size: Vector3) -> Vector3:
	var offset = get_random_offset(current_size, 1.0)
	return pos + offset


# === Moving Platform ===
func spawn_moveplatform(pos: Vector3, branch_id: int) -> Vector3:
	var instance = plat_side_scene.instantiate()
	instance.position = pos
	instance.rotation.y = rng.randf_range(0, TAU)

	var mesh_instance = instance.get_node_or_null("ABody3D/square_forest_detail") as MeshInstance3D
	_apply_branch_color(mesh_instance, branch_id)

	add_child(instance)

	return Vector3(pos.x, pos.y + plat_side_size.y, pos.z)


func get_moveplatform_position(pos: Vector3, current_size: Vector3) -> Vector3:
	var offset = get_random_offset(current_size, 1.0)
	return pos + offset


# === Nav Level ===
func spawn_nav_level(pos: Vector3, branch_id: int) -> Vector3:
	var nav_instance = NavLevel_scene.instantiate()
	if rng.randf() < 0.5:
		nav_instance = NavLevel2_scene.instantiate()
	nav_instance.position = pos
	add_child(nav_instance)

	return Vector3(pos.x, pos.y + nav_size.y, pos.z)


func get_nav_level_position(pos: Vector3, current_size: Vector3) -> Vector3:
	var offset = get_random_offset(current_size, 1.0, current_size.length() + 1.0)
	offset.y = 0  # keep Y same level
	return pos + offset



	
# === Spawn collectible ===
func spawn_collectible(top_pos: Vector3,offset: float) -> void:
	if collectible_scene and rng.randf() < item_spawn_chance:
		if 	rng.randf() < item_spawn_chance:
			collectible = re_collectible_scene.instantiate()
		else:
			collectible = collectible_scene.instantiate()

		collectible.position = Vector3(
			top_pos.x,
			top_pos.y + offset,
			top_pos.z
		)

		add_child(collectible)





func spawn_bridge(start_pos: Vector3, end_pos: Vector3, start_size: Vector3, end_size: Vector3, branch_id: int) -> void:
	# Find direction from start to end
	var dir = (end_pos - start_pos).normalized()

	# Offset each position toward its nearest edge
	var adjusted_start = start_pos 
	var adjusted_end   = end_pos - dir * (max(end_size.x, end_size.z) * 0.5)

	var distance = adjusted_start.distance_to(adjusted_end)
	if distance <= max_jump_distance:
		return  # No bridge needed

	var steps = ceil(distance / max_jump_distance)
	for i in range(1, int(steps)):
		var t = float(i) / steps
		var bridge_pos = adjusted_start.lerp(adjusted_end, t)
		spawn_normal_platform(bridge_pos, branch_id)






# === Shop spawn control ===
var shop_spawned := false

func spawn_shop(pos: Vector3, parent_size: Vector3, branch_id: int) -> void:

	shop_spawned = true  
	var shop_pos = pos + get_random_offset(shop_size, 1.0, parent_size.length() + 1.0)
	shop_pos.y = pos.y

	var shop_instance = shop_scene.instantiate()
	shop_instance.position = shop_pos
	add_child(shop_instance)

	print("🛒 Shop spawned at: ", shop_pos)

	spawn_bridge(pos, shop_pos, parent_size, shop_size, branch_id)

	var top_pos = Vector3(shop_pos.x, shop_pos.y + shop_size.y, shop_pos.z)

func spawn_goal(pos: Vector3, parent_size: Vector3, branch_id: int) -> void:
	if not goal_scene:
		return

	var goal_instance = goal_scene.instantiate()
	goal_instance.position = pos
	add_child(goal_instance)

	print("🏁 Goal spawned for branch", branch_id, "at", pos)




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
func aabb_transformed(aabb: AABB, current_transform: Transform3D) -> AABB:
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
		var world_corner = current_transform * corner  # Apply transform
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
