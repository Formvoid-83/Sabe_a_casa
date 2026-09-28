extends StaticBody2D

const GIVE_ITEMS_LINE := "Coloquemos todo esto en la olla"
const NEEDS_INGREDIENTS_LINE := "Necesitamos ingredientes para la sopa casera"
const NEEDS_CILANTRO := "En el jardin hay cilantro. Ojo, cuidadito con traerme perejil!"
const READY_QUESTION_LINE := "¿La sopa ya está lista?"
const ALMOST_PERFECT_LINE := "Casi perfecta, pero le falta algo..."
const NOW_PERFECT_LINE := "¡Ahora está perfecta!"

# Furniture (by node name, under Kitchen/Furniture) that survives the finale.
const CHAOS_SURVIVORS := ["KitchenOn", "Pot"]

const CHAOS_SOUND_INTERVAL := 0.12
const CHAOS_SETTLE_TIME := 0.6
const PEREJIL_ITEM: ItemData = preload("res://resources/items/perejil.tres")

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
		Bubbles.say(NEEDS_INGREDIENTS_LINE, 3)
		await Bubbles.closed
		Bubbles.say(NEEDS_CILANTRO)
		Recipe.reveal()
		await get_tree().create_timer(Bubbles.display_time).timeout
	else:
		Bubbles.say(GIVE_ITEMS_LINE)
		var pot: Node = get_tree().get_first_node_in_group("cooking_pot")
		var player: Node2D = get_tree().get_first_node_in_group("player")
		var hasPerejil: bool = Inventory.get_total_count(PEREJIL_ITEM) > 0 
		if pot != null and player != null and pot.has_method("receive_items"):
			await pot.receive_items(player.global_position)
			if hasPerejil:
				await Bubbles.closed
				Bubbles.say("Te dije que no trajeras PEREJIL >:(", 3)
		else:
			await get_tree().create_timer(Bubbles.display_time).timeout
		await _ask_if_ready()

	_sprite.play("idle")
	_busy = false

## Asks "is the soup ready?" and ends the game if the player says yes.
func _ask_if_ready() -> void:
	await Bubbles.closed
	var yes := await _prompt_yes_no(READY_QUESTION_LINE)
	if not yes:
		return
	if Recipe.is_completed():
		await _play_good_ending()
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

# --- The finale ---------------------------------------------------------------

func _play_good_ending() -> void:
	Bubbles.say(ALMOST_PERFECT_LINE)
	await get_tree().create_timer(Bubbles.display_time).timeout

	var pot: Node2D = get_tree().get_first_node_in_group("cooking_pot")
	await _unleash_kitchen_chaos(pot.global_position)

	Bubbles.say(NOW_PERFECT_LINE)
	await get_tree().create_timer(Bubbles.display_time).timeout

	GameOver.trigger_good_ending()

## Every tile and every piece of furniture (except what's in CHAOS_SURVIVORS)
## gets turned into a spinning, shrinking sprite that spirals into the pot,
## while a barrage of explosion/death sounds plays behind it.
func _unleash_kitchen_chaos(pot_pos: Vector2) -> void:
	var kitchen := get_parent()
	var container := Node2D.new()
	get_tree().current_scene.add_child(container)

	for layer_name in ["Floor", "Walls"]:
		var layer := kitchen.get_node_or_null(layer_name) as TileMapLayer
		if layer != null:
			_explode_tilemap(layer, container, pot_pos)

	var furniture := kitchen.get_node_or_null("Furniture")
	if furniture != null:
		for child in furniture.get_children().duplicate():
			if child.name in CHAOS_SURVIVORS:
				continue
			_explode_sprite_node(child, container, pot_pos)

	_play_chaos_sounds()

	await get_tree().create_timer(_CHAOS_MAX_DURATION() + CHAOS_SETTLE_TIME).timeout
	container.queue_free()

func _CHAOS_MAX_DURATION() -> float:
	return 1.4 + 1.3 # worst-case delay + duration from _fly_to_pot()

func _explode_tilemap(layer: TileMapLayer, container: Node2D, pot_pos: Vector2) -> void:
	for cell in layer.get_used_cells():
		var source_id := layer.get_cell_source_id(cell)
		var source := layer.tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		var atlas_coords := layer.get_cell_atlas_coords(cell)
		var atlas := AtlasTexture.new()
		atlas.atlas = source.texture
		atlas.region = source.get_tile_texture_region(atlas_coords)

		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.global_position = layer.to_global(layer.map_to_local(cell))
		container.add_child(sprite)
		_fly_to_pot(sprite, pot_pos)
	layer.clear()

func _explode_sprite_node(node: Node, container: Node2D, pot_pos: Vector2) -> void:
	var found := node.find_children("*", "Sprite2D", true, false)
	var sprite_source: Sprite2D = found[0] if not found.is_empty() else null
	node.queue_free()
	if sprite_source == null or sprite_source.texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = sprite_source.texture
	sprite.centered = sprite_source.centered
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.global_position = sprite_source.global_position
	container.add_child(sprite)
	_fly_to_pot(sprite, pot_pos)

## Sends `sprite` spiraling into the pot like it got caught in a tornado.
func _fly_to_pot(sprite: Node2D, pot_pos: Vector2) -> void:
	var start_pos := sprite.global_position
	var spin_radius := start_pos.distance_to(pot_pos) * 0.35
	var spins := randf_range(2.0, 4.0) * (1.0 if randf() < 0.5 else -1.0)
	var delay := randf_range(0.0, 1.4)
	var duration := randf_range(0.7, 1.3)

	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_method(func(t: float) -> void:
		var eased := t * t # accelerate inward
		var base_pos := start_pos.lerp(pot_pos, eased)
		var radius := spin_radius * (1.0 - t)
		var angle := t * TAU * spins
		sprite.global_position = base_pos + Vector2(cos(angle), sin(angle)) * radius
		sprite.rotation = angle
		sprite.scale = Vector2.ONE * lerpf(1.0, 0.05, t)
	, 0.0, 1.0, duration)
	tween.tween_callback(sprite.queue_free)

func _play_chaos_sounds() -> void:
	var sounds: Array = []
	for i in range(1, 14):
		sounds.append(load("res://sounds/Enemy_Robot_Death-%03d.wav" % i))
	for i in range(1, 5):
		sounds.append(load("res://sounds/Rocket_Explosion-%03d.wav" % i))
	sounds.shuffle()
	_play_sound_barrage(sounds)

func _play_sound_barrage(sounds: Array) -> void:
	for sound in sounds:
		Sfx.play(sound)
		await get_tree().create_timer(CHAOS_SOUND_INTERVAL).timeout
