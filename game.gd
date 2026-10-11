extends Node2D
## Runs the areas, HUD, pause menu, game over / victory screens, and saving.

const PlayerScript := preload("res://player.gd")
const EnemyScript := preload("res://enemy.gd")
const BossScript := preload("res://boss.gd")
const PickupScript := preload("res://pickup.gd")
const FX := preload("res://fx.gd")

const ARENA := Rect2(40, 60, 1072, 540)
const AREAS := [
	{"name": "Forest Edge", "slimes": 3, "boss": false},
	{"name": "Deep Woods", "slimes": 6, "boss": false},
	{"name": "Thorn Golem's Lair", "slimes": 0, "boss": true},
]
const POTION_DROP_CHANCE := 0.35

var player
var area := 0
var kills := 0
var enemies_left := 0
var game_over := false

var _world: Node2D
var _ui: CanvasLayer
var _health_bar: ProgressBar
var _hud: Label
var _banner: Label
var _banner_time := 0.0
var _pause_panel: Control
var _end_panel: Control
var _end_label: Label
var _boss_bar: ProgressBar
var _boss_name: Label
var _boss
var _shake := 0.0

# Background decorations, generated once with a fixed seed.
var _patches: Array = []
var _tufts: Array = []
var _flowers: Array = []
var _trees: Array = []


func _ready() -> void:
	add_to_group("game")
	_generate_decorations()
	# Gameplay lives under _world so pausing stops it while menus keep working.
	_world = Node2D.new()
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)

	player = PlayerScript.new()
	player.arena = ARENA
	player.died.connect(_on_player_died)
	player.health_changed.connect(_update_hud)
	_world.add_child(player)

	_build_ui()

	if SaveManager.pending_load:
		SaveManager.pending_load = false
		_apply_save(SaveManager.load_game())
	_enter_area(area)


func _process(delta: float) -> void:
	_banner_time -= delta
	_banner.visible = _banner_time > 0.0
	_banner.modulate.a = clampf(_banner_time * 2.0, 0.0, 1.0)

	# Screen shake: jiggle the whole world, then settle.
	if _shake > 0.0 and not get_tree().paused:
		_shake = maxf(_shake - 30.0 * delta, 0.0)
		position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	else:
		position = Vector2.ZERO

	var boss_alive: bool = is_instance_valid(_boss)
	_boss_bar.visible = boss_alive
	_boss_name.visible = boss_alive
	if boss_alive:
		_boss_bar.max_value = _boss.max_health
		_boss_bar.value = maxi(_boss.health, 0)
		_boss_name.text = _boss.display_name + ("  (ENRAGED)" if _boss.is_enraged() else "")


## Called through the "game" group by the player, enemies and pickups.
func hit_fx(at: Vector2, text: String, color: Color, shake: float) -> void:
	var fx := FX.new()
	fx.text = text
	fx.color = color
	fx.position = at
	fx.life = 0.8
	fx.burst(6, 160.0)
	_world.add_child(fx)
	_shake = maxf(_shake, shake)


func death_fx(at: Vector2, color: Color, count: int) -> void:
	var fx := FX.new()
	fx.color = color
	fx.position = at
	fx.life = 0.6
	fx.burst(count, 320.0)
	_world.add_child(fx)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not game_over:
		if get_tree().paused:
			_resume()
		else:
			get_tree().paused = true
			_pause_panel.visible = true


func _generate_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 490
	var inner := ARENA.grow(-12.0)
	for i in 22:
		_patches.append([_rand_point(rng, inner), rng.randf_range(30, 70)])
	for i in 160:
		_tufts.append(_rand_point(rng, inner))
	for i in 45:
		_flowers.append([_rand_point(rng, inner), rng.randi_range(0, 2)])
	# Trees all around the arena border
	var x := ARENA.position.x - 10.0
	while x < ARENA.end.x + 20.0:
		_trees.append([Vector2(x + rng.randf_range(-8, 8), ARENA.end.y + rng.randf_range(10, 30)), rng.randf_range(24, 34)])
		_trees.append([Vector2(x + rng.randf_range(-8, 8), ARENA.position.y - rng.randf_range(0, 12)), rng.randf_range(22, 30)])
		x += rng.randf_range(38, 52)
	var y := ARENA.position.y
	while y < ARENA.end.y + 20.0:
		_trees.append([Vector2(ARENA.position.x - rng.randf_range(12, 30), y), rng.randf_range(24, 34)])
		_trees.append([Vector2(ARENA.end.x + rng.randf_range(12, 30), y), rng.randf_range(24, 34)])
		y += rng.randf_range(38, 52)
	_trees.sort_custom(func(a, b): return a[0].y < b[0].y)


func _rand_point(rng: RandomNumberGenerator, rect: Rect2) -> Vector2:
	return Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))


func _draw() -> void:
	# The boss lair is darker and more autumn-coloured than the forest areas.
	var lair := area == AREAS.size() - 1
	var grass := Color(0.24, 0.42, 0.2) if not lair else Color(0.3, 0.3, 0.17)
	var dark := Color(0.08, 0.16, 0.08) if not lair else Color(0.13, 0.11, 0.07)

	draw_rect(Rect2(-60, -60, 1272, 768), dark)
	draw_rect(ARENA, grass)
	for p in _patches:
		draw_circle(p[0], p[1], Color(grass.lightened(0.08), 0.5))
	for p in _tufts:
		var c := grass.darkened(0.25)
		draw_line(p, p + Vector2(-3, -6), c, 1.5, true)
		draw_line(p, p + Vector2(0, -8), c, 1.5, true)
		draw_line(p, p + Vector2(3, -6), c, 1.5, true)
	var flower_colors := [Color(1, 0.95, 0.5), Color(1, 1, 1), Color(0.95, 0.55, 0.75)]
	if lair:
		flower_colors = [Color(0.85, 0.5, 0.2), Color(0.7, 0.35, 0.15), Color(0.9, 0.7, 0.3)]
	for f in _flowers:
		draw_circle(f[0], 2.5, flower_colors[f[1]])
	# Soft dark edge so the arena looks enclosed
	for i in 4:
		draw_rect(ARENA.grow(-i * 5.0), Color(0, 0, 0, 0.09), false, 5.0)

	# Trees
	var leaf := Color(0.16, 0.42, 0.18) if not lair else Color(0.55, 0.32, 0.12)
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


# --- Areas & enemies ---------------------------------------------------------

func _enter_area(index: int) -> void:
	area = index
	var data: Dictionary = AREAS[area]
	player.position = ARENA.get_center() + Vector2(0, 180)
	enemies_left = 0
	for i in data["slimes"]:
		var slime = EnemyScript.new()
		slime.speed = randf_range(90.0, 140.0)
		_spawn(slime, Vector2(
			randf_range(ARENA.position.x + 40, ARENA.end.x - 40),
			randf_range(ARENA.position.y + 40, ARENA.position.y + 200)))
	if data["boss"]:
		_boss = BossScript.new()
		_spawn(_boss, ARENA.get_center() + Vector2(0, -150))
	queue_redraw()
	_show_banner("Area %d: %s" % [area + 1, data["name"]])
	# Requirement 1.7.1: autosave whenever the player enters a new area.
	SaveManager.save_game(_make_save())
	_update_hud()


func _spawn(enemy, pos: Vector2) -> void:
	enemy.player = player
	enemy.arena = ARENA
	enemy.position = pos
	enemy.defeated.connect(_on_enemy_defeated)
	_world.add_child(enemy)
	enemies_left += 1


func _on_enemy_defeated(enemy) -> void:
	enemies_left -= 1
	kills += 1
	if enemy.is_boss:
		# Requirement 1.4.8: show the player they defeated the boss.
		_show_banner("BOSS DEFEATED: %s!" % enemy.display_name, 3.0)
	elif randf() < POTION_DROP_CHANCE:
		var potion = PickupScript.new()
		potion.player = player
		potion.position = enemy.position
		_world.add_child.call_deferred(potion)
	_update_hud()

	if enemies_left > 0:
		return
	if area + 1 < AREAS.size():
		_show_banner("Area cleared!")
		await get_tree().create_timer(1.5, false).timeout
		if not game_over:
			_enter_area(area + 1)
	else:
		await get_tree().create_timer(2.0, false).timeout
		if not game_over:
			_win()


# --- Saving (requirements 1.7.x) ----------------------------------------------

func _make_save() -> Dictionary:
	return {
		"area": area,
		"health": player.health,
		"max_health": player.max_health,
		"potions": player.potions,
		"kills": kills,
	}


func _apply_save(data: Dictionary) -> void:
	if data.is_empty():
		return
	# JSON stores numbers as floats, so convert back to int.
	area = clampi(int(data.get("area", 0)), 0, AREAS.size() - 1)
	player.max_health = int(data.get("max_health", 100))
	player.health = clampi(int(data.get("health", player.max_health)), 1, player.max_health)
	player.potions = int(data.get("potions", 0))
	kills = int(data.get("kills", 0))


# --- UI ---------------------------------------------------------------------

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)

	var top := ColorRect.new()
	top.color = Color(0, 0, 0, 0.45)
	top.position = Vector2.ZERO
	top.size = Vector2(1152, 52)
	_ui.add_child(top)

	_health_bar = _make_bar(Vector2(40, 14), Vector2(240, 24), Color(0.9, 0.22, 0.25))
	_hud = _make_label(Vector2(296, 14), 18)

	var hint := _make_label(Vector2(40, 612), 15)
	hint.text = "WASD move    Mouse aim    Left click attack    Q drink potion    Esc pause"
	hint.modulate = Color(1, 1, 1, 0.75)

	_boss_name = _make_label(Vector2(0, 64), 20)
	_boss_name.size = Vector2(1152, 30)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.add_theme_color_override("font_color", Color(1.0, 0.8, 0.45))
	_boss_bar = _make_bar(Vector2(326, 94), Vector2(500, 16), Color(0.85, 0.45, 0.15))

	_banner = _make_label(Vector2(0, 150), 40)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.size = Vector2(1152, 60)

	var pause := _make_panel("Paused", [["Resume", _resume], ["Save & Quit", _save_and_quit]])
	_pause_panel = pause[0]
	var end := _make_panel("", [["Restart", _restart], ["Main Menu", _to_menu]])
	_end_panel = end[0]
	_end_label = end[1]


func _make_label(pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_ui.add_child(label)
	return label


func _make_bar(pos: Vector2, size: Vector2, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = size
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.05, 0.05, 0.9)
	bg.set_border_width_all(2)
	bg.border_color = Color(0, 0, 0)
	bg.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	fill.border_width_bottom = 4
	fill.border_color = fill_color.darkened(0.3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	_ui.add_child(bar)
	return bar


func _make_panel(title: String, buttons: Array) -> Array:
	var root := ColorRect.new()
	root.color = Color(0, 0, 0, 0.6)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	_ui.add_child(root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	box.add_child(label)

	for b in buttons:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(240, 42)
		btn.pressed.connect(b[1])
		box.add_child(btn)
	return [root, label]


func _update_hud() -> void:
	_health_bar.max_value = player.max_health
	_health_bar.value = player.health
	_hud.text = "HP %d/%d     Potions: %d     Area %d/%d     Enemies left: %d     Kills: %d" % [
		player.health, player.max_health, player.potions,
		area + 1, AREAS.size(), enemies_left, kills]


func _show_banner(text: String, seconds := 2.0) -> void:
	_banner.text = text
	_banner_time = seconds


# --- Game flow ---------------------------------------------------------------

func _on_player_died() -> void:
	game_over = true
	_end_label.text = "You were defeated"
	_end_panel.visible = true
	get_tree().paused = true


func _win() -> void:
	game_over = true
	SaveManager.delete_save()
	_end_label.text = "Victory! The Thorn Golem has fallen.\nTotal kills: %d" % kills
	_end_panel.visible = true
	get_tree().paused = true


func _resume() -> void:
	get_tree().paused = false
	_pause_panel.visible = false


## Requirement 1.7.2: save and quit from the pause menu.
func _save_and_quit() -> void:
	SaveManager.save_game(_make_save())
	_to_menu()


## Requirement 1.4.4: restart after being defeated (from the last autosave).
func _restart() -> void:
	get_tree().paused = false
	SaveManager.pending_load = SaveManager.has_save()
	get_tree().reload_current_scene()


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
