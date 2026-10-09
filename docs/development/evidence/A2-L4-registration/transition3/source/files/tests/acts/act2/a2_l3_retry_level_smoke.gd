extends "res://tests/acts/act2/a2_l3_live_level_smoke.gd"
## Scoped actual L3 first-checkpoint lifecycle, not a second full route.
## Synthetic preceding prefix/unlocks/profile remain the inherited TEST ONLY seed.
## Normal initial HP, zero initial ammo, genuine primary/dashes/source damage.
## No live HP/motion/phase/clock/progress edits or direct damage invocation.
## Running-bank grace/corruption cases belong to a2_l3_bank_transport_smoke.

const LifecycleJson: Script = preload("res://scripts/campaign/exact_json.gd")
const LIFECYCLE_CHECKPOINT: String = "smoke-edge-clear"
const LIFECYCLE_TOOL: String = "tool_house_handler"
const LIFECYCLE_FATAL_TARGET := Vector3(-0.80, 0.0, -14.90)
const LIFECYCLE_FATAL_REGION := Rect2(-0.95, -15.05, 0.30, 0.30)
var _lc_raw: Dictionary = {}
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
	if not _read_options() or not _expect(_profile_id == "standard" and not _capture_live and not _road_only, "lifecycle fixture selects Standard and owns no art/full-route selector"):
		quit(1); return
	root.size = Vector2i(540, 1170)
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	node_added.connect(_lc_observe_added)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_l2_fixture_bytes = FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l2_transition_destination.tscn")
	_cleanup()
	print("L3 first-checkpoint lifecycle: Standard/%s; normal initial HP/zero initial ammo, real road clear/contact, running house-bank GUI Continue, real Handler death/dead Continue/GUI Retry; TEST ONLY prior prefix/unlocks; no boss-phase/final-clear claim" % _loadout_name)
	var failures_before: int = _failures
	if not await _run_route() and _failures == failures_before: _expect(false, "actual L3 lifecycle aborted: " + _diagnostic())
	await process_frame
	_lc_watching_restore = false
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	if is_instance_valid(_native_probe): _native_probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l2_transition_destination.tscn") == _l2_fixture_bytes, "lifecycle injection preserves canonical registry and frozen L2 destination")
	_cleanup()
	print("L3 first-checkpoint lifecycle smoke: %d checks, %d failures; scoped actual checkpoint/GUI/fatal transport only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _run_route() -> bool:
	_lc_raw = JSON.parse_string(_canonical)
	for info: Dictionary in _lc_raw.levels:
		if info.id in ["A2-L3", "A2-L4"]:
			info.scene_path = HOUSE_SCENE if info.id == "A2-L3" else HOUSE_DESTINATION
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(_lc_raw)
	if not _expect(registry.last_error.is_empty(), "isolated TEST ONLY registry retains canonical sequence") or not await _seed(registry): return false
	if not await _lc_new_shell(): return false
	if not await _lc_click("ContinueStoryButton"): return false
	if not _expect(_live() and paused and _game.menu.page_name() == "resume" and _game.player.hp == _game.player.max_hp and _game.player.shells == 0 and _game.player.equipment.snapshot() == _loadout, "real GUI Continue installs initial normalHP/empty-ammo L3 paused"): return false
	_lc_bind_live()
	if not await _lc_click("ResumeButton") or not await _clear(["road_tender"]): return false
	if not await _lc_swipe(): return false
	var anchor: Vector2 = _game.get_aim_anchor_normalized()
	if not await _contact("clear_ground", _lc_checkpoints): return false
	await _lc_settle()
	var checkpoint: Dictionary = _game.attempts.state().story.checkpoint.duplicate(true)
	if not _expect(not checkpoint.is_empty() and checkpoint.level.progress.checkpoint_id == LIFECYCLE_CHECKPOINT and _lc_checkpoints == [LIFECYCLE_CHECKPOINT], "actual clear-ground crossing durably earns its first checkpoint"): return false
	_expect(checkpoint.level.local.sequence.defeated_ids == ["road_tender"] and checkpoint.level.local.sequence.crossed_contacts == ["clear_ground"] and checkpoint.level.local.sequence.boss_phase == 0 and not checkpoint.level.progress.completed, "checkpoint contains only the real road defeat/contact before the house mixture")
	_expect(checkpoint.player.resources.hp == _lc_checkpoint_resources.hp and checkpoint.player.resources.shells == _lc_checkpoint_resources.shells and checkpoint.equipment_ids == _lc_checkpoint_resources.equipment, "checkpoint retains actual initiating HP/ammo/gear without refill")
	_expect(checkpoint.shell.anchor_normalized == [anchor.x, anchor.y] and checkpoint.shell.input_sequence > 0, "checkpoint retains the actual routed final-release anchor/input history")
	var running: Dictionary = await _lc_pause_house_bank()
	if running.is_empty() or not _lc_valid_snapshot(running): return false
	var bank: Dictionary = running.level.local.banks.house_bank
	_expect(bank.status == "running" and bank.phase == "lock" and bank.pending_stage.is_empty() and bank.processed_count == bank.trace.size() and bank.sample.position == running.player.motion.position and bank.sample.clock_s == running.level.local.scheduler.clock_s, "full deferred native pause retains running bank/current Player sample/processed history")
	var running_encoded: String = LifecycleJson.stringify(running)
	var decoded: Dictionary = LifecycleJson.parse(running_encoded)
	if not _expect(decoded.get("accepted", false) and LifecycleJson.stringify(decoded.get("value", {})) == running_encoded, "ExactJson transports the actual complete running-bank Shell unit"): return false
	if not await _lc_fresh_continue(running_encoded, "running house bank"): return false
	_expect(LifecycleJson.stringify(_game.attempts.state().story.checkpoint) == LifecycleJson.stringify(checkpoint), "fresh active-bank Continue preserves the earlier earned checkpoint")
	_game.menu.difficulty_preference_requested.emit("challenge")
	_expect(_game.get_difficulty_preference() == "challenge" and _state().exchanges.house_tender.resolved_role.difficulty_profile == "standard", "new public preference preserves the admitted saved Standard bank epoch")
	if not await _lc_click("ResumeButton") or not await _clear(["house_tender"]) or not await _broadside_wall() or not await _lc_approach_handler(): return false
	if not _expect(_lc_defeats == ["road_tender", "house_tender"] and _lc_checkpoints == [LIFECYCLE_CHECKPOINT] and _wall_bypass_seen, "real second Tender clear and broad side dashes reach the living Handler without the next checkpoint"): return false
	var before_wait: Dictionary = _state()
	var actions_before: int = _lc_action_sequence()
	var hits_before: int = _lc_hits.size()
	for frame: int in range(7200):
		if _game.player.dead: break
		if not _live(): break
		await _step()
	await _lc_settle()
	if not _expect(_game.player.dead and _game.player.hp == 0.0 and _lc_deaths == 1 and paused and _game.menu.page_name() == "pause" and _game.campaign_error.is_empty(), "genuine required-source damage reaches death and the Shell's deferred pause barrier: " + _diagnostic()): return false
	var tool_hits: Array[Dictionary] = []
	for hit: Dictionary in _lc_hits.slice(hits_before):
		if hit.source_id == LIFECYCLE_TOOL and hit.result.get("accepted", false) and float(hit.result.get("hp_damage", 0.0)) > 0.0: tool_hits.append(hit)
	if not _expect(not tool_hits.is_empty() and tool_hits[-1].hero_hp == 0.0, "actual armed house Handler delivers the fatal native damage without direct damage/death calls"):
		print("L3 Handler fatal diagnostic: hits=", _lc_hits, " approach=", before_wait, " current=", _state()); return false
	for hit: Dictionary in tool_hits: _expect(hit.hero_id == "hero" and hit.result.raw_damage == _expected_roles.tool.damage and hit.cycle > 0, "delivered Handler damage belongs to an actual fixed Standard source/cycle")
	var dead: Dictionary = _game.capture_campaign_snapshot()
	if not _lc_valid_snapshot(dead): return false
	_expect(dead.player.resources.dead and dead.player.world_actions.sequence == actions_before and _lc_defeats == ["road_tender", "house_tender"] and _lc_checkpoints == [LIFECYCLE_CHECKPOINT] and _lc_completions.is_empty() and _lc_exits.is_empty(), "fatal wait invents no action/target defeat/contact/completion/exit")
	_expect(dead.level.local.sequence.defeated_ids == ["road_tender", "house_tender"] and dead.level.local.sequence.crossed_contacts == ["clear_ground"] and dead.level.local.profile_id == "standard" and not dead.level.progress.completed, "dead tuple retains only the real earned prefix and saved profile")
	_expect(dead.level.local.mechanisms[LIFECYCLE_TOOL].status == "cancelled" and dead.level.local.mechanisms[LIFECYCLE_TOOL].last_cancel_reason == "hero_defeated" and dead.level.local.scheduler.reservations.is_empty(), "supported death barrier closes the actual running tool and its dangerous lease")
	_expect(_game.attempts.state().completed_main == HOUSE_PREFIX and _game.attempts.state().reward_ids.is_empty() and LifecycleJson.stringify(_game.attempts.active_snapshot()) == LifecycleJson.stringify(dead) and LifecycleJson.stringify(_game.attempts.state().story.checkpoint) == LifecycleJson.stringify(checkpoint), "Shell saves exact fatal story while protecting living checkpoint/prior prefix/no reward")
	var dead_encoded: String = LifecycleJson.stringify(dead)
	if not await _lc_fresh_continue(dead_encoded, "actual fatal unit"): return false
	var disk_before: String = FileAccess.get_file_as_string(HOUSE_TEST_ROOT + "campaign.json")
	_lc_restore_events.clear(); _lc_watching_restore = true
	if not await _lc_click("ResumeButton"): return false
	_lc_watching_restore = false
	var notice: Label = _game.menu.find_child("MenuStatus", true, false) as Label
	_expect(paused and _game.player.dead and _game.menu.page_name() == "pause" and notice != null and notice.text == "Retry your saved checkpoint." and LifecycleJson.stringify(_game.capture_campaign_snapshot()) == dead_encoded and FileAccess.get_file_as_string(HOUSE_TEST_ROOT + "campaign.json") == disk_before and _lc_restore_events.is_empty(), "dead GUI Resume consumes input and preserves exact fatal clocks/resources/history/disk without action")
	var old: Array[Dictionary] = _lc_old_refs()
	_lc_restore_events.clear(); _lc_watching_restore = true
	if not await _lc_click("RetryButton"): return false
	_lc_watching_restore = false
	var retried: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(_game.campaign_error.is_empty() and paused and _game.menu.page_name() == "resume" and not _game.player.dead and LifecycleJson.stringify(retried) == LifecycleJson.stringify(checkpoint) and _lc_restore_events.is_empty(), "real GUI Retry quietly restores the exact earned smoke-edge-clear aggregate"): return false
	_lc_refs_freed(old, "GUI checkpoint Retry")
	_expect(retried.player.resources == checkpoint.player.resources and retried.equipment_ids == checkpoint.equipment_ids and retried.shell == checkpoint.shell and _game.get_aim_anchor_normalized() == anchor and retried.level.local.profile_id == "standard" and _game.get_difficulty_preference() == "challenge", "Retry keeps actual saved resources/gear/input/camera/profile despite the newer preference")
	_lc_restore_events.clear(); _lc_watching_restore = true
	await _lc_settle()
	_lc_watching_restore = false
	_expect(LifecycleJson.stringify(_game.capture_campaign_snapshot()) == LifecycleJson.stringify(checkpoint) and _lc_restore_events.is_empty() and _game.attempts.state().completed_main == HOUSE_PREFIX and not _game.active_level.is_completed(), "paused retry neither refreshes native clocks nor emits danger/progression")
	return _failures == 0

func _lc_new_shell() -> bool:
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(_lc_raw, HOUSE_TEST_ROOT + "campaign.json", HOUSE_TEST_ROOT + "settings.json", HOUSE_TEST_ROOT + "preferences.json"), "new actual Shell uses only inherited TEST ONLY registry/save paths"): return false
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
		_observe_wall_path(record)
	)
	_game.player.died.connect(func() -> void: _lc_deaths += 1)
	for id: String in _banks:
		_banks[id].connect("tick_resolved", func(hero_id: String, cycle: int, result: Dictionary) -> void: _lc_hits.append({"source_id": id, "hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true), "hero_hp": _game.player.hp}))
	var mechanism: Node = _game.active_level.get("_mechanisms")[LIFECYCLE_TOOL]
	mechanism.connect("hit_resolved", func(hero_id: String, cycle: int, result: Dictionary) -> void: _lc_hits.append({"source_id": LIFECYCLE_TOOL, "hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true), "hero_hp": _game.player.hp}))

func _lc_pause_house_bank() -> Dictionary:
	for frame: int in range(1200):
		if not _live(): break
		var current: Dictionary = _state().banks.house_bank
		if current.status == "running" and current.phase == "lock" and _stable():
			_lc_auto_resume = false
			_game.request_pause()
			await _lc_settle()
			var saved: Dictionary = _game.capture_campaign_snapshot()
			if _expect(paused and _game.menu.page_name() == "pause" and _game.campaign_error.is_empty() and not saved.is_empty() and saved.level.local.banks.house_bank.phase == "lock", "public pause settles actual running house bank at a full native boundary"): return saved
			return {}
		if frame % 90 == 0:
			var target: Node3D = _actors.house_tender as Node3D
			var offset: Vector3 = _game.player.global_position - target.global_position
			offset.y = 0.0
			if offset.length() > 3.45 and not await _navigate_dash(target.global_position + offset.normalized() * 3.0): return {}
		await _step()
	_expect(false, "bounded real house-bank lock was unavailable: " + _diagnostic())
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
	if not _expect(paused and _game.menu.page_name() == "resume" and LifecycleJson.stringify(_game.capture_campaign_snapshot()) == expected and _lc_restore_events.is_empty(), "fresh real GUI Continue restores exact " + label + " without damage/action/phase-boundary/progression callbacks: " + str(_lc_restore_events)): return false
	if not _lc_valid_snapshot(_game.capture_campaign_snapshot()): return false
	await _lc_settle()
	_expect(LifecycleJson.stringify(_game.capture_campaign_snapshot()) == expected, "fresh paused " + label + " preserves all clocks/receipts/resources/input/camera")
	_lc_bind_live()
	_lc_auto_resume = true
	return true

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

func _lc_swipe() -> bool:
	for frame: int in range(180):
		if not _live(): return false
		var response: Dictionary = _game.player.get_threat_response_state()
		if response.stable and float(response.dash_cooldown_left_s) <= 0.00001: break
		await _step()
	var sequence: int = _lc_action_sequence()
	var input_sequence: int = int(_game.get_input_observation_state().sequence)
	var size: Vector2 = root.get_visible_rect().size
	var press := InputEventScreenTouch.new()
	press.index = 3; press.pressed = true; press.position = Vector2(0.70, 0.65) * size
	root.push_input(press, true)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 3; drag.position = Vector2(0.64, 0.50) * size; drag.relative = drag.position - press.position
	root.push_input(drag, true)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 3; release.position = drag.position
	root.push_input(release, true)
	for frame: int in range(180):
		if not _live(): return false
		if _lc_action_sequence() > sequence and _stable():
			return _expect(_last_dash().kind == "dash" and _game.get_aim_anchor_normalized().is_equal_approx(Vector2(0.64, 0.50)) and int(_game.get_input_observation_state().sequence) == input_sequence + 1, "real touch/drag/release publishes its completed dash and exact final anchor")
		await _step()
	return _expect(false, "actual routed swipe did not complete before the checkpoint")

func _lc_approach_handler() -> bool:
	# Two equal-length real dashes can reach a small lane point. The read-only
	# geometric planner validates each leg against actual floors/colliders;
	# request_dash and its completed sampled landing remain authoritative.
	for attempt: int in range(4):
		if not _live(): return false
		var start: Vector3 = _game.player.global_position
		if LIFECYCLE_FATAL_REGION.has_point(Vector2(start.x, start.z)) and _stable(): return true
		var distance: float = float(_game.player.stats.dash_distance)
		var offset: Vector3 = LIFECYCLE_FATAL_TARGET - start
		offset.y = 0.0
		var span: float = offset.length()
		var direct: Vector3 = start + offset.normalized() * distance
		if LIFECYCLE_FATAL_REGION.has_point(Vector2(direct.x, direct.z)) and _lc_path_clear(start, direct):
			if not await _dash(offset.normalized()): return false
			continue
		var waypoint: Vector3 = Vector3.INF
		if span > 0.0 and span <= 2.0 * distance:
			var midpoint: Vector3 = (start + LIFECYCLE_FATAL_TARGET) * 0.5
			var perpendicular := Vector3(-offset.z, 0.0, offset.x) / span
			var height: float = sqrt(maxf(distance * distance - span * span * 0.25, 0.0))
			for side: float in [-1.0, 1.0]:
				var candidate: Vector3 = midpoint + perpendicular * height * side
				if _lc_path_clear(start, candidate) and _lc_path_clear(candidate, LIFECYCLE_FATAL_TARGET) and (not waypoint.is_finite() or absf(candidate.x) < absf(waypoint.x)): waypoint = candidate
		if waypoint.is_finite():
			if not await _dash((waypoint - start).normalized()): return false
			var actual: Vector3 = _game.player.global_position
			if not await _dash((LIFECYCLE_FATAL_TARGET - actual).normalized()): return false
		elif not await _navigate_dash(LIFECYCLE_FATAL_TARGET): return false
		for frame: int in range(180):
			if not _live(): return false
			if _stable(): break
			await _step()
	return _expect(LIFECYCLE_FATAL_REGION.has_point(Vector2(_game.player.global_position.x, _game.player.global_position.z)) and _stable(), "bounded legitimate navigation reaches actual Handler lane point: " + _diagnostic())

func _lc_path_clear(start: Vector3, finish: Vector3) -> bool:
	var hero: CinderPlayer = _game.player
	var collision: CollisionShape3D = hero.get_node("BodyCollision") as CollisionShape3D
	var radius: float = float((collision.shape as CapsuleShape3D).radius) + 0.01
	var excluded: Array[RID] = [hero.get_rid()]
	var supported: bool = false
	for floor: Dictionary in _game.active_level.call("floor_regions"):
		excluded.append((floor.body as StaticBody3D).get_rid())
		var rect: Rect2 = (floor.safe_rect as Rect2).grow(-radius)
		if rect.has_point(Vector2(start.x, start.z)) and rect.has_point(Vector2(finish.x, finish.z)): supported = true
	if not supported: return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	var pose: Transform3D = collision.global_transform
	pose.origin += start - hero.global_position
	query.transform = pose; query.motion = finish - start
	query.collision_mask = 1; query.margin = 0.001; query.exclude = excluded
	if query.motion == Vector3.ZERO: return hero.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
	var cast: PackedFloat32Array = hero.get_world_3d().direct_space_state.cast_motion(query)
	return cast.size() == 2 and cast[0] == 1.0

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
	if node.has_signal("phase_boundary_reached"):
		node.connect("phase_boundary_reached", func(_id: String) -> void: _lc_restore_events.append("boss-boundary"))
	if node.get_script() == RayExchange:
		node.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: _lc_restore_events.append("ray-hit"))
		node.connect("scout_defeated", func(_id: String) -> void: _lc_restore_events.append("ray-defeat"))

func _lc_old_refs(include_shell: bool = false) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	if include_shell: refs.append({"label": "CampaignShell", "ref": weakref(_game)})
	for node: Node in [_game.world, _game.active_level, _game.player, _game.fx]: refs.append({"label": String(node.name), "ref": weakref(node)})
	for node: Node in _game.active_level.get_children(): refs.append({"label": String(node.name), "ref": weakref(node)})
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
