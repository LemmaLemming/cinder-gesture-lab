extends SceneTree
## OFFLINE TEST DRAFT: real public fresh Shell paths, scene-authored displaced
## spawns, actual capsule/full billboard/shadow/source and native HUD wrapping.
## --original runs the same physical defect against unchanged published Shell;
## no missing-method assertion, alias swap, seeded pose or act acceptance.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const SCENES: Dictionary = {"A1-L1": "a1_l1", "A1-L2": "a1_l2", "A1-O1": "a1_o1", "A1-L3": "a1_l3"}
const ROOT_PATH: String = "res://.cinder/fresh-entry-camera-review/"
var game: CinderCampaignShell
var candidate: Dictionary = {}
var checks: int = 0
var failures: int = 0
var finished: bool = false
var original: bool = false
var test_root: String
var old_fps: int
var old_audio: AudioBusLayout

func _initialize() -> void:
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	original = OS.get_cmdline_user_args().has("--original")
	test_root = "user://test-fresh-entry-camera-%d/" % OS.get_process_id()
	_run.call_deferred()

func _run() -> void:
	create_timer(40.0, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "bounded native fixture watchdog")
			_finish())
	root.size = Vector2i(540, 1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for entry: Dictionary in raw.levels:
		if SCENES.has(entry.id):
			entry.scene_path = ROOT_PATH + SCENES[entry.id] + ".tscn"
			entry.readiness = "accepted"
			entry.accepted_commit = "a".repeat(40)
			entry.api_revision = Registry.API_REVISION
	game = Shell.new()
	if not _guard(game.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "isolated TEST ONLY in-memory registry and user paths"):
		_finish(); return
	root.add_child(game)
	await _frames(5)
	if not _guard(paused and game.player == null and game.menu.page_name() == "title", "genuine fresh Title has no installed Player or donor actor"):
		_finish(); return
	game.menu.show_journey()
	_expect(game.menu.page_name() == "journey", "real Journey menu exposes the first test room")
	game.menu.begin_story_requested.emit()
	await _frames(7)
	if original:
		await _original_reproduction()
		_finish(); return
	if not _guard(is_instance_valid(game.player) and game.campaign_error.is_empty(), "public Journey Begin installs displaced scene-authored Player: " + game.campaign_error):
		_finish(); return
	_check_installed("A1-L1", 15.0, "fresh Journey Begin")
	_expect(game.active_level.context_captures == 1, "first fresh writer receives one genuine explicit camera/HUD context")
	var first: Dictionary = game.capture_campaign_snapshot()
	if not _guard(not first.is_empty(), "installed live writer independently validates current native projection"):
		_finish(); return
	_expect(game.active_level.request_completion("test-first-clear"), "TEST ONLY public authored completion requests first route transition")
	await _frames(7)
	var carried: Dictionary = game.capture_campaign_snapshot()
	if not _guard(game.active_level.request_contact_exit("test-first-contact", game.player), "actual same living Hero contact requests next main room"):
		_finish(); return
	await _frames(7)
	if not _guard(game.campaign_error.is_empty() and game.active_level.level_id == "A1-L2", "public story transition accepts opposite displaced spawn: " + game.campaign_error):
		_finish(); return
	_check_installed("A1-L2", -15.0, "story transition with previous-room donor")
	_expect(game.player.hp == carried.player.resources.hp and game.player.shells == carried.player.resources.shells and game.player.equipment.snapshot() == carried.equipment_ids, "fresh story transition retains actual carried resources and equipment")
	_expect(game.active_level.last_context_safe_rect.position.y > 0.1, "long actual objective produces a taller native exclusion rectangle")
	_expect(game.active_level.request_completion("test-second-clear"), "TEST ONLY second clear unlocks its canonical optional parent")
	await _frames(7)
	var protected: Dictionary = game.attempts.story_snapshot()
	game.menu.optional_requested.emit("A1-O1")
	await _frames(7)
	if not _guard(game.campaign_error.is_empty() and game.attempts.active_kind() == "optional", "public optional fresh entry accepts displaced source/full Hero: " + game.campaign_error):
		_finish(); return
	_check_installed("A1-O1", 30.0, "fresh optional entry")
	_expect(_wire(game.attempts.story_snapshot()) == _wire(protected), "optional fresh capture preserves exact protected story aggregate")
	game.menu.leave_side_requested.emit()
	await _frames(7)
	if not _guard(game.campaign_error.is_empty() and game.attempts.active_kind() == "story", "ordinary saved side return still passes independent saved-focus gate: " + game.campaign_error):
		_finish(); return
	_expect(_wire(game.capture_campaign_snapshot()) == _wire(protected), "saved restoration does not apply a fresh fit or change actual saved unit")
	game.menu.replay_requested.emit("A1-L1", protected.equipment_ids)
	await _frames(7)
	if not _guard(game.campaign_error.is_empty() and game.attempts.active_kind() == "replay", "public completed-room replay enters fresh original displaced room: " + game.campaign_error):
		_finish(); return
	_check_installed("A1-L1", 15.0, "fresh completed-level replay")
	var replay_actor_id: int = game.player.get_instance_id()
	game.menu.resume_requested.emit()
	await create_timer(0.15).timeout
	for index: int in range(2):
		if not _guard(game.player.request_dash(Vector3.RIGHT), "genuine ordinary dash %d displaces replay donor through native motion" % (index + 1)):
			_finish(); return
		await create_timer(0.8).timeout
		if not _guard(not paused and not game.player.get_committed_dash_state().active, "native ordinary dash %d completes without timer/pose forcing" % (index + 1)):
			_finish(); return
	game.request_pause()
	await _frames(7)
	var moved: Dictionary = game.capture_campaign_snapshot()
	if not _guard(not moved.is_empty() and game.player.global_position.x > 4.0, "public Pause settles the actually moved replay donor"):
		_finish(); return
	game.menu.restart_replay_requested.emit("A1-L1", protected.equipment_ids)
	await _frames(7)
	if not _guard(game.campaign_error.is_empty() and game.player.get_instance_id() != replay_actor_id, "public replay restart commits a genuinely new fresh actor: " + game.campaign_error):
		_finish(); return
	_check_installed("A1-L1", 15.0, "fresh replay restart after actual donor motion")
	_expect(game.player.global_position.x == 0.0 and game.player.snapshot_state().world_actions.clock_s == 0.0, "restart uses actual scene-authored spawn and new action clock, never translated saved optics")
	_expect(_wire(game.attempts.story_snapshot()) == _wire(protected), "replay start/restart retain exact complete protected story")
	game.menu.leave_side_requested.emit()
	await _frames(7)
	if not _guard(game.campaign_error.is_empty() and game.attempts.active_kind() == "story", "return from restarted replay restores protected story"):
		_finish(); return
	var donor: Dictionary = _donor_receipt()
	if not _guard(not donor.player.is_empty() and not donor.level.is_empty() and not donor.attempts.is_empty(), "atomicity observations are complete nonempty exact packets"):
		_finish(); return
	candidate = game._prepare("A1-L3", game.player.equipment.snapshot())
	if not _guard(not candidate.is_empty(), "actual scene constructs an oversized native Box union without changing donor"):
		_finish(); return
	var candidate_camera_before: Transform3D = candidate.camera.global_transform
	var refused: Dictionary = game.call("_capture_fresh_candidate", candidate, game._fresh_shell_state())
	_expect(refused.is_empty() and game.campaign_error.begins_with("Fresh candidate presentation failed:"), "infeasible actual native source union visibly refuses before Attempt/disk commit")
	_expect(candidate.camera.global_transform == candidate_camera_before and _donor_receipt() == donor, "failed pure plan preserves candidate camera and entire installed donor/Attempt/disk/resource state")
	_expect(_staging_hud_count() == 0, "rejected oversized plan disposes actual temporary HUD viewport")
	game._dispose(candidate); candidate = {}
	game.campaign_error = ""
	_expect(_donor_receipt() == donor, "disposing rejected hidden candidate preserves installed aliases and exact state")
	# A TEST ONLY opted writer deliberately returns a malformed envelope AFTER
	# its checked capture. The shared helper must independently validate it.
	candidate = game._prepare("A1-L1", game.player.equipment.snapshot())
	if not _guard(not candidate.is_empty(), "malformed-writer control has a genuine native fresh constructor"):
		_finish(); return
	candidate.level.return_bad_snapshot = true
	var bad_result: Dictionary = game.call("_capture_fresh_candidate", candidate, game._fresh_shell_state())
	_expect(bad_result.is_empty() and not game.campaign_error.is_empty(), "shared pure whole-level validator rejects malformed returned writer envelope")
	_expect(_donor_receipt() == donor and _staging_hud_count() == 0, "malformed writer rejection leaves donor/Attempt/disk unchanged and frees actual HUD")
	game._dispose(candidate); candidate = {}
	game.campaign_error = ""
	# Saved focus is a TEST ONLY malformed transport. Its genuine Player/local
	# packet is unchanged; the existing saved gate must refuse, never fresh-fit.
	var wrong_focus: Dictionary = protected.duplicate(true)
	wrong_focus.shell.camera_focus[0] += 100.0
	_expect(game._snapshot_problem(wrong_focus).is_empty(), "existing mechanical pure validation remains independent of optical containment")
	candidate = game._prepare_snapshot(wrong_focus)
	_expect(candidate.is_empty() and game.campaign_error.begins_with("Restore candidate presentation failed:"), "saved optical gate rejects invalid current native projection without fresh refit")
	_expect(_donor_receipt() == donor and game._validation_candidates.is_empty(), "failed saved gate retains donor and leaves no hidden recipient")
	game.campaign_error = ""
	candidate = game._prepare_snapshot(protected)
	_expect(not candidate.is_empty(), "same original exact valid save accepts after both optical refusals")
	if not candidate.is_empty(): game._dispose(candidate)
	candidate = {}
	game._dispose_validation_candidates()
	_expect(_donor_receipt() == donor and _staging_hud_count() == 0, "accepted saved gate still changes no donor or required HUD state")
	_finish()

func _original_reproduction() -> void:
	# These are intentionally the expected correct behavior assertions. Their
	# concrete failures demonstrate actual old projection/capture, not API absence.
	_expect(is_instance_valid(game.player) and game.campaign_error.is_empty(), "ORIGINAL: fresh Journey must install displaced source/Player before live capture; actual error=" + game.campaign_error)
	var before: Dictionary = {"attempts": _wire(game.attempts.state()), "disk": _disk_receipt(), "camera": game.camera.global_transform, "focus": game._camera_focus}
	candidate = game._prepare("A1-L1", CinderEquipment.STARTER)
	if not _guard(not candidate.is_empty(), "ORIGINAL: real native source/Player candidate construction succeeds"):
		return
	_expect(candidate.player.global_position == Vector3(0.0, 0.1, 15.0) and candidate.level.source.mesh is BoxMesh, "ORIGINAL: scene-authored displaced native source exists without synthetic saved pose")
	var actual_error: String = game.camera_framing_error_for_context(candidate.level.camera_framing_points(), candidate.player, candidate.camera, game.hud)
	_expect(actual_error.is_empty(), "ORIGINAL: actual current native camera must contain full physical source/Hero; actual error=" + actual_error)
	var result: Dictionary = game._capture(candidate.player, candidate.level, game._fresh_shell_state())
	_expect(not result.is_empty(), "ORIGINAL: ordinary fresh capture must pass actual live optical writer; actual error=" + game.campaign_error)
	_expect(game.player == null and _wire(game.attempts.state()) == before.attempts and _disk_receipt() == before.disk and game.camera.global_transform == before.camera and game._camera_focus == before.focus, "ORIGINAL: rejected stale projection preserves actual Title donor/attempt/disk")
	game._dispose(candidate); candidate = {}

func _check_installed(id: String, z: float, label: String) -> void:
	_expect(paused and game.active_level.level_id == id and game.player.global_position.z == z and game.player.global_position.x == 0.0, label + ": actual authored spawn installed paused")
	var source_points: Array = game.active_level.camera_framing_points()
	var body_points: Array = game.player_camera_framing_points_for(game.player, game.camera)
	_expect(source_points.size() == 8 and body_points.size() == 22, label + ": native Box source plus complete capsule/quad/shadow bounds measured")
	_expect(game.camera_framing_error_for_context(source_points, game.player, game.camera, game.hud).is_empty(), label + ": current native projection contains the complete actual union")
	_expect(game.active_level.context_captures == 1 and game.active_level.last_context_pixels == Vector2(540, 1170), label + ": explicit writer used actual outer native pixels once")
	_expect(game.active_level.last_context_safe_rect == game.hud.combat_safe_rect() and game.active_level.last_context_objective == game.hud._objective_label.text, label + ": temporary actual HUD shape matches immediately installed actual objective")
	var saved: Dictionary = game.attempts.active_snapshot()
	_expect(not saved.is_empty() and game.camera.global_position == Value.read_vector3(saved.shell.camera_focus) + game.CAMERA_OFFSET and game._camera_focus == Value.read_vector3(saved.shell.camera_focus), label + ": actual camera and committed Shell focus agree without an extra-frame replan")
	_expect(_staging_hud_count() == 0, label + ": successful fresh capture frees its temporary native HUD")

func _wire(value: Dictionary) -> String:
	return Exact.stringify(value)

func _transform(transform: Transform3D) -> Array:
	return [Value.vector3(transform.basis.x), Value.vector3(transform.basis.y), Value.vector3(transform.basis.z), Value.vector3(transform.origin)]

func _disk_receipt() -> Dictionary:
	var disk: Dictionary = {}
	for name: String in ["campaign.json", "campaign.json.bak"]:
		var path: String = test_root + name
		disk[name] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	return disk

func _donor_receipt() -> Dictionary:
	var rect: Rect2 = game.hud.combat_safe_rect()
	return {"player_id": str(game.player.get_instance_id()), "level_id": str(game.active_level.get_instance_id()), "world_id": str(game.world.get_instance_id()), "camera_id": str(game.camera.get_instance_id()), "hud_id": str(game.hud.get_instance_id()), "camera": _transform(game.camera.global_transform), "player": _wire(game.player.snapshot_state()), "level": _wire(game.active_level.snapshot_state()), "attempts": _wire(game.attempts.state()), "safe_rect": [float(rect.position.x), float(rect.position.y), float(rect.size.x), float(rect.size.y)], "objective": game.hud._objective_label.text, "anchor": [float(game._swipe_end_normalized.x), float(game._swipe_end_normalized.y)], "input": game._input_sequence, "focus": Value.vector3(game._camera_focus), "shake": game._shake, "disk": _disk_receipt()}

func _staging_hud_count() -> int:
	var count: int = 0
	for node: Node in game.get_children():
		if node is SubViewport and node.name in ["FreshCaptureHUDViewport", "RestorePresentationHUDViewport"]: count += 1
	return count

func _frames(count: int) -> void:
	for _index: int in range(count): await process_frame

func _guard(ok: bool, note: String) -> bool:
	_expect(ok, note)
	return ok

func _expect(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + note)

func _stop_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		node.stop()
	for child: Node in node.get_children(): _stop_audio(child)

func _finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(game):
		_stop_audio(game)
		if not candidate.is_empty(): game._dispose(candidate)
		game._dispose_validation_candidates()
	# Real-time audio flush after assertions; no source/action-clock adjustment.
	await create_timer(0.3, true).timeout
	if is_instance_valid(game): game.free()
	paused = false
	await _frames(2)
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	Engine.max_fps = old_fps
	AudioServer.set_bus_layout(old_audio)
	print("Fresh entry camera smoke: %d checks, %d failures; original=%s; TEST ONLY real fresh paths/current native optics, no authored acceptance" % [checks, failures, str(original)])
	quit(0 if failures == 0 else 1)
