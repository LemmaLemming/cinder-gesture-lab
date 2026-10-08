extends CinderLevel
## Temporary one-source room. This is not the complete A1-L2 campaign scene.
## One shared hero/camera/controller, shared scheduler motion and cues.

const RusherScript = preload("res://scripts/acts/act1/rush_selenite.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Equipment = preload("res://scripts/equipment.gd")
const SOURCE_ID: String = "a1_l2_greybox_rusher"
const ENCOUNTER_ID: String = "a1_l2_rusher_greybox"
const LIVE_OBJECTIVE: String = "RUSH GREYBOX · READ THE LANE\nDASH BESIDE IT · AIM A PRIMARY AT RECOVERY"
const CLEAR_OBJECTIVE: String = "RUSH GREYBOX CLEAR · ORDINARY PRIMARY\nFULL CRATER GARDENS REMAINS IN DEVELOPMENT"

var scheduler: CinderThreatScheduler
var rusher: CharacterBody3D
var last_admission: Dictionary = {}
var admission_enabled: bool = true
var last_capture_error: String = ""
var _forecast_points: Array = []
var _framing_witness: Dictionary = {}


func _ready() -> void:
	process_physics_priority = 200
	scheduler = CinderThreatScheduler.new()
	scheduler.name = "LunarThreatScheduler"
	add_child(scheduler)
	rusher = RusherScript.new()
	rusher.name = "RushSelenite"
	rusher.position = Vector3(0, 0.005, 0)
	rusher.call("configure", SOURCE_ID)
	add_child(rusher)
	rusher.set("presentation_guard", Callable(self, "presentation_error"))
	_build_edges()


func _build_edges() -> void:
	for spec: Array in [[Vector3(-7, 0.2, 0), Vector3(0.2, 0.4, 12), "WestEdge"], [Vector3(7, 0.2, 0), Vector3(0.2, 0.4, 12), "EastEdge"], [Vector3(0, 0.2, -6), Vector3(14, 0.4, 0.2), "NorthEdge"], [Vector3(0, 0.2, 6), Vector3(14, 0.4, 0.2), "SouthEdge"]]:
		var body := StaticBody3D.new()
		body.name = spec[2]
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = spec[0]
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = spec[1]
		collision.shape = shape
		body.add_child(collision)
		var visible_edge := MeshInstance3D.new()
		visible_edge.name = "VisibleEdge"
		var box := BoxMesh.new()
		box.size = spec[1]
		visible_edge.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.18, 0.18, 0.19)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		visible_edge.material_override = material
		body.add_child(visible_edge)
		add_child(body)


func _on_enter_level() -> void:
	rusher.call("bind", scheduler, hero)
	scheduler.begin_encounter("standard", ENCOUNTER_ID, 1)
	objective_text = LIVE_OBJECTIVE


func _on_exit_level() -> void:
	if is_instance_valid(rusher):
		if rusher.is_inside_tree():
			rusher.call("cancel", "greybox_exit")
		rusher.set_physics_process(false)
		rusher.remove_from_group("enemies")
	if is_instance_valid(scheduler):
		if scheduler.is_inside_tree():
			scheduler.end_encounter("greybox_exit")
		scheduler.set_physics_process(false)
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(hero) or hero.dead or not admission_enabled:
		return
	var source: Dictionary = rusher.call("state")
	objective_text = CLEAR_OBJECTIVE if source.dead else LIVE_OBJECTIVE
	if source.dead:
		_forecast_points.clear()
		_framing_witness.clear()
		return
	if not String(source.reservation_id).is_empty() or not hero.get_threat_response_state().stable:
		return
	var direction: Vector3 = hero.global_position - rusher.global_position
	direction.y = 0.0
	if direction.length() > 4.5 or direction.length() < 0.1:
		return
	direction = direction.normalized()
	_forecast_points = _source_points(rusher.global_position + direction * 2.4)
	_forecast_points.append_array(_lane_points(Geometry.lane(rusher.global_position, rusher.global_position + direction * 2.4, 0.38)))
	if is_instance_valid(shared_shell):
		var proposed: Dictionary = shared_shell.call("camera_framing_plan", _forecast_points, hero.global_position + Vector3(0, 0.65, 0))
		if not proposed.get("accepted", false) or not String(shared_shell.call("camera_framing_error", _forecast_points)).is_empty():
			return
	last_admission = rusher.call("start", response_context(), direction)
	if last_admission.get("accepted", false):
		_framing_witness = {"reservation_id": last_admission.reservation_id, "landing": last_admission.proof.landing, "attack_position": last_admission.proof.attack_position}
	else:
		_forecast_points.clear()
		_framing_witness.clear()


func scheduler_bindings() -> Dictionary:
	return {"world_root": self, "owners": {SOURCE_ID: rusher}, "floors": {"lunar_floor": {"collision": get_node_or_null("Floor/CollisionShape3D"), "safe_rect": Rect2(-7, -6, 14, 12)}}}


func response_context() -> Dictionary:
	var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			directions.append(Vector3(x, 0, z).normalized())
	for x: float in [-0.6, 0.6, -0.8, 0.8]:
		var z: float = sqrt(1.0 - x * x)
		directions.append(Vector3(x, 0, z))
		directions.append(Vector3(x, 0, -z))
	# Diagonal ordinary returns keep the two silhouettes separated in portrait.
	# The shared solver still proves the actual full dash and primary reach.
	var returns: Array[Vector3] = [Vector3(-1, 0, -1).normalized(), Vector3(1, 0, -1).normalized(), Vector3(-1, 0, 1).normalized(), Vector3(1, 0, 1).normalized()]
	for direction: Vector3 in directions:
		if not returns.has(direction):
			returns.append(direction)
	return {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.18, "attack_input_margin_s": 0.08, "escape_directions": directions, "return_directions": returns, "floor_regions": [scheduler_bindings().floors.lunar_floor]}


func presentation_error() -> String:
	if not is_instance_valid(shared_shell):
		return ""
	return String(shared_shell.call("camera_framing_error", _camera_framing_points()))


func _camera_framing_points() -> Array:
	if not is_instance_valid(rusher):
		return []
	var source: Dictionary = rusher.call("state")
	if source.dead:
		return []
	if String(source.reservation_id).is_empty():
		return _forecast_points.duplicate()
	var points: Array = _source_points(source.opening_position)
	var shape: Dictionary = source.geometry
	if shape.get("kind") == "lane":
		points.append_array(_lane_points(shape))
	for key: String in ["landing", "attack_position"]:
		if _framing_witness.get(key) is Vector3:
			points.append_array(_box_points(AABB(Vector3(-0.32, 0, -0.32), Vector3(0.64, 1.45, 0.64)), Transform3D(Basis.IDENTITY, _framing_witness[key])))
	return points


func _lane_points(shape: Dictionary) -> Array:
	var points: Array = []
	for centre: Vector3 in [shape.from, shape.to]:
		points.append_array(_box_points(AABB(Vector3(-shape.radius, 0, -shape.radius), Vector3(shape.radius * 2.0, 0.08, shape.radius * 2.0)), Transform3D(Basis.IDENTITY, centre)))
	return points


func _source_points(endpoint: Vector3) -> Array:
	var points: Array = []
	# Cue meshes already describe the actual committed footprint. Only actor
	# presentation is translated to a future body pose; never duplicate the lane.
	var presentation: Node3D = rusher.get_node("TemporaryC30Presentation")
	for node: Node in presentation.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh != null and mesh.is_visible_in_tree():
			points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
			# This temporary native mesh has three authored poses. Bound every
			# pose now, before crouching can hide the future standing/rush extent.
			if mesh.name == "StandingCrouchingBody":
				var parent_transform: Transform3D = (mesh.get_parent() as Node3D).global_transform
				for pose: Transform3D in [Transform3D(Basis.IDENTITY, Vector3(0, 0.75, 0)), Transform3D(Basis(Vector3.RIGHT, 0.24), Vector3(0, 0.75, 0)), Transform3D(Basis.IDENTITY.scaled(Vector3(1, 0.68, 1)), Vector3(0, 0.48, 0))]:
					points.append_array(_box_points(mesh.get_aabb(), parent_transform * pose))
	var current: Array = points.duplicate()
	for point: Vector3 in current:
		points.append(point + endpoint - rusher.global_position)
	return points


func _box_points(bounds: AABB, transform: Transform3D) -> Array:
	var points: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(transform * Vector3(x, y, z))
	return points


func _capture_local_state() -> Dictionary:
	last_capture_error = ""
	var paired: Dictionary = scheduler.snapshot_state(scheduler_bindings())
	if paired.is_empty():
		last_capture_error = scheduler.last_snapshot_error
		return {}
	var actor: Dictionary = rusher.call("snapshot_state", paired)
	if actor.is_empty():
		last_capture_error = rusher.get("last_snapshot_error")
		return {}
	var framing: Dictionary = {}
	if not actor.reservation_id.is_empty():
		framing = {"reservation_id": _framing_witness.get("reservation_id", ""), "landing": Codec.vector3(_framing_witness.get("landing", Vector3.INF)), "attack_position": Codec.vector3(_framing_witness.get("attack_position", Vector3.INF))}
	return {"scheduler": paired, "rusher": actor, "framing_witness": framing}


func _local_snapshot_error(state: Dictionary) -> String:
	return _validate_pair(state, hero.snapshot_state())


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	return _validate_pair(state, saved_player)


func _validate_pair(state: Dictionary, saved_player: Dictionary) -> String:
	if state.is_empty() and not last_capture_error.is_empty():
		return "Greybox capture: " + last_capture_error
	if not Codec.keys_error(state, ["scheduler", "rusher", "framing_witness"]).is_empty() or not state.scheduler is Dictionary or not state.rusher is Dictionary or not state.framing_witness is Dictionary:
		return "Greybox requires exactly scheduler, C30 and retained framing witness envelopes"
	var error: String = rusher.call("actor_snapshot_error", state.rusher, state.scheduler, saved_player)
	if not error.is_empty():
		return error
	var bindings: Dictionary = scheduler_bindings()
	var staged: Dictionary = rusher.call("staged_actor_bindings", state.rusher)
	bindings.merge(staged, true)
	bindings.hero_positions = {"hero": Codec.read_vector3(saved_player.motion.position)}
	error = scheduler.snapshot_error(state.scheduler, bindings)
	if not error.is_empty():
		return error
	if state.scheduler.encounter_id != ENCOUNTER_ID or state.scheduler.world_revision != 1:
		return "Greybox scheduler epoch must retain its authored encounter"
	var framing: Dictionary = state.framing_witness
	if state.rusher.reservation_id.is_empty():
		return "Inactive source cannot retain a framing witness" if not framing.is_empty() else ""
	if not Codec.keys_error(framing, ["reservation_id", "landing", "attack_position"]).is_empty() or framing.reservation_id != state.rusher.reservation_id or not Codec.is_vector3(framing.landing) or not Codec.is_vector3(framing.attack_position):
		return "Live source requires its same complete admission framing witness"
	var reservation: Dictionary = {}
	for record: Dictionary in state.scheduler.reservations:
		if record.id == state.rusher.reservation_id:
			reservation = record
	var landing: Vector3 = Codec.read_vector3(framing.landing)
	var opening: Vector3 = Codec.read_vector3(reservation.opening_position)
	var attack: Vector3 = Codec.read_vector3(framing.attack_position)
	var saved_equipment = Equipment.new()
	if not saved_player.get("equipment") is Dictionary or not saved_equipment.restore(saved_player.equipment):
		return "Framing witness requires the canonical saved equipment"
	# Shared capsule bottom is root Y + .005; use published resting clearance.
	if Codec.vector3(landing) != framing.landing or Codec.vector3(attack) != framing.attack_position or not Codec.in_range(landing.y + 0.005, -0.001, 0.015) or not Codec.in_range(attack.y + 0.005, -0.001, 0.015):
		return "Framing witness must retain exact native floor points"
	var safe := Rect2(-6.675, -5.675, 13.35, 11.35)
	if not safe.has_point(Vector2(landing.x, landing.z)) or not safe.has_point(Vector2(attack.x, attack.z)) or attack.distance_to(opening) > float(saved_equipment.resolved_stats().primary_range) - 0.005:
		return "Framing witness must retain supported floor and ordinary-primary opening"
	var geometry: Dictionary = reservation.geometry
	var lane: Dictionary = Geometry.lane(Codec.read_vector3(geometry["from"]), Codec.read_vector3(geometry["to"]), geometry.radius)
	if Geometry.segment_hits(lane, landing, landing, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN):
		return "Framing witness landing must remain outside the complete active lane"
	return ""


func _restore_local_state(state: Dictionary) -> void:
	# The shell validates the entire pair and restores the hero before this hook.
	var actor_restored: bool = rusher.call("restore_actor_state", state.rusher)
	assert(actor_restored, "Validated actual C30 physical state must restore")
	var scheduler_restored: bool = scheduler.restore_state(state.scheduler, scheduler_bindings())
	assert(scheduler_restored, "Validated actual C30 and scheduler restore quietly")
	var exchange_restored: bool = rusher.call("restore_exchange_state", state.rusher)
	assert(exchange_restored, "Validated C30 samples and presentation must restore")
	last_admission.clear()
	_forecast_points.clear()
	_framing_witness = {} if state.framing_witness.is_empty() else {"reservation_id": state.framing_witness.reservation_id, "landing": Codec.read_vector3(state.framing_witness.landing), "attack_position": Codec.read_vector3(state.framing_witness.attack_position)}
	objective_text = CLEAR_OBJECTIVE if state.rusher.dead else LIVE_OBJECTIVE


func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = super.snapshot_error(snapshot)
	return _progress_error(snapshot) if error.is_empty() else error


func snapshot_error_with_player(snapshot: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(snapshot, saved_player)
	return _progress_error(snapshot) if error.is_empty() else error


func restore_state(snapshot: Dictionary) -> bool:
	# Base restore uses its private envelope validator, so enforce this room's
	# stronger authored progress invariant before it can commit any local state.
	var error: String = snapshot_error(snapshot)
	if not error.is_empty():
		last_snapshot_error = error
		return false
	return super.restore_state(snapshot)


func _progress_error(snapshot: Dictionary) -> String:
	var progress: Dictionary = snapshot.progress
	return "Temporary rusher room cannot carry campaign completion/checkpoints/exits" if progress.completed or not String(progress.completion_id).is_empty() or not String(progress.contact_exit_id).is_empty() or not String(progress.checkpoint_id).is_empty() or not String(progress.checkpoint_kind).is_empty() or not progress.checkpoint_ids.is_empty() else ""


func request_completion(_completion_id: String = "complete") -> bool:
	return false


func request_checkpoint(_checkpoint_id: String, _boundary_kind: String = "encounter") -> bool:
	return false


func request_contact_exit(_exit_id: String, _body: Node3D) -> bool:
	return false
