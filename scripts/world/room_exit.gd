extends Area2D
class_name RoomExit

# Trigger that sends the player to another room when the player's
# CollisionShape2D enters it (stairs, doors...). Lives on layer 3 "Triggers"
# and watches layer 2 "Player". To use a solid object (a wardrobe, a bed) as
# an exit, make this area a bit bigger than the object's collision so the
# player can touch it.

## Room scene to load (e.g. res://scenes/world/second_floor.tscn).
@export_file("*.tscn") var target_room: String
## Name of a Marker2D inside the target room's "Spawns" node.
## Put it outside this room's exits, or you'd bounce straight back.
@export var target_spawn: String = ""

func _ready() -> void:
	add_to_group("doors")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Ignored while a transition runs: the player may land on an exit, and it
	# only fires again after walking out and back in.
	if body is Player and not RoomManager.is_busy():
		activate()

func activate() -> void:
	RoomManager.go_to(target_room, target_spawn)
