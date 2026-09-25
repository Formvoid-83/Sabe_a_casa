extends CanvasLayer

const ICON_SIZE := 24

@onready var _item_list: VBoxContainer = $Root/PanelContainer/MarginContainer/Content/ItemList

func _ready() -> void:
	visible = false
	Inventory.inventory_changed.connect(_refresh)
	_refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		visible = not visible

func _refresh() -> void:
	for child in _item_list.get_children():
		child.queue_free()
	if Inventory.slots.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(empty)"
		_item_list.add_child(empty_label)
		return
	for slot in Inventory.slots:
		_item_list.add_child(_build_slot_row(slot))

func _build_slot_row(slot: Dictionary) -> HBoxContainer:
	var item: ItemData = slot["item"]
	var row := HBoxContainer.new()

	var icon_rect := TextureRect.new()
	icon_rect.texture = item.icon
	icon_rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon_rect)

	var label := Label.new()
	label.text = "%s x%d" % [item.display_name, slot["quantity"]]
	row.add_child(label)

	return row
