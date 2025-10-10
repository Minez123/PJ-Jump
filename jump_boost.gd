extends Area3D

# Use a preloaded ItemResource for better data management

@export var item_resource: ItemResource
@export var spin_speed: float = 90.0
@export var price: int = 15
@export var uid: String = "jump_boost"
var player_in_range: Node = null
@onready var interact_label: Label3D = $Label3D
@onready var item_sfx: AudioStreamPlayer3D = $collect_sfx

func _ready() -> void:
	add_to_group("items")
	interact_label.visible = false
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	
func _process(delta: float) -> void:
	rotate_y(deg_to_rad(spin_speed * delta))
	
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = body
		interact_label.visible = true
		var shop_ui = get_tree().get_first_node_in_group("shop_ui")
		if shop_ui:
			shop_ui.show_item(price, body.get_ammo())


func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		_try_buy_item()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = null
		interact_label.visible = false
		var shop_ui = get_tree().get_first_node_in_group("shop_ui")
		if shop_ui:
			shop_ui.hide_item()

func _try_buy_item() -> void:
	if not player_in_range:
		return
	
	if player_in_range.get_ammo() >= price:
		player_in_range.consume_ammo(price)

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
	else:
		var shop_ui = get_tree().get_first_node_in_group("shop_ui")
		shop_ui.reject()
