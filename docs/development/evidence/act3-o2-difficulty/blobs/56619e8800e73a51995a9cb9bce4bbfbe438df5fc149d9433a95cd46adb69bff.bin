extends CinderLevel
## Authored O2: three sequential familiar Root courts on stable forest floor.
## Four actual Root deaths clear the courts; the final Stalker is optional pressure.
## CP1/CP2 save coherent next-court activation; third clear completes only.
## Versioned ground-slot metadata binds before native once-configuration.
## Legacy API2/schema1 remains literal; only fresh Challenge changes ground slots.

const ForestScenery = preload("res://scripts/acts/act3/living_forest_scenery.gd")
const RootScript = preload("res://scripts/acts/act3/garden_root_latcher.gd")
const StalkerScript = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const InteractionCue = preload("res://scripts/cues/interaction_cue.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const ENCOUNTER_DATA: String = "res://data/campaign/act3/a3_o2_encounters.json"
const ENCOUNTER_ID: String = "A3-O2/quiet-root-circuit"
const LEGACY_ROUTE_API: String = "act3-quiet-root-circuit-2"
const ROUTE_API: String = "act3-quiet-root-circuit-3"
const LOCAL_VERSION: int = 2
const WORLD_REVISION: int = 1
const COMPLETION_ID: String = "three-root-courts-cleared"
const EXIT_ID: String = "quiet-root-return-threshold"
const COURT_IDS: Array[String] = ["first-root-court", "rearranged-root-court", "final-source-choice"]
const SOURCE_IDS: Array[String] = ["o2-first-root", "o2-second-root", "o2-final-west-root", "o2-final-east-root", "o2-final-stalker"]
const ROOT_IDS: Array[String] = ["o2-first-root", "o2-second-root", "o2-final-west-root", "o2-final-east-root"]
const SOURCE_KINDS: Dictionary = {"o2-first-root":"root", "o2-second-root":"root", "o2-final-west-root":"root", "o2-final-east-root":"root", "o2-final-stalker":"stalker"}
const SOURCE_COURTS: Dictionary = {"o2-first-root":0, "o2-second-root":1, "o2-final-west-root":2, "o2-final-east-root":2, "o2-final-stalker":2}
const SOURCE_POSITIONS: Dictionary = {"o2-first-root":Vector3(0,0,4), "o2-second-root":Vector3(1.4,0,-1), "o2-final-west-root":Vector3(-1.2,0,-6), "o2-final-east-root":Vector3(1.2,0,-6), "o2-final-stalker":Vector3(0,0.1,-4.5)}
const LEGACY_RECIPE_IDS: Dictionary = {"assisted":"A3-O2/assisted-canonical@v1", "standard":"A3-O2/standard-canonical@v1", "challenge":"A3-O2/challenge-canonical-legacy@v1"}
const CHALLENGE_RECIPE: String = "A3-O2/challenge-forward-knot@v2"
const LEGACY_LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route"]
const ARRANGEMENT_LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route", "arrangement"]
const CHECKPOINT_IDS: Array[String] = ["first-root-court-cleared", "rearranged-root-court-cleared"]
const FLOOR_RECT: Rect2 = Rect2(-7, -11, 14, 22)
const BASE_POSITION: Vector3 = Vector3(-1.2, 0, 4)
const SECOND_BASE_POSITION: Vector3 = Vector3(0, 0, -1.7)
const GLYPH_POSITIONS: Array[Vector3] = [Vector3(3.8,0.014,4), Vector3(-3.8,0.014,-1), Vector3(3.8,0.014,-6)]
const EXIT_POSITION: Vector3 = Vector3(0, 0, -9)
const EXIT_RECT: Rect2 = Rect2(-1.2, -9.65, 2.4, 1.3)
const PROP_VIEW_DISTANCE: float = 2.7
const SUN_STABLE_S: float = 10.0
const SUN_PREVIEW_S: float = 3.0
const SUN_LOCK_S: float = 1.0
const SUN_PERIOD_S: float = SUN_STABLE_S + SUN_PREVIEW_S + SUN_LOCK_S

var scenery: Node3D
var sources: Dictionary = {}
var threat_scheduler: CinderThreatScheduler
var exit_cue: CinderInteractionCue
var sun_state: int = 0
var sun_elapsed_s: float = 0.0
var sun_stage: String = "stable"
var _floor_region: Dictionary = {}
var _active: bool = false
var _active_court: int = 0
var _clears: Array[Dictionary] = []
var _deaths: Dictionary = {}
var _exit_state: String = "clear"
var _contact: Dictionary = {}
var _configuration_error: String = ""
var _callbacks: Dictionary = {}
var _exit_generation: int = 0
var _exit_queued: bool = false
var _last_sun_view: String = ""
var _glyphs: Array[Node3D] = []
var _glyph_materials: Array[StandardMaterial3D] = []
var _glyph_clear_count: int = -1
var _arrangement_descriptor: Dictionary = {}
var _selected_positions: Dictionary = {}
var _legacy_capture: bool = false
var _sources_configured: bool = false


## Immutable metadata uses the published pure helper; it grants no safety proof.
static func arrangement_definition() -> Dictionary:
	var recipes: Array = []
	for profile: String in Arrangement.PROFILE_IDS:
		recipes.append({"recipe_id":LEGACY_RECIPE_IDS[profile], "profile":profile, "order":SOURCE_IDS.duplicate()})
	var challenge: Array = SOURCE_IDS.duplicate()
	challenge[3] = "o2-final-stalker"
	challenge[4] = "o2-final-east-root"
	recipes.append({"recipe_id":CHALLENGE_RECIPE, "profile":"challenge", "order":challenge})
	return {"schema_version":1, "unit_ids":SOURCE_IDS.duplicate(), "recipes":recipes, "current":{"assisted":LEGACY_RECIPE_IDS.assisted, "standard":LEGACY_RECIPE_IDS.standard, "challenge":CHALLENGE_RECIPE}}


static func arrangement_layout(descriptor: Variant) -> Dictionary:
	var selector := Arrangement.new(arrangement_definition())
	var error: String = selector.saved_error(descriptor)
	if not error.is_empty(): return {"error":error}
	var starts: Dictionary = {}
	for index: int in range(SOURCE_IDS.size()):
		var slot: String = SOURCE_IDS[index]
		var id: String = descriptor.order[index]
		if SOURCE_COURTS[id] != SOURCE_COURTS[slot]: return {"error":"O2 retained recipes cannot exchange court entitlement"}
		var at: Vector3 = SOURCE_POSITIONS[slot]
		at.y = (SOURCE_POSITIONS[id] as Vector3).y
		starts[id] = at
	return {"error":"", "descriptor":selector.restore(descriptor), "starts":starts}


## Pure closed construction receipt only. Full native pair/route checks still
## run after quiet entitled construction and before any physical state commit.
static func arrangement_constructor(local: Variant) -> Dictionary:
	var error: String = Codec.value_error(local)
	if not error.is_empty(): return {"error":error}
	if not local is Dictionary: return {"error":"O2 local unit must be a dictionary"}
	var legacy: bool = local.get("api_revision") == LEGACY_ROUTE_API and Codec.is_integer(local.get("schema_version"),1,1)
	var current: bool = local.get("api_revision") == ROUTE_API and Codec.is_integer(local.get("schema_version"),2,2)
	if not legacy and not current: return {"error":"Unsupported O2 inner API/schema"}
	if not Codec.keys_error(local,LEGACY_LOCAL_KEYS if legacy else ARRANGEMENT_LOCAL_KEYS).is_empty() or not local.get("scenery") is Dictionary or not local.get("scheduler") is Dictionary or not local.get("sources") is Dictionary or not local.get("route") is Dictionary:
		return {"error":"Closed complete O2 arrangement/native local unit required"}
	var profile: Variant = local.scheduler.get("profile")
	if not profile is Dictionary or not profile.get("id") is String: return {"error":"Saved canonical Scheduler profile required for O2 construction"}
	var resolver := Difficulty.new()
	var canonical: Dictionary = resolver.profile(profile.id)
	if canonical.is_empty() or not Codec.same_values(profile,canonical): return {"error":"Saved O2 construction profile differs from the canonical profile"}
	var descriptor: Variant = local.get("arrangement")
	if legacy:
		descriptor = {"schema_version":1, "profile":profile.id, "recipe_id":LEGACY_RECIPE_IDS[profile.id], "order":SOURCE_IDS.duplicate()}
	var selected: Dictionary = arrangement_layout(descriptor)
	if not String(selected.error).is_empty(): return selected
	if selected.descriptor.profile != profile.id: return {"error":"O2 saved recipe and Scheduler profiles differ"}
	if not Codec.keys_error(local.sources,SOURCE_IDS).is_empty() or not Codec.is_integer(local.route.get("active_court"),0,COURT_IDS.size()): return {"error":"All five typed O2 sources and their bounded court entitlement required"}
	for id: String in SOURCE_IDS:
		var typed: Variant = local.sources[id]
		if not typed is Dictionary or not Codec.keys_error(typed,["kind","actor"]).is_empty() or typed.get("kind") != SOURCE_KINDS[id] or not typed.get("actor") is Dictionary or typed.actor.get("stable_id") != id or not Codec.is_vector3(typed.actor.get("position")):
			return {"error":"O2 construction requires each original typed native identity/position"}
		if not typed.actor.get("resolved_role") is Dictionary or typed.actor.resolved_role.get("difficulty_profile") != profile.id: return {"error":"O2 native construction roles must join the saved profile"}
		# Fixed Roots always retain their selected native origin. A dormant
		# C50 cannot have moved; entered C50 current motion remains native-owned.
		if SOURCE_KINDS[id] == "root" or int(SOURCE_COURTS[id]) > mini(int(local.route.active_court),COURT_IDS.size()-1):
			if Codec.read_vector3(typed.actor.position) != selected.starts[id]: return {"error":"Saved fixed/dormant O2 origin differs from its retained recipe: "+id}
	selected["legacy"] = legacy
	return selected


func selected_source_positions() -> Dictionary:
	return _selected_positions.duplicate(true)


func _ready() -> void:
	local_snapshot_version = LOCAL_VERSION
	process_physics_priority = 130 # Hero/Scheduler, Stalker20, Root90/Mechanism100 precede us.
	scenery = ForestScenery.new()
	scenery.name = "QuietRootForestScenery"
	add_child(scenery)
	scenery.call("build", true)
	scenery.call("_fixed_base", "o2-first-low-base", "FirstCourtLowBase", BASE_POSITION)
	scenery.call("_fixed_base", "o2-rearranged-low-base", "RearrangedCourtLowBase", SECOND_BASE_POSITION)
	_build_route_glyphs()
	var body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var solid: CollisionShape3D = body.get_node_or_null("Solid") as CollisionShape3D if is_instance_valid(body) else null
	if not is_instance_valid(solid) or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Vector3(14, 1, 22):
		_configuration_error = "Quiet Root requires its actual unchanged forest room floor"
		return
	_floor_region = {"collision": solid, "safe_rect": FLOOR_RECT}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTER_DATA))
	_configuration_error = _authoring_error(data)
	if not _configuration_error.is_empty():
		return
	threat_scheduler = SchedulerScript.new()
	threat_scheduler.name = "QuietRootThreatScheduler"
	add_child(threat_scheduler)
	for id: String in SOURCE_IDS:
		var source: Node3D = RootScript.new() if SOURCE_KINDS[id] == "root" else StalkerScript.new()
		source.name = id.replace("-", "_")
		add_child(source)
		source.position = SOURCE_POSITIONS[id]
		source.set_physics_process(false)
		sources[id] = source
	exit_cue = InteractionCue.new()
	exit_cue.name = "QuietRootReturnContactCue"
	add_child(exit_cue)
	exit_cue.position = EXIT_POSITION
	_update_presentation()


func _authoring_error(data: Variant) -> String:
	if not data is Dictionary or data.get("level_id") != "A3-O2" or data.get("prototype") != false or data.get("court_ids") != COURT_IDS or data.get("source_ids") != SOURCE_IDS or not data.get("source_positions") is Dictionary or not Codec.keys_error(data.source_positions,SOURCE_IDS).is_empty(): return "Exact three-court O2 identities required"
	for key: String in ["floor_size","spawn","base_position","second_base_position","exit_position"]:
		if not Codec.is_vector3(data.get(key)): return "Finite authored native vector required: "+key
	if Codec.read_vector3(data.floor_size)!=Vector3(14,1,22) or Codec.read_vector3(data.spawn)!=Vector3(0,0.1,8) or Codec.read_vector3(data.base_position)!=BASE_POSITION or Codec.read_vector3(data.second_base_position)!=SECOND_BASE_POSITION or Codec.read_vector3(data.exit_position)!=EXIT_POSITION: return "Authored forest floor/spawn/bases/exit differ from exact native geometry"
	for id: String in SOURCE_IDS:
		if not Codec.is_vector3(data.source_positions[id]) or Codec.read_vector3(data.source_positions[id])!=SOURCE_POSITIONS[id]: return "Authored source position differs: "+id
	if not Codec.same_values(data.get("root_role"),RootScript.RAW_ROLE) or not Codec.same_values(data.get("root_timing_floors"),RootScript.TIMING_FLOORS) or not Codec.same_values(data.get("stalker_role"),StalkerScript.DEFAULT_ROLE) or not Codec.same_values(data.get("stalker_timing_floors"),StalkerScript.DEFAULT_FLOORS): return "O2 must retain unchanged C51/C50 roles and timing floors"
	return ""


func contract_error() -> String:
	var error: String = super.contract_error()
	if not error.is_empty(): return error
	if level_id != "A3-O2" or position != Vector3.ZERO or basis != Basis.IDENTITY or (get_node(spawn_path) as Marker3D).position != Vector3(0, 0.1, 8):
		return "O2 identity/root transform/local spawn must match authored room"
	return _configuration_error


func _configure_sources(descriptor: Dictionary, legacy: bool) -> String:
	if not _configuration_error.is_empty(): return _configuration_error
	if _sources_configured: return "O2 native sources may only be configured once"
	var selected: Dictionary = arrangement_layout(descriptor)
	if not String(selected.error).is_empty(): return String(selected.error)
	if legacy and selected.descriptor.recipe_id != LEGACY_RECIPE_IDS[selected.descriptor.profile]: return "Legacy O2 construction must retain canonical ground slots"
	_arrangement_descriptor = selected.descriptor.duplicate(true)
	_selected_positions = selected.starts.duplicate(true)
	_legacy_capture = legacy
	# Every actual recipient gets its native ground slot BEFORE its only
	# configure call. No configured Root or retained history is translated.
	for id: String in SOURCE_IDS:
		sources[id].position = _selected_positions[id]
		sources[id].set_physics_process(false)
	if not threat_scheduler.begin_encounter(_arrangement_descriptor.profile,ENCOUNTER_ID,WORLD_REVISION): return threat_scheduler.last_error
	_sources_configured = true
	for id: String in SOURCE_IDS:
		var source: Node3D = sources[id]
		var configured: bool
		if SOURCE_KINDS[id]=="root": configured=source.call("configure",id,hero,effects,threat_scheduler,combat_response.bind(id),root_framing_guard.bind(id))
		else: configured=source.call("configure",id,hero,effects,threat_scheduler,combat_response.bind(id),StalkerScript.DEFAULT_ROLE,StalkerScript.DEFAULT_FLOORS)
		if not configured: return "Typed source configuration failed: "+id+": "+String(source.get("last_error"))
		var callback: Callable = _on_source_died.bind(id)
		_callbacks[id]=callback
		source.connect("died",callback)
		source.set_physics_process(_source_entered(id) and not source.get("dead"))
	return ""


func _on_enter_level() -> void:
	_active = true
	var profile: String = "standard"
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		profile = shared_shell.call("get_difficulty_preference")
	var selector := Arrangement.new(arrangement_definition())
	var descriptor: Dictionary = selector.select_fresh(profile)
	_configuration_error = selector.last_error if descriptor.is_empty() else _configure_sources(descriptor,false)
	scenery.call("follow_landmarks", hero.global_position)
	_update_presentation()


func restore_candidate_construction_required() -> bool:
	return true


func restore_candidate_physics_registration_required() -> bool:
	return true


func _on_enter_restore_candidate(local: Dictionary, player: Dictionary) -> String:
	var selected: Dictionary = arrangement_constructor(local)
	if not String(selected.error).is_empty(): return String(selected.error)
	_configuration_error = _configure_sources(selected.descriptor,selected.legacy)
	if not _configuration_error.is_empty(): return _configuration_error
	_active = true
	return _local_snapshot_error_with_player(local, player)


func _on_source_died(where: Vector3,id: String) -> void:
	if not _active or _deaths.has(id) or not sources.has(id) or not _configuration_error.is_empty(): return
	var source: Node3D = sources[id]
	if not source.get("dead") or float(source.get("hp"))!=0.0 or where!=source.global_position or source.call("state").stable_id!=id: return
	if SOURCE_KINDS[id]=="root" and (where!=_selected_positions[id] or not _source_entered(id)): return
	_deaths[id]={"clock_s":threat_scheduler.get_clock(),"source_position":Codec.vector3(where)}
	# Native death is retained without progression inside its hit transaction.


func _physics_process(_delta: float) -> void:
	if not _active or not is_instance_valid(hero) or not _configuration_error.is_empty(): return
	_sync_sun()
	scenery.call("follow_landmarks",hero.global_position)
	_update_presentation()
	if hero.dead: return
	if _advance_clear(): return
	if not is_completed() or _exit_state=="spent": return
	if _exit_state=="available" and _at_exit(hero.global_position):
		_contact={"clock_s":threat_scheduler.get_clock(),"hero_position":Codec.vector3(hero.global_position)}
		_exit_state="active"
		_update_presentation()
	if _exit_state=="active" and not _exit_queued:
		_exit_queued=true
		_dispatch_exit.bind(_exit_generation).call_deferred()


func _source_entered(id: String) -> bool:
	return int(SOURCE_COURTS[id])<=mini(_active_court,COURT_IDS.size()-1)


func _advance_clear() -> bool:
	if _active_court>=COURT_IDS.size(): return false
	for id: String in ROOT_IDS:
		if int(SOURCE_COURTS[id])==_active_court and not _deaths.has(id): return false
	var cleared_index: int=_active_court
	_clears.append({"court_id":COURT_IDS[cleared_index],"clock_s":threat_scheduler.get_clock(),"hero_position":Codec.vector3(hero.global_position)})
	_active_court+=1
	if _active_court==COURT_IDS.size(): _exit_state="available"
	# Enable the next real recipients before the coherent checkpoint. Their
	# source callbacks have already passed this native tick and start next tick.
	_update_presentation()
	var accepted: bool=request_checkpoint(CHECKPOINT_IDS[cleared_index],"encounter") if cleared_index<CHECKPOINT_IDS.size() else request_completion(COMPLETION_ID)
	if not accepted: _configuration_error="Genuine court clear progression rejected"
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and _active and is_instance_valid(hero):
		_settle_paused_presentation.bind(_exit_generation).call_deferred()


func _settle_paused_presentation(generation: int) -> void:
	if generation != _exit_generation or not _active or not is_inside_tree() or is_queued_for_deletion() or not get_tree().paused or is_restore_candidate() or not is_instance_valid(hero) or not is_instance_valid(threat_scheduler) or not _configuration_error.is_empty(): return
	_sync_sun()
	scenery.call("follow_landmarks", hero.global_position)
	_update_presentation(true) # No clock, clear, checkpoint, contact, damage or admission.


func _sync_sun() -> void:
	var clock: float = threat_scheduler.get_clock()
	sun_state = int(floorf(clock / SUN_PERIOD_S)) % 2
	sun_elapsed_s = fposmod(clock, SUN_PERIOD_S)
	sun_stage = "stable" if sun_elapsed_s < SUN_STABLE_S else ("preview" if sun_elapsed_s < SUN_STABLE_S + SUN_PREVIEW_S else "lock")
	var view: String = "%d:%s" % [sun_state, sun_stage]
	if view != _last_sun_view:
		scenery.call("show_sun", sun_state, sun_stage)
		_last_sun_view = view


func _at_exit(at: Vector3) -> bool:
	return at.is_finite() and absf(at.y) <= 0.2 and EXIT_RECT.has_point(Vector2(at.x, at.z))


func _dispatch_exit(generation: int) -> void:
	if generation != _exit_generation: return
	_exit_queued = false
	if not _active or not is_instance_valid(hero) or hero.dead or not is_completed() or _exit_state != "active": return
	_exit_state = "spent"
	_update_presentation()
	if not request_contact_exit(EXIT_ID, hero):
		_exit_state = "available"
		_contact.clear()
		_update_presentation()


func combat_response(id: String) -> Dictionary:
	if not is_instance_valid(hero) or not sources.has(id) or _floor_region.is_empty(): return {}
	var source: Node3D = sources[id]
	var response: Dictionary = hero.get_threat_response_state()
	var directions: Array[Vector3] = []
	var toward: Vector3 = hero.global_position - source.global_position
	toward.y = 0
	if toward.length_squared() > 0.0001:
		var side: Vector3 = Vector3.UP.cross(toward.normalized())
		if SOURCE_KINDS[id]=="stalker" and int(source.call("state").sun_visual)==1: side=-side
		directions.append_array([side, -side])
	for candidate: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK, Vector3(-1,0,-1).normalized(), Vector3(-1,0,1).normalized(), Vector3(1,0,-1).normalized(), Vector3(1,0,1).normalized()]:
		if not directions.has(candidate): directions.append(candidate)
	var returns: Array[Vector3] = []
	for escape: Vector3 in directions:
		var landing: Vector3 = hero.global_position + escape * float(response.stats.dash_distance)
		var back: Vector3 = source.global_position - landing
		back.y = 0
		if back.length_squared() > 0.0001 and not returns.has(back.normalized()): returns.append(back.normalized())
	for candidate: Vector3 in directions:
		if returns.size() == 16: break
		if not returns.has(candidate): returns.append(candidate)
	if SOURCE_KINDS[id]=="stalker": returns=directions.duplicate()
	response.world_root = get_parent() as Node3D
	response.world_revision = WORLD_REVISION
	response.encounter_id = ENCOUNTER_ID
	response.recognition_s = 0.25
	response.attack_input_margin_s = 0.06
	response.escape_directions = directions
	response.return_directions = returns
	response.floor_regions = [_floor_region]
	return response


func scheduler_bindings() -> Dictionary:
	var owners: Dictionary={}
	for id: String in SOURCE_IDS:
		if not is_instance_valid(sources.get(id)): continue
		if SOURCE_KINDS[id]=="root": owners.merge(sources[id].call("scheduler_owners"))
		else: owners[id]=sources[id]
	return {"world_root":get_parent() as Node3D,"owners":owners,"floors":{"forest-floor":_floor_region},"actors":{"hero":hero}}


func state() -> Dictionary:
	var actual: Dictionary = {}
	var cleared: Array[String] = []
	for id: String in SOURCE_IDS:
		if is_instance_valid(sources[id]): actual[id] = sources[id].state()
	for receipt: Dictionary in _clears: cleared.append(receipt.court_id)
	return {"api_revision": LEGACY_ROUTE_API if _legacy_capture else ROUTE_API, "configuration_error": _configuration_error, "active_court": _active_court, "cleared_courts": cleared, "clears": _clears.duplicate(true), "deaths": _deaths.duplicate(true), "source_states": actual, "exit_state": _exit_state, "contact": _contact.duplicate(true), "completed": is_completed(), "checkpoint": current_checkpoint(), "clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else 0.0, "sun_state": sun_state, "sun_stage": sun_stage}


func _update_presentation(quiet: bool = false) -> void:
	for id: String in sources:
		if not is_instance_valid(sources[id]): continue
		if SOURCE_KINDS[id]=="stalker": sources[id].call("set_sun_visual",sun_state)
		sources[id].set_physics_process(_source_entered(id) and not sources[id].get("dead"))
	if is_instance_valid(exit_cue):
		var blocked: bool=exit_cue.is_blocking_signals()
		if quiet: exit_cue.set_block_signals(true)
		if _exit_state=="clear": exit_cue.clear()
		else: exit_cue.present(_exit_state,"contact")
		if quiet: exit_cue.set_block_signals(blocked)
	if _glyph_clear_count!=_clears.size():
		for index: int in range(_glyph_materials.size()):
			_glyph_materials[index].albedo_color=Color("8a9082") if index<_clears.size() else Color("52414e")
		_glyph_clear_count=_clears.size()
	objective_text="QUIET ROOT UNAVAILABLE\n"+_configuration_error if not _configuration_error.is_empty() else ("THREE ROOT COURTS RELEASED\nCONTACT THE NORTH RETURN" if _active_court>=COURT_IDS.size() else "THE QUIET ROOT CIRCUIT\nCOURT %d/3 — BAIT ROOT; KEEP A RETURN"%mini(_active_court+1,3))


func _build_route_glyphs() -> void:
	# Three low leaf/stone notches identify courts; no ring, arrow, collider,
	# contact authority, timer, pulse or attack outline is introduced.
	for index: int in range(COURT_IDS.size()):
		var glyph:=Node3D.new()
		glyph.name="QuietCourtGlyph%d"%index
		glyph.position=GLYPH_POSITIONS[index]
		add_child(glyph)
		var material:=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color=Color("52414e")
		material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		for notch: int in range(index+1):
			var mesh:=BoxMesh.new()
			mesh.size=Vector3(0.09,0.012,0.27)
			var piece:=MeshInstance3D.new()
			piece.name="LeafNotch%d"%notch
			piece.mesh=mesh
			piece.material_override=material
			piece.position=Vector3(float(notch)*0.18-float(index)*0.09,0,0)
			piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			glyph.add_child(piece)
		_glyphs.append(glyph)
		_glyph_materials.append(material)


func _source_running(id: String) -> bool:
	if sources[id].get("dead"): return false
	var actual: Dictionary=sources[id].call("state")
	return actual.mechanism.status=="running" if SOURCE_KINDS[id]=="root" else not String(actual.reservation_id).is_empty()


func _root_preview(id: String) -> Dictionary:
	var source: CinderAct3RootLatcher = sources[id]
	var supplied: Dictionary = combat_response(id)
	var context: Dictionary = {}
	for key: String in CinderLaneMechanism.RESPONSE_KEYS:
		if not supplied.has(key): return {"accepted": false, "reason": "Actual Root response context unavailable"}
		context[key] = supplied[key]
	var bearing: Vector3 = hero.global_position - source.global_position
	bearing.y = 0
	if not bearing.is_finite() or bearing.length_squared() == 0: return {"accepted": false, "reason": "Nonzero native Root bearing required"}
	return source.get_mechanism().preview_start("hero", context, null, bearing.normalized())


func _camera_framing_points() -> Array:
	if not _active: return []
	var camera: Camera3D = get_viewport().get_camera_3d()
	var union: Dictionary = camera_framing_union("", [], false, camera)
	if not String(union.error).is_empty(): last_camera_framing_error = String(union.error); return []
	if not get_tree().paused and is_instance_valid(hero) and not hero.dead:
		for id: String in SOURCE_IDS:
			if SOURCE_KINDS[id]!="root" or not _source_entered(id) or sources[id].get("dead") or _source_running(id): continue
			var preview: Dictionary = _root_preview(id)
			if not preview.get("accepted", false): continue
			var group: Dictionary = _root_bounds(id, camera, preview)
			if not String(group.error).is_empty(): last_camera_framing_error = String(group.error); return []
			var prospective: Dictionary = camera_framing_union(id, group.points, false, camera)
			last_camera_framing_error = String(prospective.error)
			return prospective.points if last_camera_framing_error.is_empty() else []
	return union.points


func camera_framing_union(candidate_id: String = "",candidate_points: Array = [],current_view: bool = false,camera: Camera3D = null) -> Dictionary:
	if not is_instance_valid(camera): camera=get_viewport().get_camera_3d()
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not _configuration_error.is_empty(): return _bounds_error("Actual configured typed sources/Hero/Shell required")
	if not candidate_id.is_empty():
		if not sources.has(candidate_id) or candidate_points.is_empty() or _source_running(candidate_id): return _bounds_error("Prospective corners replace only their unleased native source")
	elif not candidate_points.is_empty(): return _bounds_error("Prospective native source identity required")
	var points: Array=candidate_points.duplicate()
	for id: String in SOURCE_IDS:
		if id==candidate_id: continue
		var group: Dictionary
		if SOURCE_KINDS[id]=="root":
			if _source_running(id): group=_root_bounds(id,camera)
			elif sources[id].global_position.distance_to(hero.global_position)<=PROP_VIEW_DISTANCE: group=sources[id].call("current_render_framing_points_for_camera",camera)
			else: continue
		else:
			var source: CinderAct3SunboundStalker=sources[id]
			group=source.camera_framing_points_for_context(shared_shell,hero,camera,{}, {},current_view) if get_tree().paused else source.camera_framing_points(shared_shell,{}, {},current_view)
			if not String(group.error).is_empty(): return group
			points.append_array(group.points)
			if String(source.state().reservation_id).is_empty() and source.global_position.distance_to(hero.global_position)<=PROP_VIEW_DISTANCE:
				group=source.current_render_framing_points_for_context(shared_shell,hero,camera)
			else: continue
		if not String(group.get("error","Missing actual native source bounds")).is_empty(): return group
		points.append_array(group.points)
	var contact: Dictionary=_contact_bounds()
	if not String(contact.error).is_empty(): return contact
	points.append_array(contact.points)
	return _checked_bounds(points)


func _root_bounds(id: String, camera: Camera3D, prospective: Dictionary = {}) -> Dictionary:
	var source: CinderAct3RootLatcher = sources[id]
	var geometry: Dictionary = {}
	var response: Dictionary = source.get_selected_response()
	if not prospective.is_empty():
		if not prospective.get("accepted", false) or not prospective.get("candidate") is Dictionary or not prospective.candidate.get("geometry") is Dictionary or not prospective.get("proof") is Dictionary: return _bounds_error("Exact native Root preview and witness required")
		geometry = prospective.candidate.geometry
		response = prospective.proof
	var native: Dictionary = source.call("framing_points_for_camera", camera, geometry)
	if not String(native.get("error", "Missing explicit-camera Root group")).is_empty(): return native
	var points: Array = native.points.duplicate()
	var hero_points: Array = shared_shell.call("player_camera_framing_points_for", hero, camera)
	if hero_points.is_empty(): return _bounds_error("Actual configured Hero/native Camera corners required")
	for key: String in ["landing", "attack_position"]:
		if not response.get(key) is Vector3 or not response[key].is_finite(): return _bounds_error("Actual selected Root witness missing: " + key)
		for corner: Vector3 in hero_points: points.append(corner + response[key] - hero.global_position)
	return _enclosing_box(points)


func root_framing_guard(current_view: bool, prospective: Dictionary, id: String) -> String:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var union: Dictionary
	if prospective.is_empty(): union = camera_framing_union("", [], current_view, camera)
	else:
		var group: Dictionary = _root_bounds(id, camera, prospective)
		if not String(group.error).is_empty(): return String(group.error)
		union = camera_framing_union(id, group.points, current_view, camera)
	if not String(union.error).is_empty(): return String(union.error)
	if current_view: return String(shared_shell.call("camera_framing_error", union.points))
	var plan: Dictionary = shared_shell.call("camera_framing_plan", union.points, hero.global_position + Vector3.UP * 0.75)
	return "" if plan.get("accepted", false) else String(plan.get("reason", "Complete prospective Root union does not fit"))


func _contact_bounds() -> Dictionary:
	if _exit_state == "clear" or hero.global_position.distance_to(EXIT_POSITION) > PROP_VIEW_DISTANCE: return {"error": "", "points": []}
	if not is_instance_valid(exit_cue) or exit_cue.state().state != _exit_state or exit_cue.state().trigger != "contact": return _bounds_error("Actual enabled contact exit cue required")
	var mesh: MeshInstance3D = exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if not is_instance_valid(mesh) or not mesh.is_visible_in_tree() or not mesh.mesh is ArrayMesh or not mesh.material_override is StandardMaterial3D: return _bounds_error("Actual visible native contact mesh required")
	var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
	if material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.grow or material.get_flag(BaseMaterial3D.FLAG_FIXED_SIZE): return _bounds_error("Contact mesh must retain its fixed native bounds")
	var points: Array = []
	var box: AABB = mesh.mesh.get_aabb()
	for corner: int in range(8): points.append(mesh.global_transform * box.get_endpoint(corner))
	for x: float in [EXIT_RECT.position.x, EXIT_RECT.end.x]:
		for y: float in [0.0, 0.05]:
			for z: float in [EXIT_RECT.position.y, EXIT_RECT.end.y]: points.append(Vector3(x,y,z))
	return _checked_bounds(points)


func _bounds_error(error: String) -> Dictionary:
	return {"error": error, "points": []}


func _checked_bounds(points: Array) -> Dictionary:
	if points.size() > 224: return _bounds_error("Complete actual native bounds exceed224corners")
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024: return _bounds_error("Finite bounded native world corners required")
	return {"error": "", "points": points.duplicate()}


func _enclosing_box(points: Array) -> Dictionary:
	if points.is_empty(): return _bounds_error("Complete nonempty native group required")
	if not points[0] is Vector3: return _bounds_error("Native group corners must be Vector3 values")
	var low: Vector3 = points[0]
	var high: Vector3 = points[0]
	# Complete raw Root/art/footprint plus both Hero witness groups precede
	# conservative compression. The shared224 bound applies to the final union.
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024: return _bounds_error("Finite bounded native group corners required before compression")
		low = low.min(point)
		high = high.max(point)
	var box := AABB(low, high-low)
	var corners: Array = []
	for corner: int in range(8): corners.append(box.get_endpoint(corner))
	return _checked_bounds(corners)


func candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	if not is_instance_valid(shared_shell) or not is_instance_valid(hero) or not is_instance_valid(camera) or not is_instance_valid(hud): return "Actual native Hero/Camera/HUD/Shell required"
	var group: Dictionary = camera_framing_union("", [], true, camera)
	if not String(group.error).is_empty(): return String(group.error)
	var points: Array = group.points.duplicate()
	points.append_array(shared_shell.call("player_camera_framing_points_for", hero, camera))
	var checked: Dictionary = _checked_bounds(points)
	if not String(checked.error).is_empty() or points.is_empty(): return "Complete actual Root/Hero current view required"
	return String(shared_shell.call("camera_framing_error_for_context", checked.points, hero, camera, hud))


func snapshot_state() -> Dictionary:
	return _capture_checked(get_viewport().get_camera_3d(), shared_shell.get("hud") as GameHUD if is_instance_valid(shared_shell) else null)


func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	return _capture_checked(camera, hud)


func _capture_checked(camera: Camera3D, hud: GameHUD) -> Dictionary:
	var saved: Dictionary = super.snapshot_state()
	if saved.is_empty(): return saved
	last_snapshot_error = _progress_error(saved)
	if last_snapshot_error.is_empty(): last_snapshot_error = candidate_presentation_error(camera, hud)
	return saved if last_snapshot_error.is_empty() else {}


func _capture_local_state() -> Dictionary:
	if not _runtime_error().is_empty(): return {}
	var bindings: Dictionary=scheduler_bindings()
	var actors: Dictionary={}
	for id: String in SOURCE_IDS:
		var saved: Dictionary=sources[id].call("snapshot_state",bindings) if SOURCE_KINDS[id]=="root" else sources[id].call("snapshot_state")
		actors[id]={"kind":SOURCE_KINDS[id],"actor":saved}
	var local: Dictionary = {"api_revision":LEGACY_ROUTE_API if _legacy_capture else ROUTE_API,"schema_version":1 if _legacy_capture else 2,"scenery":{"sun_state":sun_state,"sun_elapsed_s":sun_elapsed_s,"beat_index":_clears.size()},"scheduler":threat_scheduler.snapshot_state(bindings),"sources":actors,"route":{"active_court":_active_court,"clears":_clears.duplicate(true),"deaths":_deaths.duplicate(true),"exit_state":_exit_state,"contact":_contact.duplicate(true)}}
	if not _legacy_capture: local["arrangement"] = _arrangement_descriptor.duplicate(true)
	return local


func _runtime_error() -> String:
	if not _configuration_error.is_empty(): return _configuration_error
	if not is_instance_valid(scenery) or scenery.is_queued_for_deletion() or not scenery.call("runtime_error").is_empty(): return "Exact live forest floor/base/scenery required"
	if not is_instance_valid(threat_scheduler) or threat_scheduler.is_queued_for_deletion() or threat_scheduler.get_parent() != self: return "Actual retained Scheduler required"
	if not Codec.keys_error(sources, SOURCE_IDS).is_empty(): return "Exact retained typed Root sources required"
	var selected: Dictionary = arrangement_layout(_arrangement_descriptor)
	if not _sources_configured or not String(selected.error).is_empty(): return "Validated immutable O2 constructor arrangement required"
	if _selected_positions != selected.starts or threat_scheduler.encounter_profile().get("id") != _arrangement_descriptor.profile: return "O2 native starts/profile differ from the retained recipe"
	if _legacy_capture and _arrangement_descriptor.recipe_id != LEGACY_RECIPE_IDS[_arrangement_descriptor.profile]: return "Legacy O2 capture requires canonical ground slots"
	for id: String in SOURCE_IDS:
		if not is_instance_valid(sources[id]) or sources[id].is_queued_for_deletion() or not sources[id].is_inside_tree() or sources[id].get_parent()!=self: return "Actual retained typed source required: "+id
		var expected: Script=RootScript if SOURCE_KINDS[id]=="root" else StalkerScript
		if sources[id].get_script()!=expected or (SOURCE_KINDS[id]=="root" and sources[id].position!=_selected_positions[id]): return "Assigned native source class/fixed Root position changed: "+id
	if _glyphs.size()!=COURT_IDS.size() or _glyph_materials.size()!=COURT_IDS.size(): return "Three authored route glyphs required"
	for glyph: Node3D in _glyphs:
		if not is_instance_valid(glyph) or glyph.is_queued_for_deletion() or glyph.get_parent()!=self: return "Retained flat route glyph required"
	if not is_instance_valid(exit_cue) or exit_cue.is_queued_for_deletion() or exit_cue.get_parent() != self or exit_cue.position != EXIT_POSITION or exit_cue.basis != Basis.IDENTITY: return "Actual immutable return contact cue required"
	var solid: CollisionShape3D = _floor_region.get("collision") as CollisionShape3D
	if not is_instance_valid(solid) or solid.disabled or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Vector3(14,1,22) or solid.global_position != Vector3(0,-0.5,0) or solid.global_basis != Basis.IDENTITY or _floor_region.safe_rect != FLOOR_RECT or position != Vector3.ZERO or basis != Basis.IDENTITY: return "Registered continuous floor must remain immutable"
	return ""


func _local_snapshot_error(local: Dictionary) -> String:
	return _paired_local_error(local, hero.global_position, hero.dead) if is_instance_valid(hero) else "Paired actual Hero required"


func _local_snapshot_error_with_player(local: Dictionary, player: Dictionary) -> String:
	if not player.get("motion") is Dictionary or not Codec.is_vector3(player.motion.get("position")) or not player.get("resources") is Dictionary or not player.resources.get("dead") is bool: return "Validated saved Hero pose/lifecycle required"
	return _paired_local_error(local, Codec.read_vector3(player.motion.position), player.resources.dead)


func _paired_local_error(local: Dictionary,expected_hero: Vector3,expected_dead: bool) -> String:
	var error: String=_runtime_error()
	if not error.is_empty(): return error
	var selected: Dictionary = arrangement_constructor(local)
	if not String(selected.error).is_empty(): return String(selected.error)
	if selected.legacy != _legacy_capture or Exact.stringify(selected.descriptor) != Exact.stringify(_arrangement_descriptor) or selected.starts != _selected_positions: return "Saved O2 arrangement differs from the constructed immutable native bindings"
	if not Codec.keys_error(local.scenery,["sun_state","sun_elapsed_s","beat_index"]).is_empty() or not Codec.is_number(local.scheduler.get("clock_s")) or float(local.scheduler.clock_s)<0 or not Codec.is_integer(local.scenery.get("sun_state"),0,1) or not Codec.is_integer(local.scenery.get("beat_index"),0,COURT_IDS.size()) or not Codec.is_number(local.scenery.get("sun_elapsed_s")): return "Exact continuous Sun/court clock required"
	if int(local.scenery.sun_state)!=int(floorf(float(local.scheduler.clock_s)/SUN_PERIOD_S))%2 or float(local.scenery.sun_elapsed_s)!=fposmod(float(local.scheduler.clock_s),SUN_PERIOD_S): return "Sun state/time must join actual Scheduler clock exactly"
	if not Codec.keys_error(local.sources,SOURCE_IDS).is_empty(): return "Every retained typed actor required"
	var bindings: Dictionary=scheduler_bindings()
	bindings.hero_positions={"hero":expected_hero}
	bindings.owner_positions={}
	bindings.owner_velocities={}
	bindings.owner_collision_states={}
	for id: String in SOURCE_IDS:
		var typed: Variant=local.sources[id]
		if not typed is Dictionary or not Codec.keys_error(typed,["kind","actor"]).is_empty() or typed.get("kind")!=SOURCE_KINDS[id] or not typed.get("actor") is Dictionary or not Codec.is_vector3(typed.actor.get("position")): return "Exact typed native actor envelope required"
		var actor: Dictionary=typed.actor
		if SOURCE_KINDS[id]=="root": bindings.owner_positions[id+"/attack"]=Codec.read_vector3(actor.position)
		else:
			error=sources[id].call("snapshot_error",actor,local.scheduler)
			if not error.is_empty(): return id+": "+error
			bindings.owner_positions[id]=Codec.read_vector3(actor.position)
			bindings.owner_velocities[id]=Codec.read_vector3(actor.velocity)
			if not actor.dead and not String(actor.reservation_id).is_empty(): bindings.owner_collision_states[id]={"collision_path":"BodyCollision","enabled":true,"layer":2,"mask":1}
			if float(actor.previous.clock_s)==float(local.scheduler.clock_s) and Codec.read_vector3(actor.previous.hero_position)!=expected_hero: return "Current Stalker sample differs from paired Hero"
	error=threat_scheduler.snapshot_error(local.scheduler,bindings)
	if not error.is_empty(): return error
	if local.scheduler.encounter_id!=ENCOUNTER_ID or local.scheduler.world_revision!=WORLD_REVISION: return "Exact continuous O2 encounter identity required"
	for id: String in ROOT_IDS:
		error=sources[id].call("snapshot_error",local.sources[id].actor,bindings,local.scheduler)
		if not error.is_empty(): return id+": "+error
	return _route_error(local,expected_hero,expected_dead)


func _route_error(local: Dictionary,expected_hero: Vector3,_expected_dead: bool) -> String:
	var route: Dictionary=local.route
	if not Codec.keys_error(route,["active_court","clears","deaths","exit_state","contact"]).is_empty() or not Codec.is_integer(route.get("active_court"),0,COURT_IDS.size()) or not route.get("clears") is Array or route.clears.size()>COURT_IDS.size() or not route.get("deaths") is Dictionary or not route.get("exit_state") is String or not route.get("contact") is Dictionary: return "Closed finite court/death/contact history required"
	if int(route.active_court)!=route.clears.size() or int(local.scenery.beat_index)!=route.clears.size(): return "Active court/Sun presentation must follow genuine clear prefix"
	for id: Variant in route.deaths:
		if not id is String or not SOURCE_IDS.has(id): return "Unknown source death identity"
	for id: String in SOURCE_IDS:
		var actor: Dictionary=local.sources[id].actor
		var entered: bool=int(SOURCE_COURTS[id])<=mini(int(route.active_court),COURT_IDS.size()-1)
		if actor.dead!=route.deaths.has(id): return "Actual typed source death and receipt must agree"
		if route.deaths.has(id):
			var death: Variant=route.deaths[id]
			if not death is Dictionary or not Codec.keys_error(death,["clock_s","source_position"]).is_empty() or not Codec.in_range(death.get("clock_s"),0,float(local.scheduler.clock_s)) or not Codec.is_vector3(death.get("source_position")) or Codec.read_vector3(death.source_position)!=Codec.read_vector3(actor.position): return "Actual dead source pose/clock receipt required"
		if not entered:
			if SOURCE_KINDS[id]=="root":
				if actor.dead or float(actor.hp)!=float(actor.max_hp) or int(actor.mechanism.cycle)!=0 or actor.mechanism.status!="idle" or actor.mechanism.phase!="clear" or not actor.mechanism.exchange.is_empty(): return "Unentered Root must remain untouched, idle and unleased"
			else:
				# An optional ordinary hit can reach a dormant C50. Preserve it;
				# no motion/cycle/lease may run before final court activation.
				if int(actor.cycle)!=0 or not String(actor.reservation_id).is_empty() or Codec.read_vector3(actor.position)!=_selected_positions[id] or actor.phase not in ["idle","defeated"]: return "Unentered Stalker cannot move or start an attack cycle"
				if float(actor.hp)==float(actor.max_hp) and Codec.read_vector3(actor.velocity)!=Vector3.ZERO: return "Untouched dormant Stalker cannot manufacture motion"
	var previous_clear: float=-1
	for index: int in range(route.clears.size()):
		var latest_death: float=0
		for id: String in ROOT_IDS:
			if int(SOURCE_COURTS[id])!=index: continue
			if not route.deaths.has(id): return "Court clear requires every actual Root death in that court"
			var death_clock: float=float(route.deaths[id].clock_s)
			var activation_clock: float=0 if index==0 else float(route.clears[index-1].clock_s)
			if death_clock<activation_clock: return "Root death cannot precede its real court activation"
			latest_death=maxf(latest_death,death_clock)
		var clear: Variant=route.clears[index]
		if not clear is Dictionary or not Codec.keys_error(clear,["court_id","clock_s","hero_position"]).is_empty() or clear.get("court_id")!=COURT_IDS[index] or not Codec.in_range(clear.get("clock_s"),latest_death,float(local.scheduler.clock_s)) or float(clear.clock_s)<=previous_clear or not Codec.is_vector3(clear.get("hero_position")): return "Canonical chronological Root-clear prefix required"
		var at: Vector3=Codec.read_vector3(clear.hero_position)
		if not FLOOR_RECT.has_point(Vector2(at.x,at.z)) or absf(at.y)>0.2: return "Actual grounded court-clear Hero sample required"
		if float(clear.clock_s)==float(local.scheduler.clock_s) and at!=expected_hero: return "Current clear sample differs from paired Hero"
		previous_clear=float(clear.clock_s)
	for id: String in ROOT_IDS:
		if not route.deaths.has(id): continue
		var court: int=int(SOURCE_COURTS[id])
		if court>0 and (route.clears.size()<court or float(route.deaths[id].clock_s)<float(route.clears[court-1].clock_s)): return "Root death cannot precede its real court activation"
	if route.clears.size()==COURT_IDS.size():
		if route.exit_state not in ["available","active","spent"]: return "Three Root clears require their enabled contact exit"
	elif route.exit_state!="clear" or not route.contact.is_empty(): return "Uncleared courts cannot open or consume exit"
	if route.exit_state in ["active","spent"]:
		if not Codec.keys_error(route.contact,["clock_s","hero_position"]).is_empty() or not Codec.in_range(route.contact.get("clock_s"),previous_clear,float(local.scheduler.clock_s)) or float(route.contact.clock_s)<=previous_clear or not Codec.is_vector3(route.contact.get("hero_position")) or not _at_exit(Codec.read_vector3(route.contact.hero_position)): return "Exit must follow third completion through later real grounded contact"
		if float(route.contact.clock_s)==float(local.scheduler.clock_s) and Codec.read_vector3(route.contact.hero_position)!=expected_hero: return "Current contact sample differs from paired Hero"
	elif not route.contact.is_empty(): return "Unused exit cannot retain contact history"
	return ""


func _snapshot_envelope_error(snapshot: Dictionary) -> String:
	var error: String = super._snapshot_envelope_error(snapshot)
	if not error.is_empty(): return error
	if not Codec.keys_error(snapshot,["api_revision","schema_version","level_id","scene_path","local_snapshot_version","progress","local"]).is_empty(): return "Closed O2 snapshot envelope required"
	return _progress_error(snapshot)


func _progress_error(snapshot: Dictionary) -> String:
	if not snapshot.local.get("route") is Dictionary or not snapshot.local.route.get("clears") is Array or not snapshot.local.route.get("exit_state") is String: return "Complete court/progress unit required"
	var route: Dictionary=snapshot.local.route
	var progress: Dictionary=snapshot.progress
	if not Codec.keys_error(progress,["completed","completion_id","contact_exit_id","checkpoint_id","checkpoint_kind","checkpoint_ids"]).is_empty(): return "Closed O2 progress fields required"
	var completed: bool=route.clears.size()==COURT_IDS.size()
	if progress.completed!=completed or progress.completion_id!=(COMPLETION_ID if completed else ""): return "Completion must match all three genuine Root court clears"
	var expected: Array[String]=[]
	for index: int in range(mini(route.clears.size(),CHECKPOINT_IDS.size())): expected.append(CHECKPOINT_IDS[index])
	if not Codec.keys_error(progress.checkpoint_ids,expected).is_empty(): return "Only first and second court clears create checkpoints"
	for id: String in expected:
		if progress.checkpoint_ids[id]!="encounter": return "Root court-clear checkpoint kind must be encounter"
	var latest: String=expected[-1] if not expected.is_empty() else ""
	if progress.checkpoint_id!=latest or progress.checkpoint_kind!=("encounter" if not latest.is_empty() else ""): return "Latest checkpoint must follow the first/second clear prefix"
	if progress.contact_exit_id!=(EXIT_ID if route.exit_state=="spent" else ""): return "Actual spent exit must match contact-exit progress"
	return ""


func _restore_local_state(local: Dictionary) -> void:
	for id: String in SOURCE_IDS:
		var applied: bool=sources[id].call("apply_validated_state",local.sources[id].actor)
		assert(applied,"Prevalidated physical typed actor commit failed: "+id)
	var scheduler_applied: bool=threat_scheduler.restore_state(local.scheduler,scheduler_bindings())
	assert(scheduler_applied,"Prevalidated actual Scheduler commit failed")
	for id: String in SOURCE_IDS:
		if SOURCE_KINDS[id]=="root":
			var mechanism_applied: bool=sources[id].call("restore_mechanism_state",local.sources[id].actor,scheduler_bindings())
			assert(mechanism_applied,"Prevalidated Root mechanism commit failed: "+id)
		else:
			sources[id].call("set_sun_visual",int(local.scenery.sun_state))
			var refreshed: bool=sources[id].call("refresh_presentation")
			assert(refreshed,"Prevalidated native C50 presentation commit failed")
	sun_state=int(local.scenery.sun_state)
	sun_elapsed_s=float(local.scenery.sun_elapsed_s)
	_last_sun_view=""
	_active_court=int(local.route.active_court)
	_clears.clear()
	for receipt: Dictionary in local.route.clears: _clears.append(receipt.duplicate(true))
	_deaths=local.route.deaths.duplicate(true)
	_exit_state=local.route.exit_state
	_contact=local.route.contact.duplicate(true)
	_exit_generation+=1
	_exit_queued=false
	_active=true
	_glyph_clear_count=-1
	_sync_sun()
	scenery.call("follow_landmarks",hero.global_position)
	_update_presentation(true)


func _restore_candidate_presentation_error(camera: Camera3D,hud: GameHUD) -> String:
	return candidate_presentation_error(camera,hud)


func _on_exit_level() -> void:
	_active=false
	_exit_generation+=1
	_exit_queued=false
	for id: String in _callbacks:
		if not is_instance_valid(sources.get(id)): continue
		if sources[id].is_connected("died",_callbacks[id]): sources[id].disconnect("died",_callbacks[id])
		sources[id].set_physics_process(false)
	_callbacks.clear()
	if is_instance_valid(exit_cue): exit_cue.clear()
	if is_instance_valid(threat_scheduler): threat_scheduler.end_encounter("quiet_root_circuit_exit")
