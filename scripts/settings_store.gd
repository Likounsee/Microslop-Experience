extends Node
## Centralized settings storage for Microslop Experience.

const SETTINGS_PATH := "user://settings.cfg"

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
	var error := config.load(SETTINGS_PATH)
	if error != OK:
		return
	for key in values.keys():
		var candidate: Variant = config.get_value("settings", key, values[key])
		if _is_valid_setting(key, candidate):
			values[key] = candidate

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

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in values.keys():
		config.set_value("settings", key, values[key])
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Unable to save settings: %s" % error)

func set_value_and_save(key: String, value: Variant) -> void:
	# Validate writes as well as reads: UI callbacks or future features must not
	# be able to persist unsupported values that break settings consumers.
	if not values.has(key):
		push_warning("Ignoring unknown setting: %s" % key)
		return
	if not _is_valid_setting(key, value):
		push_warning("Ignoring invalid value for setting: %s" % key)
		return
	if values[key] == value:
		return
	values[key] = value
	save_settings()

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
