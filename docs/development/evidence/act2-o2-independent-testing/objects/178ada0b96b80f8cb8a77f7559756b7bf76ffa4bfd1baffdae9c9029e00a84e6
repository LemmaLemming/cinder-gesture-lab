extends SceneTree
## Snapshot transport and atomic rejection; no campaign fairness claim.

const World = preload("res://tests/fixtures/threat_world.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_warning_and_atomic_validation()
	await _test_active_and_cooldown()
	await _test_staged_and_fresh_bindings()
	await _test_callback_and_collision_guards()
	print("Threat snapshot smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_warning_and_atomic_validation() -> void:
	var arena: Dictionary = World.create(self)
	await physics_frame
	var scheduler = arena["scheduler"]
	var bindings: Dictionary = World.bindings(arena)
	_expect(scheduler.begin_encounter("standard", "snapshot-warning"), "snapshot fixture starts a fixed encounter")
	_expect(scheduler.request_attack(arena["source_a"], World.threat(), World.response(arena)).get("accepted", false), "snapshot fixture reserves a real proved exchange")
	_expect(scheduler.snapshot_state(bindings).is_empty(), "active-tree capture is rejected instead of mixing clock generations")
	await create_timer(0.2).timeout
	paused = true
	await process_frame
	var snapshot: Dictionary = scheduler.snapshot_state(bindings)
	_expect(not snapshot.is_empty() and snapshot["reservations"].size() == 1 and scheduler.reservations()[0]["state"] == "warning", "paused warning snapshot contains its committed reservation")
	if snapshot.is_empty():
		push_error(scheduler.last_snapshot_error)
		await _dispose(arena)
		return
	_expect(Codec.value_error(snapshot).is_empty() and snapshot["reservations"][0]["source_id"] == "scout-a" and snapshot["reservations"][0]["floors"][0]["floor_id"] == "main-floor", "transport contains finite JSON and stable authored IDs instead of object/RID references")
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	var events: Array[String] = []
	scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: events.append(reason))
	_expect(scheduler.snapshot_error(round_trip, bindings).is_empty() and scheduler.restore_state(round_trip, bindings), "JSON round-trip accepts integral schema/serial fields and exact saved phase deadlines")
	_expect(Codec.same_values(snapshot, scheduler.snapshot_state(bindings)) and events.is_empty(), "restore preserves profile, clock, geometry, serial, floors and cooldowns without callbacks")
	var copy: Dictionary = scheduler.snapshot_state(bindings)
	copy["reservations"][0]["geometry"]["radius"] = 999
	_expect(Codec.same_values(snapshot, scheduler.snapshot_state(bindings)), "returned snapshot is a defensive copy")
	var bad: Dictionary = snapshot.duplicate(true)
	bad["reservations"][0]["lock_from_s"] = bad["reservations"][0]["active_from_s"]
	_expect(_reject_unchanged(scheduler, bad, bindings), "bad deadline ordering rejects before any state commit")
	bad = snapshot.duplicate(true)
	bad["cooldowns"].clear()
	_expect(_reject_unchanged(scheduler, bad, bindings), "missing live source cooldown cannot refresh an otherwise old reservation")
	bad = snapshot.duplicate(true)
	bad["profile"]["raw_damage_multiplier"] = 0.5
	_expect(_reject_unchanged(scheduler, bad, bindings), "catalogue profile drift rejects instead of applying new multipliers to saved phases")
	bad = snapshot.duplicate(true)
	bad["reservations"][0]["source_id"] = "scout-a\n"
	_expect(_reject_unchanged(scheduler, bad, bindings), "newline owner identity cannot alias a stable binding")
	bad = snapshot.duplicate(true)
	bad["reservations"][0]["unknown"] = true
	_expect(_reject_unchanged(scheduler, bad, bindings), "unsupported reservation fields fail closed")
	bad = snapshot.duplicate(true)
	bad["serial"] = 0
	_expect(_reject_unchanged(scheduler, bad, bindings), "serial must cover all retained reservation IDs")
	_expect(events.is_empty(), "all rejected restores leave cancellation/event history untouched")
	await _dispose(arena)


func _test_active_and_cooldown() -> void:
	var arena: Dictionary = World.create(self)
	await physics_frame
	var scheduler = arena["scheduler"]
	var bindings: Dictionary = World.bindings(arena)
	scheduler.begin_encounter("standard", "snapshot-active")
	scheduler.request_attack(arena["source_a"], World.threat(), World.response(arena))
	await create_timer(0.7).timeout
	paused = true
	await process_frame
	var snapshot: Dictionary = scheduler.snapshot_state(bindings)
	_expect(not snapshot.is_empty() and scheduler.reservations()[0]["state"] == "active", "snapshot captures an active reservation after the warning/lock boundary")
	if not snapshot.is_empty():
		var before: float = scheduler.get_clock()
		await create_timer(0.05, true).timeout
		_expect(scheduler.restore_state(snapshot, bindings) and is_equal_approx(scheduler.get_clock(), before) and scheduler.reservations()[0]["state"] == "active", "paused active restore preserves remaining lifetime rather than rescheduling windup")
		scheduler.cancel(snapshot["reservations"][0]["id"])
		var cancelled: Dictionary = scheduler.snapshot_state(bindings)
		_expect(cancelled["reservations"].is_empty() and cancelled["cooldowns"].size() == 1, "cancelled geometry still snapshots its retained source cooldown")
		scheduler.end_encounter()
		_expect(scheduler.restore_state(cancelled, bindings), "retained cooldown restores independently of a live reservation")
		paused = false
		await physics_frame
		var denied: Dictionary = scheduler.request_attack(arena["source_a"], World.threat(), World.response(arena))
		_expect(not denied.get("accepted", false) and String(denied["reason"]).contains("cooldown"), "resuming a cancelled checkpoint does not grant a fresh attack interval")
	await _dispose(arena)


func _test_staged_and_fresh_bindings() -> void:
	var arena: Dictionary = World.create(self)
	await physics_frame
	var scheduler = arena["scheduler"]
	var bindings: Dictionary = World.bindings(arena)
	scheduler.begin_encounter("standard", "snapshot-staged")
	scheduler.request_attack(arena["source_a"], World.threat(), World.response(arena))
	paused = true
	await process_frame
	var snapshot: Dictionary = scheduler.snapshot_state(bindings)
	_expect(not snapshot.is_empty(), "staged restore fixture captures a coherent source position")
	if snapshot.is_empty():
		await _dispose(arena)
		return
	scheduler.end_encounter()
	(arena["source_a"] as Node3D).position.x = 1.0
	bindings["owner_positions"] = {"scout-a": Vector3.ZERO}
	_expect(scheduler.snapshot_error(snapshot, bindings).is_empty(), "staged enemy position supports full aggregate prevalidation before enemy mutation")
	_expect(not scheduler.restore_state(snapshot, bindings) and scheduler.reservations().is_empty() and scheduler.encounter_profile().is_empty(), "commit independently rejects staged-only positions until live enemies are restored")
	(arena["source_a"] as Node3D).position.x = 0.0
	_expect(scheduler.restore_state(snapshot, bindings), "validated matching live enemy position commits without phase reset")
	arena["root"].queue_free()
	await process_frame
	arena = World.create(self)
	await process_frame
	scheduler = arena["scheduler"]
	bindings = World.bindings(arena)
	_expect(scheduler.restore_state(snapshot, bindings), "fresh node instances with the same authored paths/IDs restore despite different instance IDs and RIDs")
	_expect(Codec.same_values(snapshot, scheduler.snapshot_state(bindings)), "cross-instance transport rebuilds weak owners/floor guards while preserving saved state")
	var missing: Dictionary = bindings.duplicate(true)
	missing["owners"].erase("scout-a")
	_expect(not scheduler.restore_state(snapshot, missing), "missing stable source mapping rejects instead of attaching to a different enemy")
	await _dispose(arena)


func _test_callback_and_collision_guards() -> void:
	var arena: Dictionary = World.create(self)
	await physics_frame
	var scheduler = arena["scheduler"]
	var bindings: Dictionary = World.bindings(arena)
	scheduler.begin_encounter("standard", "snapshot-guards")
	scheduler.request_attack(arena["source_a"], World.threat(), World.response(arena))
	paused = true
	await process_frame
	var snapshot: Dictionary = scheduler.snapshot_state(bindings)
	_expect(not snapshot.is_empty(), "collision guard fixture captures registered static scenery")
	if snapshot.is_empty():
		await _dispose(arena)
		return
	var callback_rejections: Array[bool] = []
	scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void:
		callback_rejections.append(scheduler.snapshot_state(bindings).is_empty())
		callback_rejections.append(not scheduler.restore_state(snapshot, bindings)))
	scheduler.cancel(snapshot["reservations"][0]["id"])
	_expect(callback_rejections == [true, true], "capture and restore reject paused cancellation callbacks until a deferred transaction barrier")
	_expect(scheduler.restore_state(snapshot, bindings), "deferred paused caller can restore after cancellation callback returns")
	(arena["wall"] as StaticBody3D).position.x += 0.25
	_expect(_reject_unchanged(scheduler, snapshot, bindings) and scheduler.last_snapshot_error.contains("fingerprint"), "changed real wall transform rejects even though every floor signature remains unchanged")
	(arena["wall"] as StaticBody3D).position.x -= 0.25
	var bad_floors: Dictionary = bindings.duplicate(true)
	bad_floors["floors"]["main-floor"]["safe_rect"] = Rect2(-9, -9, 18, 18)
	_expect(not scheduler.restore_state(snapshot, bad_floors), "authored supported-rectangle changes reject even inside the same solid box")
	(arena["wall"] as StaticBody3D).collision_layer = 0
	_expect(not scheduler.restore_state(snapshot, bindings), "collision-layer drift changes the actual blocker fingerprint")
	(arena["wall"] as StaticBody3D).collision_layer = 1
	var outside := StaticBody3D.new()
	outside.name = "OutsideBlocker"
	outside.collision_layer = 1
	var shape := CollisionShape3D.new()
	shape.name = "Solid"
	shape.shape = BoxShape3D.new()
	outside.add_child(shape)
	root.add_child(outside)
	_expect(scheduler.snapshot_state(bindings).is_empty(), "same-world scenery outside authored world_root cannot be omitted from the collision fingerprint")
	outside.queue_free()
	await process_frame
	var unnamed := StaticBody3D.new()
	unnamed.collision_layer = 1
	var unnamed_shape := CollisionShape3D.new()
	unnamed_shape.name = "Solid"
	unnamed_shape.shape = BoxShape3D.new()
	unnamed.add_child(unnamed_shape)
	arena["root"].add_child(unnamed)
	_expect(scheduler.snapshot_state(bindings).is_empty(), "unstable generated collider paths reject cross-process transport")
	await _dispose(arena)


func _reject_unchanged(scheduler: Variant, candidate: Dictionary, bindings: Dictionary) -> bool:
	var before: Dictionary = scheduler.snapshot_state(bindings)
	var rejected: bool = not scheduler.restore_state(candidate, bindings)
	var error: String = scheduler.last_snapshot_error
	var after: Dictionary = scheduler.snapshot_state(bindings)
	scheduler.last_snapshot_error = error
	return rejected and not before.is_empty() and Codec.same_values(before, after)


func _dispose(arena: Dictionary) -> void:
	arena["root"].queue_free()
	await process_frame
	paused = false


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
