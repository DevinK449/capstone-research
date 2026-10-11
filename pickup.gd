extends Node2D
## Healing potion dropped by enemies. Walk over it to pick it up.

var player


func _process(_delta: float) -> void:
	queue_redraw()
	if player != null and not player.dead and position.distance_to(player.position) < 26.0:
		player.potions += 1
		player.health_changed.emit()
		get_tree().call_group("game", "hit_fx", position, "+1 Potion", Color(1.0, 0.55, 0.75), 0.0)
		queue_free()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var y := sin(t * 4.0) * 3.0
	draw_set_transform(Vector2(0, 9), 0.0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(0, y), 15.0 + sin(t * 6.0) * 2.0, Color(1.0, 0.4, 0.6, 0.18))
	var outline := Color(0.15, 0.05, 0.08)
	draw_rect(Rect2(-4, -12 + y, 8, 8), outline)
	draw_circle(Vector2(0, 2 + y), 9.5, outline)
	draw_rect(Rect2(-2.5, -11 + y, 5, 7), Color(0.85, 0.85, 0.95, 0.9))
	draw_circle(Vector2(0, 2 + y), 8.0, Color(0.92, 0.2, 0.4))
	draw_rect(Rect2(-3, -15 + y, 6, 4), Color(0.7, 0.5, 0.3))
	draw_circle(Vector2(-3, -1 + y), 2.5, Color(1, 1, 1, 0.6))
