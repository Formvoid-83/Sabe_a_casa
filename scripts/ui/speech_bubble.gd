extends Control
class_name SpeechBubble

# Reusable dialogue bubble docked to the bottom of the screen.
# Put it under a CanvasLayer (the Bubbles autoload already does this).
# The frame is drawn from two swappable sprites:
#   corner_texture: TOP-LEFT corner, mirrored for the other three.
#   side_texture:   TOP edge (outer edge on row 0), tiled and mirrored/rotated for the rest.
# Any Control can be placed inside via set_content()/add_content().

signal opened
signal closed

@export var corner_texture: Texture2D = preload("res://sprites/ui/bubble_corner.png"):
	set(value):
		corner_texture = value
		_update_frame()
@export var side_texture: Texture2D = preload("res://sprites/ui/bubble_side.png"):
	set(value):
		side_texture = value
		_update_frame()
@export var fill_color := Color.WHITE:
	set(value):
		fill_color = value
		queue_redraw()
## Size of one sprite pixel on screen (matches the camera zoom).
@export var pixel_scale := 4:
	set(value):
		pixel_scale = max(1, value)
		_update_frame()
## Extra space between the frame and the content, in sprite pixels.
@export var content_padding := 2:
	set(value):
		content_padding = value
		_update_frame()

@export_group("Layout")
## Fraction of the screen height the bubble occupies.
@export_range(0.05, 1.0) var height_ratio := 0.25:
	set(value):
		height_ratio = value
		_update_layout()
## Gap between the bubble and the screen edges, in screen pixels.
@export var screen_margin := 0.0:
	set(value):
		screen_margin = value
		_update_layout()

@export_group("Look")
## Final opacity of the whole bubble (a bit transparent).
@export_range(0.0, 1.0) var bubble_opacity := 0.85
@export var text_size := 20
@export var text_color := Color(0.16, 0.12, 0.12)

@export_group("Transitions")
## Seconds the bubble stays on screen before closing by itself.
## 0 = stays open until close() is called.
@export var display_time := 3.0
@export var appear_time := 0.25
@export var disappear_time := 0.2
## How far (screen pixels) the bubble slides in from / out to.
@export var slide_distance := 48.0

@onready var _margin: MarginContainer = $Margin
@onready var _content: VBoxContainer = $Margin/Content

var _slide := 0.0
var _tween: Tween
var _is_open := false
var _close_timer: SceneTreeTimer

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	resized.connect(queue_redraw)
	hide()
	_update_layout()
	_update_frame()

func is_open() -> bool:
	return _is_open

# --- Content -----------------------------------------------------------------

func set_text(text: String) -> void:
	set_content(make_label(text))

func set_content(node: Control) -> void:
	clear_content()
	add_content(node)

func add_content(node: Control) -> void:
	_content.add_child(node)

func clear_content() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

func make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", text_size)
	label.add_theme_color_override("font_color", text_color)
	return label

# --- Transitions -------------------------------------------------------------

## duration < 0 uses display_time; 0 stays open until close().
## Calling it while already open just restarts the countdown.
func open(duration := -1.0) -> void:
	_schedule_close(display_time if duration < 0.0 else duration)
	if _is_open:
		return
	_is_open = true
	_kill_tween()
	if not visible:
		modulate.a = 0.0
		_set_slide(slide_distance)
		show()
	# If it was mid-close, it reverses from wherever it is.
	_tween = create_tween().set_parallel()
	_tween.tween_method(_set_slide, _slide, 0.0, appear_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", bubble_opacity, appear_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(opened.emit)

func close(free_after := false) -> void:
	_close_timer = null
	if not _is_open:
		return
	_is_open = false
	_kill_tween()
	_tween = create_tween().set_parallel()
	_tween.tween_method(_set_slide, _slide, slide_distance, disappear_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, disappear_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(_on_close_finished.bind(free_after))

func _on_close_finished(free_after: bool) -> void:
	hide()
	closed.emit()
	if free_after:
		queue_free()

func _schedule_close(duration: float) -> void:
	_close_timer = null
	if duration <= 0.0:
		return
	_close_timer = get_tree().create_timer(duration)
	_close_timer.timeout.connect(_on_close_timer.bind(_close_timer))

func _on_close_timer(timer: SceneTreeTimer) -> void:
	# Ignore timers from earlier opens that were replaced by newer content.
	if timer == _close_timer:
		close()

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

func _set_slide(value: float) -> void:
	_slide = value
	_update_layout()

# --- Layout & drawing --------------------------------------------------------

func _update_layout() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0 - height_ratio
	anchor_bottom = 1.0
	offset_left = screen_margin
	offset_right = -screen_margin
	offset_top = screen_margin + _slide
	offset_bottom = -screen_margin + _slide

func _border() -> int:
	var corner := corner_texture.get_size() if corner_texture else Vector2.ZERO
	var side_h := side_texture.get_height() if side_texture else 0
	return int(max(corner.x, corner.y, side_h))

func _update_frame() -> void:
	if not is_node_ready():
		return
	var m := (_border() + content_padding) * pixel_scale
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, m)
	queue_redraw()

func _draw() -> void:
	var s := float(pixel_scale)
	var w := floorf(size.x / s)
	var h := floorf(size.y / s)
	var c := corner_texture.get_size() if corner_texture else Vector2.ZERO
	var sh := float(side_texture.get_height()) if side_texture else 0.0
	var base := Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO)

	# Center fill (everything inside the side strips).
	draw_set_transform_matrix(base)
	draw_rect(Rect2(sh, sh, w - sh * 2.0, h - sh * 2.0), fill_color)

	if side_texture:
		var along_x := Rect2(c.x, 0, w - c.x * 2.0, sh)
		var along_y := Rect2(c.y, 0, h - c.y * 2.0, sh)
		# Top, bottom (mirrored), left and right (axes swapped so row 0 stays outside).
		_draw_tiled(base, Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2.ZERO), along_x)
		_draw_tiled(base, Transform2D(Vector2(1, 0), Vector2(0, -1), Vector2(0, h)), along_x)
		_draw_tiled(base, Transform2D(Vector2(0, 1), Vector2(1, 0), Vector2.ZERO), along_y)
		_draw_tiled(base, Transform2D(Vector2(0, 1), Vector2(-1, 0), Vector2(w, 0)), along_y)

	if corner_texture:
		for flip in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var origin := Vector2(0.0 if flip.x > 0 else w, 0.0 if flip.y > 0 else h)
			draw_set_transform_matrix(base * Transform2D(0.0, flip, 0.0, origin))
			draw_texture(corner_texture, Vector2.ZERO)

	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_tiled(base: Transform2D, local: Transform2D, rect: Rect2) -> void:
	draw_set_transform_matrix(base * local)
	draw_texture_rect(side_texture, rect, true)
