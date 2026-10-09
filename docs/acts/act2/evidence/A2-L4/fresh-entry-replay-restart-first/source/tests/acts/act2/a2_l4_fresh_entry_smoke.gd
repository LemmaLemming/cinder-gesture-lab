extends "res://tests/acts/act2/a2_l4_live_level_smoke.gd"
## TEST ONLY Shared36 fresh ordinary L4 recipient, one Standard/Standard kit.
## Synthetic completed-prefix/unlocks make the real replay UI available; the
## protected story contains a complete actually captured initial L4 checkpoint.
## No authored completion, route/HP/phase/clock/transform seed or combat credit.
## Actual public Shell GUI replay entry and restart exercise the new helper.
## Complete initial packets, native bindings/HUD/focus and whole cleanup only.
## DRAFT: native/parser/import execution belongs to the parent queue.

const FreshJson: Script = preload("res://scripts/campaign/exact_json.gd")
const FRESH_ROOT: String = "user://test-a2-l4-fresh-entry/"
const FRESH_PUBLICATION: String = "103f4f03704166d8c6066b476ec066abd086e6b6"
const FRESH_SHELL_SHA: String = "426e8190469e6efef710aba0d943ad77bc86729c58ffc81ff89656513b23948f"
const FRESH_LEVEL_SHA: String = "1989a4170b68329afd6f49c5698b23aa96722883698ccacf32f905619539010d"
var _fr_raw: Dictionary = {}
var _fr_preserved: Dictionary = {}
var _fr_events: Array[String] = []
var _fr_watch: bool = false
var _fr_hud_refs: Array[Dictionary] = []

func _run() -> void:
	_loadout_name = "standard"
	_profile_id = "standard"
	if not _read_options() or not _expect(_loadout_name == "standard" and _profile_id == "standard" and not _capture_live, "bounded fixture uses one existing Standard kit/profile and no portraits"):
		quit(1); return
	if not _expect(FileAccess.get_sha256("res://scripts/campaign/shell.gd") == FRESH_SHELL_SHA and FileAccess.get_sha256("res://scripts/campaign/level.gd") == FRESH_LEVEL_SHA, "actual loaded shared entry seam matches exact published36 " + FRESH_PUBLICATION):
		quit(1); return
	root.size = Vector2i(540, 1170)
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	for path: String in FROZEN_INPUTS + ["res://tests/acts/act2/a2_l4_live_level_smoke.gd", LONDON_SCENE, LONDON_DESTINATION]:
		_fr_preserved[path] = FileAccess.get_file_as_string(path)
	_fr_cleanup()
	node_added.connect(_fr_observe_added)
	print("L4 fresh Shell scope: published36, actual L4 completed-level replay and GUI restart; synthetic completed prefix only, real initial protected unit, one Standard kit/profile. No nine-kill route, checkpoint lifecycle, art or performance credit.")
	var prior_failures: int = _failures
	if not await _fr_check() and _failures == prior_failures: _expect(false, "bounded actual fresh L4 entry check aborted")
	_fr_watch = false
	if is_instance_valid(_game):
		var old: Array[Dictionary] = _fr_old_refs(true)
		_release_fixture_shell(_game)
		_game = null
		await _fr_settle()
		_fr_refs_freed(old, "whole Shell removal")
	if is_instance_valid(_native_probe): _native_probe.free()
	paused = false
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "whole fresh fixture leaves no native enemy/required-cue bindings")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "TEST ONLY injection preserves canonical registry bytes")
	for path: String in _fr_preserved: _expect(FileAccess.get_file_as_string(path) == _fr_preserved[path], "fixture preserves original helper/scene bytes: " + path)
	_fr_cleanup()
	print("L4 fresh Shell smoke: %d checks, %d failures; two fresh actual L4 constructors and saved protected-story return only; no combat or native-art claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _fr_check() -> bool:
	_fr_raw = JSON.parse_string(_canonical)
	for info: Dictionary in _fr_raw.levels:
		if info.id in ["A2-L4", "A2-L5"]:
			info.scene_path = LONDON_SCENE if info.id == "A2-L4" else LONDON_DESTINATION
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(_fr_raw)
	if not _expect(registry.last_error.is_empty(), "isolated accepted TEST registry retains canonical route") or not await _fr_seed(registry): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(_fr_raw, FRESH_ROOT + "campaign.json", FRESH_ROOT + "settings.json", FRESH_ROOT + "preferences.json"), "actual Shell owns only isolated fresh-entry save paths"): return false
	root.add_child(_game)
	await _fr_settle()
	if not _expect(paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "title", "actual Shell validates the complete protected unit at Title") or not await _fr_click("ContinueStoryButton"): return false
	if not _expect(_live() and paused and _game.menu.page_name() == "resume" and _game.attempts.active_kind() == "story", "real GUI Continue installs the actual initial protected L4 unit"): return false
	var protected: String = FreshJson.stringify(_game.attempts.state().story)
	var protected_unit: String = FreshJson.stringify(_game.capture_campaign_snapshot())
	if not _expect(not protected.is_empty() and not protected_unit.is_empty(), "complete protected story and actual native unit have exact nonempty transport"): return false
	var story_refs: Array[Dictionary] = _fr_old_refs()
	_fr_events.clear(); _fr_watch = true
	_game.menu.show_replay_setup("A2-L4")
	if not _expect(_game.menu.page_name() == "replay" and _game.menu.replay_loadout() == _loadout, "public completed-level setup selects the actual existing story kit") or not await _fr_click("StartReplayButton"): return false
	_fr_refs_freed(story_refs, "completed-level replay entry")
	var first: Dictionary = _fr_initial("replay entry")
	if first.is_empty(): return false
	_expect(FreshJson.stringify(_game.attempts.state().story) == protected, "fresh replay preserves the exact complete protected story and checkpoint")
	_expect(_fr_events.is_empty(), "paused fresh replay emits no observed action/damage/defeat/progression/gear events: " + str(_fr_events))
	var first_exact: String = FreshJson.stringify(first)
	var first_refs: Array[Dictionary] = _fr_old_refs()
	_game.request_pause()
	await _fr_settle()
	if not _expect(paused and _game.menu.page_name() == "pause" and _game.campaign_error.is_empty() and FreshJson.stringify(_game.capture_campaign_snapshot()) == first_exact, "public paused replay menu records the unchanged native initial unit") or not await _fr_click("RestartReplayButton"): return false
	if not _expect(_game.menu.page_name() == "replay" and _game.menu.replay_loadout() == _loadout, "actual GUI restart setup retains the same existing kit") or not await _fr_click("StartReplayButton"): return false
	_fr_refs_freed(first_refs, "GUI fresh replay restart")
	var restarted: Dictionary = _fr_initial("replay restart")
	if restarted.is_empty(): return false
	_expect(FreshJson.stringify(restarted) == first_exact, "fresh restart produces the same complete initial Player/local/focus tuple with distinct native recipients")
	_expect(FreshJson.stringify(_game.attempts.state().story) == protected and _fr_events.is_empty(), "fresh restart preserves exact protected history and emits no observed mechanical/progression event")
	var replay_refs: Array[Dictionary] = _fr_old_refs()
	_game.request_pause()
	await _fr_settle()
	if not await _fr_click("LeaveSideButton"): return false
	_fr_refs_freed(replay_refs, "saved protected-story return")
	_expect(_live() and paused and _game.attempts.active_kind() == "story" and _game.menu.page_name() == "resume" and FreshJson.stringify(_game.capture_campaign_snapshot()) == protected_unit and FreshJson.stringify(_game.attempts.state().story) == protected, "public side return quietly restores the exact original saved focus/unit without fresh fitting")
	_expect(_fr_events.is_empty(), "saved return retains the bounded action/damage/defeat/progression/gear silence")
	_fr_watch = false
	return _failures == 0

func _fr_seed(registry: CinderCampaignRegistry) -> bool:
	var preview: Node = MainScene.instantiate()
	preview.set_script(ProfileSeedGame)
	preview.set("test_profile_id", _profile_id)
	preview.set("level_scene_path", LONDON_SCENE)
	root.add_child(preview)
	paused = true
	var hero: CinderPlayer = preview.get("player") as CinderPlayer
	if not _expect(hero.equipment.restore(_loadout) and hero.equip_item(String(_loadout.weapon)) and hero.equipment.snapshot() == _loadout, "TEST ONLY initial canonical kit selection occurs before any combat"):
		preview.free(); return false
	preview.call("resume_lab")
	for frame: int in range(8): await physics_frame
	paused = true
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var actor: Dictionary = hero.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var shell: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": _profile_id}
	var unit: Dictionary = {"schema_version": 1, "level_id": "A2-L4", "scene_path": LONDON_SCENE, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": actor, "level": local, "shell": shell}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var seed: Dictionary = model.state()
	seed.completed_main = LONDON_PREFIX.duplicate()
	seed.completed_main.append("A2-L4") # TEST ONLY completion metadata enables replay.
	for id: String in _loadout.values():
		if not seed.unlocked_equipment.has(id): seed.unlocked_equipment.append(id)
	seed.story = {"kind": "story", "level_id": "A2-L4", "snapshot": unit.duplicate(true), "checkpoint": unit.duplicate(true)}
	var store: CinderSaveStore = Store.new(FRESH_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var error: String = model.state_error(seed)
	var saved: bool = not actor.is_empty() and not local.is_empty() and error.is_empty() and store.write_payload(seed)
	_expect(saved, "TEST ONLY prior completion/unlocks accompany an actually captured incomplete checkpoint: " + error + " / " + store.last_error)
	print("TEST ONLY replay-access metadata: completed_main=", seed.completed_main, "; current local remains genuinely initial, no claimed gameplay completion")
	level.exit_level()
	preview.free()
	_expect(not is_instance_valid(hero) and not is_instance_valid(level), "native seed Game/Player/level retire before actual Shell construction")
	return saved

func _fr_initial(label: String) -> Dictionary:
	if not _expect(_live() and paused and _game.menu.page_name() == "resume" and _game.attempts.active_kind() == "replay", label + " installs a paused actual L4 replay"): return {}
	var hero: CinderPlayer = _game.player
	var level: CinderLevel = _game.active_level
	var unit: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not unit.is_empty() and not FreshJson.stringify(unit).is_empty(), label + " has a complete nonempty exact aggregate: " + _game.campaign_error): return {}
	_expect(hero.snapshot_error(unit.player).is_empty() and level.snapshot_error(unit.level).is_empty() and _game.attempts.state_error(_game.attempts.state()).is_empty(), label + " passes actual Player/whole local/campaign pure validation")
	_expect(FreshJson.stringify(hero.snapshot_state()) == FreshJson.stringify(unit.player) and FreshJson.stringify(level.snapshot_state()) == FreshJson.stringify(unit.level), label + " stores the exact current authoritative Player and complete native local tuple")
	_expect(level.get_script() == LondonRoot and level.scene_file_path == LONDON_SCENE and level.hero == hero and level.effects == _game.fx and level.shared_shell == _game and hero.fx == _game.fx and level.get_world_3d() == hero.get_world_3d() and _game.world.is_ancestor_of(level) and _game.world.is_ancestor_of(hero), label + " retains original native Script/same-world Player/effects/Shell bindings")
	_expect(hero.presentation_id == "act2_survivor" and hero.equipment.snapshot() == _loadout and unit.equipment_ids == _loadout and hero.stats == _expected_stats and hero.hp == hero.max_hp and not hero.dead and hero.shells == hero.max_shells and unit.player.world_actions.sequence == 0, label + " has unchanged actual fresh resources/gear/stats/presentation and no action history")
	var local: Dictionary = unit.level.local
	_expect(local.profile_id == "standard" and unit.shell.difficulty_at_entry == "standard" and local.sequence.stage_index == 0 and local.sequence.defeated_ids.is_empty() and local.sequence.crossed_contacts.is_empty() and not unit.level.progress.completed and unit.level.progress.checkpoint_ids.is_empty(), label + " has actual initial stage/profile and no invented defeat/checkpoint/completion")
	_expect(local.targets.size() == 6 and local.rays.actors.size() == 3 and local.rays.records.size() == 3 and local.mechanisms.size() == 4 and local.banks.size() == 2 and local.scheduler.reservations.is_empty() and local.scheduler.clock_s == 0.0 and local.views.is_empty() and local.bank_views.is_empty(), label + " retains all nine targets/four tools/two banks and a pristine actual scheduler")
	var actors: Dictionary = level.get("_actors")
	_expect(actors.size() == 9, label + " binds all nine real stationary HP sources")
	for id: String in LondonSequence.ACTORS:
		var actor: Variant = actors.get(id)
		_expect(is_instance_valid(actor) and actor is Node3D and actor.is_inside_tree() and actor.get_parent() == level and actor.get("hp") == 30.0 and actor.get("max_hp") == 30.0 and actor.global_position == LondonSequence.ACTORS[id], label + " actual initial actor HP/root/custody: " + id)
	for id: String in local.mechanisms: _expect(local.mechanisms[id].status == "idle" and local.mechanisms[id].phase == "clear", label + " initial shared tool: " + id)
	for id: String in local.banks: _expect(local.banks[id].status == "idle" and local.banks[id].phase == "clear", label + " initial shared bank: " + id)
	_expect(_game.camera.global_position == Codec.read_vector3(unit.shell.camera_focus) + Vector3(0, 18, 13) and _game.camera.projection == Camera3D.PROJECTION_ORTHOGONAL and _game.camera.size == Vector2(7.2, 0.0).x, label + " installs exact fresh focus with the fixed portrait camera")
	var points: Array = level.camera_framing_points()
	var player_points: Array = _game.player_camera_framing_points()
	_expect(level.last_camera_framing_error.is_empty() and not player_points.is_empty() and _game.camera_framing_error(points if not points.is_empty() else player_points).is_empty(), label + " currently contains the actual complete Player/required native level union")
	var objective: Label = _game.hud.find_child("ObjectiveLabel", true, false) as Label
	var safe: Rect2 = _game.hud.combat_safe_rect()
	_expect(_game.hud.get_viewport().get_visible_rect().size == Vector2(540, 1170) and is_instance_valid(objective) and objective.text == level.objective_text.to_upper() and safe.size.x > 0.0 and safe.size.y > 0.0, label + " actual canonical outer HUD uses the incoming objective and a nonempty exclusion-safe rectangle")
	_expect(FreshJson.stringify(_game.attempts.state().side_attempt.snapshot) == FreshJson.stringify(unit) and FreshJson.stringify(_game.attempts.state().side_attempt.checkpoint) == FreshJson.stringify(unit), label + " commits exact fresh focus/local/Player packet before installation")
	for entry: Dictionary in _fr_hud_refs: _expect((entry.ref as WeakRef).get_ref() == null, label + " frees staging HUD " + String(entry.label))
	_expect(_fr_hud_refs.size() == 2, label + " actually traversed exactly one native fresh staging viewport/HUD pair")
	_fr_hud_refs.clear()
	return unit

func _fr_observe_added(node: Node) -> void:
	if not _fr_watch: return
	if String(node.name) in ["FreshCaptureHUDViewport", "FreshCaptureHUD"]: _fr_hud_refs.append({"label": String(node.name), "ref": weakref(node)})
	if node is CinderPlayer:
		node.fired.connect(func(_kind: String) -> void: _fr_events.append("player-fired"))
		node.died.connect(func() -> void: _fr_events.append("player-death"))
		node.equipment_changed.connect(func(_id: String) -> void: _fr_events.append("player-gear"))
		node.world_action_executed.connect(func(_record: Dictionary) -> void: _fr_events.append("player-action"))
	elif node is CinderLevel:
		node.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _fr_events.append("checkpoint"))
		node.completion_requested.connect(func(_id: String, _completion: String) -> void: _fr_events.append("completion"))
		node.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _fr_events.append("exit"))
	elif node is CinderLaneMechanism:
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _fr_events.append("tool-hit"))
	elif node.get_script() == SmokeBank:
		node.connect("tick_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _fr_events.append("bank-tick"))
	elif node.has_signal("defeated"):
		node.connect("defeated", func(_id: String) -> void: _fr_events.append("target-defeat"))
	if node.get_script() == RayExchange:
		node.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: _fr_events.append("ray-hit"))
		node.connect("scout_defeated", func(_id: String) -> void: _fr_events.append("ray-defeat"))

func _fr_old_refs(include_shell: bool = false) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	if include_shell: refs.append({"label": "CampaignShell", "ref": weakref(_game)})
	var old_container: Node = _game.world.get_parent().get_parent()
	_fr_collect_refs(old_container, refs)
	return refs

func _fr_collect_refs(node: Node, refs: Array[Dictionary]) -> void:
	refs.append({"label": String(node.get_path()), "ref": weakref(node)})
	for child: Node in node.get_children(): _fr_collect_refs(child, refs)

func _fr_refs_freed(refs: Array[Dictionary], label: String) -> void:
	for entry: Dictionary in refs: _expect((entry.ref as WeakRef).get_ref() == null, label + " retires old native node " + String(entry.label))

func _fr_click(name: String) -> bool:
	await _fr_settle()
	var button: Button = _game.menu.find_child(name, true, false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled, "actual current enabled GUI button exists: " + name): return false
	var presses: Array[String] = []
	button.pressed.connect(func() -> void: presses.append(name))
	var at: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at; motion.global_position = at
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = at; press.global_position = at; press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	await _fr_settle()
	return _expect(presses == [name] and _game.campaign_error.is_empty(), "one actual viewport GUI click settles without duplicate publication/campaign error: " + name + " " + _game.campaign_error)

func _fr_settle() -> void:
	for frame: int in range(8): await process_frame

func _fr_cleanup() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FRESH_ROOT + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FRESH_ROOT))
