extends "res://tests/acts/act1/a1_o2_mechanics.gd"
## SOURCE ONLY. Reuses the unchanged first fixture's native readers/Player
## helpers/diagnostics; no first-fixture rerun or inherited run is performed.
## Main-only groups/finite-carryover/ordinary/contact scope. TEST Hero poses are
## explicitly unearned same-floor setup, never native response/save packets.
## No actor/HP/phase/clock/progress/field/sample/ammo/controller writes.

const TestSweep = preload("res://scripts/combat/body_sweep.gd")
const TestGeometry = preload("res://scripts/combat/threat_geometry.gd")
const GROUP_WATCHDOG_MS: int = 150000 # New bounded three-group fixture only.
var field_handles: Dictionary = {}
var spent_stamps: Dictionary = {}
var field_last_clocks: Dictionary = {}
var checkpoints: Array[Dictionary] = []
var completion_rows: Array[Dictionary] = []
var exit_rows: Array[Dictionary] = []
var primary_rows: Array[Dictionary] = []
var group_rows: Array[Dictionary] = []
var source_rows: Array[Dictionary] = []
var activation_counts: Dictionary = {}
var last_dormant: Dictionary = {}
var source_keys: Dictionary = {}
var last_group_key: String = ""
var exit_area: Area3D


func _initialize() -> void:
	started_ms = Time.get_ticks_msec(); old_fps = Engine.max_fps; old_audio = AudioServer.generate_bus_layout()
	report_path = "res://.cinder/a1-o2-groups-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	process_frame.connect(_watchdog); physics_frame.connect(_observe); _run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170); paused = true
	game = MainScene.instantiate(); game.set("level_scene_path", LEVEL_PATH); root.add_child(game)
	paused = true # Re-latch after synchronous Main.reset_lab, before any yield.
	await process_frame; await process_frame
	level = game.get("active_level") as CinderLevel; hero = game.get("player") as CinderPlayer
	if not _expect(level != null and hero != null and level.scene_file_path == LEVEL_PATH and level.hero == hero and level.contract_error().is_empty() and _count_players(game) == 1 and hero.global_position == Bloom.SPAWN and hero.equipment.snapshot() == Equipment.STARTER, "actual Main O2 begins with one unchanged canonical starter Hero"): await _finish(); return
	sources = (level.get("sources") as Dictionary).duplicate(); scheduler = level.get("scheduler") as CinderThreatScheduler
	floor_collision = level.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	exit_area = level.get_node_or_null("ActualBloomExit") as Area3D
	if not _expect(scheduler != null and floor_collision != null and floor_collision.shape is BoxShape3D and exit_area != null and Codec.keys_error(sources, Bloom.SOURCE_IDS).is_empty() and _count_native_sources(game) == 9, "nine original native actors, accepted floor, Scheduler and real contact exist"): await _finish(); return
	floor_shape = floor_collision.shape as BoxShape3D; floor_frame = floor_collision.global_transform; initial_hp = hero.hp
	for id: String in Bloom.SOURCE_IDS:
		var actor := sources[id] as Act1MushroomSelenite
		if not _expect(actor != null and actor.dormant and not actor.dead and actor.hp == (24.0 if id == "bloom-final-guard" else 16.0) and actor.global_position == Bloom.SOURCE_POINTS[id], "genuine pristine dormant source retained: " + id): await _finish(); return
		source_hp[id] = actor.hp; activation_counts[id] = 0; last_dormant[id] = true
		actor.state_changed.connect(_source_event.bind(id)); actor.hit_resolved.connect(_enemy_hit.bind(id))
	hero.world_action_executed.connect(func(record: Dictionary) -> void: actions.append(record.duplicate(true)))
	level.checkpoint_requested.connect(_checkpoint); level.completion_requested.connect(_completed); level.contact_exit_requested.connect(_exited)
	level.connect("native_admission_published", func(id: String, answer: Dictionary) -> void: admissions.append({"source_id": id, "answer": _portable(answer)}))
	game.call("resume_lab")
	if not await _wait(_primary_ready, "real initial floor settling", 4.0): await _finish(); return
	if not await _place(Vector3(Bloom.EXIT.x, hero.global_position.y, Bloom.EXIT.z), "TEST actual early contact; no entrance earned"): await _finish(); return
	if not await _wait(func() -> bool: return exit_area.overlaps_body(hero), "genuine early Area overlap", 3.0): await _finish(); return
	if not _expect(level.call("bloom_state").room_stage == "approach" and not level.is_completed() and checkpoints.is_empty() and completion_rows.is_empty() and exit_rows.is_empty(), "real early contact cannot activate, complete or exit O2"): await _finish(); return
	if not await _place(Vector3(TEST_POSITION.x, hero.global_position.y, TEST_POSITION.z), "TEST first approach threshold; no traversal credit"): await _finish(); return
	for group: int in range(3):
		if not await _wait(func() -> bool: return level.call("bloom_state").beat_index == group and level.call("bloom_state").room_stage == "active", "genuine native group activation " + str(group), 14.0): await _finish(); return
		if not _group_boundary(group): await _finish(); return
		if group < 2:
			if not await _deplete(Bloom.FIELD_IDS[group]): await _finish(); return
		if not _expect(_all_installed_spent() and _carryover(), "every installed original supply is spent before ordinary group clear " + str(group)): await _finish(); return
		var attempts: int = 0
		while _living(group) != "" and attempts < 12:
			attempts += 1
			if not await _ordinary(_living(group)): await _finish(); return
		if not _expect(_living(group) == "" and _healthy(), "actual public ordinary primaries clear original group after depletion " + str(group)): await _finish(); return
		# Hero position can help the real next current-view admission; no local
		# stage, source placement, activation, checkpoint or camera is supplied.
		if group < 2:
			if not await _place(Vector3(0, hero.global_position.y, .5), "TEST neutral next-group Hero position"): await _finish(); return
	if not await _wait(func() -> bool: return level.call("bloom_state").room_stage == "hatch", "actual final clear settles into incomplete contact hatch", 8.0): await _finish(); return
	if not _expect(not level.is_completed() and completion_rows.is_empty() and exit_rows.is_empty() and checkpoints.size() == 1 and activations.size() == 4 and _carryover() and level.current_checkpoint() == {"id": Bloom.CHECKPOINT_ID, "kind": "encounter"}, "all genuine defeats leave hatch incomplete and retain exactly the actual pre-final checkpoint request"): await _finish(); return
	for id: String in Bloom.SOURCE_IDS:
		if not _expect((sources[id] as Act1MushroomSelenite).dead and activation_counts[id] == 1, "actual source activates and is genuinely defeated once: " + id): await _finish(); return
	if not await _place(Vector3(Bloom.EXIT.x, hero.global_position.y, Bloom.EXIT.z), "TEST repaired actual contact approach; no earned exit route"): await _finish(); return
	if not await _wait(func() -> bool: return exit_rows.size() == 1, "real deferred contact emits completion then exit", 8.0): await _finish(); return
	if not _expect(exit_area.overlaps_body(hero) and level.is_completed() and level.call("bloom_state").room_stage == "departed" and completion_rows.size() == 1 and completion_rows[0].completion_id == Bloom.COMPLETION_ID and exit_rows[0].exit_id == Bloom.EXIT_ID and progress_events.map(func(row: Dictionary) -> String: return row.kind) == ["checkpoint", "completion", "exit"] and completion_rows[0].reentry_rejected and exit_rows[0].reentry_rejected, "genuine contact seals exact completion/exit order once and rejects synchronous public reentry"): await _finish(); return
	for tick: int in range(5): await process_frame
	_expect(completion_rows.size() == 1 and exit_rows.size() == 1 and not level.request_completion(Bloom.COMPLETION_ID) and not level.request_contact_exit(Bloom.EXIT_ID, hero) and _healthy() and _carryover() and _floor_unchanged(), "continued actual overlap and repeat requests grant no duplicate progress, field refresh or injury")
	await _finish()


func _group_boundary(index: int) -> bool:
	var state: Dictionary = level.call("bloom_state")
	var expected_fields: Array[String] = ["bloom-near"] if index == 0 else Bloom.FIELD_IDS.duplicate()
	if not _expect(state.completed_beats == Bloom.BEAT_IDS.slice(0, index) and state.installed_fields == expected_fields and state.installed_consumers == Bloom.CONSUMER_IDS.slice(0, index + 1) and state.checkpoint_published == (index == 2), "exact genuine completed/installation/checkpoint prefixes at group " + str(index)): return false
	for field_id: String in expected_fields:
		var actual := (level.get("_fields") as Dictionary)[field_id] as CinderSporeField
		if field_handles.has(field_id):
			if not _expect(actual == field_handles[field_id], "consumer transition retains the same original field handle: " + field_id): return false
		else:
			field_handles[field_id] = actual
			actual.activated.connect(func(domain: Dictionary) -> void: activations.append(domain.duplicate(true)))
			if not _expect(actual.state().generation == 0 and actual.state().remaining_clusters == 2, "new original native field has exactly its two genuine supplies: " + field_id): return false
	for group: int in range(index + 1):
		var actual := (level.get("_consumers") as Dictionary)[Bloom.consumer_id(group)] as CinderSporeRepulsion
		if not _expect(actual != null and actual.consumer_id() == Bloom.consumer_id(group), "permanent actual consumer identity retained"): return false
		for id: String in Bloom.SOURCE_IDS:
			if not _expect(actual.source_binding_matches(sources[id], id) == (id in Bloom.group_ids(group)), "consumer retains exactly its disjoint actual source group: " + id): return false
		for field_id: String in expected_fields:
			var original := field_handles[field_id] as CinderSporeField
			if not _expect(original.activated.is_connected(Callable(actual, "_on_activated")) == (field_id in Bloom.group_field_ids(group)), "native coordinator keeps its exact original Field subscription subset: " + field_id): return false
	for id: String in Bloom.SOURCE_IDS:
		var actor := sources[id] as Act1MushroomSelenite; var group: int = Bloom.source_group(id)
		if not _expect(actor.dormant == (group > index) and actor.dead == (group < index) and (group <= index or actor.hp == source_hp[id]), "native prior/current/future actor lifecycle agrees with real group prefix: " + id): return false
	if index == 2:
		if not _expect(checkpoints.size() == 1 and checkpoints[0].level_id == Bloom.LEVEL_ID and checkpoints[0].checkpoint_id == Bloom.CHECKPOINT_ID and checkpoints[0].kind == "encounter" and checkpoints[0].current_checkpoint == {"id": Bloom.CHECKPOINT_ID, "kind": "encounter"} and checkpoints[0].host.beat_index == 2 and checkpoints[0].host.room_stage == "approach" and checkpoints[0].host.completed_beats == Bloom.BEAT_IDS.slice(0, 2) and checkpoints[0].host.checkpoint_published and checkpoints[0].dormant_ids == Bloom.group_ids(2), "genuine pre-final checkpoint callback precedes every final activation and retains exact canonical progress"): return false
	return _expect(_carryover() and _healthy(), "original spent field stamps persist across new native bindings")


func _deplete(id: String) -> bool:
	field = field_handles[id] as CinderSporeField
	for anchor: String in ["cluster-right", "cluster-left"]:
		if not await _wait(func() -> bool: return field.state().phase == "available" and _primary_ready(), "original available finite anchor " + id + "/" + anchor, 8.0): return false
		var cluster := field.get_node(anchor) as Node3D
		var position: Vector3 = _choose_pose(cluster, true, true)
		if not _expect(position.is_finite(), "real finite anchor has a clear same-floor TEST Hero pose"): return false
		if not await _place(position, "TEST ordinary native anchor setup " + id + "/" + anchor): return false
		var before: Dictionary = field.state()
		if not _primary(anchor, "actual finite release " + id + "/" + anchor, true): return false
		var after: Dictionary = field.state()
		if not _expect(after.generation == before.generation + 1 and after.spent_ids.back() == anchor and after.deadline_s == after.activation_s + 3.0 and (before.deadline_s == null or after.activation_s >= before.deadline_s), "real original native finite release spends one anchor after actual expiry"): return false
		if not await _wait(func() -> bool: return field.state().phase in ["available", "spent"] and _environment_idle(), "original finite lifetime and real native episodes settle", 8.0): return false
	spent_stamps[id] = field.state().duplicate(true); field_last_clocks[id] = float(field.state().clock_s)
	return _expect(field.state().generation == 2 and field.state().remaining_clusters == 0 and _carryover(), "same native field has both genuine supplies permanently spent: " + id)


func _ordinary(id: String) -> bool:
	if not await _wait(func() -> bool: return _primary_ready() and (sources[id] as Act1MushroomSelenite).get_spore_response_state().grounded, "real ordinary Hero/source readiness " + id, 6.0): return false
	var actor := sources[id] as Act1MushroomSelenite
	var position: Vector3 = _choose_pose(actor, false, false)
	if not position.is_finite():
		if not await _wait(func() -> bool: return _choose_pose(actor, false, false).is_finite(), "actual safe TEST ordinary attack pose " + id, 8.0): return false
		position = _choose_pose(actor, false, false)
	if not await _place(position, "TEST same-floor ordinary range; no earned approach " + id): return false
	var supplied: Vector3 = actor.global_position - hero.global_position; supplied.y = 0; supplied = supplied.normalized()
	var expected: Vector3 = supplied.normalized(); var before: Dictionary = {}; var states: Dictionary = {}
	for source_id: String in Bloom.SOURCE_IDS: before[source_id] = (sources[source_id] as Act1MushroomSelenite).hp; states[source_id] = _portable((sources[source_id] as Act1MushroomSelenite).pure_presentation_state())
	var sequence: int = _sequence(); var shells: int = hero.shells
	if not _expect(_all_installed_spent() and _carryover() and _reaches(actor, expected), "actual ordinary target is reachable after every installed supply is spent"): return false
	var result: int = hero.slash(supplied); var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var losses: Dictionary = {}; var count: int = 0; var damage: float = float(hero.equipment.resolved_stats().primary_damage)
	for source_id: String in Bloom.SOURCE_IDS:
		var loss: float = float(before[source_id]) - (sources[source_id] as Act1MushroomSelenite).hp
		if loss > 0:
			losses[source_id] = loss; count += 1
			if not _expect(loss == minf(float(before[source_id]), damage), "actual native ordinary damage matches the untouched canonical attack: " + source_id): return false
	primary_rows.append({"target_id": id, "source_before": states, "hp_before": before, "losses": losses, "returned_hits": result, "records": _portable(records), "fields": _field_states()})
	return _expect(result > 0 and result == count and (sources[id] as Act1MushroomSelenite).hp < before[id] and records.size() == 1 and records[0].kind == "primary" and records[0].origin == "player_direct" and records[0].direction == expected and records[0].hits == count and hero.shells == shells and _healthy(), "real ordinary primary credits exactly all native HP losses without ammo, pickup or Hero damage")


func _choose_pose(target: Node3D, cluster: bool, exclude_other: bool) -> Vector3:
	for radius: float in [1.0, 1.4]:
		for step: int in range(16):
			var offset := Vector3(sin(TAU * step / 16.0), 0, cos(TAU * step / 16.0)) * radius
			var position := Vector3(target.global_position.x + offset.x, hero.global_position.y, target.global_position.z + offset.z)
			if not _pose_clear(position): continue
			# The helper only chooses disclosed TEST setup. Native Player still
			# executes the actual hit; no accepted response descriptor is created.
			var supplied: Vector3 = target.global_position - position; supplied.y = 0; supplied = supplied.normalized()
			if cluster:
				# A perpendicular fixture aim can select one wide-cone anchor.
				if _pose_anchor_aim(target, position, exclude_other) == Vector3.ZERO: continue
			elif not _pose_reaches(target, position, supplied.normalized()): continue
			return position
	return Vector3.INF


func _pose_anchor_aim(target: Node3D, position: Vector3, exclude_other: bool) -> Vector3:
	for index: int in range(72):
		var aim := Vector3(cos(TAU * index / 72.0), 0, sin(TAU * index / 72.0)).normalized()
		if not _pose_reaches(target, position, aim): continue
		var clear: bool = true
		for actor: Act1MushroomSelenite in sources.values():
			if not actor.dead and not actor.dormant and _pose_reaches(actor, position, aim): clear = false
		if exclude_other:
			for id: String in Bloom.CLUSTER_IDS:
				var other := field.get_node(id) as Node3D
				if other != target and _pose_reaches(other, position, aim): clear = false
		if clear: return aim
	return Vector3.ZERO


func _pose_reaches(target: Node3D, position: Vector3, aim: Vector3) -> bool:
	var offset: Vector3 = target.global_position - position
	if absf(offset.y) > CinderPlayer.ATTACK_MAX_VERTICAL_DISTANCE: return false
	offset.y = 0; var stats: Dictionary = hero.equipment.resolved_stats()
	if offset.length() > float(stats.primary_range) or (offset.length() > CinderPlayer.ATTACK_ORIGIN_DISK_RADIUS and offset.normalized().dot(aim) < float(stats.primary_cone_min_dot)): return false
	var query := PhysicsRayQueryParameters3D.create(position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, target.global_position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, CinderPlayer.ATTACK_SCENERY_MASK)
	return hero.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _pose_clear(position: Vector3) -> bool:
	var body: Dictionary = TestSweep.source_description(hero)
	if body.has("error"): return false
	var radius: float = float(body.footprint_half.x)
	for actor: Act1MushroomSelenite in sources.values():
		if not actor.dead and not actor.dormant:
			var collision := actor.get_node("BodyCollision") as CollisionShape3D
			if _distance(position, actor.global_position) < radius + (collision.shape as CapsuleShape3D).radius + .12: return false
	var now: float = scheduler.get_clock(); var interval: float = float(hero.equipment.resolved_stats().primary_cooldown) + .1
	# Conservative TEST setup exclusion: the complete relocation segment must
	# avoid every lease whose real active window overlaps the action interval.
	# This is no transported response proof or native sampling substitute.
	for actor: Act1MushroomSelenite in sources.values():
		for lease: Dictionary in scheduler.source_control_state(actor).get("reservations", []):
			if float(lease.active_until_s) >= now and float(lease.active_from_s) <= now + interval and TestGeometry.segment_hits(lease.geometry, hero.global_position, position, radius): return false
	var measured: Dictionary = TestSweep.sweep(hero, Transform3D(hero.global_basis, position), Vector3.ZERO, (level.call("scheduler_bindings") as Dictionary).floors.values())
	return not measured.has("error") and not measured.get("collided", true)


func _place(position: Vector3, label: String) -> bool:
	if not await _wait(_primary_ready, label + " actual ready barrier", 5.0): return false
	game.call("open_bench")
	if not _expect(paused and hero.velocity == Vector3.ZERO and _pose_clear(position), label + " retains actual zero motion and measured same-floor capsule/scenery/threat clearance"): return false
	var before: Vector3 = hero.global_position; hero.global_position = position # ONLY authored TEST mutation.
	setups.append({"kind": label, "before": _portable(before), "after": _portable(position), "scope": "TEST pose only; no velocity/phase/clock/sample/controller/camera/progress seed or earned traversal"})
	game.call("resume_lab")
	return _expect(not paused, label + " returns through the public Main resume")


func _field_states() -> Dictionary:
	var result: Dictionary = {}
	if is_instance_valid(level):
		for id: String in level.get("_fields"): result[id] = (level.get("_fields")[id] as CinderSporeField).state()
	return result


func _carryover() -> bool:
	for id: String in spent_stamps:
		var actual := (level.get("_fields") as Dictionary).get(id) as CinderSporeField
		if actual != field_handles[id]: return false
		var value: Dictionary = actual.state(); var original: Dictionary = spent_stamps[id]
		for key: String in ["generation", "spent_ids", "activation_s", "deadline_s"]:
			if not _same(value[key], original[key]): return false
		if float(value.clock_s) < float(field_last_clocks[id]): return false
		field_last_clocks[id] = float(value.clock_s) # Observation only; never Field state.
	return true


func _all_installed_spent() -> bool:
	for value: Dictionary in _field_states().values():
		if value.generation != 2 or value.phase != "spent": return false
	return true


func _environment_idle() -> bool:
	for id: String in Bloom.SOURCE_IDS:
		var actor := sources[id] as Act1MushroomSelenite
		if not actor.dormant and not actor.dead and actor.get_spore_response_state().phase != "none": return false
	return true


func _living(group: int) -> String:
	for id: String in Bloom.group_ids(group):
		if not (sources[id] as Act1MushroomSelenite).dead: return id
	return ""


func _healthy() -> bool:
	return is_instance_valid(hero) and hero.hp == initial_hp and hits.is_empty()


func _source_event(value: Dictionary, id: String) -> void:
	if last_dormant.get(id, true) and not value.get("dormant", true): activation_counts[id] += 1
	last_dormant[id] = value.get("dormant", true)
	var key: String = str([value.get("phase"), value.get("reservation_id"), value.get("hp"), value.get("dormant"), value.get("dead")])
	if source_keys.get(id) != key: source_keys[id] = key; source_rows.append({"source_id": id, "native": _portable(value)})


func _enemy_hit(hero_id: String, cycle: int, result: Dictionary, id: String) -> void:
	hits.append({"source_id": id, "hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true)})


func _checkpoint(level_id: String, id: String, kind: String) -> void:
	var dormant: Array[String] = []
	for source_id: String in Bloom.SOURCE_IDS:
		if (sources[source_id] as Act1MushroomSelenite).dormant: dormant.append(source_id)
	var row: Dictionary = {"level_id": level_id, "checkpoint_id": id, "kind": kind, "current_checkpoint": level.current_checkpoint(), "host": _portable(level.call("bloom_state")), "dormant_ids": dormant, "fields": _field_states(), "scope": "actual request/current_checkpoint only; no Shell/save/captured checkpoint packet"}
	checkpoints.append(row); progress_events.append({"kind": "checkpoint", "id": id})


func _completed(level_id: String, id: String) -> void:
	var rejected: bool = not level.request_completion(id) and not level.request_contact_exit(Bloom.EXIT_ID, hero)
	completion_rows.append({"level_id": level_id, "completion_id": id, "host": _portable(level.call("bloom_state")), "reentry_rejected": rejected}); progress_events.append({"kind": "completion", "id": id})


func _exited(level_id: String, id: String) -> void:
	exit_rows.append({"level_id": level_id, "exit_id": id, "host": _portable(level.call("bloom_state")), "reentry_rejected": not level.request_completion(Bloom.COMPLETION_ID) and not level.request_contact_exit(id, hero)}); progress_events.append({"kind": "exit", "id": id})


func _observe() -> void:
	if finishing or paused or not is_instance_valid(level) or not is_instance_valid(hero): return
	var state: Dictionary = level.call("bloom_state")
	var key: String = str([state.beat_index, state.room_stage, state.installed_fields, state.installed_consumers])
	if key != last_group_key: last_group_key = key; group_rows.append({"host": _portable(state), "fields": _field_states(), "hero_hp": hero.hp, "clock_s": scheduler.get_clock()})


func _diagnostic() -> Dictionary:
	var value: Dictionary = super._diagnostic()
	value["fields"] = _field_states(); value["spent_stamps"] = spent_stamps; value["activation_counts"] = activation_counts
	return value


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > GROUP_WATCHDOG_MS:
		_expect(false, "O2 groups watchdog reached150 wall seconds"); _finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	if physics_frame.is_connected(_observe): physics_frame.disconnect(_observe)
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(scheduler):
		var retired: bool = not scheduler.is_physics_processing() and scheduler.reservations().is_empty()
		for actor: Act1MushroomSelenite in sources.values(): retired = retired and not actor.is_physics_processing()
		for actual: CinderSporeField in field_handles.values(): retired = retired and not actual.is_physics_processing()
		_expect(retired, "public exit retires every actual source/retained Field/Scheduler before disposal")
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		var effects := game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
		refs = _refs(game)
		if is_instance_valid(floor_shape): refs.append(weakref(floor_shape))
		game.free()
	game = null; level = null; hero = null; scheduler = null; field = null; consumer = null; exit_area = null
	sources.clear(); field_handles.clear(); floor_collision = null; floor_shape = null
	paused = false; await create_timer(.5, true).timeout; await process_frame
	var freed: bool = true
	for ref: WeakRef in refs:
		if ref.get_ref() != null: freed = false
	_expect(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal group-world teardown frees descendant/floor weakrefs and native groups")
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	var evidence: Dictionary = {"checks": checks, "failures": failures, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "setups": setups, "actions": _portable(actions), "finite_receipts": receipts, "primary_receipts": primary_rows, "activation_counts": activation_counts, "source_rows": source_rows, "group_rows": group_rows, "field_activations": _portable(activations), "checkpoints": checkpoints, "completion": completion_rows, "exit": exit_rows, "enemy_hits": hits, "admissions": admissions, "scope": "Production Main oneHero/three actual source groups; disclosed measured same-floor TEST Hero poses, no earned movement/GUI/recognizer. Original near then far genuinely depleted by ordinary hits; same native handles/supplies/deadlines and monotonic independent Field clocks through permanent disjoint consumers; ordinary-primary actual HP-loss clears after depletion; real CP request/current_checkpoint only (no save packet/Shell); incomplete hatch then actual contact completion/exit once/public reentry refusal; normal cleanup. No transported snapshots/Continue/Retry/protectedStory/rewards/full-route/all-kit/balance/portrait/performance claim."}
	var exact: String = Exact.stringify(evidence)
	_expect(not exact.is_empty(), "complete group observations preserve exact finite scalar transport")
	evidence["checks"] = checks; evidence["failures"] = failures; evidence["exact_observations"] = exact
	var output := FileAccess.open(report_path, FileAccess.WRITE)
	if output == null: _expect(false, "unique native O2 groups report is writable")
	else: output.store_string(JSON.stringify(evidence, "\t")); output.close()
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O2 GROUPS: %d checks, %d failures; report=%s" % [checks, failures, report_path]); quit(1 if failures > 0 else 0)
