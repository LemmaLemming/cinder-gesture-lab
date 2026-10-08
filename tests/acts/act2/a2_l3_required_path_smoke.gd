extends "res://tests/acts/act2/a2_l3_live_level_smoke.gd"
## Separate actual required-only L3 branch. Original all-seven tests stay intact.
## Copied parent _run_route at SHA256 0d3feb4641b0493528e0813cb7d57911cdf9b460dc54edf57d6e76c775a5dadd.
## Differences: omit only side-Tender clear; six defeats, two defeated-Tender
## tails, logical minimum seven primary hits; omit optional bank's all4-phase
## requirement. Add native HP30 after each primary/tick/completion/exit, exact
## completed aggregate/protected earned15HP checkpoint and quiet-bank checks.
## All actual controls/proofs/timeouts/checkpoints/route/cleanup are inherited.
## No live HP/phase/clock/pose/source-hiding seed; no blast/ammo/pickup grant.
## Only inherited prior campaign prefix/unlocks/profile/L4 fixture are TEST ONLY.
## This fixture owns no portraits or road-only selector and has not run yet.

const RequiredExact: Script = preload("res://scripts/campaign/exact_json.gd")
var _required_primary_observations: Array[Dictionary] = []
var _required_side_damage_seen: bool = false
var _required_completion_banks: Dictionary = {}
var _required_running_bank_checks: int = 0

func _read_options() -> bool:
	return super._read_options() and _expect(not _capture_live and not _road_only, "required-only full route requests no portrait or road-only scope")

func _run_route() -> bool:
	print("Required L3 path: six real defeats; Side Tender remains HP30/unhit, no optional clear; inherited actual controls/proofs and TEST ONLY prefix/L4 destination")
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L3", "A2-L4"]:
			info.scene_path = HOUSE_SCENE if info.id == "A2-L3" else HOUSE_DESTINATION
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L4").is_empty(), "injected TEST ONLY L4 destination has matching exported identity/contract") or not await _seed(registry): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, HOUSE_TEST_ROOT + "campaign.json", HOUSE_TEST_ROOT + "settings.json", HOUSE_TEST_ROOT + "preferences.json"), "actual shell accepts isolated test registry/save paths"): return false
	root.add_child(_game)
	await _settle()
	_game.menu.difficulty_preference_requested.emit(_profile_id)
	_game.resume_campaign()
	await _settle()
	if not _expect(_live() and _game.active_level.scene_file_path == HOUSE_SCENE, "actual shell installs authored L3: " + _game.campaign_error): return false
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	var installed: Dictionary = level.snapshot_state()
	if not _expect(not installed.is_empty() and installed.local.get("profile_id") == _profile_id and _state().smoke_api_ready, "actual whole L3 snapshot and published bank hookup retain the chosen fixed profile"): return false
	if not _expect(hero.presentation_id == "act2_survivor" and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats) and hero.shells == 0, "actual L3 entry retains shared Act2 presentation/canonical gear/stats and initial zero ammo"): return false
	if _loadout_name == "heavy": _expect(is_equal_approx(float(hero.stats.primary_range), 1.8), "Heavy uses actual shortest shared primary reach")
	_actors = level.get("_actors").duplicate()
	_banks = level.get("_clouds").duplicate()
	if not _expect(_actors.size() == 7 and _banks.size() == 3 and level.get("_mechanisms").size() == 4 and not _contains_pickup(level), "seven actual HP sources, three independent banks and four stationary tools; no victory pickups"): return false
	for id: String in _actors:
		_expect(_actors[id].get("hp") == 30.0 and _actors[id].get("max_hp") == 30.0 and _actors[id].global_position == HouseSequence.ACTORS[id], "actual stationary source retains authored HP30/origin: " + id)
	for id: String in _banks:
		var bank: Node3D = _banks[id]
		_expect(bank.get_script() == SmokeBank and bank.get_parent() == level and bank.global_position == HouseSequence.CLOUDS[id], "published bank is an independent fixed level child: " + id)
	var defeats: Array[String] = []
	for actor: Node in _actors.values():
		actor.connect("defeated", func(id: String) -> void:
			defeats.append(id)
			_observe_defeat(id)
		)
	_actors.handling_machine.connect("phase_boundary_reached", func(_id: String) -> void:
		var boss: Node = _actors.handling_machine
		_boundary_records.append({"hp": boss.get("hp"), "max_hp": boss.get("max_hp"), "boss_phase": boss.get("boss_phase"), "transition_pending": boss.get("transition_pending"), "beat": _state().beat, "action_count": _actions.size()})
	)
	var checkpoints: Array[String] = []
	var completions: Array[String] = []
	var exits: Array[String] = []
	var resources_at_exit: Dictionary = {}
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append(checkpoint)
		_expect(kind == ("boss_phase" if checkpoint == "handling-machine-phase-two" else "encounter"), "actual checkpoint retains its authored contact/phase kind")
	)
	level.completion_requested.connect(func(_id: String, completion: String) -> void:
		completions.append(completion)
		_required_completion_banks.clear()
		for id: String in _banks:
			var current: Dictionary = _banks[id].call("state")
			_required_completion_banks[id] = current.duplicate(true)
			_expect(current.status != "running" and current.phase == "clear", "actual completion callback occurs only after a supported quiet bank: " + id)
		_expect(_actors.side_tender.get("hp") == 30.0 and not defeats.has("side_tender"), "required completion retains the living optional Tender without a defeat")
	)
	level.contact_exit_requested.connect(func(_id: String, exit_id: String) -> void:
		exits.append(exit_id)
		resources_at_exit["hp"] = hero.hp
		resources_at_exit["shells"] = hero.shells
		resources_at_exit["equipment"] = hero.equipment.snapshot()
		resources_at_exit["side_tender_hp"] = _actors.side_tender.get("hp")
		_expect(_actors.side_tender.get("hp") == 30.0 and not defeats.has("side_tender"), "actual breakout leaves the optional Tender alive until the old unit is released")
	)
	hero.world_action_executed.connect(func(record: Dictionary) -> void:
		_actions.append(record.duplicate(true))
		_observe_wall_path(record)
		if record.kind == "primary":
			var side_hp: float = float(_actors.side_tender.get("hp"))
			_required_primary_observations.append({"sequence": record.sequence, "side_hp": side_hp, "side_max_hp": _actors.side_tender.get("max_hp")})
			if side_hp != 30.0: _required_side_damage_seen = true
			_expect(side_hp == 30.0 and _actors.side_tender.get("max_hp") == 30.0, "every delivered ordinary primary leaves the optional Tender HP30 with no accepted primary damage")
	)
	_game.resume_campaign()
	if not await _clear(["road_tender"]): return false
	if _road_only:
		print("Road-only actual primary scope: ", _state(), " actions=", _actions.size())
		return _expect(defeats == ["road_tender"] and _state().beat == "clear_ground", "focused road encounter ends through actual ordinary primary")
	_expect(defeats == ["road_tender"] and _state().beat == "clear_ground" and checkpoints.is_empty(), "first real Tender defeat precedes separate clear-ground contact")
	if not await _contact("clear_ground", checkpoints): return false
	if not await _clear(["house_tender"]) or not await _broadside_wall() or not await _clear(["house_handler"]): return false
	_expect(_wall_bypass_seen and _state().beat == "wall_opening" and defeats.slice(0, 3) == ["road_tender", "house_tender", "house_handler"], "actual Tender/Handler kills and capsule-clear side dash earn the ruined-house opening")
	if not await _contact("wall_opening", checkpoints) or not await _clear(["apron_scout", "apron_handler"]): return false
	_expect(defeats.size() == 5 and defeats.has("apron_scout") and defeats.has("apron_handler") and _state().beat == "boss_entry", "familiar Ray/Handler are actually defeated before boss-entry contact")
	if not await _contact("boss_entry", checkpoints) or not await _advance_boss_phase(checkpoints): return false
	# Branch difference: skip only the optional source's clear. Its real bank
	# may still require inherited escape proofs; never attack it deliberately.
	if not await _clear(["handling_machine"]): return false
	for frame: int in range(600):
		if not _live(): return false
		if level.is_completed(): break
		await _step()
	var expected_checkpoints: Array[String] = []
	for contact: String in HOUSE_CONTACT_ORDER: expected_checkpoints.append(HouseSequence.CONTACTS[contact].checkpoint)
	expected_checkpoints.append("handling-machine-phase-two")
	_expect(checkpoints == expected_checkpoints and level.current_checkpoint().id == expected_checkpoints.back(), "three real contact checkpoints then exact HP phase checkpoint commit once in order")
	_expect(defeats.size() == 6 and defeats.slice(0, 3) == ["road_tender", "house_tender", "house_handler"] and defeats.slice(3, 5).has("apron_scout") and defeats.slice(3, 5).has("apron_handler") and defeats[5] == "handling_machine" and not defeats.has("side_tender"), "exactly the six required sources are defeated while the optional side Tender remains alive")
	_expect(_actors.handling_machine.get("hp") == 0.0 and _actors.handling_machine.get("max_hp") == 30.0 and _actors.handling_machine.get("boss_phase") == 2 and _boundary_records.size() == 1, "B02 keeps one totalHP30 and one earned15HP boundary before local arm disengagement")
	_expect(_tail_pending.is_empty() and _tail_completed.size() == 2 and _tail_completed.has("road_bank") and _tail_completed.has("house_bank") and not _tail_completed.has("boss_bank"), "the two actually defeated Tenders finish their original tails; the living side source earns no defeat-tail receipt")
	_expect(not _required_side_damage_seen and _actors.side_tender.get("hp") == 30.0 and _actors.side_tender.get("max_hp") == 30.0 and not _required_primary_observations.is_empty(), "all native ticks/primary observations preserve optional Tender HP30 with no accepted hit or defeat")
	_expect(not _boss_hits.is_empty() and _boss_hits[0].before == 30.0 and _boss_hits[0].after == 15.0 and _boss_hits[0].phase == 1 and _boss_hits[-1].after == 0.0 and _boss_hits[-1].phase == 2, "actual ordinary primaries cross the genuine protected15HP phase checkpoint before required boss HP0")
	_expect(_required_completion_banks.size() == 3, "one required completion observes all three actual quiet banks without granting a new cycle")
	_expect(_state().beat == "clear" and _state().exit_open and level.is_completed() and completions == ["ruined-house-escape"] and exits.is_empty(), "actual local arm disable/tails complete once before separate breakout contact")
	for source: String in ["road_bank", "house_bank", "tool_house_handler", "tool_apron_handler", "apron_scout", "boss_reach", "boss_place"]:
		for phase: String in ["warning", "lock", "active", "recovery"]:
			_expect(_native_phases.get(source, {}).has(phase), "actual native %s observed %s" % [source, phase])
	if _capture_live:
		# Combat is clear; normal render settling here cannot delay a proof.
		for settle_frame: int in range(8):
			if not _capture_pending and _captured.has("clear"): break
			await process_frame
		for family: String in ["smoke", "tool", "ray", "boss-reach", "boss-place"]:
			for phase: String in ["warning", "lock", "active", "recovery"]:
				_expect(_captured.has(family + "-" + phase), "actual native source/phase capture exists: " + family + "-" + phase)
		_expect(_captured.has("clear"), "actual native local-arm-clear capture exists")
	_game.request_pause()
	await _settle()
	var aggregate: Dictionary = _game.capture_campaign_snapshot()
	_expect(not aggregate.is_empty() and _game.campaign_error.is_empty() and _game.attempts.state().completed_main == HOUSE_PREFIX + ["A2-L3"] and aggregate.level.progress.contact_exit_id.is_empty(), "actual paused shell records L3 completion with distinct unopened breakout: " + _game.campaign_error)
	if not aggregate.is_empty():
		_expect(aggregate.level.local.sequence.crossed_contacts == HOUSE_CONTACT_ORDER and aggregate.level.local.sequence.defeated_ids.size() == 6 and not aggregate.level.local.sequence.defeated_ids.has("side_tender") and aggregate.level.local.sequence.boss_phase == 2 and aggregate.level.local.targets.side_tender.hp == 30.0 and aggregate.level.local.targets.side_tender.max_hp == 30.0, "actual completed aggregate retains six earned defeats/three contacts/two-stage machine and living optional Tender HP30")
		_expect(hero.snapshot_error(aggregate.player).is_empty() and level.snapshot_error_with_player(aggregate.level, aggregate.player).is_empty() and RequiredExact.stringify(hero.snapshot_state()) == RequiredExact.stringify(aggregate.player) and RequiredExact.stringify(level.snapshot_state()) == RequiredExact.stringify(aggregate.level), "supported paused full Player/level aggregate preflights and matches both actual independent native units exactly")
		for bank_id: String in aggregate.level.local.banks:
			_expect(aggregate.level.local.banks[bank_id].status != "running" and aggregate.level.local.banks[bank_id].phase == "clear", "completed paused aggregate preserves supported quiet bank state: " + bank_id)
		var checkpoint: Dictionary = _game.attempts.state().story.checkpoint
		_expect(checkpoint.level.progress.checkpoint_id == "handling-machine-phase-two" and checkpoint.level.progress.checkpoint_kind == "boss_phase" and checkpoint.level.local.targets.handling_machine.actor.hp == 15.0 and checkpoint.level.local.targets.handling_machine.boss_phase == 2 and checkpoint.level.local.sequence.stage_index == 7 and checkpoint.level.local.sequence.defeated_ids.size() == 5 and checkpoint.level.local.targets.side_tender.hp == 30.0 and not checkpoint.level.progress.completed, "completion protects the actually earned HP15/stage7 checkpoint with living optional Tender and no fabricated phase transition")
	var primary_hits: int = 0
	var dashes: int = 0
	for action: Dictionary in _actions:
		_expect(action.kind != "blast" and action.equipment_ids == _loadout and Codec.same_values(action.resolved_stats, _expected_stats), "real actions use unchanged canonical gear/stats and no blast")
		if action.kind == "primary": primary_hits += int(action.hits)
		elif action.kind == "dash": dashes += 1
	_expect(primary_hits >= 7 and dashes > 0 and hero.equipment.snapshot() == _loadout, "ordinary shared primaries and real sampled dashes supply six required targets and both15HP boss pools without an optional hit")
	var old_nodes: Array[Node] = [level, hero, _game.fx, level.get_node("RuinedHouseDryGround"), level.get_node("RuinedHouseSceneryKit")]
	for node: Node in _actors.values(): old_nodes.append(node)
	for node: Node in _banks.values(): old_nodes.append(node)
	for node: Node in level.get("_mechanisms").values(): old_nodes.append(node)
	for cue: Node in get_nodes_in_group("required_cues"):
		if level.is_ancestor_of(cue): old_nodes.append(cue)
	_game.resume_campaign()
	if not await _dash_to_exit(): return false
	await _settle()
	_expect(_game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L4" and _game.active_level.scene_file_path == HOUSE_DESTINATION, "actual breakout installs only the injected TEST ONLY L4 destination")
	_expect(exits == ["excavation-breakout"] and completions == ["ruined-house-escape"], "real breakout exits once without repeating completion")
	_expect(resources_at_exit.get("side_tender_hp") == 30.0 and defeats.size() == 6 and not defeats.has("side_tender") and not _required_side_damage_seen, "the optional Tender remains HP30/unhit/undefeated through actual exit and old-unit cleanup")
	for old: Node in old_nodes: _expect(not is_instance_valid(old), "actual transition frees old L3 player/scenery/target/bank/tool/cue")
	_expect(_game.player.hp == resources_at_exit.get("hp") and _game.player.shells == resources_at_exit.get("shells") and _game.player.equipment.snapshot() == resources_at_exit.get("equipment") and not _game.active_level.is_completed(), "transition preserves exact resources/gear without claiming L4 gameplay")
	return _failures == 0

func _observe_runtime() -> void:
	super._observe_runtime()
	if not _live() or not _actors.has("side_tender"): return
	if _actors.side_tender.get("hp") != 30.0 and not _required_side_damage_seen:
		_required_side_damage_seen = true
		_expect(false, "actual native tick detected forbidden optional Tender HP damage")
	var running: bool = false
	for bank: Node in _banks.values():
		if bank.call("state").status == "running": running = true
	if running:
		_required_running_bank_checks += 1
		_expect(not _game.active_level.is_completed(), "actual completion remains closed during every observed independently running bank")

