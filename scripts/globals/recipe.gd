extends Node

# Autoloaded singleton (see project.godot [autoload]).
# Tracks how many of each ingredient have been delivered to the pot, and
# whether the "homemade soup" recipe has been fully completed.
# Perejil is a decoy: it's pickable but intentionally left out of this list.

signal updated
signal completed

const REQUIRED_AMOUNT := 5

const REQUIRED_ITEM_PATHS := [
	"res://resources/items/pan.tres",      # Carrot
	"res://resources/items/pot.tres",      # Mushroom
	"res://resources/items/glass.tres",    # Egg
	"res://resources/items/cup.tres",      # Drumstick
	"res://resources/items/candle.tres",   # Cheese
	"res://resources/items/book.tres",     # Potatoe
	"res://resources/items/saucer.tres",   # Garlic
	"res://resources/items/jar.tres",      # Jar
	"res://resources/items/cilantro.tres", # Cilantro
]

var _delivered: Dictionary = {} # ItemData -> int
var _revealed := false
var _completed := false

func _ready() -> void:
	for path in REQUIRED_ITEM_PATHS:
		var item: ItemData = load(path)
		_delivered[item] = 0

## Shows the checklist for the first time. Safe to call repeatedly.
func reveal() -> void:
	if _revealed:
		return
	_revealed = true
	updated.emit()

func is_revealed() -> bool:
	return _revealed

func is_completed() -> bool:
	return _completed

## Counts `amount` of `item` towards the recipe, if it's one of the required ingredients.
func deliver(item: ItemData, amount: int) -> void:
	if amount <= 0 or not _delivered.has(item):
		return
	_delivered[item] = mini(_delivered[item] + amount, REQUIRED_AMOUNT)
	updated.emit()
	if not _completed and _is_complete():
		_completed = true
		completed.emit()
		Bubbles.say("¡Excelente! La sopa casera está lista.")

## Ingredients still missing, as [{item, remaining}], in recipe order.
func get_remaining_list() -> Array:
	var result := []
	for item in _delivered:
		var remaining: int = REQUIRED_AMOUNT - _delivered[item]
		if remaining > 0:
			result.append({"item": item, "remaining": remaining})
	return result

func _is_complete() -> bool:
	for item in _delivered:
		if _delivered[item] < REQUIRED_AMOUNT:
			return false
	return true
