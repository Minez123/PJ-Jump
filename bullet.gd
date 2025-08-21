extends RigidBody3D
@export var spin_speed := 10.0  # radians per second
@export var damage := 10
@export var speed := 60.0
@export var lifetime := 1.0
var velocity := Vector3.ZERO

func _ready():
	# Initially disable monitoring to ignore collisions
	$Area3D.monitoring = false
	$Area3D.body_entered.connect(_on_body_entered)

	# After 0.1 seconds, enable monitoring
	_enable_collision_after_delay()

	# Lifetime timer to free bullet eventually
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _enable_collision_after_delay() -> void:
	await get_tree().create_timer(0.05).timeout
	$Area3D.monitoring = true

func set_velocity(v: Vector3):
	velocity = v

func _physics_process(delta):
	global_translate(velocity * delta)
	

		
func _on_body_entered(body):
	var target = body


	if target and target.is_in_group("AI_NPC"):
		if target.has_method("take_damage"):
			target.take_damage(damage)
	queue_free()
