extends Node2D
## Short-lived visual effect: a floating number and/or a burst of particles.

var text := ""
var color := Color.WHITE
var life := 0.6

var _age := 0.0
var _particles: Array = [] # each entry: [position, velocity, size]


func _ready() -> void:
	z_index = 5


func burst(count: int, speed: float) -> void:
	for i in count:
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(speed * 0.35, speed)
		_particles.append([Vector2.ZERO, vel, randf_range(2.0, 4.5)])


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	for p in _particles:
		p[0] += p[1] * delta
		p[1] = p[1].move_toward(Vector2.ZERO, 600.0 * delta)
	queue_redraw()


func _draw() -> void:
	var t := _age / life
	var c := color
	c.a = 1.0 - t
	for p in _particles:
		draw_circle(p[0], p[2] * (1.0 - t * 0.5), c)
	if text != "":
		var font := ThemeDB.fallback_font
		var pos := Vector2(-100, -18.0 - 34.0 * t)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 200, 20, 5, Color(0, 0, 0, c.a))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 200, 20, c)
