class_name CinderAct3CrystalmanCapturePhase
extends CinderLevel
## SOURCE-ONLY production current-unit candidate derived from sealed mechanics.
## Production-path external-floor candidate; native validation remains required.

const LocalCodec = preload("res://scripts/acts/act3/crystalman_capture_codec.gd")
const FrameArt = preload("res://scripts/acts/act3/crystalman_recorded_frame_art.gd")
const LocalValue = preload("res://scripts/campaign/snapshot_codec.gd")
const LocalDifficulty = preload("res://scripts/combat/difficulty.gd")
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

const EXTERNAL_FLOOR_API: String = "act3-crystalman-external-floor-1"
var _external_parent: Node3D
var _external_collision: CollisionShape3D
var _external_shape: BoxShape3D
var _external_signature: Array = []
var _tether_branches: Array[MeshInstance3D] = []
var _floor: Dictionary = {}
var _floor_body: StaticBody3D
var _capture_context: Dictionary = {}
var _sequence: Dictionary = {}
var _native_sequence: Dictionary = {}
var _framing_art: CinderAct3RecordedFrameArt
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
	if get_node_or_null("PlayerSpawn") == null:
		var marker := Marker3D.new()
		marker.name = "PlayerSpawn"
		marker.position = Vector3(0, 0.1, -2.7)
		add_child(marker)
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
	_external_parent = get_parent() as Node3D
	if not is_instance_valid(_external_parent) or not _external_parent.has_method("crystalman_capture_floor_binding"):
		last_configuration_error = "Exact production parent floor binding required"
		return
	var binding: Variant = _external_parent.call("crystalman_capture_floor_binding")
	if not binding is Dictionary or binding.get("api_revision") != EXTERNAL_FLOOR_API or binding.get("world_root") != _external_parent or binding.get("floor_id") != "firm-crystalman-route" or binding.get("safe_rect") != FLOOR_RECT:
		last_configuration_error = "Exact external-floor recipe required"
		return
	_external_collision = binding.get("collision") as CollisionShape3D
	_floor_body = _external_collision.get_parent() as StaticBody3D if is_instance_valid(_external_collision) else null
	_external_shape = _external_collision.shape as BoxShape3D if is_instance_valid(_external_collision) else null
	_floor = {"collision": _external_collision, "safe_rect": FLOOR_RECT}
	last_configuration_error = _external_floor_error()
	if not last_configuration_error.is_empty(): return
	var signature: Dictionary = Footprint.floor_signature(_external_parent, [_floor])
	if not signature.get("accepted", false):
		last_configuration_error = String(signature.get("reason", "Actual external floor refused"))
		return
	_external_signature = signature.signature.duplicate(true)

func _external_floor_error() -> String:
	if not is_instance_valid(_floor_body) or not is_instance_valid(_external_collision) or not is_instance_valid(_external_shape): return "Retained parent floor resources required"
	if not is_instance_valid(_external_parent) or get_parent() != _external_parent or not _external_parent.is_ancestor_of(_floor_body): return "Physical floor must remain outside child under parent"
	if _floor_body.global_transform != Transform3D(Basis.IDENTITY, Vector3(0, -0.5, 13)) or _floor_body.collision_layer != 1 or _floor_body.collision_mask != 0 or _external_collision.get_parent() != _floor_body or _external_collision.transform != Transform3D.IDENTITY or _external_collision.disabled or _external_collision.shape != _external_shape or _external_shape.size != Vector3(12, 1, 54): return "Exact immutable parent54m Box required"
	if _floor.get("collision") != _external_collision or _floor.get("safe_rect") != FLOOR_RECT: return "Original arena domain bound to actual parent Box required"
	var answer: Dictionary = Footprint.floor_signature(_external_parent, [_floor])
	if not answer.get("accepted", false): return String(answer.get("reason", "Actual floor refused"))
	return "" if _external_signature.is_empty() or _same(answer.signature, _external_signature) else "External floor signature changed within phase"

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
	for side: float in [-1.0, 1.0]:
		_tether_branches.append(_box(tether, "MineralArm" + str(side), Vector3(side * 0.19, 0.32, 0), Vector3(0.10, 0.40, 0.12), Color(0.46, 0.39, 0.57)))
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
	# Parent constructs this fresh unit at a paused boundary. Configure gen0 now
	# so interrupted settling has a complete genuine Gate recipient, no arm.
	if get_tree().paused and not _configured:
		if not capture_gate.configure(OWNER_ID,ACTOR_ID,hero,_capture_epoch):
			last_configuration_error = capture_gate.last_error
			return
		_configured = true
	_update_guidance()


func _physics_process(_delta: float) -> void:
	if not _active or not is_instance_valid(hero) or _transaction_busy:
		return
	if phase == "severed" and _cleared and not _queued:
		_queue_barrier("finish")
		return
	if hero.dead:
		_cancel_consumer("crystalman_actual_actor_died")
		return
	if phase in ["settling", "rejected"]:
		var actual_response: Dictionary = hero.get_threat_response_state()
		if float(actual_response.commitment_remaining_s) > 0.0 or not String(actual_response.pending_weapon_id).is_empty():
			_update_guidance()
			return
		if actual_response.stable and hero.get_world_action_clock() >= _rearm_after_clock_s:
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
	var floors: Dictionary = Footprint.floor_signature(actual_world_root(), [_floor])
	if not floors.get("accepted", false):
		_reject_at_barrier(String(floors.get("reason", "Unsupported floor")))
		return
	_capture_context = {"source_epoch": _capture_epoch, "generation": _generation, "capture_collision_fingerprint": threat_scheduler.pure_collision_fingerprint(actual_world_root()), "capture_floor_signature": floors.signature}
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
	_projection = Footprint.plan(threat_scheduler, proposed, actual_world_root(), [_floor], _capture_context)
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
		if not capture_gate.discard_preparation():
			_reject_at_barrier(capture_gate.last_error)
			return
		playback.free()
		playback = null
		# Public complete Gate records remain unconsumed/unretired. This static
		# native recipient owns no Playback, clock, collision or action listener.
		var frame_gate: Dictionary = capture_gate.snapshot_state()
		var frame_error: String = capture_gate.snapshot_error(frame_gate, actor_before)
		if frame_error.is_empty():
			frame_error = _install_framing_art(FrameArt.recipe_from_complete_gate(frame_gate, _sequence))
		if not frame_error.is_empty():
			_reject_at_barrier(frame_error)
			return
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
	_clear_framing_art()
	_joins += 1
	_locked = false
	phase = "warning"
	recording_joined.emit(_join_receipt.duplicate(true))


func actual_world_root() -> Node3D:
	# Keep physical floor custody in the outer level and query the common Hero world.
	return _external_parent.get_parent() as Node3D if is_instance_valid(_external_parent) else null

func scheduler_context() -> Dictionary:
	return {"world_root": actual_world_root(), "source_epoch": _capture_epoch, "generation": _generation, "capture_collision_fingerprint": _capture_context.capture_collision_fingerprint}


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
	_clear_framing_art()
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
	if phase == "framing" and not is_instance_valid(playback):
		return captured_codec_framing_union(shared_shell.get("camera") as Camera3D)
	var points: Array = _forecast_points.duplicate()
	_append_mesh(points, _tether_visual)
	for part: MeshInstance3D in _tether_branches:
		if part.visible: _append_mesh(points, part)
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
	return {"world_root": actual_world_root(), "owners": owners, "actors": {ACTOR_ID: hero}, "floors": {"firm-floor": _floor}}


func _update_guidance() -> void:
	_present_tether_branches()
	_update_slot_markers()
	if not last_configuration_error.is_empty(): objective_text = "RULE ROOM UNAVAILABLE"
	elif phase == "spent": objective_text = "THE LOCAL TETHER IS QUIET\nONE FINITE RECORDING RELEASED"
	elif phase in ["exposed", "severed"]: objective_text = "THE LOW TETHER IS EXPOSED\nRETURN AND USE YOUR PRIMARY"
	elif phase == "rejected": objective_text = "THAT RECORDING FADES SAFELY\nCHOOSE A FRESH DASH AND PRIMARY"
	elif phase == "warning": objective_text = "YOUR ROUTE IS ABOUT TO RETURN\nREAD ITS FOOTPRINT AND OPEN LANDING"
	elif phase == "lock": objective_text = "THE RECORDED ROUTE IS LOCKED\nEVADE, THEN RETURN TO THE LOW TETHER"
	elif phase == "active": objective_text = "THE WORLD REPEATS YOUR ROUTE\nEVADE, THEN RETURN TO THE TETHER"
	elif _slot_capacity == 2 and phase in ["recording", "framing"]:
		var sealed: int = int(capture_gate.state().capture.sealed) if is_instance_valid(capture_gate) else 0
		objective_text = "RECORD %d OF 2\nCOMPLETE A DASH, THEN A PRIMARY" % mini(sealed + 1, 2)
	else: objective_text = "COMPOSE AN ESCAPE\nCOMPLETE A DASH, THEN A PRIMARY"


static func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


# DRAFT public owned adapter hooks; copied V2 live mechanics above are unchanged.
var _local_codec = LocalCodec.new()
var _codec_capture_error: String = ""
var _codec_restore_error: String = ""
var _codec_expected: Dictionary = {}
var _codec_restored: bool = false
var _codec_camera: Camera3D
var _codec_hud: GameHUD

func snapshot_state() -> Dictionary:
	if is_restore_candidate():
		last_snapshot_error = "Nonplayable candidate is inspected through the explicit candidate gate"
		return {}
	return _codec_checked_capture(null, null)

func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if is_restore_candidate() or not is_instance_valid(camera) or not is_instance_valid(hud):
		last_snapshot_error = "Actual fresh ordinary Camera/HUD context required"
		return {}
	return _codec_checked_capture(camera, hud)

func _codec_checked_capture(camera: Camera3D, hud: GameHUD) -> Dictionary:
	_codec_capture_error = ""
	_codec_camera = camera
	_codec_hud = hud
	var saved: Dictionary = super.snapshot_state()
	_codec_camera = null
	_codec_hud = null
	if not _codec_capture_error.is_empty():
		last_snapshot_error = _codec_capture_error
		return {}
	return saved

func _snapshot_envelope_error(saved: Dictionary) -> String:
	var error: String = super._snapshot_envelope_error(saved)
	return error if not error.is_empty() else LocalCodec.progress_error(saved.progress)

func snapshot_error(saved: Dictionary) -> String:
	return super.snapshot_error(saved)

func snapshot_error_with_player(saved: Dictionary, saved_player: Dictionary) -> String:
	return super.snapshot_error_with_player(saved, saved_player)

func restore_state(saved: Dictionary) -> bool:
	if not is_restore_candidate():
		last_snapshot_error = "Rebuild a fresh whole local candidate; existing finite custody cannot rewind"
		return false
	_codec_restore_error = ""
	_codec_restored = false
	var accepted: bool = super.restore_state(saved)
	if not _codec_restore_error.is_empty():
		last_snapshot_error = _codec_restore_error
		return false # Base cannot roll back; caller must discard this whole candidate.
	return accepted and _codec_restored

func _capture_local_state() -> Dictionary:
	var local: Dictionary = _local_codec.capture(self, hero.snapshot_state(), _codec_camera == null)
	_codec_capture_error = _local_codec.last_error
	if _codec_capture_error.is_empty() and _codec_camera != null:
		_codec_capture_error = _local_codec.candidate_presentation_error(self, _codec_camera, _codec_hud)
	return local if _codec_capture_error.is_empty() else {}

func _local_snapshot_error(local: Dictionary) -> String:
	return _local_codec.record_error(local, self, hero.snapshot_state())

func _local_snapshot_error_with_player(local: Dictionary, player: Dictionary) -> String:
	return _local_codec.record_error(local, self, player)

func _restore_local_state(local: Dictionary) -> void:
	_codec_expected = local.duplicate(true)
	_codec_restored = _local_codec.restore_local(local, self, hero.snapshot_state())
	_codec_restore_error = _local_codec.last_error

func restore_candidate_construction_required() -> bool:
	return true

func _on_enter_restore_candidate(local: Dictionary, player: Dictionary) -> String:
	_active = false
	# Native floor/tether/cues/Gate/Scheduler were built by _ready, inert while paused.
	if not local.get("world") is Dictionary or not local.world.get("profile_id") is String or LocalDifficulty.new().profile(local.world.profile_id).is_empty(): return "Validated canonical immutable constructor profile required"
	if not threat_scheduler.begin_encounter(local.world.profile_id, ENCOUNTER_ID, 1): return threat_scheduler.last_error
	if not capture_gate.configure(OWNER_ID, ACTOR_ID, hero, _capture_epoch): return capture_gate.last_error
	_configured = true # Configure once, generation0; never arm, consume or restore yet.
	var recipe: Dictionary = _local_codec.constructor_recipe(local, self, player)
	if not recipe.get("accepted", false): return recipe.get("error", "Constructor recipe refused")
	if recipe.has_owner:
		playback = Playback.new()
		playback.name = "FiniteCapturedApparition" + str(recipe.generation)
		add_child(playback)
		playback.global_position = tether.global_position
		if not playback.configure(recipe.playback_id, recipe.sequence, recipe.source_epoch, recipe.generation, "act3_traveller"): return playback.last_error
	elif recipe.has_frame_art:
		var frame_error: String = _install_framing_art(recipe.frame_recipe)
		if not frame_error.is_empty(): return frame_error
	return _local_codec.record_error(local, self, player)

func finish_restore_candidate() -> bool:
	var finished: bool = super.finish_restore_candidate()
	if finished:
		_codec_expected.clear()
		_codec_restored = false
	return finished

func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	if not _codec_restored or _codec_expected.is_empty(): return "Exact quiet native aggregate commit required before optics"
	return _local_codec.verify_candidate(_codec_expected, self, hero.snapshot_state(), camera, hud)

func captured_codec_boundary_error() -> String:
	if not is_inside_tree() or not get_tree().paused or not is_instance_valid(hero) or _queued or _transaction_busy: return "Observed deferred paused boundary outside owned transactions required"
	if not last_configuration_error.is_empty(): return last_configuration_error
	return captured_codec_native_error()

func captured_codec_native_error() -> String:
	var art_error: String = _framing_art_native_error()
	if not art_error.is_empty(): return art_error
	if global_transform != Transform3D.IDENTITY or capture_slots != _slot_capacity or _capture_epoch != (SOURCE_EPOCH if _slot_capacity == 1 else "A3-L5/two-slot-rule"): return "Actual immutable selected native room configuration changed"
	if hero.dead or not is_instance_valid(capture_gate) or capture_gate.get_script() != Gate or not is_instance_valid(threat_scheduler) or threat_scheduler.get_script() != Scheduler: return "Live shared Hero and original ready leaf recipients required"
	if is_instance_valid(playback) and playback.get_script() != Playback: return "Original captured Playback script required"
	if not is_instance_valid(tether) or not tether.is_node_ready() or tether.global_transform != Transform3D(Basis.IDENTITY, TETHER_POSITION) or tether.get_parent() != self or not tether is LowTether or tether.custodian == null or tether.custodian.get_ref() != self: return "Actual fixed low tether pose/native owner binding changed"
	var floor_error: String = _external_floor_error()
	if not floor_error.is_empty(): return floor_error
	if not is_instance_valid(_tether_visual) or not _tether_visual.visible or _tether_visual.get_parent() != tether or _tether_visual.position != Vector3(0, 0.24, 0) or _tether_visual.basis.get_rotation_quaternion() != Quaternion.IDENTITY or _tether_visual.scale != Vector3(1, 0.2 if _cleared else 1.0, 1) or not _tether_visual.mesh is BoxMesh or _tether_visual.mesh.size != Vector3(0.5, 0.48, 0.5) or _tether_visual.material_override != _tether_material or not _tether_material is StandardMaterial3D: return "Actual ordinary tether visual/resource/state changed"
	var opened: bool = _cleared or phase == "exposed"
	if _tether_material.albedo_color != (Color(0.79, 0.89, 0.56) if opened else Color(0.33, 0.30, 0.39)): return "Actual native tether material must retain its real opened/spent state"
	if tether.is_in_group("environment_attack_targets") == _cleared: return "Actual target group must match genuine tether custody"
	if not is_instance_valid(_tether_cue) or _tether_cue.get_script() != Interaction or _tether_cue.get_parent() != tether or not _tether_cue.is_in_group("required_cues"): return "Original ordinary interaction cue recipient required"
	var cue: Dictionary = _tether_cue.state()
	var expected_state: String = "spent" if _cleared else ("available" if phase == "exposed" else "clear")
	if cue.get("api_revision") != Interaction.API_REVISION or cue.get("state") != expected_state or cue.get("trigger") != "attack" or cue.get("required") != true or cue.get("visible") != (expected_state != "clear"): return "Actual current ordinary cue state/trigger/visibility differs"
	var marker: MeshInstance3D = _tether_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if marker == null or marker.get_parent() != _tether_cue or marker.position != Vector3(0, 0.025, 0) or marker.basis != Basis.IDENTITY or marker.visible != (expected_state != "clear") or not marker.material_override is StandardMaterial3D: return "Actual current required cue mesh recipient/visibility changed"
	if marker.layers != 1 or marker.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or marker.transparency != 0.0 or marker.material_overlay != null or marker.visibility_range_begin != 0.0 or marker.visibility_range_end != 0.0: return "Actual required marker render layers/shadow/transparency/range policy changed"
	var material: StandardMaterial3D = marker.material_override as StandardMaterial3D
	if material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA or material.cull_mode != BaseMaterial3D.CULL_DISABLED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.albedo_texture != null or material.no_depth_test or material.grow or material.distance_fade_mode != BaseMaterial3D.DISTANCE_FADE_DISABLED: return "Actual ordinary shared marker material/render policy changed"
	if expected_state != "clear":
		var expected_color := Color(0.88, 0.92, 0.82, 0.85)
		if expected_state == "active": expected_color = Color(1.0, 0.98, 0.87, 1.0)
		elif expected_state == "spent": expected_color = Color(0.64, 0.68, 0.65, 0.40)
		if not marker.is_visible_in_tree() or material.albedo_color != expected_color: return "Actual CURRENT visible ordinary marker must retain original shared color/alpha"
	if expected_state == "clear":
		if marker.mesh != null: return "Clear current cue must really have no attack marker"
	else:
		var factory: ArrayMesh = CueMesh.interaction_mesh(expected_state, "attack")
		if not marker.mesh is ArrayMesh or marker.mesh.get_surface_count() != factory.get_surface_count(): return "Required CURRENT ordinary marker mesh is missing"
		for index: int in range(factory.get_surface_count()):
			if var_to_bytes(marker.mesh.surface_get_arrays(index)) != var_to_bytes(factory.surface_get_arrays(index)): return "Actual CURRENT ordinary marker differs from shared native mesh"
	if _capture_frame.size() != 4 or not is_instance_valid(_rejection_marker) or not _rejection_marker.mesh is BoxMesh or _rejection_marker.visible != (phase == "rejected"): return "Actual recording/rejection display required"
	for frame: MeshInstance3D in _capture_frame:
		if not is_instance_valid(frame) or not frame.visible or frame.get_parent() != self or not frame.mesh is BoxMesh: return "Actual original recording-frame mesh required"
	if _slot_markers.size() != (2 if _slot_capacity == 2 else 0) or _slot_marker_materials.size() != _slot_markers.size(): return "Both passive original number recipients required"
	for index: int in range(_slot_markers.size()):
		if not is_instance_valid(_slot_markers[index]) or _slot_markers[index].get_parent() != self or _slot_markers[index].basis != Basis.IDENTITY or not _slot_markers[index].visible or _slot_markers[index].get_child_count() != (1 if index == 0 else 5): return "Original passive slot mesh topology required"
		for stroke: Node in _slot_markers[index].get_children():
			if not stroke is MeshInstance3D or not stroke.mesh is BoxMesh or stroke.material_override != _slot_marker_materials[index] or not stroke.visible: return "Every original passive number stroke/resource required"
	if _tether_branches.size() != 2: return "Two native mineral branch recipients required"
	for index: int in range(2):
		var part: MeshInstance3D = _tether_branches[index]
		var side: float = -1.0 if index == 0 else 1.0
		if not is_instance_valid(part) or part.get_parent() != tether or part.layers != 1 or part.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or part.transparency != 0.0 or part.material_overlay != null or not part.material_override is StandardMaterial3D or (part.material_override as StandardMaterial3D).albedo_color != Color(0.46, 0.39, 0.57) or (part.material_override as StandardMaterial3D).shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or (part.material_override as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or (part.material_override as StandardMaterial3D).no_depth_test or not part.mesh is BoxMesh or part.mesh.size != Vector3(0.10, 0.40, 0.12) or part.visible != (not _cleared) or part.position != Vector3(side * (0.34 if phase == "exposed" else 0.19), 0.32, 0) or part.rotation != Vector3(0, 0, side * (-0.45 if phase == "exposed" else 0.0)): return "Actual phase-derived mineral arm changed"
	return ""

func captured_codec_configuration() -> Dictionary:
	return {"base_runtime_sha256": LocalCodec.BASE_SHA, "layout_id": "crystalman-full-route-floor-1", "capacity": _slot_capacity, "source_epoch": _capture_epoch, "gate_owner": OWNER_ID, "actor_id": ACTOR_ID, "presentation_id": "act3_traveller", "floor_rect": [-6.0, -8.0, 12.0, 16.0], "floor_box": [12.0, 1.0, 54.0], "floor_center": [0.0, -0.5, 13.0], "floor_id": "firm-crystalman-route", "external_floor_api": EXTERNAL_FLOOR_API, "recipient_script": "res://scripts/acts/act3/crystalman_capture_phase.gd", "tether_position": LocalValue.vector3(TETHER_POSITION), "gate_script": "res://scripts/combat/replay_capture_gate.gd", "scheduler_script": "res://scripts/combat/threat_scheduler.gd", "playback_script": "res://scripts/combat/replay_playback.gd", "cue_script": "res://scripts/cues/interaction_cue.gd", "frame_art_script": "res://scripts/acts/act3/crystalman_recorded_frame_art.gd", "frame_art_api": FrameArt.API}

func captured_codec_owned_state() -> Dictionary:
	var points: Array = []
	for point: Vector3 in _forecast_points: points.append(LocalValue.vector3(point))
	var cue: Dictionary = _tether_cue.state()
	var numbers: Array = []
	for index: int in range(_slot_markers.size()):
		var color: Color = _slot_marker_materials[index].albedo_color
		numbers.append({"position": LocalValue.vector3(_slot_markers[index].global_position), "color": [float(color.r), float(color.g), float(color.b), float(color.a)]})
	return {"phase": phase, "frame_art": _framing_art.capture_packet() if is_instance_valid(_framing_art) else {}, "configured": _configured, "generation": _generation, "joins": _joins, "rejections": _rejections, "tether_hits": _tether_hits, "cleared": _cleared, "locked": _locked, "operation": _operation, "last_rejection": last_rejection, "last_camera_error": last_camera_error, "capture_context": _capture_context.duplicate(true), "sequence": _sequence.duplicate(true), "projection": _projection.duplicate(true), "proof": LocalCodec.encode_proof(_proof), "held_exchange": LocalCodec.encode_exchange(_lease), "join_receipt": _join_receipt.duplicate(true), "last_rejected_capture": _last_rejected_capture.duplicate(true), "forecast": points, "rearm_after_clock_s": _rearm_after_clock_s, "exposure_from_s": _exposure_from_s, "exposure_until_s": _exposure_until_s, "presentation": {"tether_state": cue.state, "tether_trigger": cue.trigger, "tether_scale_y": _tether_visual.scale.y, "tether_color": [float(_tether_material.albedo_color.r), float(_tether_material.albedo_color.g), float(_tether_material.albedo_color.b), float(_tether_material.albedo_color.a)], "attack_group": tether.is_in_group("environment_attack_targets"), "rejection_visible": _rejection_marker.visible, "marker_mode": "sequence" if phase == "framing" or is_instance_valid(playback) else "capture", "numbers": numbers}}

func captured_codec_apply_owned_state(o: Dictionary) -> String:
	phase = o.phase
	_configured = o.configured
	_generation = o.generation
	_joins = o.joins
	_rejections = o.rejections
	_tether_hits = o.tether_hits
	_cleared = o.cleared
	_locked = o.locked
	_operation = o.operation
	last_rejection = o.last_rejection
	last_camera_error = o.last_camera_error
	_capture_context = o.capture_context.duplicate(true)
	_sequence = o.sequence.duplicate(true)
	_native_sequence = {}
	if not _sequence.is_empty():
		var reader = Sequence.new()
		if not reader.restore_state(_sequence, _capture_epoch, _generation): return reader.last_snapshot_error
		_native_sequence = reader.state()
	_projection = o.projection.duplicate(true)
	_proof = LocalCodec.decode_proof(o.proof)
	_lease = LocalCodec.decode_exchange(o.held_exchange, playback, hero) if is_instance_valid(playback) else {}
	_join_receipt = o.join_receipt.duplicate(true)
	_last_rejected_capture = o.last_rejected_capture.duplicate(true)
	_forecast_points.clear()
	for point: Array in o.forecast: _forecast_points.append(LocalValue.read_vector3(point))
	_rearm_after_clock_s = o.rearm_after_clock_s
	_exposure_from_s = o.exposure_from_s
	_exposure_until_s = o.exposure_until_s
	_queued = false
	_transaction_busy = false
	_tether_visual.scale.y = o.presentation.tether_scale_y
	_tether_material.albedo_color = Color(0.79, 0.89, 0.56) if _cleared or phase == "exposed" else Color(0.33, 0.30, 0.39)
	if o.presentation.attack_group: tether.add_to_group("environment_attack_targets")
	else: tether.remove_from_group("environment_attack_targets")
	_rejection_marker.visible = o.presentation.rejection_visible
	var blocked: bool = _tether_cue.is_blocking_signals()
	_tether_cue.set_block_signals(true)
	if o.presentation.tether_state == "clear": _tether_cue.clear()
	else: _tether_cue.present(o.presentation.tether_state, "attack")
	_tether_cue.set_block_signals(blocked)
	if o.presentation.marker_mode == "sequence": _position_slot_markers_for_sequence()
	else: _position_slot_markers_for_capture()
	_active = true # Tree remains paused, candidate remains nonplayable until Shell gate.
	_update_guidance()
	# Retain actual harmless display prefix, including the one-frame recording
	# observation before a subsequent normal owned update derives its color.
	for index: int in range(_slot_markers.size()):
		_slot_markers[index].global_position = LocalValue.read_vector3(o.presentation.numbers[index].position)
		var rgba: Array = o.presentation.numbers[index].color
		_slot_marker_materials[index].albedo_color = Color(rgba[0], rgba[1], rgba[2], rgba[3])
	return ""

func captured_codec_framing_union(camera: Camera3D) -> Array:
	if not is_instance_valid(camera) or not is_instance_valid(hero): return []
	# Independent native context: never use installed donor camera aliases.
	# Framing measures original inert native art/route/projection/proof below;
	# never count a discarded-preview forecast as an actual art recipient.
	var points: Array = [] if phase == "framing" else _forecast_points.duplicate()
	_append_mesh(points, _tether_visual)
	for part: MeshInstance3D in _tether_branches:
		if part.visible: _append_mesh(points, part)
	var marker: MeshInstance3D = _tether_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	_append_mesh(points, marker)
	if marker != null and _opening_cue_mesh != null: _append_native_bounds(points, _opening_cue_mesh.get_aabb(), marker.global_transform)
	for frame: MeshInstance3D in _capture_frame: _append_mesh(points, frame)
	var numbers: Array = []
	for number: Node3D in _slot_markers:
		for child: Node in number.get_children():
			if child is MeshInstance3D: _append_mesh(numbers, child as MeshInstance3D)
	_append_cloud_bounds(points, numbers)
	if is_instance_valid(playback):
		var sprite: Sprite3D = playback.get_apparition()
		var art: Array = _codec_billboard_points(sprite, camera)
		if art.is_empty(): return []
		points.append_array(art)
		var routes: Array = []
		var origin: Vector3 = playback.get_apparition_root().global_position
		for slot: Dictionary in _native_sequence.timeline.slots:
			for sample: Dictionary in slot.route:
				for point: Vector3 in art: routes.append(point + sample.position - origin)
		_append_cloud_bounds(points, routes)
		var cues: Array = []
		for cue: Node3D in playback.get_cues():
			for child: Node in cue.get_children():
				if child is MeshInstance3D: _append_mesh(cues, child as MeshInstance3D)
		_append_cloud_bounds(points, cues)
		for event: Dictionary in _projection.events:
			var b: Array = event.bounds
			_append_box(points, Vector3(b[0], event.floor_y, b[1]), Vector3(b[2] - b[0], 0.08, b[3] - b[1]))
		var cloud: Array = []
		var actor: Array = shared_shell.call("player_camera_framing_points_for", hero, camera)
		if actor.is_empty(): return []
		for segment: Dictionary in _proof.path:
			for key: String in ["from", "to"]:
				for point: Vector3 in actor: cloud.append(point + segment[key] - hero.global_position)
		_append_cloud_bounds(points, cloud)
	elif phase == "framing":
		if not is_instance_valid(_framing_art): return []
		var art: Array = _framing_art.route_framing_points(camera, _sequence)
		if art.is_empty(): return []
		points.append_array(art)
		for event: Dictionary in _projection.events:
			var b: Array = event.bounds
			_append_box(points, Vector3(b[0], event.floor_y, b[1]), Vector3(b[2] - b[0], 0.08, b[3] - b[1]))
		var actor: Array = shared_shell.call("player_camera_framing_points_for", hero, camera)
		if actor.is_empty(): return []
		var cloud: Array = []
		for segment: Dictionary in _proof.path:
			for key: String in ["from", "to"]:
				for point: Vector3 in actor: cloud.append(point + segment[key] - hero.global_position)
		_append_cloud_bounds(points, cloud)
	return points

func _codec_billboard_points(sprite: Sprite3D, camera: Camera3D) -> Array:
	# Native mesh measurement for this level-owned sprite with explicit current
	# camera, matching existing billboard geometry; no controller/palette clone.
	if not is_instance_valid(sprite) or sprite.texture == null or sprite.texture is AtlasTexture or sprite.billboard != BaseMaterial3D.BILLBOARD_ENABLED or sprite.axis != Vector3.AXIS_Z or sprite.fixed_size or sprite.region_enabled or sprite.hframes != 1 or sprite.vframes != 1 or sprite.material_override != null or sprite.material_overlay != null: return []
	var mesh: TriangleMesh = sprite.generate_triangle_mesh()
	if mesh == null: return []
	var scale: Vector3 = sprite.global_basis.get_scale()
	var points: Array = []
	for vertex: Vector3 in mesh.get_faces(): points.append(sprite.global_position + camera.global_basis.x * vertex.x * scale.x + camera.global_basis.y * vertex.y * scale.y)
	return points


func _on_exit_level() -> void:
	_clear_framing_art()
	_active = false
	_queued = false
	_cancel_consumer("crystalman_rule_room_exit")
	if is_instance_valid(threat_scheduler): threat_scheduler.end_encounter("crystalman_rule_room_exit")


func _present_tether_branches() -> void:
	for index: int in range(_tether_branches.size()):
		var part: MeshInstance3D = _tether_branches[index]
		var side: float = -1.0 if index == 0 else 1.0
		part.visible = not _cleared
		part.position = Vector3(side * (0.34 if phase == "exposed" else 0.19), 0.32, 0)
		part.rotation.z = side * (-0.45 if phase == "exposed" else 0.0)

func phase_boundary_error() -> String:
	var error: String = captured_codec_boundary_error()
	if not error.is_empty(): return error
	if phase != "spent" or not _cleared or not _locked or _tether_hits != 1 or not is_instance_valid(playback): return "Genuine settled spent source required"
	var leaf: Dictionary = playback.state()
	if leaf.get("status") not in ["running", "complete"] or leaf.has("pending_delivery"): return "Uncanceled delivered original finite owner required"
	var count: int = 0
	for slot: Dictionary in _native_sequence.timeline.slots: count += slot.events.size()
	if leaf.cursor.next_event_index != count or leaf.cursor.executed_events.size() != count or leaf.opportunities.size() != count or threat_scheduler.get_clock() < float(_lease.active_until_s): return "All attacks must finish once before whole disposal"
	var packet: Dictionary = _local_codec.capture(self, hero.snapshot_state())
	return _local_codec.last_error if packet.is_empty() else ""

func closed_phase_metadata() -> Dictionary:
	var error: String = phase_boundary_error()
	if not error.is_empty(): return {"accepted": false, "reason": error}
	var retirement: Dictionary = capture_gate.retirement_state()
	return {"accepted": true, "reason": "", "phase_id": "capture-one" if _slot_capacity == 1 else "capture-two", "capacity": _slot_capacity, "generation": _generation, "sequence_id": _sequence.sequence_id, "completed_at_actor_s": hero.get_world_action_clock(), "completed_at_unit_s": threat_scheduler.get_clock(), "retirement_slot_ids": retirement.slot_ids.duplicate(), "retirement_sha256": Exact.stringify(retirement).sha256_text(), "sequence_sha256": Exact.stringify(_sequence).sha256_text(), "projection_sha256": Exact.stringify(_projection).sha256_text(), "delivered_attack_count": playback.state().opportunities.size(), "tether_hits": 1, "disposition": "whole_unit_disposal"}

func capture_native_state(player: Dictionary,optical: bool = true) -> Dictionary:
	return _local_codec.capture(self,player,optical)

func native_capture_error() -> String:
	return _local_codec.last_error

func native_state_error(local: Dictionary,player: Dictionary) -> String:
	return _local_codec.record_error(local,self,player)

func _parent_local_envelope(local: Dictionary) -> Dictionary:
	return {"api_revision":CinderLevel.API_REVISION,"schema_version":1,"level_id":level_id,"scene_path":scene_file_path,"local_snapshot_version":local_snapshot_version,"progress":{"completed":false,"completion_id":"","contact_exit_id":"","checkpoint_id":"","checkpoint_kind":"","checkpoint_ids":{}},"local":local.duplicate(true)}

func prepare_parent_restore(local: Dictionary,player: Dictionary,parent_hero: CinderPlayer,parent_effects: PixelEffects,shell: Node) -> bool:
	return enter_restore_candidate(parent_hero,parent_effects,shell,_parent_local_envelope(local),player)

func restore_parent_state(local: Dictionary,player: Dictionary) -> bool:
	if not _same(player,hero.snapshot_state()): return false
	return restore_state(_parent_local_envelope(local))

func verify_parent_candidate(local: Dictionary,player: Dictionary,camera: Camera3D,hud: GameHUD) -> String:
	return _local_codec.verify_candidate(local,self,player,camera,hud)


func _clear_framing_art() -> void:
	if is_instance_valid(_framing_art): _framing_art.free()
	_framing_art = null

func _install_framing_art(recipe: Dictionary) -> String:
	var error: String = FrameArt.recipe_error(recipe)
	if not error.is_empty(): return error
	if not get_tree().paused: return "Fresh inert recorded art requires an actual paused barrier"
	_clear_framing_art()
	_framing_art = FrameArt.new()
	_framing_art.name = "OriginalRecordedFrameArt"
	add_child(_framing_art)
	if not _framing_art.configure(recipe):
		error = _framing_art.last_error
		_clear_framing_art()
		return error
	return ""

func _framing_art_native_error() -> String:
	if phase == "framing" and not is_instance_valid(_framing_art): return "Framing requires every actual original static recorded-art recipient"
	if not is_instance_valid(_framing_art): return ""
	if _framing_art.get_parent() != self or _framing_art.get_script() != FrameArt: return "Original owned framing-art script/parent required"
	# Fresh restore construction stages native art before local quiet apply.
	if phase != "framing" and not (phase == "settling" and is_restore_candidate()): return "Static recorded art may exist only for genuine framing or its fresh candidate"
	return _framing_art.native_error()

func framing_art_record_error(packet: Dictionary, gate: Dictionary, sequence: Dictionary) -> String:
	if not is_instance_valid(_framing_art): return "Actual fresh original framing artwork missing"
	return _framing_art.native_packet_error(packet, gate, sequence)
