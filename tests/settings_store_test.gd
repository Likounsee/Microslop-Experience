extends SceneTree

const SettingsStoreScript = preload("res://scripts/settings_store.gd")
const TEST_SETTINGS_PATH := "user://settings_store_test.cfg"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run_tests")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _run_tests() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	for path in [absolute_path, absolute_path + ".tmp", absolute_path + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	var store = SettingsStoreScript.new()
	store.settings_path = TEST_SETTINGS_PATH
	root.add_child(store)
	_check(store.save_settings(), "save initial settings atomically")
	_check(FileAccess.file_exists(absolute_path), "atomic settings save creates primary file")
	_check(not FileAccess.file_exists(absolute_path + ".tmp"), "successful save removes temporary file")
	_check(not FileAccess.file_exists(absolute_path + ".bak"), "successful save removes backup file")

	store.set_value_and_save("fps_limit", 120)
	_check(store.values["fps_limit"] == 120, "valid setting update is retained after save")
	var reloaded = SettingsStoreScript.new()
	reloaded.settings_path = TEST_SETTINGS_PATH
	root.add_child(reloaded)
	_check(reloaded.values["fps_limit"] == 120, "fresh store loads persisted setting")
	reloaded.set_value_and_save("fps_limit", 121)
	_check(reloaded.values["fps_limit"] == 120, "invalid setting is rejected without changing value")
	_check(reloaded.save_settings(), "replace an existing settings file")
	_check(not FileAccess.file_exists(absolute_path + ".bak"), "replacement cleans backup after success")

	# A directory at the destination forces the final rename to fail. The in-memory
	# value must roll back instead of claiming a setting was saved.
	var blocked_path := TEST_SETTINGS_PATH + "_blocked"
	var blocked_absolute := ProjectSettings.globalize_path(blocked_path)
	if DirAccess.dir_exists_absolute(blocked_absolute):
		DirAccess.remove_absolute(blocked_absolute)
	_check(DirAccess.make_dir_absolute(blocked_absolute) == OK, "create blocked settings destination")
	var blocked_store = SettingsStoreScript.new()
	blocked_store.settings_path = blocked_path
	root.add_child(blocked_store)
	var original_limit: int = blocked_store.values["fps_limit"]
	blocked_store.set_value_and_save("fps_limit", 60)
	_check(blocked_store.values["fps_limit"] == original_limit, "failed disk write rolls back in-memory setting")
	_check(not FileAccess.file_exists(blocked_absolute + ".tmp"), "failed replacement cleans temporary settings file")
	_check(DirAccess.dir_exists_absolute(blocked_absolute), "failed replacement preserves destination directory")

	for path in [absolute_path, absolute_path + ".tmp", absolute_path + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(blocked_absolute):
		DirAccess.remove_absolute(blocked_absolute)
	store.queue_free()
	reloaded.queue_free()
	blocked_store.queue_free()
	if failures.is_empty():
		print("SettingsStore tests passed.")
		quit(0)
	else:
		push_error("%d SettingsStore test(s) failed: %s" % [failures.size(), str(failures)])
		quit(1)
