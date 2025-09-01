extends CanvasLayer

@export var grid: GridContainer
var items: Dictionary = {}   # "item_id": {"icon": Texture2D, "desc": String}
var visible_inventory := false

func _ready() -> void:
	add_to_group("inventory_ui")
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle"):
		visible_inventory = !visible_inventory
		visible = visible_inventory

# Called when player collects an item
func add_item(icon: Texture2D, item_id: String, desc: String) -> void:
	if not items.has(item_id):  # avoid duplicates
		items[item_id] = {
			"icon": icon,
			"desc": desc
		}
		_update_inventory_ui()

func _update_inventory_ui() -> void:
	for child in grid.get_children():
		child.queue_free()

	grid.columns = 5
	for item_id in items.keys():
		var tex_rect = TextureRect.new()
		tex_rect.texture = items[item_id]["icon"]
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(32, 32)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		grid.add_child(tex_rect)

func has_item(item_id: String) -> bool:
	return items.has(item_id)

func get_item(item_id: String) -> Dictionary:
	if items.has(item_id):
		return {
			"id": item_id,
			"icon": items[item_id]["icon"],
			"desc": items[item_id]["desc"]
		}
	return {}
