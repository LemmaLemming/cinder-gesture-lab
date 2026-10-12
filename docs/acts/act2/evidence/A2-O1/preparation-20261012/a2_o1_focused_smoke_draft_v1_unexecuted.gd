extends SceneTree
## Focused production O1 component/contact preview, not an earned playthrough.
## Unit1: real native warning/lock/proof-directed controls and ordinary primary.
## TEST_ONLY set public shells=0 once at the real opening; reload stays native.
## Unit2: disclosed representative Hero placements test actual contact handling.
## No actor HP/driver phase/clock/proof/progress seed. No Shell reward/side return.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const O1_PATH: String = "res://scenes/acts/act2/a2_o1.tscn"
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
const CAPTURE_ROOT: String = "res://captures/act2/a2-o1-focused/"
const LABELS: Array[String] = ["entry", "scout-lock", "collected-journal", "opened-exit"]
const MAX_TICKS: int = 600
const TICK_S: float = 1.0 / 60.0
const DERIVED_EPS: float = 0.00001

class NativeTickProbe extends Node:
	signal tick_finished
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void:
		tick_finished.emit()

var _checks: int = 0
var _failures: int = 0
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _driver: Node3D
var _probe: Node
var _capture: bool = false
var _capture_pending: bool = false
var _frames: Array[Dictionary] = []
var _phases: Dictionary = {}
var _checkpoints: Array[Dictionary] = []
var _completions: Array[Dictionary] = []
var _exits: Array[Dictionary] = []
var _actions: Array[Dictionary] = []
var _abort: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	_capture = "--portraits" in OS.get_cmdline_user_args()
	if _capture:
		if not _expect(DisplayServer.get_name() != "headless", "portrait option requires actual native graphics"): _finish(); return
		if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_ROOT)) == OK, "separate O1 focused capture directory"): _finish(); return
	_probe = NativeTickProbe.new()
	root.add_child(_probe)
	var combat_ok: bool = await _combat_component()
	await _release()
	if combat_ok: await _contact_component()
	await _release()
	if _capture:
		var actual: Array[String] = []
		for f: Dictionary in _frames: actual.append(f["label"])
		_expect(actual == LABELS, "exact four actual entry/lock/contact/open-exit portrait labels")
		var packet: Dictionary = {"api_revision":"act2-o1-focused-preview-1", "scope":"production Main/Hero/native ordinary exchange; representative TEST_ONLY contact placements; no route/Shell stamp/side-return/all-defeats claim", "setup":{"empty_ammo":"public Hero.shells=0 once immediately before real ordinary primary; no reload/stat suppression", "contact_order":["east","west","north"], "contact_placements":"TEST_ONLY actual Hero.global_position, stable native floor before observations"}, "checks":_checks, "failures":_failures, "frames":_frames, "source_files":_sources(), "art_accepted":false}
		var encoded: String = Exact.stringify(packet)
		var file: FileAccess = FileAccess.open(CAPTURE_ROOT + "metadata.exact.json", FileAccess.WRITE)
		_expect(file != null and not encoded.is_empty(), "exact finite native metadata output opens")
		if file != null:
			file.store_string(encoded + "\n")
			file.close()
	if is_instance_valid(_probe): _probe.queue_free()
	await process_frame
	_finish()


func _boot() -> bool:
	_abort = false
	_phases.clear(); _checkpoints.clear(); _completions.clear(); _exits.clear(); _actions.clear()
	_game = MainScene.instantiate()
	_game.set("level_scene_path", O1_PATH)
	root.add_child(_game)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(_level) and is_instance_valid(_hero) and _level.level_id == "A2-O1" and _level.contract_error().is_empty(), "actual production Main installs O1 identity/shared Hero contract"): return false
	_driver = _level.get("_exchange") as Node3D
	if not _expect(is_instance_valid(_driver) and _level.get("_actors").size() == 2, "actual production two ordinary reused Scouts and native exchange"): return false
	_level.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void: _checkpoints.append({"level":id,"id":checkpoint,"kind":kind}))
	_level.completion_requested.connect(func(id: String, complete: String) -> void: _completions.append({"level":id,"id":complete}))
	_level.contact_exit_requested.connect(func(id: String, exit: String) -> void: _exits.append({"level":id,"id":exit}))
	_hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	_game.call("resume_lab")
	for _tick: int in range(12): await _step()
	return _expect(_live() and _hero.presentation_id == "act2_survivor" and _hero.is_on_floor() and _hero.equipment.snapshot()["weapon"] == "WEAPON-01", "actual default Act2 Hero settles on native dry O1 floor")


func _combat_component() -> bool:
	if not await _boot(): return false
	if _capture: await _capture_view("entry", "production initial scenery, no encounter/progression seed")
	var hp_before: float = _hero.hp
	if not await _dash(Vector3.FORWARD): return false
	if (await _wait_phase("warning")).is_empty(): return false
	var locked: Dictionary = await _wait_phase("lock")
	if locked.is_empty(): return false
	var exchange: Dictionary = locked["exchange"]
	if not _expect(locked.get("armed", false) and locked.get("proof_available", false) and locked["proof"].get("accepted", false) and float(exchange["active_from_s"]) - float(exchange["lock_from_s"]) >= 1.1 - DERIVED_EPS, "actual native tracking lock carries supported complete ordinary response and full1.10 lock"): return false
	if _capture: _capture_view("scout-lock", "actual native armed west Scout lock, full admitted source/lane/landing points")
	var actor: Node3D = (_level.get("_actors") as Dictionary)["west"]
	var target_before: float = float(actor.get("hp"))
	if not await _follow(locked, actor): return false
	await _wait_capture()
	_expect(_phases.has("warning") and _phases.has("lock") and _phases.has("active") and _phases.has("recovery"), "actual source traverses all four native cue phases")
	_expect(_hero.hp == hp_before and not _hero.dead, "actual proof-directed escape/return incurs no ray HP loss")
	_expect(float(actor.get("hp")) < target_before and float(actor.get("hp")) > 0.0, "real ordinary primary damages low housing without requiring defeat")
	var primary_count: int = 0
	var blast_count: int = 0
	for record: Dictionary in _actions:
		if record["kind"] == "primary": primary_count += 1
		if record["kind"] == "blast": blast_count += 1
	_expect(primary_count == 1 and blast_count == 0, "one actual primary, no blast or pickup dependency")
	return _live() and _failures == 0


func _follow(locked: Dictionary, actor: Node3D) -> bool:
	var cycle: int = int(locked["cycle"])
	for segment: Dictionary in locked["proof"]["path"]:
		var kind: String = segment["kind"]
		if kind not in ["escape_dash", "positioning_dash", "ordinary_primary"]: continue
		for _tick: int in range(MAX_TICKS):
			if not _live(): return false
			if _clock() + DERIVED_EPS >= float(segment["start_s"]): break
			await _step()
		if not _expect(_clock() + DERIVED_EPS >= float(segment["start_s"]) and _clock() <= float(segment["start_s"]) + TICK_S + DERIVED_EPS, "native120 sampler reaches actual planned " + kind + " within one tick"): return false
		var current: Dictionary = _ray()
		if not _expect(current.get("status") == "running" and int(current.get("cycle", -1)) == cycle and current.get("armed", false), "same native armed cycle still owns planned action"): return false
		if kind == "ordinary_primary":
			if not _expect(current["phase"] == "recovery" and bool(_driver.call("damage_window_open", "west")), "actual recovery and required presentation permit ordinary primary"): return false
			var direction: Vector3 = actor.global_position - _hero.global_position
			direction.y = 0.0
			if not _expect(direction.length() <= float(_hero.stats.primary_range) + DERIVED_EPS, "actual primary landing reaches the low housing"): return false
			# Disclosed TEST_ONLY resource conditioning. Only the public ammo field
			# is changed once; all native reload/HP/clock/pose/proof behavior remains.
			_hero.shells = 0
			_expect(_hero.shells == 0, "ordinary primary begins with actual empty ammo")
			var before: float = float(actor.get("hp"))
			var seq: int = _sequence()
			var hits: int = _hero.slash(direction)
			if not _expect(hits == 1 and float(actor.get("hp")) < before and _sequence() == seq + 1 and _actions.back()["kind"] == "primary", "public ordinary slash accepts one real low-housing hit with empty ammo"): return false
			for _tick: int in range(MAX_TICKS):
				if _clock() + DERIVED_EPS >= float(segment["end_s"]): break
				await _step()
		else:
			var direction: Vector3 = segment["to"] - _hero.global_position
			direction.y = 0.0
			if not await _dash(direction): return false
	return _live()


func _contact_component() -> bool:
	if not await _boot(): return false
	var alive_hp: Dictionary = {}
	for id: String in ["west", "final"]: alive_hp[id] = float((_level.get("_actors") as Dictionary)[id].get("hp"))
	if not await _place_contact(Vector3(2.05, 0.1, -0.6)): return false
	_expect(_state()["collected_ids"] == ["east"] and not _level.is_completed(), "actual east contact is collected first; order is not sorted west-first")
	if _capture: await _capture_view("collected-journal", "actual collected east prop/cue; representative contact placement, not traversal")
	for _tick: int in range(8): await _step()
	_expect(_state()["collected_ids"] == ["east"] and _completions.is_empty(), "repeated contact at same journal does not duplicate collection/complete")
	if not await _place_contact(Vector3(-2.05, 0.1, -0.6)): return false
	_expect(_state()["collected_ids"] == ["east", "west"], "actual west contact preserves non-sorted distinct collection order")
	if not await _place_contact(Vector3(-1.4, 0.1, -5.2)): return false
	_expect(_checkpoints == [{"level":"A2-O1","id":"cylinder-before-final-exchange","kind":"encounter"}] and _level.current_checkpoint()["id"] == "cylinder-before-final-exchange", "actual native before-final region issues exactly one public checkpoint request")
	if not await _place_contact(Vector3(-1.4, 0.1, -8.9)): return false
	_expect(_state()["collected_ids"] == ["east", "west", "north"] and _level.is_completed() and _state()["exit_open"], "third actual contact completes collection and opens exit")
	_expect(_completions == [{"level":"A2-O1","id":"cylinder-journal-complete"}] and _exits.is_empty(), "one public completion is distinct from later exit contact")
	for id: String in ["west", "final"]:
		_expect(float((_level.get("_actors") as Dictionary)[id].get("hp")) == alive_hp[id] and alive_hp[id] > 0.0, "journal completion retains alive Scout without defeat-all " + id)
	if _capture: await _capture_view("opened-exit", "actual three contacts/open marker; neither earned route nor Shell stamp")
	if not await _place_contact(Vector3(0.0, 0.1, -9.9)): return false
	_expect(_exits == [{"level":"A2-O1","id":"cylinder-perimeter-return"}], "actual supported exit contact issues once after completion")
	for _tick: int in range(8): await _step()
	_expect(_completions.size() == 1 and _exits.size() == 1 and _checkpoints.size() == 1, "held repeat contact does not duplicate completion/exit/checkpoint")
	return _live() and _failures == 0


func _place_contact(at: Vector3) -> bool:
	# Explicit TEST_ONLY representative placement. No motion/velocity/history,
	# driver phase/clock/HP or progression field is assigned. Not route evidence.
	if not _live() or _hero.action_in_progress(): return _expect(false, "contact setup requires current quiet healthy native Hero")
	_hero.global_position = at
	for _tick: int in range(12): await _step()
	return _expect(_live() and _hero.is_on_floor() and _hero.get_threat_response_state().get("stable", false), "representative contact resolves through actual native stable dry floor")


func _dash(direction: Vector3) -> bool:
	for _tick: int in range(MAX_TICKS):
		if not _live(): return false
		if float(_hero.get_motion_flags()["dash_cooldown_left"]) <= DERIVED_EPS and not _hero.action_in_progress(): break
		await _step()
	var sequence: int = _sequence()
	if not _expect(_hero.request_dash(direction), "actual shared controller accepts normal fixed-distance dash"): return false
	for _tick: int in range(MAX_TICKS):
		await _step()
		if not _live(): return false
		if _sequence() > sequence:
			var record: Dictionary = _actions.back()
			return _expect(record["kind"] == "dash" and record["landing"] == _hero.global_position and not _hero.action_in_progress(), "actual completed dash record/landing follows native deliberate stop")
	return _expect(false, "bounded actual dash completion")


func _wait_phase(phase: String) -> Dictionary:
	for _tick: int in range(MAX_TICKS):
		if not _live(): break
		var state: Dictionary = _ray()
		if state.get("status") == "running" and state.get("phase") == phase: return state
		await _step()
	_expect(false, "bounded actual " + phase + " publication: " + str(_state()))
	return {}


func _step() -> void:
	await _probe.tick_finished
	if not _live(): return
	var state: Dictionary = _ray()
	if state.get("status") == "running": _phases[String(state.get("phase"))] = true
	var error: String = String(_level.get("runtime_error"))
	if not error.is_empty():
		_expect(false, "production root runtime fault: " + error)
		_abort = true


func _state() -> Dictionary:
	return _level.call("encounter_state") if is_instance_valid(_level) else {}

func _ray() -> Dictionary:
	return _driver.call("state", "west") if is_instance_valid(_driver) else {}

func _clock() -> float:
	return float(_state().get("clock_s", 0.0))

func _sequence() -> int:
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return int(records.back()["sequence"]) if not records.is_empty() else 0

func _live() -> bool:
	return not _abort and is_instance_valid(_game) and is_instance_valid(_level) and is_instance_valid(_hero) and not _hero.dead


func _capture_view(label: String, scope: String) -> void:
	_capture_pending = true
	await RenderingServer.frame_post_draw
	if not _live():
		_expect(false, "actual live source/Hero survives capture barrier " + label)
		_capture_pending = false
		return
	var points: Array = _game.call("player_camera_framing_points")
	if label == "scout-lock":
		var state: Dictionary = _ray()
		_expect(state.get("status") == "running" and state.get("phase") == "lock" and state.get("armed", false), "post-draw image retains actual armed native lock")
		var actor: Node3D = (_level.get("_actors") as Dictionary)["west"]
		points.append_array(_level.call("_required_source_points", actor))
		points.append_array(_level.call("_lane_points", _level.call("_state_geometry", state)))
		if state.get("proof_available", false):
			points.append_array(_level.call("_landing_points", state["proof"]["landing"]))
			points.append_array(_level.call("_landing_points", state["proof"]["attack_position"]))
	elif label in ["collected-journal", "opened-exit"]:
		var kit: Dictionary = _level.get("_kit")
		var prop: Node3D = kit["journals"]["east"] if label == "collected-journal" else kit["exit_marker"]
		_level.call("_append_mesh_points", prop, points)
	var framing: String = _game.call("camera_framing_error", points)
	_expect(framing.is_empty(), "actual Hero/source/cue/landing framing " + label + ": " + framing)
	var picture: Image = root.get_texture().get_image()
	var image_path: String = CAPTURE_ROOT + label + ".png"
	_expect(picture != null and picture.get_size() == Vector2i(540, 1170) and picture.save_png(image_path) == OK, "original actual540x1170 portrait saved " + label)
	var camera: Camera3D = _game.get("camera") as Camera3D
	_frames.append({"label":label,"scope":scope,"hero_position":_encode(_hero.global_position),"hp":_hero.hp,"shells":_hero.shells,"hero_on_floor":_hero.is_on_floor(),"state":_encode(_state()),"checkpoint":_level.current_checkpoint(),"completed":_level.is_completed(),"actual_world_actions":_encode(_actions),"required_points":_encode(points),"camera_position":_encode(camera.global_position),"camera_basis":_encode(camera.global_basis),"camera_size":camera.size,"required_camera_error":framing,"image_path":image_path,"image_sha256":FileAccess.get_sha256(image_path)})
	_capture_pending = false


func _wait_capture() -> void:
	for _frame: int in range(120):
		if not _capture_pending: return
		await process_frame
	_expect(false, "bounded native portrait post-draw completion")


func _encode(value: Variant) -> Variant:
	if value is Vector3: return [value.x, value.y, value.z]
	if value is Basis: return {"x":_encode(value.x),"y":_encode(value.y),"z":_encode(value.z)}
	if value is Array:
		var array: Array = []
		for item: Variant in value: array.append(_encode(item))
		return array
	if value is Dictionary:
		var dict: Dictionary = {}
		for key: Variant in value: dict[String(key)] = _encode(value[key])
		return dict
	return value


func _sources() -> Dictionary:
	var sources: Dictionary = {}
	for path: String in [O1_PATH,"res://scripts/acts/act2/cylinder_perimeter.gd","res://scripts/acts/act2/cylinder_perimeter_kit.gd","res://scripts/acts/act2/heath_kit.gd","res://scripts/acts/act2/ray_scout_actor.gd","res://scripts/acts/act2/ray_scout_exchange.gd","res://scripts/game.gd","res://scripts/player.gd"]:
		sources[path] = FileAccess.get_sha256(path)
	return sources


func _refs(node: Node, result: Array[WeakRef]) -> void:
	result.append(weakref(node))
	for child: Node in node.get_children(): _refs(child, result)


func _release() -> void:
	await _wait_capture()
	var refs: Array[WeakRef] = []
	if is_instance_valid(_game):
		_refs(_game, refs)
		_game.queue_free()
	_game = null; _level = null; _hero = null; _driver = null
	paused = false
	for _frame: int in range(4): await process_frame
	var freed: bool = true
	for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
	_expect(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "actual whole production subtree/targets/required cues fully freed")


func _expect(ok: bool, label: String) -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL: " + label)
	return ok

func _finish() -> void:
	print("A2-O1 focused mechanics/contact smoke: %d checks, %d failures; ordinary native response + representative contacts/brief portraits, no full-route/Shell-return claim" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
