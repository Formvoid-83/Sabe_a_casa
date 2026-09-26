extends CanvasLayer

# Autoloaded singleton (see project.godot [autoload]).
# Global access to the bottom-of-screen speech bubble from any scene:
#   Bubbles.say("Hola!")                   # stays display_time seconds (0 = until Bubbles.close())
#   Bubbles.say("Hola!", 2.0)              # closes itself after 2 s
#   Bubbles.say("Hola!", 0)                # stays until Bubbles.close()
#   Bubbles.show_content(some_control)     # any Control (icons, rows, buttons...)
#   Bubbles.bubble.add_content(other)      # append more content to the open bubble
# Default display time: Bubbles.display_time, or the "Display Time" export on speech_bubble.tscn.

signal opened
signal closed

const BUBBLE_SCENE := preload("res://scenes/ui/speech_bubble.tscn")

var bubble: SpeechBubble

## Seconds the bubble stays on screen when no duration is passed (0 = until closed).
var display_time: float:
	get:
		return bubble.display_time
	set(value):
		bubble.display_time = value

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	bubble = BUBBLE_SCENE.instantiate()
	add_child(bubble)
	bubble.opened.connect(opened.emit)
	bubble.closed.connect(closed.emit)

## duration < 0 uses display_time; 0 stays open until close().
func say(text: String, duration := -1.0) -> SpeechBubble:
	return show_content(bubble.make_label(text), duration)

func show_content(content: Control, duration := -1.0) -> SpeechBubble:
	bubble.set_content(content)
	bubble.open(duration)
	return bubble

func close() -> void:
	bubble.close()

func is_open() -> bool:
	return bubble.is_open()
