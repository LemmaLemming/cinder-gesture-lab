class_name CinderAct3RootLatcher
extends StaticBody3D
## Living fixed bulb for A3-E2. Each native crescent selects one actual bearing
## before admission. Shared LaneMechanism owns contact paths and damage.

signal died(where: Vector3)
signal state_changed(source_state: Dictionary)

const MechanismScript = preload("res://scripts/combat/lane_mechanism.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const CueMesh = preload("res://scripts/cues/cue_mesh.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const API_REVISION: String = "act3-root-latcher-2"
const HERO_ID: String = "hero"
const ART_PATH: String = "res://scripts/acts/act3/root_latcher_art.gd"
const RAW_ROLE: Dictionary = {"raw_damage": 10.0, "max_hp": 20.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 1.8, "attack_interval_s": 4.0, "move_speed": 0.0}
const TIMING_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.8}
const TUNING: Dictionary = {"capsule_radius": 0.32, "capsule_height": 0.64, "capsule_center_y": 0.32, "inner_radius": 0.55, "outer_radius": 2.0, "min_dot": 0.5, "request_retry_s": 0.25}
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "stable_id", "position", "clock_s", "resolved_role", "hp", "max_hp", "dead", "death_emitted", "retry_at_s", "collision", "mechanism", "framing"]

var hp: float = 20.0
var max_hp: float = 20.0
var dead: bool = false
var last_error: String = ""
var last_snapshot_error: String = ""

var _stable_id: String = ""
var _source_id: String = ""
var _hero: CinderPlayer
var _effects: PixelEffects
var _scheduler: CinderThreatScheduler
var _response_provider: Callable
var _framing_guard: Callable
var _body: CollisionShape3D
var _mechanism: CinderLaneMechanism
var _art: Node3D
var _configured: bool = false
var _fixed_position: Vector3 = Vector3.ZERO
var _role: Dictionary = {}
var _retry_at_s: float = 0.0
var _death_emitted: bool = false
var _transaction_depth: int = 0
var _last_rejection: String = ""
var _framing_error: String = ""
var _proof: Dictionary = {}
var _framing: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# Guard the current physical frame before the shared mechanism at 100.
	process_physics_priority = 90
	collision_layer = 2
	collision_mask = 1
	_body = CollisionShape3D.new()
	_body.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = float(TUNING.capsule_radius)
	capsule.height = float(TUNING.capsule_height)
	_body.shape = capsule
	_body.position.y = float(TUNING.capsule_center_y)
	add_child(_body)
	_mechanism = MechanismScript.new()
	_mechanism.name = "RootAttack"
	add_child(_mechanism)
	_mechanism.state_changed.connect(_on_mechanism_state)


## Provider supplies the seven public LaneMechanism RESPONSE_KEYS; it may
## include other defensive public observations, which are never authority here.
## Guard(current_view, prospective) receives the exact native preview before
## admission, and {} during a held cycle. Empty String means the view is valid.
func configure(stable_id: String, hero: CinderPlayer, effects: PixelEffects, scheduler: CinderThreatScheduler, response_provider: Callable, framing_guard: Callable = Callable()) -> bool:
	if _configured or not _valid_id(stable_id) or stable_id.length() > 120 or not is_inside_tree() or not is_node_ready() or not is_instance_valid(hero) or not is_instance_valid(scheduler) or not response_provider.is_valid():
		return _reject("Ready fixed source, stable ID and actual shared bindings required")
	if hero.get_world_3d() != get_world_3d() or scheduler.get_world_3d() != get_world_3d() or hero.process_physics_priority >= process_physics_priority or scheduler.process_physics_priority >= process_physics_priority:
		return _reject("Actual hero and scheduler must precede the fixed source guard")
	var resolver := Difficulty.new()
	var role: Dictionary = resolver.resolve_role(RAW_ROLE, String(scheduler.encounter_profile().get("id", "")), TIMING_FLOORS)
	if role.is_empty():
		return _reject(resolver.last_error)
	var source_id: String = stable_id + "/attack"
	# The default +Z bearing is immutable idle configuration only. Every actual
	# cycle supplies its measured nonzero root-to-hero planar bearing explicitly.
	var shape: Dictionary = Geometry.crescent(global_position, Vector3.BACK, float(TUNING.inner_radius), float(TUNING.outer_radius), float(TUNING.min_dot))
	if not _mechanism.configure(source_id, shape, global_position, RAW_ROLE, TIMING_FLOORS) or not _mechanism.bind(scheduler, {HERO_ID: hero}):
		return _reject(_mechanism.last_error)
	_stable_id = stable_id
	_source_id = source_id
	_hero = hero
	_effects = effects
	_scheduler = scheduler
	_response_provider = response_provider
	_framing_guard = framing_guard
	_fixed_position = global_position
	_role = role
	max_hp = float(role.max_hp)
	hp = max_hp
	_configured = true
	_attach_optional_art()
	_set_lifecycle()
	_present()
	last_error = ""
	return true


func get_mechanism() -> CinderLaneMechanism:
	return _mechanism


func get_art() -> Node3D:
	return _art


func scheduler_owners() -> Dictionary:
	return {_source_id: _mechanism} if _configured else {}


func get_selected_geometry() -> Dictionary:
	return (_mechanism.state().geometry as Dictionary).duplicate(true) if _configured and is_instance_valid(_mechanism) else {}


## Historical presentation points, never a fresh mechanical witness or proof
## that later gear/input may follow the original selected response.
func get_selected_response() -> Dictionary:
	return _framing.duplicate(true)


func state() -> Dictionary:
	var mechanism_state: Dictionary = _mechanism.state() if is_instance_valid(_mechanism) else {}
	return {"api_revision": API_REVISION, "stable_id": _stable_id, "source_id": _source_id, "native_crescent": true, "position": global_position, "clock_s": _clock(), "hp": hp, "max_hp": max_hp, "dead": dead, "phase": "defeated" if dead else String(mechanism_state.get("phase", "clear")), "knot_open": _recovery_open(), "resolved_role": _role.duplicate(true), "mechanism": mechanism_state, "geometry": get_selected_geometry(), "framing": get_selected_response(), "retry_at_s": _retry_at_s, "framing_error": _framing_error, "last_rejection": _last_rejection, "proof": _proof.duplicate(true)}


func _physics_process(_delta: float) -> void:
	if not _configured or dead or get_tree().paused or _transaction_depth > 0:
		return
	_transaction_depth += 1
	if not _bindings_valid() or global_position != _fixed_position or not is_visible_in_tree():
		_mechanism.cancel("fixed_source_unavailable")
		_last_rejection = "Fixed living bulb and stable actual bindings required"
	else:
		var current: Dictionary = _mechanism.state()
		if current.status == "running":
			var record: Dictionary = _scheduler.reservation_state(String(current.reservation_id))
			if not record.is_empty() and record.state in ["lock", "active", "recovery"]:
				_guard_current_view()
		elif not _hero.dead and _clock() >= _retry_at_s:
			_try_start()
	_present()
	_transaction_depth -= 1


func _try_start() -> void:
	_retry_at_s = _clock() + float(TUNING.request_retry_s)
	_framing_error = ""
	var supplied: Variant = _response_provider.call()
	if not supplied is Dictionary:
		_last_rejection = "Actual finite response context required"
		return
	var context: Dictionary = {}
	for key: String in MechanismScript.RESPONSE_KEYS:
		if not supplied.has(key):
			_last_rejection = "Missing actual response context: " + key
			return
		context[key] = supplied[key]
	var bearing: Vector3 = _hero.global_position - global_position
	bearing.y = 0.0
	# Null/default and zero (including signed-zero components) never select a
	# live cycle. No hidden fallback direction or tracking warning is authored.
	if not bearing.is_finite() or bearing.length_squared() == 0.0:
		_last_rejection = "Nonzero actual root-to-hero planar bearing required"
		return
	bearing = bearing.normalized()
	var selected: Dictionary = Geometry.crescent(_fixed_position, bearing, float(TUNING.inner_radius), float(TUNING.outer_radius), float(TUNING.min_dot))
	var geometry_error: String = _framing_geometry_error(selected)
	if not geometry_error.is_empty():
		_last_rejection = geometry_error
		return
	var prospective: Dictionary = _mechanism.preview_start(HERO_ID, context, null, bearing)
	if not prospective.get("accepted", false):
		_last_rejection = String(prospective.get("reason", "Stationary preview rejected"))
		return
	var next_framing: Dictionary = _response_framing(prospective.get("proof", {}))
	if next_framing.is_empty():
		_last_rejection = "Selected native stationary proof lacks bounded render points"
		return
	_framing_error = _guard(false, prospective)
	if _framing_error.is_empty():
		# Normal public camera following may settle this future view while clear.
		# Allocate only when the first selected warning also actually fits.
		_framing_error = _guard(true, prospective)
	if not _framing_error.is_empty():
		_last_rejection = "prospective_view_unsafe: " + _framing_error
		return
	var answer: Dictionary = _mechanism.start(HERO_ID, context, null, bearing, prospective)
	_last_rejection = "" if answer.get("accepted", false) else String(answer.get("reason", "Stationary exchange rejected"))
	if answer.get("accepted", false):
		# The common admission freshly checks the entire unchanged preview. Store
		# only its two historical render points; geometry remains in the exchange.
		_framing = next_framing
		_proof = (answer.get("proof", {}) as Dictionary).duplicate(true)


func _guard(current_view: bool, prospective: Dictionary = {}) -> String:
	if not _framing_guard.is_valid():
		return ""
	# A caller can inspect/mutate its defensive copy without changing the native
	# value submitted synchronously to the exact shared admission guard.
	var answer: Variant = _framing_guard.call(current_view, prospective.duplicate(true))
	return answer if answer is String else "Framing guard must return a diagnostic String"


func _guard_current_view() -> void:
	_framing_error = _guard(true)
	if not _framing_error.is_empty():
		_mechanism.cancel("required_view_unsafe: " + _framing_error)


func _on_mechanism_state(mechanism_state: Dictionary) -> void:
	if not _configured or _transaction_depth > 0:
		return
	_transaction_depth += 1
	if not dead and mechanism_state.get("phase") in ["lock", "active", "recovery"]:
		_guard_current_view()
	_present()
	state_changed.emit(state())
	_transaction_depth -= 1


func _recovery_open() -> bool:
	if not _configured or dead or not is_instance_valid(_mechanism) or not is_instance_valid(_scheduler):
		return false
	var current: Dictionary = _mechanism.state()
	if current.get("status") != "running" or current.get("phase") != "recovery":
		return false
	var record: Dictionary = _scheduler.reservation_state(String(current.reservation_id))
	return not record.is_empty() and record.get("state") == "recovery" and _scheduler.get_clock() <= float(record.recovery_until_s)


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var alive_before: bool = _configured and not dead and hp > 0.0 and not is_queued_for_deletion()
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": alive_before}
	if not alive_before or not is_finite(amount) or amount <= 0.0 or not impulse.is_finite() or not _recovery_open():
		return result
	_transaction_depth += 1
	var previous_hp: float = hp
	hp = maxf(0.0, hp - amount)
	result.accepted = true
	result.hp_damage = previous_hp - hp
	# Rooted source deliberately accepts no impulse displacement. A surviving
	# low knot stays open for the remaining actual shared recovery interval.
	if hp <= 0.0:
		dead = true
		_mechanism.cancel("source_defeated")
		_set_lifecycle()
		_present()
		if not _death_emitted:
			_death_emitted = true
			died.emit(global_position)
	state_changed.emit(state())
	_transaction_depth -= 1
	return result


func _set_lifecycle() -> void:
	collision_layer = 0 if dead else 2
	collision_mask = 0 if dead else 1
	if _transaction_depth > 0 and not get_tree().paused:
		_body.set_deferred("disabled", dead)
	else:
		_body.disabled = dead
	# Retain the quiet severed/spent still on the stable defeated node. HP,
	# collision, group and the cleared shared cue remain authoritative.
	visible = true
	if dead:
		remove_from_group("enemies")
	elif not is_in_group("enemies"):
		add_to_group("enemies")


func _attach_optional_art() -> void:
	if is_instance_valid(_art) or not ResourceLoader.exists(ART_PATH):
		return
	var script: GDScript = load(ART_PATH) as GDScript
	if script == null:
		return
	_art = script.new() as Node3D
	if is_instance_valid(_art):
		_art.name = "RootLatcherArt"
		add_child(_art)


func _present(silent: bool = false) -> bool:
	if is_instance_valid(_art) and _art.has_method("present"):
		var blocked: bool = _art.is_blocking_signals()
		if silent:
			_art.set_block_signals(true)
		var accepted: Variant = _art.call("present", "defeated" if dead else String(_mechanism.state().get("phase", "clear")))
		if silent:
			_art.set_block_signals(blocked)
		if accepted != true:
			_framing_error = "Actual Root Latcher art rejected its native phase presentation"
			if not silent:
				_mechanism.cancel("required_art_unavailable")
			return false
	return true


## Complete native body and crescent boundaries, including both arcs and ends.
## Optional geometry is presentation-only prospective native crescent data.
func camera_framing_points(geometry: Dictionary = {}) -> Dictionary:
	if not _configured or not _bindings_valid() or global_position != _fixed_position:
		return {"error": "Ready actual fixed source geometry required", "points": []}
	if dead:
		return {"error": "", "points": []}
	var shape: Dictionary = get_selected_geometry() if geometry.is_empty() else geometry.duplicate(true)
	var geometry_error: String = _framing_geometry_error(shape)
	if not geometry_error.is_empty():
		return {"error": geometry_error, "points": []}
	var points: Array = []
	var r: float = float(TUNING.capsule_radius)
	var half_height: float = float(TUNING.capsule_height) * 0.5
	for x: float in [-r, r]:
		for y: float in [-half_height, half_height]:
			for z: float in [-r, r]:
				points.append(_body.global_transform * Vector3(x, y, z))
	var anchor: Vector3 = CueMesh.anchor(shape)
	for point: Vector3 in CueMesh.boundary(shape):
		points.append(anchor + point + Vector3.UP * 0.029)
	# Include the native stroke/fill extents, not only their logical boundary.
	# These fixed nonbillboard meshes use their real generated local AABBs.
	for filled: bool in [false, true]:
		var footprint: ArrayMesh = CueMesh.geometry_mesh(shape, filled)
		var height: float = CinderThreatCue.FLOOR_OFFSET - (0.004 if filled else 0.0)
		_append_native_box(points, footprint.get_aabb(), anchor + Vector3.UP * height)
	var marker_bounds: AABB = CueMesh.source_mesh("warning").get_aabb()
	for phase: String in ["lock", "active", "recovery"]:
		marker_bounds = marker_bounds.merge(CueMesh.source_mesh(phase).get_aabb())
	_append_native_box(points, marker_bounds, anchor + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004))
	points.append(_fixed_position)
	return {"error": "", "points": points}


func framing_points(shell: Node, geometry: Dictionary = {}) -> Dictionary:
	var result: Dictionary = camera_framing_points(geometry)
	if not String(result.get("error", "")).is_empty() or dead:
		return result
	if not is_instance_valid(_art) or not _art.is_inside_tree() or _art.is_queued_for_deletion() or not _art.is_visible_in_tree() or not _art.has_method("framing_points"):
		return {"error": "Actual native Root Latcher art bounds required", "points": []}
	var native: Variant = _art.call("framing_points", shell)
	if not native is Dictionary or not native.get("error") is String or not native.get("points") is Array:
		return {"error": "Unsupported native Root Latcher art framing response", "points": []}
	if not String(native.error).is_empty() or native.points.is_empty():
		return {"error": String(native.error) if not String(native.error).is_empty() else "Native Root Latcher art bounds are empty", "points": []}
	var combined: Array = result.points.duplicate()
	combined.append_array(native.points)
	if combined.size() > 224:
		return {"error": "Complete fixed source view exceeds shared point budget", "points": []}
	for point: Variant in combined:
		if not point is Vector3 or not point.is_finite():
			return {"error": "Complete fixed source view requires finite native corners", "points": []}
	return {"error": "", "points": combined}


func _append_native_box(points: Array, bounds: AABB, origin: Vector3) -> void:
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(origin + Vector3(x, y, z))


func _framing_geometry_error(shape: Dictionary) -> String:
	var error: String = Geometry.error(shape)
	if not error.is_empty():
		return error
	if shape.get("kind") != "crescent" or shape.origin != _fixed_position or float(shape.inner_radius) != float(TUNING.inner_radius) or float(shape.outer_radius) != float(TUNING.outer_radius) or float(shape.min_dot) != float(TUNING.min_dot):
		return "Framing requires the actual fixed crescent origin, radii and sector"
	return ""


func _response_framing(proof: Variant) -> Dictionary:
	if not proof is Dictionary:
		return {}
	var result: Dictionary = {}
	for key: String in ["landing", "attack_position"]:
		var point: Variant = proof.get(key)
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			return {}
		result[key] = point
	return result


func _encoded_framing() -> Dictionary:
	var result: Dictionary = {}
	for key: String in _framing:
		result[key] = Codec.vector3(_framing[key])
	return result


func _framing_payload_error(snapshot: Dictionary) -> String:
	if not snapshot.framing is Dictionary or not Codec.is_integer(snapshot.mechanism.get("cycle")):
		return "Historical framing requires its closed native cycle join"
	if int(snapshot.mechanism.cycle) == 0:
		return "Unstarted bulb cannot manufacture framing history" if not snapshot.framing.is_empty() else ""
	if not Codec.keys_error(snapshot.framing, ["landing", "attack_position"]).is_empty():
		return "Executed bulb must retain both selected historical render points"
	for key: String in ["landing", "attack_position"]:
		if not Codec.is_vector3(snapshot.framing[key]):
			return "Historical framing requires a canonical vector: " + key
		var point: Vector3 = Codec.read_vector3(snapshot.framing[key])
		if maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			return "Historical framing exceeds the bounded native camera envelope"
	return ""


## Common snapshots retain geometry/opening/deadlines but omit the response
## witness. These exact historical points constrain presentation only. A joint
## finite historical rewrite cannot be authenticated here; never reprove them
## using the current hero/gear or treat them as new mechanical permission.
func _framing_floor_error(frame: Dictionary, bindings: Dictionary) -> String:
	if frame.is_empty():
		return ""
	if not bindings.get("floors") is Dictionary or bindings.floors.is_empty():
		return "Historical framing requires actual immutable floor bindings"
	for key: String in ["landing", "attack_position"]:
		var point: Vector3 = Codec.read_vector3(frame[key])
		var supported: bool = false
		for region: Variant in bindings.floors.values():
			if not region is Dictionary or not region.get("safe_rect") is Rect2:
				return "Historical framing requires supported stable floor rectangles"
			var collision: CollisionShape3D = region.get("collision") as CollisionShape3D
			if not is_instance_valid(collision) or not collision.shape is BoxShape3D:
				return "Historical framing requires an actual stable box floor"
			var top: float = collision.global_position.y + (collision.shape as BoxShape3D).size.y * 0.5
			var rect: Rect2 = (region.safe_rect as Rect2).grow(-(CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN))
			if rect.has_point(Vector2(point.x, point.z)) and absf(point.y - top) <= 0.2:
				supported = true
		if not supported:
			return "Historical framing point lacks its stable supported floor envelope"
	return ""


func _bindings_valid() -> bool:
	return _configured and is_inside_tree() and is_node_ready() and not is_queued_for_deletion() and is_instance_valid(_body) and is_instance_valid(_mechanism) and _mechanism.is_inside_tree() and not _mechanism.is_queued_for_deletion() and is_instance_valid(_hero) and _hero.is_inside_tree() and not _hero.is_queued_for_deletion() and is_instance_valid(_scheduler) and _scheduler.is_inside_tree() and not _scheduler.is_queued_for_deletion() and _hero.get_world_3d() == get_world_3d() and _scheduler.get_world_3d() == get_world_3d() and _hero.process_physics_priority < process_physics_priority and _scheduler.process_physics_priority < process_physics_priority and process_physics_priority < _mechanism.process_physics_priority


func _clock() -> float:
	return _scheduler.get_clock() if is_instance_valid(_scheduler) else 0.0


func _valid_id(value: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var matched: RegExMatch = pattern.search(value)
	return not value.is_empty() and matched != null and matched.get_string() == value


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _snapshot_boundary_error() -> String:
	if not _bindings_valid() or not get_tree().paused or _transaction_depth > 0:
		return "Fixed source snapshots require a deferred paired paused barrier"
	return ""


func snapshot_state(bindings: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_boundary_error()
	if not last_snapshot_error.is_empty():
		return {}
	var mechanism_snapshot: Dictionary = _mechanism.snapshot_state(bindings)
	if mechanism_snapshot.is_empty():
		last_snapshot_error = _mechanism.last_snapshot_error
		return {}
	var result: Dictionary = {"api_revision": API_REVISION, "schema_version": 2, "stable_id": _stable_id, "position": Codec.vector3(global_position), "clock_s": _clock(), "resolved_role": _role.duplicate(true), "hp": hp, "max_hp": max_hp, "dead": dead, "death_emitted": _death_emitted, "retry_at_s": _retry_at_s, "collision": {"enabled": not _body.disabled, "layer": collision_layer, "mask": collision_mask}, "mechanism": mechanism_snapshot, "framing": _encoded_framing()}
	last_snapshot_error = snapshot_error(result, bindings)
	return result.duplicate(true) if last_snapshot_error.is_empty() else {}


## Pure. Caller has independently validated its saved hero and supplies that
## native position as bindings.hero_positions.hero for the common path sample.
func snapshot_error(snapshot: Dictionary, bindings: Dictionary, staged_scheduler: Dictionary = {}) -> String:
	var error: String = _snapshot_boundary_error()
	if not error.is_empty():
		return error
	error = _fields_error(snapshot)
	if not error.is_empty():
		return error
	if not bindings.get("owners") is Dictionary or bindings.owners.get(_source_id) != _mechanism:
		return "Stable attack binding must name the actual shared mechanism child"
	var paired: Dictionary = staged_scheduler if not staged_scheduler.is_empty() else _scheduler.snapshot_state(bindings)
	if paired.is_empty():
		return _scheduler.last_snapshot_error
	if not Codec.is_number(paired.get("clock_s")) or float(snapshot.clock_s) != float(paired.clock_s):
		return "Bulb and shared scheduler clocks differ"
	var profile: Variant = paired.get("profile")
	if not profile is Dictionary or not profile.get("id") is String:
		return "Independent paired scheduler profile required"
	var resolver := Difficulty.new()
	var role: Dictionary = resolver.resolve_role(RAW_ROLE, profile.id, TIMING_FLOORS)
	if role.is_empty() or not _same_exact(snapshot.resolved_role, role):
		return "Bulb HP role must resolve from the paired shared profile"
	error = _mechanism.snapshot_error(snapshot.mechanism, bindings, paired)
	return _framing_floor_error(snapshot.framing, bindings) if error.is_empty() else error


func _fields_error(snapshot: Dictionary) -> String:
	var error: String = Codec.value_error(snapshot)
	if error.is_empty():
		error = Codec.keys_error(snapshot, SNAPSHOT_KEYS)
	if not error.is_empty():
		return error
	if snapshot.api_revision != API_REVISION or not Codec.is_integer(snapshot.schema_version, 2, 2) or snapshot.stable_id != _stable_id or not Codec.is_vector3(snapshot.position) or Codec.read_vector3(snapshot.position) != _fixed_position or not Codec.in_range(snapshot.clock_s, 0.0, 1000000000.0) or not snapshot.resolved_role is Dictionary or not snapshot.resolved_role.get("difficulty_profile") is String or not snapshot.mechanism is Dictionary:
		return "Fixed bulb identity, position, profile and native mechanism required"
	var resolver := Difficulty.new()
	var role: Dictionary = resolver.resolve_role(RAW_ROLE, snapshot.resolved_role.difficulty_profile, TIMING_FLOORS)
	if role.is_empty() or not _same_exact(snapshot.resolved_role, role) or not Codec.is_number(snapshot.max_hp) or float(snapshot.max_hp) != float(role.max_hp) or not Codec.in_range(snapshot.hp, 0.0, float(role.max_hp)) or not snapshot.dead is bool or not snapshot.death_emitted is bool or snapshot.dead != (float(snapshot.hp) == 0.0) or snapshot.death_emitted != snapshot.dead:
		return "Fixed bulb resources/lifecycle differ from its immutable role"
	if not Codec.in_range(snapshot.retry_at_s, 0.0, float(snapshot.clock_s) + float(TUNING.request_retry_s)) or not snapshot.collision is Dictionary or not Codec.keys_error(snapshot.collision, ["enabled", "layer", "mask"]).is_empty() or not snapshot.collision.enabled is bool or not Codec.is_integer(snapshot.collision.layer, 0, 2) or not Codec.is_integer(snapshot.collision.mask, 0, 1):
		return "Malformed fixed bulb retry or collision state"
	if snapshot.collision.enabled != (not snapshot.dead) or int(snapshot.collision.layer) != (0 if snapshot.dead else 2) or int(snapshot.collision.mask) != (0 if snapshot.dead else 1):
		return "Actual bulb collision must match living/dead lifecycle"
	if not Codec.is_number(snapshot.mechanism.get("clock_s")) or float(snapshot.mechanism.clock_s) != float(snapshot.clock_s) or (snapshot.dead and (snapshot.mechanism.get("status") == "running" or snapshot.mechanism.get("phase") != "clear")):
		return "Defeated bulb cannot retain a threat; actor/mechanism clocks must match"
	if float(snapshot.hp) < float(snapshot.max_hp) and not Codec.is_integer(snapshot.mechanism.get("cycle"), 1):
		return "An ordinary knot hit requires a prior actual recovery cycle"
	if snapshot.dead and (snapshot.mechanism.get("status") != "cancelled" or snapshot.mechanism.get("last_cancel_reason") != "source_defeated"):
		return "Defeated bulb must retain its explicit shared source cancellation"
	return _framing_payload_error(snapshot)


## Whole aggregate already prevalidated; apply real bulb flags before the
## scheduler, then call restore_mechanism_state without yielding. No callbacks.
func apply_validated_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = _snapshot_boundary_error()
	if last_snapshot_error.is_empty():
		last_snapshot_error = _fields_error(snapshot)
	if not last_snapshot_error.is_empty():
		return false
	_role = snapshot.resolved_role.duplicate(true)
	hp = float(snapshot.hp)
	max_hp = float(snapshot.max_hp)
	dead = snapshot.dead
	_death_emitted = snapshot.death_emitted
	_retry_at_s = float(snapshot.retry_at_s)
	_framing.clear()
	for key: String in snapshot.framing:
		_framing[key] = Codec.read_vector3(snapshot.framing[key])
	_proof.clear()
	_framing_error = ""
	_last_rejection = ""
	global_position = Codec.read_vector3(snapshot.position)
	_set_lifecycle()
	return true


func restore_mechanism_state(snapshot: Dictionary, bindings: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(snapshot, bindings)
	if not last_snapshot_error.is_empty():
		return false
	if not _mechanism.restore_state(snapshot.mechanism, bindings):
		last_snapshot_error = _mechanism.last_snapshot_error
		return false
	return _present(true)


func restore_state(snapshot: Dictionary, bindings: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(snapshot, bindings)
	if not last_snapshot_error.is_empty():
		return false
	return apply_validated_state(snapshot) and restore_mechanism_state(snapshot, bindings)


func _same_exact(left: Variant, right: Variant) -> bool:
	if Codec.is_number(left) and Codec.is_number(right):
		return float(left) == float(right)
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: String in left:
			if not right.has(key) or not _same_exact(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _same_exact(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right


func _exit_tree() -> void:
	if is_instance_valid(_scheduler) and is_instance_valid(_mechanism):
		_scheduler.cancel_owner(_mechanism, "root_latcher_removed")
