extends Node
## Autoload that reads and writes the save file as JSON (requirements 1.7.x).

const SAVE_PATH := "user://savegame.json"

## Set by the main menu so the game scene knows to load instead of starting fresh.
var pending_load := false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	print("Game saved: ", data)


func load_game() -> Dictionary:
	if not has_save():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		return parsed
	push_error("Save file is corrupted, ignoring it")
	return {}


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
