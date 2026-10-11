extends Node2D
## Draws the forest arena background. The walls you collide with are the
## separate "Walls" StaticBody2D in game.tscn.

const RECT := Rect2(40, 60, 1072, 540)

## The boss lair uses darker, autumn colours.
var lair := false:
	set(value):
		lair = value
		queue_redraw()

var _patches: Array = []
var _tufts: Array = []
var _flowers: Array = []
var _trees: Array = []


func _ready() -> void:
	# Fixed seed so the decorations look the same every time.
	var rng := RandomNumberGenerator.new()
	rng.seed = 490
	var inner := RECT.grow(-12.0)
	for i in 22:
		_patches.append([_rand_point(rng, inner), rng.randf_range(30, 70)])
	for i in 160:
		_tufts.append(_rand_point(rng, inner))
	for i in 45:
		_flowers.append([_rand_point(rng, inner), rng.randi_range(0, 2)])
	var x := RECT.position.x - 10.0
	while x < RECT.end.x + 20.0:
		_trees.append([Vector2(x + rng.randf_range(-8, 8), RECT.end.y + rng.randf_range(10, 30)), rng.randf_range(24, 34)])
		_trees.append([Vector2(x + rng.randf_range(-8, 8), RECT.position.y - rng.randf_range(0, 12)), rng.randf_range(22, 30)])
		x += rng.randf_range(38, 52)
	var y := RECT.position.y
	while y < RECT.end.y + 20.0:
		_trees.append([Vector2(RECT.position.x - rng.randf_range(12, 30), y), rng.randf_range(24, 34)])
		_trees.append([Vector2(RECT.end.x + rng.randf_range(12, 30), y), rng.randf_range(24, 34)])
		y += rng.randf_range(38, 52)
	_trees.sort_custom(func(a, b): return a[0].y < b[0].y)


func _rand_point(rng: RandomNumberGenerator, rect: Rect2) -> Vector2:
	return Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))


func _draw() -> void:
	var grass := Color(0.3, 0.3, 0.17) if lair else Color(0.24, 0.42, 0.2)
	var dark := Color(0.13, 0.11, 0.07) if lair else Color(0.08, 0.16, 0.08)
	var leaf := Color(0.55, 0.32, 0.12) if lair else Color(0.16, 0.42, 0.18)
	var flower_colors := [Color(0.85, 0.5, 0.2), Color(0.7, 0.35, 0.15), Color(0.9, 0.7, 0.3)] if lair \
			else [Color(1, 0.95, 0.5), Color(1, 1, 1), Color(0.95, 0.55, 0.75)]

	draw_rect(Rect2(-60, -60, 1272, 768), dark)
	draw_rect(RECT, grass)
	for p in _patches:
		draw_circle(p[0], p[1], Color(grass.lightened(0.08), 0.5))
	for p in _tufts:
		for tip in [Vector2(-3, -6), Vector2(0, -8), Vector2(3, -6)]:
			draw_line(p, p + tip, grass.darkened(0.25), 1.5, true)
	for f in _flowers:
		draw_circle(f[0], 2.5, flower_colors[f[1]])
	for i in 4:
		draw_rect(RECT.grow(-i * 5.0), Color(0, 0, 0, 0.09), false, 5.0)

	for tr in _trees:
		var pos: Vector2 = tr[0]
		var r: float = tr[1]
		draw_set_transform(pos + Vector2(4, r * 0.7), 0.0, Vector2(1, 0.45))
		draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(pos.x - 4, pos.y, 8, r * 0.6), Color(0.35, 0.22, 0.12))
		draw_circle(pos, r + 2.0, leaf.darkened(0.55))
		draw_circle(pos, r, leaf)
		draw_circle(pos + Vector2(-r * 0.25, -r * 0.3), r * 0.55, leaf.lightened(0.15))
