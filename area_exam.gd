extends Node3D

@export var current_size: Vector3 = Vector3(5, 0.5, 5)
@export var scaleoff: float = 1.0
@export var padding: float = 2.0
@export var branch_id: int = 0
@export var segments: int = 64
@export var show_debug_area: bool = true
@export var show_samples: bool = true
@export var sample_count: int = 40
@export var sample_point_size: float = 0.12
@export var max_vertical_step: float = 2.0

# Example bias map (adjust to your project)
@export var branch_bias := {
	0: Vector3(0, 0, 0),
	1: Vector3(-1, 0, 0),
	2: Vector3(1, 0, 0)
}

var rng := RandomNumberGenerator.new()
var mesh_instance: MeshInstance3D
var sample_instances := []

func _ready():
	rng.randomize()

	# MeshInstance that will hold the debug mesh
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

	# Create sample point instances (one-time)
	if show_samples:
		var sample_parent := Node3D.new()
		sample_parent.name = "DebugSamples"
		add_child(sample_parent)
		for i in range(sample_count):
			var s := MeshInstance3D.new()
			s.mesh = SphereMesh.new()
			s.scale = Vector3.ONE * sample_point_size
			s.visible = true
			sample_parent.add_child(s)
			sample_instances.append(s)

	_update_debug_mesh()

func _process(_delta):
	# Update every frame while debugging (or call manually when parameters change)
	if show_debug_area:
		_update_debug_mesh()

func _update_debug_mesh():
	# compute radii
	var base_radius = max(current_size.x, current_size.z)
	var min_radius = base_radius * scaleoff + padding
	var max_radius = base_radius * scaleoff + padding * 2

	# create ArrayMesh and add two line-strip surfaces (inner and outer ring)
	var mesh := ArrayMesh.new()

	# --- inner ring vertices ---
	var verts_min := PackedVector3Array()
	for i in range(segments + 1):
		var a = TAU * float(i) / segments
		verts_min.append(Vector3(cos(a) * min_radius, 0.05, sin(a) * min_radius))

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts_min
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)

	# --- outer ring vertices ---
	var verts_max := PackedVector3Array()
	for i in range(segments + 1):
		var a = TAU * float(i) / segments
		verts_max.append(Vector3(cos(a) * max_radius, 0.05, sin(a) * max_radius))

	arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts_max
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)

	# --- bias line (optional) ---
	var bias_surface_index = -1
	if branch_bias.has(branch_id) and branch_bias[branch_id] != Vector3.ZERO:
		var dir = branch_bias[branch_id].normalized()
		var verts_bias := PackedVector3Array()
		verts_bias.append(Vector3.ZERO)
		verts_bias.append(dir * max_radius)
		arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts_bias
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
		bias_surface_index = mesh.get_surface_count() - 1

	# assign simple materials for visibility
	var mat_min := StandardMaterial3D.new()
	mat_min.albedo_color = Color(0, 1, 0)           # green
	mesh.surface_set_material(0, mat_min)

	var mat_max := StandardMaterial3D.new()
	mat_max.albedo_color = Color(1, 0, 0)           # red
	mesh.surface_set_material(1, mat_max)

	if bias_surface_index >= 0:
		var mat_bias := StandardMaterial3D.new()
		mat_bias.albedo_color = Color(1, 1, 0)      # yellow
		mesh.surface_set_material(bias_surface_index, mat_bias)

	# give the mesh to the MeshInstance
	mesh_instance.mesh = mesh
	mesh_instance.visible = show_debug_area

	# --- update sample points to show where actual offsets can land ---
	if show_samples:
		for i in range(sample_instances.size()):
			var s = sample_instances[i]
			var offs := _get_random_offset_for_debug(current_size, scaleoff, padding, branch_id)
			# put sample in local coordinates (Node is parent)
			s.transform.origin = offs

# Local copy of get_random_offset (deterministic according to this rng instance)
func _get_random_offset_for_debug(current_size: Vector3, scaleoff: float, padding: float, branch_id: int) -> Vector3:
	var base_radius = max(current_size.x, current_size.z)
	var min_radius = base_radius * scaleoff + padding
	var max_radius = base_radius * scaleoff + padding * 2
	var radius = rng.randf_range(min_radius, max_radius)

	var dir: Vector3
	if branch_bias.has(branch_id) and branch_bias[branch_id] != Vector3.ZERO:
		dir = branch_bias[branch_id].normalized()
		var angle_spread = rng.randf_range(-PI * 0.5, PI * 0.5)
		var cos_a = cos(angle_spread)
		var sin_a = sin(angle_spread)
		dir = Vector3(
			dir.x * cos_a - dir.z * sin_a,
			0,
			dir.x * sin_a + dir.z * cos_a
		).normalized()
	else:
		var theta = rng.randf_range(0, TAU)
		dir = Vector3(cos(theta), 0, sin(theta))

	var offset = dir * radius
	offset.y = rng.randf_range(0.5, max_vertical_step) * scaleoff
	return offset
