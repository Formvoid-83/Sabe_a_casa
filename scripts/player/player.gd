extends CharacterBody2D
class_name Player

# Free top-down movement: the player's CollisionShape2D slides against every
# World collision (layer 1) exactly as drawn, pixel by pixel.
# To see them while playing: Debug > Visible Collision Shapes.

@export var speed: float = 80.0 # pixels per second

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# After a teleport the player stays still until the direction keys are released,
# so holding "up" on the stairs doesn't walk you straight back into them.
var _wait_for_release := false

func _ready() -> void:
	add_to_group("player")
	_sprite.play("idle")

func _physics_process(_delta: float) -> void:
	var direction := _get_input_direction()
	if _wait_for_release:
		_wait_for_release = direction != Vector2.ZERO
		direction = Vector2.ZERO
	velocity = direction * speed
	move_and_slide()
	if direction == Vector2.ZERO:
		_sprite.play("idle")
		return
	if direction.x != 0.0:
		_sprite.flip_h = direction.x < 0.0
	_sprite.play("walk")

func _get_input_direction() -> Vector2:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		return direction
	direction = Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	return direction.normalized()

## Instantly moves the player (used by RoomManager when changing rooms).
func teleport_to(point: Vector2) -> void:
	global_position = point
	velocity = Vector2.ZERO
	_wait_for_release = true
	_sprite.play("idle")
