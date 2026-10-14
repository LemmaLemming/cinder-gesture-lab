extends SceneTree
## Compact native any-order rule; production optional transport is separate.
## Two fixed routes use ordinary dashes. No Hero/source/HP/clock writes.
const MainScene = preload("res://scenes/main.tscn")
const O1 = preload("res://scripts/acts/act3/pillars_before_time.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const ROOM: String = "res://scenes/acts/act3/a3_o1_pillars_before_time.tscn"
const SW: String = "o1-southwest-marker"
const EAST: String = "o1-east-marker"
const NW: String = "o1-northwest-marker"

class PostActorBarrier extends Node:
	signal observed(boundary: String)
	signal presentation_observed(boundary: String)
	var presentation_waiting: bool = false
	var presentation_expiration: int = 0
	var waiting: bool = false
	var expiration: int = 0
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 1000
		process_priority = 1000
	func _physics_process(_delta: float) -> void:
		if not get_tree().paused:
			_wake("post_actor_physics")
	func _process(_delta: float) -> void:
		if waiting and Engine.get_process_frames() >= expiration:
			_wake("expired_process_bound")
		if presentation_waiting:
			_wake_presentation("expired_presentation_bound" if Engine.get_process_frames() >= presentation_expiration else ("unexpected_paused_process" if get_tree().paused else "post_presentation_process"))
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting:
			_wake.bind("paused_notification").call_deferred()
	func _wake(boundary: String) -> void:
		if waiting:
			waiting = false
			observed.emit(boundary)

	func _wake_presentation(boundary: String) -> void:
		if presentation_waiting:
			presentation_waiting = false
			presentation_observed.emit(boundary)

var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _scheduler: CinderThreatScheduler
var _barrier: PostActorBarrier
var _kit: Dictionary = {}
var _expected: Array[String] = []
var _checkpoints: Array[String] = []
var _completions: Array[String] = []
var _exits: Array[String] = []
var _actions: Array[Dictionary] = []
var _saved_counts: Dictionary = {}
var _observed_awakenings: Dictionary = {}
var _early_seen: bool = false
var _ticks: int = 0
var _checks: int = 0
var _failures: int = 0
var _finishing: bool = false
var _done: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_watchdog)
	if not OS.get_cmdline_user_args().is_empty():
		_expect(false, "compact mechanics accepts no selectors")
		await _finish()
		return
	for case_index: int in range(2):
		if _finishing or not await _open(case_index): break
		print("Pillars mechanics: actual order ", _expected)
		var passed: bool = await _route(case_index)
		if _finishing: return
		await _dispose()
		if not passed or _finishing: break
	await _finish()

func _open(case_index: int) -> bool:
	_expected.assign([EAST, SW, NW] if case_index == 0 else [NW, EAST, SW])
	_checkpoints.clear()
	_completions.clear()
	_exits.clear()
	_actions.clear()
	_saved_counts.clear()
	_observed_awakenings.clear()
	_early_seen = false
	_game = MainScene.instantiate()
	root.add_child(_game)
	_game.call("open_bench")
	if not _expect(paused and _game.call("is_lab_level") and get_nodes_in_group("enemies").is_empty(), "actual Main opens its enemy-free paused lab"): return false
	if not _expect(_game.call("load_level_scene", ROOM), "public Main selects actual O1", String(_game.get("level_load_error"))): return false
	_game.call("open_bench")
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	if not _expect(_level != null and _hero != null and _scheduler != null and _level.level_id == "A3-O1" and _level.scene_file_path == ROOM and _level.local_snapshot_version == O1.LOCAL_VERSION and _level.contract_error().is_empty(), "native final O1/current local version binds one actual shared Hero/Scheduler", str({"level_valid":is_instance_valid(_level), "hero_valid":is_instance_valid(_hero), "scheduler_valid":is_instance_valid(_scheduler), "level_id":_level.level_id if _level != null else "<null>", "scene_file_path":_level.scene_file_path if _level != null else "<null>", "local_snapshot_version":_level.local_snapshot_version if _level != null else -1, "contract_error":_level.contract_error() if _level != null else "<null>", "configuration_error":(_level.call("state") as Dictionary).get("configuration_error", "<missing>") if _level != null and _level.has_method("state") else "<unavailable>"})): return false
	_kit = _hero.equipment.snapshot()
	if not _expect(_hero.global_position == Vector3(0, 0.1, 8) and _hero.hp == _hero.max_hp and not _hero.dead and _scheduler.get_clock() == 0.0 and _scheduler.reservations().is_empty() and _hero.get_world_action_records().is_empty() and is_equal_approx(float(_hero.equipment.resolved_stats().dash_distance), 2.7), "unchanged neutral-kit spawn and clock0 contain no previous action/lease"): return false
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var sources: Dictionary = _level.get("sources")
	if not _expect(bindings.world_root == _level and O1.SOURCE_IDS.size() == 3 and Codec.keys_error(bindings.owners, O1.SOURCE_IDS).is_empty() and Codec.keys_error(sources, O1.SOURCE_IDS).is_empty() and bindings.floors.size() == 1 and bindings.floors["shelf-floor"].safe_rect == O1.FLOOR_RECT, "all three final familiar Stalkers join the actual permanent floor"): return false
	for id: String in O1.SOURCE_IDS:
		var source: CinderAct3SunboundStalker = sources[id]
		if not _expect(bindings.owners[id] == source and source.get_parent() == _level and source.hp == source.max_hp and not source.dead and source.is_in_group("enemies") and source.global_position == O1.SOURCE_POSITIONS[id], "fresh immutable living source recipient: " + id): return false
	_level.checkpoint_requested.connect(_on_checkpoint)
	_level.completion_requested.connect(_on_completion)
	_level.contact_exit_requested.connect(_on_exit)
	_hero.world_action_executed.connect(_on_action)
	_barrier = PostActorBarrier.new()
	_barrier.name = "O1TestPostActorBarrier"
	root.add_child(_barrier)
	for _frame: int in range(4): await process_frame
	if not _expect((_level.call("state") as Dictionary).awake.is_empty() and (_level.call("state") as Dictionary).awakenings.is_empty(), "fresh final topology declares no earned awakening history"): return false
	_game.call("resume_lab")
	for _index: int in range(8):
		if _hero.is_on_floor(): break
		if not await _tick(): return false
	return _expect(_hero.is_on_floor() and _level.call("state").collections.is_empty() and _checkpoints.is_empty(), "ordinary native floor registration earns no marker")

func _route(case_index: int) -> bool:
	# Fixed 2.7m cardinal commands; D crosses the threshold from z=-8.2.
	var groups: Array = [
		{"path":"FFFFFFD", "count":0, "early":true},
		{"path":"BBBB", "count":1},
		{"path":"FB", "count":1, "duplicate":true},
		{"path":"LLB", "count":2},
		{"path":"FFF", "count":3},
		{"path":"RFF", "count":3, "exit":true},
		{"path":"BF", "count":3, "duplicate":true},
	] if case_index == 0 else [
		{"path":"LLFFFFFR", "count":1},
		{"path":"LR", "count":1, "duplicate":true},
		{"path":"LBBBBRRRRFFL", "count":2},
		{"path":"RBBLLLF", "count":3},
		{"path":"RFFFFD", "count":3, "exit":true},
		{"path":"LBF", "count":3, "duplicate":true},
	]
	var directions: Dictionary = {"L":Vector3.LEFT, "R":Vector3.RIGHT, "F":Vector3.FORWARD, "B":Vector3.BACK, "D":Vector3(1,0,-0.5).normalized()}
	for group: Dictionary in groups:
		var before: Dictionary = _level.call("state")
		var events: Array = [_checkpoints.duplicate(), _completions.duplicate(), _exits.duplicate()]
		var path: String = group.path
		for command_index: int in range(path.length()):
			if not await _dash(directions[path.substr(command_index, 1)]): return false
		var state: Dictionary = _level.call("state")
		if not _expect(state.collected == _expected.slice(0, int(group.count)) and state.collections.size() == int(group.count), "real waypoint group earns exactly its chosen contact prefix", str(state)): return false
		if group.get("early", false) and not _expect(_early_seen and _exits.is_empty() and not _level.is_completed() and state.exit_state == "clear" and state.contact.is_empty() and not _level.request_contact_exit(O1.EXIT_ID, _hero), "real early crossing/public premature request cannot exit"): return false
		if group.get("duplicate", false) and not _expect(_exact(state.collections, before.collections) and _exact(events, [_checkpoints, _completions, _exits]), "real repeated contact preserves original receipts/events"): return false
		if int(group.count) > 0 and not _saved_counts.has(int(group.count)):
			if not await _capture_boundary(int(group.count)): return false
		if group.get("exit", false):
			for _frame: int in range(4): await process_frame
			state = _level.call("state")
			if not _expect(_exits == [O1.EXIT_ID] and state.exit_state == "spent" and not state.contact.is_empty() and O1.EXIT_RECT.has_point(_xz(Codec.read_vector3(state.contact.hero_position))) and absf(Codec.read_vector3(state.contact.hero_position).y) <= 0.2, "later real grounded threshold dispatches canonical exit once"): return false
	return _expect(_checkpoints == O1.CHECKPOINT_IDS and _completions == [O1.COMPLETION_ID] and _exits == [O1.EXIT_ID] and _saved_counts.size() == 3 and _hero.hp > 0.0 and not _hero.dead and _hero.equipment.snapshot() == _kit and _actions.size() > 0 and _all_sources_alive(), "contacts complete without kill gate, third checkpoint or duplicate progression", str({"hp":_hero.hp, "actions":_actions.size(), "observed_awake":_observed_awakenings.keys()}))

func _all_sources_alive() -> bool:
	var sources: Dictionary = _level.get("sources")
	for id: String in O1.SOURCE_IDS:
		var source: CinderAct3SunboundStalker = sources[id]
		if source.dead or source.hp <= 0.0: return false
	return true

func _dash(direction: Vector3) -> bool:
	for _index: int in range(90):
		var response: Dictionary = _hero.get_threat_response_state()
		if response.get("stable", false) and float(response.dash_cooldown_left_s) == 0.0: break
		if not await _tick(): return false
	var ready: Dictionary = _hero.get_threat_response_state()
	if not _expect(ready.get("stable", false) and float(ready.dash_cooldown_left_s) == 0.0, "bounded ordinary dash readiness"): return false
	var start: Vector3 = _hero.global_position
	var motion: Vector3 = direction * float(_hero.equipment.resolved_stats().dash_distance)
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var sweep: Dictionary = BodySweep.sweep(_hero, _hero.global_transform, motion, bindings.floors.values())
	if not _expect(not sweep.has("error") and not sweep.get("collided", true) and (sweep.end as Vector3).distance_to(start + motion) <= 0.005, "single actual body/floor preflight supports route dash", str(sweep)): return false
	var count: int = _actions.size()
	if not _expect(_hero.request_dash(direction), "ordinary public controller accepts dash"): return false
	for _index: int in range(40):
		if not await _tick(): return false
		if _actions.size() > count:
			var record: Dictionary = _actions.back()
			return _expect(_actions.size() == count + 1 and record.kind == "dash" and not record.blocked and record.world_origin == start and (record.landing as Vector3).distance_to(start + motion) <= 0.005 and record.landing == _hero.global_position and _hero.is_on_floor() and O1.FLOOR_RECT.has_point(_xz(_hero.global_position)) and record.equipment_ids == _kit and not CinderPlayer.encode_world_action_record(record, _hero.get_world_action_clock()).is_empty(), "one genuine completed dash retains native travel/record/kit/landing", str(record))
	return _expect(false, "bounded genuine dash completion")

func _tick() -> bool:
	if _finishing: return false
	if not is_instance_valid(_barrier) or paused: return _expect(false, "route cannot wait on missing/paused actors")
	_barrier.waiting = true
	_barrier.expiration = Engine.get_process_frames() + 240
	var boundary: String = await _barrier.observed
	_ticks += 1
	if _finishing: return false
	var state: Dictionary = _level.call("state")
	if boundary != "post_actor_physics" or paused or _ticks > 4800 or _hero.dead or _hero.hp <= 0.0 or _hero.equipment.snapshot() != _kit or state.configuration_error != "" or not _level.contract_error().is_empty():
		return _expect(false, "bounded post-actor route retains real live world/HP/kit", str({"boundary":boundary, "paused":paused, "ticks":_ticks, "hero":_hero.get_threat_response_state(), "state":state}))
	if _hero.is_on_floor() and O1.EXIT_RECT.has_point(_xz(_hero.global_position)) and absf(_hero.global_position.y) <= 0.2 and not _level.is_completed(): _early_seen = true
	var awake_error: String = _awakening_error(state)
	if not awake_error.is_empty(): return _expect(false, "native proximity awakening history remains genuine and retained", awake_error + "; " + str(state))
	if state.collections.size() > _expected.size(): return _expect(false, "no extra marker receipt")
	for index: int in range(state.collections.size()):
		var receipt: Dictionary = state.collections[index]
		var point: Vector3 = Codec.read_vector3(receipt.hero_position)
		if receipt.id != _expected[index] or not O1.MARKERS[receipt.id].contact_rect.has_point(_xz(point)) or absf(point.y) > 0.2 or float(receipt.clock_s) > _scheduler.get_clock():
			return _expect(false, "receipt preserves chosen order and actual grounded contact region", str(state))
	return true


func _awakening_error(state: Dictionary) -> String:
	var history: Dictionary = state.awakenings
	var canonical: Array[String] = []
	for id: String in O1.SOURCE_IDS:
		if not history.has(id):
			if _observed_awakenings.has(id): return "earned awakening disappeared: " + id
			var dormant: Dictionary = state.source_states[id]
			if dormant.phase != "idle" or int(dormant.cycle) != 0 or not String(dormant.reservation_id).is_empty() or dormant.position != O1.SOURCE_POSITIONS[id]: return "unawakened native source acted/moved: " + id
			continue
		canonical.append(id)
		var receipt: Dictionary = history[id]
		if not Codec.keys_error(receipt, ["clock_s", "hero_position"]).is_empty() or not Codec.is_number(receipt.clock_s) or not Codec.is_vector3(receipt.hero_position): return "finite closed native awakening required: " + id
		var point: Vector3 = Codec.read_vector3(receipt.hero_position)
		if float(receipt.clock_s) < 0.0 or float(receipt.clock_s) > _scheduler.get_clock() or absf(point.y) > 0.2 or not O1.FLOOR_RECT.has_point(_xz(point)) or _xz(point).distance_to(_xz(O1.SOURCE_POSITIONS[id])) > O1.SOURCE_WAKE_RADIUS: return "awakening lacks actual near-home floor/clock receipt: " + id
		if _observed_awakenings.has(id):
			if not _exact(_observed_awakenings[id], receipt): return "earned awakening was replaced: " + id
		else:
			if not _hero.is_on_floor() or float(receipt.clock_s) != _scheduler.get_clock() or not _exact(receipt.hero_position, Codec.vector3(_hero.global_position)): return "first observed awakening differs from actual same-tick Hero/clock: " + id
			_observed_awakenings[id] = receipt.duplicate(true)
	if history.size() != canonical.size() or state.awake != canonical: return "actual awake identities/order differ from retained receipt keys"
	return ""

func _capture_boundary(count: int) -> bool:
	# The physics observer resumes before Main's ordinary HUD/camera process.
	# Observe its real completed presentation before requesting a public pause.
	if not _expect(not paused and is_instance_valid(_barrier) and _game.process_priority < _barrier.process_priority, "native presentation observer follows actual Main/HUD/camera process"): return false
	_barrier.presentation_waiting = true
	_barrier.presentation_expiration = Engine.get_process_frames() + 120
	var presentation: String = await _barrier.presentation_observed
	if _finishing: return false
	var current: Dictionary = _level.call("state")
	var awake_error: String = _awakening_error(current)
	if not _expect(presentation == "post_presentation_process" and not paused and not _hero.dead and _hero.hp > 0.0 and _hero.equipment.snapshot() == _kit and current.collections.size() == count and current.configuration_error.is_empty() and awake_error.is_empty(), "real post-presentation boundary preserves live Hero/kit/current contact receipt", str({"boundary":presentation, "paused":paused, "hero":_hero.get_threat_response_state(), "state":current, "awake_error":awake_error})): return false
	_game.call("open_bench")
	await process_frame
	var pair: Dictionary = {"player":_hero.snapshot_state(), "level":_level.snapshot_state()}
	if not _expect(paused and not pair.player.is_empty() and not pair.level.is_empty() and _hero.snapshot_error(pair.player).is_empty() and _level.snapshot_error_with_player(pair.level, pair.player).is_empty(), "count boundary captures/prevalidates whole actual source/Sun/Scheduler/Hero pair", _capture_failure_detail(pair)): return false
	if not _expect(Codec.keys_error(pair.level.local.sources, O1.SOURCE_IDS).is_empty() and _exact(pair.level.local.route.awakenings, _observed_awakenings) and _exact(pair.level.local.route.awakenings, (_level.call("state") as Dictionary).awakenings), "whole boundary retains all three native sources and actual once-only awakening receipts"): return false
	var encoded: String = ExactJson.stringify(pair)
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not _expect(not encoded.is_empty() and decoded.get("accepted", false) and _exact(pair, decoded.get("value")), "native ExactJson preserves whole boundary unit"): return false
	if not _expect(pair.level.local.route.collections.size() == count and pair.level.progress.checkpoint_id == O1.CHECKPOINT_IDS[mini(count,2)-1] and pair.level.progress.checkpoint_ids.size() == mini(count,2) and pair.level.progress.completed == (count == 3) and _checkpoints.size() == mini(count,2) and _completions.size() == (1 if count == 3 else 0), "CP1/CP2 coherent; third completes with no checkpoint"): return false
	var bad: Dictionary = pair.level.duplicate(true)
	bad.local.route.collections[0].id = "unearned-contact"
	var events: Array = [_checkpoints.duplicate(), _completions.duplicate(), _exits.duplicate(), _actions.size()]
	if not _expect(not _level.snapshot_error_with_player(bad, pair.player).is_empty() and not _level.restore_state(bad) and _exact(_hero.snapshot_state(), pair.player) and _exact(_level.snapshot_state(), pair.level) and _exact(events, [_checkpoints,_completions,_exits,_actions.size()]), "malformed collection pure/restore rejection is atomic"): return false
	_saved_counts[count] = true
	print("Pillars mechanics: exact boundary ", count, "; actual hp=", _hero.hp)
	_game.call("resume_lab")
	return _expect(not paused, "public Main resumes unchanged boundary")


## Pure failure-only measurements of the actual context, without raw points.
func _capture_failure_detail(pair: Dictionary) -> String:
	var errors: String = _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	if not pair.player.is_empty() and not pair.level.is_empty(): return errors
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	if not is_instance_valid(camera) or not is_instance_valid(hud): return errors + "; missing actual Camera/HUD"
	var hero_points: Array = _game.call("player_camera_framing_points_for", _hero, camera)
	var required: Array = hero_points.duplicate()
	var groups: Dictionary = {}
	for id: String in O1.SOURCE_IDS:
		var source: CinderAct3SunboundStalker = (_level.get("sources") as Dictionary)[id]
		var state: Dictionary = source.state()
		var held: Dictionary = source.camera_framing_points_for_context(_game, _hero, camera, {}, {}, true)
		var current: Dictionary = source.current_render_framing_points_for_context(_game, _hero, camera)
		var current_required: bool = source.global_position.distance_to(_hero.global_position) <= O1.PROP_VIEW_DISTANCE or not String(state.reservation_id).is_empty()
		required.append_array(held.points)
		if current_required: required.append_array(current.points)
		groups[id] = {"phase":state.phase, "position":source.global_position, "lease_id":state.reservation_id, "current_required":current_required, "held":_framing_group_detail(held, hero_points, camera, hud), "current":_framing_group_detail(current, hero_points, camera, hud)}
	var route: Dictionary = _level.call("state")
	for id: String in O1.MARKERS:
		if _hero.global_position.distance_to(O1.MARKERS[id].position) > O1.PROP_VIEW_DISTANCE: continue
		var group: Dictionary = _level.call("_prop_cue_bounds", (_level.get("marker_props") as Dictionary)[id], (_level.get("marker_cues") as Dictionary)[id], O1.MARKERS[id].contact_rect, route.marker_states[id])
		required.append_array(group.points)
		groups[id] = _framing_group_detail(group, hero_points, camera, hud)
	if _hero.global_position.distance_to(O1.EXIT_POSITION) <= O1.PROP_VIEW_DISTANCE:
		var group: Dictionary = _level.call("_prop_cue_bounds", _level.get("exit_prop"), _level.get("exit_cue"), O1.EXIT_RECT, route.exit_state)
		required.append_array(group.points)
		groups[O1.EXIT_ID] = _framing_group_detail(group, hero_points, camera, hud)
	var live: Dictionary = _level.call("camera_framing_union", "", [], true)
	return errors + "; " + str({"paused":paused, "hero_position":_hero.global_position, "camera_position":camera.global_position, "protected_rect":hud.combat_safe_rect(), "hero":_framing_group_detail({"error":"", "points":hero_points}, [], camera, hud), "groups":groups, "candidate_union":_framing_group_detail({"error":"", "points":required}, [], camera, hud), "normal_live_union":_framing_group_detail(live, hero_points, camera, hud)})

func _framing_group_detail(group: Dictionary, hero_points: Array, camera: Camera3D, hud: GameHUD) -> Dictionary:
	var points: Array = group.get("points", [])
	var joined: Array = hero_points.duplicate()
	joined.append_array(points)
	var plan: Dictionary = _game.call("camera_framing_plan_for_context", joined, _hero.global_position, _hero, camera, hud)
	return {"construction_error":group.get("error", "<missing>"), "point_count":points.size(), "with_hero_count":joined.size(), "current_error":String(_game.call("camera_framing_error_for_context", joined, _hero, camera, hud)), "plan_accepted":plan.get("accepted", false), "plan_error":plan.get("reason", "")}

func _on_checkpoint(id: String, checkpoint: String, kind: String) -> void:
	_expect(id == "A3-O1" and kind == "encounter", "canonical checkpoint identity/kind")
	_checkpoints.append(checkpoint)

func _on_completion(id: String, completion: String) -> void:
	_expect(id == "A3-O1", "canonical completion identity")
	_completions.append(completion)

func _on_exit(id: String, exit_id: String) -> void:
	_expect(id == "A3-O1", "canonical contact identity")
	_exits.append(exit_id)

func _on_action(record: Dictionary) -> void:
	_actions.append(record.duplicate(true))

func _dispose() -> void:
	var refs: Array[WeakRef] = []
	if is_instance_valid(_game):
		_game.call("open_bench")
		if is_instance_valid(_level):
			_level.exit_level()
			_expect(_scheduler.reservations().is_empty(), "normal public exit releases genuine leases")
		_weakrefs(_game, refs)
		root.remove_child(_game)
		_game.queue_free()
	if is_instance_valid(_barrier):
		if _barrier.waiting: _barrier._wake("fixture_disposal")
		if _barrier.presentation_waiting: _barrier._wake_presentation("fixture_disposal")
		refs.append(weakref(_barrier))
		root.remove_child(_barrier)
		_barrier.queue_free()
	_barrier = null
	paused = false
	for _frame: int in range(8): await process_frame
	await create_timer(0.15, true, false, true).timeout
	var clean: bool = true
	for ref: WeakRef in refs: clean = clean and ref.get_ref() == null
	for group: String in ["enemies","required_cues","practice_targets","lab_weapons"]: clean = clean and get_nodes_in_group(group).is_empty()
	_expect(clean, "bounded disposal frees owners/floor/cues/Hero/barrier")
	_game = null
	_level = null
	_hero = null
	_scheduler = null

func _weakrefs(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _weakrefs(child, refs)

func _watchdog() -> void:
	if not _done and not _finishing:
		_expect(false, "finite native process-time fixture watchdog expired")
		_finish.call_deferred()

func _finish() -> void:
	if _finishing: return
	_finishing = true
	await _dispose()
	_done = true
	print("Pillars focused mechanics: ", _checks, " checks; failures: ", _failures, "; post-actor ticks: ", _ticks)
	quit(0 if _failures == 0 else 1)

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		push_error(label + (": " + detail if not detail.is_empty() else ""))
	return ok

func _xz(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)

func _exact(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is float: return var_to_bytes(a) == var_to_bytes(b)
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _exact(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for index: int in range(a.size()):
			if not _exact(a[index], b[index]): return false
		return true
	return a == b
