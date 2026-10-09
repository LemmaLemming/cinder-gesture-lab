extends "res://tests/acts/act1/a1_l3_gui_capture_repro.gd"
## Focused current production-scene material/entry inspection. One actual
## paused portrait/GUI Resume; optional Crossed setup uses six public test
## injuries and actual entrance gestures or disclosed Hero test placements;
## neither representative setup claims ordinary combat.
## Existing native input, containment, draw and GUI predicates are inherited.

const BriefScene: String = "res://scenes/acts/act1/a1_l3.tscn"
const BriefPins: Dictionary = {
	"scripts/acts/act1/mushroom_caverns_full.gd": "e6669c37647542b6225dbcfabd4e2ec99a4085bf77e3d8ef1b757fdf176956d5",
	"scripts/acts/act1/mushroom_caverns_route.gd": "3784a019bfd5dec6e49b18e64e73ca00b7fd21dc6497258b9f948154762b18bb",
	"scripts/acts/act1/mushroom_grotto_art.gd": "221ceb3f976a219e5e4c8d769e57c6e01aa161ca971936052bc5565acfdcbca1",
	"assets/acts/act1/grotto/environment_manifest.json": "fcafea9c192e6049212bdcc8e8cd64767011e274dcd9646c0b687f1152dd346a",
	"scenes/acts/act1/a1_l3.tscn": "2c53526ff33cfb8b61bfcd6205a565bff2e37f75e24976e15351407cccfff556",
	"tests/acts/act1/a1_l3_gui_capture_repro.gd": "45f380588ed3b91eb5b27a16b913f5cf59b50e80f7ef4dd95805b164079e8c7a",
	"tests/acts/act1/a1_l3_normal_full_route.gd": "203160e330dc10ea3c9f2d7b26e946e0c48dd1bfb23cac5e6a64085fcf3fbada",
	"tests/acts/act1/a1_l3_greybox.gd": "e98a81e75a775c07faf34b7c6b1beb691fd0f154e25eb84132e32de5176feefb"
}
var brief_done: bool = false
var brief_crossed: bool = false
var brief_test_injuries: Array[Dictionary] = []
var brief_representative_placement: bool = false
var brief_test_placements: Array[Dictionary] = []


func _run() -> void:
	portrait = true
	brief_crossed = "--crossed" in OS.get_cmdline_user_args()
	brief_representative_placement = "--representative-placement" in OS.get_cmdline_user_args()
	if not _require(not brief_representative_placement or brief_crossed, "representative placement is explicitly selected for Crossed-only visual setup"): await _finish(); return
	root.size = PortraitSize
	if not _require(DisplayServer.get_name() != "headless" and "--capture" not in OS.get_cmdline_user_args() and "--capture-polish" not in OS.get_cmdline_user_args(), "brief current portrait requires actual renderer and normal native focus handling"):
		await _finish(); return
	for path: String in BriefPins:
		if not _require(FileAccess.file_exists("res://" + path) and FileAccess.get_file_as_string("res://" + path).sha256_text() == BriefPins[path], "current material/geometry/helper pin: " + path): await _finish(); return
	capture_dir = "res://.cinder/captures/l3-brief-current-%d" % Time.get_ticks_usec()
	if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "brief current portrait output directory is writable"): await _finish(); return
	if not await _open_world(BriefScene, "production-opening-current-material", FullLayout.SPAWN): await _finish(); return
	full_spec = level.call("normal_route_spec")
	full_world_ids = {"game": str(game.get_instance_id()), "level": str(level.get_instance_id()), "player": str(hero.get_instance_id()), "scheduler": str(scheduler.get_instance_id()), "camera": str((game.get("camera") as Camera3D).get_instance_id())}
	for id: String in NormalIds:
		full_defeats[id] = 0
		sources[id].connect("defeated", _full_notice_defeat)
	if not _install_passive_observers(): await _finish(); return
	process_frame.connect(_sample_opening)
	process_frame.connect(_sample_crowd)
	repro_cycle = 1
	if brief_crossed:
		for room: int in range(2):
			if not await _brief_enter_selected(room): await _finish(); return
			for id: String in _full_ids(room):
				var before_hp: float = float(sources[id].get("hp"))
				var damage: Dictionary = sources[id].call("take_damage", before_hp, Vector3.ZERO)
				if not _require(damage.get("accepted", false) and damage.get("hp_damage") == before_hp and sources[id].get("dead") and full_defeats[id] == 1, "disclosed public TEST injury clears only entitled current source: " + id): await _finish(); return
				brief_test_injuries.append({"id": id, "room": room, "hp_before": before_hp, "result": _portable(damage), "ordinary_primary": false})
			if not await _wait(func() -> bool:
				var current: Dictionary = level.call("route_state")
				return current.beat_index == room + 1 and current.completed_beats == FullBeats.slice(0, room + 1) and current.room_stage == "approach" and scheduler.reservations().is_empty() and scheduler.encounter_profile().is_empty(), "actual parent publishes representative test-injury room boundary", 2.0): await _finish(); return
		if not await _brief_enter_selected(2): await _finish(); return
	else:
		if not await _full_enter_room(0): await _finish(); return
	repro_finished_cycles = 1
	var selected_room: int = 2 if brief_crossed else 0
	if not _require(not repro_overflow and shots.size() == 1 and not paused and (swipes == 0 if brief_representative_placement else swipes > 0) and primaries == 0 and hero.hp == initial_hp and hit_events.is_empty() and opening_checkpoint_events.size() == selected_room and opening_completion_events == 0 and opening_contact_events == 0 and level.call("route_state").beat_index == selected_room and level.call("route_state").room_stage == "active" and brief_test_injuries.size() == (6 if brief_crossed else 0) and brief_test_placements.size() == (3 if brief_representative_placement else 0) and _future_pristine(_full_allowed(selected_room), "brief current entrance retains every future dormant actor"), "brief inspection has one actual portrait/GUI Resume; disclosed representative setup has no ordinary combat/completion credit"):
		await _finish(); return
	brief_done = true
	await _finish()


func _brief_enter_selected(room: int) -> bool:
	if not brief_representative_placement: return await _full_enter_room(room)
	var before: Dictionary = level.call("route_state")
	if not _require(not paused and before.beat_index == room and before.room_stage == "approach" and before.completed_beats == FullBeats.slice(0, room), "disclosed visual placement retains actual preceding parent progress"): return false
	# Legitimate representative test state under focused-desktop-level-1. This
	# changes only the real Hero's test location, not clocks/HP/phase/activation,
	# history or camera. Native physics still owns activation and floor contact.
	var prior: Vector3 = hero.global_position
	hero.global_position = Vector3(0, prior.y, FullLayout.BEAT_THRESHOLDS[room] - 0.4)
	brief_test_placements.append({"room": room, "from": _portable(prior), "to": _portable(hero.global_position), "real_gesture": false})
	if not await _wait(func() -> bool:
		var current: Dictionary = level.call("route_state")
		return current.beat_index == room and current.room_stage == "active" and current.encounter_started and _full_room_framing_ready(), "representative placement receives actual native activation and current full framing", 2.0): return false
	_sample_opening()
	if not _require(level.call("current_source_ids") == _full_ids(room) and scheduler.encounter_profile().get("id") == "standard" and opening_epochs == _full_expected_epochs(room), "representative scene retains the correct actual Standard epoch and entitled cast"): return false
	for id: String in _full_ids(room):
		var state: Dictionary = sources[id].call("pure_presentation_state")
		if not _require(not state.dead and not state.dormant and state.hp == 16.0 and full_defeats[id] == 0 and opening_activation_counts[id] == 1, "representative native activation starts each current C31 once at original HP: " + id): return false
	if not _retained_truth("representative native entrance") or not _future_pristine(_full_allowed(room), "representative future cast remains dormant") or not _full_environment(room, true): return false
	return await _full_quiet_capture("%s-actual-whole-cast-entrance" % FullRoomNames[room])


func _full_quiet_capture(stage: String) -> bool:
	# Crossed-only inspection omits earlier images and their GUI loops. Retain
	# actual current containment; no skipped image is reported as a capture.
	if brief_crossed and stage != "crossed-actual-whole-cast-entrance": return _framing(stage)
	return await super._full_quiet_capture(stage)


func _capture(stage: String) -> bool:
	if not _require(paused and String(level.call("route_snapshot_runtime_error")).is_empty(), "current Full parent retains actual floor/stalk/art/material/body/cue resources at the paused portrait boundary"): return false
	return await super._capture(stage)


func _watchdog() -> void:
	var limit: int = 180000 if brief_crossed else WatchdogMs
	if not finishing and Time.get_ticks_msec() - started_ms > limit:
		_require_unexpected(false, "brief selected portrait completes within its finite wall budget")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	_record_repro("before_brief_cleanup", {})
	var final_route: Dictionary = level.call("route_state") if is_instance_valid(level) else {}
	var final_records: Array = hero.get_world_action_records() if is_instance_valid(hero) else []
	var retained_sources: Array = sources.values()
	var retained_scheduler: CinderThreatScheduler = scheduler
	_full_disconnect_observers()
	finishing = true
	if is_instance_valid(repro_observer):
		repro_observer.receiver = Callable()
		repro_observer.queue_free()
	if root.focus_entered.is_connected(_repro_window_focus_entered): root.focus_entered.disconnect(_repro_window_focus_entered)
	if root.focus_exited.is_connected(_repro_window_focus_exited): root.focus_exited.disconnect(_repro_window_focus_exited)
	paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(retained_scheduler):
		_require(retained_scheduler.reservations().is_empty() and retained_scheduler.encounter_profile().is_empty(), "brief normal exit retires native reservations and encounter")
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
		var until: int = Time.get_ticks_msec() + 500
		while Time.get_ticks_msec() < until: await process_frame
		game.queue_free()
	paused = false
	await process_frame
	await process_frame
	for actor: Variant in retained_sources:
		_require(not is_instance_valid(actor), "brief cleanup removes each retained actor")
	_require(not is_instance_valid(retained_scheduler) and not is_instance_valid(game) and not is_instance_valid(level) and not is_instance_valid(repro_observer), "brief cleanup removes native level/Scheduler/Game and passive observer")
	var path: String = capture_dir.path_join("evidence.json") if not capture_dir.is_empty() else "res://.cinder/l3-brief-current-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scope": "focused actual production Full L3 current pale-cap material and one portrait/real GUI Resume; optional Crossed prefix uses six disclosed public test injuries and either actual gestures or explicitly disclosed representative Hero placements. No ordinary combat, save/Continue/Retry, full route, defeat-all, earned exit, campaign traversal or optical acceptance before image review", "checks": checks, "failures": failures, "brief_done": brief_done, "crossed_representative_setup": brief_crossed, "representative_Hero_placement": brief_representative_placement, "test_placements": brief_test_placements, "test_injuries": brief_test_injuries, "actual_swipes": swipes, "actual_primaries": primaries, "source_count": retained_sources.size(), "normal_focus_out_preserved": true, "current_pins": BriefPins, "world_ids": full_world_ids, "final_route": _portable(final_route), "world_actions": _portable(final_records), "receipt_overflow": repro_overflow, "finished_gui_resumes": repro_finished_cycles, "receipts": repro_receipts, "captures": shots}, "\t"))
		file.close()
	else:
		checks += 1; failures += 1; push_error("brief current portrait report unavailable")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 BRIEF CURRENT PORTRAIT: %d checks/%d failures; %d captures/%d GUI Resumes; %d real swipes/%d ordinary primaries; report=%s" % [checks, failures, shots.size(), repro_finished_cycles, swipes, primaries, path])
	quit(1 if failures else 0)
