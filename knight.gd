extends CharacterBody3D

@export var mouse_sensitivity := 0.0015
@export var can_move_in_air: bool = false
@export var inf_Ammo = false

@export var shotgun_pellet_scene: PackedScene
@export var pellets_per_shot := 8
@export var pellet_speed := 60.0
@export var pellet_spread_angle := 8.0 # degrees

@export var min_jump_power := 5.0
@export var max_jump_power := 10.0
@export var jump_charge_rate := 10.0 

@export var move_speed := 8.0
@export var bounce_speed := 8.0

@export var respawn_position: Vector3 = Vector3(0, 15, 0)
@export var fall_limit: float = -50.0  # Y-position considered "fell out"

#Cam
@export var min_zoom := -20.0
@export var max_zoom := 0.0
@export var zoom_speed := 1.0
@export var zoom_hide_threshold:= 0  # Distance at which the mesh disappears
@export var zoom_fov := 30.0
@export var normal_fov := 70.0
@export var focus_speed := 10.0

var zooming := false

@onready var anim_tree = $AnimationTree
@onready var anim_state = $AnimationTree.get("parameters/playback")
@onready var model = $Rig

@onready var character_mesh = $Rig/Skeleton3D
@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
@onready var camera := $TwistPivot/PitchPivot/Camera3D
@onready var crosshair: TextureRect = $"../HUD/TextureRect"
@onready var camera_raycast: RayCast3D = $TwistPivot/PitchPivot/CameraRayCast


#UI
@onready var pause_menu: Node = $PauseMenu  
@onready var jump_bar := $"../HUD/JumpPowerBar" 
# Shotgun
@onready var shotgun_ammo_label := $"../HUD/ShotgunAmmoLabel"

#sfx
@onready var jump_sfx: AudioStreamPlayer2D = $jump_sfx
@onready var landing_sfx: AudioStreamPlayer3D = $Landing_sfx
@onready var full_charge_sfx: AudioStreamPlayer2D = $Full_Charge_sfx
@onready var shotgun_sfx: AudioStreamPlayer3D = $ShotgunSfx
@onready var bouce_1: AudioStreamPlayer2D = $bouce_1
@onready var bouce_2: AudioStreamPlayer2D = $bouce_2
@onready var bouce_3: AudioStreamPlayer2D = $bouce_3
var current_zoom := -10.0  # initial zoom distance

var charging_jump := false
var was_on_floor := false
var full_charge_sfx_played := false
var jump_power := 0.0
var jump_direction := 0 
var jump_hight := 2
var landed_timer := 0.0
var current_platform_type = 0
var platform_factor: float = 1.0


var GRAVITY = 9.8 * jump_hight 
var original_gravity: float  # Store the original gravity value
var jump_boost = 1

var last_dash_time := -1.0
const DASH_COOLDOWN := 1.0  # seconds

# Mouse input
var twist_input := 0.0
var pitch_input := 0.0



@export var shotgun_knockback_force := -15.0
@export var shotgun_cooldown := 1.5  # Cooldown after 2 shots
@export var shotgun_recoil_upward := 14.0
const MAX_SHOTGUN_AMMO := 2
var shotgun_shots_remaining := MAX_SHOTGUN_AMMO
var shotgun_knockback := Vector3.ZERO



func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	original_gravity = GRAVITY  # Store the original gravity value
	


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input = -event.relative.x * mouse_sensitivity
		pitch_input = -event.relative.y * mouse_sensitivity

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			current_zoom = max(min_zoom, current_zoom - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			current_zoom = min(max_zoom, current_zoom + zoom_speed)
	if event.is_action_pressed("ui_cancel") and not pause_menu.visible:
		pause_menu.game_script = self
		pause_menu.show_menu()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			zooming = event.pressed


func _physics_process(delta: float) -> void:
	var inventory = get_tree().get_first_node_in_group("inventory_ui")
	if global_transform.origin.y < fall_limit:
		respawn()
	var target_fov = 1

	# Smooth zoom transition
	if zooming:
		target_fov = zoom_fov
	else:
		target_fov = normal_fov
	camera.fov = lerp(camera.fov, target_fov, delta * focus_speed)


	crosshair.visible = zooming

	
	# Camera rotation
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	twist_input = 0.0
	pitch_input = 0.0
	camera.transform.origin.z = -current_zoom
	# Visibility toggle based on zoom
	character_mesh.visible = current_zoom < zoom_hide_threshold
	var desired_distance = -current_zoom
	
	# Update ray length to match zoom
	camera_raycast.target_position = Vector3(0, 0, desired_distance)
	camera_raycast.force_raycast_update()
	
	if camera_raycast.is_colliding():
		var collision_point = camera_raycast.get_collision_point()
		var local_pos = pitch_pivot.to_local(collision_point)
		camera.position = local_pos + Vector3(0, 0, 0.3) # small offset so it doesn’t clip
	else:
		camera.position = Vector3(0, 0, desired_distance)
	if landed_timer > 0.0:
		landed_timer -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		# Movement input
	else:
		var input_dir = Vector3.ZERO
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.z = Input.get_axis("move_forward", "move_back")
		
		input_dir = input_dir.normalized()
		var direction = twist_pivot.basis * input_dir
		direction.y = 0
		direction = direction.normalized()
	

		$Rig.rotation.y = twist_pivot.global_rotation.y
		#Animetion
		var model_var = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position",Vector2(model_var.x,-model_var.z)/move_speed)






		if landed_timer > 0.0:
			landed_timer -= delta

		
		# Allow movement if grounded or if air movement is enabled
		if is_on_floor() or can_move_in_air:
			anim_tree.set("parameters/conditions/grounded", true)
			match current_platform_type:
				0:  # NORMAL
					velocity.x = direction.x * move_speed
					velocity.z = direction.z * move_speed

				1:  # STICKY
					if inventory.has_item("slime_boot"):
						platform_factor = 1
					velocity.x = direction.x * move_speed * platform_factor
					velocity.z = direction.z * move_speed * platform_factor

				2:  # SLIPPERY
					var target_velocity = direction * move_speed
					if inventory.has_item("ice_boot"):
						platform_factor = 1
					velocity.x = lerp(velocity.x, target_velocity.x, delta * 5.0 * platform_factor)
					velocity.z = lerp(velocity.z, target_velocity.z, delta * 5.0 * platform_factor)

			
			# Start charging
			if Input.is_action_pressed("move_up"): 
				charging_jump = true
				jump_power = min(jump_power + jump_charge_rate * delta, max_jump_power)

				# Show jump charge
				if charging_jump:
					jump_bar.visible = true
					jump_bar.value = jump_power
					if jump_power >= jump_bar.max_value  and not full_charge_sfx_played:
						full_charge_sfx.play()
						full_charge_sfx_played = true

				else:
					jump_bar.visible = false

			elif Input.is_action_just_released("move_up") and charging_jump:
				anim_tree.set("parameters/conditions/jumping",true)
				anim_tree.set("parameters/conditions/grounded",false)
				charging_jump = false
				full_charge_sfx_played = false  
				if inventory.has_item("jump_boost"):
					jump_boost = 1.2
				velocity.y = jump_power * jump_hight *jump_boost
				
				var cloud_ring = preload("res://effects/jump_cloud.tscn").instantiate()
				get_parent().add_child(cloud_ring)
				cloud_ring.global_transform.origin = global_transform.origin
				cloud_ring.emitting = true


				# Get camera's forward direction (ignoring vertical tilt)
				var forward = -twist_pivot.global_transform.basis.z
				forward.y = 0
				forward = forward.normalized()
				jump_sfx.play()
				velocity.x = forward.x * jump_power 
				velocity.z = forward.z * jump_power 

				jump_power = 0.0

		# Gravity
		if not is_on_floor():
			anim_state.travel("Jump_Idle")
			anim_tree.set("parameters/conditions/grounded",false)
			$CloudTrail.emitting = true
			# Check if character is falling down (negative y velocity)
			if velocity.y < 0:

				# Increase gravity when falling to make character fall faster
				GRAVITY = original_gravity + (2.5 * original_gravity)
			else:
				# Reset gravity to original when not falling (jumping up)
				GRAVITY = original_gravity
			
			velocity.y -= GRAVITY * delta
		else:
			$CloudTrail.emitting = false
			# Reset gravity to original when on floor
			GRAVITY = original_gravity	
			
		var velocity_before_slide := velocity
		
		# Bounce on enemy collision

		

		




		if Input.is_action_just_pressed("shoot_shotgun") and shotgun_shots_remaining > 0:
			var free_shot = false
			if inventory.has_item("ammo_box") and 15>randf_range(1,100):
				free_shot = true
				var popup = get_tree().get_first_node_in_group("item_popup")
				var item = inventory.get_item("ammo_box")
				popup.show_item(item,1)


			if not inf_Ammo and not free_shot:
				shotgun_shots_remaining -= 1

			shotgun_sfx.play()
			charging_jump = false
			jump_power = 0 
			# Knockback
			var shoot_dir = -camera.global_transform.basis.z.normalized()
			shotgun_knockback = shoot_dir * shotgun_knockback_force
			shotgun_knockback.y += shotgun_recoil_upward
			velocity = shotgun_knockback
			shotgun_knockback = Vector3.ZERO

			# Spawn pellets
			fire_shotgun(shoot_dir)
			
			
			
		shotgun_ammo_label.text = "Ammo: %d" % shotgun_shots_remaining
		move_and_slide()
				
				
		#wall bouncing
		var collision_count = get_slide_collision_count()
		if collision_count > 0:
			for i in range(collision_count):
				var collision = get_slide_collision(i)
				if abs(collision.get_normal().y) < 0.1:
					var wall_normal := collision.get_normal()
					#R=L−2(N⋅L)N
					var reflection := velocity_before_slide - 2*(wall_normal.dot(velocity_before_slide))*wall_normal
					velocity = reflection
					play_bounce_sfx()
					
					

		if not was_on_floor and is_on_floor():
			landing_sfx.play()
			landed_timer = 0.0 
			anim_tree.set("parameters/conditions/grounded",true)
			anim_tree.set("parameters/conditions/jumping",false)
			jump_bar.value = 0
		was_on_floor = is_on_floor()
		
var bounce_index := 0

func play_bounce_sfx():
	if is_on_floor(): 
		return
	var sounds = [bouce_1, bouce_2, bouce_3]
	sounds[bounce_index].play()
	bounce_index = (bounce_index + 1) % sounds.size()
	
func refill_shotgun():
		shotgun_shots_remaining += 1

func trigger_enemy_bounce(enemy_position: Vector3):
	anim_tree.set("parameters/conditions/jumping", true)
	anim_tree.set("parameters/conditions/grounded", false)
	jump_sfx.play()

	var bounce_dir = (global_position - enemy_position).normalized()
	bounce_dir.y = 0
	bounce_dir = bounce_dir.normalized()

	velocity.x = bounce_dir.x * 5
	velocity.z = bounce_dir.z * 5
	velocity.y = 5 * jump_hight
	charging_jump = false
	jump_power = 0 
	
func fire_shotgun(shoot_dir: Vector3):
	for i in range(pellets_per_shot):
		var pellet = shotgun_pellet_scene.instantiate()
		get_parent().add_child(pellet)

		pellet.global_transform.origin = twist_pivot.global_transform.origin + Vector3(0, 2, 0)

		# Spread — randomize angles
		var spread = deg_to_rad(pellet_spread_angle)
		var random_rot = Basis(
			Vector3.UP, randf_range(-spread, spread)
		) * Basis(
			Vector3.RIGHT, randf_range(-spread, spread)
		)

		var pellet_dir = (random_rot * shoot_dir).normalized()

		# Give the pellet its velocity
		if pellet.has_method("set_velocity"):
			pellet.set_velocity(pellet_dir * pellet_speed)
		elif pellet is RigidBody3D:
			pellet.linear_velocity = pellet_dir * pellet_speed
		
			
func respawn():
	global_transform.origin = respawn_position
	velocity = Vector3.ZERO 

func consume_ammo(amount: int) -> void:
	shotgun_shots_remaining  = max(shotgun_shots_remaining  - amount, 0)

func get_ammo() -> int:
	return shotgun_shots_remaining 

func set_platform_state(p_type: int, factor: float) -> void:
	current_platform_type = p_type
	platform_factor = factor

func reset_platform_state() -> void:
	current_platform_type = 0
	platform_factor = 1.0
