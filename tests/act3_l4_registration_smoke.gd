extends "res://tests/acts/act3/false_paradise_displaced_continue_smoke.gd"
## Focused actual canonical registration/first-court Save/Continue/Retry.
## Original prefix13 remains disclosed TEST history; no late/full route gate.
## Inherited proposal metadata is unused by every real Shell construction.

const ACCEPTED_COMMIT: String = "741fe48ee2db1ad27ba6e9ce2f7c7ab0a41fb6a7"
var _checked_empty_journey: bool = false


func _open() -> String:
	var registry := Registry.new()
	var current: Dictionary = registry.entry("A3-L4")
	var previous: Dictionary = registry.entry("A3-L3")
	var future: Dictionary = registry.entry("A3-L5")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and current.get("readiness") == "accepted" and current.get("accepted_commit") == ACCEPTED_COMMIT and current.get("scene_path") == LEVEL and current.get("api_revision") == "campaign-level-1" and current.get("previous_main_id") == "A3-L3" and current.get("next_main_id") == "A3-L5" and previous.get("readiness") == "accepted" and future.get("readiness") == "accepted" and future.get("scene_path") == "res://scenes/acts/act3/a3_l5_crystalman.tscn" and future.get("accepted_commit") == "83a6efa2509b5c7f5e408f3ecb4324f53d1e496d" and future.get("api_revision") == "campaign-level-1" and registry.scene_error("A3-L4").is_empty(), "actual canonical False Paradise identity, accepted L3 prerequisite and accepted L5 successor are exact", registry.last_error):
		return "canonical L4 registration differs"
	var error: String = await super._open()
	if error.is_empty() and not _expect(_same(_shell.registry.entry("A3-L4"), current), "production Shell consumes the canonical accepted content pin, with inherited proposal metadata unused"):
		error = "production Shell registry differs from canonical source"
	return error


func _new_shell() -> String:
	_shell = Shell.new()
	_host = _shell
	if not _shell.configure_runtime({}, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"):
		return "canonical production Shell configuration refused: " + _shell.campaign_error
	root.add_child(_shell)
	for _i: int in range(4): await process_frame
	if not paused or not _shell.campaign_error.is_empty() or _shell.menu == null or _shell.menu.page_name() != "title":
		return "fresh canonical Shell title/load refused: " + _shell.campaign_error
	if not _checked_empty_journey:
		_checked_empty_journey = true
		var before: Dictionary = _shell.attempts.state()
		_shell.menu.journey_requested.emit()
		for _i: int in range(4): await process_frame
		_shell.menu.select_level("A3-L4")
		var node: Button = _shell.menu.find_child("Node_A3_L4", true, false) as Button
		var action: Button = _shell.menu.find_child("LevelCardAction", true, false) as Button
		var body: Label = _shell.menu.find_child("LevelCardBody", true, false) as Label
		if not _expect(before.completed_main.is_empty() and _shell.active_level == null and _shell.menu.page_name() == "journey" and node != null and node.get_meta("campaign_state", "") == "locked" and action != null and action.disabled and body != null and body.text.contains("A3-L3"), "real fresh Journey keeps accepted L4 locked behind its actual L3 prerequisite"):
			return "fresh Journey exposed L4 without predecessor progress"
		if not _expect(_same(before, _shell.attempts.state()) and _shell.active_level == null, "locked Journey inspection invents no campaign progress or native level"):
			return "locked Journey changed fresh campaign state"
		_shell.menu.show_title()
	return ""
