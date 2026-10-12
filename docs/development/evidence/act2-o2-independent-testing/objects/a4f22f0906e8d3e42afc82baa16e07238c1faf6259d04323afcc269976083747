extends SceneTree
## Actual first-Stalker fatal tick and fresh typed-unit reconstruction.
## MainScene preview uses the shared Hero, controls, camera and deferred pause.
## Natural contacts deplete HP; no resource/pose/clock/stat writes or fake kills.
## The retained living entry pair is an in-memory mechanical Retry fixture.
## No ProductionShell/SaveStore, GUI Retry, screen-anchor or full-route claim.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const FullPath: String = "res://scenes/acts/act3/a3_l2_living_forest.tscn"
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const FirstSource: String = "l2-threshold-stalker"
const FirstCheckpoint: String = "forest-threshold-entry"
const EntryWaitS: float = 3.0
const FatalWaitS: float = 90.0

class PostActorBarrier:
	extends Node
	signal completed
	var waiting: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func wait_next() -> void:
		waiting = true
		await completed
		waiting = false
	func _physics_process(_delta: float) -> void:
		if waiting:
			completed.emit()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting:
			_wake.call_deferred()
	func _wake() -> void:
		if waiting:
			completed.emit()

var _game: Node
var _hero: CinderPlayer
var _level: CinderLevel
var _scheduler: CinderThreatScheduler
var _sources: Dictionary = {}
var _barrier: PostActorBarrier
var _weak: Dictionary = {}
var _events: Dictionary = {}
var _contacts: Array[Dictionary] = []
var _checkpoints: Array[Dictionary] = []
var _arm_entry_pause: bool = false
var _entry_pause_accepted: bool = false
var _fatal_pause_accepted: bool = false
var _fatal_callback: Dictionary = {}
var _fatal_capture_only: bool = false
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not _expect(args.is_empty() or args == PackedStringArray(["--fatal-capture-only"]), "default full unit proof or the bounded fatal-capture selector"):
		await _finish()
		return
	_fatal_capture_only = not args.is_empty()
	if not await _open(false):
		await _finish()
		return
	var initial_hp: float = _hero.hp
	var initial_sources: Dictionary = _source_resources()
	if not _expect(_hero.is_on_floor() and initial_hp == _hero.max_hp and _hero.global_position.z > 38.0 and _scheduler.reservations().is_empty() and (_level.call("state") as Dictionary).entered.is_empty(), "actual grounded arrival has natural full HP and nine dormant sources before any entry"):
		await _finish()
		return
	_arm_entry_pause = true
	var approach_dashes: int = 0
	for _i: int in range(_limit(EntryWaitS)):
		if _entry_pause_accepted or _hero.dead:
			break
		var response: Dictionary = _hero.get_threat_response_state()
		if response.stable and float(response.dash_cooldown_left_s) == 0.0:
			if approach_dashes >= 3 or not _hero.request_dash(Vector3.FORWARD):
				_expect(false, "bounded public forward dash readiness must reach the real first spatial entry")
				await _finish()
				return
			approach_dashes += 1
		await _tick()
	await _settle_pause()
	if not _expect(approach_dashes > 0 and _entry_pause_accepted and paused and not _hero.dead and _hero.hp == initial_hp and _contacts.is_empty(), "bounded real forward dashes reach the first-entry observer's complete-tick living pause before contact"):
		_diagnostic("living entry pause")
		await _finish()
		return
	var living: Dictionary = _transport(_capture(), "living entry")
	if living.is_empty():
		await _finish()
		return
	if not _expect(_checkpoints.size() == 1 and _checkpoints[0] == {"id": FirstCheckpoint, "kind": "encounter"} and living.level.progress.checkpoint_id == FirstCheckpoint and living.level.progress.checkpoint_ids.size() == 1 and living.level.progress.checkpoint_ids.get(FirstCheckpoint) == "encounter" and living.level.local.route.entries.size() == 1 and living.level.local.route.entries[0].id == "vast-trunks" and Codec.read_vector3(living.level.local.route.entries[0].hero_position).z <= 38.0 and living.level.local.scheduler.reservations.is_empty(), "retained living pair binds the actual first floor crossing and incomplete checkpoint prefix"):
		await _finish()
		return
	if not _expect(float(living.hero.clocks.dash_left_s) > 0.0 and not living.hero.world_actions.pending_dash.is_empty() and _hero.get_committed_dash_state().active and _source_resources() == initial_sources, "entry capture retains the actual unfinished ordinary dash and all unhurt source resources"):
		await _finish()
		return
	if not _pure_pair(living, "actual living entry"):
		await _finish()
		return
	var protected_text: String = ExactJson.stringify(living)
	var living_presentation: Dictionary = _presentation()
	_game.call("resume_lab")
	var start: float = _scheduler.get_clock()
	var wall_start: int = Time.get_ticks_msec()
	var previous_hp: float = _hero.hp
	for _i: int in range(_limit(FatalWaitS)):
		if _hero.dead:
			break
		if _scheduler.get_clock() - start > FatalWaitS or Time.get_ticks_msec() - wall_start > int(FatalWaitS * 1500.0):
			break
		await _tick()
		if _hero.hp > previous_hp or not String((_level.call("state") as Dictionary).configuration_error).is_empty():
			_expect(false, "natural fatal observation must not heal or acquire a configuration error")
			_diagnostic("natural contact wait")
			await _finish()
			return
		previous_hp = _hero.hp
	await _settle_pause()
	if not _expect(_hero.dead and _hero.hp == 0.0 and paused and _fatal_pause_accepted and int(_events.get("hero_death", 0)) == 1, "genuine repeated first-Stalker contacts produce one fatal Hero and supported complete-tick pause"):
		_diagnostic("natural fatal not reached within finite budget")
		await _finish()
		return
	var accepted_damage: float = 0.0
	var accepted_contacts: int = 0
	for contact: Dictionary in _contacts:
		if contact.result.accepted:
			accepted_damage += float(contact.result.hp_damage)
			accepted_contacts += 1
	if not _expect(accepted_contacts > 1 and accepted_damage == initial_hp and not _fatal_callback.paused and _fatal_callback.request_accepted and _fatal_callback.clock_s == _scheduler.get_clock() and int(_events.get("fired_blast", 0)) == 0 and int(_events.get("fired_slash", 0)) == 0 and int(_events.get("source_death", 0)) == 0, "only real first-source contact depletes natural HP; death observer queues rather than interrupts the native tick"):
		_diagnostic("fatal contact history")
		await _finish()
		return
	var fatal: Dictionary = _transport(_capture(), "fatal complete tick")
	if fatal.is_empty() or not _fatal_scope(fatal, initial_sources):
		await _finish()
		return
	if not _expect(ExactJson.stringify(living) == protected_text and living.hero.resources.hp == initial_hp and not living.hero.resources.dead and living.level.progress.checkpoint_id == FirstCheckpoint, "fatal capture leaves the independently retained original living entry pair unchanged"):
		await _finish()
		return
	if not _pure_pair(fatal, "actual fatal unit") or not _rejections(fatal, living) or not await _frozen(fatal, "actual fatal"):
		await _finish()
		return
	var fatal_presentation: Dictionary = _presentation()
	if _fatal_capture_only:
		await _finish()
		return
	if not await _close() or not await _open(true):
		await _finish()
		return
	if not _expect(_scheduler.get_clock() == 0.0 and _hero.get_world_action_clock() == 0.0 and not _hero.dead and _scheduler.reservations().is_empty(), "fresh actual full layout is paused before any tick, contact or admission"):
		await _finish()
		return
	if not _restore(fatal, fatal_presentation, "fatal") or not await _frozen(fatal, "fresh fatal"):
		await _finish()
		return
	if not _expect(_hero.dead and _hero.hp == 0.0 and int(_events.get("hero_death", 0)) == 0 and _contacts.is_empty() and ExactJson.stringify(living) == protected_text, "fresh fatal reconstruction stays dead and emits no duplicate hurt/death while retaining the original living pair"):
		await _finish()
		return
	# A separate fresh world consumes the actual original saved living unit.
	# This fixture calls public Hero/level restoration, not campaign Retry.
	if not await _close() or not await _open(true):
		await _finish()
		return
	if not _restore(living, living_presentation, "retained living entry") or not await _frozen(living, "fresh retained living entry"):
		await _finish()
		return
	if not _expect(not _hero.dead and _hero.hp == float(living.hero.resources.hp) and _hero.shells == int(living.hero.resources.shells) and _hero.get_committed_dash_state().active and (_level.call("state") as Dictionary).cleared.is_empty() and int(_events.get("checkpoint", 0)) == 0, "mechanical Retry restores exactly the old living resources, unfinished dash and no source-clear/checkpoint event"):
		await _finish()
		return
	_game.call("resume_lab")
	await _tick()
	if not _expect(not paused and _scheduler.get_clock() > float(living.level.local.scheduler.clock_s) and _hero.get_world_action_clock() == _scheduler.get_clock() and _hero.hp == float(living.hero.resources.hp), "public resume advances the reconstructed living Hero, sun and scheduler on one genuine native tick"):
		await _finish()
		return
	for _i: int in range(_limit(0.5)):
		if not _hero.get_committed_dash_state().active:
			break
		await _tick()
	var history: Array[Dictionary] = _hero.get_world_action_records()
	if not _expect(not _hero.get_committed_dash_state().active and history.size() == living.hero.world_actions.history.size() + 1 and _dash_prefix_error(history.back(), living.hero.world_actions.pending_dash).is_empty() and _hero.hp == float(living.hero.resources.hp) and int(_events.get("fired_dash", 0)) == 0 and _contacts.is_empty(), "original unfinished dash completes once with its exact saved native path prefix and no replayed input or extra contact"):
		_diagnostic("retained movement continuation")
		await _finish()
		return
	await _finish()


func _open(quiet: bool) -> bool:
	paused = false
	_events.clear()
	_contacts.clear()
	_checkpoints.clear()
	_arm_entry_pause = false
	_entry_pause_accepted = false
	_fatal_pause_accepted = false
	_fatal_callback.clear()
	_game = MainScene.instantiate()
	_game.set("level_scene_path", FullPath)
	root.add_child(_game)
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	_sources = _level.get("sources") if _level != null else {}
	_barrier = PostActorBarrier.new()
	_game.add_child(_barrier)
	if not _expect(_hero != null and _level != null and _scheduler != null and _sources.size() == 9 and _level.scene_file_path == FullPath and _level.contract_error().is_empty() and String((_level.call("state") as Dictionary).configuration_error).is_empty(), "actual MainScene supplies the nine-source typed Living Forest" + (" at a fresh zero-tick boundary" if quiet else "")):
		return false
	var bindings: Dictionary = _level.call("scheduler_bindings")
	if not _expect(bindings.world_root == _game.get("world") and bindings.owners.size() == 9 and bindings.actors.hero == _hero and _hero.process_physics_priority < 20 and _scheduler.process_physics_priority < 20 and _level.process_physics_priority == 130 and _barrier.process_physics_priority == 1000, "real shared actor/scheduler and owned consumers precede the pausable post-actor observer"):
		return false
	_weak = {"game": weakref(_game), "world": weakref(_game.get("world")), "hero": weakref(_hero), "level": weakref(_level), "scheduler": weakref(_scheduler), "barrier": weakref(_barrier)}
	_hero.fired.connect(_on_fired)
	_hero.died.connect(_on_hero_death)
	_hero.world_action_executed.connect(func(_record: Dictionary) -> void: _event("world_action"))
	_level.checkpoint_requested.connect(_on_checkpoint)
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _event("completion"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _event("exit"))
	for id: String in _sources:
		var source: Node3D = _sources[id]
		_weak[id] = weakref(source)
		source.connect("died", func(_where: Vector3) -> void: _event("source_death"))
		source.connect("state_changed", func(_state: Dictionary) -> void: _event("source_state"))
		var cue: CinderThreatCue
		if source is CinderAct3SunboundStalker:
			cue = source.call("get_cue") as CinderThreatCue
			if id == FirstSource:
				source.connect("hit_resolved", _on_contact)
		else:
			var mechanism: CinderLaneMechanism = source.call("get_mechanism") as CinderLaneMechanism
			_weak[id + "/attack"] = weakref(mechanism)
			cue = mechanism.get_cue()
		_weak[id + "/cue"] = weakref(cue)
		cue.state_changed.connect(func(_state: Dictionary) -> void: _event("cue_state"))
	if quiet:
		_game.call("open_bench")
		await _settle_pause()
	else:
		for _i: int in range(12):
			await _tick()
	return true


func _on_checkpoint(_id: String, checkpoint: String, kind: String) -> void:
	_checkpoints.append({"id": checkpoint, "kind": kind})
	_event("checkpoint")
	if _arm_entry_pause and checkpoint == FirstCheckpoint:
		_arm_entry_pause = false
		_entry_pause_accepted = _game.call("request_pause_deferred")


func _on_hero_death() -> void:
	_event("hero_death")
	_fatal_callback = {"clock_s": _scheduler.get_clock(), "hero_clock_s": _hero.get_world_action_clock(), "paused": paused}
	_fatal_pause_accepted = _game.call("request_pause_deferred")
	_fatal_callback["request_accepted"] = _fatal_pause_accepted


func _on_contact(result: Dictionary) -> void:
	_contacts.append({"clock_s": _scheduler.get_clock(), "result": result.duplicate(true)})
	if result.accepted:
		print("ACTUAL FIRST STALKER CONTACT: cycle=%s hp_damage=%s heroHP=%s clock=%s" % [result.cycle, result.hp_damage, _hero.hp, _scheduler.get_clock()])


func _on_fired(kind: String) -> void:
	_event("fired_" + kind)


func _event(kind: String) -> void:
	_events[kind] = int(_events.get(kind, 0)) + 1


func _capture() -> Dictionary:
	var player: Dictionary = _hero.snapshot_state()
	var level: Dictionary = _level.snapshot_state()
	if not _expect(not player.is_empty() and not level.is_empty(), "paused public writers capture the complete Hero, sun, route and all typed native sources"):
		_diagnostic("capture: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error)
		return {}
	return {"hero": player, "level": level}


func _transport(pair: Dictionary, label: String) -> Dictionary:
	if pair.is_empty():
		return {}
	var encoded: String = ExactJson.stringify(pair)
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not _expect(not encoded.is_empty() and decoded.get("accepted", false) and _exact(pair, decoded.get("value")), "published exact JSON preserves every native scalar/type of " + label):
		print("EXACT TRANSPORT ERROR: ", decoded.get("error", ""))
		return {}
	return decoded.value


func _pure_pair(pair: Dictionary, label: String) -> bool:
	var before: Dictionary = _capture()
	var native: Dictionary = _presentation()
	var events: Dictionary = _events.duplicate(true)
	var error: String = _hero.snapshot_error(pair.hero)
	if error.is_empty():
		error = _level.snapshot_error_with_player(pair.level, pair.hero)
	var valid: bool = error.is_empty() and _exact(before, _capture()) and _same_native(native, _presentation()) and _events == events
	if not _expect(valid, "independently validated Hero then complete typed " + label + " proof is pure; " + error):
		_diagnostic("pure pairing")
	return valid


func _fatal_scope(pair: Dictionary, initial_sources: Dictionary) -> bool:
	var route: Dictionary = _level.call("state")
	var clock: float = float(pair.level.local.scheduler.clock_s)
	var source: Dictionary = pair.level.local.sources[FirstSource].actor
	if not _expect(pair.hero.resources.dead and float(pair.hero.resources.hp) == 0.0 and float(pair.hero.world_actions.clock_s) == clock and _fatal_callback.hero_clock_s == clock and route.entered == ["vast-trunks"] and route.deaths.is_empty() and not route.completed and route.exit_state == "clear" and _source_resources() == initial_sources and source.hit_consumed and source.previous.clock_s == clock and Codec.read_vector3(source.previous.hero_position) == _hero.global_position, "fatal native unit retains the exact current Hero sample, unchanged first-entry progress and all nine living sources"):
		return false
	var kinds: Dictionary = {"stalker": 0, "root": 0}
	for id: String in pair.level.local.sources:
		var typed: Dictionary = pair.level.local.sources[id]
		kinds[typed.kind] += 1
		if float(typed.actor.clock_s) != clock or typed.actor.dead:
			return _expect(false, "all living typed source clocks settle at the actual fatal Scheduler tick: " + id)
		if id != FirstSource:
			var cycle: int = int(typed.actor.cycle) if typed.kind == "stalker" else int(typed.actor.mechanism.cycle)
			if cycle != 0 or (_sources[id] as Node3D).is_physics_processing():
				return _expect(false, "unentered source remains genuinely dormant at fatal capture: " + id)
	return _expect(kinds == {"stalker": 4, "root": 5} and int(_events.get("completion", 0)) == 0 and int(_events.get("exit", 0)) == 0 and _checkpoints.size() == 1, "fatal full-parent aggregate includes all four Stalkers/five Roots without a later entry, reward or contact exit")


func _rejections(fatal: Dictionary, living: Dictionary) -> bool:
	var before: Dictionary = _capture()
	var events: Dictionary = _events.duplicate(true)
	var native: Dictionary = _presentation()
	var forged: Dictionary = fatal.level.duplicate(true)
	forged.local.sources["l2-promise-root"].kind = "stalker"
	var rejected: bool = not _level.snapshot_error_with_player(forged, fatal.hero).is_empty() and not _level.restore_state(forged)
	if not _expect(rejected and _exact(before, _capture()) and _events == events and _same_native(native, _presentation()), "fatal typed aggregate rejects a crossed Root/Stalker envelope atomically"):
		return false
	return _expect(_hero.snapshot_error(living.hero).is_empty() and not _level.snapshot_error_with_player(fatal.level, living.hero).is_empty() and _exact(before, _capture()) and _events == events and _same_native(native, _presentation()), "valid earlier living Hero cannot replace the same-tick fatal source sample in pure parent validation")


func _restore(pair: Dictionary, presentation: Dictionary, label: String) -> bool:
	if not _pure_pair(pair, "fresh " + label):
		return false
	var events: Dictionary = _events.duplicate(true)
	# One call stack; the owned level commits actors → Scheduler → mechanisms.
	var restored: bool = _hero.restore_state(pair.hero) and _level.restore_state(pair.level)
	if not _expect(restored and _events == events and _exact(pair, _capture()), "quiet public Hero then typed level restore retains exact " + label + " resources/clocks/callback custody; " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error):
		_diagnostic("restore " + label)
		return false
	return _expect(_same_native(presentation, _presentation()), "restored " + label + " preserves native required source/art/cue, sun and route-derived presentation")


func _frozen(pair: Dictionary, label: String) -> bool:
	var events: Dictionary = _events.duplicate(true)
	var presentation: Dictionary = _presentation()
	await process_frame
	await process_frame
	return _expect(paused and _exact(pair, _capture()) and _events == events and _same_native(presentation, _presentation()), label + " remains paused without extra contact, callback, clock or presentation change")


func _source_resources() -> Dictionary:
	var result: Dictionary = {}
	for id: String in _sources:
		var source: Node3D = _sources[id]
		result[id] = {"hp": source.get("hp"), "max_hp": source.get("max_hp"), "dead": source.get("dead")}
	return result


func _presentation() -> Dictionary:
	var result: Dictionary = {"objective": _level.objective_text, "sun_state": _level.get("sun_state"), "sun_elapsed_s": _level.get("sun_elapsed_s"), "sun_stage": _level.get("sun_stage"), "beat_index": _level.get("beat_index"), "sources": {}}
	for id: String in _sources:
		var source: Node3D = _sources[id]
		var cue: CinderThreatCue
		var art: Dictionary
		if source is CinderAct3SunboundStalker:
			cue = source.call("get_cue") as CinderThreatCue
			art = source.call("get_art_state")
		else:
			cue = (source.call("get_mechanism") as CinderLaneMechanism).get_cue()
			art = source.call("get_art").state()
		result.sources[id] = {"cue": cue.state(), "art": art, "position": source.global_position, "processing": source.is_physics_processing()}
	return result


func _dash_prefix_error(record: Dictionary, pending: Dictionary) -> String:
	if record.get("kind") != "dash" or record.started_at_s != pending.started_at_s or record.world_origin != Codec.read_vector3(pending.world_origin) or record.direction != Codec.read_vector3(pending.direction) or record.path.size() < pending.path.size():
		return "Completed action differs from original pending dash identity"
	for i: int in range(pending.path.size()):
		if record.path[i].time_s != pending.path[i].time_s or record.path[i].position != Codec.read_vector3(pending.path[i].position):
			return "Completed action lost an exact saved movement sample"
	return ""


func _tick() -> void:
	if paused:
		await process_frame
	else:
		await _barrier.wait_next()


func _settle_pause() -> void:
	await process_frame
	await process_frame


func _limit(seconds: float) -> int:
	return int(ceilf(seconds * float(Engine.physics_ticks_per_second))) + 4


func _exact(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)


func _same_native(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right):
		return false
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _same_native(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for i: int in range(left.size()):
			if not _same_native(left[i], right[i]): return false
		return true
	return left == right


func _expect(condition: bool, label: String) -> bool:
	_checks += 1
	if condition:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label)
	return condition


func _diagnostic(label: String) -> void:
	print("FATAL UNIT DIAGNOSTIC: ", label, " hero=", _hero.get_threat_response_state() if is_instance_valid(_hero) else {}, " route=", _level.call("state") if is_instance_valid(_level) else {}, " events=", _events, " contacts=", _contacts, " fatal_callback=", _fatal_callback)


func _close() -> bool:
	var clean: bool = true
	if is_instance_valid(_level):
		_level.exit_level()
	if is_instance_valid(_scheduler):
		clean = _expect(_scheduler.reservations().is_empty(), "public full-level exit releases every actual typed lease") and clean
	if is_instance_valid(_game):
		if _game.get_parent() == root:
			root.remove_child(_game)
		_game.queue_free()
	paused = false
	for _i: int in range(5):
		await process_frame
	var remaining: Array[String] = []
	for key: String in _weak:
		if (_weak[key] as WeakRef).get_ref() != null:
			remaining.append(key)
	for group: String in ["enemies", "practice_targets", "lab_weapons", "required_cues"]:
		if not get_nodes_in_group(group).is_empty():
			remaining.append("group:" + group)
	clean = _expect(remaining.is_empty(), "actual old Hero/world, all typed sources, mechanisms and cue groups are freed: " + str(remaining)) and clean
	_game = null
	_hero = null
	_level = null
	_scheduler = null
	_sources.clear()
	_barrier = null
	_weak.clear()
	return clean


func _finish() -> void:
	await _close()
	await create_timer(0.15, true, false, true).timeout
	print("Living Forest actual fatal unit: %d checks, %d failures; capture_only=%s. Direct full-parent mechanical restore; no ProductionShell/disk/GUI Retry/native-input/full-route claim." % [_checks, _failures, _fatal_capture_only])
	quit(0 if _failures == 0 else 1)
