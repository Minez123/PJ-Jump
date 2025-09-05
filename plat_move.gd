extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var trigger: Area3D = $Area3D

var player_on_platform := false

func _ready() -> void:
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)
	anim_player.animation_finished.connect(_on_anim_finished)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_on_platform = true
		if not anim_player.is_playing():
			anim_player.play("platmove_right")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_on_platform = false
		# don't play move_down yet, wait until current anim finishes

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "platmove_right" and not player_on_platform:
		# Only move down if player already left
		anim_player.play("platmove_left")
