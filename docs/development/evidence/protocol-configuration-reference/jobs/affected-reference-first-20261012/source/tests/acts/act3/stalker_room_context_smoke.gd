extends SceneTree
## Native saved-player pairing proof in the actual MainScene/rule room.
## Public request_dash calls are automated mechanic evidence, not native OS
## gestures or human play. This fixture covers an idle source/contact sample,
## harmless sun clocks and ordered native restore. It requires no accepted
## lunge and establishes no attack-phase, checkpoint or campaign acceptance.
## No JSON serialization/parse or replacement hero participates in this proof.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_stalker_room.tscn"
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const EndpointTolerance: float = 0.005

var _checks: int = 0
var _failures: int = 0
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _source: CharacterBody3D
var _scheduler: CinderThreatScheduler
var _cue: CinderThreatCue
var _motifs: Node3D
var _events: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("CASE: native saved-player proof, actual idle Stalker and harmless suns")
	if await _open_room():
		await _context_case()
	await _close_room()
	print("Stalker native saved-player context: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _open_room() -> bool:
	_game = MainScene.instantiate()
	_game.set("level_scene_path", RoomPath)
	root.add_child(_game)
	var spawned: CinderPlayer = _game.get("player") as CinderPlayer
	if spawned != null:
		# Public depleted resources make any accidental reset/heal visible.
		spawned.hp = 31.25
		spawned.shells = 0
	await _ticks(12)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(_level != null and _hero != null and _level.scene_file_path == RoomPath and _level.contract_error().is_empty(), "actual rule room and shared player enter through MainScene"):
		return false
	_source = _level.get("stalker") as CharacterBody3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if not _expect(_source != null and _scheduler != null and _source.has_method("state") and _source.has_method("get_cue"), "room retains the real owned source and shared scheduler"):
		return false
	_cue = _source.call("get_cue") as CinderThreatCue
	_motifs = _level.find_child("ScenicSuns", true, false) as Node3D
	if not _expect(_cue != null and _motifs != null and _hero.is_on_floor() and _hero.presentation_id == "act3_traveller", "real shared traveller, public cue and scenic suns are ready on the floor"):
		return false
	_source.connect("state_changed", func(_state: Dictionary) -> void: _count_event("source_phase"))
	_source.connect("hit_resolved", func(_result: Dictionary) -> void: _count_event("source_hit"))
	_source.connect("died", func(_where: Vector3) -> void: _count_event("source_death"))
	_cue.state_changed.connect(func(_state: Dictionary) -> void: _count_event("cue"))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _count_event("cancellation"))
	_hero.world_action_executed.connect(func(_record: Dictionary) -> void: _count_event("world_action"))
	_hero.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: _count_event("action"))
	_hero.fired.connect(func(_kind: String) -> void: _count_event("fired"))
	_hero.died.connect(func() -> void: _count_event("hero_death"))
	_hero.equipment_changed.connect(func(_id: String) -> void: _count_event("equipment"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _count_event("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _count_event("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _count_event("exit"))
	return _expect(_hero.hp == 31.25 and _hero.shells == 0 and _source.get_world_3d() == _hero.get_world_3d(), "nonfull HP and zero ammo belong to the actual shared world")


func _context_case() -> void:
	# These two ordinary paths remain inside the source's three-unit stop range.
	if not await _dash_completed(Vector3.FORWARD, "earlier forward dash"):
		return
	var earlier: Dictionary = await _pause_pair("earlier idle pair")
	if earlier.is_empty():
		return
	var earlier_source: Dictionary = _source.call("state")
	var earlier_cue: Dictionary = _cue.state()
	if not _idle_sample(earlier, "earlier"):
		return
	var paused_before: Dictionary = _observe()
	await process_frame
	await process_frame
	_expect(_exact(_observe(), paused_before), "paused source/scheduler/sun/player clocks, pose, resources and events stay exact across deferred frames")

	_game.call("resume_lab")
	if not await _wait_dash_ready():
		return
	if not await _dash_completed(Vector3.BACK, "later return dash"):
		return
	var later: Dictionary = await _pause_pair("later idle pair")
	if later.is_empty():
		return
	if not _idle_sample(later, "later"):
		return
	var earlier_position: Vector3 = Codec.read_vector3(earlier["hero"]["motion"]["position"])
	var later_position: Vector3 = Codec.read_vector3(later["hero"]["motion"]["position"])
	_expect(earlier_position.distance_to(later_position) > 2.0 and _hero.global_position == later_position and _hero.get_world_action_records().size() == 2, "a second completed ordinary dash creates a genuinely different receiving hero and completed history")
	_expect(float(later["level"]["local"]["scheduler"]["clock_s"]) > float(earlier["level"]["local"]["scheduler"]["clock_s"]) and float(later["level"]["local"]["scenery"]["sun_elapsed_s"]) > float(earlier["level"]["local"]["scenery"]["sun_elapsed_s"]), "resumed actual scheduler and harmless sun clocks advance before the later paused capture")

	var before_proof: Dictionary = _observe()
	var earlier_copy: Dictionary = earlier.duplicate(true)
	var later_copy: Dictionary = later.duplicate(true)
	# The complete shared actor must be independently valid before context proof.
	var old_hero_error: String = _hero.snapshot_error(earlier["hero"])
	var new_hero_error: String = _hero.snapshot_error(later["hero"])
	if not _expect(old_hero_error.is_empty() and new_hero_error.is_empty(), "both complete saved shared actors independently validate before authored pair proof; old=" + old_hero_error + "; new=" + new_hero_error):
		return
	var old_pair_error: String = _level.snapshot_error_with_player(earlier["level"], earlier["hero"])
	_expect(old_pair_error.is_empty(), "earlier local state accepts its independently validated saved hero while the actual hero remains later; " + old_pair_error)
	var live_error: String = _level.snapshot_error(earlier["level"])
	_expect(live_error == "Stalker contact sample must match the paired hero position", "live-only proof correctly rejects the earlier local sample against the different actual hero; " + live_error)
	var crossed_error: String = _level.snapshot_error_with_player(earlier["level"], later["hero"])
	_expect(crossed_error == "Stalker contact sample must match the paired hero position", "independently valid newer hero cross-forged with earlier local state rejects; " + crossed_error)

	var forged: Dictionary = earlier["level"].duplicate(true)
	forged["local"]["stalker"]["previous"]["hero_position"] = later["hero"]["motion"]["position"].duplicate()
	var forged_error: String = _level.snapshot_error_with_player(forged, earlier["hero"])
	_expect(forged_error == "Stalker contact sample must match the paired hero position", "copying the receiving hero position into an old contact sample cannot authorize the original saved hero; " + forged_error)
	# A context hook must retain the complete local validator, not just the hero
	# sample check. These two owned corruptions exercise its scenery/source pair.
	var bad_sun: Dictionary = earlier["level"].duplicate(true)
	bad_sun["local"]["scenery"]["sun_elapsed_s"] = -0.125
	_expect(not _level.snapshot_error_with_player(bad_sun, earlier["hero"]).is_empty(), "saved-player context still rejects an invalid authored sun clock")
	var bad_clock: Dictionary = earlier["level"].duplicate(true)
	bad_clock["local"]["scheduler"]["clock_s"] += 0.125
	_expect(not _level.snapshot_error_with_player(bad_clock, earlier["hero"]).is_empty(), "saved-player context still rejects a mismatched source/scheduler clock")
	_expect(_exact(earlier, earlier_copy) and _exact(later, later_copy), "pure validators preserve both input pairs by value")
	_expect(_exact(_observe(), before_proof), "all accepted and rejected pure proofs leave actual pose, resources, histories, clocks, source/cue state and event counts exact")

	_restore_earlier(earlier, earlier_source, earlier_cue)


func _idle_sample(pair: Dictionary, label: String) -> bool:
	var local: Dictionary = pair["level"]["local"]
	var source: Dictionary = local["stalker"]
	var scheduler: Dictionary = local["scheduler"]
	var previous: Dictionary = source["previous"]
	return _expect(source["phase"] == "idle" and String(source["reservation_id"]).is_empty() and scheduler["reservations"].is_empty() and _cue.state()["phase"] == "clear" and float(previous["clock_s"]) == float(scheduler["clock_s"]) and Codec.read_vector3(previous["hero_position"]) == Codec.read_vector3(pair["hero"]["motion"]["position"]), label + " fixture has a same-tick actual idle source/hero sample and clear cue; attack phases remain outside this proof")


func _restore_earlier(pair: Dictionary, expected_source: Dictionary, expected_cue: Dictionary) -> void:
	var events_before: Dictionary = _events.duplicate(true)
	var prevalidated: bool = _hero.snapshot_error(pair["hero"]).is_empty() and _level.snapshot_error_with_player(pair["level"], pair["hero"]).is_empty()
	if not _expect(paused and prevalidated, "complete native aggregate prevalidates before either component commits"):
		return
	if not _expect(_hero.restore_state(pair["hero"]), "actual shared hero restores first with saved resources and completed history; " + _hero.last_snapshot_error):
		return
	var live_error: String = _level.snapshot_error(pair["level"])
	if not _expect(live_error.is_empty() and _level.restore_state(pair["level"]), "ordered actual hero then local restore accepts at the same paused barrier; " + live_error + "; " + _level.last_snapshot_error):
		return
	var restored: Dictionary = {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}
	_expect(_exact(restored, pair), "native recapture exactly preserves actor/local pose, clocks, resources, scenery and completed history without JSON transport")
	var local: Dictionary = pair["level"]["local"]
	var motion: Dictionary = pair["hero"]["motion"]
	var basis: Array = motion["basis"]
	_expect(_hero.global_position == Codec.read_vector3(motion["position"]) and _hero.velocity == Codec.read_vector3(motion["velocity"]) and _hero.facing == Codec.read_vector3(motion["facing"]) and _hero.global_basis == Basis(Codec.read_vector3(basis[0]), Codec.read_vector3(basis[1]), Codec.read_vector3(basis[2])), "actual restored hero equals its native position/velocity/facing/basis exactly")
	_expect(_source.global_position == Codec.read_vector3(local["stalker"]["position"]) and _source.velocity == Codec.read_vector3(local["stalker"]["velocity"]) and _exact(_source.call("state"), expected_source), "actual source pose and full public idle state equal the earlier native capture")
	_expect(_scheduler.get_clock() == float(local["scheduler"]["clock_s"]) and _scheduler.reservations().is_empty() and _exact(_cue.state(), expected_cue), "public scheduler clock and clear native cue restore exactly without a new reservation")
	_expect(int(_level.get("sun_state")) == int(local["scenery"]["sun_state"]) and float(_level.get("sun_elapsed_s")) == float(local["scenery"]["sun_elapsed_s"]) and _motifs.position == Vector3(_hero.global_position.x, 0.0, _hero.global_position.z), "actual harmless sun clock and scenic motifs match the restored hero before any tick")
	_expect(_hero.hp == 31.25 and _hero.shells == 0 and _hero.get_world_action_records().size() == 1 and _exact(_events, events_before), "ordered restore preserves nonfull HP, zero ammo and only saved history with no phase/cue/hit/action/death/equipment/progression signal")
	_expect(not _level.is_completed() and String(_level.current_checkpoint()["id"]).is_empty(), "native rule proof awards no production checkpoint or campaign completion")


func _pause_pair(label: String) -> Dictionary:
	_game.call("open_bench")
	await process_frame
	await process_frame
	var hero_state: Dictionary = _hero.snapshot_state()
	var level_state: Dictionary = _level.snapshot_state()
	if not _expect(paused and not hero_state.is_empty() and not level_state.is_empty(), label + ": native pair captures outside callbacks at the deferred paused barrier; hero=" + _hero.last_snapshot_error + "; level=" + _level.last_snapshot_error):
		return {}
	return {"hero": hero_state, "level": level_state}


func _observe() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state(), "hero_position": _hero.global_position, "hero_velocity": _hero.velocity, "source": _source.call("state"), "source_position": _source.global_position, "source_velocity": _source.velocity, "scheduler_clock_s": _scheduler.get_clock(), "reservations": _scheduler.reservations(), "cue": _cue.state(), "motifs_position": _motifs.position, "events": _events.duplicate(true)}


func _wait_dash_ready() -> bool:
	for _index: int in range(_frame_limit(0.75)):
		var response: Dictionary = _hero.get_threat_response_state()
		if bool(response.get("stable", false)) and float(response.get("dash_cooldown_left_s", 1.0)) <= 0.0:
			return true
		await _ticks(1)
	return _expect(false, "bounded public response wait reaches a grounded stopped hero with dash cooldown expired")


func _dash_completed(direction: Vector3, label: String) -> bool:
	var history: Array[Dictionary] = _hero.get_world_action_records()
	var sequence: int = int(history[-1]["sequence"]) if not history.is_empty() else 0
	var origin: Vector3 = _hero.global_position
	var stats: Dictionary = _hero.equipment.resolved_stats()
	var accepted: bool = _hero.request_dash(direction)
	var actions: Array[Dictionary] = []
	for _index: int in range(_frame_limit(float(stats["dash_duration"]) + 0.25)):
		actions = _hero.get_world_action_records(sequence)
		if not actions.is_empty():
			break
		await _ticks(1)
	var valid: bool = accepted and actions.size() == 1
	if valid:
		var action: Dictionary = actions[0]
		var path: Array = action["path"]
		valid = action["kind"] == "dash" and not bool(action["blocked"]) and not bool(action["collision_shortened"]) and float(action["completed_at_s"]) > float(action["started_at_s"]) and path.size() >= 2 and (action["world_origin"] as Vector3).distance_to(origin) <= EndpointTolerance and (action["landing"] as Vector3).distance_to(_hero.global_position) <= EndpointTolerance and absf(float(action["distance"]) - float(stats["dash_distance"])) <= 0.02
	return _expect(valid, label + ": one actual full ordinary dash publishes a bounded completed path and landing")


func _frame_limit(seconds: float) -> int:
	return int(ceilf(seconds * float(Engine.physics_ticks_per_second))) + 8


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _close_room() -> void:
	if is_instance_valid(_level):
		_level.exit_level()
	if is_instance_valid(_scheduler):
		_expect(_scheduler.reservations().is_empty(), "public rule-room exit releases every source reservation")
	if is_instance_valid(_game):
		_game.queue_free()
	paused = false
	await process_frame
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("practice_targets").is_empty(), "cleanup releases the actual source and creates no substitute target")


func _count_event(kind: String) -> void:
	_events[kind] = int(_events.get(kind, 0)) + 1


## Native exact comparison: no tolerance or JSON transport conversion.
func _exact(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
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


func _expect(ok: bool, label: String) -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)
	return ok
