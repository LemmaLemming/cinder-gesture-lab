extends SceneTree
## Actual signed-sun rule-room evidence with the shared MainScene/player.
## Public mechanic calls are automated engine evidence, not native OS gestures,
## human balance, portrait art acceptance, a full clear or campaign acceptance.
## Native dictionaries only: this does not establish JSON transport correctness.
## No source/player position, private control, damage or substitute actor is used.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_stalker_room.tscn"
const SourcePath: String = "res://scripts/acts/act3/sunbound_stalker.gd"
const Baseline: Dictionary = {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}
const WarningBudgetS: float = 4.0
const CaseBudgetS: float = 30.0
const PointTolerance: float = 0.005
const FixedDeadlines: Array[String] = ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]
const FixedAdapter: Array[String] = ["kind", "start", "direction", "planned_endpoint", "speed", "distance", "duration_s", "damage_radius", "body_collision_path", "body_signature", "collision_shortened"]

var _checks: int = 0
var _failures: int = 0
var _attempted: int = 0
var _passed: int = 0
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _source: CharacterBody3D
var _scheduler: CinderThreatScheduler
var _cue: CinderThreatCue
var _floor: StaticBody3D
var _motifs: Node3D
var _old_hero: Variant
var _old_level: Variant
var _stats: Dictionary = {}
var _events: Dictionary = {}
var _actions: Array[Dictionary] = []
var _topology: Array[int] = []
var _hp_before: float = 0.0
var _source_hp: float = 0.0
var _deadline: float = 0.0
var _sun: int = 0
var _record: Dictionary = {}
var _commit: Dictionary = {}
var _warning_art_path: String = ""
var _phases: Dictionary = {}
var _active_travel: float = 0.0
var _approach_travel: float = 0.0
var _turn_travel: float = 0.0
var _closest_gap: float = INF
var _backed_away: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var selector: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if not _expect(selector.is_empty() and argument in ["--sun0-only", "--sun1-only", "--close-only"], "one supported focused selector", argument):
			_finish()
			return
		selector = argument
	var cases: Array[Dictionary] = []
	if selector.is_empty() or selector == "--sun0-only":
		cases.append({"sun": 0, "close": false})
	if selector.is_empty() or selector == "--sun1-only":
		cases.append({"sun": 1, "close": false})
	if selector.is_empty() or selector == "--close-only":
		cases.append({"sun": 0, "close": true})
	for entry: Dictionary in cases:
		if not await _case(int(entry["sun"]), bool(entry["close"])):
			break
	if _failures == 0:
		_expect(_attempted == cases.size() and _passed == cases.size(), "every selected actual case completes its bounded native rule proof")
	else:
		print("STOPPED after first meaningful failure: attempted=%d passed=%d intended=%d; later cases unattempted" % [_attempted, _passed, cases.size()])
	_finish()


func _case(sun: int, close_entry: bool) -> bool:
	_attempted += 1
	_sun = sun
	_events.clear()
	_actions.clear()
	_record.clear()
	_commit.clear()
	_phases.clear()
	_active_travel = 0.0
	_approach_travel = 0.0
	_turn_travel = 0.0
	_closest_gap = INF
	_backed_away = false
	print("CASE: native signed flank Sun%d; close_entry=%s; baseline public mechanics" % [sun, close_entry])
	var reason: String = _prepare()
	if reason.is_empty():
		await process_frame
		await process_frame
		reason = _initial_sun(sun)
	if not _expect(reason.is_empty(), "paused public baseline carryover enters local v4/source v3 before any encounter tick", reason):
		await _dispose()
		return false
	_game.call("resume_lab")
	_deadline = _scheduler.get_clock() + CaseBudgetS
	if close_entry and not _expect(_hero.request_dash(Vector3.FORWARD), "close entry begins a real forward dash before the first encounter tick"):
		await _dispose()
		return false
	var warning: Dictionary = await _first_warning(close_entry)
	if warning.is_empty():
		await _dispose()
		return false
	if not _admission(warning, close_entry):
		await _dispose()
		return false
	if not await _flip_warning():
		await _dispose()
		return false
	_game.call("resume_lab")
	if not await _until_phase("lock") or not await _near_dash():
		await _dispose()
		return false
	if not await _until_moving_active() or not await _active_native_restore():
		await _dispose()
		return false
	_game.call("resume_lab")
	if not await _until_phase("recovery") or not _recovery() or not _ordinary_primary():
		await _dispose()
		return false
	if not _expect(_scheduler.get_clock() <= _deadline and not _level.is_completed() and String(_level.current_checkpoint()["id"]).is_empty() and int(_game.get("cores")) == 0 and int(_game.get("kills")) == 0, "isolated signed-flank proof awards no checkpoint, production clear, pickup or reward"):
		await _dispose()
		return false
	var clean: bool = await _dispose()
	if clean:
		_passed += 1
	return clean


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
	for slot: String in ["jacket", "pants", "shoes", "weapon"]:
		if not lab_hero.equip_item(String(Baseline[slot])):
			return "public baseline equip failed: " + slot
	_stats = lab_hero.equipment.resolved_stats()
	if not paused or not _game.call("load_level_scene", RoomPath):
		return "public paused carryover transition failed"
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	if _hero == null or _level == null or _hero == lab_hero or _level.scene_file_path != RoomPath or not _level.contract_error().is_empty():
		return "actual rule room/new shared hero failed to enter"
	_source = _level.get("stalker") as CharacterBody3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if _source == null or _scheduler == null or _source.get_script().resource_path != SourcePath or not _source.is_in_group("enemies"):
		return "actual owned source/scheduler is unavailable"
	_cue = _source.call("get_cue") as CinderThreatCue
	_motifs = _level.find_child("ScenicSuns", true, false) as Node3D
	var scenery: Node = _level.get("scenery") as Node
	_floor = scenery.get("floor_body") as StaticBody3D if scenery != null else null
	if _cue == null or _floor == null or _motifs == null or _hero.presentation_id != "act3_traveller" or not _exact(_hero.equipment.snapshot(), Baseline) or not _exact(_hero.stats, _stats):
		return "shared traveller, baseline, floor, scenic motifs or required cue differs"
	_game.call("open_bench")
	_hero.shells = 0 # Public no-blast-ammo fixture; shared natural reload is retained.
	_hp_before = _hero.hp
	_source_hp = float((_source.call("state") as Dictionary)["hp"])
	_topology = _world_topology()
	_source.connect("state_changed", func(_state: Dictionary) -> void: _event("source_phase"))
	_source.connect("hit_resolved", func(_result: Dictionary) -> void: _event("source_contact"))
	_source.connect("died", func(_where: Vector3) -> void: _event("source_death"))
	_cue.state_changed.connect(func(_state: Dictionary) -> void: _event("cue"))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _event("cancel"))
	_hero.world_action_executed.connect(_on_world_action)
	_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
	_hero.action_resolved.connect(func(kind: String, _hits: int, _damage: float) -> void: _event("resolved_" + kind))
	_hero.equipment_changed.connect(func(_id: String) -> void: _event("equipment"))
	_hero.died.connect(func() -> void: _event("hero_death"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _event("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _event("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _event("exit"))
	return ""


func _initial_sun(sun: int) -> String:
	var state: Dictionary = _source.call("state")
	if not paused or _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0 or int(state.get("cycle", -1)) != 0 or not _scheduler.reservations().is_empty() or _hero.shells != 0:
		return "setup advanced clocks/reservation or failed zero-ammo setup"
	var native: Dictionary = _level.snapshot_state()
	if native.is_empty() or native.get("local_snapshot_version") != 4 or native["local"]["stalker"].get("api_revision") != "act3-stalker-snapshot-3" or native["local"]["stalker"].get("schema_version") != 3:
		return "signed commit requires native source schema3 / local envelope4: " + _level.last_snapshot_error
	var before: Dictionary = _events.duplicate(true)
	native["local"]["scenery"]["sun_state"] = sun
	var error: String = _level.snapshot_error(native)
	if not error.is_empty() or not _level.restore_state(native):
		return "native initial sun rejected: " + error + "; " + _level.last_snapshot_error
	state = _source.call("state")
	return "" if _exact(before, _events) and _hero.hp == _hp_before and _hero.shells == 0 and _scheduler.get_clock() == 0.0 and state.get("sun_visual") == sun and state.get("effective_sun") == sun else "initial native sun changed resources/events/clocks or did not reach the actor"


func _first_warning(close_entry: bool) -> Dictionary:
	var stop: float = _scheduler.get_clock() + WarningBudgetS
	var previous: Dictionary = _source.call("state")
	var previous_clock: float = _scheduler.get_clock()
	var close_dash: bool = not close_entry
	for _index: int in range(_frame_limit(WarningBudgetS)):
		var state: Dictionary = _source.call("state")
		var now: float = _scheduler.get_clock()
		var gap: float = _planar(_hero.global_position - _source.global_position).length()
		_closest_gap = minf(_closest_gap, gap)
		if not String(state.get("reservation_id", "")).is_empty():
			if not _expect(state.get("phase") == "warning" and int(state.get("cycle", -1)) == 1 and now <= stop, "first accepted physical lease is observed in warning within four simulation seconds"):
				return {}
			if close_entry:
				var history: Array[Dictionary] = _hero.get_world_action_records()
				close_dash = history.size() == 1 and history[0].get("kind") == "dash" and history[0].get("blocked") == false and history[0].get("collision_shortened") == false and absf(float(history[0].get("distance", 0.0)) - float(_stats["dash_distance"])) <= PointTolerance
			if not _expect(close_dash, "close-entry setup publishes its actual full forward dash before admission"):
				return {}
			return state
		if now > stop:
			break
		var elapsed: float = now - previous_clock
		if elapsed > 0.0:
			var step: Vector3 = _planar(_source.global_position - (previous["position"] as Vector3))
			var turn: float = absf((previous["facing"] as Vector3).signed_angle_to(state["facing"], Vector3.UP))
			if not _expect(step.length() <= float(state["resolved_role"]["move_speed"]) * elapsed + 0.001 and turn <= 1.2 * elapsed + 0.0002, "observed unleased source travels and turns within real approach bounds"):
				return {}
			_approach_travel += step.length()
			_turn_travel += turn
			# Observe actual travel away from the instantaneous hero at close gap.
			var away: Vector3 = _planar((previous["position"] as Vector3) - _hero.global_position)
			if close_entry and gap < 1.8 and not step.is_zero_approx() and step.dot(away) > 0.0:
				_backed_away = true
		previous = state
		previous_clock = now
		if not await _tick():
			return {}
	_expect(false, "actual source reaches a supported first warning within four seconds", _diagnostic())
	return {}


func _admission(state: Dictionary, close_entry: bool) -> bool:
	_record = _scheduler.reservation_state(String(state["reservation_id"]))
	_commit = (state.get("commit", {}) as Dictionary).duplicate(true)
	var body: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	if not _expect(not _record.is_empty() and _record.get("armed") == true and _record.get("state") == "warning" and _record.get("source_instance_id") == _source.get_instance_id() and _record.get("adapter", {}).get("kind") == "lunge" and body != null and body.shape is CapsuleShape3D and not body.disabled and _source.collision_layer == 2 and _source.collision_mask == 1, "warning binds the actual living capsule and shared physical lunge adapter"):
		return false
	var shape: CapsuleShape3D = body.shape as CapsuleShape3D
	if not _expect(is_equal_approx(shape.radius, 0.32) and is_equal_approx(shape.height, 1.45) and body.position.is_equal_approx(Vector3(0.0, 0.73, 0.0)) and _source.get_world_3d() == _hero.get_world_3d(), "real measured body uses the centred authored footprint in the shared world"):
		return false
	if not _expect(_commit.size() == 4 and _commit.get("sun_choice") == _sun and _commit.get("source_position") == _source.global_position and _commit.get("hero_position") == _hero.global_position and _commit.get("facing") == state["facing"], "native commit retains the actual admitted sun, source, hero and facing"):
		return false
	var toward: Vector3 = _planar(_commit["hero_position"] - _commit["source_position"])
	var expected: Vector3 = toward.normalized().rotated(Vector3.UP, deg_to_rad(20.0) * (1.0 if _sun == 0 else -1.0)).normalized()
	var adapter: Dictionary = _record["adapter"]
	if not _expect(toward.length() >= 1.8 and toward.length() <= 2.0 and (state["facing"] as Vector3).dot(expected) >= 0.99999 and adapter.get("start") == _commit["source_position"] and adapter.get("direction") == _commit["facing"] and _source.velocity.is_zero_approx() and _hero.get_threat_response_state().get("stable") == true, "actual stopped brace admits only gap 1.8–2.0 and the signed twenty-degree heading"):
		return false
	var art: Dictionary = _source.call("get_art_state")
	_warning_art_path = String(art.get("source_path", ""))
	if not _expect(art.get("visible") == true and art.get("facing") == (state["facing"] as Vector3).normalized() and art.get("sun_state") == _sun and _warning_art_path.contains("alppain" if _sun == 1 else "branchspell") and _approach_travel > 0.01 and _turn_travel > 0.1, "source genuinely approaches and visibly turns before its corresponding candidate crest warns"):
		return false
	var proof: Dictionary = state.get("proof", {})
	if not _expect(proof.get("accepted") == true and proof.get("uses_blast") == false and proof.get("uses_invulnerability") == false and proof.get("path") is Array and not proof["path"].is_empty() and float(proof.get("primary_time_s", 0.0)) > float(_record["active_until_s"]), "live admission retains a floor-supported ordinary-primary witness without blast or invulnerability"):
		return false
	var response: Dictionary = _level.call("combat_response")
	var bindings: Dictionary = _level.call("scheduler_bindings")
	if not _expect(response.get("actor") == _hero and _exact(response.get("equipment_ids"), Baseline) and _exact(response.get("stats"), _stats) and bindings.get("owners", {}).get("rule-stalker") == _source and bindings.get("floors", {}).get("shelf-floor", {}).get("collision") == _floor.get_child(0), "actual admission response and stable floor/source bindings retain the real selected shared actor"):
		return false
	var primary_segments: int = 0
	var escape_segments: int = 0
	for segment: Dictionary in proof["path"]:
		if not _expect(segment.get("from") is Vector3 and segment.get("to") is Vector3 and _floor_hit(segment["from"]) and _floor_hit(segment["to"]), "native admitted response path endpoints lie on the actual continuous shelf"):
			return false
		primary_segments += 1 if segment.get("kind") == "ordinary_primary" else 0
		escape_segments += 1 if segment.get("kind") == "escape_dash" else 0
	if not _expect(primary_segments == 1 and escape_segments == 1, "native positive response contains one ordinary escape and one ordinary primary opportunity"):
		return false
	if close_entry and not _expect(_closest_gap < 1.8 and _backed_away and toward.length() >= 1.8, "a real close forward entry causes observed backing away before a valid separated brace"):
		return false
	_phases["warning"] = true
	return true


func _flip_warning() -> bool:
	var pair: Dictionary = await _pause_pair("native warning")
	if pair.is_empty():
		return false
	var before: Dictionary = _observe()
	var changed: Dictionary = pair["level"].duplicate(true)
	changed["local"]["scenery"]["sun_state"] = 1 - _sun # Only changed payload field.
	var input: Dictionary = changed.duplicate(true)
	var error: String = _level.snapshot_error_with_player(changed, pair["hero"])
	if not _expect(error.is_empty() and _exact(_observe(), before) and _exact(input, changed), "opposite scenic sun validates purely against the independently valid native warning hero", error):
		return false
	var events: Dictionary = _events.duplicate(true)
	if not _expect(_level.restore_state(changed), "validated local restore changes only the latest scenic sun", _level.last_snapshot_error):
		return false
	var state: Dictionary = _source.call("state")
	var after: Dictionary = _level.snapshot_state()
	if not _expect(_exact(after, changed) and _exact(_hero.snapshot_state(), pair["hero"]) and _exact(_events, events) and _exact(_scheduler.reservation_state(String(_record["id"])), _record) and _exact(_cue.state(), before["cue"]) and _exact(_source.call("get_art_state"), before["art"]), "scenic flip preserves the exact actor, physical reservation, cue, held crest and silent native state"):
		return false
	if not _expect(int(_level.get("sun_state")) == 1 - _sun and state.get("sun_visual") == 1 - _sun and state.get("effective_sun") == _sun and _exact(state.get("commit"), _commit), "latest opposite sun remains pending while this entire lease holds its original sun choice"):
		return false
	var paused_before: Dictionary = _observe()
	await process_frame
	await process_frame
	return _expect(_exact(paused_before, _observe()), "paused warning clocks, native source/hero state and held cue stay exact across deferred frames")


func _near_dash() -> bool:
	var response: Dictionary = _hero.get_threat_response_state()
	var available: float = float(_record["active_from_s"]) - _hero.get_world_action_clock()
	if not _expect(response.get("stable") == true and float(response.get("dash_cooldown_left_s", 1.0)) == 0.0 and available >= float(_stats["dash_duration"]) + 2.0 * _tick_s(), "actual lock deadline leaves the ready baseline dash time to reach a clear near landing"):
		return false
	var bearing: Vector3 = _planar(_commit["hero_position"] - _commit["source_position"]).normalized()
	var right: Vector3 = bearing.rotated(Vector3.UP, PI * 0.5).normalized()
	var chosen: Vector3 = right * (1.0 if _sun == 0 else -1.0)
	var origin: Vector3 = _hero.global_position
	var sequence: int = _last_sequence()
	var started: float = _hero.get_world_action_clock()
	if not _expect(_hero.request_dash(chosen), "public dash executes the authored source-relative near side for this held sun"):
		return false
	var actions: Array[Dictionary] = []
	for _index: int in range(_frame_limit(float(_stats["dash_duration"]) + 0.25)):
		actions = _hero.get_world_action_records(sequence)
		if not actions.is_empty():
			break
		if not await _tick():
			return false
	if not _expect(actions.size() == 1 and actions[0].get("kind") == "dash" and actions[0].get("blocked") == false and actions[0].get("collision_shortened") == false and _exact(actions[0].get("equipment_ids"), Baseline), "one completed ordinary near-side dash publishes its real collision result and equipment"):
		return false
	var action: Dictionary = actions[0]
	var landing: Vector3 = action["landing"]
	var expected: Vector3 = origin + chosen * float(_stats["dash_distance"])
	if not _expect(_planar(landing - expected).length() <= PointTolerance and _planar((action["world_origin"] as Vector3) - origin).length() <= PointTolerance and landing.distance_to(_hero.global_position) <= PointTolerance and absf(float(action["distance"]) - float(_stats["dash_distance"])) <= PointTolerance and float(action["started_at_s"]) == started and float(action["completed_at_s"]) <= float(_record["active_from_s"]) and action.get("path") is Array and action["path"].size() >= 2, "actual completed dash reaches its authored near landing before the real activation deadline"):
		return false
	for sample: Dictionary in action["path"]:
		if not _expect(_floor_hit(sample["position"]), "actual completed near-dash samples have true shelf support"):
			return false
	var near: float = _planar(landing - (_record["adapter"]["planned_endpoint"] as Vector3)).length()
	var far: Vector3 = origin - chosen * float(_stats["dash_distance"])
	return _expect(near < float(_stats["primary_range"]) and _planar(far - (_record["adapter"]["planned_endpoint"] as Vector3)).length() > float(_stats["primary_range"]), "actual near landing exposes ordinary primary reach while the opposite endpoint side requires a normal return")


func _until_phase(phase: String) -> bool:
	var deadline_key: String = "lock_from_s" if phase == "lock" else "active_until_s"
	var stop: float = minf(_deadline, float(_record[deadline_key]) + 3.0 * _tick_s())
	for _index: int in range(_frame_limit(CaseBudgetS)):
		var current: Dictionary = _source.call("state")
		if current.get("phase") == phase:
			return _expect(true, "actual reserved source presents " + phase + " at its public deadline")
		if _scheduler.get_clock() > stop:
			break
		if not await _tick():
			return false
	return _expect(false, "source reaches actual " + phase + " without losing its fixed lease", _diagnostic())


func _until_moving_active() -> bool:
	var stop: float = minf(_deadline, float(_record["active_until_s"]))
	for _index: int in range(_frame_limit(CaseBudgetS)):
		var state: Dictionary = _source.call("state")
		var travel: float = _planar(_source.global_position - (_record["adapter"]["start"] as Vector3)).length()
		var remaining: float = _planar(_source.global_position - (_record["adapter"]["planned_endpoint"] as Vector3)).length()
		if state.get("phase") == "active" and travel > 0.1 and remaining > 0.8:
			return _expect(not _source.velocity.is_zero_approx() and _active_travel > 0.1, "actual source moves its measured capsule during active before reaching the endpoint")
		if _scheduler.get_clock() > stop:
			break
		if not await _tick():
			return false
	return _expect(false, "a meaningful actual moving-active pose exists inside the fixed active window", _diagnostic())


func _active_native_restore() -> bool:
	var earlier: Dictionary = await _pause_pair("moving active, depleted ammo", true)
	if earlier.is_empty():
		return false
	var expected: Dictionary = _observe()
	if not _expect(earlier["level"]["local"]["stalker"].get("phase") == "active" and _hero.shells == 0 and _source.velocity.length() > 0.0, "earlier paired native capture contains the real moving active source and zero-ammo hero"):
		return false
	var input: Dictionary = earlier.duplicate(true)
	var before: Dictionary = _observe()
	var hero_error: String = _hero.snapshot_error(earlier["hero"])
	var pair_error: String = _level.snapshot_error_with_player(earlier["level"], earlier["hero"])
	if not _expect(hero_error.is_empty() and pair_error.is_empty() and _exact(before, _observe()) and _exact(earlier, input), "complete saved hero then moving local pair validate purely without changing live pose/clocks/resources/events", hero_error + "; " + pair_error):
		return false
	if not _forged_commit_rejections(earlier):
		return false
	_game.call("resume_lab")
	if not await _tick() or not await _tick():
		return false
	var later: Dictionary = await _pause_pair("later moving active")
	if later.is_empty():
		return false
	var before_restore: Dictionary = _observe()
	if not _expect(later["level"]["local"]["stalker"].get("phase") == "active" and _source.global_position.distance_to(expected["source_position"]) > 0.1 and _scheduler.get_clock() > float(earlier["level"]["local"]["scheduler"]["clock_s"]), "two actual ticks create a genuinely later moving source before retrying the earlier native pair"):
		return false
	hero_error = _hero.snapshot_error(earlier["hero"])
	pair_error = _level.snapshot_error_with_player(earlier["level"], earlier["hero"])
	if not _expect(hero_error.is_empty() and pair_error.is_empty() and _exact(before_restore, _observe()), "earlier moving pair validates against the saved hero while the actual source remains later", hero_error + "; " + pair_error):
		return false
	var events: Dictionary = _events.duplicate(true)
	if not _expect(_hero.restore_state(earlier["hero"]) and _level.restore_state(earlier["level"]), "silent ordered hero → actual local source/scheduler restore accepts the prevalidated earlier native pair", _hero.last_snapshot_error + "; " + _level.last_snapshot_error):
		return false
	var after: Dictionary = _observe()
	expected["events"] = events
	if not _expect(_exact(after, expected) and _exact(_events, events) and _exact(_hero.snapshot_state(), earlier["hero"]) and _exact(_level.snapshot_state(), earlier["level"]), "restored native pose, motion, clocks, resources, history, held commit, scenic follow, source cue and art are exact without new signals"):
		return false
	if not _expect(_hero.global_position == Codec.read_vector3(earlier["hero"]["motion"]["position"]) and _source.global_position == Codec.read_vector3(earlier["level"]["local"]["stalker"]["position"]) and _source.velocity == Codec.read_vector3(earlier["level"]["local"]["stalker"]["velocity"]) and _cue.state().get("source_position") == _source.global_position and _motifs.position == Vector3(_hero.global_position.x, 0.0, _hero.global_position.z), "live source marker and scenic landmarks align with their restored actual actors before a tick"):
		return false
	before = _observe()
	await process_frame
	await process_frame
	return _expect(_exact(before, _observe()), "paused moving-active native state does not advance any restored clock, motion, event or resource")


func _forged_commit_rejections(pair: Dictionary) -> bool:
	for field: String in ["sun_choice", "source_position", "facing", "old_local_version"]:
		var forged: Dictionary = pair["level"].duplicate(true)
		if field == "old_local_version":
			forged["local_snapshot_version"] = 3
		elif field == "sun_choice":
			forged["local"]["stalker"]["commit"][field] = 1 - _sun
		elif field == "source_position":
			forged["local"]["stalker"]["commit"][field][0] += 0.125
		else:
			var held: Vector3 = Codec.read_vector3(forged["local"]["stalker"]["commit"][field])
			forged["local"]["stalker"]["commit"][field] = Codec.vector3(-held)
		var input: Dictionary = forged.duplicate(true)
		var before: Dictionary = _observe()
		var error: String = _level.snapshot_error_with_player(forged, pair["hero"])
		var restored: bool = _level.restore_state(forged)
		if not _expect(not error.is_empty() and not restored and _exact(before, _observe()) and _exact(input, forged), "forged " + field + " rejects atomically and pure native proof leaves input/live state untouched", error):
			return false
	return true


func _recovery() -> bool:
	var state: Dictionary = _source.call("state")
	var current: Dictionary = _scheduler.reservation_state(String(_record["id"]))
	for phase: String in ["warning", "lock", "active", "recovery"]:
		if not _expect(_phases.has(phase), "actual capsule/cue presents observed " + phase + " in this held lease"):
			return false
	return _expect(not current.is_empty() and _active_travel > 0.1 and _source.global_position.distance_to(_record["adapter"]["planned_endpoint"]) <= PointTolerance and _source.velocity.is_zero_approx() and _floor_hit(_source.global_position) and state.get("effective_sun") == _sun and state.get("sun_visual") == 1 - _sun and (_source.call("get_art_state") as Dictionary).get("sun_state") == _sun and _cue.state().get("source_position") == _source.global_position and _cue.state().get("footprint_visible") == false, "real stopped endpoint recovery retains its original crest choice and moving source marker while the scenic flip remains pending")


func _ordinary_primary() -> bool:
	var state: Dictionary = _source.call("state")
	var response: Dictionary = _hero.get_threat_response_state()
	var toward: Vector3 = _planar(_source.global_position - _hero.global_position)
	if not _expect(response.get("stable") == true and float(response.get("primary_cooldown_left_s", 1.0)) == 0.0 and toward.length() < float(_stats["primary_range"]) and _source.is_in_group("enemies"), "near-side actual recovery body remains reachable by the same ordinary primary under either held sun"):
		return false
	_hero.shells = 0 # Public depleted fixture only; no reload clock is changed.
	var before: float = float(state["hp"])
	var ammo_before: int = _hero.shells
	var sequence: int = _last_sequence()
	var hits: int = _hero.slash(toward.normalized())
	_record.clear() # A real primary legitimately cancels this physical lease.
	var after: Dictionary = _source.call("state")
	var actions: Array[Dictionary] = _hero.get_world_action_records(sequence)
	_source_hp = float(after["hp"])
	if not _expect(hits == 1 and actions.size() == 1 and actions[0].get("kind") == "primary" and actions[0].get("hits") == 1 and float(actions[0].get("damage", 0.0)) == float(_stats["primary_damage"]) and _source_hp == maxf(before - float(_stats["primary_damage"]), 0.0) and _source_hp > 0.0 and _hero.hp == _hp_before and ammo_before == 0, "one real shared slash hits the actual whole body for ordinary damage without ammo or a crest/flank-only hitbox"):
		return false
	if not _expect(String(after.get("reservation_id", "")).is_empty() and _scheduler.reservations().is_empty() and after.get("effective_sun") == 1 - _sun and after.get("sun_visual") == 1 - _sun and _exact(after.get("commit"), _commit) and float(after.get("cooldown_until_s", 0.0)) == float(state["cooldown_until_s"]), "legitimate primary cancellation releases the pending latest sun and preserves historical commit/source cooldown"):
		return false
	return _expect(int(_events.get("source_contact", 0)) == 0 and int(_events.get("fired_blast", 0)) == 0 and int(_events.get("hero_death", 0)) == 0 and _hero.hp == _hp_before and not _hero.dead and _exact(_actions, _hero.get_world_action_records()), "executed native history contains only the real dash/primary actions, no contact tanking, blast or duplicate restore event")


func _pause_pair(label: String, deplete_ammo: bool = false) -> Dictionary:
	_game.call("open_bench")
	await process_frame
	await process_frame
	if deplete_ammo:
		_hero.shells = 0 # Public active snapshot fixture; natural reload stays shared.
	var hero_state: Dictionary = _hero.snapshot_state()
	var level_state: Dictionary = _level.snapshot_state()
	if not _expect(paused and not hero_state.is_empty() and not level_state.is_empty(), label + ": complete native pair captures at a deferred paused barrier", _hero.last_snapshot_error + "; " + _level.last_snapshot_error):
		return {}
	var error: String = _hero.snapshot_error(hero_state)
	if not _expect(error.is_empty(), label + ": complete shared saved hero independently validates first", error):
		return {}
	return {"hero": hero_state, "level": level_state}


func _observe() -> Dictionary:
	var state: Dictionary = _source.call("state")
	state.erase("proof") # Diagnostic witness intentionally clears on restore.
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state(), "hero_position": _hero.global_position, "hero_velocity": _hero.velocity, "source": state, "source_position": _source.global_position, "source_velocity": _source.velocity, "scheduler_clock_s": _scheduler.get_clock(), "record": _scheduler.reservation_state(String(state.get("reservation_id", ""))), "cue": _cue.state(), "art": _source.call("get_art_state"), "motifs_position": _motifs.position, "events": _events.duplicate(true)}


func _tick() -> bool:
	await physics_frame
	await process_frame
	var error: String = _live_error()
	return _expect(error.is_empty(), "actual case preserves its native lease, floor, resources and finite simulation budget", error) if not error.is_empty() else true


func _live_error() -> String:
	if not is_instance_valid(_hero) or not is_instance_valid(_source) or not is_instance_valid(_scheduler):
		return "actual player/source/scheduler disappeared"
	if _scheduler.get_clock() > _deadline or _hero.hp != _hp_before or _hero.dead or int(_events.get("source_contact", 0)) != 0:
		return "case exceeded thirty seconds, took contact damage or healed/died"
	if not _exact(_hero.equipment.snapshot(), Baseline) or int(_events.get("equipment", 0)) != 0 or int(_events.get("fired_blast", 0)) != 0 or int(_events.get("completion", 0)) != 0 or int(_events.get("checkpoint", 0)) != 0 or int(_events.get("exit", 0)) != 0 or _world_topology() != _topology:
		return "equipment, blast, progress or owned world topology changed"
	var state: Dictionary = _source.call("state")
	if float(state.get("hp", -1.0)) != _source_hp:
		return "source HP changed outside the real ordinary-primary call"
	if _record.is_empty():
		return ""
	var current: Dictionary = _scheduler.reservation_state(String(_record["id"]))
	var cue: Dictionary = _cue.state()
	var art: Dictionary = _source.call("get_art_state")
	if current.is_empty() or not _exact(_fixed_record(current), _fixed_record(_record)) or state.get("reservation_id") != _record["id"] or not _exact(state.get("commit"), _commit) or state.get("effective_sun") != _sun or state.get("sun_visual") != 1 - _sun or int(_level.get("sun_state")) != 1 - _sun:
		return "physical geometry/deadlines/held choice changed or pending sun did not remain latest"
	if state.get("phase") not in ["warning", "lock", "active", "recovery"] or current.get("state") != state["phase"] or cue.get("phase") != state["phase"] or not _exact(cue.get("geometry"), current.get("geometry")) or cue.get("source_position") != _source.global_position or cue.get("source_visible") != true or art.get("visible") != true or art.get("facing") != (state["facing"] as Vector3).normalized() or art.get("sun_state") != _sun:
		return "actual source, fixed footprint, facing, crest or common source cue is incoherent"
	if state["phase"] in ["warning", "lock", "active"] and art.get("source_path") != _warning_art_path:
		return "held braced crest changed during its accepted exchange"
	_phases[String(state["phase"])] = true
	if state["phase"] == "active":
		_active_travel = maxf(_active_travel, _planar(_source.global_position - (_record["adapter"]["start"] as Vector3)).length())
	if not _floor_hit(_hero.global_position) or not _floor_hit(_source.global_position):
		return "actual hero/source left supported continuous shelf"
	return ""


func _fixed_record(record: Dictionary) -> Dictionary:
	var fixed: Dictionary = {"id": record.get("id"), "source_instance_id": record.get("source_instance_id"), "geometry": record.get("geometry"), "armed": record.get("armed"), "adapter": {}}
	for key: String in FixedDeadlines:
		fixed[key] = record.get(key)
	for key: String in FixedAdapter:
		fixed["adapter"][key] = record.get("adapter", {}).get(key)
	return fixed


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


func _last_sequence() -> int:
	var history: Array[Dictionary] = _hero.get_world_action_records()
	return int(history[-1]["sequence"]) if not history.is_empty() else 0


func _planar(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)


func _tick_s() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


func _frame_limit(seconds: float) -> int:
	return int(ceilf(seconds * float(Engine.physics_ticks_per_second))) + 8


func _on_world_action(action: Dictionary) -> void:
	_actions.append(action.duplicate(true))
	_event("world_action")


func _event(kind: String) -> void:
	_events[kind] = int(_events.get(kind, 0)) + 1


func _dispose() -> bool:
	if is_instance_valid(_game) and is_instance_valid(_hero):
		_game.call("open_bench")
	else:
		paused = true
	if is_instance_valid(_level):
		_level.exit_level()
	var released: bool = not is_instance_valid(_scheduler) or _scheduler.reservations().is_empty()
	_expect(released, "public room exit releases every physical source reservation")
	var refs: Array = [_game, _hero, _source, _level, _scheduler, _cue, _old_hero, _old_level]
	if is_instance_valid(_game):
		if _game.get_parent() == root:
			root.remove_child(_game)
		_game.queue_free()
	paused = false
	for _index: int in range(4):
		await process_frame
	# Effects.clear stops its actual child AudioStreamPlayers at public exit.
	# A finite real-time drain allows the audio server to retire stopped voices;
	# no warning is suppressed and no actor continues processing during it.
	await create_timer(0.25, true, false, true).timeout
	var clean: bool = released
	for actor: Variant in refs:
		clean = clean and not is_instance_valid(actor)
	for group: String in ["enemies", "practice_targets", "lab_weapons", "required_cues"]:
		clean = clean and get_nodes_in_group(group).is_empty()
	_expect(clean, "finite cleanup frees actual lab/room/source/cue actors and drains retired audio without a proxy or group remnant")
	_game = null
	_level = null
	_hero = null
	_source = null
	_scheduler = null
	_cue = null
	_floor = null
	_motifs = null
	_old_hero = null
	_old_level = null
	return clean


func _diagnostic() -> String:
	return str({"clock_s": _scheduler.get_clock(), "hero": _hero.get_threat_response_state(), "source": _source.call("state"), "cue": _cue.state(), "events": _events})


## Native exact equality; no tolerance, serialization or parser conversion.
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


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok


func _finish() -> void:
	print("Stalker signed-sun native flank: %d checks, %d failures; selected cases=%d passed=%d" % [_checks, _failures, _attempted, _passed])
	quit(0 if _failures == 0 else 1)
