extends "res://enemy.gd"
## Thorn Golem boss. Unique mechanic (1.4.5): every time BurstTimer runs out it fires
## a ring of thorns. Below half health it enrages (faster, denser rings).

const ThornScene := preload("res://projectile.tscn")
const TELEGRAPH_TIME := 0.5

var _rock := PackedVector2Array()

@onready var _burst_timer: Timer = $BurstTimer


func _ready() -> void:
	super()
	# Lumpy rock outline, generated once.
	for i in 14:
		_rock.append(Vector2.from_angle(TAU * i / 14.0) * radius * randf_range(0.88, 1.08))


func is_enraged() -> bool:
	return health < max_health / 2


func _on_burst_timer_timeout() -> void:
	_burst_timer.wait_time = 1.5 if is_enraged() else 2.6
	var count := 16 if is_enraged() else 10
	var offset := randf() * TAU
	for i in count:
		var thorn = ThornScene.instantiate()
		thorn.position = position
		thorn.velocity = Vector2.from_angle(offset + TAU * i / count) * 220.0
		get_parent().add_child(thorn)


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var fill := Color.WHITE if _hurt_flash > 0.0 else color
	var glow := Color(1.0, 0.3, 0.1) if is_enraged() else Color(1.0, 0.75, 0.2)

	_ellipse(Vector2(0, radius * 0.85), Vector2(radius * 1.2, radius * 0.4), Color(0, 0, 0, 0.35))

	# Telegraph: glowing ring right before the thorn burst
	if _burst_timer.time_left < TELEGRAPH_TIME:
		var k := 1.0 - _burst_timer.time_left / TELEGRAPH_TIME
		draw_arc(Vector2.ZERO, radius + 6.0 + 18.0 * k, 0.0, TAU, 40, Color(glow, 0.8 * k), 4.0, true)

	# Thorns around the body, slowly rotating
	var spin := t * (0.9 if is_enraged() else 0.4)
	for i in 10:
		var d := Vector2.from_angle(spin + TAU * i / 10.0)
		var base := d * radius * 0.85
		var side := d.orthogonal() * 6.0
		var thorn := PackedVector2Array([base - side, d * (radius + 13.0), base + side])
		draw_colored_polygon(thorn, Color(0.3, 0.55, 0.2))
		draw_polyline(thorn, Color(0.1, 0.2, 0.08), 2.0, true)

	# Rocky body with cracks and moss
	var outline := PackedVector2Array()
	var lower := PackedVector2Array()
	for p in _rock:
		outline.append(p * 1.08)
		lower.append(Vector2(p.x * 0.85, p.y * 0.5 + radius * 0.3))
	draw_colored_polygon(outline, Color(0.12, 0.1, 0.08))
	draw_colored_polygon(_rock, fill)
	draw_colored_polygon(lower, fill.darkened(0.2))
	draw_polyline(PackedVector2Array([Vector2(-20, -8), Vector2(-10, -2), Vector2(-14, 10)]), Color(0.2, 0.16, 0.12), 2.5, true)
	draw_polyline(PackedVector2Array([Vector2(16, -16), Vector2(8, -6), Vector2(18, 4)]), Color(0.2, 0.16, 0.12), 2.5, true)
	draw_circle(Vector2(-12, -22), 7.0, Color(0.35, 0.6, 0.25))
	draw_circle(Vector2(14, -24), 5.0, Color(0.35, 0.6, 0.25))

	# Glowing eyes facing the player
	for s in [-1, 1]:
		var e := Vector2(s * 11.0, -6.0) + _look_dir() * 4.0
		draw_circle(e, 8.0, Color(glow, 0.25))
		draw_circle(e, 4.5, glow)
		draw_circle(e, 2.0, Color(1, 1, 0.85))
