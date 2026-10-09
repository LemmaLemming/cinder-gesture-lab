extends "res://scripts/acts/act1/mushroom_caverns_route.gd"
## PRIVATE, inert full-parent draft. No parsed/playable/save acceptance claim.
## Requires the separately reviewed Actor constructor, route-codec and capture
## opt-in patch plus exact Shared34. Saved mechanics remain pure preflight;
## actual current optics are checked independently at capture and post-quiet.
## One real Hero/Scheduler and inherited native gameplay; no copied controller.

const RouteCodec = preload("res://scripts/acts/act1/mushroom_caverns_route_codec.gd") # Proposed owned promotion path.
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const NativeMotion = preload("res://scripts/combat/lunge_motion.gd")
const NativeCueMesh = preload("res://scripts/cues/cue_mesh.gd")
const FIELD_IDS: Array[String] = ["breathing", "crossed-left", "crossed-right", "court"]
const CONSUMER_ROOMS: Array[String] = ["breathing", "crossed", "court"]
const PROOF_KEYS: Array[String] = ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]
const SEGMENT_KEYS: Array[String] = ["from", "to", "start_s", "end_s", "kind"]
const ACCEPTED_FRAME_KEYS: Array[String] = ["reservation_id", "landing", "attack_position", "primary_time_s", "response_complete_s", "action_escape"]

var _aggregate: RefCounted = RouteCodec.new()
var _constructor_open: bool = false
var _constructor_entitlements: Dictionary = {}
var _candidate_plan: Dictionary = {}
var _quiet_commit: bool = false
var _quiet_commit_error: String = ""
var _capture_error: String = ""
var _accepted_frames: Dictionary = {} # Original serialized native proof; never recomputed.
var _trusted_configurations: Dictionary = {}
var _retained_scheduler: CinderThreatScheduler
var _scheduler_script: Script
var _hero_script: Script
var _hero_sprite: Sprite3D
var _hero_shadow: MeshInstance3D
var _hero_shadow_mesh: Mesh
var _hero_shadow_material: Material
var _hero_sprite_transform: Transform3D
var _hero_shadow_transform: Transform3D
var _contact_cue: CinderInteractionCue
var _contact_marker: MeshInstance3D
var _contact_material: Material
var _contact_mesh: Mesh
var _cue_parts: Dictionary = {} # Actual ready native node/material/readback pins.


func _ready() -> void:
	super._ready()
	if not _construction_error.is_empty(): return
	_retained_scheduler = scheduler
	_scheduler_script = scheduler.get_script() as Script
	_contact_cue = _exit_cue
	_contact_marker = _exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if not is_instance_valid(_contact_marker):
		_construction_error = "Retain actual native contact marker"
		return
	_contact_material = _contact_marker.material_override
	_contact_mesh = _contact_marker.mesh
	for id: String in NORMAL_SOURCE_IDS:
		var retained: Variant = _retained_cues.get(id)
		if not is_instance_valid(retained) or not retained is CinderThreatCue:
			_construction_error = "Retain actual native threat cue before resource pins: " + id
			return
		var cue: CinderThreatCue = retained
		var pins: Dictionary = {}
		for part_name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
			var part := cue.get_node_or_null(part_name) as MeshInstance3D
			if not is_instance_valid(part) or not part.material_override is StandardMaterial3D:
				_construction_error = "Retain every actual native threat-cue part"
				return
			var settings: Array = _cue_part_settings(part)
			if settings.is_empty():
				_construction_error = "Native threat-cue material cannot carry a script or next pass"
				return
			pins[part_name] = {"node": part, "material": part.material_override, "settings": settings, "transform": part.transform}
		_cue_parts[id] = pins
	native_admission_published.connect(_record_native_admission) # Before external gameplay subscriptions.


func _native_route_snapshot_enabled() -> bool:
	return true # Only this subclass; both old scaffold refusal overrides stay false.


func restore_candidate_construction_required() -> bool:
	return true


func _on_enter_level() -> void:
	super._on_enter_level() # Normal entry binds19; no initial begin/activation in this route.
	if not _running: return
	var error: String = _pin_entry_resources()
	if not error.is_empty(): _entry_failed(error)


func _pin_entry_resources() -> String:
	if not is_instance_valid(hero) or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d(): return "Retain actual same-world Hero"
	_hero_script = hero.get_script() as Script
	_hero_sprite = hero.get_node_or_null("ActorSprite") as Sprite3D
	_hero_shadow = hero.get_node_or_null("ContactShadow") as MeshInstance3D
	if not is_instance_valid(_hero_sprite) or not is_instance_valid(_hero_shadow) or _hero_shadow.mesh == null: return "Actual complete Hero art/shadow required"
	_hero_shadow_mesh = _hero_shadow.mesh
	_hero_shadow_material = _hero_shadow.material_override
	_hero_sprite_transform = _hero_sprite.transform
	_hero_shadow_transform = _hero_shadow.transform
	_trusted_configurations.clear()
	for id: String in NORMAL_SOURCE_IDS:
		var retained: Variant = sources.get(id)
		if not is_instance_valid(retained) or not retained is Act1MushroomSelenite: return "Retain actual source before entry configuration pins: " + id
		var actor: Act1MushroomSelenite = retained
		var native: Dictionary = actor.get_spore_native_bindings()
		if native.is_empty() or native.scheduler != scheduler or native.player != hero or native.source_id != id: return "Actual immutable source/Player/Scheduler aliases required: " + id
		_trusted_configurations[id] = native.configuration.duplicate(true)
	return String(_aggregate.call("configuration_error", _authored_definitions()))


func _on_enter_restore_candidate(local: Dictionary, saved_player: Dictionary) -> String:
	# Entire tree remains paused. Do not call ordinary entry or replay an epoch.
	if not is_restore_candidate() or not _fields.is_empty() or not _consumers.is_empty() or not _protocols.is_empty(): return "Fresh actual candidate without prior installed topology required"
	_running = true
	for id: String in NORMAL_SOURCE_IDS:
		var retained: Variant = sources.get(id)
		if not is_instance_valid(retained) or not retained is Act1MushroomSelenite: return "Retain actual fresh source before candidate binding: " + id
		var actor: Act1MushroomSelenite = retained
		if not actor.bind(scheduler, hero): return actor.last_error
		var callback: Callable = Callable(self, "_on_source_state").bind(id)
		_source_callbacks[id] = callback
		actor.state_changed.connect(callback)
	if not hero.died.is_connected(_on_hero_died): hero.died.connect(_on_hero_died)
	if not hero.fired.is_connected(_on_hero_fired): hero.fired.connect(_on_hero_fired)
	# Inherited helper only pins actual Hero capsule and initial presentation.
	_start_initial_encounter()
	if not _running: return _construction_error
	var error: String = _pin_entry_resources()
	if not error.is_empty(): return error
	var plan: Dictionary = _aggregate.call("construction_plan", local, saved_player, _authored_definitions(), _trusted_configurations)
	if plan.get("accepted") != true: return String(plan.get("error", "Closed construction plan rejected"))
	_candidate_plan = plan.duplicate(true)
	_constructor_open = true
	_constructor_entitlements = plan.descriptors.duplicate(true)
	for id: String in plan.activated_source_ids:
		var retained: Variant = sources.get(id)
		if not is_instance_valid(retained) or not retained is Act1MushroomSelenite:
			_constructor_open = false
			_constructor_entitlements.clear()
			return "Retain actual entitled source before native recipient construction: " + id
		var actor: Act1MushroomSelenite = retained
		var descriptor: Dictionary = _constructor_entitlements[id].duplicate(true)
		var accepted: Variant = actor.call("construct_restore_recipient", self, descriptor)
		_constructor_entitlements.erase(id) # Consume on every attempt, including failure.
		if not is_instance_valid(actor):
			_constructor_open = false
			_constructor_entitlements.clear()
			return "Actual native recipient disappeared during constructor callback"
		if not accepted is bool or accepted != true:
			_constructor_open = false
			_constructor_entitlements.clear()
			return actor.last_error if not actor.last_error.is_empty() else "Native one-shot recipient construction refused"
	_constructor_open = false
	_constructor_entitlements.clear()
	# Construct real permanent bindings for exactly the already-validated prefix.
	for room_id: String in plan.installed_rooms:
		var room: int = Layout.ROOM_IDS.find(room_id)
		if not ROOM_FIELDS[room].is_empty():
			error = _construct_room_environment(room)
			if not error.is_empty(): return error
	_refresh_render_state()
	return route_snapshot_runtime_error() # Still no saved HP/pose/clock/history applied.


func restore_recipient_construction_error(source: Act1MushroomSelenite, descriptor: Dictionary) -> String:
	# Pure exact entitlement; never obtained from same-tick cancellation or IDs alone.
	if not _constructor_open or not is_restore_candidate() or _callback_depth != 0 or not _quiet_commit_error.is_empty(): return "Owned constructor entitlement is closed"
	if not descriptor.get("source_id") is String: return "Stable entitled source ID required"
	var id: String = descriptor.source_id
	if not _constructor_entitlements.has(id) or sources.get(id) != source or _retained_sources.get(id) != source or not is_instance_valid(source) or source.get_parent() != self or source.get_world_3d() != get_world_3d(): return "Exact retained entitled recipient required"
	return "" if _same(descriptor, _constructor_entitlements[id]) else "Descriptor differs from the closed copied construction plan"


func _construct_room_environment(room: int) -> String:
	# Private owned parameter seam selects immutable tables without writing any
	# current/saved beat. Native bindings derive from genuine exposed recipients.
	if not is_restore_candidate() or room < 0 or room >= 5 or ROOM_FIELDS[room].is_empty(): return "Actual paused installed spore room required"
	return _install_authored_room_environment(room)


func _authored_definitions() -> Dictionary:
	var positions: Dictionary = {}
	for id: String in NORMAL_SOURCE_IDS: positions[id] = Codec.vector3(_source_spec(id).position)
	var field_positions: Dictionary = {}
	for id: String in FIELD_IDS: field_positions[id] = Codec.vector3(NORMAL_FIELD_POINTS[id])
	return {"source_ids": NORMAL_SOURCE_IDS.duplicate(), "room_ids": Layout.ROOM_IDS.duplicate(), "room_sources": ROOM_SOURCES.duplicate(true), "field_ids": FIELD_IDS.duplicate(), "room_fields": ROOM_FIELDS.duplicate(true), "consumer_rooms": CONSUMER_ROOMS.duplicate(), "beat_ids": ROOM_BEATS.duplicate(), "checkpoint_ids": CHECKPOINTS.duplicate(), "completion_id": COMPLETION_ID, "exit_id": EXIT_ID, "source_positions": positions, "field_positions": field_positions, "world_revision": WORLD_REVISION, "controller_id": CONTROLLER_ID, "player_id": "hero"}


func _aggregate_bindings() -> Dictionary:
	var fields: Dictionary = {}
	var consumers: Dictionary = {}
	var protocols: Dictionary = {}
	for id: String in FIELD_IDS: fields[id] = _fields.get(id)
	for room: String in CONSUMER_ROOMS:
		consumers[room] = _consumers.get(room)
		protocols[room] = _protocols.get(room)
	return {"level": self, "player": hero, "scheduler": scheduler, "actors": sources.duplicate(), "fields": fields, "consumers": consumers, "protocols": protocols, "scheduler_bindings": scheduler_bindings(), "runtime_error": Callable(self, "route_snapshot_runtime_error"), "framing_error": Callable(self, "route_snapshot_framing_error")}


func route_snapshot_runtime_error() -> String:
	# Identity/resources/barriers only; fresh construction may be physically
	# pristine living while the submitted earlier room actor is saved dead.
	if not _running or _changing or _callback_depth != 0 or _constructor_open or not _constructor_entitlements.is_empty() or not _activation_entitlement.is_empty() or not get_tree().paused or not _quiet_commit_error.is_empty(): return "Actual quiet retained native parent boundary required"
	if global_basis != Basis.IDENTITY or global_position != Vector3.ZERO or not _floor_error().is_empty() or not _scenery_error().is_empty(): return "Retain actual authored static floor/scenery/world frame"
	if not is_instance_valid(scheduler) or scheduler != _retained_scheduler or scheduler.get_script() != _scheduler_script or scheduler.get_parent() != self or get_node_or_null("MushroomThreatScheduler") != scheduler or not scheduler.is_inside_tree() or scheduler.is_queued_for_deletion(): return "Retain actual single native Scheduler"
	if not is_instance_valid(hero) or hero.get_script() != _hero_script or _world_root() == null or hero.get_world_3d() != get_world_3d(): return "Actual same-world candidate/live Hero required"
	var measured: Dictionary = BodySweep.source_description(hero)
	if measured.has("error") or _player_body.is_empty() or measured.get("collision") != _player_body.collision or hero.get_parent() != _player_body.parent or _player_body.collision.shape != _player_body.shape or _player_body.collision.transform != _player_body.transform or _player_body.shape.radius != _player_body.radius or _player_body.shape.height != _player_body.height: return "Retain actual Hero capsule/body settings"
	if hero.get_node_or_null("ActorSprite") != _hero_sprite or hero.get_node_or_null("ContactShadow") != _hero_shadow or not is_instance_valid(_hero_sprite) or not _hero_sprite.is_inside_tree() or _hero_sprite.is_queued_for_deletion() or _hero_sprite.get_parent() != hero or not _hero_sprite.is_visible_in_tree() or _hero_sprite.transform != _hero_sprite_transform: return "Retain actual native Hero billboard"
	if not is_instance_valid(_hero_shadow) or not _hero_shadow.is_inside_tree() or _hero_shadow.is_queued_for_deletion() or _hero_shadow.get_parent() != hero or not _hero_shadow.is_visible_in_tree() or _hero_shadow.mesh != _hero_shadow_mesh or _hero_shadow.material_override != _hero_shadow_material or _hero_shadow.transform != _hero_shadow_transform: return "Retain actual native Hero contact shadow"
	if not Codec.keys_error(sources, NORMAL_SOURCE_IDS).is_empty() or not Codec.keys_error(_retained_sources, NORMAL_SOURCE_IDS).is_empty(): return "All nineteen retained native actors required"
	for id: String in NORMAL_SOURCE_IDS:
		var retained: Variant = sources.get(id)
		if not is_instance_valid(retained) or not retained is Act1MushroomSelenite: return "Retain actual native actor before typed validation: " + id
		var actor: Act1MushroomSelenite = retained
		if actor != _retained_sources[id] or actor.get_script() != ActorScript or actor.get_parent() != self or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d(): return "Retain actual native actor/script/world: " + id
		var native: Dictionary = actor.get_spore_native_bindings()
		if native.is_empty() or native.scheduler != scheduler or native.player != hero or not _same(native.configuration, _trusted_configurations.get(id)): return "Retain immutable source configuration/aliases: " + id
		var error: String = actor.body_binding_error()
		if error.is_empty(): error = actor.art_binding_error()
		if error.is_empty(): error = _native_cue_resources_error(id)
		if not error.is_empty(): return id + ": " + error
		if actor.get_node_or_null("BodyCollision") != _retained_collisions[id] or _retained_collisions[id].shape != _retained_capsules[id] or actor.get_cue() != _retained_cues[id]: return "Retain actual capsule/cue resource: " + id
		var callback: Callable = Callable(self, "_on_source_state").bind(id)
		if _source_callbacks.get(id) != callback or not actor.state_changed.is_connected(callback) or actor.activation_guard != Callable(self, "_activation_permitted") or actor.presentation_guard != Callable(self, "_source_presentation_error").bind(id) or actor.approach_guard != Callable(self, "_source_approach_error").bind(id): return "Retain exact owned native callbacks/guards: " + id
	if not hero.died.is_connected(_on_hero_died) or not hero.fired.is_connected(_on_hero_fired): return "Retain actual Hero lifecycle/action callbacks"
	for id: Variant in _fields:
		if id not in FIELD_IDS: return "Only authored installed field IDs permitted"
	for room: Variant in _consumers:
		if room not in CONSUMER_ROOMS: return "Only authored installed consumer IDs permitted"
	if not Codec.keys_error(_field_callbacks, _fields.keys()).is_empty() or not Codec.keys_error(_cluster_art, _fields.keys()).is_empty() or not Codec.keys_error(_protocols, _consumers.keys()).is_empty(): return "Installed native callback/art/protocol membership must be exact"
	var error: String = _cluster_bindings_error()
	if error.is_empty(): error = _spore_bindings_error()
	if error.is_empty(): error = _quiet_contact_resources_error()
	if not error.is_empty(): return error
	for id: String in _fields:
		var retained: Variant = _fields.get(id)
		if not is_instance_valid(retained) or not retained is CinderSporeField: return "Retain actual installed native Field: " + id
		var field: CinderSporeField = retained
		var callback: Callable = Callable(self, "_on_room_field_state").bind(id)
		if _field_callbacks.get(id) != callback or not field.state_changed.is_connected(callback): return "Retain exact native Field callback: " + id
	return ""


func _quiet_contact_resources_error() -> String:
	var error: String = _contact_mesh_factory_error()
	if error.is_empty(): error = _contact_error()
	if not error.is_empty(): return error
	if _exit_cue != _contact_cue or _exit_cue.get_script() != InteractionCue or not _exit_cue.is_in_group("required_cues") or not is_instance_valid(_contact_marker) or _exit_cue.get_node_or_null("RequiredInteractionMarker") != _contact_marker or not _contact_marker.is_inside_tree() or _contact_marker.is_queued_for_deletion() or _contact_marker.get_parent() != _exit_cue or _contact_marker.material_override != _contact_material or _contact_marker.mesh != _contact_mesh: return "Retain actual native contact cue/marker/material/current-state mesh"
	var state: Dictionary = _exit_cue.state()
	if beat_index == 5:
		if state.state != "available" or state.trigger != "contact" or not _contact_marker.is_visible_in_tree(): return "Completed court has actual native available/contact presentation"
	elif state.state != "clear" or _contact_marker.visible or _contact_marker.mesh != null: return "Incomplete court retains actual native clear contact presentation"
	return ""


func _record_native_admission(id: String, answer: Dictionary) -> void:
	if answer.get("accepted") != true: return
	# Earlier publication listeners may synchronously cancel, pause, defeat or
	# detach a source. Validate current native custody before storing its proof.
	var custody_error: String = _admission_custody_error(id, answer)
	if not custody_error.is_empty():
		_reject_corresponding_admission(id, answer, custody_error)
		return
	var current: Variant = _framing.get(id)
	if not current is Dictionary or current.get("reservation_id") != answer.get("reservation_id") or not answer.get("proof") is Dictionary:
		_reject_corresponding_admission(id, answer, "Actual native response must still name its returned lease")
		return
	var proof: Dictionary = _encode_native_proof(answer.proof)
	if proof.is_empty():
		_reject_corresponding_admission(id, answer, "Actual accepted native proof cannot be retained exactly")
		return
	var frame: Dictionary = {"reservation_id": String(answer.reservation_id), "landing": proof.landing.duplicate(), "attack_position": proof.attack_position.duplicate(), "primary_time_s": proof.primary_time_s, "response_complete_s": proof.response_complete_s, "action_escape": proof}
	_accepted_frames[id] = frame
	_framing[id]["primary_time_s"] = frame.primary_time_s
	_framing[id]["response_complete_s"] = frame.response_complete_s
	_framing[id]["action_escape"] = answer.proof.duplicate(true)


func _encode_native_proof(proof: Dictionary) -> Dictionary:
	if not Codec.keys_error(proof, PROOF_KEYS).is_empty() or proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or proof.get("proof_scope") != "static_box_floor_full_dash_stationary_primary" or not proof.get("path") is Array or not proof.get("landing") is Vector3 or not proof.get("attack_position") is Vector3: return {}
	var encoded: Dictionary = proof.duplicate(true)
	encoded["landing"] = Codec.vector3(proof.landing)
	encoded["attack_position"] = Codec.vector3(proof.attack_position)
	encoded["path"] = []
	for segment: Variant in proof.path:
		if not segment is Dictionary or not Codec.keys_error(segment, SEGMENT_KEYS).is_empty() or not segment.get("from") is Vector3 or not segment.get("to") is Vector3: return {}
		var value: Dictionary = segment.duplicate(true)
		value["from"] = Codec.vector3(segment["from"])
		value["to"] = Codec.vector3(segment["to"])
		encoded.path.append(value)
	return encoded if not Exact.stringify(encoded).is_empty() else {}


func _on_source_state(state: Dictionary, id: String) -> void:
	super._on_source_state(state, id)
	if state.reservation_id.is_empty() or state.dead or (_accepted_frames.has(id) and _accepted_frames[id].reservation_id != state.reservation_id): _accepted_frames.erase(id)


func _advance_room() -> void:
	# Finish native cleanup before the public automatic checkpoint can schedule a
	# paused aggregate capture. Never serialize preparing_environment/transient flags.
	if not _room_genuinely_clear() or not _quiet_lifecycle_error().is_empty(): return
	_changing = true
	scheduler.end_encounter("actual_room_required_cast_defeated")
	for id: String in current_source_ids():
		var retained: Variant = sources.get(id)
		if not is_instance_valid(retained) or not retained is Act1MushroomSelenite:
			_changing = false
			_entry_failed("Actual cleared room source disappeared before native readiness check")
			return
		var actor: Act1MushroomSelenite = retained
		var control: Dictionary = scheduler.source_control_state(actor)
		if not control.outside_transaction or not control.reservations.is_empty() or control.cooldown != null:
			_changing = false
			_entry_failed("Actual cleared room retained native readiness after boundary")
			return
	completed_beats.append(ROOM_BEATS[beat_index])
	beat_index += 1
	encounter_started = false
	room_stage = "complete" if beat_index == 5 else "approach"
	_framing.clear()
	_accepted_frames.clear()
	_clear_forecast_hint()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()
	_changing = false
	_apply_route_presentation()
	if not _running or not _quiet_commit_error.is_empty(): return
	_publishing_progress = true
	var accepted: bool = request_completion(COMPLETION_ID) if beat_index == 5 else request_checkpoint(CHECKPOINTS[beat_index - 1], "encounter")
	_publishing_progress = false
	if not accepted: _entry_failed("Actual authored progress publication rejected")


func _apply_route_presentation() -> void:
	if not _running: return
	# Verify the old native glyph before an authoritative transition. The old
	# logical state can legitimately differ from the new beat during quiet restore.
	var error: String = _contact_mesh_factory_error()
	if error.is_empty() and _contact_marker.mesh != _contact_mesh:
		error = "Retain the prior native contact mesh before presentation"
	if not error.is_empty():
		_contact_presentation_failed(error)
		return
	var actual_cue: CinderInteractionCue = _exit_cue
	var before: Dictionary = actual_cue.state()
	var blocked: bool = actual_cue.is_blocking_signals()
	# Same public scoped silent-presentation primitive as Actor quiet exchange.
	# Native present/clear owns its bytes; a callback cannot make arbitrary bytes trusted.
	if _quiet_commit: actual_cue.set_block_signals(true)
	super._apply_route_presentation()
	if _quiet_commit and is_instance_valid(actual_cue): actual_cue.set_block_signals(blocked)
	error = _contact_mesh_factory_error()
	if error.is_empty(): error = _contact_error()
	if not error.is_empty():
		_contact_presentation_failed(error)
		return
	# Repin only a genuine state transition whose actual glyph matches the
	# public native factory. Idempotent presentation cannot legitimize replacement.
	if before.state != actual_cue.state().state:
		_contact_mesh = _contact_marker.mesh
	elif _contact_marker.mesh != _contact_mesh:
		_contact_presentation_failed("Idempotent native contact presentation replaced the retained mesh")


func _contact_mesh_factory_error() -> String:
	if not is_instance_valid(_exit_cue) or _exit_cue != _contact_cue or not _exit_cue.is_inside_tree() or _exit_cue.is_queued_for_deletion() or _exit_cue.get_parent() != self or _exit_cue.get_script() != InteractionCue: return "Retain actual native contact cue before glyph validation"
	if not is_instance_valid(_contact_marker) or _exit_cue.get_node_or_null("RequiredInteractionMarker") != _contact_marker or not _contact_marker.is_inside_tree() or _contact_marker.is_queued_for_deletion() or _contact_marker.get_parent() != _exit_cue or _contact_marker.material_override != _contact_material or not _contact_material is StandardMaterial3D: return "Retain actual native contact marker/material before glyph validation"
	var material: StandardMaterial3D = _contact_material
	if material.get_script() != null or material.next_pass != null: return "Native contact material cannot carry a script or next pass"
	var shown: Dictionary = _exit_cue.state() # Pure native read; no repair or callback.
	if shown.state == "clear":
		return "" if _contact_marker.mesh == null and not _contact_marker.visible else "Clear native contact must retain its genuine null hidden mesh"
	if shown.state != "available" or shown.trigger != "contact" or shown.required != true or shown.visible != true or not _contact_marker.is_visible_in_tree(): return "Only genuine available/contact presentation is supported by this exit"
	var expected: ArrayMesh = NativeCueMesh.interaction_mesh(shown.state, shown.trigger)
	return "" if _same_native_mesh(_contact_marker.mesh, expected) else "Actual contact glyph differs from the public native mesh factory"


func _contact_presentation_failed(error: String) -> void:
	_quiet_commit_error = error
	last_encounter_error = error
	_freeze_failed_candidate() # Reject playback/install; never repair or repin a bad callback.


func snapshot_state() -> Dictionary:
	# Ordinary installed capture obtains its current HUD, then uses the same
	# guarded writer as the proposed explicit fresh-entry context below.
	var raw_hud: Variant = shared_shell.get("hud") if is_instance_valid(shared_shell) else null
	var hud: GameHUD = null
	if is_instance_valid(raw_hud) and raw_hud is GameHUD: hud = raw_hud
	return _snapshot_state_in_presentation(_actual_presentation_camera(), hud)


func snapshot_state_for_presentation(actual_camera: Camera3D, actual_hud: GameHUD) -> Dictionary:
	# UNPUBLISHED Integration812cac04 opt-in proposal. The shared caller alone
	# prepares/fits its real fresh camera and canonical HUD before this read.
	# Never substitute the installed HUD for the explicitly supplied context.
	return _snapshot_state_in_presentation(actual_camera, actual_hud)


func _snapshot_state_in_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	_capture_error = ""
	# Independent LIVE guard, never substituted by pure saved-unit preflight.
	# A candidate must first finish the whole quiet unit and its explicit hook.
	if is_restore_candidate():
		last_snapshot_error = "Nonplayable candidate cannot supply a live optical capture"
		return {}
	if not is_instance_valid(hud):
		last_snapshot_error = "Actual live canonical HUD required for capture"
		return {}
	last_snapshot_error = _current_presentation_error(camera, hud)
	if not last_snapshot_error.is_empty(): return {}
	var snapshot: Dictionary = super.snapshot_state() # Private two-hop opt-in patch required.
	if snapshot.is_empty():
		if not _capture_error.is_empty(): last_snapshot_error = _capture_error
		return {}
	last_snapshot_error = snapshot_error(snapshot)
	return snapshot if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = super.snapshot_error(snapshot)
	return _whole_progress_error(snapshot, hero.snapshot_state()) if error.is_empty() else error


func snapshot_error_with_player(snapshot: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(snapshot, saved_player)
	return _whole_progress_error(snapshot, saved_player) if error.is_empty() else error


func restore_state(snapshot: Dictionary) -> bool:
	if not _quiet_commit_error.is_empty():
		last_snapshot_error = "Dispose failed native candidate: " + _quiet_commit_error
		return false
	last_snapshot_error = snapshot_error(snapshot)
	if not last_snapshot_error.is_empty(): return false
	var accepted: bool = super.restore_state(snapshot)
	if not _quiet_commit_error.is_empty():
		last_snapshot_error = _quiet_commit_error
		return false # Base void hook may have marked ready; installation guard below rejects.
	return accepted


func finish_restore_candidate() -> bool:
	if not _quiet_commit_error.is_empty() or _quiet_commit or _constructor_open: return false
	return super.finish_restore_candidate()


func _capture_local_state() -> Dictionary:
	var error: String = route_snapshot_runtime_error()
	if not error.is_empty():
		_capture_error = error
		return {}
	var metadata: Dictionary = {"beat_index": beat_index, "completed_beats": completed_beats.duplicate(), "room_stage": room_stage, "framing": _accepted_frames.duplicate(true)}
	var local: Dictionary = _aggregate.call("capture_state", metadata, hero.snapshot_state(), _aggregate_bindings(), _authored_definitions())
	_capture_error = String(_aggregate.get("last_error"))
	return local


func _local_snapshot_error(state: Dictionary) -> String:
	return _local_snapshot_error_with_player(state, hero.snapshot_state())


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	return String(_aggregate.call("state_error", state, saved_player, _aggregate_bindings(), _authored_definitions()))


func _whole_progress_error(snapshot: Dictionary, saved_player: Dictionary) -> String:
	var error: String = String(_aggregate.call("progress_error", snapshot.progress, snapshot.local, _authored_definitions()))
	if not error.is_empty() or snapshot.progress.contact_exit_id.is_empty(): return error
	# A supplied contact flag must correspond to the actual saved capsule and
	# retained upright native box, not the fresh candidate's pre-commit overlaps.
	var centre: Vector3 = Codec.read_vector3(saved_player.motion.position) + _player_body.collision.position
	var capsule := _player_body.shape as CapsuleShape3D
	var box: AABB = AABB(_exit_shape.global_position - _exit_resource.size * .5, _exit_resource.size)
	var half_line: float = capsule.height * .5 - capsule.radius
	var nearest := Vector3(clampf(centre.x, box.position.x, box.end.x), clampf(centre.y, box.position.y - half_line, box.end.y + half_line), clampf(centre.z, box.position.z, box.end.z))
	return "" if centre.distance_squared_to(nearest) <= capsule.radius * capsule.radius else "Saved contact progress is outside the actual capsule/box overlap domain"


func route_snapshot_framing_error(state: Dictionary, saved_player: Dictionary) -> String:
	# RouteCodec already validates exact complete original action_escape history,
	# Player/19 actors/native Scheduler/Field/Consumer context and retained guards.
	# Keep full body-path/threat-union/range/recovery/scenery proof before commit.
	# Do not interpret saved billboard poses against the pristine candidate or
	# donor. Only actual optical projection is deferred to Shared34's quiet gate.
	return _saved_response_mechanical_error(state, saved_player)


func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	# Shared34 calls only AFTER actual Player -> whole local quiet commit, with
	# the real saved-focus native camera and correctly wrapped canonical HUD.
	# No capture/restore/finish/progress calls, yields, repair or camera fitting.
	if not _quiet_commit_error.is_empty() or _quiet_commit or _constructor_open:
		return "Dispose incomplete or failed quiet native candidate"
	return _current_presentation_error(camera, hud)


func _current_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	var error: String = route_snapshot_runtime_error()
	if not error.is_empty(): return error
	if camera == null or camera != _actual_presentation_camera() or not is_instance_valid(hud): return "Actual current same-world camera and canonical HUD required"
	error = _billboard_camera_error(camera)
	if error.is_empty(): error = _current_framing_history_error()
	if not error.is_empty(): return error
	var mandatory: Array = _actual_hero_points(hero.global_position)
	if mandatory.size() != 22: return "Actual complete Hero body/billboard/shadow unavailable"
	var points: Array = _camera_framing_points()
	if points.is_empty() or points.size() > 224 or points.has(Vector3.INF): return "Complete actual source/cue/footprint/response union unavailable"
	# This certifies actual CURRENT containment, including mandatory real Hero22.
	# A future plan is not queried/applied here. Native HUD owns its safe rectangle.
	return String(shared_shell.call("camera_framing_error_for_context", points, hero, camera, hud))


func _current_framing_history_error() -> String:
	# Actual render anchors must agree with the original six-field native receipt.
	# The codec separately checks complete leases, proof paths and exact context.
	if not Codec.keys_error(_framing, _accepted_frames.keys()).is_empty(): return "Current response anchors must retain exact accepted history membership"
	for id: String in _accepted_frames:
		var raw: Variant = _framing[id]
		var original: Variant = _accepted_frames[id]
		if not raw is Dictionary or not original is Dictionary or not Codec.keys_error(raw, ACCEPTED_FRAME_KEYS).is_empty() or not Codec.keys_error(original, ACCEPTED_FRAME_KEYS).is_empty() or not Codec.value_error(original).is_empty(): return "Complete current accepted response anchor required"
		if not raw.landing is Vector3 or not raw.landing.is_finite() or not raw.attack_position is Vector3 or not raw.attack_position.is_finite() or not Codec.is_vector3(original.landing) or not Codec.is_vector3(original.attack_position) or not raw.primary_time_s is float or not raw.response_complete_s is float or not is_finite(raw.primary_time_s) or not is_finite(raw.response_complete_s): return "Exact finite current accepted response types required"
		if not raw.action_escape is Dictionary: return "Complete current native action proof required"
		# Genuine live receipt holds native Vector3; quiet-restored render cache
		# holds exact encoded arrays. Normalize only a detached comparison value.
		var current_proof: Dictionary = _encode_native_proof(raw.action_escape) if raw.action_escape.get("landing") is Vector3 else raw.action_escape.duplicate(true)
		if current_proof.is_empty() or raw.reservation_id != original.reservation_id or raw.landing != Codec.read_vector3(original.landing) or raw.attack_position != Codec.read_vector3(original.attack_position) or raw.primary_time_s != original.primary_time_s or raw.response_complete_s != original.response_complete_s or not _same(current_proof, original.action_escape): return "Current response anchors differ from the genuine accepted native history"
		var shown: Variant = _render_sources.get(id)
		if not shown is Dictionary or shown.get("reservation_id") != original.reservation_id: return "Actual current source must retain the same accepted native lease"
	return ""


func _actual_presentation_camera() -> Camera3D:
	# A Title/Retry candidate has its OWN current viewport Camera3D. Installed
	# Game.camera may be in another world; its pose never supplies this context.
	if not is_inside_tree(): return null
	var raw: Variant = get_viewport().get_camera_3d()
	if not is_instance_valid(raw) or not raw is Camera3D: return null
	var camera: Camera3D = raw
	if camera.get_script() != null or not camera.is_inside_tree() or not camera.is_node_ready() or camera.is_queued_for_deletion() or camera.get_viewport() != get_viewport() or camera.get_world_3d() != get_world_3d(): return null
	return camera


func _billboard_camera_error(camera: Camera3D) -> String:
	if camera == null or camera != _actual_presentation_camera() or not is_instance_valid(shared_shell): return "Actual current native camera required for billboards"
	var raw: Variant = shared_shell.get("camera")
	if not is_instance_valid(raw) or not raw is Camera3D: return "Shared fixed billboard basis unavailable"
	var reference: Camera3D = raw
	if not reference.is_inside_tree() or not reference.is_node_ready() or reference.is_queued_for_deletion() or reference.get_script() != null or camera.global_basis != reference.global_basis: return "Actual candidate must retain the exact shared fixed billboard basis"
	# The public camera_billboard_points adapter reads ONLY this basis, not the
	# installed Camera's position, viewport, focus or Player. Shared34's explicit
	# context validator independently checks native width/depth/cull/viewport/HUD.
	return ""


func _actor_points(id: String, endpoint: Vector3) -> Array:
	if not _billboard_camera_error(_actual_presentation_camera()).is_empty(): return [Vector3.INF]
	return super._actor_points(id, endpoint) # actual body/art + public fixed-basis adapter


func _response_points(landing: Vector3, attack: Vector3) -> Array:
	var actual: Array = _actual_hero_points(hero.global_position) if is_instance_valid(hero) else []
	if actual.size() != 22 or not landing.is_finite() or not attack.is_finite(): return [Vector3.INF]
	var points: Array = []
	for point: Vector3 in actual:
		points.append(point + landing - hero.global_position)
		points.append(point + attack - hero.global_position)
	return _unique_points(points)


func _camera_framing_points() -> Array:
	# Fully overrides BOTH inherited builders: neither can append donor Player
	# points at a committed dash. Actual Hero22 is required even empty approach.
	if not _running: return []
	if not _floor_error().is_empty() or not _scenery_error().is_empty() or not _spore_bindings_error().is_empty() or not _cluster_bindings_error().is_empty() or not _billboard_camera_error(_actual_presentation_camera()).is_empty(): return [Vector3.INF]
	var points: Array = _actual_hero_points(hero.global_position) if is_instance_valid(hero) else []
	if points.size() != 22: return [Vector3.INF]
	if _forecast_hint_current(): points.append_array(_forecast_points)
	for forecast: Array in _approach_forecasts.values(): points.append_array(forecast)
	for request: Array in _approach_camera_requests.values(): points.append_array(request)
	for id: String in current_source_ids():
		var raw: Variant = sources.get(id)
		if not is_instance_valid(raw) or not raw is Act1MushroomSelenite: return [Vector3.INF]
		var actor: Act1MushroomSelenite = raw
		if actor != _retained_sources.get(id) or actor.get_parent() != self or not actor.is_inside_tree() or actor.is_queued_for_deletion(): return [Vector3.INF]
		var state: Dictionary = _render_sources.get(id, {})
		if state.is_empty(): return [Vector3.INF]
		if state.dead or state.dormant: continue
		if not actor.is_visible_in_tree(): return [Vector3.INF]
		points.append_array(_actor_points(id, state.opening_position))
		if state.geometry.get("kind") == "lane": points.append_array(_lane_points(state.geometry))
		points.append_array(_cue_points(id, state)) # actual retained native phase meshes
	for frame: Dictionary in _framing.values(): points.append_array(_response_points(frame.landing, frame.attack_position))
	var dash: Dictionary = hero.get_committed_dash_state()
	if dash.get("active", false):
		var endpoint: Vector3 = dash.origin + dash.direction * float(dash.distance)
		points.append_array(_actual_hero_points(endpoint))
	if beat_index < 5:
		for field_id: String in ROOM_FIELDS[beat_index]:
			if not _fields.has(field_id): continue # genuinely absent approach-stage field
			var field_raw: Variant = _fields[field_id]
			if not is_instance_valid(field_raw) or not field_raw is CinderSporeField: return [Vector3.INF]
			var field: CinderSporeField = field_raw
			var origin: Vector3 = field.global_position
			for x: float in [-Layout.FIELD_RADIUS, Layout.FIELD_RADIUS]:
				for z: float in [-Layout.FIELD_RADIUS, Layout.FIELD_RADIUS]: points.append(origin + Vector3(x, .03, z))
			for leaf_raw: Variant in _cluster_art[field_id].values():
				if not is_instance_valid(leaf_raw) or not leaf_raw is Node3D: return [Vector3.INF]
				var leaf: Node3D = leaf_raw
				# Existing clockless leaf includes actual billboard AND native cue corners.
				# Its public adapter is safe only under the exact fixed-basis guard above.
				var actual: Array = leaf.call("framing_points", shared_shell)
				if actual.is_empty(): return [Vector3.INF]
				points.append_array(actual)
			for id: String in current_source_ids():
				var actor_raw: Variant = sources.get(id)
				if not is_instance_valid(actor_raw) or not actor_raw is Act1MushroomSelenite: return [Vector3.INF]
				var actor: Act1MushroomSelenite = actor_raw
				if actor.dead or actor.dormant: continue
				var response: Dictionary = actor.get_spore_response_state()
				if response.is_empty(): return [Vector3.INF]
				var radius: float = Layout.FIELD_RADIUS + float(response.support_radius) + float(Repulsion.DEFAULTS.exit_clearance) + SPORE_CAMERA_PAD
				var actual: Array = _actor_points(id, actor.global_position)
				for x: float in [-radius, radius]:
					for z: float in [-radius, radius]:
						var endpoint := Vector3(origin.x + x, actor.global_position.y, origin.z + z)
						for point: Vector3 in actual: points.append(point + endpoint - actor.global_position)
		var raw_consumer: Variant = _consumers.get(Layout.ROOM_IDS[beat_index])
		if raw_consumer != null:
			if not is_instance_valid(raw_consumer) or not raw_consumer is CinderSporeRepulsion: return [Vector3.INF]
			var consumer: CinderSporeRepulsion = raw_consumer
			for id: String in current_source_ids():
				var record: Dictionary = consumer.source_state(id)
				if record.get("route", {}).get("planned_endpoint") is Vector3: points.append_array(_actor_points(id, record.route.planned_endpoint))
	elif not _contact_error().is_empty():
		return [Vector3.INF]
	else:
		points.append_array(_box_points(AABB(-_exit_resource.size * .5, _exit_resource.size), _exit_shape.global_transform))
		var marker := _exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
		if not is_instance_valid(marker) or marker.mesh == null or not marker.is_visible_in_tree(): return [Vector3.INF]
		points.append_array(_box_points(marker.get_aabb(), marker.global_transform))
	return _bounded_union(points)


func _bounded_union(points: Array) -> Array:
	if points.is_empty(): return []
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return [Vector3.INF]
	var camera: Camera3D = _actual_presentation_camera()
	if camera == null: return [Vector3.INF]
	var basis: Basis = camera.global_basis
	if not basis.is_finite() or absf(basis.determinant() - 1.0) > .00001: return [Vector3.INF]
	var inverse: Basis = basis.inverse()
	var bounds := AABB(inverse * points[0], Vector3.ZERO)
	for point: Vector3 in points: bounds = bounds.expand(inverse * point)
	# Same outward float32 presentation reserve as the inherited native view.
	# Pure convex containment only: no world/camera movement or response license.
	return _box_points(bounds.grow(.0001), Transform3D(basis, Vector3.ZERO))


func _containment_error(points: Array) -> String:
	if points.is_empty() or points.size() > 224 or not is_instance_valid(shared_shell): return "Complete bounded actual source/Player presentation required"
	return String(shared_shell.call("camera_framing_error_for_player", points, hero, _actual_presentation_camera()))


func _framing_ready(points: Array, optional_owner: String = "") -> bool:
	if points.is_empty() or points.size() > 224 or not is_instance_valid(shared_shell) or not is_instance_valid(hero):
		if not optional_owner.is_empty(): _clear_forecast_hint(optional_owner)
		return false
	# Ordinary live advisory admission only; no plan is applied or accepted as
	# current optics. A feasible plan preserves its owner's optional hint while
	# actual current containment waits; an impossible plan clears only that owner.
	var plan: Dictionary = shared_shell.call("camera_framing_plan_for_player", points, hero.global_position + Vector3(0, .65, 0), hero, _actual_presentation_camera())
	if plan.get("accepted") != true and not optional_owner.is_empty(): _clear_forecast_hint(optional_owner)
	last_encounter_error = String(plan.get("reason", "")) if not plan.get("accepted", false) else _containment_error(points)
	return plan.get("accepted", false) and last_encounter_error.is_empty()


func _saved_response_mechanical_error(state: Dictionary, saved_player: Dictionary) -> String:
	var environment_error: String = _saved_environment_definition_error(state)
	if not environment_error.is_empty(): return environment_error
	if not _same(hero.equipment.snapshot(), saved_player.equipment): return "Actual candidate equipment must match the supplied saved Player before mechanical response proof"
	var stats: Dictionary = hero.equipment.resolved_stats() # Actual candidate loadout, separately native-validated.
	var decoded: Array[Dictionary] = []
	for raw: Dictionary in state.scheduler.reservations:
		var shape: Dictionary = _decode_shape(raw.geometry)
		var error: String = Geometry.error(shape)
		if not error.is_empty(): return error
		decoded.append({"record": raw, "shape": shape})
	for item: Dictionary in decoded:
		var record: Dictionary = item.record
		var proof: Dictionary = state.framing[record.source_id].action_escape
		var path: Array[Dictionary] = []
		for segment: Dictionary in proof.path:
			path.append({"from": Codec.read_vector3(segment["from"]), "to": Codec.read_vector3(segment["to"]), "start_s": segment.start_s, "end_s": segment.end_s, "kind": segment.kind})
		for segment: Dictionary in path:
			var motion: Vector3 = segment["to"] - segment["from"]
			if segment.kind in ["escape_dash", "positioning_dash"]:
				var precision: float = BodySweep.position_rounding_bound(segment["from"], segment["to"])
				if absf(motion.y) > BodySweep.EPSILON or absf(motion.length() - float(stats.dash_distance)) > precision or not is_equal_approx(float(segment.end_s) - float(segment.start_s), float(stats.dash_duration)): return "Accepted response retains its actual full native dash distance/duration"
			elif motion != Vector3.ZERO: return "Accepted stationary response segment moved"
			var swept: Dictionary = BodySweep.sweep(hero, Transform3D(Basis.IDENTITY, segment["from"]), motion, scheduler_bindings().floors.values())
			if swept.has("error") or swept.get("collided", true) or not swept.get("end") is Vector3 or swept.end.distance_to(segment["to"]) > BodySweep.position_rounding_bound(segment["from"], segment["to"]): return "Saved ordinary response lacks actual full capsule static-floor/scenery support"
		for threat: Dictionary in decoded:
			if Geometry.timed_path_hits(threat.shape, path, float(threat.record.active_from_s), float(threat.record.active_until_s), float(_player_body.radius) + CinderThreatScheduler.SKIN): return "Saved original ordinary response intersects the committed native threat union"
		var opening: Vector3 = Codec.read_vector3(record.opening_position)
		var attack: Vector3 = Codec.read_vector3(proof.attack_position)
		var adapter: Dictionary = record.get("adapter", {})
		var endpoint_reserve: float = NativeMotion.ENDPOINT_TOLERANCE if adapter.get("kind") == "lunge" and not adapter.get("finished", false) else 0.0
		if Vector2(opening.x - attack.x, opening.z - attack.z).length() > float(stats.primary_range) - endpoint_reserve - CinderThreatScheduler.SKIN or absf(opening.y - attack.y) > 1.4: return "Saved ordinary primary cannot reach actual stopped native source"
		var ray := PhysicsRayQueryParameters3D.create(attack + Vector3.UP * .7, opening + Vector3.UP * .7, 1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Actual static scenery blocks the saved ordinary-primary opening"
		if float(proof.response_complete_s) < float(proof.primary_time_s) + float(stats.primary_cooldown): return "Saved ordinary response truncates the actual primary recovery"
	return "" # Pure mechanical proof; Shared34 checks actual optics after quiet commit.


func _saved_environment_definition_error(state: Dictionary) -> String:
	# Authored immutable choices only; native Field/Consumer validators still own
	# every supply, phase, episode, deadline and Route. No clock equality is assumed.
	for id: String in FIELD_IDS:
		if state.fields[id] == null: continue
		var expected: Dictionary = {"id": id, "parameters": {"radius": Layout.FIELD_RADIUS, "duration_s": 3.0, "thinning_s": .5}, "clusters": [{"id": CLUSTER_IDS[0], "offset": Codec.vector3(Layout.CLUSTER_OFFSETS[0])}, {"id": CLUSTER_IDS[1], "offset": Codec.vector3(Layout.CLUSTER_OFFSETS[1])}]}
		if not _same(state.fields[id].definition, expected): return "Saved Field differs from actual authored finite definition: " + id
	var directions: Array = []
	for direction: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]: directions.append(Codec.vector3(direction))
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]: directions.append(Codec.vector3(Vector3(x, 0, z).normalized()))
	for room: String in CONSUMER_ROOMS:
		if state.consumers[room] == null: continue
		var expected: Dictionary = {"id": "a1_l3_" + room + "_spores", "directions": directions, "parameters": Repulsion.DEFAULTS.duplicate(true)}
		if not _same(state.consumers[room].definition, expected): return "Saved Consumer differs from actual authored native definition: " + room
	return ""


func _cue_part_settings(part: MeshInstance3D) -> Array:
	var material := part.material_override as StandardMaterial3D
	if material == null or material.get_script() != null or material.next_pass != null: return []
	# Native phase owns color/visibility/mesh. Fixed required depth and renderer
	# settings remain the actual ready readbacks, never repaired during capture.
	return [part.get_script(), part.layers, part.cast_shadow, part.material_overlay, part.transparency, part.extra_cull_margin, part.visibility_range_begin, part.visibility_range_end, part.visibility_range_fade_mode, part.ignore_occlusion_culling, material.shading_mode, material.transparency, material.cull_mode, material.texture_filter, material.no_depth_test, material.albedo_texture]


func _native_cue_resources_error(id: String) -> String:
	var retained: Variant = _retained_cues.get(id)
	if not is_instance_valid(retained) or not retained is CinderThreatCue: return "Retain actual required native cue before typed validation: " + id
	var cue: CinderThreatCue = retained
	if not cue.is_inside_tree() or cue.is_queued_for_deletion() or cue.get_parent() != sources.get(id) or cue.get_script() != CinderThreatCue or not cue.is_in_group("required_cues") or not cue.is_set_as_top_level() or not cue.visible: return "Retain actual required native threat cue: " + id
	var shown: Dictionary = cue.state() # Pure logical read; no prune/presentation.
	if cue.global_basis != Basis.IDENTITY: return "Retain the native identity threat-cue world basis: " + id
	if shown.phase != "clear":
		if not Geometry.error(shown.geometry).is_empty() or cue.global_position != NativeCueMesh.anchor(shown.geometry): return "Actual threat cue moved from its native logical geometry anchor: " + id
	var pins: Dictionary = _cue_parts.get(id, {})
	for part_name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		if not pins.has(part_name): return "Actual ready native cue pins absent"
		var pin: Dictionary = pins[part_name]
		var part := cue.get_node_or_null(part_name) as MeshInstance3D
		if not is_instance_valid(part) or part != pin.node or not part.is_inside_tree() or part.is_queued_for_deletion() or part.get_parent() != cue or part.is_set_as_top_level() or part.material_override != pin.material or _cue_part_settings(part) != pin.settings: return "Retain actual native threat-cue node/material/settings: " + id
		if part_name != "RequiredSourceMarker" and part.transform != pin.transform: return "Retain actual native footprint local frame: " + id
		if part_name == "RequiredSourceMarker" and part.basis != pin.transform.basis: return "Retain actual native source glyph basis: " + id
		if shown.phase == "clear":
			if part.mesh != null or part.visible: return "Clear native cue cannot retain visible threat meshes: " + id
			continue
		var expected: ArrayMesh
		var expected_visible: bool
		if part_name == "RequiredSourceMarker":
			expected = NativeCueMesh.source_mesh(shown.phase)
			expected_visible = true
			if part.position != shown.source_position - cue.global_position + Vector3.UP * pin.transform.origin.y: return "Actual source glyph moved from the native cue source"
		else:
			expected = NativeCueMesh.geometry_mesh(shown.geometry, part_name == "RequiredFootprintFill")
			expected_visible = shown.phase == "active" if part_name == "RequiredFootprintFill" else shown.phase != "recovery"
		if part.visible != expected_visible or not _same_native_mesh(part.mesh, expected): return "Required native phase mesh/visibility changed: " + id
	return ""


func _same_native_mesh(actual: Variant, expected: ArrayMesh) -> bool:
	if not is_instance_valid(actual) or not actual is ArrayMesh or not is_instance_valid(expected): return false
	var native: ArrayMesh = actual
	if native.get_aabb() != expected.get_aabb() or native.get_surface_count() != expected.get_surface_count(): return false
	for surface: int in range(expected.get_surface_count()):
		if native.surface_get_primitive_type(surface) != expected.surface_get_primitive_type(surface) or native.surface_get_arrays(surface) != expected.surface_get_arrays(surface): return false
	return true


func _actual_hero_points(endpoint: Vector3) -> Array:
	# Explicit ACTUAL Hero/current native camera. Never Shell.player; never saved
	# Player interpretation or pristine-spawn-to-saved-room translation.
	var camera: Camera3D = _actual_presentation_camera()
	if not endpoint.is_finite() or not is_instance_valid(hero) or not is_instance_valid(shared_shell) or camera == null: return []
	var raw: Variant = shared_shell.call("player_camera_framing_points_for", hero, camera)
	if not raw is Array or raw.size() != 22: return [] # native capsule8 + quad6 + shadow8
	var points: Array = []
	for point: Variant in raw:
		if not point is Vector3 or not point.is_finite(): return []
		# Additional genuine future response anchors use the CURRENT real geometry.
		# Actual mandatory Hero corners are separately retained at its real pose.
		points.append(point + endpoint - hero.global_position)
	return points


func _decode_shape(encoded: Dictionary) -> Dictionary:
	var shape: Dictionary = encoded.duplicate(true)
	for key: String in ["origin", "direction", "from", "to", "source_position"]:
		if shape.has(key): shape[key] = Codec.read_vector3(shape[key])
	return shape


func _restore_local_state(state: Dictionary) -> void:
	_quiet_commit = true
	var restored: bool = _aggregate.call("restore_native_state", state, hero.snapshot_state(), _aggregate_bindings(), _authored_definitions())
	if not restored:
		_quiet_commit_error = String(_aggregate.get("last_commit_error"))
		if _quiet_commit_error.is_empty(): _quiet_commit_error = "Whole native quiet commit unexpectedly refused"
		_quiet_commit = false
		_freeze_failed_candidate()
		return
	beat_index = state.beat_index
	completed_beats.assign(state.completed_beats)
	room_stage = state.room_stage
	encounter_started = room_stage == "active"
	_accepted_frames = state.framing.duplicate(true)
	_framing.clear()
	for id: String in state.framing:
		var frame: Dictionary = state.framing[id].duplicate(true)
		frame["landing"] = Codec.read_vector3(frame.landing)
		frame["attack_position"] = Codec.read_vector3(frame.attack_position)
		_framing[id] = frame
	_clear_forecast_hint()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()
	last_admission.clear()
	_refresh_render_state()
	_quiet_commit_error = _sync_clusters()
	if _quiet_commit_error.is_empty():
		_apply_route_presentation()
		if _quiet_commit_error.is_empty(): _quiet_commit_error = route_snapshot_runtime_error()
	_quiet_commit = false
	if not _quiet_commit_error.is_empty(): _freeze_failed_candidate()


func _freeze_failed_candidate() -> void:
	# Never hide a failed void-hook commit behind Base's true return/readiness.
	# Stop playback; the Shell sees false and disposes this nonplayable world.
	_running = false
	_clear_forecast_hint()
	for retained: Variant in sources.values():
		if not is_instance_valid(retained) or not retained is Act1MushroomSelenite: continue
		var actor: Act1MushroomSelenite = retained
		actor.set_physics_process(false)
	for retained: Variant in _fields.values():
		if not is_instance_valid(retained) or not retained is CinderSporeField: continue
		var field: CinderSporeField = retained
		field.set_physics_process(false)
	if is_instance_valid(scheduler): scheduler.set_physics_process(false)
	set_physics_process(false)


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


func _on_exit_level() -> void:
	_constructor_open = false
	_constructor_entitlements.clear()
	_accepted_frames.clear()
	if native_admission_published.is_connected(_record_native_admission): native_admission_published.disconnect(_record_native_admission)
	super._on_exit_level()
