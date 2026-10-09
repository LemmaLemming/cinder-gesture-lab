extends SceneTree
## TEST ONLY production C52 managed lifecycle. Actual Main, public input,
## ordinary primary and the unchanged native 36HP/porcelain owner. No production
## Shell, whole Mirror Sea, candidate-camera, OS-gesture or human acceptance.

const MainScene = preload("res://scenes/main.tscn")
const ROOM: String = "res://tests/acts/act3/mirror_echo_lifecycle_fixture.tscn"
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const TICK_EPSILON: float = 0.000001

class Barrier extends Node:
	signal observed
	var waiting: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		if waiting:
			waiting = false
			observed.emit()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting:
			_wake.call_deferred()
	func _wake() -> void:
		if waiting:
			waiting = false
			observed.emit()

var _game: Node
var _hero: CinderPlayer
var _level: CinderLevel
var _source: Node3D
var _scheduler: CinderThreatScheduler
var _barrier: Barrier
var _checks: int = 0
var _failures: int = 0
var _events: Array[String] = []
var _kit: Dictionary = {}
var _hero_hp: float = 0.0
var _knot: Transform3D
var _weak: bool = false
var _moving_seen: bool = false
var _quiet_probe_seen: bool = false
var _phases: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_weak = "--weak-primary" in OS.get_cmdline_user_args()
	if _expect(not _equal(1, 1.0) and not _equal(Vector3.ZERO, [0.0, 0.0, 0.0]), "native equality keeps scalar/vector tags distinct"):
		if await _two_cycles():
			await _close()
			if not _weak:
				await _post_complete_death()
	await _close()
	print("Owned production Echo lifecycle: %d checks; failures: %d. Managed native source only; no full-level/Shell/presentation-gate acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _open(fresh: bool = false) -> bool:
	paused = true
	_game = MainScene.instantiate()
	if not _weak or fresh:
		_game.set("level_scene_path", ROOM)
	root.add_child(_game)
	_game.call("open_bench")
	if _weak and not fresh:
		var lab: CinderPlayer = _game.get("player") as CinderPlayer
		if not _expect(lab != null and _game.call("is_lab_level") and get_nodes_in_group("enemies").is_empty(), "actual enemy-free lab provides legal kit boundary"):
			return false
		for id: String in ["CLOTH-J1", "CLOTH-P2", "CLOTH-S2", "WEAPON-04"]:
			if not _expect(lab.equip_item(id), "legal carried weak/long/slow kit selects " + id):
				return false
		if not _expect(_game.call("load_level_scene", ROOM), "public paused transition carries the genuine legal kit"):
			return false
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	_source = _level.get("echo") as Node3D if _level != null else null
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	_barrier = Barrier.new()
	_game.add_child(_barrier)
	_events.clear()
	_phases.clear()
	if not _expect(_hero != null and _level != null and _source != null and _scheduler != null and paused and _level.scene_file_path == ROOM and String(_level.get("last_configuration_error")).is_empty(), "actual Main installs the separate test-only native court", String(_level.get("last_configuration_error")) if _level != null else "missing level"):
		return false
	if not _expect(_source.has_method("source_cycles_managed") and not _source.call("source_cycles_managed") and _source.call("source_phase") == "idle" and float(_source.get("max_hp")) == 36.0 and float(_source.get("hp")) == 36.0 and (_source.call("get_enemy_apparition") as Node3D).get_child_count() == 16 and _scheduler.get_clock() == 0.0 and _scheduler.reservations().is_empty(), "fresh actual source is untracked API1/HP36/sixteen-mesh with no admission or history"):
		return false
	_source.connect("event_dispatched", func(_event: Dictionary, receipt: Dictionary) -> void:
		_events.append("slash")
		if receipt.contact:
			_events.append("contact")
	)
	_source.connect("source_hit_resolved", func(_hit: Dictionary) -> void: _events.append("hit"))
	_source.connect("source_defeated", func(_hit: Dictionary) -> void: _events.append("defeat"))
	_source.connect("died", func() -> void: _events.append("died"))
	_source.connect("state_changed", func(_state: Dictionary) -> void: _events.append("state"))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _events.append("invalidated"))
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_hero.world_action_executed.connect(func(_record: Dictionary) -> void: _events.append("action"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _events.append("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _events.append("checkpoint"))
	if not fresh:
		# Disclosed initial native resource seed, before opt-in/admission/ticks.
		var seed: Dictionary = _hero.snapshot_state()
		seed.resources.shells = 0
		seed.clocks.reload_s = 0.0
		if not _expect(_hero.restore_state(seed) and _level.call("enable_cycles"), "public initial zero-ammo seed and real opt-in earn only cycle_ready", String(_source.get("last_error"))):
			return false
		_hero_hp = _hero.hp
		_kit = _hero.equipment.snapshot()
		_knot = _source.global_transform
	return true


func _two_cycles() -> bool:
	if not _open():
		return false
	var ready: Dictionary = _pair()
	if not _expect(_valid_pair(ready) and ready.level.local.playback.status == "cycle_ready" and ready.level.local.playback.schema_version == 1 and ready.level.local.playback.lifecycle.terminal_receipts.is_empty() and not ready.level.local.playback.has("exchange") and _hero.get_world_action_records().is_empty(), "initial ready snapshot has no invented exchange/Cursor/event/hit history"):
		return false
	if not await _fresh_restore(ready):
		return false
	var retained: Dictionary = _resources()
	var expected_hits: int = int(ceil(36.0 / float(_hero.equipment.resolved_stats().primary_damage)))
	if not _expect(expected_hits >= 2 and expected_hits <= 4, "genuine carried primary damage determines bounded required generations"):
		return false
	_game.call("resume_lab")
	for generation: int in range(1, expected_hits + 1):
		if not await _admit_and_lock():
			return false
		var proof: Dictionary = _level.call("state").proof
		if not await _follow(proof, generation) or not _hit():
			return false
		if not _expect(_equal(retained, _resources()) and _source.call("get_authored_cycle_generation") == generation and int(_source.get("source_hits")) == generation and float(_source.get("hp")) == maxf(0.0, 36.0 - generation * float(_hero.equipment.resolved_stats().primary_damage)), "same actual owner retains native resources and cumulative real primary HP at generation%d" % generation):
			return false
		if generation < expected_hits:
			if not await _await_phase("complete"):
				return false
			var terminal: Dictionary = _source.call("get_authored_cycle_terminal_receipt")
			var before: Dictionary = _observation()
			if not _expect(not terminal.is_empty() and not _level.call("prepare_next_cycle") and _equal(before, _observation()), "pre-expiry next preparation refuses without native HP/resources/history mutation"):
				return false
			if not await _until(float(terminal.exchange.cooldown_until_s) + 1.0 / Engine.physics_ticks_per_second):
				return false
			for _i: int in range(12):
				if not await _tick():
					return false
			if not _expect(_equal(terminal, _source.call("get_authored_cycle_terminal_receipt")) and _level.call("prepare_next_cycle") and _equal(retained, _resources()) and _source.call("source_phase") == "cycle_ready", "expired original cooldown prepares only the next generation on the surviving native owner"):
				return false
			if not await _pause():
				return false
			var next_ready: Dictionary = _pair()
			if not _expect(_valid_pair(next_ready) and next_ready.level.local.playback.status == "cycle_ready" and next_ready.level.local.playback.lifecycle.terminal_receipts.size() == generation and next_ready.level.local.source.hit_receipts.size() == generation, "next ready capture preserves predecessor terminal and complete real hit chain") or not _atomic_negatives(next_ready):
				return false
			_game.call("resume_lab")
	if not _expect(bool(_source.get("dead")) and _source.call("state").status == "cancelled" and _events.count("slash") == expected_hits and _events.count("hit") == expected_hits and _events.count("defeat") == 1 and _events.count("died") == 1 and not _source.is_in_group("enemies") and not _events.has("contact") and not _events.has("fired_blast") and _hero.hp == _hero_hp and not _events.has("completion") and not _events.has("checkpoint") and _moving_seen, "real generation route kills once in recovery with full Hero HP/no blast/history replay"):
		return false
	var cancelled: Dictionary = _source.call("get_authored_cycle_terminal_receipt")
	if not await _until(float(cancelled.exchange.cooldown_until_s) + 2.0 / Engine.physics_ticks_per_second) or not await _pause():
		return false
	var late: Dictionary = _pair()
	if not _expect(_valid_pair(late) and late.level.local.source.clock_s > late.level.local.source.defeated_at_s and late.level.local.playback.cancelled_at_s == late.level.local.source.defeated_at_s and _equal(cancelled, late.level.local.playback.lifecycle.terminal_receipts[-1]), "late dead capture retains original cancellation while actual outer clocks advance") or not _atomic_negatives(late):
		return false
	if not await _fresh_restore(late):
		return false
	var predecessor: Dictionary = _source.call("get_authored_cycle_terminal_receipt")
	if not _expect(_level.call("add_ready_peer"), "second actual fixed-recipe owner registers ready on the same Hero/root/full floor domain"):
		return false
	var mixed: Dictionary = _pair()
	if not _expect(_valid_pair(mixed) and mixed.level.local.peers.size() == 1 and mixed.level.local.scheduler.authored_source_cycles.sources.size() == 2 and mixed.level.local.peers[0].playback.status == "cycle_ready" and mixed.level.local.peers[0].playback.lifecycle.terminal_receipts.is_empty() and mixed.level.local.peers[0].source.hp == 36.0 and mixed.level.local.peers[0].source.hit_receipts.is_empty() and _equal(predecessor, _source.call("get_authored_cycle_terminal_receipt")), "whole capture contains truthful dead history plus a genuine ready peer with no invented exchange/hits") or not await _fresh_restore(mixed):
		return false
	var history: Dictionary = _source.call("get_authored_cycle_terminal_receipt")
	var action_count: int = _hero.get_world_action_records().size()
	_game.call("resume_lab")
	for _i: int in range(12):
		if not await _tick():
			return false
	return _expect(_events.is_empty() and _hero.get_world_action_records().size() == action_count and _equal(history, _source.call("get_authored_cycle_terminal_receipt")) and bool(_source.get("dead")) and not _level.call("prepare_next_cycle"), "fresh late-dead continuation stays inert and cannot grant another cycle")


func _post_complete_death() -> bool:
	if not _open():
		return false
	_game.call("resume_lab")
	if not await _admit_and_lock() or not await _follow(_level.call("state").proof, 1) or not _hit() or not await _await_phase("complete"):
		return false
	var terminal: Dictionary = _source.call("get_authored_cycle_terminal_receipt")
	if not await _until(float(terminal.exchange.cooldown_until_s) + 1.0 / Engine.physics_ticks_per_second) or not _hit() or not await _pause():
		return false
	var pair: Dictionary = _pair()
	if not _expect(_valid_pair(pair) and bool(_source.get("dead")) and pair.level.local.playback.status == "complete" and pair.level.local.playback.cancellation.is_empty() and pair.level.local.playback.cancelled_at_s == null and pair.level.local.source.hit_receipts[-1].phase == "complete" and _equal(terminal, pair.level.local.playback.lifecycle.terminal_receipts[-1]), "genuine late completed-knot primary preserves original completion without manufacturing cancellation"):
		return false
	return await _fresh_restore(pair)


func _admit_and_lock() -> bool:
	for _i: int in range(180):
		if _level.call("admit_cycle"):
			break
		if not await _tick():
			return false
	if not _expect(bool(_level.call("state").admitted), "fresh actual witness/native view admits a genuine managed exchange", str(_level.call("state"))):
		return false
	for _i: int in range(300):
		if bool(_level.call("state").locked):
			break
		if not await _tick():
			return false
	var state: Dictionary = _level.call("state")
	return _expect(state.locked and state.lease.adapter.locked and state.proof.get("accepted", false) and not state.proof.uses_blast and not state.proof.uses_invulnerability, "due native commit keeps a complete ordinary escape/return witness", str(state))


func _follow(proof: Dictionary, generation: int) -> bool:
	var tested: bool = false
	for segment: Dictionary in proof.path:
		if segment.kind not in ["first_escape_dash", "tether_positioning_dash"]:
			continue
		if not await _until(float(segment.start_s)):
			return false
		var previous: int = _hero.get_world_action_records().size()
		var error: String = _swipe((segment.to - segment.from).normalized())
		if not _expect(error.is_empty() and _hero.get_world_action_records().size() == previous + 1 and _hero.get_world_action_records().back().kind == "dash", "actual final-release swipe starts " + String(segment.kind), error):
			return false
		if generation == 2 and not tested:
			tested = true
			if not await _tick() or not await _pause():
				return false
			var moving: Dictionary = _pair()
			if not _expect(_valid_pair(moving) and float(_hero.get_threat_response_state().motion.dash_left_s) > 0.0 and moving.level.local.playback.status == "running" and moving.level.local.source.generation == 2, "genuine unfinished generation2 dash captures complete current native pair") or not _atomic_negatives(moving):
				return false
			var events: Array[String] = _events.duplicate()
			if not _expect(_hero.restore_state(moving.hero) and _level.restore_state(moving.level) and _equal(events, _events) and _equal(moving, _pair()), "same current-generation moving pair restores quietly without duplicate actions/hits", _level.last_snapshot_error):
				return false
			_moving_seen = true
			_game.call("resume_lab")
		for _i: int in range(80):
			if float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0:
				break
			if not await _tick():
				return false
		if not _expect(float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0 and _hero.global_position.distance_to(segment.to) < 0.005 and _hero.is_on_floor(), "native dash finishes at the actual proved floor landing"):
			return false
	if not await _until(float(proof.primary_time_s)):
		return false
	return _expect(_source.call("source_phase") == "recovery" and _hero.global_position.distance_to(proof.attack_position) < 0.005, "actual returned Hero reaches the ordinary recovery opening")


func _hit() -> bool:
	var before: float = float(_source.get("hp"))
	var previous: int = _hero.get_world_action_records().size()
	var error: String = _tap((_source.global_position - _hero.global_position).normalized())
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return _expect(error.is_empty() and records.size() == previous + 1 and records.back().kind == "primary" and records.back().hits == 1 and float(_source.get("hp")) == maxf(0.0, before - float(_hero.equipment.resolved_stats().primary_damage)), "real first-tap primary commits one production source HP transaction", error)


func _fresh_restore(pair: Dictionary) -> bool:
	var read: Dictionary = Exact.parse(Exact.stringify(pair))
	if not _expect(read.get("accepted", false) and _equal(pair, read.value), "format2 transport preserves the complete exact native fixture pair"):
		return false
	await _close()
	if not _open(true):
		return false
	var error: String = _level.call("construct_saved_recipients", pair.level.local, pair.hero)
	if not _expect(error.is_empty(), "fresh constructor builds only explicitly saved immutable native recipients", error):
		return false
	var before: Dictionary = _observation()
	error = _level.call("prevalidate_saved_unit", pair.level.local, pair.hero)
	if not _expect(error.is_empty() and _equal(before, _observation()), "fresh native Hero/source/journal preflight is pure before immutable preparation", error):
		return false
	error = _level.call("prepare_saved_unit", pair.level.local, pair.hero)
	var recipe: Dictionary = _source.call("get_authored_cycle_restore_recipe")
	if not _expect(error.is_empty() and not recipe.is_empty() and _source.call("get_authored_cycle_terminal_receipt").is_empty() and float(_source.get("hp")) == 36.0 and int(_source.get("source_hits")) == 0 and _scheduler.get_clock() == 0.0 and _hero.get_world_action_records().is_empty(), "saved-generation construction recipe does not earn HP/clock/hit/terminal history", error):
		return false
	before = _observation()
	error = _hero.snapshot_error(pair.hero)
	if error.is_empty():
		error = _level.snapshot_error_with_player(pair.level, pair.hero)
	if not _expect(error.is_empty() and _equal(before, _observation()), "prepared recipient completely prevalidates the exact pair without physical/history commit", error):
		return false
	_events.clear()
	if not _expect(_hero.restore_state(pair.hero) and _level.restore_state(pair.level) and _events.is_empty() and _equal(pair, _pair()) and _source.call("get_authored_cycle_restore_recipe").is_empty(), "quiet actual Hero→source→Scheduler3→Playback2 reconstruction is exact and event-free", _level.last_snapshot_error + "; " + String(_source.get("source_snapshot_error"))):
		return false
	_hero_hp = _hero.hp
	_kit = _hero.equipment.snapshot()
	_knot = _source.global_transform
	_quiet_probe_seen = true
	return true


func _atomic_negatives(pair: Dictionary) -> bool:
	for kind: String in ["generation_type", "outer_clock", "hp", "hit_generation", "history_clock", "native", "view", "unknown"]:
		var bad: Dictionary = pair.duplicate(true)
		match kind:
			"generation_type": bad.level.local.source.generation = float(bad.level.local.source.generation)
			"outer_clock": bad.level.local.source.clock_s += 0.00000001
			"hp": bad.level.local.source.hp = -0.1
			"hit_generation": bad.level.local.source.hit_receipts[0].generation = float(bad.level.local.source.hit_receipts[0].generation)
			"history_clock":
				for entry: Dictionary in [bad.level.local.source.lifecycle, bad.level.local.playback.lifecycle, bad.level.local.scheduler.authored_source_cycles.sources[0]]:
					entry.terminal_receipts[0].exchange.cooldown_until_s += 0.00000001
			"native": bad.level.local.source.native["foreign"] = true
			"view": bad.level.local.view.positions = [[100.0, 0.0, 0.0]]
			"unknown": bad.level.local["foreign"] = {}
		var before: Dictionary = _observation()
		var error: String = _level.snapshot_error_with_player(bad.level, bad.hero)
		if not _expect(not error.is_empty() and not _level.restore_state(bad.level) and _equal(before, _observation()), "pure and attempted restore reject forged " + kind + " without native mutation", error):
			return false
	return true


func _pair() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}


func _valid_pair(pair: Dictionary) -> bool:
	return not pair.hero.is_empty() and not pair.level.is_empty() and pair.level.local.source.api_revision == "act3-mirror-echo-source-2" and pair.level.local.playback.api_revision == "authored-echo-playback-2" and pair.level.local.scheduler.schema_version == 3 and _equal(pair.level.local.source.lifecycle, pair.level.local.playback.lifecycle) and _equal(pair.level.local.playback.lifecycle, pair.level.local.scheduler.authored_source_cycles.sources[0])


func _resources() -> Dictionary:
	var renderer: Node3D = _source.call("get_enemy_apparition") as Node3D
	var parts: Array = renderer.get("required_visuals")
	var visuals: Array = []
	for visual: MeshInstance3D in parts:
		visuals.append([visual.get_instance_id(), visual.mesh.get_instance_id(), visual.material_override.get_instance_id()])
	var knot: MeshInstance3D = _source.get_node("FixedLowRecoveryKnot") as MeshInstance3D
	visuals.append([knot.get_instance_id(), knot.mesh.get_instance_id(), knot.material_override.get_instance_id()])
	return {"owner": _source.get_instance_id(), "hero": _hero.get_instance_id(), "scheduler": _scheduler.get_instance_id(), "script": _source.get_script().get_instance_id(), "renderer": renderer.get_instance_id(), "renderer_script": renderer.get_script().get_instance_id(), "visuals": visuals, "descriptor": _source.call("native_descriptor"), "knot": _source.global_transform}


func _observation() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "source_hp": _source.get("hp"), "source_hits": _source.get("source_hits"), "source_dead": _source.get("dead"), "hit_receipts": _source.call("source_hit_receipts"), "program": _source.call("source_program"), "playback": _source.call("state"), "terminal": _source.call("get_authored_cycle_terminal_receipt"), "recipe": _source.call("get_authored_cycle_restore_recipe"), "resources": _resources(), "hero_transform": _hero.global_transform, "velocity": _hero.velocity, "clock": _scheduler.get_clock(), "reservations": _scheduler.reservations(), "events": _events.duplicate()}


func _pause() -> bool:
	_game.call("request_pause_deferred")
	await process_frame
	await process_frame
	return _expect(paused, "deferred actual native pause boundary settled")


func _await_phase(phase: String) -> bool:
	for _i: int in range(600):
		if _source.call("source_phase") == phase:
			return true
		if not await _tick():
			return false
	return _expect(false, "bounded native phase reached: " + phase, str(_level.call("state")))


func _until(target: float) -> bool:
	for _i: int in range(1800):
		if _scheduler.get_clock() >= target:
			return _expect(_scheduler.get_clock() - target <= 1.0 / Engine.physics_ticks_per_second + TICK_EPSILON, "actual action uses first available native tick")
		if not await _tick():
			return false
	return _expect(false, "finite actual action deadline reached")


func _tick() -> bool:
	if paused:
		return _expect(false, "actual route cannot advance while paused")
	_barrier.waiting = true
	await _barrier.observed
	var phase: String = _source.call("source_phase")
	_phases[phase] = true
	if not String(_level.get("last_configuration_error")).is_empty() or _hero.hp != _hero_hp or _hero.dead or _source.global_transform != _knot or not _equal(_kit, _hero.equipment.snapshot()) or _events.has("fired_blast") or _events.has("contact") or _scheduler.get_clock() > 90.0 or not String(_source.call("source_native_error")).is_empty():
		return _expect(false, "post-actor native tick retains actual Hero/source/kit/custody", str(_level.call("state")))
	return true


func _close() -> void:
	var refs: Array[WeakRef] = []
	for node: Node in [_source, _scheduler, _barrier, _game]:
		if is_instance_valid(node):
			refs.append(weakref(node))
	if is_instance_valid(_level):
		_level.exit_level()
	if is_instance_valid(_barrier):
		_barrier.waiting = false
		if _barrier.get_parent() != null:
			_barrier.get_parent().remove_child(_barrier)
		_barrier.queue_free()
	if is_instance_valid(_game):
		_game.queue_free()
	paused = false
	for _i: int in range(5):
		await process_frame
	if not refs.is_empty():
		var freed: bool = true
		for ref: WeakRef in refs:
			freed = freed and ref.get_ref() == null
		_expect(freed and get_nodes_in_group("enemies").is_empty(), "actual source/world/Scheduler/barrier/groups retire before replacement")
	_game = null
	_hero = null
	_level = null
	_source = null
	_scheduler = null
	_barrier = null


func _swipe(direction: Vector3) -> String:
	if direction.is_zero_approx():
		return "Actual swipe direction is empty"
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.60)
	var finish: Vector2 = start + _screen_direction(direction) * size.x * 0.22
	if not root.get_visible_rect().has_point(finish) or finish.y < 100.0:
		return "Actual final release leaves the shared input region"
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = finish
	root.push_input(release, true)
	return "" if float(_hero.get_threat_response_state().motion.dash_left_s) > 0.0 and (_game.call("get_aim_anchor_normalized") as Vector2).distance_to(finish / size) < 0.000001 else "Actual router did not start dash/retain final release anchor"


func _tap(direction: Vector3) -> String:
	if direction.is_zero_approx():
		return "Actual primary target direction is empty"
	var point: Vector2 = _game.call("get_aim_anchor") + _screen_direction(direction) * 60.0
	if not root.get_visible_rect().has_point(point) or point.y < 100.0:
		return "Actual tap leaves the shared input region"
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = point
	root.push_input(press, true)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = point
	root.push_input(release, true)
	return ""


func _screen_direction(direction: Vector3) -> Vector2:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var right: Vector3 = camera.global_basis.x
	var down: Vector3 = camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	return Vector2(direction.dot(right.normalized()), direction.dot(down.normalized())).normalized()


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok


func _equal(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right):
		return false
	if left is float:
		var a := PackedByteArray()
		var b := PackedByteArray()
		a.resize(8)
		b.resize(8)
		a.encode_double(0, left)
		b.encode_double(0, right)
		return a == b
	if left is Dictionary:
		if left.size() != right.size():
			return false
		for key: Variant in left:
			if not right.has(key) or not _equal(left[key], right[key]):
				return false
		return true
	if left is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _equal(left[index], right[index]):
				return false
		return true
	if typeof(left) in [TYPE_VECTOR2, TYPE_VECTOR3, TYPE_BASIS, TYPE_TRANSFORM3D, TYPE_COLOR, TYPE_AABB]:
		return var_to_bytes(left) == var_to_bytes(right)
	return left == right
