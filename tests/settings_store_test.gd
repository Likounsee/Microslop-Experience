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

	# Direct mutations must not bypass validation at the persistence boundary.
	store.values["fps_limit"] = 121
	_check(not store.save_settings(), "reject invalid in-memory values before writing")
	var persisted_after_rejection := ConfigFile.new()
	_check(persisted_after_rejection.load(TEST_SETTINGS_PATH) == OK, "invalid save leaves previous settings readable")
	_check(persisted_after_rejection.get_value("settings", "fps_limit", -1) == 0, "invalid save preserves previously persisted value")
	store.values["fps_limit"] = 0
	store.values["unexpected_setting"] = true
	_check(not store.save_settings(), "reject unknown in-memory setting keys before writing")
	store.values.erase("unexpected_setting")
	var readable_after_unknown_key := ConfigFile.new()
	_check(readable_after_unknown_key.load(TEST_SETTINGS_PATH) == OK, "unknown setting rejection preserves readable save")

	_check(store.set_value_and_save("fps_limit", 120), "valid setting update reports successful persistence")
	_check(store.set_value_and_save("fps_limit", 120), "unchanged valid setting reports success")
	_check(not store.set_value_and_save("unknown_setting", 1), "unknown setting reports persistence failure")
	_check(store.values["fps_limit"] == 120, "valid setting update is retained after save")
	var reloaded = SettingsStoreScript.new()
	reloaded.settings_path = TEST_SETTINGS_PATH
	root.add_child(reloaded)
	_check(reloaded.values["fps_limit"] == 120, "fresh store loads persisted setting")
	_check(not reloaded.set_value_and_save("fps_limit", 121), "invalid setting reports persistence failure")
	_check(reloaded.values["fps_limit"] == 120, "invalid setting is rejected without changing value")
	_check(reloaded.save_settings(), "replace an existing settings file")
	_check(not FileAccess.file_exists(absolute_path + ".bak"), "replacement cleans backup after success")

	# Simulate a crash after the old file was moved to .bak but before the
	# replacement reached the primary path.
	var saved_settings_text := FileAccess.get_file_as_string(absolute_path)
	var backup_file := FileAccess.open(absolute_path + ".bak", FileAccess.WRITE)
	_check(backup_file != null, "create interrupted-save backup fixture")
	if backup_file != null:
		backup_file.store_string(saved_settings_text)
		backup_file.close()
	var malformed_primary := FileAccess.open(absolute_path, FileAccess.WRITE)
	_check(malformed_primary != null, "create malformed primary settings fixture")
	if malformed_primary != null:
		malformed_primary.store_string("[settings\nvsync = broken")
		malformed_primary.close()
	var recovery_store = SettingsStoreScript.new()
	recovery_store.settings_path = TEST_SETTINGS_PATH
	root.add_child(recovery_store)
	_check(recovery_store.values["fps_limit"] == 120, "recover settings values from verified backup")
	_check(FileAccess.file_exists(absolute_path), "restore recovered settings to primary path")
	_check(not FileAccess.file_exists(absolute_path + ".bak"), "consume backup after successful recovery")

	# If neither copy parses, preserve both for later diagnosis and use defaults.
	var malformed_primary_text := "[settings\nprimary = broken"
	var malformed_backup_text := "[settings\nbackup = broken"
	var damaged_primary_file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if damaged_primary_file != null:
		damaged_primary_file.store_string(malformed_primary_text)
		damaged_primary_file.close()
	var damaged_backup_file := FileAccess.open(absolute_path + ".bak", FileAccess.WRITE)
	if damaged_backup_file != null:
		damaged_backup_file.store_string(malformed_backup_text)
		damaged_backup_file.close()
	var damaged_store = SettingsStoreScript.new()
	damaged_store.settings_path = TEST_SETTINGS_PATH
	root.add_child(damaged_store)
	_check(damaged_store.values["fps_limit"] == 0, "use defaults when both settings copies are malformed")
	_check(FileAccess.get_file_as_string(absolute_path) == malformed_primary_text, "preserve malformed primary settings for diagnosis")
	_check(FileAccess.get_file_as_string(absolute_path + ".bak") == malformed_backup_text, "preserve malformed backup settings for diagnosis")
	var restore_fixture := FileAccess.open(absolute_path, FileAccess.WRITE)
	if restore_fixture != null:
		restore_fixture.store_string(saved_settings_text)
		restore_fixture.close()
	if FileAccess.file_exists(absolute_path + ".bak"):
		DirAccess.remove_absolute(absolute_path + ".bak")

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
	_check(not blocked_store.set_value_and_save("fps_limit", 60), "failed disk write reports persistence failure")
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
	recovery_store.queue_free()
	damaged_store.queue_free()
	blocked_store.queue_free()
	if failures.is_empty():
		print("SettingsStore tests passed.")
		quit(0)
	else:
		push_error("%d SettingsStore test(s) failed: %s" % [failures.size(), str(failures)])
		quit(1)
