extends SceneTree
## Actual authored A3-L1 consumer: public lab carryover, ordinary world paths,
## five real source clears, coherent exact paired retry and actor contact exit.
## This is automated mechanic evidence, not native gestures, human balance,
## art acceptance or production registry/campaign acceptance. No HP is written.
## Optional portrait PNGs preserve the same actual driver and observed states.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const EquipmentScript: GDScript = preload("res://scripts/equipment.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const BodySweep: GDScript = preload("res://scripts/combat/body_sweep.gd")
const FullPath: String = "res://scenes/acts/act3/a3_l1.tscn"
const RuntimePath: String = "res://scripts/acts/act3/twin_suns_level.gd"
# Preserve the earlier unframed first-pocket PNGs in their original folder.
const CapturePath: String = "res://captures/act3/twin-suns-authored/shared18-contact-and-body"
const Slots: Array[String] = ["jacket", "pants", "shoes", "weapon"]
const SourceIds: Array[String] = ["l1-flank-stalker", "l1-approach-stalker", "l1-crossing-west", "l1-crossing-east", "l1-departure-stalker"]
const PocketIds: Array[String] = ["useful-flank", "two-approaches", "crossing-shadow", "pillars-recede"]
const CheckpointIds: Array[String] = ["useful-flank-entry", "two-approaches-entry", "crossing-shadow-entry", "departure-entry"]
const EntryZ: Array[float] = [30.0, 15.0, -6.0, -29.0]
const FixedDeadlines: Array[String] = ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]
const PointTolerance: float = 0.005
const TimeEpsilon: float = 0.000001
const WarningBudgetS: float = 8.0
const RouteBudgetS: float = 180.0
const GroupBudgetS: float = 60.0
const Replan: String = "new_union_warning"


## TEST ONLY observation node. Normal wakes follow every actual actor's fixed
## callback; synchronous shell pauses can skip this later pausable callback.
## The deferred pause wake observes the completed boundary without advancing
## actors or inventing a checkpoint. Existing save/capture settling stays owned
## by the fixture's ordinary process-frame barriers.
class PostActorPhysicsBarrier:
	extends Node
	signal observed(boundary: String)
	var waiting: bool = false
	var _pause_wake_queued: bool = false

	func _physics_process(_delta: float) -> void:
		_wake("post_actor_physics")

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting and not _pause_wake_queued:
			_pause_wake_queued = true
			_wake_paused.call_deferred()

	func _wake_paused() -> void:
		_pause_wake_queued = false
		if is_inside_tree() and not is_queued_for_deletion() and get_tree().paused:
			_wake("paused_deferred_boundary")

	func _wake(boundary: String) -> void:
		if not waiting:
			return
		waiting = false
		observed.emit(boundary)

var _checks: int = 0
var _failures: int = 0
var _route_selector: String = ""
var _kit_selector: String = ""
var _capture_portrait: bool = false
var _captured: Dictionary = {}
var _side: int = -1
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _scheduler: CinderThreatScheduler
var _floor: StaticBody3D
var _motifs: Node3D
var _exit_cue: CinderInteractionCue
var _old_hero: Variant
var _old_level: Variant
var _sources: Dictionary = {}
var _kit: Dictionary = {}
var _stats: Dictionary = {}
var _expected_hp: Dictionary = {}
var _events: Dictionary = {}
var _actions: Array[Dictionary] = []
var _checkpoints: Array[String] = []
var _death_events: Dictionary = {}
var _warnings: Dictionary = {}
var _used_warnings: Dictionary = {}
var _edge_rejoins: Dictionary = {}
var _records: Dictionary = {}
var _phases: Dictionary = {}
var _active_travel: Dictionary = {}
var _current: Dictionary = {}
var _group_ids: Array[String] = []
var _source_id: String = ""
var _hp_before: float = 0.0
var _route_deadline: float = 0.0
var _group_deadline: float = 0.0
var _roundtrip_done: bool = false
var _fresh_partial_done: bool = false
var _union_seen: bool = false
var _crossing_primary_deferred: bool = false
var _topology: Array[int] = []
# Diagnostic only: two selected gear cases retain at most six wait observations.
var _tick_trace: Array[Dictionary] = []
var _trace_path_segment: Dictionary = {}
var _tick_barrier: PostActorPhysicsBarrier


func _initialize() -> void:
	_tick_barrier = PostActorPhysicsBarrier.new()
	_tick_barrier.name = "TestOnlyPostActorPhysicsBarrier"
	_tick_barrier.process_mode = Node.PROCESS_MODE_PAUSABLE
	_tick_barrier.process_physics_priority = 1000
	root.add_child(_tick_barrier)
	_run.call_deferred()


func _run() -> void:
	var reason: String = _options()
	if reason.is_empty():
		reason = _select_kit()
	if reason.is_empty():
		reason = await _prepare()
	if not _expect(reason.is_empty(), "actual public-model carryover enters the authored full scene before its first tick", reason):
		await _dispose()
		_finish()
		return
	_game.call("resume_lab")
	_route_deadline = _scheduler.get_clock() + RouteBudgetS
	reason = await _tick_safe()
	if reason.is_empty():
		reason = await _capture("arrival")
	if reason.is_empty():
		reason = await _scenic_detour()
	var pocket_count: int = 1 if _route_selector == "--first-pocket-only" else (2 if _route_selector == "--east-approach-only" else 4)
	for pocket: int in range(pocket_count):
		if not reason.is_empty():
			break
		reason = await _travel_entry(pocket)
		if reason.is_empty():
			reason = await _checkpoint_pair(pocket)
		if reason.is_empty():
			reason = await _clear_pocket(pocket)
		if not _expect(reason.is_empty(), "actual pocket " + PocketIds[pocket] + " clears its retained source(s) using ordinary primary", reason):
			break
	if reason.is_empty() and _route_selector == "--east-approach-only":
		reason = await _corridor()
		if reason.is_empty():
			reason = await _travel_z(4.0)
		if reason.is_empty():
			reason = await _rejoin()
		if reason.is_empty() and (_hero.global_position.z >= 5.0 or absf(_hero.global_position.x) > 1.35 or not _floor_hit(_hero.global_position)):
			reason = "east ordinary path failed to pass the z8 trunk and rejoin the actual solid shelf"
		_expect(reason.is_empty(), "east approach clears real encounters and rejoins beyond the actual z8 trunk", reason)
	elif reason.is_empty() and _route_selector.is_empty():
		reason = await _contact_exit()
		_expect(reason.is_empty(), "all five real tombstones lead to one actual hero contact departure", reason)
	if reason.is_empty():
		reason = _final_error(pocket_count)
		_expect(reason.is_empty(), "retained actual source/progression/action evidence matches the selected route scope", reason)
	if not reason.is_empty():
		if _failures == 0:
			_expect(false, "actual route stops at its first failed scope", reason)
		print("FIRST MEANINGFUL FAILURE; remaining route actions unattempted: " + reason + "; " + _diagnostic())
		_print_source_physical_diagnostic()
	await _dispose()
	_finish()


func _options() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--capture-portrait" and not _capture_portrait:
			_capture_portrait = true
		elif argument in ["--first-pocket-only", "--east-approach-only"] and _route_selector.is_empty():
			_route_selector = argument
		elif argument in ["--compound-extreme", "--weak-damage", "--long-dash"] and _kit_selector.is_empty():
			_kit_selector = argument
		else:
			return "unsupported or repeated fixture selector: " + argument
	_side = 1 if _route_selector == "--east-approach-only" else -1
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
				return "public static catalogue identity/type differs: " + id
			ids[id] = true
	var kits: Array[Dictionary] = []
	for jacket: Dictionary in choices["jacket"]:
		for pants: Dictionary in choices["pants"]:
			for shoes: Dictionary in choices["shoes"]:
				for weapon: Dictionary in choices["weapon"]:
					var kit: Dictionary = {"jacket": jacket.id, "pants": pants.id, "shoes": shoes.id, "weapon": weapon.id}
					if not catalogue.restore(kit) or not catalogue.acceptance_errors().is_empty():
						return "actual static model rejects a legal kit"
					kits.append({"kit": kit, "stats": catalogue.resolved_stats()})
	if not _expect(ids.size() == 13 and kits.size() == 108, "actual public catalogue retains thirteen canonical IDs and 108 implemented static kits"):
		return "public catalogue cardinality drift"
	catalogue.reset_starter()
	_kit = catalogue.snapshot()
	_stats = catalogue.resolved_stats()
	if not _kit_selector.is_empty():
		var chosen: Dictionary = kits[0]
		for entry: Dictionary in kits:
			if _prefer(entry, chosen):
				chosen = entry
		_kit = chosen.kit.duplicate(true)
		_stats = chosen.stats.duplicate(true)
	print("ACTUAL KIT: selector=%s IDs=%s primary_damage=%s range=%s dash_distance=%s speed=%s duration=%s cooldown=%s" % [_kit_selector, _kit, _stats.primary_damage, _stats.primary_range, _stats.dash_distance, _stats.dash_speed, _stats.dash_duration, _stats.dash_cooldown])
	if _kit_selector == "--compound-extreme":
		print("Compound order is legal minimum primary reach, then minimum dash speed, then maximum distance among those ties; this does not assert incompatible global shoe extrema coexist.")
	return ""


func _prefer(candidate: Dictionary, current: Dictionary) -> bool:
	var fields: Array[String] = ["primary_range", "dash_speed", "dash_distance"]
	var maximize: Array[bool] = [false, false, true]
	if _kit_selector == "--weak-damage":
		fields = ["primary_damage", "primary_range", "primary_cooldown"]
		maximize = [false, false, true]
	elif _kit_selector == "--long-dash":
		fields = ["dash_distance", "primary_range", "dash_speed"]
		maximize = [true, false, false]
	for index: int in range(fields.size()):
		var a: float = float(candidate.stats[fields[index]])
		var b: float = float(current.stats[fields[index]])
		if a != b:
			return a > b if maximize[index] else a < b
	return _kit_key(candidate.kit) < _kit_key(current.kit)


func _prepare() -> String:
	paused = false
	_game = MainScene.instantiate()
	root.add_child(_game)
	var lab_hero: CinderPlayer = _game.get("player") as CinderPlayer
	_old_hero = lab_hero
	_old_level = _game.get("active_level")
	if lab_hero == null or not _game.call("is_lab_level") or not get_nodes_in_group("enemies").is_empty():
		return "actual enemy-free lab is unavailable"
	_game.call("open_bench")
	for slot: String in Slots:
		if not lab_hero.equip_item(String(_kit[slot])):
			return "public selected kit equip failed: " + slot
	if not paused or not _game.call("load_level_scene", FullPath):
		return "actual paused carryover transition failed"
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	if _hero == null or _level == null or _hero == lab_hero or _level.scene_file_path != FullPath or _level.get_script().resource_path != RuntimePath or not _level.contract_error().is_empty():
		return "full authored scene/new shared hero did not enter"
	var binding_error: String = _bind_runtime()
	if not binding_error.is_empty():
		return binding_error
	_game.call("open_bench")
	_hero.shells = 0 # Public no-blast fixture; natural reload remains unchanged.
	_hp_before = _hero.hp
	_topology = _world_topology()
	await process_frame
	await process_frame
	var state: Dictionary = _level.call("state")
	if not paused or _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0 or state.get("api_revision") != "act3-twin-suns-level-1" or not String(state.get("configuration_error", "")).is_empty() or not state.get("entered", []).is_empty() or not state.get("cleared", []).is_empty() or _hero.shells != 0:
		return "paused setup advanced actual route clocks/history or configuration failed"
	var bindings: Dictionary = _level.call("scheduler_bindings")
	return "" if bindings.get("owners") == _sources and bindings.get("floors", {}).get("shelf-floor", {}).get("collision") == _floor.get_node("Solid") else "public source/floor bindings differ from actual nodes"


## Rebind observations to the actual freshly loaded world, never substitutes.
func _bind_runtime() -> String:
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	var public_sources: Variant = _level.get("sources")
	if _scheduler == null or not public_sources is Dictionary or not Codec.keys_error(public_sources, SourceIds).is_empty():
		return "exact five-source public scheduler binding is unavailable"
	_sources = public_sources.duplicate()
	var scenery: Node = _level.get("scenery") as Node
	_floor = scenery.get("floor_body") as StaticBody3D if scenery != null else null
	_motifs = _level.find_child("ScenicSuns", true, false) as Node3D
	_exit_cue = _level.get("exit_cue") as CinderInteractionCue
	if _floor == null or _motifs == null or _exit_cue == null or _hero.presentation_id != "act3_traveller" or not _exact(_hero.equipment.snapshot(), _kit) or not _exact(_hero.stats, _stats):
		return "actual floor/traveller/cues/equipment differ"
	var solid: CollisionShape3D = _floor.get_node_or_null("Solid") as CollisionShape3D
	if solid == null or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Vector3(14, 1, 108):
		return "actual full route lacks its continuous fourteen by108 floor"
	for id: String in SourceIds:
		var source: CharacterBody3D = _sources[id] as CharacterBody3D
		if source == null or not source.has_method("state") or not source.is_in_group("enemies") or source.get_world_3d() != _hero.get_world_3d():
			return "actual living source unavailable: " + id
		_expected_hp[id] = float((source.call("state") as Dictionary).hp)
		source.connect("state_changed", _on_source_state.bind(id))
		source.connect("hit_resolved", _on_contact.bind(id))
		source.connect("died", _on_death.bind(id))
		var cue: CinderThreatCue = source.call("get_cue") as CinderThreatCue
		cue.state_changed.connect(func(_value: Dictionary) -> void: _event("cue"))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _event("cancel"))
	_hero.world_action_executed.connect(_on_action)
	_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
	_hero.action_resolved.connect(func(kind: String, _hits: int, _damage: float) -> void: _event("resolved_" + kind))
	_hero.equipment_changed.connect(func(_id: String) -> void: _event("equipment"))
	_hero.died.connect(func() -> void: _event("hero_death"))
	_level.checkpoint_requested.connect(_on_checkpoint)
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _event("completion"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _event("exit"))
	_exit_cue.state_changed.connect(func(_state: Dictionary) -> void: _event("exit_cue"))
	return ""


## Optional actual scenic excursion before z30; no mandatory timer/entry wait.
## Real forward dashes approach the quiet bank, a left dash frames the couple,
## then an ordinary right return rejoins before the standard route starts.
func _scenic_detour() -> String:
	if not _capture_portrait:
		return ""
	for _step: int in range(8):
		if _hero.global_position.z - float(_stats.dash_distance) <= 30.0:
			break
		var forward_error: String = await _route_dash(Vector3.FORWARD)
		if not forward_error.is_empty():
			return forward_error
	if _hero.global_position.z <= 30.0 or not (_level.call("state") as Dictionary).entered.is_empty():
		return "optional scenic excursion unexpectedly entered combat"
	var error: String = await _route_dash(Vector3.LEFT)
	var second_left: bool = false
	# The first real left landing clips the quiet duo in the fixed camera.
	# Take an optional second ordinary dash only when its full footprint fits
	# the permanent shelf, then return over the same real path before entry.
	if error.is_empty() and _hero.global_position.x - float(_stats.dash_distance) >= -6.5:
		error = await _route_dash(Vector3.LEFT)
		second_left = error.is_empty()
	if error.is_empty():
		error = await _capture("companion-dry-bank-optional-actual-detour")
	if error.is_empty():
		error = await _route_dash(Vector3.RIGHT)
	if error.is_empty() and second_left:
		error = await _route_dash(Vector3.RIGHT)
	return error


func _travel_entry(index: int) -> String:
	var reason: String = await _corridor()
	if not reason.is_empty():
		return reason
	for _step: int in range(40):
		var state: Dictionary = _level.call("state")
		if state.entered.size() >= index + 1:
			return "" if state.entered.size() == index + 1 and state.entered[index] == PocketIds[index] else "spatial entry skipped or reordered a canonical pocket"
		if _hero.global_position.z <= EntryZ[index] and state.entered.size() <= index:
			reason = await _tick_safe()
		else:
			reason = await _route_dash(Vector3.FORWARD)
		if not reason.is_empty():
			return reason
	return "ordinary entry route exceeded its finite dash bound"


func _corridor() -> String:
	var low: float = -6.0 if _side < 0 else 1.25
	var high: float = -1.25 if _side < 0 else 6.0
	if float(_stats.dash_distance) > high - low:
		return "selected actual full dash exceeds the authorable side corridor width"
	for _step: int in range(8):
		var x: float = _hero.global_position.x
		if x >= low and x <= high:
			return ""
		var reason: String = await _route_dash(Vector3.RIGHT if x < low else Vector3.LEFT)
		if not reason.is_empty():
			return reason
	return "real horizontal dashes did not reach the selected broad side corridor"


func _travel_z(target: float) -> String:
	for _step: int in range(45):
		if _hero.global_position.z <= target:
			return ""
		for trunk: float in [8.0, -13.0]:
			if _hero.global_position.z > trunk and _hero.global_position.z - float(_stats.dash_distance) <= trunk:
				var capture_error: String = await _capture(("west" if _side < 0 else "east") + "-trunk-z" + str(int(trunk)))
				if not capture_error.is_empty():
					return capture_error
		var reason: String = await _route_dash(Vector3.FORWARD)
		if not reason.is_empty():
			return reason
	return "actual forward route exceeded finite dash bound"


func _rejoin() -> String:
	for _step: int in range(5):
		if absf(_hero.global_position.x) <= 1.35:
			return ""
		var lateral: float = clampf(-_hero.global_position.x / float(_stats.dash_distance), -1.0, 1.0)
		# A diagonal full dash can rejoin with any legal dash length; repeated
		# horizontal steps would falsely require a favourable distance modulus.
		var toward: Vector3 = Vector3(lateral, 0.0, -sqrt(maxf(0.0, 1.0 - lateral * lateral)))
		var reason: String = await _route_dash(toward)
		if not reason.is_empty():
			return reason
	return "ordinary full dash did not rejoin after the actual trunk"


func _route_dash(direction: Vector3) -> String:
	var reason: String = await _ready_dash()
	if not reason.is_empty():
		return reason
	if direction.is_equal_approx(Vector3.FORWARD):
		for trunk: float in [8.0, -13.0]:
			if _hero.global_position.z > trunk and _hero.global_position.z - float(_stats.dash_distance) <= trunk:
				reason = await _capture(("west" if _side < 0 else "east") + "-trunk-z" + str(int(trunk)))
				if not reason.is_empty():
					return reason
	var origin: Vector3 = _hero.global_position
	var segment: Dictionary = {"kind": "route_dash", "from": origin, "to": origin + direction.normalized() * float(_stats.dash_distance), "start_s": _hero.get_world_action_clock(), "end_s": _hero.get_world_action_clock() + float(_stats.dash_duration)}
	return await _dash(segment)


func _ready_dash() -> String:
	for _tick: int in range(_frame_limit(1.0)):
		var response: Dictionary = _hero.get_threat_response_state()
		if response.get("stable") == true and float(response.get("dash_cooldown_left_s", 1.0)) == 0.0:
			return ""
		var reason: String = await _tick_safe()
		if not reason.is_empty():
			return reason
	return "actual stopped shared hero never reached a ready dash within one second"


func _checkpoint_pair(index: int) -> String:
	var pair: Dictionary = await _pause_pair("actual spatial checkpoint " + CheckpointIds[index])
	if pair.is_empty():
		return "actual entry checkpoint pair could not capture/transport"
	var entries: Array = pair.level.local.route.entries
	if entries.size() != index + 1 or pair.level.progress.checkpoint_id != CheckpointIds[index] or pair.level.progress.checkpoint_ids.size() != index + 1 or _checkpoints.size() != index + 1:
		return "checkpoint history differs from actual entered canonical prefix"
	for i: int in range(index + 1):
		var point: Vector3 = Codec.read_vector3(entries[i].hero_position)
		if entries[i].id != PocketIds[i] or point.z > EntryZ[i] or not _floor_hit(point) or _checkpoints[i] != CheckpointIds[i]:
			return "checkpoint lacks its real completed/continuing ordinary entry path and floor sample"
	if _actions.is_empty() or (_actions[-1] as Dictionary).get("kind") != "dash" or _hero.hp != _hp_before:
		return "entry checkpoint was not reached by an actual ordinary dash without healing"
	var before: Dictionary = _observe()
	var error: String = _hero.snapshot_error(pair.hero)
	if error.is_empty():
		error = _level.snapshot_error_with_player(pair.level, pair.hero)
	if not error.is_empty() or not _exact(before, _observe()):
		return "actual entered checkpoint pure pair proof failed: " + error
	if index == 1:
		error = await _fresh_partial_retry(pair)
		if not error.is_empty():
			return error
	_game.call("resume_lab")
	return ""


func _fresh_partial_retry(pair: Dictionary) -> String:
	if not paused or pair.level.local.route.deaths.size() != 1 or not pair.level.local.route.deaths.has(SourceIds[0]) or pair.level.local.route.entries.size() != 2 or not pair.level.local.sources[SourceIds[0]].dead or not pair.level.local.scheduler.reservations.is_empty():
		return "fresh partial retry requires the actual first death, two spatial entries and no pending source lease"
	var expected: Dictionary = _observe()
	var old_hero: CinderPlayer = _hero
	var old_level: CinderLevel = _level
	var old_sources: Array = _sources.values()
	if not _game.call("load_level_scene", FullPath):
		return "public fresh same-level preview load rejected"
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	if _hero == null or _level == null or _hero == old_hero or _level == old_level or _level.scene_file_path != FullPath or _level.get_script().resource_path != RuntimePath:
		return "public retry did not instantiate a genuinely fresh actual player/full level"
	var error: String = _bind_runtime()
	if not error.is_empty():
		return error
	_game.call("open_bench")
	_topology = _world_topology()
	await process_frame
	await process_frame
	if not paused or not (_level.call("state") as Dictionary).entered.is_empty() or not (_level.call("state") as Dictionary).cleared.is_empty() or _scheduler.get_clock() != 0.0 or _hero.get_world_action_clock() != 0.0:
		return "fresh same-level receiver advanced or inherited route/death clocks before validated restore"
	if is_instance_valid(old_hero) or is_instance_valid(old_level):
		return "public preview replacement retained the old player/level"
	for source: Variant in old_sources:
		if is_instance_valid(source):
			return "public preview replacement retained an old source body"
	error = _pure_pair_error(pair)
	if not error.is_empty():
		return "fresh post-death receiver: " + error
	var events: Dictionary = _events.duplicate(true)
	if not _hero.restore_state(pair.hero) or not _level.restore_state(pair.level):
		return "fresh independently prevalidated hero→partial-death level retry rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	for id: String in SourceIds:
		_expected_hp[id] = float(pair.level.local.sources[id].hp)
	expected.events = events
	if not _exact(expected, _observe()) or not _exact(_events, events):
		return "fresh actual partial-death retry changed snapshots, native poses/cues/resources/history or emitted restore events"
	error = _tombstone_error(SourceIds[0])
	if not error.is_empty() or _sources[SourceIds[1]].is_physics_processing() != true or _motifs.position != Vector3(_hero.global_position.x, 0.0, _hero.global_position.z):
		return "fresh retained tombstone/next entered source/scenic follow differs: " + error
	var before: Dictionary = _observe()
	await process_frame
	await process_frame
	if not _exact(before, _observe()):
		return "paused fresh post-death retry advances a clock, source, player resource or event"
	_fresh_partial_done = true
	_expect(true, "actual second-entry post-death exact pair prevalidates and silently restores into a genuinely fresh full world with its retained tombstone")
	return ""


## The default starter route is dedicated mandatory two-lease coverage.
## Carried-kit routes verify actual primary viability under their real geometry:
## forcing a hold at an edge can correctly prevent the other source's admission.
## Every genuine held union still receives the same immutable/path checks.
## A profile-specific production consumer retains its own coverage requirement.
func _requires_crossing_union() -> bool:
	return _kit_selector.is_empty()


func _clear_pocket(index: int) -> String:
	_group_ids.clear()
	if index < 2:
		_group_ids.append(SourceIds[index])
	elif index == 2:
		_group_ids.append(SourceIds[2])
		_group_ids.append(SourceIds[3])
	else:
		_group_ids.append(SourceIds[4])
	_group_deadline = minf(_route_deadline, _scheduler.get_clock() + GroupBudgetS)
	for _episode: int in range(20):
		if _scheduler.get_clock() > _group_deadline:
			return "current actual pocket exceeded its sixty-second bounded proof budget"
		if _group_dead():
			for id: String in _group_ids:
				var error: String = _tombstone_error(id)
				if not error.is_empty():
					return error
			return ""
		var warning: Dictionary = await _next_warning()
		if warning.is_empty():
			return "no next actual supported warning in the current spatial pocket; " + _diagnostic()
		_source_id = warning.id
		_current = warning.record.duplicate(true)
		var error: String = _proof_error(warning)
		if not error.is_empty():
			return error
		print("FOLLOW ACTUAL PROOF: source=%s reservation=%s start=%.9f leases=%d" % [_source_id, _current.id, float(_current.start_s), _scheduler.reservations().size()])
		for segment: Dictionary in warning.proof.path:
			if _tick_trace_enabled():
				_trace_path_segment = {"kind": segment.kind, "start_s": segment.start_s, "end_s": segment.end_s}
			if segment.kind in ["escape_dash", "positioning_dash"]:
				error = await _at_time(float(segment.start_s))
				if error.is_empty():
					error = await _dash(segment)
			elif segment.kind == "ordinary_primary":
				if _requires_crossing_union() and index == 2 and not _union_seen and not _crossing_primary_deferred:
					error = await _defer_crossing_primary(segment, warning.proof)
				else:
					error = await _primary(segment, warning.proof)
			else:
				error = await _hold(segment)
			if not error.is_empty():
				break
		if error == Replan:
			print("REPLAN: newer actual union warning joined a stable hold; old fixed lane remains monitored")
			continue
		if not error.is_empty():
			return _source_id + ": " + error
	return "current pocket exceeded twenty real proof episodes"


func _group_dead() -> bool:
	for id: String in _group_ids:
		if not bool((_sources[id].call("state") as Dictionary).dead):
			return false
	return true


func _pending() -> Dictionary:
	var chosen: Dictionary = {}
	for reservation_id: String in _warnings:
		var warning: Dictionary = _warnings[reservation_id]
		if _used_warnings.has(reservation_id) or not _group_ids.has(warning.id):
			continue
		var source: CharacterBody3D = _sources[warning.id]
		var state: Dictionary = source.call("state")
		var record: Dictionary = _scheduler.reservation_state(reservation_id)
		if state.get("dead") == true or state.get("reservation_id") != reservation_id or record.is_empty() or record.get("state") != "warning":
			continue
		if chosen.is_empty() or float(record.start_s) > float(chosen.record.start_s) or (float(record.start_s) == float(chosen.record.start_s) and String(warning.id) > String(chosen.id)):
			chosen = {"id": warning.id, "state": state, "record": record, "proof": warning.proof.duplicate(true)}
	return chosen


## A declined outward lane leaves the real player free to rejoin the shelf.
## This is one ordinary navigation choice, never an invented attack witness.
func _edge_rejoin_candidate() -> Dictionary:
	var response: Dictionary = _hero.get_threat_response_state()
	if paused or response.get("stable") != true or float(response.get("dash_cooldown_left_s", 1.0)) != 0.0:
		return {}
	for id: String in _group_ids:
		var source: CharacterBody3D = _sources[id]
		var state: Dictionary = source.call("state")
		if state.get("dead") != false or state.get("phase") != "idle" or state.get("reservation_id") != "" or not source.velocity.is_zero_approx() or int(state.get("cycle", 0)) <= 0 or float(state.get("hp", 0.0)) != float(_expected_hp[id]) or float(state.hp) >= float(state.max_hp) or state.get("last_cancel_reason") != "primary_stagger" or state.get("last_rejection") != "Measured footprint loses continuous floor coverage":
			continue
		# A restored fresh world has different actual bodies, even when its
		# stable IDs and saved cycle are the same. No derived rebind hook needed.
		var key: String = "%s:%d:%d" % [id, source.get_instance_id(), int(state.cycle)]
		if _edge_rejoins.has(key):
			continue
		var direction: Vector3 = Vector3.RIGHT if _hero.global_position.x < 0.0 else Vector3.LEFT
		var landing: Vector3 = _hero.global_position + direction * float(_stats.dash_distance)
		if absf(landing.x) >= absf(_hero.global_position.x):
			continue
		return {"id": id, "key": key, "direction": direction}
	return {}


func _edge_rejoin_guard(id: String, held: Array[Dictionary]) -> Dictionary:
	var source: CharacterBody3D = _sources[id]
	var response: Dictionary = _level.call("combat_response", id)
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var solid: CollisionShape3D = _floor.get_node_or_null("Solid") as CollisionShape3D
	if response.get("actor") != _hero or response.get("world_root") != _hero.get_parent() or not response.get("floor_regions") is Array or bindings.get("owners") != _sources or bindings.get("floors", {}).get("shelf-floor", {}).get("collision") != solid or not is_instance_valid(solid) or not solid.shape is BoxShape3D or solid.disabled or _floor.get_world_3d() != _hero.get_world_3d() or source.get_world_3d() != _hero.get_world_3d() or _scheduler.get_world_3d() != _hero.get_world_3d() or _hero.collision_layer != 4 or _hero.collision_mask != 1:
		return {"error": "centerward rejoin lost its actual actor/source/solid-floor bindings"}
	return {"hero": _hero, "level": _level, "scheduler": _scheduler, "source": source, "clock_s": _scheduler.get_clock(), "hero_transform": _hero.global_transform, "response": response.duplicate(true), "source_state": source.call("state"), "bindings": bindings.duplicate(true), "floor": {"body": _floor, "solid": solid, "shape": solid.shape, "size": (solid.shape as BoxShape3D).size, "transform": solid.global_transform, "disabled": solid.disabled, "layer": _floor.collision_layer, "mask": _floor.collision_mask}, "held": held.duplicate(true), "events": _events.duplicate(true), "topology": _world_topology()}


func _edge_rejoin(candidate: Dictionary) -> String:
	# These ordinary public reads may prune; take the guard after that boundary.
	var held: Array[Dictionary] = _scheduler.reservations()
	var guard: Dictionary = _edge_rejoin_guard(candidate.id, held)
	if guard.has("error"):
		return String(guard.error)
	var response: Dictionary = guard.response
	var now: float = float(guard.clock_s)
	if now != _hero.get_world_action_clock() or response.get("stable") != true or float(response.get("dash_cooldown_left_s", 1.0)) != 0.0 or not _exact(response.get("equipment_ids"), _kit) or not _exact(response.get("stats"), _stats):
		return "centerward rejoin lacks the current stopped ready public hero/kit clock"
	var origin: Vector3 = _hero.global_position
	var motion: Vector3 = candidate.direction * float(_stats.dash_distance)
	var landing: Vector3 = BodySweep.anchored_position(origin, motion, 1.0)
	var regions: Array = response.floor_regions
	var supported: bool = false
	var radius: float = CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
	for region: Dictionary in regions:
		if region.get("collision") != guard.floor.solid or not region.get("safe_rect") is Rect2:
			return "centerward rejoin uses another floor or an unsupported native region"
		var safe: Rect2 = (region.safe_rect as Rect2).grow(-radius)
		if safe.has_point(Vector2(origin.x, origin.z)) and safe.has_point(Vector2(landing.x, landing.z)):
			supported = true
	if not supported:
		return "centerward full dash and landing do not fit the actual supported shelf"
	var sweep: Dictionary = BodySweep.sweep(_hero, _hero.global_transform, motion, regions)
	if sweep.has("error") or sweep.get("collided") != false or not sweep.get("end") is Vector3 or not sweep.get("travel") is Vector3:
		return "centerward actual capsule sweep failed: " + String(sweep.get("error", "scenery collision or malformed result"))
	if _planar((sweep.end as Vector3) - landing).length() > PointTolerance or absf(_planar(sweep.travel).length() - float(_stats.dash_distance)) > PointTolerance:
		return "centerward actual capsule sweep shortens the ordinary full dash"
	var duration: float = float(_stats.dash_duration)
	var steps: int = ceili(duration / _tick_s())
	var dash_end: float = now + float(steps) * _tick_s()
	var ready_until: float = now + maxf(float(_stats.dash_cooldown), float(steps) * _tick_s()) + 2.0 * _tick_s()
	if ready_until > _group_deadline or ready_until > _route_deadline:
		return "centerward ordinary rejoin exceeds the existing finite pocket/route deadline"
	var path: Array[Dictionary] = []
	for index: int in range(steps):
		var elapsed_from: float = minf(float(index) * _tick_s(), duration)
		var elapsed_to: float = minf(float(index + 1) * _tick_s(), duration)
		path.append({"from": BodySweep.anchored_position(origin, motion, elapsed_from / duration), "to": BodySweep.anchored_position(origin, motion, elapsed_to / duration), "start_s": now + float(index) * _tick_s(), "end_s": now + float(index + 1) * _tick_s()})
	path.append({"from": landing, "to": landing, "start_s": dash_end, "end_s": ready_until})
	for record: Dictionary in held:
		if Geometry.timed_path_hits(record.geometry, path, float(record.active_from_s), float(record.active_until_s), radius):
			return "centerward dash/readiness hold intersects a currently held active footprint"
		# Fail closed for a tick-boundary rounding variant of the final movement;
		# this extra spatial envelope grants no tolerance to any action deadline.
		if maxf(now, float(record.active_from_s)) <= minf(dash_end + 2.0 * _tick_s(), float(record.active_until_s)) and Geometry.segment_hits(record.geometry, origin, landing, radius):
			return "centerward dash movement envelope intersects a held active footprint"
	# BodySweep/Geometry above are pure. No await separates this exact recheck
	# from the existing real public dash request and all its native assertions.
	if not _exact(guard, _edge_rejoin_guard(candidate.id, _scheduler.reservations())):
		return "actual clock/pose/floor/binding/held union changed during pure rejoin preflight"
	_edge_rejoins[candidate.key] = true
	print("ORDINARY CENTERWARD REJOIN: source=%s cycle=%d clock=%.9f from=%s to=%s held=%d" % [candidate.id, int(guard.source_state.cycle), now, origin, landing, held.size()])
	var error: String = await _dash({"kind": "route_dash", "from": origin, "to": landing, "start_s": now, "end_s": now + duration})
	if error.is_empty():
		_expect(true, "one actual centerward ordinary dash leaves a declined outward lane and seeks a fresh genuine warning")
	return error


func _next_warning() -> Dictionary:
	var stop: float = minf(_group_deadline, _scheduler.get_clock() + WarningBudgetS)
	for _tick: int in range(_frame_limit(WarningBudgetS)):
		var warning: Dictionary = _pending()
		if not warning.is_empty():
			_used_warnings[warning.record.id] = true
			return warning
		if _scheduler.get_clock() > stop:
			break
		var rejoin: Dictionary = _edge_rejoin_candidate()
		if not rejoin.is_empty():
			var rejoin_error: String = await _edge_rejoin(rejoin)
			if not rejoin_error.is_empty():
				_expect(false, "bounded actual edge rejoin preserves full capsule/floor/timed union safety", rejoin_error)
				return {}
			continue
		var error: String = await _tick_safe()
		if not error.is_empty():
			_expect(false, "bounded live warning wait preserves actual actors/leases/resources", error)
			return {}
	return {}


func _proof_error(warning: Dictionary) -> String:
	var proof: Dictionary = warning.proof
	var record: Dictionary = warning.record
	var response: Dictionary = _level.call("combat_response", warning.id)
	var source: CharacterBody3D = _sources[warning.id]
	if record.get("armed") != true or record.get("adapter", {}).get("kind") != "lunge" or record.get("source_instance_id") != source.get_instance_id() or response.get("actor") != _hero or not _exact(response.get("equipment_ids"), _kit) or not _exact(response.get("stats"), _stats) or proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not proof.get("path") is Array or proof.path.is_empty():
		return "new warning lacks the actual bound ordinary-primary/no-immunity union witness"
	var path: Array[Dictionary] = []
	var previous: Dictionary = {}
	var escapes: int = 0
	var primaries: int = 0
	for value: Variant in proof.path:
		if not value is Dictionary or not Geometry.finite_vector(value.get("from")) or not Geometry.finite_vector(value.get("to")) or not Geometry.finite_number(value.get("start_s")) or not Geometry.finite_number(value.get("end_s")):
			return "actual proof contains malformed native path data"
		var segment: Dictionary = value
		if segment.kind not in ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"] or float(segment.end_s) < float(segment.start_s) or float(segment.start_s) < float(record.start_s) - TimeEpsilon or float(segment.end_s) > float(record.recovery_until_s):
			return "actual proof path has unsupported kind/timing"
		if not previous.is_empty() and (absf(float(previous.end_s) - float(segment.start_s)) > TimeEpsilon or (previous.to as Vector3).distance_to(segment.from) > PointTolerance):
			return "actual proof path is discontinuous"
		if not _floor_hit(segment.from) or not _floor_hit(segment.to):
			return "actual proof endpoints are unsupported by the authored floor"
		escapes += 1 if segment.kind == "escape_dash" else 0
		primaries += 1 if segment.kind == "ordinary_primary" else 0
		path.append(segment)
		previous = segment
	if escapes != 1 or primaries != 1 or (path[0].from as Vector3).distance_to(_hero.global_position) > PointTolerance or float(proof.primary_time_s) <= float(record.active_until_s) or float(proof.response_complete_s) > float(record.recovery_until_s):
		return "actual proof lacks its live origin or positive ordinary-primary opening"
	for held: Dictionary in _scheduler.reservations():
		if Geometry.timed_path_hits(held.geometry, path, float(held.active_from_s), float(held.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN):
			return "new actual path intersects a held preparing/active member of the shared union"
	return ""


func _hold(segment: Dictionary) -> String:
	if segment.from != segment.to or _hero.global_position.distance_to(segment.from) > PointTolerance:
		return "actual stationary proof segment does not begin at its advertised position"
	for _tick: int in range(_frame_limit(GroupBudgetS)):
		if not _pending().is_empty():
			return Replan
		if _scheduler.get_clock() >= float(segment.end_s):
			return ""
		if not _roundtrip_done and not _current.is_empty() and _source_id == SourceIds[0]:
			var state: Dictionary = _sources[_source_id].call("state")
			var travelled: float = (_sources[_source_id] as CharacterBody3D).global_position.distance_to(_current.adapter.start)
			var remaining: float = (_sources[_source_id] as CharacterBody3D).global_position.distance_to(_current.adapter.planned_endpoint)
			if state.phase == "active" and travelled > 0.1 and remaining > 0.8:
				var retry_error: String = await _moving_retry()
				if not retry_error.is_empty():
					return retry_error
		var error: String = await _tick_safe()
		if not error.is_empty():
			return error
		if _hero.global_position.distance_to(segment.from) > PointTolerance:
			return "actual hero drifted through a stationary proof wait"
	return "stationary proof wait exceeded finite tick bound"


func _at_time(target: float) -> String:
	if not is_finite(target) or target > _route_deadline:
		return "actual proof deadline is nonfinite/outside route budget"
	for _tick: int in range(_frame_limit(GroupBudgetS)):
		if not _pending().is_empty():
			return Replan
		var now: float = _hero.get_world_action_clock()
		if now >= target:
			if now - target <= _tick_s() + TimeEpsilon:
				return ""
			if _tick_trace_enabled():
				_print_tick_deadline_diagnostic(target, now)
			return "actual action missed its first available fixed tick"
		var error: String = await _tick_safe()
		if not error.is_empty():
			return error
	return "actual scheduled action exceeded finite tick bound"


func _dash(segment: Dictionary) -> String:
	if _hero.global_position.distance_to(segment.from) > PointTolerance:
		return "actual dash origin differs from its advertised ordinary path"
	var response: Dictionary = _hero.get_threat_response_state()
	if float(response.get("dash_cooldown_left_s", 1.0)) != 0.0 or float(response.get("motion", {}).get("dash_left_s", 1.0)) != 0.0:
		return "actual ordinary dash would overlap or queue"
	var direction: Vector3 = segment.to - segment.from
	direction.y = 0.0
	if direction.is_zero_approx():
		return "actual dash direction is empty"
	var sequence: int = _last_sequence()
	var started: float = _hero.get_world_action_clock()
	if not _hero.request_dash(direction.normalized()):
		return "real public dash rejected its ready path"
	var actions: Array[Dictionary] = []
	for _tick: int in range(_frame_limit(float(_stats.dash_duration) + 0.25)):
		actions = _hero.get_world_action_records(sequence)
		if not actions.is_empty():
			break
		var error: String = await _tick_safe()
		if not error.is_empty():
			return error
	if actions.size() != 1:
		return "real dash did not publish exactly one completed world action"
	var action: Dictionary = actions[0]
	if action.get("kind") != "dash" or action.get("blocked") != false or action.get("collision_shortened") != false or not _exact(action.get("equipment_ids"), _kit) or not _exact(action.get("resolved_stats"), _stats):
		return "actual authored route/proof dash was blocked, shortened or changed kit"
	if (action.world_origin as Vector3).distance_to(segment.from) > PointTolerance or _planar((action.landing as Vector3) - (segment.to as Vector3)).length() > PointTolerance or (action.landing as Vector3).distance_to(_hero.global_position) > PointTolerance or absf(float(action.distance) - float(_stats.dash_distance)) > PointTolerance:
		return "real completed dash origin/landing/distance differs by more than .005 world units"
	if float(action.started_at_s) != started or absf(float(action.completed_at_s) - float(action.started_at_s) - float(_stats.dash_duration)) > _tick_s() + TimeEpsilon or float(action.completed_at_s) > float(segment.end_s) + 2.0 * _tick_s() + TimeEpsilon:
		return "real completed dash exceeds the published fixed-tick timing bound"
	var previous_time: float = -1.0
	var previous_progress: float = -1.0
	var unit: Vector3 = direction.normalized()
	for sample: Dictionary in action.path:
		var point: Vector3 = sample.position
		var progress: float = _planar(point - (segment.from as Vector3)).dot(unit)
		var nearest: Vector3 = segment.from + unit * clampf(progress, 0.0, direction.length())
		if float(sample.time_s) < previous_time or progress < previous_progress - PointTolerance or _planar(point - nearest).length() > PointTolerance or not _floor_hit(point):
			return "real completed dash samples are nonmonotone, off-path or off the actual solid floor"
		previous_time = float(sample.time_s)
		previous_progress = progress
	return ""


func _primary(segment: Dictionary, proof: Dictionary) -> String:
	var error: String = await _at_time(float(proof.primary_time_s))
	if not error.is_empty():
		return error
	error = _primary_opening_error(segment, proof)
	if not error.is_empty():
		return error
	var source: CharacterBody3D = _sources[_source_id]
	_hero.shells = 0 # Public depleted-ammo fixture, retaining natural reload/credit.
	var before: Dictionary = _expected_hp.duplicate(true)
	var sequence: int = _last_sequence()
	var toward: Vector3 = _planar(source.global_position - _hero.global_position)
	var hits: int = _hero.slash(toward.normalized())
	var changed: int = 0
	for id: String in SourceIds:
		var actual: float = float((_sources[id].call("state") as Dictionary).hp)
		if actual != float(before[id]):
			if actual != maxf(float(before[id]) - float(_stats.primary_damage), 0.0):
				return "real shared slash applies unexpected source damage"
			changed += 1
		_expected_hp[id] = actual
	var actions: Array[Dictionary] = _hero.get_world_action_records(sequence)
	if hits < 1 or changed != hits or float(_expected_hp[_source_id]) >= float(before[_source_id]) or actions.size() != 1 or actions[0].get("kind") != "primary" or actions[0].get("hits") != hits or float(actions[0].get("damage", 0.0)) != float(_stats.primary_damage) or not _exact(actions[0].get("equipment_ids"), _kit):
		return "actual ordinary whole-body primary failed to publish matching real source hit(s)"
	_current.clear()
	print("ACTUAL PRIMARY: source=%s hits=%d damage=%s target_hp=%s→%s" % [_source_id, hits, _stats.primary_damage, before[_source_id], _expected_hp[_source_id]])
	return await _hold(segment)


func _primary_opening_error(segment: Dictionary, proof: Dictionary) -> String:
	var source: CharacterBody3D = _sources[_source_id]
	var state: Dictionary = source.call("state")
	if state.phase != "recovery" or state.dead or _hero.global_position.distance_to(proof.attack_position) > PointTolerance or segment.from != segment.to or float(_active_travel.get(_current.id, 0.0)) <= 0.1 or source.global_position.distance_to(_current.adapter.planned_endpoint) > PointTolerance or not source.velocity.is_zero_approx():
		return "ordinary primary lacks the actual stopped physical recovery/advertised return opening"
	for phase: String in ["warning", "lock", "active", "recovery"]:
		if not (_phases.get(_current.id, {}) as Dictionary).has(phase):
			return "actual source/cue never presented " + phase
	var response: Dictionary = _hero.get_threat_response_state()
	if response.get("stable") != true or float(response.get("primary_cooldown_left_s", 1.0)) != 0.0:
		return "actual recovery primary is unavailable or unstable"
	return ""


func _defer_crossing_primary(segment: Dictionary, proof: Dictionary) -> String:
	# TEST ONLY optional priority decision: keep the first real recovery lease
	# alive once, instead of immediately cancelling it with the available slash.
	# The hero has already executed its published escape and safe recovery hold.
	var error: String = await _at_time(float(proof.primary_time_s))
	if not error.is_empty():
		return error
	error = _primary_opening_error(segment, proof)
	if not error.is_empty():
		return "crossing union deferral: " + error
	_crossing_primary_deferred = true
	var first_id: String = _source_id
	var first_record: Dictionary = _current.duplicate(true)
	var point: Vector3 = proof.attack_position
	var stop: float = minf(_group_deadline, float(first_record.recovery_until_s) - _tick_s())
	print("DEFER ACTUAL CROSSING PRIMARY: source=%s lease=%s clock=%.9f recovery_until=%.9f point=%s" % [first_id, first_record.id, _scheduler.get_clock(), float(first_record.recovery_until_s), point])
	for _tick: int in range(_frame_limit(GroupBudgetS)):
		var held: Dictionary = _scheduler.reservation_state(first_record.id)
		if held.is_empty() or _scheduler.get_clock() > stop:
			return "crossing union coverage missing: no other genuine warning before the first retained recovery expired; first=" + first_id + "; union_seen=" + str(_union_seen)
		if _hero.global_position.distance_to(point) > PointTolerance or _hero.get_threat_response_state().get("stable") != true:
			return "crossing union deferral left the actual published safe stopped recovery point"
		var next: Dictionary = _pending()
		if not next.is_empty():
			if next.id == first_id or _scheduler.reservations().size() < 2 or not _exact(_fixed_record(held), _fixed_record(first_record)) or not _union_seen:
				return "crossing union coverage lacks two distinct actual retained immutable leases"
			_expect(true, "intentional first-primary deferral observes the other actual crossing warning while its original physical recovery lease remains held")
			return Replan
		error = await _tick_safe()
		if not error.is_empty():
			return "crossing union deferral: " + error
	return "crossing union coverage exceeded its finite fixed-tick observation bound"


func _moving_retry() -> String:
	var pair: Dictionary = await _pause_pair("actual full-level first-source moving-active exact pair", true)
	if pair.is_empty():
		return "full-level moving-active exact pair capture/transport failed"
	var expected: Dictionary = _observe()
	var source: CharacterBody3D = _sources[_source_id]
	if pair.level.local.sources[_source_id].phase != "active" or source.velocity.is_zero_approx() or _hero.shells != 0:
		return "paired retry lacks meaningful actual active motion and depleted resources"
	var error: String = _pure_pair_error(pair)
	if not error.is_empty():
		return error
	error = _forgeries(pair)
	if not error.is_empty():
		return error
	_game.call("resume_lab")
	error = await _tick_safe()
	if error.is_empty():
		error = await _tick_safe()
	if not error.is_empty():
		return error
	var later: Dictionary = await _pause_pair("later actual moving-active full aggregate")
	if later.is_empty() or source.global_position.distance_to(expected.source_positions[_source_id]) <= 0.1 or _scheduler.get_clock() <= float(pair.level.local.scheduler.clock_s):
		return "actual source did not create a genuinely later receiving motion/clock"
	error = _pure_pair_error(pair)
	if not error.is_empty():
		return error
	var events: Dictionary = _events.duplicate(true)
	if not _hero.restore_state(pair.hero) or not _level.restore_state(pair.level):
		return "prevalidated ordered actual hero→all-sources/scheduler/local retry rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	expected.events = events
	if not _exact(expected, _observe()) or not _exact(_events, events):
		return "native full aggregate pose/clocks/resources/history/tombstones/entry/cue state differed after silent ordered retry"
	if _motifs.position != Vector3(_hero.global_position.x, 0.0, _hero.global_position.z):
		return "full scenic motifs do not follow the restored actual hero before a tick"
	var before: Dictionary = _observe()
	await process_frame
	await process_frame
	if not _exact(before, _observe()):
		return "paused restored full aggregate advances motion/clocks/resources/events"
	_roundtrip_done = true
	_expect(true, "actual moving-active exact transport, pure aggregate proof, atomic forgeries and silent native retry preserve every paired actor")
	_game.call("resume_lab")
	return ""


func _pure_pair_error(pair: Dictionary) -> String:
	var input: Dictionary = pair.duplicate(true)
	var before: Dictionary = _observe()
	var error: String = _hero.snapshot_error(pair.hero)
	if error.is_empty():
		error = _level.snapshot_error_with_player(pair.level, pair.hero)
	if not error.is_empty():
		return "independent saved player→complete authored pair prevalidation failed: " + error
	return "" if _exact(before, _observe()) and _exact(input, pair) else "pure native aggregate validator mutates live/input state"


func _forgeries(pair: Dictionary) -> String:
	for kind: String in ["completed_progress", "entered_history", "dead_history", "leased_sample_clock_and_hero", "sample_clock_previous_double", "retained_cooldown_previous_double", "framing_landing_off_floor", "framing_unknown_field"]:
		var forged: Dictionary = pair.level.duplicate(true)
		if kind == "completed_progress":
			forged.progress.completed = true
			forged.progress.completion_id = "twin-suns-clear"
		elif kind == "entered_history":
			forged.local.route.entries.append({"id": "two-approaches", "clock_s": forged.local.scheduler.clock_s, "hero_position": Codec.vector3(_hero.global_position)})
			forged.local.scenery.beat_index = 2
			forged.progress.checkpoint_ids["two-approaches-entry"] = "encounter"
			forged.progress.checkpoint_id = "two-approaches-entry"
		elif kind == "leased_sample_clock_and_hero":
			forged.local.sources[_source_id].previous.clock_s = float(forged.local.sources[_source_id].previous.clock_s) - 0.00000001
			var wrong_hero: Vector3 = Codec.read_vector3(forged.local.sources[_source_id].previous.hero_position) + Vector3.RIGHT * 0.5
			forged.local.sources[_source_id].previous.hero_position = Codec.vector3(wrong_hero)
		elif kind == "sample_clock_previous_double":
			var original: float = float(forged.local.sources[_source_id].previous.clock_s)
			var prior: float = _previous_positive_double(original)
			if not is_finite(prior) or prior >= original or prior <= 0.0:
				return "active sample lacks a positive immediately previous binary64 clock"
			forged.local.sources[_source_id].previous.clock_s = prior
		elif kind == "retained_cooldown_previous_double":
			var original: float = float(forged.local.sources[_source_id].cooldown_until_s)
			var prior: float = _previous_positive_double(original)
			if not is_finite(prior) or prior >= original or prior <= float(forged.local.scheduler.clock_s):
				return "active retained cooldown lacks a future immediately previous binary64 value"
			forged.local.sources[_source_id].cooldown_until_s = prior
			var matched: int = 0
			for cooldown: Dictionary in forged.local.scheduler.cooldowns:
				if cooldown.source_id == _source_id:
					if not _exact(cooldown.ready_s, original):
						return "actual saved source/scheduler cooldown is not an exact copied identity"
					cooldown.ready_s = prior
					matched += 1
			if matched != 1:
				return "actual active source does not have exactly one retained scheduler cooldown"
			# Keep the historical exchange and reservation deadline untouched:
			# this isolates copied history from the strict source/scheduler pair.
		elif kind == "framing_landing_off_floor":
			forged.local.sources[_source_id].framing.landing[0] = 99.0
		elif kind == "framing_unknown_field":
			forged.local.sources[_source_id].framing["guaranteed_safe"] = true
		else:
			forged.local.route.deaths[_source_id] = {"clock_s": forged.local.scheduler.clock_s, "source_position": forged.local.sources[_source_id].position.duplicate()}
		var input: Dictionary = forged.duplicate(true)
		var before: Dictionary = _observe()
		var error: String = _level.snapshot_error_with_player(forged, pair.hero)
		var accepted: bool = _level.restore_state(forged)
		if error.is_empty() or accepted or not _exact(before, _observe()) or not _exact(input, forged):
			return "forged " + kind + " was accepted or changed live/input state"
		_expect(true, "forged aggregate " + kind + " rejects before any actual actor/progress mutation")
	return ""


## Positive finite IEEE-754 binary64 bit patterns are monotonically ordered.
## Decrement the little-endian encoded integer by one, with byte borrow, to
## obtain the immediately previous representable value without subtraction
## by a guessed epsilon or passing the scalar through decimal JSON.
func _previous_positive_double(value: float) -> float:
	if not is_finite(value) or value <= 0.0:
		return NAN
	var bits := PackedByteArray()
	bits.resize(8)
	bits.encode_double(0, value)
	for index: int in range(bits.size()):
		if bits[index] > 0:
			bits[index] = bits[index] - 1
			return bits.decode_double(0)
		bits[index] = 255
	return NAN


func _pause_pair(label: String, deplete_ammo: bool = false) -> Dictionary:
	_game.call("open_bench")
	await process_frame
	await process_frame
	if deplete_ammo:
		_hero.shells = 0
	var pair: Dictionary = {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}
	if not _expect(paused and not pair.hero.is_empty() and not pair.level.is_empty() and pair.level.get("local_snapshot_version") == 5, label + ": complete native local5/all-source pair captures at the deferred paused barrier", _hero.last_snapshot_error + "; " + _level.last_snapshot_error):
		return {}
	var encoded: String = ExactJson.stringify(pair)
	if not _expect(not encoded.is_empty(), label + ": published exact JSON encodes the complete actual pair"):
		return {}
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not _expect(decoded.get("accepted") == true and decoded.has("value"), label + ": exact parser explicitly accepts transport", String(decoded.get("reason", ""))):
		return {}
	var raw: Variant = decoded.value
	if not _expect(raw is Dictionary and Codec.value_error(raw).is_empty() and _exact(pair, raw), label + ": raw decoded finite snapshot preserves native scalar types/bits and all vector payloads exactly"):
		return {}
	return raw


func _contact_exit() -> String:
	if not _level.is_completed() or int(_events.get("completion", 0)) != 1 or (_level.call("state") as Dictionary).exit_state != "available" or not _scheduler.reservations().is_empty() or _exit_cue.state().get("trigger") != "contact" or _exit_cue.state().get("state") != "available":
		return "five actual source deaths did not create exactly one clear and distinct available contact cue"
	var error: String = await _corridor()
	if error.is_empty():
		error = await _travel_z(-40.0)
	if error.is_empty():
		error = await _capture("final-available-contact-cue")
	if not error.is_empty():
		return error
	var marker: Marker3D = _level.get_node("PoolingdredThreshold") as Marker3D
	for _attempt: int in range(8):
		if (_level.call("state") as Dictionary).exit_state == "spent":
			break
		var direction: Vector3 = _planar(marker.global_position - _hero.global_position).normalized()
		error = await _route_dash(direction)
		if not error.is_empty():
			return error
	var state: Dictionary = _level.call("state")
	if state.exit_state != "spent" or int(_events.get("exit", 0)) != 1 or state.contact.is_empty() or _exit_cue.state().get("state") != "spent":
		return "real ordinary entry path did not dispatch the contact threshold exactly once"
	var contact: Vector3 = Codec.read_vector3(state.contact.hero_position)
	if not Rect2(-1.2, -44.65, 2.4, 1.3).has_point(Vector2(contact.x, contact.z)) or absf(contact.y) > 0.2 or not _floor_hit(contact):
		return "contact history lacks a true actor feet sample inside the actual authored threshold"
	error = await _capture("final-spent-contact-exit")
	if error.is_empty():
		error = await _route_dash(Vector3.BACK)
	if error.is_empty():
		error = await _route_dash(Vector3.FORWARD)
	if not error.is_empty():
		return error
	return "" if int(_events.get("exit", 0)) == 1 and int(_events.get("completion", 0)) == 1 and _exact((_level.call("state") as Dictionary).contact, state.contact) else "actual return contact duplicated progression or replaced the spent contact sample"


func _tombstone_error(id: String) -> String:
	var source: CharacterBody3D = _sources[id]
	var state: Dictionary = source.call("state")
	var body: CollisionShape3D = source.get_node("BodyCollision") as CollisionShape3D
	if state.dead != true or float(state.hp) != 0.0 or state.phase != "defeated" or not String(state.reservation_id).is_empty() or source.is_in_group("enemies") or source.visible or source.collision_layer != 0 or source.collision_mask != 0 or not body.disabled or not source.velocity.is_zero_approx() or int(_death_events.get(id, 0)) != 1:
		return id + ": real stable tombstone/death/body/group/lease lifecycle differs"
	var route: Dictionary = _level.call("state")
	if not route.deaths.has(id) or Codec.read_vector3(route.deaths[id].source_position) != source.global_position:
		return id + ": authored dead history lost the actual source pose"
	return ""


func _final_error(pockets: int) -> String:
	var state: Dictionary = _level.call("state")
	var expected: int = 5 if pockets == 4 else pockets
	if state.entered.size() != pockets or state.cleared.size() != expected or _checkpoints.size() != pockets or not _roundtrip_done or (pockets >= 2 and not _fresh_partial_done):
		return "selected route entry/death/checkpoint or actual moving retry evidence is incomplete"
	for id: String in state.cleared:
		var error: String = _tombstone_error(id)
		if not error.is_empty():
			return error
	var stored: Array[Dictionary] = _hero.get_world_action_records()
	var tail: Array = _actions.slice(maxi(0, _actions.size() - stored.size()))
	if not _exact(tail, stored) or _actions.is_empty():
		return "full executed event history and bounded public history tail differ"
	for action: Dictionary in _actions:
		if action.get("kind") not in ["dash", "primary"] or not _exact(action.get("equipment_ids"), _kit):
			return "full route used an unsupported action or changed equipment"
	if _hero.hp != _hp_before or _hero.dead or int(_events.get("contact", 0)) != 0 or int(_events.get("fired_blast", 0)) != 0 or int(_game.get("cores")) != 0 or int(_game.get("kills")) != 0 or not get_nodes_in_group("lab_weapons").is_empty() or not get_nodes_in_group("practice_targets").is_empty():
		return "route took damage/healed/used blast/pickup or granted unrelated rewards"
	if pockets == 4:
		if _requires_crossing_union() and not _union_seen:
			return "full route missing actual two-source union evidence: union_seen=false; crossing_primary_deferred=" + str(_crossing_primary_deferred)
		if not _level.is_completed() or int(_events.get("completion", 0)) != 1 or int(_events.get("exit", 0)) != 1:
			return "full route contact progression differs: completed=%s completion_count=%d exit_count=%d" % [_level.is_completed(), int(_events.get("completion", 0)), int(_events.get("exit", 0))]
		if not get_nodes_in_group("enemies").is_empty() or not _scheduler.reservations().is_empty():
			return "full route cleanup differs: enemy_count=%d retained_lease_count=%d" % [get_nodes_in_group("enemies").size(), _scheduler.reservations().size()]
	elif _level.is_completed() or int(_events.get("completion", 0)) != 0 or int(_events.get("exit", 0)) != 0:
		return "focused partial route falsely completed/left the level"
	return ""


func _tick_safe() -> String:
	var error: String = _tick_barrier_error()
	if not error.is_empty():
		return error
	var traced: bool = _tick_trace_enabled()
	var before: Dictionary = _tick_clock_observation()
	var boundary: String = ""
	if paused:
		# A node already paused cannot receive another pause notification.
		# Settle ordinary deferred shell work while both real clocks stay frozen.
		await process_frame
		boundary = "already_paused_process_boundary"
		var after: Dictionary = _tick_clock_observation()
		if not _exact(before.hero_clock_s, after.hero_clock_s) or not _exact(before.scheduler_clock_s, after.scheduler_clock_s):
			return "already-paused test observation advanced a real actor clock"
	else:
		_tick_barrier.waiting = true
		boundary = await _tick_barrier.observed
	if traced:
		_tick_trace.append({"before": before, "boundary": boundary, "post_actor": _tick_clock_observation()})
		if _tick_trace.size() > 6:
			_tick_trace.pop_front()
	error = _live_error()
	if not error.is_empty():
		return error
	if _capture_portrait:
		for id: String in SourceIds:
			var source: CharacterBody3D = _sources[id]
			var state: Dictionary = source.call("state")
			if state.phase not in ["warning", "lock", "active", "recovery"]:
				continue
			if state.phase == "active" and (source.velocity.is_zero_approx() or float(_active_travel.get(state.reservation_id, 0.0)) <= 0.1):
				continue
			error = await _capture(id + "-" + String(state.phase))
			if not error.is_empty():
				return error
	return ""


func _tick_barrier_error() -> String:
	if not is_instance_valid(_tick_barrier) or _tick_barrier.get_parent() != root or _tick_barrier.process_mode != Node.PROCESS_MODE_PAUSABLE or not _tick_barrier.is_physics_processing() or _tick_barrier.process_physics_priority != 1000:
		return "TEST ONLY post-actor physics barrier is missing or incorrectly scheduled"
	var actors: Array = [_hero, _scheduler, _level]
	actors.append_array(_sources.values())
	for actor: Variant in actors:
		if is_instance_valid(actor) and actor.process_physics_priority >= _tick_barrier.process_physics_priority:
			return "TEST ONLY observation barrier does not follow an actual actor binding"
	return ""


func _free_tick_barrier() -> void:
	if is_instance_valid(_tick_barrier):
		_tick_barrier.waiting = false
		if _tick_barrier.get_parent() == root:
			root.remove_child(_tick_barrier)
		_tick_barrier.queue_free()
	_tick_barrier = null


func _tick_trace_enabled() -> bool:
	return _kit_selector in ["--compound-extreme", "--long-dash"]


func _tick_clock_observation() -> Dictionary:
	return {
		"hero_clock_s": _hero.get_world_action_clock() if is_instance_valid(_hero) else -1.0,
		"scheduler_clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else -1.0,
		"physics_frames": Engine.get_physics_frames(),
		"process_frames": Engine.get_process_frames(),
	}


func _print_tick_deadline_diagnostic(target: float, actual: float) -> void:
	var dashes: Array[Dictionary] = []
	if is_instance_valid(_hero):
		for action: Dictionary in _hero.get_world_action_records():
			if action.get("kind") != "dash":
				continue
			var stats: Dictionary = action.get("resolved_stats", {})
			dashes.append({
				"sequence": action.get("sequence"),
				"started_at_s": action.get("started_at_s"),
				"completed_at_s": action.get("completed_at_s"),
				"origin": Codec.vector3(action.world_origin) if action.get("world_origin") is Vector3 else "unavailable",
				"landing": Codec.vector3(action.landing) if action.get("landing") is Vector3 else "unavailable",
				"stats_duration_s": stats.get("dash_duration"),
				"blocked": action.get("blocked"),
				"collision_shortened": action.get("collision_shortened"),
			})
			if dashes.size() > 2:
				dashes.pop_front()
	var source: Variant = _sources.get(_source_id)
	var source_state: Dictionary = source.call("state") if is_instance_valid(source) else {}
	var diagnostic: Dictionary = {
		"target_s": target, "actual_s": actual,
		"lateness_s": actual - target, "allowed_s": _tick_s() + TimeEpsilon,
		"path_segment": _trace_path_segment.duplicate(true), "source_id": _source_id,
		"source_lease": source_state.get("reservation_id", ""), "source_phase": source_state.get("phase", "unavailable"),
		"clock_observations": _tick_trace.duplicate(true), "last_completed_dashes": dashes,
	}
	print("FIXED TICK DEADLINE DIAGNOSTIC: " + ExactJson.stringify(diagnostic))


func _live_error() -> String:
	var barrier_error: String = _tick_barrier_error()
	if not barrier_error.is_empty():
		return barrier_error
	if not is_instance_valid(_hero) or not is_instance_valid(_level) or not is_instance_valid(_scheduler) or _hero.hp != _hp_before or _hero.dead or _scheduler.get_clock() > _route_deadline or int(_events.get("contact", 0)) != 0:
		return "actual route lost actors, took/healed damage or exceeded finite simulation budget"
	var level_state: Dictionary = _level.call("state")
	if not String(level_state.get("configuration_error", "")).is_empty() or not _exact(_hero.equipment.snapshot(), _kit) or int(_events.get("equipment", 0)) != 0 or int(_events.get("fired_blast", 0)) != 0 or _world_topology() != _topology:
		return "actual authored runtime/configuration/equipment/topology changed"
	if not _floor_hit(_hero.global_position):
		return "actual hero left the continuous authored floor"
	for id: String in SourceIds:
		var source: CharacterBody3D = _sources[id]
		var state: Dictionary = source.call("state")
		if float(state.hp) != float(_expected_hp[id]):
			return "actual source HP changed outside an ordinary primary: " + id
	var records: Array[Dictionary] = _scheduler.reservations()
	if records.size() >= 2:
		_union_seen = true
	for record: Dictionary in records:
		var id: String = _source_for_record(record)
		if id.is_empty():
			return "shared reservation is not bound to one of the five actual source bodies"
		if not _records.has(record.id):
			_records[record.id] = record.duplicate(true)
			_phases[record.id] = {}
			_active_travel[record.id] = 0.0
		if not _exact(_fixed_record(record), _fixed_record(_records[record.id])):
			return "a held full-level lane, source origin/direction or deadline retargeted"
		var source: CharacterBody3D = _sources[id]
		var state: Dictionary = source.call("state")
		var cue: CinderThreatCue = source.call("get_cue") as CinderThreatCue
		var cue_state: Dictionary = cue.state()
		if state.reservation_id != record.id or state.phase != record.state or cue_state.get("phase") != record.state or not _exact(cue_state.get("geometry"), record.geometry) or cue_state.get("source_position") != source.global_position or cue_state.get("source_visible") != true:
			return "actual full-level source/canonical lane/common source cue phase differs"
		_phases[record.id][record.state] = true
		if record.state == "active":
			_active_travel[record.id] = maxf(float(_active_travel[record.id]), source.global_position.distance_to(record.adapter.start))
		if record.state == "recovery" and (source.global_position.distance_to(record.adapter.planned_endpoint) > PointTolerance or not source.velocity.is_zero_approx()):
			return "actual physical source did not stop at its advertised recovery endpoint"
	return ""


func _observe() -> Dictionary:
	var positions: Dictionary = {}
	var velocities: Dictionary = {}
	var states: Dictionary = {}
	var cues: Dictionary = {}
	for id: String in SourceIds:
		var source: CharacterBody3D = _sources[id]
		positions[id] = source.global_position
		velocities[id] = source.velocity
		states[id] = source.call("state")
		states[id].erase("proof") # Diagnostic witness intentionally clears on restore.
		cues[id] = (source.call("get_cue") as CinderThreatCue).state()
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state(), "hero_position": _hero.global_position, "hero_velocity": _hero.velocity, "source_positions": positions, "source_velocities": velocities, "source_states": states, "cues": cues, "records": _scheduler.reservations(), "exit_cue": _exit_cue.state(), "motifs": _motifs.position, "events": _events.duplicate(true)}


func _capture(label: String) -> String:
	if not _capture_portrait or _captured.has(label):
		return ""
	if DisplayServer.get_name() == "headless":
		return "--capture-portrait requires a queued graphical viewport"
	var directory: String = ProjectSettings.globalize_path(CapturePath)
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return "cannot create owned actual portrait output directory"
	# Freeze only the observed gameplay frame while rendering/writing it.
	# Opening the bench would replace the live HUD; an unpaused await could
	# consume fixed ticks and falsely miss this driver's real proof deadline.
	var previous_pause: bool = paused
	paused = true
	await RenderingServer.frame_post_draw
	if label in ["final-available-contact-cue", "final-spent-contact-exit"]:
		var contact_points: Array = _level.camera_framing_points()
		var contact_view_error: String = _level.last_camera_framing_error
		if contact_view_error.is_empty():
			contact_view_error = String(_game.call("camera_framing_error", contact_points))
		if not _expect(contact_points.size() == 8 and contact_view_error.is_empty(), "actual " + label + " contains the whole native contact marker, approach region and hero", contact_view_error):
			paused = previous_pause
			return "completed contact presentation is not wholly inside the actual protected view"
	var actual: Image = root.get_texture().get_image()
	var file: String = directory.path_join(label + ".png")
	var saved: bool = actual != null and not actual.is_empty() and actual.save_png(file) == OK
	paused = previous_pause
	if not saved:
		return "actual portrait viewport failed to save: " + file
	_captured[label] = true
	print("ACTUAL PORTRAIT: %s clock=%.9f hero=%s" % [file, _scheduler.get_clock(), _hero.global_position])
	return ""


func _source_for_record(record: Dictionary) -> String:
	for id: String in SourceIds:
		if record.get("source_instance_id") == (_sources[id] as CharacterBody3D).get_instance_id():
			return id
	return ""


func _fixed_record(record: Dictionary) -> Dictionary:
	var result: Dictionary = {"id": record.id, "source_instance_id": record.source_instance_id, "geometry": record.geometry, "armed": record.armed, "start": record.adapter.start, "direction": record.adapter.direction, "endpoint": record.adapter.planned_endpoint, "body_collision_path": record.adapter.body_collision_path}
	for key: String in FixedDeadlines:
		result[key] = record[key]
	return result


func _floor_hit(point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.25, point - Vector3.UP * 0.25, 1)
	var hit: Dictionary = _hero.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == _floor


func _world_topology() -> Array[int]:
	var result: Array[int] = []
	var world: Node = _game.get("world") as Node
	if world != null:
		for child: Node in world.get_children():
			result.append(child.get_instance_id())
	return result


func _on_source_state(state: Dictionary, id: String) -> void:
	_event("source_phase")
	if state.get("phase") == "warning" and state.get("proof", {}).get("accepted") == true:
		_warnings[String(state.reservation_id)] = {"id": id, "proof": state.proof.duplicate(true)}


func _on_contact(_result: Dictionary, _id: String) -> void:
	_event("contact")


func _on_death(_where: Vector3, id: String) -> void:
	_death_events[id] = int(_death_events.get(id, 0)) + 1
	_event("death")


func _on_checkpoint(_level_id: String, checkpoint: String, _kind: String) -> void:
	_checkpoints.append(checkpoint)
	_event("checkpoint")


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
	return Vector3(point.x, 0.0, point.z)


func _tick_s() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


func _frame_limit(seconds: float) -> int:
	return int(ceilf(seconds * float(Engine.physics_ticks_per_second))) + 8


func _diagnostic() -> String:
	return str({"clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else -1.0, "source_id": _source_id, "public_level": _level.call("state") if is_instance_valid(_level) else {}, "hero": _hero.get_threat_response_state() if is_instance_valid(_hero) else {}, "events": _events, "pending": _warnings.keys()})


## Read-only actual-body queries at the first failed route scope. Derived
## residuals describe public query output; none substitutes for an accepted
## adapter, moves the source, reserves a proof or changes a numeric threshold.
func _print_source_physical_diagnostic() -> void:
	if not is_instance_valid(_hero) or not is_instance_valid(_level) or not _sources.has(_source_id) or not is_instance_valid(_sources[_source_id]):
		print("PHYSICAL SOURCE DIAGNOSTIC: current actual source is unavailable")
		return
	var source: CharacterBody3D = _sources[_source_id]
	var state_before: Dictionary = source.call("state")
	var response: Dictionary = _level.call("combat_response", _source_id)
	var regions: Variant = response.get("floor_regions")
	var direction: Variant = state_before.get("facing")
	if not regions is Array or not direction is Vector3:
		print("PHYSICAL SOURCE DIAGNOSTIC: actual public response/facing is unavailable")
		return
	var from: Transform3D = source.global_transform
	var velocity: Vector3 = source.velocity
	var hero_before: Dictionary = _hero.get_threat_response_state()
	var events_before: Dictionary = _events.duplicate(true)
	var tuning: Dictionary = CinderAct3SunboundStalker.TUNING
	var motion: Dictionary = {"body_collision_path": "BodyCollision", "direction": direction, "distance": tuning.lunge_distance, "speed": tuning.lunge_speed, "damage_radius": tuning.damage_radius}
	var intended: Vector3 = direction * float(motion.distance)
	var sweep: Dictionary = CinderBodySweep.sweep(source, from, intended, regions)
	var plan: Dictionary = CinderLungeMotion.plan(source, motion, regions)
	var steps: Array = sweep.get("steps", [])
	var samples: Array[Dictionary] = []
	var previous: Vector3 = from.origin
	var addition_residual_count: int = 0
	var cumulative_residual_count: int = 0
	var cumulative_above_epsilon_count: int = 0
	var maximum_addition_residual: float = 0.0
	var maximum_cumulative_residual: float = 0.0
	var collided_count: int = 0
	for index: int in range(steps.size()):
		var step: Dictionary = steps[index]
		var end: Vector3 = step.end
		var travel: Vector3 = step.travel
		var addition_residual: Vector3 = (end - previous) - travel
		var cumulative: Vector3 = end - from.origin
		var projection: float = cumulative.dot(direction)
		var residual: Vector3 = cumulative - direction * projection
		addition_residual_count += 1 if addition_residual.length() > 0.0 else 0
		cumulative_residual_count += 1 if residual.length() > 0.0 else 0
		cumulative_above_epsilon_count += 1 if residual.length() > CinderLungeMotion.EPSILON else 0
		maximum_addition_residual = maxf(maximum_addition_residual, addition_residual.length())
		maximum_cumulative_residual = maxf(maximum_cumulative_residual, residual.length())
		collided_count += 1 if step.collided else 0
		if index < 3 or index >= steps.size() - 3:
			var collider_rid: RID = step.collider_rid
			samples.append({"index": index, "start": Codec.vector3(previous), "end": Codec.vector3(end), "motion": Codec.vector3(step.motion), "reported_travel": Codec.vector3(travel), "raw_travel": Codec.vector3(step.raw_travel), "endpoint_addition_residual": Codec.vector3(addition_residual), "endpoint_addition_residual_length": addition_residual.length(), "cumulative_projection": projection, "cumulative_offaxis": Codec.vector3(residual), "cumulative_offaxis_length": residual.length(), "floor_recovery": Codec.vector3(step.floor_recovery), "cancelled_recovery": Codec.vector3(step.cancelled_recovery), "collided": step.collided, "collider_rid": collider_rid.get_id(), "normal": Codec.vector3(step.normal), "safe_fraction": step.safe_fraction, "unsafe_fraction": step.unsafe_fraction})
		previous = end
	var total: Vector3 = sweep.get("travel", Vector3.ZERO)
	var projection: float = total.dot(direction)
	var residual: Vector3 = total - direction * projection
	var public_plan: Dictionary = plan.duplicate(true)
	for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "direction"]:
		if public_plan.get(key) is Vector3:
			public_plan[key] = Codec.vector3(public_plan[key])
	if public_plan.get("geometry") is Dictionary:
		for key: String in public_plan.geometry:
			if public_plan.geometry[key] is Vector3:
				public_plan.geometry[key] = Codec.vector3(public_plan.geometry[key])
	var collision: CollisionShape3D = source.get_node_or_null("BodyCollision") as CollisionShape3D
	var capsule: Dictionary = {}
	if collision != null and collision.shape is CapsuleShape3D:
		var shape: CapsuleShape3D = collision.shape as CapsuleShape3D
		capsule = {"node": String(collision.get_path()), "disabled": collision.disabled, "local_position": Codec.vector3(collision.position), "global_position": Codec.vector3(collision.global_position), "radius": shape.radius, "height": shape.height, "shape_margin": shape.margin, "bottom_y": collision.global_position.y - shape.height * 0.5}
	var floors: Array[Dictionary] = []
	for region: Dictionary in regions:
		var floor_shape: CollisionShape3D = region.get("collision") as CollisionShape3D
		if floor_shape == null or not floor_shape.shape is BoxShape3D:
			continue
		var box: BoxShape3D = floor_shape.shape as BoxShape3D
		var rect: Rect2 = region.safe_rect
		floors.append({"collision": String(floor_shape.get_path()), "global_position": Codec.vector3(floor_shape.global_position), "size": Codec.vector3(box.size), "top_y": floor_shape.global_position.y + box.size.y * 0.5, "safe_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	var pure: bool = source.global_transform == from and source.velocity == velocity and _exact(state_before, source.call("state")) and _exact(hero_before, _hero.get_threat_response_state()) and _exact(events_before, _events)
	var report: Dictionary = {"source_id": _source_id, "clock_s": _scheduler.get_clock(), "source_phase": state_before.phase, "last_rejection": state_before.last_rejection, "source_position": Codec.vector3(from.origin), "source_velocity": Codec.vector3(velocity), "source_margin": source.safe_margin, "source_grounded": source.is_on_floor(), "hero_position": Codec.vector3(_hero.global_position), "hero_stable": response.get("stable"), "facing": Codec.vector3(direction), "facing_length": direction.length(), "facing_length_squared": direction.length_squared(), "intended": Codec.vector3(intended), "intended_endpoint": Codec.vector3(from.origin + intended), "distance": motion.distance, "speed": motion.speed, "damage_radius": motion.damage_radius, "capsule": capsule, "floors": floors, "sweep_error": sweep.get("error", ""), "sweep_error_step_index": sweep.get("step_index", -1), "sweep_travel": Codec.vector3(total), "sweep_endpoint": Codec.vector3(sweep.get("end", from.origin)), "sweep_collided": sweep.get("collided", false), "projection": projection, "projection_minus_requested_distance": projection - float(motion.distance), "offaxis": Codec.vector3(residual), "offaxis_length": residual.length(), "motion_epsilon": CinderLungeMotion.EPSILON, "step_count": steps.size(), "collided_step_count": collided_count, "endpoint_addition_residual_count": addition_residual_count, "maximum_endpoint_addition_residual": maximum_addition_residual, "cumulative_offaxis_nonzero_count": cumulative_residual_count, "cumulative_offaxis_above_epsilon_count": cumulative_above_epsilon_count, "maximum_cumulative_offaxis": maximum_cumulative_residual, "first_last_three_steps": samples, "lunge_plan": public_plan, "actual_source_hero_events_unchanged": pure}
	# Full-precision decimal rendering is diagnostic only. Snapshot transport
	# remains published ExactJson; no decoded decimal feeds gameplay or proof.
	print("PHYSICAL SOURCE DIAGNOSTIC: " + JSON.stringify(report, "", false, true))


func _dispose() -> void:
	var barrier_ref: Variant = _tick_barrier
	_free_tick_barrier()
	if is_instance_valid(_game) and is_instance_valid(_hero):
		_game.call("open_bench")
	if is_instance_valid(_level):
		_level.exit_level()
	_expect(not is_instance_valid(_scheduler) or _scheduler.reservations().is_empty(), "public full-level exit releases every source lease")
	var refs: Array = [_game, _hero, _level, _scheduler, _old_hero, _old_level, barrier_ref]
	for source: Variant in _sources.values():
		refs.append(source)
	if is_instance_valid(_game):
		if _game.get_parent() == root:
			root.remove_child(_game)
		_game.queue_free()
	paused = false
	for _tick: int in range(4):
		await process_frame
	await create_timer(0.15, true, false, true).timeout
	var clean: bool = true
	for node: Variant in refs:
		clean = clean and not is_instance_valid(node)
	for group: String in ["enemies", "practice_targets", "lab_weapons", "required_cues"]:
		clean = clean and get_nodes_in_group(group).is_empty()
	_expect(clean, "full actual source/lab/floor/cue lifecycle frees with finite audio drain and no group remnants")
	_game = null
	_hero = null
	_level = null
	_scheduler = null
	_sources.clear()
	_old_hero = null
	_old_level = null


## Native exact equality preserves transport types and scalar values.
func _exact(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	if a is float:
		return var_to_bytes(a) == var_to_bytes(b)
	if a is Dictionary:
		if a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not _exact(a[key], b[key]):
				return false
		return true
	if a is Array:
		if a.size() != b.size():
			return false
		for index: int in range(a.size()):
			if not _exact(a[index], b[index]):
				return false
		return true
	return a == b


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok


func _finish() -> void:
	print("Twin Suns authored actual route: %d checks, %d failures; route=%s kit=%s captures=%d" % [_checks, _failures, _route_selector, _kit_selector, _captured.size()])
	quit(0 if _failures == 0 else 1)
