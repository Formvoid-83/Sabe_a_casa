extends CanvasLayer

# Autoloaded singleton (see project.godot [autoload]). Persists across
# scene changes so the fade overlay keeps rendering during the swap.

var _fade_rect: ColorRect
var _busy := false

func _ready() -> void:
	layer = 100
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	add_child(_fade_rect)

func go_to(scene_path: String, fade_duration: float = 0.4) -> void:
	if _busy:
		return
	_busy = true

	var fade_out := create_tween()
	fade_out.tween_property(_fade_rect, "modulate:a", 1.0, fade_duration)
	await fade_out.finished

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame

	var fade_in := create_tween()
	fade_in.tween_property(_fade_rect, "modulate:a", 0.0, fade_duration)
	await fade_in.finished

	_busy = false
