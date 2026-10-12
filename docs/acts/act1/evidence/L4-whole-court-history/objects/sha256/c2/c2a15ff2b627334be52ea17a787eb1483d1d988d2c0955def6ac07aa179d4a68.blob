extends CinderLevel
## B01 first native/component pair, not the complete A1-L4 campaign scene.
## Reuses owned one-source aggregate pattern, with full royal art/native Hero bounds.
## Two phases, helper pair and campaign progression are unfinished.
## One shared hero/camera/controller, shared scheduler motion and cues.

const KingScript = preload("res://scripts/acts/act1/selenite_king.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Equipment = preload("res://scripts/equipment.gd")
const SOURCE_ID: String = "a1_l4_greybox_king"
const ENCOUNTER_ID: String = "a1_l4_king_greybox"
const LIVE_OBJECTIVE: String = "KING LUNGE · READ THE LANE\nDASH BESIDE IT · AIM A PRIMARY AT RECOVERY"
const CLEAR_OBJECTIVE: String = "KING COMPONENT CLEAR · ORDINARY PRIMARY\nFULL COURT / PHASES / HELPERS REMAIN IN DEVELOPMENT"

var scheduler: CinderThreatScheduler
var king: CharacterBody3D
var last_admission: Dictionary = {}
var admission_enabled: bool = true
var last_capture_error: String = ""
var _forecast_points: Array = []
var _framing_witness: Dictionary = {}
var _forecast_king_frame: Transform3D
var _forecast_hero_frame: Transform3D
var _floor_collision: CollisionShape3D
var _floor_shape: BoxShape3D
var _floor_frame: Transform3D
var _construction_error: String = ""
var _retained_king: CharacterBody3D
var _retained_scheduler: CinderThreatScheduler
var _floor_visual: MeshInstance3D
var _floor_mesh: Mesh
var _floor_material: Material


func _ready() -> void:
	process_physics_priority = 200
	_floor_collision = get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	_floor_shape = _floor_collision.shape as BoxShape3D if is_instance_valid(_floor_collision) else null
	_floor_frame = _floor_collision.global_transform if is_instance_valid(_floor_collision) else Transform3D.IDENTITY
	_floor_visual = get_node_or_null("Floor/Visual") as MeshInstance3D
	_floor_mesh = _floor_visual.mesh if is_instance_valid(_floor_visual) else null
	_floor_material = _floor_visual.material_override if is_instance_valid(_floor_visual) else null
	if not _floor_error().is_empty():
		_construction_error = _floor_error()
		return
	scheduler = CinderThreatScheduler.new()
	scheduler.name = "CourtKingThreatScheduler"
	add_child(scheduler)
	_retained_scheduler = scheduler
	king = KingScript.new()
	king.name = "SeleniteKing"
	king.position = Vector3(0, 0.005, 0)
	if king.call("configure", SOURCE_ID) != true:
		_construction_error = String(king.get("last_error"))
		king.free()
		return
	add_child(king)
	_retained_king = king
	king.set("presentation_guard", Callable(self, "presentation_error"))
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
	if king.call("bind", scheduler, hero) != true:
		_construction_error = String(king.get("last_error"))
		return
	if not scheduler.begin_encounter("standard", ENCOUNTER_ID, 1):
		_construction_error = scheduler.last_error
		return
	objective_text = LIVE_OBJECTIVE


func _on_exit_level() -> void:
	if is_instance_valid(king):
		if king.is_inside_tree():
			king.call("cancel", "greybox_exit")
		king.set_physics_process(false)
		king.remove_from_group("enemies")
	if is_instance_valid(scheduler):
		if scheduler.is_inside_tree():
			scheduler.end_encounter("greybox_exit")
		scheduler.set_physics_process(false)
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(hero) or hero.dead or not admission_enabled:
		return
	var source: Dictionary = king.call("pure_presentation_state")
	objective_text = CLEAR_OBJECTIVE if source.dead else LIVE_OBJECTIVE
	if source.dead:
		_forecast_points.clear()
		_framing_witness.clear()
		return
	if not String(source.reservation_id).is_empty() or not hero.get_threat_response_state().stable:
		return
	var direction: Vector3 = hero.global_position - king.global_position
	direction.y = 0.0
	if direction.length() > 4.5 or direction.length() < 0.1:
		return
	direction = direction.normalized()
	var preview: Dictionary = king.call("preview_lunge", response_context(), direction, _world_root())
	if not preview.get("accepted", false):
		_forecast_points.clear()
		last_admission = preview.duplicate(true)
		return
	var proof: Dictionary = preview.proof
	if proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not Codec.is_number(proof.get("primary_time_s")) or not Codec.is_number(proof.get("response_complete_s")) or float(proof.primary_time_s) < float(preview.candidate.active_until_s) or float(proof.response_complete_s) >= float(preview.candidate.recovery_until_s):
		_forecast_points.clear()
		last_admission = {"accepted": false, "reason": "Ordinary primary cadence must fit the actual King recovery"}
		return
	_forecast_king_frame = king.global_transform
	_forecast_hero_frame = hero.global_transform
	_forecast_points = _source_points(preview.candidate.opening_position)
	_forecast_points.append_array(_lane_points(preview.candidate.geometry))
	_forecast_points.append_array(_response_points(proof.landing, proof.attack_position))
	var points: Array = _camera_framing_points()
	if not is_instance_valid(shared_shell): return
	var proposed: Dictionary = shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3(0, 0.65, 0))
	if not proposed.get("accepted", false) or not String(shared_shell.call("camera_framing_error", points)).is_empty(): return
	var admitted_hero: CinderPlayer = hero
	var admitted_shell: Node = shared_shell
	var answer: Dictionary = king.call("start", response_context(), direction, _world_root(), preview)
	last_admission = answer.duplicate(true)
	if answer.get("accepted", false):
		if get_tree().paused or not is_instance_valid(hero) or hero != admitted_hero or hero.dead or hero.is_queued_for_deletion() or not hero.is_inside_tree() or not is_instance_valid(shared_shell) or shared_shell != admitted_shell or shared_shell.is_queued_for_deletion() or not shared_shell.is_inside_tree() or not _custody_error().is_empty():
			if is_instance_valid(king): king.call("cancel", "king_component_returned_admission_custody_lost")
			last_admission = {"accepted": false, "reason": "Returned admission lost its actual live unpaused Hero/shell/source custody"}
			_forecast_points.clear()
			_framing_witness.clear()
			return
		var control: Dictionary = scheduler.source_control_state(king)
		var matching: Dictionary = {}
		for record: Dictionary in control.get("reservations", []):
			if record.get("id") == answer.reservation_id: matching = record
		if not control.get("outside_transaction", false) or not king.call("pure_presentation_state").get("outside_transaction", false) or matching.is_empty() or var_to_bytes(matching) != var_to_bytes(answer.reservation) or king.call("pure_presentation_state").reservation_id != answer.reservation_id:
			king.call("cancel", "king_component_returned_admission_custody_lost")
			last_admission = {"accepted": false, "reason": "Returned admission lost its actual owner/lease/callback custody"}
			_forecast_points.clear()
			_framing_witness.clear()
			return
		_framing_witness = {"reservation_id": answer.reservation_id, "landing": answer.proof.landing, "attack_position": answer.proof.attack_position}
		_forecast_points.clear()
		if not presentation_error().is_empty():
			king.call("cancel", "king_component_current_view_lost")
			last_admission = {"accepted": false, "reason": "Actual committed King/source/footprint/landing view rejected"}
			_framing_witness.clear()
	else:
		_forecast_points.clear()
		_framing_witness.clear()



func scheduler_bindings() -> Dictionary:
	return {"world_root": _world_root(), "owners": {SOURCE_ID: king}, "floors": {"lunar_floor": {"collision": get_node_or_null("Floor/CollisionShape3D"), "safe_rect": Rect2(-7, -6, 14, 12)}}}


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
	var custody: String = _custody_error()
	if not custody.is_empty(): return custody
	var art_error: String = king.call("art_binding_error")
	if not art_error.is_empty():
		return art_error
	if not is_instance_valid(shared_shell):
		return ""
	return String(shared_shell.call("camera_framing_error", _camera_framing_points()))


func _camera_framing_points() -> Array:
	if not is_instance_valid(king) or not is_instance_valid(hero) or not is_instance_valid(shared_shell): return []
	if not _floor_error().is_empty() or not _custody_error().is_empty() or not String(king.call("art_binding_error")).is_empty(): return [Vector3.INF]
	var source: Dictionary = king.call("pure_presentation_state")
	if source.dead: return []
	var points: Array = _source_points(source.opening_position)
	if source.reservation_id.is_empty():
		if not _forecast_points.is_empty() and king.global_transform == _forecast_king_frame and hero.global_transform == _forecast_hero_frame:
			points.append_array(_forecast_points)
	else:
		if source.geometry.get("kind") != "lane": return [Vector3.INF]
		points.append_array(_lane_points(source.geometry))
		if not _framing_witness.get("landing") is Vector3 or not _framing_witness.get("attack_position") is Vector3:
			if king.global_transform != _forecast_king_frame or hero.global_transform != _forecast_hero_frame or _forecast_points.is_empty(): return [Vector3.INF]
			points.append_array(_forecast_points)
		else:
			points.append_array(_response_points(_framing_witness.landing, _framing_witness.attack_position))
		var cue: CinderThreatCue = king.call("get_cue")
		for node: Node in cue.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.mesh != null and mesh.is_visible_in_tree(): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	var dash: Dictionary = hero.get_committed_dash_state()
	if dash.get("active", false):
		var endpoint: Vector3 = dash.origin + dash.direction * float(dash.distance)
		for point: Vector3 in shared_shell.call("player_camera_framing_points"): points.append(point + endpoint - hero.global_position)
	return _unique_points(points)


func _lane_points(shape: Dictionary) -> Array:
	var points: Array = []
	for centre: Vector3 in [shape.from, shape.to]:
		points.append_array(_box_points(AABB(Vector3(-shape.radius, 0, -shape.radius), Vector3(shape.radius * 2.0, 0.08, shape.radius * 2.0)), Transform3D(Basis.IDENTITY, centre)))
	return points


func _source_points(endpoint: Vector3) -> Array:
	if not is_instance_valid(king) or not endpoint.is_finite() or not is_instance_valid(shared_shell): return [Vector3.INF]
	var camera: Camera3D = shared_shell.get("camera") as Camera3D
	var points: Array = king.call("camera_art_points", camera)
	var collision := king.get_node_or_null("BodyCollision") as CollisionShape3D
	if not is_instance_valid(collision) or not collision.shape is CapsuleShape3D: return [Vector3.INF]
	var capsule := collision.shape as CapsuleShape3D
	points.append_array(_box_points(AABB(Vector3(-capsule.radius, -capsule.height * 0.5, -capsule.radius), Vector3(capsule.radius * 2, capsule.height, capsule.radius * 2)), collision.global_transform))
	var current: Array = points.duplicate()
	for point: Vector3 in current: points.append(point + endpoint - king.global_position)
	return _unique_points(points)


func _response_points(landing: Vector3, attack: Vector3) -> Array:
	var points: Array = []
	var actual: Array = shared_shell.call("player_camera_framing_points")
	if actual.is_empty(): return [Vector3.INF]
	for point: Vector3 in actual:
		points.append(point + landing - hero.global_position)
		points.append(point + attack - hero.global_position)
	return _unique_points(points)


func _unique_points(points: Array) -> Array:
	var result: Array = []
	for point: Vector3 in points:
		if not result.has(point): result.append(point)
	return result


func _world_root() -> Node3D:
	var ancestor: Node = get_parent()
	while is_instance_valid(ancestor):
		if ancestor is Node3D and ancestor.is_ancestor_of(hero) and ancestor.is_ancestor_of(scheduler) and (ancestor as Node3D).get_world_3d() == get_world_3d(): return ancestor as Node3D
		ancestor = ancestor.get_parent()
	return null


func _floor_error() -> String:
	if not is_instance_valid(_floor_collision) or _floor_collision != get_node_or_null("Floor/CollisionShape3D") or not _floor_collision.is_inside_tree() or _floor_collision.is_queued_for_deletion() or _floor_collision.shape != _floor_shape or not is_instance_valid(_floor_shape) or _floor_shape.size != Vector3(14, 1, 12) or _floor_collision.global_transform != _floor_frame or _floor_collision.disabled:
		return "King component requires its retained original BOX support"
	if not is_instance_valid(_floor_visual) or _floor_visual != get_node_or_null("Floor/Visual") or not _floor_visual.is_inside_tree() or _floor_visual.is_queued_for_deletion() or not _floor_visual.is_visible_in_tree() or _floor_visual.mesh != _floor_mesh or _floor_visual.material_override != _floor_material or _floor_visual.transform != Transform3D.IDENTITY or not _floor_mesh is BoxMesh or (_floor_mesh as BoxMesh).size != Vector3(14, 1, 12):
		return "Retain the visible original King floor mesh/material"
	return ""


func _custody_error() -> String:
	if not is_instance_valid(king) or king != _retained_king or not king.is_inside_tree() or king.is_queued_for_deletion() or king.get_parent() != self or get_node_or_null("SeleniteKing") != king or king.get_script() != KingScript:
		return "Retain the same actual B01 source/node/script"
	if not is_instance_valid(scheduler) or scheduler != _retained_scheduler or not scheduler.is_inside_tree() or scheduler.is_queued_for_deletion() or scheduler.get_parent() != self or get_node_or_null("CourtKingThreatScheduler") != scheduler:
		return "Retain the same actual earlier-physics King Scheduler"
	return ""


func contract_error() -> String:
	return _construction_error if not _construction_error.is_empty() else super.contract_error()


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
	var actor: Dictionary = king.call("snapshot_state", paired)
	if actor.is_empty():
		last_capture_error = king.get("last_snapshot_error")
		return {}
	var framing: Dictionary = {}
	if not actor.reservation_id.is_empty():
		framing = {"reservation_id": _framing_witness.get("reservation_id", ""), "landing": Codec.vector3(_framing_witness.get("landing", Vector3.INF)), "attack_position": Codec.vector3(_framing_witness.get("attack_position", Vector3.INF))}
	return {"scheduler": paired, "king": actor, "framing_witness": framing}


func _local_snapshot_error(state: Dictionary) -> String:
	return _validate_pair(state, hero.snapshot_state())


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	return _validate_pair(state, saved_player)


func _validate_pair(state: Dictionary, saved_player: Dictionary) -> String:
	var custody: String = _custody_error()
	if custody.is_empty(): custody = _floor_error()
	if not custody.is_empty(): return custody
	if state.is_empty() and not last_capture_error.is_empty():
		return "Greybox capture: " + last_capture_error
	if not Codec.keys_error(state, ["scheduler", "king", "framing_witness"]).is_empty() or not state.scheduler is Dictionary or not state.king is Dictionary or not state.framing_witness is Dictionary:
		return "Greybox requires exactly scheduler, B01 and retained framing witness envelopes"
	var error: String = king.call("actor_snapshot_error", state.king, state.scheduler, saved_player)
	if not error.is_empty():
		return error
	var bindings: Dictionary = scheduler_bindings()
	var staged: Dictionary = king.call("staged_actor_bindings", state.king)
	bindings.merge(staged, true)
	bindings.hero_positions = {"hero": Codec.read_vector3(saved_player.motion.position)}
	error = scheduler.snapshot_error(state.scheduler, bindings)
	if not error.is_empty():
		return error
	if state.scheduler.encounter_id != ENCOUNTER_ID or state.scheduler.world_revision != 1:
		return "Greybox scheduler epoch must retain its authored encounter"
	var framing: Dictionary = state.framing_witness
	if state.king.reservation_id.is_empty():
		return "Inactive source cannot retain a framing witness" if not framing.is_empty() else ""
	if not Codec.keys_error(framing, ["reservation_id", "landing", "attack_position"]).is_empty() or framing.reservation_id != state.king.reservation_id or not Codec.is_vector3(framing.landing) or not Codec.is_vector3(framing.attack_position):
		return "Live source requires its same complete admission framing witness"
	var reservation: Dictionary = {}
	for record: Dictionary in state.scheduler.reservations:
		if record.id == state.king.reservation_id:
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
	var actor_restored: bool = king.call("restore_actor_state", state.king)
	assert(actor_restored, "Validated actual B01 physical state must restore")
	var scheduler_restored: bool = scheduler.restore_state(state.scheduler, scheduler_bindings())
	assert(scheduler_restored, "Validated actual B01 and scheduler restore quietly")
	var exchange_restored: bool = king.call("restore_exchange_state", state.king)
	assert(exchange_restored, "Validated B01 samples and presentation must restore")
	last_admission.clear()
	_forecast_points.clear()
	_framing_witness = {} if state.framing_witness.is_empty() else {"reservation_id": state.framing_witness.reservation_id, "landing": Codec.read_vector3(state.framing_witness.landing), "attack_position": Codec.read_vector3(state.framing_witness.attack_position)}
	objective_text = CLEAR_OBJECTIVE if state.king.dead else LIVE_OBJECTIVE


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
	return "Temporary king room cannot carry campaign completion/checkpoints/exits" if progress.completed or not String(progress.completion_id).is_empty() or not String(progress.contact_exit_id).is_empty() or not String(progress.checkpoint_id).is_empty() or not String(progress.checkpoint_kind).is_empty() or not progress.checkpoint_ids.is_empty() else ""


func request_completion(_completion_id: String = "complete") -> bool:
	return false


func request_checkpoint(_checkpoint_id: String, _boundary_kind: String = "encounter") -> bool:
	return false


func request_contact_exit(_exit_id: String, _body: Node3D) -> bool:
	return false
