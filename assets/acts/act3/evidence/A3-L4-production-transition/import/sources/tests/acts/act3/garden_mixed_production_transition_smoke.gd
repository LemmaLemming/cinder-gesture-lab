extends "res://tests/acts/act3/garden_mixed_component_smoke.gd"
## UNEXECUTED TEST ONLY representative component completion/contact/next/replay.
## Requires the opt-in TEST recipient hook patch; never canonical late history.
## Real60→30→0/helpers/native gestures precede public CinderLevel progression.
## Public Shell/Menu/Attempts/disk operations preserve the actual protected story.

const Store = preload("res://scripts/campaign/save_store.gd")
const TRANSITION_CELL: String = "res://tests/acts/act3/fixtures/garden_mixed_production_transition.tscn"
const NEXT_FLOOR: String = "res://tests/acts/act3/fixtures/garden_mixed_next_floor.tscn"
const COMPLETION_ID: String = "false-paradise-disengaged"
const CONTACT_ID: String = "adage-plain-threshold"
var _forwarded: Array[Dictionary] = []
var _connected_levels: Dictionary = {}
var _receiver_nodes: Dictionary = {}
var _protected_story: Dictionary = {}
var _protected_core: Dictionary = {}
var _completed_pair: Dictionary = {}
var _departure_actor: Dictionary = {}
var _departure_anchor: Vector2 = Vector2.ZERO
var _contact_supported: bool = false


func _run() -> void:
	if not _expect(OS.get_cmdline_user_args().is_empty(), "one declared starter/Standard focused component transition; no alternate seed"):
		await _finish()
		return
	_root_only = true
	_canonical_registry = FileAccess.get_file_as_string(CampaignRegistry.DATA_PATH)
	if not node_added.is_connected(_watch_mixed_node): node_added.connect(_watch_mixed_node)
	if await _open_cell(TRANSITION_CELL) and _early_progress_rejections():
		# Reuse the genuine tested root branch. The override below keeps its
		# public pause/native pair checks without duplicating fresh-pair/abort
		# coverage from the component suite.
		await _root_component()
		if _failures == 0 and await _complete_component():
			if await _contact_next() and await _production_replay_return():
				_expect(_forwarded == [{"kind": "completion", "level_id": "A3-L4", "id": COMPLETION_ID}, {"kind": "exit", "level_id": "A3-L4", "id": CONTACT_ID}] and _events.count("completion") == 1 and _events.count("exit") == 1 and not _events.has("checkpoint") and not _events.has("fired_blast") and not _events.has("hero_death"), "exact canonical IDs forward once through the declared TEST arrangement; ordinary route has no blast/checkpoint/death/reward invention", str(_forwarded))
	await _finish()


func _open_cell(path: String) -> bool:
	_cell_path = path
	_events.clear()
	_game = MainScene.instantiate()
	root.add_child(_game)
	_game.call("open_bench")
	if not _expect(paused and _game.call("load_level_scene", path), "public Main loads the declared native TEST cell", path): return false
	_game.call("open_bench")
	if not _bind_mixed(): return false
	for _i: int in range(4): await process_frame
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	var input: Dictionary = _game.call("get_input_observation_state")
	if not _expect(_hero.get_world_action_clock() == 0.0 and _scheduler.get_clock() == 0.0 and _hero.get_world_action_records().is_empty() and input.sequence == 0 and input.last_observation.is_empty() and _game.call("get_aim_anchor_normalized") == Vector2(0.5, 0.5), "declared initial seed observes real clock0/no input or action history"): return false
	hud.update_status(_hero.hp, _hero.max_hp, _hero.shells, _hero.max_shells, 0, _level.objective_text)
	var actor: Dictionary = _hero.snapshot_state()
	var level: Dictionary = _level.snapshot_state_for_presentation(camera, hud)
	if not _expect(not actor.is_empty() and not level.is_empty() and _level.snapshot_error_with_player(level, actor).is_empty(), "clock0 native component pair includes its actual Camera/HUD", _level.last_snapshot_error): return false
	var seed: Dictionary = {"schema_version": 1, "level_id": "A3-L4", "scene_path": path, "paused": true, "equipment_ids": _kit.duplicate(true), "player": actor, "level": level, "shell": {"api_revision": ProductionShell.SHELL_API, "anchor_normalized": [0.5, 0.5], "input_sequence": 0, "last_input_observation": {}, "camera_focus": PairCodec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}}
	var raw: Variant = JSON.parse_string(_canonical_registry)
	if not _expect(raw is Dictionary, "canonical registry is readable without writes"): return false
	var replaced: bool = false
	var next_replaced: bool = false
	for row: Dictionary in raw.levels:
		if row.id == "A3-L4":
			row.scene_path = path
			row.readiness = "accepted" # TEST ONLY metadata, never canonical evidence.
			row.accepted_commit = "a".repeat(40)
			row.api_revision = CampaignRegistry.API_REVISION
			replaced = true
		elif row.id == "A3-L5":
			row.scene_path = NEXT_FLOOR
			row.readiness = "accepted" # TEST ONLY empty receiver floor.
			row.accepted_commit = "b".repeat(40)
			row.api_revision = CampaignRegistry.API_REVISION
			next_replaced = true
	if not _expect(replaced and next_replaced, "two in-memory TEST rows declare this component and empty next floor"): return false
	_test_registry = raw.duplicate(true)
	_initial_checkpoint = seed.duplicate(true)
	await _close()
	_isolated_root = "user://test-garden-mixed-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_production = ProductionShell.new()
	_game = _production
	if not _expect(_production.configure_runtime(raw, _isolated_root + "campaign.json", _isolated_root + "settings.json", _isolated_root + "preferences.json"), "actual ProductionShell uses its public registry and isolated SaveStore", _production.campaign_error): return false
	root.add_child(_production)
	for _i: int in range(4): await process_frame
	var prefix: Array[String] = []
	prefix.assign(_production.registry.main_route().slice(0, 13))
	if not _expect(paused and prefix.size() == 13 and prefix.back() == "A3-L3" and _production.registry.scene_error("A3-L4").is_empty(), "TEST predecessor metadata enables the declared component identity"): return false
	var session: Dictionary = _production.attempts.state()
	session.completed_main = prefix
	session.story = {"kind": "story", "level_id": "A3-L4", "snapshot": seed.duplicate(true), "checkpoint": seed.duplicate(true)}
	_begin_receiver_observation()
	var error: String = _production.attempts.state_error(session)
	if not _expect(error.is_empty() and _production.attempts.restore_session(session), "public TEST session seed preserves the actual clock0 pair", error): return false
	_production.menu.continue_story_requested.emit()
	if not await _settle_success("resume"): return false
	_quiet_watch = false
	if not _bind_mixed(): return false
	return _expect(_quiet_events.is_empty() and _wire_exact(_production.capture_campaign_snapshot(), seed), "fresh quiet Shell receiver retains exact clock0 mechanics and native optics", str(_quiet_events))


func _bind_mixed() -> bool:
	if not super._bind_mixed(): return false
	if not _expect(bool(_level.get("test_production_transition")) and _level.has_method("request_test_component_completion") and _level.has_method("request_test_component_contact"), "actual declared component exposes only its opt-in TEST production interface"): return false
	if not _connected_levels.has(_level.get_instance_id()):
		_connected_levels[_level.get_instance_id()] = true
		_level.completion_requested.connect(_on_completion)
		_level.contact_exit_requested.connect(_on_contact)
	return true


func _early_progress_rejections() -> bool:
	var before: Dictionary = _production.capture_campaign_snapshot()
	var state: Dictionary = _production.attempts.state()
	return _expect(not before.is_empty() and not _level.call("request_test_component_completion") and not _level.call("request_test_component_contact", _hero) and not _level.call("request_test_component_contact", _tether) and _forwarded.is_empty() and _wire_exact(before, _production.capture_campaign_snapshot()) and _wire_exact(state, _production.attempts.state()), "early/foreign contact and premature completion reject atomically before any native Core history")


func _roundtrip_and_abort(label: String, _abort: bool) -> bool:
	# Intentional scope override: this derivative does not repeat the default
	# component's complete fresh Continue/staged-abort suite. Genuine original
	# pauses/captures remain; every caller receives the same paused boundary.
	_production.request_pause()
	if not await _settle_success("pause"): return false
	var packet: Dictionary = _production.capture_campaign_snapshot()
	var parsed: Dictionary = PairExact.parse(PairExact.stringify(packet))
	var session: Dictionary = _production.attempts.state()
	return _expect(not packet.is_empty() and _level.snapshot_error_with_player(packet.level, packet.player).is_empty() and parsed.get("accepted", false) and _wire_exact(parsed.value, packet) and _wire_exact(session.story.snapshot, packet) and _wire_exact(session.story.checkpoint, _initial_checkpoint) and _disk_exact(session), "genuine component whole pair/ExactJson/public Pause preserves the initial checkpoint: " + label, _production.campaign_error + "; " + _level.last_snapshot_error)


func _complete_component() -> bool:
	var actual: Dictionary = _level.call("component_state")
	if not _expect(paused and actual.released and not actual.pending_release and not actual.helper_retired.is_empty() and actual.helper_death.is_empty() and _tether.get("dead") and _tether.get("hp") == 0.0 and _tether.get("phase") == 3 and _scheduler.reservations().is_empty() and _hero.hp == _hero.max_hp, "only real final0 and settled living helper retirement authorize representative component completion"): return false
	if not _expect(_level.call("request_test_component_completion"), "actual public CinderLevel completion is forwarded through production Shell"): return false
	if not await _settle_success("resume"): return false
	_completed_pair = _production.capture_campaign_snapshot()
	var session: Dictionary = _production.attempts.state()
	var prefix: Array = _production.registry.main_route().slice(0, 14)
	if not _expect(not _completed_pair.is_empty() and _completed_pair.level.progress.completed and _completed_pair.level.progress.completion_id == COMPLETION_ID and _completed_pair.level.progress.contact_exit_id.is_empty() and session.completed_main == prefix and session.completed_optional.is_empty() and session.reward_ids.is_empty() and _wire_exact(session.story.snapshot, _completed_pair) and _wire_exact(session.story.checkpoint, _initial_checkpoint) and _disk_exact(session) and _events.count("completion") == 1 and _forwarded.size() == 1, "one genuine TEST component completion durably appends A3-L4 to the declared prior prefix13 without changing its protected checkpoint"): return false
	var frozen: Dictionary = _production.capture_campaign_snapshot()
	return _expect(not _level.call("request_test_component_completion") and not _level.call("request_test_component_contact", _hero) and not _level.call("request_test_component_contact", _tether) and _wire_exact(frozen, _production.capture_campaign_snapshot()) and _events.count("completion") == 1 and _events.count("exit") == 0, "repeat completion, far Hero and foreign-body contact remain inert after actual completion")


func _contact_next() -> bool:
	if not _gui_resume("completed component"): return false
	var ready: bool = false
	for _i: int in range(90):
		if _hero.get_threat_response_state().stable:
			ready = true
			break
		if not await _tick(): return false
	if not _expect(ready and _scheduler.reservations().is_empty(), "actual released source-free Hero reaches normal dash readiness"): return false
	var start: Vector3 = _hero.global_position
	var finish: Vector3 = start + Vector3.BACK * float(_hero.stats.dash_distance)
	var count: int = _hero.get_world_action_records().size()
	var error: String = _swipe(Vector3.BACK)
	if not _expect(error.is_empty(), "ordinary full native contact approach retains routed release anchor", error) or not await _complete_dash({"from": start, "to": finish}): return false
	var actions: Array[Dictionary] = _hero.get_world_action_records()
	if not _expect(actions.size() == count + 1 and actions.back().kind == "dash" and (_level.call("test_transition_state") as Dictionary).contact_supported and _hero.hp == _hero_hp and not _hero.dead, "genuine grounded full capsule enters the declared TEST threshold after one complete ordinary dash"): return false
	# _complete_dash returns inside the physics barrier. Shell deliberately
	# defers its pause there; complete the real public barrier first so the
	# synchronous contact observer can legally capture the outgoing Hero.
	var contact_pose: Transform3D = _hero.global_transform
	var contact_clock: float = _hero.get_world_action_clock()
	var contact_history: Array[Dictionary] = _hero.get_world_action_records()
	if not await _completed_pause(): return false
	if not _expect(_hero.global_transform == contact_pose and _hero.get_world_action_clock() == contact_clock and _scheduler.get_clock() == contact_clock and _wire_exact(_hero.get_world_action_records(), contact_history) and bool((_level.call("test_transition_state") as Dictionary).contact_supported), "public completed contact pause retains the exact genuine grounded pose/clocks/history before native exit request"): return false
	var refs: Array[WeakRef] = _current_recipient_refs()
	_release_fixture_barrier()
	if not _expect(_level.call("request_test_component_contact", _hero), "actual grounded Hero contact forwards the exact canonical exit once through the TEST threshold"): return false
	if not await _settle_success("resume") or not _bind_next(): return false
	var next: Dictionary = _production.capture_campaign_snapshot()
	var session: Dictionary = _production.attempts.state()
	var okay: bool = not next.is_empty() and _contact_supported and not _departure_actor.is_empty() and _events.count("exit") == 1 and next.level_id == "A3-L5" and next.scene_path == NEXT_FLOOR and next.shell.difficulty_at_entry == "standard" and _wire_exact(next.equipment_ids, _kit) and _wire_exact(next.player.resources.hp, _departure_actor.resources.hp) and next.player.resources.shells == _departure_actor.resources.shells and _wire_exact(next.player.clocks.reload_s, _departure_actor.clocks.reload_s) and _wire_exact(next.shell.anchor_normalized, [_departure_anchor.x, _departure_anchor.y]) and _fresh_actor_error(next).is_empty() and _wire_exact(session.completed_main, _production.registry.main_route().slice(0,14)) and _wire_exact(session.story.snapshot, next) and _wire_exact(session.story.checkpoint, next) and _disk_exact(session)
	if not _expect(okay and await _recipient_freed(refs, next), "real contact installs a fresh paused TEST next floor with exact HP/ammo/reload/gear/anchor, prefix14/disk/checkpoint and whole donor retirement", _production.campaign_error): return false
	return await _resume_and_pause("next-floor")


func _production_replay_return() -> bool:
	_protected_story = _production.attempts.state().story.duplicate(true)
	_protected_core = _campaign_core(_production.attempts.state())
	_production.menu.journey_requested.emit()
	if not await _settle_success("journey"): return false
	_production.menu.select_level("A3-L4")
	var node: Button = _production.menu.find_child("Node_A3_L4", true, false) as Button
	var action: Button = _production.menu.find_child("LevelCardAction", true, false) as Button
	if not _expect(node != null and node.get_meta("campaign_state", "") == "completed" and action != null and not action.disabled and action.text == "Replay · Choose Equipment", "actual Journey exposes the genuinely completed TEST component replay"): return false
	action.pressed.emit()
	var start: Button = _production.menu.find_child("StartReplayButton", true, false) as Button
	if not _expect(_production.menu.page_name() == "replay" and start != null and not start.disabled and _wire_exact(_production.menu.replay_loadout(), _kit), "real replay setup retains the original legal carried kit"): return false
	var refs: Array[WeakRef] = _current_recipient_refs()
	_begin_receiver_observation()
	start.pressed.emit()
	if not await _settle_success("resume"): return false
	_quiet_watch = false
	if not _bind_mixed(): return false
	var replay: Dictionary = _production.capture_campaign_snapshot()
	var session: Dictionary = _production.attempts.state()
	var actual: Dictionary = _level.call("component_state")
	if not _expect(not replay.is_empty() and _fresh_actor_error(replay).is_empty() and not replay.level.progress.completed and replay.level.progress.completion_id.is_empty() and replay.level.progress.contact_exit_id.is_empty() and _tether.get("hp") == 60.0 and _tether.get("phase") == 1 and not is_instance_valid(_level.get("helper")) and not actual.sun.started and not actual.released and _scheduler.reservations().is_empty() and session.side_attempt != null and session.side_attempt.kind == "replay" and session.side_attempt.level_id == "A3-L4" and _wire_exact(session.side_attempt.snapshot, replay) and _wire_exact(session.side_attempt.checkpoint, replay) and _protected_error() and _quiet_events.is_empty() and _disk_exact(session) and await _recipient_freed(refs, replay), "fresh production replay has genuine initial native topology/clock/history and preserves protected next-story/disk with quiet fresh recipients", str(_quiet_events)): return false
	if not await _resume_and_pause("fresh replay"): return false
	var leave: Button = _production.menu.find_child("LeaveSideButton", true, false) as Button
	if not _expect(leave != null and not leave.disabled, "actual replay Leave Side button is available"): return false
	refs = _current_recipient_refs()
	_release_fixture_barrier()
	_begin_receiver_observation()
	leave.pressed.emit()
	if not await _settle_success("journey"): return false
	_quiet_watch = false
	if not _bind_next(): return false
	var returned: Dictionary = _production.capture_campaign_snapshot()
	if not _expect(_wire_exact(returned, _protected_story.snapshot) and _protected_error() and _production.attempts.state().side_attempt == null and _quiet_events.is_empty() and _disk_exact(_production.attempts.state()) and await _recipient_freed(refs, returned), "public Leave Side reconstructs the exact protected story in a distinct quiet recipient and retires the whole replay"): return false
	var back: Button = _production.menu.find_child("BackButton", true, false) as Button
	if not _expect(back != null and not back.disabled and back.is_visible_in_tree(), "actual Journey Back button exists"): return false
	back.pressed.emit()
	var button: Button = _production.menu.find_child("ContinueStoryButton", true, false) as Button
	if not _expect(_production.menu.page_name() == "title" and button != null and not button.disabled and button.text == "Continue Story · A3-L5", "real title exposes protected A3-L5 Continue"): return false
	refs = _current_recipient_refs()
	_begin_receiver_observation()
	button.pressed.emit()
	if not await _settle_success("resume"): return false
	_quiet_watch = false
	if not _bind_next(): return false
	returned = _production.capture_campaign_snapshot()
	if not _expect(_wire_exact(returned, _protected_story.snapshot) and _protected_error() and _quiet_events.is_empty() and _disk_exact(_production.attempts.state()) and await _recipient_freed(refs, returned), "explicit Back/Continue quietly reconstructs the same protected native unit without a story/history fork"): return false
	return await _resume_and_pause("returned-story")


func _bind_next() -> bool:
	_level = _production.active_level
	_hero = _production.player
	_game = _production
	_scheduler = null
	_core = null
	_tether = null
	_echo = null
	_mechanisms.clear()
	return _expect(paused and is_instance_valid(_level) and is_instance_valid(_hero) and _level.level_id == "A3-L5" and _level.scene_file_path == NEXT_FLOOR and _level.get_script().resource_path == "res://scripts/campaign/level.gd" and _level.shared_shell == _production and _hero.equipment.snapshot() == _kit and get_nodes_in_group("enemies").is_empty(), "actual production receiver is only the declared empty TEST next floor/shared Hero")


func _fresh_actor_error(packet: Dictionary) -> String:
	if packet.is_empty() or packet.player.world_actions.clock_s != 0.0 or packet.player.world_actions.sequence != 0 or not packet.player.world_actions.history.is_empty() or not packet.player.world_actions.pending_dash.is_empty() or packet.shell.input_sequence != 0 or not packet.shell.last_input_observation.is_empty() or packet.player.resources.dead: return "Fresh recipient inherited old clock/action/pending/input/death history"
	return ""


func _campaign_core(session: Dictionary) -> Dictionary:
	var result: Dictionary = session.duplicate(true)
	result.erase("story")
	result.erase("side_attempt")
	result.erase("last_replay_equipment")
	return result


func _protected_error() -> bool:
	var session: Dictionary = _production.attempts.state()
	return _wire_exact(session.story, _protected_story) and _wire_exact(_campaign_core(session), _protected_core)


func _disk_exact(session: Dictionary) -> bool:
	var reader = Store.new(_isolated_root + "campaign.json")
	var payload: Dictionary = reader.read_payload()
	return reader.last_error.is_empty() and _wire_exact(payload, session)


func _gui_resume(label: String) -> bool:
	var button: Control = _production.menu.find_child("ResumeButton", true, false) as Control
	if not _expect(paused and button != null and button.is_visible_in_tree() and _production.menu.is_open(), label + ": real Resume GUI exists"): return false
	var state: Dictionary = {"history": _hero.get_world_action_records(), "input": _production.get_input_observation_state(), "clock": _hero.get_world_action_clock(), "hp": _hero.hp, "shells": _hero.shells, "equipment": _hero.equipment.snapshot()}
	var point: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = point
	down.global_position = point
	down.pressed = true
	root.push_input(down, true)
	var consumed: bool = root.is_input_handled()
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up, true)
	return _expect(consumed and root.is_input_handled() and not paused and not _production.menu.is_open() and _wire_exact(_hero.get_world_action_records(), state.history) and _wire_exact(_production.get_input_observation_state(), state.input) and _hero.get_world_action_clock() == state.clock and _hero.hp == state.hp and _hero.shells == state.shells and _wire_exact(_hero.equipment.snapshot(), state.equipment), label + ": actual viewport GUI Resume is consumed without gameplay/input/resource/gear mutation")


func _resume_and_pause(label: String) -> bool:
	var before: Dictionary = _production.capture_campaign_snapshot()
	if not _gui_resume(label): return false
	_production.request_pause()
	if not await _settle_success("pause"): return false
	return _expect(not before.is_empty() and _wire_exact(before, _production.capture_campaign_snapshot()) and _disk_exact(_production.attempts.state()) and (_protected_story.is_empty() or _protected_error()), label + ": immediate public pause retains the exact actual native unit/disk and protected story")


func _current_recipient_refs() -> Array[WeakRef]:
	var refs: Array[WeakRef] = []
	var stage: Node = _production.get("world") as Node
	if is_instance_valid(stage): _weakrefs(stage.get_parent().get_parent(), refs)
	if is_instance_valid(_mixed_barrier): refs.append(weakref(_mixed_barrier))
	return refs


func _release_fixture_barrier() -> void:
	if not is_instance_valid(_mixed_barrier): return
	_mixed_barrier.waiting = false
	if _mixed_barrier.get_parent() != null: _mixed_barrier.get_parent().remove_child(_mixed_barrier)
	_mixed_barrier.queue_free()
	_mixed_barrier = null


func _recipient_freed(refs: Array[WeakRef], packet: Dictionary) -> bool:
	if refs.is_empty(): return false
	for _i: int in range(6):
		var empty: bool = true
		for ref: WeakRef in refs: empty = empty and ref.get_ref() == null
		if empty: return _wire_exact(packet, _production.capture_campaign_snapshot())
		await process_frame
	return false


func _begin_receiver_observation() -> void:
	_receiver_nodes.clear()
	_quiet_events.clear()
	_quiet_watch = true


func _watch_mixed_node(node: Node) -> void:
	if _quiet_watch and is_instance_valid(_production) and _production.is_ancestor_of(node) and not _seen_nodes.has(node.get_instance_id()): _receiver_nodes[node.get_instance_id()] = true
	super._watch_mixed_node(node)


func _quiet_note(node: Node, label: String) -> void:
	if _quiet_watch and is_instance_valid(node) and _receiver_nodes.has(node.get_instance_id()): _quiet_events.append(label)


func _on_completion(level_id: String, id: String) -> void:
	_forwarded.append({"kind": "completion", "level_id": level_id, "id": id})


func _on_contact(level_id: String, id: String) -> void:
	_forwarded.append({"kind": "exit", "level_id": level_id, "id": id})
	_departure_actor = _hero.snapshot_state()
	_departure_anchor = _production.get_aim_anchor_normalized()
	_contact_supported = paused and not _departure_actor.is_empty() and bool((_level.call("test_transition_state") as Dictionary).contact_supported) and _scheduler.reservations().is_empty() and _hero.hp == _hero_hp


func _tick() -> bool:
	# Mechanics are unchanged. The derivative admits only its once-forwarded
	# completion count during the source-free contact approach, rather than
	# falsely requiring the default component's perpetual noncampaign scope.
	if paused or not is_instance_valid(_mixed_barrier): return _expect(false, "actual unpaused component tick requires its native barrier")
	_mixed_barrier.expired = false
	_mixed_barrier.frames = 0
	_mixed_barrier.waiting = true
	await _mixed_barrier.observed
	var error: String = String(_level.call("runtime_error"))
	var fixed: bool = _tether.global_transform == _fixed_target
	for kind: String in ["draw", "enclose"]: fixed = fixed and _source(kind).global_transform == _fixed_sources[kind]
	if _watch_enclose:
		var current: Dictionary = _source("enclose").state()
		fixed = fixed and current.status == "running" and current.reservation_id == _enclose_id and current.geometry == _enclose_geometry
		if int((_level.call("component_state") as Dictionary).sun.effective_index) != _enclose_sun: _flip_seen = true
	_native_ticks += 1
	var count: int = 1 if _level.is_completed() else 0
	var ok: bool = not _mixed_barrier.expired and not paused and error.is_empty() and fixed and not _hero.dead and _hero.hp == _hero_hp and _hero.equipment.snapshot() == _kit and not _events.has("fired_blast") and _events.count("completion") == count and not _events.has("checkpoint") and not _events.has("exit") and _scheduler.get_clock() <= MIXED_LIMIT_S
	return true if ok else _expect(false, "bounded post-actor tick preserves original controls/fixed sources/HP/strict known progression counts", error)


func _finish() -> void:
	await _close()
	if node_added.is_connected(_watch_mixed_node): node_added.disconnect(_watch_mixed_node)
	_expect(_canonical_registry.is_empty() or FileAccess.get_file_as_string(CampaignRegistry.DATA_PATH) == _canonical_registry, "canonical registry remains byte-identical")
	print("TEST ONLY genuine mixed root completion/production contact/next/replay/return: %d checks; %d native post-actor ticks; failures: %d. Declared prior prefix13/in-memory A3-L4+empty A3-L5 rows; genuine60→40→30→10→0, living helper retirement, one actual capsule contact, complete native packets/disk, fresh recipients, GUI Resume/protected-story separation/cleanup. Canonical late full-parent history/all earlier courts/full playthrough remain untested; no canonical registration/equipment/ability/mobile credit." % [_checks, _native_ticks, _failures])
	quit(0 if _failures == 0 else 1)
