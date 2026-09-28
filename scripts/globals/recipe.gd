extends Node

# Autoloaded singleton (see project.godot [autoload]).
# Tracks how many of each ingredient have been delivered to the pot, and
# whether the "homemade soup" recipe has been fully completed.
# Perejil is a decoy: it's pickable and never shown as required, but dropping
# even one into the pot permanently ruins the soup - the player has to
# remember not to grab it in the first place.

signal updated
signal completed

const REQUIRED_ITEMS := {
	"res://resources/items/potatoe.tres": 5,      # Potatoe
	"res://resources/items/cilantro.tres": 5,  # Cilantro
	"res://resources/items/egg.tres": 2,     # Egg
	"res://resources/items/mushroom.tres": 3,       # Mushroom
	"res://resources/items/cheese.tres": 1,    # Cheese
	"res://resources/items/jar.tres": 1,       # Jar
	"res://resources/items/garlic.tres": 1,    # Garlic
	"res://resources/items/broccoli.tres": 1,  # Broccoli
	"res://resources/items/drumstick.tres": 1,       # Drumstick
}

const POISON_ITEM_PATH := "res://resources/items/perejil.tres"

var _required: Dictionary = {}  # ItemData -> required amount
var _delivered: Dictionary = {} # ItemData -> delivered amount
var _poison_item: ItemData
var _poisoned := false
var _revealed := false
var _completed := false

func _ready() -> void:
	_poison_item = load(POISON_ITEM_PATH)
	for path in REQUIRED_ITEMS:
		var item: ItemData = load(path)
		_required[item] = REQUIRED_ITEMS[path]
		_delivered[item] = 0

## Shows the checklist for the first time. Safe to call repeatedly.
func reveal() -> void:
	if _revealed:
		return
	_revealed = true
	updated.emit()

func is_revealed() -> bool:
	return _revealed

## True only if every ingredient was delivered AND no Perejil ever went in the pot.
func is_completed() -> bool:
	return _completed and not _poisoned

func is_poisoned() -> bool:
	return _poisoned

## Counts `amount` of `item` towards the recipe (or ruins it, for the decoy).
func deliver(item: ItemData, amount: int) -> void:
	if amount <= 0:
		return
	if item == _poison_item:
		_poisoned = true
		updated.emit()
		return
	if not _required.has(item):
		return
	_delivered[item] = mini(_delivered[item] + amount, _required[item])
	updated.emit()
	if not _completed and _is_complete():
		_completed = true
		completed.emit()

## Ingredients still missing, as [{item, remaining}], in recipe order.
func get_remaining_list() -> Array:
	var result := []
	for item in _required:
		var remaining: int = _required[item] - _delivered[item]
		if remaining > 0:
			result.append({"item": item, "remaining": remaining})
	return result

func _is_complete() -> bool:
	for item in _required:
		if _delivered[item] < _required[item]:
			return false
	return true
