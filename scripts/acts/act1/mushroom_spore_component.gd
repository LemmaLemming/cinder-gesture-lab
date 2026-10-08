extends "res://scripts/acts/act1/mushroom_caverns.gd"
## Owned native-source composition witness. Reuses the actual grove/guard,
## Player and Scheduler. A translated single mushroom is component geometry;
## this is not the canonical five-room level or a campaign save envelope.

const NativeProtocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const SporeField = preload("res://scripts/environment/spore_field.gd")
const Repulsion = preload("res://scripts/environment/spore_repulsion.gd")
const SporeRoute = preload("res://scripts/combat/repulsion_route.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const LowClusterArt = preload("res://scripts/acts/act1/mushroom_cluster_art.gd")
const CLUSTER_IDS: Array[String] = ["cluster-left", "cluster-right"]
const COMPONENT_API: String = "act1-mushroom-spore-component-1"
const CONTROLLER_ID: String = "mushroom-scheduler"
const FIELD_ID: String = "component-mushroom"
const CONSUMER_ID: String = "component-native-spores"
const SPORE_CAMERA_PAD: float = 0.05 # Presentation headroom only; no motion tuning.

var spore_field: CinderSporeField
var spore_consumer: CinderSporeRepulsion
var source_protocols: Dictionary = {}
var spores_ready: bool = false
var last_component_error: String = ""
var _spore_player: CinderPlayer
var _spore_player_parent: Node
var _spore_player_collision: CollisionShape3D
var _spore_player_capsule: CapsuleShape3D
var _spore_player_collision_transform: Transform3D
var _spore_player_radius: float = 0.0
var _spore_player_height: float = 0.0
var _spore_route_callbacks: Dictionary = {}
var _cluster_art: Dictionary = {}


func current_source_ids() -> Array[String]:
	# Isolated real role witness. The separate crowd scene/test still activates
	# all three sources; dormant recipients remain in the complete native pair.
	return ["umbrella-1"] if initial_greybox_room == 0 else ["lone-guard"]


func _physics_process(delta: float) -> void:
	if not _running or _changing or not is_instance_valid(hero): return
	if not spores_ready:
		_bind_component_spores()
		return
	var art_error: String = _refresh_cluster_art()
	if not art_error.is_empty():
		last_component_error = art_error
		return # Existing native presentation/route guards see invalid art bounds.
	super._physics_process(delta)


func _bind_component_spores() -> void:
	# No hittable cluster is inserted before all actual living sources settle
	# and their pure retained protocol preflight succeeds in one callback.
	for id: String in current_source_ids():
		var response: Dictionary = (sources[id] as Act1MushroomSelenite).get_spore_response_state()
		if response.is_empty() or not response.grounded or not response.outside_transaction: return
	if _spore_player == null:
		var player_body: Dictionary = BodySweep.source_description(hero)
		if player_body.has("error") or not player_body.get("collision") is CollisionShape3D or not player_body.collision.shape is CapsuleShape3D:
			_component_failed("Retained actual shared Player capsule is required for spore spacing")
			return
		_spore_player = hero
		_spore_player_parent = hero.get_parent()
		_spore_player_collision = player_body.collision
		_spore_player_capsule = _spore_player_collision.shape
		_spore_player_collision_transform = _spore_player_collision.transform
		_spore_player_radius = _spore_player_capsule.radius
		_spore_player_height = _spore_player_capsule.height
		for id: String in current_source_ids():
			var callback: Callable = Callable(self, "_source_spore_route_error").bind(id)
			_spore_route_callbacks[id] = callback
			(sources[id] as Act1MushroomSelenite).spore_route_guard = callback
			(sources[id] as Act1MushroomSelenite).spore_route_guard_required = true
	var guard_error: String = _component_route_bindings_error()
	if not guard_error.is_empty():
		_component_failed(guard_error)
		return
	var native: Dictionary = scheduler_bindings()
	var environment: Dictionary = {"world_root": native.world_root, "floors": native.floors}
	var recipients: Dictionary = {}
	for id: String in current_source_ids():
		var protocol := NativeProtocol.new()
		if not protocol.configure(sources[id], scheduler, hero, id, CONTROLLER_ID, "hero", environment):
			_component_failed("Native spore configure: " + protocol.last_error)
			return
		source_protocols[id] = protocol
		recipients[id] = sources[id]
	var field := SporeField.new()
	field.name = "ComponentMushroom"
	# Keep the guard's complete possible retreat costume and genuine native
	# escape/return proof within the fixed portrait. The right low anchor remains
	# ordinary-primary reachable behind the neutral forward-dash landing, so
	# aiming at it excludes the living guard from the real broad primary cone.
	field.position = Vector3(-1.6, 0, 11) if initial_greybox_room == 0 else Vector3(0.9, 0, -28.8)
	if not field.configure(FIELD_ID, [{"id": "cluster-left", "offset": Layout.CLUSTER_OFFSETS[0]}, {"id": "cluster-right", "offset": Layout.CLUSTER_OFFSETS[1]}], {"radius": Layout.FIELD_RADIUS, "duration_s": 3.0, "thinning_s": 0.5}):
		_component_failed("Component mushroom definition: " + field.last_error)
		field.free()
		return
	add_child(field)
	spore_field = field
	var consumer := Repulsion.new()
	consumer.name = "ComponentSporeRepulsion"
	var directions: Array[Vector3] = [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]: directions.append(Vector3(x, 0, z).normalized())
	if not consumer.configure(CONSUMER_ID, directions):
		_component_failed("Component spore definition: " + consumer.last_error)
		consumer.free()
		return
	add_child(consumer)
	spore_consumer = consumer
	if not consumer.bind_environment({"world_root": native.world_root, "floors": native.floors, "fields": {FIELD_ID: field}, "sources": recipients, "source_protocols": source_protocols}):
		_component_failed("Actual native spore binding: " + consumer.last_error)
		return
	if not _bind_cluster_art():
		_component_failed("Native low-cluster art binding: " + last_component_error)
		return
	spore_field.state_changed.connect(_on_cluster_field_state)
	spores_ready = true
	objective_text = "SPORE COMPONENT · HIT THE LOW CLUSTER\nLIVING ENEMIES RETREAT WITHOUT DAMAGE"


func _bind_cluster_art() -> bool:
	for id: String in CLUSTER_IDS:
		var cluster := spore_field.get_node_or_null(id) as Node3D
		var visual = LowClusterArt.new()
		visual.name = "AuthoredLowCluster"
		if not visual.configure(cluster, spore_field):
			last_component_error = visual.last_error
			visual.free()
			return false
		cluster.add_child(visual)
		_cluster_art[id] = visual
		last_component_error = String(visual.binding_error())
		if not last_component_error.is_empty(): return false
	return true


func _cluster_art_error() -> String:
	if not Codec.keys_error(_cluster_art, CLUSTER_IDS).is_empty(): return "Both actual low-cluster art leaves are required"
	for id: String in CLUSTER_IDS:
		var visual := _cluster_art.get(id) as Node3D
		if not is_instance_valid(visual) or visual.is_queued_for_deletion() or not visual.is_inside_tree() or visual.get_script() != LowClusterArt or visual.get_parent() != spore_field.get_node_or_null(id): return "Retained native cluster art identity changed"
		var error: String = String(visual.call("binding_error"))
		if not error.is_empty(): return id + ": " + error
	return ""


func _refresh_cluster_art() -> String:
	if not Codec.keys_error(_cluster_art, CLUSTER_IDS).is_empty(): return "Both native cluster art leaves must already exist"
	for id: String in CLUSTER_IDS:
		var visual := _cluster_art.get(id) as Node3D
		if not is_instance_valid(visual) or visual.is_queued_for_deletion() or not visual.is_inside_tree() or visual.get_script() != LowClusterArt or visual.get_parent() != spore_field.get_node_or_null(id): return "Retain actual cluster art before presentation"
		var error: String = String(visual.call("sync_from_native"))
		if not error.is_empty(): return id + ": " + error
	return ""


func _on_cluster_field_state(_native_state: Dictionary) -> void:
	# Field emits after every native cluster has selected its honest new state.
	# Quiet restore suppresses this signal and calls the same sync explicitly.
	if not _running or not spores_ready: return
	var error: String = _refresh_cluster_art()
	if not error.is_empty(): last_component_error = error


func _component_failed(reason: String) -> void:
	last_component_error = reason
	_entry_failed(reason)


func _camera_framing_points() -> Array:
	var points: Array = super._camera_framing_points()
	if not _running or not spores_ready: return points
	if not is_instance_valid(spore_field) or not spore_field.binding_error().is_empty() or not _cluster_art_error().is_empty(): return [Vector3.INF]
	var origin: Vector3 = spore_field.global_position
	var radius: float = Layout.FIELD_RADIUS
	for x: float in [-radius, radius]:
		for z: float in [-radius, radius]: points.append(origin + Vector3(x, 0.03, z))
	for offset: Vector3 in Layout.CLUSTER_OFFSETS:
		var centre: Vector3 = origin + offset
		points.append_array(_box_points(AABB(Vector3(-0.2, -0.05, -0.2), Vector3(0.4, 0.5, 0.4)), Transform3D(Basis.IDENTITY, centre)))
	for cluster_id: String in CLUSTER_IDS:
		var art_points: Array = _cluster_art[cluster_id].call("framing_points", shared_shell)
		if art_points.is_empty(): return [Vector3.INF]
		points.append_array(art_points)
	for id: String in current_source_ids():
		var actor: Act1MushroomSelenite = sources[id]
		if not actor.dead:
			# Announce the entire possible outside-field silhouette BEFORE a hit.
			# A reaction callback may pause before Game's next camera update. Keep
			# all native quad/body extrema, compressed only by convex AABB bounds.
			var response: Dictionary = actor.get_spore_response_state()
			if response.is_empty(): return [Vector3.INF]
			var exit_radius: float = radius + float(response.support_radius) + float(Repulsion.DEFAULTS.exit_clearance) + SPORE_CAMERA_PAD
			var actual: Array = _actor_points(id, actor.global_position)
			var extrema: Array = []
			for x: float in [-exit_radius, exit_radius]:
				for z: float in [-exit_radius, exit_radius]:
					var endpoint := Vector3(origin.x + x, actor.global_position.y, origin.z + z)
					for point: Vector3 in actual: extrema.append(point + endpoint - actor.global_position)
			if extrema.is_empty(): return [Vector3.INF]
			var bounds := AABB(extrema[0], Vector3.ZERO)
			for point: Vector3 in extrema: bounds = bounds.expand(point)
			points.append_array(_box_points(bounds, Transform3D.IDENTITY))
		var record: Dictionary = spore_consumer.source_state(id)
		if record.get("route", {}).get("planned_endpoint") is Vector3:
			points.append_array(_actor_points(id, record.route.planned_endpoint))
	return _unique_points(points)


func _component_route_bindings_error() -> String:
	# Actual resources are bindings, not serialized motion copies. This witness
	# certifies one living recipient; the remaining retained actors stay dormant.
	if not is_inside_tree() or is_queued_for_deletion() or not _running or _changing or not is_instance_valid(shared_shell): return "Running actual spore component bindings required"
	if not is_instance_valid(hero) or hero != _spore_player or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_parent() != _spore_player_parent or hero.get_world_3d() != get_world_3d(): return "Retain the actual shared Player and containing world"
	var player_body: Dictionary = BodySweep.source_description(hero)
	if player_body.has("error") or player_body.get("collision") != _spore_player_collision or not is_instance_valid(_spore_player_collision) or not is_instance_valid(_spore_player_capsule) or _spore_player_collision.shape != _spore_player_capsule or _spore_player_collision.transform != _spore_player_collision_transform or _spore_player_capsule.radius != _spore_player_radius or _spore_player_capsule.height != _spore_player_height: return "Retain the actual shared Player capsule dimensions/pivot/resource"
	var error: String = _floor_error()
	if error.is_empty(): error = _scenery_error()
	if not error.is_empty(): return error
	if spores_ready:
		error = _cluster_art_error()
		if not error.is_empty(): return error
	if current_source_ids().size() != 1: return "Spore route spacing currently certifies one actual living recipient"
	for id: String in SOURCE_IDS:
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor) or actor != _retained_sources.get(id) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_parent() != self or actor.get_world_3d() != get_world_3d(): return "Retain every actual component source/neighbor"
		error = actor.body_binding_error()
		if not error.is_empty(): return error
		if id not in current_source_ids():
			if not actor.dead and not actor.dormant: return "Additional living neighbors require a separate tested compound route guard"
			continue
		if actor.spore_route_guard_required != true or actor.spore_route_guard != _spore_route_callbacks.get(id) or not actor.spore_route_guard.is_valid(): return "Retain the mandatory one-role source route guard"
		if not actor.dead:
			error = actor.art_binding_error()
			if not error.is_empty(): return error
	return ""


func _source_spore_route_error(proposal: Dictionary, id: String) -> String:
	var error: String = _component_route_bindings_error()
	if not error.is_empty(): return error
	if not Codec.keys_error(proposal, ["source_id", "consumer", "episode_id", "boundary", "direction"]).is_empty() or proposal.source_id != id or proposal.consumer != spore_consumer or not proposal.episode_id is String or proposal.boundary not in ["cancel", "continue"] or not proposal.direction is Vector3: return "Closed actual source route boundary proposal required"
	if get_tree().paused or not spores_ready or hero.dead or not is_instance_valid(spore_consumer) or not spore_consumer.source_binding_matches(sources[id], id) or not is_instance_valid(spore_field): return "Actual live environmental source/Player/field bindings required"
	error = spore_field.binding_error()
	if not error.is_empty(): return error
	var actor: Act1MushroomSelenite = sources[id]
	var response: Dictionary = actor.get_spore_response_state()
	var record: Dictionary = spore_consumer.source_state(id)
	var required_phase: String = "recoil" if proposal.boundary == "cancel" else "interrupted"
	if response.is_empty() or not response.alive or not response.grounded or not response.outside_transaction or record.get("episode_id") != proposal.episode_id or record.get("phase") != required_phase or not record.get("original_endpoint") is Vector3: return "Actual prepared same-episode endpoint required before owned hook commit"
	var start: Vector3 = actor.global_position
	var original_endpoint: Vector3 = record.original_endpoint
	if not original_endpoint.is_finite() or absf(original_endpoint.y - start.y) > SporeRoute.ENDPOINT_TOLERANCE: return "Native original endpoint must retain the actual supported feet plane"
	# The native continuation preserves XZ and current feet Y. This is a pure
	# horizontal query, never a physical pose or endpoint rewrite.
	var finish := Vector3(original_endpoint.x, start.y, original_endpoint.z)
	var displacement: Vector3 = finish - start
	if not displacement.is_finite() or displacement.length() <= Repulsion.EPSILON or displacement.length() > BodySweep.MAX_DISTANCE or not proposal.direction.is_finite(): return "Bounded actual prepared retreat displacement required"
	if proposal.boundary == "continue" and (proposal.direction as Vector3) != displacement.normalized(): return "Actual continuation must point toward the immutable original endpoint"
	var native: Dictionary = scheduler_bindings()
	var sweep: Dictionary = BodySweep.sweep(actor, Transform3D(Basis.IDENTITY, start), displacement, native.floors.values())
	if sweep.has("error") or sweep.get("collided", true) or not sweep.get("end") is Vector3 or sweep.end.distance_to(finish) > BodySweep.position_rounding_bound(start, finish): return "Actual complete retreat body path must remain supported and clear: " + String(sweep.get("error", "blocked endpoint"))
	# All other recipients were proven dormant/defeated above, so this call does
	# not fabricate a neighbor timing horizon. Its real capsule semantics remain
	# reusable when a separate compound policy supplies complete native paths.
	error = _source_path_gap_error(id, start, finish, 0.0)
	if not error.is_empty(): return error
	var player_response: Dictionary = hero.get_threat_response_state()
	var motion: Dictionary = player_response.get("motion", {})
	var dash: Dictionary = hero.get_committed_dash_state()
	if motion.is_empty() or not motion.get("grounded", false) or dash.is_empty(): return "Grounded actual Player motion/commitment required for route spacing"
	var player_endpoint: Vector3 = hero.global_position
	if dash.get("active", false):
		player_endpoint = dash.origin + dash.direction * float(dash.distance)
	elif motion.get("velocity") != Vector3.ZERO or motion.get("queued_dash") != Vector3.ZERO:
		return "One-role route guard does not certify uncommitted Player hurt/queued motion"
	var capsule := _retained_capsules[id] as CapsuleShape3D
	if not is_instance_valid(capsule) or _planar_segment_distance(start, finish, hero.global_position, player_endpoint) < capsule.radius + _spore_player_radius + 0.12: return "Actual retreat path/landing needs a clear Player capsule and committed dash gap"
	# Only after real world/capsule proof: source, field, old native cue/opening,
	# complete prospective sprite/body and Player/dash union in the current view.
	# No camera fit request, private camera override or mechanical permission.
	var points: Array = _camera_framing_points()
	points.append_array(_actor_points(id, finish))
	var player_points: Array = shared_shell.call("player_camera_framing_points")
	if player_points.is_empty(): return "Actual full Player presentation required"
	points.append_array(player_points)
	for point: Vector3 in player_points: points.append(point + player_endpoint - hero.global_position)
	return _containment_error(_unique_points(points))


func _component_boundary_error() -> String:
	if not spores_ready or not _running or _changing or _callback_depth > 0 or not get_tree().paused or not spore_consumer.snapshot_boundary_available():
		return "Component units require the complete paused native barrier outside callbacks"
	return _component_route_bindings_error()


func component_unit_state() -> Dictionary:
	last_component_error = _component_boundary_error()
	if not last_component_error.is_empty(): return {}
	var player: Dictionary = hero.snapshot_state()
	var control: Dictionary = scheduler.snapshot_state(scheduler_bindings())
	if player.is_empty() or control.is_empty():
		last_component_error = "Actual Player/Scheduler component capture rejected"
		return {}
	var pair: Dictionary = {"controllers": {CONTROLLER_ID: control}, "players": {"hero": player}}
	var actors: Dictionary = {}
	for id: String in SOURCE_IDS:
		var actor: Act1MushroomSelenite = sources[id]
		actors[id] = source_protocols[id].current_unit(pair) if source_protocols.has(id) else actor.capture_state(control)
		if actors[id].is_empty():
			last_component_error = "Actual component actor capture rejected: " + id + ": " + (source_protocols[id].last_error if source_protocols.has(id) else actor.last_snapshot_error)
			return {}
	var fields: Dictionary = {FIELD_ID: spore_field.snapshot_state()}
	var value: Dictionary = {"api_revision": COMPONENT_API, "player": player, "scheduler": control, "actors": actors, "fields": fields}
	var context: Dictionary = _component_context(value)
	value["coordinator"] = spore_consumer.snapshot_state(context)
	last_component_error = component_unit_error(value)
	return value.duplicate(true) if last_component_error.is_empty() else {}


func _component_context(unit: Dictionary) -> Dictionary:
	var opted: Dictionary = {}
	for id: String in source_protocols: opted[id] = unit.actors[id]
	return {"fields": unit.fields, "sources": opted, "controllers": {CONTROLLER_ID: unit.scheduler}, "players": {"hero": unit.player}}


func component_unit_error(unit: Dictionary) -> String:
	var error: String = _component_boundary_error()
	if not error.is_empty(): return error
	if Exact.stringify(unit).is_empty() or not Codec.keys_error(unit, ["api_revision", "player", "scheduler", "actors", "fields", "coordinator"]).is_empty() or unit.api_revision != COMPONENT_API:
		return "Closed complete native spore component transport required"
	for key: String in ["player", "scheduler", "actors", "fields", "coordinator"]:
		if not unit[key] is Dictionary: return "Complete component unit maps required"
	if not Codec.keys_error(unit.actors, SOURCE_IDS).is_empty() or not Codec.keys_error(unit.fields, [FIELD_ID]).is_empty(): return "Exact actual component actor/field coverage required"
	error = hero.snapshot_error(unit.player)
	if not error.is_empty(): return error
	if unit.scheduler.get("encounter_id") != _encounter_id() or unit.scheduler.get("world_revision") != WORLD_REVISION or Exact.stringify(unit.scheduler.get("profile")) != Exact.stringify(scheduler.encounter_profile()):
		return "Actual component encounter/world/resolved profile must remain the same"
	for id: String in SOURCE_IDS:
		if not unit.actors[id] is Dictionary: return "Complete native actor required"
		error = (sources[id] as Act1MushroomSelenite).snapshot_error(unit.actors[id], unit.scheduler, unit.player)
		if not error.is_empty(): return id + ": " + error
		if unit.actors[id].dormant != (id not in current_source_ids()): return "Component activated/dormant composition changed"
	var staged: Dictionary = _component_staged_bindings(unit)
	if staged.is_empty(): return "Actual complete source staging rejected"
	error = scheduler.snapshot_error(unit.scheduler, staged)
	if not error.is_empty(): return error
	if not unit.fields[FIELD_ID] is Dictionary: return "Complete actual field required"
	error = spore_field.snapshot_error(unit.fields[FIELD_ID])
	if not error.is_empty(): return error
	return spore_consumer.snapshot_error(unit.coordinator, _component_context(unit))


func _component_staged_bindings(unit: Dictionary) -> Dictionary:
	var native: Dictionary = scheduler_bindings()
	for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]: native[key] = {}
	for id: String in SOURCE_IDS:
		var staged: Dictionary = (sources[id] as Act1MushroomSelenite).staged_actor_bindings(unit.actors[id])
		if staged.is_empty(): return {}
		for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]:
			for owner_id: String in staged[key]: native[key][owner_id] = staged[key][owner_id]
	native["hero_positions"] = {"hero": Codec.read_vector3(unit.player.motion.position)}
	return native


func restore_component_unit(unit: Dictionary) -> bool:
	last_component_error = component_unit_error(unit)
	if not last_component_error.is_empty(): return false
	var native: Dictionary = _component_staged_bindings(unit)
	# Every whole unit validates before any mutation. No yield or admission,
	# configuration, damage, cancellation, time advance or signals in this commit.
	if not spore_field.restore_state(unit.fields[FIELD_ID]) or not hero.restore_state(unit.player): return false
	for id: String in SOURCE_IDS:
		if not (sources[id] as Act1MushroomSelenite).restore_actor_state(unit.actors[id]): return false
	if not scheduler.restore_state(unit.scheduler, native): return false
	for id: String in SOURCE_IDS:
		if not (sources[id] as Act1MushroomSelenite).restore_exchange_state(unit.actors[id]): return false
	if not spore_consumer.restore_state(unit.coordinator, _component_context(unit)): return false
	last_component_error = _refresh_cluster_art() # Native Field restore was quiet.
	if not last_component_error.is_empty(): return false
	for id: String in SOURCE_IDS:
		_render_sources[id] = (sources[id] as Act1MushroomSelenite).pure_presentation_state()
	_framing.clear()
	_forecast_points.clear()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()
	last_component_error = ""
	return true


func _on_exit_level() -> void:
	if is_instance_valid(spore_field) and spore_field.state_changed.is_connected(_on_cluster_field_state):
		spore_field.state_changed.disconnect(_on_cluster_field_state)
	# Retire actual environmental Route custody before native actor/scheduler
	# shutdown; source_interrupted preserves genuine motion and does not fake HP.
	if is_instance_valid(spore_consumer):
		for id: String in current_source_ids():
			if is_instance_valid(sources.get(id)): spore_consumer.source_interrupted(sources[id], "component_exit")
	if is_instance_valid(spore_field): spore_field.set_physics_process(false)
	super._on_exit_level()
