extends SceneTree
## Actual actor/capture/sequence fixtures; no ghost, reservation or damage test.

const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Cursor = preload("res://scripts/combat/replay_cursor.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const AUTHORED: Dictionary = {"recognition_s": 0.2, "warning_s": 0.5, "locked_lead_s": 1.1, "inter_echo_gap_s": 0.7, "final_recovery_s": 1.6, "tether_position": Vector3.ZERO}

class TickClock extends Node:
	var clock_s: float = 0.0
	var ticks: int = 0
	var stop_at: int = 6

	func _physics_process(delta: float) -> void:
		clock_s += delta
		ticks += 1
		if ticks >= stop_at:
			set_physics_process(false)

var _checks: int = 0
var _failures: int = 0
var _two_plan: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _single_shortened()
	await _two_actual()
	_transport_rejections()
	_exact_identity_rejections()
	_inverse_origin_edge()
	_derived_due_edge()
	_equal_time_transport_edge()
	_finite_pose_transport_edge()
	await _actual_clock_edges()
	print("Replay cursor smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _single_shortened() -> void:
	var fixture: Dictionary = await _record(1, true)
	if fixture.is_empty():
		return
	var plan: Dictionary = fixture.plan
	var native: Dictionary = fixture.native
	var epoch: String = String(plan.source_epoch)
	var cursor = Cursor.new()
	_expect(cursor.configure(plan, epoch, 1, 10.0), "actual shortened slash-only sequence binds as an unarmed owner")
	var frozen: Dictionary = cursor.snapshot_state()
	_expect(cursor.state().phase == "warning" and not cursor.state().armed and cursor.state().poses.is_empty(), "unarmed preview exposes neither a physical ghost nor attacks")
	_expect(not cursor.arm(9.99, 10.49) and cursor.snapshot_state() == frozen, "early lock rejects atomically rather than shortening the full warning")
	_expect(not cursor.arm(10.6, 11.0) and cursor.snapshot_state() == frozen, "noncanonical timeline origin cannot retime geometry independently")
	var unarmed: Dictionary = cursor.advance(12.0)
	_expect(unarmed.accepted and unarmed.events.is_empty() and unarmed.poses.is_empty() and cursor.state().next_event_index == 0, "even a late unarmed clock cannot deliver any recorded attack")
	var warning_save: Dictionary = _json(cursor.snapshot_state())
	var warning_restore = Cursor.new()
	_expect(warning_restore.restore_state(warning_save, plan, epoch, 1, 12.0) and warning_restore.advance(12.0).events.is_empty(), "late unarmed JSON continuation stays unarmed without manufactured attacks")
	_expect(cursor.arm(11.5, 12.0), "actual delayed lock retains the canonical full locked lead")
	_expect(not cursor.arm(11.5, 12.0), "already armed owner cannot arm a second time")
	var origin: float = 11.5
	var slot: Dictionary = native.timeline.slots[0]
	var playback: float = origin + float(slot.from_s)
	_expect(cursor.state().phase == "lock" and cursor.advance(playback - 0.01).poses.is_empty(), "locked lead remains harmless and ghost-free until the original route starts")
	var begin: Dictionary = cursor.advance(playback)
	_expect(begin.events.is_empty() and begin.poses.size() == 1 and begin.poses[0].position == slot.route[0].position and begin.poses[0].direction == native.capture_snapshot.slots[0].dash.direction and not begin.poses[0].movement_damage, "playback begins at the exact recorded absolute origin with harmless travel")
	var middle_index: int = maxi(1, int(slot.route.size() / 2))
	var left: Dictionary = slot.route[middle_index - 1]
	var right: Dictionary = slot.route[middle_index]
	var midpoint: float = (float(left.at_s) + float(right.at_s)) * 0.5
	var travel: Dictionary = cursor.advance(origin + midpoint)
	_expect(travel.events.is_empty() and travel.poses[0].position.is_equal_approx((left.position as Vector3).lerp(right.position, 0.5)), "absolute route interpolates only between the actual neighboring physics samples")
	var travel_save: Dictionary = _json(cursor.snapshot_state())
	var resumed = Cursor.new()
	_expect(resumed.restore_state(travel_save, plan, epoch, 1, float(travel_save.last_advanced_clock_s)) and resumed.state().poses[0].position == cursor.state().poses[0].position, "JSON restore recreates the same shortened mid-route pose without advancing")
	var primary_time: float = origin + float(slot.events[0].at_s)
	var primary: Dictionary = cursor.advance(primary_time)
	_expect(primary.events.size() == 1 and primary.events[0].kind == "primary" and primary.events[0].record.direction == native.capture_snapshot.slots[0].primary.direction and primary.events[0].record.geometry == native.capture_snapshot.slots[0].primary.geometry, "slash-only due event keeps the actual continuous aim and canonical geometry")
	_expect(primary.poses[0].position == native.capture_snapshot.slots[0].dash.landing and cursor.state().next_event_index == 1 and cursor.advance(primary_time).events.is_empty(), "actual collision-shortened landing is exact and event prefix commits before a nested caller advance")
	_expect(resumed.advance(primary_time).events.size() == 1 and resumed.advance(primary_time).events.is_empty(), "restored travel continuation delivers the future primary once only")
	var after_hit: Dictionary = cursor.snapshot_state()
	for bad_clock: float in [primary_time - 0.001, -1.0, INF, NAN]:
		_expect(not cursor.advance(bad_clock).accepted and cursor.snapshot_state() == after_hit, "invalid/backward advance leaves once-only progress unchanged")
	paused = true
	var actor_before: Dictionary = fixture.player.snapshot_state()
	await create_timer(0.12, true).timeout
	_expect(cursor.snapshot_state() == after_hit and Codec.same_values(actor_before, fixture.player.snapshot_state()), "paused wall time changes neither external-clock cursor nor actual actor resources")
	var final: Dictionary = cursor.advance(origin + float(native.timeline.tether_from_s))
	_expect(final.phase == "recovery" and final.poses.is_empty() and final.events.is_empty(), "complete intrinsic slot end hides the ghost for the full tether recovery")
	_expect(cursor.advance(origin + float(native.timeline.tether_until_s)).phase == "complete", "final recovery ends at the exact authored deadline")
	_expect(not cursor.restore_state(travel_save, plan, epoch, 1, float(travel_save.last_advanced_clock_s)), "existing completed owner cannot rewind into a prior saved route")
	await _dispose(fixture)


func _two_actual() -> void:
	var fixture: Dictionary = await _record(2)
	if fixture.is_empty():
		return
	var plan: Dictionary = fixture.plan
	_two_plan = plan.duplicate(true)
	var native: Dictionary = fixture.native
	var epoch: String = String(plan.source_epoch)
	var cursor = _armed(plan)
	var origin: float = 10.5
	var first: Dictionary = native.timeline.slots[0]
	var second: Dictionary = native.timeline.slots[1]
	var primary_time: float = origin + float(first.events[0].at_s)
	var blast_time: float = origin + float(first.events[1].at_s)
	_expect(cursor.advance(primary_time).events.size() == 1, "first actual primary delivers before its independently aimed optional blast")
	var between: float = (primary_time + blast_time) * 0.5
	_expect(cursor.advance(between).events.is_empty(), "actual captured blast spacing has no extra attack in between")
	var saved: Dictionary = _json(cursor.snapshot_state())
	var resumed = Cursor.new()
	_expect(resumed.restore_state(saved, plan, epoch, 1, between) and resumed.advance(between).events.is_empty(), "pending optional-blast JSON restore does not replay the past primary")
	var blast: Dictionary = cursor.advance(blast_time)
	var restored_blast: Dictionary = resumed.advance(blast_time)
	_expect(blast.events.size() == 1 and restored_blast.events.size() == 1 and blast.events[0].record.direction == Vector3.RIGHT and Codec.same_values(blast.events[0], restored_blast.events[0]), "uninterrupted and restored optional blast preserve exact aim, geometry, gear and timing")
	_expect(blast.events[0].scheduled_at_s == blast_time and blast.events[0].record.completed_at_s == native.capture_snapshot.slots[0].blast.completed_at_s and blast.events[0].record.origin == "player_direct", "delivery retains original historical actor record alongside its separate sequence deadline")
	var gap: float = origin + (float(first.end_s) + float(second.from_s)) * 0.5
	var gap_result: Dictionary = cursor.advance(gap)
	_expect(gap_result.phase == "gap" and gap_result.poses.is_empty() and gap_result.events.is_empty(), "inter-echo gap shows no ghost or invented connecting travel")
	_expect(first.route[-1].position != second.route[0].position, "actual extra unpaired dash makes the next absolute route origin distinct")
	var gap_save: Dictionary = _json(cursor.snapshot_state())
	var gap_restore = Cursor.new()
	_expect(gap_restore.restore_state(gap_save, plan, epoch, 1, gap) and gap_restore.state().poses.is_empty(), "saved inter-echo gap remains empty after quiet restore")
	var next: Dictionary = cursor.advance(origin + float(second.from_s))
	_expect(next.events.is_empty() and next.poses.size() == 1 and next.poses[0].slot_id == second.slot_id and next.poses[0].position == second.route[0].position, "second ghost starts at its own exact source rather than the preceding landing")
	var second_primary: Dictionary = cursor.advance(origin + float(second.events[0].at_s))
	_expect(second_primary.events.size() == 1 and second_primary.events[0].record.equipment_ids == native.capture_snapshot.slots[1].primary.equipment_ids and second_primary.events[0].record.equipment_ids.weapon != blast.events[0].record.equipment_ids.weapon, "second empty-ammo primary keeps its own static legal weapon snapshot")
	var jumped = _armed(plan)
	var final_clock: float = origin + float(native.timeline.tether_until_s)
	var batch: Dictionary = jumped.advance(final_clock)
	_expect(batch.events.size() == 3 and batch.events[0].event_id == first.events[0].event_id and batch.events[1].event_id == first.events[1].event_id and batch.events[2].event_id == second.events[0].event_id, "large monotonic advance returns the complete bounded canonical event order once")
	_expect(jumped.state().next_event_index == 3 and jumped.advance(final_clock).events.is_empty() and batch.phase == "complete" and batch.poses.is_empty(), "whole due batch commits before caller processing and produces no third hidden ghost")
	var complete_save: Dictionary = _json(jumped.snapshot_state())
	var complete_restore = Cursor.new()
	_expect(complete_restore.restore_state(complete_save, plan, epoch, 1, final_clock) and complete_restore.advance(final_clock).events.is_empty(), "completed JSON owner restores without redelivering any past action")
	var immutable: Dictionary = cursor.snapshot_state()
	second_primary.events[0].record.geometry.reach = 99
	batch.events.clear()
	var copied: Dictionary = cursor.state()
	copied.executed_events.clear()
	copied.poses[0].equipment_ids.weapon = "forged"
	_expect(cursor.snapshot_state() == immutable, "caller mutation of native records, poses and history cannot rewrite owner data")
	copied = cursor.snapshot_state()
	copied.sequence.timeline.slots.clear()
	_expect(cursor.snapshot_state() == immutable, "finite JSON getter protects the exact frozen sequence from nested mutation")
	await _dispose(fixture)


func _transport_rejections() -> void:
	if _two_plan.is_empty():
		_expect(false, "actual two-slot fixture required for rejection tests")
		return
	var native_reader = Sequence.new()
	native_reader.restore_state(_two_plan, _two_plan.source_epoch, 1)
	var native: Dictionary = native_reader.state()
	var epoch: String = String(_two_plan.source_epoch)
	var cursor = _armed(_two_plan)
	var blast_time: float = 10.5 + float(native.timeline.slots[0].events[1].at_s)
	cursor.advance(blast_time)
	var original: Dictionary = cursor.snapshot_state()
	for change: String in ["extra", "schema", "epoch", "generation", "clock", "phase", "origin", "unarm", "index", "prefix", "order", "dispatch", "sequence", "third", "future"]:
		var bad: Dictionary = original.duplicate(true)
		match change:
			"extra": bad.screen_release = [540, 1170]
			"schema": bad.schema_version = 2
			"epoch": bad.source_epoch = "another-attempt"
			"generation": bad.generation = 2
			"clock": bad.last_advanced_clock_s += 0.001
			"phase": bad.phase = "gap"
			"origin": bad.timeline_origin_s += 0.01
			"unarm": bad.armed = false
			"index": bad.next_event_index = 1
			"prefix": bad.executed_events[0].event_id = "unknown"
			"order": bad.executed_events.reverse()
			"dispatch": bad.executed_events[0].dispatch_clock_s = 11.0
			"sequence": bad.sequence.timeline.slots[0].route[0].position[0] += 0.01
			"third": bad.sequence.timeline.slots.append(bad.sequence.timeline.slots[1].duplicate(true))
			"future":
				bad.next_event_index = 3
				bad.executed_events.append({"event_id": native.timeline.slots[1].events[0].event_id, "scheduled_at_s": 10.5 + float(native.timeline.slots[1].events[0].at_s), "dispatch_clock_s": blast_time})
		_expect(not cursor.restore_state(bad, _two_plan, epoch, 1, blast_time) and cursor.snapshot_state() == original, "malformed " + change + " rejects atomically without replaying or losing progress")
	_expect(not cursor.snapshot_error(original, _two_plan, epoch, 1, blast_time + 1.0).is_empty(), "external scheduler clock cannot silently disagree with cursor progress")
	var forged = _two_plan.duplicate(true)
	forged.capture_snapshot.slots[0].primary.origin = "apparition"
	var empty = Cursor.new()
	_expect(not empty.configure(forged, epoch, 1, 10.0) and empty.snapshot_state().is_empty(), "ghost-origin or malformed frozen canonical records reject before owner binding")
	_expect(not empty.configure(_two_plan, epoch, 2, 10.0), "different expected capture generation cannot claim this sequence")
	_expect(not empty.configure(_two_plan, epoch, 1, Cursor.MAX_CLOCK_S), "finite clock overflow of the complete plan rejects before assignment")
	var changed_history: Dictionary = original.duplicate(true)
	changed_history.executed_events[0].dispatch_clock_s = float(changed_history.executed_events[0].scheduled_at_s) + 0.001
	_expect(cursor.snapshot_error(changed_history, _two_plan, epoch, 1, blast_time).is_empty() and not cursor.restore_state(changed_history, _two_plan, epoch, 1, blast_time) and cursor.snapshot_state() == original, "existing once-only owner cannot rewrite otherwise valid delivery history")
	_expect(cursor.restore_state(_json(original), _two_plan, epoch, 1, blast_time) and cursor.advance(blast_time).events.is_empty(), "identical JSON restore is idempotent without delivery")
	var rebound = Sequence.new()
	rebound.configure("cursor/other-plan", _two_plan.capture_snapshot, AUTHORED, epoch, 1)
	var different = _armed(rebound.snapshot_state())
	different.advance(blast_time)
	_expect(not cursor.restore_state(different.snapshot_state(), rebound.snapshot_state(), epoch, 1, blast_time), "existing owner cannot adopt a different valid immutable sequence")


func _exact_identity_rejections() -> void:
	if _two_plan.is_empty():
		return
	var reader = Sequence.new()
	reader.restore_state(_two_plan, _two_plan.source_epoch, 1)
	var native: Dictionary = reader.state()
	var epoch: String = String(_two_plan.source_epoch)
	var cursor = _armed(_two_plan)
	var primary_clock: float = 10.5 + float(native.timeline.slots[0].events[0].at_s)
	var blast_clock: float = 10.5 + float(native.timeline.slots[0].events[1].at_s)
	cursor.advance(primary_clock)
	cursor.advance(blast_clock)
	var saved: Dictionary = cursor.snapshot_state()
	_expect(_same(saved, _json(saved)), "tagged JSON preserves every saved scalar bit and type in an actual two-slot cursor")
	_expect(not cursor.snapshot_error(saved, _two_plan, epoch, 1, _adjacent_float(blast_clock, 1)).is_empty(), "one-bit external scheduler clock disagreement rejects without a transport tolerance")
	for change: String in ["sequence", "clock", "scheduled", "origin"]:
		var bad: Dictionary = saved.duplicate(true)
		match change:
			"sequence": bad.sequence.authored.warning_s = _adjacent_float(float(bad.sequence.authored.warning_s), 1)
			"clock": bad.last_advanced_clock_s = _adjacent_float(float(bad.last_advanced_clock_s), 1)
			"scheduled": bad.executed_events[0].scheduled_at_s = _adjacent_float(float(bad.executed_events[0].scheduled_at_s), 1)
			"origin": bad.timeline_origin_s = _adjacent_float(float(bad.timeline_origin_s), 1)
		_expect(not cursor.restore_state(_json(bad), _two_plan, epoch, 1, blast_clock) and _same(cursor.snapshot_state(), saved), "one-bit " + change + " mutation rejects atomically after exact transport")
	var history: Dictionary = saved.duplicate(true)
	history.executed_events[0].dispatch_clock_s = _adjacent_float(primary_clock, 1)
	_expect(cursor.snapshot_error(history, _two_plan, epoch, 1, blast_clock).is_empty(), "one-bit later primary dispatch is independently valid bounded historical data")
	_expect(not cursor.restore_state(_json(history), _two_plan, epoch, 1, blast_clock) and _same(cursor.snapshot_state(), saved), "existing owner rejects a one-bit rewrite of a valid already delivered prefix")
	var locked = _armed(_two_plan)
	locked.advance(11.125)
	var lock_save: Dictionary = locked.snapshot_state()
	var configured: Dictionary = lock_save.duplicate(true)
	configured.configured_at_s = _adjacent_float(float(configured.configured_at_s), 1)
	_expect(locked.snapshot_error(configured, _two_plan, epoch, 1, 11.125).is_empty(), "one-bit changed preview remains internally coherent for a fresh data owner")
	_expect(not locked.restore_state(_json(configured), _two_plan, epoch, 1, 11.125) and _same(locked.snapshot_state(), lock_save), "existing owner cannot rebind its configured preview by one bit")
	var rearmed: Dictionary = lock_save.duplicate(true)
	rearmed.armed_at_s = _adjacent_float(float(rearmed.armed_at_s), 1)
	rearmed.timeline_origin_s = float(rearmed.armed_at_s) - float(AUTHORED.warning_s)
	_expect(locked.snapshot_error(rearmed, _two_plan, epoch, 1, 11.125).is_empty(), "one-bit changed arm and its exact inverse origin form coherent fresh data")
	_expect(not locked.restore_state(_json(rearmed), _two_plan, epoch, 1, 11.125) and _same(locked.snapshot_state(), lock_save), "existing owner cannot rewrite its immutable actual arm and origin by one bit")
	var preview = Cursor.new()
	preview.configure(_two_plan, epoch, 1, 0.0)
	preview.advance(0.25)
	var preview_save: Dictionary = preview.snapshot_state()
	var backward: Dictionary = preview_save.duplicate(true)
	backward.last_advanced_clock_s = _adjacent_float(0.25, -1)
	_expect(preview.snapshot_error(backward, _two_plan, epoch, 1, float(backward.last_advanced_clock_s)).is_empty(), "one-bit earlier warning clock is internally valid for a fresh owner")
	_expect(not preview.restore_state(_json(backward), _two_plan, epoch, 1, float(backward.last_advanced_clock_s)) and _same(preview.snapshot_state(), preview_save), "existing owner rejects even one-bit rewind with an otherwise exactly paired clock")
	_expect(not preview.advance(float(backward.last_advanced_clock_s)).accepted and _same(preview.snapshot_state(), preview_save), "public advance also rejects one-bit rewind without changing saved progress")


func _inverse_origin_edge() -> void:
	if _two_plan.is_empty():
		return
	# Labelled clock arithmetic only; actual capture geometry is unchanged.
	var authored: Dictionary = AUTHORED.duplicate(true)
	authored.warning_s = 0.2
	var sequence = Sequence.new()
	_expect(sequence.configure("cursor/inverse-origin", _two_plan.capture_snapshot, authored, _two_plan.source_epoch, 1), "inverse-origin arithmetic fixture retains actual canonical capture data")
	var cursor = Cursor.new()
	var plan: Dictionary = sequence.snapshot_state()
	if plan.is_empty():
		return
	var lock_s: float = 0.9
	var origin_s: float = lock_s - float(authored.warning_s)
	_expect(origin_s + float(authored.warning_s) != lock_s, "fixture distinguishes inverse origin from a rounded subtract-then-add identity")
	_expect(cursor.configure(plan, _two_plan.source_epoch, 1, 0.0) and not cursor.arm(_adjacent_float(origin_s, 1), lock_s) and not cursor.state().armed, "one-bit noncanonical origin cannot arm despite an otherwise eligible clock")
	_expect(cursor.arm(origin_s, lock_s), "exact canonical inverse origin arms without requiring rounded re-add equality")
	var restored = Cursor.new()
	_expect(restored.restore_state(_json(cursor.snapshot_state()), plan, _two_plan.source_epoch, 1, lock_s) and restored.state().timeline_origin_s == origin_s and restored.state().armed_at_s == lock_s, "inverse-origin tagged continuation preserves actual lock and origin exactly")


func _derived_due_edge() -> void:
	if _two_plan.is_empty():
		return
	var reader = Sequence.new()
	reader.restore_state(_two_plan, _two_plan.source_epoch, 1)
	var native: Dictionary = reader.state()
	var cursor = _armed(_two_plan)
	var scheduled_s: float = 10.5 + float(native.timeline.slots[0].events[0].at_s)
	var derived_edge_s: float = scheduled_s - Cursor.TIME_EPSILON_S * 0.5
	var due: Dictionary = cursor.advance(derived_edge_s)
	_expect(derived_edge_s < scheduled_s and due.events.size() == 1 and due.events[0].scheduled_at_s == scheduled_s and due.events[0].dispatch_clock_s == derived_edge_s, "derived inclusive due tolerance preserves both distinct exact clocks without a physical damage claim")
	var restored = Cursor.new()
	_expect(restored.restore_state(_json(cursor.snapshot_state()), _two_plan, _two_plan.source_epoch, 1, derived_edge_s) and restored.advance(derived_edge_s).events.is_empty(), "derived due boundary restores exactly and does not redeliver its committed data event")


func _actual_clock_edges() -> void:
	if _two_plan.is_empty():
		return
	_expect(Engine.physics_ticks_per_second == 60, "actual clock fixture uses the project's unchanged 60 Hz simulation")
	if Engine.physics_ticks_per_second != 60:
		return
	paused = true
	var clock := TickClock.new()
	root.add_child(clock)
	paused = false
	var completed: bool = await _until_clock(clock, 6)
	_expect(completed, "bounded actual physics callback fixture reaches exactly six ticks")
	if not completed:
		clock.queue_free()
		await process_frame
		return
	paused = true
	await process_frame
	var six_tick_clock: float = clock.clock_s
	var cursor = Cursor.new()
	cursor.configure(_two_plan, _two_plan.source_epoch, 1, 0.0)
	cursor.advance(six_tick_clock)
	var saved: Dictionary = cursor.snapshot_state()
	var roundtrip: Dictionary = _json(saved)
	_expect(six_tick_clock != 0.1 and six_tick_clock > 0.099 and six_tick_clock < 0.101, "actual six-tick accumulation exposes the observed nondecimal float64 clock")
	_expect(_same(saved, roundtrip) and roundtrip.last_advanced_clock_s is float and float(roundtrip.last_advanced_clock_s) == six_tick_clock, "exact JSON retains the actual six-tick clock bits and float type")
	var restored = Cursor.new()
	_expect(restored.restore_state(roundtrip, _two_plan, _two_plan.source_epoch, 1, six_tick_clock) and restored.advance(six_tick_clock).events.is_empty(), "six-tick tagged continuation stays exactly paired and quiet")
	_expect(not cursor.snapshot_error(roundtrip, _two_plan, _two_plan.source_epoch, 1, 0.1).is_empty(), "decimal 0.1 cannot silently replace the actual six-tick saved clock")
	clock.stop_at = 30
	clock.set_physics_process(true)
	paused = false
	completed = await _until_clock(clock, 30)
	_expect(completed, "bounded actual physics callback fixture reaches exactly thirty ticks")
	if not completed:
		clock.queue_free()
		await process_frame
		return
	paused = true
	await process_frame
	var early_clock: float = clock.clock_s
	var nominal_lock: float = float(AUTHORED.warning_s)
	_expect(early_clock < nominal_lock and nominal_lock - early_clock < Cursor.TIME_EPSILON_S, "actual thirty-tick accumulation is strictly before the nominal warning boundary")
	cursor.advance(early_clock)
	var before_arm: Dictionary = cursor.snapshot_state()
	_expect(not cursor.arm(0.0, early_clock) and _same(cursor.snapshot_state(), before_arm), "actual one-bit early clock cannot arm or shorten the complete warning")
	var early_save: Dictionary = _json(before_arm)
	var forged_arm: Dictionary = early_save.duplicate(true)
	forged_arm.armed = true
	forged_arm.armed_at_s = early_clock
	forged_arm.timeline_origin_s = 0.0
	forged_arm.phase = "lock"
	_expect(not cursor.restore_state(forged_arm, _two_plan, _two_plan.source_epoch, 1, early_clock) and _same(cursor.snapshot_state(), before_arm), "transport cannot manufacture an early lock using the derived due epsilon")
	clock.stop_at = 31
	clock.set_physics_process(true)
	paused = false
	completed = await _until_clock(clock, 31)
	_expect(completed, "bounded actual clock reaches the first physical tick after full warning")
	paused = true
	await process_frame
	var actual_lock: float = clock.clock_s
	var actual_origin: float = actual_lock - nominal_lock
	_expect(completed and actual_lock >= nominal_lock and cursor.arm(actual_origin, actual_lock) and cursor.state().phase == "lock", "first eligible actual tick arms with exact inverse origin and unchanged full locked lead")
	var locked_restore = Cursor.new()
	_expect(locked_restore.restore_state(_json(cursor.snapshot_state()), _two_plan, _two_plan.source_epoch, 1, actual_lock) and locked_restore.state().timeline_origin_s == actual_origin and locked_restore.state().armed_at_s == actual_lock, "actual delayed lock survives exact tagged continuation without rounding or clamping")
	clock.queue_free()
	paused = false
	await process_frame


func _until_clock(clock: TickClock, expected_ticks: int) -> bool:
	for _index: int in range(180):
		if clock.ticks == expected_ticks:
			return true
		await physics_frame
		await process_frame
	return clock.ticks == expected_ticks


func _equal_time_transport_edge() -> void:
	if _two_plan.is_empty():
		return
	# Labelled transport edge: retain actual geometry/gear/action identities and
	# move only this real blast's source timestamps to its primary's clock.
	# Canonical validators still establish that this is supported transport.
	var capture: Dictionary = _two_plan.capture_snapshot.duplicate(true)
	capture.slots[0].blast.started_at_s = capture.slots[0].primary.completed_at_s
	capture.slots[0].blast.completed_at_s = capture.slots[0].primary.completed_at_s
	var sequence = Sequence.new()
	_expect(sequence.configure("cursor/equal-time-transport", capture, AUTHORED, _two_plan.source_epoch, 1), "labelled equal-time transport derives from actual canonical attack records")
	var plan: Dictionary = sequence.snapshot_state()
	if plan.is_empty():
		return
	var native: Dictionary = sequence.state()
	var cursor = _armed(plan)
	var clock_s: float = 10.5 + float(native.timeline.slots[0].events[0].at_s)
	var events: Array = cursor.advance(clock_s).events
	_expect(events.size() == 2 and events[0].kind == "primary" and events[1].kind == "blast" and float(events[0].scheduled_at_s) == float(events[1].scheduled_at_s), "equal-time instant events retain primary/blast order with exactly equal deadlines in one committed prefix")
	_expect(cursor.state().next_event_index == 2 and cursor.advance(clock_s).events.is_empty(), "equal-time batch is fully consumed before a nested caller observes it")
	var snapshot: Dictionary = _json(cursor.snapshot_state())
	var resumed = Cursor.new()
	_expect(resumed.restore_state(snapshot, plan, _two_plan.source_epoch, 1, clock_s) and resumed.advance(clock_s).events.is_empty(), "equal-time JSON continuation cannot replay either past event")


func _finite_pose_transport_edge() -> void:
	if _two_plan.is_empty():
		return
	# Labelled hostile transport, NOT a physically executed large-coordinate
	# route. Public canonical codecs cannot authenticate historical motion.
	var capture: Dictionary = _two_plan.capture_snapshot.duplicate(true)
	capture.slots[0].dash.path[2].position[0] = 3.0e38
	capture.slots[0].dash.path[3].position[0] = -3.0e38
	var sequence = Sequence.new()
	_expect(sequence.configure("cursor/finite-pose-transport", capture, AUTHORED, _two_plan.source_epoch, 1), "labelled finite-coordinate transport is canonical data without a physical route claim")
	var plan: Dictionary = sequence.snapshot_state()
	if plan.is_empty():
		return
	var native: Dictionary = sequence.state()
	var cursor = _armed(plan)
	var left: Dictionary = native.timeline.slots[0].route[2]
	var right: Dictionary = native.timeline.slots[0].route[3]
	var clock_s: float = 10.5 + (float(left.at_s) + float(right.at_s)) * 0.5
	var result: Dictionary = cursor.advance(clock_s)
	_expect(result.accepted and result.events.is_empty() and result.poses.size() == 1 and result.poses[0].position.is_finite() and absf(float(result.poses[0].position.x)) < 1.0e26, "opposite finite native coordinates cannot overflow interpolated data pose")
	var saved: Dictionary = _json(cursor.snapshot_state())
	var restored = Cursor.new()
	_expect(restored.restore_state(saved, plan, _two_plan.source_epoch, 1, clock_s) and restored.state().poses[0].position.is_finite(), "finite-coordinate JSON continuation preserves a finite data pose without execution")


func _record(count: int, wall: bool = false) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	_box(world, Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	if wall:
		_box(world, Vector3(1.5, 1, 0), Vector3(0.3, 2, 10))
	var player: CinderPlayer = Player.new()
	world.add_child(player)
	await _ticks(5, player)
	var capture = Capture.new()
	var epoch: String = "cursor/actual-two" if count == 2 else "cursor/actual-wall"
	paused = true
	await process_frame
	_expect(player.get_threat_response_state().stable and capture.arm(epoch, count, 0, player.get_world_action_clock()), "real capture arms at a stable paused actor boundary")
	paused = false
	var controls: Dictionary = {"attack": true, "second": false}
	player.world_action_executed.connect(func(record: Dictionary) -> void:
		capture.ingest(record, epoch)
		if record.kind == "dash" and controls.attack:
			player.slash(Vector3(0.4, 0, -0.9) if controls.second or wall else Vector3.FORWARD)
	)
	player.shells = 0 if count == 1 else player.max_shells
	player.request_dash(Vector3.RIGHT if wall else Vector3(0.6, 0, 0.8))
	await _ticks(22, player, capture)
	if count == 2:
		player.blast(Vector3.RIGHT)
	await _ticks(20, player, capture)
	if count == 2:
		controls.attack = false
		player.request_dash(Vector3.FORWARD) # Actual unpaired route, then superseded.
		await _ticks(26, player, capture)
		paused = true
		await process_frame
		_expect(player.equip_item("WEAPON-03"), "second route uses a different canonical legal static weapon")
		paused = false
		controls.attack = true
		controls.second = true
		player.shells = 0
		player.request_dash(Vector3.LEFT)
		await _ticks(42, player, capture)
	paused = true
	await process_frame
	capture.advance(player.get_world_action_clock())
	var snapshot: Dictionary = capture.snapshot_state()
	var sequence = Sequence.new()
	var okay: bool = sequence.configure("cursor/actual-%d" % count, snapshot, AUTHORED, epoch, 1)
	_expect(okay, "actual canonical capture produces a frozen sequence: " + sequence.last_error)
	if not okay:
		paused = false
		world.queue_free()
		await process_frame
		return {}
	var native: Dictionary = sequence.state()
	_expect(native.timeline.slots.size() == count and (not wall or native.capture_snapshot.slots[0].dash.collision_shortened), "fixture retains actual completed slots and collision-shortened travel when authored")
	return {"root": world, "player": player, "plan": sequence.snapshot_state(), "native": native}


func _armed(plan: Dictionary):
	var cursor = Cursor.new()
	_expect(cursor.configure(plan, plan.source_epoch, 1, 10.0) and cursor.arm(10.5, 11.0), "fixture binds and arms the exact immutable sequence at canonical lock")
	return cursor


func _ticks(count: int, player: CinderPlayer, capture = null) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame
		if capture != null:
			capture.advance(player.get_world_action_clock())


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


func _json(value: Dictionary) -> Dictionary:
	var parsed: Dictionary = ExactJson.parse(ExactJson.stringify(value))
	return parsed.value if parsed.get("accepted", false) and parsed.value is Dictionary else {}


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)


func _adjacent_float(value: float, step: int) -> float:
	# These labelled mutation fixtures use finite positive values only.
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + step)
	return bytes.decode_double(0)


func _dispose(fixture: Dictionary) -> void:
	paused = false
	fixture.root.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
