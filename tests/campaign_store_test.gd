extends SceneTree

const CampaignStoreScript = preload("res://scripts/campaign_store.gd")
const TEST_SAVE_PATH := "user://campaign_store_test.cfg"

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
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)

	var store = CampaignStoreScript.new()
	store.save_path = TEST_SAVE_PATH
	root.add_child(store)

	_check(store.save_progress(4), "save progress")
	_check(store.load_progress() == 4, "load saved progress")
	_check(store.save_case_answer("case_test", 2), "save valid case answer")
	_check(store.load_case_answer("case_test") == 2, "load valid case answer")
	_check(store.load_case_answer("") == -1, "reject empty case ID when loading")
	_check(not store.save_case_answer("", 1), "reject empty case ID when saving")
	_check(not store.save_case_answer("case_invalid", 3), "reject out-of-range answer")
	_check(store.save_evidence("evidence_test"), "save evidence")
	_check(store.load_evidence().has("evidence_test"), "load evidence")

	_check(store.save_report_review("A factual report with limits and actions.", 2), "save accepted report review")
	_check(store.load_report_draft() == "A factual report with limits and actions.", "load report draft")
	var config := ConfigFile.new()
	_check(config.load(TEST_SAVE_PATH) == OK, "read test save")
	if config.load(TEST_SAVE_PATH) == OK:
		var evidence: Array = config.get_value("campaign", "evidence", [])
		_check(evidence.has("report_studio_reviewed"), "accepted review marker exists")
		_check(not evidence.has("report_studio_revision_requested"), "opposite review marker removed")

	# A wrong-typed evidence field is normalized before a new evidence ID is written.
	config.set_value("campaign", "evidence", "not-an-array")
	_check(config.save(TEST_SAVE_PATH) == OK, "seed malformed evidence field")
	_check(store.save_evidence("evidence_after_malformed"), "save evidence after malformed field")
	var normalized := store.load_evidence()
	_check(normalized.size() == 1 and normalized[0] == "evidence_after_malformed", "normalize malformed evidence")

	# An unreadable existing file must not be overwritten by a save attempt.
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string("this is not a ConfigFile")
		file.close()
	_check(not store.save_progress(1), "refuse to overwrite unreadable save")
	var verify := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	var saved_text := verify.get_as_text() if verify != null else ""
	if verify != null:
		verify.close()
	_check(saved_text == "this is not a ConfigFile", "preserve unreadable save contents")

	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
	store.queue_free()
	if failures.is_empty():
		print("CampaignStore tests passed.")
		quit(0)
	else:
		push_error("%d CampaignStore test(s) failed: %s" % [failures.size(), ", ".join(failures)])
		quit(1)
