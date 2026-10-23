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
	_check(store.save_progress(99), "save progress above maximum")
	_check(store.load_progress() == 5, "clamp progress to maximum")
	_check(store.save_progress(4), "restore normal progress for remaining tests")
	_check(store.save_case_answer("case_test", 2), "save valid case answer")
	_check(store.load_case_answer("case_test") == 2, "load valid case answer")
	var malformed_answers := ConfigFile.new()
	_check(malformed_answers.load(TEST_SAVE_PATH) == OK, "load save before malformed answers fixture")
	malformed_answers.set_value("campaign", "case_answers", "not-a-dictionary")
	_check(malformed_answers.save(TEST_SAVE_PATH) == OK, "seed malformed case answers")
	_check(store.save_case_answer("case_after_malformed", 1), "save answer after malformed answer collection")
	_check(store.load_case_answer("case_after_malformed") == 1, "load answer after malformed answer collection")
	_check(store.load_case_answer("") == -1, "reject empty case ID when loading")
	_check(not store.save_case_answer("", 1), "reject empty case ID when saving")
	_check(store.save_case_answer("case_stage", 12), "save multi-step campaign stage")
	_check(store.load_case_answer("case_stage") == 12, "load multi-step campaign stage")
	_check(store.save_case_answer("case_negative_score", -24), "save negative campaign score")
	_check(store.load_case_answer("case_negative_score") == -24, "load negative campaign score")
	_check(store.save_case_answer("case_reset_sentinel", -1), "save reset sentinel")
	_check(store.load_case_answer("case_reset_sentinel") == -1, "load reset sentinel")
	_check(not store.save_case_answer("case_invalid", 1001), "reject answer above supported bound")
	_check(not store.save_case_answer("case_invalid_low", -1001), "reject answer below supported bound")
	_check(store.save_case_answers_with_evidence({"atomic_choice": 2, "atomic_score": -3}, "atomic_choice_evidence"), "save answers and evidence atomically")
	_check(store.load_case_answer("atomic_choice") == 2, "load atomically saved choice")
	_check(store.load_case_answer("atomic_score") == -3, "load atomically saved score")
	_check(store.load_evidence().has("atomic_choice_evidence"), "load evidence from atomic decision")
	_check(not store.save_case_answers_with_evidence({}, "invalid_atomic_evidence"), "reject empty atomic answer batch")
	_check(not store.save_case_answers_with_evidence({"atomic_invalid": 1001}, "invalid_atomic_evidence"), "reject out-of-range atomic answer")
	_check(store.save_evidence("evidence_test"), "save evidence")
	_check(store.load_evidence().has("evidence_test"), "load evidence")
	_check(store.save_ending("published"), "save valid published ending")
	_check(store.load_ending() == "published", "load published ending")
	_check(not store.save_ending("unknown"), "reject unknown ending")
	_check(store.load_ending() == "published", "invalid ending does not replace saved ending")
	_check(store.save_ending("preserved"), "replace ending with preserved outcome")
	_check(store.load_ending() == "preserved", "load updated ending")

	_check(store.save_report_review("A factual report with limits and actions.", 2), "save accepted report review")
	_check(not store.save_report_review("Invalid outcome must not replace this report.", 3), "reject invalid report review outcome")
	_check(store.load_report_draft() == "A factual report with limits and actions.", "invalid review leaves saved report unchanged")
	_check(store.load_report_draft() == "A factual report with limits and actions.", "load report draft")
	var config := ConfigFile.new()
	_check(config.load(TEST_SAVE_PATH) == OK, "read test save")
	if config.load(TEST_SAVE_PATH) == OK:
		var evidence: Array = config.get_value("campaign", "evidence", [])
		_check(evidence.has("report_studio_reviewed"), "accepted review marker exists")
		_check(not evidence.has("report_studio_revision_requested"), "opposite review marker removed")
		_check(evidence.has("evidence_test"), "report review preserves unrelated evidence")

	_check(store.save_report_review("Report to revise.", 1), "save revised report review after acceptance")
	_check(config.load(TEST_SAVE_PATH) == OK, "reload revised report review")
	if config.load(TEST_SAVE_PATH) == OK:
		var revised_evidence: Array = config.get_value("campaign", "evidence", [])
		_check(revised_evidence.has("report_studio_revision_requested"), "revision marker replaces acceptance")
		_check(not revised_evidence.has("report_studio_reviewed"), "stale acceptance marker removed")
		_check(revised_evidence.has("evidence_test"), "revision review preserves unrelated evidence")

	# A wrong-typed evidence field is normalized before a new evidence ID is written.
	config.set_value("campaign", "evidence", "not-an-array")
	_check(config.save(TEST_SAVE_PATH) == OK, "seed malformed evidence field")
	_check(store.save_evidence("evidence_after_malformed"), "save evidence after malformed field")
	var normalized := store.load_evidence()
	_check(normalized.size() == 1 and normalized[0] == "evidence_after_malformed", "normalize malformed evidence")

	# Replaying the cinematic must clear its own state while preserving the wider case file.
	_check(store.save_report_draft("Keep this unrelated report draft."), "seed report draft before cinematic reset")
	var reset_fixture := ConfigFile.new()
	_check(reset_fixture.load(TEST_SAVE_PATH) == OK, "load save before cinematic reset fixture")
	reset_fixture.set_value("campaign", "evidence", ["evidence_to_keep", "cinematic_scene_02", "cinematic_choice_evidence_02", "orchid_cinematic_shared", "cinematic_outcome_calculated"])
	# Real gameplay stores these decisions in case_answers, not as top-level keys.
	reset_fixture.set_value("campaign", "case_answers", {
		"case_test": 2,
		"cinematic_choice_02": 1,
		"cinematic_choice_38": 2,
		"cinematic_outcome_score": 17,
		"orchid_lea_support_status": 1,
		"orchid_report_quality": 1,
		"orchid_sample_protocol": 1,
		"orchid_release_guardrail": 1,
		"orchid_results_claim": 0,
		"orchid_final_prompt_choice": 0,
		"orchid_cinematic_focus_pause": 1
	})
	reset_fixture.set_value("campaign", "cinematic_choice_02", 1)
	reset_fixture.set_value("campaign", "cinematic_choice_38", 2)
	reset_fixture.set_value("campaign", "cinematic_outcome_score", 17)
	reset_fixture.set_value("campaign", "quick_settings_mode", "digest")
	reset_fixture.set_value("campaign", "cinematic_baseline", {
		"quick_settings_mode": {"exists": true, "value": "normal"},
		"cinematic_only_temporary_flag": {"exists": false, "value": null}
	})
	_check(reset_fixture.save(TEST_SAVE_PATH) == OK, "seed cinematic reset fixture")
	_check(store.reset_cinematic_progress(), "reset cinematic progress")
	var reset_result := ConfigFile.new()
	_check(reset_result.load(TEST_SAVE_PATH) == OK, "reload save after cinematic reset")
	if reset_result.load(TEST_SAVE_PATH) == OK:
		var reset_evidence: Array = reset_result.get_value("campaign", "evidence", [])
		_check(reset_evidence.has("evidence_to_keep"), "cinematic reset preserves unrelated evidence")
		_check(not reset_evidence.has("cinematic_scene_02"), "cinematic reset removes scene evidence")
		_check(not reset_evidence.has("cinematic_choice_evidence_02"), "cinematic reset removes choice evidence")
		_check(not reset_evidence.has("orchid_cinematic_shared"), "cinematic reset removes namespaced cinematic evidence")
		_check(not reset_evidence.has("cinematic_outcome_calculated"), "cinematic reset removes calculated outcome evidence")
		_check(not reset_result.has_section_key("campaign", "cinematic_choice_02"), "cinematic reset clears early choice")
		_check(not reset_result.has_section_key("campaign", "cinematic_choice_38"), "cinematic reset clears epilogue choice")
		_check(not reset_result.has_section_key("campaign", "cinematic_outcome_score"), "cinematic reset clears outcome score")
		var reset_answers: Dictionary = reset_result.get_value("campaign", "case_answers", {})
		_check(not reset_answers.has("cinematic_choice_02"), "cinematic reset clears persisted early answer")
		_check(not reset_answers.has("cinematic_choice_38"), "cinematic reset clears persisted epilogue answer")
		_check(not reset_answers.has("cinematic_outcome_score"), "cinematic reset clears persisted outcome score")
		_check(not reset_answers.has("orchid_lea_support_status"), "cinematic reset clears derived testimony status")
		_check(not reset_answers.has("orchid_report_quality"), "cinematic reset clears derived report status")
		_check(not reset_answers.has("orchid_sample_protocol"), "cinematic reset clears derived sampling status")
		_check(not reset_answers.has("orchid_release_guardrail"), "cinematic reset clears derived release guardrail")
		_check(not reset_answers.has("orchid_results_claim"), "cinematic reset clears derived results claim")
		_check(not reset_answers.has("orchid_final_prompt_choice"), "cinematic reset clears final prompt choice")
		_check(not reset_answers.has("orchid_cinematic_focus_pause"), "cinematic reset clears cinematic focus pause choice")
		_check(reset_answers.get("case_test", -1) == 2, "cinematic reset preserves unrelated case answer")
		_check(reset_result.get_value("campaign", "quick_settings_mode", "") == "normal", "cinematic reset restores pre-cinematic shared setting")
		_check(not reset_result.has_section_key("campaign", "cinematic_only_temporary_flag"), "cinematic reset removes keys created by cinematic")
		_check(not reset_result.has_section_key("campaign", "cinematic_baseline"), "cinematic reset clears baseline snapshot")
		_check(reset_result.get_value("campaign", "report_draft", "") == "Keep this unrelated report draft.", "cinematic reset preserves report draft")
		_check(reset_result.get_value("campaign", "ending", "") == "preserved", "cinematic reset preserves campaign ending")
		_check(reset_result.get_value("campaign", "mission_step", -1) == 4, "cinematic reset preserves mission progress")

	# A directory at the save path simulates a location ConfigFile cannot read or overwrite.
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
	var directory_error := DirAccess.make_dir_absolute(absolute_path)
	_check(directory_error == OK, "create unreadable save location")
	var previous_step: int = store.mission_step
	_check(not store.save_case_answers_with_evidence({"failed_atomic_choice": 1}, "failed_atomic_evidence"), "refuse atomic decision when save location is unreadable")
	_check(store.load_case_answer("failed_atomic_choice") == -1, "failed atomic decision does not persist its answer")
	_check(not store.load_evidence().has("failed_atomic_evidence"), "failed atomic decision does not persist evidence")
	_check(not store.save_progress(1), "refuse to overwrite unreadable save location")
	_check(store.mission_step == previous_step, "failed save does not change in-memory progress")
	_check(DirAccess.dir_exists_absolute(absolute_path), "preserve unreadable save location")
	if DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.remove_absolute(absolute_path)
	store.queue_free()
	if failures.is_empty():
		print("CampaignStore tests passed.")
		quit(0)
	else:
		push_error("%d CampaignStore test(s) failed: %s" % [failures.size(), str(failures)])
		quit(1)
