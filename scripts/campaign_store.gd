extends Node
## Owns campaign persistence so UI code does not manage save-file details.

const SAVE_PATH := "user://campaign.cfg"
## Can be overridden by isolated tests without touching the player save.
var save_path: String = SAVE_PATH
const MIN_MISSION_STEP := 0
const MAX_MISSION_STEP := 5
const CAMPAIGN_VERSION := 2
const MIN_CASE_ANSWER := -1000
const MAX_CASE_ANSWER := 1000

var mission_step: int = MIN_MISSION_STEP

## Returns only unique, non-empty evidence IDs from potentially malformed save data.
func _normalized_evidence(raw: Variant) -> Array:
	var evidence: Array = []
	if not (raw is Array):
		return evidence
	for item in raw:
		if item is String and not item.strip_edges().is_empty() and not evidence.has(item):
			evidence.append(item)
	return evidence

func load_progress() -> int:
	var config := ConfigFile.new()
	var error := config.load(save_path)
	if error != OK:
		mission_step = MIN_MISSION_STEP
		return mission_step

	var saved_value: Variant = config.get_value("campaign", "mission_step", MIN_MISSION_STEP)
	var raw_version: Variant = config.get_value("campaign", "version", 1)
	var saved_version: int = raw_version if typeof(raw_version) == TYPE_INT else 1
	if typeof(saved_value) != TYPE_INT:
		mission_step = MIN_MISSION_STEP
	else:
		mission_step = clampi(saved_value, MIN_MISSION_STEP, MAX_MISSION_STEP)
		# The previous tutorial ended at step 3. Reopen the update clue so returning players can reach the new story chapter.
		if saved_version < CAMPAIGN_VERSION and mission_step >= 3:
			mission_step = 2
	return mission_step

func save_progress(step: int) -> bool:
	var next_step := clampi(step, MIN_MISSION_STEP, MAX_MISSION_STEP)
	var config := ConfigFile.new()
	# Refuse to overwrite an unreadable save; a missing save is valid for a new campaign.
	var load_error := config.load(save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant d'enregistrer la progression.")
		return false
	config.set_value("campaign", "mission_step", next_step)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(save_path)
	if error != OK:
		push_warning("Impossible d'enregistrer la progression de campagne : %s" % error)
		return false
	mission_step = next_step
	return true


## Stores the player's chapter-ending decision without invalidating older campaign saves.
func save_ending(ending: String) -> bool:
	if ending not in ["published", "preserved"]:
		return false
	var config := ConfigFile.new()
	var load_error := config.load(save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant d'enregistrer la conclusion ORCHID.")
		return false
	config.set_value("campaign", "ending", ending)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var save_error := config.save(save_path)
	if save_error != OK:
		push_warning("Impossible d'enregistrer la conclusion ORCHID : %s" % save_error)
		return false
	return true

## Persists optional ORCHID evidence IDs without disturbing mission progress or ending.
func save_evidence(evidence_id: String) -> bool:
	if evidence_id.strip_edges().is_empty():
		return false
	var config := ConfigFile.new()
	var load_error := config.load(save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant d'enregistrer les indices ORCHID.")
		return false
	var raw: Variant = config.get_value("campaign", "evidence", [])
	var evidence := _normalized_evidence(raw)
	if not evidence.has(evidence_id):
		evidence.append(evidence_id)
	config.set_value("campaign", "evidence", evidence)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(save_path)
	if error != OK:
		push_warning("Impossible d'enregistrer les indices ORCHID : %s" % error)
		return false
	return true


func load_evidence() -> Array:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return []
	var raw: Variant = config.get_value("campaign", "evidence", [])
	return _normalized_evidence(raw)


## Saves the latest answer for a named ORCHID evidence puzzle.
func save_case_answer(case_id: String, answer: int) -> bool:
	if case_id.strip_edges().is_empty() or answer < MIN_CASE_ANSWER or answer > MAX_CASE_ANSWER:
		return false
	var config := ConfigFile.new()
	var load_error := config.load(save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant d'enregistrer la réponse ORCHID.")
		return false
	var raw_answers: Variant = config.get_value("campaign", "case_answers", {})
	var answers: Dictionary = raw_answers if raw_answers is Dictionary else {}
	answers[case_id] = answer
	config.set_value("campaign", "case_answers", answers)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(save_path)
	if error != OK:
		push_warning("Impossible d'enregistrer la réponse ORCHID : %s" % error)
		return false
	return true


## Commits related case answers and their evidence marker in one save-file write.
## Prevents a choice from appearing recorded when its supporting evidence failed to persist.
func save_case_answers_with_evidence(answers_to_save: Dictionary, evidence_id: String) -> bool:
	if answers_to_save.is_empty() or evidence_id.strip_edges().is_empty():
		return false
	for case_id in answers_to_save:
		var answer: Variant = answers_to_save[case_id]
		if not (case_id is String) or case_id.strip_edges().is_empty():
			return false
		if typeof(answer) != TYPE_INT or answer < MIN_CASE_ANSWER or answer > MAX_CASE_ANSWER:
			return false
	var config := ConfigFile.new()
	var load_error := config.load(save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant d'enregistrer la décision ORCHID.")
		return false
	var raw_answers: Variant = config.get_value("campaign", "case_answers", {})
	var persisted_answers: Dictionary = raw_answers if raw_answers is Dictionary else {}
	for case_id in answers_to_save:
		persisted_answers[case_id] = answers_to_save[case_id]
	config.set_value("campaign", "case_answers", persisted_answers)
	var evidence := _normalized_evidence(config.get_value("campaign", "evidence", []))
	if not evidence.has(evidence_id):
		evidence.append(evidence_id)
	config.set_value("campaign", "evidence", evidence)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var save_error := config.save(save_path)
	if save_error != OK:
		push_warning("Impossible d'enregistrer la décision ORCHID et sa preuve : %s" % save_error)
		return false
	return true


func load_case_answer(case_id: String) -> int:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return -1
	if case_id.strip_edges().is_empty():
		return -1
	var raw: Variant = config.get_value("campaign", "case_answers", {})
	if not (raw is Dictionary):
		return -1
	var answer: Variant = raw.get(case_id, -1)
	if typeof(answer) != TYPE_INT or answer < MIN_CASE_ANSWER or answer > MAX_CASE_ANSWER:
		return -1
	return answer


## Stores an editable report draft independently of the campaign ending and progress.
func save_report_draft(draft: String) -> bool:
	var config := ConfigFile.new()
	var load_error := config.load(save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant d'enregistrer le brouillon ORCHID.")
		return false
	config.set_value("campaign", "report_draft", draft)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(save_path)
	if error != OK:
		push_warning("Impossible d’enregistrer le brouillon ORCHID : %s" % error)
		return false
	return true



## Commits the report text, review outcome and matching evidence in one config write.
## This avoids reporting a completed review when only part of the state was saved.
func save_report_review(draft: String, outcome: int) -> bool:
	if outcome < 0 or outcome > 2:
		return false
	var config := ConfigFile.new()
	var load_error := config.load(save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant la revue ORCHID.")
		return false
	config.set_value("campaign", "report_draft", draft)
	var raw_answers: Variant = config.get_value("campaign", "case_answers", {})
	var answers: Dictionary = raw_answers if raw_answers is Dictionary else {}
	answers["report_studio_reviewed"] = outcome
	config.set_value("campaign", "case_answers", answers)
	var raw_evidence: Variant = config.get_value("campaign", "evidence", [])
	var evidence := _normalized_evidence(raw_evidence)
	var evidence_id := "report_studio_reviewed" if outcome == 2 else "report_studio_revision_requested"
	# Rebuild the two mutually exclusive review markers to remove stale or duplicate entries.
	evidence.erase("report_studio_reviewed")
	evidence.erase("report_studio_revision_requested")
	evidence.append(evidence_id)
	config.set_value("campaign", "evidence", evidence)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(save_path)
	if error != OK:
		push_warning("Impossible d'enregistrer la revue complète du rapport ORCHID : %s" % error)
		return false
	return true


func load_report_draft() -> String:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return ""
	var raw_draft: Variant = config.get_value("campaign", "report_draft", "")
	return raw_draft if raw_draft is String else ""


## Restarts only the cinematic thread, leaving the wider ORCHID case file intact.
## Scene markers and choice keys are cleared together so resume cannot jump to the ending.
## Capture a pre-cinematic value once so replay can restore settings owned by other gameplay paths.
func capture_cinematic_baseline(case_id: String) -> bool:
	if case_id.strip_edges().is_empty():
		return false
	var config := ConfigFile.new()
	var load_error := config.load(save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return false
	var raw_baseline: Variant = config.get_value("campaign", "cinematic_baseline", {})
	var baseline: Dictionary = raw_baseline if raw_baseline is Dictionary else {}
	if baseline.has(case_id):
		return true
	baseline[case_id] = {
		"exists": config.has_section_key("campaign", case_id),
		"value": config.get_value("campaign", case_id)
	}
	config.set_value("campaign", "cinematic_baseline", baseline)
	return config.save(save_path) == OK

## Restores only values first changed by cinematic choices, preserving earlier workday settings.
func restore_cinematic_baseline(config: ConfigFile) -> void:
	var raw_baseline: Variant = config.get_value("campaign", "cinematic_baseline", {})
	if raw_baseline is Dictionary:
		for case_id in raw_baseline:
			var snapshot: Variant = raw_baseline[case_id]
			if not (snapshot is Dictionary):
				continue
			if bool(snapshot.get("exists", false)):
				config.set_value("campaign", str(case_id), snapshot.get("value"))
			elif config.has_section_key("campaign", str(case_id)):
				config.erase_section_key("campaign", str(case_id))
	if config.has_section_key("campaign", "cinematic_baseline"):
		config.erase_section_key("campaign", "cinematic_baseline")

## Restarts only the cinematic thread, clearing all of its choices and derived flags.
## Other evidence, the report draft, ending, and mission progress remain untouched.
func reset_cinematic_progress() -> bool:
	var config := ConfigFile.new()
	var load_error := config.load(save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant de relancer la séquence ORCHID.")
		return false

	var raw_evidence: Variant = config.get_value("campaign", "evidence", [])
	var kept_evidence: Array = []
	for item in _normalized_evidence(raw_evidence):
		var evidence_id: String = item
		if evidence_id.begins_with("cinematic_scene_") or evidence_id.begins_with("cinematic_choice_evidence_") or evidence_id == "cinematic_outcome_calculated" or evidence_id.begins_with("orchid_cinematic_"):
			continue
		kept_evidence.append(item)
	config.set_value("campaign", "evidence", kept_evidence)

	# The sequence currently has 39 scenes (indices 0..38). Its choices are stored
	# inside the case_answers dictionary, not as top-level ConfigFile keys.
	var raw_answers: Variant = config.get_value("campaign", "case_answers", {})
	var answers: Dictionary = raw_answers if raw_answers is Dictionary else {}
	for scene_index in range(39):
		answers.erase("cinematic_choice_%02d" % scene_index)
	for answer_key in [
		"cinematic_outcome_score",
		"orchid_lea_support_status",
		"orchid_report_quality",
		"orchid_sample_protocol",
		"orchid_release_guardrail",
		"orchid_results_claim",
		"orchid_final_prompt_choice",
		"orchid_cinematic_focus_pause"
	]:
		answers.erase(answer_key)
	config.set_value("campaign", "case_answers", answers)

	# Older saves or integrations may also have left top-level scene keys behind.
	for scene_index in range(39):
		var choice_key := "cinematic_choice_%02d" % scene_index
		if config.has_section_key("campaign", choice_key):
			config.erase_section_key("campaign", choice_key)

	# Restore settings which a cinematic choice may have overwritten in other game modes.
	restore_cinematic_baseline(config)
	if config.has_section_key("campaign", "cinematic_outcome_score"):
		config.erase_section_key("campaign", "cinematic_outcome_score")

	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var save_error := config.save(save_path)
	if save_error != OK:
		push_warning("Impossible de réinitialiser la séquence ORCHID : %s" % save_error)
		return false
	return true

func load_ending() -> String:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return ""
	var raw_ending: Variant = config.get_value("campaign", "ending", "")
	if raw_ending is String and raw_ending in ["published", "preserved"]:
		return raw_ending
	return ""
