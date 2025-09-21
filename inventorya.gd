extends CanvasLayer

@export var grid: GridContainer
var items: Dictionary = {}   
var visible_inventory := false

func _ready() -> void:
	add_to_group("inventory_ui")
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle"):
		visible_inventory = !visible_inventory
		visible = visible_inventory


func add_item(item_resource: Resource) -> void:
	if not item_resource or not item_resource is ItemResource:
		return

	if not items.has(item_resource.uid):
		items[item_resource.uid] = item_resource # Store the whole resource
		_update_inventory_ui()

func _update_inventory_ui() -> void:
	for child in grid.get_children():
		child.queue_free()

	grid.columns = 5
	for uid in items.keys():
		var item_resource = items[uid]
		if not item_resource:
			continue
			
		var tex_rect = TextureRect.new()
		tex_rect.texture = item_resource.texture # Get texture from resource

		tex_rect.expand = true
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(48, 48)  # adjust grid slot size

		grid.add_child(tex_rect)

func has_item(item_id: String) -> bool:
	return items.has(item_id)


func get_item(uid: String) -> ItemResource:
	if items.has(uid):
		return items[uid]
	return null

func remove_item(uid: String) -> void:
	if items.has(uid):
		items.erase(uid)
		_update_inventory_ui()
		
func load_inventory(inventory_uids: Array) -> void:
	# Clear the current inventory
	items.clear()
	
	# Load each item by its UID
	for uid in inventory_uids:
		var item_resource_path = "res://items/" + uid + ".tres"
		var item_resource = load(item_resource_path)
		
		if item_resource and item_resource is ItemResource:
			add_item(item_resource)
		else:
			print("Failed to load item with UID:", uid)
