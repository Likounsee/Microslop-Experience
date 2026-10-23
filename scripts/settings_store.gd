extends Node
## Centralized settings storage for Microslop Experience.

const SETTINGS_PATH := "user://settings.cfg"
const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"

var settings_path: String = SETTINGS_PATH
var values: Dictionary = {
	"display_mode": "Fenêtré",
	"resolution": Vector2i(1280, 720),
	"vsync": true,
	"fps_limit": 0,
	"master_volume": 0.8,
	"music_volume": 0.7,
	"sfx_volume": 0.85,
	"language": "Français",
}

func _ready() -> void:
	load_settings()
	apply_audio_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	var error := _load_settings_config(config)
	if error != OK:
		return
	for key in values.keys():
		var candidate: Variant = config.get_value("settings", key, values[key])
		if _is_valid_setting(key, candidate):
			values[key] = candidate

## Recovers an interrupted replacement only when the backup parses successfully.
## If both files are damaged, leave them untouched for diagnosis rather than guessing.
func _load_settings_config(config: ConfigFile) -> Error:
	var load_error := config.load(settings_path)
	if load_error == OK:
		return OK

	var absolute_target := ProjectSettings.globalize_path(settings_path)
	var absolute_backup := ProjectSettings.globalize_path(settings_path + BACKUP_SUFFIX)
	if not FileAccess.file_exists(absolute_backup):
		return load_error

	var backup_config := ConfigFile.new()
	if backup_config.load(settings_path + BACKUP_SUFFIX) != OK:
		return load_error

	if FileAccess.file_exists(absolute_target):
		var remove_error := DirAccess.remove_absolute(absolute_target)
		if remove_error != OK:
			return remove_error
	var restore_error := DirAccess.rename_absolute(absolute_backup, absolute_target)
	if restore_error != OK:
		return restore_error
	return config.load(settings_path)

func _is_valid_setting(key: String, candidate: Variant) -> bool:
	match key:
		"display_mode":
			return typeof(candidate) == TYPE_STRING and candidate in [
				"Fenêtré", "Plein écran sans bordures", "Plein écran exclusif"
			]
		"resolution":
			return typeof(candidate) == TYPE_VECTOR2I and candidate in [
				Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)
			]
		"vsync":
			return typeof(candidate) == TYPE_BOOL
		"fps_limit":
			return typeof(candidate) == TYPE_INT and candidate in [0, 30, 60, 120, 144, 240]
		"master_volume", "music_volume", "sfx_volume":
			var numeric_type := typeof(candidate) == TYPE_FLOAT or typeof(candidate) == TYPE_INT
			return numeric_type and float(candidate) >= 0.0 and float(candidate) <= 1.0
		"language":
			return typeof(candidate) == TYPE_STRING and candidate in ["Français", "English"]
		_:
			return false

func save_settings() -> bool:
	var config := ConfigFile.new()
	for key in values.keys():
		if not _is_valid_setting(str(key), values[key]):
			push_warning("Refusing to save invalid setting: %s" % key)
			return false
		config.set_value("settings", key, values[key])

	var temporary_path := settings_path + TEMP_SUFFIX
	var backup_path := settings_path + BACKUP_SUFFIX
	var error := config.save(temporary_path)
	if error != OK:
		push_warning("Unable to write temporary settings: %s" % error)
		return false

	var verification := ConfigFile.new()
	error = verification.load(temporary_path)
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
		push_warning("Temporary settings failed verification: %s" % error)
		return false
	for key in values.keys():
		if not verification.has_section_key("settings", key) or verification.get_value("settings", key) != values[key]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
			push_warning("Temporary settings did not preserve value: %s" % key)
			return false

	var absolute_target := ProjectSettings.globalize_path(settings_path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	var had_previous := FileAccess.file_exists(absolute_target)
	if had_previous:
		# Never discard a backup while the current settings file is unreadable.
		var current := ConfigFile.new()
		error = current.load(settings_path)
		if error != OK:
			DirAccess.remove_absolute(absolute_temporary)
			push_warning("Refusing to replace unreadable settings; existing file preserved.")
			return false
		if FileAccess.file_exists(absolute_backup):
			error = DirAccess.remove_absolute(absolute_backup)
			if error != OK:
				DirAccess.remove_absolute(absolute_temporary)
				push_warning("Unable to remove stale settings backup: %s" % error)
				return false
		error = DirAccess.rename_absolute(absolute_target, absolute_backup)
		if error != OK:
			DirAccess.remove_absolute(absolute_temporary)
			push_warning("Unable to preserve previous settings: %s" % error)
			return false

	error = DirAccess.rename_absolute(absolute_temporary, absolute_target)
	if error != OK:
		DirAccess.remove_absolute(absolute_temporary)
		if had_previous and FileAccess.file_exists(absolute_backup):
			DirAccess.rename_absolute(absolute_backup, absolute_target)
		push_warning("Unable to replace settings file: %s" % error)
		return false
	if FileAccess.file_exists(absolute_backup):
		DirAccess.remove_absolute(absolute_backup)
	return true

func set_value_and_save(key: String, value: Variant) -> bool:
	# Validate writes as well as reads: UI callbacks or future features must not
	# be able to persist unsupported values that break settings consumers.
	if not values.has(key):
		push_warning("Ignoring unknown setting: %s" % key)
		return false
	if not _is_valid_setting(key, value):
		push_warning("Ignoring invalid value for setting: %s" % key)
		return false
	if values[key] == value:
		return true
	var previous_value: Variant = values[key]
	values[key] = value
	if not save_settings():
		values[key] = previous_value
		return false
	return true

func apply_display_settings() -> void:
	var mode: String = str(values.get("display_mode", "Fenêtré"))
	match mode:
		"Fenêtré":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		"Plein écran sans bordures":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"Plein écran exclusif":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	var resolution: Vector2i = values.get("resolution", Vector2i(1280, 720))
	if mode == "Fenêtré":
		DisplayServer.window_set_size(resolution)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if bool(values.get("vsync", true))
		else DisplayServer.VSYNC_DISABLED
	)

	var fps_limit := int(values.get("fps_limit", 0))
	Engine.max_fps = fps_limit if fps_limit > 0 else 0

func apply_audio_settings() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, get_volume_db("master_volume"))
		AudioServer.set_bus_mute(master_bus, float(values.get("master_volume", 0.8)) <= 0.0)

func get_volume_db(key: String) -> float:
	var linear_value := clampf(float(values.get(key, 0.8)), 0.0, 1.0)
	return linear_to_db(linear_value) if linear_value > 0.0 else -80.0
