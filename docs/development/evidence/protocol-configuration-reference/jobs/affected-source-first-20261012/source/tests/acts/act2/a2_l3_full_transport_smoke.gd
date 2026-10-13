extends SceneTree
## Actual initial L3 complete transport and distinct fresh native restoration.
## No running combat, target defeat, earlier campaign seed or full route claim.
const Main: PackedScene = preload("res://scenes/main.tscn")
const Rules: Script = preload("res://scripts/acts/act2/ruined_house_smoke_rules.gd")
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
var _checks: int = 0
var _failures: int = 0
var _game: Node
var _whole: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_game = Main.instantiate()
	_game.set("level_scene_path", "res://scenes/acts/act2/a2_l3.tscn")
	root.add_child(_game)
	_game.call("resume_lab")
	await _settle(15)
	var level := _game.get("active_level") as CinderLevel
	var hero := _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(level) and is_instance_valid(hero) and level.level_id == "A2-L3" and String(level.get("runtime_error")).is_empty(), "actual authored L3 aggregate unit enters through shared Game"):
		await _release(); quit(1); return
	_expect(level.call("_capture_local_state").has("error"), "aggregate capture refuses an unpaused native unit")
	_expect(_game.call("request_pause_deferred"), "supported deferred full native pause requested")
	for ignored: int in range(3): await process_frame
	_expect(paused and not _game.call("is_pause_requested"), "complete native paused commit barrier settles")
	var player: Dictionary = hero.snapshot_state()
	_expect(not player.is_empty() and hero.snapshot_error(player).is_empty(), "same shared actor supplies its complete real paused snapshot")
	var local: Dictionary = level.call("_capture_local_state")
	var baseline: String = Exact.stringify(local)
	_expect(local.size() == 19 and local.has_all(["banks", "bank_views"]) and local.banks.size() == 3 and not baseline.is_empty(), "closed actual nineteen-field whole pack retains three complete published banks")
	_expect(local.targets.size() == 6 and local.rays.actors.size() == 1 and local.mechanisms.size() == 4, "actual six non-Ray targets/one Ray/four tools retain separate complete snapshots")
	var verdict: String = level.call("_whole_snapshot_error", local, player)
	_expect(verdict.is_empty(), "actual supported public nested snapshots and local coherence preflight: " + verdict)
	_expect(Rules.smoke_state_error(local).is_empty(), "pure local rules accept their actual prevalidated initial unit")
	var roundtrip: Dictionary = Exact.parse(baseline)
	_expect(roundtrip.accepted and Exact.stringify(roundtrip.value) == baseline, "exact JSON retains every actual aggregate scalar bit/type")
	_expect(level.call("_whole_snapshot_error", roundtrip.value, player).is_empty(), "exact decoded actual aggregate unit preflights without clock tolerance")
	_expect(not level.call("_saved_response_point_supported", Vector3(0.0, 0.1, -13.4)), "retained feet/attack point cannot occupy the actual low-wall Box")
	_expect(level.call("_saved_response_point_supported", Vector3(-2.0, 0.1, -13.4)), "actual broad left wall approach remains supported")
	_expect(level.call("_saved_response_point_supported", Vector3(2.0, 0.1, -13.4)), "actual broad right wall approach remains supported")
	_expect(not level.call("_saved_response_point_supported", Vector3(0.0, 0.45, -13.4)), "wall top is not a new raised traversal floor")
	_expect(level.call("_saved_response_point_supported", Vector3(1.52, 0.1, -12.90)), "actual capsule-clear north-east wall corner remains supported")
	_expect(level.call("_saved_response_point_supported", Vector3(-1.52, 0.1, -12.90)), "actual capsule-clear north-west wall corner remains supported")
	_expect(not level.call("_saved_response_point_supported", Vector3(1.40, 0.1, -13.02)), "actual rounded capsule still rejects a near wall corner overlap")
	_expect(not level.call("_saved_response_point_supported", Vector3(1.57, 0.1, -13.4)), "actual wall side excludes feet inside the retained capsule skin")
	var variants: Array[Dictionary] = []
	var changed: Dictionary = local.duplicate(true); changed["banks"] = {}; variants.append({"label": "missing all three supported bank snapshots", "state": changed})
	changed = local.duplicate(true); changed.world_revision = 2; variants.append({"label": "foreign authored world revision", "state": changed})
	changed = local.duplicate(true); changed.boss_ready_s = 0.1; variants.append({"label": "unearned boss cooldown", "state": changed})
	changed = local.duplicate(true); changed.boss_phase_pending = true; variants.append({"label": "unearned root phase intent", "state": changed})
	changed = local.duplicate(true); changed.targets.handling_machine.boss_phase = 2; variants.append({"label": "phase two health refill", "state": changed})
	changed = local.duplicate(true); changed.targets.house_tender.hp = 25.0; variants.append({"label": "damaged future Tender", "state": changed})
	changed = local.duplicate(true); changed.targets.erase("side_tender"); variants.append({"label": "missing optional real source", "state": changed})
	changed = local.duplicate(true); changed.mechanisms.erase("boss_place"); variants.append({"label": "missing alternate tool receipt", "state": changed})
	changed = local.duplicate(true); changed.targets.house_handler.root_position[0] += 1.0; variants.append({"label": "moved fixed housing", "state": changed})
	changed = local.duplicate(true); changed.completion_pending = true; variants.append({"label": "premature completion intent", "state": changed})
	changed = local.duplicate(true); changed.exit_requested = true; variants.append({"label": "premature contact exit", "state": changed})
	changed = local.duplicate(true); changed.pending_checkpoints.append("handling-machine-phase-two"); variants.append({"label": "unearned phase checkpoint", "state": changed})
	changed = local.duplicate(true); changed.views["boss_reach"] = {}; variants.append({"label": "view without running lease", "state": changed})
	changed = local.duplicate(true); changed.rays.clock_s = float(changed.rays.clock_s) + 0.000000001; variants.append({"label": "copied Ray clock drift", "state": changed})
	changed = local.duplicate(true); changed.banks.road_bank.configuration.geometry.radius = 1.04; variants.append({"label": "changed authored smoke radius", "state": changed})
	changed = local.duplicate(true); changed.banks.road_bank.clock_s += 0.000000001; variants.append({"label": "copied bank clock drift", "state": changed})
	changed = local.duplicate(true); changed.banks.house_bank.cycle = 1; variants.append({"label": "unearned future bank cycle", "state": changed})
	changed = local.duplicate(true); changed.banks.road_bank.contact_since_s = 0.0; variants.append({"label": "unearned idle exposure", "state": changed})
	changed = local.duplicate(true); changed.bank_views.road_bank = {}; variants.append({"label": "view without an actual running bank", "state": changed})
	changed = local.duplicate(true); changed.banks.road_bank.configuration.opening_position[0] += 0.01; variants.append({"label": "changed fixed Tender opening", "state": changed})
	for variant: Dictionary in variants:
		var error: String = level.call("_whole_snapshot_error", variant.state, player)
		_expect(not error.is_empty(), "strict refusal of " + variant.label)
		_expect(Exact.stringify(level.call("_capture_local_state")) == baseline and hero.snapshot_state() == player, "pure refusal leaves the actual native unit unchanged: " + variant.label)
	_whole = level.snapshot_state()
	_expect(not _whole.is_empty() and _whole.local == local and level.snapshot_error_with_player(_whole, player).is_empty(), "actual complete CinderLevel/progress pack validates with the complete saved Player")
	var whole_encoded: String = Exact.stringify(_whole)
	var whole_decoded: Dictionary = Exact.parse(whole_encoded)
	_expect(whole_decoded.accepted and Exact.stringify(whole_decoded.value) == whole_encoded, "exact whole level/progress transport retains every original bit and bank")
	_whole = whole_decoded.value
	_expect(hero.hp == 100.0 and hero.get_world_action_records().is_empty() and not level.is_completed() and level.current_checkpoint().id.is_empty(), "aggregate preflight grants no input/damage/defeat/checkpoint/completion")
	var original_refs: Array[Dictionary] = _unit_refs(level, hero)
	await _release()
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "actual aggregate/native cue subtree releases cleanly")
	var original_freed: bool = true
	var original_ids: Dictionary = {}
	for item: Dictionary in original_refs:
		original_freed = original_freed and item.reference.get_ref() == null
		original_ids[item.instance_id] = true
	_expect(original_freed, "original actual Game/Hero/seven targets/four tools/scenery/cues release before fresh receiver")
	# A separate real Main instance constructs every receiving native binding.
	# Reusing the actual initial snapshot creates no synthetic progress/phase.
	_game = Main.instantiate()
	_game.set("level_scene_path", "res://scenes/acts/act2/a2_l3.tscn")
	root.add_child(_game)
	_game.call("resume_lab")
	await _settle(15)
	var fresh_level := _game.get("active_level") as CinderLevel
	var fresh_hero := _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(fresh_level) and is_instance_valid(fresh_hero) and fresh_level.level_id == "A2-L3" and fresh_level.hero == fresh_hero and String(fresh_level.get("runtime_error")).is_empty(), "fresh actual Game constructs a second authored L3 aggregate unit"):
		await _release(); quit(1); return
	var fresh_distinct: bool = true
	for node: Node in _unit_nodes(fresh_level, fresh_hero):
		fresh_distinct = fresh_distinct and not original_ids.has(node.get_instance_id())
	_expect(fresh_distinct and fresh_level.get("_actors").size() == 7 and fresh_level.get("_mechanisms").size() == 4, "all fresh native Game/Hero/seven targets/four tools/cues/scenery have distinct identities")
	_expect(_game.call("request_pause_deferred"), "fresh receiver requests its own supported deferred full native pause")
	for ignored: int in range(3): await process_frame
	_expect(paused and not _game.call("is_pause_requested"), "fresh receiver reaches its own complete native paused commit barrier")
	var player_encoded: String = Exact.stringify(player)
	var player_decoded: Dictionary = Exact.parse(player_encoded)
	if not _expect(not player_encoded.is_empty() and player_decoded.get("accepted", false) and player_decoded.get("value") is Dictionary and Exact.stringify(player_decoded.value) == player_encoded, "exact JSON also retains the original complete real shared Hero snapshot"):
		await _release(); quit(1); return
	var saved_player: Dictionary = player_decoded.value
	var saved_local: Dictionary = roundtrip.value
	var events: Array[String] = []
	_observe_quiet(fresh_level, fresh_hero, events)
	var fresh_before: String = Exact.stringify(fresh_level.call("_capture_local_state"))
	var fresh_player_before: String = Exact.stringify(fresh_hero.snapshot_state())
	_expect(fresh_hero.snapshot_error(saved_player).is_empty(), "fresh shared Hero public preflight accepts the original complete paused actor")
	_expect(Exact.stringify(fresh_level.call("_capture_local_state")) == fresh_before and Exact.stringify(fresh_hero.snapshot_state()) == fresh_player_before and events.is_empty(), "fresh public actor preflight mutates no actual receiver or event")
	if not _expect(fresh_hero.restore_state(saved_player), "supported public quiet Hero restore precedes the local aggregate commit"):
		await _release(); quit(1); return
	_expect(Exact.stringify(fresh_hero.snapshot_state()) == player_encoded and events.is_empty(), "complete original Hero resources/equipment/motion/history/presentation restore exactly without events")
	var fresh_preflight: String = fresh_level.call("_whole_snapshot_error", saved_local, saved_player)
	_expect(fresh_preflight.is_empty(), "original real local snapshot preflights against all fresh native bindings: " + fresh_preflight)
	_expect(Exact.stringify(fresh_level.call("_capture_local_state")) == fresh_before and Exact.stringify(fresh_hero.snapshot_state()) == player_encoded and events.is_empty(), "fresh staged local preflight remains pure after actual Hero restoration")
	var restore_error: String = _restore_pack(fresh_level, saved_local)
	if not _expect(restore_error.is_empty(), "private local-aggregate quiet restore accepts its preflighted actual unit: " + restore_error):
		await _release(); quit(1); return
	_expect(Exact.stringify(fresh_level.call("_capture_local_state")) == baseline and Exact.stringify(fresh_hero.snapshot_state()) == player_encoded, "fresh native unit reconstructs the exact original local aggregates and complete shared Hero")
	var all_actor_snapshots_match: bool = true
	for id: String in fresh_level.get("_actors"):
		var actor: Node = fresh_level.get("_actors")[id]
		var actor_saved: Dictionary = saved_local.rays.actors[id] if id == "apron_scout" else saved_local.targets[id]
		all_actor_snapshots_match = all_actor_snapshots_match and Exact.stringify(actor.call("snapshot_state")) == Exact.stringify(actor_saved) and float(actor.get("hp")) == 30.0 and actor.get("phase") == "idle"
	_expect(all_actor_snapshots_match, "all seven actual initial HP30 idle actors retain their exact original anchored snapshots")
	var all_tools_initial: bool = true
	for id: String in fresh_level.get("_mechanisms"):
		var tool_state: Dictionary = fresh_level.get("_mechanisms")[id].call("state")
		all_tools_initial = all_tools_initial and tool_state.status == "idle" and tool_state.phase == "clear" and int(tool_state.cycle) == 0
	_expect(all_tools_initial and saved_local.views.is_empty(), "all four actual tools remain unstarted without invented lease/view/progression")
	_expect(events.is_empty() and fresh_hero.hp == float(saved_player.resources.hp) and fresh_hero.shells == int(saved_player.resources.shells) and fresh_hero.get_world_action_records().is_empty() and not fresh_level.is_completed() and fresh_level.current_checkpoint().id.is_empty(), "initial quiet aggregate restore publishes no gameplay/cue/phase/checkpoint events or resource changes")
	for repeat: int in range(2):
		var repeated_error: String = _restore_pack(fresh_level, saved_local)
		_expect(repeated_error.is_empty() and Exact.stringify(fresh_level.call("_capture_local_state")) == baseline and Exact.stringify(fresh_hero.snapshot_state()) == player_encoded and events.is_empty(), "repeated quiet local commit is exact and event-free: " + str(repeat))
	for variant: Dictionary in variants:
		var refused: String = _restore_pack(fresh_level, variant.state)
		_expect(not refused.is_empty(), "quiet local restore refuses malformed original aggregate tuple: " + variant.label)
		_expect(Exact.stringify(fresh_level.call("_capture_local_state")) == baseline and Exact.stringify(fresh_hero.snapshot_state()) == player_encoded and events.is_empty(), "malformed local restore refuses atomically before native state/resource/events: " + variant.label)
	_expect(Exact.stringify(fresh_level.snapshot_state()) == whole_encoded and fresh_level.snapshot_error_with_player(_whole, saved_player).is_empty(), "fresh actual full level/progress/three-bank snapshot exactly reconstructs the original whole pack")
	var fresh_refs: Array[Dictionary] = _unit_refs(fresh_level, fresh_hero)
	await _release()
	var fresh_freed: bool = true
	for item: Dictionary in fresh_refs: fresh_freed = fresh_freed and item.reference.get_ref() == null
	_expect(fresh_freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "fresh actual aggregate/native cue subtree releases without retained identity")
	print("A2-L3 full initial transport: %d checks, %d failures; actual whole level and fresh quiet restore, running combat/route untested" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _restore_pack(level: CinderLevel, local: Dictionary) -> String:
	var candidate: Dictionary = _whole.duplicate(true)
	candidate.local = local
	return "" if level.restore_state(candidate) else level.last_snapshot_error

func _observe_quiet(level: CinderLevel, hero: CinderPlayer, events: Array[String]) -> void:
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("action"))
	hero.fired.connect(func(_kind: String) -> void: events.append("fired"))
	hero.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: events.append("action-result"))
	hero.died.connect(func() -> void: events.append("death"))
	hero.equipment_changed.connect(func(_id: String) -> void: events.append("gear"))
	level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: events.append("checkpoint"))
	level.completion_requested.connect(func(_id: String, _completion: String) -> void: events.append("completion"))
	level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: events.append("exit"))
	_game.connect("input_observed", func(_record: Dictionary) -> void: events.append("input"))
	level.get("_scheduler").connect("reservation_invalidated", func(_id: String, _reason: String) -> void: events.append("cancel"))
	var driver: Node = level.get("_exchange")
	driver.connect("state_changed", func(_id: String, _state: Dictionary) -> void: events.append("ray-phase"))
	driver.connect("hit_resolved", func(_id: String, _hit: Dictionary) -> void: events.append("ray-hit"))
	driver.connect("scout_defeated", func(_id: String) -> void: events.append("ray-defeat"))
	for mechanism: Node in level.get("_mechanisms").values():
		mechanism.connect("state_changed", func(_state: Dictionary) -> void: events.append("tool-phase"))
		mechanism.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: events.append("tool-hit"))
	for bank: Node in level.get("_clouds").values():
		bank.connect("state_changed", func(_state: Dictionary) -> void: events.append("bank-phase"))
		bank.connect("tick_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: events.append("bank-tick"))
	for actor: Node in level.get("_actors").values():
		actor.connect("defeated", func(_id: String) -> void: events.append("target-defeat"))
		if actor.has_signal("phase_boundary_reached"):
			actor.connect("phase_boundary_reached", func(_id: String) -> void: events.append("boss-phase-boundary"))
	for cue: Node in get_nodes_in_group("required_cues"):
		if level.is_ancestor_of(cue) and cue.has_signal("state_changed"): cue.connect("state_changed", func(_state: Dictionary) -> void: events.append("required-cue"))
	for cue: Node in level.get("_opening_cues").values():
		cue.connect("state_changed", func(_state: Dictionary) -> void: events.append("opening"))
	for cue: Node in driver.get("_opening_cues").values():
		cue.connect("state_changed", func(_state: Dictionary) -> void: events.append("ray-opening"))
	level.get("_exit_cue").connect("state_changed", func(_state: Dictionary) -> void: events.append("exit-cue"))

func _unit_nodes(level: CinderLevel, hero: CinderPlayer) -> Array[Node]:
	var nodes: Array[Node] = [_game, level, hero, _game.get("fx") as Node, level.get("_scheduler") as Node, level.get("_exchange") as Node, level.get("_kit").root as Node, level.get_node("RuinedHouseDryGround"), level.get("_exit_cue") as Node]
	for actor: Node in level.get("_actors").values(): nodes.append(actor)
	for tool: Node in level.get("_mechanisms").values(): nodes.append(tool)
	for bank: Node in level.get("_clouds").values(): nodes.append(bank)
	for art: Node in level.get("_cloud_art").values(): nodes.append(art)
	for cue: Node in level.get("_opening_cues").values(): nodes.append(cue)
	for cue: Node in level.get("_exchange").get("_opening_cues").values(): nodes.append(cue)
	for cue: Node in get_nodes_in_group("required_cues"):
		if level.is_ancestor_of(cue): nodes.append(cue)
	return nodes

func _unit_refs(level: CinderLevel, hero: CinderPlayer) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	for node: Node in _unit_nodes(level, hero):
		refs.append({"label": str(node.name), "reference": weakref(node), "instance_id": node.get_instance_id()})
	return refs

func _release() -> void:
	if not is_instance_valid(_game): return
	var level := _game.get("active_level") as CinderLevel
	if is_instance_valid(level): level.exit_level()
	_game.get("fx").clear()
	paused = false
	await create_timer(0.15).timeout
	_game.queue_free()
	await _settle(3)

func _settle(count: int) -> void:
	for ignored: int in range(count): await physics_frame
	await process_frame

func _expect(ok: bool, label: String) -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL: " + label)
	return ok
