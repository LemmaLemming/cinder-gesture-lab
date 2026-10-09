extends CinderLevel
## First owned C52 rule room: one genuine stationary HP/lease/Playback owner.
## A finite own sequence, no captured Player actions or private cycle reset.

const Scenery = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const ReplayProjection = preload("res://scripts/combat/replay_footprint.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const SOURCE_ID: String = "mirror-rule/real-knot"
const SOURCE_EPOCH: String = "A3-L3/first-rule-room"
const ENCOUNTER_ID: String = "A3-L3/echo-rule-room"
const FloorRect: Rect2 = Rect2(-7, -11, 14, 22)

var scenery: Node3D
var echo: Node3D
var threat_scheduler: CinderThreatScheduler
var last_configuration_error: String = ""
var last_admission_reason: String = ""
var last_camera_error: String = ""
var _floor: Dictionary = {}
var _context: Dictionary = {}
var _projection: Dictionary = {}
var _proof: Dictionary = {}
var _view_positions: Array[Vector3] = []
var _lease: Dictionary = {}
var _active: bool = false
var _admitted: bool = false
var _locked: bool = false


func _ready() -> void:
	# Lock/camera custody precede canonical Playback's priority110 delivery.
	process_physics_priority = 100
	scenery = Scenery.new()
	scenery.name = "MirrorSeaScenery"
	add_child(scenery)
	scenery.call("build", true)
	var body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var collision: CollisionShape3D = body.get_node_or_null("Solid") as CollisionShape3D if body != null else null
	if collision == null:
		last_configuration_error = "Mirror rule requires its real firm shore floor"
	else:
		_floor = {"collision": collision, "safe_rect": FloorRect}
	_build_stone()
	_build_harmless_reflection()
	threat_scheduler = Scheduler.new()
	threat_scheduler.name = "MirrorRuleScheduler"
	add_child(threat_scheduler)
	echo = Echo.new()
	echo.name = "ActualMirrorKnot"
	add_child(echo)


func _build_stone() -> void:
	# One stable nonactionable parent obstacle; full-height Box LOS is supported.
	var stone := StaticBody3D.new()
	stone.name = "FixedShoreStone"
	stone.position = Vector3(-2.3, 0.8, -0.4)
	stone.collision_layer = 1
	stone.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.name = "Solid"
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.6, 1.2)
	shape.shape = box
	stone.add_child(shape)
	var visual := MeshInstance3D.new()
	visual.name = "DryMineralMass"
	var mesh := BoxMesh.new()
	mesh.size = box.size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.055, 0.044, 0.07)
	visual.material_override = material
	stone.add_child(visual)
	add_child(stone)


func _build_harmless_reflection() -> void:
	# The outlined companion owns no warning, HP, collision or attack handler.
	# Its open interior and muted value differ from the filled real porcelain.
	var reflection := Node3D.new()
	reflection.name = "HarmlessOutlinedReflection"
	reflection.position = Vector3(-1.4, 0.02, -2.1)
	var pieces: Array = [
		[Vector3(0.055, 0.9, 0.06), Vector3(-0.23, 0.56, 0)],
		[Vector3(0.055, 0.9, 0.06), Vector3(0.23, 0.56, 0)],
		[Vector3(0.51, 0.055, 0.06), Vector3(0, 1.04, 0)],
		[Vector3(0.51, 0.055, 0.06), Vector3(0, 0.26, 0)],
		[Vector3(0.055, 0.23, 0.06), Vector3(-0.17, 1.25, 0)],
		[Vector3(0.055, 0.23, 0.06), Vector3(0.17, 1.25, 0)],
		[Vector3(0.39, 0.05, 0.06), Vector3(0, 1.39, 0)],
		[Vector3(0.39, 0.05, 0.06), Vector3(0, 1.12, 0)]
	]
	for index: int in range(pieces.size()):
		var visual := MeshInstance3D.new()
		visual.name = "QuietOutlinePart%d" % index
		var mesh := BoxMesh.new()
		mesh.size = pieces[index][0]
		visual.mesh = mesh
		visual.position = pieces[index][1]
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.albedo_color = Color(0.48, 0.47, 0.56)
		visual.material_override = material
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		reflection.add_child(visual)
	add_child(reflection)


func _on_enter_level() -> void:
	if not last_configuration_error.is_empty():
		return
	var profile: String = shared_shell.call("get_difficulty_preference") if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, 1):
		last_configuration_error = threat_scheduler.last_error
		return
	var floors: Dictionary = ReplayProjection.floor_signature(get_parent() as Node3D, [_floor])
	if not floors.get("accepted", false):
		last_configuration_error = String(floors.get("reason", "Unsupported shore domain"))
		return
	_context = {"world_root": get_parent() as Node3D, "source_id": SOURCE_ID, "source_epoch": SOURCE_EPOCH, "generation": 1, "world_collision_fingerprint": threat_scheduler.pure_collision_fingerprint(get_parent() as Node3D), "world_floor_signature": floors.signature}
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": _context.world_collision_fingerprint, "floor_signature": _context.world_floor_signature}
	if not echo.call("configure_source", SOURCE_ID, SOURCE_EPOCH, 1, native_definition(), profile, prepared, threat_scheduler):
		last_configuration_error = String(echo.get("source_snapshot_error")) + "; " + String(echo.get("last_error"))
		return
	_active = true
	scenery.call("follow_landmarks", hero.global_position)
	_update_guidance()


func native_definition() -> Dictionary:
	var travel_s: float = 0.30
	var slash_s: float = 0.18
	# Own-route positions are feet on the actual Y=0 floor, not cue padding.
	return {"definition_id": "act3/mirror-rule/straight-return", "definition_revision": 1, "role_id": "C52", "raw_role": {"raw_damage": 18.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": travel_s + slash_s, "recovery_s": 2.2, "attack_interval_s": 4.2, "max_hp": 36.0, "move_speed": 0.0}, "timing_floors": {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.8}, "recognition_s": 0.25, "route": [{"position": Vector3(0, 0, -2.5), "at_s": 0.0}, {"position": Vector3(0, 0, -0.5), "at_s": travel_s}], "travel_clearance": {"radius_m": 0.65, "height_m": 1.45}, "slash": {"world_origin": Vector3(0, 0, -0.5), "direction": Vector3.BACK, "reach": 2.2, "cone_min_dot": 0.2, "origin_disk_radius": 0.25, "max_vertical_distance": 0.75, "los_height": 0.5, "commitment_duration_s": slash_s, "visual_duration_s": 0.28}, "presentation": {"presentation_id": "act3/porcelain-mirror-echo", "presentation_revision": 1}}


func _physics_process(_delta: float) -> void:
	if not _active or not is_instance_valid(hero):
		return
	scenery.call("follow_landmarks", hero.global_position)
	if not _admitted and hero.is_on_floor():
		_try_admit()
	elif _admitted and not _locked and not _lease.is_empty() and threat_scheduler.get_clock() >= float(_lease.lock_from_s):
		var current: String = shared_shell.call("camera_framing_error", camera_framing_points())
		if not current.is_empty():
			last_camera_error = current
			echo.call("cancel", "act3_actual_locked_view_unreadable")
			_locked = true
		else:
			var answer: Dictionary = threat_scheduler.commit_authored_replay(String(_lease.id), combat_response())
			_locked = true
			if answer.get("accepted", false):
				_lease = answer.reservation.duplicate(true)
				_proof = answer.proof.duplicate(true)
				_retain_view_positions(_proof)
			else:
				last_admission_reason = String(answer.get("reason", "Actual lock rejected"))
	if _admitted and _locked and String(echo.call("source_phase")) not in ["complete", "cancelled", "defeated"]:
		var current: String = shared_shell.call("camera_framing_error", camera_framing_points())
		if not current.is_empty():
			last_camera_error = current
			echo.call("cancel", "act3_actual_exchange_view_unreadable")
	_update_guidance()


func _try_admit() -> void:
	var response: Dictionary = combat_response()
	var candidate: Dictionary = Witness.new().prove_authored(threat_scheduler, echo, echo.call("source_program"), response, _context)
	if not candidate.get("accepted", false):
		last_admission_reason = String(candidate.get("reason", "No complete ordinary response"))
		return
	_proof = candidate.duplicate(true)
	_retain_view_positions(_proof)
	if _projection.is_empty():
		_projection = ReplayProjection.plan_authored(threat_scheduler, echo.call("source_program"), get_parent() as Node3D, [_floor], _context)
		if not _projection.get("accepted", false):
			last_configuration_error = String(_projection.get("reason", "Required footprint rejected"))
			_projection = {}
			return
	last_camera_error = shared_shell.call("camera_framing_error", camera_framing_points())
	if not last_camera_error.is_empty():
		return # Visible forecast may settle; no lease or attack is hidden here.
	var answer: Dictionary = threat_scheduler.request_authored_replay(echo, echo.call("source_program"), response, _context)
	if not answer.get("accepted", false):
		last_admission_reason = String(answer.get("reason", "Admission rejected"))
		return
	_lease = answer.reservation.duplicate(true)
	_proof = answer.proof.duplicate(true)
	_retain_view_positions(_proof)
	_admitted = true
	if not echo.call("bind_projected", threat_scheduler, String(answer.reservation_id), {"hero": hero}, [_floor], _projection, _context):
		threat_scheduler.cancel(String(answer.reservation_id), "act3_required_projection_binding_failed")
		last_configuration_error = String(echo.get("last_error"))
		return
	last_admission_reason = ""


func combat_response() -> Dictionary:
	var response: Dictionary = hero.get_threat_response_state()
	# Prefer the centreward landing from this offset spawn. The complete shared
	# witness still rejects an unsafe direction; no movement is imposed on Hero.
	var directions: Array[Vector3] = [Vector3.LEFT, Vector3.RIGHT, Vector3.BACK, Vector3.FORWARD] if hero.global_position.x >= 0.0 else [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			directions.append(Vector3(x, 0, z).normalized())
	response.merge({"world_revision": 1, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [_floor]})
	return response


func scheduler_bindings() -> Dictionary:
	return {"world_root": get_parent() as Node3D, "owners": {SOURCE_ID: echo}, "actors": {"hero": hero}, "floors": {"firm-shore": _floor}}


func context() -> Dictionary:
	return _context.duplicate(true)


func floor_regions() -> Array:
	return [_floor.duplicate()]


func state() -> Dictionary:
	return {"api_revision": "act3-echo-rule-room-1", "configuration_error": last_configuration_error, "admission_reason": last_admission_reason, "camera_error": last_camera_error, "source": echo.call("get_source_state") if is_instance_valid(echo) else {}, "playback": echo.call("state") if is_instance_valid(echo) else {}, "lease": _lease.duplicate(true), "proof": _proof.duplicate(true), "admitted": _admitted, "locked": _locked, "clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else -1.0}


func _camera_framing_points() -> Array:
	return camera_framing_points() if _active else []


func camera_framing_points() -> Array:
	var points: Array = []
	var definition: Dictionary = native_definition()
	for endpoint: Dictionary in definition.route:
		_append_box(points, endpoint.position, 0.65, 1.45)
	if not _projection.is_empty():
		for event: Dictionary in _projection.events:
			var bounds: Array = event.bounds
			if bounds.size() == 4:
				for x: float in [float(bounds[0]), float(bounds[2])]:
					for z: float in [float(bounds[1]), float(bounds[3])]:
						points.append(Vector3(x, float(event.floor_y) + 0.035, z))
	for point: Vector3 in _view_positions:
		_append_box(points, point, 0.4, 1.45)
	return points


func _retain_view_positions(proof: Dictionary) -> void:
	_view_positions.clear()
	for segment: Dictionary in proof.get("path", []):
		for key: String in ["from", "to"]:
			var point: Variant = segment.get(key)
			if point is Vector3 and not _view_positions.has(point):
				_view_positions.append(point)


func _view_receipt() -> Dictionary:
	var positions: Array = []
	for point: Vector3 in _view_positions:
		positions.append(Value.vector3(point))
	return {"api_revision": "act3-echo-view-1", "source_id": SOURCE_ID, "source_epoch": SOURCE_EPOCH, "generation": 1, "positions": positions}


func _view_receipt_error(view: Dictionary) -> String:
	if not Value.keys_error(view, ["api_revision", "source_id", "source_epoch", "generation", "positions"]).is_empty() or view.get("api_revision") != "act3-echo-view-1" or view.get("source_id") != SOURCE_ID or view.get("source_epoch") != SOURCE_EPOCH or not view.get("generation") is int or view.generation != 1 or not view.get("positions") is Array or view.positions.is_empty() or view.positions.size() > 12:
		return "Closed same-cycle view-only accepted path positions required"
	var unique: Array[Vector3] = []
	for encoded: Variant in view.positions:
		if not Value.is_vector3(encoded):
			return "View-only path positions require native exact vector transport"
		var point: Vector3 = Value.read_vector3(encoded)
		if unique.has(point) or not FloorRect.grow(-0.33).has_point(Vector2(point.x, point.z)) or absf(point.y) > 0.05:
			return "View-only path points must stay on this firm supported shore"
		unique.append(point)
	if String(echo.call("state").get("status", "idle")) != "idle" and not _view_positions.is_empty() and not CinderAuthoredEnemySequence.exact_equal(view, _view_receipt()):
		return "An existing source cannot rewrite its retained accepted view positions"
	# Display bounds only: this record never authorizes a route or slash. The
	# current actual Scheduler reproves the complete response at the due lock.
	return ""


func _append_box(points: Array, pivot: Vector3, radius: float, height: float) -> void:
	for x: float in [-radius, radius]:
		for y: float in [0.0, height]:
			for z: float in [-radius, radius]:
				points.append(pivot + Vector3(x, y, z))


func _capture_local_state() -> Dictionary:
	var player: Dictionary = hero.snapshot_state()
	var bindings: Dictionary = scheduler_bindings()
	var scheduler: Dictionary = threat_scheduler.snapshot_state(bindings)
	var playback: Dictionary = echo.call("snapshot_state", scheduler, bindings)
	var source: Dictionary = echo.call("capture_source", player, scheduler, playback)
	return {"scheduler": scheduler, "playback": playback, "source": source, "view": _view_receipt()} if not source.is_empty() and not playback.is_empty() and not scheduler.is_empty() else {}


func _local_snapshot_error(data: Dictionary) -> String:
	return _paired_error(data, hero.snapshot_state())


func _local_snapshot_error_with_player(data: Dictionary, player: Dictionary) -> String:
	return _paired_error(data, player)


func _paired_error(data: Dictionary, player: Dictionary) -> String:
	if not last_configuration_error.is_empty():
		return last_configuration_error
	var error: String = scenery.call("runtime_error")
	if not error.is_empty():
		return error
	if not Value.keys_error(data, ["source", "scheduler", "playback", "view"]).is_empty() or not data.source is Dictionary or not data.scheduler is Dictionary or not data.playback is Dictionary or not data.view is Dictionary:
		return "Mirror room requires its complete closed native source/Scheduler/Playback unit"
	error = _view_receipt_error(data.view)
	if not error.is_empty():
		return error
	error = echo.call("source_record_error", data.source, player, data.scheduler, data.playback)
	if not error.is_empty():
		return error
	var staged: Dictionary = scheduler_bindings()
	staged["authored_owner_bindings"] = {SOURCE_ID: echo.call("staged_source_binding", data.source, player, data.scheduler, data.playback)}
	error = threat_scheduler.snapshot_error(data.scheduler, staged)
	if not error.is_empty():
		return error
	if data.scheduler.get("encounter_id") != ENCOUNTER_ID:
		return "Mirror source belongs to this actual rule room"
	return echo.call("snapshot_error", data.playback, threat_scheduler, data.scheduler, staged, {"hero": hero}, [_floor], _context)


func _restore_local_state(data: Dictionary) -> void:
	var player: Dictionary = hero.snapshot_state()
	var physical: bool = echo.call("restore_source_physical", data.source, player, data.scheduler, data.playback)
	assert(physical, "Prevalidated Mirror native HP/lifecycle commit failed")
	var scheduler: bool = threat_scheduler.restore_state(data.scheduler, scheduler_bindings())
	assert(scheduler, "Prevalidated Mirror Scheduler commit failed")
	var playback: bool = echo.call("restore_state", data.playback, threat_scheduler, data.scheduler, scheduler_bindings(), {"hero": hero}, [_floor], _context)
	assert(playback, "Prevalidated Mirror quiet Playback commit failed; discard failed aggregate")
	var phase: bool = echo.call("verify_restored_source_phase", data.source)
	assert(phase, "Prevalidated Mirror actual source phase join failed")
	_admitted = true
	_lease = data.playback.exchange.duplicate(true)
	_locked = bool(_lease.adapter.locked)
	_projection = data.playback.get("projection", {}).duplicate(true)
	_view_positions.clear()
	for point: Array in data.view.positions:
		_view_positions.append(Value.read_vector3(point))
	# Diagnostic proof is not saved authority. Retain view-only original landing
	# bounds; no request/reproof or route authorization occurs through restore.
	_proof = {}
	scenery.call("follow_landmarks", hero.global_position)
	_update_guidance()


func _update_guidance() -> void:
	if not last_configuration_error.is_empty():
		objective_text = "MIRROR ROOM UNAVAILABLE\n" + last_configuration_error
	elif String(echo.call("source_phase")) == "defeated":
		objective_text = "THE REAL KNOT IS QUIET\nFINITE RULE ROOM CLEAR"
	elif String(echo.call("source_phase")) in ["recovery", "complete"]:
		objective_text = "THE LOW KNOT IS REAL\nORDINARY ATTACKS FINISH THE SOURCE"
	elif String(echo.call("source_phase")) == "cancelled":
		objective_text = "THE SEQUENCE FADES SAFELY\nRESET THE RULE ROOM TO TRY AGAIN"
	else:
		objective_text = "READ THE REAL KNOT\nESCAPE THE SLASH; RETURN TO ITS END"


func _on_exit_level() -> void:
	_active = false
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("mirror_rule_room_exit")
