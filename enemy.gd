extends CharacterBody2D
## Basic enemy (slime): chases the player and deals contact damage. Dies at 0 health (1.4.6).
## Stats are exported so they can be changed in the Inspector (the boss scene does this).

signal defeated(enemy)

@export var max_health := 50
@export var speed := 110.0
@export var contact_damage := 10
@export var color := Color(0.42, 0.86, 0.38)
@export var display_name := "Slime"
@export var is_boss := false

var health := 0
var radius := 14.0
var player

var _knockback := Vector2.ZERO
var _hurt_flash := 0.0
var _phase := 0.0

@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	health = max_health
	radius = ($CollisionShape2D.shape as CircleShape2D).radius
	_phase = randf() * 10.0


func _physics_process(delta: float) -> void:
	_hurt_flash -= delta
	queue_redraw()
	if player == null or player.dead:
		return
	velocity = global_position.direction_to(player.global_position) * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1500.0 * delta)
	move_and_slide()

	# Contact damage: the Hitbox only detects the player's layer.
	if _hitbox.overlaps_body(player):
		player.take_damage(contact_damage)


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
	return Vector2.DOWN if player == null else global_position.direction_to(player.global_position)


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

	for side in [-1, 1]:
		var e := body_pos + Vector2(side * radius * 0.38, -size.y * 0.05) + _look_dir() * 2.5
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
