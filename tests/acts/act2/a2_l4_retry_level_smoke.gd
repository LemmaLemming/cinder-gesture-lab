extends "res://tests/acts/act2/a2_l4_live_level_smoke.gd"
## Scoped actual L4 first-checkpoint lifecycle, not a second full route.
## Inherits TEST ONLY prior prefix throughL3/unlocks and initial canonical gear.
## Standard/Heavy normal initial HP, shells0; actual viewport swipes/primaries.
## No live HP/motion/phase/clock/progress edits or direct damage/death calls.
## Complete format2 Continue/Retry preserve every source, bank and shell field.
## Running grace/atomic malformed transport belongs to focused bank fixtures.
## Native art, full L4 route, other profiles/loadouts and device scope untested.

const LifecycleJson: Script = preload("res://scripts/campaign/exact_json.gd")
const LIFECYCLE_CHECKPOINT: String = "changed-garden-clear"
const LIFECYCLE_RAY: String = "flood_scout"
const LifecycleRoutePlanner: Script = preload("res://tests/acts/act2/a2_l3_route_planner.gd")
const LIFECYCLE_FATAL_TARGET := Vector3(-0.65, 0.0, -10.20)
const LIFECYCLE_FATAL_REGION := Rect2(-0.80, -10.35, 0.30, 0.30)
var _lc_raw: Dictionary = {}
var _lc_preserved_sources: Dictionary = {}
var _lc_checkpoints: Array[String] = []
var _lc_defeats: Array[String] = []
var _lc_completions: Array[String] = []
var _lc_exits: Array[String] = []
var _lc_checkpoint_resources: Dictionary = {}
var _lc_hits: Array[Dictionary] = []
var _lc_deaths: int = 0
var _lc_restore_events: Array[String] = []
var _lc_watching_restore: bool = false
var _lc_auto_resume: bool = true

func _run() -> void:
	if not _read_options() or not _expect(_profile_id == "standard" and _loadout_name == "heavy" and not _capture_live, "lifecycle fixture selects Standard/Heavy and owns no art/full-route selector"):
		quit(1); return
	root.size = Vector2i(540, 1170)
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	node_added.connect(_lc_observe_added)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	for path: String in FROZEN_INPUTS + ["res://tests/acts/act2/a2_l4_live_level_smoke.gd", LONDON_DESTINATION]:
		_lc_preserved_sources[path] = FileAccess.get_file_as_string(path)
	_cleanup()
	print("L4 first-checkpoint lifecycle: Standard/%s; normal initial HP/zero initial ammo, real garden clear/contact, running flood-bank GUI Continue, genuine tracking-ray fatal damage/dead Continue/dead Resume/GUI Retry; TEST ONLY prior prefix throughL3/unlocks/L5 destination; no full-clear/native-art claim" % _loadout_name)
	var failures_before: int = _failures
	if not await _run_route() and _failures == failures_before: _expect(false, "actual L4 lifecycle aborted: " + _diagnostic())
	await process_frame
	_lc_watching_restore = false
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	if is_instance_valid(_native_probe): _native_probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "lifecycle injection preserves canonical registry bytes")
	for path: String in _lc_preserved_sources:
		_expect(FileAccess.get_file_as_string(path) == _lc_preserved_sources[path], "lifecycle preserves existing helper/destination and frozen new base bytes: " + path)
	_cleanup()
	print("L4 first-checkpoint lifecycle smoke: %d checks, %d failures; scoped actual checkpoint/GUI/fatal transport only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _run_route() -> bool:
	_lc_raw = JSON.parse_string(_canonical)
	for info: Dictionary in _lc_raw.levels:
		if info.id in ["A2-L4", "A2-L5"]:
			info.scene_path = LONDON_SCENE if info.id == "A2-L4" else LONDON_DESTINATION
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(_lc_raw)
	if not _expect(registry.last_error.is_empty(), "isolated TEST ONLY registry retains canonical sequence") or not await _seed(registry): return false
	if not await _lc_new_shell(): return false
	if not await _lc_click("ContinueStoryButton"): return false
	if not _expect(_live() and paused and _game.menu.page_name() == "resume" and _game.player.hp == _game.player.max_hp and _game.player.shells == 0 and _game.player.equipment.snapshot() == _loadout, "real GUI Continue installs initial normalHP/empty-ammo L4 paused"): return false
	_lc_bind_live()
	if not await _lc_click("ResumeButton") or not await _clear(["garden_handler"]): return false
	if not await _broadside_blocker("GardenStemBlocker") or not await _contact("road_entry", _lc_checkpoints): return false
	await _lc_settle()
	var anchor: Vector2 = _game.get_aim_anchor_normalized()
	var checkpoint: Dictionary = _game.attempts.state().story.checkpoint.duplicate(true)
	if not _expect(not checkpoint.is_empty() and checkpoint.level.progress.checkpoint_id == LIFECYCLE_CHECKPOINT and _lc_checkpoints == [LIFECYCLE_CHECKPOINT], "actual road-entry crossing durably earns its first checkpoint"): return false
	_expect(checkpoint.level.local.sequence.defeated_ids == ["garden_handler"] and checkpoint.level.local.sequence.crossed_contacts == ["road_entry"] and checkpoint.level.local.sequence.stage_index == 2 and not checkpoint.level.progress.completed, "checkpoint contains only the real garden defeat/contact before the flood mixture")
	_expect(checkpoint.player.resources.hp == _lc_checkpoint_resources.hp and checkpoint.player.resources.shells == _lc_checkpoint_resources.shells and checkpoint.equipment_ids == _lc_checkpoint_resources.equipment, "checkpoint retains actual initiating HP/ammo/gear without refill")
	_expect(checkpoint.shell.anchor_normalized == [anchor.x, anchor.y] and checkpoint.shell.input_sequence > 0, "checkpoint retains the actual routed final-release anchor/input history")
	var running: Dictionary = await _lc_pause_flood_bank()
	if running.is_empty() or not _lc_valid_snapshot(running): return false
	var bank: Dictionary = running.level.local.banks.flood_bank
	_expect(bank.status == "running" and bank.phase == "lock" and bank.pending_stage.is_empty() and bank.processed_count == bank.trace.size() and bank.sample.position == running.player.motion.position and bank.sample.clock_s == running.level.local.scheduler.clock_s, "full deferred native pause retains running bank/current Player sample/processed history")
	var running_encoded: String = LifecycleJson.stringify(running)
	if not _lc_format2(running_encoded): return false
	var decoded: Dictionary = LifecycleJson.parse(running_encoded)
	if not _expect(decoded.get("accepted", false) and LifecycleJson.stringify(decoded.get("value", {})) == running_encoded, "ExactJson transports the actual complete running-bank Shell unit"): return false
	if not await _lc_fresh_continue(running_encoded, "running flood bank"): return false
	_expect(LifecycleJson.stringify(_game.attempts.state().story.checkpoint) == LifecycleJson.stringify(checkpoint), "fresh active-bank Continue preserves the earlier earned checkpoint")
	_game.menu.difficulty_preference_requested.emit("challenge")
	_expect(_game.get_difficulty_preference() == "challenge" and _state().exchanges.flood_tender.resolved_role.difficulty_profile == "standard", "new public preference preserves the admitted saved Standard bank epoch")
	if not await _lc_click("ResumeButton") or not await _clear(["flood_tender"]): return false
	# Use the exact native-tail helper: consume a genuine escape proof once
	# and always await a tick, even if its original dash deadline is past.
	if not await _finish_bank_tail("flood_bank"): return false
	if not _expect(_state().banks.flood_bank.status == "complete" and float(_actors.flood_scout.get("hp")) > 0.0, "independent original flood tail finishes while the required Scout remains genuinely alive"): return false
	if not await _lc_approach_scout(): return false
	if not _expect(_lc_defeats == ["garden_handler", "flood_tender"] and _lc_checkpoints == [LIFECYCLE_CHECKPOINT] and _blocker_bypass_seen.has("GardenStemBlocker"), "real Tender clear and legitimate dry dashes reach the living Scout without another checkpoint"): return false
	var before_wait: Dictionary = _state()
	var actions_before: int = _lc_action_sequence()
	var hits_before: int = _lc_hits.size()
	for frame: int in range(7200):
		if _game.player.dead: break
		if not _live(): break
		await _step()
	await _lc_settle()
	if not _expect(_game.player.dead and _game.player.hp == 0.0 and _lc_deaths == 1 and paused and _game.menu.page_name() == "pause" and _game.campaign_error.is_empty(), "genuine required-source damage reaches death and the Shell's deferred pause barrier: " + _diagnostic()): return false
	var ray_hits: Array[Dictionary] = []
	for hit: Dictionary in _lc_hits.slice(hits_before):
		if hit.source_id == LIFECYCLE_RAY and hit.result.get("accepted", false) and float(hit.result.get("hp_damage", 0.0)) > 0.0: ray_hits.append(hit)
	if not _expect(not ray_hits.is_empty() and ray_hits[-1].hero_hp == 0.0, "actual armed flood Scout delivers the fatal native damage without direct damage/death calls"):
		print("L4 Scout fatal diagnostic: hits=", _lc_hits, " approach=", before_wait, " current=", _state()); return false
	for hit: Dictionary in ray_hits:
		_expect(hit.result.raw_damage == _expected_roles.ray.damage and hit.cycle > 0, "delivered tracking-ray damage belongs to an actual fixed Standard source/cycle")
	var dead: Dictionary = _game.capture_campaign_snapshot()
	if not _lc_valid_snapshot(dead): return false
	_expect(dead.player.resources.dead and dead.player.world_actions.sequence == actions_before and _lc_defeats == ["garden_handler", "flood_tender"] and _lc_checkpoints == [LIFECYCLE_CHECKPOINT] and _lc_completions.is_empty() and _lc_exits.is_empty(), "fatal wait invents no action/target defeat/contact/completion/exit")
	_expect(dead.level.local.sequence.defeated_ids == ["garden_handler", "flood_tender"] and dead.level.local.sequence.crossed_contacts == ["road_entry"] and dead.level.local.profile_id == "standard" and not dead.level.progress.completed, "dead tuple retains only the real earned prefix and saved profile")
	_expect(dead.level.local.rays.records[LIFECYCLE_RAY].status == "cancelled" and dead.level.local.rays.records[LIFECYCLE_RAY].last_cancel_reason == "hero_defeated" and dead.level.local.scheduler.reservations.is_empty(), "supported death barrier closes the actual running Scout and its dangerous lease")
	_expect(_game.attempts.state().completed_main == LONDON_PREFIX and _game.attempts.state().reward_ids.is_empty() and LifecycleJson.stringify(_game.attempts.active_snapshot()) == LifecycleJson.stringify(dead) and LifecycleJson.stringify(_game.attempts.state().story.checkpoint) == LifecycleJson.stringify(checkpoint), "Shell saves exact fatal story while protecting living checkpoint/prior prefix/no reward")
	var dead_encoded: String = LifecycleJson.stringify(dead)
	if not _lc_format2(dead_encoded): return false
	if not await _lc_fresh_continue(dead_encoded, "actual fatal unit"): return false
	_expect(_game.get_difficulty_preference() == "challenge" and _state().exchanges.flood_scout.resolved_role.difficulty_profile == "standard", "fresh fatal Continue reloads newer settings while preserving the original source epoch")
	var disk_before: String = FileAccess.get_file_as_string(LONDON_TEST_ROOT + "campaign.json")
	_lc_restore_events.clear(); _lc_watching_restore = true
	if not await _lc_click("ResumeButton"): return false
	_lc_watching_restore = false
	var notice: Label = _game.menu.find_child("MenuStatus", true, false) as Label
	_expect(paused and _game.player.dead and _game.menu.page_name() == "pause" and notice != null and notice.text == "Retry your saved checkpoint." and LifecycleJson.stringify(_game.capture_campaign_snapshot()) == dead_encoded and FileAccess.get_file_as_string(LONDON_TEST_ROOT + "campaign.json") == disk_before and _lc_restore_events.is_empty(), "dead GUI Resume consumes input and preserves exact fatal clocks/resources/history/disk without action")
	var old: Array[Dictionary] = _lc_old_refs()
	_lc_restore_events.clear(); _lc_watching_restore = true
	if not await _lc_click("RetryButton"): return false
	_lc_watching_restore = false
	var retried: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(_game.campaign_error.is_empty() and paused and _game.menu.page_name() == "resume" and not _game.player.dead and LifecycleJson.stringify(retried) == LifecycleJson.stringify(checkpoint) and _lc_restore_events.is_empty(), "real GUI Retry quietly restores the exact earned changed-garden-clear aggregate"): return false
	_lc_refs_freed(old, "GUI checkpoint Retry")
	_expect(retried.player.resources == checkpoint.player.resources and retried.equipment_ids == checkpoint.equipment_ids and retried.shell == checkpoint.shell and _game.get_aim_anchor_normalized() == anchor and retried.level.local.profile_id == "standard" and _game.get_difficulty_preference() == "challenge", "Retry keeps actual saved resources/gear/input/camera/profile despite the newer preference")
	_lc_restore_events.clear(); _lc_watching_restore = true
	await _lc_settle()
	_lc_watching_restore = false
	_expect(LifecycleJson.stringify(_game.capture_campaign_snapshot()) == LifecycleJson.stringify(checkpoint) and _lc_restore_events.is_empty() and _game.attempts.state().completed_main == LONDON_PREFIX and not _game.active_level.is_completed(), "paused retry neither refreshes native clocks nor emits danger/progression")
	return _failures == 0

func _lc_new_shell() -> bool:
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(_lc_raw, LONDON_TEST_ROOT + "campaign.json", LONDON_TEST_ROOT + "settings.json", LONDON_TEST_ROOT + "preferences.json"), "new actual Shell uses only inherited TEST ONLY registry/save paths"): return false
	root.add_child(_game)
	await _lc_settle()
	return _expect(paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "title", "fresh actual Shell loads isolated saved story at Title")

func _lc_bind_live() -> void:
	_actors = _game.active_level.get("_actors").duplicate()
	_banks = _game.active_level.get("_clouds").duplicate()
	for actor: Node in _actors.values():
		actor.connect("defeated", func(id: String) -> void:
			_lc_defeats.append(id)
			_observe_defeat(id)
		)
	_game.active_level.checkpoint_requested.connect(func(_id: String, checkpoint: String, _kind: String) -> void:
		_lc_checkpoints.append(checkpoint)
		if checkpoint == LIFECYCLE_CHECKPOINT: _lc_checkpoint_resources = {"hp": _game.player.hp, "shells": _game.player.shells, "equipment": _game.player.equipment.snapshot()}
	)
	_game.active_level.completion_requested.connect(func(_id: String, id: String) -> void: _lc_completions.append(id))
	_game.active_level.contact_exit_requested.connect(func(_id: String, id: String) -> void: _lc_exits.append(id))
	_game.player.world_action_executed.connect(func(record: Dictionary) -> void:
		_actions.append(record.duplicate(true))
		_observe_blocker_path(record)
	)
	_game.player.died.connect(func() -> void: _lc_deaths += 1)
	for id: String in _banks:
		_banks[id].connect("tick_resolved", func(hero_id: String, cycle: int, result: Dictionary) -> void: _lc_hits.append({"source_id": id, "hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true), "hero_hp": _game.player.hp}))
	var exchange: Node = _game.active_level.get("_exchange")
	exchange.connect("hit_resolved", func(source_id: String, result: Dictionary) -> void:
		var current: Dictionary = _state().exchanges.get(source_id, {})
		_lc_hits.append({"source_id": source_id, "cycle": int(current.get("cycle", 0)), "result": result.duplicate(true), "hero_hp": _game.player.hp})
	)

func _lc_pause_flood_bank() -> Dictionary:
	for frame: int in range(1200):
		if not _live(): break
		var current: Dictionary = _state().banks.flood_bank
		if current.status == "running" and current.phase == "lock" and _stable():
			_lc_auto_resume = false
			_game.request_pause()
			await _lc_settle()
			var saved: Dictionary = _game.capture_campaign_snapshot()
			if _expect(paused and _game.menu.page_name() == "pause" and _game.campaign_error.is_empty() and not saved.is_empty() and saved.level.local.banks.flood_bank.phase == "lock", "public pause settles actual running flood bank at a full native boundary"): return saved
			return {}
		if frame % 90 == 0:
			var target: Node3D = _actors.flood_tender as Node3D
			var offset: Vector3 = _game.player.global_position - target.global_position
			offset.y = 0.0
			if offset.length() > 3.45 and not await _navigate_dash(target.global_position + offset.normalized() * 3.0): return {}
		await _step()
	_expect(false, "bounded real flood-bank lock was unavailable: " + _diagnostic())
	return {}

func _lc_fresh_continue(expected: String, label: String) -> bool:
	var retired: Array[Dictionary] = _lc_old_refs(true)
	await process_frame
	_lc_watching_restore = false
	_release_fixture_shell(_game)
	_game = null
	_lc_refs_freed(retired, "old " + label + " closure")
	_lc_restore_events.clear(); _lc_watching_restore = true
	if not await _lc_new_shell() or not await _lc_click("ContinueStoryButton"): return false
	_lc_watching_restore = false
	if not _expect(paused and _game.menu.page_name() == "resume" and LifecycleJson.stringify(_game.capture_campaign_snapshot()) == expected and _lc_restore_events.is_empty(), "fresh real GUI Continue restores exact " + label + " without damage/action/source-defeat/progression callbacks: " + str(_lc_restore_events)): return false
	if not _lc_valid_snapshot(_game.capture_campaign_snapshot()): return false
	var restored: Dictionary = _game.capture_campaign_snapshot()
	_expect(Codec.same_values(_input_json(), {"schema_version": 1, "sequence": restored.shell.input_sequence, "anchor_normalized": restored.shell.anchor_normalized, "last_observation": restored.shell.last_input_observation}), "fresh " + label + " installs the actual public input router state")
	await _lc_settle()
	_expect(LifecycleJson.stringify(_game.capture_campaign_snapshot()) == expected, "fresh paused " + label + " preserves all clocks/receipts/resources/input/camera")
	_lc_bind_live()
	_lc_auto_resume = true
	return true

func _lc_format2(expected: String) -> bool:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(LONDON_TEST_ROOT + "campaign.json"))
	if not _expect(envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("payload_json") is String and envelope.get("sha256") is String and float(envelope.get("generation", 0)) > 0.0, "actual Shell publishes a real format2 generation"): return false
	var encoded: String = envelope.payload_json
	var decoded: Dictionary = LifecycleJson.parse(encoded)
	return _expect(envelope.sha256 == encoded.sha256_text() and decoded.get("accepted", false) and LifecycleJson.stringify(decoded.value.story.snapshot) == expected and _game.attempts.saved_payload_error(decoded.value).is_empty(), "format2 checksum/ExactJson/public payload validation retains the exact paused story")

func _lc_valid_snapshot(saved: Dictionary) -> bool:
	return _expect(not saved.is_empty() and _game.player.snapshot_error(saved.player).is_empty() and _game.active_level.snapshot_error_with_player(saved.level, saved.player).is_empty(), "public complete saved-player/level preflight accepts the actual paused lifecycle tuple")

func _lc_click(name: String) -> bool:
	await _lc_settle()
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
	await _lc_settle()
	return _expect(presses == [name] and _game.campaign_error.is_empty(), "one actual GUI click settles without duplicate publication/campaign error: " + name + " " + _game.campaign_error)

func _lc_action_sequence() -> int:
	# Snapshot capture is deliberately paused-only; live completed records expose
	# the monotonically increasing sequence even after older history is bounded.
	var records: Array[Dictionary] = _game.player.get_world_action_records()
	return 0 if records.is_empty() else int(records.back().sequence)

func _lc_approach_scout() -> bool:
	# Pure planner proposes actual supported capsule-clear full-length legs.
	# Inherited _dash publishes real viewport swipes and measured native paths.
	for attempt: int in range(6):
		if not _live(): return false
		var start: Vector3 = _game.player.global_position
		if LIFECYCLE_FATAL_REGION.has_point(Vector2(start.x, start.z)) and _stable(): return true
		var path: Array[Vector3] = LifecycleRoutePlanner.path(_game.player, _game.active_level, LIFECYCLE_FATAL_TARGET)
		if path.is_empty():
			if not await _navigate_dash(LIFECYCLE_FATAL_TARGET): return false
		else:
			for waypoint: Vector3 in path:
				if not _live(): return false
				var actual: Vector3 = _game.player.global_position
				if actual.distance_to(waypoint) <= 0.0001: continue
				if not LifecycleRoutePlanner.leg_clear(_game.player, _game.active_level, actual, waypoint): break
				if not await _dash((waypoint - actual).normalized()): return false
		for frame: int in range(180):
			if not _live(): return false
			if _stable(): break
			await _step()
	return _expect(LIFECYCLE_FATAL_REGION.has_point(Vector2(_game.player.global_position.x, _game.player.global_position.z)) and _stable(), "bounded real routed navigation reaches the living Scout's supported lane point: " + _diagnostic())

func _lc_observe_added(node: Node) -> void:
	if not _lc_watching_restore: return
	if node is CinderPlayer:
		var hero: CinderPlayer = node as CinderPlayer
		hero.fired.connect(func(_kind: String) -> void: _lc_restore_events.append("player-fired"))
		hero.died.connect(func() -> void: _lc_restore_events.append("player-death"))
		hero.equipment_changed.connect(func(_id: String) -> void: _lc_restore_events.append("player-gear"))
		hero.world_action_executed.connect(func(_record: Dictionary) -> void: _lc_restore_events.append("player-action"))
	elif node is CinderLevel:
		var level: CinderLevel = node as CinderLevel
		level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _lc_restore_events.append("checkpoint"))
		level.completion_requested.connect(func(_id: String, _completion: String) -> void: _lc_restore_events.append("completion"))
		level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _lc_restore_events.append("exit"))
	elif node is CinderLaneMechanism:
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _lc_restore_events.append("tool-hit"))
	elif node.get_script() == SmokeBank:
		node.connect("tick_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _lc_restore_events.append("bank-tick"))
	elif node.has_signal("defeated"):
		node.connect("defeated", func(_id: String) -> void: _lc_restore_events.append("target-defeat"))
	if node.get_script() == RayExchange:
		node.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: _lc_restore_events.append("ray-hit"))
		node.connect("scout_defeated", func(_id: String) -> void: _lc_restore_events.append("ray-defeat"))

func _lc_old_refs(include_shell: bool = false) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	if include_shell: refs.append({"label": "CampaignShell", "ref": weakref(_game)})
	for node: Node in [_game.world, _game.active_level, _game.player, _game.fx]: refs.append({"label": String(node.name), "ref": weakref(node)})
	for node: Node in _game.active_level.get_children(): refs.append({"label": String(node.name), "ref": weakref(node)})
	var kit: Node = _game.active_level.get_node_or_null("LondonApproachesKit")
	if is_instance_valid(kit):
		var meshes: Array[Node] = kit.find_children("*", "MeshInstance3D", true, false)
		if not meshes.is_empty(): refs.append({"label": "representative scenery mesh", "ref": weakref(meshes.front())})
	var ground: Node = _game.active_level.get_node_or_null("LondonApproachesDryGround")
	if is_instance_valid(ground): refs.append({"label": "actual dry support", "ref": weakref(ground.get_node("garden/DrySupport"))})
	for cue: Node in get_nodes_in_group("required_cues"):
		if _game.active_level.is_ancestor_of(cue): refs.append({"label": String(cue.name), "ref": weakref(cue)})
	return refs

func _lc_refs_freed(refs: Array[Dictionary], label: String) -> void:
	for entry: Dictionary in refs: _expect((entry.ref as WeakRef).get_ref() == null, label + " frees old actual " + String(entry.label))

func _lc_settle() -> void:
	# Native pause requests drain only after the complete physics tick. Paused
	# GUI/transport checks await render/process frames, never the bot's auto-resume.
	for frame: int in range(8): await process_frame

func _step() -> void:
	await _native_probe.tick_finished
	if _lc_auto_resume and is_instance_valid(_game) and paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "resume" and not _game.player.dead: _game.resume_campaign()
	_observe_runtime()
