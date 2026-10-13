extends "res://tests/acts/act3/garden_root_rule_room_smoke.gd"
## Focused art fixture only. Added consumers are outside prototype v2 snapshots.
## Parent cosmetic disengagement is disclosed test setup, not an earned clear.
## Render capture uses public resume then the existing disclosed TEST ONLY
## tree freeze, with no direct UI/camera alteration. Public pause remains tested
## separately; these visible frames are not pause-panel screenshots.
## Application focus notifications remain enabled. Unexpected pause is drained
## and publicly resumed only for the isolated cosmetic progression below;
## no application-focus behavior acceptance is claimed.
const GardenArt = preload("res://scripts/acts/act3/garden_scenery.gd")
const LikenessArt = preload("res://scripts/acts/act3/garden_likeness_art.gd")
const LikenessTexture = preload("res://assets/acts/act3/garden/sullenbode-likeness-v1.png")
const CosmeticExact = preload("res://scripts/campaign/exact_json.gd")
var _garden: Node3D
var _likeness: Node3D


func _run() -> void:
	if not _expect(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name() != "headless", "garden art fixture requires actual graphical portrait without automatic preview selectors"):
		await _finish()
		return
	if not await _open():
		await _finish()
		return
	_garden = GardenArt.new()
	_garden.name = "GardenDressingArtFixture"
	_level.add_child(_garden)
	_likeness = LikenessArt.new()
	_likeness.name = "HarmlessLikenessArtFixture"
	_likeness.position = Vector3(-0.85, 0, -1.5)
	_level.add_child(_likeness)
	var floor_before: Transform3D = (_level.get("_floor_body") as StaticBody3D).global_transform
	var art_ok: bool = _garden.call("build") and _likeness.call("configure", LikenessTexture)
	if not _expect(art_ok and _garden.call("runtime_error") == "" and _likeness.call("runtime_error") == "" and _garden.call("state").mesh_count == 130 and not _likeness.is_in_group("enemies") and not _garden.is_in_group("enemies"), "produced native garden/likeness build with recorded geometry and harmless role", str(_garden.call("state")) + "; " + String(_likeness.call("runtime_error"))):
		await _finish()
		return
	if not await _capture_art("welcoming-court"):
		await _finish()
		return
	var answer: Dictionary = await _admit("draw", Vector3.LEFT)
	if answer.is_empty() or not await _capture_art("draw-warning"):
		await _finish()
		return
	# Public cancellation retires the actual warning before an isolated cosmetic
	# fade probe; no actor movement, injury, target HP or source clock is edited.
	_allow_cancelled = true
	if not _expect(_source("draw").cancel("art_fixture_cosmetic_probe") and _all_sources_clear(), "public native cancellation clears warning before isolated art probe"):
		await _finish()
		return
	if not await _completed_art_pause():
		await _finish()
		return
	var target_before: float = float(_tether.get("hp"))
	var source_before: Dictionary = _source("draw").state()
	var clock_before: float = _scheduler.get_clock()
	var floor_body: StaticBody3D = _level.get("_floor_body") as StaticBody3D
	if not _expect(_garden.call("present_parent_disengagement", true) and _likeness.call("present_parent_disengagement", true) and floor_body.global_transform == floor_before and float(_tether.get("hp")) == target_before and _source("draw").state() == source_before and _scheduler.get_clock() == clock_before, "disclosed cosmetic parent flag strips only beauty and latches fade without altering floor/target/source"):
		await _finish()
		return
	var cosmetic: Dictionary = _likeness.call("presentation_state")
	var decoded: Dictionary = CosmeticExact.parse(CosmeticExact.stringify(cosmetic))
	if not _expect(decoded.get("accepted", false) and _likeness.call("presentation_error", decoded.value, true) == "" and _likeness.call("restore_presentation", decoded.value, true) and _likeness.call("presentation_state") == cosmetic, "actual paused cosmetic fade state ExactJson-roundtrips and quietly restores"):
		await _finish()
		return
	for _i: int in range(5):
		await process_frame
	if not _expect(_likeness.call("presentation_state") == cosmetic and _scheduler.get_clock() == clock_before and floor_body.global_transform == floor_before, "native paused render frames consume neither cosmetic fade nor encounter time") or not await _capture_art("stripped-paused"):
		await _finish()
		return
	_game.call("resume_lab")
	for _i: int in range(90):
		if _likeness.call("presentation_state").stage == "hidden":
			break
		if paused or _game.call("is_pause_requested"):
			if not await _completed_art_pause():
				await _finish()
				return
			_game.call("resume_lab")
			if not _expect(not paused and not _game.call("is_pause_requested"), "isolated cosmetic progression publicly resumes the completed pause"):
				await _finish()
				return
		if not await _tick():
			await _finish()
			return
	if not _expect(_likeness.call("presentation_state").stage == "hidden" and _garden.call("runtime_error") == "" and _likeness.call("runtime_error") == "" and floor_body.global_transform == floor_before and float(_tether.get("hp")) == target_before and _hero.hp == _hero_hp and _all_sources_clear(), "real unpaused cosmetic ticks retire harmless likeness while fixed floor/roots/native HP remain exact") or not await _capture_art("stripped-hidden"):
		await _finish()
		return
	await _finish()


func _completed_art_pause() -> bool:
	if not paused and not _game.call("request_pause_deferred"):
		return _expect(false, "public art pause request accepted")
	for _i: int in range(4):
		await process_frame
	return _expect(paused and not _game.call("is_pause_requested"), "art probe uses completed native pause")


func _capture_art(label: String) -> bool:
	if not await _completed_art_pause():
		return false
	var was_paused: bool = paused
	_game.call("resume_lab") # Real public UI/input resume, no visibility writes.
	await RenderingServer.frame_post_draw # Actual current HUD/world has rendered.
	paused = true # Disclosed TEST ONLY render freeze, as in root rule portraits.
	var before: Dictionary = {"unit": _observation(), "garden": _garden.call("state"), "likeness": _likeness.call("presentation_state")}
	await process_frame
	await RenderingServer.frame_post_draw
	var camera: Camera3D = _game.get("camera") as Camera3D
	var roots: Dictionary = _garden.call("native_bounds", "roots")
	var likeness: Dictionary = _likeness.call("framing_points", camera)
	var required: Array = _level.camera_framing_points()
	if not _expect(roots.error == "" and likeness.error == "", "actual native root and complete likeness quad bounds exist: " + label, str(roots.get("error")) + "; " + str(likeness.get("error"))):
		return false
	required.append_array(roots.points)
	if _likeness.call("presentation_state").stage != "hidden":
		required.append_array(likeness.points)
	var error: String = String(_game.call("camera_framing_error", required))
	if not _expect(error.is_empty(), "current shared portrait contains actual Hero/source/landing/root/likeness bounds: " + label, error):
		return false
	var pixels: Image = root.get_texture().get_image()
	var folder: String = ProjectSettings.globalize_path("res://.cinder/a3-l4-garden-art-resume-portraits")
	var same: bool = before == {"unit": _observation(), "garden": _garden.call("state"), "likeness": _likeness.call("presentation_state")}
	var ok: bool = pixels != null and pixels.get_size() == Vector2i(339, 736) and same and DirAccess.make_dir_recursive_absolute(folder) == OK and pixels.save_png(folder.path_join(label + ".png")) == OK
	if ok:
		print("ART PORTRAIT: ", folder.path_join(label + ".png"))
	paused = was_paused
	return _expect(ok, "unchanged actual339×736 garden portrait saved: " + label)


func _finish() -> void:
	await _close()
	await create_timer(0.15, true, false, true).timeout
	print("Garden art portrait: %d checks; failures: %d. Disclosed cosmetic fixture only; no production/persistence/full-level credit." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
