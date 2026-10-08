extends SceneTree

const PlayerScript: GDScript = preload("res://scripts/player.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_ensure_test_uid()
	_run.call_deferred()


func _run() -> void:
	await _free_dash_and_restore()
	await _wall_shortened_dash()
	await _cancelled_capture_and_death()
	paused = false
	print("Player dash framing smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _free_dash_and_restore() -> void:
	var arena: Node3D = _arena()
	var actor: CinderPlayer = _player(arena)
	var events: Array[String] = []
	_connect_events(actor, events)
	await _ticks(4)
	_expect(_idle(actor.get_committed_dash_state()), "ready idle actor exposes finite null dash parameters")
	paused = true
	var idle_snapshot: String = _snapshot_wire(actor)
	actor.last_snapshot_error = "idle-query-sentinel"
	for _index: int in range(32):
		actor.get_committed_dash_state()
	_expect(actor.last_snapshot_error == "idle-query-sentinel" and events.is_empty() and _snapshot_wire(actor) == idle_snapshot, "idle query changes no snapshot, diagnostic or event")
	_expect(actor.equip_item("CLOTH-S2"), "legal paused bench selects long committed travel")
	var initial_stats: Dictionary = actor.get_threat_response_state().stats
	paused = false
	var origin: Vector3 = actor.global_position
	var direction: Vector3 = Vector3(2.0, 0.0, -1.0).normalized()
	_expect(actor.request_dash(Vector3(2.0, 5.0, -1.0)), "actual dash accepts a horizontal normalized direction")
	var initial: Dictionary = actor.get_committed_dash_state()
	_expect(_active(initial) and initial.origin == origin and initial.direction == direction, "accepted dash exposes cached native origin and direction immediately")
	_expect(initial.speed == initial_stats.dash_speed and initial.duration_s == initial_stats.dash_duration and initial.distance == initial.speed * initial.duration_s and initial.remaining_s == initial.duration_s, "framing budget uses exact accepted speed and duration")
	_expect(initial.size() == 8 and not initial.has("landing") and not initial.has("endpoint"), "framing query makes no shortened endpoint claim")
	await _ticks(3)
	var moving: Dictionary = actor.get_committed_dash_state()
	_expect(_active(moving) and actor.global_position != origin and moving.remaining_s < initial.remaining_s, "moving dash retains the original cache with decreasing remaining time")
	_expect(_same_parameters(initial, moving), "actual movement does not replace origin or intended budget with current velocity")
	paused = true
	_expect(actor.equip_item("CLOTH-S1") and actor.equip_item("CLOTH-P2"), "legal paused clothing retune changes live gear during committed motion")
	var retuned: Dictionary = actor.get_threat_response_state().stats
	_expect(retuned.dash_speed != initial.speed and retuned.dash_duration != initial.duration_s and _wire(actor.get_committed_dash_state()) == _wire(moving), "current gear retune cannot change cached active dash framing")
	_expect(not actor.request_dash(Vector3.BACK), "real next dash request buffers behind current cooldown")
	_expect(_wire(actor.get_committed_dash_state()) == _wire(moving), "buffered direction does not replace the current committed direction")
	var before: String = _snapshot_wire(actor)
	var before_events: Array[String] = events.duplicate()
	actor.last_snapshot_error = "active-query-sentinel"
	var exposed: Dictionary = actor.get_committed_dash_state()
	exposed["origin"] = Vector3(999.0, 999.0, 999.0)
	exposed["direction"] = Vector3.LEFT
	exposed["speed"] = 999.0
	exposed["active"] = false
	for _index: int in range(64):
		actor.get_committed_dash_state()
	_expect(actor.last_snapshot_error == "active-query-sentinel" and events == before_events and _snapshot_wire(actor) == before, "active query and mutation of its returned dictionary change no actor state")
	_expect(_wire(actor.get_committed_dash_state()) == _wire(moving), "returned native dictionary cannot alias the active cache")
	var captured: Dictionary = actor.snapshot_state()
	_expect(_snapshot_parameters_match(captured, moving), "query reads exactly the motion and clock cache already present in schema1")
	var transport: String = ExactJson.stringify(captured)
	var decoded: Dictionary = ExactJson.parse(transport)
	_expect(not transport.is_empty() and decoded.accepted, "actual mid-dash whole player snapshot uses exact tagged JSON transport")
	var restored: CinderPlayer = _player(arena)
	var restore_events: Array[String] = []
	_connect_events(restored, restore_events)
	_expect(_idle(restored.get_committed_dash_state()) and restored.restore_state(decoded.value), "fresh paused actual shared actor accepts the saved committed dash")
	_expect(_wire(restored.get_committed_dash_state()) == _wire(moving) and _snapshot_wire(restored) == before and restore_events.is_empty(), "fresh restore reproduces query, gear, buffered motion and full snapshot without events")
	var restored_before: String = _snapshot_wire(restored)
	await create_timer(0.06).timeout
	_expect(paused and _wire(restored.get_committed_dash_state()) == _wire(moving) and _snapshot_wire(restored) == restored_before, "paused fresh retry leaves dash cache and all clocks frozen")
	decoded.value.motion["dash_speed"] = 999.0
	_expect(_wire(restored.get_committed_dash_state()) == _wire(moving), "accepted transport dictionary cannot mutate restored cached parameters")
	paused = false
	await _ticks(1)
	_expect(_wire(actor.get_committed_dash_state()) == _wire(restored.get_committed_dash_state()) and actor.global_position == restored.global_position, "actual fresh retry continues the same dash on its next physics step")
	var next: Dictionary = {}
	for _index: int in range(40):
		var current: Dictionary = actor.get_committed_dash_state()
		if current.active and current.direction == Vector3.BACK:
			next = current
			break
		await _ticks(1)
	_expect(_active(next) and next.speed == retuned.dash_speed and next.duration_s == retuned.dash_duration and next.origin != origin, "eventually executed buffered dash caches the new legal gear and actual new origin")
	await _ticks(30)
	_expect(_idle(actor.get_committed_dash_state()) and _idle(restored.get_committed_dash_state()), "completed original and buffered dashes expose no stale origin or parameters")
	_expect(actor.get_world_action_records().size() == 2 and restored.get_world_action_records().size() == 2, "queries never fabricate or duplicate executed dash records")
	paused = true
	_expect(_snapshot_wire(actor) == _snapshot_wire(restored), "restored physical continuation preserves complete player state")
	paused = false
	arena.queue_free()
	await process_frame


func _wall_shortened_dash() -> void:
	var arena: Node3D = _arena()
	_world_box(arena, Vector3(1.1, 1.0, 0.0), Vector3(0.2, 2.0, 6.0))
	var actor: CinderPlayer = _player(arena)
	var completion_queries: Array[Dictionary] = []
	actor.world_action_executed.connect(func(record: Dictionary) -> void:
		if record.kind == "dash":
			completion_queries.append(actor.get_committed_dash_state())
	)
	await _ticks(4)
	_expect(actor.request_dash(Vector3.RIGHT), "actual dash starts toward a real scenery wall")
	var committed: Dictionary = actor.get_committed_dash_state()
	await _ticks(5)
	var blocked: Dictionary = actor.get_committed_dash_state()
	_expect(_active(blocked) and actor.global_position.x < 0.8 and absf(actor.velocity.x) < 0.001, "real wall stops horizontal body velocity while the dash commitment remains active")
	_expect(_same_parameters(committed, blocked) and blocked.direction == Vector3.RIGHT and blocked.speed > 0.0, "wall slide velocity does not replace the intended cached framing direction or speed")
	paused = true
	var before: String = _snapshot_wire(actor)
	var observed: Dictionary = actor.get_committed_dash_state()
	_expect(observed.distance > actor.global_position.distance_to(observed.origin) and _snapshot_wire(actor) == before, "blocked active query retains nominal span rather than pretending to know a shortened endpoint")
	paused = false
	await _ticks(18)
	var records: Array[Dictionary] = actor.get_world_action_records()
	_expect(records.size() == 1 and records[0].blocked and records[0].collision_shortened and records[0].distance < committed.distance, "completed actual record separately reports real collision-shortened travel")
	_expect(completion_queries.size() == 1 and _idle(completion_queries[0]), "completion callback sees idle despite the internal origin retiring after publication")
	_expect(_idle(actor.get_committed_dash_state()), "shortened completion clears public committed framing")
	arena.queue_free()
	await process_frame


func _cancelled_capture_and_death() -> void:
	var arena: Node3D = _arena()
	var actor: CinderPlayer = _player(arena)
	await _ticks(4)
	_expect(actor.request_dash(Vector3.FORWARD), "actual dash begins for explicit capture cancellation")
	await _ticks(2)
	var committed: Dictionary = actor.get_committed_dash_state()
	actor.cancel_world_action_capture()
	_expect(_active(committed) and _wire(actor.get_committed_dash_state()) == _wire(committed), "discarding an unfinished capture cannot hide ongoing physical dash framing")
	await _ticks(6)
	_expect(_active(actor.get_committed_dash_state()), "real committed motion outlasts its short invulnerability window")
	actor.take_damage(1000.0, Vector3.ZERO)
	_expect(actor.dead and _idle(actor.get_committed_dash_state()), "real lethal damage hides retained unfinished cache on a dead actor")
	paused = true
	var before: String = _snapshot_wire(actor)
	actor.last_snapshot_error = "dead-query-sentinel"
	actor.get_committed_dash_state()
	_expect(actor.last_snapshot_error == "dead-query-sentinel" and _snapshot_wire(actor) == before and actor.get_world_action_records().is_empty(), "dead query cannot refresh motion, resources or cancelled capture")
	paused = false
	arena.queue_free()
	await process_frame


func _active(state: Dictionary) -> bool:
	return state.get("api_revision") == "player-dash-framing-1" and state.get("active", false) and state.get("origin") is Vector3 and state.origin.is_finite() and state.get("direction") is Vector3 and state.direction.is_finite() and is_finite(float(state.get("speed", NAN))) and float(state.speed) > 0.0 and is_finite(float(state.get("duration_s", NAN))) and float(state.duration_s) > 0.0 and is_finite(float(state.get("distance", NAN))) and float(state.distance) > 0.0 and is_finite(float(state.get("remaining_s", NAN))) and float(state.remaining_s) > 0.0 and float(state.remaining_s) <= float(state.duration_s)


func _idle(state: Dictionary) -> bool:
	return state.get("api_revision") == "player-dash-framing-1" and state.get("active") == false and state.get("origin") == null and state.get("direction") == null and state.get("speed") == null and state.get("duration_s") == null and state.get("distance") == null and state.get("remaining_s") == 0.0


func _same_parameters(left: Dictionary, right: Dictionary) -> bool:
	for key: String in ["origin", "direction", "speed", "duration_s", "distance"]:
		if left.get(key) != right.get(key):
			return false
	return true


func _snapshot_parameters_match(snapshot: Dictionary, state: Dictionary) -> bool:
	return snapshot.motion.dash_origin == [state.origin.x, state.origin.y, state.origin.z] and snapshot.motion.dash_direction == [state.direction.x, state.direction.y, state.direction.z] and snapshot.motion.dash_speed == state.speed and snapshot.motion.dash_total_s == state.duration_s and snapshot.clocks.dash_left_s == state.remaining_s


func _wire(state: Dictionary) -> String:
	var encoded: Dictionary = state.duplicate(true)
	for key: String in ["origin", "direction"]:
		if encoded.get(key) is Vector3:
			var value: Vector3 = encoded[key]
			encoded[key] = [value.x, value.y, value.z]
	return ExactJson.stringify(encoded)


func _snapshot_wire(actor: CinderPlayer) -> String:
	return ExactJson.stringify(actor.snapshot_state())


func _connect_events(actor: CinderPlayer, events: Array[String]) -> void:
	actor.fired.connect(func(_kind: String) -> void: events.append("fired"))
	actor.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: events.append("resolved"))
	actor.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("world"))
	actor.equipment_changed.connect(func(_id: String) -> void: events.append("equipment"))
	actor.died.connect(func() -> void: events.append("died"))


func _arena() -> Node3D:
	var arena := Node3D.new()
	root.add_child(arena)
	_world_box(arena, Vector3(0.0, -0.5, 0.0), Vector3(40.0, 1.0, 40.0))
	return arena


func _player(arena: Node3D) -> CinderPlayer:
	var actor: CinderPlayer = PlayerScript.new()
	actor.position = Vector3(0.0, 0.02, 0.0)
	arena.add_child(actor)
	return actor


func _world_box(parent: Node3D, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = position


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)


func _ensure_test_uid() -> void:
	var path: String = "res://tests/player_dash_framing_smoke.gd.uid"
	if not FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))
