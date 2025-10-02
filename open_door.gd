extends Area3D

func _ready() -> void:
	trigger.body_entered.connect(_on_body_entered)
	
