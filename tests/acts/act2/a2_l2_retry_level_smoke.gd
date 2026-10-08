extends "res://tests/acts/act2/a2_l2_live_level_smoke.gd"
## Real first two defeats, yard contact, isolated foot and apron paired pause.
## Full saved-player transport/preflight, actual source death and public retry.
## Inherited TEST ONLY preceding prefix/unlocks/profile/destination stay explicit.
## No live HP, ammo, transform, pose, death or progression is assigned.
## Scoped Standard two-source profile only; no final clear/native art claim.

const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const RETRY_CHECKPOINT_ID: String = "weybridge-yard-exit"
const RETRY_TOOL_ID: String = "tool_apron_handler"
const RETRY_FOOT_ID: String = "foot_apron"
const RETRY_PAIR_TARGET := Vector3(-0.45, 0.0, -13.2)
const RETRY_PAIR_REGION := Rect2(-0.65, -13.4, 0.4, 0.4)
var _fresh: Node

func _run() -> void:
	if not _read_options() or not _expect(_profile_id == "standard" and not _capture_live, "retry fixture selects Standard two-source state and owns no native art capture"):
		quit(1)
		return
	root.size = Vector2i(540, 1170)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_l1_fixture_bytes = FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn")
	_cleanup()
	print("Weybridge retry scope: Standard/%s; actual village/yard primary clears, yard contact, foot demo, apron Handler+foot pause/ExactJson/atomic validation, real source death/public retry; inherited TEST ONLY prefix/unlocks" % _loadout_name)
	var failures_before: int = _failures
	if not await _retry_route() and _failures == failures_before: _expect(false, "actual retry route aborted: " + _diagnostic())
	if is_instance_valid(_fresh): _release_fixture_receiver(_fresh)
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn") == _l1_fixture_bytes, "retry fixture preserves canonical registry and existing L1 fixture bytes")
	_cleanup()
	print("Weybridge authored retry smoke: %d checks, %d failures; real earned yard checkpoint and source damage, no forced state/final clear/native art or future-level acceptance" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _release_fixture_receiver(receiver: Node) -> void:
	var level: CinderLevel = receiver.get("active_level") as CinderLevel
	if is_instance_valid(level): level.exit_level()
	receiver.free()

func _retry_route() -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L2", "A2-L3"]:
			info.scene_path = LevelPath if info.id == "A2-L2" else NextPath
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty(), "isolated TEST ONLY registry preserves canonical links") or not await _seed(registry): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json"), "real retry shell uses isolated inherited save paths"): return false
	root.add_child(_game)
	await _settle()
	_game.menu.difficulty_preference_requested.emit(_profile_id)
	_game.resume_campaign()
	await _settle()
	if not _expect(_live() and paused, "actual Weybridge seed installs paused: " + _game.campaign_error): return false
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	_expect(hero.shells == 0 and hero.hp == hero.max_hp and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats), "normal initial HP and zero ammo with canonical selected gear/stats")
	_actors = level.get("_actors").duplicate()
	if not _expect(_actors.size() == 6 and not _contains_pickup(level), "actual L2 has six authored targets and no victory pickup"): return false
	var defeats: Array[String] = []
	var checkpoints: Array[String] = []
	var checkpoint_resources: Dictionary = {}
	var completions: Array[String] = []
	var exits: Array[String] = []
	for actor: Node in _actors.values(): actor.connect("defeated", func(id: String) -> void: defeats.append(id))
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append(checkpoint)
		_expect(kind == "encounter", "actual contact emits shared encounter boundary")
		if checkpoint == RETRY_CHECKPOINT_ID:
			checkpoint_resources["hp"] = hero.hp
			checkpoint_resources["shells"] = hero.shells
			checkpoint_resources["equipment"] = hero.equipment.snapshot()
	)
	level.completion_requested.connect(func(_id: String, id: String) -> void: completions.append(id))
	level.contact_exit_requested.connect(func(_id: String, id: String) -> void: exits.append(id))
	hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	_game.resume_campaign()
	var actions_before: int = _actions.size()
	await _retry_swipe(Vector2(0.70, 0.65), Vector2(0.64, 0.50))
	for frame: int in range(180):
		if _actions.size() > actions_before and _last_dash().get("kind") == "dash": break
		if not _live(): return false
		await _step()
	var anchor: Vector2 = _game.get_aim_anchor_normalized()
	if not _expect(_actions.size() > actions_before and anchor.is_equal_approx(Vector2(0.64, 0.50)), "real routed swipe establishes a nondefault final-release anchor and completed dash"): return false
	if not await _clear(["village_scout"]) or not await _clear(["yard_handler"]) or not await _contact("yard_exit", checkpoints): return false
	await _settle()
	var checkpoint: Dictionary = _game.attempts.state().story.checkpoint.duplicate(true)
	if not _expect(not checkpoint.is_empty() and checkpoint.level.progress.checkpoint_id == RETRY_CHECKPOINT_ID and checkpoints == [RETRY_CHECKPOINT_ID], "actual stable yard crossing durably records the first authored checkpoint"): return false
	_expect(checkpoint.level.local.sequence.defeated_ids == ["village_scout", "yard_handler"] and checkpoint.level.local.sequence.completed_feet.is_empty() and checkpoint.level.local.sequence.crossed_contacts == ["yard_exit"] and not checkpoint.level.progress.completed, "yard checkpoint holds only actual first two defeats/contact before foot teaching")
	_expect(checkpoint.player.resources.hp == checkpoint_resources.get("hp") and checkpoint.player.resources.shells == checkpoint_resources.get("shells") and checkpoint.equipment_ids == checkpoint_resources.get("equipment"), "yard checkpoint saves initiating real HP/ammo/gear without refill")
	_expect(checkpoint.shell.anchor_normalized == [anchor.x, anchor.y] and int(checkpoint.shell.input_sequence) > 0, "yard checkpoint retains actual routed input observer and release anchor")
	if paused: _game.resume_campaign()
	if not await _complete_foot("foot_demo") or not await _retry_navigate_pair(): return false
	_expect(_state().beat == "apron_pair" and defeats == ["village_scout", "yard_handler"], "real isolated foot completes before the living apron Handler+foot mixture")
	var warning: Dictionary = await _retry_pause_pair("warning", checkpoint)
	if warning.is_empty(): return false
	_game.resume_campaign()
	await _step()
	var locked: Dictionary = await _retry_pause_pair("lock", checkpoint)
	if locked.is_empty(): return false
	var hits: Array[Dictionary] = []
	var deaths: Array[String] = []
	for id: String in [RETRY_TOOL_ID, RETRY_FOOT_ID]:
		var mechanism: Node = level.get("_mechanisms")[id]
		mechanism.connect("hit_resolved", func(hero_id: String, cycle: int, result: Dictionary) -> void:
			if result.get("accepted", false): hits.append({"source_id": id, "hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true)})
		)
	hero.died.connect(func() -> void: deaths.append("actual-source-death"))
	_game.menu.difficulty_preference_requested.emit("challenge")
	_expect(_game.get_difficulty_preference() == "challenge" and _state().exchanges.apron_handler.resolved_role.difficulty_profile == "standard", "new public preference preserves current fixed Standard tool/foot role")
	var old_refs: Array[Dictionary] = _retry_old_refs(level, hero)
	var action_sequence: int = int(locked.player.world_actions.sequence)
	_game.resume_campaign()
	# The real accepted sources damage the stationary hero. No take_damage call,
	# HP assignment, emitted death, forced phase or extra navigation is used.
	for frame: int in range(7200):
		if hero.dead or not _live(): break
		await _step()
	await _settle()
	if not _expect(hero.dead and hero.hp == 0.0 and deaths == ["actual-source-death"] and not hits.is_empty() and paused and _game.campaign_error.is_empty(), "genuine required tool/foot damage causes death and synchronous shell pause: " + _diagnostic()): return false
	for hit: Dictionary in hits:
		var role: Dictionary = _expected_roles.tool if hit.source_id == RETRY_TOOL_ID else _expected_roles.foot
		_expect(hit.source_id in [RETRY_TOOL_ID, RETRY_FOOT_ID] and hit.hero_id == "hero" and float(hit.result.raw_damage) == float(role.damage) and float(hit.result.hp_damage) > 0.0, "death damage belongs to an actual fixed Standard source/cycle")
	var dead: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not dead.is_empty(), "dead actual L2 aggregate stays capturable: " + _game.campaign_error): return false
	var tool_phase: String = String(_state().mechanisms.tool_apron_handler.phase)
	_expect(_game.player.snapshot_error(dead.player).is_empty() and level.snapshot_error_with_player(dead.level, dead.player).is_empty() and dead.level.local.handlers.apron_handler.phase == ("idle" if tool_phase == "clear" else tool_phase) and dead.level.local.mechanisms.tool_apron_handler.clock_s == dead.level.local.scheduler.clock_s, "dead aggregate retains strict actual Handler phase/progress and exact source clock preflight")
	_expect(int(dead.player.world_actions.sequence) == action_sequence and defeats == ["village_scout", "yard_handler"] and completions.is_empty() and exits.is_empty() and checkpoints == [RETRY_CHECKPOINT_ID], "waiting for source death invents no action/HP defeat/checkpoint/completion/exit")
	_expect(Codec.same_values(_game.attempts.state().story.checkpoint, checkpoint) and _game.attempts.state().completed_main == PREFIX, "death preserves protected earned yard checkpoint and preceding campaign prefix")
	_game.request_retry()
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and paused and _game.menu.page_name() == "resume" and not _game.player.dead, "public death retry installs alive checkpoint and remains paused: " + _game.campaign_error): return false
	var retried: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not retried.is_empty() and ExactJson.stringify(retried) == ExactJson.stringify(checkpoint), "public retry restores entire exact authored yard aggregate"): return false
	_expect(retried.player.resources == checkpoint.player.resources and retried.equipment_ids == checkpoint.equipment_ids and retried.player.equipment == checkpoint.player.equipment, "retry restores exact saved HP/ammo/gear instead of fresh resources")
	_expect(retried.shell == checkpoint.shell and _game.get_aim_anchor_normalized() == anchor, "retry restores saved input/observer/camera and exact final release anchor")
	_expect(retried.level.local.profile_id == "standard" and _game.get_difficulty_preference() == "challenge" and Codec.same_values(retried.level.local.rays.configuration.resolved_role, _expected_roles.ray), "retry restores fixed saved Standard profile despite newer Challenge preference")
	for entry: Dictionary in old_refs: _expect((entry.ref as WeakRef).get_ref() == null, "retry frees old actual " + String(entry.label))
	_expect(_state().beat == "foot_demo" and retried.level.local.sequence.completed_feet.is_empty() and _game.attempts.state().completed_main == PREFIX and _game.attempts.state().reward_ids.is_empty() and not _game.active_level.is_completed(), "retry resumes uncleared foot teaching without extra progression/rewards")
	_expect(float(retried.level.local.handlers.apron_handler.hp) == 30.0 and checkpoints == [RETRY_CHECKPOINT_ID] and defeats == ["village_scout", "yard_handler"] and completions.is_empty() and exits.is_empty(), "retry retains actual untouched apron Handler and no final clear or shelter exit")
	return true

func _retry_pause_pair(phase: String, checkpoint: Dictionary) -> Dictionary:
	var found: bool = false
	for frame: int in range(900):
		if not _live(): break
		if _retry_pair_phase(_state(), phase): found = true; break
		await _step()
	if not _expect(found, "actual apron foot reaches %s beside living armed Handler: %s" % [phase, _diagnostic()]): return {}
	_game.request_pause()
	await _settle()
	var saved: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(paused and _game.campaign_error.is_empty() and not saved.is_empty() and _retry_pair_phase(_state(), phase), "public pause preserves actual apron " + phase + " tuple: " + _game.campaign_error): return {}
	var local: Dictionary = saved.level.local
	var clock: float = float(local.scheduler.clock_s)
	_expect(local.rays.clock_s == clock, "paused mixed aggregate shares exact ray/scheduler clock")
	for id: String in [RETRY_TOOL_ID, RETRY_FOOT_ID]:
		var consumer: Dictionary = local.mechanisms[id]
		_expect(consumer.clock_s == clock and consumer.hero_samples.hero.clock_s == clock and Codec.same_values(consumer.hero_samples.hero.position, saved.player.motion.position), "paused actual mechanism samples match authoritative hero position/clock: " + id)
		var expected: Dictionary = _expected_roles.tool if id == RETRY_TOOL_ID else _expected_roles.foot
		_expect(is_equal_approx(float(consumer.exchange.active_from_s) - float(consumer.exchange.lock_from_s), float(expected.lock_s)) and float(expected.lock_s) >= 1.1, "actual paused source preserves full resolved lock: " + id)
		var mechanism: Node = _game.active_level.get("_mechanisms")[id]
		var cue: Node3D = mechanism.call("get_cue") as Node3D
		var cue_state: Dictionary = cue.call("state")
		_expect(cue.is_visible_in_tree() and cue_state.phase == consumer.phase and cue_state.source_visible and cue_state.footprint_visible == (consumer.phase != "recovery") and cue_state.active_fill_visible == (consumer.phase == "active"), "actual shared source/footprint presentation follows its warning/lock/active/recovery state: " + id)
	_expect(local.views.foot_apron.target_id == "apron_handler" and local.mechanisms.foot_apron.exchange.opening_position == local.handlers.apron_handler.root_position and local.views.foot_apron.equipment_ids == _loadout, "paused foot binds the actual low Handler opening/admission gear")
	var before: String = ExactJson.stringify(saved)
	var events: Array[String] = []
	_retry_observe(_game.active_level, _game.player, events)
	_expect(_game.player.snapshot_error(saved.player).is_empty() and _game.active_level.snapshot_error_with_player(saved.level, saved.player).is_empty(), "pure full saved-player preflight accepts actual " + phase + " tuple")
	_expect(ExactJson.stringify(_game.capture_campaign_snapshot()) == before and events.is_empty(), "accepted pure preflight preserves actual components/events")
	_expect(_game.player.snapshot_error(checkpoint.player).is_empty() and not _game.active_level.snapshot_error_with_player(saved.level, checkpoint.player).is_empty(), "individually valid yard player rejects mismatched apron samples")
	await _settle()
	_expect(ExactJson.stringify(_game.capture_campaign_snapshot()) == before and events.is_empty(), "paused render frames freeze whole actual paired aggregate exactly")
	var decoded: Dictionary = ExactJson.parse(before)
	if not _expect(not before.is_empty() and decoded.get("accepted", false) and decoded.get("value") is Dictionary, "exact-json-1 transports actual mixed aggregate: " + String(decoded.get("reason", ""))): return {}
	var transported: Dictionary = decoded.value
	_expect(ExactJson.stringify(transported) == before and transported.level.local.scheduler.clock_s == clock, "transport retains exact scalar bits/native types/clock")
	if not _retry_corruptions(transported, checkpoint, events): return {}
	if phase == "warning" and not _retry_fresh_preflight(transported): return {}
	_expect(_game.player.snapshot_error(transported.player).is_empty() and _game.active_level.snapshot_error_with_player(transported.level, transported.player).is_empty(), "complete preflight precedes ordered actual restore")
	_expect(_game.player.restore_state(transported.player) and _game.active_level.restore_state(transported.level) and String(_game.active_level.get("runtime_error")).is_empty(), "quiet paused player then level restore commits actual tuple")
	_expect(ExactJson.stringify(_game.capture_campaign_snapshot()) == before and events.is_empty(), "actual quiet restore retains exact full tuple with no phase/hit/action/progression events")
	_expect(Codec.same_values(_game.attempts.state().story.checkpoint, checkpoint), "ordinary paired pause/restore cannot replace earned yard retry checkpoint")
	print("Weybridge retry checked actual paused ", phase, " Handler=", local.mechanisms.tool_apron_handler.phase, " foot=", local.mechanisms.foot_apron.phase)
	return transported

func _retry_pair_phase(state: Dictionary, phase: String) -> bool:
	if state.get("beat") != "apron_pair" or state.get("foot_id") != RETRY_FOOT_ID: return false
	var tool: Dictionary = state.mechanisms[RETRY_TOOL_ID]
	var foot: Dictionary = state.mechanisms[RETRY_FOOT_ID]
	# This reports each actual tuple; it does not imply two simultaneous locks.
	return tool.status == "running" and tool.phase in ["warning", "lock", "active", "recovery"] and foot.status == "running" and foot.phase == phase and _reservation(String(tool.reservation_id)).get("armed", false)

func _retry_corruptions(saved: Dictionary, checkpoint: Dictionary, events: Array[String]) -> bool:
	var before: String = ExactJson.stringify(_game.capture_campaign_snapshot())
	var model_before: String = ExactJson.stringify(_game.attempts.state())
	for index: int in range(8):
		var forged: Dictionary = saved.duplicate(true)
		var label: String = ""
		match index:
			0:
				forged.level.progress.checkpoint_id = "unearned"
				forged.level.progress.checkpoint_ids["unearned"] = "encounter"
				label = "unearned checkpoint history"
			1:
				forged.level.local.views.foot_apron.response_complete_s = forged.level.local.views.foot_apron.primary_time_s
				label = "missing complete primary cadence"
			2:
				forged.level.local.views.foot_apron.landing = [50.0, 0.0, -13.2]
				label = "off-floor accepted landing"
			3:
				forged.level.local.views.foot_apron.attack_position = [-50.0, 0.0, -13.2]
				label = "off-floor ordinary opening approach"
			4:
				forged.level.local.mechanisms.foot_demo.status = "cancelled"
				forged.level.local.mechanisms.foot_demo.last_cancel_reason = "test-forged-earn"
				label = "canceled receipt for earned foot demo"
			5:
				forged.level.local.views.foot_apron.target_id = ""
				label = "missing living counterpart custody"
			6:
				var current: float = float(forged.level.local.handlers.apron_handler.phase_progress)
				forged.level.local.handlers.apron_handler.phase_progress = current + 0.25 if current < 0.5 else current - 0.25
				label = "locally valid Handler progress mismatched to exact source clock"
			7:
				forged.level.local.mechanisms.foot_apron.hero_samples.hero.position = checkpoint.player.motion.position.duplicate()
				label = "mismatched authoritative hero sample"
		var error: String = _game.active_level.snapshot_error_with_player(forged.level, forged.player)
		if index == 4 and not _expect(error == "Earned L2 foot requires its actual finished cycle receipt", "completed isolated foot rejects a locally coherent canceled receipt at the earned-stage crosscheck"): return false
		if index == 6 and not _expect(_actors.apron_handler.call("snapshot_error", forged.level.local.handlers.apron_handler).is_empty() and error == "L2 Handler progress differs from its actual saved tool clock", "finite valid actor pose rejects only its mixed-consumer clock mismatch"): return false
		var refused: bool = not error.is_empty() and not _game.active_level.restore_state(forged.level) and not _game.attempts.record_snapshot(forged)
		if not _expect(refused and ExactJson.stringify(_game.capture_campaign_snapshot()) == before and ExactJson.stringify(_game.attempts.state()) == model_before and events.is_empty(), "complete atomic refusal before mutation/events: " + label): return false
	var crossed: Dictionary = saved.duplicate(true)
	crossed.player = checkpoint.player.duplicate(true)
	crossed.shell = checkpoint.shell.duplicate(true)
	return _expect(_game.player.snapshot_error(crossed.player).is_empty() and not _game.active_level.snapshot_error_with_player(crossed.level, crossed.player).is_empty() and not _game.attempts.record_snapshot(crossed) and ExactJson.stringify(_game.capture_campaign_snapshot()) == before and ExactJson.stringify(_game.attempts.state()) == model_before and events.is_empty(), "whole model rejects cross-forged valid player/apron tuple atomically")

func _retry_fresh_preflight(saved: Dictionary) -> bool:
	_fresh = MainScene.instantiate()
	_fresh.set_script(ProfileSeedGame)
	_fresh.set("test_profile_id", "standard")
	_fresh.set("level_scene_path", LevelPath)
	root.add_child(_fresh)
	paused = true
	var hero: CinderPlayer = _fresh.get("player") as CinderPlayer
	var level: CinderLevel = _fresh.get("active_level") as CinderLevel
	var before: Dictionary = {"player": hero.snapshot_state(), "level": level.snapshot_state()}
	var events: Array[String] = []
	_retry_observe(level, hero, events)
	if not _expect(not before.player.is_empty() and not before.level.is_empty() and not hero.global_position.is_equal_approx(Codec.read_vector3(saved.player.motion.position)), "fresh receiver remains at its actual different idle spawn"): return false
	_expect(hero.snapshot_error(saved.player).is_empty() and level.snapshot_error_with_player(saved.level, saved.player).is_empty(), "fresh pure staged-player preflight accepts actual saved Handler/foot tuple")
	_expect(ExactJson.stringify({"player": hero.snapshot_state(), "level": level.snapshot_state()}) == ExactJson.stringify(before) and events.is_empty(), "fresh pure proof changes no hero/actor/consumer/clock/gear/event")
	_expect(hero.restore_state(saved.player) and level.restore_state(saved.level) and String(level.get("runtime_error")).is_empty(), "fresh ordered paused player then level commit succeeds")
	_expect(ExactJson.stringify(hero.snapshot_state()) == ExactJson.stringify(saved.player) and ExactJson.stringify(level.snapshot_state()) == ExactJson.stringify(saved.level) and events.is_empty(), "fresh restore reconstructs exact mixed phases/samples/deadlines quietly")
	level.exit_level()
	_fresh.free()
	_fresh = null
	return true

func _retry_observe(level: CinderLevel, hero: CinderPlayer, events: Array[String]) -> void:
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("action"))
	hero.died.connect(func() -> void: events.append("death"))
	hero.equipment_changed.connect(func(_id: String) -> void: events.append("gear"))
	level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: events.append("checkpoint"))
	level.completion_requested.connect(func(_id: String, _completion: String) -> void: events.append("completion"))
	level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: events.append("exit"))
	level.get_node("WeybridgeThreatScheduler").connect("reservation_invalidated", func(_id: String, _reason: String) -> void: events.append("cancel"))
	level.get_node("ReusedRayExchanges").connect("state_changed", func(_id: String, _state: Dictionary) -> void: events.append("ray-phase"))
	level.get_node("ReusedRayExchanges").connect("hit_resolved", func(_id: String, _hit: Dictionary) -> void: events.append("ray-hit"))
	for mechanism: Node in level.get("_mechanisms").values():
		mechanism.connect("state_changed", func(_state: Dictionary) -> void: events.append("mechanism-phase"))
		mechanism.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: events.append("mechanism-hit"))
	for actor: Node in level.get("_actors").values(): actor.connect("defeated", func(_id: String) -> void: events.append("defeat"))
	for cue: Node in level.get("_opening_cues").values(): cue.connect("state_changed", func(_state: Dictionary) -> void: events.append("opening"))

func _retry_old_refs(level: Node, hero: Node) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	var nodes: Array[Node] = [level, hero, _game.fx, level.get_node("ReusedRayExchanges"), level.get_node("WeybridgeThreatScheduler"), level.get_node("DryGround"), level.get_node("WeybridgeSceneryKit"), level.get_node("OneVisibleGiantFoot"), level.get_node("WeybridgeSceneryKit/DistantArtilleryTripodCollapse")]
	for actor: Node in _actors.values(): nodes.append(actor)
	for mechanism: Node in level.get("_mechanisms").values(): nodes.append(mechanism)
	for witness: Node in level.get_node("WeybridgeSceneryKit").find_children("NonhostileWitness_*", "Node3D", false, false): nodes.append(witness)
	for cue: Node in get_nodes_in_group("required_cues"):
		if level.is_ancestor_of(cue): nodes.append(cue)
	for node: Node in nodes: refs.append({"label": String(node.name), "ref": weakref(node)})
	return refs

func _retry_navigate_pair() -> bool:
	for attempt: int in range(4):
		if not _live(): return _expect(false, "live encounter stopped before actual paired landing: " + _diagnostic())
		var hero: CinderPlayer = _game.player
		var start: Vector3 = hero.global_position
		var landing: Variant = _last_dash().get("landing")
		if RETRY_PAIR_REGION.has_point(Vector2(start.x, start.z)):
			return _expect(landing is Vector3 and landing.y > -0.05 and RETRY_PAIR_REGION.has_point(Vector2(landing.x, landing.z)) and _retry_plan_clear(start, start), "actual supported completed dash lands inside both authored apron source footprints")
		var distance: float = float(hero.stats.dash_distance)
		var target := Vector3(RETRY_PAIR_TARGET.x, start.y, RETRY_PAIR_TARGET.z)
		var offset: Vector3 = target - start
		var span: float = offset.length()
		var direct: Vector3 = start + offset.normalized() * distance
		if RETRY_PAIR_REGION.has_point(Vector2(direct.x, direct.z)) and _retry_plan_clear(start, direct):
			if not await _dash(offset.normalized()): return false
			continue
		var waypoint: Vector3 = Vector3.INF
		if span > 0.0 and span <= 2.0 * distance:
			var midpoint: Vector3 = (start + target) * 0.5
			var perpendicular := Vector3(-offset.z, 0.0, offset.x) / span
			var height: float = sqrt(maxf(distance * distance - span * span * 0.25, 0.0))
			for side: float in [-1.0, 1.0]:
				var candidate: Vector3 = midpoint + perpendicular * height * side
				if _retry_plan_clear(start, candidate) and _retry_plan_clear(candidate, target) and (not waypoint.is_finite() or absf(candidate.x) < absf(waypoint.x)):
					waypoint = candidate
		if waypoint.is_finite():
			if not await _dash((waypoint - start).normalized()): return false
			# Re-aim from the real first landing; keep collision and engine rounding.
			var actual: Vector3 = _game.player.global_position
			var final_direction := Vector3(RETRY_PAIR_TARGET.x - actual.x, 0.0, RETRY_PAIR_TARGET.z - actual.z).normalized()
			if not await _dash(final_direction): return false
		elif not await _navigate_dash(target): return false
	var final_position: Vector3 = _game.player.global_position
	var final_landing: Variant = _last_dash().get("landing")
	return _expect(RETRY_PAIR_REGION.has_point(Vector2(final_position.x, final_position.z)) and final_landing is Vector3 and final_landing.y > -0.05 and RETRY_PAIR_REGION.has_point(Vector2(final_landing.x, final_landing.z)) and _retry_plan_clear(final_position, final_position), "bounded actual dashes end at supported apron paired landing: " + _diagnostic())

func _retry_plan_clear(start: Vector3, finish: Vector3) -> bool:
	var hero: CinderPlayer = _game.player
	var collision: CollisionShape3D = hero.get_node("BodyCollision") as CollisionShape3D
	var radius: float = float((collision.shape as CapsuleShape3D).radius) + 0.01
	var supported: bool = false
	var excluded: Array[RID] = [hero.get_rid()]
	for floor: Dictionary in _game.active_level.call("floor_regions"):
		excluded.append((floor.body as StaticBody3D).get_rid())
		var rect: Rect2 = (floor.safe_rect as Rect2).grow(-radius)
		if rect.has_point(Vector2(start.x, start.z)) and rect.has_point(Vector2(finish.x, finish.z)): supported = true
	if not supported: return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	var virtual_pose: Transform3D = collision.global_transform
	virtual_pose.origin += start - hero.global_position
	query.transform = virtual_pose
	query.motion = finish - start
	query.collision_mask = 1
	query.margin = 0.001
	query.exclude = excluded
	# TEST ONLY planner excludes floor RIDs from the cast. Real shared-player
	# dashes retain every collider; actual completed landings remain authoritative.
	if query.motion == Vector3.ZERO: return hero.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
	var cast: PackedFloat32Array = hero.get_world_3d().direct_space_state.cast_motion(query)
	return cast.size() == 2 and cast[0] == 1.0

func _retry_swipe(from_normalized: Vector2, to_normalized: Vector2) -> void:
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
