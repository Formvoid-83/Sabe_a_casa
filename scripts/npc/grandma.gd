extends StaticBody2D

const GIVE_ITEMS_LINE := "Coloquemos todo esto en la olla"
const NEEDS_INGREDIENTS_LINE := "Necesitamos ingredientes para la sopa casera"
const READY_QUESTION_LINE := "¿La sopa ya está lista?"

## Tiny signal carrier so _prompt_yes_no() can `await` a button press.
class YesNoResult extends RefCounted:
	signal answered(value: bool)

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

	if Inventory.slots.is_empty():
		Bubbles.say(NEEDS_INGREDIENTS_LINE)
		Recipe.reveal()
		await get_tree().create_timer(Bubbles.display_time).timeout
	else:
		Bubbles.say(GIVE_ITEMS_LINE)
		var pot: Node = get_tree().get_first_node_in_group("cooking_pot")
		var player: Node2D = get_tree().get_first_node_in_group("player")
		if pot != null and player != null and pot.has_method("receive_items"):
			await pot.receive_items(player.global_position)
		else:
			await get_tree().create_timer(Bubbles.display_time).timeout
		await _ask_if_ready()

	_sprite.play("idle")
	_busy = false

## Asks "is the soup ready?" and ends the game if the player says yes.
func _ask_if_ready() -> void:
	var yes := await _prompt_yes_no(READY_QUESTION_LINE)
	if not yes:
		return
	if Recipe.is_completed():
		GameOver.trigger_good_ending()
	else:
		GameOver.trigger_bad_ending()

## Shows a Sí/No prompt in the speech bubble and waits for an answer.
func _prompt_yes_no(question: String) -> bool:
	var result := YesNoResult.new()

	var content := VBoxContainer.new()

	var label := Label.new()
	label.text = question
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	content.add_child(buttons)

	var yes_button := Button.new()
	yes_button.text = "Sí"
	yes_button.pressed.connect(func() -> void: result.answered.emit(true))
	buttons.add_child(yes_button)

	var no_button := Button.new()
	no_button.text = "No"
	no_button.pressed.connect(func() -> void: result.answered.emit(false))
	buttons.add_child(no_button)

	Bubbles.show_content(content, 0.0)
	var answer: bool = await result.answered
	Bubbles.close()
	return answer
