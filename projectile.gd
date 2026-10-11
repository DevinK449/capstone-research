extends Node2D
## Thorn fired by the boss. Damages the player on touch.

const RADIUS := 7.0
const DAMAGE := 12

var velocity := Vector2.ZERO
var player
var arena: Rect2


func _process(delta: float) -> void:
	position += velocity * delta
	if not arena.grow(40.0).has_point(position):
		queue_free()
		return
	if player != null and not player.dead and position.distance_to(player.position) < RADIUS + player.radius:
		player.take_damage(DAMAGE)
		queue_free()


func _draw() -> void:
	var d := velocity.normalized()
	var side := d.orthogonal() * 5.0
	var thorn := PackedVector2Array([d * 11.0, -d * 7.0 + side, -d * 4.0, -d * 7.0 - side])
	draw_colored_polygon(thorn, Color(0.55, 0.85, 0.25))
	thorn.append(thorn[0])
	draw_polyline(thorn, Color(0.12, 0.25, 0.05), 2.0, true)
