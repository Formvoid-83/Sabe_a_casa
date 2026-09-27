extends StaticBody2D

const DIALOGUE_LINE := "Coloquemos todo esto en la olla"

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _interact_area: Area2D = $InteractArea

var _player_nearby := false
var _busy := false

func _ready() -> void:
	_sprite.play("idle")
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and not _busy and event.is_action_pressed("ui_accept"):
		_talk()

func _talk() -> void:
	_busy = true
	_sprite.play("talk")
	Bubbles.say(DIALOGUE_LINE)

	var pot: Node = get_tree().get_first_node_in_group("cooking_pot")
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if pot != null and player != null and pot.has_method("receive_items"):
		pot.receive_items(player.global_position)

	await get_tree().create_timer(Bubbles.display_time).timeout
	_sprite.play("idle")
	_busy = false
