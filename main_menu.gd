extends Control
## Main menu. The buttons are laid out in main_menu.tscn and connected to the functions below.

@onready var _continue_button: Button = $Center/VBox/ContinueButton


func _ready() -> void:
	_continue_button.disabled = not SaveManager.has_save()


## Background: dark forest floor framed by trees.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.16, 0.09))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 60:
		var p := Vector2(rng.randf_range(0, 1152), rng.randf_range(0, 648))
		match rng.randi_range(0, 3):
			0: p.y = rng.randf_range(-10, 70)
			1: p.y = rng.randf_range(580, 660)
			2: p.x = rng.randf_range(-10, 120)
			3: p.x = rng.randf_range(1030, 1160)
		var r := rng.randf_range(28, 46)
		draw_circle(p, r + 2.0, Color(0.05, 0.12, 0.05))
		draw_circle(p, r, Color(0.16, 0.4, 0.18))
		draw_circle(p + Vector2(-r * 0.25, -r * 0.3), r * 0.55, Color(0.22, 0.5, 0.24))


func _on_new_game_pressed() -> void:
	SaveManager.pending_load = false
	get_tree().change_scene_to_file("res://game.tscn")


func _on_continue_pressed() -> void:
	SaveManager.pending_load = true
	get_tree().change_scene_to_file("res://game.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
