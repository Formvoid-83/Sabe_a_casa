extends CanvasLayer

@onready var _item_list: VBoxContainer = $Root/PanelContainer/MarginContainer/Content/ItemList

func _ready() -> void:
	Inventory.inventory_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in _item_list.get_children():
		child.queue_free()
	if Inventory.slots.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(empty)"
		_item_list.add_child(empty_label)
		return
	for slot in Inventory.slots:
		var item: ItemData = slot["item"]
		var label := Label.new()
		label.text = "%s x%d" % [item.display_name, slot["quantity"]]
		_item_list.add_child(label)
