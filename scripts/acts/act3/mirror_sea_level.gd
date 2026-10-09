extends CinderLevel
## Owned A3-L3 aggregate candidate with one native Scheduler and actual
## spatial recipients. Source-free arrival capture is verified; restored
## combat, full route, Shell persistence and native art acceptance are pending.

const Shore = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const Stalker = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const EchoRecipe = preload("res://scripts/acts/act3/mirror_echo_rule_room.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Mechanism = preload("res://scripts/combat/lane_mechanism.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const Shape = preload("res://scripts/combat/threat_geometry.gd")
const CueMeshes = preload("res://scripts/cues/cue_mesh.gd")
const ContactCue = preload("res://scripts/cues/interaction_cue.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const ParentCodec = preload("res://scripts/acts/act3/mirror_sea_codec.gd")
const Vignettes = preload("res://scripts/acts/act3/mirror_sea_vignettes.gd")
const API: String = "act3-mirror-sea-parent-1"
const LAYOUT: String = "res://data/campaign/act3/mirror_sea_layout_candidate.json"
const ENCOUNTER_ID: String = "A3-L3/mirror-sea-shore"
const WORLD_REVISION: int = 1
const FLOOR_RECT: Rect2 = Rect2(-7, -54, 14, 108)
const ENTRY_IDS: Array[String] = ["shore-and-doubled-sky", "one-real-body", "useful-ending-west", "useful-ending-east", "resonant-apron", "shore-falls-silent"]
const ENTRY_Z: Array[float] = [39.0, 27.0, 15.0, 2.0, -14.0, -32.0]
const ENTRY_BEATS: Array[int] = [1, 2, 3, 3, 4, 5]
const ENEMY_IDS: Array[String] = ["l3-threshold-stalker", "l3-first-echo", "l3-useful-west-echo", "l3-useful-east-echo", "l3-resonant-echo", "l3-priority-echo", "l3-priority-stalker"]
const SOURCE_ORIGINS: Dictionary = {"l3-threshold-stalker": Vector3(1.2, 0.1, 34), "l3-first-echo": Vector3(0, 0, 21), "l3-useful-west-echo": Vector3(-0.65, 0, 9), "l3-useful-east-echo": Vector3(0.65, 0, -3), "l3-resonant-echo": Vector3(0, 0, -21), "l3-priority-echo": Vector3(-1.1, 0, -38), "l3-priority-stalker": Vector3(1.2, 0.1, -38), "l3-resonant-pulse": Vector3(2.6, 0, -21)}
const PULSE_ID: String = "l3-resonant-pulse"
const EXIT_ID: String = "mirror-sea-dry-threshold"
const COMPLETION_ID: String = "mirror-sea-clear"
const EXIT_RECT: Rect2 = Rect2(-1.2, -47.65, 2.4, 1.3)
const SAVE_LIMIT: String = "Mirror Sea candidate has no complete paired parent codec: saves, checkpoint dispatch and fresh retry construction are unsupported"
const MANAGED_METHODS: Array[String] = ["source_definition", "source_profile", "prepared_world", "source_cycles_managed", "retain_source_environment", "enable_authored_cycle_tracking", "get_authored_cycle_program", "get_authored_cycle_generation", "get_authored_cycle_terminal_receipt", "prepare_next_authored_cycle"]

## Own no attack transaction: sample the real required view after native actor
## motion, before either stationary consumer can resolve a retained contact.
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
var vignettes: Node3D
var _vignette_instance_id: int = 0
var _vignette_world: World3D
var _vignette_children: int = 0
var sources: Dictionary = {}
var threat_scheduler: CinderThreatScheduler
var mechanism: CinderLaneMechanism
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
var _reflections: Dictionary = {}
var _callbacks: Dictionary = {}
var _cue_callbacks: Array[Dictionary] = []
var _stones: Dictionary = {}
var _pending_view: Dictionary = {}
var _mineral: MeshInstance3D
var _pulse_bounds: Array = []
var _pulse_proofs: Dictionary = {}
var _pulse_exchanges: Dictionary = {}
var _pulse_view: Array[Vector3] = []
var _ring_stage: String = "uninstalled"
var _ring_history: Array[Dictionary] = []
var _between_receipt: Dictionary = {}
var _exit_state: String = "clear"
var _contact: Dictionary = {}
var _exit_queued: bool = false
var _exit_generation: int = 0
var _view_observer: RequiredViewObserver
var _pre_consumer_guard_busy: bool = false
var _parent_codec = ParentCodec.new()
var _owned_restore_error: String = ""
var _owned_capture_busy: bool = false
var _owned_capture_error: String = ""
var _owned_capture_camera: Camera3D
var _owned_capture_hud: GameHUD


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 130 # Hero/Scheduler -> guard/locks90 -> Mech100/Playback110 -> route.
	scenery = Shore.new()
	scenery.name = "MirrorSeaScenery"
	add_child(scenery)
	scenery.call("build", false)
	var body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var solid: CollisionShape3D = body.get_node_or_null("Solid") as CollisionShape3D if is_instance_valid(body) else null
	if solid == null or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Vector3(14, 1, 108) or body.global_position != Vector3(0, -0.5, 0):
		last_configuration_error = "Actual continuous 14x108 shore floor required"
		return
	_floor = {"collision": solid, "safe_rect": FLOOR_RECT}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if not parsed is Dictionary:
		last_configuration_error = "Authored Mirror Sea layout unavailable"
		return
	_layout = parsed
	last_configuration_error = _layout_error()
	if not last_configuration_error.is_empty():
		return
	for row: Dictionary in _layout.sources:
		_rows[String(row.id)] = row.duplicate(true)
	for row: Dictionary in _layout.fixed_stones:
		_build_stone(row)
	vignettes = Vignettes.new()
	vignettes.name = "OptionalStaticShoreVignettes"
	if not vignettes.call("build", self):
		last_configuration_error = "Optional authored scenery construction refused: " + String(vignettes.get("last_error"))
		return
	_vignette_instance_id = vignettes.get_instance_id()
	_vignette_world = vignettes.get_world_3d()
	_vignette_children = vignettes.get_child_count()
	threat_scheduler = Scheduler.new()
	threat_scheduler.name = "ContinuousShoreScheduler"
	add_child(threat_scheduler)
	_view_observer = RequiredViewObserver.new()
	_view_observer.name = "RequiredViewBeforeStationaryContact"
	_view_observer.observe = _guard_before_consumers
	add_child(_view_observer)
	exit_cue = ContactCue.new()
	exit_cue.name = "DryThresholdContactCue"
	exit_cue.position = Vector3(0, 0.1, -47)
	add_child(exit_cue)
	_update_presentation()


func _layout_error() -> String:
	if _layout.get("level_id") != "A3-L3" or not Value.is_integer(_layout.get("schema_version"), 1, 1) or not _layout_numbers_match(_layout.get("spawn_world"), [0.0, 0.1, 43.0]) or not _layout.get("arrangements") is Array or _layout.arrangements.size() != 6 or not _layout.get("sources") is Array or _layout.sources.size() != 8 or not _layout.get("fixed_stones") is Array or _layout.fixed_stones.size() != 2:
		return "Canonical six-entry/five-beat shore layout required"
	var seen: Array[String] = []
	for index: int in range(ENTRY_IDS.size()):
		var entry: Variant = _layout.arrangements[index]
		if not entry is Dictionary or entry.get("id") != ENTRY_IDS[index] or entry.get("entry_index") != index or entry.get("entry_z") != ENTRY_Z[index] or entry.get("beat") != ENTRY_BEATS[index] or not entry.get("source_ids") is Array:
			return "Authored spatial entry order differs"
		for id: Variant in entry.source_ids:
			if not id is String or seen.has(id):
				return "Each actual owner requires one unique entry"
			seen.append(id)
	if seen.size() != 8 or not seen.has(PULSE_ID):
		return "Seven living sources and one bounded mechanism required"
	for id: String in ENEMY_IDS:
		if not seen.has(id):
			return "Canonical living source missing: " + id
	var rows_seen: Array[String] = []
	var counts: Dictionary = {"stalker": 0, "echo": 0, "environmental_mechanism": 0}
	for row: Variant in _layout.sources:
		if not row is Dictionary or not seen.has(row.get("id")) or row.get("kind") not in ["stalker", "echo", "environmental_mechanism"]:
			return "Supported owned source recipe required"
		var id: String = String(row.id)
		if rows_seen.has(id) or not SOURCE_ORIGINS.has(id):
			return "Each canonical owner requires one immutable recipe"
		rows_seen.append(id)
		counts[row.kind] += 1
		var entry: Dictionary = _layout.arrangements[seen_entry(id)]
		if row.get("arrangement_id") != entry.id:
			return "Source entitlement must match its actual spatial entry"
		if row.kind == "echo":
			if row.get("canonical_role_id") != "C52" or row.get("definition_id") != id + "/straight-return" or row.get("source_epoch_recipe") != "A3-L3/" + id + "/own-sequence" or not Value.is_vector3(row.get("definition_translation_world")) or Value.read_vector3(row.definition_translation_world) != SOURCE_ORIGINS[id] or not row.get("own_route_world") is Array or row.own_route_world.size() != 2:
				return "Immutable own-route C52 recipe required"
			for index: int in range(2):
				var point: Variant = row.own_route_world[index]
				if not point is Dictionary or not Value.is_vector3(point.get("position")) or Value.read_vector3(point.position) != SOURCE_ORIGINS[id] + Vector3(0, 0, -2.5 if index == 0 else -0.5) or point.get("at_s") != (0.0 if index == 0 else 0.3):
					return "Echo's measured two-metre own route/timing must remain unchanged"
			if not Value.is_vector3(row.get("fixed_knot_world")) or Value.read_vector3(row.fixed_knot_world) != SOURCE_ORIGINS[id] + Vector3(0, 0, -0.5) or row.get("slash_origin_world") != row.fixed_knot_world or not _layout_numbers_match(row.get("slash_direction_world"), [0.0, 0.0, 1.0]):
				return "Echo ordinary knot and native slash must bind its actual endpoint"
		elif not Value.is_vector3(row.get("position_world")) or Value.read_vector3(row.position_world) != SOURCE_ORIGINS[id]:
			return "Fixed canonical source position differs"
		elif row.kind == "stalker" and (row.get("canonical_role_id") != "C50" or id not in ["l3-threshold-stalker", "l3-priority-stalker"]):
			return "Two existing C50 sources required"
		elif row.kind == "environmental_mechanism" and (id != PULSE_ID or not row.get("geometry") is Dictionary or row.geometry.get("kind") != "circle" or row.geometry.get("origin_world") != row.position_world or row.geometry.get("radius_world") != 1.15 or row.geometry.get("damage_area") != "filled_disk" or not _layout_numbers_match(row.get("first_opening_world"), [1.9, 0.0, -20.35])):
			return "One bounded filled native disk and its actual first opening required"
	if counts != {"stalker": 2, "echo": 5, "environmental_mechanism": 1} or not _layout.get("floor") is Dictionary or not _layout_numbers_match(_layout.floor.get("size_world"), [14.0, 1.0, 108.0]) or not _layout_numbers_match(_layout.floor.get("center_world"), [0.0, -0.5, 0.0]) or not _layout_numbers_match(_layout.floor.get("safe_rect_xz"), [-7.0, -54.0, 14.0, 108.0]) or not _layout.get("contact_exit") is Dictionary or _layout.contact_exit.get("id") != EXIT_ID or _layout.contact_exit.get("completion_id") != COMPLETION_ID or not _layout_numbers_match(_layout.contact_exit.get("position_world"), [0.0, 0.1, -47.0]) or not _layout_numbers_match(_layout.contact_exit.get("rect_xz"), [-1.2, -47.65, 2.4, 1.3]):
		return "Original inventory, continuous support and contact threshold required"
	for index: int in range(2):
		var stone: Variant = _layout.fixed_stones[index]
		var expected: Vector3 = Vector3(-2.95, 0.8, 8.6) if index == 0 else Vector3(2.95, 0.8, -3.4)
		if not stone is Dictionary or stone.get("id") != ("useful-west-stone" if index == 0 else "useful-east-stone") or not Value.is_vector3(stone.get("position_world")) or Value.read_vector3(stone.position_world) != expected or not _layout_numbers_match(stone.get("size_world"), [0.8, 1.6, 1.2]):
			return "The two fixed matching shore stones must retain their actual geometry"
	return ""


func _layout_numbers_match(value: Variant, expected: Array) -> bool:
	# Standard authored JSON decodes every number as float. Array equality keeps
	# element types, so compare each finite numeric value exactly at this input
	# boundary. This does not normalize snapshots, change geometry or add epsilon.
	if not value is Array or value.size() != expected.size():
		return false
	for index: int in range(expected.size()):
		if not Value.is_number(value[index]) or float(value[index]) != float(expected[index]):
			return false
	return true


func seen_entry(id: String) -> int:
	for index: int in range(_layout.arrangements.size()):
		if _layout.arrangements[index].source_ids.has(id):
			return index
	return -1


func contract_error() -> String:
	var error: String = super.contract_error()
	return last_configuration_error if error.is_empty() else error


func _build_stone(row: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = String(row.id).replace("-", "_")
	body.position = Value.read_vector3(row.position_world)
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Solid"
	var shape := BoxShape3D.new()
	shape.size = Value.read_vector3(row.size_world)
	collision.shape = shape
	body.add_child(collision)
	var view := MeshInstance3D.new()
	view.name = "FixedVisibleShoreStone"
	var box := BoxMesh.new()
	box.size = shape.size
	view.mesh = box
	view.material_override = _quiet_material(Color("504556"))
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(view)
	add_child(body)
	_stones[String(row.id)] = {"body": body, "collision": collision, "shape": shape, "transform": body.global_transform, "size": shape.size, "view": view, "mesh": box, "material": view.material_override}


func _on_enter_level() -> void:
	if not last_configuration_error.is_empty():
		_update_presentation()
		return
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_plan") or not shared_shell.has_method("camera_framing_error"):
		_fail("Actual shared shell and native presentation services required")
		return
	_profile = String(shared_shell.call("get_difficulty_preference")) if shared_shell.has_method("get_difficulty_preference") else "standard"
	if not threat_scheduler.begin_encounter(_profile, ENCOUNTER_ID, WORLD_REVISION):
		_fail(threat_scheduler.last_error)
		return
	_active = true
	scenery.call("show_sun", 0, "stable") # Quiet two-sun scenery, no new transition mechanic.
	_update_presentation()


func _physics_process(_delta: float) -> void:
	if not _active or not is_instance_valid(hero):
		return
	_update_presentation() # Required native presentation also finishes a fatal tick.
	if not last_configuration_error.is_empty() or hero.dead:
		return
	var error: String = runtime_error()
	if not error.is_empty():
		_fail(error)
		return
	if _advance_entry():
		return # Newly installed owners cannot process until the next native tick.
	_dispatch_pending_checkpoint()
	_pending_view.clear()
	_step_ring()
	for id: String in ENEMY_IDS:
		if sources.has(id) and _rows[id].kind == "echo":
			_step_echo(id)
	if _all_cleared() and not is_completed():
		_exit_state = "available"
		request_completion(COMPLETION_ID)
		_update_presentation()
	if is_completed() and _exit_state == "available" and _capsule_in_rect(EXIT_RECT) and _view_guard(EXIT_ID, true).is_empty():
		_contact = {"clock_s": threat_scheduler.get_clock(), "hero_position": Value.vector3(hero.global_position)}
		_exit_state = "active"
		_update_presentation()
	if _exit_state == "active" and not _exit_queued:
		_exit_queued = true
		_dispatch_exit.bind(_exit_generation).call_deferred()


func _guard_before_consumers() -> void:
	if not _active or _pre_consumer_guard_busy or not is_inside_tree() or is_queued_for_deletion() or get_tree().paused or not is_instance_valid(hero) or hero.dead or not last_configuration_error.is_empty() or not is_instance_valid(threat_scheduler) or threat_scheduler.reservations().is_empty():
		return
	_pre_consumer_guard_busy = true
	# The pending candidate is unadmitted display metadata. It must not cancel
	# an existing exchange; this guard uses every actual held required group.
	var union: Dictionary = camera_framing_union("", [], true, false)
	var error: String = String(union.error)
	if error.is_empty():
		error = "Complete actual held source/cue/witness union unavailable" if union.points.is_empty() else String(shared_shell.call("camera_framing_error", union.points))
	last_camera_error = error
	if not error.is_empty():
		for id: String in ENEMY_IDS:
			if not _active:
				break
			if not sources.has(id) or not is_instance_valid(sources[id]):
				continue
			var source: Node3D = sources[id]
			var actual: Dictionary = source.call("state")
			if _rows[id].kind == "echo" and actual.get("status") == "running":
				source.call("cancel", "mirror_parent_pre_consumer_echo_view_unreadable")
			elif _rows[id].kind == "stalker" and not String(actual.get("reservation_id", "")).is_empty():
				# Cancel the lease rather than the owner: preserve its real cooldown.
				threat_scheduler.cancel(String(actual.reservation_id), "mirror_parent_pre_consumer_stalker_view_unreadable")
		if _active and is_instance_valid(mechanism) and mechanism.state().status == "running":
			mechanism.cancel("mirror_parent_pre_consumer_pulse_view_unreadable")
	else:
		# Commit due leases after the real Hero/Scheduler/current-view gate, but
		# BEFORE automatic Playback110 consumes this same native tick. A lock
		# after Playback would leave a locked lease with an unarmed cursor at
		# the supported end-of-tick capture boundary. No deadline is shifted.
		for id: String in ENEMY_IDS:
			if not _active or hero.dead or not last_configuration_error.is_empty(): break
			if sources.has(id) and is_instance_valid(sources[id]) and _rows[id].kind == "echo":
				_commit_due_echo(id)
	_pre_consumer_guard_busy = false


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
	if not _view_guard(id, true).is_empty(): source.call("cancel", "mirror_parent_locked_echo_view_unreadable")


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


func _advance_entry() -> bool:
	if _entries.size() == ENTRY_IDS.size() or not _capsule_in_rect(FLOOR_RECT):
		return false
	var body: Dictionary = _capsule()
	var index: int = _entries.size()
	# Teaching order is earned by genuine prior clear, without closing the
	# continuous floor. Running ahead installs nothing: return and finish the
	# real current source. The final two living targets are installed together.
	if not _previous_entry_clear(index):
		return false
	if float(body.center.z) + float(body.radius) > ENTRY_Z[index]:
		return false
	for id: String in _layout.arrangements[index].source_ids:
		if not _install_source(id):
			return false
	var receipt: Dictionary = {"id": ENTRY_IDS[index], "beat": ENTRY_BEATS[index], "clock_s": threat_scheduler.get_clock(), "hero_position": Value.vector3(hero.global_position), "capsule_radius": body.radius}
	_entries.append(receipt)
	_pending_boundaries.append(receipt.duplicate(true))
	# Defer actual dispatch until the next complete native current-view boundary.
	_update_presentation()
	return true


func _previous_entry_clear(index: int) -> bool:
	if index == 0:
		return true
	if not threat_scheduler.reservations().is_empty():
		return false
	for id: String in _layout.arrangements[index - 1].source_ids:
		if id == PULSE_ID:
			if not is_instance_valid(mechanism) or _ring_stage != "terminal" or mechanism.state().status != "complete":
				return false
			continue
		if not _deaths.has(id) or not sources.has(id) or not bool(sources[id].get("dead")) or float(sources[id].get("hp")) != 0.0 or sources[id].is_in_group("enemies"):
			return false
		if _rows[id].kind == "echo" and ((sources[id].call("state") as Dictionary).has("pending_delivery") or (sources[id].call("get_authored_cycle_terminal_receipt") as Dictionary).is_empty()):
			return false
	return true


func _install_source(id: String, prepare_managed: bool = true) -> bool:
	if sources.has(id) or (id == PULSE_ID and is_instance_valid(mechanism)):
		_fail("Spatial entry cannot configure a duplicate owner: " + id)
		return false
	var row: Dictionary = _rows[id]
	if row.kind == "environmental_mechanism":
		return _install_pulse(row)
	var source: Node3D = Stalker.new() if row.kind == "stalker" else Echo.new()
	source.name = id.replace("-", "_")
	add_child(source)
	sources[id] = source
	if row.kind == "stalker":
		source.global_position = Value.read_vector3(row.position_world)
		if not source.call("configure", id, hero, effects, threat_scheduler, combat_response.bind(id)):
			_fail(id + ": " + String(source.get("last_error")))
			return false
		source.call("set_sun_visual", 0)
		var callback: Callable = _on_stalker_died.bind(id)
		_callbacks[id] = callback
		source.connect("died", callback)
		return true
	for method: String in MANAGED_METHODS:
		if not source.has_method(method):
			_fail("Managed owned Echo port required before entry: " + method)
			return false
	var signature: Dictionary = Footprint.floor_signature(get_parent() as Node3D, [_floor])
	if not signature.get("accepted", false):
		_fail(String(signature.get("reason", "Native full shore signature unavailable")))
		return false
	var context: Dictionary = {"world_root": get_parent() as Node3D, "source_id": id, "source_epoch": String(row.source_epoch_recipe), "generation": 1, "world_collision_fingerprint": threat_scheduler.pure_collision_fingerprint(get_parent() as Node3D), "world_floor_signature": signature.signature}
	var prepared: Dictionary = {"world_revision": WORLD_REVISION, "collision_fingerprint": context.world_collision_fingerprint, "floor_signature": context.world_floor_signature}
	var definition: Dictionary = native_definition(id)
	if not source.call("configure_source", id, context.source_epoch, 1, definition, _profile, prepared, threat_scheduler) or not source.call("retain_source_environment", get_parent() as Node3D, [_floor]) or (prepare_managed and (not source.call("enable_authored_cycle_tracking", threat_scheduler, {"hero": hero}, [_floor], context) or not source.call("source_cycles_managed"))):
		_fail(id + ": " + String(source.get("source_snapshot_error")) + "; " + String(source.get("last_error")))
		return false
	_echo_records[id] = {"context": context, "projection": {}, "lease": {}, "proof": {}, "positions": [], "locked": false, "admissions": []}
	_build_reflection(id, Value.read_vector3(row.definition_translation_world))
	var callback: Callable = _on_echo_died.bind(id)
	_callbacks[id] = callback
	source.connect("died", callback)
	return true


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


func _install_pulse(row: Dictionary) -> bool:
	mechanism = Mechanism.new()
	mechanism.name = "SameBoundedResonanceSource"
	mechanism.position = Value.read_vector3(row.position_world)
	add_child(mechanism)
	var geometry: Dictionary = Shape.circle(mechanism.global_position, float(row.geometry.radius_world))
	if not mechanism.configure(PULSE_ID, geometry, Value.read_vector3(row.first_opening_world)) or not mechanism.bind(threat_scheduler, {"hero": hero}):
		_fail(mechanism.last_error)
		return false
	_mineral = MeshInstance3D.new()
	_mineral.name = "QuietMineralPulseSource"
	var box := BoxMesh.new()
	box.size = Vector3(0.22, 0.12, 0.22)
	_mineral.mesh = box
	_mineral.position.y = 0.06
	_mineral.material_override = _quiet_material(Color("787184"))
	mechanism.add_child(_mineral)
	_pulse_bounds = _geometry_bounds(geometry)
	mechanism.state_changed.connect(_on_pulse_phase)
	_set_ring_stage("pulse1_wait")
	return true


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


func pulse_response(cycle: int) -> Dictionary:
	var escaping: Array[Vector3] = [Vector3.LEFT]
	var returning: Array[Vector3] = [Vector3.RIGHT]
	if cycle == 2:
		escaping = [Vector3(1, 0, 1).normalized(), Vector3.BACK, Vector3.RIGHT, Vector3.LEFT]
		returning = [Vector3(-1, 0, -1).normalized(), Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]
	return {"encounter_id": ENCOUNTER_ID, "world_revision": WORLD_REVISION, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": escaping, "return_directions": returning, "floor_regions": [_floor]}


func _step_echo(id: String) -> void:
	var source: Node3D = sources[id]
	if bool(source.get("dead")) or hero.dead:
		return
	var data: Dictionary = _echo_records[id]
	var phase: String = String(source.call("source_phase"))
	var playback: Dictionary = source.call("state")
	if playback.get("status") == "running":
		if not _view_guard(id, true).is_empty():
			source.call("cancel", "mirror_parent_current_echo_view_unreadable")
			return
		return
	if id == "l3-resonant-echo" and _ring_stage not in ["echo_wait", "echo", "terminal"]:
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
		if id == "l3-resonant-echo" and _ring_stage == "echo":
			_set_ring_stage("echo_wait")
		return
	if playback.get("status") in ["idle", "cycle_ready"] and hero.is_on_floor() and hero.get_threat_response_state().get("stable", false) and threat_scheduler.reservations().is_empty():
		_try_echo(id)


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
		threat_scheduler.cancel(String(answer.reservation_id), "mirror_parent_projection_binding_failed")
		_fail(id + ": " + String(source.get("last_error")))
		return
	_bind_echo_cues(id)
	last_admission_reason = ""
	if id == "l3-resonant-echo" and _ring_stage == "echo_wait":
		_set_ring_stage("echo")


func _step_ring() -> void:
	if not is_instance_valid(mechanism):
		return
	var current: Dictionary = mechanism.state()
	if current.status == "running":
		if not _view_guard(PULSE_ID, true).is_empty():
			mechanism.cancel("mirror_parent_current_pulse_view_unreadable")
		return
	if _ring_stage in ["pulse1", "pulse2"]:
		if current.status == "cancelled":
			_set_ring_stage("pulse1_wait" if _ring_stage == "pulse1" else "pulse2_wait")
		elif current.status == "complete" and threat_scheduler.reservations().is_empty():
			_set_ring_stage("echo_wait" if _ring_stage == "pulse1" else "terminal")
	if _ring_stage == "echo" and sources.has("l3-resonant-echo"):
		var echo: Node3D = sources["l3-resonant-echo"]
		var terminal: Dictionary = echo.call("get_authored_cycle_terminal_receipt")
		var real_end: bool = echo.call("source_phase") == "complete" or (bool(echo.get("dead")) and not (echo.call("source_hit_receipts") as Array).is_empty())
		if real_end and not terminal.is_empty() and threat_scheduler.reservations().is_empty():
			_between_receipt = terminal.duplicate(true)
			_set_ring_stage("pulse2_wait")
	if _ring_stage in ["pulse1_wait", "pulse2_wait"] and hero.is_on_floor() and hero.get_threat_response_state().get("stable", false) and threat_scheduler.reservations().is_empty():
		_try_pulse(1 if _ring_stage == "pulse1_wait" else 2)


func _try_pulse(cycle: int) -> void:
	if cycle == 2 and _between_receipt.is_empty():
		return
	# A genuinely reached retained knot survives ordinary death; no replacement
	# target or HP is manufactured. Native environmental proof still owns return.
	var opening: Vector3 = Value.read_vector3(_rows[PULSE_ID].first_opening_world) if cycle == 1 else (sources["l3-resonant-echo"] as Node3D).global_position
	var preview: Dictionary = mechanism.preview_start("hero", pulse_response(cycle), opening)
	if not preview.get("accepted", false):
		last_admission_reason = String(preview.get("reason", "Native pulse preview rejected"))
		return
	_pending_view = {"id": PULSE_ID, "kind": "pulse", "proof": preview.proof, "positions": _proof_positions(preview.proof)}
	if not _view_guard(PULSE_ID, false).is_empty() or not _view_guard(PULSE_ID, true).is_empty():
		return
	var answer: Dictionary = mechanism.start("hero", pulse_response(cycle), opening, null, preview)
	if not answer.get("accepted", false):
		last_admission_reason = String(answer.get("reason", "Native pulse admission rejected"))
		return
	_pulse_proofs[str(cycle)] = answer.proof.duplicate(true)
	_pulse_exchanges[str(cycle)] = answer.reservation.duplicate(true)
	_pulse_view = _proof_positions(answer.proof)
	_pending_view.clear()
	_set_ring_stage("pulse%d" % cycle)
	last_admission_reason = ""


func _set_ring_stage(stage: String) -> void:
	_ring_stage = stage
	_ring_history.append({"id": stage, "clock_s": threat_scheduler.get_clock()})


func _camera_framing_points() -> Array:
	if not _active:
		return []
	var union: Dictionary = camera_framing_union()
	last_camera_framing_error = String(union.error)
	return union.points.duplicate() if last_camera_framing_error.is_empty() else []


## All held required native groups plus ONE fresh, display-only prospective
## selection. Enclosing boxes use every original corner, never trimmed points.
func camera_framing_union(candidate_id: String = "", candidate_points: Array = [], current_view: bool = false, include_pending: bool = true) -> Dictionary:
	if not last_configuration_error.is_empty() or not is_instance_valid(shared_shell) or not is_instance_valid(hero):
		return _bounds_error("Actual configured parent/Hero/presentation bindings required")
	if not candidate_id.is_empty() and (not sources.has(candidate_id) and candidate_id != PULSE_ID):
		return _bounds_error("Prospective view requires an installed actual owner")
	if candidate_id.is_empty() and not candidate_points.is_empty():
		return _bounds_error("Prospective points require the real source ID")
	var points: Array = []
	if not candidate_id.is_empty():
		if candidate_points.is_empty():
			return _bounds_error("Complete prospective native corners required")
		var candidate: Dictionary = _enclosure(candidate_points)
		if not String(candidate.error).is_empty():
			return candidate
		points.append_array(candidate.points)
	for id: String in ENEMY_IDS:
		if id == candidate_id or not sources.has(id):
			continue
		var source: Node3D = sources[id]
		var actual: Dictionary = source.call("state")
		if _rows[id].kind == "stalker":
			if String(actual.get("reservation_id", "")).is_empty():
				continue
			var bounds: Dictionary = source.call("camera_framing_points", shared_shell, {}, {}, current_view)
			if not String(bounds.get("error", "Actual Stalker render bounds required")).is_empty():
				return _bounds_error(id + ": " + String(bounds.error))
			var enclosing: Dictionary = _enclosure(bounds.points)
			if not String(enclosing.error).is_empty():
				return enclosing
			points.append_array(enclosing.points)
		elif actual.get("status") == "running":
			var bounds: Dictionary = _echo_bounds(id)
			if not String(bounds.error).is_empty():
				return bounds
			points.append_array(bounds.points)
	if candidate_id != PULSE_ID and is_instance_valid(mechanism) and mechanism.state().status == "running":
		var bounds: Dictionary = _pulse_render_bounds(_pulse_view)
		if not String(bounds.error).is_empty():
			return bounds
		points.append_array(bounds.points)
	if include_pending and candidate_id.is_empty() and not _pending_view.is_empty():
		var id: String = String(_pending_view.id)
		if sources.has(id) and sources[id].call("state").get("status") != "running":
			var bounds: Dictionary = _echo_bounds(id, _pending_view)
			if not String(bounds.error).is_empty():
				return bounds
			points.append_array(bounds.points)
		elif id == PULSE_ID and is_instance_valid(mechanism) and mechanism.state().status != "running":
			var bounds: Dictionary = _pulse_render_bounds(_pending_view.positions)
			if not String(bounds.error).is_empty():
				return bounds
			points.append_array(bounds.points)
	if _exit_state != "clear":
		var contact: Dictionary = _contact_bounds()
		if not String(contact.error).is_empty():
			return contact
		points.append_array(contact.points)
	if points.size() > 224:
		return _bounds_error("Complete held native union exceeds shared point bound")
	return {"error": "", "points": points}


func _view_guard(id: String, current: bool) -> String:
	var candidate: Dictionary = {}
	if not _pending_view.is_empty() and _pending_view.id == id:
		candidate = _echo_bounds(id, _pending_view) if _pending_view.kind == "echo" else _pulse_render_bounds(_pending_view.positions)
	var union: Dictionary = camera_framing_union(id, candidate.points, current) if not candidate.is_empty() and String(candidate.error).is_empty() else camera_framing_union("", [], current)
	if not candidate.is_empty() and not String(candidate.error).is_empty():
		last_camera_error = String(candidate.error)
	elif not String(union.error).is_empty():
		last_camera_error = String(union.error)
	elif union.points.is_empty():
		last_camera_error = "Complete actual source/cue/witness union unavailable"
	elif current:
		last_camera_error = String(shared_shell.call("camera_framing_error", union.points))
	else:
		var plan: Dictionary = shared_shell.call("camera_framing_plan", union.points, hero.global_position + Vector3.UP * 0.75)
		last_camera_error = "" if plan.get("accepted", false) else String(plan.get("reason", "Complete native prospective union does not fit"))
	return last_camera_error


func _echo_bounds(id: String, prospective: Dictionary = {}, framing_camera: Camera3D = null) -> Dictionary:
	var source: Node3D = sources[id]
	var art: Dictionary = source.call("framing_points")
	if not String(art.get("error", "Actual native Echo art bounds unavailable")).is_empty():
		return _bounds_error(id + ": " + String(art.error))
	var points: Array = art.points.duplicate()
	var data: Dictionary = _echo_records[id] if prospective.is_empty() else prospective
	var projection: Dictionary = data.get("projection", {})
	if projection.is_empty():
		return _bounds_error("Actual complete projected Echo footprint required: " + id)
	for event: Dictionary in projection.events:
		if not event.get("bounds") is Array or event.bounds.size() != 4:
			return _bounds_error("Native Echo projected footprint bounds unavailable")
		for x: float in [float(event.bounds[0]), float(event.bounds[2])]:
			for z: float in [float(event.bounds[1]), float(event.bounds[3])]:
				points.append(Vector3(x, float(event.floor_y) + CinderThreatCue.FLOOR_OFFSET, z))
	# Whole actual future source glyphs, including a not-yet-visible phase.
	var origin: Vector3 = (source.call("source_definition") as Dictionary).slash.world_origin
	for phase: String in ["warning", "lock", "active", "recovery"]:
		_append_mesh(points, CueMeshes.source_mesh(phase), Transform3D(Basis.IDENTITY, origin + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004)))
	for cue: Node3D in source.call("get_cues"):
		_append_cue(points, cue)
	var route: MeshInstance3D = source.get_node_or_null("ExactHarmlessRoutes") as MeshInstance3D
	if route != null and route.is_visible_in_tree() and route.mesh != null:
		_append_mesh(points, route.mesh, route.global_transform)
	if not is_instance_valid(_reflections.get(id)):
		return _bounds_error("Distinct actual harmless outline required: " + id)
	for child: Node in _reflections[id].get_children():
		var view: MeshInstance3D = child as MeshInstance3D
		if view == null or not view.is_visible_in_tree() or view.mesh == null:
			return _bounds_error("Actual complete harmless outline geometry required")
		_append_mesh(points, view.mesh, view.global_transform)
	var error: String = _append_hero_forecasts(points, data.get("positions", []), framing_camera)
	return _enclosure(points) if error.is_empty() else _bounds_error(error)


func _pulse_render_bounds(positions: Array, framing_camera: Camera3D = null) -> Dictionary:
	if not is_instance_valid(_mineral) or not is_instance_valid(mechanism) or not _mineral.is_visible_in_tree() or _mineral.mesh == null:
		return _bounds_error("Actual complete mineral pulse source required")
	var points: Array = _pulse_bounds.duplicate()
	_append_mesh(points, _mineral.mesh, _mineral.global_transform)
	_append_cue(points, mechanism.get_cue())
	var error: String = _append_hero_forecasts(points, positions, framing_camera)
	return _enclosure(points) if error.is_empty() else _bounds_error(error)


func _geometry_bounds(geometry: Dictionary) -> Array:
	var points: Array = []
	var origin: Vector3 = geometry.origin
	for filled: bool in [false, true]:
		_append_mesh(points, CueMeshes.geometry_mesh(geometry, filled), Transform3D(Basis.IDENTITY, origin + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET if not filled else CinderThreatCue.FLOOR_OFFSET - 0.004)))
	for phase: String in ["warning", "lock", "active", "recovery"]:
		_append_mesh(points, CueMeshes.source_mesh(phase), Transform3D(Basis.IDENTITY, origin + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004)))
	return points


func _proof_positions(proof: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for segment: Dictionary in proof.get("path", []):
		for key: String in ["from", "to"]:
			var point: Variant = segment.get(key)
			if point is Vector3 and not points.has(point):
				points.append(point)
	return points


func _append_hero_forecasts(points: Array, positions: Array, framing_camera: Camera3D = null) -> String:
	var native: Array = shared_shell.call("player_camera_framing_points_for", hero, framing_camera) if framing_camera != null else shared_shell.call("player_camera_framing_points")
	if native.is_empty() or positions.is_empty():
		return "Complete real Hero corners and native selected response path required"
	for position: Variant in positions:
		if not position is Vector3 or not position.is_finite():
			return "Selected native path requires finite world positions"
		for corner: Vector3 in native:
			points.append(corner + position - hero.global_position)
	return "" # Display forecast only; Scheduler alone authorizes real actions.


func _append_cue(points: Array, cue: Node3D) -> void:
	if not is_instance_valid(cue):
		return
	for label: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
		var view: MeshInstance3D = cue.get_node_or_null(label) as MeshInstance3D
		if view != null and view.is_visible_in_tree() and view.mesh != null:
			_append_mesh(points, view.mesh, view.global_transform)


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


func _contact_bounds() -> Dictionary:
	if not is_instance_valid(exit_cue) or exit_cue.state().get("state") != _exit_state:
		return _bounds_error("Actual contact state/marker required")
	var view: MeshInstance3D = exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if view == null or not view.is_visible_in_tree() or view.mesh == null:
		return _bounds_error("Actual full visible contact geometry required")
	var points: Array = []
	_append_mesh(points, view.mesh, view.global_transform)
	for x: float in [EXIT_RECT.position.x, EXIT_RECT.end.x]:
		for z: float in [EXIT_RECT.position.y, EXIT_RECT.end.y]:
			points.append(Vector3(x, 0, z))
	return _enclosure(points)


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
		sources[id].call("cancel", "mirror_parent_required_echo_cue_view_unreadable")


func _on_pulse_phase(current: Dictionary) -> void:
	if _active and not _pre_consumer_guard_busy and current.status == "running" and current.phase in ["lock", "active", "recovery"] and not _view_guard(PULSE_ID, true).is_empty():
		mechanism.cancel("mirror_parent_required_pulse_view_unreadable")


func _on_stalker_died(_where: Vector3, id: String) -> void:
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
	# Retain the actual node and Playback's terminal settlement after death.
	_update_presentation()


func _all_cleared() -> bool:
	if _entries.size() != 6 or _deaths.size() != 7 or _ring_stage != "terminal" or not threat_scheduler.reservations().is_empty():
		return false
	for id: String in ENEMY_IDS:
		if not sources.has(id) or not bool(sources[id].get("dead")) or float(sources[id].get("hp")) != 0.0:
			return false
		if _rows[id].kind == "echo":
			var playback: Dictionary = sources[id].call("state")
			if playback.has("pending_delivery") or (sources[id].call("get_authored_cycle_terminal_receipt") as Dictionary).is_empty():
				return false
	return true


func _dispatch_exit(generation: int) -> void:
	if generation != _exit_generation:
		return
	_exit_queued = false
	if not _active or hero.dead or not is_completed() or not _all_cleared() or _exit_state != "active":
		return
	_exit_state = "spent"
	if not request_contact_exit(EXIT_ID, hero):
		_exit_state = "available"
		_contact.clear()
	_update_presentation()


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


func _update_presentation(quiet: bool = false) -> void:
	if is_instance_valid(hero) and is_instance_valid(scenery):
		# Keep the ordinary-depth horizon behind this authored court's whole
		# route, including a rear escape. A HeroZ follower masks its start.
		# This scenery-only anchor never activates/constructs a future source.
		var court_index: int = maxi(0, _entries.size() - 1)
		var court_z: float = float(_layout.arrangements[court_index].court_origin_world[2])
		scenery.call("follow_landmarks", Vector3(hero.global_position.x, 0, court_z + 0.4))
	if is_instance_valid(exit_cue):
		var silent_objects: Array[Object] = [exit_cue]
		var signal_flags: Array[bool] = []
		if quiet:
			# Preserve the actual native cue, child visibility and existing
			# material observers through derived reconstruction.
			for child: Node in exit_cue.get_children():
				silent_objects.append(child)
				if child is MeshInstance3D and child.material_override != null:
					silent_objects.append(child.material_override)
			for object: Object in silent_objects:
				signal_flags.append(object.is_blocking_signals())
				object.set_block_signals(true)
		if _exit_state == "clear":
			exit_cue.clear()
		else:
			exit_cue.present(_exit_state, "contact")
		if quiet:
			for index: int in range(silent_objects.size()):
				silent_objects[index].set_block_signals(signal_flags[index])
	if not last_configuration_error.is_empty():
		objective_text = "MIRROR SEA UNAVAILABLE\n" + last_configuration_error
	elif _exit_state != "clear":
		objective_text = "THE SHORE FALLS SILENT\nCONTACT THE DRY THRESHOLD"
	elif _entries.is_empty():
		objective_text = "SHORE AND DOUBLED SKY\nFOLLOW THE FILLED DRY SHELF"
	elif _entries.size() == 1:
		objective_text = "ONE FAMILIAR CREST\nDASH CLEAR / TAP THE LOW FLANK"
	elif _entries.size() == 5:
		objective_text = "ONE DISK / ONE REAL BODY\nREAD EACH SOURCE / RETURN TO THE KNOT"
	elif _entries.size() == 6:
		objective_text = "CHOOSE THE USEFUL TARGET\nDASH CLEAR / TAP THE REAL OPENING"
	else:
		objective_text = "ONE REAL ECHO\nREAD ITS ROUTE / TAP THE GROUNDED KNOT"


func _fail(reason: String) -> void:
	last_configuration_error = reason
	if is_instance_valid(mechanism):
		mechanism.cancel("mirror_parent_invalid")
	for id: String in sources:
		if _rows[id].kind == "echo":
			sources[id].call("cancel", "mirror_parent_invalid")
		else:
			threat_scheduler.cancel_owner(sources[id], "mirror_parent_invalid")
	_update_presentation()


func runtime_error() -> String:
	if not last_configuration_error.is_empty():
		return last_configuration_error
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not is_instance_valid(threat_scheduler) or threat_scheduler.get_script() != Scheduler or threat_scheduler.get_parent() != self or not is_instance_valid(scenery) or scenery.get_script() != Shore or scenery.get_parent() != self:
		return "Actual shared Hero, retained shore and continuous Scheduler required"
	if not is_instance_valid(_view_observer) or _view_observer.get_parent() != self or _view_observer.observe != _guard_before_consumers or not _view_observer.is_physics_processing() or _view_observer.process_mode != Node.PROCESS_MODE_PAUSABLE or _view_observer.process_physics_priority != 90 or hero.process_physics_priority >= 90 or threat_scheduler.process_physics_priority >= 90:
		return "Actual pausable required-view observer must precede stationary contact"
	var error: String = scenery.call("runtime_error")
	if not error.is_empty():
		return error
	error = _vignette_root_error()
	if not error.is_empty():
		return error
	for id: String in _stones:
		var spec: Dictionary = _stones[id]
		var body: StaticBody3D = spec.body
		if not is_instance_valid(body) or body.get_parent() != self or body.global_transform != spec.transform or body.collision_layer != 1 or body.collision_mask != 0 or not is_instance_valid(spec.collision) or spec.collision.disabled or spec.collision.shape != spec.shape or spec.shape.size != spec.size or not is_instance_valid(spec.view) or not spec.view.is_visible_in_tree() or spec.view.mesh != spec.mesh or spec.view.material_override != spec.material:
			return "Actual permanent visible shore stone differs: " + id
	for id: String in sources:
		var source: Node3D = sources[id]
		if not is_instance_valid(source) or source.is_queued_for_deletion() or source.get_parent() != self or not source.is_inside_tree():
			return "Retained actual source required: " + id
		if _rows[id].kind == "echo":
			if source.get_script() != Echo:
				return "Actual owned Echo script required: " + id
			error = String(source.call("source_native_error"))
			if not error.is_empty():
				return id + ": " + error
		elif source.get_script() != Stalker:
			return "Actual owned Stalker script required: " + id
	if is_instance_valid(mechanism) and (mechanism.get_script() != Mechanism or mechanism.get_parent() != self or mechanism.global_transform != Transform3D(Basis.IDENTITY, Value.read_vector3(_rows[PULSE_ID].position_world)) or not is_instance_valid(_mineral) or _mineral.get_parent() != mechanism or not _mineral.is_visible_in_tree() or not _mineral.mesh is BoxMesh):
		return "Retained actual fixed mineral mechanism required"
	return ""


## Cheap retained-root custody only. Never193 native property/texture hashes
## from physics, admission, contact or the ordinary camera follow callback.
func _vignette_root_error() -> String:
	if not is_instance_valid(vignettes) or vignettes.get_instance_id() != _vignette_instance_id or vignettes.get_script() != Vignettes or vignettes.get_parent() != self or not vignettes.is_inside_tree() or not vignettes.is_node_ready() or vignettes.is_queued_for_deletion() or vignettes.get_world_3d() != _vignette_world or vignettes.get_world_3d() != get_world_3d() or vignettes.global_transform != Transform3D.IDENTITY or not vignettes.visible or vignettes.get_child_count() != _vignette_children or not vignettes.get_groups().is_empty() or vignettes.is_processing() or vignettes.is_physics_processing():
		return "Original static noninteractive vignette root required"
	return ""


## Finite native gate: build already validates; complete capture and saved
## candidate presentation recheck real buffers, textures, crops and resources.
## Its complete optional banks never enter mandatory combat/save view bounds.
func _vignette_full_error() -> String:
	var error: String = _vignette_root_error()
	return error if not error.is_empty() else String(vignettes.call("native_error"))


func scheduler_bindings() -> Dictionary:
	var owners: Dictionary = sources.duplicate()
	if is_instance_valid(mechanism):
		owners[PULSE_ID] = mechanism
	return {"world_root": get_parent() as Node3D, "owners": owners, "actors": {"hero": hero}, "floors": {"firm-shore": _floor}}


func state() -> Dictionary:
	var actual: Dictionary = {}
	for id: String in ENEMY_IDS:
		if sources.has(id):
			actual[id] = {"kind": _rows[id].kind, "installed": true, "source": sources[id].call("get_source_state") if _rows[id].kind == "echo" else sources[id].call("state"), "playback": sources[id].call("state") if _rows[id].kind == "echo" else {}}
		else:
			actual[id] = {"kind": _rows[id].kind, "installed": false}
	return {"api_revision": API, "clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else -1.0, "configuration_error": last_configuration_error, "admission_reason": last_admission_reason, "camera_error": last_camera_error, "route": {"entries": _entries.duplicate(true), "deaths": _deaths.duplicate(true), "pending_checkpoint_boundaries": _pending_boundaries.duplicate(true)}, "sources": actual, "ring": {"installed": is_instance_valid(mechanism), "stage": _ring_stage, "history": _ring_history.duplicate(true), "mechanism": mechanism.state() if is_instance_valid(mechanism) else {}, "proofs": _pulse_proofs.duplicate(true), "exchanges": _pulse_exchanges.duplicate(true), "between_receipt": _between_receipt.duplicate(true)}, "echo_records": _echo_records.duplicate(true), "completed": is_completed(), "exit_state": _exit_state, "contact": _contact.duplicate(true), "persistence_supported": true, "checkpoint_dispatch_supported": true}


func snapshot_state() -> Dictionary:
	return _capture_checked(null, null)


## Shared36 ordinary-fresh opt-in. Actual native receiver context is retained
## only for this synchronous owned call; Game aliases/focus are never replaced.
func snapshot_state_for_presentation(framing_camera: Camera3D, framing_hud: GameHUD) -> Dictionary:
	if is_restore_candidate():
		last_snapshot_error = "Explicit fresh capture cannot substitute for saved restoration"
		return {}
	if not is_instance_valid(framing_camera) or not is_instance_valid(framing_hud):
		last_snapshot_error = "Actual fresh native Camera/HUD pair required"
		return {}
	return _capture_checked(framing_camera, framing_hud)


func _capture_checked(framing_camera: Camera3D, framing_hud: GameHUD) -> Dictionary:
	if _owned_capture_busy:
		last_snapshot_error = "Owned checked writer cannot reenter"
		return {}
	if (framing_camera == null) != (framing_hud == null):
		last_snapshot_error = "Complete actual native presentation context required"
		return {}
	last_snapshot_error = _vignette_full_error()
	if not last_snapshot_error.is_empty(): return {}
	_owned_capture_busy = true
	_owned_capture_error = ""
	_owned_capture_camera = framing_camera
	_owned_capture_hud = framing_hud
	# Base retains lifecycle, snapshot-busy, complete value/local validation and
	# the original progression envelope. No header or busy exemption is added.
	var saved: Dictionary = super.snapshot_state()
	var capture_error: String = _owned_capture_error
	_owned_capture_error = ""
	_owned_capture_camera = null
	_owned_capture_hud = null
	_owned_capture_busy = false
	if saved.is_empty():
		# Preserve this synchronous native capture refusal after base validation
		# rejects its empty local unit. A call that never captured keeps base error.
		if not capture_error.is_empty(): last_snapshot_error = capture_error
		return {}
	last_snapshot_error = snapshot_error(saved)
	if last_snapshot_error.is_empty():
		last_snapshot_error = _parent_codec.live_presentation_error(self) if framing_camera == null else _parent_codec.candidate_presentation_error(self, framing_camera, framing_hud)
	return saved if last_snapshot_error.is_empty() else {}


func snapshot_error(saved: Dictionary) -> String:
	var error: String = super.snapshot_error(saved)
	return error if not error.is_empty() else _parent_codec.progress_error(saved.local, saved.progress, self)


func snapshot_error_with_player(saved: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(saved, saved_player)
	return error if not error.is_empty() else _parent_codec.progress_error(saved.local, saved.progress, self)


func restore_state(saved: Dictionary) -> bool:
	var error: String = snapshot_error(saved)
	if not error.is_empty():
		last_snapshot_error = error
		return false
	_owned_restore_error = ""
	var restored: bool = super.restore_state(saved)
	if not _owned_restore_error.is_empty():
		last_snapshot_error = _owned_restore_error
		return false # Shell disposes the entire failed native candidate.
	return restored


func _capture_local_state() -> Dictionary:
	var saved: Dictionary = _parent_codec.capture(self, hero.snapshot_state(), _owned_capture_camera, _owned_capture_hud)
	last_snapshot_error = _parent_codec.last_error
	if _owned_capture_busy: _owned_capture_error = last_snapshot_error
	return saved


func _local_snapshot_error(local: Dictionary) -> String:
	return _parent_codec.record_error(local, self, hero.snapshot_state())


func _local_snapshot_error_with_player(local: Dictionary, saved_player: Dictionary) -> String:
	return _parent_codec.record_error(local, self, saved_player)


func _restore_local_state(local: Dictionary) -> void:
	if not _parent_codec.restore_local(local, self, hero.snapshot_state()):
		_owned_restore_error = _parent_codec.last_error


func restore_candidate_construction_required() -> bool:
	return true


func _on_enter_restore_candidate(local: Dictionary, saved_player: Dictionary) -> String:
	_active = false
	if not local.get("world") is Dictionary or not local.world.get("profile_id") is String:
		return "Complete canonical saved world/profile recipe required"
	_profile = local.world.profile_id
	if not threat_scheduler.begin_encounter(_profile, ENCOUNTER_ID, WORLD_REVISION):
		return threat_scheduler.last_error
	var recipe: Dictionary = _parent_codec.constructor_recipe(local, self, saved_player)
	if not recipe.get("accepted", false):
		return String(recipe.get("error", "Immutable entitled constructor recipe refused"))
	for id: String in recipe.recipe.source_ids:
		if not _install_source(id, false):
			return last_configuration_error
	if recipe.recipe.mechanism_entitled and not _install_source(PULSE_ID, false):
		return last_configuration_error
	# All recipients are native immutable configuration only. Pure complete
	# Scheduler/source validation precedes every prospective Playback recipe.
	return _parent_codec.prepare_sources(local, self, saved_player)


func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	var error: String = _vignette_full_error()
	return error if not error.is_empty() else _parent_codec.candidate_presentation_error(self, camera, hud)


func mirror_sea_codec_checkpoint_ids() -> Array[String]:
	return ["mirror-sea-shore-entry", "mirror-sea-real-body-entry", "mirror-sea-useful-west-entry", "mirror-sea-useful-east-entry", "mirror-sea-resonant-entry", "mirror-sea-final-court-entry"]


func mirror_sea_codec_owned_state() -> Dictionary:
	var views: Dictionary = {}
	for id: String in _echo_records:
		var positions: Array = []
		for at: Vector3 in _echo_records[id].positions:
			positions.append(Value.vector3(at))
		views[id] = positions
	var pulses: Array = []
	for at: Vector3 in _pulse_view:
		pulses.append(Value.vector3(at))
	var exchanges: Dictionary = {}
	for label: String in _pulse_exchanges:
		exchanges[label] = ParentCodec.encode_pulse_exchange(_pulse_exchanges[label])
	return {"route": {"entries": _entries.duplicate(true), "deaths": _deaths.duplicate(true), "pending_checkpoint_boundaries": _pending_boundaries.duplicate(true), "exit_state": _exit_state, "contact": _contact.duplicate(true)}, "ring": {"stage": _ring_stage, "history": _ring_history.duplicate(true), "exchanges": exchanges, "between_receipt": _between_receipt.duplicate(true), "mechanism": {}}, "view": {"echoes": views, "pulse": pulses}}


func mirror_sea_codec_framing_union(framing_camera: Camera3D = null) -> Dictionary:
	var camera: Camera3D = framing_camera if framing_camera != null else shared_shell.get("camera") as Camera3D
	var native: Array = shared_shell.call("player_camera_framing_points_for", hero, camera)
	if native.is_empty():
		return _bounds_error("Actual current Hero/native context camera bounds required")
	var points: Array = native.duplicate()
	var court_ids: Array = [] if _entries.is_empty() else _layout.arrangements[_entries.size() - 1].source_ids.duplicate()
	for id: String in sources:
		var source: Node3D = sources[id]
		var actual: Dictionary = source.call("state")
		var held: bool = actual.get("status") == "running" if _rows[id].kind == "echo" else not String(actual.get("reservation_id", "")).is_empty()
		if not held and not court_ids.has(id):
			continue # Remote inactive history is still mechanically retained.
		var bounds: Dictionary
		if _rows[id].kind == "stalker":
			bounds = source.call("camera_framing_points_for_context", shared_shell, hero, camera, {}, {}, true) if held else source.call("current_render_framing_points_for_context", shared_shell, hero, camera)
		elif held:
			bounds = _echo_bounds(id, {}, camera)
		else:
			bounds = _current_echo_render_bounds(id)
		if not String(bounds.get("error", "Native current-court source bounds unavailable")).is_empty():
			return _bounds_error(id + ": " + String(bounds.error))
		if bounds.get("points", []).is_empty():
			if _rows[id].kind == "stalker" and bool(source.get("dead")) and not held:
				continue # Getter validated the genuinely hidden retired body/cue.
			return _bounds_error(id + ": Incomplete current native source group")
		var group: Dictionary = _enclosure(bounds.points)
		if not group.error.is_empty():
			return group
		points.append_array(group.points)
	if is_instance_valid(mechanism) and (court_ids.has(PULSE_ID) or mechanism.state().status == "running"):
		var pulse: Dictionary = _pulse_render_bounds(_pulse_view, camera) if mechanism.state().status == "running" else _current_pulse_render_bounds()
		if not pulse.error.is_empty():
			return pulse
		points.append_array(pulse.points)
	if not _entries.is_empty():
		for row: Dictionary in _layout.fixed_stones:
			if row.arrangement_id != ENTRY_IDS[_entries.size() - 1]:
				continue
			var spec: Dictionary = _stones[row.id]
			var stone: Array = []
			_append_mesh(stone, spec.mesh, spec.view.global_transform)
			points.append_array((_enclosure(stone) as Dictionary).points)
	if _exit_state != "clear":
		var contact: Dictionary = _contact_bounds()
		if not contact.error.is_empty():
			return contact
		points.append_array(contact.points)
	return _bounds_error("Complete current native union exceeds224corners") if points.size() > 224 else {"error": "", "points": points}


func _current_echo_render_bounds(id: String) -> Dictionary:
	var art: Dictionary = sources[id].call("framing_points")
	if not String(art.get("error", "Actual native Echo art unavailable")).is_empty():
		return _bounds_error(id + ": " + String(art.error))
	var points: Array = art.points.duplicate()
	if not is_instance_valid(_reflections.get(id)):
		return _bounds_error("Retained harmless outline required: " + id)
	for child: Node in _reflections[id].get_children():
		var visual: MeshInstance3D = child as MeshInstance3D
		if visual == null or not visual.is_visible_in_tree() or visual.mesh == null:
			return _bounds_error("Complete actual harmless outline group required")
		_append_mesh(points, visual.mesh, visual.global_transform)
	for cue: Node3D in sources[id].call("get_cues"):
		_append_cue(points, cue)
	var route: MeshInstance3D = sources[id].get_node_or_null("ExactHarmlessRoutes") as MeshInstance3D
	if route != null and route.is_visible_in_tree() and route.mesh != null:
		_append_mesh(points, route.mesh, route.global_transform)
	return _enclosure(points)


func _current_pulse_render_bounds() -> Dictionary:
	if not is_instance_valid(mechanism) or not is_instance_valid(_mineral) or not _mineral.is_visible_in_tree() or _mineral.mesh == null:
		return _bounds_error("Actual retained mineral source required")
	var points: Array = []
	_append_mesh(points, _mineral.mesh, _mineral.global_transform)
	_append_cue(points, mechanism.get_cue())
	return _enclosure(points)


func _dispatch_pending_checkpoint() -> void:
	if _pending_boundaries.is_empty() or not _active or hero.dead or is_restore_candidate() or is_completed():
		return
	var union: Dictionary = mirror_sea_codec_framing_union()
	if not union.error.is_empty() or not String(shared_shell.call("camera_framing_error", union.points)).is_empty():
		return # A future camera fit never earns a protected actual-world view.
	var boundary: Dictionary = _pending_boundaries.pop_front()
	var index: int = -1
	for candidate: int in range(_entries.size()):
		if Authored.exact_equal(_entries[candidate], boundary):
			index = candidate
			break
	if index < 0 or not request_checkpoint(mirror_sea_codec_checkpoint_ids()[index], "encounter"):
		_pending_boundaries.push_front(boundary)
	# Remove before synchronous observers capture native progress. A successful
	# request records delivery; the Shell independently owns actual protection.


func mirror_sea_codec_apply_owned_state(owned: Dictionary) -> String:
	_entries.clear()
	for receipt: Dictionary in owned.route.entries:
		_entries.append(receipt.duplicate(true))
	_deaths = owned.route.deaths.duplicate(true)
	_pending_boundaries.clear()
	for receipt: Dictionary in owned.route.pending_checkpoint_boundaries:
		_pending_boundaries.append(receipt.duplicate(true))
	_exit_state = owned.route.exit_state
	_contact = owned.route.contact.duplicate(true)
	_ring_stage = owned.ring.stage
	_ring_history.clear()
	for receipt: Dictionary in owned.ring.history:
		_ring_history.append(receipt.duplicate(true))
	_between_receipt = owned.ring.between_receipt.duplicate(true)
	_pulse_exchanges.clear()
	for label: String in owned.ring.exchanges:
		_pulse_exchanges[label] = ParentCodec.decode_pulse_exchange(owned.ring.exchanges[label])
	_pulse_view.clear()
	for at: Array in owned.view.pulse:
		_pulse_view.append(Value.read_vector3(at))
	var world: Dictionary = ParentCodec.native_world(self)
	for id: String in _echo_records:
		var source: Node3D = sources[id]
		var positions: Array[Vector3] = []
		for at: Array in owned.view.echoes[id]:
			positions.append(Value.read_vector3(at))
		var actual: Dictionary = source.call("state")
		_echo_records[id].context = ParentCodec.echo_context(world, self, id, int(source.call("get_authored_cycle_generation")))
		_echo_records[id].projection = source.call("get_footprint_projection")
		_echo_records[id].lease = threat_scheduler.replay_reservation_state(String(actual.get("reservation_id", ""))) if actual.get("status") == "running" else {}
		_echo_records[id].positions = positions
		_echo_records[id].locked = bool(_echo_records[id].lease.get("adapter", {}).get("locked", false))
		_echo_records[id].proof = {}
		_echo_records[id].admissions = [] # Diagnostic only, not transported authority.
		_bind_echo_cues(id)
	_pending_view.clear()
	_pulse_proofs.clear()
	_exit_generation += 1
	_exit_queued = false
	_active = true # Still paused/nonplayable until Shell finishes its real gate.
	_update_presentation(true)
	return runtime_error()


func _on_exit_level() -> void:
	var discarded_candidate: bool = is_restore_candidate()
	_active = false
	if is_instance_valid(_view_observer):
		_view_observer.set_physics_process(false)
	_exit_generation += 1
	_exit_queued = false
	for entry: Dictionary in _cue_callbacks:
		if is_instance_valid(entry.node) and entry.node.is_connected("state_changed", entry.callback):
			entry.node.disconnect("state_changed", entry.callback)
	_cue_callbacks.clear()
	for id: String in _callbacks:
		if is_instance_valid(sources.get(id)) and sources[id].is_connected("died", _callbacks[id]):
			sources[id].disconnect("died", _callbacks[id])
	_callbacks.clear()
	for source: Node3D in sources.values():
		if is_instance_valid(source):
			source.set_physics_process(false)
	if is_instance_valid(mechanism):
		if mechanism.state_changed.is_connected(_on_pulse_phase):
			mechanism.state_changed.disconnect(_on_pulse_phase)
		mechanism.set_physics_process(false)
	# A managed journal refuses end_encounter reset. Retire actual native held
	# owners while Hero/resources remain inside this whole parent, never later
	# through an already removed Echo's _exit_tree presentation callback.
	if is_instance_valid(threat_scheduler) and threat_scheduler.is_inside_tree() and not threat_scheduler.is_queued_for_deletion():
		for id: String in sources:
			_retire_held_parent_owner(sources[id], String(_rows[id].kind), discarded_candidate)
		if is_instance_valid(mechanism):
			_retire_held_parent_owner(mechanism, "environmental_mechanism", discarded_candidate)
	if is_instance_valid(exit_cue):
		exit_cue.clear()
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("mirror_sea_level_exit")


func _retire_held_parent_owner(owner: Node3D, kind: String, discarded_candidate: bool) -> void:
	if not is_instance_valid(owner) or not owner.is_inside_tree():
		return
	if owner.is_queued_for_deletion() or owner.get_parent() != self:
		push_error("Whole-parent exit refuses a foreign or already removing native owner")
		return
	var control: Dictionary = threat_scheduler.source_control_state(owner)
	if control.is_empty():
		push_error("Whole-parent exit requires this actual owner/Scheduler world custody")
		return
	if control.reservations.is_empty():
		return # Unadmitted/ready and original terminal history stay untouched.
	if not control.outside_transaction:
		push_error("Whole-parent retirement requires an outside native transaction boundary")
		return
	var reason: String = "mirror_sea_whole_parent_exit"
	if kind == "echo":
		var current: Dictionary = owner.call("state")
		var recipe: Dictionary = owner.call("get_authored_cycle_restore_recipe")
		var unfinished: bool = discarded_candidate and not recipe.is_empty()
		if control.reservations.size() != 1 or not owner.call("source_cycles_managed"):
			push_error("Retire only this actual managed Echo lease, never foreign or legacy history")
			return
		var id: String = String(control.reservations[0].id)
		if current.get("status") == "running":
			if current.get("reservation_id") != id:
				push_error("Native running Playback must retain its original held lease")
				return
			var accepted: bool = owner.call("cancel", reason)
			if not unfinished:
				var terminal: Dictionary = owner.call("get_authored_cycle_terminal_receipt")
				assert(accepted and terminal.get("outcome") == "cancelled" and terminal.get("reason") == reason and terminal.get("exchange", {}).get("id") == id, "Committed owner retirement must seal its original real cancellation")
		else:
			if not unfinished or current.get("status") not in ["idle", "cycle_ready"]:
				push_error("Only a discarded unfinished native candidate may hold an uncommitted Playback lease")
				return
		var remaining: Dictionary = threat_scheduler.source_control_state(owner)
		if not remaining.reservations.is_empty():
			if not unfinished:
				push_error("Only a genuine unfinished discarded candidate may use raw owner retirement")
				return
			# Scheduler may have committed before this Playback. Remove only its
			# real held lease; unsealed history stays unusable and is discarded.
			threat_scheduler.cancel_owner(owner, reason + "_unfinished_candidate")
	elif kind == "stalker":
		threat_scheduler.cancel_owner(owner, reason)
	elif kind == "environmental_mechanism":
		var current: Dictionary = owner.call("state")
		if current.get("status") == "running":
			var accepted: bool = owner.call("cancel", reason)
			assert(accepted, "Retire the actual running mechanism through its public cancel")
		else:
			if not discarded_candidate or not String(current.get("reservation_id", "")).is_empty():
				push_error("Only an unfinished discarded mechanism candidate may have a staged raw lease")
				return
			threat_scheduler.cancel_owner(owner, reason + "_unfinished_candidate")
	else:
		assert(false, "Known actual native parent owner kind required for retirement")
	var after: Dictionary = threat_scheduler.source_control_state(owner)
	assert(not after.is_empty() and after.reservations.is_empty() and Authored.exact_equal(control.clock_s, after.clock_s), "Retire the actual native held owner before whole-parent disposal without clock advancement")
