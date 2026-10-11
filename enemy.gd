extends Node2D
## Basic enemy (slime): chases the player and deals contact damage. Dies at 0 health (1.4.6).

signal defeated(enemy)

var radius := 14.0
var max_health := 50
var health := 50
var speed := 110.0
var contact_damage := 10
var color := Color(0.42, 0.86, 0.38)
var display_name := "Slime"
var is_boss := false
var player
var arena: Rect2

var _knockback := Vector2.ZERO
var _hurt_flash := 0.0
var _phase := 0.0


func _ready() -> void:
	add_to_group("enemies")
	_phase = randf() * 10.0


func _process(delta: float) -> void:
	_hurt_flash -= delta
	queue_redraw()
	if player == null or player.dead:
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > 1.0:
		position += to_player.normalized() * speed * delta
	position += _knockback * delta
	_knockback = _knockback.move_toward(Vector2.ZERO, 1500.0 * delta)
	var margin := Vector2(radius, radius)
	position = position.clamp(arena.position + margin, arena.end - margin)

	if to_player.length() < radius + player.radius:
		player.take_damage(contact_damage)
	_behavior(delta)


## Overridden by bosses to add their unique attacks.
func _behavior(_delta: float) -> void:
	pass


func take_damage(amount: int, hit_dir: Vector2) -> void:
	health -= amount
	_hurt_flash = 0.12
	_knockback = hit_dir * (80.0 if is_boss else 450.0)
	get_tree().call_group("game", "hit_fx", global_position, str(amount), Color(1.0, 0.95, 0.55), 4.0 if is_boss else 2.5)
	if health <= 0:
		get_tree().call_group("game", "death_fx", global_position, color, 30 if is_boss else 14)
		defeated.emit(self)
		queue_free()


func _look_dir() -> Vector2:
	if player == null:
		return Vector2.DOWN
	return (player.global_position - global_position).normalized()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0 + _phase
	var squish := 1.0 + sin(t * 9.0) * 0.1
	var size := Vector2(radius * squish, radius / squish)
	var body_pos := Vector2(0, radius - size.y)
	var fill := Color.WHITE if _hurt_flash > 0.0 else color

	_ellipse(Vector2(0, radius * 0.8), Vector2(radius * 1.15, radius * 0.4), Color(0, 0, 0, 0.3))
	_ellipse(body_pos, size + Vector2(2.5, 2.5), color.darkened(0.65))
	_ellipse(body_pos, size, fill)
	_ellipse(body_pos + Vector2(0, size.y * 0.35), size * Vector2(0.85, 0.55), fill.darkened(0.15))
	_ellipse(body_pos + Vector2(-radius * 0.35, -size.y * 0.4), Vector2(radius * 0.32, radius * 0.18), Color(1, 1, 1, 0.55))

	var look := _look_dir() * 2.5
	for side in [-1, 1]:
		var e := body_pos + Vector2(side * radius * 0.38, -size.y * 0.05) + look
		draw_circle(e, radius * 0.2, Color(0.08, 0.1, 0.08))
		draw_circle(e + Vector2(-0.8, -0.8), radius * 0.07, Color.WHITE)

	if health < max_health:
		var w := radius * 2.0
		var bar := Rect2(-w / 2.0, -radius - 12.0, w, 5.0)
		draw_rect(bar.grow(1.0), Color(0, 0, 0, 0.7))
		bar.size.x = w * clampf(float(health) / max_health, 0.0, 1.0)
		draw_rect(bar, Color(0.95, 0.3, 0.3))


func _ellipse(pos: Vector2, size: Vector2, col: Color) -> void:
	draw_set_transform(pos, 0.0, size / size.x)
	draw_circle(Vector2.ZERO, size.x, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
