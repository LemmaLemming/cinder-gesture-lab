extends "res://tests/acts/act3/twin_suns_authored_shell_smoke.gd"
## TEST ONLY: production-shell fatal contact with two actual authored leases.
## Reuses the authored-shell seed, exact comparison, restore observer and cleanup.
## Registry acceptance/ten predecessors exist only in memory; saves are isolated.
## Public ordinary dashes preserve all pursuers, real source poses and budget2.
## A bounded failure to reach two leases is UNSUPPORTED REPRO, never a fabricated
## fatal-boundary failure. No engine/import job may run outside dev.py's queue.

const CrossingCheckpoint: String = "crossing-shadow-entry"
const RouteDashBound: int = 32
const PairWaitSeconds: float = 30.0
const FatalWaitSeconds: float = 18.0

var _prefix: Array[String] = []
var _protected_checkpoint: Dictionary = {}
var _before_fatal: Dictionary = {}
var _fatal_event: Dictionary = {}
var _contacts: Array[Dictionary] = []
var _unsupported_repro: String = ""
var _fatal_checked: bool = false
var _selected_overlap: Dictionary = {}
var _paused_source_events: Array[Dictionary] = []


func _run() -> void:
	_test_root = "user://test-act3-multi-fatal-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	var canonical: String = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var raw: Variant = JSON.parse_string(canonical)
	if _expect(raw is Dictionary, "read canonical registry without editing it"):
		await _exercise(raw)
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical, "canonical registry bytes remain unchanged")
	await _close_case()
	print("Twin Suns multi fatal: %d checks, %d failures; fatal_boundary_exercised=%s; unsupported_repro=%s (TEST ONLY; no acceptance/native/human claim)" % [_checks, _failures, _fatal_checked, _unsupported_repro])
	quit(1 if _failures else (2 if not _unsupported_repro.is_empty() else 0))


func _exercise(canonical: Dictionary) -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "run without shell preview-selecting arguments")
			return
	var initial: Dictionary = await _initial_snapshot()
	if initial.is_empty():
		return
	var raw: Dictionary = canonical.duplicate(true)
	for info: Dictionary in raw.levels:
		if info.id == "A3-L1":
			info.scene_path = FullPath
			info.readiness = "accepted" # TEST ONLY in-memory metadata.
			info.accepted_commit = "a".repeat(40)
			info.api_revision = Registry.API_REVISION
	_game = Shell.new()
	if not _expect(_game.configure_runtime(raw, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"), "configure production shell with isolated SaveStore paths"):
		_game.free()
		_game = null
		return
	root.add_child(_game)
	await _settle()
	for id: String in _game.registry.main_route():
		if id == "A3-L1":
			break
		_prefix.append(id)
	var session: Dictionary = _game.attempts.state()
	session.completed_main = _prefix.duplicate() # TEST ONLY canonical prefix.
	session.story = {"kind": "story", "level_id": "A3-L1", "snapshot": initial.duplicate(true), "checkpoint": initial.duplicate(true)}
	if not _expect(_prefix.size() == 10 and _game.attempts.restore_session(session), "seed the actual authored aggregate through public restore_session: " + _game.attempts.last_error):
		return
	_game.resume_campaign()
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and paused and is_instance_valid(_game.active_level) and _game.active_level.scene_file_path == FullPath and _source_bindings_valid(), "production shell installs five real retained sources and their common scheduler: " + _game.campaign_error):
		return
	_game.active_level.checkpoint_requested.connect(func(id: String, checkpoint: String, boundary: String) -> void:
		_checkpoint_events.append({"level_id": id, "checkpoint_id": checkpoint, "boundary": boundary, "paused": paused}))
	var sources: Dictionary = _game.active_level.get("sources")
	for id: String in SourceIDs:
		sources[id].connect("hit_resolved", _on_fatal_contact.bind(id))
		sources[id].connect("state_changed", _on_paused_source_event.bind("phase", id))
		sources[id].get_cue().state_changed.connect(_on_paused_source_event.bind("cue", id))
	_game.player.died.connect(_on_fatal_death)
	_game.resume_campaign()
	if not await _advance_actor(0.12):
		return
	# One left dash gives the two immutable low trunks a broad bypass. Every
	# later movement is an ordinary forward dash; no pursuer is killed or moved.
	if not await _ordinary_dash(Vector3.LEFT):
		return
	for _step: int in range(RouteDashBound):
		if _game.player.global_position.z <= -10.0 and _level_state().get("entered", []).size() == 3:
			break
		if not await _ordinary_dash(Vector3.FORWARD):
			return
	if not _expect(_game.player.global_position.z <= -10.0 and _level_state().get("entered", []).size() == 3 and _checkpoint_events.size() == 3 and _level_state().get("cleared", []).is_empty(), "real dashes enter z30/z15/z-6, bring both crossing sources into pursuit and retain all earlier pursuers"):
		return
	_protected_checkpoint = _game.attempts.state().story.checkpoint.duplicate(true)
	if not _expect(not _protected_checkpoint.is_empty() and _protected_checkpoint.level.progress.checkpoint_id == CrossingCheckpoint and _no_progress_awarded(_prefix), "actual crossing-entry save remains the protected earlier checkpoint without a source clear/reward"):
		return
	var scheduler: CinderThreatScheduler = _game.active_level.get("threat_scheduler") as CinderThreatScheduler
	var pair_deadline: float = scheduler.get_clock() + PairWaitSeconds
	var found_pair: bool = false
	for _tick: int in range(int(ceilf(PairWaitSeconds * Engine.physics_ticks_per_second)) + 120):
		if _game.player.dead or not _game.campaign_error.is_empty():
			break
		var records: Array[Dictionary] = scheduler.reservations()
		_selected_overlap = _qualifying_overlap(records, scheduler.get_clock())
		if not _selected_overlap.is_empty():
			found_pair = true
			break
		if scheduler.get_clock() >= pair_deadline:
			break
		await _ticks(1)
	if not found_pair:
		_unsupported("no genuine future stationary contact while a later processed source retained its lease within %.2f simulation seconds; fatal boundary was not exercised" % PairWaitSeconds)
		return
	_expect(scheduler.encounter_profile().get("reserved_threat_budget") == 2 and _all_sources_alive(), "two genuine common-scheduler leases coexist with all five original living nodes and budget2")
	print("SELECTED ACTUAL FATAL OVERLAP: ", _selected_overlap)
	# Deplete only the documented public fixture resource, after actual pairing.
	# A normal production pause captures the exact pre-fatal sample dates. No
	# private clock, hero pose, source HP, lease or geometry is synthesized.
	_game.player.hp = 0.1
	_game.request_pause()
	await _settle()
	_before_fatal = _game.capture_campaign_snapshot()
	if not _expect(_game.campaign_error.is_empty() and paused and not _before_fatal.is_empty() and _before_fatal.player.resources.hp == 0.1 and _before_fatal.level.local.scheduler.reservations.size() >= 2, "real paused pre-fatal aggregate retains concurrent actual leases and public depleted HP: " + _game.campaign_error):
		return
	_game.resume_campaign()
	var fatal_deadline: float = scheduler.get_clock() + FatalWaitSeconds
	for _tick: int in range(int(ceilf(FatalWaitSeconds * Engine.physics_ticks_per_second)) + 120):
		if _game.player.dead:
			break
		if scheduler.get_clock() >= fatal_deadline or not _game.campaign_error.is_empty():
			break
		await _ticks(1)
	if not _game.player.dead:
		_unsupported("stationary actual hero received no fatal contact within %.2f simulation seconds after genuine pair; no fatal assertion" % FatalWaitSeconds)
		return
	await _settle()
	if _fatal_event.get("reservations", []).size() < 2 or not _fatal_has_later_lease():
		_unsupported("genuine overlap was selected, but actual fatal contact had no later processed source retaining a lease; no callback-boundary assertion")
		await _retry_after_fatal()
		return
	_fatal_checked = true
	var death_snapshot: Dictionary = _game.capture_campaign_snapshot()
	_expect(paused and not _fatal_event.is_empty(), "first fatal contact synchronously pauses the actual shell while both leases remain retained")
	_expect(not death_snapshot.is_empty() and death_snapshot.get("player", {}).get("resources", {}).get("dead") == true, "deferred paused death captures a nonempty complete hero/five-source/scheduler aggregate: " + _game.active_level.last_snapshot_error)
	if not death_snapshot.is_empty():
		for reservation: Dictionary in death_snapshot.level.local.scheduler.reservations:
			var saved_source: Dictionary = death_snapshot.level.local.sources[reservation.source_id]
			_expect(float(saved_source.previous.clock_s) == float(death_snapshot.level.local.scheduler.clock_s) and _same_exact(saved_source.previous.hero_position, death_snapshot.player.motion.position), "leased source retains its exact current-clock fatal hero sample after the paused callback: " + String(reservation.source_id))
	var fatal_source_id: String = String(_contacts.back().source_id)
	var later_events: Array[Dictionary] = []
	for event: Dictionary in _paused_source_events:
		if SourceIDs.find(String(event.source_id)) > SourceIDs.find(fatal_source_id):
			later_events.append(event)
	var paused_contacts: int = 0
	for contact: Dictionary in _contacts:
		paused_contacts += 1 if contact.paused else 0
	_expect(later_events.is_empty() and paused_contacts == 1, "quiet death settlement adds no later-source phase/cue or duplicate fatal-contact callback: " + str(later_events))
	_expect(_game.campaign_error.is_empty(), "production death pause completes its SaveStore operation without a pending error: " + _game.campaign_error)
	var reader = Store.new(_test_root + "campaign.json")
	var disk: Dictionary = reader.read_payload()
	_expect(reader.last_error.is_empty() and not disk.is_empty() and disk.get("story", {}).get("snapshot", {}).get("player", {}).get("resources", {}).get("dead") == true, "production SaveStore reopens the coherent fatal aggregate: " + reader.last_error)
	_expect(_same_exact(_game.attempts.state().story.checkpoint, _protected_checkpoint), "fatal pause preserves the real earlier crossing checkpoint")
	print("MULTI FATAL DEFERRED PUBLIC DIAGNOSTIC: ", _diagnostic())
	# Exercise retry even when death capture exposes the intended regression.
	# Public retry intentionally abandons a failed pending pause and prepares a
	# fresh world; it must restore the real saved checkpoint without new events.
	await _retry_after_fatal()


## Admission is observed, never synthesized. Prefer an unconsumed real lunge
## whose measured straight route reaches the stationary hero before another
## later processed source's lease expires. Merely overlapping recovery records
## cannot exercise the missing-later-sample hypothesis. Keep a full hurt-time
## margin before contact so existing invulnerability naturally expires.
func _qualifying_overlap(records: Array[Dictionary], now: float) -> Dictionary:
	if records.size() < 2:
		return {}
	var tick_s: float = 1.0 / float(Engine.physics_ticks_per_second)
	var minimum_delay: float = float(_game.player.equipment.resolved_stats().hurt_invulnerability) + 3.0 * tick_s
	for attacker: Dictionary in records:
		var attacker_id: String = _actual_source_id(attacker)
		if attacker_id.is_empty() or _game.active_level.get("sources")[attacker_id].state().get("hit_consumed") == true:
			continue
		var contact_s: float = _stationary_contact_clock(attacker)
		if not is_finite(contact_s) or contact_s < now + minimum_delay or contact_s > float(attacker.active_until_s) - 2.0 * tick_s:
			continue
		var earlier_contact: bool = false
		for other: Dictionary in records:
			var other_id: String = _actual_source_id(other)
			if other.id == attacker.id or other_id.is_empty() or _game.active_level.get("sources")[other_id].state().get("hit_consumed") == true:
				continue
			var other_contact_s: float = _stationary_contact_clock(other)
			if is_finite(other_contact_s) and other_contact_s >= now and other_contact_s < contact_s:
				earlier_contact = true
				break
		if earlier_contact:
			continue
		for later: Dictionary in records:
			var later_id: String = _actual_source_id(later)
			if later_id.is_empty() or SourceIDs.find(later_id) <= SourceIDs.find(attacker_id) or float(later.recovery_until_s) <= contact_s + 3.0 * tick_s:
				continue
			return {"attacker_id": attacker_id, "attacker_lease": attacker.id, "attacker_active_from_s": attacker.active_from_s, "predicted_stationary_contact_s": contact_s, "later_source_id": later_id, "later_lease": later.id, "later_recovery_until_s": later.recovery_until_s, "sample_clock_s": now, "actual_lease_count": records.size()}
	return {}


func _stationary_contact_clock(record: Dictionary) -> float:
	if record.get("adapter", {}).get("kind") != "lunge" or record.get("state") not in ["warning", "lock", "active"]:
		return INF
	var start: Vector3 = record.adapter.start
	var end: Vector3 = record.adapter.planned_endpoint
	var direction: Vector3 = record.adapter.direction
	var offset: Vector3 = _game.player.global_position - start
	if absf(offset.y) > float(Stalker.TUNING.contact_height_tolerance):
		return INF
	offset.y = 0.0
	var projection: float = offset.dot(direction)
	var perpendicular: Vector3 = offset - direction * projection
	var radius: float = float(record.adapter.damage_radius) + CinderThreatScheduler.CAPSULE_RADIUS
	if perpendicular.length_squared() >= radius * radius:
		return INF
	var first_distance: float = maxf(0.0, projection - sqrt(radius * radius - perpendicular.length_squared()))
	if first_distance > (end - start).dot(direction) - 0.01:
		return INF
	return float(record.active_from_s) + first_distance / float(record.adapter.speed)


func _actual_source_id(record: Dictionary) -> String:
	for id: String in SourceIDs:
		if record.get("source_instance_id") == _game.active_level.get("sources")[id].get_instance_id():
			return id
	return ""


func _fatal_has_later_lease() -> bool:
	if _contacts.is_empty():
		return false
	var fatal_source_id: String = _contacts[-1].source_id
	for record: Dictionary in _fatal_event.get("reservations", []):
		var id: String = _actual_source_id(record)
		if not id.is_empty() and SourceIDs.find(id) > SourceIDs.find(fatal_source_id):
			return true
	return false


func _ordinary_dash(direction: Vector3) -> bool:
	for _tick: int in range(180):
		if _game.player.dead or not _game.campaign_error.is_empty():
			return _expect(false, "route failed before two-source fatal setup: " + _game.campaign_error)
		if paused:
			await _settle()
			if not _game.campaign_error.is_empty():
				return _expect(false, "real entry checkpoint save failed: " + _game.campaign_error)
			_game.resume_campaign()
		var response: Dictionary = _game.player.get_threat_response_state()
		if response.get("stable") == true and float(response.get("dash_cooldown_left_s", 1.0)) == 0.0:
			var sequence: int = _game.player.get_world_action_records().back().sequence if not _game.player.get_world_action_records().is_empty() else 0
			if not _expect(_game.player.request_dash(direction), "public ordinary dash accepts real ready actor toward " + str(direction)):
				return false
			if not await _advance_actor(float(response.stats.dash_cooldown) + 0.04):
				return false
			var records: Array[Dictionary] = _game.player.get_world_action_records(sequence)
			return _expect(records.size() == 1 and records[0].kind == "dash" and not records[0].blocked and not records[0].collision_shortened, "actual authored route publishes one complete unblocked dash")
		await _ticks(1)
	return _expect(false, "ordinary dash did not become ready within its finite bound")


func _advance_actor(duration: float) -> bool:
	var target: float = _game.player.get_world_action_clock() + duration
	for _tick: int in range(int(ceilf(duration * Engine.physics_ticks_per_second)) + 180):
		if _game.player.dead or not _game.campaign_error.is_empty():
			return _expect(false, "actor died or shell failed while routing before fatal setup: " + _game.campaign_error)
		if paused:
			await _settle()
			if not _game.campaign_error.is_empty():
				return _expect(false, "authored entry pause could not commit: " + _game.campaign_error)
			_game.resume_campaign()
		if _game.player.get_world_action_clock() >= target:
			return true
		await _ticks(1)
	return _expect(false, "real actor clock did not advance within finite routed wait")


func _retry_after_fatal() -> void:
	var old_level: CinderLevel = _game.active_level
	var old_actor: CinderPlayer = _game.player
	var old_world: Node3D = _game.world
	_restore_events.clear()
	_watching_restore = true
	node_added.connect(_observe_restore_node)
	_game.request_retry()
	await _settle()
	_watching_restore = false
	node_added.disconnect(_observe_restore_node)
	var restored: Dictionary = _game.capture_campaign_snapshot()
	_expect(_game.campaign_error.is_empty() and paused and _game.menu.page_name() == "resume" and not restored.is_empty(), "public request_retry replaces fatal world with a fresh paused authored unit: " + _game.campaign_error)
	_expect_exact(restored, _protected_checkpoint, "fresh production retry restores every real checkpoint scalar/type/pose/history/input/camera exactly")
	_expect(_restore_events.is_empty(), "fresh retry emits no action/damage/death/equipment/checkpoint/completion/contact event: " + str(_restore_events))
	_expect(not is_instance_valid(old_level) and not is_instance_valid(old_actor) and not is_instance_valid(old_world) and _count_levels(root) == 1 and _source_bindings_valid(), "retry retires old actual world and retains one entered level with five stable owners")
	_expect(_no_progress_awarded(_prefix), "fatal/retry does not manufacture clear, reward or departure")
	await create_timer(0.08, true).timeout
	_expect_exact(_game.capture_campaign_snapshot(), _protected_checkpoint, "restored fresh unit remains exact and paused without another tick")


func _all_sources_alive() -> bool:
	if not _source_bindings_valid():
		return false
	for source: CinderAct3SunboundStalker in _game.active_level.get("sources").values():
		if source.dead or source.hp != source.max_hp or not source.is_in_group("enemies"):
			return false
	return true


func _on_fatal_contact(result: Dictionary, source_id: String) -> void:
	_contacts.append({"source_id": source_id, "result": result.duplicate(true), "paused": paused})


func _on_paused_source_event(_state: Dictionary, kind: String, source_id: String) -> void:
	if paused and is_instance_valid(_game) and is_instance_valid(_game.player) and _game.player.dead:
		_paused_source_events.append({"kind": kind, "source_id": source_id})


func _on_fatal_death() -> void:
	var scheduler: CinderThreatScheduler = _game.active_level.get("threat_scheduler") as CinderThreatScheduler
	var states: Dictionary = {}
	for id: String in SourceIDs:
		states[id] = _game.active_level.get("sources")[id].state()
	# Public diagnostics only: snapshot hooks correctly reject inside the source
	# damage transaction. Exact previous samples are inspected after the barrier.
	_fatal_event = {"paused": paused, "clock_s": scheduler.get_clock(), "hero_position": _game.player.global_position, "sources": states, "reservations": scheduler.reservations(), "contacts_before_player_died": _contacts.duplicate(true)}


func _diagnostic() -> Dictionary:
	var actors: Dictionary = {}
	var scheduler_state: Dictionary = {}
	var scheduler_error: String = "not captured outside a paused barrier"
	var nested_errors: Array[Dictionary] = []
	var records: Array[Dictionary] = []
	if is_instance_valid(_game) and is_instance_valid(_game.active_level):
		var scheduler: CinderThreatScheduler = _game.active_level.get("threat_scheduler") as CinderThreatScheduler
		if is_instance_valid(scheduler):
			records = scheduler.reservations()
			if paused:
				scheduler_state = scheduler.snapshot_state(_game.active_level.call("scheduler_bindings"))
				scheduler_error = scheduler.last_snapshot_error
				if not scheduler_error.is_empty():
					nested_errors.append({"component": "scheduler", "error": scheduler_error})
		for id: String in SourceIDs:
			var source: CinderAct3SunboundStalker = _game.active_level.get("sources").get(id) as CinderAct3SunboundStalker
			if is_instance_valid(source):
				var captured: Dictionary = source.snapshot_state() if paused else {}
				var source_error: String = source.last_snapshot_error if paused else "not captured outside a paused barrier"
				actors[id] = {"state": source.state(), "snapshot": captured, "snapshot_error": source_error, "pre_fatal_previous": _before_fatal.get("level", {}).get("local", {}).get("sources", {}).get(id, {}).get("previous", {})}
				if paused and not source_error.is_empty():
					nested_errors.append({"component": id, "error": source_error})
	return {"nested_snapshot_errors": nested_errors, "scheduler_snapshot_error": scheduler_error, "paused": paused, "campaign_error": _game.campaign_error if is_instance_valid(_game) else "no shell", "level_snapshot_error": _game.active_level.last_snapshot_error if is_instance_valid(_game) and is_instance_valid(_game.active_level) else "no level", "level": _level_state(), "actor_samples": actors, "scheduler_snapshot": scheduler_state, "reservations": records, "selected_overlap": _selected_overlap, "fatal_event": _fatal_event, "contacts": _contacts, "checkpoint_events": _checkpoint_events}


func _unsupported(reason: String) -> void:
	_unsupported_repro = reason
	print("UNSUPPORTED REPRO: ", reason, "; PUBLIC DIAGNOSTIC: ", _diagnostic())


func _expect(ok: bool, note: String) -> bool:
	_checks += 1
	if ok:
		print("PASS: TEST ONLY multi fatal: " + note)
	else:
		_failures += 1
		push_error("FAIL: TEST ONLY multi fatal: " + note)
		if _failures == 1:
			var diagnostic: Dictionary = _diagnostic()
			# Emit the direct public nested errors before the larger actor/route dump;
			# an empty aggregate can otherwise mask its rejected scheduler component.
			print("FIRST FAILURE NESTED PUBLIC SNAPSHOT ERRORS: ", diagnostic.nested_snapshot_errors, "; scheduler_snapshot_error=", diagnostic.scheduler_snapshot_error)
			print("FIRST FAILURE PUBLIC DIAGNOSTIC: ", diagnostic)
	return ok
