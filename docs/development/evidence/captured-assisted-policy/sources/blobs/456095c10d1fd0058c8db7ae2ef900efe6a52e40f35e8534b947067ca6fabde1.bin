class_name CinderAct3CrystalmanLevel
extends CinderLevel
## SOURCE-ONLY complete authored parent candidate. Native import/flows/art pending.
## One permanent parent floor, one current native unit, one Shell-owned Hero.
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Approach = preload("res://scripts/acts/act3/crystalman_approach_unit.gd")
const CapturePhase = preload("res://scripts/acts/act3/crystalman_capture_phase.gd")
const Scenery = preload("res://scripts/acts/act3/crystalman_scenery.gd")
const ParentCodec = preload("res://scripts/acts/act3/crystalman_parent_codec.gd")
const ContactCue = preload("res://scripts/cues/interaction_cue.gd")
const LayoutPath: String = "res://data/campaign/act3/crystalman_layout.json"
const FLOOR_ID: String = "firm-crystalman-route"
const FULL_RECT := Rect2(-6,-14,12,54)
const ARENA_RECT := Rect2(-6,-8,12,16)
const CAPTURE_POCKET := Rect2(-1.5,-2.9,3,5.8)
const EXIT_RECT := Rect2(-1.2,-11.65,2.4,1.3)
const CHECKPOINTS: Array[String] = ["crystalman-offered-entry","crystalman-plain-entry","crystalman-phase1-entry","crystalman-phase2-entry","crystalman-bare-platform"]
const KINDS: Array[String] = ["encounter","encounter","boss_phase","boss_phase","encounter"]
const COMPLETE_ID: String = "crystalman-local-tethers-released"
const EXIT_ID: String = "crystalman-local-escape"
var current_unit: CinderLevel
var scenery: Node3D
var floor_body: StaticBody3D
var floor_collision: CollisionShape3D
var exit_cue: CinderInteractionCue
var last_configuration_error: String = ""
var _layout: Dictionary = {}
var _layout_sha: String = ""
var _floor_shape: BoxShape3D
var _blockers: Array[Dictionary] = []
var _floor_signature: Array = []
var _stage: int = 0
var _active: bool = false
var _entries: Array[Dictionary] = []
var _regular_metadata: Dictionary = {}
var _phase_metadata: Array[Dictionary] = []
var _pending_checkpoint: int = -1
var _phase_observed: bool = false
var _transition_queued: bool = false
var _transition_busy: bool = false
var _exit_queued: bool = false
var _exit_generation: int = 0
var _exit_state: String = "clear"
var _contact: Dictionary = {}
var _codec = ParentCodec.new()
var _capture_camera: Camera3D
var _capture_hud: GameHUD
var _capture_error: String = ""
var _restore_expected: Dictionary = {}
var _restore_finished: bool = false

func _ready() -> void:
	level_id = "A3-L5"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 140
	var raw: String = FileAccess.get_file_as_string(LayoutPath)
	var decoded: Variant = JSON.parse_string(raw)
	if not decoded is Dictionary or decoded.get("level_id") != "A3-L5": last_configuration_error = "Exact authored Crystalman layout required"; return
	_layout = decoded
	_layout_sha = raw.sha256_text()
	if get_node_or_null("PlayerSpawn") == null:
		var spawn := Marker3D.new()
		spawn.name = "PlayerSpawn"
		spawn.position = Vector3(0,0.1,34)
		add_child(spawn)
	floor_body = StaticBody3D.new()
	floor_body.name = "PermanentFirmFloor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	floor_body.position = Vector3(0,-0.5,13)
	add_child(floor_body)
	floor_collision = CollisionShape3D.new()
	floor_collision.name = "Solid"
	_floor_shape = BoxShape3D.new()
	_floor_shape.size = Vector3(12,1,54)
	floor_collision.shape = _floor_shape
	floor_body.add_child(floor_collision)
	for row: Dictionary in _layout.floor.fixed_blockers:
		var body := StaticBody3D.new()
		body.name = row.id
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Value.read_vector3(row.center_world)
		add_child(body)
		var shape := CollisionShape3D.new()
		shape.name = "Solid"
		var box := BoxShape3D.new()
		box.size = Value.read_vector3(row.size_world)
		shape.shape = box
		body.add_child(shape)
		var mesh := MeshInstance3D.new()
		mesh.name = "GroundedPermanentSideEdge"
		var primitive := BoxMesh.new()
		primitive.size = box.size
		mesh.mesh = primitive
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.albedo_color = Color("292331")
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(mesh)
		_blockers.append({"body":body,"collision":shape,"shape":box,"transform":body.global_transform,"size":box.size,"mesh":mesh,"material":material})
	scenery = Scenery.new()
	scenery.name = "AuthoredCrystalLandscapeAndDryShore"
	add_child(scenery)
	if not scenery.call("build",floor_body): last_configuration_error = "Original authored scenery construction refused"; return
	var signature: Dictionary = Footprint.floor_signature(self,[crystalman_regular_floor_binding()])
	if not signature.get("accepted",false): last_configuration_error = String(signature.get("reason","Permanent route floor refused")); return
	_floor_signature = signature.signature.duplicate(true)
	var marker := Node3D.new()
	marker.name = "PlainContactExit"
	marker.position = Vector3(0,0,-11)
	add_child(marker)
	exit_cue = ContactCue.new()
	exit_cue.name = "CanonicalContactCue"
	marker.add_child(exit_cue)

func contract_error() -> String:
	var error: String = super.contract_error()
	return error if not error.is_empty() else last_configuration_error

func crystalman_regular_floor_binding() -> Dictionary:
	return {"collision":floor_collision,"safe_rect":FULL_RECT}

func crystalman_capture_floor_binding() -> Dictionary:
	return {"api_revision":"act3-crystalman-external-floor-1","world_root":self,"floor_id":FLOOR_ID,"collision":floor_collision,"safe_rect":ARENA_RECT}

func crystalman_source_rows() -> Dictionary:
	var result: Dictionary = {}
	for original: Dictionary in _layout.sources:
		var row: Dictionary = original.duplicate(true)
		if row.kind == "echo":
			row["source_epoch_recipe"] = row.source_epoch
			row["definition_id"] = row.id+"/straight-return"
			row["definition_translation_world"] = row.fixed_knot_world.duplicate()
			row["slash_origin_world"] = row.fixed_knot_world.duplicate()
		result[row.id] = row
	return result

func parent_native_error() -> String:
	if not last_configuration_error.is_empty(): return last_configuration_error
	if global_transform != Transform3D.IDENTITY or not is_instance_valid(hero) or not is_instance_valid(shared_shell): return "Exact actual outer parent/shared Hero/Shell required"
	if not is_instance_valid(floor_body) or floor_body.get_parent()!=self or floor_body.global_transform!=Transform3D(Basis.IDENTITY,Vector3(0,-0.5,13)) or floor_body.collision_layer!=1 or floor_body.collision_mask!=0 or floor_collision.get_parent()!=floor_body or floor_collision.disabled or floor_collision.transform!=Transform3D.IDENTITY or floor_collision.shape!=_floor_shape or _floor_shape.size!=Vector3(12,1,54): return "Retained immutable parent54m floor required"
	var signature: Dictionary = Footprint.floor_signature(self,[crystalman_regular_floor_binding()])
	if not signature.get("accepted",false) or not ParentCodec.same(signature.signature,_floor_signature): return "Actual original floor signature changed"
	for row: Dictionary in _blockers:
		if not is_instance_valid(row.body) or row.body.get_parent()!=self or row.body.global_transform!=row.transform or row.body.constant_linear_velocity!=Vector3.ZERO or row.body.constant_angular_velocity!=Vector3.ZERO or row.body.get_child_count()!=2 or row.collision.get_parent()!=row.body or row.collision.transform!=Transform3D.IDENTITY or row.collision.disabled or row.collision.shape!=row.shape or row.shape.size!=row.size or row.body.collision_layer!=1 or row.body.collision_mask!=0: return "Original permanent visible side blockers changed"
	if not is_instance_valid(scenery) or scenery.get_script()!=Scenery or scenery.get_parent()!=self: return "Actual original authored scenery recipient required"
	var error: String = String(scenery.call("runtime_error"))
	if not error.is_empty(): return error
	if not is_instance_valid(exit_cue) or exit_cue.get_script()!=ContactCue or exit_cue.get_parent().get_parent()!=self or exit_cue.get_parent().position!=Vector3(0,0,-11): return "Actual retained contact recipient required"
	return ""

func _on_enter_level() -> void:
	if not last_configuration_error.is_empty(): return
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_error_for_context"): last_configuration_error = "Actual canonical portrait services required"; return
	_active = true
	current_unit = Approach.new()
	current_unit.name = "CurrentRegularApproach"
	add_child(current_unit)
	current_unit.enter_level(hero,effects,shared_shell)
	if not String(current_unit.get("last_configuration_error")).is_empty(): _fail(String(current_unit.get("last_configuration_error"))); return
	_record_entry(0)
	_update_presentation()

func _physics_process(_delta: float) -> void:
	if not _active or _transition_busy or not is_instance_valid(hero) or hero.dead: return
	if not parent_native_error().is_empty(): _fail(parent_native_error()); return
	if _stage==0 and current_unit.call("source_dead","l5-offered-echo") and _capsule_inside(Rect2(-6,-14,12,36)):
		if current_unit.call("advance_to_plain"):
			_stage=1
			if not scenery.call("present_stage",_stage): _fail("Original priority scenery stage declined"); return
			_record_entry(1)
	elif _stage==1 and current_unit.call("all_regular_clear") and _capsule_inside(CAPTURE_POCKET) and _actor_stable_for_capture(): _queue_transition("capture-entry")
	elif _stage in [2,3] and _phase_observed: _queue_transition("phase-spent")
	_update_presentation()
	# Let the Shell persist this checkpoint before publishing completion.
	if _dispatch_checkpoint_if_safe(): return
	if not _active or get_tree().paused or hero.dead: return
	if _stage==4 and _pending_checkpoint<0:
		if not is_completed(): request_completion(COMPLETE_ID)
		if _exit_state=="available" and _capsule_inside(EXIT_RECT) and not _exit_queued:
			_exit_state="active"
			_contact={"actor_clock_s":hero.get_world_action_clock(),"hero_position":Value.vector3(hero.global_position),"exit_id":EXIT_ID}
			_exit_queued=true
			_exit_generation+=1
			_finish_exit.call_deferred(_exit_generation)

func _actor_stable_for_capture() -> bool:
	var response: Dictionary = hero.get_threat_response_state()
	return response.stable and float(response.commitment_remaining_s)==0.0 and String(response.pending_weapon_id).is_empty()

func _capsule_inside(rect: Rect2) -> bool:
	if not is_instance_valid(hero) or hero.dead or not hero.is_on_floor(): return false
	var collision: CollisionShape3D = hero.get_node_or_null("BodyCollision") as CollisionShape3D
	if collision==null or collision.disabled or not collision.shape is CapsuleShape3D or collision.global_basis!=Basis.IDENTITY: return false
	var shape: CapsuleShape3D = collision.shape as CapsuleShape3D
	if not is_finite(shape.radius) or shape.radius<=0 or absf(collision.global_position.y-shape.height*0.5)>0.2: return false
	return rect.grow(-shape.radius).has_point(Vector2(collision.global_position.x,collision.global_position.z))

func _record_entry(stage: int) -> void:
	_entries.append({"stage":stage,"actor_clock_s":hero.get_world_action_clock(),"hero_position":Value.vector3(hero.global_position)})
	_pending_checkpoint=stage

func _queue_transition(_kind: String) -> void:
	if _transition_queued or _transition_busy or get_tree().paused: return
	_transition_queued=true
	_finish_transition.call_deferred()

func _on_tether_severed(_untrusted: Dictionary) -> void:
	if _active and _stage in [2,3]: _phase_observed=true

func _on_recording_joined(_untrusted: Dictionary) -> void:
	if _active and is_instance_valid(current_unit): objective_text=current_unit.objective_text

func _finish_transition() -> void:
	_transition_queued=false
	if not _active or _transition_busy or get_tree().paused or not is_instance_valid(current_unit) or hero.dead: return
	if _stage in [2,3] and current_unit.call("state").get("phase")!="spent": return
	_transition_busy=true
	get_tree().paused=true
	var player_before: Dictionary = hero.snapshot_state()
	var floor_before: Array = _floor_signature.duplicate(true)
	var metadata: Dictionary = {}
	if _stage==1:
		metadata=current_unit.call("closed_regular_metadata")
	elif _stage in [2,3]:
		metadata=current_unit.call("closed_phase_metadata")
	if metadata.is_empty() or (_stage in [2,3] and not metadata.get("accepted",false)):
		_transition_busy=false
		if not bool(shared_shell.call("is_pause_requested")): get_tree().paused=false
		return # Genuine native boundary has not settled; no invented completion.
	var old: CinderLevel = current_unit
	current_unit=null
	_disconnect_unit(old)
	old.exit_level()
	old.free() # Permanent floor lives under this outer parent, never the child.
	if not ParentCodec.same(player_before,hero.snapshot_state()) or not ParentCodec.same(floor_before,Footprint.floor_signature(self,[crystalman_regular_floor_binding()]).get("signature")):
		_fail("Whole current-unit disposal changed actual Player/floor; preserve failure")
	else:
		if _stage==1:
			_regular_metadata=metadata.duplicate(true)
			_stage=2
			_install_capture(1)
		elif _stage==2:
			_phase_metadata.append(metadata.duplicate(true))
			_stage=3
			_install_capture(2) # Fresh Scheduler; no wait for old finite recovery.
		else:
			_phase_metadata.append(metadata.duplicate(true))
			_stage=4
			_exit_state="available"
		_phase_observed=false
		_record_entry(_stage)
		if not scenery.call("present_stage",_stage): _fail("Original authored strip/coda recipient declined")
	_update_presentation()
	_transition_busy=false
	if is_inside_tree() and not bool(shared_shell.call("is_pause_requested")): get_tree().paused=false

func _install_capture(capacity: int) -> void:
	current_unit=CapturePhase.new()
	current_unit.name="CurrentCapturePhase%d"%capacity
	current_unit.set("capture_slots",capacity)
	add_child(current_unit)
	current_unit.enter_level(hero,effects,shared_shell)
	current_unit.connect("tether_severed",_on_tether_severed)
	current_unit.connect("recording_joined",_on_recording_joined)
	if not String(current_unit.get("last_configuration_error")).is_empty(): _fail(String(current_unit.get("last_configuration_error")))

func _disconnect_unit(unit: CinderLevel) -> void:
	if unit.has_signal("tether_severed") and unit.is_connected("tether_severed",_on_tether_severed): unit.disconnect("tether_severed",_on_tether_severed)
	if unit.has_signal("recording_joined") and unit.is_connected("recording_joined",_on_recording_joined): unit.disconnect("recording_joined",_on_recording_joined)

func _dispatch_checkpoint_if_safe() -> bool:
	if _pending_checkpoint<0 or _transition_queued or _transition_busy or get_tree().paused or is_restore_candidate() or is_completed() or not _actor_stable_for_capture() or not _capsule_inside(FULL_RECT): return false
	if _stage in [0,1] and current_unit.call("has_held_attacks"): return false
	if _stage in [2,3]:
		var state: Dictionary = current_unit.call("state")
		if state.phase!="recording" or state.capture.capture.allocated!=0 or state.capture.capture.has_dash_candidate: return false
	if not candidate_presentation_error(get_viewport().get_camera_3d(),shared_shell.get("hud")).is_empty(): return false
	if request_checkpoint(CHECKPOINTS[_pending_checkpoint],KINDS[_pending_checkpoint]):
		_pending_checkpoint=-1
		return true
	return false

func _finish_exit(generation: int) -> void:
	if generation!=_exit_generation: return
	_exit_queued=false
	if not _active or hero.dead or not is_completed() or _stage!=4 or _exit_state!="active": return
	_exit_state="spent"
	if not request_contact_exit(EXIT_ID,hero):
		_exit_state="available"
		_contact.clear()
	_update_presentation()

func _update_presentation(quiet: bool = false) -> void:
	if is_instance_valid(current_unit): objective_text=current_unit.objective_text
	elif _stage==4: objective_text="THE IMAGE FALLS AWAY\nCONTACT THE PLAIN SHORE"
	if not last_configuration_error.is_empty(): objective_text="CRYSTALMAN UNAVAILABLE"
	if is_instance_valid(exit_cue):
		var blocked: bool = exit_cue.is_blocking_signals()
		if quiet: exit_cue.set_block_signals(true)
		if _exit_state=="clear": exit_cue.clear()
		else: exit_cue.present(_exit_state,"contact")
		exit_cue.set_block_signals(blocked)

func _camera_framing_points() -> Array:
	if not _active or not is_instance_valid(hero): return []
	# A live pending Echo forecast lets the ordinary shared camera settle
	# before admission. Paused writers and candidate optics stay committed-only.
	var union: Dictionary = parent_framing_union(get_viewport().get_camera_3d(),false,not get_tree().paused and not is_restore_candidate())
	last_camera_framing_error=String(union.error)
	return union.points if last_camera_framing_error.is_empty() else []

func parent_framing_union(camera: Camera3D,current_view: bool = false,include_pending: bool = false) -> Dictionary:
	var points: Array = []
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not is_instance_valid(camera): return {"error":"Actual Hero/Shell/Camera required","points":[]}
	if is_instance_valid(current_unit):
		if _stage in [0,1]:
			var group: Dictionary = current_unit.call("camera_framing_union","",[],current_view,include_pending,{},camera)
			if not String(group.error).is_empty(): return group
			points.append_array(group.points)
		else: points.append_array(current_unit.call("captured_codec_framing_union",camera))
	if points.is_empty(): points.append_array(shared_shell.call("player_camera_framing_points_for",hero,camera))
	# A distant contact destination must not pull the close following camera
	# away from the traveller. Its existing world cue remains available;
	# require it in the protected view within the final four-metre approach.
	if _exit_state!="clear" and Vector2(hero.global_position.x,hero.global_position.z+11.0).length()<=4.0:
		var marker: MeshInstance3D = exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
		if marker==null or marker.mesh==null: return {"error":"Actual current contact marker required","points":[]}
		for index: int in range(8): points.append(marker.global_transform*marker.mesh.get_aabb().get_endpoint(index))
	return {"error":"" if points.size()<=224 else "Complete required native groups exceed224","points":points}

func candidate_presentation_error(camera: Camera3D,hud: GameHUD) -> String:
	var union: Dictionary = parent_framing_union(camera,true)
	if not String(union.error).is_empty(): return String(union.error)
	return String(shared_shell.call("camera_framing_error_for_context",union.points,hero,camera,hud))

func parent_owned_state() -> Dictionary:
	return {"stage":_stage,"entries":_entries.duplicate(true),"regular_metadata":_regular_metadata.duplicate(true),"phase_metadata":_phase_metadata.duplicate(true),"pending_checkpoint":_pending_checkpoint,"phase_observed":_phase_observed,"exit_state":_exit_state,"contact":_contact.duplicate(true)}

func parent_boundary_error() -> String:
	if not is_inside_tree() or not get_tree().paused or _transition_queued or _transition_busy or _exit_queued: return "Whole parent requires settled paused callback boundary"
	return parent_native_error()

func parent_apply_owned_state(route: Dictionary,presentation: Dictionary) -> String:
	_stage=route.stage
	_entries.clear()
	for row: Dictionary in route.entries: _entries.append(row.duplicate(true))
	_regular_metadata=route.regular_metadata.duplicate(true)
	_phase_metadata.clear()
	for row: Dictionary in route.phase_metadata: _phase_metadata.append(row.duplicate(true))
	_pending_checkpoint=route.pending_checkpoint
	_phase_observed=route.phase_observed
	_exit_state=route.exit_state
	_contact=route.contact.duplicate(true)
	if not scenery.call("restore_presentation",presentation,_stage): return "Quiet original landscape/coda display declined"
	_transition_queued=false
	_transition_busy=false
	_exit_queued=false
	_exit_generation+=1
	_active=true
	_update_presentation(true)
	return parent_native_error()

func _fail(reason: String) -> void:
	last_configuration_error=reason
	_update_presentation()

func _on_exit_level() -> void:
	_active=false
	_transition_queued=false
	_phase_observed=false
	_exit_generation+=1
	_exit_queued=false
	if is_instance_valid(current_unit):
		_disconnect_unit(current_unit)
		current_unit.exit_level()
		current_unit.free()
		current_unit=null
	if is_instance_valid(exit_cue): exit_cue.clear()

func snapshot_state() -> Dictionary:
	return _capture_checked(null,null)

func snapshot_state_for_presentation(camera: Camera3D,hud: GameHUD) -> Dictionary:
	if not is_instance_valid(camera) or not is_instance_valid(hud): last_snapshot_error="Actual fresh Camera/HUD pair required"; return {}
	return _capture_checked(camera,hud)

func _capture_checked(camera: Camera3D,hud: GameHUD) -> Dictionary:
	_capture_camera=camera
	_capture_hud=hud
	_capture_error=""
	var unit: Dictionary=super.snapshot_state()
	_capture_camera=null
	_capture_hud=null
	if not _capture_error.is_empty(): last_snapshot_error=_capture_error; return {}
	return unit

func _capture_local_state() -> Dictionary:
	var unit: Dictionary=_codec.capture(self,hero.snapshot_state(),_capture_camera,_capture_hud)
	_capture_error=_codec.last_error
	return unit

func _local_snapshot_error(local: Dictionary) -> String:
	return _codec.record_error(local,self,hero.snapshot_state())

func _local_snapshot_error_with_player(local: Dictionary,player: Dictionary) -> String:
	return _codec.record_error(local,self,player)

func _snapshot_envelope_error(snapshot: Dictionary) -> String:
	var error: String=super._snapshot_envelope_error(snapshot)
	return error if not error.is_empty() else _codec.progress_error(snapshot.local,snapshot.progress,self)

func restore_candidate_construction_required() -> bool:
	return true

# Published registration opt-in; immutable native query floor is ready first.
func restore_candidate_physics_registration_required() -> bool:
	return true

func _on_enter_restore_candidate(local: Dictionary,player: Dictionary) -> String:
	_active=false
	var error: String=_codec.header_error(local,self,player)
	if not error.is_empty(): return error
	var stage: int=local.route.stage
	if stage<2:
		current_unit=Approach.new()
		current_unit.name="CurrentRegularApproach"
	elif stage<4:
		current_unit=CapturePhase.new()
		current_unit.name="CurrentCapturePhase%d"%(stage-1)
		current_unit.set("capture_slots",stage-1)
	if is_instance_valid(current_unit):
		add_child(current_unit)
		if not current_unit.call("prepare_parent_restore",local.current_unit.state,player,hero,effects,shared_shell): return current_unit.last_snapshot_error
		if stage in [2,3]:
			current_unit.connect("tether_severed",_on_tether_severed)
			current_unit.connect("recording_joined",_on_recording_joined)
	return _codec.record_error(local,self,player)

func _restore_local_state(local: Dictionary) -> void:
	_restore_expected=local.duplicate(true)
	_restore_finished=_codec.restore_local(local,self,hero.snapshot_state())
	last_snapshot_error=_codec.last_error

func restore_state(snapshot: Dictionary) -> bool:
	if not is_restore_candidate(): last_snapshot_error="Fresh whole parent candidate required"; return false
	var ok: bool=super.restore_state(snapshot)
	if not _restore_finished: last_snapshot_error=_codec.last_error; return false
	return ok

func _restore_candidate_presentation_error(camera: Camera3D,hud: GameHUD) -> String:
	if not _restore_finished: return "Actual whole quiet parent required before native optics"
	return _codec.verify_candidate(_restore_expected,self,hero.snapshot_state(),camera,hud)

func finish_restore_candidate() -> bool:
	if is_instance_valid(current_unit) and not current_unit.finish_restore_candidate(): return false
	var ok: bool=super.finish_restore_candidate()
	if ok: _restore_expected.clear(); _restore_finished=false
	return ok

func parent_blocker_recipe() -> Array:
	var result: Array=[]
	for row: Dictionary in _blockers:
		result.append({"id":String(row.body.name),"position":Value.vector3(row.body.global_position),"size":Value.vector3(row.shape.size),"layer":row.body.collision_layer,"mask":row.body.collision_mask})
	return result
