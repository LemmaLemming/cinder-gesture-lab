extends SceneTree
## SOURCE ONLY until imported/run by Root. Production Main, native first group,
## public Player.slash only. Disclosed same-floor TEST Hero positioning grants
## no GUI/recognizer/traversal credit. No actor/field/HP/phase/clock/sample seed,
## direct cluster attack/Field activation, snapshot, restore or campaign claim.

const MainScene = preload("res://scenes/main.tscn")
const Bloom = preload("res://scripts/acts/act1/spore_bloom_layout.gd")
const BaseLayout = preload("res://scripts/acts/act1/mushroom_caverns_layout.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_o2.tscn"
const WATCHDOG_MS: int = 60000
const TEST_POSITION: Vector3 = Vector3(0, 0.005, 1.95)

var game: Node
var level: CinderLevel
var hero: CinderPlayer
var scheduler: CinderThreatScheduler
var sources: Dictionary = {}
var field: CinderSporeField
var consumer: CinderSporeRepulsion
var floor_collision: CollisionShape3D
var floor_shape: BoxShape3D
var floor_frame: Transform3D
var checks: int = 0
var failures: int = 0
var first_failure: Dictionary = {}
var started_ms: int
var report_path: String
var finishing: bool = false
var old_fps: int
var old_audio: AudioBusLayout
var initial_hp: float
var source_hp: Dictionary = {}
var setups: Array[Dictionary] = []
var receipts: Array[Dictionary] = []
var actions: Array[Dictionary] = []
var activations: Array[Dictionary] = []
var reactions: Array[Dictionary] = []
var rejections: Array[Dictionary] = []
var hits: Array[Dictionary] = []
var progress_events: Array[Dictionary] = []
var admissions: Array[Dictionary] = []
var phase_rows: Dictionary = {}
var last_phase: Dictionary = {}
var native_rows: Array[Dictionary] = []
var field_rows: Array[Dictionary] = []


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	old_fps = Engine.max_fps; old_audio = AudioServer.generate_bus_layout()
	report_path = "res://.cinder/a1-o2-mechanics-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	process_frame.connect(_watchdog); physics_frame.connect(_observe)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	paused = true
	game = MainScene.instantiate(); game.set("level_scene_path", LEVEL_PATH)
	root.add_child(game)
	paused = true # Main.reset_lab unpauses synchronously; re-latch before yielding.
	await process_frame; await process_frame
	level = game.get("active_level") as CinderLevel; hero = game.get("player") as CinderPlayer
	if not _expect(level != null and hero != null and level.scene_file_path == LEVEL_PATH and level.hero == hero and level.level_id == Bloom.LEVEL_ID and level.contract_error().is_empty(), "actual production Main loads O2 with its shared level/Player contract"): await _finish(); return
	if not _expect(_count_players(game) == 1 and hero.global_position == Bloom.SPAWN and hero.global_position == level.spawn_position() and hero.equipment.snapshot() == Equipment.STARTER, "one pristine canonical starter Player begins at the exact O2 spawn"): await _finish(); return
	sources = (level.get("sources") as Dictionary).duplicate(); scheduler = level.get("scheduler") as CinderThreatScheduler
	floor_collision = level.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	if not _expect(scheduler != null and floor_collision != null and floor_collision.shape is BoxShape3D and Codec.keys_error(sources, Bloom.SOURCE_IDS).is_empty() and _count_native_sources(game) == 9, "all nine real native actors and original Box floor/Scheduler exist"): await _finish(); return
	floor_shape = floor_collision.shape as BoxShape3D; floor_frame = floor_collision.global_transform
	if not _expect(_floor_unchanged() and floor_collision.global_position == BaseLayout.FLOOR_CENTRE and floor_collision.global_basis == Basis.IDENTITY and scheduler.get_clock() == 0.0 and scheduler.encounter_profile().is_empty() and scheduler.reservations().is_empty(), "pristine paused entrance retains the exact accepted72m floor and unbegun native Scheduler"): await _finish(); return
	for id: String in Bloom.SOURCE_IDS:
		var actor := sources[id] as Act1MushroomSelenite
		var state: Dictionary = actor.pure_presentation_state() if actor != null else {}
		if not _expect(not state.is_empty() and state.source_id == id and state.entity_id == ("C32" if id == "bloom-final-guard" else "C31") and state.dormant and not state.dead and actor.hp == (24.0 if id == "bloom-final-guard" else 16.0) and actor.global_position == Bloom.SOURCE_POINTS[id] and not actor.visible and not actor.is_in_group("enemies") and actor.body_binding_error().is_empty() and actor.art_binding_error().is_empty(), "pristine actual dormant role/body/art/HP/placement retained: " + id): await _finish(); return
		source_hp[id] = actor.hp
		actor.hit_resolved.connect(func(hero_id: String, cycle: int, result: Dictionary) -> void: hits.append({"source_id": id, "hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true)}))
	var initial: Dictionary = level.call("bloom_state")
	if not _expect(initial.beat_index == 0 and initial.room_stage == "approach" and initial.completed_beats.is_empty() and not initial.checkpoint_published and initial.installed_fields.is_empty() and initial.installed_consumers.is_empty(), "initial O2 installs no field/consumer and earns no activation, checkpoint or completion"): await _finish(); return
	initial_hp = hero.hp
	hero.world_action_executed.connect(func(record: Dictionary) -> void: actions.append(record.duplicate(true)))
	level.connect("native_admission_published", func(id: String, answer: Dictionary) -> void: admissions.append({"source_id": id, "answer": _portable(answer)}))
	level.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void: progress_events.append({"kind": "checkpoint", "level_id": id, "id": checkpoint, "boundary": kind}))
	level.completion_requested.connect(func(id: String, completion: String) -> void: progress_events.append({"kind": "completion", "level_id": id, "id": completion}))
	level.contact_exit_requested.connect(func(id: String, exit_id: String) -> void: progress_events.append({"kind": "exit", "level_id": id, "id": exit_id}))
	receipts.append({"label": "actual pristine paused Main entrance", "host": _portable(initial), "player": hero.snapshot_state(), "floor_size": _portable(floor_shape.size), "floor_frame": _portable(floor_frame)})
	# TEST positioning only: no dash/recognizer/traversal credit. Native gravity,
	# stable Hero/current camera, approach threshold and activation guards run.
	hero.global_position = TEST_POSITION; hero.velocity = Vector3.ZERO
	setups.append({"kind": "TEST same-floor Hero position/zero velocity only; no earned route", "position": _portable(TEST_POSITION)})
	game.call("resume_lab")
	if not await _wait(func() -> bool: return level.call("bloom_state").room_stage == "active", "genuine settled first approach activates the real first group", 12.0): await _finish(); return
	var active: Dictionary = level.call("bloom_state")
	if not _expect(active.beat_index == 0 and active.installed_fields == ["bloom-near"] and active.installed_consumers == [Bloom.consumer_id(0)] and scheduler.source_control_state(sources[Bloom.SOURCE_IDS[0]]).encounter_id == Bloom.epoch_id(0), "actual first epoch installs exactly one original near field and permanent first consumer"): await _finish(); return
	field = (level.get("_fields") as Dictionary).get("bloom-near") as CinderSporeField
	consumer = (level.get("_consumers") as Dictionary).get(Bloom.consumer_id(0)) as CinderSporeRepulsion
	if not _expect(field != null and consumer != null and field.binding_error().is_empty() and consumer.consumer_id() == Bloom.consumer_id(0) and consumer.placement_accepted() and field.state().generation == 0 and field.state().remaining_clusters == 2, "native near field and disjoint first coordinator bind with both finite anchors available"): await _finish(); return
	for id: String in Bloom.SOURCE_IDS:
		var actor := sources[id] as Act1MushroomSelenite
		if not _expect(actor.dormant == (id not in Bloom.group_ids(0)) and actor.hp == source_hp[id] and (id not in Bloom.group_ids(0) or actor.get_spore_response_state().consumer_id == Bloom.consumer_id(0)), "only actual first-group actors activate/bind; later actors remain untouched: " + id): await _finish(); return
	# Signal observers preserve supplied payloads only; no mutation or capture
	# reentry in source/field/consumer callbacks.
	field.activated.connect(func(domain: Dictionary) -> void: activations.append(domain.duplicate(true)))
	field.state_changed.connect(func(state: Dictionary) -> void: field_rows.append(state.duplicate(true)))
	consumer.reaction_started.connect(func(id: String, episode: String) -> void: reactions.append({"source_id": id, "episode_id": episode}))
	consumer.placement_rejected.connect(func(id: String, reason: String) -> void: rejections.append({"source_id": id, "reason": reason}))
	# Original starts are outside the field. Wait for genuine native lunge entry;
	# releasing earlier would not prove repulsion. No actor position is supplied.
	if not await _wait(_native_entry, "a real first C31 lunge enters the original near domain", 14.0): await _finish(); return
	if not _primary("cluster-right", "actual first finite release", true): await _finish(); return
	var released: Dictionary = field.state()
	if not _expect(released.phase == "releasing" and field_rows.any(func(row: Dictionary) -> bool: return row.phase == "releasing") and released.generation == 1 and released.spent_ids == ["cluster-right"] and released.remaining_clusters == 1 and released.deadline_s == released.activation_s + 3.0 and activations.size() == 1 and not reactions.is_empty() and activations[0].causes_damage == false, "one real primary releases one finite harmless native field and starts an actual enemy episode"): await _finish(); return
	# This second call is truthfully cooldown-refused by Player, not Field credit.
	var sequence: int = _sequence(); var before: Dictionary = field.state()
	var refused_hits: int = hero.slash(Vector3.RIGHT)
	receipts.append({"label": "synchronous releasing cooldown refusal; no Field rejection credit", "returned_enemy_hits": refused_hits, "field_before": before, "field_after": field.state(), "new_world_actions": _portable(hero.get_world_action_records(sequence))})
	if not _expect(refused_hits == 0 and hero.get_world_action_records(sequence).is_empty() and _same(before, field.state()), "immediate releasing call is rejected by real Player cooldown without another action or supply change"): await _finish(); return
	for phase: String in ["active", "thinning"]:
		if not await _wait(func() -> bool: return field.state().phase == phase and _primary_ready(), "real " + phase + " field and ordinary primary readiness", 8.0): await _finish(); return
		before = field.state()
		if not _primary("cluster-left", "actual unspent-anchor " + phase + " refusal"): await _finish(); return
		var after: Dictionary = field.state()
		if not _expect(_same(before, after) and after.generation == 1 and after.spent_ids == ["cluster-right"] and activations.size() == 1 and field.last_error == "Spore cluster is unavailable or field already active" and _healthy(), "real reachable unspent-anchor " + phase + " primary preserves complete field clock/deadline/supply and all HP"): await _finish(); return
	if not await _wait(func() -> bool: return field.state().phase == "available" and _episodes_finished(), "original field expires and actual retreat/hold/regroup episodes finish", 8.0): await _finish(); return
	_observe() # Read the settled actual None before a next physics tick is needed.
	if not _expect(_phases_proved() and _healthy() and consumer.placement_accepted() and rejections.is_empty(), "native source observations include real outward motion, outside supported hold, regroup and ordinary return with intact Hero/enemy HP"): await _finish(); return
	# A second genuine ordinary hit uses the original remaining anchor only after
	# expiry. Native actors may start another real warning; no phase is suppressed.
	if not await _wait(_primary_ready, "second finite primary readiness", 4.0): await _finish(); return
	if not _primary("cluster-left", "actual second finite release after original expiry"): await _finish(); return
	var second: Dictionary = field.state()
	if not _expect(second.generation == 2 and second.spent_ids == ["cluster-right", "cluster-left"] and second.remaining_clusters == 0 and second.activation_s >= released.deadline_s and second.deadline_s == second.activation_s + 3.0 and activations.size() == 2 and _healthy(), "same actual field consumes its second and final supply after the first original deadline"): await _finish(); return
	if not await _wait(func() -> bool: return field.state().phase == "spent" and _episodes_finished(), "second original field expires with both supplies permanently spent", 8.0): await _finish(); return
	_expect(field.state().generation == 2 and field.state().spent_ids == second.spent_ids and field.state().deadline_s == second.deadline_s and field.get_node("cluster-left").call("get_cue_state").state == "spent" and field.get_node("cluster-right").call("get_cue_state").state == "spent" and _healthy() and actions.size() == 4 and actions.all(func(record: Dictionary) -> bool: return record.kind == "primary" and record.hits == 0) and level.call("bloom_state").beat_index == 0 and progress_events.is_empty() and not level.is_completed() and _floor_unchanged(), "two genuine releases leave both real spent cues, original HP/floor, and all later groups/progress unearned")
	receipts.append({"label": "final first-field focused state", "diagnostic": _diagnostic()})
	await _finish()


func _native_entry() -> bool:
	if not _primary_ready(): return false
	for id: String in Bloom.group_ids(0):
		var actor := sources[id] as Act1MushroomSelenite
		var response: Dictionary = actor.get_spore_response_state()
		if actor.pure_presentation_state().phase == "active" and response.grounded and _distance(actor.global_position, field.global_position) <= Bloom.FIELD_RADIUS + float(response.support_radius): return true
	return false


func _primary(cluster_id: String, label: String, exclude_other: bool = false) -> bool:
	var cluster := field.get_node_or_null(cluster_id) as Node3D
	var aim: Vector3 = _aim(cluster, exclude_other)
	var expected_facing: Vector3 = Vector3(aim.x, 0, aim.z).normalized()
	if not _expect(_primary_ready() and cluster != null and cluster.is_in_group("environment_attack_targets") and aim != Vector3.ZERO, label + " has real ordinary readiness/LOS/reach/cone excluding every living enemy"): return false
	var before: Dictionary = field.state(); var sequence: int = _sequence(); var shells: int = hero.shells
	var result: int = hero.slash(aim)
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	receipts.append({"label": label, "cluster_id": cluster_id, "hero_position": _portable(hero.global_position), "anchor_position": _portable(cluster.global_position), "supplied_aim": _portable(aim), "expected_public_normalized_facing": _portable(expected_facing), "before": before, "after": field.state(), "field_error": field.last_error, "returned_enemy_hits": result, "actions": _portable(records), "scope": "Player dispatches native receive_attack internally; its return Dictionary is not publicly surfaced"})
	return _expect(result == 0 and records.size() == 1 and records[0].kind == "primary" and records[0].origin == "player_direct" and records[0].hits == 0 and records[0].direction == expected_facing and records[0].direction == hero.facing and hero.shells == shells and _healthy(), label + " publishes exactly one real public ordinary primary without enemy hit, ammo cost or damage")


func _aim(cluster: Node3D, exclude_other: bool) -> Vector3:
	if cluster == null: return Vector3.ZERO
	for index: int in range(360):
		var direction := Vector3(cos(TAU * index / 360.0), 0, sin(TAU * index / 360.0))
		var actual: Vector3 = direction.normalized() # Same public _face_attack transformation.
		if not _reaches(cluster, actual): continue
		var clear: bool = true
		for actor: Act1MushroomSelenite in sources.values():
			if not actor.dormant and not actor.dead and _reaches(actor, actual): clear = false
		if exclude_other:
			for id: String in Bloom.CLUSTER_IDS:
				var other := field.get_node(id) as Node3D
				if other != cluster and _reaches(other, actual): clear = false
		if clear: return direction
	return Vector3.ZERO


func _reaches(target: Node3D, direction: Vector3) -> bool:
	# Actual preflight observation of the public Player radial-cone/LOS policy;
	# never substitutes for the native attack dispatch or measured Route solver.
	var offset: Vector3 = target.global_position - hero.global_position
	if absf(offset.y) > CinderPlayer.ATTACK_MAX_VERTICAL_DISTANCE: return false
	offset.y = 0.0
	var stats: Dictionary = hero.equipment.resolved_stats()
	if offset.length() > float(stats.primary_range) or (offset.length() > CinderPlayer.ATTACK_ORIGIN_DISK_RADIUS and offset.normalized().dot(direction) < float(stats.primary_cone_min_dot)): return false
	var query := PhysicsRayQueryParameters3D.create(hero.global_position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, target.global_position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, CinderPlayer.ATTACK_SCENERY_MASK)
	return hero.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _primary_ready() -> bool:
	if paused or not is_instance_valid(hero) or hero.dead: return false
	var state: Dictionary = hero.get_threat_response_state()
	return state.stable and float(state.commitment_remaining_s) == 0.0 and float(state.primary_cooldown_left_s) == 0.0


func _observe() -> void:
	if finishing or paused or not is_instance_valid(consumer) or not is_instance_valid(field): return
	for id: String in Bloom.group_ids(0):
		var actor := sources[id] as Act1MushroomSelenite
		var response: Dictionary = actor.get_spore_response_state()
		if response.is_empty(): continue
		var phase: String = response.phase
		if not phase_rows.has(id): phase_rows[id] = {}
		if phase == "none" and not phase_rows[id].has("regroup"): continue
		if last_phase.get(id) == phase and phase != "retreat": continue
		last_phase[id] = phase
		var row: Dictionary = _portable({"source_id": id, "source": response, "native": actor.pure_presentation_state(), "controller": scheduler.source_control_state(actor), "consumer": consumer.source_state(id), "field": field.state(), "hero": hero.get_threat_response_state(), "hero_hp": hero.hp})
		if not phase_rows[id].has(phase): phase_rows[id][phase] = row
		native_rows.append(row) # Full original native records; no path/clock pruning.


func _episodes_finished() -> bool:
	for id: String in Bloom.group_ids(0):
		if (sources[id] as Act1MushroomSelenite).get_spore_response_state().phase != "none": return false
	return true


func _phases_proved() -> bool:
	for reaction: Dictionary in reactions:
		var rows: Dictionary = phase_rows.get(reaction.source_id, {})
		if not rows.has_all(["recoil", "retreat", "hold", "regroup", "none"]): continue
		var hold: Dictionary = rows.hold
		var position: Vector3 = Codec.read_vector3(hold.source.position)
		var support: float = float(hold.source.support_radius)
		var original: Vector3 = Codec.read_vector3(rows.recoil.source.position)
		var moving: bool = native_rows.any(func(row: Dictionary) -> bool: return row.source_id == reaction.source_id and row.source.phase == "retreat" and Codec.read_vector3(row.source.velocity) != Vector3.ZERO)
		if moving and hold.source.grounded and _distance(original, position) > .02 and _distance(position, field.global_position) > Bloom.FIELD_RADIUS + support + .08 and Codec.read_vector3(hold.source.velocity) == Vector3.ZERO and not hold.consumer.route.is_empty() and hold.consumer.route.elapsed_s > 0.0:
			return true
	return false


func _healthy() -> bool:
	if hero.hp != initial_hp or not hits.is_empty(): return false
	for id: String in Bloom.SOURCE_IDS:
		if (sources[id] as Act1MushroomSelenite).hp != source_hp[id]: return false
	return true


func _wait(predicate: Callable, label: String, native_seconds: float) -> bool:
	var end: float = hero.get_world_action_clock() + native_seconds
	while not finishing and hero.get_world_action_clock() <= end:
		if predicate.call() == true: return true
		if paused or not is_instance_valid(game) or hero.dead or not level.contract_error().is_empty(): return _expect(false, "native observation lost living unpaused Main contract: " + label)
		await process_frame
	return false if finishing else _expect(false, "bounded native observation failed: " + label)


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WATCHDOG_MS:
		_expect(false, "O2 native mechanics watchdog reached60 wall seconds"); _finish.call_deferred()


func _floor_unchanged() -> bool:
	return level.get_node_or_null("Floor/CollisionShape3D") == floor_collision and floor_collision.shape == floor_shape and floor_shape.size == BaseLayout.FLOOR_SIZE and floor_collision.global_transform == floor_frame


func _diagnostic() -> Dictionary:
	var value: Dictionary = {"paused": paused, "elapsed_ms": Time.get_ticks_msec() - started_ms}
	if is_instance_valid(level): value["host"] = _portable(level.call("bloom_state")); value["contract_error"] = level.contract_error(); value["approach_error"] = level.get("last_approach_error")
	if is_instance_valid(game): value["camera_error"] = game.get("last_camera_framing_error")
	if is_instance_valid(hero): value["hero"] = _portable(hero.get_threat_response_state()); value["hero_hp"] = hero.hp
	if is_instance_valid(field): value["field"] = field.state(); value["field_error"] = field.last_error; value["cue"] = field.get_cue_state()
	if is_instance_valid(consumer): value["consumer_error"] = consumer.last_error; value["placement_accepted"] = consumer.placement_accepted()
	if is_instance_valid(scheduler):
		value["clock_s"] = scheduler.get_clock(); value["source_controls"] = {}
		for id: String in sources: value.source_controls[id] = _portable(scheduler.source_control_state(sources[id]))
	return value


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = {"label": label, "diagnostic": _diagnostic()}
		push_error(label)
	return ok


func _sequence() -> int:
	var history: Array[Dictionary] = hero.get_world_action_records()
	return 0 if history.is_empty() else int(history.back().sequence)


func _same(left: Variant, right: Variant) -> bool:
	return not Exact.stringify(left).is_empty() and Exact.stringify(left) == Exact.stringify(right)


func _distance(left: Vector3, right: Vector3) -> float:
	return Vector2(left.x - right.x, left.z - right.z).length()


func _count_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_players(child)
	return count


func _count_native_sources(node: Node) -> int:
	var count: int = 1 if node is Act1MushroomSelenite else 0
	for child: Node in node.get_children(): count += _count_native_sources(child)
	return count


func _portable(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Vector2: return [value.x, value.y]
	if value is Basis: return {"x": _portable(value.x), "y": _portable(value.y), "z": _portable(value.z)}
	if value is Transform3D: return {"basis": _portable(value.basis), "origin": _portable(value.origin)}
	if value is StringName: return String(value)
	if value is Object: return {"native_class": value.get_class(), "instance_id": value.get_instance_id()} if is_instance_valid(value) else null
	if value is Dictionary:
		var converted: Dictionary = {}
		for key: Variant in value: converted[String(key)] = _portable(value[key])
		return converted
	if value is Array:
		var converted: Array = []
		for child: Variant in value: converted.append(_portable(child))
		return converted
	return value


func _refs(node: Node) -> Array[WeakRef]:
	var result: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children(): result.append_array(_refs(child))
	return result


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	if physics_frame.is_connected(_observe): physics_frame.disconnect(_observe)
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(scheduler):
		var retired: bool = not scheduler.is_physics_processing() and scheduler.reservations().is_empty()
		for actor: Act1MushroomSelenite in sources.values(): retired = retired and not actor.is_physics_processing()
		if is_instance_valid(field): retired = retired and not field.is_physics_processing()
		_expect(retired, "public level exit retires actual sources/field and Scheduler processing/leases")
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		var fx := game.get("fx") as PixelEffects
		if is_instance_valid(fx): fx.clear()
		refs = _refs(game)
		if is_instance_valid(floor_shape): refs.append(weakref(floor_shape))
		game.free()
	game = null; level = null; hero = null; scheduler = null; field = null; consumer = null
	sources.clear(); floor_collision = null; floor_shape = null
	paused = false
	await create_timer(.5, true).timeout; await process_frame
	var freed: bool = true
	for ref: WeakRef in refs:
		if ref.get_ref() != null: freed = false
	_expect(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal Main teardown frees descendants and native enemy/cluster/cue groups")
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	var exact_observations: String = Exact.stringify(_portable({"receipts": receipts, "actions": actions, "field_callbacks": field_rows, "activations": activations, "native_rows": native_rows, "admissions": admissions}))
	_expect(not exact_observations.is_empty(), "complete finite native observations retain exact scalar types/bits in the report")
	var output := FileAccess.open(report_path, FileAccess.WRITE)
	if output == null: _expect(false, "unique O2 native JSON report is writable")
	else:
		output.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "setups": setups, "receipts": receipts, "actions": _portable(actions), "field_callbacks": field_rows, "activations": _portable(activations), "reactions": reactions, "placement_rejections": rejections, "native_rows": native_rows, "hits": hits, "admissions": admissions, "progress_events": progress_events, "exact_observations": exact_observations, "scope": "Production Main O2 at540x1170; pristine oneHero/nine dormant native roles/accepted72m floor; disclosed TEST Hero same-floor positioning then actual approach activation; public ordinary primaries only, genuine finite release/active+thinning no-refresh geometry+Field error (native interaction return not surfaced), harmless native retreat/hold/regroup/none and actual second supply expiry; public exit and weakref/group/settings cleanup. Releasing cooldown refusal is not Field no-refresh credit. No GUI/recognizer/earned traversal, group clears/later consumers/shared-field carryover/checkpoint/save/Continue/Retry/route/all-kit/portrait/performance credit."}, "\t")); output.close()
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O2 MECHANICS: %d checks, %d failures; report=%s" % [checks, failures, report_path])
	quit(1 if failures > 0 else 0)
