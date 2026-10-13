extends SceneTree
## Real authored Living Forest route, public equipment carryover and ordinary
## completed dash/primary actions. This is automated mechanic evidence, not
## routed/native gestures, human balance, art or production campaign acceptance.
## No actor HP/pose/clock, player pose, physics, stats or controller is written.
## --first-pocket clears the first actual Stalker and captures its entry unit;
## --full-route (default) crosses all six entries, kills all nine real sources
## and contacts the distinct available threshold. No blast or pickup is needed.

const MainScene = preload("res://scenes/main.tscn")
const EquipmentScript = preload("res://scripts/equipment.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const FullPath: String = "res://scenes/acts/act3/a3_l2_living_forest.tscn"
const RuntimePath: String = "res://scripts/acts/act3/living_forest_level.gd"
const Slots: Array[String] = ["jacket", "pants", "shoes", "weapon"]
const SourceIds: Array[String] = ["l2-threshold-stalker", "l2-promise-root", "l2-trunk-root", "l2-priority-root", "l2-priority-stalker", "l2-watched-root", "l2-watched-stalker", "l2-slit-root", "l2-slit-stalker"]
const SourceEntries: Array[int] = [0, 1, 2, 3, 3, 4, 4, 5, 5]
const EntryIds: Array[String] = ["vast-trunks", "root-promise", "trunk-court", "priority-court", "watched-clearing", "canopy-slit"]
const CheckpointIds: Array[String] = ["forest-threshold-entry", "root-promise-entry", "trunk-court-entry", "priority-court-entry", "watched-clearing-entry", "canopy-slit-entry"]
const EntryZ: Array[float] = [38.0, 26.0, 14.0, 1.0, -15.0, -31.0]
const FixedDeadlines: Array[String] = ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]
const PointTolerance: float = 0.005
const TimeEpsilon: float = 0.000001
const WarningBudgetS: float = 10.0
const GroupBudgetS: float = 90.0
const RouteBudgetS: float = 360.0
const Replan: String = "new_live_union_warning"

signal primary_deferred_settled

## TEST ONLY completed-native-tick observer. A deferred pause wake observes
## the published complete boundary without ticking or repairing any consumer.
class PostActorBarrier:
	extends Node
	signal observed
	var waiting: bool = false
	var _pause_wake_queued: bool = false

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000

	func _physics_process(_delta: float) -> void:
		_wake()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting and not _pause_wake_queued:
			_pause_wake_queued = true
			_wake_paused.call_deferred()

	func _wake_paused() -> void:
		_pause_wake_queued = false
		if is_inside_tree() and get_tree().paused:
			_wake()

	func _wake() -> void:
		if waiting:
			waiting = false
			observed.emit()

var _checks: int = 0
var _failures: int = 0
var _first_only: bool = false
var _kit_selector: String = ""
var _game: Node
var _hero: CinderPlayer
var _level: CinderLevel
var _scheduler: CinderThreatScheduler
var _floor: StaticBody3D
var _exit_cue: CinderInteractionCue
var _barrier: PostActorBarrier
var _old_hero: Variant
var _old_level: Variant
var _sources: Dictionary = {}
var _kit: Dictionary = {}
var _stats: Dictionary = {}
var _expected_hp: Dictionary = {}
var _hp_before: float = 0.0
var _events: Dictionary = {}
var _actions: Array[Dictionary] = []
var _checkpoints: Array[String] = []
var _death_events: Dictionary = {}
var _warnings: Dictionary = {}
var _used_warnings: Dictionary = {}
var _edge_rejoins: Dictionary = {}
var _root_approaches: Dictionary = {}
var _records: Dictionary = {}
var _phases: Dictionary = {}
var _active_travel: Dictionary = {}
var _group_ids: Array[String] = []
var _source_id: String = ""
var _current: Dictionary = {}
var _route_deadline: float = 0.0
var _group_deadline: float = 0.0
var _union_seen: bool = false
var _watched_observed: bool = false
var _topology: Array[int] = []


func _initialize() -> void:
	_barrier = PostActorBarrier.new()
	_barrier.name = "TestOnlyForestPostActorBarrier"
	root.add_child(_barrier)
	_run.call_deferred()


func _run() -> void:
	var reason: String = _options()
	if reason.is_empty(): reason = _select_kit()
	if reason.is_empty(): reason = await _prepare()
	if not _expect(reason.is_empty(), "public paused lab carryover enters the actual nine-source forest before physics", reason):
		await _dispose()
		_finish()
		return
	_game.call("resume_lab")
	_route_deadline = _scheduler.get_clock() + RouteBudgetS
	reason = await _tick_safe()
	var count: int = 1 if _first_only else EntryIds.size()
	for index: int in range(count):
		if not reason.is_empty(): break
		reason = await _travel_entry(index)
		if reason.is_empty(): reason = await _checkpoint_pair(index, false)
		if reason.is_empty(): reason = await _clear_entry(index)
		if not _expect(reason.is_empty(), "actual " + EntryIds[index] + " source(s) die to admitted ordinary-primary paths", reason): break
		if _first_only and reason.is_empty(): reason = await _checkpoint_pair(index, true)
	if reason.is_empty() and not _first_only:
		reason = await _contact_exit()
		_expect(reason.is_empty(), "nine actual deaths make one available contact exit reached by real ordinary dashes", reason)
	if reason.is_empty():
		reason = _final_error(count)
		_expect(reason.is_empty(), "selected route scope retains real action, checkpoint, tombstone and no-blast evidence", reason)
	if not reason.is_empty():
		if _failures == 0: _expect(false, "route stops on its first meaningful failure", reason)
		print("FIRST MEANINGFUL FAILURE; later route actions unattempted: ", reason, "; ", _diagnostic())
	await _dispose()
	_finish()


func _options() -> String:
	var route_selected: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument in ["--first-pocket", "--full-route"] and not route_selected:
			route_selected = true
			_first_only = argument == "--first-pocket"
		elif argument in ["--weak-damage", "--compound-extreme"] and _kit_selector.is_empty():
			_kit_selector = argument
		else:
			return "unsupported or repeated selector: " + argument
	return ""


func _select_kit() -> String:
	var catalogue: CinderEquipment = EquipmentScript.new() as CinderEquipment
	var choices: Dictionary = {}
	var ids: Dictionary = {}
	for slot: String in Slots:
		choices[slot] = catalogue.available_items(slot)
		for item: Dictionary in choices[slot]:
			var id: String = String(item.get("id", ""))
			if id.is_empty() or item.get("slot") != slot or item.get("perk_id") != null or not catalogue.is_implemented(id) or ids.has(id):
				return "actual public equipment catalogue identity/type differs: " + id
			ids[id] = true
	var kits: Array[Dictionary] = []
	for jacket: Dictionary in choices.jacket:
		for pants: Dictionary in choices.pants:
			for shoes: Dictionary in choices.shoes:
				for weapon: Dictionary in choices.weapon:
					var kit: Dictionary = {"jacket": jacket.id, "pants": pants.id, "shoes": shoes.id, "weapon": weapon.id}
					if not catalogue.restore(kit) or not catalogue.acceptance_errors().is_empty(): return "public model rejects legal carried kit"
					kits.append({"kit": kit, "stats": catalogue.resolved_stats()})
	if not _expect(ids.size() == 13 and kits.size() == 108, "live public model retains thirteen IDs and108 implemented static combinations"):
		return "public equipment cardinality drift"
	catalogue.reset_starter()
	_kit = catalogue.snapshot()
	_stats = catalogue.resolved_stats()
	if not _kit_selector.is_empty():
		var chosen: Dictionary = kits[0]
		for entry: Dictionary in kits:
			if _prefer(entry, chosen): chosen = entry
		_kit = chosen.kit.duplicate(true)
		_stats = chosen.stats.duplicate(true)
	print("ACTUAL CARRIED KIT: ", _kit_selector, " IDs=", _kit, " stats=", _stats)
	return ""


func _prefer(candidate: Dictionary, current: Dictionary) -> bool:
	var fields: Array[String] = ["primary_range", "dash_speed", "dash_distance"]
	var maximize: Array[bool] = [false, false, true]
	if _kit_selector == "--weak-damage":
		fields = ["primary_damage", "primary_range", "primary_cooldown"]
		maximize = [false, false, true]
	for index: int in range(fields.size()):
		var a: float = float(candidate.stats[fields[index]])
		var b: float = float(current.stats[fields[index]])
		if a != b: return a > b if maximize[index] else a < b
	return _kit_key(candidate.kit) < _kit_key(current.kit)


func _prepare() -> String:
	paused = false
	_game = MainScene.instantiate()
	root.add_child(_game)
	var lab_hero: CinderPlayer = _game.get("player") as CinderPlayer
	_old_hero = lab_hero
	_old_level = _game.get("active_level")
	if lab_hero == null or not _game.call("is_lab_level") or not get_nodes_in_group("enemies").is_empty(): return "actual enemy-free lab is unavailable"
	_game.call("open_bench")
	for slot: String in Slots:
		if not lab_hero.equip_item(String(_kit[slot])): return "public equip failed: " + slot
	if not paused or not _game.call("load_level_scene", FullPath): return "actual paused full-scene carryover failed"
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	if _hero == null or _level == null or _hero == lab_hero or _level.scene_file_path != FullPath or _level.get_script().resource_path != RuntimePath or not _level.contract_error().is_empty(): return "fresh actual full forest did not enter: " + (_level.contract_error() if _level != null else "missing level")
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	var public_sources: Variant = _level.get("sources")
	if _scheduler == null or not public_sources is Dictionary or not Codec.keys_error(public_sources, SourceIds).is_empty(): return "public nine-source map/Scheduler differs"
	_sources = public_sources.duplicate()
	var scenery: Node = _level.get("scenery") as Node
	_floor = scenery.get("floor_body") as StaticBody3D if scenery != null else null
	_exit_cue = _level.get("exit_cue") as CinderInteractionCue
	if _floor == null or _exit_cue == null or _hero.presentation_id != "act3_traveller" or not _exact(_hero.equipment.snapshot(), _kit) or not _exact(_hero.stats, _stats): return "actual shared traveller/floor/cue/carried kit differs"
	var solid: CollisionShape3D = _floor.get_node_or_null("Solid") as CollisionShape3D
	if solid == null or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Vector3(14, 1, 108): return "actual continuous14×108 box floor differs"
	var owners: Dictionary = {}
	for id: String in SourceIds:
		var source: Node3D = _sources[id] as Node3D
		if source == null or not source.has_method("state") or not source.is_in_group("enemies") or source.get_world_3d() != _hero.get_world_3d() or source.is_physics_processing(): return "actual configured dormant source differs: " + id
		if _is_root(id):
			if not source is CinderAct3RootLatcher: return "actual Root type differs: " + id
			var mechanism: CinderLaneMechanism = source.call("get_mechanism")
			owners[id + "/attack"] = mechanism
			mechanism.hit_resolved.connect(_on_root_contact.bind(id))
		else:
			if not source is CinderAct3SunboundStalker: return "actual Stalker type differs: " + id
			owners[id] = source
			source.connect("hit_resolved", _on_stalker_contact.bind(id))
		_expected_hp[id] = float((source.call("state") as Dictionary).hp)
		source.connect("died", _on_death.bind(id))
	_hero.world_action_executed.connect(_on_action)
	_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
	_hero.equipment_changed.connect(func(_id: String) -> void: _event("equipment"))
	_hero.died.connect(func() -> void: _event("hero_death"))
	_level.checkpoint_requested.connect(_on_checkpoint)
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _event("completion"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _event("exit"))
	_game.call("open_bench")
	_hero.shells = 0 # Public depleted-ammo fixture; natural reload/credit unchanged.
	_hp_before = _hero.hp
	_topology = _world_topology()
	await process_frame
	await process_frame
	var state: Dictionary = _level.call("state")
	var bindings: Dictionary = _level.call("scheduler_bindings")
	if not paused or _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0 or state.get("api_revision") != "act3-living-forest-level-1" or not String(state.get("configuration_error", "")).is_empty() or not state.entered.is_empty() or not state.cleared.is_empty() or _hero.shells != 0: return "paused setup advanced route history/clock or failed configuration"
	return "" if bindings.get("owners") == owners and bindings.get("actors", {}).get("hero") == _hero and bindings.get("floors", {}).get("forest-floor", {}).get("collision") == solid else "typed public scheduler owner/floor/Hero bindings differ"


func _travel_entry(index: int) -> String:
	var reason: String = await _corridor()
	if not reason.is_empty(): return reason
	for _step: int in range(45):
		var state: Dictionary = _level.call("state")
		if state.entered.size() >= index + 1:
			return "" if state.entered.size() == index + 1 and state.entered[index] == EntryIds[index] else "ordinary movement skipped/reordered a spatial entry"
		if _hero.global_position.z <= EntryZ[index]: reason = await _tick_safe()
		else: reason = await _route_dash(Vector3.FORWARD)
		if not reason.is_empty(): return reason
	return "ordinary entry route exceeded finite45 dash bound"


func _corridor() -> String:
	if float(_stats.dash_distance) > 4.75: return "actual full dash exceeds broad west corridor width"
	for _step: int in range(8):
		var ready: String = await _route_ready()
		if not ready.is_empty(): return ready
		var x: float = _hero.global_position.x
		if x >= -6.0 and x <= -1.25: return ""
		# A real knot return may stop immediately beside a fixed base. Choose
		# an ordinary full dash around that visible body before rejoining the
		# west corridor; a successful combat proof grants no navigation path.
		var side: Vector3 = Vector3.RIGHT if x < -6.0 else Vector3.LEFT
		var chosen := Vector3.ZERO
		for direction: Vector3 in [side, (side + Vector3.BACK).normalized(), (side + Vector3.FORWARD).normalized(), Vector3.BACK, Vector3.FORWARD]:
			var next: Vector3 = _hero.global_position + direction * float(_stats.dash_distance)
			if next.x < -6.0 or (next.x > x and x > -1.25): continue
			if _ordinary_navigation_clear(direction):
				chosen = direction
				break
		if chosen.is_zero_approx(): return "no actual swept ordinary detour reaches the west corridor"
		var reason: String = await _route_dash(chosen)
		if not reason.is_empty(): return reason
	return "real lateral dashes failed to reach open west corridor"


func _route_dash(direction: Vector3) -> String:
	var ready: String = await _route_ready()
	if not ready.is_empty(): return ready
	var origin: Vector3 = _hero.global_position
	return await _dash({"kind": "route_dash", "from": origin, "to": origin + direction.normalized() * float(_stats.dash_distance), "start_s": _hero.get_world_action_clock(), "end_s": _hero.get_world_action_clock() + float(_stats.dash_duration)})


func _route_ready() -> String:
	for _tick: int in range(_frame_limit(1.0)):
		var response: Dictionary = _hero.get_threat_response_state()
		if response.get("stable") == true and float(response.get("dash_cooldown_left_s", 1.0)) == 0.0:
			return ""
		var reason: String = await _tick_safe()
		if not reason.is_empty(): return reason
	return "actual stopped Hero dash readiness exceeded one second"


func _checkpoint_pair(index: int, after_clear: bool) -> String:
	_game.call("open_bench")
	await process_frame
	await process_frame
	if not paused: return "public entry pause did not settle"
	var pair: Dictionary = {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}
	if pair.hero.is_empty() or pair.level.is_empty(): return "actual entry pair capture rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	var encoded: String = ExactJson.stringify(pair)
	var decoded: Dictionary = ExactJson.parse(encoded)
	if encoded.is_empty() or not decoded.get("accepted", false) or not _exact(pair, decoded.get("value")): return "published exact JSON changed entry native values/types"
	var entries: Array = pair.level.local.route.entries
	if entries.size() != index + 1 or _checkpoints.size() != index + 1 or int(_events.get("wrong_checkpoint_kind", 0)) != 0 or pair.level.progress.checkpoint_id != CheckpointIds[index] or pair.level.progress.checkpoint_ids.size() != index + 1: return "actual entry/checkpoint signal/history prefix differs"
	for i: int in range(index + 1):
		var point: Vector3 = Codec.read_vector3(entries[i].hero_position)
		if entries[i].id != EntryIds[i] or point.z > EntryZ[i] or not _floor_hit(point) or _checkpoints[i] != CheckpointIds[i]: return "spatial entry lacks real completed/continuing ordinary dash floor crossing"
	if _actions.is_empty() or _hero.hp != _hp_before or (not after_clear and (_actions[-1] as Dictionary).get("kind") != "dash"): return "checkpoint not reached by actual ordinary movement without damage/heal"
	var error: String = _hero.snapshot_error(pair.hero)
	if error.is_empty(): error = _level.snapshot_error_with_player(pair.level, pair.hero)
	if not error.is_empty() or not _exact(pair, {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}): return "pure paused entry pair proof failed/mutated: " + error
	if after_clear and (pair.level.local.route.deaths.size() != 1 or not pair.level.local.sources[SourceIds[0]].actor.dead): return "first-pocket final pair lacks its true Stalker tombstone"
	_expect(true, "exact native entry pair " + CheckpointIds[index] + (" retains first genuine death" if after_clear else " binds its real spatial crossing"))
	_game.call("resume_lab")
	return ""


func _clear_entry(index: int) -> String:
	_group_ids.clear()
	for i: int in range(SourceIds.size()):
		if SourceEntries[i] <= index and not bool((_sources[SourceIds[i]].call("state") as Dictionary).dead): _group_ids.append(SourceIds[i])
	_group_deadline = minf(_route_deadline, _scheduler.get_clock() + GroupBudgetS)
	for _episode: int in range(32):
		if _group_dead(): return ""
		if _scheduler.get_clock() > _group_deadline: return "actual entry exceeded ninety-second bounded proof budget"
		var warning: Dictionary = await _next_warning()
		if warning.is_empty(): return "no fresh supported actual warning within ten seconds; " + _diagnostic()
		_source_id = warning.id
		_current = warning.record.duplicate(true)
		var error: String = _proof_error(warning)
		if not error.is_empty(): return error
		print("FOLLOW ACTUAL TYPED PROOF: source=", _source_id, " reservation=", _current.id, " start=", _current.start_s, " held=", _scheduler.reservations().size())
		for segment: Dictionary in warning.proof.path:
			if segment.kind in ["escape_dash", "positioning_dash"]:
				error = await _at_time(float(segment.start_s))
				if error.is_empty(): error = await _dash(segment)
			elif segment.kind == "ordinary_primary":
				error = await _primary(segment, warning.proof)
			else:
				error = await _hold(segment)
			if not error.is_empty(): break
		if error == Replan:
			print("REPLAN: yield only to a fresh genuine warning; cancelled proof grants no later action permission")
			continue
		if not error.is_empty(): return error
	return "actual group did not clear within32 admitted proof/replan episodes"


func _group_dead() -> bool:
	for id: String in _group_ids:
		if not bool((_sources[id].call("state") as Dictionary).dead): return false
	return true


func _pending() -> Dictionary:
	var chosen: Dictionary = {}
	for reservation_id: String in _warnings:
		var warning: Dictionary = _warnings[reservation_id]
		if _used_warnings.has(reservation_id) or not _group_ids.has(warning.id): continue
		var state: Dictionary = _sources[warning.id].call("state")
		var record: Dictionary = _scheduler.reservation_state(reservation_id)
		if state.dead or _reservation_id(state, warning.id) != reservation_id or record.is_empty() or record.state != "warning": continue
		if chosen.is_empty() or float(record.start_s) > float(chosen.record.start_s) or (float(record.start_s) == float(chosen.record.start_s) and String(warning.id) > String(chosen.id)):
			chosen = {"id": warning.id, "state": state, "record": record, "proof": warning.proof.duplicate(true)}
	return chosen


func _next_warning() -> Dictionary:
	var stop: float = minf(_group_deadline, _scheduler.get_clock() + WarningBudgetS)
	for _tick: int in range(_frame_limit(WarningBudgetS)):
		var warning: Dictionary = _pending()
		if not warning.is_empty():
			_used_warnings[warning.record.id] = true
			return warning
		if _scheduler.get_clock() > stop: break
		var rejoin: Dictionary = _edge_rejoin_candidate()
		if rejoin.is_empty(): rejoin = _root_approach_candidate()
		if not rejoin.is_empty():
			var rejoin_error: String = await _edge_rejoin(rejoin)
			if not rejoin_error.is_empty():
				_expect(false, "ordinary centerward rejoin preserves actual capsule/floor/timed union safety", rejoin_error)
				return {}
			continue
		var error: String = await _tick_safe()
		if not error.is_empty():
			_expect(false, "bounded actual warning wait retains safe actors and resources", error)
			return {}
	return {}


## One ordinary navigation choice after an outward physical attack was really
## declined. This pure public preflight creates neither attack nor permission
## from an old witness. The next attack must still be genuinely admitted.
func _edge_rejoin_candidate() -> Dictionary:
	var response: Dictionary = _hero.get_threat_response_state()
	if paused or response.get("stable") != true or float(response.get("dash_cooldown_left_s", 1.0)) != 0.0: return {}
	for id: String in _group_ids:
		if _is_root(id): continue
		var source: CharacterBody3D = _sources[id] as CharacterBody3D
		var state: Dictionary = source.call("state")
		if state.dead or state.phase != "idle" or state.reservation_id != "" or not source.velocity.is_zero_approx() or int(state.cycle) <= 0 or float(state.hp) != float(_expected_hp[id]) or float(state.hp) >= float(state.max_hp) or state.last_cancel_reason != "primary_stagger" or state.last_rejection != "Measured footprint loses continuous floor coverage": continue
		var key: String = "%s:%d" % [id, int(state.cycle)]
		var direction: Vector3 = Vector3.RIGHT if _hero.global_position.x < 0 else Vector3.LEFT
		var landing: Vector3 = _hero.global_position + direction * float(_stats.dash_distance)
		if _edge_rejoins.has(key) or absf(landing.x) >= absf(_hero.global_position.x): continue
		return {"id": id, "key": key, "direction": direction}
	return {}


## Fixed sources do not chase from their court to the entry line. When no
## actual lease exists, approach the still-living full-health bulb with
## at most three ordinary full dashes, using the same native navigation
## preflight below. This does not manufacture an attack or timed witness.
func _root_approach_candidate() -> Dictionary:
	var response: Dictionary = _hero.get_threat_response_state()
	if paused or not _scheduler.reservations().is_empty() or response.get("stable") != true or float(response.get("dash_cooldown_left_s", 1.0)) != 0.0: return {}
	for id: String in _group_ids:
		if not _is_root(id): continue
		var state: Dictionary = _sources[id].call("state")
		var steps: int = int(_root_approaches.get(id, 0))
		if state.dead or state.phase != "clear" or not _reservation_id(state, id).is_empty() or float(state.hp) != float(state.max_hp) or steps >= 3: continue
		var at: Vector3 = (_sources[id] as Node3D).global_position
		if _planar(at - _hero.global_position).length() <= 3.5: continue
		var toward: Vector3 = _planar(at - _hero.global_position)
		var entered: int = (_level.call("state") as Dictionary).entered.size()
		var chosen := Vector3.ZERO
		var nearest: float = toward.length()
		# Pure actual capsule sweeps reject the tempting straight route into
		# a visible base. Rank the remaining full ordinary dashes by progress
		# toward this same unleased bulb, without skipping the next entry.
		for direction: Vector3 in [toward.normalized(), Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3(1, 0, -1).normalized(), Vector3(-1, 0, -1).normalized(), Vector3(1, 0, 1).normalized(), Vector3(-1, 0, 1).normalized()]:
			var next: Vector3 = _hero.global_position + direction * float(_stats.dash_distance)
			var distance: float = _planar(at - next).length()
			if distance >= nearest or (entered < EntryZ.size() and next.z <= EntryZ[entered]): continue
			if not _ordinary_navigation_clear(direction): continue
			chosen = direction
			nearest = distance
		if not chosen.is_zero_approx():
			return {"id": id, "key": id + ":unleased-approach:" + str(steps), "direction": chosen, "root_approach": true}
	return {}


## Navigation is a separate player choice while no attack lease exists. This
## only queries the native body/floor; _edge_rejoin or _dash still executes and
## checks the actual completed action. No rejected sweep is made permissive.
func _ordinary_navigation_clear(direction: Vector3) -> bool:
	if paused or not _scheduler.reservations().is_empty() or not direction.is_finite() or direction.is_zero_approx(): return false
	var response: Dictionary = _level.call("combat_response", SourceIds[0])
	if response.get("actor") != _hero or response.get("stable") != true or float(response.get("dash_cooldown_left_s", 1.0)) != 0.0 or not response.get("floor_regions") is Array: return false
	var origin: Vector3 = _hero.global_position
	var motion: Vector3 = direction.normalized() * float(_stats.dash_distance)
	var landing: Vector3 = BodySweep.anchored_position(origin, motion, 1.0)
	var radius: float = CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
	var supported: bool = false
	for region: Dictionary in response.floor_regions:
		if not region.get("safe_rect") is Rect2: return false
		var safe: Rect2 = (region.safe_rect as Rect2).grow(-radius)
		if safe.has_point(Vector2(origin.x, origin.z)) and safe.has_point(Vector2(landing.x, landing.z)): supported = true
	if not supported: return false
	var sweep: Dictionary = BodySweep.sweep(_hero, _hero.global_transform, motion, response.floor_regions)
	return not sweep.has("error") and sweep.get("collided") == false and sweep.get("end") is Vector3 and _planar((sweep.end as Vector3) - landing).length() <= PointTolerance


func _navigation_guard(id: String, held: Array[Dictionary]) -> Dictionary:
	var response: Dictionary = _level.call("combat_response", id)
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var solid: CollisionShape3D = _floor.get_node_or_null("Solid") as CollisionShape3D
	if response.get("actor") != _hero or response.get("world_root") != _hero.get_parent() or not response.get("floor_regions") is Array or bindings.get("actors", {}).get("hero") != _hero or bindings.get("floors", {}).get("forest-floor", {}).get("collision") != solid or not is_instance_valid(solid) or not solid.shape is BoxShape3D or solid.disabled or _hero.collision_layer != 4 or _hero.collision_mask != 1: return {"error": "actual ordinary navigation/floor/Hero binding differs"}
	return {"clock_s": _scheduler.get_clock(), "hero_transform": _hero.global_transform, "response": response.duplicate(true), "source_state": _sources[id].call("state"), "bindings": bindings.duplicate(true), "floor": {"body": _floor, "solid": solid, "shape": solid.shape, "size": (solid.shape as BoxShape3D).size, "transform": solid.global_transform, "disabled": solid.disabled, "layer": _floor.collision_layer, "mask": _floor.collision_mask}, "held": held.duplicate(true), "events": _events.duplicate(true), "topology": _world_topology()}


func _edge_rejoin(candidate: Dictionary) -> String:
	var held: Array[Dictionary] = _scheduler.reservations()
	var guard: Dictionary = _navigation_guard(candidate.id, held)
	if guard.has("error"): return String(guard.error)
	var response: Dictionary = guard.response
	var now: float = float(guard.clock_s)
	if now != _hero.get_world_action_clock() or response.get("stable") != true or float(response.get("dash_cooldown_left_s", 1.0)) != 0.0 or not _exact(response.get("equipment_ids"), _kit) or not _exact(response.get("stats"), _stats): return "actual stopped centerward dash readiness/clock/kit differs"
	var origin: Vector3 = _hero.global_position
	var motion: Vector3 = candidate.direction * float(_stats.dash_distance)
	var landing: Vector3 = BodySweep.anchored_position(origin, motion, 1.0)
	var radius: float = CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
	var supported: bool = false
	for region: Dictionary in response.floor_regions:
		if region.get("collision") != guard.floor.solid or not region.get("safe_rect") is Rect2: return "ordinary rejoin floor region differs"
		var safe: Rect2 = (region.safe_rect as Rect2).grow(-radius)
		if safe.has_point(Vector2(origin.x, origin.z)) and safe.has_point(Vector2(landing.x, landing.z)): supported = true
	if not supported: return "ordinary centerward full dash lacks actual floor coverage"
	var sweep: Dictionary = BodySweep.sweep(_hero, _hero.global_transform, motion, response.floor_regions)
	if sweep.has("error") or sweep.get("collided") != false or not sweep.get("end") is Vector3 or not sweep.get("travel") is Vector3: return "ordinary centerward capsule sweep rejected: " + String(sweep.get("error", "actual scenery collision"))
	if _planar((sweep.end as Vector3) - landing).length() > PointTolerance or absf(_planar(sweep.travel).length() - float(_stats.dash_distance)) > PointTolerance: return "actual capsule sweep shortens centerward dash"
	var duration: float = float(_stats.dash_duration)
	var steps: int = ceili(duration / _tick_s())
	var dash_end: float = now + float(steps) * _tick_s()
	var ready_until: float = now + maxf(float(_stats.dash_cooldown), float(steps) * _tick_s()) + 2.0 * _tick_s()
	if ready_until > _group_deadline or ready_until > _route_deadline: return "ordinary centerward rejoin exceeds finite proof-wait budget"
	var path: Array[Dictionary] = []
	for index: int in range(steps):
		path.append({"from": BodySweep.anchored_position(origin, motion, minf(float(index) * _tick_s(), duration) / duration), "to": BodySweep.anchored_position(origin, motion, minf(float(index + 1) * _tick_s(), duration) / duration), "start_s": now + float(index) * _tick_s(), "end_s": now + float(index + 1) * _tick_s()})
	path.append({"from": landing, "to": landing, "start_s": dash_end, "end_s": ready_until})
	for record: Dictionary in held:
		if Geometry.timed_path_hits(record.geometry, path, float(record.active_from_s), float(record.active_until_s), radius): return "ordinary centerward rejoin/readiness intersects actual held union"
		if maxf(now, float(record.active_from_s)) <= minf(dash_end + 2.0 * _tick_s(), float(record.active_until_s)) and Geometry.segment_hits(record.geometry, origin, landing, radius): return "ordinary centerward dash envelope intersects held active footprint"
	if not _exact(guard, _navigation_guard(candidate.id, _scheduler.reservations())): return "actual pure rejoin preflight changed clock/pose/floor/held geometry"
	_edge_rejoins[candidate.key] = true
	if candidate.get("root_approach", false): _root_approaches[candidate.id] = int(_root_approaches.get(candidate.id, 0)) + 1
	_current.clear() # Declined/cancelled attack grants no future path permission.
	print("ORDINARY UNLEASED COURT NAVIGATION: ", candidate.id, " from=", origin, " to=", landing, " held=", held.size())
	return await _dash({"kind": "route_dash", "from": origin, "to": landing, "start_s": now, "end_s": now + duration})


func _proof_error(warning: Dictionary) -> String:
	var proof: Dictionary = warning.proof
	var record: Dictionary = warning.record
	var response: Dictionary = _level.call("combat_response", warning.id)
	if record.get("armed") != true or record.source_instance_id != _owner(warning.id).get_instance_id() or response.get("actor") != _hero or not _exact(response.get("equipment_ids"), _kit) or not _exact(response.get("stats"), _stats) or proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not proof.get("path") is Array or proof.path.is_empty(): return "actual typed warning lacks ordinary no-ammo/no-immunity bound proof"
	if (_is_root(warning.id) and record.geometry.get("kind") != "crescent") or (not _is_root(warning.id) and record.get("adapter", {}).get("kind") != "lunge"): return "actual Root crescent/Stalker physical adapter kind differs"
	var path: Array[Dictionary] = []
	var previous: Dictionary = {}
	var escapes: int = 0
	var primaries: int = 0
	for value: Variant in proof.path:
		if not value is Dictionary or not Geometry.finite_vector(value.get("from")) or not Geometry.finite_vector(value.get("to")) or not Geometry.finite_number(value.get("start_s")) or not Geometry.finite_number(value.get("end_s")): return "native proof path is malformed"
		var segment: Dictionary = value
		if segment.kind not in ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"] or float(segment.end_s) < float(segment.start_s) or float(segment.start_s) < float(record.start_s) - TimeEpsilon or float(segment.end_s) > float(record.recovery_until_s): return "native proof path kind/timing unsupported"
		if not previous.is_empty() and (absf(float(previous.end_s) - float(segment.start_s)) > TimeEpsilon or (previous.to as Vector3).distance_to(segment.from) > PointTolerance): return "native proof path is discontinuous"
		if not _floor_hit(segment.from) or not _floor_hit(segment.to): return "native proof endpoints lack actual authored floor support"
		escapes += 1 if segment.kind == "escape_dash" else 0
		primaries += 1 if segment.kind == "ordinary_primary" else 0
		path.append(segment)
		previous = segment
	if escapes != 1 or primaries != 1 or (path[0].from as Vector3).distance_to(_hero.global_position) > PointTolerance or float(proof.primary_time_s) <= float(record.active_until_s) or float(proof.response_complete_s) > float(record.recovery_until_s): return "live proof origin/positive ordinary-primary recovery opening differs"
	for held: Dictionary in _scheduler.reservations():
		if Geometry.timed_path_hits(held.geometry, path, float(held.active_from_s), float(held.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN): return "selected native path intersects a held union footprint"
	return ""


func _hold(segment: Dictionary) -> String:
	if not _current.is_empty() and not _current_live(): return Replan
	if not _pending().is_empty(): return Replan
	if segment.from != segment.to or _hero.global_position.distance_to(segment.from) > PointTolerance: return "actual stationary wait origin differs from published path"
	for _tick: int in range(_frame_limit(GroupBudgetS)):
		if not _current.is_empty() and not _current_live(): return Replan
		if not _pending().is_empty(): return Replan
		if _scheduler.get_clock() >= float(segment.end_s): return ""
		var error: String = await _tick_safe()
		if not error.is_empty(): return error
		if _hero.global_position.distance_to(segment.from) > PointTolerance: return "Hero drifted during genuine stationary proof hold"
	return "stationary wait exceeded finite tick bound"


func _at_time(target: float) -> String:
	if not is_finite(target) or target > _route_deadline: return "nonfinite/out-of-budget action deadline"
	for _tick: int in range(_frame_limit(GroupBudgetS)):
		if not _current.is_empty() and not _current_live(): return Replan
		if not _pending().is_empty(): return Replan
		var now: float = _hero.get_world_action_clock()
		if now >= target: return "" if now - target <= _tick_s() + TimeEpsilon else "action missed first available native fixed tick: target=%s actual=%s" % [target, now]
		var error: String = await _tick_safe()
		if not error.is_empty(): return error
	return "scheduled action exceeded finite tick bound"


func _dash(segment: Dictionary) -> String:
	if _hero.global_position.distance_to(segment.from) > PointTolerance: return "actual dash origin differs from ordinary path"
	var response: Dictionary = _hero.get_threat_response_state()
	if response.get("stable") != true or float(response.get("dash_cooldown_left_s", 1.0)) != 0.0 or float(response.get("motion", {}).get("dash_left_s", 1.0)) != 0.0: return "actual dash would overlap or queue"
	var direction: Vector3 = _planar(segment.to - segment.from)
	if direction.is_zero_approx(): return "ordinary dash direction empty"
	var sequence: int = _last_sequence()
	var started: float = _hero.get_world_action_clock()
	if not _hero.request_dash(direction.normalized()): return "actual public dash rejected its ready path"
	var actions: Array[Dictionary] = []
	for _tick: int in range(_frame_limit(float(_stats.dash_duration) + 0.25)):
		actions = _hero.get_world_action_records(sequence)
		if not actions.is_empty(): break
		var error: String = await _tick_safe()
		if not error.is_empty(): return error
	if actions.size() != 1: return "dash did not publish one completed real world action"
	var action: Dictionary = actions[0]
	if action.get("kind") != "dash" or action.get("blocked") != false or action.get("collision_shortened") != false or not _exact(action.get("equipment_ids"), _kit) or not _exact(action.get("resolved_stats"), _stats): return "ordinary dash blocked/shortened/changed kit"
	if (action.world_origin as Vector3).distance_to(segment.from) > PointTolerance or _planar((action.landing as Vector3) - (segment.to as Vector3)).length() > PointTolerance or (action.landing as Vector3).distance_to(_hero.global_position) > PointTolerance or absf(float(action.distance) - float(_stats.dash_distance)) > PointTolerance: return "completed origin/landing/distance differs by more than.005WU"
	if float(action.started_at_s) != started or absf(float(action.completed_at_s) - started - float(_stats.dash_duration)) > _tick_s() + TimeEpsilon or float(action.completed_at_s) > float(segment.end_s) + 2.0 * _tick_s() + TimeEpsilon: return "completed dash exceeds native fixed-tick path timing"
	var previous_time: float = -1.0
	var previous_progress: float = -1.0
	var unit: Vector3 = direction.normalized()
	for sample: Dictionary in action.path:
		var point: Vector3 = sample.position
		var progress: float = _planar(point - (segment.from as Vector3)).dot(unit)
		var nearest: Vector3 = segment.from + unit * clampf(progress, 0, direction.length())
		if float(sample.time_s) < previous_time or progress < previous_progress - PointTolerance or _planar(point - nearest).length() > PointTolerance or not _floor_hit(point): return "real dash samples nonmonotone/off-path/off-floor"
		previous_time = float(sample.time_s)
		previous_progress = progress
	return ""


func _primary(segment: Dictionary, proof: Dictionary) -> String:
	var error: String = await _at_time(float(proof.primary_time_s))
	if not error.is_empty(): return error
	var source: Node3D = _sources[_source_id]
	var state: Dictionary = source.call("state")
	var record: Dictionary = _scheduler.reservation_state(String(_current.id))
	if record.is_empty() or record.state != "recovery" or _reservation_id(state, _source_id) != _current.id or state.dead or state.phase != "recovery" or _hero.global_position.distance_to(proof.attack_position) > PointTolerance or segment.from != segment.to: return "ordinary primary lacks its still-live actual recovery lease/return position"
	if _is_root(_source_id):
		if state.get("knot_open") != true or source.global_position != record.geometry.origin: return "actual fixed low recovery knot is closed/moved"
	else:
		if float(_active_travel.get(_current.id, 0.0)) <= 0.1 or source.global_position.distance_to(record.adapter.planned_endpoint) > PointTolerance or not (source as CharacterBody3D).velocity.is_zero_approx(): return "actual moving source lacks stopped advertised recovery endpoint"
	for phase: String in ["warning", "lock", "active", "recovery"]:
		if not (_phases.get(_current.id, {}) as Dictionary).has(phase): return "actual source/common cue omitted observed phase: " + phase
	var response: Dictionary = _hero.get_threat_response_state()
	if response.get("stable") != true or float(response.get("primary_cooldown_left_s", 1.0)) != 0.0: return "ordinary recovery primary is not ready/stable"
	_prepare_primary_resources()
	var before: Dictionary = _expected_hp.duplicate(true)
	var sequence: int = _last_sequence()
	var hits: int = _hero.slash(_planar(source.global_position - _hero.global_position).normalized())
	var changed: int = 0
	var terminal_cleanup: bool = false
	for id: String in SourceIds:
		var actual: float = float((_sources[id].call("state") as Dictionary).hp)
		if actual != float(before[id]):
			if actual != maxf(float(before[id]) - float(_stats.primary_damage), 0.0): return "real slash applies unexpected typed source HP damage"
			changed += 1
			terminal_cleanup = terminal_cleanup or actual == 0.0
		_expected_hp[id] = actual
	var actions: Array[Dictionary] = _hero.get_world_action_records(sequence)
	if hits < 1 or changed != hits or float(_expected_hp[_source_id]) >= float(before[_source_id]) or actions.size() != 1 or actions[0].get("kind") != "primary" or actions[0].get("hits") != hits or float(actions[0].get("damage", 0.0)) != float(_stats.primary_damage) or not _exact(actions[0].get("equipment_ids"), _kit): return "real primary failed matching target HP/action/hit publication"
	print("ACTUAL PRIMARY: source=", _source_id, " hits=", hits, " damage=", _stats.primary_damage, " targetHP=", before[_source_id], "→", _expected_hp[_source_id])
	_current.clear()
	if terminal_cleanup:
		# Actors remove group/layer authority synchronously and defer their
		# shape flag safely. A graphical post-draw attack can precede the next
		# message flush; observe that FIFO boundary before asserting the flag.
		primary_deferred_settled.emit.call_deferred()
		await primary_deferred_settled
		error = _live_error()
		if not error.is_empty(): return error
	return await _hold(segment)


func _tick_safe() -> String:
	if not is_instance_valid(_barrier) or _barrier.get_parent() != root or _barrier.process_physics_priority != 1000 or not _barrier.is_physics_processing(): return "test-only post-consumer native barrier unavailable"
	if paused:
		var clock: float = _scheduler.get_clock()
		var hero_clock: float = _hero.get_world_action_clock()
		await process_frame
		if _scheduler.get_clock() != clock or _hero.get_world_action_clock() != hero_clock: return "already-paused observation advanced native clocks"
	else:
		_barrier.waiting = true
		await _barrier.observed
	return _live_error()


func _live_error() -> String:
	if not is_instance_valid(_hero) or not is_instance_valid(_level) or not is_instance_valid(_scheduler) or _hero.dead or _hero.hp != _hp_before or _scheduler.get_clock() > _route_deadline or int(_events.get("contact", 0)) != 0: return "actual route lost actor, took/healed damage or exceeded finite budget"
	var route: Dictionary = _level.call("state")
	if not String(route.configuration_error).is_empty() or not _exact(_hero.equipment.snapshot(), _kit) or int(_events.get("equipment", 0)) != 0 or int(_events.get("fired_blast", 0)) != 0 or _world_topology() != _topology or not _floor_hit(_hero.global_position): return "actual runtime/kit/topology/floor changed"
	if route.entries.size() >= 5 and not _watched_observed:
		_watched_observed = true
		if route.watched_preview.get("clock_s") != route.entries[4].clock_s or route.sun_elapsed_s != 10.0 or route.sun_stage != "preview": return "watched spatial entry did not begin genuine3second preview/1second lock"
	for id: String in SourceIds:
		var state: Dictionary = _sources[id].call("state")
		if float(state.hp) != float(_expected_hp[id]): return "source HP changed outside real primary: " + id
		# Native Root's first admission intentionally suppresses its wrapper
		# callback. Poll the actual public post-consumer state/proof instead.
		if state.phase == "warning" and state.get("proof", {}).get("accepted") == true:
			var reservation_id: String = _reservation_id(state, id)
			if not reservation_id.is_empty() and not _warnings.has(reservation_id): _warnings[reservation_id] = {"id": id, "proof": state.proof.duplicate(true)}
		if state.dead:
			var death_error: String = _tombstone_error(id)
			if not death_error.is_empty(): return death_error
	var held: Array[Dictionary] = _scheduler.reservations()
	if held.size() >= 2: _union_seen = true
	for record: Dictionary in held:
		var id: String = _source_for_record(record)
		if id.is_empty(): return "reservation owner not one of nine actual typed nodes/mechanisms"
		if not _records.has(record.id):
			_records[record.id] = _fixed_record(record)
			_phases[record.id] = {}
			_active_travel[record.id] = 0.0
		if not _exact(_records[record.id], _fixed_record(record)): return "held typed geometry/source/adapter/deadlines retargeted"
		var state: Dictionary = _sources[id].call("state")
		var cue: CinderThreatCue = _cue(id)
		var presentation: Dictionary = cue.state()
		if _reservation_id(state, id) != record.id or state.phase != record.state or presentation.get("phase") != record.state or not _exact(presentation.get("geometry"), record.geometry) or presentation.get("source_position") != (_sources[id] as Node3D).global_position or presentation.get("source_visible") != true: return "actual typed source/common footprint/cue phase differs: " + id
		_phases[record.id][record.state] = true
		if _is_root(id):
			if (_sources[id] as Node3D).global_position != record.geometry.origin or not _exact(state.geometry, record.geometry): return "rooted source/held native crescent moved"
		else:
			var source: CharacterBody3D = _sources[id] as CharacterBody3D
			if record.state == "active": _active_travel[record.id] = maxf(float(_active_travel[record.id]), source.global_position.distance_to(record.adapter.start))
			if record.state == "recovery" and (source.global_position.distance_to(record.adapter.planned_endpoint) > PointTolerance or not source.velocity.is_zero_approx()): return "physical Stalker did not stop at advertised recovery endpoint"
	return ""


func _contact_exit() -> String:
	var route: Dictionary = _level.call("state")
	if not _level.is_completed() or int(_events.get("completion", 0)) != 1 or route.exit_state != "available" or not _scheduler.reservations().is_empty() or _exit_cue.state().get("trigger") != "contact" or _exit_cue.state().get("state") != "available": return "nine genuine deaths failed distinct available contact cue/completion"
	var marker: Marker3D = _level.get_node("DryThreshold") as Marker3D
	for _step: int in range(14):
		if (_level.call("state") as Dictionary).exit_state == "spent": break
		var error: String = await _route_dash(_planar(marker.global_position - _hero.global_position).normalized())
		if not error.is_empty(): return error
	# Actual contact dispatch is deferred after the completed level tick.
	await process_frame
	route = _level.call("state")
	if route.exit_state != "spent" or int(_events.get("exit", 0)) != 1 or route.contact.is_empty() or _exit_cue.state().get("state") != "spent": return "ordinary full dashes did not dispatch actual contact exactly once"
	var at: Vector3 = Codec.read_vector3(route.contact.hero_position)
	if not Rect2(-1.2, -47.65, 2.4, 1.3).has_point(Vector2(at.x, at.z)) or absf(at.y) > 0.2 or not _floor_hit(at): return "contact history lacks actual feet inside authored dry threshold"
	var contact: Dictionary = route.contact.duplicate(true)
	var error: String = await _route_dash(Vector3.BACK)
	if error.is_empty(): error = await _route_dash(Vector3.FORWARD)
	if not error.is_empty(): return error
	return "" if int(_events.get("exit", 0)) == 1 and int(_events.get("completion", 0)) == 1 and _exact((_level.call("state") as Dictionary).contact, contact) else "return contact duplicated progress/replaced spent sample"


func _tombstone_error(id: String) -> String:
	var source: Node3D = _sources[id]
	var state: Dictionary = source.call("state")
	var body: CollisionShape3D = source.get_node("BodyCollision") as CollisionShape3D
	if not state.dead or float(state.hp) != 0.0 or state.phase != "defeated" or not _reservation_id(state, id).is_empty() or source.is_in_group("enemies") or source.get("collision_layer") != 0 or source.get("collision_mask") != 0 or not body.disabled or int(_death_events.get(id, 0)) != 1: return "retained real tombstone/group/collision/death/lease differs: " + id
	if _is_root(id):
		if not source.visible or state.mechanism.status != "cancelled" or state.mechanism.last_cancel_reason != "source_defeated": return "real severed Root lost retained spent presentation/cancellation"
	elif source.visible or not (source as CharacterBody3D).velocity.is_zero_approx(): return "real Stalker tombstone visibility/velocity differs"
	var route: Dictionary = _level.call("state")
	return "" if route.deaths.has(id) and Codec.read_vector3(route.deaths[id].source_position) == source.global_position else "actual death route lost native tombstone pose: " + id


func _final_error(count: int) -> String:
	var state: Dictionary = _level.call("state")
	var expected: int = 1 if _first_only else SourceIds.size()
	if state.entered.size() != count or state.cleared.size() != expected or _checkpoints.size() != count: return "selected real entry/death/checkpoint scope incomplete"
	for id: String in state.cleared:
		var error: String = _tombstone_error(id)
		if not error.is_empty(): return error
	var stored: Array[Dictionary] = _hero.get_world_action_records()
	if _actions.is_empty() or not _exact(_actions.slice(maxi(0, _actions.size() - stored.size())), stored): return "full actual action event history/public bounded tail differs"
	for action: Dictionary in _actions:
		if action.get("kind") not in ["dash", "primary"] or not _exact(action.get("equipment_ids"), _kit): return "route used unsupported action/changed equipment"
	if _hero.hp != _hp_before or _hero.dead or int(_events.get("contact", 0)) != 0 or int(_events.get("fired_blast", 0)) != 0 or int(_game.get("cores")) != 0 or int(_game.get("kills")) != 0 or not get_nodes_in_group("lab_weapons").is_empty() or not get_nodes_in_group("practice_targets").is_empty(): return "route damage/heal/blast/pickup/unrelated reward present"
	if _first_only:
		return "" if not _level.is_completed() and int(_events.get("completion", 0)) == 0 and int(_events.get("exit", 0)) == 0 else "first-pocket falsely completed/exited full level"
	if not _watched_observed or not _union_seen or not _level.is_completed() or int(_events.get("completion", 0)) != 1 or int(_events.get("exit", 0)) != 1 or not _scheduler.reservations().is_empty() or not get_nodes_in_group("enemies").is_empty(): return "full route lacks actual watched preview/mixed union/deaths/single contact/cleanup"
	return ""


func _owner(id: String) -> Node3D:
	return _sources[id].call("get_mechanism") as Node3D if _is_root(id) else _sources[id] as Node3D


func _cue(id: String) -> CinderThreatCue:
	return (_owner(id) as CinderLaneMechanism).get_cue() if _is_root(id) else _sources[id].call("get_cue") as CinderThreatCue


func _is_root(id: String) -> bool:
	return id.ends_with("-root")


func _reservation_id(state: Dictionary, id: String) -> String:
	return String(state.get("mechanism", {}).get("reservation_id", "")) if _is_root(id) else String(state.get("reservation_id", ""))


func _source_for_record(record: Dictionary) -> String:
	for id: String in SourceIds:
		if record.get("source_instance_id") == _owner(id).get_instance_id(): return id
	return ""


func _fixed_record(record: Dictionary) -> Dictionary:
	# The moving adapter publishes its actual current position/velocity and
	# source_position every tick. Commitment is its immutable native start,
	# endpoint/direction/body/configuration, rather than those physical samples.
	var fixed: Dictionary = {"id": record.id, "source_instance_id": record.source_instance_id, "geometry": record.geometry.duplicate(true), "armed": record.armed}
	if record.get("adapter", {}).get("kind") == "lunge":
		var adapter: Dictionary = {}
		for key: String in ["kind", "start", "planned_endpoint", "direction", "speed", "distance", "duration_s", "damage_radius", "body_signature", "body_collision_path"]:
			adapter[key] = record.adapter[key]
		fixed["adapter"] = adapter
	else:
		fixed["source_position"] = record.source_position
	for key: String in FixedDeadlines: fixed[key] = record[key]
	return fixed


func _current_live() -> bool:
	if _current.is_empty() or _source_id.is_empty(): return false
	var state: Dictionary = _sources[_source_id].call("state")
	var record: Dictionary = _scheduler.reservation_state(String(_current.id))
	return not state.dead and not record.is_empty() and _reservation_id(state, _source_id) == _current.id and _exact(_fixed_record(record), _fixed_record(_current))


func _floor_hit(point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.25, point - Vector3.UP * 0.25, 1)
	var hit: Dictionary = _hero.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == _floor


func _world_topology() -> Array[int]:
	var result: Array[int] = []
	var world: Node = _game.get("world") as Node
	if world != null:
		for child: Node in world.get_children(): result.append(child.get_instance_id())
	return result


func _on_stalker_contact(_result: Dictionary, _id: String) -> void:
	_event("contact")


func _on_root_contact(_hero_id: String, _cycle: int, _result: Dictionary, _id: String) -> void:
	_event("contact")


func _on_death(_where: Vector3, id: String) -> void:
	_death_events[id] = int(_death_events.get(id, 0)) + 1
	_event("death")


func _on_checkpoint(_level_id: String, checkpoint: String, kind: String) -> void:
	_checkpoints.append(checkpoint)
	_event("checkpoint")
	if kind != "encounter": _event("wrong_checkpoint_kind")


func _on_action(record: Dictionary) -> void:
	_actions.append(record.duplicate(true))
	_event("world_action")


func _event(kind: String) -> void:
	_events[kind] = int(_events.get(kind, 0)) + 1


func _last_sequence() -> int:
	var history: Array[Dictionary] = _hero.get_world_action_records()
	return int(history[-1].sequence) if not history.is_empty() else 0


func _kit_key(kit: Dictionary) -> String:
	return "%s|%s|%s|%s" % [kit.jacket, kit.pants, kit.shoes, kit.weapon]


func _planar(point: Vector3) -> Vector3:
	return Vector3(point.x, 0, point.z)


func _tick_s() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


func _frame_limit(seconds: float) -> int:
	return ceili(seconds * float(Engine.physics_ticks_per_second)) + 8


func _diagnostic() -> String:
	return str({"source_id": _source_id, "clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else -1.0, "actual_route": _level.call("state") if is_instance_valid(_level) else {}, "hero": _hero.get_threat_response_state() if is_instance_valid(_hero) else {}, "current_record": _current, "events": _events, "used_warnings": _used_warnings.keys()})


## Owned no-ammo mechanic fixture. Production subclasses leave naturally
## earned ammo untouched while retaining the same no-blast action assertions.
func _prepare_primary_resources() -> void:
	_hero.shells = 0


func _dispose() -> void:
	var refs: Array = [_game, _hero, _level, _scheduler, _old_hero, _old_level, _barrier]
	refs.append_array(_sources.values())
	if is_instance_valid(_barrier):
		_barrier.waiting = false
		if _barrier.get_parent() == root: root.remove_child(_barrier)
		_barrier.queue_free()
	if is_instance_valid(_game) and is_instance_valid(_hero): _game.call("open_bench")
	if is_instance_valid(_level): _level.exit_level()
	_expect(not is_instance_valid(_scheduler) or _scheduler.reservations().is_empty(), "actual public full-level exit releases all typed source leases")
	if is_instance_valid(_game):
		if _game.get_parent() == root: root.remove_child(_game)
		_game.queue_free()
	paused = false
	for _tick: int in range(4): await process_frame
	await create_timer(0.15, true, false, true).timeout
	var clean: bool = true
	for node: Variant in refs: clean = clean and not is_instance_valid(node)
	for group: String in ["enemies", "practice_targets", "lab_weapons", "required_cues"]: clean = clean and get_nodes_in_group(group).is_empty()
	_expect(clean, "actual whole forest/lab/source/cue lifecycle frees without residual groups after finite audio drain")
	_game = null
	_hero = null
	_level = null
	_scheduler = null
	_sources.clear()
	_barrier = null
	_old_hero = null
	_old_level = null


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


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok: print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok


func _finish() -> void:
	print("Living Forest actual route: %d checks, %d failures; first_only=%s kit=%s" % [_checks, _failures, _first_only, _kit_selector])
	quit(0 if _failures == 0 else 1)
