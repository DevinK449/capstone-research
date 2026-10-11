extends Area2D
## Thorn fired by the boss. Hurts the player on touch and breaks on walls.

const DAMAGE := 12

var velocity := Vector2.ZERO


func _physics_process(delta: float) -> void:
	position += velocity * delta


func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.take_damage(DAMAGE)
	queue_free()


func _draw() -> void:
	var d := velocity.normalized()
	var side := d.orthogonal() * 5.0
	var thorn := PackedVector2Array([d * 11.0, -d * 7.0 + side, -d * 4.0, -d * 7.0 - side, d * 11.0])
	draw_colored_polygon(thorn.slice(0, 4), Color(0.55, 0.85, 0.25))
	draw_polyline(thorn, Color(0.12, 0.25, 0.05), 2.0, true)
