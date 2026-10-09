extends "res://tests/acts/act1/a1_l3_gui_capture_repro.gd"
## Focused current production-scene material/entry inspection. One entrance
## and one real paused portrait/GUI Resume; no combat or completed route claim.
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


func _run() -> void:
	portrait = true
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
	for id: String in NormalIds: full_defeats[id] = 0
	if not _install_passive_observers(): await _finish(); return
	process_frame.connect(_sample_opening)
	process_frame.connect(_sample_crowd)
	repro_cycle = 1
	if not await _full_enter_room(0): await _finish(); return
	repro_finished_cycles = 1
	if not _require(not repro_overflow and shots.size() == 1 and not paused and swipes > 0 and primaries == 0 and hero.hp == initial_hp and hit_events.is_empty() and opening_checkpoint_events.is_empty() and opening_completion_events == 0 and opening_contact_events == 0 and level.call("route_state").beat_index == 0 and level.call("route_state").room_stage == "active" and _future_pristine(CrowdIds, "brief current entrance retains sixteen future dormant actors"), "brief inspection has one actual portrait/GUI Resume and genuine entrance only; no damage, checkpoint or completion"):
		await _finish(); return
	brief_done = true
	await _finish()


func _capture(stage: String) -> bool:
	if not _require(paused and String(level.call("route_snapshot_runtime_error")).is_empty(), "current Full parent retains actual floor/stalk/art/material/body/cue resources at the paused portrait boundary"): return false
	return await super._capture(stage)


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
		file.store_string(JSON.stringify({"scope": "focused actual production Full L3 entry/current pale-cap material and one portrait/real GUI Resume; no combat, save/Continue/Retry, Crossed view, full route, defeat-all, earned exit, campaign traversal or optical acceptance before image review", "checks": checks, "failures": failures, "brief_done": brief_done, "actual_swipes": swipes, "actual_primaries": primaries, "source_count": retained_sources.size(), "normal_focus_out_preserved": true, "current_pins": BriefPins, "world_ids": full_world_ids, "final_route": _portable(final_route), "world_actions": _portable(final_records), "receipt_overflow": repro_overflow, "finished_gui_resumes": repro_finished_cycles, "receipts": repro_receipts, "captures": shots}, "\t"))
		file.close()
	else:
		checks += 1; failures += 1; push_error("brief current portrait report unavailable")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 BRIEF CURRENT PORTRAIT: %d checks/%d failures; %d captures/%d GUI Resumes; %d real swipes/%d ordinary primaries; report=%s" % [checks, failures, shots.size(), repro_finished_cycles, swipes, primaries, path])
	quit(1 if failures else 0)
