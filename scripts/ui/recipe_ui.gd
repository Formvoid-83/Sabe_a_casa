extends CanvasLayer

const ICON_SIZE := 24

@onready var _item_list: VBoxContainer = $Root/PanelContainer/MarginContainer/Content/ItemList

func _ready() -> void:
	visible = Recipe.is_revealed()
	Recipe.updated.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if Recipe.is_revealed():
		visible = true
	for child in _item_list.get_children():
		child.queue_free()
	var remaining := Recipe.get_remaining_list()
	if remaining.is_empty():
		var done_label := Label.new()
		done_label.text = "¡Completo!"
		_item_list.add_child(done_label)
		return
	for entry in remaining:
		_item_list.add_child(_build_row(entry["item"], entry["remaining"]))

func _build_row(item: ItemData, remaining: int) -> HBoxContainer:
	var row := HBoxContainer.new()

	var icon_rect := TextureRect.new()
	icon_rect.texture = item.icon
	icon_rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon_rect)

	var label := Label.new()
	label.text = "%s x%d" % [item.display_name, remaining]
	row.add_child(label)

	return row
