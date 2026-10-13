extends SceneTree
## TEST ONLY saved-story seed at A2-L1, using the actual shared player and Horsell
## scene. The five completed A1 IDs are fixture prerequisites, not evidence of
## Act 1 play/completion. This art-preview lifecycle suite never clears/exits L1
## and does not certify Ray combat, campaign transitions or human balance.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const Shell: Script = preload("res://scripts/campaign/shell.gd")
const Registry: Script = preload("res://scripts/campaign/registry.gd")
const Attempts: Script = preload("res://scripts/campaign/attempts.gd")
const Store: Script = preload("res://scripts/campaign/save_store.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"
const TEST_ROOT: String = "user://test-a2-l1-shell/"
const FIXTURE_PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5"]
var _checks: int = 0
var _failures: int = 0
var _game: CinderCampaignShell
var _canonical_registry_text: String = ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	paused = false
	_cleanup()
	_canonical_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var raw: Dictionary = JSON.parse_string(_canonical_registry_text)
	# Acceptance metadata exists only in this injected dictionary, never on disk.
	for info: Dictionary in raw["levels"]:
		if info["id"] == "A2-L1":
			info["scene_path"] = LevelPath
			info["readiness"] = "accepted"
			info["accepted_commit"] = "b".repeat(40)
			info["api_revision"] = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	_expect(registry.last_error.is_empty(), "test-only registry preserves all canonical IDs/links while injecting only Horsell's scene")
	if not await _seed_actual_scene(registry):
		_finish()
		return
	# The temporary MainScene was freed before installing the real shell.
	_game = Shell.new() as CinderCampaignShell
	_expect(_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json"), "shared shell accepts the isolated test registry/save paths")
	root.add_child(_game)
	await _settle()
	_expect(_game.campaign_error.is_empty() and paused and _game.menu.page_name() == "title" and _game.active_level == null, "semantically validated seeded story loads at the paused title without an extra live world: " + _game.campaign_error)
	_expect(_game.attempts.state()["completed_main"] == FIXTURE_PREFIX and _game.attempts.active_snapshot()["level_id"] == "A2-L1", "fixture prerequisite prefix selects uncompleted A2-L1 without inventing a completion event")
	_game.resume_campaign()
	await _settle()
	_expect(_game.campaign_error.is_empty() and _game.active_level != null and paused and _game.menu.page_name() == "resume", "public resume installs the actual seeded Horsell candidate and keeps it paused")
	if _game.active_level == null:
		_finish()
		return
	_expect(_game.active_level.level_id == "A2-L1" and _game.active_level.scene_file_path == LevelPath and _game.active_level.hero == _game.player and _game.active_level.effects == _game.fx, "actual scene owns the one shared actor/effects and exact selected level identity")
	_expect(_game.player.presentation_id == "act2_survivor" and (_game.player.get_node("ActorSprite") as LabSprite).presentation_id == "act2_survivor", "the shared player and attached runtime sprite select the exact Act 2 survivor presentation")
	_expect(_game.player.hp == 37.0 and _game.player.shells == 0 and String(_game.attempts.state_error(_game.attempts.state())).is_empty(), "shared load validation restores seeded low HP/empty ammo without healing")
	_game.resume_campaign()
	await _swipe(Vector2(0.70, 0.65), Vector2(0.64, 0.50))
	await create_timer(0.30).timeout
	var checkpoint_anchor: Vector2 = _game.get_aim_anchor_normalized()
	_expect(not paused and checkpoint_anchor.is_equal_approx(Vector2(0.64, 0.50)) and _game.player.get_world_action_records().size() == 1, "actual pointer swipe establishes its final screen-release anchor and one completed shared dash")
	_game.request_pause()
	await _settle()
	_expect(paused and _game.menu.page_name() == "pause", "public pause establishes a deferred saved boundary")
	_game.player.hp = 22.0
	_game.player.shells = 0
	var posed: Dictionary = _game.active_level.snapshot_state()
	posed["local"]["scenic_clock"] = 0.8
	posed["local"]["witness_state"] = "retreat"
	posed["local"]["eruption_visible"] = true
	_expect(_game.active_level.restore_state(posed), "fixture uses validated local restore to pose independent witnesses and harmless eruption")
	var checkpoint_pose: Dictionary = _scenery_pose(_game.active_level)
	_expect(checkpoint_pose["witnesses"].size() == 6 and checkpoint_pose["eruption"]["visible"], "paused checkpoint has concrete witness and eruption presentation to restore")
	_expect(_game.active_level.request_checkpoint("foundation-fixture", "encounter"), "authored encounter checkpoint reaches the actual shared shell consumer")
	await _settle()
	var checkpoint: Dictionary = _game.attempts.active_snapshot()
	_expect(_game.campaign_error.is_empty() and paused and checkpoint["player"]["resources"]["hp"] == 22.0 and checkpoint["player"]["resources"]["shells"] == 0 and Codec.same_values(checkpoint, _game.capture_campaign_snapshot()), "checkpoint saves the complete paused aggregate without healing or filling ammo")
	_expect(Codec.same_values(checkpoint["level"]["local"], posed["local"]) and Codec.same_values(checkpoint["shell"]["anchor_normalized"], [checkpoint_anchor.x, checkpoint_anchor.y]), "checkpoint retains scenery state and the exact final screen anchor as separate components")
	var observation_before: Dictionary = _game.get_input_observation_state()
	var actions_before: Array[Dictionary] = _game.player.get_world_action_records()
	_game.handle_tap(root.get_visible_rect().size * 0.5)
	_expect(_game.get_input_observation_state() == observation_before and _game.player.get_world_action_records() == actions_before, "menu-open combat taps neither attack nor alter input observations")
	var button: Button = _game.menu.find_child("ResumeButton", true, false) as Button
	_expect(button != null, "real paused-resume menu exposes its Resume button")
	if button == null:
		_finish()
		return
	await _click(button.get_global_rect().get_center())
	_expect(not paused and not _game.menu.is_open() and _game.get_input_observation_state() == observation_before and _game.player.get_world_action_records() == actions_before, "actual menu mouse gesture resumes and is consumed before combat/input observation")
	# Change the live fixture and save a pause; its checkpoint must remain intact.
	_game.player.hp = 3.0
	_game.player.shells = 1
	await _swipe(Vector2(0.30, 0.70), Vector2(0.45, 0.65))
	await create_timer(0.30).timeout
	_game.request_pause()
	await _settle()
	var changed: Dictionary = _game.active_level.snapshot_state()
	changed["local"]["scenic_clock"] = 0.4
	changed["local"]["witness_state"] = "absent"
	changed["local"]["eruption_visible"] = false
	_expect(_game.active_level.restore_state(changed) and _game.get_aim_anchor_normalized() != checkpoint_anchor, "live resources, scenery and release anchor can differ before retry")
	var old_level: CinderLevel = _game.active_level
	var old_player: CinderPlayer = _game.player
	var old_effects: PixelEffects = _game.fx
	var old_kit: Node = old_level.get_node("HorsellHeathKit")
	var old_floor: Node = old_level.get_node("DryGround")
	var old_scout: Node = old_level.get_node("ScoutVisual_arrival")
	_game.request_retry()
	await _settle()
	_expect(_game.campaign_error.is_empty() and paused and _game.menu.page_name() == "resume" and Codec.same_values(_game.capture_campaign_snapshot(), checkpoint), "public retry installs the exact coherent paused checkpoint aggregate: " + _game.campaign_error)
	_expect(_game.player.hp == 22.0 and _game.player.shells == 0 and _game.get_aim_anchor_normalized() == checkpoint_anchor and _game.player.presentation_id == "act2_survivor", "retry retains low HP, empty ammo, exact aim and the selected Act 2 identity")
	_expect(Codec.same_values(_scenery_pose(_game.active_level), checkpoint_pose), "retry reconstructs actual witness/eruption transforms and visibility from saved scenery state")
	_expect(not is_instance_valid(old_level) and not is_instance_valid(old_player) and not is_instance_valid(old_effects) and not is_instance_valid(old_kit) and not is_instance_valid(old_floor) and not is_instance_valid(old_scout), "candidate installation frees external references to the previous actor, level, effects and scenery subtree")
	var before_live: Dictionary = _game.capture_campaign_snapshot()
	var before_model: Dictionary = _game.attempts.state()
	var malformed: Dictionary = before_live.duplicate(true)
	malformed["level"]["local"]["scenic_clock"] = -1.0
	_expect(not _game.attempts.record_snapshot(malformed) and _game.attempts.state() == before_model and _game.capture_campaign_snapshot() == before_live, "malformed local state rejects atomically through the aggregate semantic validator")
	_expect(not _game.active_level.restore_state(malformed["level"]) and _game.capture_campaign_snapshot() == before_live, "direct local restore also rejects without changing the actual paused world")
	_expect(not _game.active_level.is_completed() and _game.attempts.state()["completed_main"] == FIXTURE_PREFIX and _game.attempts.state()["reward_ids"].is_empty(), "foundation checks introduce no L1 completion, exit, reward or route advancement")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical_registry_text, "test-only injected acceptance leaves canonical registry bytes unchanged")
	_finish()


func _seed_actual_scene(registry: CinderCampaignRegistry) -> bool:
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", LevelPath)
	root.add_child(preview)
	preview.call("resume_lab")
	for index: int in range(8):
		await physics_frame
	paused = true
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	actor.hp = 37.0
	actor.shells = 0
	var player_state: Dictionary = actor.snapshot_state()
	var level_state: Dictionary = level.snapshot_state()
	var camera: Camera3D = preview.get("camera") as Camera3D
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0.0, 18.0, 13.0)), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	var aggregate: Dictionary = {"schema_version": 1, "level_id": "A2-L1", "scene_path": LevelPath, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": level_state, "shell": shell_state}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var seed: Dictionary = model.state()
	seed["completed_main"] = FIXTURE_PREFIX.duplicate()
	seed["story"] = {"kind": "story", "level_id": "A2-L1", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var error: String = model.state_error(seed)
	_expect(not player_state.is_empty() and not level_state.is_empty() and error.is_empty(), "fixture seed uses real captured components and a canonical prerequisite prefix: " + error)
	var store: CinderSaveStore = Store.new(TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var seeded: bool = error.is_empty() and store.write_payload(seed)
	_expect(seeded, "SaveStore publishes only the isolated validated fixture seed: " + store.last_error)
	var reload_model: CinderCampaignAttempts = Attempts.new(registry, Store.new(TEST_ROOT + "campaign.json"))
	_expect(seeded and reload_model.load_saved() and Codec.same_values(reload_model.active_snapshot(), aggregate), "attempt load validator round-trips the fixture seed before actual shell semantic installation")
	var old_preview_actor: CinderPlayer = actor
	var old_preview_level: CinderLevel = level
	preview.free()
	_expect(not is_instance_valid(preview) and not is_instance_valid(old_preview_actor) and not is_instance_valid(old_preview_level), "standalone seed MainScene/player/level are freed before shell installation")
	return seeded


func _scenery_pose(level: CinderLevel) -> Dictionary:
	var kit: Node3D = level.get_node("HorsellHeathKit") as Node3D
	var witnesses: Array[Dictionary] = []
	for child: Node in kit.get_children():
		if child is Node3D and String(child.name).begins_with("NonhostileWitness_"):
			var costume: Sprite3D = child.get_node("FeetAnchoredCostume") as Sprite3D
			witnesses.append({"id": String(child.name), "position": Codec.vector3(child.position), "visible": child.visible, "pose": child.get_meta("witness_pose", "watch"), "pixel_texture": costume.texture.get_image().get_data().hex_encode().sha256_text()})
	var eruption: Node3D = kit.get_node("HarmlessDistantEruption") as Node3D
	var puffs: Array[Dictionary] = []
	for child: Node3D in eruption.get_children():
		puffs.append({"id": String(child.name), "position": Codec.vector3(child.position), "scale": Codec.vector3(child.scale)})
	return {"witnesses": witnesses, "eruption": {"visible": eruption.visible, "progress": eruption.get_meta("eruption_progress", 0.0), "puffs": puffs}}


func _swipe(from_normalized: Vector2, to_normalized: Vector2) -> void:
	var size: Vector2 = root.get_visible_rect().size
	var press := InputEventScreenTouch.new()
	press.index = 2
	press.pressed = true
	press.position = from_normalized * size
	root.push_input(press, true)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = to_normalized * size
	drag.relative = drag.position - press.position
	root.push_input(drag, true)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 2
	release.position = to_normalized * size
	root.push_input(release, true)
	await process_frame


func _click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = at
	press.global_position = at
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = at
	release.global_position = at
	root.push_input(release, true)
	await process_frame


func _settle() -> void:
	for index: int in range(4):
		await process_frame


func _finish() -> void:
	if is_instance_valid(_game):
		_game.free()
	paused = false
	_cleanup()
	print("Horsell shell foundation smoke: %d checks, %d failures; TEST ONLY seeded story/art preview" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _cleanup() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
