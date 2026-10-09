class_name CinderCampaignShell
extends "res://scripts/game.gd"
## Desktop consumer over the existing portrait view, controller and recognizer.
## Every durable operation runs at a deferred paused barrier. Scene candidates
## have their own World3D and are fully validated before the live world changes.

const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Settings = preload("res://scripts/settings/game_settings.gd")
const Menu = preload("res://scripts/ui/campaign_menu.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const SHELL_API: String = "campaign-shell-1"

var registry: CinderCampaignRegistry
var attempts: CinderCampaignAttempts
var settings: CinderGameSettings
var menu: CinderCampaignMenu
var campaign_error: String = ""
var _save_path: String = "user://cinder/campaign.json"
var _settings_path: String = "user://cinder/settings.json"
var _preferences_path: String = "user://cinder/preferences.json"
var _preferences_store: CinderSaveStore
var _difficulty_preference: String = "standard"
var _difficulty_at_entry: String = "standard"
var _preview_mode: bool = false
var _operations: Array[Dictionary] = []
var _draining: bool = false
var _drain_queued: bool = false
var _validation_candidates: Dictionary = {}
var _failed_operations: Array[Dictionary] = []
var _old_auto_quit: bool = true
var _resume_after_drain: bool = false

## Test harnesses may inject accepted fixture metadata and isolated user paths
## before entering the tree. This never edits the canonical campaign registry.
func configure_runtime(raw_registry: Dictionary = {}, save_path: String = "user://cinder/campaign.json", settings_path: String = "user://cinder/settings.json", preferences_path: String = "user://cinder/preferences.json") -> bool:
	if is_inside_tree():
		return false
	registry = Registry.new(raw_registry)
	if not registry.last_error.is_empty():
		campaign_error = registry.last_error
		return false
	_save_path = save_path
	_settings_path = settings_path
	_preferences_path = preferences_path
	return true

func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument == "--capture" or argument == "--capture-polish":
			_preview_mode = true
	if _preview_mode:
		super._ready()
		return
	_build_view()
	if registry == null:
		registry = Registry.new()
	settings = Settings.new(_settings_path)
	settings.load_settings()
	settings.apply_runtime()
	_apply_cosmetic_policy()
	_preferences_store = Store.new(_preferences_path)
	_preferences_store.payload_validator = _preferences_error
	var preferences: Dictionary = _preferences_store.read_payload()
	if _preferences_error(preferences).is_empty():
		_difficulty_preference = preferences.profile_id
	attempts = Attempts.new(registry, Store.new(_save_path))
	attempts.snapshot_validator = _snapshot_problem
	hud = HUDScript.new()
	add_child(hud)
	hud.set_campaign_mode()
	hud.hide_overlay()
	hud.restart_requested.connect(request_retry)
	hud.bench_requested.connect(request_pause)
	hud.start_requested.connect(resume_campaign)
	hud.visible = false
	menu = Menu.new()
	menu.configure(registry, attempts, settings)
	add_child(menu)
	menu.set_difficulty_preference(_difficulty_preference)
	menu.begin_story_requested.connect(func() -> void: _enqueue("begin"))
	menu.continue_story_requested.connect(func() -> void: _enqueue("continue"))
	menu.optional_requested.connect(func(id: String) -> void: _enqueue("side", {"kind": "optional", "level_id": id}))
	menu.replay_requested.connect(func(id: String, loadout: Dictionary) -> void: _enqueue("side", {"kind": "replay", "level_id": id, "loadout": loadout.duplicate(true)}))
	menu.restart_replay_requested.connect(func(id: String, loadout: Dictionary) -> void: _enqueue("restart_replay", {"level_id": id, "loadout": loadout.duplicate(true)}))
	menu.resume_requested.connect(resume_campaign)
	menu.retry_requested.connect(request_retry)
	menu.leave_side_requested.connect(func() -> void: _enqueue("leave_side"))
	menu.journey_requested.connect(func() -> void: _enqueue("journey"))
	menu.settings_changed_request.connect(_settings_requested)
	menu.difficulty_preference_requested.connect(_difficulty_requested)
	menu.retry_failed_operation_requested.connect(retry_pending_operations)
	get_tree().paused = true
	_old_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	if FileAccess.file_exists(_save_path) or FileAccess.file_exists(_save_path + ".bak"):
		if not attempts.load_saved():
			campaign_error = attempts.last_error
		else:
			campaign_error = attempts.last_warning
	_dispose_validation_candidates()
	menu.show_title()
	if not campaign_error.is_empty():
		menu.show_error(campaign_error)

func get_difficulty_preference() -> String:
	return _difficulty_preference

func request_pause() -> void:
	if _preview_mode:
		super.open_bench()
	else:
		_enqueue("pause")

func _pause_at_barrier() -> void:
	request_pause()

func request_retry() -> void:
	if _preview_mode:
		super.reset_lab()
	else:
		_enqueue("retry")

func reset_lab() -> void:
	if _preview_mode:
		super.reset_lab()
	else:
		request_retry()

func resume_lab() -> void:
	if _preview_mode:
		super.resume_lab()
	else:
		resume_campaign()

func resume_campaign() -> void:
	if _preview_mode:
		super.resume_lab()
		return
	if _pause_request_pending or _draining or _drain_queued or not _failed_operations.is_empty():
		return
	if not is_instance_valid(active_level):
		_enqueue("load_active")
		return
	if not is_instance_valid(player) or player.dead:
		menu.show_pause()
		menu.show_error("Retry your saved checkpoint.")
		return
	_clear_gesture_chain()
	hud.hide_overlay()
	hud.visible = true
	menu.hide_menu()
	get_viewport().set_input_as_handled()
	get_tree().paused = false

func _enqueue(kind: String, data: Dictionary = {}) -> void:
	if _preview_mode:
		return
	if kind == "retry" or kind == "leave_side":
		_failed_operations.clear()
	elif not _failed_operations.is_empty():
		# Navigation/focus events cannot replace a failed completion or transition.
		# An explicit checkpoint retry/side abandonment is the supported discard.
		get_tree().paused = true
		_clear_gesture_chain()
		if kind == "quit":
			if not _failed_operations.any(func(value: Dictionary) -> bool: return value.operation == "quit"):
				_failed_operations.append({"operation": "quit", "resume_after": false})
			retry_pending_operations.call_deferred()
		else:
			menu.show_pause() if is_instance_valid(active_level) else menu.show_title()
			menu.show_commit_error(campaign_error)
		return
	data = data.duplicate(true)
	data["operation"] = kind
	data["resume_after"] = not get_tree().paused and ["checkpoint", "complete"].has(kind)
	_operations.append(data)
	if not Engine.is_in_physics_frame():
		get_tree().paused = true
	_clear_gesture_chain()
	if not _drain_queued and not _draining:
		_drain_queued = true
		_drain.call_deferred()

func _drain() -> void:
	_drain_queued = false
	if _draining or not is_instance_valid(menu):
		return
	_draining = true
	get_tree().paused = true
	_clear_gesture_chain()
	# Pause notifications may queue quiet settlement of the final native tick.
	# Commit after those callbacks, with input and simulation still latched.
	_commit_drain.call_deferred()

func _commit_drain() -> void:
	if not _draining or not is_instance_valid(menu):
		return
	campaign_error = ""
	while not _operations.is_empty():
		var operation: Dictionary = _operations.pop_front()
		if not _perform(operation):
			_failed_operations = [operation]
			_failed_operations.append_array(_operations)
			_operations.clear()
			menu.show_pause() if is_instance_valid(active_level) else menu.show_title()
			menu.show_commit_error(campaign_error)
			break
	_dispose_validation_candidates()
	_draining = false
	if _failed_operations.is_empty() and _resume_after_drain:
		resume_campaign.call_deferred()

func retry_pending_operations() -> void:
	if _failed_operations.is_empty() or _draining or _drain_queued:
		return
	_operations.append_array(_failed_operations)
	_failed_operations.clear()
	get_tree().paused = true
	_clear_gesture_chain()
	_drain_queued = true
	_drain.call_deferred()

func _perform(operation: Dictionary) -> bool:
	_resume_after_drain = operation.get("resume_after", false)
	match operation.operation:
		"begin":
			var candidate: Dictionary = _prepare("A1-L1", Equipment.STARTER)
			if candidate.is_empty():
				return false
			var snapshot: Dictionary = _capture(candidate.player, candidate.level, _fresh_shell_state())
			if snapshot.is_empty() or not attempts.begin_story(snapshot):
				_dispose(candidate)
				return _fail(attempts.last_error if not attempts.last_error.is_empty() else campaign_error)
			_install(candidate, snapshot.shell)
			menu.show_resume("story")
		"continue":
			if attempts.state().side_attempt != null:
				return _leave_side()
			return _load_active()
		"load_active":
			return _load_active()
		"pause", "journey":
			if is_instance_valid(active_level) and not _record_live(false):
				return false
			menu.show_journey() if operation.operation == "journey" else menu.show_pause()
		"checkpoint":
			# A request can precede actual death later in the same native tick.
			# Persist that fatal active unit, retaining the last living Retry unit.
			var living: bool = is_instance_valid(player) and not player.dead
			if operation.level_id != active_level.level_id or not _record_live(living):
				return false
			if living:
				menu.show_resume(attempts.active_kind())
			else:
				_resume_after_drain = false
				menu.show_pause()
		"complete":
			var snapshot: Dictionary = capture_campaign_snapshot()
			if operation.level_id != active_level.level_id or snapshot.is_empty() or not attempts.complete_active(snapshot):
				return _fail(attempts.last_error)
			# Completion records progress. Contact exit remains an authored event.
			menu.show_resume(attempts.active_kind())
		"exit":
			if operation.level_id != active_level.level_id or not _record_live(false):
				return false
			if attempts.state().side_attempt != null:
				return _leave_side()
			var next_id: String = registry.next_main(active_level.level_id)
			if next_id.is_empty():
				menu.show_journey()
				return true
			var candidate: Dictionary = _prepare(next_id, player.equipment.snapshot(), {"hp": player.hp, "shells": player.shells, "reload_s": player.snapshot_state().clocks.reload_s})
			if candidate.is_empty():
				return false
			var state: Dictionary = _fresh_shell_state()
			state.anchor_normalized = [_swipe_end_normalized.x, _swipe_end_normalized.y]
			var snapshot: Dictionary = _capture(candidate.player, candidate.level, state)
			if snapshot.is_empty() or not attempts.advance_story(snapshot):
				_dispose(candidate)
				return _fail(attempts.last_error)
			_install(candidate, snapshot.shell)
			menu.show_resume("story")
		"retry":
			var active: Variant = attempts.state().story if attempts.state().side_attempt == null else attempts.state().side_attempt
			if active == null:
				return _fail("No checkpoint to retry")
			var candidate: Dictionary = _prepare_snapshot(active.checkpoint)
			if candidate.is_empty():
				return false
			if attempts.retry_snapshot().is_empty():
				_dispose(candidate)
				return _fail(attempts.last_error)
			_install(candidate, active.checkpoint.shell)
			menu.show_resume(attempts.active_kind())
		"side":
			if not is_instance_valid(active_level) and not _load_active():
				return false
			if not _record_live(false):
				return false
			var loadout: Dictionary = operation.get("loadout", player.equipment.snapshot())
			var candidate: Dictionary = _prepare(operation.level_id, loadout)
			if candidate.is_empty():
				return false
			var snapshot: Dictionary = _capture(candidate.player, candidate.level, _fresh_shell_state())
			if snapshot.is_empty() or not attempts.begin_side(operation.kind, operation.level_id, snapshot):
				_dispose(candidate)
				return _fail(attempts.last_error)
			_install(candidate, snapshot.shell)
			menu.show_resume(operation.kind)
		"leave_side":
			return _leave_side()
		"restart_replay":
			var candidate: Dictionary = _prepare(operation.level_id, operation.loadout)
			if candidate.is_empty():
				return false
			var snapshot: Dictionary = _capture(candidate.player, candidate.level, _fresh_shell_state())
			if snapshot.is_empty() or not attempts.restart_replay(snapshot):
				_dispose(candidate)
				return _fail(attempts.last_error)
			_install(candidate, snapshot.shell)
			menu.show_resume("replay")
		"quit":
			if is_instance_valid(active_level) and not _record_live(false):
				return false
			get_tree().quit()
	return true

func _load_active() -> bool:
	var snapshot: Dictionary = attempts.active_snapshot()
	if snapshot.is_empty():
		return _fail("Begin the story first.")
	var candidate: Dictionary = _prepare_snapshot(snapshot)
	if candidate.is_empty():
		return false
	_install(candidate, snapshot.shell)
	# A latched authored exit may have awaited an unavailable accepted scene or
	# a disk retry. Continue is the explicit consumer; never require a duplicate
	# contact event that the restored level correctly suppresses.
	if not String(snapshot.level.progress.get("contact_exit_id", "")).is_empty():
		if attempts.state().side_attempt != null:
			return _leave_side()
		var next_id: String = registry.next_main(snapshot.level_id)
		if next_id.is_empty() or registry.is_playable(next_id):
			return _perform({"operation": "exit", "level_id": snapshot.level_id})
	menu.show_resume(attempts.active_kind())
	return true

func _leave_side() -> bool:
	var preserved: Dictionary = attempts.story_snapshot()
	var candidate: Dictionary = _prepare_snapshot(preserved)
	if candidate.is_empty():
		return false
	if attempts.leave_side().is_empty():
		_dispose(candidate)
		return _fail(attempts.last_error)
	_install(candidate, preserved.shell)
	if _story_exit_complete():
		menu.show_journey()
	else:
		menu.show_resume("story")
	menu.show_notice("Story equipment restored.")
	return true

func _story_exit_complete() -> bool:
	var saved: Dictionary = attempts.story_snapshot()
	return attempts.state().completed_main.size() == registry.main_route().size() and not String(saved.get("level", {}).get("progress", {}).get("contact_exit_id", "")).is_empty()

func _record_live(checkpoint: bool) -> bool:
	var snapshot: Dictionary = capture_campaign_snapshot()
	if snapshot.is_empty():
		return false
	return attempts.record_snapshot(snapshot, checkpoint) or _fail(attempts.last_error)

func capture_campaign_snapshot() -> Dictionary:
	if not get_tree().paused or not is_instance_valid(active_level) or not is_instance_valid(player):
		_fail("Capture requires an active level at a paused deferred boundary")
		return {}
	return _capture(player, active_level, _shell_state())

func _capture(actor: CinderPlayer, level: CinderLevel, shell_state: Dictionary) -> Dictionary:
	var player_state: Dictionary = actor.snapshot_state()
	var local_state: Dictionary = level.snapshot_state()
	if player_state.is_empty() or local_state.is_empty():
		_fail(actor.last_snapshot_error if player_state.is_empty() else level.last_snapshot_error)
		return {}
	if Codec.read_vector3(shell_state.camera_focus).is_zero_approx():
		shell_state.camera_focus = Codec.vector3(actor.global_position + Vector3.UP * 0.75)
	return {"schema_version": 1, "level_id": level.level_id, "scene_path": level.scene_file_path, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": local_state, "shell": shell_state}

func _prepare(id: String, loadout: Dictionary, carried_resources: Dictionary = {}, restore_snapshot: Dictionary = {}) -> Dictionary:
	if not restore_snapshot.is_empty() and (not get_tree().paused or not carried_resources.is_empty() or not restore_snapshot.get("level") is Dictionary or not restore_snapshot.get("player") is Dictionary):
		_fail("Restore candidate construction requires paused whole saved units and no carried-resource seed")
		return {}
	campaign_error = registry.scene_error(id)
	if not campaign_error.is_empty():
		return {}
	# Keep the accepted candidate in its original tree/world. Reparenting a
	# ready level invokes _exit_tree and correctly destroys its entered lifecycle.
	# Instead reveal its already-owned portrait container only after commit.
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = 2
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.visible = false
	add_child(container)
	var viewport := SubViewport.new()
	viewport.name = "PreparedCampaignWorld"
	viewport.own_world_3d = true
	viewport.size = Vector2i(270, 585)
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	for child: Node in world.get_children():
		if child is WorldEnvironment or child is DirectionalLight3D:
			stage.add_child(child.duplicate())
	var stage_camera := Camera3D.new()
	stage_camera.projection = camera.projection
	stage_camera.keep_aspect = camera.keep_aspect
	stage_camera.size = camera.size
	stage_camera.transform = camera.transform
	stage.add_child(stage_camera)
	stage_camera.current = true
	var level: CinderLevel = (load(registry.entry(id).scene_path) as PackedScene).instantiate() as CinderLevel
	stage.add_child(level)
	var staged_fx: PixelEffects = EffectsScript.new()
	stage.add_child(staged_fx)
	if staged_fx.has_method("configure_policy"):
		staged_fx.configure_policy(settings.cosmetic_policy())
	var actor: CinderPlayer = PlayerScene.instantiate()
	actor.set_presentation(LabSprite.presentation_for_act(int(id.substr(1, 1))))
	if not actor.equipment.restore(loadout):
		container.free()
		_fail("Fresh actor loadout is unavailable or mismatched")
		return {}
	actor.fx = staged_fx
	stage.add_child(actor)
	actor.global_position = level.spawn_position()
	actor.hp = actor.max_hp
	actor.shells = actor.max_shells
	var candidate: Dictionary = {"container": container, "viewport": viewport, "stage": stage, "camera": stage_camera, "level": level, "player": actor, "fx": staged_fx}
	if restore_snapshot.is_empty():
		level.enter_level(actor, staged_fx, self)
	elif not level.enter_restore_candidate(actor, staged_fx, self, restore_snapshot.level, restore_snapshot.player):
		var construction_error: String = level.last_snapshot_error
		_dispose(candidate)
		_fail("Restore candidate construction failed: " + construction_error)
		return {}
	if not carried_resources.is_empty():
		var fresh: Dictionary = actor.snapshot_state()
		fresh.resources.hp = carried_resources.hp
		fresh.resources.shells = carried_resources.shells
		fresh.clocks.reload_s = carried_resources.reload_s
		if not actor.restore_state(fresh):
			_dispose(candidate)
			_fail(actor.last_snapshot_error)
			return {}
	return candidate

func _prepare_snapshot(snapshot: Dictionary) -> Dictionary:
	var error: String = _snapshot_problem(snapshot)
	if not error.is_empty():
		_fail(error)
		return {}
	# Fresh pure validation owns the exact constructed candidate. Never rebuild
	# it through ordinary entry or reuse an ID-only stale construction.
	var candidate: Dictionary = _validation_candidates.get(snapshot.level_id, {})
	_validation_candidates.erase(snapshot.level_id)
	if candidate.is_empty():
		candidate = _prepare(snapshot.level_id, snapshot.equipment_ids, {}, snapshot)
	if candidate.is_empty():
		return {}
	# Prevalidation completed for every component before either commit hook.
	if not candidate.player.restore_state(snapshot.player) or not candidate.level.restore_state(snapshot.level):
		_dispose(candidate)
		_fail("Validated aggregate commit hook failed")
		return {}
	# Only the real quietly restored candidate can certify current presentation.
	# Reject before retry/leave operations, donor disposal or Shell alias changes.
	error = _candidate_presentation_error(candidate, snapshot.shell)
	if not error.is_empty():
		_dispose(candidate)
		_fail("Restore candidate presentation failed: " + error)
		return {}
	return candidate

## Construction happens after all mechanical proof and quiet unit commits.
## The temporary HUD has its own offscreen native viewport at the OUTER pixel
## dimensions; using the 270x585 world viewport would shape different fonts.
## It has no campaign button observers and is freed on every outcome.
func _candidate_presentation_error(candidate: Dictionary, shell_state: Dictionary) -> String:
	if not get_tree().paused or not is_instance_valid(hud) or not hud.is_inside_tree() or not hud.is_node_ready() or hud.is_queued_for_deletion() or hud.get_script() != HUDScript or hud.custom_viewport != null:
		return "Ready canonical outer HUD and paused candidate required"
	var outer_size: Vector2 = hud.get_viewport().get_visible_rect().size
	if not outer_size.is_finite() or outer_size.x < 1.0 or outer_size.y < 1.0 or outer_size.x > 16384.0 or outer_size.y > 16384.0 or Vector2(Vector2i(outer_size)) != outer_size:
		return "Outer HUD requires bounded integral native pixel dimensions"
	if not is_instance_valid(candidate.get("player")) or not is_instance_valid(candidate.get("level")) or not is_instance_valid(candidate.get("camera")):
		return "Quietly restored native candidate bindings unavailable"
	# Saved focus changes only this candidate Camera3D. Installed focus, shake,
	# aim, HUD, resources and donor aliases remain untouched until installation.
	candidate.camera.global_position = Codec.read_vector3(shell_state.camera_focus) + CAMERA_OFFSET
	var hud_viewport := SubViewport.new()
	hud_viewport.name = "RestorePresentationHUDViewport"
	hud_viewport.size = Vector2i(outer_size)
	hud_viewport.disable_3d = true
	hud_viewport.handle_input_locally = false
	hud_viewport.gui_disable_input = true
	hud_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(hud_viewport)
	var framing_hud: GameHUD = HUDScript.new()
	framing_hud.name = "RestorePresentationHUD"
	framing_hud.visible = false
	hud_viewport.add_child(framing_hud)
	framing_hud.set_campaign_mode()
	framing_hud.hide_overlay()
	framing_hud.update_status(candidate.player.hp, candidate.player.max_hp, candidate.player.shells, candidate.player.max_shells, 0, candidate.level.objective_text)
	var error: String = ""
	if hud_viewport.get_visible_rect().size != outer_size:
		error = "Staging HUD viewport differs from the actual outer pixel dimensions"
	else:
		error = candidate.level.restore_candidate_presentation_error(candidate.camera, framing_hud)
	if is_instance_valid(hud_viewport): hud_viewport.free()
	return error

func _snapshot_problem(snapshot: Dictionary) -> String:
	if not get_tree().paused:
		return "Aggregate validation requires a paused candidate boundary"
	# Every submitted whole snapshot owns a new construction. Invalid identity
	# or gear must also discard a previous hidden validation candidate.
	_dispose_validation_candidates()
	var error: String = Codec.value_error(snapshot)
	if not error.is_empty():
		return error
	if not snapshot.get("level_id") is String or not snapshot.get("player") is Dictionary or not snapshot.get("level") is Dictionary or not snapshot.get("shell") is Dictionary or not snapshot.get("equipment_ids") is Dictionary:
		return "Missing live aggregate components"
	var id: String = snapshot.level_id
	if snapshot.get("scene_path") != registry.entry(id).get("scene_path") or snapshot.level.get("level_id") != id or snapshot.level.get("scene_path") != snapshot.scene_path:
		return "Aggregate scene identity differs from accepted registry"
	if not Codec.same_values(snapshot.equipment_ids, snapshot.player.get("equipment")):
		return "Actor gear differs from aggregate equipment"
	var candidate: Dictionary = {}
	if is_instance_valid(active_level) and active_level.level_id == id and active_level.scene_file_path == snapshot.scene_path and not active_level.restore_candidate_construction_required():
		candidate = {"player": player, "level": active_level}
	else:
		candidate = _prepare(id, snapshot.equipment_ids, {}, snapshot)
		if candidate.is_empty():
			return campaign_error
		_validation_candidates[id] = candidate
	error = candidate.player.snapshot_error(snapshot.player)
	if error.is_empty():
		# Cross-component local proof uses this validated saved actor, not a
		# fresh candidate's spawn pose. Commit still restores actor before level.
		error = candidate.level.snapshot_error_with_player(snapshot.level, snapshot.player)
	if error.is_empty():
		error = _shell_state_error(snapshot.shell, snapshot.player)
	return error

func _install(candidate: Dictionary, shell_state: Dictionary) -> void:
	if not candidate.level.finish_restore_candidate():
		_dispose(candidate)
		_fail("Uncommitted restore candidate cannot become playable")
		return
	_clear_gesture_chain()
	var old_container: Node = world.get_parent().get_parent()
	if is_instance_valid(active_level):
		active_level.exit_level()
	if is_instance_valid(player):
		player.cancel_world_action_capture()
	if is_instance_valid(fx):
		fx.clear_lab()
	active_level = candidate.level
	player = candidate.player
	fx = candidate.fx
	world = candidate.stage
	camera = candidate.camera
	level_scene_path = active_level.scene_file_path
	old_container.free()
	candidate.container.visible = true
	_restore_shell_state(shell_state)
	active_level.completion_requested.connect(func(id: String, _completion_id: String) -> void: _enqueue("complete", {"level_id": id}))
	active_level.checkpoint_requested.connect(func(id: String, _checkpoint_id: String, _boundary: String) -> void: _enqueue("checkpoint", {"level_id": id}))
	active_level.contact_exit_requested.connect(func(id: String, _exit_id: String) -> void: _enqueue("exit", {"level_id": id}))
	player.fired.connect(_on_fired)
	player.died.connect(func() -> void: _enqueue("pause"))
	player.equipment_changed.connect(func(id: String) -> void: hud.flash_message("Equipped " + player.equipment.item_name(id)))
	hud.visible = true
	hud.hide_overlay()
	_apply_cosmetic_policy()
	_update_status()

func _dispose(candidate: Dictionary) -> void:
	if is_instance_valid(candidate.get("level")):
		candidate.level.exit_level()
	if is_instance_valid(candidate.get("fx")):
		candidate.fx.clear_lab()
	if is_instance_valid(candidate.get("container")):
		candidate.container.free()

func _dispose_validation_candidates() -> void:
	for candidate: Dictionary in _validation_candidates.values():
		_dispose(candidate)
	_validation_candidates.clear()

func _fresh_shell_state() -> Dictionary:
	return {"api_revision": SHELL_API, "anchor_normalized": [0.5, 0.5], "input_sequence": 0, "last_input_observation": {}, "camera_focus": [0.0, 0.0, 0.0], "shake_left_s": 0.0, "difficulty_at_entry": _difficulty_preference}

func _shell_state() -> Dictionary:
	var observation: Dictionary = _last_input_observation.duplicate(true)
	if not observation.is_empty():
		observation.screen_position_normalized = [observation.screen_position_normalized.x, observation.screen_position_normalized.y]
		observation.anchor_normalized = [observation.anchor_normalized.x, observation.anchor_normalized.y]
		observation.direction = Codec.vector3(observation.direction)
	return {"api_revision": SHELL_API, "anchor_normalized": [_swipe_end_normalized.x, _swipe_end_normalized.y], "input_sequence": _input_sequence, "last_input_observation": observation, "camera_focus": Codec.vector3(_camera_focus), "shake_left_s": _shake, "difficulty_at_entry": _difficulty_at_entry}

func _shell_state_error(state: Dictionary, actor: Dictionary) -> String:
	var error: String = Codec.keys_error(state, ["api_revision", "anchor_normalized", "input_sequence", "last_input_observation", "camera_focus", "shake_left_s", "difficulty_at_entry"])
	if not error.is_empty() or state.api_revision != SHELL_API:
		return "Unsupported campaign shell state"
	if not _screen_pair(state.anchor_normalized) or not Codec.is_integer(state.input_sequence) or not Codec.is_vector3(state.camera_focus) or not Codec.in_range(state.shake_left_s, 0.0, 1.0) or not ["assisted", "standard", "challenge"].has(state.difficulty_at_entry) or not state.last_input_observation is Dictionary:
		return "Invalid input/camera/profile state"
	var record: Dictionary = state.last_input_observation
	if record.is_empty():
		return "" if state.input_sequence == 0 else "Missing last input observation"
	error = Codec.keys_error(record, ["schema_version", "sequence", "kind", "screen_position_normalized", "anchor_normalized", "direction", "accepted", "world_action_sequence", "action_clock_s"])
	if not error.is_empty() or not Codec.is_integer(record.sequence, 1) or record.sequence != state.input_sequence or record.schema_version != 1 or not ["swipe_release", "primary_tap", "blast_tap"].has(record.kind) or not _screen_pair(record.screen_position_normalized) or not _screen_pair(record.anchor_normalized) or not Codec.is_vector3(record.direction) or not record.accepted is bool or not Codec.is_integer(record.world_action_sequence, 0, int(actor.world_actions.sequence)) or not Codec.in_range(record.action_clock_s, 0.0, float(actor.world_actions.clock_s)):
		return "Invalid teaching-observer state"
	if not Codec.same_values(record.anchor_normalized, state.anchor_normalized):
		return "Observer and exact release anchor disagree"
	return ""

func _screen_pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and Codec.is_number(value[0]) and Codec.is_number(value[1]) and absf(float(value[0])) <= 1000000.0 and absf(float(value[1])) <= 1000000.0

func _restore_shell_state(state: Dictionary) -> void:
	_swipe_end_normalized = Vector2(float(state.anchor_normalized[0]), float(state.anchor_normalized[1]))
	_input_sequence = int(state.input_sequence)
	_last_input_observation = (state.last_input_observation as Dictionary).duplicate(true)
	if not _last_input_observation.is_empty():
		_last_input_observation.sequence = int(_last_input_observation.sequence)
		_last_input_observation.world_action_sequence = int(_last_input_observation.world_action_sequence)
		_last_input_observation.screen_position_normalized = Vector2(float(_last_input_observation.screen_position_normalized[0]), float(_last_input_observation.screen_position_normalized[1]))
		_last_input_observation.anchor_normalized = Vector2(float(_last_input_observation.anchor_normalized[0]), float(_last_input_observation.anchor_normalized[1]))
		_last_input_observation.direction = Codec.read_vector3(_last_input_observation.direction)
	_camera_focus = Codec.read_vector3(state.camera_focus)
	_shake = float(state.shake_left_s)
	_difficulty_at_entry = state.difficulty_at_entry
	camera.global_position = _camera_focus + CAMERA_OFFSET

func _settings_requested(changes: Dictionary) -> void:
	var accepted: bool = settings.update(changes)
	if accepted:
		settings.apply_runtime()
		_apply_cosmetic_policy()
	menu.acknowledge_settings(accepted, settings.last_error if not accepted else "")

func _difficulty_requested(profile_id: String) -> void:
	var candidate: Dictionary = {"schema_version": 1, "profile_id": profile_id}
	if not _preferences_error(candidate).is_empty() or not _preferences_store.write_payload(candidate):
		menu.set_difficulty_preference(_difficulty_preference)
		menu.show_error(_preferences_store.last_error)
		return
	_difficulty_preference = profile_id
	menu.set_difficulty_preference(profile_id)
	# Active scheduler profiles live in the local encounter snapshot. Only the
	# next authored fresh boundary reads this preference; no live retuning.

func _preferences_error(candidate: Dictionary) -> String:
	return "" if candidate.size() == 2 and candidate.get("schema_version") == 1 and ["assisted", "standard", "challenge"].has(candidate.get("profile_id")) else "Invalid fresh-encounter preference"

func _apply_cosmetic_policy() -> void:
	if is_instance_valid(fx) and settings != null and fx.has_method("configure_policy"):
		fx.configure_policy(settings.cosmetic_policy())

func _process(delta: float) -> void:
	if _preview_mode:
		super._process(delta)
		return
	if not is_instance_valid(player):
		return
	_shake = maxf(_shake - delta, 0.0)
	# Frame against the HUD this frame renders, including newly wrapped text.
	_update_status()
	_update_camera(delta)
	var shake_scale: float = 1.0
	if fx.has_method("camera_shake_scale"):
		shake_scale = fx.camera_shake_scale()
	if _shake > 0.0 and shake_scale > 0.0:
		camera.position.x += randf_range(-0.035, 0.035) * shake_scale
		camera.position.z += randf_range(-0.035, 0.035) * shake_scale

func _update_status() -> void:
	if is_instance_valid(player) and is_instance_valid(active_level):
		hud.update_status(player.hp, player.max_hp, player.shells, player.max_shells, 0, active_level.objective_text)
		hud.update_lab(player, get_aim_anchor(), false)

func handle_tap(screen_pos: Vector2) -> void:
	if not _preview_mode and (_draining or _drain_queued or menu == null or menu.is_open()):
		return
	super.handle_tap(screen_pos)

func _unhandled_input(event: InputEvent) -> void:
	if not _preview_mode and (menu == null or menu.is_open() or _draining or _drain_queued):
		return
	super._unhandled_input(event)

func _notification(what: int) -> void:
	if _preview_mode:
		super._notification(what)
	elif is_instance_valid(menu):
		if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
			request_pause()
		elif what == NOTIFICATION_WM_CLOSE_REQUEST:
			_enqueue("quit")

func _exit_tree() -> void:
	if not _preview_mode:
		_dispose_validation_candidates()
		if is_instance_valid(active_level):
			active_level.exit_level()
		if is_instance_valid(fx):
			fx.clear_lab()
		get_tree().auto_accept_quit = _old_auto_quit

func _fail(error: String) -> bool:
	campaign_error = error if not error.is_empty() else "Campaign operation could not commit"
	return false
