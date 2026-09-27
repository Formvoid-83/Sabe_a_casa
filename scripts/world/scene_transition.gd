extends Area2D
class_name SceneTransition

# Changes to target_scene when the player steps into this area.
# The inventory lives in the Inventory autoload, so it survives the scene change untouched.

const PLAYER_LAYER := 2 # physics layer "Player"

@export_file("*.tscn") var target_scene: String = "res://scenes/world/world.tscn"

## True from the moment a transition fires until the destination scene consumes it.
static var arrived_by_transition := false

var _triggered := false

func _ready() -> void:
	set_collision_mask_value(PLAYER_LAYER, true)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	arrived_by_transition = true
	get_tree().call_deferred("change_scene_to_file", target_scene)
