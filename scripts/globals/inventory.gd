extends Node

# Autoloaded singleton (see project.godot [autoload]).
# Stackable inventory: an ordered list of {item: ItemData, quantity: int} slots.
# Multiple slots of the same item can exist once max_stack is reached.

signal inventory_changed

var slots: Array[Dictionary] = []

func add_item(item: ItemData, amount: int = 1) -> void:
	if item == null or amount <= 0:
		return
	var remaining := amount
	for slot in slots:
		if slot["item"] == item and slot["quantity"] < item.max_stack:
			var space: int = item.max_stack - slot["quantity"]
			var added: int = min(space, remaining)
			slot["quantity"] += added
			remaining -= added
			if remaining <= 0:
				break
	while remaining > 0:
		var added: int = min(item.max_stack, remaining)
		slots.append({"item": item, "quantity": added})
		remaining -= added
	inventory_changed.emit()

func remove_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	var remaining := amount
	for i in range(slots.size() - 1, -1, -1):
		var slot: Dictionary = slots[i]
		if slot["item"] != item:
			continue
		var removed: int = min(slot["quantity"], remaining)
		slot["quantity"] -= removed
		remaining -= removed
		if slot["quantity"] <= 0:
			slots.remove_at(i)
		if remaining <= 0:
			break
	inventory_changed.emit()
	return remaining <= 0

func clear() -> void:
	if slots.is_empty():
		return
	slots.clear()
	inventory_changed.emit()

func get_total_count(item: ItemData) -> int:
	var total := 0
	for slot in slots:
		if slot["item"] == item:
			total += slot["quantity"]
	return total
