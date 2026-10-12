extends SceneTree
## Focused actual CampaignShell transport. TEST registry/predecessor handoffs,
## initial injured resources, public actor injuries and Hero placement are setup.
## No earned route, production registration, art/kit/balance/performance claim.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Layout = preload("res://scripts/acts/act1/selenite_court_layout.gd")
const ScenePath: String = "res://scenes/acts/act1/a1_l4.tscn"
const ScriptPath: String = "res://scripts/acts/act1/selenite_court.gd"
const LocalKeys: Array[String] = ["api_revision", "schema_version", "world_revision", "room", "formation", "awaiting_room", "roundel_demonstrated", "helpers_once", "helper_stage", "entry_records", "entry_outcomes", "actors", "scheduler", "roundel", "framing"]
const SourceIds: Array[String] = ["court-curtain-guard", "court-formation-west", "court-formation-east", "court-approach-west", "court-approach-east", "court-king", "court-helper-west", "court-helper-east"]
const WatchdogMs: int = 120000
var game: CinderCampaignShell
var fresh: CinderCampaignShell
var candidate: Dictionary = {}
var raw: Dictionary = {}
var registry_text: String = ""
var test_root: String = ""
var checks: int = 0
var failures: int = 0
var events: int = 0
var quiet_events: int = 0
var started_ms: int = 0
var finishing: bool = false
var aborted: bool = false
var old_fps: int
var old_audio: AudioBusLayout
var setups: Array[Dictionary] = []
var receipts: Array[Dictionary] = []
var first_failure: Dictionary = {}


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	test_root = "user://test-act1-court-save-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(registry_text)
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "actual registry supplies isolated TEST metadata"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for entry: Dictionary in raw.levels:
		if entry.id in ["A1-L1", "A1-L2", "A1-L3", "A1-L4"]:
			entry.scene_path = ScenePath if entry.id == "A1-L4" else "res://tests/fixtures/campaign/live_%s.tscn" % String(entry.id).to_lower().replace("-", "_")
			entry.readiness = "accepted"; entry.accepted_commit = "f".repeat(40); entry.api_revision = Registry.API_REVISION
	game = _new_shell()
	if game == null or not await _settle(): await _finish(); return
	if not _expect(paused and game.active_level == null and game.player == null and game.menu.page_name() == "title", "real isolated Title starts without an installed world") or not _press(game, "JourneyButton") or not await _settle():
		await _finish(); return
	game.menu.select_level("A1-L1")
	if not _press(game, "LevelCardAction") or not await _settle(): await _finish(); return
	# Explicit first-fixture resource setup. Later native restores must retain
	# their actual saved resources; shared passive reload is never disabled.
	if not _expect(game.active_level.level_id == "A1-L1" and paused, "actual public Begin installs disclosed generic TEST predecessor"):
		await _finish(); return
	game.player.hp = 23.0; game.player.shells = 0
	setups.append({"kind": "TEST initial predecessor resources", "hp": 23.0, "shells": 0})
	for id: String in ["A1-L1", "A1-L2", "A1-L3"]:
		if not _expect(game.active_level.level_id == id and game.active_level.scene_file_path == "res://tests/fixtures/campaign/live_%s.tscn" % id.to_lower().replace("-", "_"), "only disclosed generic predecessor is installed: " + id): await _finish(); return
		if not _expect(game.active_level.request_completion("TEST-court-entry"), "TEST predecessor public completion is setup") or not await _settle(): await _finish(); return
		if not _expect(game.active_level.request_contact_exit("TEST-court-entry-contact", game.player), "TEST predecessor public same-Hero exit is setup") or not await _settle(): await _finish(); return
	if not _expect(paused and game.active_level.scene_file_path == ScenePath and game.active_level.get_script().resource_path == ScriptPath and game.active_level.restore_candidate_construction_required(), "real Shell installs actual whole court and opts into fresh construction") or not _bindings(game): await _finish(); return
	_watch(game.active_level, game.player, false)
	var pristine: Dictionary = game.capture_campaign_snapshot()
	if not _closed(pristine) or not _expect(pristine.level.local.room == 0 and pristine.level.local.actors["court-curtain-guard"].dormant == false and pristine.level.local.actors["court-king"].dormant == true and pristine.player.resources.hp == 23.0 and pristine.player.resources.shells == 0 and pristine.level.local.scheduler.clock_s == 0.0 and pristine.level.local.scheduler.reservations.is_empty(), "pristine actual entrance retains injured carryover/zeroammo and future dormant King/helpers"):
		await _finish(); return
	var protected_wire: String = Exact.stringify(game.attempts.state().story.checkpoint)
	receipts.append({"stage": "pristine entrance", "exact_snapshot": Exact.stringify(pristine)})
	if not _expect(protected_wire == Exact.stringify(pristine) and _durable(game), "real initial protected checkpoint and format2 disk contain the whole entrance unit") or not _direct_candidate(pristine): await _finish(); return
	if not await _resume(game): await _finish(); return
	if not await _wait(func() -> bool: return _warning("court-curtain-guard"), "real initial stationary warning", 8.0): await _finish(); return
	game.player.shells = 0
	setups.append({"kind": "TEST zero shells immediately before entrance pause", "clock_s": _scheduler().get_clock()})
	if not await _pause(): await _finish(); return
	var warning: Dictionary = game.capture_campaign_snapshot()
	if not _closed(warning) or not _expect(warning.player.resources.hp == 23.0 and warning.player.resources.shells == 0 and not warning.level.local.actors["court-curtain-guard"].reservation_id.is_empty() and Exact.stringify(game.attempts.state().story.checkpoint) == protected_wire and _durable(game), "public Pause saves exact warning/HP/zeroammo without replacing earlier pristine Retry"):
		await _finish(); return
	receipts.append({"stage": "actual entrance warning", "exact_snapshot": Exact.stringify(warning), "exact_earlier_checkpoint": protected_wire})
	var frozen: Dictionary = _donor()
	await create_timer(0.08, true).timeout
	if not _expect(_donor() == frozen, "paused source/Player/native clocks/attempt/UI/effects/disk freeze exactly") or not _malformed(warning) or not _direct_candidate(warning) or not await _fresh_continue(warning): await _finish(); return
	var old_ids: Dictionary = _identities(game.active_level, game.player)
	var old_refs: Array[WeakRef] = _descendant_refs(game.world)
	game.request_retry()
	if not await _settle(): await _finish(); return
	if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == protected_wire and game.player.hp == 23.0 and game.player.shells == 0 and _identities(game.active_level, game.player) != old_ids and _all_freed(old_refs) and _durable(game), "public earlier Retry installs pristine native recipients with exact protected resources/no refill and disposes later warning world") or not _bindings(game): await _finish(); return
	if "--representative-helpers" in OS.get_cmdline_user_args():
		if not await _representative_helpers(): await _finish(); return
	await _finish()


func _new_shell() -> CinderCampaignShell:
	var shell: CinderCampaignShell = Shell.new()
	if not _expect(shell.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "real Shell uses process-isolated canonical save/settings/preference stores"):
		shell.free(); return null
	root.add_child(shell)
	return shell


func _representative_helpers() -> bool:
	# Representative state uses real native lifecycle/progression. Public TEST
	# injuries/placement replace an earned route; no phase/history/clock is seeded.
	if not await _resume(game) or not _damage("court-curtain-guard", 24.0) or not await _checkpoint("court-after-curtain"): return false
	if not await _place(Vector3(0, 0.1, -7)) or not await _wait(func() -> bool: return int(game.active_level.get("room")) == 1, "actual formation activation", 8.0): return false
	for id: String in Layout.ROOM_SOURCE_IDS[1]:
		if not _damage(id, 24.0): return false
	if not await _checkpoint("court-after-formation") or not await _place(Vector3(0, 0.1, -17)): return false
	if not await _wait(func() -> bool: return int(game.active_level.get("room")) == 2 and game.active_level.get("roundel").state().status == "running", "actual quiet roundel begins", 8.0): return false
	if not _expect(_sources()["court-approach-west"].get("dormant") and _sources()["court-approach-east"].get("dormant"), "quiet demonstration retains future guards dormant"): return false
	if not await _wait(func() -> bool: return game.active_level.get("_roundel_demonstrated") == true and not _sources()["court-approach-west"].get("dormant") and not _sources()["court-approach-east"].get("dormant"), "native complete roundel exposes actual combination", 20.0): return false
	for id: String in Layout.ROOM_SOURCE_IDS[2]:
		if not _damage(id, 24.0): return false
	if not await _checkpoint("court-after-approach") or not await _place(Vector3(0, 0.1, -26)): return false
	if not await _wait(func() -> bool: return int(game.active_level.get("room")) == 3 and game.active_level.current_checkpoint().id == "court-boss-entry", "actual broad native Area enters King epoch", 8.0) or not await _settle(): return false
	if paused and not await _resume(game): return false
	if not _damage("court-king", 40.0) or not await _wait(func() -> bool: return int(game.active_level.get("room")) == 4 and game.active_level.get("helper_stage") == "done", "actual once-only native helper entry completes", 12.0) or not await _checkpoint("court-king-phase-two"): return false
	if not _damage("court-helper-west", 5.0): return false
	game.player.shells = 0
	setups.append({"kind": "TEST zero shells immediately before representative helper pause", "clock_s": _scheduler().get_clock()})
	if not await _pause(): return false
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _closed(saved) or not _expect(saved.level.local.room == 4 and saved.level.local.helpers_once and saved.level.local.helper_stage == "done" and saved.level.local.actors["court-king"].hp == 40.0 and saved.level.local.actors["court-helper-west"].hp == 19.0 and saved.level.local.actors["court-helper-east"].hp == 24.0 and saved.player.resources.shells == 0 and saved.level.local.scheduler.encounter_id == "court-king" and not saved.level.progress.completed and _durable(game), "representative later save retains real injured helper/King, original native epoch and spent earlier actors"): return false
	receipts.append({"stage": "TEST representative King/helpers", "exact_snapshot": Exact.stringify(saved)})
	if not _direct_candidate(saved) or not await _fresh_continue(saved): return false
	var earlier: Dictionary = game.attempts.state().story.checkpoint.duplicate(true)
	var earlier_wire: String = Exact.stringify(earlier)
	receipts.append({"stage": "actual protected earlier helper checkpoint", "exact_snapshot": earlier_wire})
	var ids: Dictionary = _identities(game.active_level, game.player)
	game.request_retry()
	if not await _settle(): return false
	return _expect(paused and Exact.stringify(game.capture_campaign_snapshot()) == earlier_wire and _identities(game.active_level, game.player) != ids and game.player.snapshot_state().resources == earlier.player.resources and _durable(game), "representative Retry restores the actual earlier phase checkpoint/resources; no claimed current-state heal or fabricated checkpoint") and _bindings(game)


func _direct_candidate(saved: Dictionary) -> bool:
	var donor: Dictionary = _donor()
	candidate = game._prepare("A1-L4", saved.equipment_ids, {}, saved)
	if not _expect(not candidate.is_empty(), "canonical Shell constructs actual fresh court saved-prefix recipients"): return false
	var target: CinderLevel = candidate.level
	var player: CinderPlayer = candidate.player
	var map: Dictionary = target.get("sources")
	var before: Dictionary = _probe(target, player)
	if not _expect(target.is_restore_candidate() and not target.finish_restore_candidate() and player.global_position == Layout.SPAWN_POSITION and not target.request_checkpoint("TEST-forbidden") and not target.request_completion("TEST-forbidden"), "fresh constructor is paused/nonplayable and cannot publish progress"): return false
	for id: String in SourceIds:
		var state: Dictionary = map[id].call("pure_presentation_state")
		var native: Dictionary = _native(map[id], id)
		if not _expect(state.hp == (80.0 if id == "court-king" else 24.0) and not state.dead and state.dormant == saved.level.local.actors[id].dormant and state.cycle == 0 and state.reservation_id == "" and state.hurt_left_s == 0.0 and map[id].velocity == Vector3.ZERO and native.player == player and native.scheduler == target.get("scheduler"), "native constructor exposes only pristine entitled recipient: " + id): return false
	_watch(target, player, true)
	var quiet_before: int = quiet_events
	for id: String in ["court-curtain-guard", "court-king"]:
		var native: Dictionary = _native(map[id], id)
		var descriptor: Dictionary = {"api_revision": "act1-king-restore-recipient-construction-1" if id == "court-king" else "act1-restore-recipient-construction-1", "source_id": id, "room_id": Layout.ROOM_IDS[Layout.SOURCES[id].room], "installed_rooms": Layout.ROOM_IDS.slice(0, int(saved.level.local.room) + 1), "installed_fields": [], "configuration_sha256": Exact.stringify(native.configuration).sha256_text(), "authored_position": Codec.vector3(Layout.SOURCES[id].position)}
		if not _expect(map[id].call("construct_restore_recipient", target, descriptor) == false and _probe(target, player) == before and quiet_events == quiet_before, "duplicate or unentitled actual constructor refuses atomically: " + id): return false
		var malformed_descriptor: Dictionary = descriptor.duplicate(true)
		malformed_descriptor["unknown_entitlement"] = true
		if not _expect(map[id].call("construct_restore_recipient", target, malformed_descriptor) == false and _probe(target, player) == before and quiet_events == quiet_before, "closed actual constructor rejects extra descriptor key without native mutation: " + id): return false
	if not _expect(target.snapshot_error_with_player(saved.level, saved.player).is_empty() and _probe(target, player) == before and _donor() == donor, "complete candidate prevalidation is pure for actual recipient and donor"): return false
	if not _expect(player.restore_state(saved.player) and target.restore_state(saved.level), "quiet actual Player then whole native local commit succeeds"): return false
	var optical: String = game._candidate_presentation_error(candidate, saved.shell)
	var local: Dictionary = target.call("_capture_local_state")
	if not _expect(optical.is_empty() and Exact.stringify(player.snapshot_state()) == Exact.stringify(saved.player) and Exact.stringify(local) == Exact.stringify(saved.level.local) and quiet_events == quiet_before and target.is_restore_candidate() and _donor() == donor, "quiet native unit preserves exact HP/clocks/cues/proof/history with zero callbacks and actual candidate optics"): return false
	receipts.append({"stage": "direct actual candidate quiet restore", "room": saved.level.local.room, "exact_local": Exact.stringify(local), "quiet_callback_delta": quiet_events - quiet_before})
	var refs: Array[WeakRef] = _descendant_refs(candidate.container)
	game._dispose(candidate); candidate = {}
	return _expect(_all_freed(refs) and _donor() == donor, "canonical candidate disposal frees descendants without donor/disk changes")


func _malformed(saved: Dictionary) -> bool:
	var cases: Dictionary = {}
	var bad: Dictionary = saved.duplicate(true); bad.level.local["unknown_local"] = true; cases["unknown local root"] = bad
	bad = saved.duplicate(true); bad.level.local.actors["court-curtain-guard"].source_id = "court-king"; cases["cross-source identity"] = bad
	bad = saved.duplicate(true); bad.level.local.actors["court-king"].configuration.source_id = "foreign-king"; cases["immutable fresh King descriptor configuration"] = bad
	bad = saved.duplicate(true); bad.level.local.scheduler.clock_s += 0.125; cases["paired native clock"] = bad
	bad = saved.duplicate(true); bad.level.progress.completed = true; bad.level.progress.completion_id = "court-clear"; cases["premature court completion"] = bad
	for label: String in cases:
		var before: Dictionary = _donor()
		bad = cases[label]
		if not _expect(not game.active_level.snapshot_error_with_player(bad.level, bad.player).is_empty() and not game.active_level.restore_state(bad.level) and not game.attempts.record_snapshot(bad), label + " rejects public context/restore/durable validation"): return false
		if not _expect(_donor() == before, label + " changes no live native state/resources/UI/identity/events or disk generation"): return false
	# Use the actual canonical valid reader to clear its own rejection diagnostic,
	# never patch error/operation fields. This distinct candidate is not installed.
	candidate = game._prepare_snapshot(saved)
	if not _expect(not candidate.is_empty(), "canonical valid whole reader remains usable after malformed attempts"): return false
	game._dispose(candidate); candidate = {}
	return true


func _fresh_continue(saved: Dictionary) -> bool:
	var donor: Dictionary = _donor()
	fresh = _new_shell()
	if fresh == null: return false
	for index: int in range(8): await process_frame
	if not _expect(paused and fresh.player == null and fresh.active_level == null and fresh.menu.page_name() == "title" and fresh.campaign_error.is_empty(), "second real Shell reads format2 disk at Title with no installed Player") or not _press(fresh, "ContinueStoryButton"): return false
	for index: int in range(8): await process_frame
	if not _expect(fresh.campaign_error.is_empty() and fresh.active_level != null and paused and Exact.stringify(fresh.capture_campaign_snapshot()) == Exact.stringify(saved) and _identities(fresh.active_level, fresh.player) != _identities(game.active_level, game.player) and _durable(fresh) and _donor() == donor, "fresh disk Continue restores exact independent native unit without donor/checkpoint mutation") or not _bindings(fresh): return false
	var refs: Array[WeakRef] = _descendant_refs(fresh)
	if is_instance_valid(fresh.fx): fresh.fx.clear()
	fresh.free(); fresh = null
	return _expect(_all_freed(refs) and _donor() == donor, "fresh Continue disposal leaves no duplicate recipient or donor changes")


func _closed(saved: Dictionary) -> bool:
	return _expect(not saved.is_empty() and saved.get("level") is Dictionary and saved.level.get("local") is Dictionary and Codec.keys_error(saved.level.local, LocalKeys).is_empty() and Codec.keys_error(saved.level.local.actors, SourceIds).is_empty() and saved.level.local.api_revision == "act1-court-aggregate-1" and saved.level.local.schema_version == 1 and not Exact.stringify(saved).is_empty(), "capture is exact closed whole court/Player/Shell transport")


func _native(actor: CharacterBody3D, id: String) -> Dictionary:
	return actor.call("get_court_native_bindings") if id == "court-king" else actor.call("get_spore_native_bindings")


func _bindings(shell: CinderCampaignShell) -> bool:
	if not _expect(is_instance_valid(shell.active_level) and is_instance_valid(shell.player) and shell.active_level.hero == shell.player and shell.active_level.shared_shell == shell and _count_players(shell.world) == 1, "installed world retains exactly one actual shared Player and Shell aliases"): return false
	var map: Dictionary = shell.active_level.get("sources")
	if not _expect(Codec.keys_error(map, SourceIds).is_empty(), "whole court retains exactly the original eight source identities"): return false
	for id: String in SourceIds:
		var actor: CharacterBody3D = map[id]
		var native: Dictionary = _native(actor, id)
		if not _expect(native.get("player") == shell.player and native.get("scheduler") == shell.active_level.get("scheduler") and actor.get_parent() == shell.active_level and actor.get_world_3d() == shell.player.get_world_3d() and String(actor.call("art_binding_error")).is_empty(), "actual source aliases/world/art: " + id): return false
	return true


func _probe(target: CinderLevel, player: CinderPlayer) -> Dictionary:
	var actors: Dictionary = {}
	for id: String in SourceIds:
		var actor: CharacterBody3D = target.get("sources")[id]
		actors[id] = {"state": _portable(actor.call("pure_presentation_state")), "cue": _portable(actor.call("get_cue").state()), "transform": actor.global_transform, "velocity": actor.velocity, "visible": actor.visible, "layer": actor.collision_layer, "mask": actor.collision_mask, "disabled": actor.get_node("BodyCollision").disabled}
	var sched: CinderThreatScheduler = target.get("scheduler")
	return {"player": Exact.stringify(player.snapshot_state()), "scheduler": Exact.stringify(sched.snapshot_state(target.call("scheduler_bindings"))), "actors": actors, "roundel": _portable(target.get("roundel").state()), "ids": _identities(target, player)}


func _identities(target: CinderLevel, player: CinderPlayer) -> Dictionary:
	var result: Dictionary = {"level": target.get_instance_id(), "player": player.get_instance_id(), "scheduler": target.get("scheduler").get_instance_id(), "roundel": target.get("roundel").get_instance_id(), "actors": {}}
	for id: String in SourceIds:
		var actor: CharacterBody3D = target.get("sources")[id]
		result.actors[id] = [actor.get_instance_id(), actor.get_node("BodyCollision").get_instance_id(), actor.get_node("BodyCollision").shape.get_instance_id(), actor.call("get_art").get_instance_id(), actor.call("get_cue").get_instance_id()]
	return result


func _donor() -> Dictionary:
	var ui: Dictionary = {}
	for surface: Node in [game.menu, game.hud]:
		for node: Node in surface.find_children("*", "Control", true, false):
			var control := node as Control
			var row: Array = [control.visible, control.is_visible_in_tree()]
			if control is Label: row.append((control as Label).text)
			if control is Button: row.append((control as Button).disabled)
			ui[String(control.get_path())] = row
	return {"native": _probe(game.active_level, game.player), "snapshot": Exact.stringify(game.capture_campaign_snapshot()), "attempts": Exact.stringify(game.attempts.state()), "disk": _disk(), "ui": ui, "hud_safe_rect": game.hud.combat_safe_rect(), "camera": game.camera.global_transform, "input": game.get_input_observation_state(), "effects": _effects(game.fx), "events": events, "actions": _portable(game.player.get_world_action_records()), "paused": paused}


func _effects(fx: PixelEffects) -> Array:
	var result: Array = []
	for node: Node in fx.find_children("*", "", true, false):
		var row: Dictionary = {"id": node.get_instance_id(), "parent": node.get_parent().get_instance_id(), "class": node.get_class(), "queued": node.is_queued_for_deletion()}
		if node is Node3D: row["transform"] = (node as Node3D).transform; row["visible"] = (node as Node3D).visible
		if node is AudioStreamPlayer: row["playing"] = (node as AudioStreamPlayer).playing; row["paused"] = (node as AudioStreamPlayer).stream_paused
		result.append(row)
	return result


func _disk() -> Dictionary:
	var result: Dictionary = {}
	var dir := DirAccess.open(test_root)
	if dir != null:
		for name: String in dir.get_files(): result[name] = FileAccess.get_file_as_bytes(test_root + name)
	return result


func _durable(shell: CinderCampaignShell) -> bool:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not envelope is Dictionary or envelope.get("format_version") != 2: return false
	var decoded: Dictionary = Exact.parse(String(envelope.get("payload_json", "")))
	return decoded.get("accepted") == true and Exact.stringify(decoded.value) == Exact.stringify(shell.attempts.state())


func _watch(target: CinderLevel, player: CinderPlayer, quiet: bool) -> void:
	var one: Callable = Callable(self, "_quiet1" if quiet else "_event1")
	var two: Callable = Callable(self, "_quiet2" if quiet else "_event2")
	var three: Callable = Callable(self, "_quiet3" if quiet else "_event3")
	target.checkpoint_requested.connect(three); target.completion_requested.connect(two); target.contact_exit_requested.connect(two)
	player.world_action_executed.connect(one); player.fired.connect(one); player.action_resolved.connect(three)
	for actor: CharacterBody3D in (target.get("sources") as Dictionary).values():
		actor.connect("state_changed", one); actor.connect("defeated", one); actor.connect("hit_resolved", three)
		actor.call("get_cue").state_changed.connect(one)
	for name: String in ["BossContactCue", "ExteriorContactCue"]:
		var cue := target.get_node_or_null(name) as CinderInteractionCue
		if is_instance_valid(cue): cue.state_changed.connect(one)
	target.get("roundel").state_changed.connect(one); target.get("roundel").get_cue().state_changed.connect(one)
	target.get("scheduler").reservation_invalidated.connect(two)


func _event1(_a: Variant) -> void: events += 1
func _event2(_a: Variant, _b: Variant) -> void: events += 1
func _event3(_a: Variant, _b: Variant, _c: Variant) -> void: events += 1
func _quiet1(_a: Variant) -> void: quiet_events += 1
func _quiet2(_a: Variant, _b: Variant) -> void: quiet_events += 1
func _quiet3(_a: Variant, _b: Variant, _c: Variant) -> void: quiet_events += 1


func _resume(shell: CinderCampaignShell) -> bool:
	if not _expect(paused and shell.menu.page_name() in ["resume", "pause"], "real CampaignMenu exposes permitted Resume"): return false
	var button := shell.menu.find_child("ResumeButton", true, false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled, "native Resume button is visible and enabled"): return false
	var input: Dictionary = shell.get_input_observation_state()
	var history: Array = shell.player.get_world_action_records()
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press); await process_frame
	var release := InputEventMouseButton.new(); release.button_index = MOUSE_BUTTON_LEFT; release.position = point; release.global_position = point
	Input.parse_input_event(release); await process_frame
	return _expect(not paused and shell.get_input_observation_state() == input and shell.player.get_world_action_records() == history, "actual press/frame/release/frame Resume consumes input without action or anchor changes")


func _pause() -> bool:
	game.request_pause()
	if not await _settle(): return false
	return _expect(paused and game.menu.page_name() == "pause" and game.menu.is_open(), "public Pause drains actual native save barrier and CampaignMenu")


func _press(shell: CinderCampaignShell, name: String) -> bool:
	var button := shell.menu.find_child(name, true, false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled, "real public menu exposes " + name): return false
	button.pressed.emit() # Menu setup only; never a gameplay input action.
	return true


func _checkpoint(id: String) -> bool:
	if not await _wait(func() -> bool: return game.active_level.current_checkpoint().id == id, "actual checkpoint " + id, 8.0, true) or not await _settle(): return false
	if not _expect(game.attempts.state().story.checkpoint.level.progress.checkpoint_id == id and _durable(game), "native checkpoint drains through actual format2 store: " + id): return false
	# Shell may legitimately auto-resume an unpaused checkpoint; only resume a
	# remaining observed checkpoint Resume page, never an unexpected focus Pause.
	if paused:
		if not _expect(game.menu.page_name() == "resume", "only actual checkpoint Resume may be consumed"): return false
		return await _resume(game)
	return true


func _damage(id: String, amount: float) -> bool:
	if not _guard(): return false
	var actor: CharacterBody3D = _sources()[id]
	var before: float = actor.get("hp")
	var result: Dictionary = actor.call("take_damage", amount, Vector3.ZERO)
	setups.append({"kind": "TEST public actor injury", "id": id, "amount": amount, "before_hp": before, "after_hp": actor.get("hp"), "clock_s": _scheduler().get_clock()})
	return _expect(result.get("accepted") == true and actor.get("hp") == maxf(0.0, before - amount), "representative setup uses actual public native injury: " + id)


func _place(position: Vector3) -> bool:
	if not await _wait(func() -> bool: return game.player.get_threat_response_state().stable and game.player.velocity == Vector3.ZERO, "actual stopped Hero before TEST placement", 8.0): return false
	var before: Vector3 = game.player.global_position
	game.player.global_position = position
	setups.append({"kind": "TEST Hero placement", "from": Codec.vector3(before), "to": Codec.vector3(position), "clock_s": _scheduler().get_clock()})
	return await _wait(func() -> bool: return game.player.get_threat_response_state().stable, "actual floor settlement after TEST placement", 8.0)


func _warning(id: String) -> bool:
	var state: Dictionary = _sources()[id].call("pure_presentation_state")
	return state.phase == "warning" and not String(state.reservation_id).is_empty()


func _sources() -> Dictionary: return game.active_level.get("sources")
func _scheduler() -> CinderThreatScheduler: return game.active_level.get("scheduler")


func _settle() -> bool:
	for index: int in range(8):
		if finishing or aborted: return false
		await process_frame
	return _expect(is_instance_valid(game) and game.campaign_error.is_empty(), "canonical campaign operations settle without error: " + (game.campaign_error if is_instance_valid(game) else "Shell absent"))


func _wait(predicate: Callable, label: String, seconds: float, allow_checkpoint_pause: bool = false) -> bool:
	var end: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing and not aborted and Time.get_ticks_msec() <= end:
		if predicate.call() == true: return true
		if not is_instance_valid(game) or not is_instance_valid(game.player) or game.player.dead: return _expect(false, label + " lost actual living Player")
		if paused and not allow_checkpoint_pause: return _expect(false, label + " encountered unexpected native pause; no forced Resume")
		await process_frame
	return _expect(false, "bounded observation: " + label)


func _guard() -> bool:
	return _expect(not finishing and not aborted and not paused and is_instance_valid(game.player) and not game.player.dead, "representative setup requires actual living unpaused Player")


func _count_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_players(child)
	return count


func _descendant_refs(node: Node) -> Array[WeakRef]:
	var refs: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children(): refs.append_array(_descendant_refs(child))
	return refs


func _all_freed(refs: Array[WeakRef]) -> bool:
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return false
	return true


func _portable(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is StringName: return String(value)
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _portable(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child: Variant in value: result.append(_portable(child))
		return result
	return value


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WatchdogMs:
		_expect(false, "bounded focused whole-court Save fixture"); aborted = true; _finish.call_deferred()


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
		if first_failure.is_empty(): first_failure = {"label": label, "paused": paused, "campaign_error": game.campaign_error if is_instance_valid(game) else "Shell absent"}
	return ok


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	if is_instance_valid(game) and not candidate.is_empty(): game._dispose(candidate); candidate = {}
	if is_instance_valid(fresh):
		if is_instance_valid(fresh.fx): fresh.fx.clear()
		fresh.free(); fresh = null
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		refs = _descendant_refs(game)
		if is_instance_valid(game.fx): game.fx.clear()
		game.free(); game = null
	paused = false
	await create_timer(0.5, true).timeout
	await process_frame
	_expect(_all_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "all actual Shell/native descendants/groups retire through normal cleanup")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == registry_text, "TEST metadata never changes the production registry")
	var report: String = "res://.cinder/a1-l4-whole-save-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(report, FileAccess.WRITE)
	if file == null: _expect(false, "focused native report is writable")
	else:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "setups": setups, "receipts": receipts, "fixture_mode": "representative-helpers" if "--representative-helpers" in OS.get_cmdline_user_args() else "entrance-only", "wall_ms": Time.get_ticks_msec() - started_ms, "scope": "TEST metadata/generic predecessors/injured carryover; default is actual entrance Warning Save/format2/pristine constructors/fresh Continue/earlier Retry/quiet cleanup only. Opt-in helper state adds labelled public injuries/placement; no earned route, production registration, art/kit/balance/performance/mobile acceptance"}, "\t")); file.close()
	var dir := DirAccess.open(test_root)
	if dir != null:
		for name: String in dir.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L4 WHOLE SAVE: %d checks/%d failures; report=%s; TEST REPRESENTATIVE TRANSPORT ONLY" % [checks, failures, report])
	quit(1 if failures > 0 else 0)
