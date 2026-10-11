extends CharacterBody2D
## Player: movement, mouse-aimed sword attack, health and healing potions.
## Controls are set in Project Settings > Input Map.

signal died
signal health_changed

const SPEED := 260.0
const ATTACK_ARC := 1.75 # radians (~100 degrees)
const ATTACK_DAMAGE := 25
const SWING_TIME := 0.15
const POTION_HEAL := 40

const BODY_COLOR := Color(0.32, 0.62, 0.95)
const OUTLINE := Color(0.06, 0.08, 0.14)

var max_health := 100
var health := 100
var potions := 2
var dead := false
var radius := 16.0

var _aim_dir := Vector2.RIGHT
var _swing_time := 0.0
var _hurt_flash := 0.0

@onready var _attack_area: Area2D = $AttackArea
@onready var _attack_cooldown: Timer = $AttackCooldown
@onready var _invuln_timer: Timer = $InvulnTimer


func _ready() -> void:
	radius = ($CollisionShape2D.shape as CircleShape2D).radius


func _physics_process(delta: float) -> void:
	if dead:
		return
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED
	move_and_slide()

	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		_aim_dir = to_mouse.normalized()
	if Input.is_action_just_pressed("attack"):
		attack()
	if Input.is_action_just_pressed("drink_potion"):
		use_potion()

	_swing_time -= delta
	_hurt_flash -= delta
	queue_redraw()


func attack() -> void:
	if not _attack_cooldown.is_stopped():
		return
	_attack_cooldown.start()
	_swing_time = SWING_TIME
	# AttackArea finds enemies in range; only hit the ones in front of the player.
	var bodies: Array = _attack_area.get_overlapping_bodies()
	for enemy in bodies:
		var to_enemy: Vector2 = enemy.global_position - global_position
		if enemy.is_in_group("enemies") and absf(_aim_dir.angle_to(to_enemy)) <= ATTACK_ARC / 2.0:
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
	if dead or not _invuln_timer.is_stopped():
		return
	health = maxi(health - amount, 0)
	_invuln_timer.start()
	_hurt_flash = 0.2
	get_tree().call_group("game", "hit_fx", global_position, "-%d" % amount, Color(1.0, 0.35, 0.3), 7.0)
	health_changed.emit()
	if health == 0:
		dead = true
		queue_redraw()
		died.emit()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var moving := velocity != Vector2.ZERO and not dead
	var center := Vector2(0, sin(t * 16.0) * 2.0 if moving else 0.0)

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
		draw_arc(Vector2.ZERO, 62.0, aim_angle - ATTACK_ARC / 2.0, aim_angle + ATTACK_ARC / 2.0,
				24, Color(1, 1, 0.8, 0.45 * alpha), 18.0, true)
		draw_arc(Vector2.ZERO, 70.0, aim_angle - ATTACK_ARC / 2.0, aim_angle + ATTACK_ARC / 2.0,
				24, Color(1, 1, 1, 0.9 * alpha), 3.0, true)

	# Sword: rests at the side, sweeps across the arc while swinging
	var sword_angle := aim_angle + 0.9
	if _swing_time > 0.0:
		sword_angle = aim_angle + lerpf(-ATTACK_ARC / 2.0, ATTACK_ARC / 2.0, 1.0 - _swing_time / SWING_TIME)
	var sdir := Vector2.from_angle(sword_angle)
	var hand := center + sdir * (radius - 3.0)
	var tip := hand + sdir * 32.0
	draw_line(hand, tip, OUTLINE, 8.0, true)
	draw_line(hand, tip, Color(0.82, 0.88, 0.98), 4.5, true)
	var guard := hand + sdir * 3.0
	var perp := sdir.orthogonal() * 7.0
	draw_line(guard - perp, guard + perp, OUTLINE, 6.0, true)
	draw_line(guard - perp, guard + perp, Color(0.95, 0.75, 0.25), 3.5, true)

	# Body (blinks while invulnerable)
	var body := Color(1.0, 0.4, 0.4) if _hurt_flash > 0.0 else BODY_COLOR
	var a := 0.55 if not _invuln_timer.is_stopped() and int(t * 20.0) % 2 == 0 else 1.0
	draw_circle(center, radius + 2.5, Color(OUTLINE, a))
	draw_circle(center, radius, Color(body, a))
	draw_circle(center + Vector2(0, radius * 0.35), radius * 0.75, Color(body.darkened(0.2), a))
	draw_circle(center + Vector2(-5, -7), radius * 0.32, Color(1, 1, 1, 0.3 * a))

	# Eyes look toward the mouse
	for side in [-1, 1]:
		var e := center + Vector2(side * 5.5, -3.0) + _aim_dir * 4.0
		draw_circle(e, 3.4, Color(1, 1, 1, a))
		draw_circle(e + _aim_dir * 1.3, 1.8, Color(OUTLINE, a))


func _ellipse(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_set_transform(pos, 0.0, size / size.x)
	draw_circle(Vector2.ZERO, size.x, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
