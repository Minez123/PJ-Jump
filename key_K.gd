extends Area3D
@export var key_id := ""  
@export var uid: String = ""
@export var item_resource: ItemResource
@onready var item_sfx: AudioStreamPlayer3D = $collect_sfx

func _ready():
	add_to_group("items")
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		GameData.collected_keys[key_id] = true
		var inventory = get_tree().get_first_node_in_group("inventory_ui")
		if inventory:
			item_sfx.play()
			inventory.add_item(item_resource)
		var popup = get_tree().get_first_node_in_group("item_popup")
		if popup:
			popup.show_item(item_resource,3)
		item_sfx.play()
		await get_tree().create_timer(0.2).timeout
		queue_free()
