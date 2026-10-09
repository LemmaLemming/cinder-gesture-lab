extends "res://tests/acts/act3/mirror_sea_frontier_smoke.gd"
## TEST ONLY authored L3 route. Reuses the frozen frontier's actual Main,
## routed input, completed-dash checks, strict native equality and disposal.
## No source/Hero resources, poses, clocks, programmes or admissions are written.
## Default/--resonant-death-only: first five entries, with a genuine two-primary
## recovery death between the SAME mechanism's pulses. --full-route: all six
## entries, surviving Echo between pulses, then seven ordinary deaths/contact.
## --echo-first or --stalker-first selects a real final approach priority.
## This is unexecuted mechanic evidence, not saves/retry, art, OS gestures or
## production campaign acceptance. A current native witness is always required.

const ROUTE_ENTRIES: Array[String] = ["shore-and-doubled-sky", "one-real-body", "useful-ending-west", "useful-ending-east", "resonant-apron", "shore-falls-silent"]
const ROUTE_Z: Array[float] = [39.0, 27.0, 15.0, 2.0, -14.0, -32.0]
const ROUTE_BEATS: Array[int] = [1, 2, 3, 3, 4, 5]
const ROSTER: Array[String] = ["l3-threshold-stalker", "l3-first-echo", "l3-useful-west-echo", "l3-useful-east-echo", "l3-resonant-echo", "l3-priority-echo", "l3-priority-stalker"]
const GROUPS: Array = [["l3-threshold-stalker"], ["l3-first-echo"], ["l3-useful-west-echo"], ["l3-useful-east-echo"], ["l3-resonant-echo"], ["l3-priority-echo", "l3-priority-stalker"]]
const PULSE_ID: String = "l3-resonant-pulse"
const RESONANT_ID: String = "l3-resonant-echo"
const FINAL_ECHO: String = "l3-priority-echo"
const FINAL_STALKER: String = "l3-priority-stalker"
const ROUTE_BUDGET_S: float = 240.0
const GROUP_BUDGET_S: float = 40.0
const SAFE_RECT: Rect2 = Rect2(-7, -54, 14, 108)
const EXIT_RECT: Rect2 = Rect2(-1.2, -47.65, 2.4, 1.3)
const HOLD_KINDS: Array[String] = ["recognition_and_ready", "recovery_wait", "primary_ready", "tether_return_ready", "ordinary_primary_ready", "tether_ready"]

var _full_route: bool = false
var _priority: String = "stalker"
var _all_sources: Dictionary = {}
var _expected_hp: Dictionary = {}
var _identities: Dictionary = {}
var _entry_samples: Dictionary = {}
var _source_deaths: Dictionary = {}
var _used_leases: Dictionary = {}
var _fixed_leases: Dictionary = {}
var _lease_phases: Dictionary = {}
var _travel: Dictionary = {}
var _terminal_history: Dictionary = {}
var _generation_seen: Dictionary = {}
var _current_id: String = ""
var _current_lease: Dictionary = {}
var _group: Array[String] = []
var _group_deadline: float = 0.0
var _scheduler_identity: int = 0
var _mechanism_identity: int = 0
var _mechanism_transform: Transform3D
var _ring_seen: Dictionary = {}
var _pulse_records: Dictionary = {}
var _pulse_endings: Dictionary = {}
var _first_final_primary: String = ""
var _last_primary_wall_ms: int = -1000
var _selection_error: String = ""


func _run() -> void:
	var reason: String = _options_route()
	if reason.is_empty(): reason = await _open()
	if not _expect(reason.is_empty(), "actual paused Main/connected shore enters with genuine starter resources", reason):
		await _close_route()
		_finish()
		return
	_scheduler_identity = _scheduler.get_instance_id()
	_game.call("resume_lab")
	var count: int = 6 if _full_route else 5
	for index: int in range(count):
		reason = await _enter_route(index)
		if not reason.is_empty():
			_expect(false, "actual spatial entry " + ROUTE_ENTRIES[index], reason)
			break
		_group.assign(GROUPS[index])
		_group_deadline = _scheduler.get_clock() + GROUP_BUDGET_S
		if index == 4: reason = await _resonance()
		else: reason = await _clear_group(index)
		if not _expect(reason.is_empty(), "ordinary native clear at " + ROUTE_ENTRIES[index], reason): break
	if reason.is_empty() and _full_route:
		reason = await _contact_route_exit()
		_expect(reason.is_empty(), "seven real deaths and one completed ring earn distinct actual contact exit", reason)
	if reason.is_empty():
		reason = _route_final_error(count)
		_expect(reason.is_empty(), "selected finite route retains actual actions/tombstones/pulses/no blast or grants", reason)
	if not reason.is_empty(): print("FIRST MEANINGFUL ROUTE FAILURE; later actions unattempted: ", reason, "; ", _diagnostic())
	await _close_route()
	_finish()


func _options_route() -> String:
	var scope: bool = false
	var priority: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument in ["--full-route", "--resonant-death-only"] and not scope:
			scope = true
			_full_route = argument == "--full-route"
		elif argument in ["--echo-first", "--stalker-first"] and not priority:
			priority = true
			_priority = "echo" if argument == "--echo-first" else "stalker"
		else: return "unsupported or repeated route selector: " + argument
	return "" if _full_route or not priority else "final priority selector requires --full-route"


func _enter_route(index: int) -> String:
	_group.clear()
	_current_id = ""
	_current_lease = {}
	for _step: int in range(16):
		var state: Dictionary = _level.call("state")
		if state.route.entries.size() > index:
			return _entry_error(index)
		var reason: String = await _ready()
		if not reason.is_empty(): return reason
		if not _scheduler.reservations().is_empty(): return "spatial entry traversal encountered an unretired prior live exchange"
		# Final Echo priority uses a deliberate buffered straight approach once
		# its real entry is earned, not a permission from a prospective witness.
		reason = await _dash(Vector3.FORWARD, {}, "ordinary authored entry")
		if not reason.is_empty(): return reason
	return "bounded native swipes failed canonical entry " + ROUTE_ENTRIES[index]


func _entry_error(index: int) -> String:
	var state: Dictionary = _level.call("state")
	if state.route.entries.size() != index + 1 or not _exact(state.route.entries, state.route.pending_checkpoint_boundaries):
		return "native entered/pending-boundary prefix differs from actual route"
	var expected: Array[String] = []
	for ordinal: int in range(index + 1):
		var receipt: Dictionary = state.route.entries[ordinal]
		if receipt.id != ROUTE_ENTRIES[ordinal] or receipt.beat != ROUTE_BEATS[ordinal] or not _entry_samples.has(ordinal) or not _exact(receipt, _entry_samples[ordinal]) or float(receipt.hero_position[2]) + float(receipt.capsule_radius) > ROUTE_Z[ordinal]:
			return "canonical entry lacks genuine current capsule/clock receipt"
		for id: String in GROUPS[ordinal]: expected.append(id)
	if (_level.get("sources") as Dictionary).size() != expected.size(): return "future living sources were installed or actual recipient missing"
	for id: String in ROSTER:
		if bool(state.sources[id].installed) != expected.has(id): return "source installation does not match actual entry prefix: " + id
	if state.ring.installed != (index >= 4): return "resonant mechanism did not follow its unique actual entry"
	if index == 5 and (not state.sources[FINAL_ECHO].installed or not state.sources[FINAL_STALKER].installed or not (_all_sources[FINAL_ECHO] as Node3D).is_in_group("enemies") or not (_all_sources[FINAL_STALKER] as Node3D).is_in_group("enemies")):
		return "final pair was not simultaneously real, living and ordinary-targetable"
	return ""


func _clear_group(index: int) -> String:
	if index == 5 and _priority == "echo":
		var reason: String = await _priority_approach()
		if not reason.is_empty(): return reason
	for _iteration: int in range(12):
		if _group_dead(): return await _settle_clear()
		if _scheduler.get_clock() >= _group_deadline: return "actual group exceeded bounded40s"
		var selection: Dictionary = await _next_exchange()
		if selection.is_empty(): return (_selection_error if not _selection_error.is_empty() else "no next genuine admitted source within native bounded wait") + ": " + _diagnostic()
		_current_id = String(selection.id)
		_current_lease = selection.lease.duplicate(true)
		_used_leases[String(_current_lease.id)] = true
		var reason: String = await _walk_proof(selection.proof, _current_id)
		if not reason.is_empty(): return reason
		reason = _ordinary_hit(_current_id, "recovery")
		if not reason.is_empty(): return reason
		_current_id = ""
		_current_lease = {}
	return "bounded genuine admissions did not clear group"


func _priority_approach() -> String:
	# A real queued viewport swipe keeps the shared player deliberately moving
	# toward the chosen Echo. No native pose/buffer or enemy process is written.
	var target: Node3D = _all_sources[FINAL_ECHO]
	for _i: int in range(4):
		if _hero.global_position.distance_to(target.global_position) <= float(_stats.primary_range): return ""
		if not _scheduler.reservations().is_empty(): return "Echo-priority approach already has another genuine lease; it cannot override that permission"
		var reason: String = await _queued_navigation(Vector3.FORWARD)
		if not reason.is_empty(): return reason
	return "actual Echo-priority approach did not reach useful range without a different admission"


func _queued_navigation(direction: Vector3) -> String:
	var response: Dictionary = _hero.get_threat_response_state()
	if float(response.motion.dash_left_s) != 0.0 or response.motion.queued_dash != Vector3.ZERO or not _hero.is_on_floor(): return "real buffered navigation requires the previous physical dash to finish"
	var previous: int = _last_sequence()
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.60)
	var finish: Vector2 = start + _screen_direction(direction) * size.x * 0.22
	if not root.get_visible_rect().has_point(finish) or finish.y < 100.0: return "ordinary buffered final approach leaves input region"
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
	response = _hero.get_threat_response_state()
	if float(response.motion.dash_left_s) == 0.0 and response.motion.queued_dash != direction.normalized(): return "actual final-release input neither started nor buffered shared movement"
	# The genuine shared swipe release clears its prior nearby-tap chain.
	_last_primary_wall_ms = -1000
	for _tick_index: int in range(_frames(2.0)):
		var reason: String = await _tick()
		if not reason.is_empty(): return reason
		var records: Array[Dictionary] = _hero.get_world_action_records(previous)
		if records.is_empty(): continue
		if records.size() != 1 or records[0].kind != "dash" or records[0].blocked or records[0].collision_shortened or records[0].movement_damage or float(_hero.get_threat_response_state().motion.dash_left_s) != 0.0 or not _hero.is_on_floor(): return "buffered ordinary approach lacked its actual completed unshortened dash"
		return ""
	return "bounded actual buffered approach never completed"


func _swipe(direction: Vector3) -> String:
	var reason: String = super._swipe(direction)
	if reason.is_empty(): _last_primary_wall_ms = -1000
	return reason


func _next_exchange() -> Dictionary:
	_selection_error = ""
	var stop: float = minf(_group_deadline, _scheduler.get_clock() + WAIT_BUDGET_S)
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		for id: String in _group:
			var source: Node3D = _all_sources[id]
			if bool(source.get("dead")): continue
			var current: Dictionary = source.call("state")
			if _is_stalker(id):
				var lease: Dictionary = _scheduler.reservation_state(String(current.reservation_id))
				if current.phase == "warning" and not lease.is_empty() and not _used_leases.has(String(lease.id)):
					return {"id": id, "lease": lease, "proof": current.proof}
			elif current.status == "running":
				var data: Dictionary = (_level.call("state") as Dictionary).echo_records[id]
				if data.locked and not _used_leases.has(String(data.lease.id)):
					var lease: Dictionary = _scheduler.replay_reservation_state(String(data.lease.id))
					if not lease.is_empty(): return {"id": id, "lease": lease, "proof": data.proof}
		if _scheduler.get_clock() >= stop: break
		var reason: String = await _tick()
		if not reason.is_empty():
			_selection_error = reason
			return {}
		if _scheduler.reservations().is_empty():
			var approaching: String = _unleased_echo_approach()
			if not approaching.is_empty():
				reason = await _ready()
				if not reason.is_empty():
					_selection_error = reason
					return {}
				if _scheduler.reservations().is_empty():
					reason = await _dash(Vector3.FORWARD, {}, "unleased actual knot approach")
					if not reason.is_empty():
						_selection_error = reason
						return {}
	return {}


func _unleased_echo_approach() -> String:
	for id: String in _group:
		if _is_stalker(id) or bool((_all_sources[id] as Node3D).get("dead")): continue
		var source: Node3D = _all_sources[id]
		if source.call("source_phase") == "cycle_ready" and _hero.global_position.z > source.global_position.z + 2.0:
			return id
	return ""


func _walk_proof(proof: Dictionary, id: String) -> String:
	if not proof.get("accepted", false) or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not proof.get("path") is Array or proof.path.is_empty() or proof.path.size() > 10 or not proof.get("attack_position") is Vector3 or not is_finite(float(proof.get("primary_time_s", INF))): return "actual finite ordinary-only native proof unavailable"
	var previous: Dictionary = {}
	var escapes: int = 0
	for value: Variant in proof.path:
		if not value is Dictionary or not value.get("from") is Vector3 or not value.get("to") is Vector3 or not value.from.is_finite() or not value.to.is_finite() or not is_finite(float(value.get("start_s", INF))) or not is_finite(float(value.get("end_s", INF))) or float(value.end_s) < float(value.start_s): return "live native path segment is malformed"
		var segment: Dictionary = value
		if not previous.is_empty() and (absf(float(previous.end_s) - float(segment.start_s)) > TIME_EPSILON or (previous.to as Vector3).distance_to(segment.from) > POINT_TOLERANCE): return "native path is discontinuous"
		previous = segment
		var reason: String = ""
		if DASH_KINDS.has(String(segment.kind)):
			escapes += 1 if String(segment.kind) in ["escape_dash", "first_escape_dash"] else 0
			reason = await _until(float(segment.start_s))
			if reason.is_empty(): reason = await _dash((segment.to - segment.from).normalized(), segment, String(segment.kind))
		elif String(segment.kind) in ["ordinary_primary", "ordinary_primary_full_recovery"]:
			break
		elif HOLD_KINDS.has(String(segment.kind)):
			if segment.from != segment.to or _hero.global_position.distance_to(segment.from) > POINT_TOLERANCE: return "actual stationary path origin differs"
			reason = await _until(float(segment.end_s), segment.from)
		else: return "unsupported actual native segment kind: " + String(segment.kind)
		if not reason.is_empty(): return reason
	if escapes != 1: return "current proof omits its actual initial escape"
	var reason: String = await _until(float(proof.primary_time_s))
	if not reason.is_empty(): return reason
	if not _hero.is_on_floor() or _hero.global_position.distance_to(proof.attack_position) > POINT_TOLERANCE or _phase(id) != "recovery": return "ordinary return did not reach the real admitted recovery opening"
	var phases: Dictionary = _lease_phases.get(String(_current_lease.id), {})
	for phase: String in ["warning", "lock", "active", "recovery"]:
		if not phases.has(phase): return "actual current source/cue phase not observed: " + phase
	if _is_stalker(id) and (float(_travel.get(String(_current_lease.id), 0.0)) <= 0.1 or (_all_sources[id] as Node3D).global_position.distance_to(_current_lease.adapter.planned_endpoint) > POINT_TOLERANCE): return "native lunge did not physically reach its stopped endpoint"
	return ""


func _ordinary_hit(id: String, allowed_phase: String) -> String:
	if not _all_sources.has(id) or _phase(id) != allowed_phase or bool((_all_sources[id] as Node3D).get("dead")) or not _hero.get_threat_response_state().stable or float(_hero.get_threat_response_state().primary_cooldown_left_s) != 0.0: return "real ordinary target/phase/stability/primary readiness unavailable"
	if _last_primary_wall_ms >= 0 and Time.get_ticks_msec() - _last_primary_wall_ms <= 280: return "first-tap primary cannot be claimed within the actual nearby second-tap window"
	var before: Dictionary = _expected_hp.duplicate(true)
	var sequence: int = _last_sequence()
	var target: Node3D = _all_sources[id]
	var reason: String = _tap(target.global_position - _hero.global_position)
	if not reason.is_empty(): return reason
	_last_primary_wall_ms = Time.get_ticks_msec()
	var changed: int = 0
	for key: String in _all_sources:
		var hp: float = float((_all_sources[key] as Node3D).get("hp"))
		if hp != float(before[key]):
			if hp != maxf(0.0, float(before[key]) - float(_stats.primary_damage)): return "real ordinary slash applied unexpected native source HP"
			changed += 1
		_expected_hp[key] = hp
	var records: Array[Dictionary] = _hero.get_world_action_records(sequence)
	if records.size() != 1 or records[0].kind != "primary" or records[0].hits != changed or changed < 1 or float(_expected_hp[id]) >= float(before[id]) or records[0].damage != float(_stats.primary_damage) or not _exact(records[0].equipment_ids, _kit) or not _exact(records[0].resolved_stats, _stats): return "viewport first tap failed a genuine matching ordinary HP/action transaction"
	if id in [FINAL_ECHO, FINAL_STALKER] and _first_final_primary.is_empty(): _first_final_primary = id
	print("REAL ROUTE PRIMARY: ", id, " ", before[id], "→", _expected_hp[id], " phase=", allowed_phase, " clock=", _scheduler.get_clock(), " hits=", changed)
	return ""


func _resonance() -> String:
	var reason: String = await _next_pulse(1)
	if not reason.is_empty(): return reason
	var mechanism: CinderLaneMechanism = _level.get("mechanism") as CinderLaneMechanism
	_mechanism_identity = mechanism.get_instance_id()
	_mechanism_transform = mechanism.global_transform
	_pulse_records["1"] = _current_lease.duplicate(true)
	var ring: Dictionary = (_level.call("state") as Dictionary).ring
	reason = await _walk_proof(ring.proofs["1"], PULSE_ID)
	_current_id = ""
	_current_lease = {}
	if reason.is_empty(): reason = await _wait_pulse_terminal(1)
	if not reason.is_empty(): return reason
	var selected: Dictionary = await _next_exchange()
	if selected.is_empty() or selected.id != RESONANT_ID: return _selection_error if not _selection_error.is_empty() else "pulse1 did not yield the actual unique own Echo"
	_current_id = RESONANT_ID
	_current_lease = selected.lease.duplicate(true)
	_used_leases[String(_current_lease.id)] = true
	reason = await _walk_proof(selected.proof, RESONANT_ID)
	if reason.is_empty(): reason = _ordinary_hit(RESONANT_ID, "recovery")
	if not reason.is_empty(): return reason
	if not _full_route:
		# A second real primary is admitted by the current shared cooldown and
		# actual wall-clock gesture grammar, while the same real recovery lasts.
		reason = await _second_recovery_primary(RESONANT_ID)
		if not reason.is_empty(): return reason
		if not bool((_all_sources[RESONANT_ID] as Node3D).get("dead")): return "real two-tap recovery branch did not kill the original Echo"
	else:
		if bool((_all_sources[RESONANT_ID] as Node3D).get("dead")) or float(_expected_hp[RESONANT_ID]) <= 0.0: return "surviving branch lost the actual original Echo before pulse2"
	_current_id = ""
	_current_lease = {}
	reason = await _next_pulse(2)
	if not reason.is_empty(): return reason
	ring = (_level.call("state") as Dictionary).ring
	var echo: Node3D = _all_sources[RESONANT_ID]
	var expected_outcome: String = "complete" if _full_route else "cancelled"
	if ring.between_receipt.is_empty() or not _exact(ring.between_receipt, echo.call("get_authored_cycle_terminal_receipt")) or ring.between_receipt.outcome != expected_outcome or bool(echo.get("dead")) == _full_route or _current_lease.opening_position != echo.global_position or _current_lease.source_instance_id != _mechanism_identity or mechanism.get_instance_id() != _mechanism_identity or mechanism.global_transform != _mechanism_transform or float(_current_lease.start_s) < float(_pulse_records["1"].cooldown_until_s): return "pulse2 lost actual surviving/recovery-death caller receipt, fixed opening, same mechanism or original cooldown"
	_pulse_records["2"] = _current_lease.duplicate(true)
	reason = await _walk_proof(ring.proofs["2"], PULSE_ID)
	if reason.is_empty() and _full_route:
		# The actual returned position is the still-hittable completed living
		# knot. Clear it during pulse2 recovery, before any next Echo preparation.
		reason = _ordinary_hit(RESONANT_ID, "complete")
	_current_id = ""
	_current_lease = {}
	if reason.is_empty(): reason = await _wait_pulse_terminal(2)
	if not reason.is_empty(): return reason
	if not _group_dead() or mechanism.state().cycle != 2 or not _scheduler.reservations().is_empty(): return "same two actual pulse cycles and real Echo death did not settle"
	return await _settle_clear()


func _second_recovery_primary(id: String) -> String:
	for _i: int in range(_frames(2.0)):
		if _phase(id) != "recovery": return "actual recovery closed before the legitimate second ordinary tap"
		if float(_hero.get_threat_response_state().primary_cooldown_left_s) == 0.0 and Time.get_ticks_msec() - _last_primary_wall_ms > 280:
			return _ordinary_hit(id, "recovery")
		var reason: String = await _tick()
		if not reason.is_empty(): return reason
	return "bounded actual recovery never offered a second independent ordinary first tap"


func _next_pulse(cycle: int) -> String:
	var stop: float = _scheduler.get_clock() + WAIT_BUDGET_S
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		var ring: Dictionary = (_level.call("state") as Dictionary).ring
		var mechanism: CinderLaneMechanism = _level.get("mechanism") as CinderLaneMechanism
		if mechanism != null and mechanism.state().status == "running":
			var current: Dictionary = mechanism.state()
			if current.cycle != cycle or current.phase != "warning" or ring.stage != "pulse%d" % cycle or not ring.proofs.has(str(cycle)) or not ring.exchanges.has(str(cycle)): return "native pulse warning/cycle/current proof was skipped or replaced"
			_current_id = PULSE_ID
			_current_lease = _scheduler.reservation_state(String(current.reservation_id))
			if _current_lease.is_empty() or _current_lease.source_instance_id != mechanism.get_instance_id() or _current_lease.geometry.kind != "circle" or _current_lease.geometry.origin != mechanism.global_position: return "pulse is not a real native same-source fixed filled disk exchange"
			return ""
		if _scheduler.get_clock() >= stop: break
		var reason: String = await _tick()
		if not reason.is_empty(): return reason
	return "pulse%d did not genuinely admit within bounded native wait: " % cycle + _diagnostic()


func _wait_pulse_terminal(cycle: int) -> String:
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		var mechanism: CinderLaneMechanism = _level.get("mechanism") as CinderLaneMechanism
		if mechanism.state().status == "complete" and mechanism.state().cycle == cycle:
			_pulse_endings[str(cycle)] = {"clock_s": _scheduler.get_clock(), "instance_id": mechanism.get_instance_id()}
			return ""
		if mechanism.state().status == "cancelled": return "actual pulse cancelled; an old witness is not current permission"
		var reason: String = await _tick()
		if not reason.is_empty(): return reason
	return "actual pulse failed its finite completion"


func _settle_clear() -> String:
	# Real lethal input can follow the parent's completed tick. Observe the
	# next complete tick/FIFO shape retirement before testing its route signal.
	var settle_error: String = await _tick()
	if not settle_error.is_empty(): return settle_error
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		var ready: bool = _scheduler.reservations().is_empty()
		for id: String in _group:
			var source: Node3D = _all_sources[id]
			if not source.get("dead") or not (_level.call("state") as Dictionary).route.deaths.has(id): ready = false
			if not _is_stalker(id) and ((_source_state(id).playback as Dictionary).has("pending_delivery") or source.call("get_authored_cycle_terminal_receipt").is_empty()): ready = false
		if ready: return ""
		var reason: String = await _tick()
		if not reason.is_empty(): return reason
	return "real deaths/terminal delivery/leases did not settle for next actual entry"


func _tick() -> String:
	if paused: return "actual route cannot advance paused world"
	_barrier.waiting = true
	await _barrier.observed
	if paused: return "actual route paused before complete consumer boundary"
	var reason: String = String(_level.call("runtime_error"))
	if not reason.is_empty(): return reason
	if _scheduler.get_instance_id() != _scheduler_identity or _scheduler.get_clock() > ROUTE_BUDGET_S or _hero.dead or _hero.hp != _hero_hp or _hero.shells != _shells or not _exact(_hero.equipment.snapshot(), _kit) or not _exact(_hero.equipment.resolved_stats(), _stats) or _events.get("fired_blast", 0) != 0 or _events.get("route_contact", 0) != 0 or _events.get("pulse_hit", 0) != 0 or _events.get("equipment", 0) != 0 or _events.get("checkpoint", 0) != 0: return "continuous native clock/Hero resources/kit/no-contact/ordinary-only invariant changed"
	var state: Dictionary = _level.call("state")
	if not SAFE_RECT.has_point(Vector2(_hero.global_position.x, _hero.global_position.z)): return "actual native route left its continuous authored shore"
	for index: int in range(state.route.entries.size()):
		if _entry_samples.has(index): continue
		var receipt: Dictionary = state.route.entries[index]
		var body: CollisionShape3D = _hero.get_node("BodyCollision") as CollisionShape3D
		if index >= ROUTE_ENTRIES.size() or not body.shape is CapsuleShape3D or receipt.id != ROUTE_ENTRIES[index] or receipt.beat != ROUTE_BEATS[index] or receipt.clock_s != _scheduler.get_clock() or receipt.hero_position != [_hero.global_position.x, _hero.global_position.y, _hero.global_position.z] or receipt.capsule_radius != (body.shape as CapsuleShape3D).radius or body.global_position.z + float(receipt.capsule_radius) > ROUTE_Z[index]: return "entry lacks exact real capsule/clock/position teaching prefix"
		_entry_samples[index] = receipt.duplicate(true)
	for id: String in (_level.get("sources") as Dictionary):
		if not _all_sources.has(id):
			var installed: Node3D = (_level.get("sources") as Dictionary)[id]
			if not ROSTER.has(id) or installed.get("dead") or float(installed.get("hp")) != 36.0 or not installed.is_in_group("enemies"): return "new native recipient lacks canonical living HP36/id"
			_all_sources[id] = installed
			_expected_hp[id] = float(installed.get("hp"))
			_identities[id] = {"instance": installed.get_instance_id(), "transform": installed.global_transform, "definition": {} if _is_stalker(id) else installed.call("source_definition"), "profile": "" if _is_stalker(id) else installed.call("source_profile"), "world": {} if _is_stalker(id) else installed.call("prepared_world")}
			if _is_stalker(id): installed.connect("died", _on_stalker_route_death.bind(id))
			else:
				installed.connect("died", _death.bind(id))
				installed.connect("event_dispatched", _on_route_dispatch)
		var source: Node3D = _all_sources[id]
		if not is_instance_valid(source) or source.get_instance_id() != _identities[id].instance or float(source.get("hp")) != float(_expected_hp[id]): return "source changed/replaced HP outside an actual ordinary hit: " + id
		if not _is_stalker(id):
			if source.global_transform != _identities[id].transform or not _exact(source.call("source_definition"), _identities[id].definition) or not _exact(source.call("source_profile"), _identities[id].profile) or not _exact(source.call("prepared_world"), _identities[id].world): return "managed Echo fixed source/immutable recipe drift: " + id
			reason = _observe_generation(id)
			if not reason.is_empty(): return reason
		if source.get("dead"):
			if source.is_in_group("enemies") or float(source.get("hp")) != 0.0 or not state.route.deaths.has(id) or _source_deaths.get(id, 0) != 1 or state.route.deaths[id].source_position != [source.global_position.x, source.global_position.y, source.global_position.z]: return "retained ordinary tombstone/death receipt differs: " + id
			if _is_stalker(id) and ((source as CharacterBody3D).collision_layer != 0 or (source as CharacterBody3D).collision_mask != 0): return "real Stalker death retained collision authority"
	var held: Array[Dictionary] = _scheduler.reservations()
	for record: Dictionary in held:
		var id: String = _owner_id(record)
		if id.is_empty(): return "reservation lacks one real installed owner"
		if record.adapter.get("kind") == "authored_replay" and held.size() != 1: return "actual authored Echo lost honest exclusive lease against another source"
		if not _fixed_leases.has(String(record.id)):
			_fixed_leases[String(record.id)] = _fixed_record(record)
			_lease_phases[String(record.id)] = {}
			_travel[String(record.id)] = 0.0
		if not _exact(_fixed_leases[String(record.id)], _fixed_record(record)): return "held exact native geometry/deadline/source identity changed"
		var phase: String = _phase(id)
		_lease_phases[String(record.id)][phase] = true
		if _is_stalker(id):
			var actor: CharacterBody3D = _all_sources[id]
			if (_source_state(id).source as Dictionary).hit_consumed: return "actual moving contact was consumed despite ordinary no-immunity proof"
			if phase == "active": _travel[String(record.id)] = maxf(float(_travel[String(record.id)]), actor.global_position.distance_to(record.adapter.start))
			if phase == "recovery" and (actor.global_position.distance_to(record.adapter.planned_endpoint) > POINT_TOLERANCE or actor.velocity != Vector3.ZERO): return "real moving source failed stopped native endpoint"
	if not _current_id.is_empty():
		var record: Dictionary = _scheduler.replay_reservation_state(String(_current_lease.id)) if not _is_stalker(_current_id) and _current_id != PULSE_ID else _scheduler.reservation_state(String(_current_lease.id))
		if record.is_empty(): return "actual selected exchange cancelled/expired; stale proof cannot authorize later actions"
	if state.ring.installed:
		var mechanism: CinderLaneMechanism = _level.get("mechanism") as CinderLaneMechanism
		if _mechanism_identity == 0:
			_mechanism_identity = mechanism.get_instance_id()
			_mechanism_transform = mechanism.global_transform
			mechanism.hit_resolved.connect(func(_actor: String, _cycle: int, _receipt: Dictionary) -> void: _event("pulse_hit"))
		if mechanism.get_instance_id() != _mechanism_identity or mechanism.global_transform != _mechanism_transform or mechanism.state().cycle > 2: return "resonant source moved/replaced or invented a third pulse"
		for receipt: Dictionary in state.ring.history:
			var key: String = String(receipt.id) + ":" + str(receipt.clock_s)
			_ring_seen[key] = receipt.duplicate(true)
	if state.completed and (state.route.entries.size() != 6 or state.route.deaths.size() != 7 or state.ring.stage != "terminal" or not held.is_empty()): return "completion was earned before all canonical real deaths and terminal pulse history"
	return ""


func _observe_generation(id: String) -> String:
	var source: Node3D = _all_sources[id]
	if source.call("source_clock") != _scheduler.get_clock(): return "managed source lost the one continuous native Scheduler clock: " + id
	var generation: int = int(source.call("get_authored_cycle_generation"))
	var terminal: Dictionary = source.call("get_authored_cycle_terminal_receipt")
	if not terminal.is_empty():
		var key: String = "%s:%d" % [id, generation]
		if _terminal_history.has(key) and not _exact(_terminal_history[key], terminal): return "original terminal scalar/history changed: " + id
		_terminal_history[key] = terminal.duplicate(true)
	var previous: int = int(_generation_seen.get(id, 0))
	if previous == 0:
		if generation != 1 or source.call("source_phase") != "cycle_ready" or not terminal.is_empty(): return "installed managed source did not earn only genuine initial ready"
	elif generation != previous:
		var key: String = "%s:%d" % [id, previous]
		if generation != previous + 1 or not _terminal_history.has(key) or _scheduler.get_clock() < float(_terminal_history[key].exchange.cooldown_until_s) or source.call("source_phase") != "cycle_ready" or not terminal.is_empty() or source.get("dead"): return "next native generation not earned by original terminal/cooldown on survivor"
		print("GENERATION: ", id, " ", previous, "→", generation, " native_clock=", _scheduler.get_clock())
	_generation_seen[id] = generation
	return ""


func _fixed_record(record: Dictionary) -> Dictionary:
	var value: Dictionary = {"source_instance_id": record.source_instance_id, "geometry": record.geometry.duplicate(true), "adapter_kind": record.adapter.get("kind", "")}
	for key: String in FIXED_DEADLINES: value[key] = record[key]
	if record.adapter.get("kind") == "lunge": value.merge({"start": record.adapter.start, "endpoint": record.adapter.planned_endpoint})
	return value


func _owner_id(record: Dictionary) -> String:
	var mechanism: Node3D = _level.get("mechanism") as Node3D
	if is_instance_valid(mechanism) and record.source_instance_id == mechanism.get_instance_id(): return PULSE_ID
	for id: String in _all_sources:
		if record.source_instance_id == (_all_sources[id] as Node3D).get_instance_id(): return id
	return ""


func _phase(id: String) -> String:
	if id == PULSE_ID: return String((_level.get("mechanism") as CinderLaneMechanism).state().phase)
	return String((_all_sources[id].call("state") as Dictionary).phase) if _is_stalker(id) else String(_all_sources[id].call("source_phase"))


func _source_state(id: String) -> Dictionary:
	return (_level.call("state") as Dictionary).sources[id]


func _is_stalker(id: String) -> bool:
	return id in ["l3-threshold-stalker", FINAL_STALKER]


func _group_dead() -> bool:
	for id: String in _group:
		if not _all_sources.has(id) or not bool((_all_sources[id] as Node3D).get("dead")): return false
	return not _group.is_empty()


func _death(id: String) -> void:
	_source_deaths[id] = int(_source_deaths.get(id, 0)) + 1


func _on_stalker_route_death(_position: Vector3, id: String) -> void:
	_death(id)


func _on_route_dispatch(_event_data: Dictionary, receipt: Dictionary) -> void:
	if receipt.get("contact", false): _event("route_contact")


func _contact_route_exit() -> String:
	var state: Dictionary = _level.call("state")
	if not _level.is_completed() or state.exit_state != "available" or _events.get("completion", 0) != 1 or not _scheduler.reservations().is_empty(): return "actual all-clear did not earn one available contact exit"
	for _step: int in range(12):
		if (_level.call("state") as Dictionary).exit_state == "spent": break
		var reason: String = await _ready()
		if not reason.is_empty(): return reason
		var direction: Vector3 = Vector3(0, 0, -47) - _hero.global_position
		direction.y = 0.0
		reason = await _dash(direction.normalized(), {}, "real dry-threshold contact")
		if not reason.is_empty(): return reason
	await process_frame
	state = _level.call("state")
	if state.exit_state != "spent" or _events.get("exit", 0) != 1 or state.contact.is_empty() or _events.get("completion", 0) != 1: return "actual contact failed one deferred available→active→spent dispatch"
	var sample: Array = state.contact.hero_position
	var collision: CollisionShape3D = _hero.get_node("BodyCollision") as CollisionShape3D
	var radius: float = (collision.shape as CapsuleShape3D).radius
	if not EXIT_RECT.grow(-radius).has_point(Vector2(float(sample[0]), float(sample[2]))) or absf(float(sample[1])) > 0.2: return "contact sample lacks whole actual capsule within dry threshold"
	var original: Dictionary = state.contact.duplicate(true)
	var reason: String = await _ready()
	if reason.is_empty(): reason = await _dash(Vector3.BACK, {}, "spent threshold leave")
	if reason.is_empty(): reason = await _ready()
	if reason.is_empty(): reason = await _dash(Vector3.FORWARD, {}, "spent threshold return")
	if not reason.is_empty(): return reason
	return "" if _events.get("exit", 0) == 1 and _events.get("completion", 0) == 1 and _exact(original, (_level.call("state") as Dictionary).contact) else "spent contact duplicated completion/exit or replaced its original sample"


func _route_final_error(count: int) -> String:
	var state: Dictionary = _level.call("state")
	var expected_sources: int = 7 if _full_route else 5
	if state.route.entries.size() != count or state.route.deaths.size() != expected_sources or _all_sources.size() != expected_sources or _source_deaths.size() != expected_sources: return "selected exact route entry/death scope incomplete"
	for id: String in _all_sources:
		if not (_all_sources[id] as Node3D).get("dead") or float(_expected_hp[id]) != 0.0 or _source_deaths[id] != 1: return "real retained ordinary tombstone count differs"
	var stages: Array[String] = []
	for receipt: Dictionary in state.ring.history: stages.append(String(receipt.id))
	if stages != ["pulse1_wait", "pulse1", "echo_wait", "echo", "pulse2_wait", "pulse2", "terminal"] or _pulse_records.size() != 2 or _pulse_endings.size() != 2 or not _scheduler.reservations().is_empty(): return "actual ring history differs from one first pulse/one own Echo/one same-source second pulse"
	var source: Node3D = _all_sources[RESONANT_ID]
	var terminal: Dictionary = source.call("get_authored_cycle_terminal_receipt")
	if terminal.is_empty() or terminal.outcome != ("complete" if _full_route else "cancelled") or source.call("get_authored_cycle_generation") != 1: return "selected genuine surviving or real recovery-death terminal branch was not retained"
	if int(_generation_seen.get("l3-first-echo", 0)) < 2: return "ordinary first Echo clear omitted surviving original-cooldown-earned next generation"
	if _full_route and _first_final_primary != (FINAL_ECHO if _priority == "echo" else FINAL_STALKER): return "actual first final ordinary target differs from deliberate chosen approach"
	if not _full_route and (state.completed or _events.get("completion", 0) != 0 or _events.get("exit", 0) != 0): return "resonant-only frontier falsely completed full level"
	var stored: Array[Dictionary] = _hero.get_world_action_records()
	if _actions.is_empty() or not _exact(_actions.slice(maxi(0, _actions.size() - stored.size())), stored): return "actual bounded completed action tail differs from observed full route actions"
	for action: Dictionary in _actions:
		if action.kind not in ["dash", "primary"] or not _exact(action.equipment_ids, _kit): return "route used unsupported action or changed equipment"
	return "" if _hero.hp == _hero_hp and _hero.shells == _shells and _events.get("fired_blast", 0) == 0 and _events.get("checkpoint", 0) == 0 and int(_game.get("cores")) == 0 and int(_game.get("kills")) == 0 and get_nodes_in_group("practice_targets").is_empty() and get_nodes_in_group("lab_weapons").is_empty() else "route altered resources or acquired unrelated pickup/reward/state"


func _close_route() -> void:
	var refs: Array[WeakRef] = []
	for source: Node in _all_sources.values():
		if is_instance_valid(source): refs.append(weakref(source))
	var mechanism: Node = _level.get("mechanism") as Node if is_instance_valid(_level) else null
	if is_instance_valid(mechanism): refs.append(weakref(mechanism))
	await _close()
	var freed: bool = true
	for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
	_expect(freed and get_nodes_in_group("required_cues").is_empty(), "every actual installed route owner/mechanism/cue is disposed")


func _diagnostic() -> String:
	return str({"clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else -1.0, "group": _group, "current_id": _current_id, "current_lease": _current_lease, "hero": _hero.get_threat_response_state() if is_instance_valid(_hero) else {}, "actual_parent": _level.call("state") if is_instance_valid(_level) else {}, "events": _events})


func _finish() -> void:
	print("Owned Mirror Sea route: %d checks; failures: %d. %s; no whole-save/full-art/production/OS-human acceptance." % [_checks, _failures, "all6/seven ordinary deaths/contact priority=" + _priority if _full_route else "first5/real recovery-death between same-source pulses"])
	quit(0 if _failures == 0 else 1)
