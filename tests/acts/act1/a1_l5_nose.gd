extends SceneTree
## Bounded native B02 nose COMPONENT checks in the actual shared Main lab.
## TEST nose and stationary eye anchor are added to its real world/floor/Hero.
## No L5 scene, boss HP, earned route, campaign save/Continue, art inspection,
## gesture execution, fairness certificate, human balance or mobile credit.
## Raw defaults are provisional. Parent aggregate tests must cover the level.

const MainScene = preload("res://scenes/main.tscn")
const Nose = preload("res://scripts/acts/act1/living_moon_nose.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const SourceID: String = "moon-nose-native-component"
const EncounterID: String = "a1-l5-nose-component"
const WatchdogMs: int = 75000
var game: Node
var hero: CinderPlayer
var nose: Node3D
var eye: Node3D
var scheduler: CinderThreatScheduler
var region: Dictionary = {}
var checks: int = 0
var failures: int = 0
var events: int = 0
var hit_events: Array[Dictionary] = []
var phases: Array[String] = []
var required_points: Array = []
var started_ms: int = 0
var finishing: bool = false


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	game = MainScene.instantiate()
	root.add_child(game)
	hero = game.get("player") as CinderPlayer
	if not _expect(hero != null and game.get("world") is Node3D and game.get("camera") is Camera3D and game.get("hud") is GameHUD, "actual shared Main creates one real Hero/world/camera/HUD"):
		await _finish(); return
	game.call("resume_lab")
	if not await _wait(func() -> bool: return hero.get_threat_response_state().stable, "actual shared Hero settles on native floor", 4.0):
		await _finish(); return
	var floor: StaticBody3D = (game.get("world") as Node3D).find_child("Floor", true, false) as StaticBody3D
	var collision: CollisionShape3D = floor.get_node_or_null("Collision") as CollisionShape3D if floor != null else null
	if not _expect(collision != null and collision.shape is BoxShape3D, "actual authored lab supplies its native box floor"):
		await _finish(); return
	var size: Vector3 = (collision.shape as BoxShape3D).size
	region = {"collision": collision, "safe_rect": Rect2(Vector2(collision.global_position.x, collision.global_position.z) - Vector2(size.x, size.z) * 0.5, Vector2(size.x, size.z))}
	scheduler = Scheduler.new()
	scheduler.name = "NoseComponentScheduler"
	(game.get("world") as Node3D).add_child(scheduler)
	eye = Node3D.new()
	eye.name = "TESTStationaryEyeAnchor"
	(game.get("world") as Node3D).add_child(eye)
	eye.global_position = Vector3(hero.global_position.x - 0.6, 0.0, hero.global_position.z - 0.8)
	nose = Nose.new()
	nose.name = "ActualNoseSource"
	eye.add_child(nose)
	nose.global_position = Vector3(hero.global_position.x, 0.0, hero.global_position.z - 0.8)
	var cone: Dictionary = Geometry.cone(nose.global_position, Vector3.BACK, 2.0, 0.65, 0.1)
	if not _expect(nose.call("configure", SourceID, cone, eye.global_position), "component config uses actual nose origin and actual stationary eye anchor") or not _expect(scheduler.begin_encounter("standard", EncounterID, 1), "native shared Scheduler starts the disclosed component epoch") or not _expect(nose.call("bind", scheduler, hero, game.get("world"), eye), "nose retains actual shared Hero/Scheduler/world/eye/cue custody") or not _expect(nose.call("set_presentation_guard", _current_view_guard), "nose requires an actual current camera/footprint/opening guard"):
		await _finish(); return
	nose.connect("state_changed", func(state: Dictionary) -> void:
		events += 1
		if not phases.has(state.phase): phases.append(state.phase))
	nose.connect("hit_resolved", func(id: String, cycle: int, result: Dictionary) -> void:
		events += 1
		hit_events.append({"hero_id": id, "cycle": cycle, "result": result.duplicate(true)}))
	(nose.call("get_cue") as CinderThreatCue).state_changed.connect(func(_state: Dictionary) -> void: events += 1)
	var pure_before: Dictionary = _unit()
	nose.set("last_error", "prior-source-diagnostic")
	scheduler.last_error = "prior-scheduler-diagnostic"
	var preview: Dictionary = nose.call("preview_start", _context())
	if not _expect(preview.get("accepted", false), "genuine stationary nose preview has one ordinary escape/opening witness: " + String(preview.get("reason", ""))):
		await _finish(); return
	if not _expect(nose.get("last_error") == "prior-source-diagnostic" and scheduler.last_error == "prior-scheduler-diagnostic" and _same(pure_before, _unit()) and events == 0, "preview is pure: no phase/clock/lease/HP/callback/diagnostic mutation"):
		await _finish(); return
	var fake: Dictionary = preview.duplicate(true)
	fake.candidate.geometry["direction"] = Vector3.RIGHT
	var denied: Dictionary = nose.call("start", _context(), null, null, fake)
	if not _expect(not denied.get("accepted", false) and not scheduler.has_committed_exchange() and nose.call("state").cycle == 0, "changed copied cone cannot pass Scheduler's exact fourth-argument admission"):
		await _finish(); return
	var fresh_preview: Dictionary = nose.call("preview_start", _context())
	required_points = _framing_points(fresh_preview.candidate.geometry, fresh_preview.proof.landing, fresh_preview.candidate.opening_position)
	var admitted: Dictionary = nose.call("start", _context(), null, null, fresh_preview)
	if not _expect(admitted.get("accepted", false) and nose.call("state").status == "running", "unchanged native cone proof admits and required current view is usable: " + String(admitted.get("reason", ""))):
		await _finish(); return
	var immutable_shape: Dictionary = admitted.reservation.geometry.duplicate(true)
	var before_hp: float = hero.hp
	if not _expect(admitted.reservation.source_instance_id == nose.get_instance_id() and admitted.reservation.source_position == nose.global_position and admitted.reservation.opening_position == eye.global_position and admitted.reservation.geometry.direction == Vector3.BACK and not admitted.proof.uses_blast and not admitted.proof.uses_invulnerability, "actual nose source owns the fixed cone and ordinary-primary eye opening") or not await _paused_pair("warning"):
		await _finish(); return
	if not await _wait(func() -> bool: return nose.call("state").phase == "lock", "native shared-clock locked cone", 4.0) or not _expect(nose.call("state").geometry == immutable_shape and hero.hp == before_hp and hit_events.is_empty(), "warning/lock hold fixed world geometry and deal no premature damage"):
		await _finish(); return
	if not await _wait(func() -> bool: return hit_events.size() == 1, "actual stationary Hero path receives one active cone opportunity", 4.0):
		await _finish(); return
	if not _expect(hero.hp < before_hp and hit_events[0].hero_id == "hero" and hit_events[0].cycle == 1 and hit_events[0].result.opportunity_consumed and hit_events[0].result.accepted and nose.call("state").hit_ids == ["hero"], "native Player damage is once per genuine cone cycle, with no boss HP receiver on nose") or not await _paused_pair("active-hit"):
		await _finish(); return
	if not await _wait(func() -> bool: return nose.call("state").phase == "recovery", "native recovery", 4.0) or not _expect(nose.call("state").geometry == immutable_shape and hit_events.size() == 1 and phases.has("warning") and phases.has("lock") and phases.has("active"), "full warning/lock/active/recovery grammar preserves direction and one-hit dedupe") or not await _paused_pair("recovery"):
		await _finish(); return
	if not await _wait(func() -> bool: return nose.call("state").status == "complete", "original recovery expires normally", 5.0) or not _expect(not scheduler.has_committed_exchange() and nose.call("get_cue").state().phase == "clear" and hit_events.size() == 1, "normal expiry retires danger/cue without a new attack or repeated damage"):
		await _finish(); return
	if not await _wait(func() -> bool: return hero.get_threat_response_state().stable and scheduler.source_control_state(nose).cooldown == null, "actual source readiness after recovery", 4.0):
		await _finish(); return
	var next_preview: Dictionary = nose.call("preview_start", _context())
	if not _expect(next_preview.get("accepted", false), "next native source cycle is eligible only after original cooldown"):
		await _finish(); return
	required_points = _framing_points(next_preview.candidate.geometry, next_preview.proof.landing, next_preview.candidate.opening_position)
	var next_answer: Dictionary = nose.call("start", _context(), null, null, next_preview)
	if not _expect(next_answer.get("accepted", false), "second real cone cycle starts with new serial and native deadlines"):
		await _finish(); return
	(nose.call("get_cue") as CinderThreatCue).hide()
	if not await _wait(func() -> bool: return nose.call("state").status == "cancelled", "actual required cue loss cancels cone", 2.0) or not _expect(scheduler.source_control_state(nose).reservations.is_empty() and scheduler.source_control_state(nose).cooldown != null and scheduler.source_control_state(nose).cooldown.ready_s == next_answer.reservation.cooldown_until_s and hit_events.size() == 1, "cue loss removes lease, preserves exact original cooldown, and deals no hidden damage"):
		await _finish(); return
	await _finish()


func _context() -> Dictionary:
	return {"encounter_id": EncounterID, "world_revision": 1, "recognition_s": 0.2, "attack_input_margin_s": 0.05, "escape_directions": [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK], "return_directions": [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK], "floor_regions": [region]}


func _bindings() -> Dictionary:
	return {"world_root": game.get("world"), "owners": {SourceID: nose}, "floors": {"actual-lab-floor": region}, "actors": {"hero": hero}}


func _unit() -> Dictionary:
	var was_paused: bool = paused
	paused = true
	var bindings: Dictionary = _bindings()
	var packet: Dictionary = {"player": hero.snapshot_state(), "scheduler": scheduler.snapshot_state(bindings), "nose": nose.call("snapshot_state", bindings)}
	paused = was_paused
	return packet


func _paused_pair(label: String) -> bool:
	paused = true # TEST component barrier; this is not a campaign durable save.
	await process_frame
	var bindings: Dictionary = _bindings()
	var packet: Dictionary = _unit()
	if not _expect(not packet.player.is_empty() and not packet.scheduler.is_empty() and not packet.nose.is_empty(), label + " captures a closed actual paused Player/Scheduler/nose unit: " + String(nose.get("last_snapshot_error"))): return false
	var wire: String = Exact.stringify(packet)
	var count: int = events
	await create_timer(0.04, true).timeout
	if not _expect(wire == Exact.stringify(_unit()) and events == count, label + " paused native clock/phase/HP/geometry/hit history freezes exactly"): return false
	var changed: Dictionary = packet.nose.duplicate(true)
	changed.exchange.geometry["direction"] = Codec.vector3(Vector3.RIGHT)
	if not _expect(not String(nose.call("snapshot_error", changed, bindings, packet.scheduler)).is_empty() and events == count and wire == Exact.stringify(_unit()), label + " malformed cone rejects purely without refreshing damage/timers"): return false
	if not _expect(nose.call("snapshot_error", packet.nose, bindings, packet.scheduler) == "", label + " original paired snapshot prevalidates") or not _expect(hero.restore_state(packet.player) and scheduler.restore_state(packet.scheduler, bindings) and nose.call("restore_state", packet.nose, bindings), label + " same-unit quiet restoration applies actual Player then Scheduler then nose") or not _expect(wire == Exact.stringify(_unit()) and events == count, label + " quiet restore preserves exact IDs/clock/resources/dedupes and emits nothing"): return false
	game.call("resume_lab")
	return _expect(not paused, label + " resumes through the existing shared Main API")


func _current_view_guard(id: String, current: Dictionary) -> bool:
	if id != SourceID or not is_instance_valid(game) or not is_instance_valid(nose) or not is_instance_valid(eye) or required_points.is_empty() or current.source_id != SourceID or current.geometry.origin != nose.global_position or current.opening_position != eye.global_position:
		return false
	return game.call("camera_framing_error", required_points) == ""


func _framing_points(shape: Dictionary, landing: Vector3, opening: Vector3) -> Array:
	## Conservative bounding square contains the entire real cone/origin disk.
	## Actual camera containment is checked each boundary; no plan stands in.
	var points: Array = [shape.origin + Vector3.UP, opening, opening + Vector3.UP, landing, landing + Vector3.UP * 1.5]
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			points.append(shape.origin + Vector3(sx * float(shape.reach), 0.0, sz * float(shape.reach)))
	return points


func _same(left: Dictionary, right: Dictionary) -> bool:
	return Exact.stringify(left) == Exact.stringify(right)


func _wait(condition: Callable, message: String, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline and not finishing:
		if condition.call(): return _expect(true, message)
		await process_frame
	return _expect(false, message)


func _expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("L5 nose component: " + message)
	return ok


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WatchdogMs:
		_expect(false, "bounded native component watchdog expired")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true
	paused = true
	var refs: Array[WeakRef] = []
	for node: Node in [nose, eye, scheduler, hero, game]:
		if is_instance_valid(node): refs.append(weakref(node))
	var cue: CinderThreatCue = nose.call("get_cue") as CinderThreatCue if is_instance_valid(nose) else null
	if cue != null: refs.append(weakref(cue))
	if is_instance_valid(nose):
		nose.queue_free()
		await process_frame
		await process_frame
		if is_instance_valid(scheduler):
			var disposed: Dictionary = scheduler.snapshot_state({"world_root": game.get("world"), "owners": {}, "floors": {"actual-lab-floor": region}, "actors": {"hero": hero}})
			_expect(not disposed.is_empty() and disposed.reservations.is_empty() and disposed.cooldowns.is_empty(), "normal source disposal releases lease/cooldown without foreign process intervention")
	if is_instance_valid(game): game.queue_free()
	paused = false
	await process_frame
	await process_frame
	_expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "normal Main/world/Hero/source/cue disposal releases all retained native nodes")
	print("L5 nose native component: %d checks, %d failures; no full-level/gesture/campaign-save/art claim" % [checks, failures])
	quit(0 if failures == 0 else 1)
