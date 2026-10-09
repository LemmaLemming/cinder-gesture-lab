extends "res://tests/acts/act3/mirror_sea_production_replay_smoke.gd"
## Focused integration check on the actual canonical L3 registration.
## Reuses the owner's genuine clock-zero whole packet and native cleanup.
## Prefix12/13 are explicit TEST ONLY history, never earned route evidence.
## No injected scene/readiness/commit metadata is consumed by the real Shell.

const ACCEPTED_COMMIT: String = "55256309a1dfdbd2506cf56a6b09b7b026193541"
var _checked_empty_journey: bool = false


func _open() -> String:
	var registry := ProductionRegistry.new()
	var current: Dictionary = registry.entry("A3-L3")
	var previous: Dictionary = registry.entry("A3-L2")
	var future: Dictionary = registry.entry("A3-L4")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and current.get("readiness") == "accepted" and current.get("accepted_commit") == ACCEPTED_COMMIT and current.get("scene_path") == LEVEL_PATH and current.get("api_revision") == "campaign-level-1" and current.get("previous_main_id") == "A3-L2" and current.get("next_main_id") == "A3-L4" and previous.get("readiness") == "accepted" and future.get("readiness") == "unimplemented" and future.get("scene_path") == null and registry.scene_error("A3-L3").is_empty(), "actual canonical Mirror Sea registration, accepted L2 prerequisite and unexposed L4 are exact", registry.last_error):
		return "canonical L3 registration differs"
	var error: String = await super._open()
	if error.is_empty() and not _expect(_exact(_shell.registry.entry("A3-L3"), current), "production Shell consumes the canonical accepted commit rather than the owner's historical metadata adapter"):
		error = "production Shell registry differs from canonical source"
	return error


func _new_shell() -> String:
	_shell = ProductionShell.new()
	_game = _shell
	# Empty raw selects the actual production registry. The owner's in-memory
	# proposal metadata remains unused, preserving its exact historical leaf.
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
		_shell.menu.select_level("A3-L3")
		var node: Button = _shell.menu.find_child("Node_A3_L3", true, false) as Button
		var action: Button = _shell.menu.find_child("LevelCardAction", true, false) as Button
		var body: Label = _shell.menu.find_child("LevelCardBody", true, false) as Label
		if not _expect(before.completed_main.is_empty() and _shell.active_level == null and _shell.menu.page_name() == "journey" and node != null and node.get_meta("campaign_state", "") == "locked" and action != null and action.disabled and body != null and body.text.contains("A3-L2"), "real fresh Journey keeps accepted L3 locked behind its actual L2 prerequisite"):
			return "fresh Journey exposed L3 without predecessor progress"
		if not _expect(_exact(before, _shell.attempts.state()) and _shell.active_level == null, "locked Journey inspection invents no story/progression or native level"):
			return "locked Journey changed fresh campaign state"
		_shell.menu.show_title()
	return ""


func _return_protected_story() -> String:
	var error: String = _protected_story_error("replay")
	if not error.is_empty(): return error
	if not paused or _shell.menu.page_name() != "pause": return "actual paused replay return menu unavailable"
	var leave: Button = _shell.menu.find_child("LeaveSideButton", true, false) as Button
	if leave == null or leave.disabled: return "actual Leave Side Attempt button unavailable"
	var events: Dictionary = _events.duplicate(true)
	var actions: Array[Dictionary] = _actions.duplicate(true)
	_replay_return_refs = _current_native_refs()
	_prepare_fixture_rebind()
	leave.pressed.emit()
	# Shared41's actual return destination is Journey; the original39 leaf
	# and original14/0 evidence remain unchanged in their historical scope.
	error = await _settle_shell("journey")
	_watch_restore = false
	if not error.is_empty(): return error
	if not _quiet_events.is_empty() or not _exact(events, _events) or not _exact(actions, _actions): return "quiet protected-story return emitted gameplay observers: " + str(_quiet_events)
	error = _bind_runtime()
	if not error.is_empty(): return error
	var returned: Dictionary = _shell.capture_campaign_snapshot()
	if returned.is_empty() or not _exact(returned, _replay_story.snapshot): return "returned story differs from the complete original protected packet: " + _shell.campaign_error
	error = _source_free_packet_error(returned)
	if error.is_empty(): error = _protected_story_error("story")
	if error.is_empty(): error = await _donor_freed_error(_replay_return_refs, returned)
	if error.is_empty(): error = _disk_error(_shell.attempts.state())
	if not error.is_empty(): return error
	if not _expect(paused and _shell.menu.page_name() == "journey", "Shared41 Leave Side Attempt returns the exact protected story to paused Journey"):
		return "side return destination differs"
	var current: CinderLevel = _shell.active_level
	_shell.menu.continue_story_requested.emit()
	error = await _settle_shell("resume")
	if not error.is_empty(): return error
	if not _expect(_shell.active_level == current and _exact(returned, _shell.capture_campaign_snapshot()) and _exact(events, _events) and _exact(actions, _actions) and _quiet_events.is_empty(), "explicit Continue from Journey exposes paused Resume without replacing or advancing the coherent story"):
		return "Journey Continue changed the protected native story"
	return _disk_error(_shell.attempts.state())
