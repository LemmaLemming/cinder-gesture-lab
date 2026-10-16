class_name CinderAct3CrystalmanRuleRoom
extends CinderLevel
## DRAFT V2, UNEXECUTED two-slot extension; original finite recovery retained.
## Separate one/two-slot selectors; no campaign phase progression or transport.

const Gate = preload("res://scripts/combat/replay_capture_gate.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Playback = preload("res://scripts/combat/replay_playback.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const Interaction = preload("res://scripts/cues/interaction_cue.gd")
const CueMesh = preload("res://scripts/cues/cue_mesh.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const OWNER_ID: String = "crystalman-rule/capture"
const ACTOR_ID: String = "hero"
const SOURCE_EPOCH: String = "A3-L5/one-slot-rule"
const ENCOUNTER_ID: String = "A3-L5/crystalman-rule"
const FLOOR_RECT: Rect2 = Rect2(-6.0, -8.0, 12.0, 16.0)
const TETHER_POSITION: Vector3 = Vector3(-0.7, 0.0, -0.4)
const REJECTION_DISPLAY_S: float = 0.6
const TRANSPORT_UNIMPLEMENTED: String = "Crystalman rule prototype has no whole-parent transport"

@export_range(1, 2, 1) var capture_slots: int = 1
const TWO_SLOT_GAP_S: float = 1.0

signal recording_rejected(reason: String)
signal recording_joined(receipt: Dictionary)
signal tether_severed(receipt: Dictionary)

class LowTether extends Node3D:
	var custodian: WeakRef
	func receive_attack(request: Dictionary) -> Dictionary:
		var room: Node = custodian.get_ref() if custodian != null else null
		return room.call("receive_tether_attack", request) if is_instance_valid(room) else {"accepted": false}

var capture_gate: CinderReplayCaptureGate
var threat_scheduler: CinderThreatScheduler
var playback: CinderReplayPlayback
var tether: Node3D
var last_configuration_error: String = ""
var last_rejection: String = ""
var last_camera_error: String = ""
var phase: String = "settling"

var _floor: Dictionary = {}
var _floor_body: StaticBody3D
var _capture_context: Dictionary = {}
var _sequence: Dictionary = {}
var _native_sequence: Dictionary = {}
var _projection: Dictionary = {}
var _proof: Dictionary = {}
var _lease: Dictionary = {}
var _join_receipt: Dictionary = {}
var _last_rejected_capture: Dictionary = {}
var _forecast_points: Array = []
var _tether_visual: MeshInstance3D
var _tether_material: StandardMaterial3D
var _tether_cue: CinderInteractionCue
var _opening_cue_mesh: ArrayMesh
var _rejection_marker: MeshInstance3D
var _capture_frame: Array[MeshInstance3D] = []
var _active: bool = false
var _configured: bool = false
var _queued: bool = false
var _transaction_busy: bool = false
var _operation: String = ""
var _locked: bool = false
var _cleared: bool = false
var _rejections: int = 0
var _joins: int = 0
var _tether_hits: int = 0
var _generation: int = 0
var _slot_capacity: int = 1
var _capture_epoch: String = SOURCE_EPOCH
var _slot_markers: Array[Node3D] = []
var _slot_marker_materials: Array[StandardMaterial3D] = []
var _rearm_after_clock_s: float = 0.0
var _exposure_from_s: float = 0.0
var _exposure_until_s: float = 0.0


func _ready() -> void:
	_slot_capacity = capture_slots
	if _slot_capacity not in [1, 2]:
		last_configuration_error = "Prototype capture capacity must be one or two"
	_capture_epoch = SOURCE_EPOCH if _slot_capacity == 1 else "A3-L5/two-slot-rule"
	# Scheduler/Player precede this guard; canonical Playback delivers at110.
	process_physics_priority = 100
	_build_floor()
	_build_tether()
	_build_recording_frame()
	_build_slot_markers()
	threat_scheduler = Scheduler.new()
	threat_scheduler.name = "CrystalmanRuleScheduler"
	add_child(threat_scheduler)
	capture_gate = Gate.new()
	capture_gate.name = "SoleCompletedActionCustodian"
	add_child(capture_gate)
	capture_gate.gate_failed.connect(_on_gate_failed)


func _build_floor() -> void:
	_floor_body = StaticBody3D.new()
	_floor_body.name = "PermanentFirmFloor"
	_floor_body.collision_layer = 1
	_floor_body.collision_mask = 0
	add_child(_floor_body)
	_floor_body.position = Vector3(0, -0.5, 0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(12, 1, 16)
	var solid := CollisionShape3D.new()
	solid.name = "Solid"
	solid.shape = shape
	_floor_body.add_child(solid)
	_floor = {"collision": solid, "safe_rect": FLOOR_RECT}
	_box(_floor_body, "ObsidianPrototypeFloor", Vector3.ZERO, shape.size, Color(0.075, 0.055, 0.11))
	# Fixed Box boundaries shorten real dashes; no floor/collider ever moves.
	_wall("WestBoundary", Vector3(-5.85, 0.6, 0), Vector3(0.3, 1.2, 16))
	_wall("EastBoundary", Vector3(5.85, 0.6, 0), Vector3(0.3, 1.2, 16))
	_wall("NorthBoundary", Vector3(0, 0.6, -7.85), Vector3(12, 1.2, 0.3))
	_wall("SouthBoundary", Vector3(0, 0.6, 7.85), Vector3(12, 1.2, 0.3))


func _wall(label: String, point: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	body.position = point
	var solid := CollisionShape3D.new()
	solid.name = "Solid"
	var shape := BoxShape3D.new()
	shape.size = size
	solid.shape = shape
	body.add_child(solid)
	_box(body, "VisibleFixedEdge", Vector3.ZERO, size, Color(0.13, 0.09, 0.18))


func _build_tether() -> void:
	var target := LowTether.new()
	target.name = "LowFixedExternalTether"
	target.custodian = weakref(self)
	add_child(target)
	target.position = TETHER_POSITION
	target.add_to_group("environment_attack_targets")
	tether = target
	_tether_visual = _box(tether, "RootedCrystalPrototype", Vector3(0, 0.24, 0), Vector3(0.5, 0.48, 0.5), Color(0.33, 0.30, 0.39))
	_tether_material = _tether_visual.material_override as StandardMaterial3D
	_tether_cue = Interaction.new()
	_tether_cue.name = "SharedOrdinaryAttackCue"
	tether.add_child(_tether_cue)
	# Forecast the future available marker from the same shared native mesh
	# factory, without showing an available cue on the closed tether.
	_opening_cue_mesh = CueMesh.interaction_mesh("available", "attack")


func _build_recording_frame() -> void:
	# Quiet prototype recording frame, no input area, damage or collider.
	for x: float in [-0.85, 0.85]:
		_capture_frame.append(_box(self, "RecordingFrameX" + str(x), Vector3(x, 0.02, 0), Vector3(0.045, 0.035, 1.7), Color(0.36, 0.30, 0.44)))
	for z: float in [-0.85, 0.85]:
		_capture_frame.append(_box(self, "RecordingFrameZ" + str(z), Vector3(0, 0.02, z), Vector3(1.7, 0.035, 0.045), Color(0.36, 0.30, 0.44)))
	_rejection_marker = _box(self, "VisibleRejectedRecording", Vector3(0, 0.055, 0), Vector3(0.5, 0.05, 0.13), Color(0.80, 0.33, 0.25))
	_rejection_marker.rotation.y = PI / 4.0
	_rejection_marker.visible = false


func _build_slot_markers() -> void:
	if _slot_capacity != 2: return
	# Passive native mesh digits only. No input, collider, target group or clock.
	for index: int in range(2):
		var number := Node3D.new()
		number.name = "NumberedCaptureSlot" + str(index + 1)
		add_child(number)
		_slot_markers.append(number)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_slot_marker_materials.append(material)
		var strokes: Array[Dictionary] = []
		if index == 0:
			strokes = [{"at": Vector3(0, 0, 0), "size": Vector3(0.055, 0.035, 0.30)}]
		else:
			strokes = [{"at": Vector3(0, 0, -0.15), "size": Vector3(0.25, 0.035, 0.055)}, {"at": Vector3(0.10, 0, -0.075), "size": Vector3(0.055, 0.035, 0.15)}, {"at": Vector3(0, 0, 0), "size": Vector3(0.25, 0.035, 0.055)}, {"at": Vector3(-0.10, 0, 0.075), "size": Vector3(0.055, 0.035, 0.15)}, {"at": Vector3(0, 0, 0.15), "size": Vector3(0.25, 0.035, 0.055)}]
		for stroke: Dictionary in strokes:
			var visual: MeshInstance3D = _box(number, "DigitStroke", stroke.at, stroke.size, Color(0.36, 0.30, 0.44))
			visual.material_override = material
	_position_slot_markers_for_capture()


func _position_slot_markers_for_capture() -> void:
	for index: int in range(_slot_markers.size()):
		_slot_markers[index].position = Vector3(-0.4 if index == 0 else 0.4, 0.065, 0.60)


func _position_slot_markers_for_sequence() -> void:
	# Label the immutable original route start. This never changes capture data.
	for index: int in range(_slot_markers.size()):
		var route: Array = _native_sequence.timeline.slots[index].route
		_slot_markers[index].global_position = route[0].position + Vector3(0.65, 0.065, 0.15)


func _update_slot_markers() -> void:
	if _slot_markers.is_empty(): return
	var sealed: int = int(capture_gate.state().capture.sealed) if is_instance_valid(capture_gate) else 0
	for index: int in range(_slot_markers.size()):
		var shade := Color(0.36, 0.30, 0.44)
		if phase in ["recording", "framing"] and index < sealed:
			shade = Color(0.55, 0.50, 0.62)
		elif phase in ["warning", "lock", "active", "exposed", "severed"] and not _native_sequence.is_empty():
			var slot: Dictionary = _native_sequence.timeline.slots[index]
			var elapsed: float = threat_scheduler.get_clock() - float(_lease.adapter.timeline_origin_s) if not _lease.is_empty() else 0.0
			if elapsed >= float(slot.end_s): shade = Color(0.23, 0.20, 0.27)
			elif elapsed >= float(slot.from_s): shade = Color(0.67, 0.61, 0.76)
			else: shade = Color(0.55, 0.50, 0.62)
		elif phase in ["spent", "rejected"]:
			shade = Color(0.23, 0.20, 0.27)
		_slot_marker_materials[index].albedo_color = shade


func _box(parent: Node3D, label: String, point: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = point
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_color = color
	visual.material_override = material
	parent.add_child(visual)
	return visual


func _on_enter_level() -> void:
	if not last_configuration_error.is_empty(): return
	var profile: String = shared_shell.call("get_difficulty_preference") if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, 1):
		last_configuration_error = threat_scheduler.last_error
		return
	_active = true
	_update_guidance()


func _physics_process(_delta: float) -> void:
	if not _active or not is_instance_valid(hero) or _transaction_busy:
		return
	if hero.dead:
		_cancel_consumer("crystalman_actual_actor_died")
		return
	if phase in ["settling", "rejected"]:
		if hero.get_threat_response_state().stable and hero.get_world_action_clock() >= _rearm_after_clock_s:
			_queue_barrier("arm")
	elif phase in ["recording", "framing"]:
		var capture: Dictionary = capture_gate.state().capture
		if int(capture.allocated) == _slot_capacity and int(capture.sealed) == _slot_capacity and int(capture.pending) == 0 and not capture.has_dash_candidate and hero.get_threat_response_state().stable:
			_queue_barrier("join")
	elif not _cleared and is_instance_valid(playback):
		_guard_live_exchange()
	_update_guidance()


func _queue_barrier(operation: String) -> void:
	if _queued or not _active:
		return
	_queued = true
	_operation = operation
	_drain_barrier.call_deferred()


func _drain_barrier() -> void:
	_queued = false
	if not _active or _transaction_busy or get_tree().paused or not is_instance_valid(hero):
		return # A real menu/background pause is never overridden.
	_transaction_busy = true
	get_tree().paused = true
	match _operation:
		"arm": _arm_at_barrier()
		"join": _join_at_barrier()
		"reject": _reject_at_barrier(last_rejection)
		"finish": _finish_at_barrier()
	# No helper yields: the caller's actual actor has not received a tick.
	if is_inside_tree(): get_tree().paused = false
	_transaction_busy = false
	_update_guidance()


func _arm_at_barrier() -> void:
	if not _configured:
		if not capture_gate.configure(OWNER_ID, ACTOR_ID, hero, _capture_epoch):
			last_configuration_error = capture_gate.last_error
			return
		_configured = true
	if not capture_gate.arm(_slot_capacity):
		last_configuration_error = capture_gate.last_error
		return
	_generation = int(capture_gate.state().capture.generation)
	var floors: Dictionary = Footprint.floor_signature(get_parent() as Node3D, [_floor])
	if not floors.get("accepted", false):
		_reject_at_barrier(String(floors.get("reason", "Unsupported floor")))
		return
	_capture_context = {"source_epoch": _capture_epoch, "generation": _generation, "capture_collision_fingerprint": threat_scheduler.pure_collision_fingerprint(get_parent() as Node3D), "capture_floor_signature": floors.signature}
	_rejection_marker.visible = false
	_position_slot_markers_for_capture()
	phase = "recording"


func _authored() -> Dictionary:
	# Provisional first-room budgets; original resolved action durations remain.
	return {"recognition_s": 0.25, "warning_s": 1.3, "locked_lead_s": 1.5, "inter_echo_gap_s": TWO_SLOT_GAP_S if _slot_capacity == 2 else 0.0, "final_recovery_s": 3.5, "tether_position": tether.global_position}


func _join_at_barrier() -> void:
	if not capture_gate.synchronize():
		_reject_at_barrier(capture_gate.last_error)
		return
	var gate_before: Dictionary = capture_gate.snapshot_state()
	var actor_before: Dictionary = hero.snapshot_state()
	if gate_before.is_empty() or actor_before.is_empty():
		last_configuration_error = "No actual paused Player/gate boundary"
		return
	var proposed: Dictionary = capture_gate.prepare_sequence("crystalman-rule/sequence-" + str(_generation), _authored())
	if proposed.is_empty():
		_last_rejected_capture = gate_before.capture.duplicate(true)
		_reject_at_barrier(capture_gate.last_error)
		return
	gate_before = capture_gate.snapshot_state()
	var reader = Sequence.new()
	if not reader.restore_state(proposed, _capture_epoch, _generation):
		_reject_at_barrier(reader.last_snapshot_error)
		return
	_sequence = proposed.duplicate(true)
	_native_sequence = reader.state()
	_position_slot_markers_for_sequence()
	_projection = Footprint.plan(threat_scheduler, proposed, get_parent() as Node3D, [_floor], _capture_context)
	if not _projection.get("accepted", false):
		_reject_at_barrier(String(_projection.get("reason", "Projection rejected")))
		return
	playback = Playback.new()
	playback.name = "FiniteCapturedApparition" + str(_generation)
	add_child(playback)
	playback.global_position = tether.global_position
	if not playback.configure("crystalman-rule/owner-" + str(_generation), proposed, _capture_epoch, _generation, "act3_traveller"):
		_reject_at_barrier(playback.last_error)
		return
	# Shared whole proofs reject paused trees. This synchronous no-yield interval
	# advances no Player, Gate or Scheduler clock and emits no Player action.
	get_tree().paused = false
	var response: Dictionary = combat_response()
	var preflight: Dictionary = Witness.new().prove(threat_scheduler, proposed, response, scheduler_context())
	if not preflight.get("accepted", false):
		get_tree().paused = true
		_reject_at_barrier(String(preflight.get("reason", "Complete response rejected")))
		return
	_proof = preflight.duplicate(true)
	if not _build_forecast_points():
		get_tree().paused = true
		_reject_at_barrier(last_camera_error)
		return
	var fit: Dictionary = shared_shell.call("camera_framing_plan", camera_framing_points(), hero.global_position)
	last_camera_error = shared_shell.call("camera_framing_error", camera_framing_points())
	if not fit.get("accepted", false):
		get_tree().paused = true
		_reject_at_barrier(String(fit.get("reason", "Whole trace cannot fit")))
		return
	if not last_camera_error.is_empty():
		# A possible future fit is not current visibility authority. Keep only
		# display corners; discard this proposal and prepare a fresh current one
		# after the shared camera/HUD has framed them on a normal process frame.
		get_tree().paused = true
		capture_gate.discard_preparation()
		playback.free()
		playback = null
		phase = "framing"
		return
	var admission: Dictionary = threat_scheduler.request_replay(playback, proposed, response, scheduler_context())
	get_tree().paused = true
	if not admission.get("accepted", false):
		_reject_at_barrier(String(admission.get("reason", "Admission rejected")))
		return
	_lease = admission.reservation.duplicate(true)
	_proof = admission.proof.duplicate(true)
	var actor_after_admission: Dictionary = hero.snapshot_state()
	var gate_after_admission: Dictionary = capture_gate.snapshot_state()
	if not _same(actor_before, actor_after_admission) or not _same(gate_before, gate_after_admission):
		_reject_at_barrier("Actual frozen actor/capture changed before retirement")
		return
	var consumed: Dictionary = capture_gate.consume_sequence(proposed)
	if not consumed.get("accepted", false) or not String(consumed.get("reason", "")).is_empty():
		_reject_at_barrier(String(consumed.get("reason", "Retirement rejected")))
		return
	var actor_after_consumption: Dictionary = hero.snapshot_state()
	if not _same(actor_before, actor_after_consumption):
		_reject_at_barrier("Actual actor changed across complete retirement")
		return
	var gate_after_consumption: Dictionary = capture_gate.snapshot_state()
	_join_receipt = {"prepared_actor_sha256": gate_before.prepared_actor_sha256, "after_admission_actor_sha256": gate_after_admission.actor_sha256, "after_consumption_actor_sha256": gate_after_consumption.actor_sha256, "retirement": consumed.retirement.duplicate(true), "actor_unchanged": true, "actor_clock_s": hero.get_world_action_clock(), "bound_before_tick": false}
	# Close recording after its single retirement. Apparition is visual only;
	# later real player gestures cannot create a hidden extra capture slot.
	if not capture_gate.cancel("one finite recording transferred to replay"):
		_reject_at_barrier(capture_gate.last_error)
		return
	# Outside every Gate callback, resume and bind the fresh unarmed preview
	# immediately. No await, actor movement, input, clock advance or raw capture.
	get_tree().paused = false
	if not playback.bind_projected(threat_scheduler, String(_lease.id), {ACTOR_ID: hero}, [_floor], _projection, _capture_context):
		get_tree().paused = true
		_reject_at_barrier(playback.last_error)
		return
	get_tree().paused = true
	if hero.get_world_action_clock() != float(_join_receipt.actor_clock_s) or not _same(actor_before, hero.snapshot_state()):
		_reject_at_barrier("Physical binding crossed an actual Player tick")
		return
	_join_receipt.bound_before_tick = true
	_joins += 1
	_locked = false
	phase = "warning"
	recording_joined.emit(_join_receipt.duplicate(true))


func scheduler_context() -> Dictionary:
	return {"world_root": get_parent() as Node3D, "source_epoch": _capture_epoch, "generation": _generation, "capture_collision_fingerprint": _capture_context.capture_collision_fingerprint}


func combat_response() -> Dictionary:
	var response: Dictionary = hero.get_threat_response_state()
	var directions: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]: directions.append(Vector3(x, 0, z).normalized())
	response.merge({"world_revision": 1, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [_floor]})
	return response


func _guard_live_exchange() -> void:
	if String(playback.state().status) == "cancelled":
		last_rejection = String(playback.state().reason)
		_queue_barrier("reject")
		return
	last_camera_error = shared_shell.call("camera_framing_error", camera_framing_points())
	if not last_camera_error.is_empty():
		_cancel_consumer("crystalman_actual_current_view_unreadable")
		last_rejection = last_camera_error
		_queue_barrier("reject")
		return
	var clock: float = threat_scheduler.get_clock()
	if not _locked and clock >= float(_lease.lock_from_s):
		var answer: Dictionary = threat_scheduler.commit_replay(String(_lease.id), combat_response())
		if not answer.get("accepted", false):
			last_rejection = String(answer.get("reason", "Actual lock rejected"))
			_cancel_consumer("crystalman_actual_lock_rejected")
			_queue_barrier("reject")
			return
		_lease = answer.reservation.duplicate(true)
		_proof = answer.proof.duplicate(true)
		_locked = true
		if not _build_forecast_points():
			_cancel_consumer("crystalman_required_native_forecast_missing")
			last_rejection = last_camera_error
			_queue_barrier("reject")
			return
		var origin: float = float(_lease.adapter.timeline_origin_s)
		_exposure_from_s = maxf(origin + float(_native_sequence.timeline.tether_from_s), float(_lease.active_until_s)) + threat_scheduler.TIME_MARGIN
		_exposure_until_s = origin + float(_native_sequence.timeline.tether_until_s)
		# Recheck the actual current view of the freshly selected whole route.
		last_camera_error = shared_shell.call("camera_framing_error", camera_framing_points())
		if not last_camera_error.is_empty():
			_cancel_consumer("crystalman_actual_lock_route_unreadable")
			last_rejection = last_camera_error
			_queue_barrier("reject")
			return
	if not _locked:
		phase = "warning"
	elif clock < float(_lease.active_from_s):
		phase = "lock"
	elif clock < _exposure_from_s:
		phase = "active"
	elif clock < _exposure_until_s:
		if phase != "exposed":
			_tether_material.albedo_color = Color(0.79, 0.89, 0.56)
			_tether_cue.present("available", "attack")
		phase = "exposed"
	else:
		_cancel_consumer("crystalman_finite_opening_expired")
		last_rejection = "The finite opening closed; choose a fresh route"
		_queue_barrier("reject")


func receive_tether_attack(request: Dictionary) -> Dictionary:
	var result: Dictionary = {"accepted": false, "tether_id": "crystalman-rule/low-tether"}
	if not _active or _transaction_busy or get_tree().paused or _cleared or phase != "exposed" or not _locked or not is_instance_valid(playback) or String(playback.state().status) != "running" or request.get("origin") != "player_direct" or request.get("kind") != "primary":
		return result
	var clock: float = threat_scheduler.get_clock()
	if clock < _exposure_from_s or clock >= _exposure_until_s or not threat_scheduler.replay_reservation_error(String(_lease.id)).is_empty():
		return result
	# Routed input may arrive after the last physics guard/camera shake.
	last_camera_error = shared_shell.call("camera_framing_error", camera_framing_points())
	if not last_camera_error.is_empty():
		last_rejection = last_camera_error
		_queue_barrier("reject")
		return result
	# Shared Player checked ordinary range/cone/scenery LOS before this separate
	# environment channel. No fabricated HP/hit/reload/perk result is returned.
	_cleared = true
	_tether_hits += 1
	phase = "severed"
	tether.remove_from_group("environment_attack_targets")
	_tether_visual.scale.y = 0.2
	_tether_cue.present("active", "attack")
	result.accepted = true
	result["clock_s"] = clock
	result["generation"] = _generation
	tether_severed.emit(result.duplicate(true))
	_queue_barrier("finish")
	return result


func _finish_at_barrier() -> void:
	# All attacks have ended before the ordinary opening. Release is immediate;
	# retain the original finite recovery/clock/profile for honest completion
	# and paired snapshots. This is never a progression waiting condition.
	# Normal level disposal still cancels/ends the whole native unit.
	_tether_cue.present("spent", "attack")
	phase = "spent"


func _reject_at_barrier(reason: String) -> void:
	get_tree().paused = true
	_cancel_consumer("crystalman_recording_rejected")
	if is_instance_valid(playback):
		playback.free()
		playback = null
	if _configured and not capture_gate.cancel(reason if not reason.is_empty() else "Recording rejected visibly"):
		last_configuration_error = capture_gate.last_error
	last_rejection = reason
	_rejections += 1
	_rearm_after_clock_s = hero.get_world_action_clock() + REJECTION_DISPLAY_S
	_lease.clear()
	_sequence.clear()
	_native_sequence.clear()
	_projection.clear()
	_proof.clear()
	_forecast_points.clear()
	_locked = false
	_exposure_from_s = 0.0
	_exposure_until_s = 0.0
	_tether_material.albedo_color = Color(0.33, 0.30, 0.39)
	_tether_cue.clear()
	_rejection_marker.visible = true
	_position_slot_markers_for_capture()
	phase = "rejected"
	recording_rejected.emit(reason)


func _cancel_consumer(reason: String) -> void:
	if is_instance_valid(playback) and String(playback.state().status) == "running": playback.cancel(reason)
	if not _lease.is_empty(): threat_scheduler.cancel(String(_lease.id), reason)


func _on_gate_failed(reason: String) -> void:
	# Observation only while Gate's transaction guard remains held.
	last_rejection = reason
	if not _transaction_busy: _queue_barrier("reject")


func _build_forecast_points() -> bool:
	_forecast_points.clear()
	var route_cloud: Array = []
	var actor_art: Sprite3D = playback.get_apparition() if is_instance_valid(playback) else null
	var art_corners: Array = shared_shell.call("camera_billboard_points", actor_art) if actor_art != null else []
	if art_corners.is_empty():
		last_camera_error = "Actual shared captured Traveller artwork bounds unavailable"
		return false
	var art_origin: Vector3 = playback.get_apparition_root().global_position if is_instance_valid(playback) else Vector3.ZERO
	for slot: Dictionary in _native_sequence.get("timeline", {}).get("slots", []):
		for sample: Dictionary in slot.route:
			for corner: Vector3 in art_corners: route_cloud.append(sample.position + corner - art_origin)
	_append_cloud_bounds(_forecast_points, route_cloud)
	for event: Dictionary in _projection.get("events", []):
		var b: Array = event.bounds
		_append_box(_forecast_points, Vector3(float(b[0]), float(event.floor_y), float(b[1])), Vector3(float(b[2]) - float(b[0]), 0.08, float(b[3]) - float(b[1])))
	var positions: Array = []
	for segment: Dictionary in _proof.get("path", []):
		for key: String in ["from", "to"]:
			var point: Variant = segment.get(key)
			if point is Vector3 and not positions.has(point): positions.append(point)
	# Translate the actual shared capsule, camera-facing artwork and contact
	# shadow to future proof positions; no physical proxy for the wider sprite.
	var current_camera: Camera3D = shared_shell.get("camera") as Camera3D
	var actual_hero_corners: Array = shared_shell.call("player_camera_framing_points_for", hero, current_camera)
	if actual_hero_corners.is_empty():
		last_camera_error = "Actual shared Hero capsule/artwork/shadow bounds unavailable"
		return false
	var hero_cloud: Array = []
	for point: Vector3 in positions:
		for corner: Vector3 in actual_hero_corners: hero_cloud.append(corner + point - hero.global_position)
	_append_cloud_bounds(_forecast_points, hero_cloud)
	return true


func _camera_framing_points() -> Array:
	# Main may request one final presentation frame after exit clears context.
	if not _active or not is_instance_valid(hero) or not is_instance_valid(shared_shell): return []
	var points: Array = _forecast_points.duplicate()
	_append_mesh(points, _tether_visual)
	var marker: MeshInstance3D = _tether_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	_append_mesh(points, marker)
	if marker != null and _opening_cue_mesh != null:
		_append_native_bounds(points, _opening_cue_mesh.get_aabb(), marker.global_transform)
	for frame: MeshInstance3D in _capture_frame: _append_mesh(points, frame)
	var number_cloud: Array = []
	for number_marker: Node3D in _slot_markers:
		for child: Node in number_marker.get_children():
			if child is MeshInstance3D: _append_mesh(number_cloud, child as MeshInstance3D)
	_append_cloud_bounds(points, number_cloud)
	if is_instance_valid(playback):
		var art: Sprite3D = playback.get_apparition()
		if art != null: points.append_array(shared_shell.call("camera_billboard_points", art))
		var cloud: Array = []
		for cue: Node3D in playback.get_cues():
			for child: Node in cue.get_children():
				if child is MeshInstance3D: _append_mesh(cloud, child as MeshInstance3D)
		_append_cloud_bounds(points, cloud)
	return points


func _append_mesh(points: Array, visual: MeshInstance3D) -> void:
	if not is_instance_valid(visual) or visual.mesh == null: return
	_append_native_bounds(points, visual.get_aabb(), visual.global_transform)


func _append_native_bounds(points: Array, bounds: AABB, transform: Transform3D) -> void:
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: points.append(transform * Vector3(x, y, z))


func _append_box(points: Array, low: Vector3, size: Vector3) -> void:
	for x: float in [low.x, low.x + size.x]:
		for y: float in [low.y, low.y + size.y]:
			for z: float in [low.z, low.z + size.z]: points.append(Vector3(x, y, z))


func _append_cloud_bounds(points: Array, cloud: Array) -> void:
	if cloud.is_empty(): return
	var low: Vector3 = cloud[0]
	var high: Vector3 = cloud[0]
	for point: Vector3 in cloud:
		low = low.min(point)
		high = high.max(point)
	_append_box(points, low, high - low)


func state() -> Dictionary:
	return {"phase": phase, "capture_slots": _slot_capacity, "configuration_error": last_configuration_error, "camera_error": last_camera_error, "last_rejection": last_rejection, "generation": _generation, "joins": _joins, "rejections": _rejections, "tether_hits": _tether_hits, "cleared": _cleared, "locked": _locked, "capture": capture_gate.state() if is_instance_valid(capture_gate) else {}, "sequence": _sequence.duplicate(true), "projection": _projection.duplicate(true), "proof": _proof.duplicate(true), "lease": _lease.duplicate(true), "join_receipt": _join_receipt.duplicate(true), "last_rejected_capture": _last_rejected_capture.duplicate(true), "exposure_from_s": _exposure_from_s, "exposure_until_s": _exposure_until_s, "playback": playback.state() if is_instance_valid(playback) else {}, "clock_s": threat_scheduler.get_clock()}


func floor_regions() -> Array:
	return [_floor.duplicate()]


func scheduler_bindings() -> Dictionary:
	var owners: Dictionary = {"captured-owner": playback} if is_instance_valid(playback) else {}
	return {"world_root": get_parent() as Node3D, "owners": owners, "actors": {ACTOR_ID: hero}, "floors": {"firm-floor": _floor}}


func _update_guidance() -> void:
	_update_slot_markers()
	if not last_configuration_error.is_empty(): objective_text = "RULE ROOM UNAVAILABLE"
	elif phase == "spent": objective_text = "THE LOCAL TETHER IS QUIET\nONE FINITE RECORDING RELEASED"
	elif phase in ["exposed", "severed"]: objective_text = "THE LOW TETHER IS EXPOSED\nRETURN AND USE YOUR PRIMARY"
	elif phase == "rejected": objective_text = "THAT RECORDING FADES SAFELY\nCHOOSE A FRESH DASH AND PRIMARY"
	elif phase in ["warning", "lock", "active"]: objective_text = "THE WORLD REPEATS YOUR ROUTE\nEVADE, THEN RETURN TO THE TETHER"
	elif _slot_capacity == 2 and phase in ["recording", "framing"]:
		var sealed: int = int(capture_gate.state().capture.sealed) if is_instance_valid(capture_gate) else 0
		objective_text = "RECORD %d OF 2\nCOMPLETE A DASH, THEN A PRIMARY" % mini(sealed + 1, 2)
	else: objective_text = "COMPOSE AN ESCAPE\nCOMPLETE A DASH, THEN A PRIMARY"


static func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


func snapshot_state() -> Dictionary:
	last_snapshot_error = TRANSPORT_UNIMPLEMENTED
	return {}


func snapshot_error(_snapshot: Dictionary) -> String:
	return TRANSPORT_UNIMPLEMENTED


func snapshot_error_with_player(_snapshot: Dictionary, _saved_player: Dictionary) -> String:
	return TRANSPORT_UNIMPLEMENTED


func restore_state(_snapshot: Dictionary) -> bool:
	last_snapshot_error = TRANSPORT_UNIMPLEMENTED
	return false


func _on_exit_level() -> void:
	_active = false
	_queued = false
	_cancel_consumer("crystalman_rule_room_exit")
	if is_instance_valid(threat_scheduler): threat_scheduler.end_encounter("crystalman_rule_room_exit")
