class_name CinderAct3CrystalmanApproachUnit
extends CinderLevel
## SOURCE-ONLY production candidate; C50/C52 public native APIs from accepted L4.
## Current whole journal stays intact until ordinary whole unit disposal.
const Stalker = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const EchoRecipe = preload("res://scripts/acts/act3/mirror_echo_rule_room.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const CueMeshes = preload("res://scripts/cues/cue_mesh.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const UnitCodec = preload("res://scripts/acts/act3/crystalman_approach_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const ENCOUNTER_ID: String = "A3-L5/regular-threshold"
const WORLD_REVISION: int = 1
const FLOOR_ID: String = "firm-crystalman-route"
const FLOOR_RECT := Rect2(-6,-14,12,54)
const ENEMY_IDS: Array[String] = ["l5-offered-echo", "l5-plain-stalker", "l5-plain-echo"]
class RequiredViewObserver:
	extends Node
	var observe: Callable
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 90
	func _physics_process(_delta: float) -> void:
		if observe.is_valid(): observe.call()
var threat_scheduler: CinderThreatScheduler
var sources: Dictionary = {}
var last_configuration_error: String = ""
var last_admission_reason: String = ""
var last_camera_error: String = ""
var stage: int = 1
var _active: bool = false
var _profile: String = "standard"
var _floor: Dictionary = {}
var _rows: Dictionary = {}
var _deaths: Dictionary = {}
var _echo_records: Dictionary = {}
var _callbacks: Dictionary = {}
var _cue_callbacks: Array[Dictionary] = []
var _reflections: Dictionary = {}
var _pending_view: Dictionary = {}
var _view_observer: RequiredViewObserver
var _pre_consumer_guard_busy: bool = false
var _control_busy: bool = false
var _sun_state: Dictionary = {"effective_index":0}
var _codec = UnitCodec.new()
var _restore_expected: Dictionary = {}
var _restore_started: bool = false
var _restore_finished: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 130
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector3(0,0.1,34)
	add_child(spawn)
	threat_scheduler = Scheduler.new()
	threat_scheduler.name = "RetainedRegularScheduler"
	add_child(threat_scheduler)
	_view_observer = RequiredViewObserver.new()
	_view_observer.name = "ActualFullViewBeforeConsumers"
	_view_observer.observe = _guard_before_consumers
	add_child(_view_observer)
	var parent: Node = get_parent()
	if not parent.has_method("crystalman_regular_floor_binding") or not parent.has_method("crystalman_source_rows"):
		last_configuration_error = "Exact parent floor/layout services required"
		return
	_floor = parent.call("crystalman_regular_floor_binding")
	_rows = parent.call("crystalman_source_rows")
	var actual: Dictionary = Footprint.floor_signature(parent as Node3D, [_floor])
	if not actual.get("accepted",false): last_configuration_error = String(actual.get("reason","Actual full floor refused"))

func _on_enter_level() -> void:
	if not last_configuration_error.is_empty(): return
	_profile = String(shared_shell.call("get_difficulty_preference")) if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	if not threat_scheduler.begin_encounter(_profile, ENCOUNTER_ID,1): _fail(threat_scheduler.last_error); return
	_active = true
	_install_source(ENEMY_IDS[0])
	_update_presentation()

func _physics_process(_delta: float) -> void:
	if not _active or not is_instance_valid(hero) or hero.dead or not last_configuration_error.is_empty(): return
	_pending_view.clear()
	for id: String in ENEMY_IDS:
		if sources.has(id) and _rows[id].kind == "echo": _step_echo(id)
	_update_presentation()

func advance_to_plain() -> bool:
	if not _active or stage != 1 or _control_busy or get_tree().paused or not source_dead(ENEMY_IDS[0]) or _any_held(): return false
	_control_busy = true
	var ok: bool = _install_source(ENEMY_IDS[1]) and _install_source(ENEMY_IDS[2])
	if ok: stage = 2
	_control_busy = false
	_update_presentation()
	return ok

func source_dead(id: String) -> bool:
	return _deaths.has(id) and sources.has(id) and bool(sources[id].get("dead")) and float(sources[id].get("hp")) == 0.0 and not sources[id].is_in_group("enemies")

func all_regular_clear() -> bool:
	if stage != 2 or _any_held(): return false
	for id: String in ENEMY_IDS:
		if not source_dead(id): return false
	return true

func closed_regular_metadata() -> Dictionary:
	if not get_tree().paused or not all_regular_clear() or _control_busy or _pre_consumer_guard_busy: return {}
	var unit: Dictionary = capture_native_state(hero.snapshot_state(),false)
	if unit.is_empty(): return {}
	return {"source_ids":ENEMY_IDS.duplicate(),"deaths":_deaths.duplicate(true),"completed_at_actor_s":hero.get_world_action_clock(),"completed_at_unit_s":threat_scheduler.get_clock(),"disposition":"whole_unit_disposal","journal_sha256":Exact.stringify(unit.scheduler).sha256_text()}

func _all_scheduler_owners() -> Dictionary:
	return sources.duplicate()

func _current_enemy_ids() -> Array:
	return [ENEMY_IDS[0]] if stage == 1 else [ENEMY_IDS[1],ENEMY_IDS[2]]

func _update_presentation(_quiet: bool = false) -> void:
	objective_text = "ONE REAL ECHO / READ ITS OWN ROUTE\nRETURN TO THE GROUNDED KNOT" if stage == 1 else "TWO FAMILIAR SOURCES / CHOOSE THE OPENING\nKEEP THE NEXT LANDING CLEAR"
	if not last_configuration_error.is_empty(): objective_text = "CRYSTALMAN APPROACH UNAVAILABLE"

func _guard_before_consumers() -> void:
	if not _active or _pre_consumer_guard_busy or get_tree().paused or not is_instance_valid(hero) or hero.dead: return
	if not _any_held(): return
	_pre_consumer_guard_busy = true
	var error: String = _guard_union(camera_framing_union("",[],true,false),true)
	if not error.is_empty(): _cancel_held("crystalman_regular_actual_view_unreadable")
	else:
		for id: String in sources:
			if _rows[id].kind == "echo": _commit_due_echo(id)
	_pre_consumer_guard_busy = false

func _fail(reason: String) -> void:
	last_configuration_error = reason
	if _active: _cancel_held("crystalman_regular_invalid")

func _any_held() -> bool:
	for owner: Node3D in sources.values():
		if not threat_scheduler.source_control_state(owner).get("reservations",[]).is_empty(): return true
	return false

func actual_world_root() -> Node3D:
	# The outer level owns floor; its parent is the common source/Scheduler/Hero world.
	var outer: Node3D = get_parent() as Node3D
	return outer.get_parent() as Node3D if is_instance_valid(outer) else null

func scheduler_bindings() -> Dictionary:
	return {"world_root":actual_world_root(),"owners":sources.duplicate(),"actors":{"hero":hero},"floors":{FLOOR_ID:_floor}}

func floor_regions() -> Array:
	return [_floor.duplicate()]

func _source_held(id: String) -> bool:
	return sources.has(id) and not threat_scheduler.source_control_state(sources[id]).get("reservations",[]).is_empty()

func _cancel_held(reason: String) -> void:
	for id: String in sources:
		var error: String = _retire_source_held(id,reason)
		if not error.is_empty(): last_configuration_error = error

func _retire_source_held(id: String, reason: String, unfinished: bool = false) -> String:
	var source: Node3D = sources[id]
	var control: Dictionary = threat_scheduler.source_control_state(source)
	if control.is_empty(): return "Real retained owner control required"
	if control.reservations.is_empty(): return ""
	if _rows[id].kind == "echo":
		var current: Dictionary = source.call("state")
		if current.get("status") == "running": source.call("cancel",reason)
		elif not unfinished or (source.call("get_authored_cycle_restore_recipe") as Dictionary).is_empty(): return "Only genuine running or unfinished fresh authored owner may retire"
		if not threat_scheduler.source_control_state(source).get("reservations",[]).is_empty(): threat_scheduler.cancel_owner(source,reason)
	else: threat_scheduler.cancel_owner(source,reason)
	return "" if threat_scheduler.source_control_state(source).get("reservations",[]).is_empty() else "Held native owner did not retire"

func runtime_error() -> String:
	if not last_configuration_error.is_empty(): return last_configuration_error
	if global_transform != Transform3D.IDENTITY or not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not is_instance_valid(threat_scheduler) or threat_scheduler.get_script() != Scheduler or threat_scheduler.get_parent() != self: return "Exact local regular identity/shared bindings required"
	var floor: Dictionary = Footprint.floor_signature(actual_world_root(),[_floor])
	if not floor.get("accepted",false): return String(floor.get("reason","Actual floor refused"))
	for id: String in sources:
		if not is_instance_valid(sources[id]) or sources[id].get_parent() != self or sources[id].get_script() != (Stalker if _rows[id].kind == "stalker" else Echo): return "Original source recipient required: "+id
		if _rows[id].kind == "echo":
			var error: String = String(sources[id].call("source_native_error"))
			if not error.is_empty(): return error
	return ""

func _on_exit_level() -> void:
	_active = false
	if is_instance_valid(_view_observer): _view_observer.set_physics_process(false)
	for id: String in _callbacks:
		if is_instance_valid(sources.get(id)) and sources[id].is_connected("died",_callbacks[id]): sources[id].disconnect("died",_callbacks[id])
	for row: Dictionary in _cue_callbacks:
		if is_instance_valid(row.node) and row.node.is_connected("state_changed",row.callback): row.node.disconnect("state_changed",row.callback)
	for id: String in sources:
		if is_instance_valid(sources[id]):
			sources[id].set_physics_process(false)
			var error: String = _retire_source_held(id,"crystalman_regular_whole_disposal",is_restore_candidate() and _restore_started and not _restore_finished)
			if not error.is_empty(): push_error(error)
	# Whole subtree disposal releases managed journal. Do not end/reset/filter it.

func _install_source(id: String, prepare_managed: bool = true) -> bool:
	if sources.has(id) or not _rows.has(id) or _rows[id].kind not in ["stalker", "echo"]:
		_fail("Only one genuine fresh entitled original source may be installed: " + id)
		return false
	var row: Dictionary = _rows[id]
	var source: Node3D = Stalker.new() if row.kind == "stalker" else Echo.new()
	source.name = id.replace("-", "_")
	add_child(source)
	sources[id] = source
	if row.kind == "stalker":
		source.global_position = Value.read_vector3(row.position_world)
		if not source.call("configure",id,hero,effects,threat_scheduler,combat_response.bind(id)): _fail(id+": "+String(source.get("last_error"))); return false
		source.call("set_sun_visual",0)
		var callback: Callable = _on_actor_died.bind(id)
		_callbacks[id] = callback
		source.connect("died",callback)
		return true
	var signature: Dictionary = Footprint.floor_signature(actual_world_root(), [_floor])
	if not signature.get("accepted", false):
		_fail(String(signature.get("reason", "Actual complete garden floor signature required")))
		return false
	var context: Dictionary = {"world_root": actual_world_root(), "source_id": id, "source_epoch": String(row.source_epoch_recipe), "generation": 1, "world_collision_fingerprint": threat_scheduler.pure_collision_fingerprint(actual_world_root()), "world_floor_signature": signature.signature}
	var prepared: Dictionary = {"world_revision": WORLD_REVISION, "collision_fingerprint": context.world_collision_fingerprint, "floor_signature": context.world_floor_signature}
	if not source.call("configure_source", id, context.source_epoch, 1, native_definition(id), _profile, prepared, threat_scheduler) or not source.call("retain_source_environment", actual_world_root(), [_floor]) or (prepare_managed and (not source.call("enable_authored_cycle_tracking", threat_scheduler, {"hero": hero}, [_floor], context) or not source.call("source_cycles_managed"))):
		_fail(id + ": " + String(source.get("source_snapshot_error")) + "; " + String(source.get("last_error")))
		return false
	_echo_records[id] = {"context": context, "projection": {}, "lease": {}, "proof": {}, "positions": [], "locked": false, "admissions": []}
	_build_reflection(id, Value.read_vector3(row.definition_translation_world))
	var callback: Callable = _on_echo_died.bind(id)
	_callbacks[id] = callback
	source.connect("died", callback)
	return true


func _on_actor_died(_where: Vector3, id: String) -> void:
	_record_death(id)

func _on_echo_died(id: String) -> void:
	_record_death(id)

func _record_death(id: String) -> void:
	if not _active or _deaths.has(id) or not sources.has(id):
		return
	var source: Node3D = sources[id]
	if not bool(source.get("dead")) or float(source.get("hp")) != 0.0 or source.is_in_group("enemies"):
		return
	_deaths[id] = {"clock_s": threat_scheduler.get_clock(), "source_position": Value.vector3(source.global_position)}
	_update_presentation()

func native_definition(id: String) -> Dictionary:
	if not _rows.has(id) or _rows[id].kind != "echo":
		return {}
	# Reuse the actual owned finite recipe; only canonical identity/translation differ.
	var recipe: Node = EchoRecipe.new()
	var definition: Dictionary = recipe.call("native_definition")
	recipe.free()
	var row: Dictionary = _rows[id]
	definition.definition_id = String(row.definition_id)
	definition.route = []
	for point: Dictionary in row.own_route_world:
		definition.route.append({"position": Value.read_vector3(point.position), "at_s": float(point.at_s)})
	definition.slash.world_origin = Value.read_vector3(row.slash_origin_world)
	definition.slash.direction = Value.read_vector3(row.slash_direction_world)
	return definition

func combat_response(id: String) -> Dictionary:
	if not is_instance_valid(hero) or not sources.has(id):
		return {}
	var response: Dictionary = hero.get_threat_response_state()
	var directions: Array[Vector3] = []
	if _rows[id].kind == "stalker":
		var away: Vector3 = hero.global_position - (sources[id] as Node3D).global_position
		away.y = 0.0
		if away.length_squared() > 0.0001:
			var side: Vector3 = Vector3.UP.cross(away.normalized())
			if int(sources[id].call("state").get("effective_sun", 0)) == 1:
				side = -side
			directions.append(side)
			directions.append(-side)
	for direction: Vector3 in [Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3(-1, 0, -1).normalized(), Vector3(-1, 0, 1).normalized(), Vector3(1, 0, -1).normalized(), Vector3(1, 0, 1).normalized()]:
		if not directions.has(direction):
			directions.append(direction)
	response.merge({"world_root": actual_world_root(), "world_revision": WORLD_REVISION, "encounter_id": ENCOUNTER_ID, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [_floor]}, true)
	return response

func _commit_due_echo(id: String) -> void:
	var source: Node3D = sources[id]
	if bool(source.get("dead")) or hero.dead or (source.call("state") as Dictionary).get("status") != "running": return
	var data: Dictionary = _echo_records[id]
	var lease: Dictionary = threat_scheduler.replay_reservation_state(String(data.lease.get("id", "")))
	if lease.is_empty() or data.locked or threat_scheduler.get_clock() < float(lease.lock_from_s): return
	var answer: Dictionary = threat_scheduler.commit_authored_replay(String(lease.id), combat_response(id))
	if not _active or not is_instance_valid(hero) or hero.dead or not is_instance_valid(source):
		return
	if not answer.get("accepted", false):
		last_admission_reason = String(answer.get("reason", "Actual Echo lock rejected"))
		return
	var control: Dictionary = threat_scheduler.source_control_state(source)
	if control.is_empty() or control.reservations.size() != 1 or control.reservations[0].id != lease.id or (source.call("state") as Dictionary).get("status") != "running":
		return # Genuine native commit observers already cancelled this lease.
	data.locked = true
	data.lease = answer.reservation.duplicate(true)
	data.proof = answer.proof.duplicate(true)
	data.positions = _proof_positions(answer.proof)
	if not _view_guard(id, true).is_empty():
		var error: String = _retire_source_held(id, "crystalman_regular_locked_echo_view_unreadable")
		if not error.is_empty(): _fail(error)

func _try_echo(id: String) -> void:
	var source: Node3D = sources[id]
	var data: Dictionary = _echo_records[id]
	var program: Dictionary = source.call("source_program")
	var proof: Dictionary = Witness.new().prove_authored(threat_scheduler, source, program, combat_response(id), data.context)
	if not proof.get("accepted", false):
		last_admission_reason = id + ": " + String(proof.get("reason", "Native Echo witness rejected"))
		return
	var projection: Dictionary = Footprint.plan_authored(threat_scheduler, program, actual_world_root(), [_floor], data.context)
	if not projection.get("accepted", false):
		last_admission_reason = String(projection.get("reason", "Actual complete Echo projection rejected"))
		return
	_pending_view = {"id": id, "kind": "echo", "projection": projection, "proof": proof, "positions": _proof_positions(proof)}
	if not _view_guard(id, false).is_empty() or not _view_guard(id, true).is_empty():
		return # Normal shared framing may settle this fresh pure candidate.
	var answer: Dictionary = threat_scheduler.request_authored_replay(source, program, combat_response(id), data.context)
	if not _active or not is_instance_valid(hero) or hero.dead or not is_instance_valid(source):
		return
	if not answer.get("accepted", false):
		last_admission_reason = String(answer.get("reason", "Actual Echo admission rejected"))
		return
	data.projection = projection
	data.lease = answer.reservation.duplicate(true)
	data.proof = answer.proof.duplicate(true)
	data.positions = _proof_positions(answer.proof)
	data.locked = false
	data.admissions.append({"generation": int(data.context.generation), "reservation_id": String(answer.reservation_id), "clock_s": threat_scheduler.get_clock()})
	_pending_view.clear()
	if not source.call("bind_projected", threat_scheduler, String(answer.reservation_id), {"hero": hero}, [_floor], projection, data.context):
		threat_scheduler.cancel(String(answer.reservation_id), "crystalman_regular_projection_binding_failed")
		_fail(id + ": " + String(source.get("last_error")))
		return
	_bind_echo_cues(id)
	last_admission_reason = ""

func _proof_positions(proof: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for segment: Dictionary in proof.get("path", []):
		for key: String in ["from", "to"]:
			var point: Variant = segment.get(key)
			if point is Vector3 and not points.has(point):
				points.append(point)
	return points

func _append_mesh(points: Array, mesh: Mesh, transform: Transform3D) -> void:
	var bounds: AABB = mesh.get_aabb()
	for index: int in range(8):
		points.append(transform * bounds.get_endpoint(index))

func _enclosure(points: Array) -> Dictionary:
	if points.is_empty() or not points[0] is Vector3:
		return _bounds_error("Complete native corner group required")
	var low: Vector3 = points[0]
	var high: Vector3 = points[0]
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			return _bounds_error("Native finite bounded world corners required")
		low = low.min(point)
		high = high.max(point)
	var corners: Array = []
	var box := AABB(low, high - low)
	for index: int in range(8):
		corners.append(box.get_endpoint(index))
	return {"error": "", "points": corners}

func _bounds_error(reason: String) -> Dictionary:
	return {"error": reason, "points": []}

func _quiet_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.albedo_color = color
	return material

func _build_reflection(id: String, translation: Vector3) -> void:
	# Unchanged finite outline vocabulary; no collider/group/clock/interaction.
	var reflection := Node3D.new()
	reflection.name = id.replace("-", "_") + "_HarmlessOutline"
	reflection.position = translation + Vector3(-1.4, 0.02, -2.1)
	add_child(reflection)
	var parts: Array = [[Vector3(0.055, 0.90, 0.06), Vector3(-0.23, 0.56, 0)], [Vector3(0.055, 0.90, 0.06), Vector3(0.23, 0.56, 0)], [Vector3(0.51, 0.055, 0.06), Vector3(0, 1.04, 0)], [Vector3(0.51, 0.055, 0.06), Vector3(0, 0.26, 0)], [Vector3(0.055, 0.23, 0.06), Vector3(-0.17, 1.25, 0)], [Vector3(0.055, 0.23, 0.06), Vector3(0.17, 1.25, 0)], [Vector3(0.39, 0.05, 0.06), Vector3(0, 1.39, 0)], [Vector3(0.39, 0.05, 0.06), Vector3(0, 1.12, 0)]]
	for part: Array in parts:
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = part[0]
		visual.mesh = mesh
		visual.position = part[1]
		visual.material_override = _quiet_material(Color(0.48, 0.47, 0.56))
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		reflection.add_child(visual)
	_reflections[id] = reflection

func _bind_echo_cues(id: String) -> void:
	for cue: Node3D in sources[id].call("get_cues"):
		var callback: Callable = _on_echo_cue.bind(id)
		if not cue.is_connected("state_changed", callback):
			cue.connect("state_changed", callback)
			_cue_callbacks.append({"node": cue, "callback": callback})

func _on_echo_cue(_cue_state: Dictionary, id: String) -> void:
	# The shared cue callback precedes its native active delivery guard. A bad
	# current view cancels before damage; the parent never authorizes a hit.
	if _active and not _pre_consumer_guard_busy and sources.has(id) and sources[id].call("state").get("status") == "running" and not _view_guard(id, true).is_empty():
		var error: String = _retire_source_held(id, "crystalman_regular_required_echo_cue_view_unreadable")
		if not error.is_empty(): _fail(error)

func _step_echo(id: String) -> void:
	var source: Node3D = sources[id]
	if bool(source.get("dead")) or hero.dead:
		return
	var data: Dictionary = _echo_records[id]
	var phase: String = String(source.call("source_phase"))
	var playback: Dictionary = source.call("state")
	if playback.get("status") == "running":
		if not _view_guard(id, true).is_empty():
			var error: String = _retire_source_held(id, "crystalman_regular_current_echo_view_unreadable")
			if not error.is_empty(): _fail(error)
			return
		return
	if phase in ["complete", "cancelled"]:
		var terminal: Dictionary = source.call("get_authored_cycle_terminal_receipt")
		if terminal.is_empty() or not threat_scheduler.reservations().is_empty():
			return
		var generation: int = int(source.call("get_authored_cycle_generation")) + 1
		var reader := Authored.new()
		if not reader.configure(id + "/own-sequence/g%d" % generation, source.call("source_definition"), id, String(_rows[id].source_epoch_recipe), generation, String(source.call("source_profile")), source.call("prepared_world")):
			_fail(id + ": " + reader.last_error)
			return
		if not source.call("prepare_next_authored_cycle", id + "/playback/g%d" % generation, reader.snapshot_state()):
			last_admission_reason = String(source.get("last_error")) # Cooldown/retired-cue readiness remains canonical.
			return
		data.context.generation = generation
		data.projection = {}
		data.lease = {}
		data.proof = {}
		data.positions = []
		data.locked = false
		return
	if playback.get("status") in ["idle", "cycle_ready"] and hero.is_on_floor() and hero.get_threat_response_state().get("stable", false) and threat_scheduler.reservations().is_empty():
		_try_echo(id)

func _view_guard(id: String, current: bool) -> String:
	var candidate: Dictionary = {}
	if _pending_view.get("kind") == "echo" and _pending_view.get("id") == id:
		candidate = _echo_bounds(id, _pending_view)
	if not candidate.is_empty() and not String(candidate.error).is_empty():
		return String(candidate.error)
	var union: Dictionary = camera_framing_union(id, candidate.points, current, false) if not candidate.is_empty() else camera_framing_union("", [], current, false)
	return _guard_union(union, current)

func _guard_union(union: Dictionary, current_view: bool) -> String:
	if not String(union.get("error", "Actual native union unavailable")).is_empty():
		last_camera_error = String(union.error)
	elif union.points.is_empty():
		last_camera_error = "Complete actual required source/cue/Hero union unavailable"
	elif current_view:
		last_camera_error = String(shared_shell.call("camera_framing_error", union.points))
	else:
		var plan: Dictionary = shared_shell.call("camera_framing_plan", union.points, hero.global_position + Vector3.UP * 0.75)
		last_camera_error = "" if plan.get("accepted", false) else String(plan.get("reason", "Complete prospective native portrait does not fit"))
	return last_camera_error

func _echo_bounds(id: String, prospective: Dictionary = {}, framing_camera: Camera3D = null) -> Dictionary:
	var source: Node3D = sources[id]
	var art: Dictionary = source.call("framing_points")
	if not String(art.get("error", "Actual retained own-sequence Echo bounds required")).is_empty():
		return _bounds_error(String(art.error))
	var points: Array = art.points.duplicate()
	var data: Dictionary = _echo_records[id] if prospective.is_empty() else prospective
	var projection: Dictionary = data.get("projection", {})
	if projection.is_empty():
		return _bounds_error("Actual complete native Echo projection required")
	for event: Dictionary in projection.events:
		if not event.get("bounds") is Array or event.bounds.size() != 4:
			return _bounds_error("Whole actual projected footprint bounds required")
		for x: float in [float(event.bounds[0]), float(event.bounds[2])]:
			for z: float in [float(event.bounds[1]), float(event.bounds[3])]:
				points.append(Vector3(x, float(event.floor_y) + CinderThreatCue.FLOOR_OFFSET, z))
	var origin: Vector3 = (source.call("source_definition") as Dictionary).slash.world_origin
	for phase: String in ["warning", "lock", "active", "recovery"]:
		_append_mesh(points, CueMeshes.source_mesh(phase), Transform3D(Basis.IDENTITY, origin + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004)))
	for cue: Node3D in source.call("get_cues"):
		_append_actual_cue(points, cue)
	var route: MeshInstance3D = source.get_node_or_null("ExactHarmlessRoutes") as MeshInstance3D
	if route != null and route.is_visible_in_tree() and route.mesh != null:
		_append_mesh(points, route.mesh, route.global_transform)
	var reflection_error: String = _append_reflection(points, id)
	if not reflection_error.is_empty():
		return _bounds_error(reflection_error)
	var error: String = _append_hero_forecasts(points, data.get("positions", []), framing_camera)
	return _enclosure(points) if error.is_empty() else _bounds_error(error)

func _echo_current_bounds(id: String) -> Dictionary:
	var source: Node3D = sources[id]
	var error: String = String(source.call("source_native_error"))
	if not error.is_empty():
		return _bounds_error(error)
	var points: Array = []
	var renderer: Node3D = source.call("get_authored_echo_renderer")
	if not is_instance_valid(renderer):
		return _bounds_error("Actual original porcelain renderer required")
	for view: MeshInstance3D in renderer.get("required_visuals"):
		if view.is_visible_in_tree():
			_append_mesh(points, view.mesh, view.global_transform)
	var knot: MeshInstance3D = source.get_node_or_null("FixedLowRecoveryKnot") as MeshInstance3D
	if knot == null or not knot.is_visible_in_tree() or knot.mesh == null:
		return _bounds_error("Actual complete retained low Echo knot required")
	_append_mesh(points, knot.mesh, knot.global_transform)
	var marker: CinderAct3MirrorEchoSpentMarker = source.get_node_or_null("SpentEchoMarker") as CinderAct3MirrorEchoSpentMarker
	if marker == null:
		return _bounds_error("Original retained Echo spent marker required")
	var spent: Dictionary = marker.framing_points(bool(source.get("dead")))
	if not String(spent.error).is_empty():
		return _bounds_error(String(spent.error))
	points.append_array(spent.points)
	for cue: Node3D in source.call("get_cues"):
		_append_actual_cue(points, cue)
	var reflection_error: String = _append_reflection(points, id)
	return _enclosure(points) if reflection_error.is_empty() else _bounds_error(reflection_error)

func _append_reflection(points: Array, id: String) -> String:
	if not is_instance_valid(_reflections.get(id)):
		return "Original harmless outline required beside the current actual Echo"
	for child: Node in _reflections[id].get_children():
		var view: MeshInstance3D = child as MeshInstance3D
		if view == null or not view.is_visible_in_tree() or view.mesh == null:
			return "Complete harmless outline native geometry required"
		_append_mesh(points, view.mesh, view.global_transform)
	return ""

func _append_hero_forecasts(points: Array, positions: Array, framing_camera: Camera3D = null) -> String:
	var camera: Camera3D = framing_camera if framing_camera != null else get_viewport().get_camera_3d()
	var native: Array = shared_shell.call("player_camera_framing_points_for", hero, camera)
	if native.is_empty() or positions.is_empty():
		return "Complete actual Hero and selected native path positions required"
	for position: Variant in positions:
		if not position is Vector3 or not position.is_finite():
			return "Actual selected proof path positions must be finite"
		for corner: Vector3 in native:
			points.append(corner + position - hero.global_position)
	return ""

func _append_actual_cue(points: Array, cue: Node3D) -> void:
	if not is_instance_valid(cue):
		return
	for child: Node in cue.get_children():
		if child is MeshInstance3D:
			var view: MeshInstance3D = child as MeshInstance3D
			if view.is_visible_in_tree() and view.mesh != null:
				_append_mesh(points, view.mesh, view.global_transform)

func _camera_framing_points() -> Array:
	if not _active or not is_instance_valid(hero):
		return []
	var result: Dictionary = camera_framing_union()
	last_camera_framing_error = String(result.error)
	return result.points if last_camera_framing_error.is_empty() else []

func camera_framing_union(candidate_id: String = "", candidate_points: Array = [], current_view: bool = false, include_pending: bool = true, core_prospective: Dictionary = {}, framing_camera: Camera3D = null) -> Dictionary:
	if not _active or not last_configuration_error.is_empty() or not is_instance_valid(shared_shell) or not is_instance_valid(hero):
		return _bounds_error("Actual entered parent/Hero/presentation bindings required")
	if not candidate_id.is_empty() and not sources.has(candidate_id):
		return _bounds_error("Prospective source must be genuinely installed")
	if candidate_id.is_empty() and not candidate_points.is_empty():
		return _bounds_error("Prospective bounds require their actual source ID")
	var camera: Camera3D = framing_camera if framing_camera != null else get_viewport().get_camera_3d()
	var native_hero: Array = shared_shell.call("player_camera_framing_points_for", hero, camera)
	var hero_bounds: Dictionary = _enclosure(native_hero)
	if not String(hero_bounds.error).is_empty():
		return hero_bounds
	var points: Array = hero_bounds.points.duplicate()
	if not candidate_id.is_empty():
		var candidate: Dictionary = _enclosure(candidate_points)
		if not String(candidate.error).is_empty():
			return candidate
		points.append_array(candidate.points)
	var current_ids: Array = _current_enemy_ids()
	for id: String in ENEMY_IDS:
		if id == candidate_id or not sources.has(id):
			continue
		var source: Node3D = sources[id]
		var bounds: Dictionary = {}
		var held: bool = _source_held(id)
		if not held and id not in current_ids:
			continue # Remote inactive history cannot force a whole-level camera.
		if _rows[id].kind == "stalker":
			# The live Stalker checks this union inside its native physics
			# transaction. Its existing live bounds helper supports that call;
			# quiet restore/context queries deliberately reject transactions.
			var live_context: bool = framing_camera == null and not get_tree().paused and not is_restore_candidate() and shared_shell.get("player") == hero and shared_shell.get("camera") == camera
			if held and live_context:
				bounds = source.call("camera_framing_points", shared_shell, {}, {}, current_view)
			else:
				bounds = source.call("camera_framing_points_for_context", shared_shell, hero, camera, {}, {}, current_view) if held else source.call("current_render_framing_points_for_context", shared_shell, hero, camera)
		else:
			bounds = _echo_bounds(id, {}, camera) if held else _echo_current_bounds(id)
		if not String(bounds.get("error", "Complete native source corners required")).is_empty():
			return _bounds_error(id + ": " + String(bounds.error))
		if bounds.points.is_empty() and bool(source.get("dead")) and float(source.get("hp")) == 0.0 and not source.is_in_group("enemies"):
			continue # Native hidden-dead Stalker policy; no fake pixel requirement.
		var enclosed: Dictionary = _enclosure(bounds.points)
		if not String(enclosed.error).is_empty():
			return enclosed
		points.append_array(enclosed.points)
	if include_pending and not _pending_view.is_empty():
		var id: String = String(_pending_view.get("id", ""))
		if id != candidate_id and sources.has(id) and not _source_held(id):
			var bounds: Dictionary = _echo_bounds(id, _pending_view, camera)
			if not String(bounds.error).is_empty():
				return bounds
			points.append_array(bounds.points)
	if points.size() > 224:
		return _bounds_error("Complete actual current/held/chosen native groups exceed224 corners")
	return {"error": "", "points": points}


func current_echo_commit(id: String) -> Dictionary:
	# Defensive observation of the genuine Scheduler commit result. Re-proving
	# after arming is forbidden; this never admits, retimes or mutates a lease.
	if not _echo_records.has(id): return {}
	var data: Dictionary = _echo_records[id]
	return {"locked":data.locked,"lease":data.lease.duplicate(true),"proof":data.proof.duplicate(true)}

func regular_owned_state() -> Dictionary:
	var view: Dictionary = {}
	for id: String in _echo_records:
		var positions: Array = []
		for at: Vector3 in _echo_records[id].positions: positions.append(Value.vector3(at))
		view[id] = positions
	return {"deaths":_deaths.duplicate(true),"view":view}

func capture_native_state(player: Dictionary,optical: bool = true) -> Dictionary:
	return _codec.capture(self,player,optical)

func native_capture_error() -> String:
	return _codec.last_error

func native_state_error(local: Dictionary,player: Dictionary) -> String:
	return _codec.record_error(local,self,player)

func regular_apply_owned_state(unit: Dictionary) -> String:
	stage = unit.stage
	_deaths = unit.deaths.duplicate(true)
	var world: Dictionary = UnitCodec.native_world(self)
	for id: String in _echo_records:
		var source: Node3D = sources[id]
		_echo_records[id].context = UnitCodec.echo_context(world,self,id,int(source.call("get_authored_cycle_generation")))
		_echo_records[id].projection = source.call("get_footprint_projection")
		_echo_records[id].lease = {}
		var actual: Dictionary = source.call("state")
		if actual.get("status") == "running":
			var control: Dictionary = threat_scheduler.source_control_state(source)
			if control.reservations.size() != 1 or control.reservations[0].id != actual.reservation_id: return "Actual restored Echo held binding differs"
			_echo_records[id].lease = control.reservations[0].duplicate(true)
		_echo_records[id].positions = []
		for at: Array in unit.view[id]: _echo_records[id].positions.append(Value.read_vector3(at))
		_echo_records[id].locked = bool(_echo_records[id].lease.get("adapter",{}).get("locked",false))
		_echo_records[id].proof = {}
		_echo_records[id].admissions = []
		_bind_echo_cues(id)
	_pending_view.clear()
	_active = true
	_update_presentation(true)
	return runtime_error()

func _parent_local_envelope(local: Dictionary) -> Dictionary:
	# Outer parent alone owns production progress; child never requests it.
	return {"api_revision":CinderLevel.API_REVISION,"schema_version":1,"level_id":level_id,"scene_path":scene_file_path,"local_snapshot_version":local_snapshot_version,"progress":{"completed":false,"completion_id":"","contact_exit_id":"","checkpoint_id":"","checkpoint_kind":"","checkpoint_ids":{}},"local":local.duplicate(true)}

func prepare_parent_restore(local: Dictionary,player: Dictionary,parent_hero: CinderPlayer,parent_effects: PixelEffects,shell: Node) -> bool:
	return enter_restore_candidate(parent_hero,parent_effects,shell,_parent_local_envelope(local),player)

func restore_parent_state(local: Dictionary,player: Dictionary) -> bool:
	if Exact.stringify(player) != Exact.stringify(hero.snapshot_state()): return false
	return restore_state(_parent_local_envelope(local))

func verify_parent_candidate(local: Dictionary,player: Dictionary,camera: Camera3D,hud: GameHUD) -> String:
	var again: Dictionary = _codec.capture(self,player,false)
	if again.is_empty(): return _codec.last_error
	if not UnitCodec.same(again,local): return "Actual quiet regular candidate differs"
	return _codec.presentation_error(self,camera,hud)

func _on_enter_restore_candidate(local: Dictionary,player: Dictionary) -> String:
	_active = false
	if not local.get("world") is Dictionary or not local.world.get("profile_id") is String or not local.get("stage") is int or local.stage not in [1,2]: return "Closed entitled regular constructor recipe required"
	_profile = local.world.profile_id
	stage = local.stage
	if not threat_scheduler.begin_encounter(_profile,ENCOUNTER_ID,1): return threat_scheduler.last_error
	for id: String in UnitCodec.entitled(stage):
		if not _install_source(id,false): return last_configuration_error
	return _codec.prepare_sources(local,self,player)

func _capture_local_state() -> Dictionary:
	return _codec.capture(self,hero.snapshot_state())

func _local_snapshot_error(local: Dictionary) -> String:
	return _codec.record_error(local,self,hero.snapshot_state())

func _local_snapshot_error_with_player(local: Dictionary,player: Dictionary) -> String:
	return _codec.record_error(local,self,player)

func _restore_local_state(local: Dictionary) -> void:
	_restore_expected = local.duplicate(true)
	_restore_started = true
	_restore_finished = _codec.restore_local(local,self,hero.snapshot_state())
	last_snapshot_error = _codec.last_error

func restore_state(saved: Dictionary) -> bool:
	if not is_restore_candidate(): last_snapshot_error = "Only fresh whole regular candidates may restore"; return false
	var ok: bool = super.restore_state(saved)
	if not _restore_finished: last_snapshot_error = _codec.last_error; return false
	return ok

func restore_candidate_construction_required() -> bool:
	return true

func finish_restore_candidate() -> bool:
	var ok: bool = super.finish_restore_candidate()
	if ok: _restore_expected.clear(); _restore_started = false; _restore_finished = false
	return ok

func _restore_candidate_presentation_error(camera: Camera3D,hud: GameHUD) -> String:
	if not _restore_finished: return "Actual quiet regular commit required before optics"
	return verify_parent_candidate(_restore_expected,hero.snapshot_state(),camera,hud)

func has_held_attacks() -> bool:
	return _any_held()
