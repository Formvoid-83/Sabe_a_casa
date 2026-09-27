extends Node

# Autoloaded singleton (see project.godot [autoload]).
# Stashes the ending message so end_screen.tscn can read it after the fade,
# since change_scene_to_file() doesn't let us pass arguments directly.

const END_SCREEN := "res://scenes/menu/end_screen.tscn"
const BAD_ENDING_MESSAGE := "Buen trabajo, pero a la sopa le falta algo"
# TODO: replace with the real good ending text/flow once it's designed.
const GOOD_ENDING_MESSAGE := "¡Felicidades! (Final bueno pendiente)"

var pending_message := ""

func trigger_bad_ending() -> void:
	pending_message = BAD_ENDING_MESSAGE
	FadeTransition.go_to(END_SCREEN)

func trigger_good_ending() -> void:
	pending_message = GOOD_ENDING_MESSAGE
	FadeTransition.go_to(END_SCREEN)
