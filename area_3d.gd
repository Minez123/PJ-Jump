extends Area3D

@export var icon: Texture2D

func _ready():
	connect("body_entered", _on_body_entered)

@export var item_id: String = "slime_jelly"
@export var description: String = "Be friends with slime"
@onready var item_sfx: AudioStreamPlayer3D = $collect_sfx

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var inventory = get_tree().get_first_node_in_group("inventory_ui") 
		if inventory:
			item_sfx.play()
			inventory.add_item(icon,item_id)
			var popup = get_tree().get_first_node_in_group("item_popup")
			popup.show_item(icon,item_id,description)
		await get_tree().create_timer(0.2).timeout
		queue_free()
