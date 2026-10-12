extends CinderLevel
## TEST ONLY declared native component. No canonical route/death/checkpoint seed.
## Unparsed ignored draft; publication/import/native qualification belong to Root.
const Core = preload("res://scripts/acts/act3/garden_root_network.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Scenery = preload("res://scripts/acts/act3/false_paradise_scenery.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const Root = preload("res://scripts/acts/act3/garden_root_latcher.gd")
const EchoRecipe = preload("res://scripts/acts/act3/mirror_echo_rule_room.gd")
const Sun = preload("res://scripts/acts/act3/garden_sun_art.gd")
const Pair = preload("res://tests/acts/act3/fixtures/garden_mixed_component_codec.gd")
const Model = preload("res://scripts/acts/act3/false_paradise_codec.gd")
const Exact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const CueMeshes = preload("res://scripts/cues/cue_mesh.gd")
const ENCOUNTER: String = "TEST/A3-L4/mixed-native-components"
const FLOOR_ID: String = "test-firm-garden"
const FLOOR_RECT := Rect2(-7, -14, 14, 78)
const ECHO_ID: String = "test-garden-echo"
const ECHO_EPOCH: String = "TEST/A3-L4/mixed-own-sequence"
const HELPER_ID: String = "test-garden-helper"
const HELPER_POSITION := Vector3(-1.5, 0, 2)
@export_enum("root", "echo") var declared_cell: String = "root"

class Observer:
	extends Node
	var callback: Callable
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 85
	func _physics_process(_delta: float) -> void:
		if callback.is_valid(): callback.call()

var root_network: Node3D
var threat_scheduler: CinderThreatScheduler
var scenery: Node3D
var echo: Node3D
var helper: Node3D
var sun_art: Node3D
var configuration_error: String = ""
var admission_error: String = ""
var _floor: Dictionary = {}
var _configured: bool = false
var _sun_configured: bool = false
var _live: bool = false
var _busy: bool = false
var _core_enabled: bool = false
var _anchor: Variant = null
var _sun: Dictionary = {}
var _pending_release: bool = false
var _released: bool = false
var _helper_retired: Dictionary = {}
var _helper_death: Dictionary = {}
var _projection: Dictionary = {}
var _lease: Dictionary = {}
var _positions: Array[Vector3] = []
var _proof: Dictionary = {}
var _pending_echo: Dictionary = {}
var _observer: Observer
var _pair = Pair.new()
var _capture_camera: Camera3D
var _capture_hud: GameHUD
var _capture_error: String = ""
var _capture_busy: bool = false
var _restore_expected: Dictionary = {}
var _restore_started: bool = false
var _restore_finished: bool = false
var _restore_error: String = ""
var _abort_after_scheduler: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 130
	scenery = Scenery.new()
	add_child(scenery)
	if not scenery.call("build") or not scenery.call("show_progress", true, false):
		configuration_error = "Declared component native full floor/scenery declined"
		return
	var floor_body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	_floor = {"collision": floor_body.get_node("Solid"), "safe_rect": FLOOR_RECT}
	threat_scheduler = Scheduler.new()
	add_child(threat_scheduler)
	root_network = Core.new()
	add_child(root_network)
	echo = Echo.new()
	add_child(echo)
	sun_art = Sun.new()
	add_child(sun_art)
	_observer = Observer.new()
	_observer.callback = _before_consumers
	add_child(_observer)
	_sun = Model.sun_at(null, 0.0)

func _on_enter_level() -> void:
	var profile: String = String(shared_shell.call("get_difficulty_preference")) if shared_shell.has_method("get_difficulty_preference") else "standard"
	configuration_error = _configure_native(profile, true, false)
	_live = configuration_error.is_empty()
	_core_enabled = declared_cell == "root"
	if _live and not root_network.call("set_active", _core_enabled): configuration_error = "Declared initial Core activation declined"
	_present()

func _configure_native(profile: String, tracked: bool, with_helper: bool) -> String:
	if _configured or declared_cell not in ["root", "echo"] or not configuration_error.is_empty(): return "Fresh declared component topology required"
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER, 1): return threat_scheduler.last_error
	if not root_network.call("configure", self, hero, effects, shared_shell, threat_scheduler, get_parent() as Node3D, {FLOOR_ID: _floor}, _response, _view_guard, ENCOUNTER, 1): return String(root_network.get("last_configuration_error"))
	root_network.connect("phase_boundary", _on_boundary)
	var context: Dictionary = _context(1)
	if context.is_empty(): return "Actual full native floor context required"
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": context.world_collision_fingerprint, "floor_signature": context.world_floor_signature}
	if not echo.call("configure_source", ECHO_ID, ECHO_EPOCH, 1, native_definition(), profile, prepared, threat_scheduler) or not echo.call("retain_source_environment", get_parent() as Node3D, [_floor]): return String(echo.get("source_snapshot_error"))
	if tracked and not echo.call("enable_authored_cycle_tracking", threat_scheduler, {"hero": hero}, [_floor], context): return String(echo.get("last_error"))
	_configured = true
	if with_helper and not _install_helper(): return configuration_error
	if tracked:
		if not sun_art.call("configure", self, hero): return String(sun_art.get("last_error"))
		_sun_configured = true
	return ""

func _install_helper() -> bool:
	if is_instance_valid(helper):
		configuration_error = "Exactly one actual helper may be constructed"
		return false
	helper = Root.new()
	helper.name = "ActualDeclaredHelper"
	add_child(helper)
	helper.global_position = HELPER_POSITION
	if not helper.call("configure", HELPER_ID, hero, effects, threat_scheduler, _helper_response, _helper_guard):
		configuration_error = String(helper.get("last_error"))
		return false
	helper.connect("died", _on_helper_died)
	return true

func native_definition() -> Dictionary:
	var recipe: Node = EchoRecipe.new()
	var definition: Dictionary = recipe.call("native_definition")
	recipe.free()
	definition.definition_id = "TEST/A3-L4/mixed-near-root-echo"
	definition.route = [{"position": Vector3(-0.6, 0, -1.7), "at_s": 0.0}, {"position": Vector3(-0.6, 0, 0.3), "at_s": 0.3}]
	definition.slash.world_origin = Vector3(-0.6, 0, 0.3)
	definition.slash.direction = Vector3.BACK
	return definition

func scheduler_bindings() -> Dictionary:
	var owners: Dictionary = root_network.call("scheduler_owners") if _configured else {}
	if _configured: owners[ECHO_ID] = echo
	if is_instance_valid(helper): owners[HELPER_ID + "/attack"] = helper.call("get_mechanism")
	return {"world_root": get_parent() as Node3D, "owners": owners, "actors": {"hero": hero}, "floors": {FLOOR_ID: _floor}}

func _context(generation: int) -> Dictionary:
	var signature: Dictionary = Footprint.floor_signature(get_parent() as Node3D, [_floor])
	if not signature.get("accepted", false): return {}
	return {"world_root": get_parent() as Node3D, "source_id": ECHO_ID, "source_epoch": ECHO_EPOCH, "generation": generation, "world_collision_fingerprint": threat_scheduler.pure_collision_fingerprint(get_parent() as Node3D), "world_floor_signature": signature.signature}

func context_for_generation(generation: int) -> Dictionary:
	return _context(generation)

func context() -> Dictionary:
	return _context(int(echo.call("get_authored_cycle_generation")))

func floor_regions() -> Array:
	return [_floor.duplicate()]

func _response(_kind: String, direction: Vector3) -> Dictionary:
	return {"encounter_id": ENCOUNTER, "world_revision": 1, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": [direction], "return_directions": [-direction], "floor_regions": [_floor]}

func _helper_response() -> Dictionary:
	var response: Dictionary = hero.get_threat_response_state()
	var directions: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]
	response.merge({"encounter_id": ENCOUNTER, "world_revision": 1, "world_root": get_parent() as Node3D, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [_floor]}, true)
	return response

func combat_response() -> Dictionary:
	return _helper_response()

func try_core(kind: String, direction: Vector3) -> Dictionary:
	if not _live or _busy or get_tree().paused: return {"accepted": false, "reason": "Actual live settled component required"}
	_core_enabled = true
	if not root_network.call("set_active", true): return {"accepted": false, "reason": "Actual Core activation refused"}
	return root_network.call("try_start", kind, direction, int(_sun.effective_index))

func admit_echo() -> Dictionary:
	if not _live or _busy or get_tree().paused or echo.call("source_phase") != "cycle_ready": return {"accepted": false, "reason": "Actual live ready Echo required"}
	var ctx: Dictionary = context()
	var witness: Dictionary = Witness.new().prove_authored(threat_scheduler, echo, echo.call("source_program"), combat_response(), ctx)
	if not witness.get("accepted", false): return witness
	var projection: Dictionary = Footprint.plan_authored(threat_scheduler, echo.call("source_program"), get_parent() as Node3D, [_floor], ctx)
	if not projection.get("accepted", false): return projection
	_pending_echo = {"projection": projection, "positions": _proof_positions(witness)}
	var error: String = _view_guard(false, {})
	if error.is_empty(): error = _view_guard(true, {})
	if not error.is_empty():
		_pending_echo.clear()
		return {"accepted": false, "reason": error}
	var answer: Dictionary = threat_scheduler.request_authored_replay(echo, echo.call("source_program"), combat_response(), ctx)
	if answer.get("accepted", false):
		_projection = projection
		_lease = answer.reservation.duplicate(true)
		_proof = answer.proof.duplicate(true)
		_positions = _proof_positions(answer.proof)
		if not echo.call("bind_projected", threat_scheduler, String(answer.reservation_id), {"hero": hero}, [_floor], projection, ctx):
			threat_scheduler.cancel(String(answer.reservation_id), "test_component_bind_failed")
			configuration_error = String(echo.get("last_error"))
	_pending_echo.clear()
	return answer

func prepare_next_echo_cycle() -> bool:
	if not _live or _busy or get_tree().paused or bool(echo.get("dead")): return false
	var generation: int = int(echo.call("get_authored_cycle_generation")) + 1
	var reader = Exact.new()
	if not reader.configure(ECHO_ID + "/sequence-%d" % generation, native_definition(), ECHO_ID, ECHO_EPOCH, generation, echo.call("source_profile"), echo.call("prepared_world")): return false
	if not echo.call("prepare_next_authored_cycle", ECHO_ID + "/playback-%d" % generation, reader.snapshot_state()): return false
	_projection.clear()
	_lease.clear()
	_positions.clear()
	_proof.clear()
	return true

func _before_consumers() -> void:
	if not _live or _busy or not is_instance_valid(hero) or hero.dead: return
	_sun = Model.sun_at(_anchor, threat_scheduler.get_clock())
	if not sun_art.call("present"):
		configuration_error = String(sun_art.get("last_error"))
		return
	var held: bool = false
	for owner: Node3D in scheduler_bindings().owners.values():
		held = held or not threat_scheduler.source_control_state(owner).get("reservations", []).is_empty()
	if held:
		var current_error: String = _view_guard(true, {})
		if not current_error.is_empty():
			admission_error = current_error
			for owner: Node3D in scheduler_bindings().owners.values():
				var control: Dictionary = threat_scheduler.source_control_state(owner)
				if control.get("reservations", []).is_empty(): continue
				if owner == echo: echo.call("cancel", "test_component_actual_view_lost")
				elif owner is CinderLaneMechanism: (owner as CinderLaneMechanism).cancel("test_component_actual_view_lost")
			return
	if not _lease.is_empty() and echo.call("state").get("status") == "running" and not _lease.get("adapter", {}).get("locked", false) and threat_scheduler.get_clock() >= float(_lease.lock_from_s):
		var error: String = _view_guard(true, {})
		if not error.is_empty(): echo.call("cancel", "test_component_locked_view_lost")
		else:
			var answer: Dictionary = threat_scheduler.commit_authored_replay(String(_lease.id), combat_response())
			if answer.get("accepted", false):
				_lease = answer.reservation.duplicate(true)
				_proof = answer.proof.duplicate(true)
				_positions = _proof_positions(answer.proof)
			else: admission_error = String(answer.get("reason", "Native due lock rejected"))

func _physics_process(_delta: float) -> void:
	if not _live or _busy or not is_instance_valid(hero) or hero.dead: return
	if _pending_release: _settle_release()
	_present()

func _on_boundary(crossing: Dictionary) -> void:
	if not _live or _busy: return
	_busy = true
	var target: Node3D = root_network.call("get_tether")
	if crossing.get("clock_s") != threat_scheduler.get_clock(): configuration_error = "Actual same-clock native phase boundary required"
	elif crossing.get("from_phase") == 1 and crossing.get("to_phase") == 2 and target.get("hp") == 30.0 and _anchor == null and not is_instance_valid(helper):
		_anchor = crossing.clock_s
		_sun = Model.sun_at(_anchor, threat_scheduler.get_clock())
		_install_helper()
	elif crossing.get("from_phase") == 2 and crossing.get("to_phase") == 3 and target.get("hp") == 0.0 and not _released:
		_pending_release = true
	else: configuration_error = "Original monotonic native two-phase component boundary required"
	_busy = false
	_present()

func _on_helper_died(_position: Vector3) -> void:
	_helper_death = {"clock_s": threat_scheduler.get_clock(), "position": Value.vector3(helper.global_position)}

func _settle_release() -> void:
	_busy = true
	if is_instance_valid(helper) and not bool(helper.get("dead")):
		var mechanism: CinderLaneMechanism = helper.call("get_mechanism")
		var before: Dictionary = mechanism.state()
		var hp_before: float = float(helper.get("hp"))
		var transform_before: Transform3D = helper.global_transform
		var body: CollisionShape3D = helper.get_node("BodyCollision") as CollisionShape3D
		var layer: int = int(helper.get("collision_layer"))
		var mask: int = int(helper.get("collision_mask"))
		if not mechanism.cancel("test_garden_released") or not _live:
			configuration_error = "Real living helper retirement refused"
		else:
			helper.set_physics_process(false)
			var after: Dictionary = mechanism.state()
			if helper.global_transform != transform_before or float(helper.get("hp")) != hp_before or bool(helper.get("dead")) or not helper.is_in_group("enemies") or body.disabled or int(helper.get("collision_layer")) != layer or int(helper.get("collision_mask")) != mask or after.cycle != before.cycle or after.last_cancel_reason != "test_garden_released" or not threat_scheduler.source_control_state(mechanism).reservations.is_empty(): configuration_error = "Living helper actual body/HP/cycle/group custody changed"
			else: _helper_retired = {"clock_s": threat_scheduler.get_clock(), "cycle": before.cycle, "hp": hp_before, "reason": "test_garden_released"}
	if configuration_error.is_empty():
		if not root_network.call("set_active", false) or not scenery.call("show_progress", true, true): configuration_error = "Actual Core/source release or cosmetic stripping failed"
		else:
			_pending_release = false
			_released = true
	_busy = false

func _present(quiet: bool = false) -> void:
	if not _configured or not _sun_configured: return
	_sun = Model.sun_at(_anchor, threat_scheduler.get_clock())
	if not sun_art.call("present", quiet): configuration_error = String(sun_art.get("last_error"))
	objective_text = "TEST COMPONENT / %s / SUN%d %s -> SUN%d" % [declared_cell.to_upper(), int(_sun.effective_index), String(_sun.stage).to_upper(), int(_sun.incoming_index)]

func sun_presentation_state() -> Dictionary:
	return _sun.duplicate(true)

func component_state() -> Dictionary:
	return {"declared_cell": declared_cell, "configuration_error": configuration_error, "admission_error": admission_error, "sun": _sun.duplicate(true), "core_enabled": _core_enabled, "pending_release": _pending_release, "released": _released, "helper_retired": _helper_retired.duplicate(true), "helper_death": _helper_death.duplicate(true), "echo_projection": _projection.duplicate(true), "echo_lease": _lease.duplicate(true), "echo_positions": _positions.duplicate(), "echo_proof": _proof.duplicate(true)}

func runtime_error() -> String:
	if not configuration_error.is_empty(): return configuration_error
	if not _configured or not is_instance_valid(hero) or not is_instance_valid(shared_shell) or global_transform != Transform3D.IDENTITY: return "Actual configured component/Hero/Shell required"
	if not is_instance_valid(_observer) or _observer.get_parent() != self or _observer.callback != _before_consumers or _observer.process_mode != Node.PROCESS_MODE_PAUSABLE or _observer.process_physics_priority != 85 or not _observer.is_physics_processing() or hero.process_physics_priority >= 85 or threat_scheduler.process_physics_priority >= 85: return "Actual pre-consumer85 observer after native Hero/Scheduler required"
	var error: String = String(scenery.call("runtime_error"))
	if error.is_empty(): error = String(root_network.call("runtime_error"))
	if error.is_empty(): error = String(echo.call("source_native_error"))
	if error.is_empty():
		if _sun_configured: error = String(sun_art.call("runtime_error"))
		elif not is_restore_candidate() or _live or sun_art.get_script() != Sun or sun_art.get_child_count() != 0 or sun_art.global_transform != Transform3D.IDENTITY: error = "Only an exact empty candidate Sun reader may await quiet control construction"
	return error

func _view_guard(current: bool, prospective: Dictionary) -> String:
	var bounds: Dictionary = framing_union(get_viewport().get_camera_3d(), prospective)
	if not String(bounds.error).is_empty(): return String(bounds.error)
	if current: return String(shared_shell.call("camera_framing_error", bounds.points))
	var plan: Dictionary = shared_shell.call("camera_framing_plan", bounds.points, hero.global_position + Vector3.UP * 0.75)
	return "" if plan.get("accepted", false) else String(plan.get("reason", "Native component framing refused"))

func _helper_guard(current: bool, preview: Dictionary) -> String:
	var bounds: Dictionary = framing_union(get_viewport().get_camera_3d(), {}, preview)
	if not String(bounds.error).is_empty(): return String(bounds.error)
	if current: return String(shared_shell.call("camera_framing_error", bounds.points))
	var plan: Dictionary = shared_shell.call("camera_framing_plan", bounds.points, hero.global_position + Vector3.UP * 0.75)
	return "" if plan.get("accepted", false) else String(plan.get("reason", "Actual helper union refused"))

func framing_union(camera: Camera3D, prospective: Dictionary = {}, helper_preview: Dictionary = {}) -> Dictionary:
	if not _configured or not is_instance_valid(camera): return {"error": "Actual native configured component Camera required", "points": []}
	var points: Array = shared_shell.call("player_camera_framing_points_for", hero, camera)
	if points.is_empty(): return {"error": "Actual Hero native corners required", "points": []}
	if _core_enabled:
		var core: Dictionary = root_network.call("framing_points_for_context", camera, prospective)
		if not core.get("accepted", false): return {"error": String(core.get("reason", "Core native bounds refused")), "points": []}
		points.append_array(core.points)
	var echo_bounds: Dictionary = echo.call("framing_points")
	if not String(echo_bounds.get("error", "Actual Echo render required")).is_empty(): return {"error": String(echo_bounds.error), "points": []}
	var echo_points: Array = echo_bounds.points.duplicate()
	var projection: Dictionary = _pending_echo.get("projection", _projection)
	for event: Dictionary in projection.get("events", []):
		for x: float in [float(event.bounds[0]), float(event.bounds[2])]:
			for z: float in [float(event.bounds[1]), float(event.bounds[3])]: echo_points.append(Vector3(x, float(event.floor_y) + CinderThreatCue.FLOOR_OFFSET, z))
	var origin: Vector3 = (echo.call("source_definition") as Dictionary).slash.world_origin
	for phase: String in ["warning", "lock", "active", "recovery"]:
		var mesh: Mesh = CueMeshes.source_mesh(phase)
		var transform := Transform3D(Basis.IDENTITY, origin + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004))
		for corner: int in range(8): echo_points.append(transform * mesh.get_aabb().get_endpoint(corner))
	var route: MeshInstance3D = echo.get_node_or_null("ExactHarmlessRoutes") as MeshInstance3D
	if route != null and route.is_visible_in_tree() and route.mesh != null:
		for corner: int in range(8): echo_points.append(route.global_transform * route.mesh.get_aabb().get_endpoint(corner))
	for cue: Node3D in echo.call("get_cues"): _append_cue(echo_points, cue)
	var paths: Array = _pending_echo.get("positions", _positions)
	for position: Vector3 in paths:
		for corner: Vector3 in shared_shell.call("player_camera_framing_points_for", hero, camera): echo_points.append(corner + position - hero.global_position)
	points.append_array(_enclose(echo_points))
	if is_instance_valid(helper):
		var geometry: Dictionary = (helper_preview.get("candidate", {}) as Dictionary).get("geometry", {})
		var bounds: Dictionary = helper.call("framing_points_for_camera", camera, geometry)
		if not String(bounds.get("error", "Actual helper bounds required")).is_empty(): return {"error": String(bounds.error), "points": []}
		points.append_array(bounds.points)
		var selected: Dictionary = helper_preview.get("proof", {}) if not helper_preview.is_empty() else helper.call("get_selected_response")
		for key: String in ["landing", "attack_position"]:
			if selected.get(key) is Vector3:
				for corner: Vector3 in shared_shell.call("player_camera_framing_points_for", hero, camera): points.append(corner + selected[key] - hero.global_position)
	return {"error": "" if points.size() <= 224 else "Complete native component groups exceed224", "points": points}

func _camera_framing_points() -> Array:
	if not _live: return []
	var result: Dictionary = framing_union(get_viewport().get_camera_3d())
	last_camera_framing_error = String(result.error)
	return result.points if last_camera_framing_error.is_empty() else []

func optional_sun_bounds(camera: Camera3D) -> Dictionary:
	return sun_art.call("framing_points", camera)

func _append_cue(points: Array, cue: Node3D) -> void:
	for child: Node in cue.get_children():
		var visual: MeshInstance3D = child as MeshInstance3D
		if visual != null and visual.is_visible_in_tree() and visual.mesh != null:
			for corner: int in range(8): points.append(visual.global_transform * visual.mesh.get_aabb().get_endpoint(corner))

func _enclose(points: Array) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if points.is_empty(): return result
	var low: Vector3 = points[0]
	var high: Vector3 = low
	for point: Vector3 in points:
		low = low.min(point)
		high = high.max(point)
	var box := AABB(low, high - low)
	for index: int in range(8): result.append(box.get_endpoint(index))
	return result

func _proof_positions(proof: Dictionary) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for segment: Dictionary in proof.get("path", []):
		for key: String in ["from", "to"]:
			if segment.get(key) is Vector3 and not result.has(segment[key]): result.append(segment[key])
	return result

func _capture_local_state() -> Dictionary:
	var data: Dictionary = _pair.capture(self, hero.snapshot_state(), _capture_camera, _capture_hud)
	_capture_error = _pair.last_error
	return data

func snapshot_state() -> Dictionary:
	return _checked_capture(null, null)

func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if is_restore_candidate() or not is_instance_valid(camera) or not is_instance_valid(hud):
		last_snapshot_error = "Actual fresh native component Camera/HUD required"
		return {}
	return _checked_capture(camera, hud)

func _checked_capture(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if _capture_busy:
		last_snapshot_error = "Component capture cannot reenter"
		return {}
	_capture_busy = true
	_capture_error = ""
	_capture_camera = camera
	_capture_hud = hud
	var result: Dictionary = super.snapshot_state()
	_capture_camera = null
	_capture_hud = null
	_capture_busy = false
	if result.is_empty() and not _capture_error.is_empty(): last_snapshot_error = _capture_error
	_capture_error = ""
	return result

func _local_snapshot_error(data: Dictionary) -> String:
	return _pair.prevalidate(data, self, hero.snapshot_state())

func _local_snapshot_error_with_player(data: Dictionary, player: Dictionary) -> String:
	return _pair.prevalidate(data, self, player)

func _snapshot_envelope_error(data: Dictionary) -> String:
	var error: String = super._snapshot_envelope_error(data)
	if not error.is_empty(): return error
	var progress: Dictionary = data.progress
	if progress.completed or not progress.completion_id.is_empty() or not progress.contact_exit_id.is_empty() or not progress.checkpoint_id.is_empty() or not progress.checkpoint_kind.is_empty() or not progress.checkpoint_ids.is_empty(): return "Declared component never invents campaign progression"
	return _pair.shape_error(data.local, self)

func restore_candidate_construction_required() -> bool:
	return true

func _on_enter_restore_candidate(data: Dictionary, player: Dictionary) -> String:
	_live = false
	var error: String = _pair.shape_error(data, self)
	if not error.is_empty(): return error
	error = _configure_native(data.world.profile_id, false, not data.helper.is_empty())
	if not error.is_empty(): return error
	error = _pair.prevalidate(data, self, player, false)
	if not error.is_empty(): return error
	if not echo.call("prepare_authored_restore", data.echo.playback, threat_scheduler, {"hero": hero}, [_floor], _context(data.echo.source.generation)): return String(echo.get("source_snapshot_error"))
	return _pair.prevalidate(data, self, player)

func _restore_local_state(data: Dictionary) -> void:
	_restore_expected = data.duplicate(true)
	_restore_started = true
	_restore_finished = false
	_restore_error = _pair.commit(data, self, hero.snapshot_state(), _abort_after_scheduler)
	_restore_finished = _restore_error.is_empty()

func restore_state(saved: Dictionary) -> bool:
	if not is_restore_candidate():
		last_snapshot_error = "Component restore requires a real fresh candidate"
		return false
	_restore_error = ""
	var accepted: bool = super.restore_state(saved)
	if not _restore_error.is_empty():
		last_snapshot_error = _restore_error
		return false
	return accepted

func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	if not _restore_finished: return "Actual complete component commit required before optical gate"
	var error: String = _pair.optics(self, camera, hud)
	if not error.is_empty(): return error
	var native: Dictionary = _pair.capture(self, hero.snapshot_state(), camera, hud)
	return "" if Exact.exact_equal(native, _restore_expected) else "Actual post-optical component recapture differs"

func finish_restore_candidate() -> bool:
	var accepted: bool = super.finish_restore_candidate()
	if accepted:
		_restore_expected.clear()
		_restore_started = false
		_restore_finished = false
	return accepted

func arm_test_abort_after_scheduler() -> bool:
	# Disclosed observer arms ONLY a fresh paused unconfigured recipient before
	# CinderLevel enters it. Donor live/captured history is never changed.
	if not is_inside_tree() or not is_node_ready() or not get_tree().paused or _configured or hero != null: return false
	_abort_after_scheduler = true
	return true

func false_paradise_codec_discard_in_progress() -> bool:
	return is_restore_candidate() and get_tree().paused and _restore_started and not _restore_finished and not _restore_expected.is_empty()

func apply_component_control(data: Dictionary) -> String:
	if not is_restore_candidate() or not _restore_started or _restore_finished or _restore_expected.is_empty() or not Exact.exact_equal(data, _restore_expected): return "Owned component controls require the complete validated genuine candidate packet"
	_anchor = data.control.anchor_s
	_pending_release = data.control.pending_release
	_released = data.control.released
	_helper_retired = data.control.helper_retired.duplicate(true)
	_helper_death = data.control.helper_death.duplicate(true)
	_core_enabled = data.control.core_enabled
	_positions.clear()
	for at: Array in data.view.positions: _positions.append(Value.read_vector3(at))
	_projection = data.echo.playback.get("projection", {}).duplicate(true)
	_lease.clear()
	var actual: Dictionary = threat_scheduler.source_control_state(echo)
	if not actual.reservations.is_empty(): _lease = actual.reservations[0].duplicate(true)
	_proof.clear()
	_pending_echo.clear()
	if is_instance_valid(helper): helper.set_physics_process(_helper_retired.is_empty())
	if not root_network.call("set_active", _core_enabled and not _released): return "Actual restored Core activation refused"
	if not scenery.call("restore_presentation", data.presentation, true, _released): return "Actual quiet component scenery declined"
	_sun = Model.sun_at(_anchor, threat_scheduler.get_clock())
	if not _sun_configured:
		if not sun_art.call("configure", self, hero): return String(sun_art.get("last_error"))
		_sun_configured = true
	_live = true
	_present(true)
	return runtime_error()

func owned_transport() -> Dictionary:
	var positions: Array = []
	for at: Vector3 in _positions: positions.append(Value.vector3(at))
	return {"control": {"anchor_s": _anchor, "core_enabled": _core_enabled, "pending_release": _pending_release, "released": _released, "helper_retired": _helper_retired.duplicate(true), "helper_death": _helper_death.duplicate(true)}, "sun": _sun.duplicate(true), "view": {"positions": positions}, "presentation": scenery.call("presentation_state")}

func _on_exit_level() -> void:
	_live = false
	if is_instance_valid(_observer): _observer.set_physics_process(false)
	if not is_instance_valid(root_network) or not is_instance_valid(threat_scheduler): return
	if root_network.is_connected("phase_boundary", _on_boundary): root_network.disconnect("phase_boundary", _on_boundary)
	if is_instance_valid(helper) and helper.is_connected("died", _on_helper_died): helper.disconnect("died", _on_helper_died)
	var discarded: bool = false_paradise_codec_discard_in_progress()
	if not (discarded and root_network.call("discard_staged_candidate", "test_mixed_unfinished_exit")): root_network.call("retire", "test_mixed_exit")
	for owner: Node3D in scheduler_bindings().owners.values():
		var control: Dictionary = threat_scheduler.source_control_state(owner)
		if control.is_empty() or control.reservations.is_empty(): continue
		if owner == echo and echo.call("state").get("status") == "running": echo.call("cancel", "test_mixed_exit")
		elif owner is CinderLaneMechanism and (owner as CinderLaneMechanism).state().status == "running": (owner as CinderLaneMechanism).cancel("test_mixed_exit")
		var after: Dictionary = threat_scheduler.source_control_state(owner)
		if not after.reservations.is_empty():
			var expected_id: String = String(_restore_expected.echo.playback.get("exchange", {}).get("id", "")) if owner == echo else String(_restore_expected.helper.get("mechanism", {}).get("exchange", {}).get("id", ""))
			assert(discarded and control.reservations.size() == 1 and control.reservations[0].id == expected_id and control.clock_s == _restore_expected.scheduler.clock_s, "Raw remaining lease is only an exact genuine staged component recipient")
			threat_scheduler.cancel_owner(owner, "test_mixed_unfinished_exit")
		assert(threat_scheduler.source_control_state(owner).reservations.is_empty(), "Actual component held owner must retire inside tree")
	if is_instance_valid(helper): helper.set_physics_process(false)
	if is_instance_valid(echo): echo.set_physics_process(false)
	# Never end/reset a Scheduler3 managed journal; dispose this entire unit.
