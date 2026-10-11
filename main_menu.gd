extends Control
## Main menu: New Game, Continue (only if a save exists), Quit.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.16, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var trees := Trees.new()
	trees.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trees.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(trees)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "Horse Plinko: Combat & Saving Research"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Clear 3 areas and defeat the Thorn Golem"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(1, 1, 1, 0.7)
	box.add_child(sub)

	_add_button(box, "New Game", _on_new_game)
	var cont := _add_button(box, "Continue", _on_continue)
	cont.disabled = not SaveManager.has_save()
	_add_button(box, "Quit", func() -> void: get_tree().quit())


## A ring of trees framing the menu, drawn on top of the background.
class Trees extends Control:
	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 60:
			var edge := rng.randi_range(0, 3)
			var p := Vector2(rng.randf_range(0, 1152), rng.randf_range(0, 648))
			match edge:
				0: p.y = rng.randf_range(-10, 70)
				1: p.y = rng.randf_range(580, 660)
				2: p.x = rng.randf_range(-10, 120)
				3: p.x = rng.randf_range(1030, 1160)
			var r := rng.randf_range(28, 46)
			draw_circle(p, r + 2.0, Color(0.05, 0.12, 0.05))
			draw_circle(p, r, Color(0.16, 0.4, 0.18))
			draw_circle(p + Vector2(-r * 0.25, -r * 0.3), r * 0.55, Color(0.22, 0.5, 0.24))


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _on_new_game() -> void:
	SaveManager.pending_load = false
	get_tree().change_scene_to_file("res://game.tscn")


func _on_continue() -> void:
	SaveManager.pending_load = true
	get_tree().change_scene_to_file("res://game.tscn")
