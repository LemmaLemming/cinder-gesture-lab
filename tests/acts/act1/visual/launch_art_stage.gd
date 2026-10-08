extends "res://scripts/acts/act1/launch_rehearsal.gd"
## TEST ONLY pose/layout staging for standard --capture mode. This creates no
## gesture, traversal, checkpoint/save or human-playtest evidence. Roof/boarding
## warnings are actual accepted shared cycles on the real floor; beat prefixes
## are deliberately staged, not claimed as completed player actions. Optional
## --art-landing uses tested route landing coordinates for composition only;
## this image proves no focused gesture, traversal or actual dash animation.
var _art_stage: String = "roof"
var _art_landing: bool = false

func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--art-landing":
			_art_landing = true
		if argument.begins_with("--art-stage="):
			_art_stage = argument.trim_prefix("--art-stage=")
	super._ready()
	($PlayerSpawn as Marker3D).position = Vector3(1.2, 0.1, -6) if _art_stage == "roof" else (Vector3(1.2, 0.1, -12) if _art_stage == "boarding" else Vector3(-0.9, 0.1, -12.1))
	if _art_landing and _art_stage in ["roof", "boarding"]:
		# Change only the TEST marker before the shared shell prepares its actor.
		($PlayerSpawn as Marker3D).position += Vector3(0.6, 0, 0.8).normalized() * 2.7

func _on_enter_level() -> void:
	super._on_enter_level()
	beat_index = 3 if _art_stage == "roof" else (4 if _art_stage == "boarding" else 5)
	completed_exercises.clear()
	for index: int in beat_index:
		completed_exercises.append(EXERCISES[index])
	for index: int in TARGET_IDS.size():
		(targets[TARGET_IDS[index]] as PracticeTarget).configure(1.0, 0.0 if beat_index >= index + 2 else 1.0, 0.0, false)
	if beat_index in [3, 4]:
		scheduler.begin_encounter("standard", ENCOUNTER_IDS[beat_index - 3], 1)
	_apply_beat()
