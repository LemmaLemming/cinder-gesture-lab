extends SceneTree
## Representative actual-source clears, following each published live witness.
## Enumerate all 108 public static kits, then deduplicate baseline/extreme kits.
## This executes public mechanic calls, not routed/native gestures or human play.
## Source defeat is isolated-room evidence, never campaign completion/registry,
## artwork, balance or checkpoint allocation acceptance. No actor HP is written.
## --retained-active-restore-only: baseline Sun0 actual moving capture, two-hit
## death, pure tombstone prevalidation and quiet same-world earlier-live retry.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const EquipmentScript: GDScript = preload("res://scripts/equipment.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_stalker_room.tscn"
const SourcePath: String = "res://scripts/acts/act3/sunbound_stalker.gd"
const Slots: Array[String] = ["jacket", "pants", "shoes", "weapon"]
const SlotCounts: Array[int] = [3, 3, 3, 4]
const ExpectedKits: int = 108
const MaxCycles: int = 4
const CaseBudgetS: float = 30.0
const WarningBudgetS: float = 4.0
const PointTolerance: float = 0.005
const TimeEpsilon: float = 0.000001

var _checks: int = 0
var _failures: int = 0
var _attempted: int = 0
var _cleared: int = 0
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _source: CharacterBody3D
var _scheduler: CinderThreatScheduler
var _floor: StaticBody3D
var _old_hero: Variant
var _old_level: Variant
var _kit: Dictionary = {}
var _stats: Dictionary = {}
var _hp_before: float = 0.0
var _source_hp: float = 0.0
var _case_deadline: float = 0.0
var _events: Dictionary = {}
var _world_nodes: Array[int] = []
var _action_events: Array[Dictionary] = []
var _primary_count: int = 0
var _dash_count: int = 0
var _current_record: Dictionary = {}
var _phases: Dictionary = {}
var _active_travel: float = 0.0
var _retained_active_restore: bool = false
var _saved_active_pair: Dictionary = {}
var _saved_active_history: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var selector: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument not in ["--baseline-sun0-only", "--baseline-sun1-only", "--sun0-only", "--extremes-sun0-only", "--retained-active-restore-only"] or not selector.is_empty():
			_expect(false, "one supported focused selector", argument)
			_finish()
			return
		selector = argument
	_retained_active_restore = selector == "--retained-active-restore-only"
	var catalogue: CinderEquipment = EquipmentScript.new() as CinderEquipment
	var choices: Dictionary = {}
	var ids: Dictionary = {}
	for index: int in range(Slots.size()):
		var slot: String = Slots[index]
		var available: Array[Dictionary] = catalogue.available_items(slot)
		if not _expect(available.size() == SlotCounts[index], "public catalogue has expected implemented " + slot + " choices"):
			_finish()
			return
		choices[slot] = available
		for item: Dictionary in available:
			var id: String = String(item.get("id", ""))
			if not _expect(not id.is_empty() and item.get("slot") == slot and item.get("perk_id") == null and catalogue.is_implemented(id) and not ids.has(id), "actual static catalogue identity " + id):
				_finish()
				return
			ids[id] = true
	var kits: Array[Dictionary] = []
	for jacket: Dictionary in choices["jacket"]:
		for pants: Dictionary in choices["pants"]:
			for shoes: Dictionary in choices["shoes"]:
				for weapon: Dictionary in choices["weapon"]:
					var kit: Dictionary = {"jacket": jacket["id"], "pants": pants["id"], "shoes": shoes["id"], "weapon": weapon["id"]}
					if not catalogue.restore(kit) or not catalogue.acceptance_errors().is_empty():
						_expect(false, "108-kit enumeration uses valid public equipment resolutions", _kit_key(kit) + ": " + str(catalogue.acceptance_errors()))
						_finish()
						return
					kits.append({"kit": kit, "stats": catalogue.resolved_stats()})
	if not _expect(kits.size() == ExpectedKits and ids.size() == 13, "actual public model enumerates exactly 108 legal static combinations"):
		_finish()
		return
	catalogue.reset_starter()
	var baseline_key: String = _kit_key(catalogue.snapshot())
	var baseline: Dictionary = {}
	for entry: Dictionary in kits:
		if _kit_key(entry["kit"]) == baseline_key:
			baseline = entry
	if not _expect(not baseline.is_empty(), "actual starter baseline belongs to the enumerated legal kits"):
		_finish()
		return
	var selected: Array[Dictionary] = []
	_add_selected(selected, baseline, "baseline")
	for field: String in ["primary_damage", "primary_range", "dash_speed", "dash_distance", "effective_health"]:
		_add_selected(selected, _extreme(kits, field, false), "min_" + field)
	for field: String in ["dash_distance", "primary_cooldown", "dash_cooldown"]:
		_add_selected(selected, _extreme(kits, field, true), "max_" + field)
	print("SELECTION: %d unique representative kits from %d actual public-model combinations" % [selected.size(), kits.size()])
	for entry: Dictionary in selected:
		print("SELECTED: " + _kit_key(entry["kit"]) + "; criteria=" + str(entry["reasons"]) + "; actual_stats=" + JSON.stringify(_relevant_stats(entry["stats"]), "", true, true))
	var expected: int = selected.size() + 1
	if selector in ["--baseline-sun0-only", "--baseline-sun1-only", "--retained-active-restore-only"]:
		expected = 1
	elif selector == "--sun0-only":
		expected = selected.size()
	elif selector == "--extremes-sun0-only":
		expected = selected.size() - 1
	if selector in ["--baseline-sun0-only", "--baseline-sun1-only", "--retained-active-restore-only"]:
		await _case(baseline, 1 if selector == "--baseline-sun1-only" else 0)
	else:
		for entry: Dictionary in selected:
			if selector == "--extremes-sun0-only" and _kit_key(entry["kit"]) == baseline_key:
				continue
			if not await _case(entry, 0):
				break
		if _failures == 0 and selector.is_empty():
			await _case(baseline, 1)
	if _failures == 0:
		_expect(_attempted == expected and _cleared == expected, "every selected case actually clears its source within four cycles / thirty simulation seconds")
	else:
		print("STOPPED after first failing case: attempted=%d cleared=%d intended=%d; later cases unattempted" % [_attempted, _cleared, expected])
	_finish()


func _extreme(kits: Array[Dictionary], field: String, maximum: bool) -> Dictionary:
	var chosen: Dictionary = kits[0]
	for entry: Dictionary in kits:
		var value: float = float(entry["stats"][field])
		var current: float = float(chosen["stats"][field])
		if (maximum and value > current) or (not maximum and value < current) or (value == current and _kit_key(entry["kit"]) < _kit_key(chosen["kit"])):
			chosen = entry
	return chosen


func _add_selected(selected: Array[Dictionary], entry: Dictionary, reason: String) -> void:
	for chosen: Dictionary in selected:
		if _kit_key(chosen["kit"]) == _kit_key(entry["kit"]):
			chosen["reasons"].append(reason)
			return
	var added: Dictionary = entry.duplicate(true)
	added["reasons"] = [reason]
	selected.append(added)


func _case(entry: Dictionary, sun: int) -> bool:
	_attempted += 1
	_kit = entry["kit"].duplicate(true)
	_stats = entry["stats"].duplicate(true)
	_events.clear()
	_action_events.clear()
	_current_record.clear()
	_saved_active_pair.clear()
	_saved_active_history.clear()
	_primary_count = 0
	_dash_count = 0
	print("CASE: sun%d %s actual_stats=%s" % [sun, _kit_key(_kit), JSON.stringify(_relevant_stats(_stats), "", true, true)])
	var reason: String = _prepare()
	if reason.is_empty():
		# Retire removed lab actors/targets while the NEW room stays paused.
		# The prepare function has already completed every equip/transition
		# synchronously, and no encounter physics has run.
		await process_frame
		await process_frame
		if not paused or _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0:
			reason = "deferred setup barrier advanced encounter physics"
	if reason.is_empty() and sun == 1:
		reason = await _configure_sun_one()
	if not _expect(reason.is_empty(), "public paused-lab loadout enters a fresh actual room before its first physics tick", reason + ("; " + _diagnostic() if not reason.is_empty() else "")):
		await _dispose()
		return false
	_game.call("resume_lab")
	_case_deadline = _scheduler.get_clock() + CaseBudgetS
	var previous_cycle: int = 0
	for _attempt: int in range(MaxCycles):
		var warning: Dictionary = await _next_warning(previous_cycle)
		if warning.is_empty():
			reason = "no next accepted physical warning within the bounded wait"
			break
		previous_cycle = int(warning["cycle"])
		reason = await _follow_proof(warning)
		if not _expect(reason.is_empty(), "cycle %d executes published paths and one real ordinary-primary hit" % previous_cycle, reason + ("; " + _diagnostic() if not reason.is_empty() else "")):
			break
		if bool((_source.call("state") as Dictionary)["dead"]):
			break
	var state: Dictionary = _source.call("state")
	if reason.is_empty() and not bool(state.get("dead", false)):
		reason = "source remains alive after four actual cycles: hp=" + str(state.get("hp"))
	var clear_error: String = _clear_error()
	if reason.is_empty():
		reason = clear_error
	if reason.is_empty() and _retained_active_restore:
		if _primary_count != 2 or float(state.hp) != 0.0:
			reason = "retained retry requires the actual baseline two-primary 36→16→0 defeat"
		else:
			_expect(true, "retained retry first establishes genuine baseline ordinary-primary 36→16→0 death")
			reason = await _restore_retained_active_after_death()
	var passed: bool = reason.is_empty()
	if passed:
		_cleared += 1
	var result_label: String = "actual ordinary-primary death then pure retained-body proof, exact silent revival and safe saved-motion recovery" if _retained_active_restore else "representative source is truly defeated by ordinary primary with no blast/pickup/heal/reward/progress"
	_expect(passed, result_label, reason + ("; " + _diagnostic() if not passed else ""))
	var clean: bool = await _dispose()
	return passed and clean


func _prepare() -> String:
	paused = false
	_game = MainScene.instantiate()
	root.add_child(_game)
	var lab_hero: CinderPlayer = _game.get("player") as CinderPlayer
	_old_hero = lab_hero
	_old_level = _game.get("active_level")
	if lab_hero == null or not _game.call("is_lab_level") or not get_nodes_in_group("enemies").is_empty():
		return "public enemy-free lab boundary is unavailable"
	_game.call("open_bench")
	if not paused:
		return "public lab bench did not pause"
	# No await between lab construction, all public equips and scene transition.
	for slot: String in Slots:
		if not lab_hero.equip_item(String(_kit[slot])):
			return "public equipment rejected " + String(_kit[slot])
	if not _exact(lab_hero.equipment.snapshot(), _kit) or not _game.call("load_level_scene", RoomPath):
		return "public carryover/room transition rejected the selected loadout"
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	if _hero == null or _level == null or _hero == lab_hero or _level.scene_file_path != RoomPath or not _level.contract_error().is_empty():
		return "actual room/new shared hero did not enter"
	_source = _level.get("stalker") as CharacterBody3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if _source == null or _scheduler == null or not _source.has_method("state") or _source.get_script().resource_path != SourcePath or not _source.is_in_group("enemies"):
		return "actual owned living source / public scheduler binding is unavailable"
	var scenery: Node = _level.get("scenery") as Node
	_floor = scenery.get("floor_body") as StaticBody3D if scenery != null else null
	if _floor == null or _hero.presentation_id != "act3_traveller" or not _exact(_hero.equipment.snapshot(), _kit) or not _exact(_hero.equipment.resolved_stats(), _stats) or not _exact(_hero.stats, _stats):
		return "actual floor/traveller/selected equipment resolution differs"
	var state: Dictionary = _source.call("state")
	if int(state.get("cycle", -1)) != 0 or not String(state.get("reservation_id", "")).is_empty() or _hero.get_world_action_clock() != 0.0 or not _scheduler.reservations().is_empty():
		return "physics or an old-kit reservation ran before setup finished"
	_game.call("open_bench")
	if not paused:
		return "new room pause boundary unavailable"
	_hero.shells = 0 # Public fixture only; natural reload remains permitted.
	_hp_before = _hero.hp
	_source_hp = float(state["hp"])
	_world_nodes = _world_topology()
	_source.connect("hit_resolved", func(_result: Dictionary) -> void: _event("source_hit"))
	_source.connect("died", func(_where: Vector3) -> void: _event("source_death"))
	if _retained_active_restore:
		_source.connect("state_changed", func(_state: Dictionary) -> void: _event("source_phase"))
		var cue: CinderThreatCue = _source.call("get_cue") as CinderThreatCue
		cue.state_changed.connect(func(_state: Dictionary) -> void: _event("source_cue"))
		_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _event("source_cancel"))
	_hero.world_action_executed.connect(_on_action)
	_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
	_hero.action_resolved.connect(func(kind: String, _hits: int, _damage: float) -> void: _event("resolved_" + kind))
	_hero.equipment_changed.connect(func(_id: String) -> void: _event("equipment"))
	_hero.died.connect(func() -> void: _event("hero_death"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _event("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _event("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _event("exit"))
	return "" if _hero.shells == 0 and _hp_before > 0.0 else "fresh depleted-ammo/resource fixture failed"


func _configure_sun_one() -> String:
	await process_frame
	await process_frame
	if not paused or _hero.get_world_action_clock() != 0.0:
		return "native configured-sun barrier advanced physics"
	var native: Dictionary = _level.snapshot_state()
	if native.is_empty():
		return "native configured-sun capture rejected: " + _level.last_snapshot_error
	var before_events: Dictionary = _events.duplicate(true)
	native["local"]["scenery"]["sun_state"] = 1
	if not _level.snapshot_error(native).is_empty() or not _level.restore_state(native):
		return "native configured-sun restore rejected: " + _level.last_snapshot_error
	return "" if int(_level.get("sun_state")) == 1 and _exact(_events, before_events) and _hero.hp == _hp_before else "native sun setup emitted an event or changed resources"


func _next_warning(previous_cycle: int) -> Dictionary:
	var deadline: float = minf(_case_deadline, _scheduler.get_clock() + WarningBudgetS)
	for _index: int in range(_frame_limit(WarningBudgetS)):
		var state: Dictionary = _source.call("state")
		if _scheduler.get_clock() > deadline:
			break
		if not String(state.get("reservation_id", "")).is_empty():
			if state.get("phase") == "warning" and int(state.get("cycle", -1)) == previous_cycle + 1:
				return state
			_expect(false, "next observed reservation is the next actual warning", _diagnostic())
			return {}
		if state.get("phase") not in ["idle", "approach"] or bool(state.get("dead", false)):
			_expect(false, "unleased source uses its supported idle/approach phases", _diagnostic())
			return {}
		var error: String = await _tick_safe()
		if not error.is_empty():
			_expect(false, "waiting actual source remains safe and inside its bounded simulation budget", error + "; " + _diagnostic())
			return {}
	_expect(false, "physical source obtains its next accepted warning within four seconds", _diagnostic())
	return {}


func _follow_proof(state: Dictionary) -> String:
	var record: Dictionary = _scheduler.reservation_state(String(state["reservation_id"]))
	var proof: Variant = state.get("proof")
	if record.is_empty() or not proof is Dictionary or proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not proof.get("path") is Array:
		return "source lacks its actual accepted ammo-free, immunity-free path proof"
	if record.get("armed") != true or record.get("state") != "warning" or not record.get("adapter") is Dictionary or record["adapter"].get("kind") != "lunge" or not record.get("geometry") is Dictionary or record["geometry"].get("kind") != "lane":
		return "accepted source is not an armed actual physical-lunge reservation"
	var response: Dictionary = _level.call("combat_response")
	if record.get("source_instance_id") != _source.get_instance_id() or response.get("actor") != _hero or not _exact(response.get("equipment_ids"), _kit) or not _exact(response.get("stats"), _stats):
		return "accepted live witness is not bound to the actual source/shared hero/selected kit"
	var path: Array = proof["path"]
	if path.is_empty() or path.size() > 6 or not Geometry.finite_number(proof.get("primary_time_s")) or not Geometry.finite_number(proof.get("response_complete_s")):
		return "accepted finite path/deadlines unavailable"
	var escapes: int = 0
	var primaries: int = 0
	var positioning: int = 0
	var typed_path: Array[Dictionary] = []
	var previous: Dictionary = {}
	for value: Variant in path:
		if not value is Dictionary or not Geometry.finite_vector(value.get("from")) or not Geometry.finite_vector(value.get("to")) or not Geometry.finite_number(value.get("start_s")) or not Geometry.finite_number(value.get("end_s")):
			return "actual path contains a malformed native segment"
		var segment: Dictionary = value
		if segment.get("kind") not in ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"] or float(segment["end_s"]) < float(segment["start_s"]) or float(segment["start_s"]) < float(record["start_s"]) - TimeEpsilon or float(segment["end_s"]) > float(record["recovery_until_s"]):
			return "actual segment phase/time lies outside the reserved response"
		if not previous.is_empty() and (absf(float(previous["end_s"]) - float(segment["start_s"])) > TimeEpsilon or (previous["to"] as Vector3).distance_to(segment["from"]) > PointTolerance):
			return "accepted native proof path is discontinuous"
		escapes += 1 if segment["kind"] == "escape_dash" else 0
		primaries += 1 if segment["kind"] == "ordinary_primary" else 0
		positioning += 1 if segment["kind"] == "positioning_dash" else 0
		if segment["kind"] == "escape_dash" and (segment["to"] != proof.get("landing") or absf(float(segment["end_s"]) - float(segment["start_s"]) - float(_stats["dash_duration"])) > TimeEpsilon):
			return "published escape landing/duration differs from actual live kit"
		if segment["kind"] == "ordinary_primary" and (absf(float(segment["start_s"]) - float(proof["primary_time_s"])) > TimeEpsilon or absf(float(segment["end_s"]) - float(proof["response_complete_s"])) > TimeEpsilon):
			return "published primary segment disagrees with authoritative proof times"
		typed_path.append(segment)
		previous = segment
	if escapes != 1 or primaries != 1 or positioning > 1 or (path[0]["from"] as Vector3).distance_to(_hero.global_position) > PointTolerance or float(proof["primary_time_s"]) <= float(record["active_until_s"]) or float(proof["response_complete_s"]) > float(record["recovery_until_s"]):
		return "actual proof omits its live origin, single escape or reachable recovery primary"
	if Geometry.timed_path_hits(record["geometry"], typed_path, float(record["active_from_s"]), float(record["active_until_s"]), CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN):
		return "published no-immunity witness intersects its actual reserved active corridor"
	_current_record = record.duplicate(true)
	_phases = {"warning": true}
	_active_travel = 0.0
	print("ACCEPTED: cycle=%d clock=%.9f source=%s native_path=%s" % [int(state["cycle"]), _scheduler.get_clock(), _source.global_position, path])
	for value: Dictionary in path:
		var reason: String = ""
		if value["kind"] in ["escape_dash", "positioning_dash"]:
			reason = await _proof_dash(value)
		elif value["kind"] == "ordinary_primary":
			reason = await _proof_primary(value, proof)
		else:
			reason = await _hold(value)
		if not reason.is_empty():
			return String(value["kind"]) + ": " + reason
	return ""


func _hold(segment: Dictionary) -> String:
	if segment["from"] != segment["to"] or _hero.global_position.distance_to(segment["from"]) > PointTolerance:
		return "actual stationary segment does not begin at its published position"
	var deadline: float = float(segment["end_s"])
	for _index: int in range(_frame_limit(CaseBudgetS)):
		if _scheduler.get_clock() >= deadline:
			return ""
		if _retained_active_restore and _saved_active_pair.is_empty() and not _current_record.is_empty():
			var state: Dictionary = _source.call("state")
			if state.phase == "active" and _source.global_position.distance_to(_current_record.adapter.start) > 0.1 and _source.global_position.distance_to(_current_record.adapter.planned_endpoint) > 0.8:
				var capture_error: String = await _capture_retained_active_pair()
				if not capture_error.is_empty():
					return capture_error
		var error: String = await _tick_safe()
		if not error.is_empty():
			return error
		if _hero.global_position.distance_to(segment["from"]) > PointTolerance:
			return "real hero drifted during its displayed stationary segment"
	return "stationary segment exceeded finite frame budget"


func _capture_retained_active_pair() -> String:
	_game.call("open_bench")
	await process_frame
	await process_frame
	var native: Dictionary = {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}
	if not paused or native.hero.is_empty() or native.level.is_empty():
		return "moving retained-source pair capture rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	var saved_source: Dictionary = native.level.local.stalker
	if native.level.local_snapshot_version != 4 or saved_source.api_revision != "act3-stalker-snapshot-3" or saved_source.schema_version != 3:
		return "retained retry requires the explicitly adopted source3/schema3 and roomlocal4 aggregate"
	if saved_source.phase != "active" or saved_source.dead or float(saved_source.hp) != 36.0 or saved_source.hit_consumed or Codec.read_vector3(saved_source.velocity).is_zero_approx() or native.level.local.scheduler.reservations.size() != 1:
		return "capture lacks the genuine moving first-cycle living unconsumed source"
	if float(saved_source.clock_s) != float(native.level.local.scheduler.clock_s) or float(saved_source.previous.clock_s) != float(saved_source.clock_s) or Codec.read_vector3(saved_source.previous.hero_position) != Codec.read_vector3(native.hero.motion.position):
		return "captured moving source does not bind the exact current-clock hero sample"
	var encoded: String = ExactJson.stringify(native)
	if encoded.is_empty():
		return "published exact transport rejected the actual retained-source pair"
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not decoded.get("accepted", false) or not decoded.get("value") is Dictionary or not _strict_exact(native, decoded.value):
		return "exact native types/binary64 clocks/resources/history changed in retained-source transport: " + String(decoded.get("reason", ""))
	_saved_active_pair = decoded.value.duplicate(true)
	_saved_active_history = _hero.get_world_action_records()
	var input: Dictionary = _saved_active_pair.duplicate(true)
	var before: Dictionary = _retained_observation()
	var error: String = _hero.snapshot_error(_saved_active_pair.hero)
	if error.is_empty():
		error = _level.snapshot_error_with_player(_saved_active_pair.level, _saved_active_pair.hero)
	if not error.is_empty() or not _strict_exact(input, _saved_active_pair) or not _strict_exact(before, _retained_observation()):
		return "live captured exact pair prevalidation changed input/runtime or rejected: " + error
	_expect(true, "actual source3 moving-active/roomlocal4 pair exact-roundtrips with all native scalar bits and pure saved-hero validation")
	_game.call("resume_lab")
	return ""


func _restore_retained_active_after_death() -> String:
	if _saved_active_pair.is_empty():
		return "no earlier genuine moving-active pair was captured before the real defeat"
	_game.call("open_bench")
	# Let actual death's deferred CollisionShape3D update finish while all
	# simulation remains paused; no flags or PhysicsServer state are staged here.
	await process_frame
	await process_frame
	var body: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	if not paused or not _registered_collision_matches(true) or not _clear_error().is_empty():
		return "real deferred tombstone lacks registered disabled capsule/layer0/mask0: " + _clear_error()
	var dead_before: Dictionary = _retained_observation()
	var input_before: Dictionary = _saved_active_pair.duplicate(true)
	for _check: int in range(2):
		var error: String = _hero.snapshot_error(_saved_active_pair.hero)
		if error.is_empty():
			error = _level.snapshot_error_with_player(_saved_active_pair.level, _saved_active_pair.hero)
		if not error.is_empty():
			return "public pure saved actor/source/staged-collision/scheduler proof rejected actual retained tombstone: " + error
		if not _strict_exact(dead_before, _retained_observation()) or not _strict_exact(input_before, _saved_active_pair) or not _registered_collision_matches(true):
			return "repeated staged prevalidation enabled/moved/revived a real tombstone, changed input/resources/events or altered registrations"
	_expect(true, "earlier-live native collision staging repeatedly prevalidates while actual HP0 body remains disabled/layer0/mask0 with unchanged registrations/events")
	var events_before: Dictionary = _events.duplicate(true)
	var actions_before: Array[Dictionary] = _action_events.duplicate(true)
	var death_count: int = int(_events.get("source_death", 0))
	var hit_count: int = int(_events.get("source_hit", 0))
	# The whole saved pair was proved above. Commit actual hero, then the owned
	# aggregate's actual source collision/pose, scheduler and presentation; no
	# await occurs between these operations, and no fresh lease is requested.
	if not _hero.restore_state(_saved_active_pair.hero) or not _level.restore_state(_saved_active_pair.level):
		return "validated real actor-before-source/scheduler retained restore rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	var restored: Dictionary = {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}
	if not _strict_exact(restored, _saved_active_pair) or not _strict_exact(events_before, _events) or not _strict_exact(actions_before, _action_events):
		return "quiet retained restoration changed exact saved aggregate or emitted an action/hit/death/phase/cue/cancel/equipment/progression event"
	if not _registered_collision_matches(false) or body.disabled or _source.collision_layer != 2 or _source.collision_mask != 1 or not _source.is_in_group("enemies") or not _source.visible:
		return "ordered commit did not actually restore enabled registered collision/layer2/mask1/live presentation"
	var saved_source: Dictionary = _saved_active_pair.level.local.stalker
	var restored_record: Dictionary = _scheduler.reservation_state(saved_source.reservation_id)
	if restored_record.is_empty() or _source.global_position != Codec.read_vector3(saved_source.position) or _source.velocity != Codec.read_vector3(saved_source.velocity) or _scheduler.get_clock() != float(_saved_active_pair.level.local.scheduler.clock_s):
		return "actual revived source motion/lease/clock differs from earlier saved active state"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if float(restored_record[key]) != float(saved_source.exchange[key]):
			return "retained restore retimed held deadline: " + key
	_expect(true, "same actual retained body revives only during ordered commit with exact earlier active pose/velocity/lease/deadlines and zero restore events")
	var frozen: Dictionary = _retained_observation()
	await process_frame
	await process_frame
	if not _strict_exact(frozen, _retained_observation()):
		return "restored paused retained aggregate advances a clock/resource/motion/event"
	_source_hp = float(saved_source.hp) # Test bookkeeping; never an actor write.
	_current_record = restored_record.duplicate(true)
	_phases = {"active": true}
	_active_travel = _source.global_position.distance_to(restored_record.adapter.start)
	_game.call("resume_lab")
	var recovery_seen: bool = false
	for _tick: int in range(_frame_limit(1.0)):
		var error: String = await _tick_safe()
		if not error.is_empty():
			return "resumed saved physical motion: " + error
		var state: Dictionary = _source.call("state")
		if state.phase == "recovery":
			recovery_seen = true
			break
	if not recovery_seen or _source.global_position.distance_to(restored_record.adapter.planned_endpoint) > PointTolerance or not _source.velocity.is_zero_approx():
		return "saved active motion did not resume to its original stopped recovery endpoint"
	if int(_events.get("source_death", 0)) != death_count or int(_events.get("source_hit", 0)) != hit_count or not _strict_exact(_action_events, actions_before) or not _strict_exact(_hero.get_world_action_records(), _saved_active_history) or _hero.hp != float(_saved_active_pair.hero.resources.hp) or _source_hp != float(saved_source.hp):
		return "resumed saved motion produced duplicate hit/death/player action or changed source/hero HP"
	_expect(true, "resumed earlier physical lunge reaches its original stopped endpoint without a duplicate hit/death or additional player action")
	return ""


func _registered_collision_matches(disabled: bool) -> bool:
	var body: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	var owners: PackedInt32Array = _source.get_shape_owners()
	if body == null or owners.size() != 1 or body.disabled != disabled:
		return false
	var owner: int = owners[0]
	return _source.shape_owner_get_owner(owner) == body and _source.shape_owner_get_shape_count(owner) == 1 and _source.shape_owner_get_shape(owner, 0) == body.shape and _source.shape_owner_get_transform(owner) == body.transform and _source.is_shape_owner_disabled(owner) == disabled and _source.collision_layer == (0 if disabled else 2) and _source.collision_mask == (0 if disabled else 1)


func _retained_observation() -> Dictionary:
	var body: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	var registrations: Array[Dictionary] = []
	for owner: int in _source.get_shape_owners():
		registrations.append({"owner_id": owner, "owner": _source.shape_owner_get_owner(owner), "disabled": _source.is_shape_owner_disabled(owner), "count": _source.shape_owner_get_shape_count(owner), "transform": _source.shape_owner_get_transform(owner)})
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state(), "source_position": _source.global_position, "source_velocity": _source.velocity, "source_hp": _source.get("hp"), "source_dead": _source.get("dead"), "body_disabled": body.disabled, "layer": _source.collision_layer, "mask": _source.collision_mask, "visible": _source.visible, "enemies_group": _source.is_in_group("enemies"), "registrations": registrations, "events": _events.duplicate(true), "actions": _action_events.duplicate(true)}


func _strict_exact(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	if a is float:
		var left := PackedByteArray()
		var right := PackedByteArray()
		left.resize(8)
		right.resize(8)
		left.encode_double(0, a)
		right.encode_double(0, b)
		return left == right
	if a is Dictionary:
		if a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not _strict_exact(a[key], b[key]):
				return false
		return true
	if a is Array:
		if a.size() != b.size():
			return false
		for index: int in range(a.size()):
			if not _strict_exact(a[index], b[index]):
				return false
		return true
	return a == b


func _proof_dash(segment: Dictionary) -> String:
	var reason: String = await _at_time(float(segment["start_s"]))
	if not reason.is_empty():
		return reason
	if _hero.global_position.distance_to(segment["from"]) > PointTolerance:
		return "actual dash origin differs from the published native path"
	var response: Dictionary = _hero.get_threat_response_state()
	if float(response["dash_cooldown_left_s"]) != 0.0 or float(response["motion"]["dash_left_s"]) != 0.0:
		return "displayed dash would require queueing or overlap instead of an ordinary completed dash"
	var direction: Vector3 = segment["to"] - segment["from"]
	direction.y = 0.0
	if direction.length() <= 0.0:
		return "displayed dash has no planar direction"
	var sequence: int = _last_sequence()
	var started: float = _scheduler.get_clock()
	if not _hero.request_dash(direction.normalized()):
		return "public real dash rejected the displayed ready path"
	var actions: Array[Dictionary] = []
	for _index: int in range(_frame_limit(float(_stats["dash_duration"]) + 0.25)):
		actions = _hero.get_world_action_records(sequence)
		if not actions.is_empty():
			break
		var error: String = await _tick_safe()
		if not error.is_empty():
			return error
	if actions.size() != 1:
		return "real dash failed to publish exactly one completed world action"
	var action: Dictionary = actions[0]
	if action.get("kind") != "dash" or action.get("blocked") != false or action.get("collision_shortened") != false or not _exact(action.get("equipment_ids"), _kit) or not _exact(action.get("resolved_stats"), _stats):
		return "completed action is not the displayed ordinary full-kit dash"
	if (action["world_origin"] as Vector3).distance_to(segment["from"]) > PointTolerance or (action["landing"] as Vector3).distance_to(segment["to"]) > PointTolerance or _hero.global_position.distance_to(segment["to"]) > PointTolerance or absf(float(action["distance"]) - float(_stats["dash_distance"])) > PointTolerance:
		return "actual completed dash origin/landing/distance differs by more than 0.005 world units"
	if absf(float(action["started_at_s"]) - started) > TimeEpsilon or absf((float(action["completed_at_s"]) - float(action["started_at_s"])) - float(_stats["dash_duration"])) > _tick_s() + TimeEpsilon or float(action["completed_at_s"]) > float(segment["end_s"]) + 2.0 * _tick_s() + TimeEpsilon:
		return "actual dash timing exceeds the explicit fixed-step scheduling/completion bounds"
	var samples: Array = action["path"]
	if samples.size() < 2:
		return "completed real dash has no sampled native path"
	var previous_time: float = -1.0
	var previous_progress: float = -1.0
	var unit: Vector3 = direction.normalized()
	var length: float = direction.length()
	for sample: Dictionary in samples:
		var point: Vector3 = sample["position"]
		var progress: float = (point - (segment["from"] as Vector3)).dot(unit)
		var nearest: Vector3 = segment["from"] + unit * clampf(progress, 0.0, length)
		if float(sample["time_s"]) < previous_time or progress < previous_progress - PointTolerance or point.distance_to(nearest) > PointTolerance or not _floor_hit(point):
			return "actual completed samples are nonmonotonic, off the displayed straight path or unsupported by the authored floor"
		previous_time = float(sample["time_s"])
		previous_progress = progress
	_dash_count += 1
	print("DASH: kind=%s scheduled=%.9f actual=%.9f expected_landing=%s actual_landing=%s completed=%.9f" % [segment["kind"], float(segment["start_s"]), started, segment["to"], action["landing"], float(action["completed_at_s"])])
	return ""


func _proof_primary(segment: Dictionary, proof: Dictionary) -> String:
	var reason: String = await _at_time(float(proof["primary_time_s"]))
	if not reason.is_empty():
		return reason
	var state: Dictionary = _source.call("state")
	if state["phase"] != "recovery" or bool(state["dead"]) or _hero.global_position.distance_to(proof["attack_position"]) > PointTolerance or segment["from"] != segment["to"] or (segment["from"] as Vector3).distance_to(proof["attack_position"]) > PointTolerance:
		return "actual ordinary primary does not begin at the proof's recovery/attack position"
	for phase: String in ["warning", "lock", "active", "recovery"]:
		if not _phases.has(phase):
			return "real source never presented observed " + phase + " before primary"
	if _active_travel <= 0.1 or _source.global_position.distance_to(_current_record["adapter"]["planned_endpoint"]) > PointTolerance or not _source.velocity.is_zero_approx():
		return "primary opening was not reached by real moving active source and stopped physical endpoint"
	var response: Dictionary = _hero.get_threat_response_state()
	if response.get("stable") != true or float(response["primary_cooldown_left_s"]) != 0.0:
		return "proof primary requires an unstable actor or unavailable real primary"
	_hero.shells = 0 # Repeat only the public no-blast-ammo fixture before primary.
	var sequence: int = _last_sequence()
	var target_hp: float = float(state["hp"])
	var actual_time: float = _scheduler.get_clock()
	var toward: Vector3 = _source.global_position - _hero.global_position
	toward.y = 0.0
	if toward.length_squared() <= 0.000001:
		return "actual target cannot define a meaningful ordinary facing"
	var hits: int = _hero.slash(toward.normalized())
	_current_record.clear() # Only the real primary may cancel this source lease.
	var after: Dictionary = _source.call("state")
	var actions: Array[Dictionary] = _hero.get_world_action_records(sequence)
	if hits != 1 or actions.size() != 1 or actions[0].get("kind") != "primary" or int(actions[0].get("hits", 0)) != 1 or float(actions[0].get("damage", 0.0)) != float(_stats["primary_damage"]) or not _exact(actions[0].get("equipment_ids"), _kit) or float(after["hp"]) != maxf(target_hp - float(_stats["primary_damage"]), 0.0):
		return "real shared slash/record failed to apply precisely its ordinary damage to the actual live source"
	if absf(float(actions[0]["started_at_s"]) - actual_time) > TimeEpsilon or not String(after["reservation_id"]).is_empty() or not _scheduler.reservations().is_empty():
		return "ordinary primary timing or physical lease cancellation differs"
	_source_hp = float(after["hp"])
	_primary_count += 1
	print("PRIMARY: scheduled=%.9f actual=%.9f target_hp=%s -> %s damage=%s cycle=%s" % [float(proof["primary_time_s"]), actual_time, target_hp, _source_hp, actions[0]["damage"], state["cycle"]])
	return await _hold(segment)


## A published continuous deadline executes on the first available fixed tick.
## Starting actions may be at most one physics tick late. Completion may add
## one fractional final tick: thus at most two ticks after the path end. This
## changes no timing value, travel distance, momentum or acceptance window.
func _at_time(target: float) -> String:
	if not is_finite(target) or target > _case_deadline:
		return "published action deadline is nonfinite or outside thirty-second budget"
	for _index: int in range(_frame_limit(CaseBudgetS)):
		var now: float = _scheduler.get_clock()
		if now >= target:
			return "" if now - target <= _tick_s() + TimeEpsilon else "published action start missed its first fixed tick"
		var error: String = await _tick_safe()
		if not error.is_empty():
			return error
	return "action deadline exceeded finite frame budget"


func _tick_safe() -> String:
	await physics_frame
	await process_frame
	if not is_instance_valid(_hero) or not is_instance_valid(_source) or not is_instance_valid(_scheduler):
		return "actual player/source/scheduler disappeared during a required action"
	if _scheduler.get_clock() > _case_deadline or _hero.hp != _hp_before or _hero.dead or int(_events.get("source_hit", 0)) != 0 or int(_events.get("hero_death", 0)) != 0:
		return "live case exceeded budget, took/consumed damage, healed or died"
	if not _exact(_hero.equipment.snapshot(), _kit) or int(_events.get("equipment", 0)) != 0 or int(_game.get("cores")) != 0 or int(_game.get("kills")) != 0 or _world_topology() != _world_nodes or not get_nodes_in_group("lab_weapons").is_empty() or not get_nodes_in_group("practice_targets").is_empty():
		return "live kit changed or known pickup/reward/world-root topology appeared"
	if int(_events.get("completion", 0)) != 0 or int(_events.get("checkpoint", 0)) != 0 or int(_events.get("exit", 0)) != 0 or _level.is_completed() or not String(_level.current_checkpoint()["id"]).is_empty():
		return "isolated rule granted campaign progress/checkpoint/exit"
	var state: Dictionary = _source.call("state")
	if float(state["hp"]) != _source_hp:
		return "actual source HP changed outside the explicit real ordinary-primary call"
	if not _current_record.is_empty():
		var current: Dictionary = _scheduler.reservation_state(String(_current_record["id"]))
		if current.is_empty() or state["reservation_id"] != _current_record["id"] or state["phase"] not in ["warning", "lock", "active", "recovery"] or not _exact(current["geometry"], _current_record["geometry"]) or current["adapter"]["planned_endpoint"] != _current_record["adapter"]["planned_endpoint"]:
			return "required physical reservation/phase/locked geometry changed before ordinary primary"
		_phases[String(state["phase"])] = true
		if state["phase"] == "active":
			_active_travel = maxf(_active_travel, _source.global_position.distance_to(_current_record["adapter"]["start"]))
		if state["phase"] == "recovery" and (_source.global_position.distance_to(_current_record["adapter"]["planned_endpoint"]) > PointTolerance or not _source.velocity.is_zero_approx()):
			return "physical source failed its 0.005-world-unit endpoint/stationary recovery"
	return ""


func _clear_error() -> String:
	if not is_instance_valid(_source):
		return "source disappeared instead of leaving its diagnostic defeated node"
	var state: Dictionary = _source.call("state")
	var body: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	if state.get("dead") != true or float(state.get("hp", -1.0)) != 0.0 or state.get("phase") != "defeated" or not String(state.get("reservation_id", "")).is_empty() or _source.is_in_group("enemies") or _source.visible or _source.collision_layer != 0 or _source.collision_mask != 0 or body == null or not body.disabled or not _source.velocity.is_zero_approx() or not _scheduler.reservations().is_empty():
		return "actual death/body/enemy-group/motion/lease lifecycle is incomplete"
	if _primary_count <= 0 or _primary_count > MaxCycles or int(_events.get("source_death", 0)) != 1 or int(_events.get("source_hit", 0)) != 0 or _hero.hp != _hp_before or _hero.dead:
		return "clear did not retain the required primary/damage-free/single-death lifecycle"
	var records: Array[Dictionary] = _hero.get_world_action_records()
	if records.size() != _primary_count + _dash_count or _action_events.size() != records.size() or not _exact(_action_events, records) or int(_events.get("fired_slash", 0)) != _primary_count or int(_events.get("resolved_slash", 0)) != _primary_count or int(_events.get("fired_dash", 0)) != _dash_count or int(_events.get("fired_blast", 0)) != 0:
		return "actual completed action history/public events contain missing, duplicate or extra actions"
	for record: Dictionary in records:
		if record.get("kind") not in ["dash", "primary"]:
			return "clear used a blast or other unsupported action"
	if _scheduler.get_clock() > _case_deadline or _level.is_completed() or not String(_level.current_checkpoint()["id"]).is_empty() or int(_game.get("cores")) != 0 or int(_game.get("kills")) != 0:
		return "clear exceeded budget or granted production progress/reward"
	return ""


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


func _dispose() -> bool:
	if is_instance_valid(_game) and is_instance_valid(_hero):
		_game.call("open_bench")
	else:
		paused = true
	if is_instance_valid(_level):
		_level.exit_level()
	var released: bool = not is_instance_valid(_scheduler) or _scheduler.reservations().is_empty()
	_expect(released, "public room exit releases every source reservation")
	var game_ref: Variant = _game
	var hero_ref: Variant = _hero
	var source_ref: Variant = _source
	var level_ref: Variant = _level
	var scheduler_ref: Variant = _scheduler
	if is_instance_valid(_game):
		if _game.get_parent() == root:
			root.remove_child(_game)
		_game.queue_free()
	paused = false
	for _index: int in range(4):
		await process_frame
		if not is_instance_valid(game_ref):
			break
	var clean: bool = released and not is_instance_valid(game_ref) and not is_instance_valid(hero_ref) and not is_instance_valid(source_ref) and not is_instance_valid(level_ref) and not is_instance_valid(scheduler_ref) and not is_instance_valid(_old_hero) and not is_instance_valid(_old_level)
	for group: String in ["enemies", "practice_targets", "lab_weapons"]:
		clean = clean and get_nodes_in_group(group).is_empty()
	_expect(clean, "case cleanup frees both lab/room actors and all enemy/proxy/pickup group remnants")
	_game = null
	_hero = null
	_source = null
	_level = null
	_scheduler = null
	_floor = null
	_old_hero = null
	_old_level = null
	return clean


func _diagnostic() -> String:
	var result: Dictionary = {"kit": _kit, "stats": _relevant_stats(_stats), "events": _events, "primaries": _primary_count, "dashes": _dash_count}
	if is_instance_valid(_source):
		result["source"] = _source.call("state")
		result["source_position"] = _source.global_position
		result["source_velocity"] = _source.velocity
		result["source_grounded"] = _source.is_on_floor()
	if is_instance_valid(_scheduler):
		result["clock_s"] = _scheduler.get_clock()
		result["scheduler_error"] = _scheduler.last_error
	if is_instance_valid(_hero):
		result["hero_position"] = _hero.global_position
		result["hero_velocity"] = _hero.velocity
		result["hero_hp"] = _hero.hp
	return str(result)


func _relevant_stats(stats: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for field: String in ["primary_damage", "primary_range", "dash_speed", "dash_distance", "effective_health", "max_health", "armour", "primary_cooldown", "dash_cooldown", "dash_duration"]:
		if stats.has(field):
			result[field] = stats[field]
	return result


func _on_action(record: Dictionary) -> void:
	_action_events.append(record.duplicate(true))


func _event(kind: String) -> void:
	_events[kind] = int(_events.get(kind, 0)) + 1


func _last_sequence() -> int:
	var history: Array[Dictionary] = _hero.get_world_action_records()
	return int(history[-1]["sequence"]) if not history.is_empty() else 0


func _kit_key(kit: Dictionary) -> String:
	var ids: PackedStringArray = []
	for slot: String in Slots:
		ids.append(String(kit[slot]))
	return "/".join(ids)


func _frame_limit(seconds: float) -> int:
	return int(ceilf(seconds * float(Engine.physics_ticks_per_second))) + 8


func _tick_s() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


func _exact(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int):
		return float(a) == float(b)
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not _exact(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for index: int in range(a.size()):
			if not _exact(a[index], b[index]):
				return false
		return true
	return typeof(a) == typeof(b) and a == b


func _expect(ok: bool, message: String, diagnostic: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + message)
	else:
		_failures += 1
		push_error("FAIL: " + message + ("; " + diagnostic if not diagnostic.is_empty() else ""))
	return ok


func _finish() -> void:
	paused = false
	print("Stalker representative primary clear: %d checks, %d failures; %d attempted / %d cleared. Public mechanics only, no campaign/native/human acceptance." % [_checks, _failures, _attempted, _cleared])
	quit(1 if _failures > 0 else 0)
