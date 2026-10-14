extends "res://tests/restore_candidate_physics_smoke.gd"
## Focused native regression for physics-origin public Pause registration.
## Reuses the native floor fixture; checks additional-wait cancellation/cleanup.
const CoreTest = preload("res://tests/restore_candidate_physics_smoke.gd")

class BoundaryShell extends CoreTest.ObservedShell:
	const BoundaryExact = preload("res://scripts/campaign/exact_json.gd")
	var observe_pause: bool = false
	var anchor_frame: int = -1
	var submitted_wire: String = ""
	var preparation_result: Variant = null
	func _prepare_registration(extra: Array = [], install_snapshot: Dictionary = {}, fresh_candidate: Dictionary = {}) -> bool:
		if not observe_pause:
			return await super._prepare_registration(extra, install_snapshot, fresh_candidate)
		anchor_frame = Engine.get_process_frames()
		submitted_wire = BoundaryExact.stringify(extra[0]) if not extra.is_empty() and extra[0] is Dictionary else ""
		var owner: WeakRef = weakref(self)
		var prepared: bool = await super._prepare_registration(extra, install_snapshot, fresh_candidate)
		if is_instance_valid(owner.get_ref()):
			preparation_result = prepared
			observe_pause = false
		return prepared

class PhysicsPauseProbe extends Node:
	signal finished
	var target: WeakRef
	var armed: bool = false
	var earn_marker: bool = false
	var ticks: int = 0
	var witness: Dictionary = {}
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void:
		if not armed: return
		ticks += 1
		var shell: CinderCampaignShell = target.get_ref() as CinderCampaignShell
		if is_instance_valid(shell) and is_instance_valid(shell.player) and not get_tree().paused:
			var response: Dictionary = shell.player.get_threat_response_state()
			if response.get("stable") == true and response.get("motion", {}).get("grounded") == true and shell.player.is_on_floor() and not shell.player.action_in_progress():
				var level: Variant = shell.active_level
				var earned: bool = level.advance_marker() if earn_marker else true
				if earn_marker and earned: shell.player.take_damage(7.0, Vector3.ZERO)
				witness = {"ready": true, "earned": earned, "in_physics": Engine.is_in_physics_frame(), "process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames(), "ticks": ticks}
				armed = false
				shell.request_pause()
				finished.emit()
				return
		if ticks >= 120:
			witness = {"ready": false, "in_physics": Engine.is_in_physics_frame(), "process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames(), "ticks": ticks}
			armed = false
			finished.emit()

var _boundary_shell: BoundaryShell
var _physics_probe: PhysicsPauseProbe
var _mode: String = ""
var _signals: Array[Dictionary] = []
var _all_witnesses: Array[Dictionary] = []
var _deferred_negative: bool = false

func _run() -> void:
	old_fps = Engine.max_fps
	_cleanup()
	Fixture.reset_observers()
	raw = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for row: Dictionary in raw.levels:
		if row.id == "A1-L1":
			row.scene_path = FIXTURE_PATH; row.readiness = "accepted"
			row.accepted_commit = "a".repeat(40); row.api_revision = Registry.API_REVISION
	# Connect before production awaits so this is a passive pre-resumption stamp.
	process_frame.connect(_note_boundary)
	_physics_probe = PhysicsPauseProbe.new(); root.add_child(_physics_probe)
	_new_shell(); await _settle()
	game.menu.begin_story_requested.emit(); await _settle()
	if not _guard(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "public New Story creates the unchanged tiny actual native floor"):
		_finish(); return
	initial = game.attempts.active_snapshot()
	if not _guard(not initial.is_empty() and initial.level.local.marker == 0, "genuine entrance packet precedes physics-origin Pause"):
		_finish(); return
	await _physics_pause("positive", true)
	_expect(not _signals.is_empty() and _signals[0].process_frame == _boundary_shell.anchor_frame, "first actual process signal retains the preparation counter")
	if not _guard(game.campaign_error.is_empty() and game.get("_failed_operations").is_empty() and _boundary_shell.preparation_result == true, "first physics-origin Pause commits, with no failed operation: " + game.campaign_error):
		_finish(); return
	var saved: Dictionary = game.attempts.active_snapshot()
	var payload: Dictionary = Store.new(TEST_ROOT + "campaign.json").read_payload()
	if not _guard(not saved.is_empty() and not _boundary_shell.submitted_wire.is_empty() and Exact.stringify(saved) == _boundary_shell.submitted_wire and payload.get("story") is Dictionary and _same(payload.story.get("snapshot"), saved), "full actual submitted packet equals committed Attempts and checksummed disk packet"):
		_finish(); return
	_expect(saved.level.local.marker == 1 and saved.player.resources.hp == initial.player.resources.hp - 7.0 and _same(saved, game.capture_campaign_snapshot()), "coherent full earned native packet retains marker, public injury, Player/local/Shell state")
	_expect(_signals.size() == 2 and _signals[1].process_frame > _boundary_shell.anchor_frame and _signals[0].pending and _signals[1].pending, "additional real signal advances Engine counter while preparation remains pending")
	_expect(_live_fixture_count() == 1, "successful pause retires every raw validation candidate")
	# Existing returning helpers provide two tiny negatives in the extra wait.
	callback_ran = false; cancellation_ids.clear()
	await _physics_pause("cancel", false)
	_expect(_deferred_negative and callback_ran and game.campaign_error.is_empty() and _same(game.capture_campaign_snapshot(), initial), "public Retry during additional wait cancels Pause and restores genuine entrance")
	for id: int in cancellation_ids:
		_expect(not _has_entry(id), "canceled additional-wait raw instance never entered")
	_expect(_live_fixture_count() == 1, "canceled Pause and public Retry leave only installed recipient")
	callback_ran = false
	var disk_before: Dictionary = _donor_receipt().disk
	await _physics_pause("dispose", false)
	_expect(_deferred_negative and callback_ran and not is_instance_valid(game) and _live_fixture_count() == 0, "Shell disposal during additional wait leaves no installed/raw candidate")
	var disk_after: Dictionary = {}
	for name: String in ["campaign.json", "campaign.json.bak"]:
		var path: String = TEST_ROOT + name
		disk_after[name] = FileAccess.get_file_as_bytes(path).hex_encode() if FileAccess.file_exists(path) else "ABSENT"
	_expect(_same(disk_before, disk_after), "disposal cancels uncommitted Pause without disk mutation")
	_finish()

func _new_shell() -> void:
	_boundary_shell = BoundaryShell.new(); game = _boundary_shell
	game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json")
	root.add_child(game)

func _physics_pause(mode: String, earn: bool) -> void:
	_mode = mode; _signals.clear(); _deferred_negative = false
	_boundary_shell.observe_pause = true; _boundary_shell.preparation_result = null
	_physics_probe.target = weakref(game); _physics_probe.earn_marker = earn
	_physics_probe.ticks = 0; _physics_probe.witness = {}; _physics_probe.armed = true
	game.menu.resume_requested.emit()
	await _physics_probe.finished
	_expect(_physics_probe.witness.get("ready") == true and _physics_probe.witness.get("earned") == true and _physics_probe.witness.get("in_physics") == true, mode + " public Pause originates in actual grounded native Node._physics_process")
	await _settle()
	_all_witnesses.append({"mode": mode, "request": _physics_probe.witness.duplicate(true), "signals": _signals.duplicate(true)})
	_mode = ""

func _note_boundary() -> void:
	if _mode.is_empty() or not is_instance_valid(_boundary_shell) or not _boundary_shell.observe_pause or not _boundary_shell.get("_registration_pending"): return
	var frame: int = Engine.get_process_frames()
	_signals.append({"process_frame": frame, "physics_frame": Engine.get_physics_frames(), "anchor_frame": _boundary_shell.anchor_frame, "paused": paused, "pending": _boundary_shell.get("_registration_pending"), "inflight": _boundary_shell.get("_registration_inflight"), "ticks_msec": Time.get_ticks_msec()})
	if _signals.size() == 1 and frame == _boundary_shell.anchor_frame and _mode in ["cancel", "dispose"]:
		_deferred_negative = true
		if _mode == "cancel": _retry_during_wait.call_deferred()
		else: _delete_during_wait.call_deferred()

func _finish() -> void:
	if process_frame.is_connected(_note_boundary): process_frame.disconnect(_note_boundary)
	if is_instance_valid(_physics_probe): _physics_probe.free()
	Fixture.raw_ready_observer = Callable(); Fixture.entry_observer = Callable()
	if is_instance_valid(game): game.free()
	paused = false; Engine.max_fps = old_fps; _cleanup()
	print("Physics-origin registration boundary witnesses: " + JSON.stringify(_all_witnesses))
	print("Restore candidate physics boundary smoke: %d checks, %d failures; tiny actual native floor/physics-origin Pause/additional-wait lifecycle only; no lunge/campaign/performance claim" % [checks, failures])
	quit(1 if failures else 0)
