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

	_check(store.save_progress(4), "save progress through verified atomic replacement")
	_check(store.load_progress() == 4, "load saved progress after atomic replacement")
	var absolute_save_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	_check(FileAccess.file_exists(absolute_save_path), "atomic save creates the target file")
	_check(not FileAccess.file_exists(absolute_save_path + ".tmp"), "atomic save cleans temporary file after success")
	_check(not FileAccess.file_exists(absolute_save_path + ".bak"), "atomic save cleans backup after success")
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
	_check(store.save_case_answers_with_evidence({
		"orchid_workflow_stage": 7,
		"orchid_workflow_score": -4,
		"orchid_crisis_stage": 3
	}, "snapshot_fixture"), "seed grouped resume snapshot")
	var resume_snapshot := store.load_case_answers([
		"orchid_workflow_stage", "orchid_workflow_score", "orchid_crisis_stage", "missing_snapshot_key"
	])
	_check(resume_snapshot["orchid_workflow_stage"] == 7, "batch loader restores saved stage")
	_check(resume_snapshot["orchid_workflow_score"] == -4, "batch loader restores saved score")
	_check(resume_snapshot["orchid_crisis_stage"] == 3, "batch loader restores another journey from same snapshot")
	_check(resume_snapshot["missing_snapshot_key"] == -1, "batch loader uses missing-answer sentinel")
	_check(store.load_case_answers([]).is_empty(), "batch loader handles empty request")
	var snapshot_fixture := ConfigFile.new()
	_check(snapshot_fixture.load(TEST_SAVE_PATH) == OK, "load save to seed malformed snapshot values")
	if snapshot_fixture.load(TEST_SAVE_PATH) == OK:
		var snapshot_answers: Dictionary = snapshot_fixture.get_value("campaign", "case_answers", {})
		snapshot_answers["bad_type_snapshot"] = "12"
		snapshot_answers["bad_range_snapshot"] = 1001
		snapshot_fixture.set_value("campaign", "case_answers", snapshot_answers)
		_check(snapshot_fixture.save(TEST_SAVE_PATH) == OK, "save malformed snapshot fixtures")
	var malformed_snapshot := store.load_case_answers(["bad_type_snapshot", "bad_range_snapshot"])
	_check(malformed_snapshot["bad_type_snapshot"] == -1, "batch loader rejects wrong-typed saved answer")
	_check(malformed_snapshot["bad_range_snapshot"] == -1, "batch loader rejects out-of-range saved answer")
	# Simulate closing and reopening the application: a fresh store must recover the whole committed decision.
	var resumed_store = CampaignStoreScript.new()
	resumed_store.save_path = TEST_SAVE_PATH
	root.add_child(resumed_store)
	_check(resumed_store.load_case_answer("atomic_choice") == 2, "resume recovers atomic choice in a fresh store")
	_check(resumed_store.load_case_answer("atomic_score") == -3, "resume recovers atomic score in a fresh store")
	_check(resumed_store.load_evidence().has("atomic_choice_evidence"), "resume recovers matching evidence in a fresh store")
	resumed_store.queue_free()
	_check(not store.save_case_answers_with_evidence({}, "invalid_atomic_evidence"), "reject empty atomic answer batch")
	_check(not store.save_case_answers_with_evidence({"atomic_invalid": 1001}, "invalid_atomic_evidence"), "reject out-of-range atomic answer")

	# Reset a complete mini-game atomically, removing stale evidence while keeping other case files.
	_check(store.save_case_answers_with_evidence({"orchid_sprint_stage": 13, "orchid_sprint_score": 18, "orchid_sprint_choice_00": 2}, "orchid_sprint_stage_00"), "seed completed sprint before atomic reset")
	_check(store.save_evidence("unrelated_case_evidence"), "seed unrelated evidence before atomic reset")
	_check(store.reset_case_progress({
		"orchid_sprint_stage": 0,
		"orchid_sprint_score": 0,
		"orchid_sprint_interruptions": 0,
		"orchid_sprint_choice_00": -1
	}, ["orchid_sprint_stage_", "orchid_sprint_choice_", "sprint_"]), "reset mini-game answers and evidence atomically")
	_check(store.load_case_answer("orchid_sprint_stage") == 0, "atomic reset restores stage zero")
	_check(store.load_case_answer("orchid_sprint_score") == 0, "atomic reset clears mini-game score")
	_check(store.load_case_answer("orchid_sprint_choice_00") == -1, "atomic reset clears previous choice")
	_check(not store.load_evidence().has("orchid_sprint_stage_00"), "atomic reset removes stale stage evidence")
	_check(not store.load_evidence().has("sprint_digest_policy_applied"), "atomic reset removes related effect evidence")
	_check(store.load_evidence().has("unrelated_case_evidence"), "atomic reset preserves unrelated evidence")
	_check(store.load_case_answer("atomic_choice") == 2, "atomic reset preserves unrelated case answers")
	_check(not store.reset_case_progress({}, ["orchid_sprint_"]), "reject empty mini-game reset batch")
	_check(not store.reset_case_progress({"bad_reset": 1001}, []), "reject out-of-range mini-game reset value")
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

	# Reset is safe to retry after reopening; it must not damage unrelated campaign state.
	_check(store.reset_cinematic_progress(), "cinematic reset is idempotent on retry")
	var retry_result := ConfigFile.new()
	_check(retry_result.load(TEST_SAVE_PATH) == OK, "reload save after reset retry")
	if retry_result.load(TEST_SAVE_PATH) == OK:
		_check(retry_result.get_value("campaign", "mission_step", -1) == 4, "reset retry preserves mission progress")
		_check(retry_result.get_value("campaign", "report_draft", "") == "Keep this unrelated report draft.", "reset retry preserves report draft")
		_check(retry_result.get_value("campaign", "quick_settings_mode", "") == "normal", "reset retry preserves restored setting")

	# Simulate a crash after the previous save was moved to the backup but before replacement.
	_check(store.save_case_answer("backup_recovery_fixture", 42), "seed save before interrupted replacement recovery")
	var backup_path := absolute_path + ".bak"
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	_check(DirAccess.rename_absolute(absolute_path, backup_path) == OK, "simulate interrupted replacement with backup only")
	_check(store.load_case_answer("backup_recovery_fixture") == 42, "recover saved answer from backup after interrupted replacement")
	_check(FileAccess.file_exists(absolute_path), "backup recovery restores primary save file")
	_check(not FileAccess.file_exists(backup_path), "backup recovery consumes restored backup")

	# A syntactically corrupted primary must not hide a valid backup.
	_check(DirAccess.copy_absolute(absolute_path, backup_path) == OK, "copy valid save into backup before corruption test")
	var corrupt_primary := FileAccess.open(absolute_path, FileAccess.WRITE)
	if corrupt_primary != null:
		corrupt_primary.store_string("[campaign\nmission_step = broken")
		corrupt_primary.close()
	_check(store.load_case_answer("backup_recovery_fixture") == 42, "recover valid backup when primary save is malformed")
	_check(FileAccess.file_exists(absolute_path), "malformed primary is replaced by recovered valid save")
	_check(not FileAccess.file_exists(backup_path), "corrupt-primary recovery cleans restored backup")

	# A stale corrupt backup must not block saving when the primary is still valid.
	var corrupt_backup := FileAccess.open(backup_path, FileAccess.WRITE)
	if corrupt_backup != null:
		corrupt_backup.store_string("[campaign\nmission_step = broken")
		corrupt_backup.close()
	_check(store.save_case_answer("save_with_corrupt_backup", 73), "replace corrupt stale backup when primary save is valid")
	_check(store.load_case_answer("backup_recovery_fixture") == 42, "keep existing data while replacing corrupt stale backup")
	_check(store.load_case_answer("save_with_corrupt_backup") == 73, "load new answer after corrupt backup cleanup")
	_check(not FileAccess.file_exists(backup_path), "successful save removes stale corrupt backup")
	_check(not FileAccess.file_exists(absolute_path + ".tmp"), "successful save cleans temporary file after corrupt backup cleanup")

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
	_check(not store.reset_cinematic_progress(), "refuse cinematic reset when save location is unreadable")
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
