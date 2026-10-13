extends SceneTree
## Actual actor/capture data fixtures. No physical replay, safety or boss test.

const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const AUTHORED: Dictionary = {"recognition_s": 0.35, "warning_s": 0.9, "locked_lead_s": 1.1, "inter_echo_gap_s": 0.8, "final_recovery_s": 1.6, "tether_position": Vector3(0.3, 0.0, -0.4)}

var _checks: int = 0
var _failures: int = 0
var _two_capture: Dictionary = {}
var _two_plan: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_actual_shortened_slash_only()
	await _test_two_actual_slots_and_transport()
	_test_malformed_inputs_and_transport()
	await _test_actual_origin_discontinuity(false)
	await _test_actual_origin_discontinuity(true)
	print("Replay sequence smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_actual_shortened_slash_only() -> void:
	var arena: Dictionary = await _arena(true)
	var player: CinderPlayer = arena.player
	var capture = Capture.new()
	var epoch: String = "sequence-wall/attempt-1"
	await _arm(capture, player, epoch, 1)
	player.shells = 0
	player.world_action_executed.connect(func(record: Dictionary) -> void:
		capture.ingest(record, epoch)
		# Attack at the real completed landing, inside this publication callback.
		# Snapshot/build still happens later at the settled paused boundary.
		if record.kind == "dash":
			player.slash(Vector3(0.37, 0, -0.91))
	)
	player.request_dash(Vector3.RIGHT)
	await _ticks(35, player, capture)
	paused = true
	await process_frame
	capture.advance(player.get_world_action_clock())
	var actor_before: Dictionary = player.snapshot_state()
	var original: Array[Dictionary] = capture.slots()
	_expect(original.size() == 1 and original[0].dash.blocked and original[0].dash.collision_shortened and original[0].dash.distance > 0.0, "real wall-shortened dash and actual empty-ammo primary form one sealed slot")
	if original.size() != 1:
		await _dispose(arena)
		return
	var plan = Sequence.new()
	var accepted: bool = plan.configure("crystalman/phase-1", capture.snapshot_state(), AUTHORED, epoch, 1)
	_expect(accepted, "single actual shortened-route plan validates: " + plan.last_error)
	if not accepted:
		await _dispose(arena)
		return
	var native: Dictionary = plan.state()
	var slot: Dictionary = native.timeline.slots[0]
	_expect(slot.route.size() == original[0].dash.path.size() and slot.route[0].position == original[0].dash.world_origin and slot.route[-1].position == original[0].dash.landing, "absolute route endpoints and every physical sample are retained without translation")
	var same_route: bool = true
	for index: int in range(slot.route.size()):
		same_route = same_route and slot.route[index].position == original[0].dash.path[index].position
	_expect(same_route, "shortened polyline remains exactly the actually executed native route")
	_expect(slot.events.size() == 1 and slot.events[0].kind == "primary" and slot.events[0].damage_timing == "instant_at_execution" and _near(slot.events[0].at_s, slot.dash_until_s), "slash-only plan has one instant attack at dash completion, with no movement damage event")
	_expect(native.capture_snapshot.slots[0].primary.direction == original[0].primary.direction and native.capture_snapshot.slots[0].primary.geometry == original[0].primary.geometry and not native.capture_snapshot.slots[0].dash.movement_damage, "continuous direction, canonical footprint and harmless travel stay exact")
	_expect(Codec.same_values(actor_before, player.snapshot_state()) and player.shells == 0 and capture.state().retired.is_empty(), "building a plan causes no actor action/resource mutation or capture consumption")
	var paused_plan: Dictionary = plan.snapshot_state()
	await create_timer(0.12, true).timeout
	_expect(Codec.same_values(actor_before, player.snapshot_state()) and plan.snapshot_state() == paused_plan, "paused actor and immutable plan remain frozen while data is inspected")
	await _dispose(arena)


func _test_two_actual_slots_and_transport() -> void:
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var capture = Capture.new()
	var epoch: String = "sequence-two/phase-2"
	player.world_action_executed.connect(func(record: Dictionary) -> void: capture.ingest(record, epoch))
	await _arm(capture, player, epoch, 2)
	player.request_dash(Vector3(0.6, 0, 0.8))
	await _ticks(22, player, capture)
	await _ticks(35, player, capture) # Deliberate recording idle is omitted.
	player.slash(Vector3.FORWARD)
	await _ticks(6, player, capture)
	player.blast(Vector3.RIGHT)
	await _ticks(20, player, capture)
	paused = true
	await process_frame
	_expect(player.equip_item("WEAPON-03"), "second actual combination can retain a different canonical legal weapon snapshot")
	paused = false
	player.request_dash(Vector3.LEFT)
	await _ticks(22, player, capture)
	player.shells = 0
	player.slash(Vector3(0.4, 0, -0.9))
	await _ticks(20, player, capture)
	paused = true
	await process_frame
	capture.advance(player.get_world_action_clock())
	var snapshot: Dictionary = capture.snapshot_state()
	var original: Array[Dictionary] = capture.slots()
	_expect(original.size() == 2 and not original[0].blast.is_empty() and original[1].blast.is_empty(), "actual two-slot fixture contains primary/blast followed by an empty-ammo primary only")
	if original.size() != 2:
		await _dispose(arena)
		return
	var plan = Sequence.new()
	var accepted: bool = plan.configure("crystalman/phase-2", snapshot, AUTHORED, epoch, 1)
	_expect(accepted, "two actual sequential combinations configure without playback: " + plan.last_error)
	if not accepted:
		await _dispose(arena)
		return
	_two_capture = snapshot.duplicate(true)
	_two_plan = plan.snapshot_state()
	var native: Dictionary = plan.state()
	var first: Dictionary = native.timeline.slots[0]
	var second: Dictionary = native.timeline.slots[1]
	_expect(first.slot_id == 1 and second.slot_id == 2 and first.generation == 1 and second.generation == 1, "stable capture generation and slot order survive composition")
	_expect(_near(native.timeline.lock_from_s, AUTHORED.warning_s) and _near(first.from_s, AUTHORED.warning_s + AUTHORED.locked_lead_s) and native.authored.recognition_s == AUTHORED.recognition_s, "authored warning, full locked lead and recognition budget are explicitly retained")
	_expect(first.omitted_idle_s > 0.5 and _near(first.events[0].at_s, first.dash_until_s), "compact sequence omits arbitrary dash-to-primary idle without rewriting source records")
	_expect(first.events.size() == 2 and _near(first.events[1].at_s - first.events[0].at_s, original[0].blast.completed_at_s - original[0].primary.completed_at_s), "actual optional blast spacing and execution order remain exact")
	_expect(first.events[0].record.geometry == original[0].primary.geometry and first.events[1].record.world_origin == original[0].blast.world_origin and first.events[1].record.direction == Vector3.RIGHT and first.events[1].record.damage == original[0].blast.damage, "timed instant events expose canonical native geometry, origin, independent direction and resolved damage")
	_expect(_near(first.events[0].ready_s - first.events[0].at_s, original[0].primary.cooldown_s) and _near(first.events[1].commitment_until_s - first.events[1].at_s, original[0].blast.commitment_duration_s), "normal cooldown and logical commitment are separate from instant damage timing")
	_expect(_near(second.from_s - first.end_s, AUTHORED.inter_echo_gap_s) and second.from_s > first.end_s and first.end_s >= first.events[1].ready_s - Sequence.TIME_EPSILON_S, "second combination follows normal intrinsic recovery plus the explicit inter-echo gap")
	_expect(_near(native.timeline.tether_from_s, second.end_s) and _near(native.timeline.tether_until_s - native.timeline.tether_from_s, AUTHORED.final_recovery_s) and native.authored.tether_position == AUTHORED.tether_position, "authored absolute tether and complete final recovery window follow the finite sequence")
	_expect(native.capture_snapshot.slots[0].primary.equipment_ids == original[0].primary.equipment_ids and native.capture_snapshot.slots[1].primary.equipment_ids == original[1].primary.equipment_ids and original[0].primary.equipment_ids.weapon != original[1].primary.equipment_ids.weapon, "each action keeps its original static legal gear rather than the hero's later weapon")
	var transported: Dictionary = _json(plan.snapshot_state())
	var restored = Sequence.new()
	var restored_ok: bool = restored.restore_state(transported, epoch, 1)
	_expect(restored_ok and restored.snapshot_error(transported, epoch, 1).is_empty(), "actual two-slot plan survives finite JSON roundtrip: " + restored.last_snapshot_error)
	_expect(restored_ok and _same_native_path(restored.state().capture_snapshot.slots[0].dash.path, original[0].dash.path) and restored.state().capture_snapshot.slots[0].blast.direction == Vector3.RIGHT, "native decoding restores exact route positions, bounded decimal times and independently aimed blast")
	var copied: Dictionary = plan.state()
	copied.timeline.slots[0].route[0].position = Vector3(99, 0, 99)
	copied.capture_snapshot.slots[0].primary.geometry.reach = 99
	copied.authored.tether_position = Vector3.ZERO
	_expect(plan.snapshot_state() == _two_plan, "native getters protect paths, footprints and authored state from nested caller mutation")
	copied = plan.snapshot_state()
	copied.capture_snapshot.slots.clear()
	_expect(plan.snapshot_state() == _two_plan, "JSON getter is deeply defensive")
	_expect(not plan.configure("replacement", snapshot, AUTHORED, epoch, 1) and plan.snapshot_state() == _two_plan and plan.restore_state(transported, epoch, 1), "configured plan is immutable and identical JSON restore is idempotent")
	var another = Sequence.new()
	var different_timing: Dictionary = AUTHORED.duplicate(true)
	different_timing.locked_lead_s += 0.2
	another.configure("crystalman/phase-2", snapshot, different_timing, epoch, 1)
	_expect(not plan.restore_state(another.snapshot_state(), epoch, 1) and plan.snapshot_state() == _two_plan, "another structurally valid timetable cannot overwrite an immutable plan")
	_expect(capture.state().retired.is_empty() and capture.state().sealed == 2, "composition and roundtrip leave once-only slot transfer to the caller")
	await _dispose(arena)


func _test_malformed_inputs_and_transport() -> void:
	if _two_capture.is_empty():
		_expect(false, "actual fixture required for transport regressions")
		return
	var epoch: String = String(_two_capture.source_epoch)
	for change: String in ["third", "order", "pending", "time", "ghost", "zero", "gear", "generation", "screen"]:
		var bad: Dictionary = _two_capture.duplicate(true)
		match change:
			"third": bad.slots.append(bad.slots[1].duplicate(true))
			"order": bad.slots.reverse()
			"pending": bad.pending.append(bad.slots.pop_back())
			"time": bad.slots[0].dash.path[1].time_s = bad.slots[0].dash.path[0].time_s
			"ghost": bad.slots[0].primary.origin = "apparition"
			"zero":
				# Labeled transport zero edge derived from an actual completed dash.
				bad.slots[0].dash.landing = bad.slots[0].dash.world_origin.duplicate()
				bad.slots[0].dash.distance = 0.0
				bad.slots[0].dash.collision_shortened = true
				for sample: Dictionary in bad.slots[0].dash.path:
					sample.position = bad.slots[0].dash.world_origin.duplicate()
			"gear": bad.slots[0].primary.resolved_stats.primary_range = 99
			"generation": bad.slots[0].generation += 1
			"screen": bad.slots[0].primary.screen_release = [0.1, 0.9]
		var rejected = Sequence.new()
		_expect(not rejected.configure("rejected/" + change, bad, AUTHORED, epoch, 1) and rejected.snapshot_state().is_empty(), "malformed " + change + " capture rejects before assigning a plan")
	for change: String in ["missing", "nan", "zero_lock", "zero_gap", "native_tether"]:
		var authored: Dictionary = AUTHORED.duplicate(true)
		match change:
			"missing": authored.erase("recognition_s")
			"nan": authored.warning_s = NAN
			"zero_lock": authored.locked_lead_s = 0.0
			"zero_gap": authored.inter_echo_gap_s = 0.0
			"native_tether": authored.tether_position = [0, 0, 0]
		var rejected = Sequence.new()
		_expect(not rejected.configure("timing/" + change, _two_capture, authored, epoch, 1) and rejected.snapshot_state().is_empty(), "invalid explicit authored " + change + " rejects atomically")
	var plan = Sequence.new()
	plan.restore_state(_two_plan, epoch, 1)
	_expect(not plan.snapshot_error(_two_plan, "another-source/attempt", 1).is_empty() and not plan.snapshot_error(_two_plan, epoch, 2).is_empty(), "expected source epoch/generation prevent attaching a plan to another recording")
	for change: String in ["header", "duration", "route", "event", "order", "gap", "tether", "instant", "record"]:
		var bad: Dictionary = _two_plan.duplicate(true)
		match change:
			"header": bad.schema_version = 2
			"duration": bad.timeline.slots[0].end_s += 0.01
			"route": bad.timeline.slots[0].route[0].position[0] += 0.1
			"event": bad.timeline.slots[0].events[0].at_s += 0.01
			"order": bad.timeline.slots[0].events.reverse()
			"gap": bad.authored.inter_echo_gap_s += 0.01
			"tether": bad.timeline.tether_until_s += 0.01
			"instant": bad.timeline.slots[0].events[0].damage_timing = "continuous"
			"record": bad.capture_snapshot.slots[0].blast.geometry.reach += 0.1
		_expect(not plan.restore_state(bad, epoch, 1) and plan.snapshot_state() == _two_plan, "malformed " + change + " transport cannot alter immutable records or timetable")


func _test_actual_origin_discontinuity(blast_discontinuity: bool) -> void:
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var capture = Capture.new()
	var epoch: String = "sequence-origin/blast" if blast_discontinuity else "sequence-origin/primary"
	player.world_action_executed.connect(func(record: Dictionary) -> void: capture.ingest(record, epoch))
	await _arm(capture, player, epoch, 1)
	player.request_dash(Vector3.RIGHT)
	await _ticks(22, player, capture)
	if blast_discontinuity:
		player.slash(Vector3.FORWARD)
		player.request_dash(Vector3.LEFT)
		await _ticks(6, player, capture)
		player.blast(Vector3.BACK)
	else:
		player.request_dash(Vector3.LEFT)
		await _ticks(2, player, capture)
		player.slash(Vector3.FORWARD)
	await _ticks(25, player, capture)
	paused = true
	await process_frame
	capture.advance(player.get_world_action_clock())
	var snapshot: Dictionary = capture.snapshot_state()
	_expect(not snapshot.is_empty() and snapshot.slots.size() == 1 and capture.snapshot_error(snapshot, epoch, player.get_world_action_clock()).is_empty(), "actual moving-origin combination remains valid canonical capture data")
	var plan = Sequence.new()
	var kind: String = "blast" if blast_discontinuity else "primary"
	_expect(not plan.configure("discontinuous/" + kind, snapshot, AUTHORED, epoch, 1) and plan.last_error.contains(kind + " origin discontinuity") and plan.snapshot_state().is_empty(), "actual " + kind + " away from landing is explicitly rejected without snapping or invented route")
	await _dispose(arena)


func _arena(with_wall: bool = false) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	_box(world, Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	if with_wall:
		_box(world, Vector3(1.5, 1, 0), Vector3(0.3, 2, 10))
	var player: CinderPlayer = Player.new()
	world.add_child(player)
	await _ticks(5, player)
	return {"root": world, "player": player}


func _box(parent: Node3D, point: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = point


func _arm(capture: CinderActionCapture, player: CinderPlayer, epoch: String, capacity: int) -> void:
	paused = true
	await process_frame
	_expect(player.get_threat_response_state().stable and capture.arm(epoch, capacity, 0, player.get_world_action_clock()), "recording arms at a stable paused actual-actor boundary")
	paused = false


func _ticks(count: int, player: CinderPlayer, capture: CinderActionCapture = null) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame
		if capture != null:
			capture.advance(player.get_world_action_clock())


func _json(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value, "", true, true))


func _near(left: float, right: float) -> bool:
	return absf(left - right) <= Sequence.TIME_EPSILON_S


func _same_native_path(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index: int in range(left.size()):
		if left[index].size() != 2 or right[index].size() != 2 or left[index].position != right[index].position or not _near(float(left[index].time_s), float(right[index].time_s)):
			return false
	return true


func _dispose(arena: Dictionary) -> void:
	paused = false
	arena.root.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
