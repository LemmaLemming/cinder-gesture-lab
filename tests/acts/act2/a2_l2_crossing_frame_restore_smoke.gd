extends "res://tests/acts/act2/a2_l2_retry_level_smoke.gd"
## Narrow actual Cargo/Standard crossing-response presentation regression.
## Inherits the real six-target/four-foot/four-contact route and its TEST ONLY
## preceding prefix/unlocks/destination. No live HP, pose, phase, time or progress
## is assigned. Pause only after a genuine right-foot escape leaves an obsolete
## standalone Scout landing outside the current protected portrait rectangle.
## Fresh MainScene staged preflight and real Shell restore retain the original
## source receipts; only disposable receiver visibility/cleanup is challenged.

const FRAME_FRESH_ROOT: String = "user://test-a2-l2-crossing-frame-fresh/"
var _frame_checked: bool = false
var _frame_busy: bool = false
var _frame_ok: bool = false
var _capture_crossing_only: bool = false

func _run() -> void:
	_capture_crossing_only = "--capture-crossing-only" in OS.get_cmdline_user_args()
	_loadout_name = "slow_cargo_longstep"
	if not _read_options() or not _expect(_loadout_name == "slow_cargo_longstep" and _profile_id == "standard" and not _capture_live, "crossing regression selects actual Cargo/Standard without native art claims"):
		quit(1)
		return
	if _capture_crossing_only and not _expect(DisplayServer.get_name() != "headless", "focused actual post-dash portrait requires native display"):
		quit(1)
		return
	root.size = Vector2i(540, 1170)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_l1_fixture_bytes = FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn")
	_cleanup()
	_frame_cleanup_files()
	print("Weybridge crossing frame scope: ", "actual earned prefix/post-right-dash native tuple ONLY" if _capture_crossing_only else "actual Cargo/Standard full route; right-foot pause/ExactJson/fresh saved-camera Shell restore", "; synthetic preceding prefix/unlocks and TEST ONLY L3")
	var failures_before: int = _failures
	var route_finished: bool = await _run_route()
	if not route_finished and _failures == failures_before and not (_capture_crossing_only and _frame_checked and _frame_ok): _expect(false, "actual crossing regression route aborted: " + _diagnostic())
	_expect(_frame_checked and _frame_ok, "actual affected right-foot native tuple captured" if _capture_crossing_only else "actual route exercises the affected right-foot combined response and fresh restoration")
	if is_instance_valid(_fresh): _release_fixture_receiver(_fresh)
	_fresh = null
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn") == _l1_fixture_bytes, "crossing fixture preserves canonical registry and frozen L1 destination bytes")
	_cleanup()
	_frame_cleanup_files()
	print("Weybridge crossing frame restore smoke: %d checks, %d failures; scope=%s; no human/mobile/canonical acceptance" % [_checks, _failures, "actual earned prefix and exact post-right-dash portrait ONLY; no full clear or fresh restoration" if _capture_crossing_only else "actual full route and scoped derived presentation transport"])
	quit(0 if _failures == 0 else 1)

func _step() -> void:
	await super._step()
	if _frame_checked or _frame_busy or not _live() or paused: return
	var state: Dictionary = _state()
	if state.foot_id != "foot_right": return
	var source: Dictionary = state.exchanges.crossing_scout
	var foot: Dictionary = state.mechanisms.foot_right
	if source.status != "running" or not source.get("armed", false) or source.phase == "recovery" or foot.status != "running" or not _stable(): return
	var level: CinderLevel = _game.active_level
	var camera: Camera3D = _game.camera
	var old_points: Array[Vector3] = _frame_standalone_points(level, _actors.crossing_scout, source)
	var old_failure: Dictionary = level.call("_framing_failure", camera, old_points)
	if old_failure.is_empty(): return
	if _capture_crossing_only:
		await RenderingServer.frame_post_draw
		if not _live() or paused or not _stable(): return
		state = _state()
		if state.foot_id != "foot_right": return
		source = state.exchanges.crossing_scout
		foot = state.mechanisms.foot_right
		if source.status != "running" or not source.get("armed", false) or source.phase == "recovery" or foot.status != "running": return
		old_failure = level.call("_framing_failure", camera, _frame_standalone_points(level, _actors.crossing_scout, source))
		if old_failure.is_empty(): return
		_frame_checked = true
		_frame_ok = _frame_actual_portrait(source, foot, old_failure)
		_pair_diagnostic_stop = true
		return
	_frame_busy = true
	_frame_checked = true
	_frame_ok = await _frame_pause_and_restore(source, old_failure)
	_frame_busy = false
	if not _frame_ok: _pair_diagnostic_stop = true
	if is_instance_valid(_game) and paused and _live(): _game.resume_campaign()

func _frame_standalone_points(level: CinderLevel, actor: Node3D, source: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = level.call("_required_source_points", actor)
	if source.phase != "recovery":
		points.append_array(level.call("_lane_points", source.geometry))
		var promise: Dictionary = source.get("proof", {})
		if not promise.get("landing") is Vector3: promise = source.get("presentation_witness", {})
		for key: String in ["landing", "attack_position"]:
			if promise.get(key) is Vector3: points.append_array(level.call("_landing_points", promise[key]))
	return points

func _frame_pause_and_restore(source: Dictionary, old_failure: Dictionary) -> bool:
	var failures_before: int = _failures
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	var driver: Node = level.get_node("ReusedRayExchanges")
	var native_before: String = ExactJson.stringify(driver.call("state", "crossing_scout"))
	_game.request_pause()
	await _settle()
	var saved: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(paused and not saved.is_empty() and _game.campaign_error.is_empty(), "public crossing pause captures the actual whole aggregate: " + _game.campaign_error): return false
	var local: Dictionary = saved.level.local
	_expect(local.sequence.completed_feet == ["foot_demo", "foot_apron", "foot_left"] and local.sequence.defeated_ids == ["village_scout", "yard_handler", "apron_handler"] and local.sequence.crossed_contacts == ["yard_exit", "before_crossing"] and local.sequence.foot_id == "foot_right", "affected tuple follows three real HP defeats/feet and two real contact checkpoints")
	_expect(local.mechanisms.foot_right.status == "running" and local.rays.records.crossing_scout.status == "running" and local.rays.records.crossing_scout.exchange.adapter.locked and local.views.foot_right.target_id == "crossing_scout" and local.views.foot_right.equipment_ids == _loadout, "actual current right-foot response holds living armed Scout custody with unchanged admission gear")
	_expect(not old_failure.is_empty() and bool(level.call("_exchange_framed", _actors.crossing_scout, source)), "actual combined source/foot/landing remains protected while obsolete standalone alternative is genuinely clipped")
	print("Actual crossing superseded standalone framing witness: ", old_failure, " hero=", hero.global_position, " combined_view=", local.views.foot_right)
	var frozen: String = ExactJson.stringify(saved)
	var events: Array[String] = []
	_retry_observe(level, hero, events)
	_expect(hero.snapshot_error(saved.player).is_empty() and level.snapshot_error_with_player(saved.level, saved.player).is_empty(), "complete pure saved-player preflight accepts actual combined crossing")
	await _settle()
	_expect(ExactJson.stringify(_game.capture_campaign_snapshot()) == frozen and events.is_empty(), "paused frames and pure validation preserve exact aggregate/resources/source events")
	var decoded: Dictionary = ExactJson.parse(frozen)
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary and ExactJson.stringify(decoded.get("value")) == frozen, "ExactJson transports actual complete crossing scalar bits/types"): return false
	var transported: Dictionary = decoded.value
	var forged: Dictionary = transported.duplicate(true)
	forged.level.local.views.foot_right.reservation_id = "threat-0"
	var model_before: String = ExactJson.stringify(_game.attempts.state())
	_expect(not level.snapshot_error_with_player(forged.level, forged.player).is_empty() and not level.restore_state(forged.level) and not _game.attempts.record_snapshot(forged), "stale combined-view native lease rejects before component/model mutation")
	_expect(ExactJson.stringify(_game.capture_campaign_snapshot()) == frozen and ExactJson.stringify(_game.attempts.state()) == model_before and events.is_empty(), "rejected combined-view transport is atomic and quiet")
	if not _retry_fresh_preflight(transported): return false
	if not await _frame_fresh_shell(transported): return false
	_expect(ExactJson.stringify(_game.capture_campaign_snapshot()) == frozen and ExactJson.stringify(driver.call("state", "crossing_scout")) == native_before and events.is_empty(), "fresh tests change no original aggregate, native standalone proof, witness, clock or callback")
	return _failures == failures_before

func _frame_fresh_shell(saved: Dictionary) -> bool:
	var failures_before: int = _failures
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L2", "A2-L3"]:
			info.scene_path = LevelPath if info.id == "A2-L2" else NextPath
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	var model: CinderCampaignAttempts = Attempts.new(registry)
	# Copy only the actually earned model; keep its real protected checkpoint.
	var earned: Dictionary = _game.attempts.state().duplicate(true)
	earned.story.snapshot = saved.duplicate(true)
	var store: CinderSaveStore = Store.new(FRAME_FRESH_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(earned).is_empty() and store.write_payload(earned), "fresh TEST ONLY store copies actual earned crossing snapshot/checkpoint: " + store.last_error): return false
	var fresh: CinderCampaignShell = Shell.new() as CinderCampaignShell
	_fresh = fresh
	if not _expect(fresh.configure_runtime(raw, FRAME_FRESH_ROOT + "campaign.json", FRAME_FRESH_ROOT + "settings.json", FRAME_FRESH_ROOT + "preferences.json"), "fresh real Shell uses independent test-only paths"): return false
	root.add_child(fresh)
	await _settle()
	fresh.resume_campaign()
	await _settle()
	if not _expect(paused and fresh.campaign_error.is_empty() and is_instance_valid(fresh.active_level) and ExactJson.stringify(fresh.capture_campaign_snapshot()) == ExactJson.stringify(saved), "fresh Shell quietly restores full exact player/level/input/camera aggregate: " + fresh.campaign_error): return false
	var level: CinderLevel = fresh.active_level
	var hero: CinderPlayer = fresh.player
	var actor: Node3D = level.get("_actors").crossing_scout
	var driver: Node = level.get_node("ReusedRayExchanges")
	var source: Dictionary = driver.call("state", "crossing_scout")
	var receipt_before: String = ExactJson.stringify(source)
	var events: Array[String] = []
	_retry_observe(level, hero, events)
	var old_failure: Dictionary = level.call("_framing_failure", fresh.camera, _frame_standalone_points(level, actor, source))
	_expect(source.proof.is_empty() and not source.proof_available and not old_failure.is_empty() and bool(level.call("_exchange_framed", actor, source)), "derived combined framing survives exact fresh camera restore without regenerating proof or requiring clipped standalone promise")
	var foot: Node3D = level.get("_mechanisms").foot_right
	var foot_visual: Node3D = level.get_node("OneVisibleGiantFoot")
	actor.hide()
	_expect(not bool(level.call("_exchange_framed", actor, source)), "fresh receiver guard refuses an actually hidden Scout source")
	actor.show()
	foot_visual.hide()
	_expect(not bool(level.call("_exchange_framed", actor, source)), "fresh receiver guard refuses the actually hidden current foot source")
	foot_visual.show()
	foot.hide()
	_expect(not bool(level.call("_exchange_framed", actor, source)), "fresh receiver guard refuses a hidden native foot owner instead of bypassing source custody")
	foot.show()
	_expect(bool(level.call("_exchange_framed", actor, source)) and ExactJson.stringify(driver.call("state", "crossing_scout")) == receipt_before and ExactJson.stringify(fresh.capture_campaign_snapshot()) == ExactJson.stringify(saved) and events.is_empty(), "restored visibility recovers actual guard while native receipts, resources and events remain untouched")
	var old_refs: Array[WeakRef] = [weakref(level), weakref(hero), weakref(actor), weakref(foot), weakref(foot_visual), weakref(driver)]
	_release_fixture_shell(fresh)
	_fresh = null
	for ref: WeakRef in old_refs: _expect(ref.get_ref() == null, "fresh actual crossing receiver releases player/source/foot/driver resources")
	return _failures == failures_before

func _frame_cleanup_files() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FRAME_FRESH_ROOT + name))

func _frame_actual_portrait(source: Dictionary, foot: Dictionary, old_failure: Dictionary) -> bool:
	var failures_before: int = _failures
	if not _expect(old_failure.get("reason") == "required_source_footprint_or_landing_offscreen", "focused capture has actual structured offscreen witness"): return false
	var foot_lease: Dictionary = _reservation(String(foot.reservation_id))
	if not _expect(_live() and not paused and not foot_lease.is_empty() and foot_lease.get("armed", false), "focused capture retains actual live armed foot lease after query"): return false
	var current: Dictionary = _state()
	if not _expect(current.foot_id == "foot_right" and current.mechanisms.foot_right.reservation_id == foot.reservation_id and current.exchanges.crossing_scout.reservation_id == source.reservation_id, "focused capture query retains the exact native source/foot tuple"): return false
	var directory: String = "res://captures/act2/crossing-tuple/"
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) == OK, "create separate actual crossing-tuple portrait directory"): return false
	var image: Image = root.get_texture().get_image()
	var path: String = directory + "a2-l2-cargo-post-right-dash.png"
	if not _expect(image.get_size() == Vector2i(540, 1170) and image.save_png(path) == OK, "save exact actual native post-right-dash portrait"): return false
	var level: CinderLevel = _game.active_level
	var view: Dictionary = level.get("_views").foot_right.duplicate(true)
	var landing := Vector3(view.landing[0], view.landing[1], view.landing[2])
	_expect(_game.player.global_position.distance_to(landing) < 0.00001 and bool(level.call("_exchange_framed", _actors.crossing_scout, source)), "actual completed right-foot escape matches accepted landing and combined guard remains valid")
	var screen: Vector2 = old_failure.screen
	var safe: Rect2 = old_failure.safe_rect
	var metadata: Dictionary = {"scope": "actual earned three defeats/three feet/two contacts then genuine right-foot dash; native exact clipped obsolete standalone tuple only, no full clear/fresh restore/human/mobile acceptance", "image": path, "clock_s": _state().clock_s, "hero_position": Codec.vector3(_game.player.global_position), "hero_hp": _game.player.hp, "shells": _game.player.shells, "combined_view": view, "source": {"status": source.status, "phase": source.phase, "armed": source.armed, "reservation_id": source.reservation_id, "geometry": _geometry_json(source.geometry), "source_position": Codec.vector3(_actors.crossing_scout.global_position), "hp": _actors.crossing_scout.get("hp")}, "foot": {"status": foot.status, "phase": foot.phase, "armed": foot_lease.get("armed", false), "reservation_id": foot.reservation_id, "geometry": _geometry_json(foot.geometry)}, "old_standalone_failure": {"reason": old_failure.reason, "point": Codec.vector3(old_failure.point), "screen": [screen.x, screen.y], "safe_rect": [safe.position.x, safe.position.y, safe.size.x, safe.size.y]}}
	var file: FileAccess = FileAccess.open(directory + "a2-l2-cargo-post-right-dash-evidence.json", FileAccess.WRITE)
	if not _expect(file != null, "write exact actual post-dash portrait observations"): return false
	file.store_string(JSON.stringify(metadata, "\t", true, true))
	print("Actual focused crossing tuple portrait: ", path, " observation=", metadata)
	return _failures == failures_before
