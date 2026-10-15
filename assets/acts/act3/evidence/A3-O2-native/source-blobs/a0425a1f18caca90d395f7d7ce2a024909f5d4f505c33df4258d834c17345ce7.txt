extends "res://tests/acts/act3/pillars_before_time_focused.gd"
## Final O2 focused court rule. Reuses only accepted observation/cleanup/exact
## helpers; O1 routes and source/progress gates are never invoked. Four native
## Root recovery primaries earn three clear boundaries; the familiar Stalker
## remains alive. No resource/pose/clock/HP writes or fabricated court history.
## Fresh production transport, exit/replay and portrait are separate scopes.

const QRC = preload("res://scripts/acts/act3/quiet_root_circuit.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const QRC_ROOM: String = "res://scenes/acts/act3/a3_o2_quiet_root_circuit.tscn"
const ROOT_ID: String = "o2-first-root"
const STALKER_ID: String = "o2-final-stalker"
const COURT_ROOTS: Array = [["o2-first-root"],["o2-second-root"],["o2-final-west-root","o2-final-east-root"]]
const EPS: float = 0.00001
class NativeRootResponse extends RefCounted:
	## Test-only action driver. Actual Shell/Main owns the tree and all packets.
	## Callbacks observe its real post-actor/presentation boundaries and records.
	const BodySweep = preload("res://scripts/combat/body_sweep.gd")
	const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
	const EPS: float = 0.00001
	var _hero: CinderPlayer
	var _level: CinderLevel
	var _scheduler: CinderThreatScheduler
	var _root_source: CinderAct3RootLatcher
	var _mechanism: CinderLaneMechanism
	var _selected_root_id: String
	var _kit: Dictionary
	var _starting_hp: float
	var _action_records: Callable
	var _fired_kinds: Callable
	var _death_count: Callable
	var _tick_callback: Callable
	var _presentation_callback: Callable
	var _assertion_callback: Callable

	func configure(actual_hero: CinderPlayer, actual_level: CinderLevel, actual_scheduler: CinderThreatScheduler, actual_root: CinderAct3RootLatcher, stable_id: String, held_kit: Dictionary, action_records: Callable, fired_kinds: Callable, death_count: Callable, tick_callback: Callable, presentation_callback: Callable, assertion_callback: Callable) -> void:
		_hero = actual_hero
		_level = actual_level
		_scheduler = actual_scheduler
		_root_source = actual_root
		_mechanism = actual_root.get_mechanism()
		_selected_root_id = stable_id
		_kit = held_kit.duplicate(true)
		_starting_hp = actual_hero.hp
		_action_records = action_records
		_fired_kinds = fired_kinds
		_death_count = death_count
		_tick_callback = tick_callback
		_presentation_callback = presentation_callback
		_assertion_callback = assertion_callback

	func _expect(ok: bool, label: String, detail: String = "") -> bool:
		return bool(_assertion_callback.call(ok,label,detail))

	func _tick() -> bool:
		return bool(await _tick_callback.call())

	func _presentation() -> bool:
		return bool(await _presentation_callback.call())

	func follow(proof: Dictionary, record: Dictionary) -> bool:
		var escaped: bool = false
		var returned: bool = false
		var last_dash_end_s: float = -1.0
		for segment: Dictionary in proof.path:
			# The native controller finishes a dash on a real physics boundary.
			# Later actions cannot start before that measured completion.
			var scheduled_start_s: float = maxf(float(segment.start_s), last_dash_end_s)
			if not await _until(scheduled_start_s): return false
			if segment.kind in ["escape_dash","positioning_dash"]:
				if not _expect(_hero.global_position.distance_to(segment.from) <= 0.02, "native witness dash begins at its actual recorded world point"): return false
				var direction: Vector3 = segment.to-segment.from
				direction.y = 0
				if not await dash(direction.normalized()): return false
				var actions: Array = _action_records.call()
				var actual: Dictionary = actions.back() if not actions.is_empty() else {}
				var actual_start_s: float = float(actual.started_at_s)
				var actual_end_s: float = float(actual.completed_at_s)
				var resolved_duration_s: float = float(actual.resolved_stats.dash_duration)
				var native_duration_s: float = float(ceili(resolved_duration_s / _tick_s())) * _tick_s()
				var window_safe: bool = actual_end_s < float(record.active_from_s) if segment.kind == "escape_dash" else (actual_start_s >= float(record.active_until_s) and actual_end_s < float(record.recovery_until_s))
				if not _expect(_hero.global_position.distance_to(segment.to) <= 0.02 and actual_start_s >= scheduled_start_s-EPS and actual_start_s <= scheduled_start_s+_tick_s()+EPS and resolved_duration_s > 0.0 and absf((actual_end_s-actual_start_s)-native_duration_s) <= EPS and absf(_scheduler.get_clock()-actual_end_s) <= EPS and absf(_hero.get_world_action_clock()-actual_end_s) <= EPS and window_safe, "actual dash preserves endpoint, separately bounded request tick/native duration and genuine safe window", str({"kind":segment.kind,"planned_start_s":segment.start_s,"planned_end_s":segment.end_s,"scheduled_start_s":scheduled_start_s,"actual_start_s":actual_start_s,"actual_end_s":actual_end_s,"resolved_duration_s":resolved_duration_s,"native_duration_s":native_duration_s,"hero_position":_hero.global_position,"planned_landing":segment.to,"active_from_s":record.active_from_s,"active_until_s":record.active_until_s,"recovery_until_s":record.recovery_until_s})): return false
				last_dash_end_s = actual_end_s
				escaped = escaped or segment.kind == "escape_dash"
				returned = returned or segment.kind == "positioning_dash"
			elif segment.kind == "ordinary_primary":
				var current: Dictionary = _root_source.state()
				var held: Dictionary = _scheduler.reservation_state(String(record.id))
				if not _expect(escaped and returned and current.phase == "recovery" and held.get("state") == "recovery" and held.geometry == record.geometry and _hero.global_position.distance_to(proof.attack_position) <= 0.02 and float(proof.response_complete_s) < float(record.recovery_until_s) and float(_hero.get_threat_response_state().primary_cooldown_left_s) == 0.0, "real selected return exposes an ordinary-primary recovery opening"): return false
				var direction: Vector3 = _root_source.global_position-_hero.global_position
				direction.y = 0
				var damage: float = float(_hero.equipment.resolved_stats().primary_damage)
				var deaths_before: int = int(_death_count.call())
				var hits: int = _hero.slash(direction.normalized())
				if not _expect(hits == 1 and _root_source.hp == maxf(0.0,20.0-damage) and _root_source.dead and int(_death_count.call()) == deaths_before+1 and not (_fired_kinds.call() as Array).has("blast"), "one genuine ordinary primary severs unchanged20HP Root; no blast/resource write"): return false
				# Allow native deferred body flags to settle before the next actual
				# process/capture; no court or source state is written by this test.
				if not await _tick() or not await _presentation(): return false
				var body: CollisionShape3D = _root_source.get_node("BodyCollision") as CollisionShape3D
				var state: Dictionary = _level.call("state")
				return _expect(state.deaths.has(_selected_root_id) and Codec.read_vector3(state.deaths[_selected_root_id].source_position) == _root_source.global_position and body.disabled and _root_source.collision_layer == 0 and _root_source.collision_mask == 0 and not _root_source.is_in_group("enemies") and _mechanism.state().phase == "clear" and _hero.hp == _starting_hp and _hero.equipment.snapshot() == _kit, "real required Root death/spent body/lease/cue settles without a test-written boundary",str(state))
			elif not await _until(float(segment.end_s)): return false
		return _expect(false, "actual native witness includes one ordinary primary")

	func approach() -> bool:
		# Fixed visible-base detour only: one real lateral dash, with its
		# following sourceward dash independently swept from that native end.
		# No collision result is shortened or turned into an input/pose repair.
		var distance: float = float(_hero.get_threat_response_state().stats.dash_distance)
		var from: Transform3D = _hero.global_transform
		var toward: Vector3 = _root_source.global_position-from.origin
		toward.y = 0
		if not _expect(toward.length_squared() > 0.0,"nonzero actual fixed-source approach bearing"): return false
		var floors: Array = (_level.call("scheduler_bindings") as Dictionary).floors.values()
		var direct: Dictionary = BodySweep.sweep(_hero,from,toward.normalized()*distance,floors)
		if _complete_sweep(direct,from.origin+toward.normalized()*distance): return await dash(toward.normalized())
		for side: Vector3 in [Vector3.RIGHT,Vector3.LEFT]:
			var lateral: Dictionary = BodySweep.sweep(_hero,from,side*distance,floors)
			if not _complete_sweep(lateral,from.origin+side*distance): continue
			var next_from: Transform3D = from
			next_from.origin = lateral.end
			var next_toward: Vector3 = _root_source.global_position-next_from.origin
			next_toward.y = 0
			if next_toward.length_squared() == 0.0: continue
			var next: Dictionary = BodySweep.sweep(_hero,next_from,next_toward.normalized()*distance,floors)
			if not _complete_sweep(next,next_from.origin+next_toward.normalized()*distance): continue
			print("Quiet Root approach: native base blocks direct path; actual lateral ",side," from ",from.origin," to ",lateral.end,"; following full sweep to ",next.end)
			return await dash(side)
		return _expect(false,"bounded actual full-distance base detour exists",str({"hero":from.origin,"source":_root_source.global_position,"direct_error":direct.get("error",""),"direct_collided":direct.get("collided",true),"direct_end":direct.get("end"),"direct_normal":direct.get("normal")}))

	func _complete_sweep(sweep: Dictionary, endpoint: Vector3) -> bool:
		return not sweep.has("error") and not sweep.get("collided",true) and sweep.get("end") is Vector3 and (sweep.end as Vector3).distance_to(endpoint) <= 0.005

	func dash(direction: Vector3) -> bool:
		for _index: int in range(90):
			var ready: Dictionary = _hero.get_threat_response_state()
			if ready.get("stable",false) and float(ready.dash_cooldown_left_s) == 0.0: break
			if not await _tick(): return false
		var response: Dictionary = _hero.get_threat_response_state()
		var from: Vector3 = _hero.global_position
		var motion: Vector3 = direction*float(response.stats.dash_distance)
		var sweep: Dictionary = BodySweep.sweep(_hero,_hero.global_transform,motion,(_level.call("scheduler_bindings") as Dictionary).floors.values())
		if not _expect(response.get("stable",false) and float(response.dash_cooldown_left_s) == 0.0 and not sweep.has("error") and not sweep.get("collided",true) and (sweep.end as Vector3).distance_to(from+motion) <= 0.005, "actual current body/floor supports the complete ordinary dash",str(sweep)): return false
		var count: int = (_action_records.call() as Array).size()
		if not _expect(_hero.request_dash(direction), "public controller accepts actual Root response dash"): return false
		for _index: int in range(40):
			if not await _tick(): return false
			var actions: Array = _action_records.call()
			if actions.size() > count:
				var action: Dictionary = actions.back()
				return _expect(actions.size() == count+1 and action.kind == "dash" and not action.blocked and not action.collision_shortened and action.world_origin == from and action.landing == _hero.global_position and action.landing.distance_to(from+motion) <= 0.005 and action.equipment_ids == _kit and not CinderPlayer.encode_world_action_record(action,_hero.get_world_action_clock()).is_empty() and _hero.is_on_floor(), "one genuine completed native dash preserves distance/history/kit/supported landing")
		return _expect(false, "bounded ordinary native dash completion")

	func _until(target: float) -> bool:
		for _index: int in range(480):
			if _scheduler.get_clock()+EPS >= target: return _expect(_scheduler.get_clock() <= target+_tick_s()+EPS, "native witness time stays within one physics tick")
			if not await _tick(): return false
		return _expect(false, "bounded actual witness time")

	func _tick_s() -> float:
		return 1.0/float(Engine.physics_ticks_per_second)


var _root_source: CinderAct3RootLatcher
var _mechanism: CinderLaneMechanism
var _starting_hp: float = 0.0
var _deaths: int = 0
var _native_events: int = 0
var _fired: Array[String] = []
var _selected_root_id: String = ROOT_ID
var _checkpoint_receipts: Array[Dictionary] = []
var _boundary_pairs: Dictionary = {}

func _run() -> void:
	create_timer(150.0, true, false, true).timeout.connect(_watchdog)
	if not _expect(OS.get_cmdline_user_args().is_empty(), "one default final three-court focused case"):
		await _finish()
		return
	if await _open_root():
		await _clear_courts()
	await _finish()

func _clear_courts() -> bool:
	var expected_deaths: int = 0
	for court: int in range(COURT_ROOTS.size()):
		for index: int in range(COURT_ROOTS[court].size()):
			_selected_root_id = String(COURT_ROOTS[court][index])
			_root_source = (_level.get("sources") as Dictionary)[_selected_root_id] as CinderAct3RootLatcher
			_mechanism = _root_source.get_mechanism()
			var warning: Dictionary = await _warning()
			if warning.is_empty(): return false
			if index == 0:
				if not await _held_pair(): return false
				_game.call("resume_lab")
				if not _expect(not paused, "public Main resumes the genuine held typed whole court unit"): return false
			if not await _follow(warning.proof, warning.record): return false
			expected_deaths += 1
			if index+1 < COURT_ROOTS[court].size():
				if not _expect(not _level.is_completed() and (_level.call("state") as Dictionary).active_court == court and _checkpoints == QRC.CHECKPOINT_IDS.slice(0,court), "one final Root death cannot clear its two-source court"): return false
		if not await _court_boundary(court,expected_deaths): return false
	return true

func _open_root() -> bool:
	_game = MainScene.instantiate()
	root.add_child(_game)
	_game.call("open_bench")
	if not _expect(paused and _game.call("is_lab_level") and get_nodes_in_group("enemies").is_empty(), "actual enemy-free paused Main starts final O2"): return false
	if not _expect(_game.call("load_level_scene", QRC_ROOM), "public Main loads final authored O2", String(_game.get("level_load_error"))): return false
	_game.call("open_bench")
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	if not _expect(_level != null and _hero != null and _scheduler != null and _level.level_id == "A3-O2" and _level.scene_file_path == QRC_ROOM and _level.local_snapshot_version == QRC.LOCAL_VERSION and _level.contract_error().is_empty(), "ready O2/local2 binds one real Hero/Scheduler", _level.contract_error() if _level != null else "missing level"): return false
	var sources: Dictionary = _level.get("sources")
	_root_source = sources.get(ROOT_ID) as CinderAct3RootLatcher
	_mechanism = _root_source.get_mechanism() if _root_source != null else null
	var bindings: Dictionary = _level.call("scheduler_bindings")
	if not _expect(sources.size() == 5 and QRC.LOCAL_VERSION == 2 and QRC.ROOT_IDS.size() == 4 and QRC.COURT_IDS.size() == 3 and QRC.CHECKPOINT_IDS.size() == 2 and bindings.owners.size() == 5 and bindings.actors.get("hero") == _hero and bindings.floors["forest-floor"].safe_rect == QRC.FLOOR_RECT and _hero.get_world_3d() == _scheduler.get_world_3d(), "all final sources, court gates, native owners, Hero and permanent forest floor bind"): return false
	for id: String in QRC.SOURCE_IDS:
		var source: Node3D = sources.get(id) as Node3D
		var is_root: bool = QRC.ROOT_IDS.has(id)
		var owner_id: String = id+"/attack" if is_root else id
		var owner: Node3D = source.call("get_mechanism") as Node3D if is_root else source
		if not _expect(source != null and source.global_position == QRC.SOURCE_POSITIONS[id] and source.get_world_3d() == _hero.get_world_3d() and source.get("hp") == (20.0 if is_root else 36.0) and not source.get("dead") and source.is_in_group("enemies") and bindings.owners.get(owner_id) == owner and source.is_physics_processing() == (id == ROOT_ID), "actual retained native role/home/owner and initial court entitlement: "+id): return false
		source.connect("state_changed",func(_state: Dictionary) -> void: _native_events += 1)
		if is_root:
			source.connect("died",func(_where: Vector3) -> void: _deaths += 1)
			(owner as CinderLaneMechanism).state_changed.connect(func(_state: Dictionary) -> void: _native_events += 1)
	_kit = _hero.equipment.snapshot()
	_starting_hp = _hero.hp
	if not _expect(paused and _hero.global_position == Vector3(0,0.1,8) and _hero.hp == _hero.max_hp and not _hero.dead and _scheduler.get_clock() == 0.0 and _scheduler.reservations().is_empty() and _hero.get_world_action_records().is_empty() and (_level.call("state") as Dictionary).deaths.is_empty(), "genuine fresh spawn/clock0 contains no fabricated action/lease/death"): return false
	_level.checkpoint_requested.connect(_on_checkpoint)
	_level.completion_requested.connect(_on_completion)
	_level.contact_exit_requested.connect(_on_exit)
	_hero.world_action_executed.connect(_on_action)
	_hero.fired.connect(func(kind: String) -> void: _fired.append(kind))
	_barrier = PostActorBarrier.new()
	_barrier.name = "QuietRootPostActorObserver"
	root.add_child(_barrier)
	for _frame: int in range(4): await process_frame
	_game.call("resume_lab")
	for _index: int in range(8):
		if _hero.is_on_floor(): break
		if not await _tick(): return false
	return _expect(not paused and _hero.is_on_floor(), "ordinary native Hero settles on the continuous floor")

func _warning() -> Dictionary:
	# Observe newly enabled sources before choosing any approach input.
	if not await _tick(): return {}
	# Only real ordinary dashes approach the next fixed court. A concurrent
	# native proof from a different Hero point is never treated as executable.
	var approaches: int = 0
	for _index: int in range(480):
		var state: Dictionary = _root_source.state()
		var proof: Dictionary = state.proof
		var usable: bool = state.phase == "warning" and proof.get("path") is Array and not proof.path.is_empty() and proof.path[0].from.distance_to(_hero.global_position) <= 0.02
		if usable:
			for segment: Dictionary in proof.path:
				if segment.kind == "escape_dash":
					usable = _scheduler.get_clock() <= float(segment.start_s)+EPS
					break
		if usable:
			var record: Dictionary = _scheduler.reservation_state(String(state.mechanism.reservation_id))
			if not _expect(not record.is_empty() and record.armed and record.source_instance_id == _mechanism.get_instance_id() and record.geometry.kind == "crescent" and record.geometry.origin == _root_source.global_position and record.geometry == state.geometry and proof.get("accepted",false) and not proof.get("uses_blast",true) and not proof.get("uses_invulnerability",true) and _root_source.get_selected_response().landing == proof.landing and _root_source.get_selected_response().attack_position == proof.attack_position, "genuine native Root warning holds fixed crescent/lease and ordinary escape-return witness", str(state)): return {}
			var path: Array[Dictionary] = []
			for segment: Dictionary in proof.path: path.append(segment)
			if not _expect(not Geometry.timed_path_hits(record.geometry,path,float(record.active_from_s),float(record.active_until_s),CinderThreatScheduler.CAPSULE_RADIUS+CinderThreatScheduler.SKIN), "actual selected witness avoids the active crescent without immunity"): return {}
			print("Quiet Root focused: genuine ",_selected_root_id," warning at ",_scheduler.get_clock())
			return {"proof":proof.duplicate(true), "record":record.duplicate(true)}
		var toward: Vector3 = _root_source.global_position-_hero.global_position
		toward.y = 0
		if state.mechanism.status != "running" and toward.length() > 2.8 and approaches < 3:
			approaches += 1
			if not await _approach_native(): return {}
		elif not await _tick(): return {}
	_expect(false, "bounded real selected Root warning from current Hero point", str({"id":_selected_root_id,"hero":_hero.global_position,"source":_root_source.state(),"level":_level.call("state")}))
	return {}

func _held_pair() -> bool:
	if not await _presentation(): return false
	_game.call("open_bench")
	await process_frame
	var pair: Dictionary = _pair()
	if not _expect(not pair.is_empty() and _hero.snapshot_error(pair.player).is_empty() and _level.snapshot_error_with_player(pair.level,pair.player).is_empty(), "actual held whole Hero/Root/Mechanism/Scheduler/Sun/court pair validates", _hero.last_snapshot_error+"; "+_level.last_snapshot_error): return false
	var encoded: String = ExactJson.stringify(pair)
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not _expect(not encoded.is_empty() and decoded.get("accepted",false) and _exact(pair,decoded.get("value")) and pair.level.local.sources[ROOT_ID].kind == "root" and pair.level.local.sources[_selected_root_id].actor.mechanism.phase == "warning" and pair.level.local.sources.size() == 5 and pair.level.local.sources[STALKER_ID].kind == "stalker" and not pair.level.local.sources[STALKER_ID].actor.dead and _exact(pair.level.progress.checkpoint_ids,_checkpoint_map(int(pair.level.local.route.active_court))), "ExactJson preserves all typed native actors and exactly earned court checkpoints"): return false
	var before: Dictionary = _observation(pair)
	var bad: Dictionary = pair.level.duplicate(true)
	bad.local.sources[_selected_root_id].actor.hp = -1.0
	if not _expect(not _level.snapshot_error_with_player(bad,pair.player).is_empty() and not _level.restore_state(bad) and _exact(before,_observation(_pair())), "malformed Root HP pure/attempted whole restore rejects atomically"): return false
	var events: Array = [_native_events,_deaths,_actions.size(),_completions.duplicate(),_checkpoints.duplicate()]
	if not _expect(_hero.restore_state(pair.player) and _level.restore_state(pair.level) and _exact(pair,_pair()) and _exact(events,[_native_events,_deaths,_actions.size(),_completions,_checkpoints]), "same actual whole unit quietly restores physical Hero/Root then Scheduler/Mechanism/control without earning/events"): return false
	var frozen: Dictionary = _observation(_pair())
	for _frame: int in range(2): await process_frame
	return _expect(_exact(frozen,_observation(_pair())), "paused native clocks/body/cue/whole state and events remain frozen")

func _root_driver() -> NativeRootResponse:
	var driver := NativeRootResponse.new()
	driver.configure(_hero,_level,_scheduler,_root_source,_selected_root_id,_kit,_root_actions,_root_fired,_root_deaths,_tick,_presentation,_expect)
	return driver

func _root_actions() -> Array[Dictionary]:
	return _actions

func _root_fired() -> Array[String]:
	return _fired

func _root_deaths() -> int:
	return _deaths

func _follow(proof: Dictionary, record: Dictionary) -> bool:
	var driver: NativeRootResponse = _root_driver()
	return await driver.follow(proof,record)

func _dash_native(direction: Vector3) -> bool:
	var driver: NativeRootResponse = _root_driver()
	return await driver.dash(direction)

func _approach_native() -> bool:
	var driver: NativeRootResponse = _root_driver()
	return await driver.approach()

func _checkpoint_map(cleared: int) -> Dictionary:
	var result: Dictionary = {}
	for id: String in QRC.CHECKPOINT_IDS.slice(0,mini(cleared,QRC.CHECKPOINT_IDS.size())): result[id] = "encounter"
	return result

func _court_boundary(court: int, expected_deaths: int) -> bool:
	for _index: int in range(8):
		if int((_level.call("state") as Dictionary).active_court) == court+1: break
		if not await _tick(): return false
	if not await _presentation(): return false
	var state: Dictionary = _level.call("state")
	var completed: bool = court+1 == QRC.COURT_IDS.size()
	var expected_checkpoints: Array = QRC.CHECKPOINT_IDS.slice(0,mini(court+1,QRC.CHECKPOINT_IDS.size()))
	var stalker: Node3D = (_level.get("sources") as Dictionary)[STALKER_ID]
	if not _expect(state.active_court == court+1 and state.cleared_courts == QRC.COURT_IDS.slice(0,court+1) and state.deaths.size() == expected_deaths and _deaths == expected_deaths and _checkpoints == expected_checkpoints and _completions == ([QRC.COMPLETION_ID] if completed else []) and _exits.is_empty() and _level.is_completed() == completed and not stalker.get("dead") and float(stalker.get("hp")) > 0.0 and stalker.is_in_group("enemies") and _hero.hp == _starting_hp and _hero.equipment.snapshot() == _kit, "real court Root-clear prefix creates CP1/CP2 then completion; familiar Stalker remains alive",str(state)): return false
	_game.call("open_bench")
	await process_frame
	var pair: Dictionary = _pair()
	if not _expect(not pair.is_empty() and _level.snapshot_error_with_player(pair.level,pair.player).is_empty() and pair.level.local.route.active_court == court+1 and _exact(pair.level.progress.checkpoint_ids,_checkpoint_map(court+1)) and pair.level.progress.completed == completed and _checkpoint_receipts.size() == expected_checkpoints.size(), "post-presentation whole pair retains coherent earned boundary/progress and all source histories",_level.last_snapshot_error): return false
	_boundary_pairs[QRC.COURT_IDS[court]] = pair.duplicate(true)
	print("Quiet Root focused: clear ",QRC.COURT_IDS[court]," CPs=",_checkpoints," at ",_scheduler.get_clock(),"; Stalker alive hp=",stalker.get("hp"))
	if not completed: _game.call("resume_lab")
	return true

func _tick() -> bool:
	if _finishing: return false
	if not is_instance_valid(_barrier) or paused: return _expect(false, "actual Root tick requires live native observer/world")
	_barrier.waiting = true
	_barrier.expiration = Engine.get_process_frames()+120
	var boundary: String = await _barrier.observed
	_ticks += 1
	if _finishing: return false
	var state: Dictionary = _level.call("state")
	return _expect(boundary == "post_actor_physics" and not paused and _ticks <= 4800 and not _hero.dead and _hero.hp == _starting_hp and _hero.equipment.snapshot() == _kit and state.configuration_error.is_empty() and _root_source.global_position == QRC.SOURCE_POSITIONS[_selected_root_id], "bounded native court tick preserves full Hero HP/kit/fixed selected source",str({"boundary":boundary,"paused":paused,"clock":_scheduler.get_clock(),"ticks":_ticks,"hero_hp":_hero.hp,"starting_hp":_starting_hp,"hero_dead":_hero.dead,"actual_kit":_hero.equipment.snapshot(),"expected_kit":_kit,"actual_selected_position":_root_source.global_position,"expected_selected_position":QRC.SOURCE_POSITIONS[_selected_root_id],"source":_root_source.state(),"configuration_error":state.configuration_error}))

func _presentation() -> bool:
	_barrier.presentation_waiting = true
	_barrier.presentation_expiration = Engine.get_process_frames()+120
	var boundary: String = await _barrier.presentation_observed
	if _finishing: return false
	return _expect(boundary == "post_presentation_process" and not paused and _hero.hp == _starting_hp and not _hero.dead and _hero.equipment.snapshot() == _kit, "one actual post-Main HUD/camera process precedes pause/current view")

func _pair() -> Dictionary:
	var pair: Dictionary = {"player":_hero.snapshot_state(),"level":_level.snapshot_state()}
	return pair if not pair.player.is_empty() and not pair.level.is_empty() else {}

func _observation(pair: Dictionary) -> Dictionary:
	var body: CollisionShape3D = _root_source.get_node("BodyCollision") as CollisionShape3D
	var actors: Dictionary = {}
	for id: String in QRC.SOURCE_IDS:
		var source: Node3D = (_level.get("sources") as Dictionary)[id]
		var collision: CollisionShape3D = source.get_node("BodyCollision") as CollisionShape3D
		actors[id] = {"position":source.global_position,"hp":source.get("hp"),"dead":source.get("dead"),"body_disabled":collision.disabled,"layer":source.get("collision_layer"),"mask":source.get("collision_mask"),"enemy":source.is_in_group("enemies")}
	return {"pair":pair,"actors":actors,"cue":_mechanism.get_cue().state(),"body_disabled":body.disabled,"layer":_root_source.collision_layer,"mask":_root_source.collision_mask,"enemy":_root_source.is_in_group("enemies"),"events":[_native_events,_deaths,_actions.size(),_completions.duplicate(),_checkpoints.duplicate(),_exits.duplicate()]}

func _on_checkpoint(id: String, checkpoint: String, kind: String) -> void:
	var state: Dictionary = _level.call("state")
	var index: int = _checkpoints.size()
	var sources: Dictionary = _level.get("sources")
	var coherent: bool = index < QRC.CHECKPOINT_IDS.size() and checkpoint == QRC.CHECKPOINT_IDS[index] and state.active_court == index+1 and state.cleared_courts == QRC.COURT_IDS.slice(0,index+1) and not state.completed
	for root_id: String in COURT_ROOTS[mini(index+1,COURT_ROOTS.size()-1)]:
		coherent = coherent and not sources[root_id].dead and sources[root_id].is_physics_processing()
	if index == 1: coherent = coherent and sources[STALKER_ID].is_physics_processing()
	_expect(id == "A3-O2" and kind == "encounter" and coherent,"canonical court checkpoint emits only after coherent next-source activation",str({"id":id,"checkpoint":checkpoint,"kind":kind,"state":state}))
	_checkpoints.append(checkpoint)
	_checkpoint_receipts.append(state.duplicate(true))

func _on_completion(id: String, completion: String) -> void:
	_completions.append(completion)
	_expect(id == "A3-O2" and completion == QRC.COMPLETION_ID,"actual Root completion has canonical identity")

func _on_exit(id: String, exit_id: String) -> void:
	_exits.append(exit_id)
	_expect(false,"focused court rule does not request exit",str([id,exit_id]))

func _finish() -> void:
	if _finishing: return
	_finishing = true
	await _dispose()
	_done = true
	print("Quiet Root focused courts: ",_checks," checks; failures: ",_failures,"; native ticks: ",_ticks,"; actual four Root ordinary kills/three clear gates/alive familiar Stalker/same-unit whole pairs only; no kit matrix/fresh transport/exit/replay/portrait credit")
	quit(0 if _failures == 0 else 1)
