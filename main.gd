extends Node3D
@export var player: Node3D


var sky_material: ShaderMaterial

func _ready():
	var world_env = $WorldEnvironment
	if world_env and world_env.environment.sky:
		sky_material = world_env.environment.sky.sky_material

func _process(delta) -> void:
	if not player:
		return
	var h = player.global_position.y
	sky_material = $WorldEnvironment.environment.sky.sky_material
	if sky_material :
		sky_material.set("shader_parameter/player_height", h)
