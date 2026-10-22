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


func load_ending() -> String:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return ""
	return str(config.get_value("campaign", "ending", ""))
