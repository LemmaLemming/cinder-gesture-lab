extends "res://scripts/acts/act1/mushroom_caverns.gd"
## Owned native-source composition witness. Reuses the actual grove/guard,
## Player and Scheduler. A translated single mushroom is component geometry;
## this is not the canonical five-room level or a campaign save envelope.

const NativeProtocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const SporeField = preload("res://scripts/environment/spore_field.gd")
const Repulsion = preload("res://scripts/environment/spore_repulsion.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const COMPONENT_API: String = "act1-mushroom-spore-component-1"
const CONTROLLER_ID: String = "mushroom-scheduler"
const FIELD_ID: String = "component-mushroom"
const CONSUMER_ID: String = "component-native-spores"

var spore_field: CinderSporeField
var spore_consumer: CinderSporeRepulsion
var source_protocols: Dictionary = {}
var spores_ready: bool = false
var last_component_error: String = ""


func current_source_ids() -> Array[String]:
	# Isolated real role witness. The separate crowd scene/test still activates
	# all three sources; dormant recipients remain in the complete native pair.
	return ["umbrella-1"] if initial_greybox_room == 0 else ["lone-guard"]


func _physics_process(delta: float) -> void:
	if not _running or _changing or not is_instance_valid(hero): return
	if not spores_ready:
		_bind_component_spores()
		return
	super._physics_process(delta)


func _bind_component_spores() -> void:
	# No hittable cluster is inserted before all actual living sources settle
	# and their pure retained protocol preflight succeeds in one callback.
	for id: String in current_source_ids():
		var response: Dictionary = (sources[id] as Act1MushroomSelenite).get_spore_response_state()
		if response.is_empty() or not response.grounded or not response.outside_transaction: return
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
	field.position = Vector3(-1.6, 0, 11) if initial_greybox_room == 0 else Vector3(1.5, 0, -29.5)
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
	spores_ready = true
	objective_text = "SPORE COMPONENT · HIT THE LOW CLUSTER\nLIVING ENEMIES RETREAT WITHOUT DAMAGE"


func _component_failed(reason: String) -> void:
	last_component_error = reason
	_entry_failed(reason)


func _camera_framing_points() -> Array:
	var points: Array = super._camera_framing_points()
	if not _running or not spores_ready: return points
	if not is_instance_valid(spore_field) or not spore_field.binding_error().is_empty(): return [Vector3.INF]
	var origin: Vector3 = spore_field.global_position
	var radius: float = Layout.FIELD_RADIUS
	for x: float in [-radius, radius]:
		for z: float in [-radius, radius]: points.append(origin + Vector3(x, 0.03, z))
	for offset: Vector3 in Layout.CLUSTER_OFFSETS:
		var centre: Vector3 = origin + offset
		points.append_array(_box_points(AABB(Vector3(-0.2, -0.05, -0.2), Vector3(0.4, 0.5, 0.4)), Transform3D(Basis.IDENTITY, centre)))
	for id: String in current_source_ids():
		var record: Dictionary = spore_consumer.source_state(id)
		if record.get("route", {}).get("planned_endpoint") is Vector3:
			points.append_array(_actor_points(id, record.route.planned_endpoint))
	return _unique_points(points)


func _component_boundary_error() -> String:
	if not spores_ready or not _running or _changing or _callback_depth > 0 or not get_tree().paused or not spore_consumer.snapshot_boundary_available():
		return "Component units require the complete paused native barrier outside callbacks"
	return ""


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
	for id: String in SOURCE_IDS:
		_render_sources[id] = (sources[id] as Act1MushroomSelenite).pure_presentation_state()
	_framing.clear()
	_forecast_points.clear()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()
	last_component_error = ""
	return true


func _on_exit_level() -> void:
	# Retire actual environmental Route custody before native actor/scheduler
	# shutdown; source_interrupted preserves genuine motion and does not fake HP.
	if is_instance_valid(spore_consumer):
		for id: String in current_source_ids():
			if is_instance_valid(sources.get(id)): spore_consumer.source_interrupted(sources[id], "component_exit")
	if is_instance_valid(spore_field): spore_field.set_physics_process(false)
	super._on_exit_level()
