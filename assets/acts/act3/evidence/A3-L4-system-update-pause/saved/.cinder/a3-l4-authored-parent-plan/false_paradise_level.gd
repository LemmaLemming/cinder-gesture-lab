extends CinderLevel
## IGNORED, UNPARSED authored A3-L4 composition draft. Not registered/accepted.
## Preloads name prospective OWNED publish paths; core/adapter must be published
## together before a qualified native import. Never loads ignored paths at runtime.
## Whole save/candidate restore explicitly refuse until the complete codec exists.

const Scenery = preload("res://scripts/acts/act3/false_paradise_scenery.gd")
const RootCore = preload("res://scripts/acts/act3/garden_root_network.gd")
const Latcher = preload("res://scripts/acts/act3/garden_root_latcher.gd")
const Stalker = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const EchoRecipe = preload("res://scripts/acts/act3/mirror_echo_rule_room.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const CueMeshes = preload("res://scripts/cues/cue_mesh.gd")
const ContactCue = preload("res://scripts/cues/interaction_cue.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const API: String = "act3-false-paradise-parent-1"
const LAYOUT: String = "res://data/campaign/act3/false_paradise_layout_candidate.json"
const ENCOUNTER_ID: String = "A3-L4/false-paradise-garden"
const WORLD_REVISION: int = 1
const FLOOR_RECT: Rect2 = Rect2(-7, -14, 14, 78)
const FLOOR_ID: String = "firm-garden"
const ENTRY_IDS: Array[String] = ["offered-rest", "beauty-source", "plain-path", "root-court", "garden-release"]
const ENTRY_Z: Array[float] = [60.0, 42.0, 24.0, 7.0]
const CHECKPOINT_IDS: Array[String] = ["garden-rest-entry", "garden-beauty-entry", "garden-plain-path-entry", "garden-boss-court-entry", "garden-phase2-entry"]
const ENEMY_IDS: Array[String] = ["l4-rest-stalker", "l4-beauty-root", "l4-plain-echo", "l4-plain-root", "l4-garden-helper"]
const EARLIER_IDS: Array[String] = ["l4-rest-stalker", "l4-beauty-root", "l4-plain-echo", "l4-plain-root"]
const HELPER_ID: String = "l4-garden-helper"
const EXIT_ID: String = "adage-plain-threshold"
const COMPLETION_ID: String = "false-paradise-disengaged"
const EXIT_RECT: Rect2 = Rect2(-1.2, -8.65, 2.4, 1.3)
const ROOT_COURT_RECT: Rect2 = Rect2(-7, -5, 14, 12)
const SAVE_LIMIT: String = "False Paradise has no complete whole-parent codec: Save, Continue, checkpoint dispatch and fresh Retry restoration are unsupported"
const SUN_PREVIEW_S: float = 3.0
const SUN_LOCK_S: float = 1.0
const SUN_STABLE_S: float = 10.0
const SUN_PERIOD_S: float = SUN_PREVIEW_S + SUN_LOCK_S + SUN_STABLE_S

class RequiredViewObserver:
	extends Node
	var observe: Callable
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 90
	func _physics_process(_delta: float) -> void:
		if observe.is_valid():
			observe.call()

var scenery: Node3D
var root_network: Node3D
var sources: Dictionary = {}
var threat_scheduler: CinderThreatScheduler
var exit_cue: CinderInteractionCue
var last_configuration_error: String = ""
var last_admission_reason: String = ""
var last_camera_error: String = ""
var _active: bool = false
var _profile: String = "standard"
var _layout: Dictionary = {}
var _rows: Dictionary = {}
var _floor: Dictionary = {}
var _entries: Array[Dictionary] = []
var _deaths: Dictionary = {}
var _pending_boundaries: Array[Dictionary] = []
var _echo_records: Dictionary = {}
var _callbacks: Dictionary = {}
var _cue_callbacks: Array[Dictionary] = []
var _reflections: Dictionary = {}
var _pending_view: Dictionary = {}
var _view_observer: RequiredViewObserver
var _pre_consumer_guard_busy: bool = false
var _control_busy: bool = false
var _sun_anchor_s: Variant = null
var _sun_state: Dictionary = {"started": false, "anchor_s": null, "cycle": 0, "elapsed_s": 0.0, "stage": "stable", "effective_index": 0, "incoming_index": 1}
var _retired_sources: Dictionary = {}
var _disengaged: bool = false
var _disengagement_pending: bool = false
var _exit_state: String = "clear"
var _contact: Dictionary = {}
var _exit_queued: bool = false
var _exit_generation: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 130
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if not decoded is Dictionary:
		last_configuration_error = "Complete actual False Paradise authored layout required"
		return
	_layout = decoded
	last_configuration_error = _layout_error()
	if not last_configuration_error.is_empty():
		return
	scenery = Scenery.new()
	scenery.name = "FalseParadiseScenery"
	add_child(scenery)
	if not scenery.call("build"):
		last_configuration_error = String(scenery.call("runtime_error"))
		return
	var body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var collision: CollisionShape3D = body.get_node_or_null("Solid") as CollisionShape3D if body != null else null
	if collision == null:
		last_configuration_error = "Actual permanent continuous78m garden floor required"
		return
	_floor = {"collision": collision, "safe_rect": FLOOR_RECT}
	threat_scheduler = Scheduler.new()
	threat_scheduler.name = "FalseParadiseScheduler"
	add_child(threat_scheduler)
	_view_observer = RequiredViewObserver.new()
	_view_observer.name = "RequiredNativeViewBeforeConsumers"
	_view_observer.observe = _guard_before_consumers
	add_child(_view_observer)
	exit_cue = ContactCue.new()
	exit_cue.name = "PlainThresholdContactCue"
	exit_cue.position = Vector3(0, 0.1, -8)
	add_child(exit_cue)


func _layout_error() -> String:
	if _layout.get("level_id") != "A3-L4" or not Value.is_integer(_layout.get("schema_version"), 1, 1) or _layout.get("spawn_world") != [0.0, 0.1, 58.0] or not _layout.get("floor") is Dictionary or _layout.floor.get("safe_rect_xz") != [-7.0, -14.0, 14.0, 78.0] or _layout.floor.get("size_world") != [14.0, 1.0, 78.0] or _layout.floor.get("center_world") != [0.0, -0.5, 25.0] or _layout.floor.get("dynamic_collision") != false:
		return "Original A3-L4 identity, spawn and permanent native floor recipe required"
	if not _layout.get("arrangements") is Array or _layout.arrangements.size() != 5 or not _layout.get("sources") is Array or _layout.sources.size() != 7:
		return "Five beats/four spatial courts and seven original source recipes required"
	for index: int in range(5):
		var row: Variant = _layout.arrangements[index]
		if not row is Dictionary or row.get("id") != ENTRY_IDS[index] or row.get("entry_index") != index or row.get("checkpoint_id") != CHECKPOINT_IDS[index] or (index < 4 and row.get("entry_z") != ENTRY_Z[index]) or (index == 4 and row.get("entry_kind") != "genuine_target_phase_boundary"):
			return "Original spatial and true target-phase entry definitions required"
	var expected: Dictionary = {"l4-rest-stalker": "stalker", "l4-beauty-root": "root", "l4-plain-echo": "echo", "l4-plain-root": "root", "l4-garden-draw": "environmental_mechanism", "l4-garden-enclose": "environmental_mechanism", "l4-garden-helper": "root"}
	for row: Variant in _layout.sources:
		if not row is Dictionary or not row.get("id") is String or not expected.has(row.id) or _rows.has(row.id) or row.get("kind") != expected[row.id]:
			return "Exactly the original seven unique authored source identities required"
		_rows[row.id] = row.duplicate(true)
	for index: int in range(4):
		var expected_sources: Array = [["l4-rest-stalker"], ["l4-beauty-root"], ["l4-plain-echo", "l4-plain-root"], ["l4-garden-draw", "l4-garden-enclose"]][index]
		if _layout.arrangements[index].get("source_ids") != expected_sources:
			return "Original each-court source entitlement required"
	if _layout.arrangements[4].get("source_ids") != [HELPER_ID] or _layout.external_tether.get("position_world") != [1.0, 0.0, 0.0] or _layout.external_tether.get("max_hp") != 60.0 or _layout.external_tether.get("phase_boundary_hp") != 30.0 or _layout.external_tether.get("hp_reset_on_phase") != false:
		return "One no-repeat helper and original monotonic60/30 external target required"
	return ""


func contract_error() -> String:
	var error: String = super.contract_error()
	return error if not error.is_empty() else last_configuration_error


func _on_enter_level() -> void:
	if not last_configuration_error.is_empty():
		_update_presentation()
		return
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_plan") or not shared_shell.has_method("camera_framing_error") or not shared_shell.has_method("player_camera_framing_points_for"):
		_fail("Actual shared shell and native current Camera/Hero presentation services required")
		return
	_profile = String(shared_shell.call("get_difficulty_preference")) if shared_shell.has_method("get_difficulty_preference") else "standard"
	if not threat_scheduler.begin_encounter(_profile, ENCOUNTER_ID, WORLD_REVISION):
		_fail(threat_scheduler.last_error)
		return
	_active = true
	_update_presentation()


func _physics_process(_delta: float) -> void:
	if not _active or not is_instance_valid(hero):
		return
	_update_sun()
	_update_presentation()
	if hero.dead or not last_configuration_error.is_empty():
		return
	var error: String = runtime_error()
	if not error.is_empty():
		_fail(error)
		return
	if _advance_entry():
		return # Genuine new native owners begin on their next ordinary tick.
	if _disengagement_pending:
		_finish_disengagement()
		if not _active or not last_configuration_error.is_empty():
			return
	if not _control_busy and not _disengaged:
		_pending_view.clear()
		for id: String in ENEMY_IDS:
			if sources.has(id) and _rows[id].kind == "echo":
				_step_echo(id)
		_step_roots()
	if _disengaged and _all_required_cleared():
		if not is_completed():
			request_completion(COMPLETION_ID)
		if _exit_state == "clear":
			_exit_state = "available"
		if _exit_state == "available" and _capsule_in_rect(EXIT_RECT) and not _exit_queued:
			_exit_state = "active"
			_contact = {"clock_s": threat_scheduler.get_clock(), "hero_position": Value.vector3(hero.global_position), "exit_id": EXIT_ID}
			_exit_queued = true
			_exit_generation += 1
			_dispatch_exit.call_deferred(_exit_generation)
	_update_presentation()


func _advance_entry() -> bool:
	if _control_busy or _entries.size() >= 4 or not _capsule_in_rect(FLOOR_RECT):
		return false
	var index: int = _entries.size()
	var body: Dictionary = _capsule()
	if not _previous_entry_clear(index) or float(body.center.z) + float(body.radius) > ENTRY_Z[index]:
		return false
	_control_busy = true
	var installed: bool = true
	if index == 3:
		installed = _install_root_network()
	else:
		for id: String in _layout.arrangements[index].source_ids:
			if not _install_source(id):
				installed = false
				break
	if installed and _active:
		var receipt: Dictionary = {"id": ENTRY_IDS[index], "beat": index + 1, "clock_s": threat_scheduler.get_clock(), "hero_position": Value.vector3(hero.global_position), "capsule_radius": body.radius}
		_entries.append(receipt)
		_pending_boundaries.append(receipt.duplicate(true))
		if index == 3 and not scenery.call("show_progress", true, false):
			_fail("Actual offscreen earned boss-entry cosmetic relocation failed")
	_control_busy = false
	_update_presentation()
	return installed


func _previous_entry_clear(index: int) -> bool:
	if index == 0:
		return true
	for source: Node3D in _all_scheduler_owners().values():
		if not threat_scheduler.source_control_state(source).get("reservations", []).is_empty():
			return false
	for id: String in _layout.arrangements[index - 1].source_ids:
		if not _deaths.has(id) or not sources.has(id) or not bool(sources[id].get("dead")) or float(sources[id].get("hp")) != 0.0 or sources[id].is_in_group("enemies"):
			return false
		if _rows[id].kind == "echo" and ((sources[id].call("state") as Dictionary).has("pending_delivery") or (sources[id].call("get_authored_cycle_terminal_receipt") as Dictionary).is_empty()):
			return false
	return true


func _install_source(id: String) -> bool:
	if sources.has(id) or not _rows.has(id) or _rows[id].kind not in ["stalker", "root", "echo"]:
		_fail("Only one genuine fresh entitled original source may be installed: " + id)
		return false
	var row: Dictionary = _rows[id]
	var source: Node3D = Stalker.new() if row.kind == "stalker" else (Latcher.new() if row.kind == "root" else Echo.new())
	source.name = id.replace("-", "_")
	add_child(source)
	sources[id] = source
	if row.kind in ["stalker", "root"]:
		source.global_position = Value.read_vector3(row.position_world)
		var configured: bool = source.call("configure", id, hero, effects, threat_scheduler, combat_response.bind(id), _latcher_view_guard.bind(id)) if row.kind == "root" else source.call("configure", id, hero, effects, threat_scheduler, combat_response.bind(id))
		if not configured:
			_fail(id + ": " + String(source.get("last_error")))
			return false
		if row.kind == "stalker":
			source.call("set_sun_visual", 0)
		var callback: Callable = _on_actor_died.bind(id)
		_callbacks[id] = callback
		source.connect("died", callback)
		return true
	var signature: Dictionary = Footprint.floor_signature(get_parent() as Node3D, [_floor])
	if not signature.get("accepted", false):
		_fail(String(signature.get("reason", "Actual complete garden floor signature required")))
		return false
	var context: Dictionary = {"world_root": get_parent() as Node3D, "source_id": id, "source_epoch": String(row.source_epoch_recipe), "generation": 1, "world_collision_fingerprint": threat_scheduler.pure_collision_fingerprint(get_parent() as Node3D), "world_floor_signature": signature.signature}
	var prepared: Dictionary = {"world_revision": WORLD_REVISION, "collision_fingerprint": context.world_collision_fingerprint, "floor_signature": context.world_floor_signature}
	if not source.call("configure_source", id, context.source_epoch, 1, native_definition(id), _profile, prepared, threat_scheduler) or not source.call("retain_source_environment", get_parent() as Node3D, [_floor]) or not source.call("enable_authored_cycle_tracking", threat_scheduler, {"hero": hero}, [_floor], context) or not source.call("source_cycles_managed"):
		_fail(id + ": " + String(source.get("source_snapshot_error")) + "; " + String(source.get("last_error")))
		return false
	_echo_records[id] = {"context": context, "projection": {}, "lease": {}, "proof": {}, "positions": [], "locked": false, "admissions": []}
	_build_reflection(id, Value.read_vector3(row.definition_translation_world))
	var callback: Callable = _on_echo_died.bind(id)
	_callbacks[id] = callback
	source.connect("died", callback)
	return true


func _install_root_network() -> bool:
	if is_instance_valid(root_network):
		_fail("Root network can be constructed only at the genuinely earned boss court")
		return false
	root_network = RootCore.new()
	root_network.name = "ActualFixedRootNetwork"
	add_child(root_network)
	if not root_network.call("configure", self, hero, effects, shared_shell, threat_scheduler, get_parent() as Node3D, {FLOOR_ID: _floor}, _core_response, _core_view_guard, ENCOUNTER_ID, WORLD_REVISION):
		_fail(String(root_network.get("last_configuration_error")))
		return false
	root_network.connect("phase_boundary", _on_root_boundary)
	if not root_network.call("set_active", true):
		_fail("Actual retained root network could not enter its earned live court")
		return false
	return true


func _step_roots() -> void:
	if not is_instance_valid(root_network) or _entries.size() < 4 or _disengaged or _control_busy or hero.dead or not hero.get_threat_response_state().get("stable", false):
		return
	var current: Dictionary = root_network.call("state")
	if current.dead or threat_scheduler.get_clock() < float(current.retry_at_s):
		return
	var kind: String = current.next_kind
	for direction: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var answer: Dictionary = root_network.call("try_start", kind, direction, int(_sun_state.effective_index))
		if answer.get("accepted", false):
			last_admission_reason = ""
			_pending_view.clear()
			return
		last_admission_reason = String(answer.get("reason", "Native garden response rejected"))
		# One measured branch may need ordinary Camera follow before admission;
		# do not switch to all four simultaneous forecast alternatives.
		if _pending_view.get("kind") == "core":
			return


func _core_response(_kind: String, direction: Vector3) -> Dictionary:
	return {"encounter_id": ENCOUNTER_ID, "world_revision": WORLD_REVISION, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": [direction], "return_directions": [-direction], "floor_regions": [_floor]}


func _core_view_guard(current_view: bool, prospective: Dictionary) -> String:
	if not prospective.is_empty():
		_pending_view = {"kind": "core", "core": prospective.duplicate(true)}
	var union: Dictionary = camera_framing_union("", [], current_view, not prospective.is_empty(), prospective)
	return _guard_union(union, current_view)


func _on_root_boundary(crossing: Dictionary) -> void:
	if not _active or _control_busy or not is_instance_valid(root_network):
		return
	_control_busy = true
	var target: CinderAct3GardenRootTether = root_network.call("get_tether")
	if crossing.get("from_phase") == 1 and crossing.get("to_phase") == 2:
		if _entries.size() != 4 or _sun_anchor_s != null or sources.has(HELPER_ID) or target.phase != 2 or target.hp != 30.0:
			_fail("Actual first monotonic target boundary must create one helper exactly once")
		else:
			_sun_anchor_s = threat_scheduler.get_clock()
			_update_sun()
			if _install_source(HELPER_ID):
				var receipt: Dictionary = {"id": ENTRY_IDS[4], "beat": 5, "clock_s": threat_scheduler.get_clock(), "hero_position": Value.vector3(hero.global_position), "from_phase": 1, "to_phase": 2, "root_boundary": crossing.duplicate(true)}
				_entries.append(receipt)
				_pending_boundaries.append(receipt.duplicate(true))
	elif crossing.get("from_phase") == 2 and crossing.get("to_phase") == 3:
		if _entries.size() != 5 or not target.dead or target.hp != 0.0 or _disengaged:
			_fail("Actual final target defeat must retain its unique earned phase2 entitlement")
		else:
			_disengaged = true
			_disengagement_pending = true # After real target callback/flags settle.
	else:
		_fail("Original two target boundaries required")
	_control_busy = false
	_update_presentation()


func _finish_disengagement() -> void:
	if not _disengagement_pending or not _active or not is_instance_valid(root_network):
		return
	_control_busy = true
	if sources.has(HELPER_ID) and not bool(sources[HELPER_ID].get("dead")):
		var helper: Node3D = sources[HELPER_ID]
		var mechanism: CinderLaneMechanism = helper.call("get_mechanism")
		var before: Dictionary = mechanism.state()
		var hp_before: float = float(helper.get("hp"))
		var retired: bool = mechanism.cancel("garden_disengaged")
		helper.set_physics_process(false)
		if not retired or float(helper.get("hp")) != hp_before or bool(helper.get("dead")) or not helper.is_in_group("enemies") or not threat_scheduler.source_control_state(mechanism).get("reservations", []).is_empty():
			_fail("Living helper retirement must preserve its actual HP/body/group and empty native lease")
		else:
			_retired_sources[HELPER_ID] = {"clock_s": threat_scheduler.get_clock(), "reason": "garden_disengaged", "alive": true, "cycle": before.cycle}
	# Already dead helper is untouched; retain original source_defeated reason.
	if _active and not root_network.call("set_active", false):
		_fail("Final root native leases must be empty before admission deactivation")
	if _active and not scenery.call("show_progress", true, true):
		_fail("Actual parent cosmetic stripping failed")
	_disengagement_pending = false
	_control_busy = false


func _update_sun() -> void:
	if _sun_anchor_s == null:
		return
	var elapsed: float = maxf(0.0, threat_scheduler.get_clock() - float(_sun_anchor_s))
	var cycle: int = int(floor(elapsed / SUN_PERIOD_S))
	var local_s: float = elapsed - float(cycle) * SUN_PERIOD_S
	var effective: int = cycle % 2 if local_s < SUN_PREVIEW_S + SUN_LOCK_S else (cycle + 1) % 2
	_sun_state = {"started": true, "anchor_s": _sun_anchor_s, "cycle": cycle, "elapsed_s": local_s, "stage": "preview" if local_s < SUN_PREVIEW_S else ("lock" if local_s < SUN_PREVIEW_S + SUN_LOCK_S else "stable"), "effective_index": effective, "incoming_index": 1 - effective}


func _latcher_view_guard(current_view: bool, preview: Dictionary, id: String) -> String:
	var shape: Dictionary = {}
	var positions: Array = []
	if not preview.is_empty():
		if not preview.get("proof") is Dictionary or not preview.get("candidate") is Dictionary or not preview.candidate.get("geometry") is Dictionary:
			return "Actual native stationary preview geometry/response required"
		shape = preview.candidate.geometry
		positions = [preview.proof.landing, preview.proof.attack_position]
		_pending_view = {"kind": "root", "id": id, "geometry": shape.duplicate(true), "positions": positions.duplicate()}
	var bounds: Dictionary = _latcher_bounds(id, shape, positions)
	if not String(bounds.error).is_empty():
		return String(bounds.error)
	return _guard_union(camera_framing_union(id, bounds.points, current_view, false), current_view)


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


func _guard_before_consumers() -> void:
	if not _active or _pre_consumer_guard_busy or get_tree().paused or hero == null or hero.dead or not last_configuration_error.is_empty():
		return
	_update_sun()
	if not _any_held():
		return
	_pre_consumer_guard_busy = true
	var error: String = _guard_union(camera_framing_union("", [], true, false), true)
	if not error.is_empty():
		_cancel_held("garden_parent_pre_consumer_view_unreadable")
	else:
		for id: String in ENEMY_IDS:
			if not _active or hero.dead or not last_configuration_error.is_empty():
				break
			if sources.has(id) and _rows[id].kind == "echo":
				_commit_due_echo(id)
	_pre_consumer_guard_busy = false


func _any_held() -> bool:
	for owner: Node3D in _all_scheduler_owners().values():
		if not threat_scheduler.source_control_state(owner).get("reservations", []).is_empty():
			return true
	return false


func _all_scheduler_owners() -> Dictionary:
	var owners: Dictionary = {}
	for id: String in sources:
		if _rows[id].kind == "root":
			owners.merge(sources[id].call("scheduler_owners"), false)
		else:
			owners[id] = sources[id]
	if is_instance_valid(root_network):
		owners.merge(root_network.call("scheduler_owners"), false)
	return owners


func scheduler_bindings() -> Dictionary:
	return {"world_root": get_parent() as Node3D, "owners": _all_scheduler_owners(), "actors": {"hero": hero}, "floors": {FLOOR_ID: _floor}}


func _cancel_held(reason: String) -> void:
	for id: String in sources:
		if not _active:
			break
		var source: Node3D = sources[id]
		if _rows[id].kind == "root":
			var mechanism: CinderLaneMechanism = source.call("get_mechanism")
			if not threat_scheduler.source_control_state(mechanism).get("reservations", []).is_empty():
				mechanism.cancel(reason)
		elif not threat_scheduler.source_control_state(source).get("reservations", []).is_empty():
			if _rows[id].kind == "echo":
				source.call("cancel", reason)
			else:
				threat_scheduler.cancel_owner(source, reason)
	if is_instance_valid(root_network):
		for mechanism: CinderLaneMechanism in (root_network.call("get_mechanisms") as Dictionary).values():
			if not threat_scheduler.source_control_state(mechanism).get("reservations", []).is_empty():
				mechanism.cancel(reason)


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


func _all_required_cleared() -> bool:
	if _entries.size() != 5 or not is_instance_valid(root_network) or not _disengaged or _disengagement_pending or _any_held():
		return false
	var target: CinderAct3GardenRootTether = root_network.call("get_tether")
	if not target.dead or target.hp != 0.0:
		return false
	for id: String in EARLIER_IDS:
		if not _deaths.has(id) or not sources.has(id) or not bool(sources[id].get("dead")) or float(sources[id].get("hp")) != 0.0 or sources[id].is_in_group("enemies"):
			return false
	return _deaths.has(HELPER_ID) or _retired_sources.has(HELPER_ID)


func _update_presentation() -> void:
	if is_instance_valid(exit_cue):
		if _exit_state == "clear":
			exit_cue.clear()
		else:
			exit_cue.present(_exit_state, "contact")
	if not last_configuration_error.is_empty():
		objective_text = "FALSE PARADISE UNAVAILABLE\n" + last_configuration_error
	elif _exit_state != "clear":
		objective_text = "THE GARDEN FALLS AWAY\nCONTACT THE PLAIN THRESHOLD"
	elif _entries.size() >= 4:
		var target: CinderAct3GardenRootTether = root_network.call("get_tether")
		objective_text = "EXTERNAL LOW TETHER / ORDINARY RECOVERY SLASH" if not (root_network.call("logical_exposure") as Dictionary).is_empty() else "ROOT ENDS / LOCKED LANE OR BROKEN RING"
		if target.phase == 2:
			objective_text += "\nSUN%d %s / %d COMING" % [int(_sun_state.effective_index), String(_sun_state.stage).to_upper(), int(_sun_state.incoming_index)]
	elif _entries.size() == 3:
		objective_text = "PLAIN PATH / ONE REAL ECHO AND LOW ROOT\nREAD EACH SOURCE / RETURN WITH ORDINARY PRIMARY"
	elif _entries.size() == 2:
		objective_text = "BEAUTY HAS A LOW SOURCE\nDASH CLEAR / RETURN TO THE BULB"
	else:
		objective_text = "OFFERED REST / FAMILIAR CREST\nDASH CLEAR / TAP THE LOW FLANK"


func runtime_error() -> String:
	if not last_configuration_error.is_empty():
		return last_configuration_error
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not is_instance_valid(threat_scheduler) or threat_scheduler.get_script() != Scheduler or threat_scheduler.get_parent() != self or not is_instance_valid(scenery) or scenery.get_script() != Scenery or scenery.get_parent() != self or global_transform != Transform3D.IDENTITY:
		return "Actual configured identity parent/Hero/shared shell/Scheduler/scenery required"
	if not is_instance_valid(_view_observer) or _view_observer.get_parent() != self or _view_observer.observe != _guard_before_consumers or not _view_observer.is_physics_processing() or _view_observer.process_mode != Node.PROCESS_MODE_PAUSABLE or _view_observer.process_physics_priority != 90 or hero.process_physics_priority >= 90 or threat_scheduler.process_physics_priority >= 90:
		return "Actual view observer90 must precede native contact and Playback110"
	var error: String = String(scenery.call("runtime_error"))
	if not error.is_empty():
		return error
	for id: String in sources:
		var source: Node3D = sources[id]
		if not is_instance_valid(source) or source.get_parent() != self or not source.is_inside_tree() or source.is_queued_for_deletion():
			return "Actual retained entitled native source required: " + id
		var expected: Script = Stalker if _rows[id].kind == "stalker" else (Latcher if _rows[id].kind == "root" else Echo)
		if source.get_script() != expected:
			return "Original owned native source script required: " + id
		if _rows[id].kind == "echo":
			error = String(source.call("source_native_error"))
			if not error.is_empty():
				return id + ": " + error
		elif _rows[id].kind == "root" and source.global_transform != Transform3D(Basis.IDENTITY, Value.read_vector3(_rows[id].position_world)):
			return "Fixed original native bulb transform required: " + id
	if is_instance_valid(root_network):
		error = String(root_network.call("runtime_error"))
		if not error.is_empty():
			return error
	return ""


func state() -> Dictionary:
	var actual: Dictionary = {}
	for id: String in ENEMY_IDS:
		actual[id] = {"installed": sources.has(id), "kind": _rows[id].kind, "source": sources[id].call("get_source_state") if sources.has(id) and _rows[id].kind == "echo" else (sources[id].call("state") if sources.has(id) else {}), "retired": _retired_sources.has(id)}
	return {"api_revision": API, "clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else -1.0, "configuration_error": last_configuration_error, "admission_reason": last_admission_reason, "camera_error": last_camera_error, "profile": _profile, "route": {"entries": _entries.duplicate(true), "deaths": _deaths.duplicate(true), "pending_checkpoint_boundaries": _pending_boundaries.duplicate(true), "retired_sources": _retired_sources.duplicate(true)}, "sources": actual, "echo_records": _echo_records.duplicate(true), "root_network": root_network.call("state") if is_instance_valid(root_network) else {}, "sun": _sun_state.duplicate(true), "disengaged": _disengaged, "completed": is_completed(), "exit_state": _exit_state, "contact": _contact.duplicate(true), "persistence_supported": false, "checkpoint_dispatch_supported": false}


func _capture_local_state() -> Dictionary:
	last_snapshot_error = SAVE_LIMIT
	return {}


func _local_snapshot_error(_local: Dictionary) -> String:
	return SAVE_LIMIT


func _local_snapshot_error_with_player(_local: Dictionary, _saved_player: Dictionary) -> String:
	return SAVE_LIMIT


func restore_candidate_construction_required() -> bool:
	return true


func _on_enter_restore_candidate(_local: Dictionary, _saved_player: Dictionary) -> String:
	return SAVE_LIMIT


func _restore_local_state(_local: Dictionary) -> void:
	push_error(SAVE_LIMIT) # Pure local validation refuses before this hook.


func snapshot_state_for_presentation(_camera: Camera3D, _hud: GameHUD) -> Dictionary:
	last_snapshot_error = SAVE_LIMIT
	return {}


func _fail(reason: String) -> void:
	last_configuration_error = reason
	if _active and is_instance_valid(threat_scheduler):
		_cancel_held("garden_parent_invalid")
	_update_presentation()


func _on_exit_level() -> void:
	# Disarm local callbacks first, while actual recipients/resources are alive.
	_active = false
	_exit_generation += 1
	_exit_queued = false
	_pending_view.clear()
	if is_instance_valid(_view_observer):
		_view_observer.set_physics_process(false)
	for id: String in _callbacks:
		if sources.has(id) and is_instance_valid(sources[id]) and sources[id].is_connected("died", _callbacks[id]):
			sources[id].disconnect("died", _callbacks[id])
	for receipt: Dictionary in _cue_callbacks:
		if is_instance_valid(receipt.node) and receipt.node.is_connected("state_changed", receipt.callback):
			receipt.node.disconnect("state_changed", receipt.callback)
	if is_instance_valid(root_network):
		if root_network.is_connected("phase_boundary", _on_root_boundary):
			root_network.disconnect("phase_boundary", _on_root_boundary)
		root_network.call("retire", "garden_whole_parent_exit")
	for id: String in sources:
		var source: Node3D = sources[id]
		if not is_instance_valid(source) or not source.is_inside_tree():
			continue
		source.set_physics_process(false)
		var owner: Node3D = source.call("get_mechanism") if _rows[id].kind == "root" else source
		var control: Dictionary = threat_scheduler.source_control_state(owner)
		if not control.get("reservations", []).is_empty():
			if _rows[id].kind == "echo":
				source.call("cancel", "garden_whole_parent_exit")
			elif _rows[id].kind == "root":
				(owner as CinderLaneMechanism).cancel("garden_whole_parent_exit")
			else:
				threat_scheduler.cancel_owner(owner, "garden_whole_parent_exit")
	if is_instance_valid(exit_cue):
		exit_cue.clear()
	# Managed Echo history forbids reset-style end_encounter. This whole unit is
	# disposed after genuine public held retirement; original journals persist.


func _capsule() -> Dictionary:
	if not is_instance_valid(hero) or hero.dead or not hero.is_on_floor():
		return {}
	var body: CollisionShape3D = hero.get_node_or_null("BodyCollision") as CollisionShape3D
	if body == null or body.disabled or not body.shape is CapsuleShape3D or body.global_basis != Basis.IDENTITY:
		return {}
	var shape: CapsuleShape3D = body.shape as CapsuleShape3D
	var feet_y: float = body.global_position.y - shape.height * 0.5
	if not is_finite(shape.radius) or shape.radius <= 0.0 or absf(feet_y) > 0.2:
		return {}
	return {"center": body.global_position, "radius": shape.radius}


func _capsule_in_rect(rect: Rect2) -> bool:
	var actual: Dictionary = _capsule()
	return not actual.is_empty() and rect.grow(-float(actual.radius)).has_point(Vector2(actual.center.x, actual.center.z))


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
	response.merge({"world_root": get_parent() as Node3D, "world_revision": WORLD_REVISION, "encounter_id": ENCOUNTER_ID, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [_floor]}, true)
	return response


func _commit_due_echo(id: String) -> void:
	var source: Node3D = sources[id]
	if bool(source.get("dead")) or hero.dead or (source.call("state") as Dictionary).get("status") != "running": return
	var data: Dictionary = _echo_records[id]
	var lease: Dictionary = threat_scheduler.replay_reservation_state(String(data.lease.get("id", "")))
	if lease.is_empty() or data.locked or threat_scheduler.get_clock() < float(lease.lock_from_s): return
	var answer: Dictionary = threat_scheduler.commit_authored_replay(String(lease.id), combat_response(id))
	if not answer.get("accepted", false):
		last_admission_reason = String(answer.get("reason", "Actual Echo lock rejected"))
		return
	data.locked = true
	data.lease = answer.reservation.duplicate(true)
	data.proof = answer.proof.duplicate(true)
	data.positions = _proof_positions(answer.proof)
	if not _view_guard(id, true).is_empty(): source.call("cancel", "garden_parent_locked_echo_view_unreadable")


func _try_echo(id: String) -> void:
	var source: Node3D = sources[id]
	var data: Dictionary = _echo_records[id]
	var program: Dictionary = source.call("source_program")
	var proof: Dictionary = Witness.new().prove_authored(threat_scheduler, source, program, combat_response(id), data.context)
	if not proof.get("accepted", false):
		last_admission_reason = id + ": " + String(proof.get("reason", "Native Echo witness rejected"))
		return
	var projection: Dictionary = Footprint.plan_authored(threat_scheduler, program, get_parent() as Node3D, [_floor], data.context)
	if not projection.get("accepted", false):
		last_admission_reason = String(projection.get("reason", "Actual complete Echo projection rejected"))
		return
	_pending_view = {"id": id, "kind": "echo", "projection": projection, "proof": proof, "positions": _proof_positions(proof)}
	if not _view_guard(id, false).is_empty() or not _view_guard(id, true).is_empty():
		return # Normal shared framing may settle this fresh pure candidate.
	var answer: Dictionary = threat_scheduler.request_authored_replay(source, program, combat_response(id), data.context)
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
		threat_scheduler.cancel(String(answer.reservation_id), "garden_parent_projection_binding_failed")
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
		sources[id].call("cancel", "garden_parent_required_echo_cue_view_unreadable")


func _dispatch_exit(generation: int) -> void:
	if generation != _exit_generation:
		return
	_exit_queued = false
	if not _active or hero.dead or not is_completed() or not _all_required_cleared() or _exit_state != "active":
		return
	_exit_state = "spent"
	if not request_contact_exit(EXIT_ID, hero):
		_exit_state = "available"
		_contact.clear()
	_update_presentation()


func _step_echo(id: String) -> void:
	var source: Node3D = sources[id]
	if bool(source.get("dead")) or hero.dead:
		return
	var data: Dictionary = _echo_records[id]
	var phase: String = String(source.call("source_phase"))
	var playback: Dictionary = source.call("state")
	if playback.get("status") == "running":
		if not _view_guard(id, true).is_empty():
			source.call("cancel", "garden_parent_current_echo_view_unreadable")
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



func seen_entry(id: String) -> int:
	for index: int in range(_entries.size()):
		if _entries[index].id == id:
			return index
	return -1


func _current_enemy_ids() -> Array:
	if _entries.is_empty():
		return []
	if _entries.size() <= 3:
		return (_layout.arrangements[_entries.size() - 1].source_ids as Array).duplicate()
	return [HELPER_ID] if sources.has(HELPER_ID) and (not _disengaged or _capsule_in_rect(ROOT_COURT_RECT)) else []


func _camera_framing_points() -> Array:
	if not _active or not is_instance_valid(hero):
		return []
	var result: Dictionary = camera_framing_union()
	last_camera_framing_error = String(result.error)
	return result.points if last_camera_framing_error.is_empty() else []


func camera_framing_union(candidate_id: String = "", candidate_points: Array = [], current_view: bool = false, include_pending: bool = true, core_prospective: Dictionary = {}) -> Dictionary:
	if not _active or not last_configuration_error.is_empty() or not is_instance_valid(shared_shell) or not is_instance_valid(hero):
		return _bounds_error("Actual entered parent/Hero/presentation bindings required")
	if not candidate_id.is_empty() and not sources.has(candidate_id):
		return _bounds_error("Prospective source must be genuinely installed")
	if candidate_id.is_empty() and not candidate_points.is_empty():
		return _bounds_error("Prospective bounds require their actual source ID")
	var camera: Camera3D = get_viewport().get_camera_3d()
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
			bounds = source.call("camera_framing_points_for_context", shared_shell, hero, camera, {}, {}, current_view) if held else source.call("current_render_framing_points_for_context", shared_shell, hero, camera)
		elif _rows[id].kind == "root":
			bounds = _latcher_bounds(id) if held else source.call("current_render_framing_points_for_camera", camera)
		else:
			bounds = _echo_bounds(id) if held else _echo_current_bounds(id)
		if not String(bounds.get("error", "Complete native source corners required")).is_empty():
			return _bounds_error(id + ": " + String(bounds.error))
		if bounds.points.is_empty() and bool(source.get("dead")) and float(source.get("hp")) == 0.0 and not source.is_in_group("enemies"):
			continue # Native hidden-dead Stalker policy; no fake pixel requirement.
		var enclosed: Dictionary = _enclosure(bounds.points)
		if not String(enclosed.error).is_empty():
			return enclosed
		points.append_array(enclosed.points)
	if is_instance_valid(root_network) and (not _disengaged or _capsule_in_rect(ROOT_COURT_RECT) or not core_prospective.is_empty()):
		var prospective: Dictionary = core_prospective
		if prospective.is_empty() and include_pending and _pending_view.get("kind") == "core":
			prospective = _pending_view.core
		var core: Dictionary = root_network.call("framing_points_for_context", camera, prospective)
		if not core.get("accepted", false):
			return _bounds_error(String(core.get("reason", "Complete fixed root/cue/target/Hero union required")))
		points.append_array(core.points)
		var roots: Dictionary = scenery.call("framing_points", camera, false)
		if not String(roots.get("error", "Original actual scenic root geometry required")).is_empty():
			return _bounds_error(String(roots.error))
		points.append_array(roots.points) # Only native boss roots; beauty/likeness optional.
	if include_pending and not _pending_view.is_empty():
		var id: String = String(_pending_view.get("id", ""))
		if id != candidate_id and sources.has(id) and not _source_held(id):
			var bounds: Dictionary = _echo_bounds(id, _pending_view) if _pending_view.kind == "echo" else _latcher_bounds(id, _pending_view.geometry, _pending_view.positions)
			if not String(bounds.error).is_empty():
				return bounds
			points.append_array(bounds.points)
	if _exit_state != "clear":
		var contact: Dictionary = _contact_bounds()
		if not String(contact.error).is_empty():
			return contact
		points.append_array(contact.points)
	if points.size() > 224:
		return _bounds_error("Complete actual current/held/chosen native groups exceed224 corners")
	return {"error": "", "points": points}


func _source_held(id: String) -> bool:
	if not sources.has(id) or not is_instance_valid(sources[id]):
		return false
	var owner: Node3D = sources[id].call("get_mechanism") if _rows[id].kind == "root" else sources[id]
	return not threat_scheduler.source_control_state(owner).get("reservations", []).is_empty()


func _view_guard(id: String, current: bool) -> String:
	var candidate: Dictionary = {}
	if _pending_view.get("kind") == "echo" and _pending_view.get("id") == id:
		candidate = _echo_bounds(id, _pending_view)
	if not candidate.is_empty() and not String(candidate.error).is_empty():
		return String(candidate.error)
	var union: Dictionary = camera_framing_union(id, candidate.points, current, false) if not candidate.is_empty() else camera_framing_union("", [], current, false)
	return _guard_union(union, current)


func _latcher_bounds(id: String, geometry: Dictionary = {}, positions: Array = []) -> Dictionary:
	var source: Node3D = sources[id]
	var camera: Camera3D = get_viewport().get_camera_3d()
	var native: Dictionary = source.call("framing_points_for_camera", camera, geometry)
	if not String(native.get("error", "Native actual Root Latcher current-camera bounds required")).is_empty():
		return _bounds_error(String(native.error))
	var points: Array = native.points.duplicate()
	if positions.is_empty() and _source_held(id):
		var selected: Dictionary = source.call("get_selected_response")
		if not selected.is_empty():
			positions = [selected.landing, selected.attack_position]
	if not positions.is_empty():
		var error: String = _append_hero_forecasts(points, positions)
		if not error.is_empty():
			return _bounds_error(error)
	return _enclosure(points)


func _echo_bounds(id: String, prospective: Dictionary = {}) -> Dictionary:
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
	var error: String = _append_hero_forecasts(points, data.get("positions", []))
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


func _append_hero_forecasts(points: Array, positions: Array) -> String:
	var native: Array = shared_shell.call("player_camera_framing_points_for", hero, get_viewport().get_camera_3d())
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


func _contact_bounds() -> Dictionary:
	if not is_instance_valid(exit_cue) or not exit_cue.is_visible_in_tree():
		return _bounds_error("Actual available/active/spent contact cue required")
	var points: Array = []
	_append_actual_cue(points, exit_cue)
	for x: float in [EXIT_RECT.position.x, EXIT_RECT.end.x]:
		for z: float in [EXIT_RECT.position.y, EXIT_RECT.end.y]:
			points.append(Vector3(x, 0, z))
	return _enclosure(points)
