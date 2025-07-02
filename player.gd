extends RigidBody3D

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
@onready var floor_ray := $FloorRayCast  # Make sure to add a RayCast3D node pointing downward

# Jumping variables
var jump_force := 15.0
var max_jumps := 2
var jump_count := 0

var last_shift_time := -1.0
const SHIFT_COOLDOWN := 1.0  # seconds

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	
	apply_central_force(twist_pivot.basis * input * 1200.0 * delta)

	if Input.is_action_just_pressed("shift") and (Time.get_ticks_msec() / 1000.0 - last_shift_time) >= SHIFT_COOLDOWN:
		last_shift_time = Time.get_ticks_msec() / 1000.0
		apply_central_force(twist_pivot.basis * input * 1200.0 * delta * 200)

		

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(30))
	twist_input = 0.0
	pitch_input = 0.0

	# Handle jumping
	if Input.is_action_just_pressed("ui_accept"):  # ui_accept is usually the space key
		if is_on_floor():
			jump()
			jump_count = 1
		elif jump_count < max_jumps:
			jump()
			jump_count += 1

func jump() -> void:
	linear_velocity.y = 0  # Reset Y velocity to prevent stacking
	apply_impulse(Vector3.UP * jump_force)

func is_on_floor() -> bool:
	return floor_ray.is_colliding()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity
