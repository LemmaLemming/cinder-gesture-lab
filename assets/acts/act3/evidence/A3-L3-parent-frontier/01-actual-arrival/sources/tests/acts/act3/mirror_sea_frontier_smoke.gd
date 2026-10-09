extends SceneTree
## TEST ONLY first two authored Mirror Sea entries. Actual Main, native floor,
## viewport-routed ordinary swipes/first taps and completed public action records.
## No player/source resources, poses, clocks, physics or equipment are written.
## Default: real first Stalker death, one surviving Echo recovery hit, then an
## original-cooldown-earned generation2 on the same owner. --arrival-only stops
## at the paused arrival/save-refusal boundary. No whole retry, no-ammo, later
## route, native OS gesture, portrait art or campaign acceptance is claimed.

const MainScene = preload("res://scenes/main.tscn")
const LEVEL_PATH: String = "res://scenes/acts/act3/a3_l3_mirror_sea.tscn"
const RUNTIME_PATH: String = "res://scripts/acts/act3/mirror_sea_level.gd"
const STALKER_ID: String = "l3-threshold-stalker"
const ECHO_ID: String = "l3-first-echo"
const ENTRY_IDS: Array[String] = ["shore-and-doubled-sky", "one-real-body"]
const ENTRY_Z: Array[float] = [39.0, 27.0]
const POINT_TOLERANCE: float = 0.005 # Published physical landing/endpoint contract.
const TIME_EPSILON: float = 0.000001 # First available 60Hz action-boundary arithmetic.
const WAIT_BUDGET_S: float = 10.0
const TOTAL_BUDGET_S: float = 90.0
const DASH_KINDS: Array[String] = ["escape_dash", "positioning_dash", "first_escape_dash", "second_escape_dash", "tether_positioning_dash"]
const FIXED_DEADLINES: Array[String] = ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]

class PostActorBarrier extends Node:
	signal observed
	var waiting: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		_wake()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting:
			_wake.call_deferred()
	func _wake() -> void:
		if waiting:
			waiting = false
			observed.emit()

var _checks: int = 0
var _failures: int = 0
var _game: Node
var _hero: CinderPlayer
var _level: CinderLevel
var _scheduler: CinderThreatScheduler
var _barrier: PostActorBarrier
var _stalker: CharacterBody3D
var _echo: Node3D
var _kit: Dictionary = {}
var _stats: Dictionary = {}
var _hero_hp: float = 0.0
var _shells: int = 0
var _events: Dictionary = {}
var _actions: Array[Dictionary] = []
var _observed_phases: Dictionary = {}
var _held_source: String = ""
var _held_record: Dictionary = {}
var _active_travel: float = 0.0
var _echo_identity: Dictionary = {}
var _entry_observations: Dictionary = {}
var _initial_echo_ready: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var arrival_only: bool = arguments.size() == 1 and arguments[0] == "--arrival-only"
	var reason: String = "" if arguments.is_empty() or arrival_only else "unsupported selector: " + str(arguments)
	if reason.is_empty(): reason = await _open()
	if not _expect(reason.is_empty(), "paused actual Main installs one connected native L3 with no future sources", reason):
		await _close()
		_finish()
		return
	reason = _save_refusal()
	if not _expect(reason.is_empty(), "whole save/paired validators/restore explicitly refuse without live mutation", reason):
		await _close()
		_finish()
		return
	if not arrival_only:
		_game.call("resume_lab")
		reason = await _travel_entry(0)
		if reason.is_empty(): reason = _first_source()
		if _expect(reason.is_empty(), "real final-release swipes earn only the first native Stalker entry", reason):
			reason = await _clear_stalker()
			if _expect(reason.is_empty(), "actual moving Stalker dies to ordinary routed recovery taps", reason):
				reason = await _travel_entry(1)
				if reason.is_empty(): reason = _first_echo_ready()
				if _expect(reason.is_empty(), "prior real clear and actual capsule crossing earn only first Echo cycle_ready", reason):
					reason = await _echo_frontier()
					_expect(reason.is_empty(), "same surviving Echo earns generation2 after its original cooldown and one ordinary hit", reason)
		if not reason.is_empty():
			print("FIRST MEANINGFUL FAILURE; later frontier actions unattempted: ", reason, "; ", _diagnostic())
	await _close()
	_finish()


func _open() -> String:
	paused = true
	_game = MainScene.instantiate()
	_game.set("level_scene_path", LEVEL_PATH)
	root.add_child(_game)
	_game.call("open_bench")
	await process_frame
	await process_frame
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	if _hero == null or _level == null or _scheduler == null or not paused or _level.scene_file_path != LEVEL_PATH or _level.get_script().resource_path != RUNTIME_PATH:
		return "actual paused Main/full parent/shared Hero/Scheduler missing"
	var error: String = _level.contract_error()
	if error.is_empty(): error = String(_level.call("runtime_error"))
	if not error.is_empty(): return error
	if _hero.presentation_id != "act3_traveller" or _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0 or not _hero.get_world_action_records().is_empty():
		return "actual traveller/zero-clock arrival advanced or action history was manufactured"
	var scenery: Node = _level.get("scenery") as Node
	var floor_body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var solid: CollisionShape3D = floor_body.get_node_or_null("Solid") as CollisionShape3D if floor_body != null else null
	if solid == null or solid.disabled or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Vector3(14, 1, 108) or floor_body.global_position != Vector3(0, -0.5, 0):
		return "actual uninterrupted 14x108 Box floor/top Y0 differs"
	var blockers: Dictionary = scenery.call("blockers")
	if blockers.size() != 4:
		return "exact four permanent shore boundaries required"
	var stones: int = 0
	for child: Node in _level.get_children():
		if child is StaticBody3D:
			stones += 1
			var body: StaticBody3D = child as StaticBody3D
			var collision: CollisionShape3D = body.get_node_or_null("Solid") as CollisionShape3D
			var view: MeshInstance3D = body.get_node_or_null("FixedVisibleShoreStone") as MeshInstance3D
			if collision == null or collision.disabled or not collision.shape is BoxShape3D or view == null or not view.mesh is BoxMesh or (view.mesh as BoxMesh).size != (collision.shape as BoxShape3D).size:
				return "permanent stone collision has no matching native visible Box"
	if stones != 2 or not (_level.get("sources") as Dictionary).is_empty() or is_instance_valid(_level.get("mechanism")) or not _scheduler.reservations().is_empty() or not get_nodes_in_group("enemies").is_empty():
		return "arrival installed future actors, a hidden gate or an exchange"
	var state: Dictionary = _level.call("state")
	if state.sources.size() != 7 or not state.route.entries.is_empty() or not state.route.deaths.is_empty() or not state.route.pending_checkpoint_boundaries.is_empty() or state.ring.installed or state.completed or state.exit_state != "clear" or not state.contact.is_empty():
		return "paused route/ring/contact contains unearned progression"
	for id: String in state.sources:
		if state.sources[id].installed or state.sources[id].has("source") or state.sources[id].has("playback"):
			return "future source has installed state/HP/history: " + id
	_kit = _hero.equipment.snapshot()
	_stats = _hero.equipment.resolved_stats()
	_hero_hp = _hero.hp
	_shells = _hero.shells
	if _hero_hp <= 0.0 or float(_stats.primary_damage) <= 0.0 or float(_stats.primary_damage) >= 36.0:
		return "genuine starter kit cannot establish a surviving one-hit Echo frontier"
	_barrier = PostActorBarrier.new()
	_barrier.name = "TestOnlyMirrorSeaPostConsumerBarrier"
	_game.add_child(_barrier)
	_hero.world_action_executed.connect(_on_action)
	_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
	_hero.died.connect(func() -> void: _event("hero_death"))
	_hero.equipment_changed.connect(func(_id: String) -> void: _event("equipment"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _event("checkpoint"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _event("completion"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _event("exit"))
	return ""


func _save_refusal() -> String:
	var before: Dictionary = _observation()
	if before.hero.is_empty() or before.scheduler.is_empty():
		return "actual native Hero/Scheduler observation failed before whole-save refusal"
	var player_unit: Dictionary = _hero.snapshot_state()
	var captured: Dictionary = _level.snapshot_state()
	var message: String = _level.last_snapshot_error
	var forged: Dictionary = {"level_id": "A3-L3", "local_snapshot_version": 1, "local": {}}
	if player_unit.is_empty() or not captured.is_empty() or not message.contains("unsupported") or _level.snapshot_error(forged) != message or _level.snapshot_error_with_player(forged, player_unit) != message or _level.restore_state(forged) or _level.last_snapshot_error != message:
		return "candidate silently accepted/returned a partial whole-save unit"
	var state: Dictionary = _level.call("state")
	if state.persistence_supported or state.checkpoint_dispatch_supported or not _level.restore_candidate_construction_required() or not _exact(before, _observation()):
		return "explicit refusal changed native Hero/level/Scheduler/events"
	return ""


func _travel_entry(index: int) -> String:
	for _step: int in range(12):
		var state: Dictionary = _level.call("state")
		if state.route.entries.size() > index:
			return _entry_error(index)
		var error: String = await _ready()
		if not error.is_empty(): return error
		error = await _dash(Vector3.FORWARD, {}, "spatial entry swipe")
		if not error.is_empty(): return error
	return "bounded actual forward swipes did not earn entry " + ENTRY_IDS[index]


func _entry_error(index: int) -> String:
	var state: Dictionary = _level.call("state")
	if state.route.entries.size() != index + 1 or state.route.pending_checkpoint_boundaries.size() != index + 1 or not _exact(state.route.entries, state.route.pending_checkpoint_boundaries):
		return "entry/pending-boundary prefix is not earned once in canonical order"
	for ordinal: int in range(index + 1):
		var receipt: Dictionary = state.route.entries[ordinal]
		if receipt.id != ENTRY_IDS[ordinal] or receipt.beat != ordinal + 1 or float(receipt.clock_s) <= 0.0 or float(receipt.hero_position[2]) + float(receipt.capsule_radius) > ENTRY_Z[ordinal]:
			return "entry receipt lacks its actual capsule crossing: " + ENTRY_IDS[ordinal]
		if not _entry_observations.has(ordinal) or not _exact(receipt, _entry_observations[ordinal].receipt):
			return "entry was not independently observed at its complete native crossing tick"
	var expected: Array[String] = [STALKER_ID] if index == 0 else [STALKER_ID, ECHO_ID]
	var actual: Dictionary = _level.get("sources")
	if actual.size() != expected.size() or state.ring.installed or is_instance_valid(_level.get("mechanism")):
		return "future court/pulse installed before its earned teaching boundary"
	for id: String in state.sources:
		if bool(state.sources[id].installed) != expected.has(id) or actual.has(id) != expected.has(id):
			return "future/native source entitlement differs: " + id
	return "" if not state.completed and state.exit_state == "clear" and state.contact.is_empty() and _events.get("checkpoint", 0) == 0 else "partial frontier dispatched a checkpoint/completion/contact"


func _first_source() -> String:
	_stalker = (_level.get("sources") as Dictionary).get(STALKER_ID) as CharacterBody3D
	if _stalker == null or not _stalker.is_in_group("enemies") or float(_stalker.get("hp")) != 36.0 or int((_stalker.call("state") as Dictionary).cycle) != 0:
		return "fresh genuine first Stalker/node/HP36/empty cycle missing"
	_stalker.connect("died", func(_where: Vector3) -> void: _event("stalker_death"))
	return ""


func _clear_stalker() -> String:
	var prior_cycle: int = 0
	for _attempt: int in range(4):
		var error: String = await _warning_stalker(prior_cycle)
		if not error.is_empty(): return error
		var state: Dictionary = _stalker.call("state")
		prior_cycle = int(state.cycle)
		_held_source = STALKER_ID
		_held_record = _scheduler.reservation_state(String(state.reservation_id))
		_active_travel = 0.0
		_observed_phases = {"warning": true}
		if _held_record.is_empty() or _held_record.get("armed") != true or _held_record.source_instance_id != _stalker.get_instance_id() or _held_record.adapter.get("kind") != "lunge" or _held_record.geometry.get("kind") != "lane":
			return "actual physical source is not its own armed native lunge reservation"
		error = await _follow(state.proof, STALKER_ID)
		if not error.is_empty(): return error
		if not _expect(_observed_phases.has("lock") and _observed_phases.has("active") and _observed_phases.has("recovery") and _active_travel > 0.1, "actual Stalker cycle%d shows held lock, physical active travel and stopped recovery" % prior_cycle):
			return "actual Stalker phase/travel witness incomplete"
		_held_source = ""
		_held_record = {}
		if bool(_stalker.get("dead")): break
	if not bool(_stalker.get("dead")) or float(_stalker.get("hp")) != 0.0 or _stalker.is_in_group("enemies") or _events.get("stalker_death", 0) != 1:
		return "four-cycle bounded ordinary-primary route did not genuinely defeat retained Stalker once"
	var error: String = await _tick()
	if not error.is_empty(): return error
	var state: Dictionary = _level.call("state")
	if state.route.deaths.size() != 1 or not state.route.deaths.has(STALKER_ID) or not _scheduler.reservations().is_empty() or not is_instance_valid(_stalker) or _stalker.collision_layer != 0 or _stalker.collision_mask != 0:
		return "real death did not settle retained tombstone/lease/collision/progress"
	return _entry_error(0)


func _warning_stalker(prior_cycle: int) -> String:
	var deadline: float = _scheduler.get_clock() + WAIT_BUDGET_S
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		var state: Dictionary = _stalker.call("state")
		if not String(state.reservation_id).is_empty():
			return "" if state.phase == "warning" and int(state.cycle) == prior_cycle + 1 else "next actual Stalker warning was skipped or reused"
		if state.phase not in ["idle", "approach"] or state.dead:
			return "unleased living Stalker entered unsupported phase"
		if _scheduler.get_clock() >= deadline: break
		var error: String = await _tick()
		if not error.is_empty(): return error
	return "no accepted first/next Stalker warning within bounded actual10s: " + _diagnostic()


func _first_echo_ready() -> String:
	_echo = (_level.get("sources") as Dictionary).get(ECHO_ID) as Node3D
	if _echo == null or not _echo.is_in_group("enemies") or not _echo.call("source_cycles_managed") or _echo.call("get_authored_cycle_generation") != 1 or float(_echo.get("hp")) != 36.0 or int(_echo.get("source_hits")) != 0:
		return "fresh entitled Echo is not same-native managed initial cycle_ready/HP36/gen1"
	var playback: Dictionary = _echo.call("state")
	var state: Dictionary = _level.call("state")
	# The full capsule crosses during an unfinished ordinary entry dash. The
	# genuine ready boundary is observed then, rather than assuming it still
	# exists after completion when the parent may already legitimately admit.
	if _initial_echo_ready.is_empty() or _initial_echo_ready.instance_id != _echo.get_instance_id() or _initial_echo_ready.playback.status != "cycle_ready" or _initial_echo_ready.source.generation != 1 or _initial_echo_ready.source.hp != 36.0 or _initial_echo_ready.source.source_hits != 0 or not _initial_echo_ready.admissions.is_empty() or not _initial_echo_ready.playback.lifecycle.terminal_receipts.is_empty() or not _initial_echo_ready.terminal.is_empty() or not _initial_echo_ready.reservations.is_empty():
		return "initial ready source contains invented admission/terminal/lease history"
	if playback.status not in ["cycle_ready", "running"] or state.echo_records[ECHO_ID].admissions.size() > 1 or not _echo.call("get_authored_cycle_terminal_receipt").is_empty():
		return "source left its genuinely observed initial ready/admission frontier"
	_echo_identity = {"instance_id": _echo.get_instance_id(), "transform": _echo.global_transform, "definition": _echo.call("source_definition"), "profile": _echo.call("source_profile"), "world": _echo.call("prepared_world"), "epoch": (_echo.call("get_source_state") as Dictionary).source_epoch, "initial_program": _echo.call("get_authored_cycle_program"), "initial_playback_id": playback.playback_id}
	_echo.connect("source_hit_resolved", func(_result: Dictionary) -> void: _event("echo_hit"))
	_echo.connect("died", func() -> void: _event("echo_death"))
	_echo.connect("event_dispatched", func(_event_data: Dictionary, receipt: Dictionary) -> void:
		_event("echo_dispatch")
		if receipt.get("contact", false): _event("echo_contact")
	)
	return ""


func _echo_frontier() -> String:
	# A spatial entry is not attack permission. Approach by real ordinary
	# swipes only while there is no admitted exchange; observe ready at the
	# complete entry tick, then obtain the parent-owned current admission.
	var deadline: float = _scheduler.get_clock() + WAIT_BUDGET_S
	var admitted: bool = false
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		var playback: Dictionary = _echo.call("state")
		if playback.status == "running":
			admitted = true
			break
		if playback.status != "cycle_ready": return "initial Echo lost ready before genuine admission"
		if _scheduler.get_clock() >= deadline: break
		# Let native camera/admission settle while stationary before changing
		# position. The next dash is justified only by an absent live lease.
		var error: String = await _tick()
		if not error.is_empty(): return error
		playback = _echo.call("state")
		if playback.status == "running": continue
		if _hero.get_threat_response_state().stable and float(_hero.get_threat_response_state().dash_cooldown_left_s) == 0.0 and _hero.global_position.z > 22.5:
			error = await _dash(Vector3.FORWARD, {}, "unleased native Echo approach")
			if not error.is_empty(): return error
	if not admitted: return "first Echo did not admit within bounded native approach: " + _diagnostic()
	var error: String = await _echo_lock()
	if not error.is_empty(): return error
	var state: Dictionary = _level.call("state")
	var data: Dictionary = state.echo_records[ECHO_ID]
	_held_source = ECHO_ID
	_held_record = _scheduler.replay_reservation_state(String(data.lease.id))
	_observed_phases = {"warning": true, "lock": true}
	if _held_record.is_empty() or _held_record.source_instance_id != _echo.get_instance_id() or not data.locked or not data.lease.adapter.locked or data.admissions.size() != 1 or data.admissions[0].generation != 1:
		return "locked actual authored replay custody/admission/managed generation differs"
	error = await _follow(data.proof, ECHO_ID)
	if not error.is_empty(): return error
	if not _observed_phases.has("active") or not _observed_phases.has("recovery"):
		return "actual replay did not expose active/recovery through its live routed path"
	_held_source = ""
	_held_record = {}
	if _echo.get("dead") or float(_echo.get("hp")) != 36.0 - float(_stats.primary_damage) or _events.get("echo_hit", 0) != 1 or _events.get("echo_death", 0) != 0:
		return "one real recovery primary did not leave the original Echo alive with exact remaining HP"
	var sequence_after_hit: int = _last_sequence()
	var terminal: Dictionary = {}
	var complete_deadline: float = _scheduler.get_clock() + WAIT_BUDGET_S
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		if _echo.call("source_phase") == "complete":
			terminal = _echo.call("get_authored_cycle_terminal_receipt")
			break
		if _echo.call("get_authored_cycle_generation") != 1: return "next generation appeared before observing real predecessor terminal"
		if _scheduler.get_clock() >= complete_deadline: break
		error = await _tick()
		if not error.is_empty(): return error
	if terminal.is_empty() or not terminal.get("exchange") is Dictionary or not is_finite(float(terminal.exchange.cooldown_until_s)) or terminal.opportunities.is_empty() or _events.get("echo_dispatch", 0) != terminal.opportunities.size():
		return "surviving generation1 lacks its genuine complete terminal/cooldown receipt"
	for opportunity: Dictionary in terminal.opportunities:
		if opportunity.contact or opportunity.damage_attempted:
			return "actual ordinary replay path consumed contact/damage masked by dash immunity"
	var cooldown: float = float(terminal.exchange.cooldown_until_s)
	if _scheduler.get_clock() >= cooldown:
		return "native terminal was not observed before its original future cooldown"
	var next_deadline: float = cooldown + WAIT_BUDGET_S
	for _i: int in range(_frames(WAIT_BUDGET_S + 5.0)):
		var generation: int = int(_echo.call("get_authored_cycle_generation"))
		if generation == 2:
			var playback: Dictionary = _echo.call("state")
			var source: Dictionary = _echo.call("get_source_state")
			var program: Dictionary = _echo.call("get_authored_cycle_program")
			state = _level.call("state")
			if _scheduler.get_clock() < cooldown or playback.status != "cycle_ready" or not _scheduler.reservations().is_empty() or not state.echo_records[ECHO_ID].lease.is_empty() or state.echo_records[ECHO_ID].admissions.size() != 1:
				return "generation2 was not earned as an unadmitted ready boundary after original cooldown"
			if playback.playback_id == _echo_identity.initial_playback_id or program.sequence_id == _echo_identity.initial_program.sequence_id or playback.lifecycle.terminal_receipts.size() != 1 or not _exact(playback.lifecycle.terminal_receipts[0], terminal) or not _echo.call("get_authored_cycle_terminal_receipt").is_empty():
				return "generation2 reused IDs or copied/lost predecessor terminal authority"
			if source.generation != 2 or not source.alive or source.source_hits != 1 or source.hp != 36.0 - float(_stats.primary_damage) or source.hit_receipts.size() != 1 or source.hit_receipts[0].generation != 1 or source.hit_receipts[0].phase != "recovery":
				return "next preparation earned fabricated HP/hits or changed real recovery hit chain"
			if _last_sequence() != sequence_after_hit or _events.get("echo_hit", 0) != 1 or _events.get("echo_death", 0) != 0:
				return "terminal/cooldown preparation manufactured an additional Hero action/hit/death"
			if _echo.get_instance_id() != _echo_identity.instance_id or _echo.global_transform != _echo_identity.transform or source.source_epoch != _echo_identity.epoch or not _exact(_echo.call("source_definition"), _echo_identity.definition) or not _exact(_echo.call("source_profile"), _echo_identity.profile) or not _exact(_echo.call("prepared_world"), _echo_identity.world):
				return "next preparation replaced/moved/retuned the surviving native source"
			return _entry_error(1)
		if generation != 1: return "managed generation skipped contiguous predecessor"
		if _scheduler.get_clock() < cooldown and not _exact(terminal, _echo.call("get_authored_cycle_terminal_receipt")):
			return "original future cooldown terminal changed before expiry"
		if _scheduler.get_clock() >= next_deadline: break
		error = await _tick()
		if not error.is_empty(): return error
	return "real original cooldown did not earn generation2 within bounded wait: " + _diagnostic()


func _echo_lock() -> String:
	var deadline: float = _scheduler.get_clock() + WAIT_BUDGET_S
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		var state: Dictionary = _level.call("state")
		var data: Dictionary = state.echo_records[ECHO_ID]
		if data.locked: return ""
		if (_echo.call("state") as Dictionary).status != "running": return "actual admitted Echo cancelled before due lock: " + _diagnostic()
		if _scheduler.get_clock() >= deadline: break
		var error: String = await _tick()
		if not error.is_empty(): return error
	return "native parent did not commit actual admitted Echo at due lock"


func _follow(proof: Dictionary, id: String) -> String:
	if not proof.get("accepted", false) or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not proof.get("path") is Array or proof.path.is_empty() or proof.path.size() > 10 or not proof.get("attack_position") is Vector3 or not is_finite(float(proof.get("primary_time_s", INF))):
		return "actual accepted finite ordinary-only live proof unavailable: " + id
	var escape_count: int = 0
	var prior: Dictionary = {}
	for value: Variant in proof.path:
		if not value is Dictionary or not value.get("from") is Vector3 or not value.get("to") is Vector3 or not value.from.is_finite() or not value.to.is_finite() or not is_finite(float(value.get("start_s", INF))) or not is_finite(float(value.get("end_s", INF))) or float(value.end_s) < float(value.start_s):
			return "actual witness contains malformed native positions/times"
		var segment: Dictionary = value
		if not prior.is_empty() and (absf(float(prior.end_s) - float(segment.start_s)) > TIME_EPSILON or (prior.to as Vector3).distance_to(segment.from) > POINT_TOLERANCE):
			return "native accepted path is discontinuous"
		prior = segment
		if DASH_KINDS.has(String(segment.kind)):
			escape_count += 1 if String(segment.kind) in ["escape_dash", "first_escape_dash"] else 0
			var error: String = await _until(float(segment.start_s))
			if error.is_empty(): error = await _dash((segment.to - segment.from).normalized(), segment, String(segment.kind))
			if not error.is_empty(): return error
		elif String(segment.kind) in ["ordinary_primary", "ordinary_primary_full_recovery"]:
			break # Primary is an actual routed tap at the authoritative proof time.
		else:
			if segment.from != segment.to or _hero.global_position.distance_to(segment.from) > POINT_TOLERANCE:
				return "actual hold does not start at its displayed stationary position"
			var error: String = await _until(float(segment.end_s), segment.from)
			if not error.is_empty(): return error
	if escape_count != 1: return "native path lacks its one actual escape dash"
	var error: String = await _until(float(proof.primary_time_s))
	if not error.is_empty(): return error
	if _hero.global_position.distance_to(proof.attack_position) > POINT_TOLERANCE or not _hero.is_on_floor():
		return "actual returned Hero is outside the proved ordinary opening"
	var target: Node3D = _stalker if id == STALKER_ID else _echo
	var phase: String = String((_stalker.call("state") as Dictionary).phase) if id == STALKER_ID else String(_echo.call("source_phase"))
	if phase != "recovery": return "ordinary primary opening is not the actual recovery phase: " + phase
	var hp: float = float(target.get("hp"))
	var previous: int = _last_sequence()
	error = _tap(target.global_position - _hero.global_position)
	if not error.is_empty(): return error
	var actions: Array[Dictionary] = _hero.get_world_action_records(previous)
	if actions.size() != 1 or actions[0].kind != "primary" or actions[0].hits != 1 or actions[0].damage != float(_stats.primary_damage) or float(target.get("hp")) != maxf(0.0, hp - float(_stats.primary_damage)) or not _exact(actions[0].equipment_ids, _kit) or not _exact(actions[0].resolved_stats, _stats):
		return "real viewport first tap did not commit exactly one ordinary target HP transaction"
	print("PRIMARY: ", id, " HP ", hp, "→", target.get("hp"), " clock=", _scheduler.get_clock(), " actual_action=", actions[0].sequence)
	return ""


func _dash(direction: Vector3, segment: Dictionary, label: String) -> String:
	var response: Dictionary = _hero.get_threat_response_state()
	if not response.stable or float(response.dash_cooldown_left_s) != 0.0 or response.motion.queued_dash != Vector3.ZERO:
		return "actual " + label + " was not ready/unbuffered"
	if not segment.is_empty() and _hero.global_position.distance_to(segment.from) > POINT_TOLERANCE:
		return "actual dash origin differs from displayed witness"
	var origin: Vector3 = _hero.global_position
	var previous: int = _last_sequence()
	var error: String = _swipe(direction)
	if not error.is_empty(): return error
	# Public dash records are published at physical completion, never at press.
	var records: Array[Dictionary] = []
	for _i: int in range(_frames(2.0)):
		error = await _tick()
		if not error.is_empty(): return error
		records = _hero.get_world_action_records(previous)
		if not records.is_empty(): break
	if records.size() != 1 or records[0].kind != "dash" or records[0].blocked or records[0].collision_shortened or records[0].movement_damage or records[0].path.size() < 2 or records[0].world_origin.distance_to(origin) > POINT_TOLERANCE or records[0].landing.distance_to(_hero.global_position) > POINT_TOLERANCE or not _hero.is_on_floor() or float(_hero.get_threat_response_state().motion.dash_left_s) != 0.0 or not _exact(records[0].equipment_ids, _kit) or not _exact(records[0].resolved_stats, _stats):
		return "actual routed dash did not publish one complete unshortened native floor path"
	if not segment.is_empty() and (records[0].landing.distance_to(segment.to) > POINT_TOLERANCE or absf(float(records[0].started_at_s) - float(segment.start_s)) > _tick_s() + TIME_EPSILON or float(records[0].completed_at_s) > float(segment.end_s) + _tick_s() + TIME_EPSILON):
		return "completed actual dash does not match displayed landing/timing"
	return ""


func _ready() -> String:
	for _i: int in range(_frames(2.0)):
		var response: Dictionary = _hero.get_threat_response_state()
		if response.stable and float(response.dash_cooldown_left_s) == 0.0 and response.motion.queued_dash == Vector3.ZERO: return ""
		var error: String = await _tick()
		if not error.is_empty(): return error
	return "actual Hero did not become grounded/unbuffered/dash-ready within2s"


func _until(target: float, held_position: Variant = null) -> String:
	if not is_finite(target): return "nonfinite actual action deadline"
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		if held_position is Vector3 and _hero.global_position.distance_to(held_position) > POINT_TOLERANCE:
			return "Hero drifted from displayed stationary witness segment"
		if _scheduler.get_clock() >= target:
			return "" if _scheduler.get_clock() - target <= _tick_s() + TIME_EPSILON else "displayed action deadline was missed rather than followed"
		var error: String = await _tick()
		if not error.is_empty(): return error
	return "displayed action time exceeded bounded native wait"


func _tick() -> String:
	if paused: return "actual route cannot advance paused tree"
	_barrier.waiting = true
	await _barrier.observed
	if paused: return "actual simulation paused before completed consumer boundary"
	var error: String = String(_level.call("runtime_error"))
	if not error.is_empty(): return error
	if _hero.dead or _hero.hp != _hero_hp or _hero.shells != _shells or not _exact(_kit, _hero.equipment.snapshot()) or not _exact(_stats, _hero.equipment.resolved_stats()) or _events.get("fired_blast", 0) != 0 or _events.get("echo_contact", 0) != 0 or _events.get("equipment", 0) != 0 or _events.get("checkpoint", 0) != 0 or _events.get("completion", 0) != 0 or _events.get("exit", 0) != 0:
		return "actual Hero HP/ammo/kit or ordinary-only/no-progress frontier invariant changed"
	if _scheduler.get_clock() > TOTAL_BUDGET_S: return "finite native90s frontier budget exceeded"
	var parent_state: Dictionary = _level.call("state")
	for index: int in range(parent_state.route.entries.size()):
		if _entry_observations.has(index): continue
		var receipt: Dictionary = parent_state.route.entries[index]
		var body: CollisionShape3D = _hero.get_node_or_null("BodyCollision") as CollisionShape3D
		if index > 1 or body == null or not body.shape is CapsuleShape3D or receipt.clock_s != _scheduler.get_clock() or receipt.hero_position != [_hero.global_position.x, _hero.global_position.y, _hero.global_position.z] or receipt.capsule_radius != (body.shape as CapsuleShape3D).radius or body.global_position.z + (body.shape as CapsuleShape3D).radius > ENTRY_Z[index]:
			return "entry did not bind exact actual Hero/capsule/current clock"
		_entry_observations[index] = {"receipt": receipt.duplicate(true), "hero": _hero.global_position}
		if index == 1:
			var source: Node3D = (_level.get("sources") as Dictionary).get(ECHO_ID) as Node3D
			if source == null: return "genuine second entry lacks actual native recipient"
			_initial_echo_ready = {"instance_id": source.get_instance_id(), "source": source.call("get_source_state"), "playback": source.call("state"), "admissions": parent_state.echo_records[ECHO_ID].admissions.duplicate(true), "terminal": source.call("get_authored_cycle_terminal_receipt"), "reservations": _scheduler.reservations()}
	if not _held_source.is_empty():
		var phase: String = String((_stalker.call("state") as Dictionary).phase) if _held_source == STALKER_ID else String(_echo.call("source_phase"))
		_observed_phases[phase] = true
		var record: Dictionary = _scheduler.reservation_state(String(_held_record.id)) if _held_source == STALKER_ID else _scheduler.replay_reservation_state(String(_held_record.id))
		if record.is_empty() or record.source_instance_id != _held_record.source_instance_id:
			return "held native exchange disappeared/changed before real primary"
		for key: String in FIXED_DEADLINES:
			if not _exact(record[key], _held_record[key]): return "held actual scalar deadline changed: " + key
		if _held_source == STALKER_ID:
			if (_stalker.call("state") as Dictionary).hit_consumed: return "physical contact consumed despite ammo-free/no-immunity witness"
			if not _exact(record.geometry, _held_record.geometry) or record.adapter.planned_endpoint != _held_record.adapter.planned_endpoint:
				return "actual lunge committed footprint/endpoint changed while held"
			if phase == "active": _active_travel = maxf(_active_travel, _stalker.global_position.distance_to(_held_record.adapter.start))
			if phase == "recovery" and (_stalker.global_position.distance_to(_held_record.adapter.planned_endpoint) > POINT_TOLERANCE or _stalker.velocity != Vector3.ZERO):
				return "real physical lunge failed stopped0.005WU recovery endpoint"
	if is_instance_valid(_echo) and (_echo.global_transform != _echo_identity.transform or not String(_echo.call("source_native_error")).is_empty()):
		return "actual fixed Echo source/native renderer custody changed"
	return ""


func _swipe(direction: Vector3) -> String:
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.60)
	var finish: Vector2 = start + _screen_direction(direction) * size.x * 0.22
	if direction.is_zero_approx() or not root.get_visible_rect().has_point(finish) or finish.y < 100.0: return "ordinary swipe leaves actual shared input region"
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
	return "" if float(_hero.get_threat_response_state().motion.dash_left_s) > 0.0 and (_game.call("get_aim_anchor_normalized") as Vector2).distance_to(finish / size) < TIME_EPSILON else "actual final release did not start movement/retain screen anchor"


func _tap(direction: Vector3) -> String:
	var point: Vector2 = _game.call("get_aim_anchor") + _screen_direction(direction) * 60.0
	if direction.is_zero_approx() or not root.get_visible_rect().has_point(point) or point.y < 100.0: return "ordinary recovery tap leaves actual input region"
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


func _last_sequence() -> int:
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return 0 if records.is_empty() else int(records.back().sequence)


func _observation() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "level": _level.call("state"), "scheduler": _scheduler.snapshot_state(_level.call("scheduler_bindings")), "events": _events.duplicate(true), "actions": _actions.duplicate(true)}


func _on_action(record: Dictionary) -> void:
	_actions.append(record.duplicate(true))


func _event(label: String) -> void:
	_events[label] = int(_events.get(label, 0)) + 1


func _diagnostic() -> String:
	if not is_instance_valid(_level): return "actual parent unavailable"
	var state: Dictionary = _level.call("state")
	return str({"clock_s": state.clock_s, "hero_position": _hero.global_position, "configuration_error": state.configuration_error, "admission_reason": state.admission_reason, "camera_error": state.camera_error, "entries": state.route.entries, "deaths": state.route.deaths, "sources": state.sources, "events": _events})


func _close() -> void:
	var refs: Array[WeakRef] = []
	for node: Node in [_hero, _stalker, _echo, _scheduler, _level, _barrier, _game]:
		if is_instance_valid(node): refs.append(weakref(node))
	if is_instance_valid(_game) and is_instance_valid(_hero): _game.call("open_bench")
	# A successful frontier has genuinely retired its exchange before cleanup.
	# end_encounter may refuse a managed retained journal; an early failing
	# active case is disposed as a whole world, never rewritten/reset by test.
	if _failures == 0 and is_instance_valid(_scheduler):
		_expect(_scheduler.reservations().is_empty(), "successful native frontier has already released its actual exchange before disposal")
	if is_instance_valid(_level): _level.exit_level()
	if is_instance_valid(_barrier): _barrier.waiting = false
	if is_instance_valid(_game):
		if _game.get_parent() == root: root.remove_child(_game)
		_game.queue_free()
	paused = false
	for _i: int in range(5): await process_frame
	await create_timer(0.15, true, false, true).timeout
	if not refs.is_empty():
		var freed: bool = true
		for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
		_expect(freed and get_nodes_in_group("enemies").is_empty(), "actual parent/sources/Scheduler/Hero/barrier free with no enemy residue")
	_game = null
	_hero = null
	_level = null
	_scheduler = null
	_barrier = null
	_stalker = null
	_echo = null


func _tick_s() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


func _frames(seconds: float) -> int:
	return int(ceil(seconds * Engine.physics_ticks_per_second)) + 4


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok: print("PASS: ", label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok


func _finish() -> void:
	print("Owned Mirror Sea frontier: %d checks; failures: %d. Routed first two entries only; no full persistence/route/art/native-human acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _exact(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right): return false
	if left is float:
		var a := PackedByteArray()
		var b := PackedByteArray()
		a.resize(8)
		b.resize(8)
		a.encode_double(0, left)
		b.encode_double(0, right)
		return a == b
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _exact(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _exact(left[index], right[index]): return false
		return true
	if typeof(left) in [TYPE_VECTOR2, TYPE_VECTOR3, TYPE_BASIS, TYPE_TRANSFORM3D, TYPE_COLOR, TYPE_AABB]: return var_to_bytes(left) == var_to_bytes(right)
	return left == right
