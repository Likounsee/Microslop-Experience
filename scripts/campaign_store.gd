extends Node
## Owns campaign persistence so UI code does not manage save-file details.

const SAVE_PATH := "user://campaign.cfg"
const MIN_MISSION_STEP := 0
const MAX_MISSION_STEP := 5
const CAMPAIGN_VERSION := 2

var mission_step: int = MIN_MISSION_STEP

func load_progress() -> int:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		mission_step = MIN_MISSION_STEP
		return mission_step

	var saved_value: Variant = config.get_value("campaign", "mission_step", MIN_MISSION_STEP)
	var saved_version: int = int(config.get_value("campaign", "version", 1))
	if typeof(saved_value) != TYPE_INT:
		mission_step = MIN_MISSION_STEP
	else:
		mission_step = clampi(saved_value, MIN_MISSION_STEP, MAX_MISSION_STEP)
		# The previous tutorial ended at step 3. Reopen the update clue so returning players can reach the new story chapter.
		if saved_version < CAMPAIGN_VERSION and mission_step >= 3:
			mission_step = 2
	return mission_step

func save_progress(step: int) -> bool:
	mission_step = clampi(step, MIN_MISSION_STEP, MAX_MISSION_STEP)
	var config := ConfigFile.new()
	# Load the existing file first so ending choices and future narrative flags survive progress saves.
	config.load(SAVE_PATH)
	config.set_value("campaign", "mission_step", mission_step)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Impossible d'enregistrer la progression de campagne : %s" % error)
		return false
	return true


## Stores the player's chapter-ending decision without invalidating older campaign saves.
func save_ending(ending: String) -> bool:
	if ending not in ["published", "preserved"]:
		return false
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		config = ConfigFile.new()
	config.set_value("campaign", "ending", ending)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var save_error := config.save(SAVE_PATH)
	if save_error != OK:
		push_warning("Impossible d'enregistrer la conclusion ORCHID : %s" % save_error)
		return false
	return true

## Persists optional ORCHID evidence IDs without disturbing mission progress or ending.
func save_evidence(evidence_id: String) -> bool:
	if evidence_id.strip_edges().is_empty():
		return false
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var raw: Variant = config.get_value("campaign", "evidence", [])
	var evidence: Array = raw if raw is Array else []
	if not evidence.has(evidence_id):
		evidence.append(evidence_id)
	config.set_value("campaign", "evidence", evidence)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Impossible d'enregistrer les indices ORCHID : %s" % error)
		return false
	return true


func load_evidence() -> Array:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return []
	var raw: Variant = config.get_value("campaign", "evidence", [])
	return raw if raw is Array else []


## Saves the latest answer for a named ORCHID evidence puzzle.
func save_case_answer(case_id: String, answer: int) -> bool:
	if case_id.strip_edges().is_empty() or answer < 0 or answer > 2:
		return false
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("campaign", "case_answers", config.get_value("campaign", "case_answers", {}))
	var answers: Dictionary = config.get_value("campaign", "case_answers", {})
	answers[case_id] = answer
	config.set_value("campaign", "case_answers", answers)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Impossible d'enregistrer la réponse ORCHID : %s" % error)
		return false
	return true


func load_case_answer(case_id: String) -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return -1
	var raw: Variant = config.get_value("campaign", "case_answers", {})
	if raw is Dictionary:
		return int(raw.get(case_id, -1))
	return -1


## Stores an editable report draft independently of the campaign ending and progress.
func save_report_draft(draft: String) -> bool:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("campaign", "report_draft", draft)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(SAVE_PATH)
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
	var load_error := config.load(SAVE_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant la revue ORCHID.")
		return false
	config.set_value("campaign", "report_draft", draft)
	var raw_answers: Variant = config.get_value("campaign", "case_answers", {})
	var answers: Dictionary = raw_answers if raw_answers is Dictionary else {}
	answers["report_studio_reviewed"] = outcome
	config.set_value("campaign", "case_answers", answers)
	var raw_evidence: Variant = config.get_value("campaign", "evidence", [])
	var evidence: Array = raw_evidence if raw_evidence is Array else []
	var evidence_id := "report_studio_reviewed" if outcome == 2 else "report_studio_revision_requested"
	var stale_evidence_id := "report_studio_revision_requested" if outcome == 2 else "report_studio_reviewed"
	# Keep only the evidence matching the latest review result; older opposite outcomes are stale.
	while evidence.has(stale_evidence_id):
		evidence.erase(stale_evidence_id)
	if not evidence.has(evidence_id):
		evidence.append(evidence_id)
	config.set_value("campaign", "evidence", evidence)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Impossible d'enregistrer la revue complète du rapport ORCHID : %s" % error)
		return false
	return true


func load_report_draft() -> String:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return ""
	return str(config.get_value("campaign", "report_draft", ""))


## Restarts only the cinematic thread, leaving the wider ORCHID case file intact.
## Scene markers and choice keys are cleared together so resume cannot jump to the ending.
## Capture a pre-cinematic value once so replay can restore settings owned by other gameplay paths.
func capture_cinematic_baseline(case_id: String) -> bool:
	if case_id.strip_edges().is_empty():
		return false
	var config := ConfigFile.new()
	var load_error := config.load(SAVE_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return false
	var baseline: Dictionary = config.get_value("campaign", "cinematic_baseline", {})
	if baseline.has(case_id):
		return true
	baseline[case_id] = {
		"exists": config.has_section_key("campaign", case_id),
		"value": config.get_value("campaign", case_id)
	}
	config.set_value("campaign", "cinematic_baseline", baseline)
	return config.save(SAVE_PATH) == OK

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
	var load_error := config.load(SAVE_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Impossible de relire la sauvegarde avant de relancer la séquence ORCHID.")
		return false

	var raw_evidence: Variant = config.get_value("campaign", "evidence", [])
	var kept_evidence: Array = []
	if raw_evidence is Array:
		for item in raw_evidence:
			var evidence_id := str(item)
			if evidence_id.begins_with("cinematic_scene_") or evidence_id.begins_with("cinematic_choice_evidence_") or evidence_id == "cinematic_outcome_calculated" or evidence_id.begins_with("orchid_cinematic_"):
				continue
			kept_evidence.append(item)
	config.set_value("campaign", "evidence", kept_evidence)

	# The sequence currently has 39 scenes (indices 0..38). Clear every slot,
	# including late-epilogue decisions, rather than silently retaining old branches.
	for scene_index in range(39):
		var choice_key := "cinematic_choice_%02d" % scene_index
		if config.has_section_key("campaign", choice_key):
			config.erase_section_key("campaign", choice_key)

	# Restore settings which a cinematic choice may have overwritten in other game modes.
	restore_cinematic_baseline(config)
	if config.has_section_key("campaign", "cinematic_outcome_score"):
		config.erase_section_key("campaign", "cinematic_outcome_score")

	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var save_error := config.save(SAVE_PATH)
	if save_error != OK:
		push_warning("Impossible de réinitialiser la séquence ORCHID : %s" % save_error)
		return false
	return true

func load_ending() -> String:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return ""
	return str(config.get_value("campaign", "ending", ""))
