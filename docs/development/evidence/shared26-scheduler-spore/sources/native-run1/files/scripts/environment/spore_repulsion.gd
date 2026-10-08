class_name CinderSporeRepulsion
extends Node3D
## Opt-in living-enemy environmental controller. A measured straight retreat
## is proved before cancelling a real attack. Full circles require a supported
## no-wall authored domain; unsupported placements fail visibly. This is not
## a field-placement generator or an encounter/ordinary-primary fairness proof.
## Inactive registered circles constrain landing ONLY, never reaction/immunity.

signal reaction_started(source_id: String, episode_id: String)
signal placement_rejected(source_id: String, reason: String)

const Enemy = preload("res://scripts/enemy.gd")
const Route = preload("res://scripts/combat/repulsion_route.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const NativeProtocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const API_REVISION: String = "spore-repulsion-1"
const MAX_CLOCK: float = 1000000000.0
const EPSILON: float = 0.00001
const DEFAULTS: Dictionary = {"recoil_s": 0.12, "turn_s": 0.10, "regroup_s": 0.35, "speed": 4.0, "max_distance": 8.0, "exit_clearance": 0.08}

var last_error: String = ""
var _definition: Dictionary = {}
var _bindings: Dictionary = {}
var _geometry: Dictionary = {}
var _environments: Dictionary = {}
var _records: Dictionary = {}
var _failures: Dictionary = {}
var _failure_markers: Dictionary = {}
var _serial: int = 0
var _busy: bool = false
var _validating: bool = false
var _source_protocols: Dictionary = {}
var _binding_candidates: Dictionary = {}


## Configure before insertion. Finite authored normalized candidate directions
## are mandatory; no hidden sampled/fallback direction is treated as proof.
func configure(instance_id: String, directions: Array, parameters: Dictionary = {}) -> bool:
	if is_inside_tree() or not _definition.is_empty() or not _id(instance_id) or directions.is_empty() or directions.size() > 32:
		return _reject("Immutable consumer ID and one to 32 authored directions required")
	var encoded: Array = []
	for direction: Variant in directions:
		if not direction is Vector3 or not direction.is_finite() or absf(direction.y) > EPSILON or absf(direction.length() - 1.0) > EPSILON:
			return _reject("Candidate directions must be normalized planar vectors")
		encoded.append(Codec.vector3(direction))
	var resolved: Dictionary = DEFAULTS.duplicate(true)
	for key: Variant in parameters:
		if not key is String or not resolved.has(key):
			return _reject("Unsupported spore controller parameter")
		resolved[key] = parameters[key]
	for key: String in ["recoil_s", "turn_s", "regroup_s"]:
		if not Codec.in_range(resolved[key], 0.01, 4.0):
			return _reject("Finite bounded reaction timings required")
	if not Codec.in_range(resolved.speed, 0.1, 16.0) or not Codec.in_range(resolved.max_distance, 0.1, 16.0) or float(resolved.max_distance) / float(resolved.speed) > 16.0 or not Codec.in_range(resolved.exit_clearance, 0.01, 0.5):
		return _reject("Finite bounded retreat travel/clearance required")
	_definition = {"id": instance_id, "directions": encoded, "parameters": resolved}
	return true


## bindings={world_root:Node3D,floors:{id:{collision,safe_rect}},
## fields:{id:CinderSporeField},sources:{id:AshEnemy}}. IDs and full-circle
## footprints are immutable. Source/field units remain authoritative externally.
func bind_environment(bindings: Dictionary) -> bool:
	if _busy or not _bindings.is_empty() or _definition.is_empty() or not is_inside_tree() or not Codec.keys_error(bindings, ["world_root", "floors", "fields", "sources", "source_protocols"] if bindings.has("source_protocols") else ["world_root", "floors", "fields", "sources"]).is_empty() or not bindings.fields is Dictionary or not bindings.sources is Dictionary or bindings.fields.is_empty() or bindings.fields.size() > 16 or bindings.sources.is_empty() or bindings.sources.size() > 64:
		return _reject("Ready unbound coordinator requires finite immutable environment bindings")
	var root_node: Node3D = bindings.world_root as Node3D
	if not is_instance_valid(root_node) or not root_node.is_inside_tree() or root_node.get_world_3d() != get_world_3d() or not _under(self, root_node):
		return _reject("Coordinator must belong to the actual stable world root")
	var protocols: Variant = bindings.get("source_protocols", {})
	if not protocols is Dictionary:
		return _reject("Native source_protocols must be an explicit opted binding map")
	for id: Variant in protocols:
		if not bindings.sources.has(id) or not is_instance_valid(protocols[id]) or not protocols[id] is NativeProtocol:
			return _reject("Native protocol map must identify actual configured opted sources")
	var native_ids: Array = protocols.keys()
	for first: int in range(native_ids.size()):
		for second: int in range(first + 1, native_ids.size()):
			var compatibility: String = protocols[native_ids[first]].binding_compatibility_error(protocols[native_ids[second]])
			if not compatibility.is_empty():
				return _reject(compatibility)
	var staged_geometry: Dictionary = {}
	var staged_environments: Dictionary = {}
	var used: Dictionary = {}
	for id: Variant in bindings.fields:
		var field: Node3D = bindings.fields[id] as Node3D
		if not _id(id) or not is_instance_valid(field) or not _under(field, root_node) or field.get_world_3d() != get_world_3d() or not field.has_method("active_domain") or not field.has_method("snapshot_error") or not field.has_method("binding_error") or not field.has_signal("activated") or used.has(field.get_instance_id()):
			return _reject("Distinct actual spore fields under the stable world root required")
		var field_error: String = field.call("binding_error")
		if not field_error.is_empty():
			return _reject(field_error)
		var live: Dictionary = field.call("state")
		var cue: Dictionary = field.call("get_cue_state")
		if not live.get("bound", false) or live.get("instance_id") != id or not cue.get("geometry") is Dictionary:
			return _reject("Field binding must match its configured stable ID")
		staged_geometry[id] = cue.geometry.duplicate(true)
		used[field.get_instance_id()] = true
	for id: Variant in bindings.sources:
		var source: CharacterBody3D = bindings.sources[id] as CharacterBody3D
		if not _id(id) or not is_instance_valid(source) or (not source is Enemy and not protocols.has(id)) or not _under(source, root_node) or source.get_world_3d() != get_world_3d() or not source.has_method("get_spore_response_state") or not source.has_method("bind_spore_repulsion") or used.has(source.get_instance_id()):
			return _reject("Distinct real opt-in living sources required")
		if protocols.has(id) and not protocols[id].matches_source(source, id):
			return _reject("Native composition must retain this exact actual source")
		var response: Dictionary = _response_for(source, bindings)
		if response.is_empty() or not response.alive or not response.outside_transaction:
			return _reject("Source must be alive, unbound and outside actor callbacks")
		if protocols.has(id):
			if response.api_revision != NativeProtocol.ACTOR_REVISION or response.source_id != id or not response.consumer_id.is_empty():
				return _reject("Native source must retain its permanent ID and empty environmental binding")
		elif response.get("api_revision") != "ash-spore-adapter-1" or not response.source_id.is_empty():
			return _reject("Ordinary Ash source must retain its existing unbound contract")
		var error: String = _domain_error(source, bindings, staged_geometry)
		if not error.is_empty():
			return _reject(error)
		staged_environments[id] = Route.binding_state(source, bindings)
		used[source.get_instance_id()] = true
	# All native pure guards run before any actor binding commit. The temporary
	# map answers exact source custody only; it is cleared on every path.
	_binding_candidates = bindings.sources.duplicate()
	for id: String in protocols:
		var guard: String = protocols[id].bind_error(self)
		if not guard.is_empty():
			_binding_candidates.clear()
			return _reject(guard)
	_binding_candidates.clear()
	_bindings = bindings.duplicate(true)
	_source_protocols = protocols.duplicate()
	_geometry = staged_geometry
	_environments = staged_environments
	_busy = true
	for id: String in _bindings.sources:
		var committed: bool = _source_protocols[id].bind(self) if _source_protocols.has(id) else bool(_bindings.sources[id].call("bind_spore_repulsion", self, id))
		if not committed:
			# All actor requirements were prevalidated; no callback occurs between
			# proof and commit. An unexpected external mutation fails closed.
			_busy = false
			return _reject("Source binding changed at the environmental commit boundary")
	for id: String in _bindings.fields:
		_bindings.fields[id].activated.connect(_on_activated)
	_busy = false
	last_error = ""
	return true


func consumer_id() -> String:
	return _definition.get("id", "")


func source_binding_matches(source: Node, source_id: String) -> bool:
	return _bindings.get("sources", _binding_candidates).get(source_id) == source


func snapshot_boundary_available() -> bool:
	return not _busy and not _validating and not _bindings.is_empty()


func placement_accepted() -> bool:
	return not _bindings.is_empty() and _failures.is_empty() and _binding_error().is_empty()


func source_state(source_id: String) -> Dictionary:
	var record: Dictionary = _records.get(source_id, {}).duplicate(true)
	if record.has("route"):
		record.route = record.route.state() if record.route != null else {}
	return record


## Invoked before this source's old physics controller. Returning false lets
## actual damage/hurt/airborne motion resolve; that does not re-arm an attack.
## Cooldowns remain owned by the actor and count down exactly once per tick.
func step_source(source: CharacterBody3D, delta: float) -> bool:
	if _busy or _validating or not is_finite(delta) or delta < 0.0 or delta > 0.25 or get_tree().paused:
		return true
	var id: String = _source_id(source)
	if id.is_empty():
		return true
	var response: Dictionary = _response_for(source)
	if response.is_empty():
		_fail(id, "Retained native source response became unavailable")
		return true
	if not response.alive:
		_cleanup(id, source)
		return false
	if not response.outside_transaction:
		return false
	var binding_error: String = _binding_error()
	if not binding_error.is_empty():
		_fail(id, binding_error)
		return not response.episode_id.is_empty() and response.phase != "interrupted"
	var domains: Array = _active_domains()
	if _source_protocols.has(id) and _failures.has(id):
		# A native custody fault cannot later reacquire a route. Keep actual
		# hurt/airborne settling with its actor; never erase external impulse.
		return float(response.hurt_remaining_s) <= 0.0 and response.grounded and (response.velocity as Vector3).length() <= EPSILON
	if not _records.has(id):
		if _failures.has(id):
			return false
		var members: Array = _component_at(response.position, float(response.support_radius), domains)
		if members.is_empty():
			return false
		# Preserve real airborne/hurt motion. First reaction waits for a valid
		# grounded planar response rather than cancelling player damage.
		if not response.grounded or float(response.hurt_remaining_s) > 0.0 or absf((response.velocity as Vector3).y) > EPSILON:
			return false
		var prepared: Dictionary = _prepare(source, response, domains, members)
		if prepared.has("error"):
			_fail(id, prepared.error)
			return false
		var initial_boundary: Dictionary = {}
		if _source_protocols.has(id):
			initial_boundary = _native_boundary_state(id)
			if initial_boundary.is_empty() or not initial_boundary.control.outside_transaction or not initial_boundary.response.outside_transaction or not _copied_same(Codec.vector3(initial_boundary.response.position), Codec.vector3(prepared.route.state().start)) or not _copied_same(Codec.vector3(initial_boundary.response.velocity), Codec.vector3(prepared.route.state().approach_velocity)):
				_fail(id, "Native prepared source/controller custody changed before cancellation")
				return false
			if not initial_boundary.control.reservations.is_empty() and initial_boundary.control.reservations[0].get("adapter", {}).get("kind") == "lunge":
				var original_adapter: Dictionary = initial_boundary.control.reservations[0].adapter
				if not original_adapter.get("current_position") is Vector3 or not original_adapter.get("current_velocity") is Vector3 or not _copied_same(Codec.vector3(original_adapter.current_position), Codec.vector3(initial_boundary.response.position)) or not _copied_same(Codec.vector3(original_adapter.current_velocity), Codec.vector3(initial_boundary.response.velocity)):
					_fail(id, "Original owned lunge differs from the actual prepared native motion")
					return false
		_serial += 1
		var episode_id: String = "%s/episode-%d" % [consumer_id(), _serial]
		_busy = true
		if _source_protocols.has(id):
			_records[id] = {"episode_id": episode_id, "phase": "recoil", "age_s": 0.0, "phase_age_s": 0.0, "members": members, "direction": prepared.direction, "progress": 0.0, "original_endpoint": prepared.endpoint, "route_revision": 1, "route_started_age_s": 0.0, "route": null}
			var cancelled: bool = bool(source.call("cancel_attack_for_spores", self, episode_id, prepared.direction))
			var initial_after: Dictionary = _native_boundary_state(id)
			var post: Dictionary = initial_after.get("response", {})
			if not cancelled:
				_records.erase(id)
				_busy = false
				_fail(id, "Actual native attack cancellation rejected")
				return false
			if post.is_empty():
				_busy = false
				_fail(id, "Native callback changed source/body/controller/world custody")
				return true
			if not post.alive:
				_cleanup(id, source)
				_busy = false
				return false
			if not _records.has(id):
				_busy = false
				_fail(id, "Living source lost its committed episode during cancellation")
				return true
			var initial_error: String = _native_boundary_error(initial_boundary, initial_after)
			if not initial_error.is_empty() or not initial_after.control.reservations.is_empty():
				_busy = false
				_fail(id, "Native cancellation changed original controller custody: " + initial_error)
				return not (post.phase == "interrupted" or float(post.hurt_remaining_s) > 0.0 or not post.grounded or absf((post.velocity as Vector3).y) > EPSILON)
			if float(post.hurt_remaining_s) > 0.0 or post.phase == "interrupted" or not post.grounded or absf((post.velocity as Vector3).y) > EPSILON:
				_records[id].phase = "interrupted"
				_records[id].progress = 0.0
				source.call("present_spore_phase", self, episode_id, "interrupted", 0.0)
				_busy = false
				return false # preserve real hurt/airborne impulse; no acquire/zero
			# Only cancellation of a retained owned lunge authorizes early zeroing.
			# Other sources retain approach velocity until the measured route acquires.
			var expected_velocity: Vector3 = prepared.route.state().approach_velocity
			if not initial_boundary.control.reservations.is_empty() and initial_boundary.control.reservations[0].get("adapter", {}).get("kind") == "lunge":
				expected_velocity = Vector3.ZERO
			if not initial_error.is_empty() or not initial_after.control.reservations.is_empty() or post.episode_id != episode_id or post.phase != "recoil" or not _copied_same(Codec.vector3(post.position), Codec.vector3(prepared.route.state().start)) or not _copied_same(Codec.vector3(post.velocity), Codec.vector3(expected_velocity)) or not _copied_same(Codec.vector3(post.direction), Codec.vector3(prepared.direction)) or not _copied_same(post.progress, 0.0):
				_busy = false
				_fail(id, "Native cancellation changed exact prepared motion/controller custody: " + initial_error)
				return true
			if not prepared.route.acquire(source):
				_busy = false
				_fail(id, "Proved native retreat could not commit its actual source lease")
				return true
			_records[id].route = prepared.route
		else:
			if not bool(source.call("cancel_attack_for_spores", self, episode_id, prepared.direction)) or not prepared.route.acquire(source):
				_busy = false
				_fail(id, "Proved retreat could not commit its actual source lease")
				return true
			_records[id] = {"episode_id": episode_id, "phase": "recoil", "age_s": 0.0, "phase_age_s": 0.0, "members": members, "direction": prepared.direction, "progress": 0.0, "original_endpoint": prepared.endpoint, "route_revision": 1, "route_started_age_s": 0.0, "route": prepared.route}
		reaction_started.emit(id, episode_id)
		_busy = false
		return true
	var record: Dictionary = _records[id]
	record.age_s = float(record.age_s) + delta
	record.phase_age_s = float(record.phase_age_s) + delta
	if float(record.age_s) > MAX_CLOCK:
		_fail(id, "Spore episode clock exceeded its finite snapshot range")
		return true
	_merge_members(record, domains, float(response.support_radius))
	var still_active: bool = _members_active(record.members, domains)
	if record.phase == "interrupted":
		if not response.grounded or float(response.hurt_remaining_s) > 0.0 or (response.velocity as Vector3).length() > EPSILON:
			return false
		if _outside(response.position, float(response.support_radius), false):
			_set_phase(source, record, "hold")
			return true
		var continued: Dictionary = _continue(source, response, record)
		if continued.has("error"):
			_fail(id, continued.error)
			return false
		var continued_boundary: Dictionary = {}
		if _source_protocols.has(id):
			continued_boundary = _native_boundary_state(id)
			if continued_boundary.is_empty() or not continued_boundary.control.outside_transaction or not continued_boundary.response.outside_transaction or not continued_boundary.control.reservations.is_empty() or not _copied_same(Codec.vector3(continued_boundary.response.position), Codec.vector3(continued.route.state().start)) or not _copied_same(Codec.vector3(continued_boundary.response.velocity), Codec.vector3(continued.route.state().approach_velocity)):
				_fail(id, "Native prepared continuation custody changed before resume")
				return false
		_busy = true
		var resumed: bool = bool(source.call("resume_spore_retreat", self, record.episode_id, continued.direction))
		if _source_protocols.has(id):
			var continued_after: Dictionary = _native_boundary_state(id)
			var post: Dictionary = continued_after.get("response", {})
			if not post.is_empty() and (not post.alive or not _records.has(id)):
				_cleanup(id, source)
				_busy = false
				return false
			var continued_error: String = _native_boundary_error(continued_boundary, continued_after)
			if not continued_error.is_empty() or not continued_after.control.reservations.is_empty():
				_busy = false
				_fail(id, "Native continuation changed original controller custody: " + continued_error)
				return false
			if not post.is_empty() and (float(post.hurt_remaining_s) > 0.0 or post.phase == "interrupted" or not post.grounded or absf((post.velocity as Vector3).y) > EPSILON):
				record.phase = "interrupted"
				record.progress = 0.0
				_busy = false
				return false
			if not continued_error.is_empty() or not continued_after.control.reservations.is_empty() or post.episode_id != record.episode_id or post.phase != "retreat" or not _copied_same(Codec.vector3(post.position), Codec.vector3(continued.route.state().start)) or not _copied_same(Codec.vector3(post.velocity), Codec.vector3(continued.route.state().approach_velocity)) or not _copied_same(Codec.vector3(post.direction), Codec.vector3(continued.direction)) or not _copied_same(post.progress, 0.0):
				_busy = false
				_fail(id, "Native continuation callback changed exact source/controller custody: " + continued_error)
				return false
		if not resumed or not continued.route.acquire(source):
			_busy = false
			_fail(id, "Same-episode continuation could not acquire its actual source")
			return false
		record.route = continued.route
		record.direction = continued.direction
		record.route_revision = int(record.route_revision) + 1
		record.route_started_age_s = record.age_s
		record.phase = "retreat"
		record.phase_age_s = 0.0
		record.progress = 0.0
		_busy = false
		return true
	if record.phase == "failed":
		return true
	if record.route != null:
		var elapsed: float = float(record.phase_age_s) if record.phase == "retreat" else float(record.route.state().elapsed_s)
		var moved: Dictionary = record.route.advance(source, elapsed)
		if moved.has("error"):
			_fail(id, "Committed retreat lost proof: " + String(moved.error))
			return true
		if record.phase == "retreat":
			record.progress = minf(1.0, float(moved.elapsed_s) / maxf(EPSILON, float(moved.duration_s)))
			if moved.finished:
				if not _outside(source.global_position, float(response.support_radius), false):
					_fail(id, "Real shortened endpoint remains inside a registered field")
					return true
				_set_phase(source, record, "hold")
	if record.phase == "recoil":
		record.progress = minf(1.0, float(record.phase_age_s) / float(_definition.parameters.recoil_s))
		if float(record.phase_age_s) >= float(_definition.parameters.recoil_s):
			_set_phase(source, record, "turn")
	elif record.phase == "turn":
		record.progress = minf(1.0, float(record.phase_age_s) / float(_definition.parameters.turn_s))
		if float(record.phase_age_s) >= float(_definition.parameters.turn_s):
			_set_phase(source, record, "retreat")
			record.route_started_age_s = record.age_s
	elif record.phase == "hold" and not still_active:
		_set_phase(source, record, "regroup")
	elif record.phase == "regroup":
		if still_active:
			_set_phase(source, record, "hold")
		elif float(record.phase_age_s) >= float(_definition.parameters.regroup_s):
			_busy = true
			if record.route != null:
				record.route.release(source)
			source.call("finish_spore_episode", self, record.episode_id)
			_records.erase(id)
			_busy = false
			return true
	_busy = true
	source.call("present_spore_phase", self, record.episode_id, record.phase, record.progress)
	_busy = false
	return true


## A source already outside active circles cannot walk back into them. Actual
## damage/airborne motion is never stopped by environmental avoidance. Failed
## initial placement leaves the old controller untouched and rejects acceptance.
func allows_source_step(source: CharacterBody3D, start: Vector3, motion: Vector3) -> bool:
	var response: Dictionary = _response_for(source)
	if response.is_empty(): return false
	if _failures.has(_source_id(source)) or response.phase == "interrupted" or float(response.hurt_remaining_s) > 0.0 or absf(motion.y) > EPSILON:
		return true
	var domains: Array = _active_domains()
	for domain: Dictionary in domains:
		var radius: float = float(domain.radius) + float(response.support_radius)
		var origin: Vector3 = domain.origin
		if Vector2(start.x - origin.x, start.z - origin.z).length() <= radius:
			continue
		if not _circle_interval(start, start + motion, origin, radius).is_empty():
			return false
	return true


## Called after actual damage has already changed HP/velocity/hurt, including
## inside the actor transaction. Release never overwrites an external impulse.
func source_interrupted(source: CharacterBody3D, reason: String) -> void:
	var id: String = _source_id(source)
	if not _records.has(id):
		return
	var record: Dictionary = _records[id]
	if record.route != null:
		record.route.release(source)
	record.route = null
	record.phase = "interrupted"
	record.phase_age_s = 0.0
	record.progress = 0.0
	if reason == "actual_death":
		_records.erase(id)


func _on_activated(_domain: Dictionary) -> void:
	if _busy or _validating or _bindings.is_empty():
		return
	for id: String in _bindings.sources:
		if not is_instance_valid(_bindings.sources[id]):
			continue
		var source: CharacterBody3D = _bindings.sources[id] as CharacterBody3D
		if not source.is_queued_for_deletion():
			step_source(source, 0.0)


func _set_phase(source: CharacterBody3D, record: Dictionary, phase: String) -> void:
	record.phase = phase
	record.phase_age_s = 0.0
	record.progress = 0.0
	_busy = true
	source.call("present_spore_phase", self, record.episode_id, phase, 0.0)
	_busy = false


func _prepare(source: CharacterBody3D, response: Dictionary, domains: Array, members: Array) -> Dictionary:
	var reasons: Array[String] = []
	for encoded: Array in _definition.directions:
		var direction: Vector3 = Codec.read_vector3(encoded)
		var outward: bool = true
		for domain: Dictionary in domains:
			if not members.has(domain.field_id):
				continue
			var offset: Vector3 = response.position - domain.origin
			if Vector2(offset.x, offset.z).length() <= float(domain.radius) + float(response.support_radius) and Vector3(offset.x, 0, offset.z).dot(direction) < -EPSILON:
				outward = false
		if not outward:
			continue
		var route := Route.new()
		var distance: float = _outside_distance(response.position, direction, float(response.support_radius))
		if distance <= 0.0 or distance > float(_definition.parameters.max_distance):
			reasons.append("Registered field union exceeds the bounded retreat distance")
			continue
		var planned: Dictionary = route.plan(source, {"direction": direction, "speed": _definition.parameters.speed, "distance": distance, "body_collision_path": response.body_collision_path}, _route_bindings())
		if planned.has("error"):
			reasons.append(planned.error)
			continue
		if not _outside(planned.planned_endpoint, float(response.support_radius), false) or not _prefix_union(response.position, planned.planned_endpoint, float(response.support_radius), domains):
			reasons.append("Landing/route does not leave the whole registered field union without reentry")
			continue
		return {"route": route, "direction": direction, "endpoint": planned.planned_endpoint}
	return {"error": "No authored grounded outward route reaches an outside endpoint: " + (reasons[0] if not reasons.is_empty() else "all candidates point inward")}


func _outside_distance(start: Vector3, direction: Vector3, radius: float) -> float:
	var maximum: float = float(_definition.parameters.max_distance)
	var intervals: Array = []
	for domain: Dictionary in _registered_domains():
		intervals.append_array(_circle_interval(start, start + direction * maximum, domain.origin, float(domain.radius) + radius + float(_definition.parameters.exit_clearance)))
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var reached: float = 0.0
	for interval: Vector2 in intervals:
		if interval.x > reached + EPSILON:
			break
		reached = maxf(reached, interval.y)
	return maximum * reached + 0.02


func _continue(source: CharacterBody3D, response: Dictionary, record: Dictionary) -> Dictionary:
	var difference: Vector3 = record.original_endpoint - response.position
	if absf(difference.y) > Route.FEET_TOLERANCE or difference.length() <= EPSILON or difference.length() > Route.MAX_DISTANCE:
		return {"error": "Damage displaced source beyond its original supported outside endpoint"}
	difference.y = 0.0
	var direction: Vector3 = difference.normalized()
	var route := Route.new()
	var planned: Dictionary = route.plan(source, {"direction": direction, "speed": _definition.parameters.speed, "distance": difference.length(), "body_collision_path": response.body_collision_path}, _route_bindings())
	if planned.has("error") or planned.get("planned_endpoint", Vector3.INF).distance_to(record.original_endpoint) > Route.ENDPOINT_TOLERANCE or not _outside(record.original_endpoint, float(response.support_radius), false) or not _prefix_union(response.position, record.original_endpoint, float(response.support_radius), _active_domains()):
		return {"error": "Same-episode damage continuation cannot reach its original outside landing: " + String(planned.get("error", "blocked endpoint/field reentry"))}
	return {"route": route, "direction": direction}


func _outside(position: Vector3, support_radius: float, active_only: bool) -> bool:
	var domains: Array = _active_domains() if active_only else _registered_domains()
	for domain: Dictionary in domains:
		var origin: Vector3 = domain.origin
		if Vector2(position.x - origin.x, position.z - origin.z).length() <= float(domain.radius) + support_radius + float(_definition.parameters.exit_clearance):
			return false
	return true


func _component_at(position: Vector3, support_radius: float, domains: Array) -> Array:
	var members: Array = []
	for domain: Dictionary in domains:
		var origin: Vector3 = domain.origin
		if Vector2(position.x - origin.x, position.z - origin.z).length() <= float(domain.radius) + support_radius:
			members.append(domain.field_id)
	_expand_component(members, domains, support_radius)
	return members


func _expand_component(members: Array, domains: Array, support_radius: float) -> void:
	var changed: bool = true
	while changed:
		changed = false
		for candidate: Dictionary in domains:
			if members.has(candidate.field_id):
				continue
			for existing: Dictionary in domains:
				if members.has(existing.field_id) and (candidate.origin as Vector3).distance_to(existing.origin) <= float(candidate.radius) + float(existing.radius) + support_radius * 2.0:
					members.append(candidate.field_id)
					changed = true
					break
	members.sort()


func _merge_members(record: Dictionary, domains: Array, support_radius: float) -> void:
	# Only a still-active generation can bridge to a new generation. An expired
	# circle cannot manufacture a permanent global immunity component.
	if _members_active(record.members, domains):
		_expand_component(record.members, domains, support_radius)


func _members_active(members: Array, domains: Array) -> bool:
	for domain: Dictionary in domains:
		if members.has(domain.field_id):
			return true
	return false


func _prefix_union(start: Vector3, finish: Vector3, radius: float, domains: Array) -> bool:
	var intervals: Array = []
	for domain: Dictionary in domains:
		intervals.append_array(_circle_interval(start, finish, domain.origin, float(domain.radius) + radius))
	if intervals.is_empty():
		return true
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var reached: float = 0.0
	for interval: Vector2 in intervals:
		if interval.x > reached + EPSILON:
			return false
		reached = maxf(reached, interval.y)
	return true


static func _circle_interval(start: Vector3, finish: Vector3, origin: Vector3, radius: float) -> Array:
	var a := Vector2(start.x - origin.x, start.z - origin.z)
	var v := Vector2(finish.x - start.x, finish.z - start.z)
	var q: float = v.length_squared()
	if q <= EPSILON * EPSILON:
		return [Vector2(0, 1)] if a.length() <= radius else []
	var b: float = 2.0 * a.dot(v)
	var c: float = a.length_squared() - radius * radius
	var discriminant: float = b * b - 4.0 * q * c
	if discriminant < 0.0:
		return []
	var lower: float = maxf(0.0, (-b - sqrt(discriminant)) / (2.0 * q))
	var upper: float = minf(1.0, (-b + sqrt(discriminant)) / (2.0 * q))
	return [Vector2(lower, upper)] if lower <= upper else []


func _active_domains() -> Array:
	var domains: Array = []
	for id: String in _bindings.get("fields", {}):
		if not is_instance_valid(_bindings.fields[id]):
			continue
		var field: Node = _bindings.fields[id]
		if not field.is_queued_for_deletion():
			var domain: Dictionary = field.call("active_domain")
			if not domain.is_empty():
				domains.append(domain)
	return domains


func _registered_domains() -> Array:
	var domains: Array = []
	for id: String in _geometry:
		domains.append({"instance_id": id, "origin": Codec.read_vector3(_geometry[id].origin), "radius": _geometry[id].radius})
	return domains


func _domain_error(source: CharacterBody3D, bindings: Dictionary, geometry_bindings: Dictionary) -> String:
	var environment: Dictionary = Route.binding_state(source, bindings)
	if environment.has("error"):
		return environment.error
	var response: Dictionary = _response_for(source, bindings)
	if response.is_empty():
		return "Retained source response unavailable during domain preflight"
	if float(response.support_radius) <= 0.0 or float(response.height) <= 0.0:
		return "Supported measured native response required"
	for id: String in geometry_bindings:
		var geometry: Dictionary = geometry_bindings[id]
		var origin: Vector3 = Codec.read_vector3(geometry.origin)
		var radius: float = float(geometry.radius) + float(response.support_radius) + float(_definition.parameters.exit_clearance)
		var supported: bool = false
		var excluded: Array[RID] = [source.get_rid()]
		for floor_id: String in bindings.floors:
			var floor_spec: Dictionary = bindings.floors[floor_id]
			var collision: CollisionShape3D = floor_spec.collision
			var top: float = collision.global_position.y + (collision.shape as BoxShape3D).size.y * 0.5
			var safe: Rect2 = (floor_spec.safe_rect as Rect2).grow(-radius)
			if safe.has_point(Vector2(origin.x, origin.z)) and absf(origin.y - top) <= Route.FEET_TOLERANCE:
				supported = true
			excluded.append(collision.get_parent().get_rid())
		if not supported:
			return "Full expanded spore circle must fit one authored supported floor rectangle"
		var volume := CylinderShape3D.new()
		volume.radius = radius
		volume.height = float(response.height)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = volume
		query.transform = Transform3D(Basis.IDENTITY, origin + Vector3.UP * float(response.height) * 0.5)
		query.collision_mask = 1
		query.exclude = excluded
		query.collide_with_areas = false
		if not source.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return "Full-circle spore propagation across/through scenery is unsupported; wall-separated placement rejected"
	return ""


func _binding_error() -> String:
	if _bindings.is_empty():
		return "Spore coordinator is unbound"
	for id: String in _bindings.fields:
		if not is_instance_valid(_bindings.fields[id]):
			return "Registered immutable spore field disappeared"
		var field: Node3D = _bindings.fields[id]
		if field.is_queued_for_deletion() or not field.is_inside_tree() or not _copied_same(field.call("get_cue_state").get("geometry"), _geometry[id]):
			return "Registered immutable spore field disappeared or changed"
		var diagnostic: String = field.call("binding_error")
		if not diagnostic.is_empty():
			return diagnostic
		var field_state: Dictionary = field.call("state")
		if field_state.phase in ["releasing", "active", "thinning"] and field.call("active_domain").is_empty():
			return "Active field lost its required cluster/cue bindings"
	for id: String in _bindings.sources:
		if not is_instance_valid(_bindings.sources[id]):
			continue
		var source: CharacterBody3D = _bindings.sources[id] as CharacterBody3D
		if source.is_queued_for_deletion():
			continue # Actual deaths are externally owned; no clone/regrant.
		if not _under(source, _bindings.world_root) or source.get_world_3d() != get_world_3d():
			return "Source changed its bound world"
		if _source_protocols.has(id):
			var error: String = _source_protocols[id].binding_error()
			if not error.is_empty(): return error
	return ""


func _route_bindings() -> Dictionary:
	return {"world_root": _bindings.world_root, "floors": _bindings.floors}


func _source_id(source: Node) -> String:
	for id: String in _bindings.get("sources", {}):
		if _bindings.sources[id] == source:
			return id
	return ""


func _cleanup(id: String, source: CharacterBody3D) -> void:
	if _records.has(id) and _records[id].route != null:
		_records[id].route.release(source)
	_records.erase(id)


func _fail(id: String, reason: String) -> void:
	if _failures.has(id):
		return
	_failures[id] = reason
	if _records.has(id):
		var record: Dictionary = _records[id]
		if record.route != null:
			record.route.release(_bindings.sources[id])
			record.route = null
		if record.phase != "interrupted":
			record.phase = "failed"
			record.progress = 0.0
			if not _source_protocols.has(id) or (is_instance_valid(_bindings.sources[id]) and not _bindings.sources[id].is_queued_for_deletion()):
				_bindings.sources[id].call("present_spore_phase", self, record.episode_id, "failed", 0.0)
	_busy = true
	_refresh_failure_markers()
	placement_rejected.emit(id, reason)
	_busy = false
	last_error = reason


## Restrained explicit placement failure feedback, not a danger/damage field.
## This shared prototype text is required state feedback; act artwork/portrait
## readability remain authored validation obligations.
func _refresh_failure_markers() -> void:
	for id: String in _failure_markers:
		if is_instance_valid(_failure_markers[id]):
			_failure_markers[id].free()
	_failure_markers.clear()
	for id: String in _failures:
		if not is_instance_valid(_bindings.sources.get(id)):
			continue
		var source: Node3D = _bindings.sources[id]
		var marker := Label3D.new()
		marker.name = "Blocked_" + id.replace("/", "_").replace(".", "_").replace(":", "_")
		marker.text = "RETREAT BLOCKED"
		marker.font_size = 24
		marker.pixel_size = 0.005
		marker.modulate = Color(1.0, 0.86, 0.52)
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.no_depth_test = true
		add_child(marker)
		marker.global_position = source.global_position + Vector3.UP * 1.9
		_failure_markers[id] = marker


static func _id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	var regex := RegEx.new()
	regex.compile("^[A-Za-z0-9][A-Za-z0-9_./:-]*$")
	var found: RegExMatch = regex.search(value)
	return found != null and found.get_string() == value


static func _under(node: Node, world_root: Node) -> bool:
	return is_instance_valid(world_root) and (node == world_root or world_root.is_ancestor_of(node))


func _reject(error: String) -> bool:
	last_error = error
	return false


## External level captures fields/actors first at the same paused deferred
## boundary. Context={fields:{id:field_snapshot},sources:{id:actor_snapshot}}.
## These external units stay authoritative; only immutable reference stamps
## and this controller's episode/route timing are serialized here.
func snapshot_state(context: Dictionary) -> Dictionary:
	last_error = _snapshot_boundary_error()
	if not last_error.is_empty():
		return {}
	var records: Dictionary = {}
	for id: String in _records:
		var record: Dictionary = _records[id].duplicate(true)
		record.direction = Codec.vector3(record.direction)
		record.original_endpoint = Codec.vector3(record.original_endpoint)
		if record.route != null:
			record.route = record.route.snapshot_state(_bindings.sources[id])
			if record.route.is_empty():
				last_error = "Actual source route is unavailable at snapshot boundary"
				return {}
		records[id] = record
	var fields: Dictionary = {}
	for id: String in _bindings.fields:
		if not context.get("fields", {}).get(id) is Dictionary:
			last_error = "Already captured external field units required"
			return {}
		fields[id] = _field_stamp(context.fields[id])
	var value: Dictionary = {"api_revision": API_REVISION, "schema_version": 1, "definition": _definition.duplicate(true), "field_geometry": _geometry.duplicate(true), "source_environments": _environments.duplicate(true), "field_references": fields, "serial": _serial, "records": records, "failures": _failures.duplicate(true)}
	if not _source_protocols.is_empty():
		last_error = _native_context_error(context)
		if not last_error.is_empty(): return {}
		value.schema_version = 2
		value["source_protocols"] = _native_references(context)
	last_error = snapshot_error(value, context)
	return value.duplicate(true) if last_error.is_empty() else {}


## All external units and saved actor motions are proved before mutation.
## Rejected context never restores fields, moves actors, cancels attacks or
## emits events. A level must validate its entire aggregate before committing
## fields -> actors -> coordinator. Do not use activation/plan/acquire on retry.
func snapshot_error(snapshot: Dictionary, context: Dictionary) -> String:
	# Closed bounded native data is checked before duplicate(true), including
	# cyclic/foreign object inputs. Historical Ash schema1 keeps its contract.
	if not _source_protocols.is_empty() and (Exact.stringify(snapshot).is_empty() or Exact.stringify(context).is_empty()):
		return "Bounded closed native paired transport required before copying"
	var error: String = _snapshot_boundary_error()
	if not error.is_empty():
		return error
	_validating = true
	error = _validate_snapshot(snapshot.duplicate(true), context.duplicate(true))
	_validating = false
	return error


## Actual external fields/actors must already equal the validated staged units.
## All route instances are restored into local temporaries before assignment;
## no existing controller/lease is released or advanced on a failed commit.
func restore_state(snapshot: Dictionary, context: Dictionary) -> bool:
	last_error = snapshot_error(snapshot, context)
	if not last_error.is_empty():
		return false
	for id: String in _bindings.fields:
		if not _copied_same(_bindings.fields[id].call("snapshot_state"), context.fields[id]):
			return _reject("Actual field unit differs from the staged paired commit")
	for id: String in _bindings.sources:
		var common: Dictionary = _common_saved_source(id, context)
		if common.is_empty(): return _reject("Full owned source decoder rejected the paired commit")
		if not is_instance_valid(_bindings.sources[id]):
			if common.lifecycle.dead: continue
			return _reject("Missing live actor cannot commit a paired unit")
		var source: Node = _bindings.sources[id]
		var actual: Dictionary = _source_protocols[id].current_unit(_native_pair(context)) if _source_protocols.has(id) else source.call("snapshot_state")
		if actual.is_empty() or not _copied_same(actual, context.sources[id]):
			return _reject("Actual complete source unit differs from the staged paired commit")
	var staged: Dictionary = {}
	for id: String in snapshot.records:
		var record: Dictionary = snapshot.records[id].duplicate(true)
		record.direction = Codec.read_vector3(record.direction)
		record.original_endpoint = Codec.read_vector3(record.original_endpoint)
		if record.route != null:
			var route := Route.new()
			if not route.restore_state(record.route, _bindings.sources[id], _route_bindings()):
				return _reject("Actual route commit rejected: " + route.last_error)
			record.route = route
		staged[id] = record
	_busy = true
	_records = staged
	_failures = snapshot.failures.duplicate(true)
	_serial = int(snapshot.serial)
	_refresh_failure_markers()
	_busy = false
	last_error = ""
	return true


func _validate_snapshot(value: Dictionary, context: Dictionary) -> String:
	var native: bool = not _source_protocols.is_empty()
	var expected_keys: Array = ["api_revision", "schema_version", "definition", "field_geometry", "source_environments", "field_references", "serial", "records", "failures"]
	if native: expected_keys.append("source_protocols")
	var error: String = Codec.value_error(value)
	if not error.is_empty() or not Codec.keys_error(value, expected_keys).is_empty():
		return "Invalid spore snapshot transport/envelope: " + error
	if value.api_revision != API_REVISION or not (value.schema_version is int and value.schema_version == 2 if native else Codec.is_integer(value.schema_version, 1, 1)) or not _copied_same(value.definition, _definition) or not _copied_same(value.field_geometry, _geometry) or not _copied_same(value.source_environments, _environments) or not Codec.is_integer(value.serial, 0, 1000000000):
		return "Spore immutable definition/body/floor/world identity changed"
	if native:
		error = _native_context_error(context)
		if not error.is_empty() or not _copied_same(value.source_protocols, _native_references(context)):
			return "Native full actor/controller/player reference disagrees with external pair: " + error
	if not Codec.keys_error(context, ["fields", "sources", "controllers", "players"] if native else ["fields", "sources"]).is_empty() or not context.fields is Dictionary or not context.sources is Dictionary or not Codec.keys_error(context.fields, _bindings.fields.keys()).is_empty() or not Codec.keys_error(context.sources, _bindings.sources.keys()).is_empty() or not value.field_references is Dictionary or not Codec.keys_error(value.field_references, _bindings.fields.keys()).is_empty() or not value.records is Dictionary or not value.failures is Dictionary:
		return "Complete already validated external source/field context required"
	var saved_domains: Array = []
	var episodes_seen: Dictionary = {}
	for id: String in _bindings.fields:
		if not context.fields[id] is Dictionary:
			return "External field envelope required"
		error = _bindings.fields[id].call("snapshot_error", context.fields[id])
		if not error.is_empty() or not _copied_same(value.field_references[id], _field_stamp(context.fields[id])):
			return "Field generation/clock/deadline reference disagrees with authoritative field unit: " + error
		var field: Dictionary = context.fields[id]
		if int(field.generation) > 0 and float(field.clock_s) < float(field.deadline_s):
			saved_domains.append({"field_id": "%s/field-%d" % [id, int(field.generation)], "origin": Codec.read_vector3(field.geometry.origin), "radius": field.geometry.radius})
	for id: String in _bindings.sources:
		if not context.sources[id] is Dictionary:
			return "Already captured actual source/defeat envelopes required"
		var actor: Dictionary = _common_saved_source(id, context)
		if actor.is_empty():
			return "Paired complete owned actor envelope rejected"
		var source: CharacterBody3D = _bindings.sources[id] as CharacterBody3D if is_instance_valid(_bindings.sources[id]) else null
		if source == null:
			if not actor.lifecycle.dead or value.records.has(id):
				return "Missing live source requires ready replacement; no resource clone is manufactured"
		else:
			var response: Dictionary = _response_for(source)
			if response.is_empty() or not response.outside_transaction:
				return "Paired actor context requires a retained response outside actor transactions"

		if not _copied_same(actor.motion.basis, [Codec.vector3(Vector3.RIGHT), Codec.vector3(Vector3.UP), Codec.vector3(Vector3.BACK)] if native else [[1, 0, 0], [0, 1, 0], [0, 0, 1]]):
			return "Spore sources retain their actual unscaled upright collision basis"
		# Validate actual body/static floor signatures using a virtual supported
		# feet height, not fresh/live hero/source pose or airborne hurt velocity.
		var geometry: Dictionary = _geometry[_geometry.keys()[0]]
		var reference_position := Vector3(float(actor.motion.position[0]), float(geometry.origin[1]) - float(_environments[id].foot_offset), float(actor.motion.position[2]))
		var actual_static: Dictionary = Route.static_environment_state(_bindings.world_root, _bindings.floors, _environments[id], reference_position)
		if actual_static.has("error") or not _copied_same(actual_static.get("world_signature"), _environments[id].world_signature) or not _copied_same(actual_static.get("floor_signature"), _environments[id].floor_signature):
			return "Bound actual static collision or floor assumptions changed"
		if not actor.lifecycle.dead:
			var measured: Dictionary = Route.binding_state(source, _route_bindings(), reference_position)
			if measured.has("error") or not _copied_same(measured, _environments[id]):
				return "Bound actual living source body assumptions changed"
		if not value.records.has(id):
			if not actor.lifecycle.dead and actor.repulsion.phase != "none":
				return "Actor carries a spore episode absent from its external coordinator"
			continue
		var record: Variant = value.records[id]
		if not record is Dictionary or not Codec.keys_error(record, ["episode_id", "phase", "age_s", "phase_age_s", "members", "direction", "progress", "original_endpoint", "route_revision", "route_started_age_s", "route"]).is_empty():
			return "Invalid source episode/route envelope"
		if not _id(record.episode_id) or not record.episode_id.begins_with(consumer_id() + "/episode-") or not record.phase is String or not ["recoil", "turn", "retreat", "hold", "regroup", "interrupted", "failed"].has(record.phase) or not Codec.in_range(record.age_s, 0.0, MAX_CLOCK) or not Codec.in_range(record.phase_age_s, 0.0, float(record.age_s)) or not Codec.in_range(record.route_started_age_s, 0.0, float(record.age_s)) or not Codec.is_integer(record.route_revision, 1, 1000000000) or not Codec.in_range(record.progress, 0.0, 1.0) or not Codec.is_vector3(record.direction) or not Codec.is_vector3(record.original_endpoint) or not record.members is Array or record.members.is_empty() or record.members.size() > 32:
			return "Invalid finite source episode timing/identity/members"
		var serial_text: String = record.episode_id.trim_prefix(consumer_id() + "/episode-")
		if not serial_text.is_valid_int() or int(serial_text) <= 0 or int(serial_text) > int(value.serial) or serial_text != str(int(serial_text)):
			return "Episode identity exceeds its committed serial"
		var direction: Vector3 = Codec.read_vector3(record.direction)
		if absf(direction.y) > EPSILON or absf(direction.length() - 1.0) > EPSILON:
			return "Episode direction must be normalized and planar"
		var stamp: Dictionary = actor.repulsion
		if stamp.episode_id != record.episode_id or stamp.phase != record.phase or not _copied_same(stamp.direction, record.direction) or not _copied_same(stamp.progress, record.progress) or actor.lifecycle.dead:
			return "Episode pose/lifecycle disagrees with authoritative actor stamp"
		if episodes_seen.has(record.episode_id):
			return "Source episode identities must be globally unique within this coordinator"
		episodes_seen[record.episode_id] = true
		var seen: Dictionary = {}
		for member: Variant in record.members:
			var valid_member: bool = false
			for field_id: String in context.fields:
				for generation: int in range(1, int(context.fields[field_id].generation) + 1):
					if member == "%s/field-%d" % [field_id, generation]:
						valid_member = true
			if not valid_member or seen.has(member):
				return "Episode member is duplicated or references an unspent field generation"
			seen[member] = true
		if not _outside(Codec.read_vector3(record.original_endpoint), float(_environments[id].support_radius), false):
			return "Original episode endpoint remains inside a registered field footprint"
		var proof_members: Array = []
		for member: String in record.members:
			for field_id: String in _geometry:
				if member == field_id + "/field-1" or member == field_id + "/field-2":
					proof_members.append({"field_id": member, "origin": Codec.read_vector3(_geometry[field_id].origin), "radius": _geometry[field_id].radius})
		var connected: Array = [record.members[0]]
		_expand_component(connected, proof_members, float(_environments[id].support_radius))
		if connected.size() != record.members.size():
			return "Latched generations cannot manufacture immunity across disconnected field components"
		if record.phase in ["recoil", "turn"]:
			var duration: float = float(_definition.parameters.recoil_s if record.phase == "recoil" else _definition.parameters.turn_s)
			if float(record.phase_age_s) >= duration or not Codec.same_values(record.progress, float(record.phase_age_s) / duration) or int(record.route_revision) != 1:
				return "Recoil/turn pose must match its exact unreset original simulation timer"
		elif record.phase in ["hold", "regroup", "interrupted", "failed"] and float(record.progress) != 0.0:
			return "Stopped/interrupted episode cannot claim movement or recoil progress"
		if record.phase == "regroup" and _members_active(record.members, saved_domains):
			return "Saved regroup cannot abandon a still-active latched field component"
		if record.phase == "failed" and not value.failures.has(id):
			return "Failed episode must preserve its visible placement rejection"
		if record.route == null:
			if not ["interrupted", "failed", "hold", "regroup"].has(record.phase):
				return "Moving/recoil episode requires its exact actual-body lease"
		else:
			if not record.route is Dictionary or not record.route.get("route", {}).get("leased", false):
				return "Episode route must preserve its committed measured-body lease"
			var route := Route.new()
			var staged_motion: Dictionary = {"position": Codec.read_vector3(actor.motion.position), "velocity": Codec.read_vector3(actor.motion.velocity)}
			error = route.snapshot_error(record.route, source, _route_bindings(), staged_motion)
			if not error.is_empty() or Codec.read_vector3(record.route.route.planned_endpoint).distance_to(Codec.read_vector3(record.original_endpoint)) > Route.ENDPOINT_TOLERANCE or not _copied_same(record.route.route.direction, record.direction):
				return "Paired exact retreat route rejected: " + error
			if record.phase in ["recoil", "turn"] and (float(record.route.route.elapsed_s) != 0.0 or record.route.route.finished):
				return "Source cannot execute retreat during recoil/turn"
			if record.phase in ["hold", "regroup"] and not record.route.route.finished:
				return "Held source must have completed its exact measured retreat"
			if record.phase == "retreat" and not Codec.same_values(record.progress, minf(1.0, float(record.route.route.elapsed_s) / float(record.route.route.duration_s))):
				return "Retreat feedback must match exact committed route progress"
			if record.phase == "retreat" and (not _copied_same(record.route.route.elapsed_s, record.phase_age_s) or not Codec.same_values(float(record.age_s) - float(record.route_started_age_s), record.phase_age_s)):
				return "Retreat elapsed/remaining time must match its explicit route revision boundary"
		if ["hold", "regroup"].has(record.phase):
			# Current live fields can be fresh; use saved field domain instead.
			for domain: Dictionary in saved_domains:
				if _circle_interval(Codec.read_vector3(actor.motion.position), Codec.read_vector3(actor.motion.position), domain.origin, float(domain.radius) + float(_environments[id].support_radius)).size() > 0:
					return "Saved hold/regroup source remains inside an active saved field"
	for id: Variant in value.records:
		if not _bindings.sources.has(id):
			return "Unknown source record"
	for id: Variant in value.failures:
		if not _bindings.sources.has(id) or not value.failures[id] is String or value.failures[id].is_empty():
			return "Invalid placement failure identity/reason"
	return ""


func _snapshot_boundary_error() -> String:
	if _busy or _validating or not is_inside_tree() or not get_tree().paused:
		return "Spore snapshots require the paused deferred coordinator boundary outside callbacks"
	return _binding_error()


static func _field_stamp(field: Dictionary) -> Dictionary:
	return {"geometry": field.get("geometry"), "generation": field.get("generation"), "clock_s": field.get("clock_s"), "activation_s": field.get("activation_s"), "deadline_s": field.get("deadline_s"), "phase": field.get("phase")}


func _native_boundary_state(source_id: String) -> Dictionary:
	var protocol: CinderSchedulerSporeSourceProtocol = _source_protocols[source_id]
	var control: Dictionary = protocol.control_state()
	var response: Dictionary = protocol.response_state()
	var profile: Dictionary = protocol.profile_state()
	if control.is_empty() or response.is_empty() or (profile.is_empty() and not control.encounter_id.is_empty()) or not protocol.binding_error().is_empty():
		return {}
	return {"control": control, "response": response, "profile": profile, "binding": protocol.binding_state()}


func _native_boundary_error(before: Dictionary, after: Dictionary) -> String:
	if before.is_empty() or after.is_empty():
		return "Retained native boundary unavailable"
	if not before.control.outside_transaction or not after.control.outside_transaction or not before.response.outside_transaction or not after.response.outside_transaction:
		return "Native callback remained inside a source/controller transaction"
	for key: String in ["source_instance_id", "encounter_id", "world_revision", "clock_s", "cooldown"]:
		if not _copied_same(before.control[key], after.control[key]):
			return "Original Scheduler custody changed: " + key
	if not _copied_same(before.profile, after.profile) or not _copied_same(before.binding, after.binding):
		return "Original native profile/stable binding changed"
	return ""


func _response_for(source: CharacterBody3D, staged: Dictionary = {}) -> Dictionary:
	var protocols: Dictionary = staged.get("source_protocols", _source_protocols)
	var id: String = _source_id(source) if staged.is_empty() else ""
	if not staged.is_empty():
		for candidate: String in staged.sources:
			if staged.sources[candidate] == source: id = candidate
	if protocols.has(id):
		return protocols[id].response_state()
	return source.call("get_spore_response_state")


func _copied_same(left: Variant, right: Variant) -> bool:
	if _source_protocols.is_empty(): return Codec.same_values(left, right)
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


func _native_pair(context: Dictionary) -> Dictionary:
	return {"controllers": context.controllers, "players": context.players}


func _native_context_error(context: Dictionary) -> String:
	if Exact.stringify(context).is_empty() or not Codec.keys_error(context, ["fields", "sources", "controllers", "players"]).is_empty():
		return "Closed complete native context required"
	for key: String in ["fields", "sources", "controllers", "players"]:
		if not context[key] is Dictionary: return "Native context maps required"
	var controllers: Dictionary = {}
	var players: Dictionary = {}
	for id: String in _source_protocols:
		var descriptor: Dictionary = _source_protocols[id].binding_state()
		controllers[descriptor.controller_id] = true
		players[descriptor.player_id] = true
		if not context.sources.has(id) or not context.sources[id] is Dictionary or not context.controllers.has(descriptor.controller_id) or not context.players.has(descriptor.player_id): return "Native context lacks an exact opted binding"
		var error: String = _source_protocols[id].unit_error(context.sources[id], _native_pair(context))
		if not error.is_empty(): return error
	if not Codec.keys_error(context.controllers, controllers.keys()).is_empty() or not Codec.keys_error(context.players, players.keys()).is_empty(): return "Native context controller/Player coverage must match unique opted bindings"
	return ""


func _native_references(context: Dictionary) -> Dictionary:
	var refs: Dictionary = {}
	for id: String in _source_protocols:
		var descriptor: Dictionary = _source_protocols[id].binding_state()
		var bytes: String = Exact.stringify(context.sources[id])
		if bytes.is_empty(): return {}
		refs[id] = {"api_revision": descriptor.api_revision, "actor_revision": descriptor.actor_revision, "source_id": id, "controller_id": descriptor.controller_id, "player_id": descriptor.player_id, "configuration_sha256": descriptor.configuration_sha256, "actor_sha256": bytes.sha256_text()}
	return refs


func _common_saved_source(id: String, context: Dictionary) -> Dictionary:
	if _source_protocols.has(id):
		var view: Dictionary = _source_protocols[id].unit_view(context.sources[id], _native_pair(context))
		if view.is_empty(): return {}
		# Internal validated lifecycle/motion/stamp only. Never an Ash envelope,
		# substitute HP authority, or replacement external actor record.
		return {"lifecycle": {"dead": not view.alive}, "motion": view.motion, "repulsion": view.repulsion}
	return context.sources[id] if Enemy.spore_record_error(context.sources[id], consumer_id(), id).is_empty() else {}
