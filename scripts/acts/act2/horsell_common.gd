extends CinderLevel
## Horsell's owned dry route, authored encounters and scenery. One shared hero,
## scheduler, camera, input and shell; no pickup or blast requirement.

const HeathKit: Script = preload("res://scripts/acts/act2/heath_kit.gd")
const ScoutVisual: Script = preload("res://scripts/acts/act2/ray_scout_visual.gd")
const ScoutActor: Script = preload("res://scripts/acts/act2/ray_scout_actor.gd")
const Sequence: Script = preload("res://scripts/acts/act2/horsell_sequence.gd")
const Exchange: Script = preload("res://scripts/acts/act2/ray_scout_exchange.gd")
const Scheduler: Script = preload("res://scripts/combat/threat_scheduler.gd")
const InteractionCue: Script = preload("res://scripts/cues/interaction_cue.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const SharedGame: Script = preload("res://scripts/game.gd")
const ENCOUNTER_ID: String = "A2-L1-horsell"
const WORLD_REVISION: int = 1
const FORK_REGION: Rect2 = Rect2(-2.8, -14.2, 5.6, 3.8)
const DEPARTURE_CHECKPOINT_REGION: Rect2 = Rect2(-2.5, -20.7, 5.0, 1.5)
const EXIT_REGION: Rect2 = Rect2(-2.5, -30.15, 5.0, 1.6)
const DEPARTURE_CHECKPOINT_ID: String = "horsell-before-departure"
## Adjacent supports overlap by at least0.8m: enough for both conservative
## player-clearance insets. Extensions lie wholly inside existing floor union;
## visible terrain, playable outline, banks and travel distances stay fixed.
const FLOOR_SPECS: Array[Dictionary] = [
	{"id": "arrival", "rect": Rect2(-3.4, -4.0, 6.8, 7.6)},
	{"id": "scorched_road", "rect": Rect2(-3.4, -10.0, 6.8, 7.0)},
	{"id": "common", "rect": Rect2(-3.4, -17.6, 6.8, 8.8)},
	{"id": "reunion_road", "rect": Rect2(-2.9, -20.0, 5.8, 3.2)},
	{"id": "departure", "rect": Rect2(-3.4, -27.6, 6.8, 8.4)},
	{"id": "woking_road", "rect": Rect2(-2.9, -30.2, 5.8, 3.4)},
]
## Conservative proof-only inset; playable floor/collision is unchanged.
const FLOOR_PROOF_INSET: float = 0.002
## Preserve the six historical manual art stations. Live cast adds common_right.
const SCOUT_POSITIONS: Dictionary = {
	"arrival": Vector3(0, 0, -0.4), "road_east": Vector3(1, 0, -5.4),
	"road_west": Vector3(-1, 0, -9.0), "common_left": Vector3(-0.9, 0, -14.5),
	"departure_a": Vector3(-0.65, 0, -23.1), "departure_b": Vector3(0.65, 0, -25.5),
}
## Broad diagonal/cardinal responses first; intermediate bearings offer additional
## witnesses. These are proof candidates, never imposed gesture directions.
const RESPONSE_DIRECTIONS: Array[Vector3] = [
	Vector3(0.707106781187, 0, -0.707106781187), Vector3(-0.707106781187, 0, -0.707106781187),
	Vector3(0.707106781187, 0, 0.707106781187), Vector3(-0.707106781187, 0, 0.707106781187),
	Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT, Vector3.LEFT,
	Vector3(0.3826834324, 0, -0.9238795325), Vector3(-0.3826834324, 0, -0.9238795325),
	Vector3(0.9238795325, 0, -0.3826834324), Vector3(-0.9238795325, 0, -0.3826834324),
	Vector3(0.3826834324, 0, 0.9238795325), Vector3(-0.3826834324, 0, 0.9238795325),
	Vector3(0.9238795325, 0, 0.3826834324), Vector3(-0.9238795325, 0, 0.3826834324),
]
const LOCAL_KEYS: Array[String] = ["scenic_clock", "witness_state", "eruption_visible", "witness_started_s", "eruption_started_s", "sequence", "scheduler", "exchange", "admitted_ids", "departure_checkpoint", "exit_requested", "last_action_sequence", "profile_id", "world_revision", "departure_contact_seen", "pending_checkpoints", "completion_pending"]

@export var art_preview_only: bool = false
var runtime_error: String = ""
var _art_preview: bool = false
var _floors: Array[Dictionary] = []
## Derived scenery-only cutaways; no geometry, collision or save authority.
var _bank_visuals: Array[MeshInstance3D] = []
var _kit: Dictionary = {}
var _scouts: Dictionary = {}
var _actors: Dictionary = {}
var _sequence: RefCounted = Sequence.new()
var _scheduler: Node
var _exchange: Node3D
var _exit_cue: Node3D
var _scenic_clock: float = 0.0
var _witness_state: String = "arrival"
var _eruption_visible: bool = false
var _witness_started_s: float = 0.0
var _eruption_started_s: float = 0.0
var _profile_id: String = "standard"
var _admitted_ids: Array[String] = []
var _admission_errors: Dictionary = {}
var _pending_defeats: Array[String] = []
var _defeat_flush_queued: bool = false
var _departure_checkpoint: bool = false
var _departure_contact_seen: bool = false
var _pending_checkpoints: Array[String] = []
var _completion_pending: bool = false
var _exit_requested: bool = false
var _last_action_sequence: int = 0


func _ready() -> void:
	_art_preview = art_preview_only or OS.get_cmdline_user_args().has("--a2-art-preview")
	process_physics_priority = 110
	_build_ground()
	_kit = HeathKit.build(self)
	if _art_preview:
		for actor_id: String in SCOUT_POSITIONS:
			var visual: Node3D = ScoutVisual.new() as Node3D
			visual.name = "ScoutVisual_" + actor_id
			visual.position = SCOUT_POSITIONS[actor_id]
			add_child(visual)
			visual.call("pose", "idle", 0.0, Vector3.BACK)
			visual.visible = actor_id == "arrival"
			_scouts[actor_id] = visual
	_apply_tableau()
	set_physics_process(false)


func _on_enter_level() -> void:
	if _art_preview:
		objective_text = "HORSELL COMMON / ART PREVIEW"
		set_physics_process(true)
		return
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		_profile_id = shared_shell.call("get_difficulty_preference")
	_scheduler = Scheduler.new()
	_scheduler.name = "HorsellThreatScheduler"
	add_child(_scheduler)
	if not _scheduler.call("begin_encounter", _profile_id, ENCOUNTER_ID, WORLD_REVISION):
		runtime_error = _scheduler.get("last_error")
		return
	for actor_id: String in Sequence.ACTOR_POSITIONS:
		var actor: Node3D = ScoutActor.new() as Node3D
		actor.name = "Scout_" + actor_id
		actor.position = Sequence.ACTOR_POSITIONS[actor_id]
		add_child(actor)
		if not actor.call("configure", hero, effects, actor_id):
			runtime_error = "Could not bind authored Scout " + actor_id
			return
		actor.visible = actor_id == "arrival"
		_actors[actor_id] = actor
		_scouts[actor_id] = actor.get_node("ScoutRig")
	_exchange = Exchange.new() as Node3D
	_exchange.name = "HorsellRayExchanges"
	add_child(_exchange)
	if not _exchange.call("configure", hero, effects, _scheduler, _actors, _profile_id, _response_context()):
		runtime_error = _exchange.get("last_error")
		return
	if not _exchange.call("set_response_context_provider", _response_context) or not _exchange.call("set_presentation_guard", _presentation_guard):
		runtime_error = "Could not bind Horsell portrait preflight"
		return
	_exchange.connect("scout_defeated", _on_scout_defeated)
	_exit_cue = InteractionCue.new() as Node3D
	_exit_cue.name = "WokingContactExit"
	_exit_cue.position = Vector3(0, 0, EXIT_REGION.get_center().y)
	add_child(_exit_cue)
	_exit_cue.call("clear")
	hero.world_action_executed.connect(_on_world_action)
	_update_objective()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _entered or get_tree().paused or not is_instance_valid(hero) or hero.dead or not runtime_error.is_empty():
		return
	_scenic_clock += delta
	_apply_tableau()
	if _art_preview:
		return
	_flush_progress_requests()
	if get_tree().paused:
		return
	_update_actor_visibility()
	_apply_readability()
	if _sequence.call("current_beat") == "departure" and not _departure_checkpoint:
		_departure_contact_seen = _departure_contact_seen or _hero_contacts(DEPARTURE_CHECKPOINT_REGION)
		var response: Dictionary = hero.get_threat_response_state()
		if _departure_contact_seen and response.get("stable", false) and float(response.get("commitment_remaining_s", 1.0)) <= 0.00001:
			_departure_checkpoint = true
			_pending_checkpoints.append(DEPARTURE_CHECKPOINT_ID)
			_flush_progress_requests()
			return
	if _sequence.call("exit_is_open"):
		if is_completed() and not _exit_requested and _hero_contacts(EXIT_REGION):
			_exit_requested = true
			_exit_cue.call("present", "active", "contact")
			request_contact_exit("woking-road", hero)
		return
	if _sequence.call("current_beat") == "departure" and not _departure_checkpoint:
		return
	for actor_id: String in _sequence.call("current_active_ids"):
		var actor: Node3D = _actors[actor_id]
		var state: Dictionary = _exchange.call("state", actor_id)
		if state.get("status") == "running":
			if not _exchange_framed(actor, state):
				_exchange.call("cancel", actor_id, "required_source_footprint_or_landing_offscreen")
			continue
		if actor.get("hp") <= 0.0 or hero.global_position.distance_to(actor.global_position) > 3.8:
			continue
		var direction: Vector3 = Vector3(hero.global_position.x - actor.global_position.x, 0, hero.global_position.z - actor.global_position.z)
		if direction.length_squared() <= 0.000001:
			direction = Vector3.BACK
		var preview := {"geometry": Geometry.lane(actor.global_position, actor.global_position + direction.normalized() * 3.8, 0.31)}
		if not _exchange_framed(actor, preview):
			continue
		var answer: Dictionary = _exchange.call("activate", actor_id)
		_admission_errors[actor_id] = {} if answer.get("accepted", false) else {"reason": answer.get("reason", "rejected")}
		if answer.get("accepted", false) and not _admitted_ids.has(actor_id):
			_admitted_ids.append(actor_id)


func encounter_state() -> Dictionary:
	var exchanges: Dictionary = {}
	if is_instance_valid(_exchange):
		for actor_id: String in _actors:
			exchanges[actor_id] = _exchange.call("state", actor_id)
	return {"beat": _sequence.call("current_beat"), "route": _sequence.call("selected_route"), "active_ids": _sequence.call("current_active_ids"), "admitted_ids": _admitted_ids.duplicate(), "clock_s": _scheduler.call("get_clock") if is_instance_valid(_scheduler) else 0.0, "exchanges": exchanges, "exit_open": _sequence.call("exit_is_open"), "departure_checkpoint": _departure_checkpoint, "runtime_error": runtime_error, "admission_errors": _admission_errors.duplicate(true)}


func _response_context(actor_id: String = "", geometry: Dictionary = {}) -> Dictionary:
	var escapes: Array[Vector3] = RESPONSE_DIRECTIONS.duplicate()
	var returns: Array[Vector3] = RESPONSE_DIRECTIONS.duplicate()
	if not actor_id.is_empty() and _actors.has(actor_id) and is_instance_valid(hero):
		var actor: Node3D = _actors[actor_id]
		var camera: Camera3D = get_viewport().get_camera_3d()
		escapes.clear()
		returns.clear()
		if is_instance_valid(camera):
			var points: Array[Vector3] = _required_source_points(actor)
			points.append_array(_lane_points(geometry))
			# Existing live sources remain legible when a second mirror commits.
			for other_id: String in _sequence.call("current_active_ids"):
				if other_id == actor_id:
					continue
				var other_state: Dictionary = _exchange.call("state", other_id)
				if other_state.get("status") == "running":
					points.append_array(_required_source_points(_actors[other_id]))
					if other_state.get("phase") != "recovery":
						points.append_array(_lane_points(_state_geometry(other_state)))
			var distance: float = float(hero.equipment.resolved_stats()["dash_distance"])
			for direction: Vector3 in RESPONSE_DIRECTIONS:
				var landing: Vector3 = hero.global_position + direction * distance
				var witness: Array[Vector3] = points.duplicate()
				witness.append_array(_landing_points(landing))
				if _points_framed(camera, witness) and _points_framed(camera, witness, _settled_follow_delta(camera, landing)):
					escapes.append(direction)
			var reach: float = float(hero.equipment.resolved_stats()["primary_range"])
			for direction: Vector3 in RESPONSE_DIRECTIONS:
				var has_opening: bool = false
				var all_openings_framed: bool = true
				for escape: Vector3 in escapes:
					var returning: Vector3 = hero.global_position + (escape + direction) * distance
					# The shared prover cross-products these arrays. Every pairing
					# that could reach the ordinary opening must be framed, rather
					# than admitting this return for one different escape only.
					if Vector2(returning.x - actor.global_position.x, returning.z - actor.global_position.z).length() > reach + 0.00001:
						continue
					has_opening = true
					var witness: Array[Vector3] = _required_source_points(actor)
					witness.append_array(_landing_points(returning))
					if not _points_framed(camera, witness) or not _points_framed(camera, witness, _settled_follow_delta(camera, returning)):
						all_openings_framed = false
						break
				if has_opening and all_openings_framed:
					returns.append(direction)

	return {"encounter_id": ENCOUNTER_ID, "world_revision": WORLD_REVISION, "recognition_s": 0.30, "attack_input_margin_s": 0.10, "escape_directions": escapes, "return_directions": returns, "floor_regions": floor_regions()}


func _on_world_action(record: Dictionary) -> void:
	if not _entered or _art_preview or _restoring or _validating or _snapshotting or not runtime_error.is_empty() or get_tree().paused:
		return
	if int(record.get("sequence", 0)) <= _last_action_sequence:
		return
	_last_action_sequence = int(record["sequence"])
	if record.get("kind") != "dash" or _sequence.call("current_beat") != "fork":
		return
	var landing: Variant = record.get("landing")
	if not landing is Vector3 or not landing.is_finite() or not FORK_REGION.has_point(Vector2(landing.x, landing.z)):
		return
	var route: String = "left" if landing.x < 0.0 else "right"
	var choice: Dictionary = _sequence.call("choose_route", route)
	if choice.get("accepted", false):
		_update_objective()
		_update_actor_visibility()


func _on_scout_defeated(actor_id: String) -> void:
	if not _entered or _art_preview or _restoring or _validating or _snapshotting or not _actors.has(actor_id):
		return
	if not _pending_defeats.has(actor_id):
		_pending_defeats.append(actor_id)
	if not _defeat_flush_queued:
		_defeat_flush_queued = true
		_flush_defeats.call_deferred()


func _flush_defeats() -> void:
	# Finish accepted hit transactions after actor/player callbacks, including
	# reload credit, return. This barrier may finish before an already-queued
	# pause snapshot; it creates no new attack, movement or simulation time.
	_defeat_flush_queued = false
	if not _entered or _art_preview or _restoring or _validating or _snapshotting:
		return
	var ids: Array[String] = _pending_defeats.duplicate()
	_pending_defeats.clear()
	var checkpoints: Array[Dictionary] = []
	var completion: Dictionary = {}
	for actor_id: String in ids:
		if not _actors.has(actor_id) or float(_actors[actor_id].get("hp")) > 0.0:
			continue
		var result: Dictionary = _sequence.call("commit_defeat", actor_id)
		if not result.get("accepted", false):
			runtime_error = "Noncanonical Scout defeat: " + actor_id
			return
		_admitted_ids.erase(actor_id)
		checkpoints.append_array(result["checkpoint_intents"])
		if not (result["completion_intent"] as Dictionary).is_empty():
			completion = result["completion_intent"]
		for intent: Dictionary in result["tableau_intents"]:
			if intent["kind"] == "witnesses":
				_witness_state = intent["state"]
				if _witness_state == "retreat":
					_witness_started_s = _scenic_clock
			elif intent["kind"] == "eruption":
				_eruption_visible = intent["visible"]
				_eruption_started_s = _scenic_clock
	_update_actor_visibility()
	_apply_tableau()
	_apply_readability()
	_update_objective()
	if _sequence.call("exit_is_open"):
		_exchange.call("cancel_all", "horsell_clear")
		_scheduler.call("end_encounter", "horsell_clear")
		_exit_cue.call("present", "available", "contact")
	for checkpoint: Dictionary in checkpoints:
		_pending_checkpoints.append(checkpoint["id"])
	_completion_pending = not completion.is_empty()
	_flush_progress_requests()


func _flush_progress_requests() -> void:
	# A completed hit can coincide with death from another already-active ray.
	# Preserve unrequested boundaries in the dead paused aggregate; retry uses
	# the last coherent checkpoint. Never request new progression from a corpse.
	if hero.dead or not _entered or _restoring or _validating or _snapshotting:
		return
	while not _pending_checkpoints.is_empty():
		var id: String = _pending_checkpoints.pop_front()
		if not request_checkpoint(id):
			runtime_error = "Could not request committed Horsell checkpoint: " + id
			return
	if _completion_pending:
		_completion_pending = false
		if not request_completion("horsell-scouts-clear"):
			runtime_error = "Could not request committed Horsell completion"


func _update_actor_visibility() -> void:
	var active: Array = _sequence.call("current_active_ids")
	for actor_id: String in _actors:
		var actor: Node3D = _actors[actor_id]
		actor.visible = float(actor.get("hp")) <= 0.0 or (active.has(actor_id) and hero.global_position.distance_to(actor.global_position) <= 5.1)


func _hero_contacts(region: Rect2) -> bool:
	return not hero.dead and hero.global_position.y > -0.05 and hero.global_position.y < 0.2 and region.has_point(Vector2(hero.global_position.x, hero.global_position.z))


func _presentation_guard(actor_id: String, state: Dictionary) -> bool:
	# The driver calls this immediately before damage and fresh commitment.
	_apply_readability(actor_id, state)
	return _actors.has(actor_id) and _exchange_framed(_actors[actor_id], state)


func _hero_readability_points(camera: Camera3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not is_instance_valid(hero):
		return points
	# Read the current public Sprite3D quad. Shared animation/act presentation
	# remains authoritative; the bank/rig never substitutes a player renderer.
	var sprite: Sprite3D = hero.get_node_or_null("ActorSprite") as Sprite3D
	if not is_instance_valid(sprite) or not is_instance_valid(sprite.texture):
		return _landing_points(hero.global_position)
	var size_pixels: Vector2 = sprite.texture.get_size()
	var lower: Vector2 = sprite.offset - (size_pixels * 0.5 if sprite.centered else Vector2.ZERO)
	var upper: Vector2 = lower + size_pixels
	var right: Vector3 = camera.global_basis.x.normalized()
	var up: Vector3 = camera.global_basis.y.normalized()
	for y: float in [lower.y, (lower.y + upper.y) * 0.5, upper.y]:
		for x: float in [lower.x, (lower.x + upper.x) * 0.5, upper.x]:
			points.append(sprite.global_position + right * x * sprite.pixel_size + up * y * sprite.pixel_size)
	return points


func _apply_readability(guard_actor_id: String = "", guard_state: Dictionary = {}) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera) or not is_instance_valid(hero):
		return
	var hero_points: Array[Vector3] = _hero_readability_points(camera)
	var protected: Array[Vector3] = hero_points.duplicate()
	for actor_id: String in _actors:
		var actor: Node3D = _actors[actor_id]
		var rig: Node3D = actor.get_node_or_null("ScoutRig") as Node3D
		if is_instance_valid(rig) and rig.has_method("apply_readability"):
			if actor.is_visible_in_tree():
				rig.call("apply_readability", camera, hero_points)
			else:
				rig.call("clear_readability")
		if not actor.is_visible_in_tree():
			continue
		protected.append_array(_required_source_points(actor))
		var state: Dictionary = guard_state if actor_id == guard_actor_id else (_exchange.call("state", actor_id) if is_instance_valid(_exchange) else {})
		if state.get("status") != "running" and actor_id != guard_actor_id:
			continue
		if state.get("phase") != "recovery":
			protected.append_array(_lane_readability_points(_state_geometry(state)))
			var proof: Dictionary = state.get("proof", {})
			if not proof.get("landing") is Vector3:
				proof = state.get("presentation_witness", {})
			for key: String in ["landing", "attack_position"]:
				if proof.get(key) is Vector3:
					protected.append_array(_landing_points(proof[key]))
	for bank: MeshInstance3D in _bank_visuals:
		if not is_instance_valid(bank):
			continue
		var obscures: bool = false
		for point: Vector3 in protected:
			if camera.is_position_behind(point):
				continue
			var origin: Vector3 = camera.project_ray_origin(camera.unproject_position(point))
			if _bank_blocks_point(bank, origin, point):
				obscures = true
				break
		var material: StandardMaterial3D = bank.material_override as StandardMaterial3D
		var alpha: float = 0.12 if obscures else 1.0
		if material.albedo_color.a != alpha:
			var color: Color = material.albedo_color
			color.a = alpha
			material.albedo_color = color
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if obscures else BaseMaterial3D.TRANSPARENCY_DISABLED


func _lane_readability_points(geometry: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not geometry.get("from") is Vector3 or not geometry.get("to") is Vector3:
		return points
	var start: Vector3 = geometry["from"]
	var finish: Vector3 = geometry["to"]
	var radius: float = float(geometry.get("radius", 0.31))
	var side: Vector3 = (finish - start).cross(Vector3.UP).normalized() * radius
	for center: Vector3 in [start, finish]:
		for index: int in range(16):
			var angle: float = TAU * float(index) / 16.0
			points.append(center + Vector3(cos(angle) * radius, 0.03, sin(angle) * radius))
	for index: int in range(11):
		var center: Vector3 = start.lerp(finish, float(index) / 10.0) + Vector3.UP * 0.03
		points.append(center)
		points.append(center + side)
		points.append(center - side)
	return points


func _bank_blocks_point(bank: MeshInstance3D, origin: Vector3, point: Vector3) -> bool:
	# Segment/slab intersection uses actual transformed BoxMesh bounds. A bank
	# beyond the protected point cannot fade, nor can a mere screen rectangle.
	var inverse: Transform3D = bank.global_transform.affine_inverse()
	var start: Vector3 = inverse * origin
	var end: Vector3 = inverse * point
	var ray: Vector3 = end - start
	var bounds: AABB = bank.mesh.get_aabb()
	var near: float = 0.0
	var far: float = 1.0
	for axis: int in range(3):
		if absf(ray[axis]) <= 0.000000001:
			if start[axis] < bounds.position[axis] or start[axis] > bounds.end[axis]:
				return false
			continue
		var first: float = (bounds.position[axis] - start[axis]) / ray[axis]
		var second: float = (bounds.end[axis] - start[axis]) / ray[axis]
		near = maxf(near, minf(first, second))
		far = minf(far, maxf(first, second))
		if near > far:
			return false
	return near < 1.0 and far > 0.0


func _exchange_framed(actor: Node3D, state: Dictionary) -> bool:
	if not is_instance_valid(actor) or not actor.is_visible_in_tree():
		return false
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera):
		return false
	var points: Array[Vector3] = _required_source_points(actor)
	if points.is_empty():
		return false
	# The active footprint remains mandatory through release. In recovery its
	# spent lane cannot damage; source and exposed ordinary-primary housing do.
	if state.get("phase") != "recovery":
		points.append_array(_lane_points(_state_geometry(state)))
	var proof: Dictionary = state.get("proof", {})
	if not proof.get("landing") is Vector3:
		proof = state.get("presentation_witness", {})
	if state.get("phase") != "recovery":
		for key: String in ["landing", "attack_position"]:
			if proof.get(key) is Vector3:
				points.append_array(_landing_points(proof[key]))
	var failure: Dictionary = _framing_failure(camera, points)
	if not failure.is_empty():
		_admission_errors[String(actor.get("actor_id"))] = failure
		return false
	return true


func _state_geometry(state: Dictionary) -> Dictionary:
	var geometry: Dictionary = state.get("geometry", {})
	for key: String in ["reservation", "exchange"]:
		if geometry.is_empty() and state.get(key) is Dictionary:
			geometry = state[key].get("geometry", {})
	return geometry


func _required_source_points(actor: Node3D) -> Array[Vector3]:
	# Actual camera case, moving mirror and low housing mesh bounds establish
	# readable source/opening, rather than an imaginary 1.9m upper-body cube.
	# Peripheral support toes may reach the scenic margin; native views review
	# the whole three-legged silhouette separately.
	var points: Array[Vector3] = []
	for path: String in ["ScoutRig/ThreeLegChassis/RivetedCameraCase", "ScoutRig/ThreeLegChassis/TrackingMirrorSwivel", "ScoutRig/ThreeLegChassis/FixedLowMirrorHousing"]:
		var part: Node = actor.get_node_or_null(path)
		if not is_instance_valid(part):
			return []
		var before: int = points.size()
		_append_mesh_points(part, points)
		if points.size() == before:
			return []
	points.append_array(_landing_points(actor.global_position))
	return points


func _append_mesh_points(node: Node, points: Array[Vector3]) -> void:
	if node is MeshInstance3D and is_instance_valid(node.mesh) and node.is_visible_in_tree():
		var bounds: AABB = node.mesh.get_aabb()
		for index: int in range(8):
			points.append(node.global_transform * bounds.get_endpoint(index))
	for child: Node in node.get_children():
		_append_mesh_points(child, points)


func _lane_points(geometry: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if geometry.is_empty():
		return points
	for key: String in ["from", "to"]:
		if not geometry.get(key) is Vector3:
			return []
		for x: float in [-0.31, 0.31]:
			for z: float in [-0.31, 0.31]:
				points.append(geometry[key] + Vector3(x, 0.03, z))
	return points


func _landing_points(landing: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x: float in [-0.32, 0.32]:
		for z: float in [-0.32, 0.32]:
			points.append(landing + Vector3(x, 0.03, z))
			points.append(landing + Vector3(x, 1.46, z))
	return points


func _settled_follow_delta(camera: Camera3D, landing: Vector3) -> Vector3:
	# Fixed-angle shared camera approaches this public actor-follow endpoint;
	# testing both projections bounds its continuous translation during a dash.
	return landing + Vector3.UP * 0.75 + SharedGame.CAMERA_OFFSET - camera.global_position


func _points_framed(camera: Camera3D, points: Array[Vector3], follow_delta: Vector3 = Vector3.ZERO) -> bool:
	return not points.is_empty() and _framing_failure(camera, points, follow_delta).is_empty()


func _framing_failure(camera: Camera3D, points: Array[Vector3], follow_delta: Vector3 = Vector3.ZERO) -> Dictionary:
	var dimensions: Vector2 = get_viewport().get_visible_rect().size
	var safe := Rect2(dimensions * Vector2(12.0 / 270.0, 108.0 / 585.0), dimensions * Vector2(246.0 / 270.0, 414.0 / 585.0))
	if points.is_empty():
		return {"reason": "missing_readable_source_points"}
	for point: Vector3 in points:
		var projected: Vector3 = point - follow_delta
		var screen: Vector2 = camera.unproject_position(projected)
		if camera.is_position_behind(projected) or not safe.has_point(screen):
			return {"reason": "required_source_footprint_or_landing_offscreen", "point": point, "screen": screen, "safe_rect": safe}
	return {}


func _update_objective() -> void:
	var beat: String = _sequence.call("current_beat")
	match beat:
		"arrival": objective_text = "HORSELL COMMON / LEAVE THE CYLINDER\nLET THE MIRROR LOCK. LAND BESIDE THE RAY."
		"road_east", "road_west": objective_text = "FOLLOW THE SCORCHED ROAD\nSTRIKE THE EXPOSED LOW HOUSING."
		"fork": objective_text = "TAKE EITHER DRY APPROACH\nDASH LEFT OR RIGHT OF THE GROUNDED TRUNK."
		"common": objective_text = "CROSS THE COMMON\nKEEP THE LOCKED LANE AND A WAY BACK IN VIEW."
		"departure": objective_text = "REACH THE DEPARTURE CLEARING\nREAD THE TWO MIRRORS. KEEP A LANDING OPEN."
		"clear": objective_text = "THE WOKING ROAD IS OPEN\nLEAVE THROUGH THE PALE ROAD MARKER."


func floor_regions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for floor: Dictionary in _floors:
		result.append({"id": floor["id"], "body": floor["body"], "rect": floor["rect"], "collision": floor["collision"], "safe_rect": floor["safe_rect"]})
	return result


func floor_bindings() -> Dictionary:
	var result: Dictionary = {}
	for floor: Dictionary in _floors:
		result[floor["id"]] = {"collision": floor["collision"], "safe_rect": floor["safe_rect"]}
	return result


func _scheduler_bindings() -> Dictionary:
	return {"world_root": self, "owners": _actors.duplicate(), "floors": floor_bindings()}


func _build_ground() -> void:
	var floor_root := Node3D.new()
	floor_root.name = "DryGround"
	add_child(floor_root)
	for specification: Dictionary in FLOOR_SPECS:
		var rect: Rect2 = specification["rect"]
		var body := StaticBody3D.new()
		body.name = specification["id"]
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector3(rect.get_center().x, -0.25, rect.get_center().y)
		floor_root.add_child(body)
		var shape := BoxShape3D.new()
		shape.size = Vector3(rect.size.x, 0.5, rect.size.y)
		var collision := CollisionShape3D.new()
		collision.name = "DrySupport"
		collision.shape = shape
		body.add_child(collision)
		_floors.append({"id": specification["id"], "rect": rect, "body": body, "collision": collision, "safe_rect": rect.grow(-FLOOR_PROOF_INSET)})
		# Kit supplies the authored ground texture above this hidden collision.
	_build_bank("ArrivalEndBank", Vector3(0, 0.45, 3.9), Vector3(7.8, 1.0, 0.6), floor_root)
	_build_bank("WokingEndBank", Vector3(0, 0.45, -30.5), Vector3(6.8, 1.0, 0.6), floor_root)
	for edge: Dictionary in [
		{"id": "Heath", "half_width": 3.4, "near": 3.6, "far": -17.6},
		{"id": "Reunion", "half_width": 2.9, "near": -17.6, "far": -19.2},
		{"id": "Departure", "half_width": 3.4, "near": -19.2, "far": -27.6},
		{"id": "Woking", "half_width": 2.9, "near": -27.6, "far": -30.2},
	]:
		for side: float in [-1.0, 1.0]:
			_build_bank(edge["id"] + ("WestBank" if side < 0.0 else "EastBank"), Vector3(side * (edge["half_width"] + 0.25), 0.45, (edge["near"] + edge["far"]) * 0.5), Vector3(0.5, 1.0, edge["near"] - edge["far"]), floor_root)
	# One grounded trunk creates the short inside flank on the common. It is
	# stationary layer-1 scenery, and does not impersonate an interaction cue.
	var trunk := StaticBody3D.new()
	trunk.name = "CommonGroundedTrunk"
	trunk.position = Vector3(-1.2, 0.6, -10.8)
	trunk.collision_layer = 1
	trunk.collision_mask = 0
	floor_root.add_child(trunk)
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.35
	trunk_shape.height = 1.2
	var trunk_collision := CollisionShape3D.new()
	trunk_collision.name = "GroundedSolid"
	trunk_collision.shape = trunk_shape
	trunk.add_child(trunk_collision)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.21
	trunk_mesh.bottom_radius = 0.35
	trunk_mesh.height = 1.2
	trunk_mesh.radial_segments = 7
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color("322924")
	bark.roughness = 1.0
	var trunk_visual := MeshInstance3D.new()
	trunk_visual.mesh = trunk_mesh
	trunk_visual.material_override = bark
	trunk.add_child(trunk_visual)


func _build_bank(stable_name: String, position_value: Vector3, dimensions: Vector3, parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = stable_name
	body.position = position_value
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var collision := CollisionShape3D.new()
	collision.name = "BankSolid"
	collision.shape = shape
	body.add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var soil := StandardMaterial3D.new()
	soil.albedo_color = Color("69523b")
	soil.roughness = 1.0
	var visual := MeshInstance3D.new()
	visual.name = "BankSurface"
	visual.mesh = mesh
	visual.material_override = soil
	body.add_child(visual)
	_bank_visuals.append(visual)


func _apply_tableau() -> void:
	var witness_age: float = _scenic_clock if _art_preview else _scenic_clock - _witness_started_s
	var eruption_age: float = _scenic_clock if _art_preview else _scenic_clock - _eruption_started_s
	HeathKit.set_tableau(_kit, _witness_state, clampf(witness_age / 1.6, 0.0, 1.0) if _witness_state == "retreat" else 0.0)
	HeathKit.set_eruption(_kit, _eruption_visible, clampf(eruption_age / 1.6, 0.0, 1.0))


func _capture_local_state() -> Dictionary:
	if _art_preview:
		return {"scenic_clock": _scenic_clock, "witness_state": _witness_state, "eruption_visible": _eruption_visible}
	if not get_tree().paused or not _pending_defeats.is_empty() or _defeat_flush_queued or not runtime_error.is_empty():
		return {"error": "Horsell capture requires its deferred paused committed barrier"}
	var bindings: Dictionary = _scheduler_bindings()
	var paired: Dictionary = _scheduler.call("snapshot_state", bindings)
	var exchange: Dictionary = _exchange.call("snapshot_state", bindings)
	return {"scenic_clock": _scenic_clock, "witness_state": _witness_state, "eruption_visible": _eruption_visible, "witness_started_s": _witness_started_s, "eruption_started_s": _eruption_started_s, "sequence": _sequence.call("snapshot_state"), "scheduler": paired, "exchange": exchange, "admitted_ids": _admitted_ids.duplicate(), "departure_checkpoint": _departure_checkpoint, "exit_requested": _exit_requested, "last_action_sequence": _last_action_sequence, "profile_id": _profile_id, "world_revision": WORLD_REVISION, "departure_contact_seen": _departure_contact_seen, "pending_checkpoints": _pending_checkpoints.duplicate(), "completion_pending": _completion_pending}


func _scenery_snapshot_error(state: Dictionary) -> String:
	if not Codec.in_range(state.get("scenic_clock"), 0.0, 1000000000.0) or not state.get("witness_state") is String or state["witness_state"] not in ["arrival", "retreat", "absent"] or not state.get("eruption_visible") is bool:
		return "Invalid Horsell scenery clock/tableau"
	if _floors.size() != FLOOR_SPECS.size() or not _kit.has("root") or not is_instance_valid(_kit["root"]):
		return "Missing Horsell runtime content"
	for floor: Dictionary in _floors:
		var body: Variant = floor["body"]
		if not is_instance_valid(body) or body.is_queued_for_deletion() or not is_ancestor_of(body):
			return "Missing owned Horsell floor"
		var support: Variant = floor.get("collision")
		if not is_instance_valid(support) or support.is_queued_for_deletion() or support.get_parent() != body or not support is CollisionShape3D or support.disabled or not support.shape is BoxShape3D:
			return "Missing owned Horsell support collision"
	for key: String in ["root", "eruption"]:
		var required: Variant = _kit.get(key)
		if not is_instance_valid(required) or required.is_queued_for_deletion() or not is_ancestor_of(required):
			return "Missing owned Horsell kit node"
	if not _kit.get("witnesses") is Array:
		return "Missing Horsell witness collection"
	for witness: Variant in _kit["witnesses"]:
		if not is_instance_valid(witness) or witness.is_queued_for_deletion() or not is_ancestor_of(witness):
			return "Missing owned Horsell witness"
	return ""


func _local_snapshot_error(state: Dictionary) -> String:
	return _local_snapshot_error_for_bindings(state, _scheduler_bindings())


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	# The aggregate caller already validated the complete saved shared actor.
	# Stage only its authoritative feet position; pure proof never moves a hero.
	var bindings: Dictionary = _scheduler_bindings()
	bindings["hero_positions"] = {"hero": Codec.read_vector3(saved_player["motion"]["position"])}
	return _local_snapshot_error_for_bindings(state, bindings)


func _local_snapshot_error_for_bindings(state: Dictionary, bindings: Dictionary) -> String:
	var error: String = _scenery_snapshot_error(state)
	if not error.is_empty():
		return error
	if _art_preview:
		if not Codec.keys_error(state, ["scenic_clock", "witness_state", "eruption_visible"]).is_empty() or _scouts.size() != SCOUT_POSITIONS.size():
			return "Horsell art snapshot fields differ"
		for visual: Variant in _scouts.values():
			if not is_instance_valid(visual) or visual.is_queued_for_deletion() or not is_ancestor_of(visual):
				return "Missing owned Horsell visual"
		return ""
	if not get_tree().paused or not _pending_defeats.is_empty() or _defeat_flush_queued or not runtime_error.is_empty():
		return "Horsell snapshots require a paused committed barrier"
	error = Codec.keys_error(state, LOCAL_KEYS)
	if not error.is_empty():
		return error
	if state["profile_id"] not in ["assisted", "standard", "challenge"] or not Codec.is_integer(state["world_revision"], WORLD_REVISION, WORLD_REVISION) or not Codec.is_integer(state["last_action_sequence"]) or not state["departure_checkpoint"] is bool or not state["exit_requested"] is bool or not state["departure_contact_seen"] is bool or not state["completion_pending"] is bool or not state["pending_checkpoints"] is Array:
		return "Invalid Horsell profile/revision/contact/cursor"
	for key: String in ["witness_started_s", "eruption_started_s"]:
		if not Codec.in_range(state[key], 0.0, float(state["scenic_clock"])):
			return "Invalid Horsell independent tableau start"
	for key: String in ["sequence", "scheduler", "exchange"]:
		if not state[key] is Dictionary:
			return "Missing Horsell paired component: " + key
	if _actors.size() != Sequence.ACTOR_POSITIONS.size() or not is_instance_valid(_scheduler) or not is_instance_valid(_exchange) or not is_instance_valid(_exit_cue) or _scheduler.is_queued_for_deletion() or _exchange.is_queued_for_deletion() or _exit_cue.is_queued_for_deletion():
		return "Missing Horsell live encounter runtime"
	error = _sequence.call("snapshot_error", state["sequence"])
	if not error.is_empty():
		return error
	var sequence: Dictionary = state["sequence"]
	var beat: String = sequence["beat"]
	if not state["admitted_ids"] is Array or state["admitted_ids"].size() > 2:
		return "Invalid Horsell admitted actor set"
	var seen: Dictionary = {}
	for actor_id: Variant in state["admitted_ids"]:
		if not actor_id is String or not sequence["alive_ids"].has(actor_id) or seen.has(actor_id):
			return "Horsell admission differs from the current beat"
		seen[actor_id] = true
	if state["departure_contact_seen"] and beat not in ["departure", "clear"]:
		return "Departure contact precedes its authored clearing"
	if state["departure_checkpoint"] and not state["departure_contact_seen"]:
		return "Departure checkpoint requires an actual prior contact"
	if state["completion_pending"] and beat != "clear":
		return "Pending completion requires final Scout clear"
	if state["departure_checkpoint"] and beat not in ["departure", "clear"]:
		return "Departure contact precedes its authored clearing"
	if beat == "clear" and not state["departure_checkpoint"]:
		return "Cleared Horsell requires its departure contact checkpoint"
	if state["exit_requested"] and beat != "clear":
		return "Horsell exit cannot precede final clear"
	var expected_witness: String = "arrival" if beat == "arrival" else ("retreat" if beat in ["road_east", "road_west"] else "absent")
	if state["witness_state"] != expected_witness or state["eruption_visible"] != (beat == "clear"):
		return "Horsell tableaux differ from the authored defeat sequence"
	error = _scheduler.call("snapshot_error", state["scheduler"], bindings)
	if not error.is_empty():
		return error
	var paired: Dictionary = state["scheduler"]
	if paired.get("world_revision") != WORLD_REVISION or (beat != "clear" and (paired.get("encounter_id") != ENCOUNTER_ID or paired.get("profile", {}).get("id") != state["profile_id"])):
		return "Horsell paired scheduler epoch/profile differs"
	if beat == "clear" and (not String(paired.get("encounter_id", "")).is_empty() or not paired.get("reservations", []).is_empty()):
		return "Cleared Horsell must end its reservation encounter"
	error = _exchange.call("snapshot_error", state["exchange"], bindings, paired)
	if not error.is_empty():
		return error
	var actors: Variant = state["exchange"].get("actors")
	if not actors is Dictionary or actors.size() != Sequence.ACTOR_POSITIONS.size():
		return "Horsell snapshot requires all authored actors"
	for actor_id: String in Sequence.ACTOR_POSITIONS:
		if not actors.get(actor_id) is Dictionary:
			return "Missing Horsell actor transport"
		var actor: Dictionary = actors[actor_id]
		if (float(actor["hp"]) <= 0.0) != sequence["defeated_ids"].has(actor_id):
			return "Horsell actor HP differs from the exact defeat prefix"
		if not sequence["alive_ids"].has(actor_id) and not sequence["defeated_ids"].has(actor_id) and actor["phase"] != "idle":
			return "Dormant/unselected Horsell actor must be idle"
	return ""


func snapshot_state() -> Dictionary:
	var state: Dictionary = super.snapshot_state()
	if not state.is_empty():
		last_snapshot_error = _progress_snapshot_error(state)
		if not last_snapshot_error.is_empty():
			return {}
	return state


func snapshot_error(state: Dictionary) -> String:
	var error: String = super.snapshot_error(state)
	return error if not error.is_empty() else _progress_snapshot_error(state)


func snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(state, saved_player)
	return error if not error.is_empty() else _progress_snapshot_error(state)


func restore_state(state: Dictionary) -> bool:
	# Pure local preflight is independent of the receiver. Actual commit requires
	# the shared actor already restored, before any owned component is replaced.
	if _art_preview:
		last_snapshot_error = snapshot_error(state)
	elif not is_instance_valid(hero):
		last_snapshot_error = "Restore requires the bound shared player"
	else:
		var current_player: Dictionary = hero.snapshot_state()
		last_snapshot_error = "Restore requires a valid paused shared player" if current_player.is_empty() else snapshot_error_with_player(state, current_player)
	if not last_snapshot_error.is_empty():
		return false
	var accepted: bool = super.restore_state(state)
	if accepted and not runtime_error.is_empty():
		last_snapshot_error = runtime_error
		return false
	return accepted


func _progress_snapshot_error(state: Dictionary) -> String:
	if _art_preview:
		return ""
	var progress: Dictionary = state["progress"]
	var local: Dictionary = state["local"]
	var sequence: Dictionary = local["sequence"]
	var clear: bool = sequence["beat"] == "clear"
	if progress["completed"] != (clear and not local["completion_pending"]) or (progress["completed"] and progress["completion_id"] != "horsell-scouts-clear") or (not progress["contact_exit_id"].is_empty()) != local["exit_requested"] or (local["exit_requested"] and progress["contact_exit_id"] != "woking-road"):
		return "Horsell completion/exit differs from its real objective state"
	var expected: Dictionary = {}
	var defeated: Array = sequence["defeated_ids"]
	if defeated.has("arrival"):
		expected["horsell-arrival-clear"] = "encounter"
	if defeated.has("road_west"):
		expected["horsell-road-clear"] = "encounter"
	if sequence["beat"] in ["departure", "clear"]:
		expected["horsell-reunion"] = "encounter"
	if local["departure_checkpoint"]:
		expected[DEPARTURE_CHECKPOINT_ID] = "encounter"
	var full_expected: Dictionary = expected.duplicate()
	var pending: Array = local["pending_checkpoints"]
	if pending.size() > 1:
		return "Horsell has at most one unrequested boundary after an accepted hit/contact"
	var seen: Dictionary = {}
	for id: Variant in pending:
		if not id is String or not expected.has(id) or seen.has(id):
			return "Invalid Horsell pending checkpoint boundary"
		seen[id] = true
		expected.erase(id)
	if not Codec.same_values(progress["checkpoint_ids"], expected):
		return "Horsell checkpoint history differs from cleared/contact boundaries"
	var ordered: Array[String] = ["horsell-arrival-clear", "horsell-road-clear", "horsell-reunion", DEPARTURE_CHECKPOINT_ID]
	var applied: Array[String] = []
	var all_required: Array[String] = []
	for id: String in ordered:
		if full_expected.has(id):
			all_required.append(id)
		if expected.has(id):
			applied.append(id)
	if applied != all_required.slice(0, applied.size()) or pending != all_required.slice(applied.size()):
		return "Horsell pending boundary must be the tail of its ordered checkpoint history"
	if progress["checkpoint_id"] != (applied.back() if not applied.is_empty() else ""):
		return "Horsell current checkpoint differs from its latest requested boundary"
	return ""


func _restore_local_state(state: Dictionary) -> void:
	_scenic_clock = float(state["scenic_clock"])
	_witness_state = state["witness_state"]
	_eruption_visible = state["eruption_visible"]
	if _art_preview:
		_apply_tableau()
		return
	_witness_started_s = float(state["witness_started_s"])
	_eruption_started_s = float(state["eruption_started_s"])
	_profile_id = state["profile_id"]
	_departure_checkpoint = state["departure_checkpoint"]
	_departure_contact_seen = state["departure_contact_seen"]
	_pending_checkpoints.assign(state["pending_checkpoints"])
	_completion_pending = state["completion_pending"]
	_exit_requested = state["exit_requested"]
	_last_action_sequence = int(state["last_action_sequence"])
	_admitted_ids.assign(state["admitted_ids"])
	if not _sequence.call("restore_state", state["sequence"]):
		runtime_error = "Unexpected Horsell sequence restore failure: " + String(_sequence.get("last_snapshot_error"))
		return
	var bindings: Dictionary = _scheduler_bindings()
	for actor_id: String in _actors:
		if not _actors[actor_id].call("restore_state", state["exchange"]["actors"][actor_id]):
			runtime_error = "Unexpected Horsell actor restore failure (%s): %s" % [actor_id, _actors[actor_id].get("last_snapshot_error")]
			return
	if not _scheduler.call("restore_state", state["scheduler"], bindings):
		runtime_error = "Unexpected Horsell scheduler restore failure: " + String(_scheduler.get("last_snapshot_error"))
		return
	if not _exchange.call("restore_state", state["exchange"], bindings):
		runtime_error = "Unexpected Horsell exchange restore failure: " + String(_exchange.get("last_snapshot_error"))
		return
	_update_actor_visibility()
	_apply_tableau()
	_apply_readability()
	_update_objective()
	var blocked: bool = _exit_cue.is_blocking_signals()
	_exit_cue.set_block_signals(true)
	_exit_cue.call("clear")
	if _sequence.call("exit_is_open"):
		_exit_cue.call("present", "active" if _exit_requested else "available", "contact")
	_exit_cue.set_block_signals(blocked)


func _on_exit_level() -> void:
	set_physics_process(false)
	_pending_defeats.clear()
	_defeat_flush_queued = false
	if is_instance_valid(hero) and hero.world_action_executed.is_connected(_on_world_action):
		hero.world_action_executed.disconnect(_on_world_action)
	if is_instance_valid(_exchange):
		if _exchange.is_connected("scout_defeated", _on_scout_defeated):
			_exchange.disconnect("scout_defeated", _on_scout_defeated)
		_exchange.call("cleanup")
	if is_instance_valid(_scheduler):
		_scheduler.call("end_encounter", "level_exit")
	for actor: Node3D in _actors.values():
		if is_instance_valid(actor):
			actor.call("disarm")
	if is_instance_valid(_exit_cue):
		_exit_cue.call("clear")
