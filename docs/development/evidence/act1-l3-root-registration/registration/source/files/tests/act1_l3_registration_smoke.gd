extends "res://tests/act1_l2_registration_smoke.gd"
## Focused production-registration fixture for exact submitted A1-L3.
## Installation, native execution and original evidence are recorded by Root.
## Reuses only production Shell/Registry/format2/input/GUI helpers from L2.
## Prefix2 is TEST ONLY campaign metadata. The local packets are actual Full
## captures. Representative TEST Hero placements and public actor injuries
## exercise native transitions, not an earned route or ordinary combat clear.
## No beat/progress/entitlement/phase/clock/checkpoint/camera setter is used.

const L3_COMMIT: String = "0129e260a25405dc1e24d1869bbe607884eca430"
const L3_SCENE: String = "res://scenes/acts/act1/a1_l3.tscn"
const L3_SCRIPT: String = "res://scripts/acts/act1/mushroom_caverns_full.gd"
const L3_ACTOR: String = "res://scripts/acts/act1/mushroom_selenite.gd"
const L3_PREFIX: Array[String] = ["A1-L1", "A1-L2"]
const L3_ROOMS: Array = [
	["umbrella-1", "umbrella-2", "umbrella-3"],
	["breathing-1", "breathing-2", "breathing-3"],
	["crossed-1", "crossed-2", "crossed-3", "crossed-4", "crossed-5", "crossed-6", "crossed-7", "crossed-8"],
	["lone-guard"], ["court-1", "court-2", "court-3", "court-guard"]]
const L3_BEATS: Array[String] = ["umbrella-grove", "breathing-chamber", "crossed-grotto", "spear-pocket", "court-approach"]
const L3_THRESHOLDS: Array[float] = [13.0, 2.0, -10.0, -25.0, -38.0]
const L3_LOCAL_KEYS: Array[String] = ["authored_snapshot_version", "beat_index", "completed_beats", "room_stage", "actors", "scheduler", "fields", "consumers", "framing"]

var _l3_option_error: String = ""
var _l3_checkpoints: Array[Dictionary] = []
var _l3_completions: Array[Dictionary] = []
var _l3_contacts: Array[Dictionary] = []
var _l3_placements: Array[Dictionary] = []
var _l3_injuries: Array[Dictionary] = []
var _l3_progress_bound: Dictionary = {}


func _initialize() -> void:
	var identity: String = "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_root = "user://test-act1-l3-registration-%s/" % identity
	_capture_root = "user://test-act1-l3-registration-captures-%s/" % identity
	_expected_commit = L3_COMMIT
	var seen: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var key: String = "--expected-commit" if argument.begins_with("--expected-commit=") else argument
		if seen.has(key): _l3_option_error = "Repeated selector: " + key
		seen[key] = true
		if argument == "--portrait": graphical = true
		elif argument.begins_with("--expected-commit="): _expected_commit = argument.trim_prefix("--expected-commit=")
		else: _l3_option_error = "Unsupported selector: " + argument
	node_added.connect(_observe_restore_node)
	create_timer(600.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded L3 registration finishes within600wall seconds")
			_finish())
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(_l3_option_error.is_empty() and _expected_commit == L3_COMMIT, "exact submitted L3 commit and bounded selectors: " + _l3_option_error): _finish(); return
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	var accepted: Dictionary = registry.entry("A1-L3")
	var future: Dictionary = registry.entry("A1-L4")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == _expected_commit and accepted.get("scene_path") == L3_SCENE and accepted.get("previous_main_id") == "A1-L2" and accepted.get("api_revision") == "campaign-level-1" and registry.entry("A1-L2").get("readiness") == "accepted" and future.get("readiness") != "accepted" and future.get("scene_path") == null and registry.scene_error("A1-L3").is_empty(), "canonical registry exposes exact Full L3, accepted L2 prerequisite and unavailable L4: " + registry.last_error): _finish(); return
	game = _new_shell()
	await _settle()
	if not _title_valid("isolated first launch"): _finish(); return
	await _capture("title")
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act1Shortcut") as Control)
	await _click(_find("Node_A1_L3") as Control)
	var action: Button = _find("LevelCardAction") as Button
	var card: Label = _find("LevelCardBody") as Label
	if not _expect(game.menu.page_name() == "journey" and (_find("Node_A1_L3") as Button).get_meta("campaign_state") == "locked" and action != null and action.disabled and card != null and card.text.contains("A1-L2") and game.active_level == null and game.attempts.state().completed_main.is_empty(), "actual Journey locks L3 behind L2 without a live world or invented prefix"): _finish(); return
	_close_shell()
	if not await _seed_l3(registry): _finish(); return
	game = _new_shell()
	await _settle()
	if not _title_valid("declared TEST ONLY prefix2"): _finish(); return
	_watching_restore = true
	_restore_events.clear()
	await _click(_find("ContinueStoryButton") as Control)
	_watching_restore = false
	if not _actual_entry() or not _expect(_restore_events.is_empty(), "initial actual Full Continue has no gameplay delivery"): _finish(); return
	var entry: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not entry.is_empty() and _initial_local(entry.level) and _valid_pair(entry) and _no_progress() and _disk_state_matches(), "source-pristine actual Full entry is one exact protected native unit"): _finish(); return
	var entry_wire: String = Exact.stringify(entry)
	if not _resume_consumed("actual L3 entry"): _finish(); return
	if not await _ready_dash() or not _swipe(Vector2(.5, .76), Vector2(.5, .48)) or not await _wait_finished_dash(1): _finish(); return
	game.request_pause()
	await _settle()
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(game.campaign_error.is_empty() and paused and game.menu.page_name() == "pause" and not saved.is_empty() and _valid_pair(saved) and saved.level.local.beat_index == 0 and saved.level.local.room_stage == "active" and saved.level.local.completed_beats.is_empty() and saved.player.world_actions.sequence == 1 and saved.shell.input_sequence == 1 and not saved.level.progress.completed and saved.level.progress.checkpoint_ids.is_empty() and Exact.stringify(game.attempts.state().story.checkpoint) == entry_wire and _disk_state_matches(), "one real entrance dash saves current three-source room and protects original earlier entry: " + game.campaign_error): _finish(); return
	var saved_wire: String = Exact.stringify(saved)
	await _settle()
	if not _expect(Exact.stringify(game.capture_campaign_snapshot()) == saved_wire, "paused complete nineteen-source packet remains exact"): _finish(); return
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "saved donor cleanup")
	if not await _fresh_continue(saved_wire, "actual L3 entrance save") or not _expect(_disk_state_matches(), "fresh NULL-Player Title Continue retains exact format2 payload"): _finish(); return
	retired = _old_refs()
	if not await _quiet_retry(entry_wire, "earlier source-pristine checkpoint"): _finish(); return
	_expect_refs_freed(retired, "protected earlier Retry")
	if not _expect(_initial_local(game.capture_campaign_snapshot().level) and _no_progress() and _disk_state_matches(), "Retry restores original resources/actions/clocks and dormant19 without repair"): _finish(); return
	_bind_progress()
	for room: int in range(5):
		if not await _representative_room(room): _finish(); return
	if not await _terminal_contact(): _finish(); return
	_expect(get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "all disposed native worlds release cue/enemy groups")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "canonical registry bytes unchanged by fixture")
	_finish()


func _seed_l3(registry: CinderCampaignRegistry) -> bool:
	paused = true
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", L3_SCENE)
	root.add_child(preview)
	paused = true
	await _settle()
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(is_instance_valid(actor) and is_instance_valid(level) and is_instance_valid(camera) and level.get_script().resource_path == L3_SCRIPT and level.scene_file_path == L3_SCENE, "TEST prefix uses actual unchanged Full alias, shared Player and native camera"):
		preview.free(); return false
	var player_state: Dictionary = actor.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	var unit: Dictionary = {"schema_version": 1, "level_id": "A1-L3", "scene_path": L3_SCENE, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": local, "shell": shell_state}
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
	var model: CinderCampaignAttempts = Attempts.new(registry, store)
	var seed: Dictionary = model.state()
	seed.completed_main = L3_PREFIX.duplicate()
	seed.story = {"kind": "story", "level_id": "A1-L3", "snapshot": unit.duplicate(true), "checkpoint": unit.duplicate(true)}
	var error: String = level.snapshot_error_with_player(local, player_state) if not local.is_empty() and not player_state.is_empty() else "Actual pristine capture unavailable"
	var accepted: bool = _expect(error.is_empty() and _initial_local(local) and model.state_error(seed).is_empty() and model.restore_session(seed) and store.write_payload(model.state()), "TEST ONLY prefix2 publishes untouched actual local/resources through Attempts/format2: " + error + "; " + model.last_error + "; " + store.last_error)
	# No test HP/ammo/loadout/pose/history writes occur in this initial unit.
	level.exit_level()
	preview.free()
	return accepted


func _actual_entry() -> bool:
	if not _expect(is_instance_valid(game) and game.campaign_error.is_empty() and paused and game.menu.page_name() == "resume" and is_instance_valid(game.active_level) and is_instance_valid(game.player), "actual L3 installation waits at paused Resume: " + game.campaign_error): return false
	var level: CinderLevel = game.active_level
	var actors: Dictionary = level.get("sources")
	var spec: Dictionary = level.call("normal_route_spec")
	if not _expect(level.level_id == "A1-L3" and level.scene_file_path == L3_SCENE and level.get_script().resource_path == L3_SCRIPT and level.hero == game.player and level.effects == game.fx and game.player.presentation_id == "act1_expedition" and level.contract_error().is_empty() and actors.size() == 19 and spec.room_sources == L3_ROOMS and spec.thresholds == L3_THRESHOLDS and spec.checkpoint_ids == L3_BEATS.slice(0,4) and spec.completion_id == "mushroom-caverns-clear" and spec.exit_id == "open-court", "actual Full owns shared expedition Player/effects, nineteen retained actors and authored five-beat contract"): return false
	for room: Array in L3_ROOMS:
		for id: String in room:
			var actor: CharacterBody3D = actors.get(id) as CharacterBody3D
			if not _expect(is_instance_valid(actor) and actor.get_parent() == level and actor.get_script().resource_path == L3_ACTOR and actor.call("get_spore_native_bindings").get("player") == game.player and actor.call("get_spore_native_bindings").get("scheduler") == level.get("scheduler") and String(actor.call("body_binding_error")).is_empty() and String(actor.call("art_binding_error")).is_empty(), "retained actual native C31/C32 aliases/body/art: " + id): return false
	return _expect(String(level.call("route_snapshot_runtime_error")).is_empty(), "Full native snapshot resources and field/protocol/controller custody remain valid")


func _initial_local(snapshot: Dictionary) -> bool:
	if snapshot.is_empty() or snapshot.get("local_snapshot_version") != 1: return false
	var local: Dictionary = snapshot.get("local", {})
	var progress: Dictionary = snapshot.get("progress", {})
	if not Codec.keys_error(local, L3_LOCAL_KEYS).is_empty() or local.get("authored_snapshot_version") != 1 or local.get("beat_index") != 0 or local.get("completed_beats") != [] or local.get("room_stage") != "approach" or not local.get("actors") is Dictionary or local.actors.size() != 19 or not local.get("scheduler") is Dictionary or local.scheduler.get("clock_s") != 0.0 or not local.scheduler.get("profile", {"invalid": true}).is_empty() or not local.scheduler.get("reservations", [1]).is_empty() or not local.get("framing", {"invalid": true}).is_empty() or progress.get("completed") != false or not progress.get("checkpoint_ids", {"invalid": true}).is_empty() or progress.get("contact_exit_id") != "": return false
	for room: Array in L3_ROOMS:
		for id: String in room:
			var actor: Dictionary = local.actors.get(id, {})
			if actor.get("dormant") != true or actor.get("dead") != false or actor.get("hp") != (24.0 if id in ["lone-guard", "court-guard"] else 16.0) or actor.get("cycle") != 0 or actor.get("reservation_id") != "": return false
	for field: Variant in local.get("fields", {}).values():
		if field != null: return false
	for consumer: Variant in local.get("consumers", {}).values():
		if consumer != null: return false
	return true


func _no_progress() -> bool:
	var state: Dictionary = game.attempts.state()
	return state.completed_main == L3_PREFIX and state.completed_optional.is_empty() and state.reward_ids.is_empty() and state.side_attempt == null and not game.active_level.is_completed()


func _bind_progress() -> void:
	var level: CinderLevel = game.active_level
	if _l3_progress_bound.has(level.get_instance_id()): return
	_l3_progress_bound[level.get_instance_id()] = true
	level.checkpoint_requested.connect(func(id: String, cp: String, kind: String) -> void:
		_l3_checkpoints.append({"level_id": id, "checkpoint_id": cp, "kind": kind})
		game.request_pause()) # Public pause retains this actual full-tick boundary.
	level.completion_requested.connect(func(id: String, completion: String) -> void:
		_l3_completions.append({"level_id": id, "completion_id": completion})
		game.request_pause())
	level.contact_exit_requested.connect(func(id: String, exit_id: String) -> void:
		var area: Area3D = game.active_level.get_node_or_null("ActualOpenCourtContact") as Area3D
		_l3_contacts.append({"level_id": id, "exit_id": exit_id, "actual_overlap": is_instance_valid(area) and area.overlaps_body(game.player), "position": Codec.vector3(game.player.global_position), "player_clock_s": game.player.get_world_action_clock(), "input_sequence": game.get_input_observation_state().sequence}))


func _representative_room(room: int) -> bool:
	if paused and not _resume_consumed("representative room%d" % room): return false
	if not await _ready_dash(): return false
	var level: CinderLevel = game.active_level
	var route: Dictionary = level.call("route_state")
	if not _expect(route.beat_index == room and route.room_stage == "approach" and route.completed_beats == L3_BEATS.slice(0,room), "TEST placement begins only after true preceding native boundary%d" % room): return false
	if not _place_hero(Vector3(0, game.player.global_position.y, L3_THRESHOLDS[room] - .4), "room%d approach" % room): return false
	if not await _wait_room(room, "active"): return false
	if not await _wait_current_view("actual entitled room%d before public injury" % room): return false
	var actors: Dictionary = level.get("sources")
	if not _expect(level.call("current_source_ids") == L3_ROOMS[room], "native activation entitles only the actual current cast%d" % room): return false
	for later: int in range(room + 1,5):
		for id: String in L3_ROOMS[later]:
			if not _expect(actors[id].get("dormant") and not actors[id].get("dead") and actors[id].get("hp") == (24.0 if id in ["lone-guard", "court-guard"] else 16.0), "future actor remains untouched and dormant: " + id): return false
	for id: String in L3_ROOMS[room]:
		if room == 4 and id == "court-guard":
			# All other court actors are truly dead. Use the actual retained Area,
			# capsule and floor: stage OUTSIDE overlap before final injury. Wait for
			# actual normal follow/current containment, never assign camera focus.
			var area: Area3D = level.get_node("ActualOpenCourtContact") as Area3D
			var shape: CollisionShape3D = area.get_node("BroadCourtContact") as CollisionShape3D
			var body: CollisionShape3D = game.player.get_node("BodyCollision") as CollisionShape3D
			var front: float = area.global_position.z + (shape.shape as BoxShape3D).size.z * .5 + (body.shape as CapsuleShape3D).radius
			if not _place_hero(Vector3(area.global_position.x, game.player.global_position.y, front + 1.2), "court supported outside-contact boundary"): return false
			if not await _wait_current_view("final true living court before injury") or not _expect(not area.overlaps_body(game.player), "actual precompletion Hero remains outside physical contact Area"): return false
		if not _injure_actor(actors[id], id, room): return false
	if not await _wait_room(room + 1, "complete" if room == 4 else "approach"): return false
	await _settle()
	var unit: Dictionary = game.capture_campaign_snapshot()
	var cp_count: int = mini(room + 1,4)
	var expected: Dictionary = {}
	for index: int in range(cp_count): expected[L3_BEATS[index]] = "encounter"
	if not _expect(paused and game.campaign_error.is_empty() and not unit.is_empty() and _valid_pair(unit) and unit.level.local.completed_beats == L3_BEATS.slice(0,room + 1) and unit.level.progress.checkpoint_ids == expected and _l3_checkpoints.size() == cp_count and _l3_completions.size() == (1 if room == 4 else 0) and _l3_contacts.is_empty() and _disk_state_matches(), "native room boundary publishes exact prefix/checkpoints/completion and durable whole unit%d: " % room + game.campaign_error): return false
	for id: String in L3_ROOMS[room]:
		if not _expect(unit.level.local.actors[id].dead and unit.level.local.actors[id].hp == 0.0, "actual public injury/death retained: " + id): return false
	return true


func _place_hero(at: Vector3, label: String) -> bool:
	if not _expect(not paused and not game.player.dead and at.is_finite() and absf(at.x) < 6.0 and at.z > -53.0 and at.z < 17.0, "bounded supported-floor TEST Hero placement: " + label): return false
	# Live native getters, not the paused-only snapshot API. No await or native
	# callback lies between these reads and the one disclosed transform write.
	var before: Dictionary = game.player.get_threat_response_state()
	var actions: Array[Dictionary] = game.player.get_world_action_records()
	var hp: float = game.player.hp
	var shells: int = game.player.shells
	var basis: Basis = game.player.global_basis
	var anchor: Vector2 = game.get_aim_anchor_normalized()
	var route: Dictionary = game.active_level.call("route_state")
	var input: Dictionary = game.get_input_observation_state()
	var camera: Vector3 = game.camera.global_position
	var prior: Vector3 = game.player.global_position
	game.player.global_position = at # Disclosed TEST placement, not a gesture.
	var expected: Dictionary = before.duplicate(true)
	expected.motion.position = at
	if not _expect(game.player.get_threat_response_state() == expected and game.player.get_world_action_records() == actions and game.player.hp == hp and game.player.shells == shells and game.player.global_basis == basis and game.get_aim_anchor_normalized() == anchor and game.active_level.call("route_state") == route and game.get_input_observation_state() == input and game.camera.global_position == camera, "placement changes only actual Hero location, no native response clocks/resources/history/progress/camera: " + label): return false
	_l3_placements.append({"label": label, "from": Codec.vector3(prior), "to": Codec.vector3(at), "real_gesture": false})
	return true


func _injure_actor(actor: CharacterBody3D, id: String, room: int) -> bool:
	if not _expect(not paused and is_instance_valid(actor) and not actor.get("dead") and not actor.get("dormant") and game.active_level.call("current_source_ids").has(id), "public TEST injury requires entitled actual living actor: " + id): return false
	var hp: float = float(actor.get("hp"))
	var result: Dictionary = actor.call("take_damage", hp, Vector3.ZERO)
	_l3_injuries.append({"source_id": id, "room": room, "hp_before": hp, "accepted": result.get("accepted", false), "hp_damage": result.get("hp_damage", 0.0), "ordinary_primary": false})
	return _expect(result.get("accepted") == true and result.get("hp_damage") == hp and actor.get("dead") == true and actor.get("hp") == 0.0 and not actor.is_in_group("enemies"), "real public HP injury owns lethal native lifecycle: " + id)


func _wait_room(beat: int, stage: String) -> bool:
	for tick: int in range(240):
		if _finished or not is_instance_valid(game) or game.player.dead or not game.campaign_error.is_empty(): break
		var route: Dictionary = game.active_level.call("route_state")
		if route.beat_index == beat and route.room_stage == stage and (stage == "active" or paused): return true
		if paused: break # Unexpected pause/focus never becomes a test Resume.
		await physics_frame
		await process_frame
	return _expect(false, "native room boundary%d/%s within bounded wait: " % [beat,stage] + str(game.active_level.call("route_state")))


func _wait_current_view(label: String) -> bool:
	for tick: int in range(120):
		if _finished or paused or game.player.dead or not game.campaign_error.is_empty(): break
		var points: Array = game.active_level.camera_framing_points()
		var response: Dictionary = game.player.get_threat_response_state()
		if response.get("motion", {}).get("grounded") == true and response.get("stable") == true and not points.is_empty() and String(game.camera_framing_error(points)).is_empty(): return true
		await physics_frame
		await process_frame
	return _expect(false, "actual current native complete view/grounding required: " + label)


func _terminal_contact() -> bool:
	var terminal: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not terminal.is_empty() and terminal.level.progress.completed and terminal.level.progress.completion_id == "mushroom-caverns-clear" and terminal.level.progress.contact_exit_id == "" and terminal.level.local.beat_index == 5 and terminal.level.local.room_stage == "complete" and terminal.level.local.completed_beats == L3_BEATS and _l3_injuries.size() == 19 and _l3_placements.size() == 6 and game.attempts.state().completed_main == ["A1-L1","A1-L2","A1-L3"] and _disk_state_matches(), "representative native Full terminal persists prefix3 without inventing contact or an earned route"): return false
	await _capture("completed-before-contact")
	var area: Area3D = game.active_level.get_node("ActualOpenCourtContact") as Area3D
	var actors: Dictionary = game.active_level.get("sources")
	if not _expect(not area.overlaps_body(game.player) and not game.active_level.request_contact_exit("open-court", game.player) and not game.active_level.request_contact_exit("open-court", actors["umbrella-1"]), "completed public contact still rejects outside actual Hero and wrong actual body"): return false
	if not _resume_consumed("completed actual contact approach") or not await _ready_dash() or not _swipe(Vector2(.5,.76), Vector2(.5,.48)): return false
	for tick: int in range(120):
		if not _l3_contacts.is_empty() or paused or not game.campaign_error.is_empty(): break
		await physics_frame
		await process_frame
	await _settle()
	var contact: Dictionary = game.capture_campaign_snapshot()
	# The physical Area can pause this actual dash before publication. Pending
	# direct capture has no invented sequence1 receipt; completed history does.
	var capture: Dictionary = contact.get("player", {}).get("world_actions", {})
	var pending: Dictionary = capture.get("pending_dash", {})
	var history: Array = capture.get("history", [])
	var actual_dash: bool = (capture.get("sequence") == 0 and history.is_empty() and pending.get("kind") == "dash" and pending.get("origin") == "player_direct" and contact.get("player", {}).get("clocks", {}).get("dash_left_s", 0.0) > 0.0) or (capture.get("sequence") == 1 and pending.is_empty() and history.size() == 1 and history[0].get("kind") == "dash" and history[0].get("origin") == "player_direct" and history[0].get("sequence") == 1)
	if not _expect(paused and _l3_contacts.size() == 1 and _l3_contacts[0].actual_overlap and _l3_contacts[0].level_id == "A1-L3" and _l3_contacts[0].exit_id == "open-court" and not contact.is_empty() and _valid_pair(contact) and contact.level.progress.contact_exit_id == "open-court" and actual_dash and contact.shell.input_sequence == 1 and game.active_level.level_id == "A1-L3" and not game.campaign_error.is_empty() and not game.registry.is_playable("A1-L4") and game.registry.entry("A1-L4").scene_path == null and _disk_state_matches(), "one real pending-or-completed dash/native Area contact persists once; unavailable L4 retains paused completed L3: " + game.campaign_error): return false
	if not _expect(not game.active_level.request_contact_exit("open-court", game.player), "latched contact cannot be emitted twice"): return false
	await _capture("latched-contact-unavailable-next")
	var wire: String = Exact.stringify(contact)
	var original_contacts: Array[Dictionary] = _l3_contacts.duplicate(true)
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "completed contact donor cleanup")
	if not await _fresh_continue(wire, "latched contact with unavailable L4"): return false
	if not _expect(_restore_events.is_empty() and _l3_contacts == original_contacts and game.active_level.level_id == "A1-L3" and not game.registry.is_playable("A1-L4") and game.attempts.state().completed_main == ["A1-L1","A1-L2","A1-L3"] and _disk_state_matches(), "fresh Continue preserves original terminal/contact and emits no duplicate transition or L4 receiver"): return false
	retired = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "fresh terminal receiver cleanup")
	return true


func _observe_restore_node(node: Node) -> void:
	super._observe_restore_node(node)
	if not _watching_restore: return
	if node.get_script() != null and node.get_script().resource_path == L3_ACTOR:
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _restore_events.append("C31/C32.hit_resolved"))
		node.connect("defeated", func(_id: String) -> void: _restore_events.append("C31/C32.defeated"))
	elif node is CinderThreatScheduler:
		node.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _restore_events.append("scheduler.invalidated"))
	elif node is CinderSporeField:
		node.activated.connect(func(_domain: Dictionary) -> void: _restore_events.append("field.activated"))
	elif node is CinderSporeRepulsion:
		node.reaction_started.connect(func(_id: String, _episode: String) -> void: _restore_events.append("consumer.reaction_started"))
		node.placement_rejected.connect(func(_id: String, _reason: String) -> void: _restore_events.append("consumer.placement_rejected"))
	# Birth/immutable-config presentation is not misclassified as restore damage.
	# Whole native recapture, optical gate and original resources prove quiet state.


func _collect_refs(parent: Node, result: Array[Dictionary]) -> void:
	for child: Node in parent.get_children():
		result.append({"label": String(child.name), "ref": weakref(child)})
		_collect_refs(child,result)


func _close_shell() -> void:
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		_stop_audio(game)
		game.free()
	game = null
	paused = true


func _stop_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D: node.call("stop")
	for child: Node in node.get_children(): _stop_audio(child)


func _expect(condition: bool, message: String) -> bool:
	checks += 1
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
		if failures == 1 and is_instance_valid(game):
			print("FIRST A1-L3 REGISTRATION CONTEXT: ", {"paused": paused, "campaign_error": game.campaign_error, "menu": game.menu.page_name(), "route": game.active_level.call("route_state") if is_instance_valid(game.active_level) else {}, "player_response": game.player.get_threat_response_state() if is_instance_valid(game.player) else {}, "checkpoints": _l3_checkpoints, "completions": _l3_completions, "contacts": _l3_contacts, "test_placements": _l3_placements, "test_injuries": _l3_injuries})
	return condition


func _finish() -> void:
	if _finished: return
	_finished = true
	_close_shell()
	paused = false
	await create_timer(.2,true).timeout # Actual native audio/render disposal flush.
	_cleanup_saves()
	print("Production A1-L3 focused registration: %d checks, %d failures; expected_commit=%s. Actual Full Save/NULL-Player Continue/earlier Retry, representative native checkpoints/completion/contact/unavailable-L4/cleanup. TEST prefix2 +six Hero placements +nineteen public HP injuries; no earned route/full campaign/human/mobile/performance claim." % [checks,failures,_expected_commit])
	quit(0 if failures == 0 else 1)
