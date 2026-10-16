extends "res://tests/acts/act1/a1_l5_shell_transport.gd"
## INERT ROOT DRAFT. Paused genuine119 native world + declared TEST preflight
## inputs only. No preview/start/guard override, source activation or earned
## gameplay claim. Calls the real production camera update for soft preframing,
## with zero delta while paused; never sets a camera transform or native clock.
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const PacketPath: String = "res://tests/acts/act1/fixtures/a1_l5_saved_portrait_units.json"
const PacketSha: String = "2daa482db269374b4360d1abc4d89ff618f6f08c1bc222bea49e139913a6dd0e"
const CandidateSha: String = "d25ae002a4d6256fd95b3e6df557541de1cd4ac4503cc7fde3dd50d52b0d4808"
var report_path: String = ""
var selected_moon: CinderLevel
var report_rows: Array[Dictionary] = []
var regression_receipts: Dictionary = {}
var completed: bool = false
var owned_store_created: bool = false
var native_world_created: bool = false

func _run() -> void:
	root.size = Vector2i(540,1170)
	report_path = OS.get_environment("CINDER_A1_L5_FORECAST_REPORT")
	if not _expect(OS.get_cmdline_user_args() == PackedStringArray(["--forecast-publication"]),"one bounded forecast-publication selector"): await _finish(); return
	if not _expect(report_path.is_absolute_path() and not FileAccess.file_exists(report_path),"fresh absolute Root phase report"): await _finish(); return
	if not _expect(FileAccess.get_sha256("res://scripts/acts/act1/living_moon.gd") == CandidateSha and FileAccess.get_sha256(PacketPath) == PacketSha,"exact candidate and unchanged historical119 packet"): await _finish(); return
	test_root = "user://test-act1-l5-forecast-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	var actual_store_dir: String = ProjectSettings.globalize_path(test_root)
	if not _expect(not DirAccess.dir_exists_absolute(actual_store_dir) and DirAccess.make_dir_recursive_absolute(actual_store_dir) == OK,"fresh isolated owned user Store directory"): await _finish(); return
	owned_store_created = true
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	var registry_doc: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(registry_doc is Dictionary,"actual canonical Registry metadata"): await _finish(); return
	raw = registry_doc.duplicate(true)
	var registry := Registry.new(raw)
	if not _expect(registry.last_error.is_empty(),"unchanged canonical accepted Registry"): await _finish(); return
	if not await _restore_original(registry): await _finish(); return
	selected_moon = game.active_level
	native_world_created = is_instance_valid(selected_moon)
	var before: PackedByteArray = var_to_bytes(_native_data())
	if not _expect(before.size() > 0 and selected_moon.get("blink").state().status == "running" and selected_moon.get("nose").state().cycle == 0 and selected_moon.get("_forecast").is_empty() and game.camera_framing_error(selected_moon.camera_framing_points()).is_empty(),"genuine paused live Blink and contained committed view before synthetic proposal inputs"): await _finish(); return
	if not _write_witness("native-before.var",before): await _finish(); return
	operation = "declared TEST hard planner rejection"
	if not _hard_rejection(before): await _finish(); return
	operation = "declared TEST feasible preframe and invalid-input cleanup"
	if not _soft_and_invalid(before): await _finish(); return
	completed = true
	await _finish()

func _restore_original(registry: CinderCampaignRegistry) -> bool:
	var bundle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PacketPath))
	var row: Dictionary = bundle.frames[0]
	if not _expect(bundle.source_checks == 119 and bundle.source_failures == 0 and row.label == "blink-recovery-actual-landing","one existing genuine119 selected frame, not new production playthrough"): return false
	var decoded: Dictionary = Exact.parse(String(row.snapshot_exact))
	var checkpoint: Dictionary = Exact.parse(String(row.checkpoint_exact))
	if not _expect(decoded.get("accepted",false) and checkpoint.get("accepted",false) and Exact.stringify(decoded.value) == row.snapshot_exact and Exact.stringify(checkpoint.value) == row.checkpoint_exact,"literal original whole/current/checkpoint typed strings unchanged"): return false
	var model := Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = Prefix.duplicate() # Disclosed original TEST prefix.
	payload.story = {"kind":"story","level_id":Layout.LEVEL_ID,"snapshot":decoded.value.duplicate(true),"checkpoint":checkpoint.value.duplicate(true)}
	var store := Store.new(test_root+"campaign.json")
	store.payload_validator = model.saved_payload_error
	var model_error: String = model.state_error(payload)
	var written: bool = store.write_payload(payload) if model_error.is_empty() else false
	var store_detail: String = "model_error="+model_error+"; Store.last_error="+store.last_error
	regression_receipts["store_setup"] = {"model_error":model_error,"store_last_error":store.last_error,"written":written,"owned_user_path":test_root}
	if not _expect(model_error.is_empty() and written,"isolated Store accepts unchanged genuine saved unit plus disclosed TEST predecessors"):
		report_rows.back()["detail"] = store_detail
		first_failure["detail"] = store_detail
		return false
	game = _new_shell()
	if game == null or not await _settle(): return false
	if not _expect(paused and game.active_level == null and game.menu.page_name() == "title","actual fresh paused Title"): return false
	game.menu.continue_story_requested.emit() # Public selection; no GUI credit.
	if not await _settle() or not _bindings(game): return false
	regression_receipts["saved_setup"] = {"packet_sha256":PacketSha,"selected_label":row.label,"snapshot_sha256":row.snapshot_sha256,"prefix":Prefix,"selection":"public Continue signal; no GUI/earned-route credit","source_scope":"Original119 TEST predecessor/Rusher/approach/recovery placements retained; not earned return movement."}
	return _expect(paused and _same(game.capture_campaign_snapshot(),decoded.value) and game.campaign_error.is_empty(),"fresh current native recipient retains exact original saved state before proposal probe")

func _proposal(landing: Vector3) -> Dictionary:
	# Explicit TEST preflight input. Its shape is the unchanged authored Nose
	# cone, but this is not a native preview result or accepted gameplay proof.
	var now: float = _scheduler().get_clock()
	var origin: Vector3 = selected_moon.get("nose").global_position
	var shape: Dictionary = Geometry.cone(origin,Vector3.BACK,Layout.SNEEZE_REACH,Layout.SNEEZE_MIN_DOT,Layout.SNEEZE_ORIGIN_RADIUS)
	return {"accepted":true,"candidate":{"opening_position":Layout.EYE_POSITION,"geometry":shape,"active_until_s":now+1.0,"recovery_until_s":now+4.0},"proof":{"landing":landing,"attack_position":game.player.global_position,"primary_time_s":now+1.1,"response_complete_s":now+1.4}}

func _prospective_points(proposal: Dictionary) -> Array:
	var points: Array = selected_moon.call("_camera_framing_points",false)
	points.append_array(selected_moon.call("_source_points",Layout.NOSE_ID,proposal.candidate.opening_position))
	points.append_array(selected_moon.call("_geometry_points",proposal.candidate.geometry))
	points.append_array(selected_moon.call("_response_points",proposal.proof.landing,proposal.proof.attack_position))
	return selected_moon.call("_unique",points)

func _hard_rejection(before: PackedByteArray) -> bool:
	var committed: Array = selected_moon.camera_framing_points()
	var proposal: Dictionary = _proposal(game.player.global_position+Vector3.LEFT*30.0)
	var proposed: Array = _prospective_points(proposal)
	var plan: Dictionary = game.camera_framing_plan(proposed,game.player.global_position+Vector3.UP*0.65)
	if not _expect(not plan.get("accepted",false),"actual fixed camera planner refuses declared wide TEST prospective union"): return false
	var ready: bool = selected_moon.call("_prepare_forecast",Layout.NOSE_ID,proposal)
	regression_receipts["hard_rejection"] = {"input_kind":"TEST preflight only; no native source request","proposal":_encode(proposal),"plan_accepted":plan.get("accepted",false),"plan_reason":plan.get("reason",""),"prepare_return":ready,"error":selected_moon.get("last_encounter_error"),"forecast_count":selected_moon.get("_forecast").size(),"pending":selected_moon.get("_pending_start").duplicate(true)}
	if not _expect(not ready and selected_moon.get("_forecast").is_empty() and selected_moon.get("_pending_start").is_empty() and not String(selected_moon.get("last_encounter_error")).is_empty(),"hard planner rejection transaction retires unpublished forecast/pending"): return false
	if not _expect(var_to_bytes(selected_moon.camera_framing_points()) == var_to_bytes(committed) and game.camera_framing_error(committed).is_empty(),"rejected-only points no longer poison default framing of unchanged committed native exchange"): return false
	game.call("_update_camera",0.0) # Real camera planner/apply; no clock/lens/setter.
	return _unchanged(before,"after-hard.var") and _expect(game.camera_framing_error(committed).is_empty(),"normal production camera update preserves contained committed view after rollback")

func _soft_and_invalid(before: PackedByteArray) -> bool:
	var camera: Camera3D = game.camera
	var dimensions: Vector2 = camera.get_viewport().get_visible_rect().size
	var safe: Rect2 = game.hud.combat_safe_rect()
	var hero_y: float = camera.unproject_position(game.player.global_position).y/dimensions.y
	var proposal: Dictionary = {}
	var attempts: Array[Dictionary] = []
	# Finite geometric input construction, not native route/proof search. Pick
	# a slightly clipped point whose actual full union still has a valid plan.
	for x: float in [safe.position.x-0.002,safe.end.x+0.002]:
		var screen := Vector2(x*dimensions.x,hero_y*dimensions.y)
		var ray: Vector3 = camera.project_ray_normal(screen)
		var origin: Vector3 = camera.project_ray_origin(screen)
		var landing: Vector3 = origin+ray*((game.player.global_position.y-origin.y)/ray.y)
		var candidate_input: Dictionary = _proposal(landing)
		var points: Array = _prospective_points(candidate_input)
		var planned: Dictionary = game.camera_framing_plan(points,game.player.global_position+Vector3.UP*0.65)
		var current_error: String = game.camera_framing_error(points)
		attempts.append({"landing":_encode(landing),"plan_accepted":planned.get("accepted",false),"plan_reason":planned.get("reason",""),"current_error":current_error})
		if planned.get("accepted",false) and not current_error.is_empty(): proposal = candidate_input; break
	regression_receipts["soft_input_selection"] = attempts
	if not _expect(not proposal.is_empty(),"finite real projection supplies a feasible TEST union outside only its current view"): return false
	var ready: bool = selected_moon.call("_prepare_forecast",Layout.NOSE_ID,proposal)
	if not _expect(not ready and not selected_moon.get("_forecast").is_empty() and selected_moon.get("_pending_start").is_empty() and not String(selected_moon.get("last_encounter_error")).is_empty(),"fit plan/current-not-contained retains feasible preframe points but does not stage source admission"): return false
	if not _unchanged(before,"during-soft.var"): return false
	game.call("_update_camera",0.0) # Controlled production update while paused.
	ready = selected_moon.call("_prepare_forecast",Layout.NOSE_ID,proposal)
	regression_receipts["soft_preframe"] = {"prepare_after_production_camera_update":ready,"current_error":game.camera_framing_error(selected_moon.camera_framing_points()),"scope":"Paused transaction component calls unchanged production camera update with zero delta. Not autonomous live camera/gameplay or source admission credit."}
	if not _expect(ready and not selected_moon.get("_forecast").is_empty() and not selected_moon.get("_pending_start").is_empty(),"normal production camera planner can preframe feasible proposal without any native start call"): return false
	if not _unchanged(before,"after-soft.var"): return false
	var invalids: Array[Dictionary] = [{"accepted":false,"reason":"TEST no-longer-valid preview"},{"accepted":true,"candidate":{},"proof":{}}]
	var bad_time: Dictionary = proposal.duplicate(true)
	bad_time.proof.primary_time_s = bad_time.candidate.active_until_s-0.1
	invalids.append(bad_time)
	var errors: Array[String] = ["TEST no-longer-valid preview","Actual native candidate/proof required","Ordinary primary and its recovery must fit genuine source recovery"]
	for index: int in invalids.size():
		if index > 0 and not _expect(selected_moon.call("_prepare_forecast",Layout.NOSE_ID,proposal),"restage only feasible TEST proposal before next invalid-input gate"): return false
		ready = selected_moon.call("_prepare_forecast",Layout.NOSE_ID,invalids[index])
		if not _expect(not ready and selected_moon.get("_forecast").is_empty() and selected_moon.get("_pending_start").is_empty() and String(selected_moon.get("last_encounter_error")) == errors[index],"new invalid preview retires prior unpublished state while retaining error precedence gate"+str(index)): return false
	return _unchanged(before,"after-invalid.var") and _expect(game.camera_framing_error(selected_moon.camera_framing_points()).is_empty(),"invalid-preview cleanup leaves actual committed view available")

func _native_data() -> Dictionary:
	var eye: Node3D = selected_moon.get("eye")
	var nose: Node3D = selected_moon.get("nose")
	return {"hero":game.player.snapshot_state(),"blink":selected_moon.get("blink").state(),"nose":nose.call("state"),"eye":{"id":str(eye.get_instance_id()),"position":eye.global_position,"hp":eye.get("hp"),"phase":eye.get("phase"),"dead":eye.get("dead")},"eye_control":_scheduler().source_control_state(eye),"nose_control":_scheduler().source_control_state(nose),"frames":selected_moon.get("_frames").duplicate(true),"stage":selected_moon.get("stage"),"next_attack":selected_moon.get("next_attack"),"pending_phase":selected_moon.get("pending_phase"),"escape":selected_moon.get("escape").duplicate(true),"input":game.get_input_observation_state(),"attempts":game.attempts.state()}

func _unchanged(before: PackedByteArray, name: String) -> bool:
	var after: PackedByteArray = var_to_bytes(_native_data())
	return _expect(paused and before == after,"live saved native/Player/resources/leases/frames/input/progress remain exact: "+name) and _write_witness(name,after)

func _write_witness(name: String, wire: PackedByteArray) -> bool:
	var path: String = report_path.get_base_dir()+"/"+name
	if not _expect(wire.size() > 0 and not FileAccess.file_exists(path),"fresh nonempty original native witness "+name): return false
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if not _expect(file != null,"native witness opens "+name): return false
	file.store_buffer(wire); file.close()
	return _expect(FileAccess.get_file_as_bytes(path) == wire,"native typed witness retained exactly "+name)

func _expect(ok: bool, label: String) -> bool:
	var result: bool = super._expect(ok,label)
	report_rows.append({"check":checks,"label":label,"note":label,"ok":ok})
	return result

func _encode(value: Variant) -> Variant:
	# Diagnostic views can contain native 2D camera bounds. Preserve their
	# contents as closed JSON; original gameplay witnesses stay typed .var.
	if value is Vector2: return [value.x,value.y]
	if value is Rect2: return {"native_type":"Rect2","position":_encode(value.position),"size":_encode(value.size)}
	if value is Vector3: return Codec.vector3(value)
	if value is Color: return [value.r,value.g,value.b,value.a]
	if value is Basis: return {"x":_encode(value.x),"y":_encode(value.y),"z":_encode(value.z)}
	if value is Transform3D: return {"basis":_encode(value.basis),"origin":_encode(value.origin)}
	if value is StringName: return String(value)
	if value is int and (value < -9007199254740991 or value > 9007199254740991): return {"native_integer_decimal":str(value)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _encode(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child: Variant in value: result.append(_encode(child))
		return result
	return value

func _retain_owned_store() -> bool:
	if not owned_store_created:
		regression_receipts["owned_store_files"] = {"created":false,"files":[]}
		return true
	var directory := DirAccess.open(test_root)
	if not _expect(directory != null,"unique owned user Store directory remains available before cleanup"): return false
	var names: PackedStringArray = directory.get_files()
	if not _expect(names.size() <= 16 and directory.get_directories().is_empty(),"bounded unique owned Store contains only its native files"): return false
	var captured: Array[Dictionary] = []
	var destination: String = report_path.get_base_dir()+"/native-store/"
	if not _expect(not DirAccess.dir_exists_absolute(destination) and DirAccess.make_dir_recursive_absolute(destination) == OK,"fresh phase native Store artifact directory"): return false
	for name: String in names:
		var original: String = test_root+name
		var retained: String = destination+name
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(original)
		var file: FileAccess = FileAccess.open(retained,FileAccess.WRITE)
		if not _expect(file != null,"original owned native Store artifact opens: "+name): return false
		file.store_buffer(bytes); file.close()
		if not _expect(FileAccess.get_file_as_bytes(retained) == bytes and FileAccess.get_sha256(original) == FileAccess.get_sha256(retained),"original owned native Store bytes/SHA retained: "+name): return false
		captured.append({"name":name,"original_user_path":original,"original_absolute_path":ProjectSettings.globalize_path(original),"retained_path":retained,"bytes":bytes.size(),"sha256":FileAccess.get_sha256(retained)})
	regression_receipts["owned_store_files"] = {"created":true,"owned_user_path":test_root,"files":captured}
	return true

func _cleanup_owned_store() -> bool:
	if not owned_store_created: return true
	var directory := DirAccess.open(test_root)
	if not _expect(directory != null and directory.get_directories().is_empty(),"owned Store has no foreign nested cleanup scope"): return false
	for name: String in directory.get_files():
		if not _expect(DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root+name)) == OK,"remove only original unique owned Store file: "+name): return false
	return _expect(DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root)) == OK and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(test_root)),"unique owned user Store directory retired after artifact custody")

func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	var refs: Array[WeakRef] = []
	if is_instance_valid(game): refs.append_array(_refs(game)); game.free()
	game = null; selected_moon = null
	paused = false
	await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),"normal owned Shell/source/cue disposal or pre-Shell setup refusal leaves no retained descendants/groups")
	if completed: _expect(native_world_created and not refs.is_empty() and _freed(refs),"completed regression created and normally retired its actual native world")
	var store_retained: bool = _retain_owned_store()
	if not store_retained:
		completed = false
		regression_receipts["owned_store_cleanup"] = "Skipped after retention failure; unique original owned files preserved for diagnostic recovery"
	elif not _cleanup_owned_store(): completed = false
	if not registry_bytes.is_empty(): _expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes,"canonical Registry remains unchanged")
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	# Refuse an existing path again at closure; early setup failures must not
	# truncate a prior report. The writer assertion belongs to the real rows.
	var report_file: FileAccess = null
	if report_path.is_absolute_path() and not FileAccess.file_exists(report_path): report_file = FileAccess.open(report_path,FileAccess.WRITE)
	if not _expect(report_file != null,"fresh closed native regression report opens"): completed = false
	var packet: Dictionary = {"kind":"a1-l5-forecast-publication-regression-1","checks":checks,"failures":failures,"complete":completed,"success":completed and failures == 0,"rows":report_rows,"first_failure":first_failure,"receipts":regression_receipts,"candidate_sha256":CandidateSha,"historical_packet_sha256":PacketSha,"scope":"Paused genuine119 native world with disclosed TEST prefix and explicit synthetic proposal inputs. Tests publication rollback/feasible preframe/invalid-preview cleanup only. No source start, guard override, altered clock/HP/pose/lens, new gameplay proof/route/final-response/GUI/Retry/all-kit credit. Original owned user Store bytes are captured byte-exact in this Root phase before unique owned cleanup; original typed witnesses remain here."}
	if report_file != null:
		report_file.store_string(JSON.stringify(_encode(packet),"",true,true)+"\n"); report_file.close()
	print("CINDER_A1_L5_FORECAST_REPORT=",report_path," sha256=",FileAccess.get_sha256(report_path) if FileAccess.file_exists(report_path) else "")
	print("A1-L5 FORECAST: %d checks, %d failures; complete=%s" % [checks,failures,str(completed)])
	quit(0 if completed and failures == 0 else 2)
