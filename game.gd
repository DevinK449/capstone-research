extends Node2D
## Runs the areas, HUD, pause menu, game over / victory screens, and saving.
## All the nodes (player, walls, HUD, menus) are laid out in game.tscn.

const SlimeScene := preload("res://enemy.tscn")
const BossScene := preload("res://boss.tscn")
const PotionScene := preload("res://pickup.tscn")
const FX := preload("res://fx.gd")

const AREAS := [
	{"name": "Forest Edge", "slimes": 3, "boss": false},
	{"name": "Deep Woods", "slimes": 6, "boss": false},
	{"name": "Thorn Golem's Lair", "slimes": 0, "boss": true},
]
const SLIME_SPAWN := Rect2(80, 100, 992, 160)
const POTION_DROP_CHANCE := 0.35

var area := 0
var kills := 0
var enemies_left := 0
var game_over := false

var _boss
var _shake := 0.0

@onready var player = $World/Player
@onready var _world: Node2D = $World
@onready var _arena: Node2D = $Arena
@onready var _player_spawn: Marker2D = $World/PlayerSpawn
@onready var _boss_spawn: Marker2D = $World/BossSpawn
@onready var _health_bar: ProgressBar = $UI/HealthBar
@onready var _hud: Label = $UI/HudLabel
@onready var _boss_name: Label = $UI/BossName
@onready var _boss_bar: ProgressBar = $UI/BossBar
@onready var _banner: Label = $UI/Banner
@onready var _banner_timer: Timer = $BannerTimer
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _end_screen: Control = $UI/EndScreen
@onready var _end_label: Label = $UI/EndScreen/Center/VBox/Title


func _ready() -> void:
	if SaveManager.pending_load:
		SaveManager.pending_load = false
		_apply_save(SaveManager.load_game())
	_enter_area(area)


func _process(delta: float) -> void:
	_banner.visible = not _banner_timer.is_stopped()
	_banner.modulate.a = clampf(_banner_timer.time_left * 2.0, 0.0, 1.0)

	# Screen shake: jiggle the whole scene, then settle.
	if _shake > 0.0 and not get_tree().paused:
		_shake = maxf(_shake - 30.0 * delta, 0.0)
		position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	else:
		position = Vector2.ZERO

	var boss_alive := is_instance_valid(_boss)
	_boss_bar.visible = boss_alive
	_boss_name.visible = boss_alive
	if boss_alive:
		_boss_bar.value = maxi(_boss.health, 0)
		_boss_name.text = _boss.display_name + ("  (ENRAGED)" if _boss.is_enraged() else "")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not game_over:
		if get_tree().paused:
			_resume()
		else:
			get_tree().paused = true
			_pause_menu.visible = true


# --- Areas & enemies ---------------------------------------------------------

func _enter_area(index: int) -> void:
	area = index
	var data: Dictionary = AREAS[area]
	_arena.lair = data["boss"]
	player.position = _player_spawn.position
	enemies_left = 0
	for i in data["slimes"]:
		var slime = SlimeScene.instantiate()
		slime.speed = randf_range(90.0, 140.0)
		_spawn(slime, Vector2(randf_range(SLIME_SPAWN.position.x, SLIME_SPAWN.end.x),
				randf_range(SLIME_SPAWN.position.y, SLIME_SPAWN.end.y)))
	if data["boss"]:
		_boss = BossScene.instantiate()
		_spawn(_boss, _boss_spawn.position)
		_boss_bar.max_value = _boss.max_health
	_show_banner("Area %d: %s" % [area + 1, data["name"]])
	# Requirement 1.7.1: autosave whenever the player enters a new area.
	SaveManager.save_game(_make_save())
	_update_hud()


func _spawn(enemy, pos: Vector2) -> void:
	enemy.player = player
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
		var potion = PotionScene.instantiate()
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


# --- HUD & effects ------------------------------------------------------------

func _update_hud() -> void:
	_health_bar.max_value = player.max_health
	_health_bar.value = player.health
	_hud.text = "HP %d/%d     Potions: %d     Area %d/%d     Enemies left: %d     Kills: %d" % [
		player.health, player.max_health, player.potions,
		area + 1, AREAS.size(), enemies_left, kills]


func _show_banner(text: String, seconds := 2.0) -> void:
	_banner.text = text
	_banner_timer.start(seconds)


## Called through the "game" group by the player, enemies and potions.
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
	fx.burst(count, 320.0)
	_world.add_child(fx)


# --- Game flow (buttons are connected in game.tscn) ---------------------------

func _on_player_died() -> void:
	game_over = true
	_end_label.text = "You were defeated"
	_end_screen.visible = true
	get_tree().paused = true


func _win() -> void:
	game_over = true
	SaveManager.delete_save()
	_end_label.text = "Victory! The Thorn Golem has fallen.\nTotal kills: %d" % kills
	_end_screen.visible = true
	get_tree().paused = true


func _resume() -> void:
	get_tree().paused = false
	_pause_menu.visible = false


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
