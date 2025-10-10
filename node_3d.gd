extends Node3D

#can custom
@export var platform_count: int = 50
@export var spacing_min: Vector3 = Vector3(10, 0, 10)
@export var spacing_max: Vector3 = Vector3(10, 2, 10)
@export var custom_seed: int = GameData.custom_seed
@export var collectible_scene: PackedScene
@export var key_scenes: Array[PackedScene] = []
@export var item_spawn_chance: float = 0.5  #  chance to spawn item
@export var plat_up_scene: PackedScene
@export var scene_spawn_chance: float = 0.05  #
@export var NavLevel_scene: PackedScene
@export var NavLevel2_scene: PackedScene
@export var NavLevel3_scene: PackedScene
@export var Navscene_spawn_chance: float = 0.1  #
@export var platform_scene: PackedScene
@export var slime_platform_scene: PackedScene
@export var slime_platform_spawn_chance: float = 0.05  #
@export var ice_platform_scene: PackedScene
@export var ice_platform_spawn_chance: float = 0.05  #
@export var plat_side_scene: PackedScene
@export var sidescene_spawn_chance: float = 0.05  #
@export var shop_scene: PackedScene
@export var goal_scene: PackedScene
@export var ice_dun: PackedScene
@export var slime_dun: PackedScene
signal world_generation_finished
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
var goal_size: Vector3
var last_spawned_size: Vector3 = Vector3.ZERO
var platforms_created = 0
var batch_phase = 0  # 0 = green batch, 1 = orange batch
var did_branch := false
var shop_size: Vector3
var ice_size: Vector3
var slime_size: Vector3
var collectible



func _ready():

	if GameData.loaded_save_data:
		custom_seed = GameData.loaded_save_data["seed"]
	elif custom_seed == -1:
		custom_seed = Time.get_unix_time_from_system()
	add_to_group("world")
	rng.seed = custom_seed
	$CanvasLayer/SeedLabel.text = "Seed: %d" % custom_seed
	platform_size = get_scene_size(platform_scene)
	plat_up_size = get_scene_size(plat_up_scene)
	nav_size = get_scene_size(NavLevel_scene)
	plat_side_size = get_scene_size(plat_side_scene)
	shop_size = get_scene_size(shop_scene)
	ice_size = get_scene_size(ice_dun)
	slime_size = get_scene_size(slime_dun)
	goal_size = get_scene_size(goal_scene)



	generate_platform_batch(Vector3.ZERO, 0)  

var branch_phases := {0: 0, 1: 0, 2: 0}
func generate_platform_batch(start_position: Vector3, branch_id: int = 0):
	var last_post = start_position
	var local_created = 0
	var last_size = platform_size   # default to base size for first spawn

	while local_created < platform_count:
		# use last_size instead of fixed platform_size
		var offset = get_random_offset(last_size, 1.0, 2.0, branch_id)
		var next_position = last_post + offset

		var result = spawn_platform(next_position, branch_id)
		last_post = result
		last_size = last_spawned_size  # update size from actual spawn

		platforms_created += 1
		local_created += 1
		last_platform_pos = last_post

		if platform_count - platforms_created <= 10 and not shop_spawned:
			spawn_shop(last_post, last_size, branch_id)
		elif local_created >= 20 and not ice_spawned and batch_phase == 1 and branch_id == 1:
			spawn_ice_dun(last_post, last_size, branch_id)
		elif local_created >= 20 and not slime_spawned and batch_phase == 1 and branch_id == 2:
			spawn_slime_dun(last_post, last_size, branch_id)

		await get_tree().process_frame






		
	

	# First split (Batch 1)
	if branch_id == 0 and branch_phases[0] == 0:
		branch_phases[0] = 1
		await get_tree().create_timer(0.3).timeout
		branch_phases[1] = 1
		branch_phases[2] = 1
		generate_platform_batch(last_post, 1)
		generate_platform_batch(last_post, 2)
		batch_phase=1
		

	elif branch_id in [1, 2] and branch_phases[branch_id] == 1:
		branch_phases[branch_id] = 2
		await get_tree().create_timer(0.3).timeout
		generate_platform_batch(last_post, branch_id)
		
	else:
		spawn_goal(last_post, last_spawned_size, branch_id)
		branch_phases[branch_id]=3
		print(local_created , branch_id,branch_phases,batch_phase)
		emit_signal("world_generation_finished")
		

		




func spawn_platform(pos: Vector3, branch_id: int = 0) -> Vector3:
	var result : Array
	var roll = rng.randf()

	if roll < scene_spawn_chance and plat_up_scene:
		result = spawn_structure(pos,branch_id)
	elif roll < scene_spawn_chance + sidescene_spawn_chance and plat_side_scene:
		result = spawn_moveplatform(pos,branch_id)
	elif roll <  slime_platform_spawn_chance and batch_phase >= 1 and branch_id == 2:
		result = spawn_slime_platform(pos,branch_id)
	elif roll <  ice_platform_spawn_chance and batch_phase >= 1 and branch_id == 1:
		result = spawn_ice_platform(pos,branch_id)
	else:
		result = spawn_normal_platform(pos, branch_id)

	var top_pos = result[0]
	var current_size = result[1]

	last_spawned_size = current_size
	spawn_collectible(top_pos, 1,branch_id)

	if batch_phase >= 1 and rng.randf() < Navscene_spawn_chance and NavLevel_scene:
		result = spawn_nav_level(top_pos, current_size, branch_id)
		top_pos = result[0]
		current_size = result[1]

	return top_pos

var branch_colors = {
	1: Color.RED,
	2: Color.BLUE,
}

func _apply_branch_color(mesh_instance: MeshInstance3D, branch_id: int) -> void:
	if not mesh_instance:
		return
	var mat = mesh_instance.mesh.surface_get_material(0)
	if not mat:
		return
	mat = mat.duplicate()

	if branch_colors.has(branch_id):
		mat.albedo_color = branch_colors[branch_id]

	mesh_instance.set_surface_override_material(0, mat)



func spawn_normal_platform(pos: Vector3, branch_id: int) -> Array:
	var platform_instance = platform_scene.instantiate()
	platform_instance.position = pos
	platform_instance.rotation.y = rng.randf_range(0, TAU)
	


	var mesh_instance = platform_instance.get_node_or_null("square_forest_detail") as MeshInstance3D
	_apply_branch_color(mesh_instance, branch_id)

	add_child(platform_instance)


	return [Vector3(pos.x, pos.y +platform_size .y, pos.z), platform_size]


func spawn_slime_platform(pos: Vector3, branch_id: int) -> Array:
	var platform_instance = slime_platform_scene.instantiate()
	platform_instance.position = pos
	platform_instance.rotation.y = rng.randf_range(0, TAU)

	var random_scale = rng.randf_range(0.8, 1.5)
	platform_instance.scale *=  random_scale

	var mesh_instance = platform_instance.get_node_or_null("MeshInstance3D/square_forest_detail") as MeshInstance3D
	_apply_branch_color(mesh_instance, branch_id)

	add_child(platform_instance)

	var scaled_size = platform_size * random_scale
	return [Vector3(pos.x, pos.y + scaled_size.y, pos.z), scaled_size]


func spawn_ice_platform(pos: Vector3, branch_id: int) -> Array:
	var platform_instance = ice_platform_scene.instantiate()
	platform_instance.position = pos
	platform_instance.rotation.y = rng.randf_range(0, TAU)

	var random_scale = rng.randf_range(0.8, 1.5)
	platform_instance.scale *= random_scale

	var mesh_instance = platform_instance.get_node_or_null("MeshInstance3D/square_forest_detail") as MeshInstance3D
	_apply_branch_color(mesh_instance, branch_id)

	add_child(platform_instance)

	var scaled_size = platform_size * random_scale
	return [Vector3(pos.x, pos.y + scaled_size.y, pos.z), scaled_size, true]


func spawn_structure(pos: Vector3, branch_id: int) -> Array:
	var instance = plat_up_scene.instantiate()
	instance.position = pos
	instance.rotation.y = rng.randf_range(0, TAU)

	var random_scale = rng.randf_range(0.8, 1.5)
	instance.scale *=  random_scale

	var mesh_instance = instance.get_node_or_null("AnimatableBody3D/square_forest_detail") as MeshInstance3D
	_apply_branch_color(mesh_instance, branch_id)

	add_child(instance)

	var scaled_size = plat_up_size * random_scale
	return [Vector3(pos.x, pos.y + scaled_size.y, pos.z), scaled_size]


func spawn_moveplatform(pos: Vector3, branch_id: int) -> Array:
	var instance = plat_side_scene.instantiate()
	instance.position = pos
	instance.rotation.y = rng.randf_range(0, TAU)

	var random_scale = rng.randf_range(0.8, 1.5)
	instance.scale *=  random_scale

	var mesh_instance = instance.get_node_or_null("ABody3D/square_forest_detail") as MeshInstance3D
	_apply_branch_color(mesh_instance, branch_id)

	add_child(instance)

	var scaled_size = platform_size * random_scale
	var forward = instance.global_transform.basis.z.normalized()
	var offset = forward * plat_side_size.z * 0.8 * random_scale
	return [pos + offset, scaled_size]


var branch_key_index := {}
	
func spawn_collectible(top_pos: Vector3, offset: float, branch_id: int) -> void:
	if not branch_key_index.has(branch_id):
		branch_key_index[branch_id] = 0

	if key_scenes.size() > 0 and rng.randf() < 0.1 and branch_id>0:
		var index = branch_key_index[branch_id]
		if index < key_scenes.size():
			var key_instance = key_scenes[index].instantiate()
			key_instance.position = top_pos + Vector3(0, offset + 2, 0)
			add_child(key_instance)

			branch_key_index[branch_id] += 1
		else:
			print("Branch", branch_id, "has spawned all keys already.")

	elif collectible_scene and rng.randf() < item_spawn_chance:
		collectible = collectible_scene.instantiate()
		collectible.position = top_pos + Vector3(0, offset, 0)
		add_child(collectible)






# === Spawn nav-level with bridging ===
func spawn_nav_level(pos: Vector3, parent_size: Vector3,branch_id: int) ->  Array:
	var nav_pos = pos + get_random_offset(nav_size, 1.0, parent_size.length() + 1.0,branch_id)
	nav_pos.y=pos.y
	var nav_instance = NavLevel_scene.instantiate()
	if  rng.randf() < 0.3:
		nav_instance = NavLevel2_scene.instantiate()
	elif rng.randf() < 0.6:
		nav_instance = NavLevel3_scene.instantiate()
	nav_instance.position = nav_pos
	add_child(nav_instance)
	spawn_bridge(pos, nav_pos, parent_size,nav_size,branch_id,false)
	var top_pos = Vector3(nav_pos.x, nav_pos.y + nav_size.y, nav_pos.z)
	return [top_pos, nav_size]



func spawn_bridge(start_pos: Vector3, end_pos: Vector3, start_size: Vector3, end_size: Vector3, branch_id: int, full: bool) -> void:
	var dir = (end_pos - start_pos).normalized()
	var jumpdis = max_jump_distance
	if full:
		jumpdis *= 0.5

	# Adjust start and end
	var start_offset = max(start_size.x, start_size.z) * 0.5
	var end_offset   = max(end_size.x, end_size.z) * 0.5

	# ✅ Clamp offsets so they don't "eat" the whole distance
	var total_dist = start_pos.distance_to(end_pos)
	start_offset = min(start_offset, total_dist * 0.4)
	end_offset   = min(end_offset, total_dist * 0.4)

	var adjusted_start = start_pos + dir * start_offset
	var adjusted_end   = end_pos   - dir * end_offset

	var distance = adjusted_start.distance_to(adjusted_end)
	if distance <= max_jump_distance:
		return

	var steps = ceil(distance / jumpdis)
	for i in range(1, int(steps)):
		var t = float(i) / steps
		var bridge_pos = adjusted_start.lerp(adjusted_end, t)
		spawn_normal_platform(bridge_pos, branch_id)







# === Shop spawn control ===
var shop_spawned := false

func spawn_shop(pos: Vector3, parent_size: Vector3, branch_id: int) -> void:

	shop_spawned = true  
	var shop_pos = pos + get_random_offset(shop_size, 1.0, parent_size.length() + 1.0,branch_id)
	shop_pos.y = pos.y

	var shop_instance = shop_scene.instantiate()
	shop_instance.position = shop_pos
	add_child(shop_instance)

	print("🛒 Shop spawned at: ", shop_pos)

	spawn_bridge(pos, shop_pos, parent_size, shop_size, branch_id,false)



var ice_spawned := false

func spawn_ice_dun(pos: Vector3, parent_size: Vector3, branch_id: int) -> void:

	ice_spawned = true  
	var dun_pos = pos + get_random_offset(ice_size*2, 1.0, parent_size.length() + 1.0,branch_id)
	dun_pos.y = pos.y

	var ice_instance = ice_dun.instantiate()
	ice_instance.position =  dun_pos
	add_child(ice_instance)

	print("🛒 ice spawned at: ", dun_pos)

	spawn_bridge(pos,  dun_pos, parent_size, ice_size, branch_id,true)
var slime_spawned := false

func spawn_slime_dun(pos: Vector3, parent_size: Vector3, branch_id: int) -> void:

	slime_spawned = true  
	var dun_pos = pos + get_random_offset(slime_size*1.5, 1.0, parent_size.length() + 1.0,branch_id)
	dun_pos.y = pos.y

	var slime_instance = slime_dun.instantiate()
	slime_instance.position =  dun_pos
	add_child(slime_instance)

	print("🛒 slime spawned at: ", dun_pos)

	spawn_bridge(pos,  dun_pos, parent_size, slime_size, branch_id,true)

func spawn_goal(pos: Vector3, parent_size: Vector3, branch_id: int) -> void:
	if not goal_scene:
		return
	var goal_pos  = pos + get_random_offset(goal_size, 1.0, parent_size.length() + 1.0,branch_id)
	goal_pos.y = pos.y
	var goal_instance = goal_scene.instantiate()
	goal_instance.position = goal_pos
	add_child(goal_instance)
	spawn_bridge(pos, goal_pos, parent_size, goal_size, branch_id,true)





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

# Branch bias directions (normalized)

var branch_bias := {
	0: Vector3(0, 0, 0),   # main branch (no bias → full random)
	1: Vector3(-1, 0, 0),  # branch 1 biased left
	2: Vector3(1, 0, 0)    # branch 2 biased right
}

func get_random_offset(current_size: Vector3, scaleoff: float, padding: float = 2.0, branch_id: int = 0) -> Vector3:
	var base_radius = max(current_size.x, current_size.z)
	var min_radius = base_radius * scaleoff + padding
	var max_radius = base_radius * scaleoff + padding * 2 
	var radius = rng.randf_range(min_radius, max_radius)

	var dir: Vector3
	if branch_bias.has(branch_id) and branch_bias[branch_id] != Vector3.ZERO:
		dir = branch_bias[branch_id].normalized()
		#(±90° → 180°)
		var angle_spread = rng.randf_range(-PI * 0.5, PI * 0.5)
		var cos_a = cos(angle_spread)
		var sin_a = sin(angle_spread)
		dir = Vector3(
			dir.x * cos_a - dir.z * sin_a,
			0,
			dir.x * sin_a + dir.z * cos_a
		).normalized()
	else:
		# Default full random if no bias
		var theta = rng.randf_range(0, TAU)
		dir = Vector3(cos(theta), 0, sin(theta))

	# Final offset
	var offset = dir * radius
	offset.y = rng.randf_range(0.5, max_vertical_step)* scaleoff
	
	return offset
