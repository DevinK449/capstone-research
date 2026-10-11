# Capstone Research: Combat & Saving in Godot 4

Research project for CSCE 490 (team **Horse Plinko**). It's a small top-down action game I built to learn the Godot 4 / GDScript systems behind my assigned requirements: **1.4 Mechanics** and **1.7 Saving**.

Built with **Godot 4.7** and GDScript. All visuals are drawn in code, so there are no external assets.

## How to run
1. Install [Godot 4.7](https://godotengine.org/download).
2. Open Godot, click **Import**, and select `project.godot` in this folder.
3. Press **F5** (Run Project).

## Controls
| Key | Action |
|---|---|
| WASD | Move |
| Mouse | Aim |
| Left click | Sword swing |
| Q | Drink healing potion |
| Esc | Pause menu |

## What it does
- **3 areas**: two slime waves, then the **Thorn Golem** boss.
- **Boss mechanic**: the Golem fires rings of thorns. Below half health it enrages and fires faster, denser rings.
- **Health & potions**: potions heal 40 HP but never go over max health. Enemies sometimes drop potions.
- **Defeat & restart**: the player dies at 0 HP and can restart from the last autosave.
- **Saving**: the game autosaves to JSON (`user://savegame.json`) when you enter a new area. **Save & Quit** is in the pause menu, and **Continue** on the main menu restores the area, health, potions and kills.

## Requirements this explores
| Req | Where |
|---|---|
| 1.4.2 Enemies damage the user | `enemy.gd`, `projectile.gd` |
| 1.4.3 Defeated at 0 health | `player.gd` `take_damage()` |
| 1.4.4 Restart after defeat | `game.gd` `_restart()` |
| 1.4.5 Boss unique mechanic | `boss.gd` |
| 1.4.6 Enemies die at 0 health | `enemy.gd` `take_damage()` |
| 1.4.7 Potions don't exceed max HP | `player.gd` `use_potion()` |
| 1.4.8 Boss defeated message | `game.gd` `_on_enemy_defeated()` |
| 1.7.1 Autosave on new area | `game.gd` `_enter_area()` |
| 1.7.2 Save & quit from pause | `game.gd` `_save_and_quit()` |
| 1.7.3 / 1.7.4 Continue restores progress | `main_menu.gd`, `save_manager.gd`, `game.gd` `_apply_save()` |

## Project structure
The game is built from Godot scenes, with scripts attached for the behavior:

| Scene | Nodes | Script |
|---|---|---|
| `main_menu.tscn` | Buttons in a VBoxContainer, connected via signals | `main_menu.gd` |
| `game.tscn` | Arena, Walls (StaticBody2D), World, HUD/pause/end screens (CanvasLayer) | `game.gd`, `arena.gd` |
| `player.tscn` | CharacterBody2D + AttackArea (Area2D sword hitbox) + cooldown/invulnerability Timers | `player.gd` |
| `enemy.tscn` | CharacterBody2D + Hitbox (Area2D contact damage) | `enemy.gd` |
| `boss.tscn` | Same as enemy, stats set in the Inspector + BurstTimer | `boss.gd` |
| `projectile.tscn` | Area2D thorn | `projectile.gd` |
| `pickup.tscn` | Area2D potion | `pickup.gd` |

- `save_manager.gd` is an autoload that reads and writes the JSON save file.
- `fx.gd` is for floating damage numbers and particle bursts.
- Controls are defined in **Project Settings > Input Map** (`move_*`, `attack`, `drink_potion`, `pause`).
- Physics layers: 1 = world (walls), 2 = player, 3 = enemies.
