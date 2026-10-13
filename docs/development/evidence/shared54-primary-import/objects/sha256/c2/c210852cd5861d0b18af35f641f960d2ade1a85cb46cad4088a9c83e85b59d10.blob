extends SceneTree
## Narrow native actor fixture: actual shared Game/Player/layout, four retained
## dormant capsules, one fresh activation, pure preview and exact paired restore.
## No main-level progression, gesture route, portrait or acceptance claim.

const MainScene = preload("res://scenes/main.tscn")
const ActorScript = preload("res://scripts/acts/act1/rush_selenite.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const LevelPath: String = "res://scenes/acts/act1/a1_l2_layout_greybox.tscn"
const ENCOUNTER_ID: String = "a1-l2-dormant-preview-fixture"
const IDS: Array[String] = ["solo", "rock", "open", "finale"]
const POSITIONS: Array[Vector3] = [Vector3(0, 0.005, 13), Vector3(-2.8, 0.005, 0), Vector3(2.8, 0.005, 0), Vector3(0, 0.005, -14)]

var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _world: Node3D
var _scheduler: CinderThreatScheduler
var _sources: Dictionary = {}
var _entitlements: Dictionary = {}
var _checks: int = 0
var _failures: int = 0
var _events: int = 0
var _finishing: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0, true).timeout.connect(func() -> void:
		if not _finishing:
			_expect(false, "bounded dormant/preview fixture finishes within 45 seconds")
			_finish())
	root.size = Vector2i(540, 1170)
	_game = MainScene.instantiate()
	_game.set("level_scene_path", LevelPath)
	root.add_child(_game)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_world = _game.get("world") as Node3D
	if not _expect(_level != null and _hero != null and _world != null, "real shared shell installs the committed layout and one actual Player"):
		_finish(); return
	_expect(_hero.global_position == _level.spawn_position() and _hero.global_position.z == 16.0, "actual layout Player starts at its authored spawn16")
	_expect(get_nodes_in_group("enemies").is_empty(), "layout has no automatic enemy before fixture composition")
	_scheduler = SchedulerScript.new()
	_scheduler.name = "DormantFixtureScheduler"
	_level.add_child(_scheduler)
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _events += 1)
	for index: int in range(IDS.size()):
		var actor: Act1RushSelenite = ActorScript.new()
		actor.name = "FixtureC30_%s" % IDS[index]
		actor.position = POSITIONS[index]
		if not _expect(actor.configure(IDS[index], ActorScript.DEFAULT_RAW_ROLE, ActorScript.DEFAULT_TIMING_FLOORS, ActorScript.DEFAULT_LUNGE, true), "configure immutable initially dormant %s" % IDS[index]):
			actor.free(); _finish(); return
		_level.add_child(actor)
		_sources[IDS[index]] = actor
		actor.activation_guard = Callable(self, "_activation_permitted")
		actor.state_changed.connect(func(_s: Dictionary) -> void: _events += 1)
		actor.defeated.connect(func(_id: String) -> void: _events += 1)
		actor.get_cue().state_changed.connect(func(_s: Dictionary) -> void: _events += 1)
		if not _expect(actor.bind(_scheduler, _hero), "bind retained same-world dormant %s without waking it" % IDS[index]):
			_finish(); return
	paused = true
	var first: Dictionary = _capture()
	if not _expect(not first.is_empty(), "all four pristine dormant actors capture with an empty scheduler"):
		_finish(); return
	_expect(_unit_error(first).is_empty(), "complete dormant native unit prevalidates purely")
	var before: String = Exact.stringify(first)
	for id: String in IDS:
		var actor := _sources[id] as Act1RushSelenite
		var collision := actor.get_node("BodyCollision") as CollisionShape3D
		_expect(actor.dormant and not actor.dead and actor.hp == 20.0 and not actor.visible and collision.disabled and actor.collision_layer == 0 and actor.collision_mask == 0 and not actor.is_in_group("enemies"), "dormant %s is retained but hidden, noncolliding and untargetable" % id)
		_expect(actor.get_art().visible and (actor.get_art().get_parent() as Node3D).visible and String(actor.get_art().call("binding_error")).is_empty(), "dormant %s hides only its root while local costume bindings remain valid" % id)
		_expect(not actor.take_damage(1.0, Vector3.ZERO).accepted and actor.cancel("unused_owner_cleanup"), "dormant %s rejects damage and cancellation creates no combat history" % id)
	_expect(Exact.stringify(_capture()) == before, "dormant damage/cancel checks preserve every actor and scheduler bit")
	_game.call("resume_lab")
	await _ticks(8)
	for index: int in range(IDS.size()):
		var actor := _sources[IDS[index]] as Act1RushSelenite
		_expect(actor.global_position == POSITIONS[index] and actor.velocity == Vector3.ZERO and actor.hp == 20.0, "real physics ticks do not move or injure dormant %s" % IDS[index])
	paused = true
	var initial: Dictionary = _capture()
	if not _expect(not initial.is_empty(), "settled actual Player and all dormant sources capture exactly"):
		_finish(); return
	var solo := _sources.solo as Act1RushSelenite
	_game.call("resume_lab")
	_expect(not _attempt_activate("solo"), "activation without successful fresh encounter rejects")
	if not _expect(_fresh_boundary("solo"), "actual public begin_encounter alone grants this fixture's solo entitlement"):
		_finish(); return
	_expect(not _attempt_activate("rock"), "fresh boundary does not entitle the unchosen rock source")
	_expect(_fresh_boundary("solo"), "new successful boundary grants the next bounded activation attempt")
	solo.activation_guard = Callable()
	_expect(not _attempt_activate("solo"), "initially dormant actor requires an actual parent guard")
	_expect(_fresh_boundary("solo"), "fresh boundary precedes the literal-boolean guard check")
	solo.activation_guard = Callable(self, "_integer_guard")
	_expect(not _attempt_activate("solo"), "truthy integer cannot impersonate literal parent boolean permission")
	solo.activation_guard = Callable(self, "_activation_permitted")
	var collision := solo.get_node("BodyCollision") as CollisionShape3D
	var capsule := collision.shape as CapsuleShape3D
	var radius: float = capsule.radius
	capsule.radius = radius + 0.01
	_expect(_fresh_boundary("solo"), "fresh boundary precedes native footprint rejection")
	_expect(not _attempt_activate("solo") and solo.dormant and solo.hp == 20.0, "unpaused activation rejects changed actual retained native footprint without enabling it")
	capsule.radius = radius
	if not _expect(_fresh_boundary("solo") and _attempt_activate("solo"), "fresh permitted unpaused activation reveals the original retained capsule once"):
		_finish(); return
	_expect(not solo.dormant and solo.visible and not collision.disabled and solo.is_in_group("enemies") and solo.hp == 20.0, "activation changes lifecycle only, preserving HP20 and physical identity")
	_expect(not _attempt_activate("solo") and solo.hp == 20.0, "repeat activation rejects without reset or free heal")
	var context: Dictionary = _context()
	var direction: Vector3 = Vector3.BACK
	var preview_before: Dictionary = _unit_between_calls()
	var event_count: int = _events
	solo.last_error = "retain-preview-actor-diagnostic"
	solo.last_snapshot_error = "retain-preview-snapshot-diagnostic"
	var preview: Dictionary = solo.preview_lunge(context, direction, _world)
	_expect(solo.last_error == "retain-preview-actor-diagnostic" and solo.last_snapshot_error == "retain-preview-snapshot-diagnostic" and _events == event_count, "pure actor preview leaves diagnostics/events untouched")
	if not _expect(preview.get("accepted", false), "actual native capsule and shared Player produce prospective measured endpoint/proof: " + String(preview.get("reason", ""))):
		_finish(); return
	_expect(Exact.stringify(_unit_between_calls()) == Exact.stringify(preview_before), "preview changes no actor HP/history/profile, Player, clock, lease or cooldown")
	_expect(preview.api_revision == "lunge-preview-1" and preview.plan.planned_endpoint == preview.candidate.opening_position and not preview.proof.uses_blast and not preview.proof.uses_invulnerability, "native preview exposes measured real endpoint and ordinary-primary response")
	var extra_context: Dictionary = context.duplicate()
	extra_context.world_root = _world
	_expect(not solo.preview_lunge(extra_context, direction, _world).accepted, "seven-key authored context cannot accept an extra world-root field")
	_expect(not solo.preview_lunge(context, direction, _level).accepted, "level-only root cannot impersonate containing world with sibling Player")
	var forged: Dictionary = preview.duplicate(true)
	forged.candidate.active_from_s += 0.001
	_expect(not solo.start(context, direction, _world, forged).accepted and solo.state().cycle == 0, "copied prospective deadline forgery rejects without a source cycle")
	var answer: Dictionary = solo.start(context, direction, _world, preview)
	if not _expect(answer.get("accepted", false), "unchanged synchronous native preview correspondence admits exactly one actual source: " + String(answer.get("reason", ""))):
		_finish(); return
	_expect(answer.reservation.opening_position == preview.candidate.opening_position and _native_same(answer.proof, preview.proof) and solo.state().cycle == 1, "admission retains the exact prospective endpoint and selected supported response")
	paused = true
	var warning: Dictionary = _capture()
	if not _expect(not warning.is_empty() and _unit_error(warning).is_empty(), "one real warning plus three dormant sources captures/prevalidates its exact aggregate"):
		_finish(); return
	_game.call("resume_lab")
	solo.cancel("same_tick_fixture_interruption")
	_expect(not _attempt_activate("rock"), "same-tick cancellation and retained cooldown never grant another actor's activation guard")
	var hurt: Dictionary = solo.take_damage(5.0, Vector3.ZERO)
	_expect(hurt.accepted and solo.hp == 15.0 and not _attempt_activate("solo") and solo.hp == 15.0, "real surviving damage and repeat activation retain injured HP15")
	_expect(not solo.start(context, direction, _world).accepted and solo.hp == 15.0, "repeat start during actual hurt rejects without healing or resetting history")
	solo.take_damage(20.0, Vector3.ZERO)
	await process_frame
	paused = true
	var defeated: Dictionary = _capture()
	if not _expect(not defeated.is_empty() and solo.dead and solo.hp == 0.0, "actual death removes the live target/cooldown while retaining the capsule for restore"):
		_finish(); return
	var frozen_dead: String = Exact.stringify(defeated)
	_expect(_unit_error(warning).is_empty() and Exact.stringify(_capture()) == frozen_dead, "earlier-live prevalidation against current dead capsule enables/moves/heals nothing")
	if not _expect(_restore(warning), "validated exact warning restores actual actors then scheduler then exchanges quietly"):
		_finish(); return
	_expect(Exact.stringify(_capture()) == Exact.stringify(warning) and solo.hp == 20.0 and not solo.dormant, "whole earlier-live restore reproduces original saved HP/clock/sample, not a new activation")
	_expect(_restore(initial) and Exact.stringify(_capture()) == Exact.stringify(initial), "earlier-live to genuine earlier-dormant restore clears only the validated aggregate history silently")
	_expect(_restore(defeated) and Exact.stringify(_capture()) == frozen_dead, "earlier-dormant to genuine saved-dead aggregate preserves exact HP0 and history")
	_expect(_restore(initial), "genuine saved-dormant restore is legal against retained dead actors")
	var malformed: Dictionary = initial.duplicate(true)
	malformed.sources.finale.hp = 19.0
	var unchanged: String = Exact.stringify(_capture())
	_expect(not _unit_error(malformed).is_empty() and not _restore(malformed) and Exact.stringify(_capture()) == unchanged, "malformed later dormant HP rejects the entire unit before any earlier actor mutation")
	malformed = initial.duplicate(true)
	malformed.sources.rock.dormant = false
	_expect(not _unit_error(malformed).is_empty() and Exact.stringify(_capture()) == unchanged, "fixture's unchosen retained route cannot invent activation in saved parent composition")
	malformed = initial.duplicate(true)
	malformed.sources.solo.erase("dormant")
	_expect(not _unit_error(malformed).is_empty(), "closed schema2 cannot silently default a missing dormant field")
	malformed = initial.duplicate(true)
	malformed.sources.solo.schema_version = 1
	_expect(not _unit_error(malformed).is_empty(), "schema1 transport is not silently reinterpreted as schema2")
	var old_shape: Shape3D = collision.shape
	collision.shape = old_shape.duplicate()
	_expect(not _unit_error(initial).is_empty(), "equivalent replacement resource cannot impersonate the retained actual capsule")
	collision.shape = old_shape
	_expect(_unit_error(initial).is_empty(), "repairing the original native resource restores pure validation")
	_game.call("resume_lab")
	if not _expect(_fresh_boundary("solo"), "fresh begin after exact dormant restore can grant this source anew in restored history"):
		_finish(); return
	_entitlements.clear()
	_expect(not _attempt_activate("solo") and solo.hp == 20.0 and solo.dormant, "cleared parent grant cannot activate or heal an actor at clock0")
	_finish()


func _fresh_boundary(source_id: String) -> bool:
	_entitlements.clear()
	if _scheduler.has_committed_exchange():
		return false
	_scheduler.end_encounter("fixture_new_fresh_boundary")
	if not _scheduler.begin_encounter("standard", ENCOUNTER_ID, 1):
		return false
	_entitlements[source_id] = true
	return true


func _attempt_activate(source_id: String) -> bool:
	var accepted: bool = (_sources[source_id] as Act1RushSelenite).activate()
	_entitlements.clear()
	return accepted


func _activation_permitted(source_id: String) -> bool:
	return _entitlements.get(source_id, false) == true


func _integer_guard(_source_id: String) -> int:
	return 1


func _context() -> Dictionary:
	var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			directions.append(Vector3(x, 0, z).normalized())
	return {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.18, "attack_input_margin_s": 0.08, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [_bindings().floors.floor]}


func _bindings() -> Dictionary:
	return {"world_root": _world, "owners": _sources.duplicate(), "floors": {"floor": {"collision": _level.get_node("Floor/CollisionShape3D"), "safe_rect": Rect2(-7, -24, 14, 44)}}}


func _capture() -> Dictionary:
	var paired: Dictionary = _scheduler.snapshot_state(_bindings())
	var player: Dictionary = _hero.snapshot_state()
	if paired.is_empty() or player.is_empty():
		return {}
	var sources: Dictionary = {}
	for id: String in IDS:
		var saved: Dictionary = (_sources[id] as Act1RushSelenite).snapshot_state(paired)
		if saved.is_empty():
			print("SOURCE SNAPSHOT DIAGNOSTIC ", id, ": ", (_sources[id] as Act1RushSelenite).last_snapshot_error)
			return {}
		sources[id] = saved
	return {"player": player, "scheduler": paired, "sources": sources}


func _unit_between_calls() -> Dictionary:
	var prior: bool = paused
	paused = true
	var result: Dictionary = _capture()
	paused = prior
	return result


func _unit_error(unit: Dictionary) -> String:
	if not Codec.keys_error(unit, ["player", "scheduler", "sources"]).is_empty() or not unit.player is Dictionary or not unit.scheduler is Dictionary or not unit.sources is Dictionary or not Codec.keys_error(unit.sources, IDS).is_empty():
		return "Closed native fixture unit required"
	var error: String = _hero.snapshot_error(unit.player)
	if not error.is_empty():
		return error
	var bindings: Dictionary = _bindings()
	bindings.owner_positions = {}
	bindings.owner_velocities = {}
	bindings.owner_collision_states = {}
	for index: int in range(IDS.size()):
		var id: String = IDS[index]
		if not unit.sources[id] is Dictionary:
			return "Retained source record required"
		var saved: Dictionary = unit.sources[id]
		var actor := _sources[id] as Act1RushSelenite
		error = actor.actor_snapshot_error(saved, unit.scheduler, unit.player)
		if not error.is_empty():
			return error
		# This narrow fixture activates only solo; it proves no main-level route gate.
		if id != "solo" and (not saved.dormant or saved.motion.position != Codec.vector3(POSITIONS[index])):
			return "Future/unchosen fixture source must retain its dormant authored placement"
		var staged: Dictionary = actor.staged_actor_bindings(saved)
		if staged.is_empty():
			return "Actual retained source staging failed"
		for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]:
			for staged_id: String in staged[key]:
				if bindings[key].has(staged_id):
					return "Duplicate staged source identity"
				bindings[key][staged_id] = staged[key][staged_id]
	bindings.hero_positions = {"hero": Codec.read_vector3(unit.player.motion.position)}
	return _scheduler.snapshot_error(unit.scheduler, bindings)


func _restore(unit: Dictionary) -> bool:
	if not _unit_error(unit).is_empty():
		return false
	var before_events: int = _events
	if not _hero.restore_state(unit.player):
		return false
	for id: String in IDS:
		if not (_sources[id] as Act1RushSelenite).restore_actor_state(unit.sources[id]):
			return false
	if not _scheduler.restore_state(unit.scheduler, _bindings()):
		return false
	for id: String in IDS:
		if not (_sources[id] as Act1RushSelenite).restore_exchange_state(unit.sources[id]):
			return false
	return _events == before_events


func _native_same(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right):
		return false
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: String in left:
			if not right.has(key) or not _native_same(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _native_same(left[index], right[index]): return false
		return true
	return left == right


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _expect(condition: bool, description: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(description)
	return condition


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	_entitlements.clear()
	paused = true
	if is_instance_valid(_game):
		_game.free()
	print("Act1 L2 dormant/preview fixture: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
