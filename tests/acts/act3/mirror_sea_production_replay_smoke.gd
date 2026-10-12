extends "res://tests/acts/act3/mirror_sea_production_warning_smoke.gd"
## TEST ONLY focused production Journey/replay/return; native result separate.
## Genuine initial L3 packet; declared historical prefix13 opens replay access.
## That metadata is not an earned route, enemy death, pulse or terminal packet.
## Public menu requests/buttons, actual GUI Resume and normal Shell disposal.

var _replay_story: Dictionary = {}
var _replay_prefix: Array[String] = []
var _replay_core: Dictionary = {}
var _replay_departure_refs: Array[WeakRef] = []
var _replay_return_refs: Array[WeakRef] = []
var _replay_continue_refs: Array[WeakRef] = []


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var reason: String = "" if arguments.is_empty() else "unsupported selector: " + str(arguments)
	if reason.is_empty(): reason = await _open()
	if _expect(reason.is_empty(), "genuine paused source-free L3 installs through the production Shell", reason):
		reason = _arrival_pair()
		if _expect(reason.is_empty(), "initial whole arrival pair and malformed controls remain exact", reason):
			reason = await _declare_historical_replay_access()
			if _expect(reason.is_empty(), "explicit TEST ONLY prefix13 persists without changing the genuine local packet", reason):
				reason = await _enter_production_replay()
				if _expect(reason.is_empty(), "Journey starts a distinct fresh native L3 replay and preserves its protected story", reason):
					reason = await _resume_and_repause("fresh replay")
					if _expect(reason.is_empty(), "fresh replay GUI Resume is consumed and public pause preserves the whole packet", reason):
						reason = await _return_protected_story()
						if _expect(reason.is_empty(), "public Leave Side Attempt quietly returns the exact protected story to Journey in fresh recipients", reason):
							reason = await _continue_returned_story()
							if _expect(reason.is_empty(), "public Back/Continue Story quietly installs the same protected packet and offers paused Resume", reason):
								reason = await _resume_and_repause("continued returned story")
								_expect(reason.is_empty(), "continued returned story GUI Resume is consumed without earned gameplay or packet changes", reason)
	if not reason.is_empty():
		print("FIRST MEANINGFUL PRODUCTION REPLAY FAILURE; later actions unattempted: ", reason, "; ", _diagnostic())
	await _dispose_host(_failures == 0)
	if node_added.is_connected(_watch_new_node): node_added.disconnect(_watch_new_node)
	_expect(_canonical_registry_bytes.is_empty() or FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH) == _canonical_registry_bytes, "canonical registry bytes remain unchanged")
	_cleanup_owned_path(_test_root)
	print("TEST ONLY Mirror Sea focused production replay: %d checks; failures: %d. Declared historical prefix13; genuine initial packet, Journey/fresh replay/return to Journey/explicit Continue, GUI Resume, exact story/disk and native donor cleanup. No earned clear/contact-next/full route/combat/pixels/canonical registration claim." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _declare_historical_replay_access() -> String:
	var genuine: Dictionary = _shell.capture_campaign_snapshot()
	var error: String = _source_free_packet_error(genuine)
	if not error.is_empty(): return error
	var initial: Dictionary = _shell.attempts.state()
	if initial.side_attempt != null or initial.completed_main.size() != 12 or not _exact(initial.story.snapshot, genuine) or not _exact(initial.story.checkpoint, genuine):
		return "inherited real initial story differs before historical metadata setup"
	_replay_prefix.assign(_shell.registry.main_route().slice(0,13))
	if _replay_prefix.size() != 13 or _replay_prefix[11] != "A3-L2" or _replay_prefix[12] != "A3-L3": return "actual canonical historical prefix13 differs"
	var session: Dictionary = initial.duplicate(true)
	# Only campaign history metadata changes. The genuine older local packet
	# remains uncompleted, as explicitly allowed for a reopened checkpoint.
	session.completed_main = _replay_prefix.duplicate()
	var observation: Dictionary = _native_observation()
	error = _shell.attempts.state_error(session)
	if not error.is_empty() or not _shell.attempts.restore_session(session): return "public historical session validation refused: " + error + "; " + _shell.attempts.last_error
	var after: Dictionary = _native_observation()
	# restore_session is an in-memory operation. Apart from the deliberately
	# declared Attempts history, the enumerated actual observations stay exact.
	observation.erase("attempts")
	after.erase("attempts")
	if not _exact(observation, after) or not _exact(_shell.capture_campaign_snapshot(), genuine) or not _exact(_shell.attempts.state(), session):
		return "historical metadata setup changed the native unit, disk or other session fields"
	_replay_story = session.story.duplicate(true)
	_replay_core = _campaign_core(session)
	# The real public Journey operation publishes the new campaign metadata
	# together with the unchanged actual packet through Attempts/SaveStore.
	_shell.menu.journey_requested.emit()
	error = await _settle_shell("journey")
	if not error.is_empty(): return error
	if not _exact(_shell.capture_campaign_snapshot(), genuine): return "Journey changed the genuine initial packet"
	error = _protected_story_error("story")
	if not error.is_empty(): return error
	return _disk_error(_shell.attempts.state())


func _enter_production_replay() -> String:
	if not paused or _shell.menu.page_name() != "journey": return "actual paused Journey unavailable"
	_shell.menu.select_level("A3-L3")
	var node: Button = _shell.menu.find_child("Node_A3_L3", true, false) as Button
	var action: Button = _shell.menu.find_child("LevelCardAction", true, false) as Button
	if node == null or node.get_meta("campaign_state", "") != "completed" or action == null or action.disabled or action.text != "Replay · Choose Equipment":
		return "real Journey does not expose the declared completed L3 replay"
	# Public button signal invokes the actual menu selection handler; this is
	# not a claim of viewport-routed or native OS input for navigation buttons.
	action.pressed.emit()
	if _shell.menu.page_name() != "replay" or not _exact(_shell.menu.replay_loadout(), _kit): return "actual replay setup differs from protected legal equipment"
	var start: Button = _shell.menu.find_child("StartReplayButton", true, false) as Button
	if start == null or start.disabled: return "actual Start Replay button unavailable"
	var events: Dictionary = _events.duplicate(true)
	var actions: Array[Dictionary] = _actions.duplicate(true)
	_replay_departure_refs = _current_native_refs()
	_prepare_fixture_rebind()
	start.pressed.emit()
	var error: String = await _settle_shell("resume")
	_watch_restore = false
	if not error.is_empty(): return error
	if not _quiet_events.is_empty() or not _exact(events, _events) or not _exact(actions, _actions): return "fresh replay emitted gameplay observers: " + str(_quiet_events)
	error = _bind_runtime()
	if not error.is_empty(): return error
	var replay: Dictionary = _shell.capture_campaign_snapshot()
	error = _source_free_packet_error(replay)
	if not error.is_empty(): return error
	var session: Dictionary = _shell.attempts.state()
	if session.side_attempt == null or session.side_attempt.kind != "replay" or session.side_attempt.level_id != "A3-L3" or not _exact(session.side_attempt.snapshot, replay) or not _exact(session.side_attempt.checkpoint, replay) or not _exact(session.last_replay_equipment, _kit):
		return "public replay did not publish one fresh complete side attempt/checkpoint"
	error = _protected_story_error("replay")
	if error.is_empty(): error = await _donor_freed_error(_replay_departure_refs, replay)
	if error.is_empty(): error = _disk_error(_shell.attempts.state())
	return error


func _return_protected_story() -> String:
	var error: String = _protected_story_error("replay")
	if not error.is_empty(): return error
	if not paused or _shell.menu.page_name() != "pause": return "actual paused replay return menu unavailable"
	var leave: Button = _shell.menu.find_child("LeaveSideButton", true, false) as Button
	if leave == null or leave.disabled: return "actual Leave Side Attempt button unavailable"
	var events: Dictionary = _events.duplicate(true)
	var actions: Array[Dictionary] = _actions.duplicate(true)
	_replay_return_refs = _current_native_refs()
	_prepare_fixture_rebind()
	leave.pressed.emit()
	error = await _settle_shell("journey")
	_watch_restore = false
	if not error.is_empty(): return error
	if not _quiet_events.is_empty() or not _exact(events, _events) or not _exact(actions, _actions): return "quiet protected-story return emitted gameplay observers: " + str(_quiet_events)
	error = _bind_runtime()
	if not error.is_empty(): return error
	var returned: Dictionary = _shell.capture_campaign_snapshot()
	if returned.is_empty() or not _exact(returned, _replay_story.snapshot): return "returned story differs from the complete original protected packet: " + _shell.campaign_error
	error = _source_free_packet_error(returned)
	if error.is_empty(): error = _protected_story_error("story")
	if error.is_empty(): error = await _donor_freed_error(_replay_return_refs, returned)
	if error.is_empty(): error = _disk_error(_shell.attempts.state())
	return error


func _continue_returned_story() -> String:
	var before: Dictionary = _shell.capture_campaign_snapshot()
	var error: String = _source_free_packet_error(before)
	if not error.is_empty(): return error
	if _shell.menu.page_name() != "journey": return "default side return did not open the actual paused Journey"
	var events: Dictionary = _events.duplicate(true)
	var actions: Array[Dictionary] = _actions.duplicate(true)
	var quiet: Array[String] = _quiet_events.duplicate()
	var back: Button = _shell.menu.find_child("BackButton", true, false) as Button
	if back == null or back.disabled or not back.is_visible_in_tree(): return "actual Journey Back button unavailable"
	# Navigation uses real public button signals, as above; only Resume is
	# claimed as actual viewport GUI input. Back itself changes no native unit.
	back.pressed.emit()
	if _shell.menu.page_name() != "title" or not _exact(before, _shell.capture_campaign_snapshot()) or not _exact(events, _events) or not _exact(actions, _actions) or not _exact(quiet, _quiet_events):
		return "public Journey Back changed the protected packet or gameplay observers"
	var continue_button: Button = _shell.menu.find_child("ContinueStoryButton", true, false) as Button
	if continue_button == null or continue_button.disabled or not continue_button.is_visible_in_tree() or continue_button.text != "Continue Story · A3-L3":
		return "actual title Continue Story button unavailable"
	_replay_continue_refs = _current_native_refs()
	_prepare_fixture_rebind()
	continue_button.pressed.emit()
	error = await _settle_shell("resume")
	_watch_restore = false
	if not error.is_empty(): return error
	if not _quiet_events.is_empty() or not _exact(events, _events) or not _exact(actions, _actions): return "explicit quiet Continue emitted gameplay observers: " + str(_quiet_events)
	error = _bind_runtime()
	if not error.is_empty(): return error
	var continued: Dictionary = _shell.capture_campaign_snapshot()
	if continued.is_empty() or not _exact(continued, before) or not _exact(continued, _replay_story.snapshot): return "explicit Continue changed the whole protected story: " + _shell.campaign_error
	error = _source_free_packet_error(continued)
	if error.is_empty(): error = _protected_story_error("story")
	if error.is_empty(): error = await _donor_freed_error(_replay_continue_refs, continued)
	if error.is_empty(): error = _disk_error(_shell.attempts.state())
	return error


func _resume_and_repause(label: String) -> String:
	var before: Dictionary = _shell.capture_campaign_snapshot()
	var error: String = _source_free_packet_error(before)
	if not error.is_empty(): return error
	var events: Dictionary = _events.duplicate(true)
	var actions: Array[Dictionary] = _actions.duplicate(true)
	var quiet: Array[String] = _quiet_events.duplicate()
	if not _resume_consumed(label): return label + ": actual GUI Resume was not consumed"
	# No physics wait or combat input is inserted. Outside a physics callback,
	# public request_pause immediately latches the real Shell deferred barrier.
	_shell.request_pause()
	error = await _settle_shell("pause")
	if not error.is_empty(): return error
	if not _exact(before, _shell.capture_campaign_snapshot()) or not _exact(events, _events) or not _exact(actions, _actions) or not _exact(quiet, _quiet_events):
		return label + ": Resume/public pause changed the packet or gameplay observers"
	error = _protected_story_error(_shell.attempts.active_kind())
	return _disk_error(_shell.attempts.state()) if error.is_empty() else error


func _source_free_packet_error(packet: Dictionary) -> String:
	if packet.is_empty() or not paused or not is_instance_valid(_shell) or _shell.active_level != _level or _shell.player != _hero: return "actual paused current production packet unavailable"
	var error: String = _pair_error({"hero": packet.player, "level": packet.level})
	if error.is_empty(): error = _host_bindings_error()
	if error.is_empty(): error = String(_level.call("runtime_error"))
	if not error.is_empty(): return error
	var local: Dictionary = packet.level.local
	var state: Dictionary = _level.call("state")
	if packet.level_id != "A3-L3" or packet.scene_path != LEVEL_PATH or packet.level.local_snapshot_version != 1 or local.api_revision != "act3-mirror-sea-snapshot-1" or local.schema_version != 1:
		return "actual L3 scene/format identity differs"
	if _scheduler.get_clock() != 0.0 or _hero.get_world_action_clock() != 0.0 or packet.player.world_actions.clock_s != 0.0 or packet.player.world_actions.sequence != 0 or not packet.player.world_actions.history.is_empty() or not packet.player.world_actions.pending_dash.is_empty() or not _hero.get_world_action_records().is_empty():
		return "focused source-free lifecycle unexpectedly earned clocks/actions"
	if not local.sources.is_empty() or not local.scheduler.reservations.is_empty() or not local.route.entries.is_empty() or not local.route.deaths.is_empty() or not local.route.pending_checkpoint_boundaries.is_empty() or local.ring.stage != "uninstalled" or not local.ring.mechanism.is_empty() or not local.ring.history.is_empty() or not local.ring.between_receipt.is_empty() or local.route.exit_state != "clear" or not local.route.contact.is_empty() or packet.level.progress.completed or not packet.level.progress.completion_id.is_empty() or not packet.level.progress.contact_exit_id.is_empty() or not packet.level.progress.checkpoint_ids.is_empty() or not state.route.entries.is_empty():
		return "historical access metadata invented local topology, route, pulse, death or completion"
	if not (_level.get("sources") as Dictionary).is_empty() or is_instance_valid(_level.get("mechanism")) or not get_nodes_in_group("enemies").is_empty() or _hero.dead or _hero.hp != _hero_hp or _hero.shells != _shells or not _exact(_kit, _hero.equipment.snapshot()) or not _exact(_stats, _hero.equipment.resolved_stats()):
		return "actual source-free world/resources/equipment differ"
	var cue: Node3D = _level.get("exit_cue") as Node3D
	var cues: Array[Node] = get_nodes_in_group("required_cues")
	if cue == null or cues.size() != 1 or cues[0] != cue or cue.get_parent() != _level or not cue.is_node_ready() or cue.get_script().resource_path != "res://scripts/cues/interaction_cue.gd": return "actual source-free world must retain only its configured clear exit cue"
	var cue_state: Dictionary = cue.call("state")
	var marker: MeshInstance3D = cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if not _exact(cue_state, {"api_revision": "interaction-cue-1", "state": "clear", "trigger": "attack", "required": true, "visible": false}) or marker == null or marker.visible or marker.mesh != null: return "initial exit cue gained available/contact presentation before local completion"
	return ""


func _protected_story_error(kind: String) -> String:
	var session: Dictionary = _shell.attempts.state()
	if _shell.attempts.active_kind() != kind or not _exact(session.story, _replay_story) or not _exact(_campaign_core(session), _replay_core): return "story/progression/rewards/unlocks changed across the isolated " + kind + " lifecycle"
	if kind == "story" and session.side_attempt != null: return "return retained a side attempt"
	if kind == "replay" and (session.side_attempt == null or session.side_attempt.kind != "replay"): return "actual replay side attempt unavailable"
	return ""


func _campaign_core(session: Dictionary) -> Dictionary:
	return {"completed_main": session.completed_main.duplicate(), "completed_optional": session.completed_optional.duplicate(), "reward_ids": session.reward_ids.duplicate(), "unlocked_equipment": session.unlocked_equipment.duplicate()}


func _prepare_fixture_rebind() -> void:
	# Only fixture-owned observers/barrier retire here. Actual Shell/parent
	# callbacks and whole-world disposal remain the production implementation.
	_detach_quiet_observers()
	_quiet_events.clear()
	if is_instance_valid(_barrier):
		_barrier.waiting = false
		_barrier.queue_free()
	_barrier = null
	_watch_restore = true


func _current_native_refs() -> Array[WeakRef]:
	var refs: Array[WeakRef] = []
	var seen: Dictionary = {}
	var world: Node = _shell.get("world") as Node
	_collect_native_refs(world, refs, seen)
	for node: Node in [_hero, _level, _scheduler, _barrier, _shell.get("camera") as Node, _shell.get("fx") as Node]:
		_collect_native_refs(node, refs, seen)
	return refs


func _collect_native_refs(node: Node, refs: Array[WeakRef], seen: Dictionary) -> void:
	if not is_instance_valid(node) or seen.has(node.get_instance_id()): return
	seen[node.get_instance_id()] = true
	refs.append(weakref(node))
	for child: Node in node.get_children(): _collect_native_refs(child, refs, seen)


func _donor_freed_error(refs: Array[WeakRef], receiver: Dictionary) -> String:
	if refs.is_empty(): return "actual native donor custody was not recorded"
	for _i: int in range(4):
		var freed: bool = true
		for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
		if freed:
			return "" if paused and _exact(receiver, _shell.capture_campaign_snapshot()) and get_nodes_in_group("enemies").is_empty() else "receiver changed during the native donor retirement observation"
		await process_frame
		if not paused or _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0: return "native donor cleanup observation advanced the source-free recipient"
	return "public production installation retained a donor World/body/source/camera/effect or fixture barrier"
