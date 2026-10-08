extends SceneTree
## Actual actor-publication fixtures plus labeled exact-zero/deadline edges.
## This tests capture data, never physical replay or campaign fairness.

const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_actual_slash_only_and_pending_restore()
	await _test_two_slots_and_blast()
	await _test_interleaved_dash_and_blast()
	await _test_buffered_supersession()
	await _test_attack_before_completion_and_prearm()
	await _test_zero_completion_and_late_blast()
	await _test_stream_loss_and_atomic_validation()
	print("Action capture smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_actual_slash_only_and_pending_restore() -> void:
	var arena: Dictionary = await _arena(true)
	var player: CinderPlayer = arena.player
	var capture = Capture.new()
	var ingested: Array[bool] = []
	player.world_action_executed.connect(func(record: Dictionary) -> void: ingested.append(capture.ingest(record, "actor-a/attempt-1")))
	_expect(await _arm(capture, player, "actor-a/attempt-1", 1), "capture arms at the paused stable shared-actor boundary")
	_expect(not player.request_dash(Vector3.ZERO) and capture.state().cursor == 0, "rejected zero-direction input produces no capture publication")
	_expect(player.request_dash(Vector3.RIGHT) and not capture.state().has_dash_candidate, "accepted unfinished dash does not sample before actual completion")
	await _ticks(16, player, capture)
	var actual_dash: Dictionary = player.get_world_action_records()[0]
	_expect(actual_dash.blocked and actual_dash.collision_shortened and actual_dash.distance > 0.0 and capture.state().has_dash_candidate, "actual collision-shortened positive dash becomes an exact world-route candidate")
	await _ticks(35, player, capture) # Deliberate idle time is not replayed.
	player.shells = 0
	_expect(player.slash(Vector3(0.37, 0, -0.91)) == 0 and capture.state().pending == 1 and capture.state().sealed == 0 and capture.state().allocated == 1, "actual primary pairs once while the full quick-blast window remains pending")
	_expect(player.blast(Vector3.BACK) == 0 and player.shells == 0 and capture.state().cursor == 2 and ingested == [true, true], "empty-ammo blast rejection adds no record or extra slot")
	paused = true
	await process_frame
	capture.advance(player.get_world_action_clock())
	var snapshot: Dictionary = _json(capture.snapshot_state())
	var clock: float = player.get_world_action_clock()
	_expect(not snapshot.is_empty() and Codec.value_error(snapshot).is_empty() and snapshot.pending.size() == 1 and snapshot.pending[0].sealed_at_s == null, "pending combo snapshots finite canonical records without premature sealing")
	var restored = Capture.new()
	var restored_ok: bool = restored.restore_state(snapshot, "actor-a/attempt-1", clock)
	_expect(restored_ok, "pending JSON roundtrip restores only with its exact actor/attempt epoch and simulation clock: " + restored.last_snapshot_error)
	if not restored_ok:
		await _dispose(arena)
		return
	await create_timer(0.35, true).timeout
	capture.advance(player.get_world_action_clock())
	restored.advance(player.get_world_action_clock())
	_expect(capture.state().pending == 1 and restored.state().pending == 1 and capture.slots().is_empty() and restored.slots().is_empty(), "background pause cannot expire the combo through wall-clock time")
	var pending_before: Dictionary = restored.snapshot_state()
	var bad: Dictionary = snapshot.duplicate(true)
	bad.pending[0].window_until_s += 0.001
	_expect(not restored.restore_state(bad, "actor-a/attempt-1", clock) and Codec.same_values(pending_before, restored.snapshot_state()), "altered actual combo deadline rejects atomically")
	_expect(not restored.restore_state(snapshot, "new-actor/attempt-2", clock) and not restored.restore_state(snapshot, "actor-a/attempt-1", clock + 0.1), "epoch or actor-clock mismatch never attaches old capture to a new source")
	paused = false
	await _ticks(18, player, restored)
	_expect(restored.state().sealed == 1 and restored.state().pending == 0 and restored.slots()[0].blast.is_empty(), "actual simulation advance seals a valid slash-only combination with no ammo requirement")
	if restored.slots().is_empty():
		await _dispose(arena)
		return
	var slot: Dictionary = restored.slots()[0]
	var actual_primary: Dictionary = player.get_world_action_records()[1]
	_expect(_same_transport(slot.dash.path, actual_dash.path) and slot.dash.landing == actual_dash.landing and slot.primary.world_origin == actual_primary.world_origin and slot.primary.direction == actual_primary.direction and _same_transport(slot.primary.geometry, actual_primary.geometry), "sealed slot preserves exact native wall-shortened route/world vectors and transported primary geometry")
	_expect(slot.primary.equipment_ids == actual_primary.equipment_ids and _same_transport(slot.primary.resolved_stats, actual_primary.resolved_stats) and slot.timetable.primary_at_s == slot.timetable.dash_end_s and slot.timetable.omitted_idle_s > 0.5, "canonical gear/stat values and timing survive JSON while compact timetable omits arbitrary dash-to-attack idle wait")
	slot.dash.path[0].position = Vector3(999, 0, 999)
	slot.primary.equipment_ids.weapon = "observer-mutation"
	_expect(_same_transport(restored.slots()[0].dash.path, actual_dash.path) and restored.slots()[0].primary.equipment_ids.weapon == actual_primary.equipment_ids.weapon, "native slot getters protect nested routes and gear from caller mutation")
	_expect(restored.take_next().slot_id == 1 and restored.take_next().is_empty() and restored.state().retired == [1] and restored.state().allocated == 1, "ordered take consumes the captured slot exactly once and never reopens capacity")
	_expect(restored.cancel() and restored.slots().is_empty() and restored.snapshot_state().source_epoch == "actor-a/attempt-1", "cancel clears stale recordings while preserving the serialized source identity")
	await _dispose(arena)


func _test_two_slots_and_blast() -> void:
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var capture = Capture.new()
	player.world_action_executed.connect(func(record: Dictionary) -> void: capture.ingest(record, "actor-two/phase-2"))
	_expect(await _arm(capture, player, "actor-two/phase-2", 2), "phase-two foundation arms exactly two slots")
	player.request_dash(Vector3(0.6, 0, 0.8))
	await _ticks(15, player, capture)
	player.slash(Vector3.FORWARD)
	await _ticks(6, player, capture)
	player.blast(Vector3.RIGHT)
	_expect(capture.state().allocated == 1 and capture.state().pending == 1 and capture.state().sealed == 0, "actual primary plus actual optional blast consumes one slot and still waits for combo close")
	await _ticks(18, player, capture)
	_expect(capture.slots()[0].blast.kind == "blast" and capture.slots()[0].blast.direction == Vector3.RIGHT and capture.slots()[0].primary.direction == Vector3.FORWARD, "optional follow-up retains its separately executed direction and short-range footprint")
	var first: Dictionary = capture.slots()[0]
	_expect(first.blast.completed_at_s > first.primary.completed_at_s and absf((first.timetable.blast_at_s - first.timetable.primary_at_s) - (first.blast.completed_at_s - first.primary.completed_at_s)) < 0.00000001, "compact timetable preserves the actual positive within-combo blast spacing")
	_test_inclusive_transport_boundary(first)
	player.request_dash(Vector3.LEFT)
	await _ticks(15, player, capture)
	player.shells = 0
	player.slash(Vector3.BACK)
	player.blast(Vector3.BACK)
	await _ticks(18, player, capture)
	var slots: Array[Dictionary] = capture.slots()
	_expect(slots.size() == 2 and slots[0].slot_id == 1 and slots[1].slot_id == 2 and slots[1].blast.is_empty(), "two finite combinations stay in displayed publication order with optional blast independent per slot")
	if slots.size() != 2:
		await _dispose(arena)
		return
	_expect(slots[1].dash.sequence > slots[0].primary.sequence and slots[1].primary.sequence > slots[1].dash.sequence, "second slot is a later completed dash and executed primary rather than repeated input or ghost recursion")
	paused = true
	await process_frame
	var paired_clock: float = player.get_world_action_clock()
	capture.advance(paired_clock)
	var two_slots: Dictionary = _json(capture.snapshot_state())
	var independent = Capture.new()
	var restored_ok: bool = independent.restore_state(two_slots, "actor-two/phase-2", paired_clock)
	_expect(restored_ok, "both real sequential slots and their optional blast survive JSON transport: " + independent.last_snapshot_error)
	if not restored_ok:
		await _dispose(arena)
		return
	var duplicate: Dictionary = two_slots.duplicate(true)
	duplicate.slots[1].dash.sequence = duplicate.slots[0].blast.sequence
	_expect(not independent.restore_state(duplicate, "actor-two/phase-2", paired_clock) and independent.last_snapshot_error.contains("only once") and Codec.same_values(two_slots, independent.snapshot_state()), "snapshot cannot reuse one publication as both an earlier blast and a later dash")
	var reversed: Dictionary = two_slots.duplicate(true)
	# Swap two distinct sequence identities while leaving each slot's internal
	# dash-before-primary order valid; their actual completion clocks disagree.
	reversed.slots[0].blast.sequence = two_slots.slots[1].dash.sequence
	reversed.slots[1].dash.sequence = two_slots.slots[0].blast.sequence
	_expect(not independent.restore_state(reversed, "actor-two/phase-2", paired_clock) and Codec.same_values(two_slots, independent.snapshot_state()), "unique but time-reversed publication identities reject without changing the restored buffer")
	paused = false
	var before: int = capture.state().cursor
	player.request_dash(Vector3.FORWARD)
	await _ticks(15, player, capture)
	player.slash(Vector3.BACK)
	await _ticks(18, player, capture)
	_expect(capture.state().allocated == 2 and capture.slots().size() == 2 and capture.state().cursor > before and not capture.state().has_dash_candidate, "further actual publications advance the cursor without a third hidden slot")
	_expect(not capture.discard_slot(2) and capture.discard_slot(1) and capture.take_next().slot_id == 2 and capture.take_next().is_empty(), "discard/take preserve once-only FIFO consumption instead of silently recycling slots")
	paused = true
	await process_frame
	paired_clock = player.get_world_action_clock()
	capture.advance(paired_clock)
	var consumed: Dictionary = _json(capture.snapshot_state())
	var copy = Capture.new()
	var consumed_ok: bool = copy.restore_state(consumed, "actor-two/phase-2", paired_clock)
	_expect(consumed_ok and copy.slots().is_empty() and _same_transport(copy.state().retired, [1, 2]), "consumed snapshot cannot resurrect either sequential slot: " + copy.last_snapshot_error)
	paused = false
	await _dispose(arena)


func _test_interleaved_dash_and_blast() -> void:
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var capture = Capture.new()
	var epoch: String = "actor-interleaved/phase"
	player.world_action_executed.connect(func(record: Dictionary) -> void: capture.ingest(record, epoch))
	_expect(await _arm(capture, player, epoch, 2), "two-slot capture arms for real interleaved publications")
	player.request_dash(Vector3.RIGHT)
	await _ticks(22, player, capture)
	player.slash(Vector3.FORWARD)
	_expect(player.request_dash(Vector3.LEFT), "new actual dash can begin while the previous combo blast window remains open")
	await _ticks(12, player, capture)
	player.blast(Vector3.BACK)
	await _ticks(8, player, capture)
	player.slash(Vector3.FORWARD)
	await _ticks(18, player, capture)
	var slots: Array[Dictionary] = capture.slots()
	var ordered: bool = slots.size() == 2
	if ordered:
		ordered = slots[0].dash.sequence == 1 and slots[0].primary.sequence == 2 and slots[0].blast.get("sequence") == 4 and slots[1].dash.sequence == 3 and slots[1].primary.sequence == 5
	_expect(ordered, "actual later dash publication may precede the earlier combination's optional blast without reusing either action")
	paused = true
	await process_frame
	var paired_clock: float = player.get_world_action_clock()
	capture.advance(paired_clock)
	var transported: Dictionary = _json(capture.snapshot_state())
	var restored = Capture.new()
	var accepted: bool = restored.restore_state(transported, epoch, paired_clock)
	_expect(accepted and Codec.same_values(transported, restored.snapshot_state()), "snapshot keeps legal cross-slot interleaving while enforcing unique ordered publications: " + restored.last_snapshot_error)
	await _dispose(arena)

func _test_inclusive_transport_boundary(actual_slot: Dictionary) -> void:
	# A labeled protocol edge derived from actual dash/primary/blast geometry,
	# gear and publication order. Only the blast's instantaneous timestamp is
	# moved to the exact deadline; this does not claim a 60 Hz input hit it.
	var dash: Dictionary = actual_slot.dash
	var primary: Dictionary = actual_slot.primary
	var blast: Dictionary = actual_slot.blast.duplicate(true)
	var deadline: float = float(primary.completed_at_s) + Capture.COMBO_WINDOW_S
	blast.started_at_s = deadline
	blast.completed_at_s = deadline
	_expect(not Player.encode_world_action_record(blast, deadline).is_empty(), "exact-deadline transport fixture preserves canonical actual attack geometry and gear")
	var capture = Capture.new()
	var epoch: String = "transport-edge/inclusive"
	_expect(capture.arm(epoch, 1, int(dash.sequence) - 1, float(dash.started_at_s)) and capture.ingest(dash, epoch) and capture.ingest(primary, epoch), "exact-boundary fixture consumes the same contiguous actual dash and primary")
	_expect(capture.advance(deadline) and capture.state().pending == 1 and capture.slots().is_empty(), "advance at the inclusive deadline cannot seal away a same-time publication")
	_expect(capture.ingest(blast, epoch) and capture.state().pending == 1 and not capture.snapshot_state().pending[0].blast.is_empty(), "actual completed blast published exactly at 0.28 seconds attaches before sealing")
	var snapshot: Dictionary = _json(capture.snapshot_state())
	var restored = Capture.new()
	var restored_ok: bool = restored.restore_state(snapshot, epoch, deadline)
	_expect(restored_ok and restored.state().pending == 1, "JSON roundtrip retains the boundary blast in a still-open inclusive window: " + restored.last_snapshot_error)
	if not restored_ok:
		return
	var bad: Dictionary = snapshot.duplicate(true)
	var early_sealed: Dictionary = bad.pending.pop_front()
	early_sealed.sealed_at_s = deadline
	bad.slots.append(early_sealed)
	_expect(not restored.restore_state(bad, epoch, deadline) and Codec.same_values(snapshot, restored.snapshot_state()), "sealed-at-deadline transport rejects atomically while a same-time blast remains legal")
	_expect(restored.advance(deadline + Capture.TIME_EPSILON_S * 0.5) and restored.state().pending == 1, "tiny canonical timestamp tolerance retains the inclusive boundary")
	_expect(restored.advance(deadline + 0.000001) and restored.state().sealed == 1 and restored.slots()[0].blast.completed_at_s == deadline, "first simulation advance past the inclusive boundary seals the exact accepted blast")
	var slash_only = Capture.new()
	slash_only.arm("transport-edge/slash", 1, int(dash.sequence) - 1, float(dash.started_at_s))
	slash_only.ingest(dash, "transport-edge/slash")
	slash_only.ingest(primary, "transport-edge/slash")
	_expect(slash_only.advance(deadline) and slash_only.state().pending == 1 and slash_only.advance(deadline + 0.000001) and slash_only.slots()[0].blast.is_empty(), "slash-only edge seals promptly after the inclusive deadline without an arbitrary extra wait")
	var late = Capture.new()
	late.arm("transport-edge/late", 1, int(dash.sequence) - 1, float(dash.started_at_s))
	late.ingest(dash, "transport-edge/late")
	late.ingest(primary, "transport-edge/late")
	blast.started_at_s = deadline + 0.000001
	blast.completed_at_s = blast.started_at_s
	_expect(late.ingest(blast, "transport-edge/late") and late.state().sealed == 1 and late.slots()[0].blast.is_empty(), "canonical actual-record fixture just past the inclusive window is consumed without joining the combo")
	var late_snapshot: Dictionary = _json(late.snapshot_state())
	bad = late_snapshot.duplicate(true)
	bad.slots[0].blast = Player.encode_world_action_record(blast, float(blast.completed_at_s))
	_expect(not late.restore_state(bad, "transport-edge/late", float(blast.completed_at_s)) and Codec.same_values(late_snapshot, late.snapshot_state()), "late blast insertion rejects atomically under the same inclusive snapshot guard")


func _test_buffered_supersession() -> void:
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var capture = Capture.new()
	player.world_action_executed.connect(func(record: Dictionary) -> void: capture.ingest(record, "actor-buffer/phase"))
	await _arm(capture, player, "actor-buffer/phase", 1)
	_expect(player.request_dash(Vector3.RIGHT) and not player.request_dash(Vector3.BACK) and capture.state().cursor == 0, "buffered swipe is neither a completed record nor a capture candidate")
	await _ticks(40, player, capture)
	var actual: Array[Dictionary] = player.get_world_action_records()
	_expect(actual.size() == 2 and capture.state().cursor == 2 and capture.state().allocated == 0, "both real buffered-chain completions publish but consume no slot without an attack")
	player.slash(Vector3(0.4, 0, -0.9))
	await _ticks(18, player, capture)
	var slot: Dictionary = capture.slots()[0]
	_expect(slot.dash.sequence == 2 and slot.dash.path == actual[1].path and slot.dash.world_origin == actual[1].world_origin and slot.primary.sequence == 3, "next actual primary pairs the second completed dash that superseded the first")
	var taken: Dictionary = capture.take_next()
	_expect(taken.generation == 1 and not capture.arm("actor-buffer/phase", 1, 0, 0.0), "same source cannot re-arm by rewinding already observed records/clock")
	_expect(capture.arm("actor-buffer/phase", 1, capture.state().cursor, player.get_world_action_clock()) and capture.state().generation == 2, "explicit visible new recording generation can arm only after its prior slot was consumed")
	await _dispose(arena)


func _test_attack_before_completion_and_prearm() -> void:
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var capture = Capture.new()
	player.world_action_executed.connect(func(record: Dictionary) -> void: capture.ingest(record, "actor-moving/phase"))
	await _arm(capture, player, "actor-moving/phase", 1)
	player.request_dash(Vector3.RIGHT)
	await _ticks(2, player, capture)
	paused = true
	var pending_actor: Dictionary = player.snapshot_state()
	var before_pending: Dictionary = capture.snapshot_state()
	_expect(not pending_actor.world_actions.pending_dash.is_empty() and not capture.ingest(pending_actor.world_actions.pending_dash, "actor-moving/phase") and Codec.same_values(before_pending, capture.snapshot_state()), "actual unfinished actor snapshot path rejects as a noncompleted publication without a sample")
	paused = false
	player.slash(Vector3.FORWARD)
	_expect(capture.state().cursor == 1 and capture.state().allocated == 0, "attack during an unfinished first dash is observed but has no completed route to pair")
	await _ticks(12, player, capture)
	player.blast(Vector3.BACK)
	_expect(capture.state().has_dash_candidate and capture.state().allocated == 0 and capture.slots().is_empty(), "later dash completion and an earlier primary's blast never retroactively create a captured combination")
	await _ticks(12, player, capture)
	player.slash(Vector3.LEFT)
	await _ticks(18, player, capture)
	var slot: Dictionary = capture.slots()[0]
	_expect(slot.dash.sequence == 2 and slot.primary.sequence == 4 and slot.blast.is_empty(), "only the next actually executed primary after completion pairs that route")
	await _dispose(arena)
	arena = await _arena()
	player = arena.player
	player.request_dash(Vector3.BACK)
	await _ticks(2, player)
	capture = Capture.new()
	# Deliberately exercise older-start filtering; production callers require
	# the stable paused arm barrier to resolve equal-clock start ambiguity.
	paused = true
	_expect(capture.arm("actor-prearm/phase", 1, 0, player.get_world_action_clock()), "older-start transport fixture arms after the actual dash already began")
	paused = false
	player.world_action_executed.connect(func(record: Dictionary) -> void: capture.ingest(record, "actor-prearm/phase"))
	await _ticks(15, player, capture)
	player.slash(Vector3.RIGHT)
	await _ticks(18, player, capture)
	_expect(capture.state().cursor == 2 and capture.state().allocated == 0 and not capture.state().has_dash_candidate, "completed dash begun before the arm clock is consumed but never sampled")
	await _dispose(arena)


func _test_zero_completion_and_late_blast() -> void:
	var arena: Dictionary = await _arena(true)
	var player: CinderPlayer = arena.player
	var records: Array[Dictionary] = []
	player.world_action_executed.connect(func(record: Dictionary) -> void: records.append(record.duplicate(true)))
	var capture = Capture.new()
	await _arm(capture, player, "actor-zero/phase", 1)
	player.request_dash(Vector3.RIGHT)
	await _ticks(24, player)
	player.request_dash(Vector3.RIGHT)
	await _ticks(15, player)
	_expect(records.size() == 2 and records[1].blocked and records[1].distance < 0.01, "actual wall fixture publishes its almost/fully blocked accepted dash completion truthfully")
	_expect(capture.ingest(records[0], "actor-zero/phase") and capture.state().has_dash_candidate, "first real positive completed route is eligible")
	var zero: Dictionary = records[1].duplicate(true)
	# Physics recovery can leave a microscopic nonzero travel. The exact-zero
	# protocol boundary is a canonical fixture derived from the real blocked
	# record's clock/gear, not a claim that the solver produced exactly zero.
	zero.landing = zero.world_origin
	zero.distance = 0.0
	for sample: Dictionary in zero.path:
		sample.position = zero.world_origin
	_expect(not Player.encode_world_action_record(zero, float(zero.completed_at_s)).is_empty(), "labeled exact-zero completed transport fixture satisfies the same canonical player validator")
	_expect(capture.ingest(zero, "actor-zero/phase") and not capture.state().has_dash_candidate and capture.state().allocated == 0, "zero-travel completion supersedes an old route without becoming a sample itself")
	player.slash(Vector3.BACK)
	_expect(capture.ingest(records[-1], "actor-zero/phase") and capture.state().allocated == 0, "an attack after zero travel cannot resurrect the superseded positive route")
	await _dispose(arena)
	arena = await _arena()
	player = arena.player
	capture = Capture.new()
	player.world_action_executed.connect(func(record: Dictionary) -> void: capture.ingest(record, "actor-late/phase"))
	await _arm(capture, player, "actor-late/phase", 1)
	player.request_dash(Vector3.RIGHT)
	await _ticks(15, player, capture)
	player.slash(Vector3.FORWARD)
	await _ticks(21, player, capture)
	player.shells = 1
	_expect(player.blast(Vector3.BACK) == 0 and capture.slots()[0].blast.is_empty(), "actually executed blast outside the quick window remains excluded from the sealed slash-only combination")
	await _dispose(arena)


func _test_stream_loss_and_atomic_validation() -> void:
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var capture = Capture.new()
	await _arm(capture, player, "actor-gap/attempt", 1)
	player.request_dash(Vector3.RIGHT)
	await _ticks(15, player)
	player.slash(Vector3.BACK)
	var records: Array[Dictionary] = player.get_world_action_records()
	var before: Dictionary = capture.snapshot_state()
	_expect(not capture.ingest(records[1], "actor-gap/attempt") and Codec.same_values(before, capture.snapshot_state()), "dropped publication history rejects atomically instead of pairing a guessed route")
	_expect(not capture.ingest(records[0], "wrong-actor/attempt") and Codec.same_values(before, capture.snapshot_state()), "source epoch mismatch cannot consume another actor's real record")
	var bad_record: Dictionary = records[0].duplicate(true)
	bad_record.origin = "apparition"
	_expect(not capture.ingest(bad_record, "actor-gap/attempt") and Codec.same_values(before, capture.snapshot_state()), "replays cannot record themselves or begin a ghost recursion")
	bad_record = records[0].duplicate(true)
	bad_record.screen_release_anchor = Vector2(10, 20)
	_expect(not capture.ingest(bad_record, "actor-gap/attempt") and Codec.same_values(before, capture.snapshot_state()), "screen input fields never enter canonical world capture")
	_expect(capture.ingest(records[0], "actor-gap/attempt") and capture.ingest(records[1], "actor-gap/attempt"), "recovering exact missing contiguous publications safely resumes the pending combination")
	_expect(not capture.ingest(records[1], "actor-gap/attempt"), "duplicate publication cannot spend the slot a second time")
	paused = true
	capture.advance(player.get_world_action_clock())
	var snapshot: Dictionary = _json(capture.snapshot_state())
	for change: String in ["capacity", "retired", "record", "unknown", "sealed", "generation"]:
		var bad: Dictionary = snapshot.duplicate(true)
		match change:
			"capacity": bad.max_slots = 3
			"retired": bad.retired = [1, 1]
			"record": bad.pending[0].primary.resolved_stats.primary_range = 999.0
			"unknown": bad.aim_screen_point = [1.0, 2.0]
			"sealed": bad.pending[0].sealed_at_s = bad.pending[0].window_until_s
			"generation": bad.pending[0].generation += 1
		_expect(not capture.restore_state(bad, "actor-gap/attempt", player.get_world_action_clock()) and Codec.same_values(snapshot, capture.snapshot_state()), "malformed snapshot data rejects before record/slot/cursor mutation")
	var copied: Dictionary = capture.snapshot_state()
	copied.pending[0].dash.path.clear()
	_expect(Codec.same_values(snapshot, capture.snapshot_state()), "JSON transport getter protects deep sampled paths")
	_expect(capture.cancel() and not capture.state().armed and capture.state().retired == [1] and capture.snapshot_state().pending.is_empty(), "phase retry cancellation clears unfinished combinations and stale routes without replaying them")
	_expect(not capture.ingest(records[1], "actor-gap/attempt") and capture.arm("new-actor/new-attempt", 2, 0, 0.0), "cancelled old attempt rejects stale events while an explicitly new epoch may start a new actor clock")
	paused = false
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


func _arm(capture: CinderActionCapture, player: CinderPlayer, epoch: String, capacity: int) -> bool:
	paused = true
	await process_frame
	var actor: Dictionary = player.get_threat_response_state()
	var records: Array[Dictionary] = player.get_world_action_records()
	var cursor: int = 0 if records.is_empty() else int(records[-1].sequence)
	var result: bool = actor.stable and capture.arm(epoch, capacity, cursor, player.get_world_action_clock())
	paused = false
	return result


func _ticks(count: int, player: CinderPlayer, capture: CinderActionCapture = null) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame
		if capture != null:
			capture.advance(player.get_world_action_clock())


func _json(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value, "", true, true))


func _same_transport(left: Variant, right: Variant) -> bool:
	# JSON changes integral Variant types and can shift a parsed decimal by one
	# binary rounding step. Do not use broad gameplay approximation: native
	# Vector3s are exact, keys/order match, and scalar roundoff is <=1e-12 here.
	if Codec.is_number(left) and Codec.is_number(right):
		return absf(float(left) - float(right)) <= 0.000000000001
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size(): return false
		for key: String in left:
			if not right.has(key) or not _same_transport(left[key], right[key]): return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _same_transport(left[index], right[index]): return false
		return true
	return typeof(left) == typeof(right) and left == right


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
