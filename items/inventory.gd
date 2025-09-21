extends Node

var items = {} # Dictionary to store items by UID

func add_item(item_resource: ItemResource) -> void:
	if not item_resource:
		return
	
	if items.has(item_resource.uid):
		# Handle stackable items
		if item_resource.is_stackable:
			# Add to the existing stack
			# For simplicity, assume you have a way to track the current count
			print("Added to stack:", item_resource.item_name)
	else:
		# Add a new, non-stackable item
		items[item_resource.uid] = item_resource
		print("Added new item:", item_resource.item_name)

func get_item_by_uid(uid: String) -> ItemResource:
	if items.has(uid):
		return items[uid]
	return null

func remove_item_by_uid(uid: String) -> void:
	if items.has(uid):
		items.erase(uid)
		print("Removed item:", uid)
