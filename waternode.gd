extends Node3D

@onready var player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if player:
		var pos = player.global_position
		# Keep water centered on player (ignore Y so it stays flat)
		global_position.x = pos.x
		global_position.z = pos.z
