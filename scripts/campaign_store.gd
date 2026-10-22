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
	config.set_value("campaign", "mission_step", mission_step)
	config.set_value("campaign", "version", CAMPAIGN_VERSION)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Impossible d'enregistrer la progression de campagne : %s" % error)
		return false
	return true
