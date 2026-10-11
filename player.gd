extends Node2D
## Player: WASD movement, mouse-aimed sword attack, health and healing potions.

signal died
signal health_changed

const SPEED := 260.0
const ATTACK_RANGE := 70.0
const ATTACK_ARC := 1.75 # radians (~100 degrees)
const ATTACK_DAMAGE := 25
const ATTACK_COOLDOWN := 0.35
const SWING_TIME := 0.15
const POTION_HEAL := 40
const INVULN_TIME := 0.6

const BODY_COLOR := Color(0.32, 0.62, 0.95)
const OUTLINE := Color(0.06, 0.08, 0.14)

var radius := 16.0
var arena: Rect2
var max_health := 100
var health := 100
var potions := 2
var dead := false

var _aim_dir := Vector2.RIGHT
var _attack_timer := 0.0
var _swing_time := 0.0
var _invuln := 0.0
var _hurt_flash := 0.0
var _moving := false


func _ready() -> void:
	z_index = 1


func _process(delta: float) -> void:
	if dead:
		return
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		dir.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		dir.x += 1
	_moving = dir != Vector2.ZERO
	position += dir.normalized() * SPEED * delta
	var margin := Vector2(radius, radius)
	position = position.clamp(arena.position + margin, arena.end - margin)

	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		_aim_dir = to_mouse.normalized()

	_attack_timer -= delta
	_swing_time -= delta
	_invuln -= delta
	_hurt_flash -= delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		attack()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Q:
		use_potion()


func attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = ATTACK_COOLDOWN
	_swing_time = SWING_TIME
	# Hit every enemy inside the swing arc in front of the player.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var to_enemy: Vector2 = enemy.global_position - global_position
		var in_range: bool = to_enemy.length() <= ATTACK_RANGE + enemy.radius
		if in_range and absf(_aim_dir.angle_to(to_enemy)) <= ATTACK_ARC / 2.0:
			enemy.take_damage(ATTACK_DAMAGE, _aim_dir)


## Requirement 1.4.7: heal without going over max health.
func use_potion() -> void:
	if potions <= 0 or health >= max_health:
		return
	potions -= 1
	var healed := mini(POTION_HEAL, max_health - health)
	health += healed
	get_tree().call_group("game", "hit_fx", global_position, "+%d" % healed, Color(0.4, 1.0, 0.5), 0.0)
	health_changed.emit()


## Requirements 1.4.2 / 1.4.3: enemies damage the player, player dies at 0 health.
func take_damage(amount: int) -> void:
	if dead or _invuln > 0.0:
		return
	health = maxi(health - amount, 0)
	_invuln = INVULN_TIME
	_hurt_flash = 0.2
	get_tree().call_group("game", "hit_fx", global_position, "-%d" % amount, Color(1.0, 0.35, 0.3), 7.0)
	health_changed.emit()
	if health == 0:
		dead = true
		queue_redraw()
		died.emit()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var bob := sin(t * 16.0) * 2.0 if _moving and not dead else 0.0
	var center := Vector2(0, bob)

	# Shadow
	_ellipse(Vector2(0, radius * 0.85), Vector2(radius * 1.1, radius * 0.4), Color(0, 0, 0, 0.3))
	if dead:
		draw_circle(Vector2.ZERO, radius + 2.5, OUTLINE)
		draw_circle(Vector2.ZERO, radius, Color(0.35, 0.37, 0.42))
		for side in [-1, 1]:
			var e := Vector2(side * 6, -2)
			draw_line(e + Vector2(-3, -3), e + Vector2(3, 3), OUTLINE, 2.0)
			draw_line(e + Vector2(3, -3), e + Vector2(-3, 3), OUTLINE, 2.0)
		return

	# Swing trail
	var aim_angle := _aim_dir.angle()
	if _swing_time > 0.0:
		var alpha := _swing_time / SWING_TIME
		draw_arc(Vector2.ZERO, ATTACK_RANGE - 8.0, aim_angle - ATTACK_ARC / 2.0, aim_angle + ATTACK_ARC / 2.0,
				24, Color(1, 1, 0.8, 0.45 * alpha), 18.0, true)
		draw_arc(Vector2.ZERO, ATTACK_RANGE, aim_angle - ATTACK_ARC / 2.0, aim_angle + ATTACK_ARC / 2.0,
				24, Color(1, 1, 1, 0.9 * alpha), 3.0, true)

	# Sword: rests at the side, sweeps across the arc while swinging
	var sword_angle := aim_angle + 0.9
	if _swing_time > 0.0:
		var progress := 1.0 - _swing_time / SWING_TIME
		sword_angle = aim_angle + lerpf(-ATTACK_ARC / 2.0, ATTACK_ARC / 2.0, progress)
	var sdir := Vector2.from_angle(sword_angle)
	var hand := center + sdir * (radius - 3.0)
	var tip := hand + sdir * 32.0
	draw_line(hand, tip, OUTLINE, 8.0, true)
	draw_line(hand, tip, Color(0.82, 0.88, 0.98), 4.5, true)
	draw_line(hand + sdir * 3.0, tip - sdir * 2.0, Color(1, 1, 1, 0.8), 1.5, true)
	var guard := hand + sdir * 3.0
	var perp := sdir.orthogonal() * 7.0
	draw_line(guard - perp, guard + perp, OUTLINE, 6.0, true)
	draw_line(guard - perp, guard + perp, Color(0.95, 0.75, 0.25), 3.5, true)

	# Body
	var body := BODY_COLOR
	if _hurt_flash > 0.0:
		body = Color(1.0, 0.4, 0.4)
	var alpha_mul := 0.55 if _invuln > 0.0 and int(t * 20.0) % 2 == 0 else 1.0
	draw_circle(center, radius + 2.5, Color(OUTLINE, alpha_mul))
	draw_circle(center, radius, Color(body, alpha_mul))
	draw_circle(center + Vector2(0, radius * 0.35), radius * 0.75, Color(body.darkened(0.2), alpha_mul))
	draw_circle(center + Vector2(-5, -7), radius * 0.32, Color(1, 1, 1, 0.3 * alpha_mul))

	# Eyes look toward the mouse
	var look := _aim_dir * 4.0
	for side in [-1, 1]:
		var e := center + Vector2(side * 5.5, -3.0) + look
		draw_circle(e, 3.4, Color(1, 1, 1, alpha_mul))
		draw_circle(e + _aim_dir * 1.3, 1.8, Color(OUTLINE, alpha_mul))


func _ellipse(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_set_transform(pos, 0.0, size / size.x)
	draw_circle(Vector2.ZERO, size.x, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
