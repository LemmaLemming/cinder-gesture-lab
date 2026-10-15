extends "res://tests/acts/act3/irontick_reflection_portrait.gd"
## Diagnostic-only reader: original producer/runtime/reader pins stay unchanged.
func _portrait() -> bool:
	await process_frame # Native UI layout only; gameplay remains paused.
	var view: SubViewport = production.world.get_parent() as SubViewport
	var container: SubViewportContainer = view.get_parent() as SubViewportContainer
	if not _expect(paused and not production.is_pause_requested() and container.is_visible_in_tree() and view.own_world_3d and view.get_camera_3d() == production.camera and production.hud.visible and production.menu.visible, "actual installed native World/Camera/Hero/HUD and paused Menu are visible"):
		return false
	var wire: String = Exact.stringify(production.capture_campaign_snapshot())
	var input: PackedByteArray = var_to_bytes(production.get_input_observation_state())
	var optics_before: Dictionary = _optics_record().duplicate(true)
	var optics: PackedByteArray = var_to_bytes(optics_before)
	var events: PackedByteArray = var_to_bytes(receiver_events)
	var menu_visibility: bool = production.menu.visible
	production.menu.visible = false # TEST ONLY independent overlay exclusion.
	draw_seen = false
	RenderingServer.frame_post_draw.connect(_on_draw)
	for _frame: int in range(32):
		await process_frame
		if finished or not is_instance_valid(production):
			if is_instance_valid(production): production.menu.visible = menu_visibility
			if RenderingServer.frame_post_draw.is_connected(_on_draw): RenderingServer.frame_post_draw.disconnect(_on_draw)
			return false
		if draw_seen: break
	if RenderingServer.frame_post_draw.is_connected(_on_draw): RenderingServer.frame_post_draw.disconnect(_on_draw)
	var pixels: Image = root.get_texture().get_image() if draw_seen else null
	var problem: String = String(production.active_level.call("candidate_presentation_error", production.camera, production.hud))
	var unchanged: bool = paused and not production.is_pause_requested() and not wire.is_empty() and wire == Exact.stringify(production.capture_campaign_snapshot()) and input == var_to_bytes(production.get_input_observation_state()) and optics == var_to_bytes(_optics_record()) and events == var_to_bytes(receiver_events)
	var diagnostic: Dictionary = {"draw_seen":draw_seen,"pixels_size":str(pixels.get_size()) if pixels != null else "null","paused":paused,"pause_pending":production.is_pause_requested(),"wire_nonempty":not wire.is_empty(),"wire_equal":wire == Exact.stringify(production.capture_campaign_snapshot()),"input_equal":input == var_to_bytes(production.get_input_observation_state()),"optics_equal":optics == var_to_bytes(_optics_record()),"events_equal":events == var_to_bytes(receiver_events),"candidate_error":problem,"shell_error":production.campaign_error,"level_error":production.active_level.last_snapshot_error}
	print("O3 PORTRAIT DIAGNOSTIC: ",str(diagnostic))
	if not diagnostic.optics_equal: print("O3 OPTICS BEFORE: ",str(optics_before),"\nO3 OPTICS AFTER: ",str(_optics_record()))
	if pixels != null:
		var diagnostic_path: String = "res://captures/act3/irontick-reflection/diagnostic-%d.png" % OS.get_process_id()
		print("O3 DIAGNOSTIC PIXELS: ",ProjectSettings.globalize_path(diagnostic_path)," save=",pixels.save_png(diagnostic_path))
	production.menu.visible = menu_visibility # Restore before every failure return.
	if not _expect(draw_seen and pixels != null and pixels.get_size().x == 340 and pixels.get_size().y == 736 and unchanged and production.menu.visible == menu_visibility and problem.is_empty(), "native paused portrait preserves full packet/input/current Camera/HUD/events and restores Menu", problem):
		return false
	var folder: String = "res://captures/act3/irontick-reflection/portrait-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	portrait_path = folder.path_join("01-authentic-held-warning.png")
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK and pixels.save_png(portrait_path) == OK, "original native portrait pixels saved unchanged"):
		return false
	# Resource IDs may use signed high bits. Preserve exact decimal text in
	# evidence metadata; do not widen campaign ExactJson numeric contracts.
	var native: Dictionary = _native_ids()
	var native_text: Dictionary = {}
	for key: String in native: native_text[key] = str(native[key])
	var receipt: Dictionary = {"schema_version": 1, "test_only": true, "archive": archive_path, "archive_manifest_sha256": FileAccess.get_sha256(archive_path.path_join("manifest.json")), "reader_sha256": FileAccess.get_sha256("res://tests/acts/act3/irontick_reflection_portrait.gd"), "png_sha256": FileAccess.get_sha256(portrait_path), "actual_size": [pixels.get_size().x, pixels.get_size().y], "actual_native_ids_decimal_text": native_text, "held_receipt": _held_receipt(), "whole_pair_exact_wire_sha256": wire.sha256_text(), "paused_without_tick": true, "whole_pair_input_camera_hud_events_unchanged": unchanged, "native_optical_error": problem, "menu_test_only_exclusion": {"visible_before": menu_visibility, "visible_during": false, "visible_restored": production.menu.visible}, "scope": "one authentic saved warning; no active/lateral/full-route/pacing/human balance claim"}
	var file: FileAccess = FileAccess.open(portrait_path + ".json", FileAccess.WRITE)
	if not _expect(file != null, "native portrait receipt opens"): return false
	var receipt_wire: String = Exact.stringify(receipt)
	if not _expect(not receipt_wire.is_empty(), "complete finite portrait receipt preserves native identity text"):
		file.close(); return false
	file.store_string(receipt_wire + "\n")
	file.close()
	print("O3 PORTRAIT: ", ProjectSettings.globalize_path(portrait_path))
	return true
