extends Area3D


@export var spin_speed: float = 90.0  # degrees per second
@export var uid: String = "slime_boot"
@export var item_resource: ItemResource
func _process(delta: float) -> void:
	rotate_y(deg_to_rad(spin_speed * delta))
func _ready():
	add_to_group("items")
	connect("body_entered", _on_body_entered)

@onready var item_sfx: AudioStreamPlayer3D = $collect_sfx

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var inventory = get_tree().get_first_node_in_group("inventory_ui")
		if inventory:
			item_sfx.play()
			# Pass the ItemResource object directly to the inventory
			inventory.add_item(item_resource)
		
		var popup = get_tree().get_first_node_in_group("item_popup")
		if popup:
			popup.show_item(item_resource,3)
		
		# Separate SFX and `queue_free()` call for better control
		item_sfx.play()
		await get_tree().create_timer(0.2).timeout
		queue_free()
		queue_free()
