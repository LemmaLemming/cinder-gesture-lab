extends "res://tests/acts/act3/garden_helper_choice_smoke.gd"
## TEST ONLY saved dead-helper reader. Never runs a producer or gameplay route.
## A pinned CLOSED clean --transport-dead result/log and original archive are
## required. The manifest is custody only; public Shell/native validation rules.

const HP_NATIVE_FILES: Array[String] = ["unit.native.json", "session.native.json", "checkpoint.native.json", "registry.native.json"]
const HP_STORE_FILES: Array[String] = ["campaign.json", "campaign.json.bak", "preferences.json"]
const HP_SOURCE_PATHS: Array[String] = ["res://tests/acts/act3/garden_helper_choice_smoke.gd", HC_RUNTIME, "res://tests/acts/act3/fixtures/garden_helper_choice_component_codec.gd", HC_ROOM, "res://scripts/acts/act3/garden_root_network.gd", "res://scripts/acts/act3/garden_root_latcher.gd", "res://scripts/acts/act3/garden_root_tether.gd", "res://scripts/acts/act3/false_paradise_level.gd", "res://scripts/acts/act3/false_paradise_codec.gd", "res://scripts/combat/threat_scheduler.gd", "res://scripts/campaign/shell.gd", "res://data/design/difficulty_profiles.json"]
var _hp_args: Dictionary = {}
var _hp_archive: String = ""
var _hp_manifest: Dictionary = {}
var _hp_files: Dictionary = {}
var _hp_origin: Dictionary = {}
var _hp_origin_sources: Dictionary = {}
var _hp_unit: Dictionary = {}
var _hp_session: Dictionary = {}
var _hp_png: String = ""
var _hp_draw_seen: bool = false
var _hp_exclusions: Array[Dictionary] = []
var _hp_draw_ui: Array[Dictionary] = []

func _run() -> void:
	_hc_selector = "saved-dead-portrait"
	_hc_case_name = "saved-dead-portrait"
	_hc_registry_text = FileAccess.get_file_as_string(HC_Registry.DATA_PATH)
	if not _expect(DisplayServer.get_name() != "headless", "saved dead portrait requires the actual graphical renderer"):
		await _finish(); return
	root.size = Vector2i(340,736)
	root.content_scale_size = Vector2i(340,736)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for argument: String in OS.get_cmdline_user_args():
		var at: int = argument.find("=")
		if at <= 2 or not argument.begins_with("--") or _hp_args.has(argument.substr(2,at-2)):
			_expect(false,"unique explicit portrait custody arguments",argument); await _finish(); return
		_hp_args[argument.substr(2,at-2)] = argument.substr(at+1)
	if not _expect(PairCodec.keys_error(_hp_args,["archive","manifest-sha256","origin-run","origin-result-sha256","origin-log-sha256"]).is_empty(),"exact archive and CLOSED origin result/log pins supplied"):
		await _finish(); return
	for key: String in ["manifest-sha256","origin-result-sha256","origin-log-sha256"]:
		if not _expect(_hp_digest(_hp_args[key]),"explicit SHA256 required: "+key): await _finish(); return
	_hp_archive = ProjectSettings.localize_path(String(_hp_args.archive)).trim_suffix("/") + "/"
	if not _expect(_hp_archive.begins_with("res://captures/act3/garden-helper-choice/dead-"),"explicit original dead-helper archive under the owned capture root"):
		await _finish(); return
	if not _hp_read_origin() or not _hp_read_archive(): await _finish(); return
	paused = true # This reader never enables gameplay. Shared registration remains public Shell-owned.
	_hc_registry = _hp_files["registry.native.json"].duplicate(true)
	_hc_initial = _hp_files["checkpoint.native.json"].duplicate(true)
	_hc_store_root = "user://test-garden-helper-saved-portrait-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_hc_store_root)) == OK,"new isolated reader Store directory"):
		await _finish(); return
	for name: String in HP_STORE_FILES:
		if _hp_manifest.files.has(name) and not _hp_write(_hc_store_root+name,FileAccess.get_file_as_bytes(_hp_archive+name)):
			await _finish(); return
	if not node_added.is_connected(_hc_watch_node): node_added.connect(_hc_watch_node)
	if not await _hc_new_shell(_hp_session): await _finish(); return
	_hc_shell.menu.continue_story_requested.emit()
	if not await _hp_installed() or not _hc_bind(): await _finish(); return
	_hc_quiet_events.clear(); _events.clear(); _hc_actions.clear(); _hc_quiet = true
	if not await _hc_quiet_exact(_hp_unit,_hp_session) or not await _hp_portrait(): await _finish(); return
	_expect(not _hp_png.is_empty(),"one actual paused saved-dead PNG and typed witnesses retained")
	await _finish()

func _hp_digest(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value:
		if not "0123456789abcdef".contains(character): return false
	return true

func _hp_bytes(path: String) -> PackedByteArray:
	var file: FileAccess = FileAccess.open(path,FileAccess.READ)
	if not _expect(file != null,"original custody file exists",path): return PackedByteArray()
	if not _expect(file.get_length() > 0 and file.get_length() <= HC_Exact.MAX_BYTES,"bounded nonempty custody file",path): file.close(); return PackedByteArray()
	var bytes: PackedByteArray = file.get_buffer(file.get_length()); file.close()
	return bytes

func _hp_read_origin() -> bool:
	var folder: String = String(_hp_args["origin-run"]).trim_suffix("/") + "/"
	var bytes: PackedByteArray = _hp_bytes(folder+"result.json")
	if bytes.is_empty() or not _expect(FileAccess.get_sha256(folder+"result.json") == _hp_args["origin-result-sha256"],"exact CLOSED origin result bytes"): return false
	var result: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not _expect(result is Dictionary and result.get("closed_at") is String and not result.closed_at.is_empty() and result.get("actual_exit_code") == 0 and result.get("diagnostics") is Array and result.diagnostics.is_empty() and result.get("selected_source_changes_during_run") is Array and result.selected_source_changes_during_run.is_empty() and result.get("footers") is Array and not result.footers.is_empty(),"terminal clean origin metadata exists; no inferred pass or mutable run"):
		return false
	var summaries: Array[String] = []
	for item: Variant in result.footers:
		if not _expect(item is String,"original runner footer is textual"): return false
		if item.begins_with("Garden helper choice: ") and item.contains("; failures: ") and item.contains("; selector=") and item.contains("; observed native ticks="): summaries.append(item)
	if not _expect(summaries.size() == 1,"exactly one actual final summary among all original runner footer records"): return false
	bytes = _hp_bytes(folder+"native.log")
	if bytes.is_empty(): return false
	var log_hash: String = FileAccess.get_sha256(folder+"native.log")
	var footer: String = summaries[0]
	if not _expect(log_hash == _hp_args["origin-log-sha256"] and result.get("native_log_sha256") == log_hash and footer.begins_with("Garden helper choice: ") and footer.contains("; failures: 0; selector=--transport-dead;") and footer.contains("; cases=1; authentic archives=") and footer.contains('"'+_hp_archive+'"') and bytes.get_string_from_utf8().contains(footer),"pinned actual clean dead-transport footer names this exact authentic archive"):
		return false
	bytes = _hp_bytes(folder+"sources.json")
	if bytes.is_empty(): return false
	var sources: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not _expect(sources is Dictionary and sources.get("head") is String and sources.head.length() == 40 and sources.head == result.get("head_after") and sources.get("selected_sources") is Dictionary and not sources.selected_sources.is_empty(),"closed origin HEAD joins its original selected source manifest"): return false
	_hp_origin_sources = sources.selected_sources.duplicate(true)
	_hp_origin = {"run":folder,"result_sha256":_hp_args["origin-result-sha256"],"native_log_sha256":log_hash,"sources_sha256":FileAccess.get_sha256(folder+"sources.json"),"head":sources.head,"closed_at":result.closed_at,"summary_footer":footer,"all_original_footers":result.footers.duplicate()}
	return true

func _hp_read_archive() -> bool:
	var bytes: PackedByteArray = _hp_bytes(_hp_archive+"manifest.json")
	if bytes.is_empty() or not _expect(FileAccess.get_sha256(_hp_archive+"manifest.json") == _hp_args["manifest-sha256"],"original manifest pin matches"): return false
	var parsed: Dictionary = HC_Exact.parse(bytes.get_string_from_utf8())
	if not _expect(parsed.get("accepted",false) and parsed.get("value") is Dictionary,"bounded original native manifest parses exactly"): return false
	_hp_manifest = parsed.value
	if not _expect(PairCodec.keys_error(_hp_manifest,["schema_version","scope","files","source_pins","producer_fixture_hash_is_provenance_only"]).is_empty() and _hp_manifest.schema_version == 1 and _hp_manifest.scope == "TEST Challenge helper component, genuinely earned boundary/death; no canonical MAIN checkpoint5/route authority" and _hp_manifest.producer_fixture_hash_is_provenance_only == true and _hp_manifest.files is Dictionary and _hp_manifest.source_pins is Dictionary and PairCodec.keys_error(_hp_manifest.source_pins,HP_SOURCE_PATHS).is_empty(),"closed original TEST archive declaration and source inventory"): return false
	for name: String in HP_NATIVE_FILES + ["campaign.json"]:
		if not _expect(_hp_manifest.files.has(name),"required original archive member: "+name): return false
	for name: Variant in _hp_manifest.files:
		if not _expect(name is String and (HP_NATIVE_FILES.has(name) or HP_STORE_FILES.has(name)),"closed archive member name",str(name)): return false
		var receipt: Variant = _hp_manifest.files[name]
		if not _expect(receipt is Dictionary and PairCodec.keys_error(receipt,["bytes","sha256"]).is_empty() and receipt.bytes is int and receipt.bytes > 0 and receipt.bytes <= HC_Exact.MAX_BYTES and _hp_digest(receipt.sha256),"bounded typed archive receipt: "+name): return false
		bytes = _hp_bytes(_hp_archive+name)
		if bytes.is_empty() or not _expect(bytes.size() == receipt.bytes and FileAccess.get_sha256(_hp_archive+name) == receipt.sha256,"unchanged original archive bytes: "+name): return false
		if HP_NATIVE_FILES.has(name):
			parsed = HC_Exact.parse(bytes.get_string_from_utf8())
			if not _expect(parsed.get("accepted",false) and parsed.get("value") is Dictionary,"native ExactJSON archive value: "+name): return false
			_hp_files[name] = parsed.value
	if not _hp_sources_exact(): return false
	_hp_unit = _hp_files["unit.native.json"]
	_hp_session = _hp_files["session.native.json"]
	var registry: Dictionary = _hp_files["registry.native.json"]
	var canonical: Variant = JSON.parse_string(_hc_registry_text)
	if not _expect(canonical is Dictionary and canonical.get("levels") is Array,"canonical registry supports the original disclosed TEST row"): return false
	for row: Dictionary in canonical.levels:
		if row.id == "A3-L4": row.scene_path = HC_ROOM; row.readiness = "accepted"; row.accepted_commit = "a".repeat(40); row.api_revision = HC_Registry.API_REVISION
	var model: CinderCampaignAttempts = HC_Attempts.new(HC_Registry.new(registry))
	if not _expect(_wire_exact(registry,canonical) and model.state_error(_hp_session).is_empty() and _hp_session.completed_main == model.registry.main_route().slice(0,13) and _hp_session.story is Dictionary and _hp_session.story.level_id == "A3-L4" and _wire_exact(_hp_session.story.snapshot,_hp_unit) and _wire_exact(_hp_session.story.checkpoint,_hp_files["checkpoint.native.json"]),"original TEST prefix13/session/clock0 checkpoint joins; no canonical MAIN authority"): return false
	if not _expect(PairCodec.keys_error(_hp_unit,["schema_version","level_id","scene_path","paused","equipment_ids","player","level","shell"]).is_empty() and _hp_unit.schema_version == 1 and _hp_unit.level_id == "A3-L4" and _hp_unit.scene_path == HC_ROOM and _hp_unit.paused == true and _hp_unit.level is Dictionary and _hp_unit.level.get("local") is Dictionary,"complete original TEST whole unit identity"): return false
	var local: Dictionary = _hp_unit.level.local
	return _expect(local.get("world") is Dictionary and local.world.get("profile_id") == "challenge" and local.get("helper") is Dictionary and local.helper.get("dead") == true and local.helper.get("hp") == 0.0 and local.get("control") is Dictionary and local.control.get("helper_death") is Dictionary and not local.control.helper_death.is_empty(),"saved archive has actual Challenge dead-helper receipt; native validators still decide")

func _hp_sources_exact() -> bool:
	for path: String in HP_SOURCE_PATHS:
		var digest: Variant = _hp_manifest.source_pins[path]
		if not _expect(_hp_digest(digest),"original runtime source hash exists: "+path): return false
		var selected_path: String = path.trim_prefix("res://")
		var blob: String = String(_hp_origin.run)+"source-blobs/"+String(digest)+".bin"
		if not _expect(_hp_origin_sources.get(selected_path) == digest and FileAccess.get_sha256(blob) == digest,"archive source pin joins original frozen selected map and exact source blob: "+path): return false
		# The producer fixture is provenance; this separate reader is not that writer.
		if path == "res://tests/acts/act3/garden_helper_choice_smoke.gd": continue
		if not _expect(FileAccess.get_sha256(path) == digest,"archived native runtime source remains exact: "+path): return false
	return true

func _hp_installed() -> bool:
	for _frame: int in range(120):
		await process_frame
		if _hc_done or _hc_finishing: return false
		if not _hc_shell.campaign_error.is_empty(): return _expect(false,"public saved-dead Continue refuses explicitly",_hc_shell.campaign_error)
		if not paused or not is_instance_valid(_hc_shell.active_level) or _hc_shell.menu.page_name() != "resume": continue
		var unit: Dictionary = _hc_shell.capture_campaign_snapshot()
		if unit.is_empty() or not _wire_exact(unit,_hp_unit): continue
		var level: CinderLevel = _hc_shell.active_level
		var helper: StaticBody3D = level.get("helper") as StaticBody3D
		var core: Node3D = level.get("root_network") as Node3D
		if not is_instance_valid(helper) or not is_instance_valid(core): return _expect(false,"actual saved helper and Core retained")
		var body: CollisionShape3D = helper.get_node_or_null("BodyCollision") as CollisionShape3D
		var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
		var mechanism: CinderLaneMechanism = helper.call("get_mechanism")
		if not _expect(is_instance_valid(scheduler) and is_instance_valid(mechanism),"actual retained native Scheduler/helper mechanism"): return false
		var controls: Dictionary = scheduler.source_control_state(mechanism)
		var target: StaticBody3D = core.call("get_tether") as StaticBody3D
		var state: Dictionary = level.call("component_state")
		return _expect(not _hc_shell.is_pause_requested() and level.hero == _hc_shell.player and level.shared_shell == _hc_shell and _hc_shell.camera == _hc_shell.player.get_viewport().get_camera_3d() and _hc_shell.camera.get_world_3d() == _hc_shell.player.get_world_3d() and not level.is_restore_candidate() and String(level.call("runtime_error")).is_empty() and level.snapshot_error_with_player(unit.level,unit.player).is_empty() and _wire_exact(_hc_shell.attempts.state(),_hp_session) and helper.get("dead") == true and helper.get("hp") == 0.0 and helper.collision_layer == 0 and helper.collision_mask == 0 and body != null and body.disabled and not helper.is_in_group("enemies") and not controls.is_empty() and controls.reservations.is_empty() and not state.helper_death.is_empty() and state.helper_retired.is_empty() and is_instance_valid(target) and target.get("hp") == 30.0 and target.get("phase") == 2 and scheduler.encounter_profile().get("id") == "challenge","public paused Continue recaptures exact dead unit/native body/lease/history/current context; no invented donor identity")
	return _expect(false,"bounded public saved-dead Continue installation",_hc_shell.campaign_error)

func _hp_labels(node: Node, rows: Array) -> void:
	if node is Label:
		var label: Label = node as Label
		rows.append([String(_hc_shell.get_path_to(label)),label.text,label.is_visible_in_tree(),label.global_position,label.size,label.get_theme_font_size("font_size")])
	for child: Node in node.get_children(): _hp_labels(child,rows)

func _hp_render(node: Node, rows: Array) -> void:
	if node is Node3D:
		var physical: Node3D = node as Node3D
		var row: Array = [String(_hc_shell.get_path_to(node)),str(node.get_instance_id()),physical.transform,physical.global_transform,physical.visible,physical.is_visible_in_tree()]
		if node is CollisionObject3D:
			var body: CollisionObject3D = node as CollisionObject3D
			row.append_array([body.collision_layer,body.collision_mask,node.is_in_group("enemies")])
		if node is CollisionShape3D:
			var collision: CollisionShape3D = node as CollisionShape3D
			var shape: Shape3D = collision.shape
			var dimensions: Variant = null
			if shape is BoxShape3D: dimensions = (shape as BoxShape3D).size
			elif shape is CapsuleShape3D: dimensions = [(shape as CapsuleShape3D).radius,(shape as CapsuleShape3D).height]
			row.append_array([collision.disabled,str(shape.get_instance_id()) if shape != null else "",dimensions])
		if node is MeshInstance3D:
			var mesh: MeshInstance3D = node as MeshInstance3D
			var materials: Array = []
			if mesh.mesh != null:
				for surface: int in range(mesh.mesh.get_surface_count()):
					var material: Material = mesh.get_active_material(surface)
					materials.append(str(material.get_instance_id()) if material != null else "")
			row.append_array([str(mesh.mesh.get_instance_id()) if mesh.mesh != null else "",str(mesh.material_override.get_instance_id()) if mesh.material_override != null else "",materials,mesh.layers])
		if node is Sprite3D:
			var sprite: Sprite3D = node as Sprite3D
			row.append_array([str(sprite.texture.get_instance_id()) if sprite.texture != null else "",sprite.pixel_size,sprite.offset,sprite.modulate,sprite.layers])
		rows.append(row)
	for child: Node in node.get_children(): _hp_render(child,rows)

func _hp_witnesses() -> Dictionary:
	if not paused or not is_instance_valid(_hc_shell) or not is_instance_valid(_level) or not _hc_shell.campaign_error.is_empty(): return {}
	var camera: Camera3D = _hc_shell.camera
	var hud: GameHUD = _hc_shell.hud
	if camera != _hero.get_viewport().get_camera_3d() or camera.get_world_3d() != _hero.get_world_3d() or not hud.visible: return {}
	var union: Dictionary = _level.call("framing_union",camera)
	var sun: Dictionary = _level.call("optional_sun_bounds",camera)
	if not String(union.get("error","Missing full current union")).is_empty() or not union.get("points") is Array or union.points.is_empty() or not String(sun.get("error","Missing actual Sun bounds")).is_empty() or not sun.get("points") is Array or sun.points.size() != 16: return {}
	var view_error: String = String(_hc_shell.call("camera_framing_error",union.points))
	if not view_error.is_empty() or not String(_hc_shell.call("camera_framing_error",sun.points)).is_empty(): return {}
	var labels: Array = []; _hp_labels(hud,labels); _hp_labels(_hc_shell.menu,labels)
	var optics: Dictionary = {"camera":[camera.global_transform,camera.projection,camera.keep_aspect,camera.size,camera.near,camera.far,camera.h_offset,camera.v_offset,camera.cull_mask],"framing":_hc_shell.call("get_camera_framing_state"),"hud":[hud.visible,hud.combat_safe_rect(),labels],"menu":[_hc_shell.menu.visible,_hc_shell.menu.page_name()],"union":union,"sun_bounds":sun,"sun":_level.call("sun_presentation_state"),"root_size":root.size}
	var render: Array = []; _hp_render(_hc_shell.world,render)
	var native: Dictionary = _hc_host_observation(_hc_shell)
	var input: Dictionary = _hc_shell.get_input_observation_state()
	if native.is_empty() or native.get("unit",{}).is_empty() or native.get("ids",{}).is_empty() or native.get("choice_native",{}).is_empty() or input.is_empty() or optics.is_empty() or labels.is_empty() or render.is_empty(): return {}
	native["events"] = {"events":_events.duplicate(),"quiet":_hc_quiet_events.duplicate(),"actions":_hc_actions.duplicate(true)}
	var typed: Dictionary = {"native":native,"input":input,"optics":optics,"render":render}
	var bytes: Dictionary = {}
	for key: String in typed:
		bytes[key] = var_to_bytes(typed[key])
		if (bytes[key] as PackedByteArray).is_empty(): return {}
	return bytes

func _hp_restore_ui() -> void:
	for row: Dictionary in _hp_exclusions:
		var layer: CanvasLayer = (row.node as WeakRef).get_ref() as CanvasLayer
		if is_instance_valid(layer): layer.visible = row.visible

func _hp_ui_state() -> Array[Dictionary]:
	var actual: Array[Dictionary] = []
	for row: Dictionary in _hp_exclusions:
		var layer: CanvasLayer = (row.node as WeakRef).get_ref() as CanvasLayer
		actual.append({"label":row.label,"available":is_instance_valid(layer),"visible":layer.visible if is_instance_valid(layer) else null})
	return actual

func _hp_all_hidden(actual: Array[Dictionary]) -> bool:
	if actual.is_empty() or actual.size() != _hp_exclusions.size(): return false
	for row: Dictionary in actual:
		if row.available != true or row.visible != false: return false
	return true

func _hp_portrait() -> bool:
	var campaign_error_before: String = _hc_shell.campaign_error
	var before: Dictionary = _hp_witnesses()
	if not _expect(before.size() == 4 and _hc_shell.campaign_error.is_empty() and _hc_quiet_events.is_empty() and _wire_exact(_hc_shell.capture_campaign_snapshot(),_hp_unit),"four actual NONEMPTY typed witnesses and no campaign error before saved-dead draw"): return false
	_hp_exclusions = [{"node":weakref(_hc_shell.menu),"visible":_hc_shell.menu.visible,"label":"campaign menu"}]
	var bench: CanvasLayer = _hc_shell.get("bench") as CanvasLayer
	if is_instance_valid(bench): _hp_exclusions.append({"node":weakref(bench),"visible":bench.visible,"label":"bench"})
	for row: Dictionary in _hp_exclusions: ((row.node as WeakRef).get_ref() as CanvasLayer).visible = false
	_hp_draw_seen = false
	_hp_draw_ui.clear()
	var visibility_observations: Array = [_hp_ui_state()]
	var hidden_during_draw: bool = _hp_all_hidden(visibility_observations[0])
	RenderingServer.frame_post_draw.connect(_hp_on_draw)
	for _frame: int in range(120):
		await process_frame
		var actual: Array[Dictionary] = _hp_ui_state()
		visibility_observations.append(actual)
		hidden_during_draw = hidden_during_draw and _hp_all_hidden(actual)
		if _hp_draw_seen or _hc_done or _hc_finishing: break
	if RenderingServer.frame_post_draw.is_connected(_hp_on_draw): RenderingServer.frame_post_draw.disconnect(_hp_on_draw)
	var picture: Image = root.get_texture().get_image() if _hp_draw_seen and not _hc_finishing else null
	hidden_during_draw = hidden_during_draw and _hp_all_hidden(_hp_draw_ui)
	_hp_restore_ui() # Restore every presentation exclusion BEFORE any return/validation.
	if _hc_done or _hc_finishing: return false
	var campaign_error_after: String = _hc_shell.campaign_error
	var after: Dictionary = _hp_witnesses()
	var unchanged: bool = after.size() == 4 and paused and _hc_shell.campaign_error.is_empty() and not _hc_shell.is_pause_requested() and _hc_quiet_events.is_empty() and _wire_exact(_hc_shell.capture_campaign_snapshot(),_hp_unit) and _wire_exact(_hc_shell.attempts.state(),_hp_session)
	for key: String in before: unchanged = unchanged and before[key] == after.get(key)
	if not _expect(_hp_draw_seen and hidden_during_draw and picture != null and not picture.is_empty() and picture.get_size().x in [339,340] and picture.get_size().y == 736 and unchanged,"actual paused339/340x736 dead portrait preserves native/input/optics/render without gameplay, hidden actors or campaign errors"): return false
	if not _hp_sources_exact() or not _expect(FileAccess.get_sha256(_hp_archive+"manifest.json") == _hp_args["manifest-sha256"],"original archive pin remains unchanged after draw"): return false
	var folder: String = "res://captures/act3/garden-helper-choice/portrait-dead-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,"unique actual portrait output folder"): return false
	_hp_png = folder+"01-authentic-saved-dead-helper.png"
	if not _expect(picture.save_png(_hp_png) == OK,"original native PNG saved without resizing"): return false
	var pins: Dictionary = {}
	for key: String in before:
		var path: String = folder+key+".var.bin"
		if not _hp_write(path,before[key]): return false
		pins[key] = {"file":key+".var.bin","bytes":(before[key] as PackedByteArray).size(),"sha256":FileAccess.get_sha256(path)}
	var exclusions: Array = []
	for index: int in range(_hp_exclusions.size()):
		var row: Dictionary = _hp_exclusions[index]
		exclusions.append({"label":row.label,"visible_before":row.visible,"visible_during":_hp_draw_ui[index].visible,"visible_restored":((row.node as WeakRef).get_ref() as CanvasLayer).visible})
	var receipt: Dictionary = {"schema_version":1,"test_only":true,"kind":"a3-l4-authentic-saved-dead-portrait-1","origin":_hp_origin,"archive":_hp_archive,"manifest_sha256":_hp_args["manifest-sha256"],"reader_sha256":FileAccess.get_sha256("res://tests/acts/act3/garden_helper_choice_portrait.gd"),"actual_dimensions":[picture.get_size().x,picture.get_size().y],"png_sha256":FileAccess.get_sha256(_hp_png),"clock_s":_scheduler.get_clock(),"helper_dead":true,"helper_hp":_hc_helper.get("hp"),"tether_hp":_tether.get("hp"),"typed_witnesses":pins,"native_input_optics_render_unchanged":unchanged,"menu_only_exclusions_restored":exclusions,"actual_hidden_ui_observations":visibility_observations,"actual_post_draw_ui":_hp_draw_ui,"hidden_at_every_observed_boundary":hidden_during_draw,"campaign_error_before":campaign_error_before,"campaign_error_after":campaign_error_after,"scope":"One actual paused authentic TEST Challenge dead-helper view, restored by public Continue. No gameplay route/active view/new producer/canonical MAIN checkpoint5/art-fidelity/human balance/level acceptance credit."}
	var wire: String = HC_Exact.stringify(receipt)
	if not _expect(not wire.is_empty(),"portrait receipt contains only exact JSON-safe observations") or not _hp_write(_hp_png+".json",wire.to_utf8_buffer()): return false
	print("GARDEN_HELPER_SAVED_DEAD_PORTRAIT "+ProjectSettings.globalize_path(_hp_png)+" sha256="+receipt.png_sha256)
	return true

func _hp_write(path: String, bytes: PackedByteArray) -> bool:
	if not _expect(not bytes.is_empty() and not FileAccess.file_exists(path),"new nonempty reader output",path): return false
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if not _expect(file != null,"reader output opens",path): return false
	file.store_buffer(bytes); file.flush(); var error: Error = file.get_error(); file.close()
	return _expect(error == OK and FileAccess.get_file_as_bytes(path) == bytes,"reader bytes persist exactly",path)

func _hp_on_draw() -> void:
	_hp_draw_ui = _hp_ui_state()
	_hp_draw_seen = true

func _finish() -> void:
	if _hc_finishing: return
	_hc_finishing = true; _hc_done = true
	if RenderingServer.frame_post_draw.is_connected(_hp_on_draw): RenderingServer.frame_post_draw.disconnect(_hp_on_draw)
	_hp_restore_ui()
	await _close()
	if node_added.is_connected(_hc_watch_node): node_added.disconnect(_hc_watch_node)
	_expect(_hc_registry_text.is_empty() or FileAccess.get_file_as_string(HC_Registry.DATA_PATH) == _hc_registry_text,"canonical registry remains exact")
	print("Garden helper saved portrait: %d checks; failures: %d; png=%s. Paused authentic TEST dead-helper only; no active route/producer/MAIN/acceptance credit." % [_checks,_failures,_hp_png])
	quit(0 if _failures == 0 else 1)
