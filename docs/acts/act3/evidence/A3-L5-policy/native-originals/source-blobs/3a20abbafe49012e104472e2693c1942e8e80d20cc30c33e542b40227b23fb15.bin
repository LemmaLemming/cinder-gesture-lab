extends "res://tests/acts/act3/crystalman_regular_priority_smoke.gd"
## SOURCE-ONLY declared two-native-source comparison. No parent/Approach saves,
## offered history, MAIN progress, forced source order or controller fork.
const PC_Geometry = preload("res://scripts/combat/threat_geometry.gd")
const PC_START := Vector3(-0.7,0.1,19)
const PC_LIMIT: String = "TEST two-source component refuses whole-parent/Approach save authority"

class ComponentApproach:
	extends CinderAct3CrystalmanApproachUnit
	func _on_enter_level() -> void:
		if not last_configuration_error.is_empty(): return
		var error: String = _constructor_profile_error()
		if not error.is_empty(): _fail(error); return
		if not threat_scheduler.begin_encounter(_profile,ENCOUNTER_ID,1): _fail(threat_scheduler.last_error); return
		if Exact.stringify(threat_scheduler.encounter_profile()) != _constructor_profile_wire: _fail("Actual TEST Scheduler must equal frozen Challenge"); return
		# Initial TEST topology only; no offered actor/death/journal or advance.
		stage = 2
		_active = true
		if not _install_source(ENEMY_IDS[1]) or not _install_source(ENEMY_IDS[2]): return
		_update_presentation()
	func _update_presentation(_quiet: bool = false) -> void:
		objective_text = "TEST TWO FAMILIAR SOURCES / ORDINARY SAFE RETURN"
	func _capture_local_state() -> Dictionary: return {}
	func _local_snapshot_error(_state: Dictionary) -> String: return "TEST two-source component refuses whole-parent/Approach save authority"
	func _local_snapshot_error_with_player(_state: Dictionary,_player: Dictionary) -> String: return "TEST two-source component refuses whole-parent/Approach save authority"
	func _on_enter_restore_candidate(_state: Dictionary,_player: Dictionary) -> String: return "TEST two-source component refuses whole-parent/Approach save authority"
	func capture_native_state(_player: Dictionary,_optical: bool = true) -> Dictionary: return {}
	func native_capture_error() -> String: return "TEST two-source component refuses whole-parent/Approach save authority"
	func native_state_error(_state: Dictionary,_player: Dictionary) -> String: return "TEST two-source component refuses whole-parent/Approach save authority"
	func prepare_parent_restore(_state: Dictionary,_player: Dictionary,_hero: CinderPlayer,_effects: PixelEffects,_shell: Node) -> bool: return false
	func restore_parent_state(_state: Dictionary,_player: Dictionary) -> bool: return false
	func verify_parent_candidate(_state: Dictionary,_player: Dictionary,_camera: Camera3D,_hud: GameHUD) -> String: return "TEST two-source component refuses whole-parent/Approach save authority"
	func restore_state(_state: Dictionary) -> bool: return false
	func finish_restore_candidate() -> bool: return false

class ComponentHost:
	extends CinderLevel
	@export var west_inset: bool = false
	var current_unit: CinderLevel
	var floor_body: StaticBody3D
	var floor_collision: CollisionShape3D
	var last_configuration_error: String = ""
	var _rows: Dictionary = {}
	var _profile: Dictionary = {}
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		var resolver: CinderDifficulty = CinderDifficulty.new()
		_profile = resolver.profile("challenge")
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/act3/crystalman_layout.json"))
		if not raw is Dictionary or not raw.get("sources") is Array: last_configuration_error = "Actual immutable layout rows required"; return
		for original: Dictionary in raw.sources:
			var row: Dictionary = original.duplicate(true)
			if row.kind == "echo":
				if west_inset and row.id == "l5-plain-echo":
					for point: Dictionary in row.own_route_world:
						var at: Vector3 = CinderSnapshotCodec.read_vector3(point.position)
						at.x = -3.0; point.position = CinderSnapshotCodec.vector3(at)
					var knot: Vector3 = CinderSnapshotCodec.read_vector3(row.fixed_knot_world)
					knot.x = -3.0; row.fixed_knot_world = CinderSnapshotCodec.vector3(knot)
				row["source_epoch_recipe"] = row.source_epoch
				row["definition_id"] = row.id + "/straight-return"
				row["definition_translation_world"] = row.fixed_knot_world.duplicate()
				row["slash_origin_world"] = row.fixed_knot_world.duplicate()
			_rows[row.id] = row
		floor_body = StaticBody3D.new(); floor_body.name = "PermanentFirmFloor"
		floor_body.collision_layer = 1; floor_body.collision_mask = 0; floor_body.position = Vector3(0,-0.5,13)
		add_child(floor_body)
		floor_collision = CollisionShape3D.new(); floor_collision.name = "Solid"
		var box := BoxShape3D.new(); box.size = Vector3(12,1,54); floor_collision.shape = box; floor_body.add_child(floor_collision)
		_mesh(floor_body,box.size,Color("25202e"))
		for row: Dictionary in raw.floor.fixed_blockers:
			var wall := StaticBody3D.new(); wall.name = row.id; wall.collision_layer = 1; wall.collision_mask = 0
			wall.position = CinderSnapshotCodec.read_vector3(row.center_world); add_child(wall)
			var collision := CollisionShape3D.new(); collision.name = "Solid"
			var wall_box := BoxShape3D.new(); wall_box.size = CinderSnapshotCodec.read_vector3(row.size_world)
			collision.shape = wall_box; wall.add_child(collision); _mesh(wall,wall_box.size,Color("292331"))
	func _mesh(parent: Node3D,size: Vector3,color: Color) -> void:
		var mesh := MeshInstance3D.new(); mesh.name = "VisiblePermanentGeometry"
		var shape := BoxMesh.new(); shape.size = size; mesh.mesh = shape
		var material := StandardMaterial3D.new(); material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; material.albedo_color = color
		mesh.material_override = material; mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; parent.add_child(mesh)
	func crystalman_approach_constructor() -> Dictionary:
		# TEST declaration, not a new/legacy production parent policy packet.
		return {"legacy":false,"policy":{},"profile":_profile.duplicate(true)}
	func crystalman_source_rows() -> Dictionary: return _rows.duplicate(true)
	func crystalman_regular_floor_binding() -> Dictionary: return {"collision":floor_collision,"safe_rect":Rect2(-6,-14,12,54)}
	func _on_enter_level() -> void:
		if not last_configuration_error.is_empty(): return
		current_unit = ComponentApproach.new(); current_unit.name = "DeclaredPlainSources"; add_child(current_unit)
		current_unit.enter_level(hero,effects,shared_shell)
		last_configuration_error = String(current_unit.get("last_configuration_error"))
	func _camera_framing_points() -> Array:
		if not is_instance_valid(current_unit): return []
		var union: Dictionary = current_unit.call("camera_framing_union")
		last_camera_framing_error = String(union.get("error","Missing actual union"))
		return union.points if last_camera_framing_error.is_empty() else []
	func _on_exit_level() -> void:
		if is_instance_valid(current_unit): current_unit.exit_level()
	func _capture_local_state() -> Dictionary: return {}
	func _local_snapshot_error(_state: Dictionary) -> String: return "TEST two-source component refuses whole-parent/Approach save authority"
	func _local_snapshot_error_with_player(_state: Dictionary,_player: Dictionary) -> String: return "TEST two-source component refuses whole-parent/Approach save authority"
	func _on_enter_restore_candidate(_state: Dictionary,_player: Dictionary) -> String: return "TEST two-source component refuses whole-parent/Approach save authority"

var _pc_scenes: Array[PackedScene] = []
var _pc_view: SubViewport
var _pc_world_ids: Array[int] = []
var _pc_done: bool = false
var _pc_closing: bool = false
var _pc_finished: bool = false
var _pc_cell: String = ""
var _pc_actions: Array[Dictionary] = []
var _pc_hits: Array[Dictionary] = []
var _pc_events: Array[Dictionary] = []
var _pc_trace: Array[Dictionary] = []
var _pc_used: Dictionary = {}
var _pc_selected_responses: Array[Dictionary] = []
var _pc_holds: Array[Dictionary] = []
var _pc_cases: Array[Dictionary] = []
var _pc_baseline: Dictionary = {}
var _pc_definition_baseline: Dictionary = {}
var _pc_definition: Dictionary = {}
var _pc_echo_execution: Dictionary = {}
var _pc_last_dash_end: float = -1.0
var _pc_last_tap_ms: int = -10000
var _pc_c50_complete: bool = false
var _pc_echo_complete: bool = false
var _pc_frozen_results: Array[PackedByteArray] = []
var _pc_comparison: Dictionary = {}
var _pc_cell_frozen: bool = false
var _pc_grounded: bool = false
var _pc_close_done: bool = true

func _initialize() -> void:
	create_timer(600.0,true,false,true).timeout.connect(_pc_timeout,CONNECT_ONE_SHOT)
	_run.call_deferred()

func _run() -> void:
	if not expect(OS.get_cmdline_user_args().is_empty(),"One finite neutral canonical/new declared component comparison only"):
		await _pc_finish(); return
	root.size = Vector2i(340,736); root.content_scale_size = root.size; root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for changed: bool in [false,true]:
		if _pc_done or failures > 0: break
		await _pc_case(changed)
		await _pc_close()
	if failures == 0 and _pc_cases.size() == 2:
		var result: Dictionary = _pc_difference(_pc_cases[0],_pc_cases[1])
		_pc_comparison = result.duplicate(true)
		expect(result.get("outcome") == "meaningful-safe-difference","Actual complete paired responses establish a useful decision difference; coordinates/range/tie-break alone do not",str(result))
	await _pc_finish()

func _pc_scene(changed: bool) -> String:
	var host := ComponentHost.new(); host.name = "TESTPlainComparison"; host.level_id = "A3-L5"; host.west_inset = changed
	var spawn := Marker3D.new(); spawn.name = "PlayerSpawn"; spawn.position = PC_START; host.add_child(spawn); spawn.owner = host
	var scene := PackedScene.new(); var error: Error = scene.pack(host); host.free()
	if not expect(error == OK,"Unique declared component packs without writing a scene"): return ""
	var path: String = "res://tests/acts/act3/__TEST_l5_plain_%d_%d.tscn" % [OS.get_process_id(),Time.get_ticks_usec()]
	if not expect(not FileAccess.file_exists(path) and not ResourceLoader.has_cached(path),"Unique TEST cache never replaces a canonical resource"): return ""
	scene.take_over_path(path); _pc_scenes.append(scene); return path

func _pc_open(changed: bool) -> bool:
	if _pc_done or _pc_finished: return false
	_pc_cell = "west-inset" if changed else "canonical"
	_pc_actions.clear(); _pc_hits.clear(); _pc_events.clear(); _pc_trace.clear(); _pc_used.clear(); _pc_holds.clear(); _pc_echo_execution.clear(); _pc_definition.clear(); _pc_selected_responses.clear()
	_pc_last_dash_end = -1.0; _pc_last_tap_ms = -10000; _pc_c50_complete = false; _pc_echo_complete = false
	_pc_cell_frozen = false; _pc_grounded = false; events.clear(); invalidations.clear()
	paused = true
	# Actual Main keeps its ordinary inner native world/camera. This independent
	# outer viewport also gives its actual HUD the native portrait context.
	_pc_view = SubViewport.new(); _pc_view.name = "TESTIndependentMainViewport"
	_pc_view.size = Vector2i(340,736); _pc_view.own_world_3d = true
	_pc_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(_pc_view)
	game = MainScene.instantiate(); _pc_view.add_child(game); game.call("open_bench")
	var lab: CinderPlayer = game.get("player") as CinderPlayer
	if not expect(paused and is_instance_valid(lab),"Actual paused enemy-free Main Lab precedes the declared component"): return false
	var kit: Dictionary = {"jacket":"CLOTH-J0","pants":"CLOTH-P0","shoes":"CLOTH-S0","weapon":"WEAPON-01"}
	for slot: String in kit:
		if lab.equipment.snapshot().get(slot) == kit[slot]: continue
		if not expect(lab.equip_item(kit[slot]),"Only public initial neutral equipment selection"): return false
	var path: String = _pc_scene(changed)
	if path.is_empty() or not expect(game.call("load_level_scene",path),"Public Main loader installs only the fresh declared TEST component",String(game.get("level_load_error"))): return false
	game.call("open_bench")
	level = game.get("active_level") as CinderLevel; hero = game.get("player") as CinderPlayer
	regular = level.get("current_unit") as CinderLevel if is_instance_valid(level) else null
	scheduler = regular.get("threat_scheduler") as CinderThreatScheduler if is_instance_valid(regular) else null
	if not expect(paused and hero != lab and is_instance_valid(scheduler) and String(level.get("last_configuration_error")).is_empty() and String(regular.get("last_configuration_error")).is_empty(),"Actual native two-source component construction",String(regular.get("last_configuration_error")) if is_instance_valid(regular) else "No Approach"): return false
	var actors: Dictionary = regular.get("sources")
	if not expect(actors.size() == 2 and actors.has(STALKER) and actors.has(PLAIN) and not actors.has(OFFERED),"Only declared living C50/C52; no fabricated offered actor/journal"): return false
	stalker = actors[STALKER]; plain = actors[PLAIN]
	var camera: Camera3D = game.get("camera") as Camera3D
	var hud: GameHUD = game.get("hud") as GameHUD
	var world_id: int = level.get_world_3d().get_instance_id()
	if not expect(_pc_view.size==Vector2i(340,736) and _pc_view.own_world_3d and game.get_parent()==_pc_view and hud.get_viewport()==_pc_view and camera.get_viewport()==hero.get_viewport() and camera==hero.get_viewport().get_camera_3d() and camera.get_world_3d()==hero.get_world_3d() and world_id!=0 and world_id not in _pc_world_ids,"Each actual Main/HUD owns its native viewport and a distinct actual current Camera/World3D"): return false
	_pc_world_ids.append(world_id)
	_pc_definition = plain.call("source_definition")
	if _pc_definition_baseline.is_empty(): _pc_definition_baseline = _pc_definition.duplicate(true)
	var expected_definition: Dictionary = _pc_definition_baseline.duplicate(true)
	if changed:
		for row: Dictionary in expected_definition.route:
			var position: Vector3 = row.position; position.x = -3.0; row.position = position
		var origin: Vector3 = expected_definition.slash.world_origin; origin.x = -3.0; expected_definition.slash.world_origin = origin
	if not expect(not _pc_definition.is_empty() and var_to_bytes(_pc_definition)==var_to_bytes(expected_definition) and plain.call("source_profile")=="challenge","Only the whole native C52 definition translates−2.3m; all other source/program/profile fields retain exact bytes"): return false
	baseline_kit = hero.equipment.snapshot(); baseline_hp = hero.hp; baseline_epoch = hero.get_world_action_clock()
	floor_collision = level.get("floor_collision") as CollisionShape3D; floor_transform = floor_collision.global_transform; floor_size = (floor_collision.shape as BoxShape3D).size
	if not expect(hero.global_position == PC_START and baseline_epoch == 0.0 and scheduler.get_clock() == 0.0 and hero.hp == hero.max_hp and hero.facing == Vector3.FORWARD and scheduler.encounter_profile().id == "challenge" and plain.call("source_cycles_managed") and stalker.get("hp") == 36.0 and plain.get("hp") == 36.0,"Same actual fresh Challenge Hero/source baseline; no after-construction repairs"): return false
	if not expect(level.snapshot_state().is_empty() and level.last_snapshot_error == PC_LIMIT and regular.snapshot_state().is_empty() and regular.last_snapshot_error == PC_LIMIT,"Both partial TEST recipients explicitly refuse whole-parent/Approach saves"): return false
	var response: Dictionary = hero.get_threat_response_state().duplicate(true); response.erase("actor")
	var initial: Dictionary = {"hero":response,"hp":hero.hp,"max_hp":hero.max_hp,"shells":hero.shells,"max_shells":hero.max_shells,"facing":hero.facing,"input":game.call("get_input_observation_state"),"profile":scheduler.encounter_profile(),"floor":[floor_transform,floor_size],"stalker_home":stalker.global_position,"stalker_role":stalker.call("state").resolved_role}
	if _pc_baseline.is_empty(): _pc_baseline = initial.duplicate(true)
	elif not expect(var_to_bytes(initial) == var_to_bytes(_pc_baseline),"Both declared cells retain identical actual position/facing/clocks/kit/cooldowns/input baseline"): return false
	barrier = PriorityBarrier.new(); barrier.name = "TESTPostActorObserver"; root.add_child(barrier)
	hero.world_action_executed.connect(_pc_action)
	hero.fired.connect(_pc_fired)
	stalker.connect("hit_resolved",_pc_c50_contact)
	plain.connect("event_dispatched",_pc_echo_event)
	plain.connect("source_hit_resolved",_pc_source_hit)
	scheduler.reservation_invalidated.connect(_pc_invalidated)
	game.call("resume_lab")
	return expect(not paused,"Public Resume begins normal autonomous native sources")

func _pc_case(changed: bool) -> bool:
	if not await _pc_open(changed): return false
	for _choice: int in range(64):
		if _pc_done or failures > 0: break
		if _pc_c50_complete and _pc_echo_complete: break
		var response: Dictionary = await _pc_response()
		if response.is_empty(): break
		var completed: Dictionary = await _pc_follow(response)
		if completed.is_empty(): break
		if completed.source_id == STALKER: _pc_c50_complete = true
		elif completed.source_id == PLAIN: _pc_echo_complete = true
	var ok: bool = failures == 0 and _pc_c50_complete and _pc_echo_complete and not _pc_echo_execution.is_empty()
	if not expect(ok,"Actual complete C50 response plus useful ordinary C52 response/hold, unrestricted source order",_pc_detail()): return false
	var row: Dictionary = {"cell":_pc_cell,"constructor_start":PC_START,"initial":_pc_baseline.duplicate(true),"native_definition":_pc_definition.duplicate(true),"native_actions":_pc_actions.duplicate(true),"contacts":_pc_hits.duplicate(true),"events":_pc_events.duplicate(true),"trace":_pc_trace.duplicate(true),"observed_usable_responses":_pc_selected_responses.duplicate(true),"holds":_pc_holds.duplicate(true),"echo_execution":_pc_echo_execution.duplicate(true),"final":_pc_observation(),"canonical_parent_authority":false}
	_pc_cases.append(row); _pc_frozen_results.append(var_to_bytes(row)); _pc_cell_frozen = true
	return true

func _pc_response() -> Dictionary:
	for _sample: int in range(480):
		var selected: Dictionary = _pc_fresh()
		if not selected.is_empty(): _pc_used[selected.id] = true; return selected
		if not await tick(): return {}
	expect(false,"Finite actual autonomous warning supplies a usable native response",_pc_detail()); return {}

func _pc_fresh() -> Dictionary:
	# Observe either real source; no request/cancel/admit or first-source rule.
	for id: String in [STALKER,PLAIN]:
		var source: Node3D = stalker if id == STALKER else plain
		var state: Dictionary = source.call("state")
		var lease_id: String = String(state.get("reservation_id",""))
		if (id==STALKER and state.get("phase")!="warning") or (id==PLAIN and state.get("status")!="running"): continue
		if lease_id.is_empty() or _pc_used.has(lease_id): continue
		var controls: Dictionary = scheduler.source_control_state(source)
		if controls.get("reservations",[]).size() != 1: continue
		var lease: Dictionary = controls.reservations[0]
		if not expect(controls.get("outside_transaction",false) and controls.get("source_instance_id")==source.get_instance_id() and lease.get("id")==lease_id and lease.get("source_instance_id")==source.get_instance_id() and lease.get("response_actor_instance_id")==hero.get_instance_id(),"Actual settled selected source/lease/Hero identity joins"): return {}
		var proof: Dictionary = state.get("proof",{})
		if id == PLAIN:
			var committed: Dictionary = regular.call("current_echo_commit",PLAIN)
			if not committed.get("locked",false) or not lease.get("adapter",{}).get("locked",false): continue
			if not expect(state.get("cursor",{}).get("armed",false) and state.cursor.timeline_origin_s==lease.adapter.timeline_origin_s,"Real Playback cursor is armed at the same native committed timeline"): return {}
			var original_lease: Dictionary = committed.lease.duplicate(true)
			var current_lease: Dictionary = lease.duplicate(true)
			# Only the public derived phase changes as the unchanged native clock
			# advances. Every immutable armed lease field must still be identical.
			original_lease.erase("state"); current_lease.erase("state")
			if not expect(var_to_bytes(original_lease) == var_to_bytes(current_lease),"Actual retained Echo immutable armed commit equals current native lease"): return {}
			proof = committed.proof
			if not expect(proof.get("at_lock",false) and proof.get("timeline_origin_s") == lease.adapter.timeline_origin_s and proof.get("evaluated_at_s") == lease.lock_from_s,"Use genuine lock proof; never re-prove armed Echo"): return {}
		if not proof.get("accepted",false) or proof.get("uses_blast",true) or proof.get("uses_invulnerability",true): continue
		var first: Dictionary = {}
		for segment: Dictionary in proof.get("path",[]):
			if String(segment.kind).ends_with("dash"): first = segment; break
		if first.is_empty() or scheduler.get_clock() > float(first.start_s) + 0.000000001 or hero.global_position.distance_to(first.from) > 0.005: continue
		var actual_response: Dictionary=hero.get_threat_response_state().duplicate(true); actual_response.erase("actor")
		var c50_state: Dictionary=stalker.call("state")
		var selection: Dictionary={"clock_s":scheduler.get_clock(),"hero_position":hero.global_position,"facing":hero.facing,"hero":actual_response,"input":game.call("get_input_observation_state"),"stalker":{"position":c50_state.position,"velocity":c50_state.velocity,"phase":c50_state.phase,"cycle":c50_state.cycle}}
		var candidate: Dictionary = {"id":lease_id,"source_id":id,"owner":source,"lease":lease.duplicate(true),"proof":proof.duplicate(true),"selection":selection}
		var union_error: String = _pc_union_error(candidate)
		if union_error.is_empty():
			var observation: Dictionary=candidate.duplicate(true); observation.erase("owner"); observation["owner_instance_id"]=source.get_instance_id()
			_pc_selected_responses.append(observation) # Observation, not an assertion that execution completed.
			return candidate
		_pc_events.append({"kind":"declined_native_remaining_plan","clock_s":scheduler.get_clock(),"id":lease_id,"source_id":id,"reason":union_error,"proof":proof.duplicate(true)})
	return {}

func _pc_union_error(response: Dictionary) -> String:
	var path: Array[Dictionary] = []
	for segment: Dictionary in response.proof.path:
		if float(segment.end_s) >= scheduler.get_clock(): path.append(segment)
	if path.is_empty(): return "No unchanged remaining native rows"
	for source: Node3D in [stalker,plain]:
		var control: Dictionary = scheduler.source_control_state(source)
		if control.is_empty() or not control.get("outside_transaction",false): return "Pure settled native owner control required"
		for lease: Dictionary in control.reservations:
			if lease.get("adapter",{}).get("kind") == "authored_replay":
				if not lease.adapter.get("locked",false): continue # No active damage before native lock.
				var preview: Dictionary = source.call("preview_state")
				for slot: Dictionary in preview.slots:
					for event: Dictionary in slot.events:
						var record: Dictionary = event.record
						var geometry: Dictionary = PC_Geometry.cone(record.world_origin,record.direction,float(record.geometry.reach),float(record.geometry.cone_min_dot),float(record.geometry.origin_disk_radius))
						var at: float = float(lease.adapter.timeline_origin_s) + float(event.at_s)
						if PC_Geometry.timed_path_hits(geometry,path,at,at+CinderReplayWitness.MAX_DISPATCH_DELAY_S,CinderThreatScheduler.CAPSULE_RADIUS+CinderThreatScheduler.SKIN): return "Remaining original path intersects actual authored event " + String(event.event_id)
			elif not PC_Geometry.error(lease.geometry).is_empty(): return "Unsupported actual committed geometry"
			elif PC_Geometry.timed_path_hits(lease.geometry,path,float(lease.active_from_s),float(lease.active_until_s),CinderThreatScheduler.CAPSULE_RADIUS+CinderThreatScheduler.SKIN): return "Remaining original path intersects actual ordinary lease " + String(lease.id)
	return ""

func _pc_until(deadline: float,response: Dictionary) -> Dictionary:
	for _sample: int in range(900):
		var error: String = _pc_union_error(response)
		if not error.is_empty():
			_pc_events.append({"kind":"declined_original_plan","clock_s":scheduler.get_clock(),"original_id":response.id,"proof":response.proof.duplicate(true),"reason":error})
			var next: Dictionary = _pc_fresh()
			if not expect(not next.is_empty(),"Unsafe old plan requires an actual fresh same-origin native response, never retiming",error): return {}
			_pc_used[next.id] = true; return next
		if scheduler.get_clock() >= deadline: return response
		if not await tick(): return {}
	expect(false,"Finite original native deadline",_pc_detail()); return {}

func _pc_follow(initial: Dictionary) -> Dictionary:
	var response: Dictionary = initial
	for _revision: int in range(16):
		var changed: bool = false
		var actions_from: int = _pc_actions.size()
		for segment: Dictionary in response.proof.path:
			if not String(segment.kind).ends_with("dash"): continue
			var scheduled: float = maxf(float(segment.start_s),_pc_last_dash_end)
			var next: Dictionary = await _pc_until(scheduled,response)
			if next.is_empty(): return {}
			if next.id != response.id: response = next; changed = true; break
			var start: float = scheduler.get_clock()
			var origin: Vector3 = hero.global_position
			var direction: Vector3 = (segment.to-segment.from).normalized()
			if not expect(origin.distance_to(segment.from)<0.005 and hero.get_threat_response_state().dash_cooldown_left_s == 0.0 and hero.request_dash(direction),"Public full native dash begins at actual original response point"): return {}
			var cache: Dictionary = hero.get_committed_dash_state()
			if not expect(cache.get("active",false) and cache.distance == hero.stats.dash_distance and cache.duration_s == hero.stats.dash_duration,"Native immutable full dash cache retained"): return {}
			if not await _pc_complete_dash(segment,scheduled,start): return {}
			if String(segment.kind) in ["escape_dash","first_escape_dash"] and not expect(_pc_last_dash_end <= float(response.lease.active_from_s)+0.000000001,"Complete escape before original active interval"): return {}
		if changed: continue
		var next: Dictionary = await _pc_until(maxf(float(response.proof.primary_time_s),_pc_last_dash_end),response)
		if next.is_empty(): return {}
		if next.id != response.id: response = next; continue
		var source: Node3D = response.owner
		var phase: String = String(source.call("source_phase")) if response.source_id == PLAIN else String(source.call("state").phase)
		if not expect(phase == "recovery" and hero.global_position.distance_to(response.proof.attack_position)<0.02 and scheduler.get_clock()<float(response.lease.recovery_until_s),"Actual unchanged response reaches its OWN ordinary recovery opening"): return {}
		if not await _pc_primary(source,String(response.source_id)): return {}
		var finish: float = float(response.proof.response_complete_s)
		for _hold: int in range(120):
			if scheduler.get_clock() >= finish and hero.get_threat_response_state().primary_cooldown_left_s == 0.0 and hero.get_threat_response_state().commitment_remaining_s == 0.0: break
			if not await tick(): return {}
			if scheduler.get_clock()<finish and not expect(_pc_union_error(response).is_empty(),"Unmodified original remaining response stays safe during full primary hold; conservative historical crossing rows",_pc_detail()): return {}
		if not expect(scheduler.get_clock() >= finish and hero.get_threat_response_state().stable and hero.get_threat_response_state().primary_cooldown_left_s == 0.0 and hero.get_threat_response_state().commitment_remaining_s == 0.0 and scheduler.get_clock() < float(response.lease.recovery_until_s),"Full native ordinary-primary response hold and actual recovery, not immediate-hit-only"): return {}
		var receipt: Dictionary = {"source_id":response.source_id,"reservation_id":response.id,"lease":response.lease.duplicate(true),"proof":response.proof.duplicate(true),"selection":response.selection.duplicate(true),"actions":_pc_actions.slice(actions_from),"actual_hold_clock_s":scheduler.get_clock(),"hero_position":hero.global_position,"source_state":source.call("state"),"preview":plain.call("preview_state") if response.source_id == PLAIN else {}}
		_pc_holds.append(receipt)
		if response.source_id == PLAIN: _pc_echo_execution = receipt.duplicate(true)
		return response
	expect(false,"Finite sixteen actual native response revisions"); return {}

func _pc_complete_dash(segment: Dictionary,scheduled: float,started: float) -> bool:
	for _sample: int in range(80):
		if hero.get_threat_response_state().motion.dash_left_s == 0.0:
			var records: Array[Dictionary] = hero.get_world_action_records()
			var record: Dictionary = {} if records.is_empty() else records.back()
			var dt: float = 1.0/float(Engine.physics_ticks_per_second)
			var expected_end: float = started + ceil(float(hero.stats.dash_duration)/dt-0.000000001)*dt
			var ok: bool = record.get("kind") == "dash" and record.get("started_at_s") == started and started >= scheduled and started <= scheduled+dt+0.000000001 and absf(float(record.get("completed_at_s",-1.0))-expected_end)<0.000000001 and not record.get("collision_shortened",true) and not record.get("movement_damage",true) and hero.global_position.distance_to(segment.to)<0.005 and record.get("equipment_ids") == baseline_kit and hero.get_world_action_clock() == scheduler.get_clock()
			if not expect(ok,"Independent request/duration tick ceilings and full native path/landing remain exact",str(record)): return false
			_pc_last_dash_end = float(record.completed_at_s); return true
		if not await tick(): return false
	return expect(false,"Bounded original full dash completes")

func _pc_primary(source: Node3D,id: String) -> bool:
	if not expect(hero.get_threat_response_state().primary_cooldown_left_s == 0.0 and hero.get_world_action_clock()==scheduler.get_clock(),"Actual ordinary native cooldown/clock, no blast or synthetic delay/action"): return false
	var before: float = float(source.get("hp")); var old_actions: int = hero.get_world_action_records().size()
	var direction: Vector3 = source.global_position-hero.global_position; direction.y = 0.0
	var hits: int = hero.slash(direction.normalized()); _pc_last_tap_ms = Time.get_ticks_msec()
	var records: Array[Dictionary] = hero.get_world_action_records(); var record: Dictionary = {} if records.is_empty() else records.back()
	return expect(hits>0 and records.size()==old_actions+1 and record.get("kind")=="primary" and record.get("hits")==hits and record.get("damage")==hero.stats.primary_damage and float(source.get("hp"))==maxf(0.0,before-float(hero.stats.primary_damage)) and float(source.get("hp"))<before,"Useful actual ordinary HP damage on selected native "+id,str(record))

func tick() -> bool:
	if _pc_done or _pc_finished or paused or not is_instance_valid(barrier): return false
	barrier.frames = 0; barrier.expired = false; barrier.waiting = true
	await barrier.observed
	if _pc_done or _pc_finished or not is_instance_valid(regular): return false
	if not paused and not barrier.expired: ticks += 1
	var error: String = String(regular.call("runtime_error"))
	var state: Dictionary = stalker.call("state")
	for contact: Dictionary in _pc_hits:
		if contact.get("source_id") == STALKER and contact.get("opportunity_consumed",false): error = "C50 consumed contact even if invulnerability rejected HP damage"
		if contact.get("source_id") == PLAIN and (contact.get("contact",false) or contact.get("damage_attempted",false)): error = "C52 contact/damage attempt even if invulnerability rejected HP damage"
	if state.get("hit_consumed",false): error = "Actual C50 cycle consumed contact"
	for opportunity: Dictionary in plain.call("state").get("opportunities",[]):
		if opportunity.contact or opportunity.damage_attempted: error = "Actual retained C52 opportunity had contact"
	for id: String in [STALKER,PLAIN]:
		var source: Node3D = stalker if id == STALKER else plain
		var reason: String = String(source.call("state").get("last_cancel_reason","")) if id == STALKER else String(source.call("state").get("reason",""))
		if not reason.is_empty() and reason not in ["primary_stagger","source_defeated","authored_source_defeated"]: error = "Unexpected held/source cancellation: "+reason
	if hero.is_on_floor(): _pc_grounded = true
	elif _pc_grounded: error = "Actual grounded Hero lost floor contact"
	var fixed: bool = floor_collision.global_transform==floor_transform and (floor_collision.shape as BoxShape3D).size==floor_size and not floor_collision.disabled
	var ok: bool = not paused and not barrier.expired and error.is_empty() and fixed and not hero.dead and hero.hp==baseline_hp and hero.hp==hero.max_hp and hero.equipment.snapshot()==baseline_kit and hero.get_world_action_clock()==scheduler.get_clock() and (_pc_grounded or (hero.get_threat_response_state().motion.dash_left_s==0.0 and _pc_actions.is_empty())) and absf(hero.global_position.y)<=0.2 and Rect2(-6,-14,12,54).has_point(Vector2(hero.global_position.x,hero.global_position.z)) and scheduler.get_clock()<=baseline_epoch+CASE_BUDGET_S and not events.any(func(e: Dictionary)->bool: return e.get("attack")=="blast")
	_pc_trace.append(_pc_observation())
	return expect(ok,"Actual native timeline retains zero consumed contacts/fullHP/kit/ordinary actions/floor/clock",error+"; "+_pc_detail())

func _pc_observation() -> Dictionary:
	if not is_instance_valid(hero) or not is_instance_valid(scheduler) or not is_instance_valid(stalker) or not is_instance_valid(plain) or not is_instance_valid(regular) or not is_instance_valid(game): return {}
	var response: Dictionary = hero.get_threat_response_state().duplicate(true); response.erase("actor")
	return {"clock_s":scheduler.get_clock(),"hero":response,"hp":hero.hp,"stalker":stalker.call("state"),"echo":plain.call("state"),"echo_preview":plain.call("preview_state"),"c50_control":scheduler.source_control_state(stalker),"echo_control":scheduler.source_control_state(plain),"admission_reason":regular.get("last_admission_reason"),"camera_error":regular.get("last_camera_error"),"actual_camera":game.call("get_camera_framing_state"),"source_union":regular.call("camera_framing_union","",[],false,false),"native_world_id":str(hero.get_world_3d().get_instance_id()),"hud_viewport_size":(game.get("hud") as GameHUD).get_viewport().get_visible_rect().size}

func _pc_detail() -> String:
	return str({"cell":_pc_cell,"clock_s":scheduler.get_clock() if is_instance_valid(scheduler) else null,"hp":hero.hp if is_instance_valid(hero) else null,"position":hero.global_position if is_instance_valid(hero) else null,"contacts":_pc_hits,"last_actions":_pc_actions.slice(maxi(0,_pc_actions.size()-3))})

func _pc_action(record: Dictionary) -> void: _pc_actions.append(record.duplicate(true))
func _pc_fired(kind: String) -> void: events.append({"attack":kind})
func _pc_c50_contact(result: Dictionary) -> void:
	var row: Dictionary = result.duplicate(true); row["source_id"] = STALKER; _pc_hits.append(row)
func _pc_echo_event(event: Dictionary,opportunity: Dictionary) -> void:
	var row: Dictionary = opportunity.duplicate(true); row["source_id"] = PLAIN; row["event"] = event.duplicate(true); _pc_hits.append(row)
func _pc_source_hit(result: Dictionary) -> void: _pc_events.append({"kind":"real_echo_damage","clock_s":scheduler.get_clock(),"receipt":result.duplicate(true)})
func _pc_invalidated(id: String,reason: String) -> void: _pc_events.append({"kind":"invalidation","id":id,"reason":reason,"clock_s":scheduler.get_clock()})

func _pc_difference(old: Dictionary,new: Dictionary) -> Dictionary:
	var a: Dictionary = old.echo_execution; var b: Dictionary = new.echo_execution
	var result: Dictionary = {"outcome":"inconclusive","matched_actual_origin":false,"matched_native_schedule":false,"structural_response_difference":false,"whole_union_complete":false,"old_proof_unsupported":false,"actual_execution_corroborates":false,"range_only_diagnostic":false}
	# Same initial component spawn cannot stand in for the selected response
	# origin AFTER autonomous C50 pressure. No profile/clock/path is repaired.
	var first_a: Dictionary = a.proof.path[0]; var first_b: Dictionary = b.proof.path[0]
	result["matched_actual_origin"] = first_a.from==first_b.from and a.selection.hero_position==first_a.from and b.selection.hero_position==first_b.from and a.selection.facing==b.selection.facing and var_to_bytes(a.selection.hero)==var_to_bytes(b.selection.hero) and var_to_bytes(a.selection.input)==var_to_bytes(b.selection.input) and var_to_bytes(a.selection.stalker)==var_to_bytes(b.selection.stalker)
	if not result.matched_actual_origin: result["reason"]="Selected original proof origin/actual Hero response/input/C50 context differ"; return result
	var schedule_a: Dictionary = {}; var schedule_b: Dictionary = {}
	for key: String in ["start_s","lock_from_s","active_from_s","active_until_s","recovery_until_s","cooldown_until_s"]:
		schedule_a[key]=a.lease[key]; schedule_b[key]=b.lease[key]
	schedule_a["timeline_origin_s"]=a.lease.adapter.timeline_origin_s; schedule_b["timeline_origin_s"]=b.lease.adapter.timeline_origin_s
	schedule_a["proof_start_s"]=first_a.start_s; schedule_b["proof_start_s"]=first_b.start_s
	schedule_a["selected_at_s"]=a.selection.clock_s; schedule_b["selected_at_s"]=b.selection.clock_s
	result["matched_native_schedule"] = var_to_bytes(schedule_a)==var_to_bytes(schedule_b)
	if not result.matched_native_schedule: result["reason"]="Actual start/lock/active/recovery/selection schedules differ; no retiming"; return result
	# Kind/count/order is a composition decision. Direction, sign, coordinate,
	# initial/ending range, and which source happens to go first cannot pass it.
	var composition_a: Array[String] = []; var composition_b: Array[String] = []
	for row: Dictionary in a.proof.path:
		if String(row.kind).ends_with("dash"): composition_a.append(String(row.kind))
	for row: Dictionary in b.proof.path:
		if String(row.kind).ends_with("dash"): composition_b.append(String(row.kind))
	var actual_a: Array[String]=[]; var actual_b: Array[String]=[]
	for action: Dictionary in a.actions: actual_a.append(String(action.kind))
	for action: Dictionary in b.actions: actual_b.append(String(action.kind))
	var expected_a: Array[String]=[]; var expected_b: Array[String]=[]
	for _kind: String in composition_a: expected_a.append("dash")
	for _kind: String in composition_b: expected_b.append("dash")
	expected_a.append("primary"); expected_b.append("primary")
	result["actual_action_order_matches_original_paths"]=actual_a==expected_a and actual_b==expected_b
	if not result.actual_action_order_matches_original_paths: result["reason"]="Actual action records do not establish the complete original response composition"; return result
	composition_a.append("ordinary_primary:"+String(a.source_id)); composition_b.append("ordinary_primary:"+String(b.source_id))
	result["old_composition"]=composition_a; result["new_composition"]=composition_b
	result["structural_response_difference"]=composition_a!=composition_b
	var knot: Vector3=b.lease.opening_position; var attack: Vector3=a.proof.attack_position
	result["range_only_diagnostic"]=Vector2(attack.x,attack.z).distance_to(Vector2(knot.x,knot.z))>float(old.initial.hero.stats.primary_range)
	if not result.structural_response_difference: result["outcome"]="safe-no-demonstrated-structural-difference"; result["reason"]="Only direction/coordinates/range or an equivalent action composition differs"; return result
	# The complete actual controls/program/event observations remain literal in
	# BOTH cell traces. They are not a proof of every between-sample causal
	# interaction, and native request/duration ceilings can differ from original
	# theoretical rows. Do not replace/retime those rows or promote sampled
	# reconstruction into authority merely to obtain a positive classification.
	result["reason"]="Actual composition differs, but this bounded source-only classifier has no conclusive unchanged-proof/full-actual-union/rounding causal join; literal native traces retained"
	result["original_proof_rows_retained"]=true
	result["actual_whole_owner_observations"]=new.trace.size()
	result["actual_control_owners"]=[STALKER,PLAIN]
	return result

func _pc_close() -> void:
	if _pc_closing:
		for _frame: int in range(120):
			if _pc_close_done: return
			await process_frame
		expect(false,"Existing normal component cleanup settles within120 process frames"); return
	_pc_closing = true; _pc_close_done = false; paused = true
	# Freeze literal observations while actors still exist, before any public
	# exit/disposal. Global observed ticks are not mislabeled per-case ticks.
	if not _pc_cell_frozen and is_instance_valid(game):
		var partial: Dictionary = {"cell":_pc_cell,"completed":false,"partial":_pc_observation(),"actions":_pc_actions.duplicate(true),"contacts":_pc_hits.duplicate(true),"events":_pc_events.duplicate(true),"trace":_pc_trace.duplicate(true),"holds":_pc_holds.duplicate(true),"echo_execution":_pc_echo_execution.duplicate(true),"native_definition":_pc_definition.duplicate(true),"used_response_ids":_pc_used.duplicate(true),"observed_usable_responses":_pc_selected_responses.duplicate(true),"observed_native_ticks_global":ticks}
		_pc_frozen_results.append(var_to_bytes(partial)); _pc_cell_frozen = true
	if is_instance_valid(level): level.exit_level()
	var refs: Array[WeakRef] = []
	for node: Node in [regular,scheduler,stalker,plain,hero,level,game,barrier,_pc_view]:
		if is_instance_valid(node): refs.append(weakref(node))
	if is_instance_valid(barrier):
		if barrier.waiting:
			barrier.waiting = false; barrier.observed.emit() # Release only this TEST observer's suspended waiter.
		barrier.queue_free()
	await close()
	if is_instance_valid(_pc_view): _pc_view.queue_free()
	for _frame: int in range(3): await process_frame
	expect(refs.all(func(ref: WeakRef)->bool: return ref.get_ref()==null),"Normal whole declared component disposal frees native worlds/sources/Scheduler/floor/Hero/cues")
	expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),"No actor/cue group residue after component cleanup")
	game = null; level = null; hero = null; regular = null; scheduler = null; stalker = null; plain = null; barrier = null; _pc_view = null
	_pc_closing = false; _pc_close_done = true

func _pc_timeout() -> void:
	if _pc_done or _pc_finished: return
	expect(false,"600 wall seconds bounds only this comparison process; no native performance claim")
	await _pc_finish()

func _pc_finish() -> void:
	if _pc_finished: return
	_pc_finished = true; _pc_done = true
	await _pc_close()
	var path: String = "res://captures/act3/crystalman-plain-comparison/results-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	var folder: String = ProjectSettings.globalize_path(path)
	if expect(DirAccess.make_dir_recursive_absolute(folder)==OK,"New literal component result folder"):
		var output: FileAccess = FileAccess.open(path+"native-results.var.bin",FileAccess.WRITE)
		if expect(output!=null,"Literal native bytes remain diagnostic only"):
			output.store_buffer(var_to_bytes({"case_bytes":_pc_frozen_results,"comparison":_pc_comparison,"checks":checks,"failures":failures,"observed_native_ticks_global":ticks})); output.close()
	var outcome: String=String(_pc_comparison.get("outcome","incomplete-native-case"))
	print("L5_COMPARE_RESULT "+JSON.stringify({"outcome":outcome,"checks":checks,"failures":failures,"cases":_pc_cases.size(),"global_native_ticks":ticks,"native_result_path":path+"native-results.var.bin","matched_actual_origin":_pc_comparison.get("matched_actual_origin",false),"matched_native_schedule":_pc_comparison.get("matched_native_schedule",false),"structural_response_difference":_pc_comparison.get("structural_response_difference",false),"whole_union_complete":_pc_comparison.get("whole_union_complete",false),"old_proof_unsupported":_pc_comparison.get("old_proof_unsupported",false),"actual_execution_corroborates":_pc_comparison.get("actual_execution_corroborates",false)}))
	print("Crystalman plain comparison: %d checks/%d failures; %d observed native ticks; %d literal case rows; no parent/Approach Save, offered history, MAIN/fullroute/allkill/allkit/novelty acceptance claim." % [checks,failures,ticks,_pc_cases.size()])
	quit(0 if failures==0 else 1)
