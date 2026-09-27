extends StaticBody2D

## Easter egg: press Space near the fridge to get a cheese.

const CHEESE_ITEM := preload("res://resources/items/candle.tres")
const CHEESE_SOUND := preload("res://sounds/cheese.ogg")

@onready var _interact_area: Area2D = $InteractArea

var _player_nearby := false

func _ready() -> void:
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_pressed("ui_accept"):
		Inventory.add_item(CHEESE_ITEM, 1)
		Sfx.play(CHEESE_SOUND)
