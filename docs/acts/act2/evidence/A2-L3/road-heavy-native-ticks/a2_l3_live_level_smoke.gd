extends "res://tests/acts/act2/a2_l2_live_level_smoke.gd"
## Actual L3 CampaignShell route, reusing the frozen L2 fixture's native dash,
## collision-query navigation, action collection and canonical loadout helpers.
## The preceding prefix/unlocks/profile and L4 destination are TEST ONLY.
## No live HP/ammo/transform/phase/progress assignment, blast or pickup grant.
## Requires the parent-owned published SmokeBank/full aggregate hookup.
## --loadout=standard/heavy/slow_cargo_longstep/slow_padded_reach/quick
## --profile=standard/assisted/challenge; --capture-live requires graphics.

const HouseSequence: Script = preload("res://scripts/acts/act2/ruined_house_sequence.gd")
const HouseRoot: Script = preload("res://scripts/acts/act2/ruined_house.gd")
const HouseFloor: Script = preload("res://scripts/acts/act2/ruined_house_floor.gd")
const SmokeBank: Script = preload("res://scripts/combat/smoke_bank.gd")
const HOUSE_SCENE: String = "res://scenes/acts/act2/a2_l3.tscn"
const HOUSE_DESTINATION: String = "res://tests/acts/act2/fixtures/a2_l3_transition_destination.tscn"
const HOUSE_TEST_ROOT: String = "user://test-a2-l3-live-level/"
const HOUSE_PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5", "A2-L1", "A2-L2"]
const HOUSE_CONTACT_ORDER: Array[String] = ["clear_ground", "wall_opening", "boss_entry"]
const HOUSE_CAPTURE_ROOT: String = "res://captures/act2/a2-l3-live/"
var _l2_fixture_bytes: String = ""
var _banks: Dictionary = {}
var _native_phases: Dictionary = {}
var _framed_phases: Dictionary = {}
var _tail_pending: Dictionary = {}
var _tail_completed: Dictionary = {}
var _boundary_records: Array[Dictionary] = []
var _boss_hits: Array[Dictionary] = []
var _boss_hp_observed: float = 30.0
var _wall_bypass_seen: bool = false
# TEST ONLY observer after authoritative Hero/Scheduler/Bank/level physics.
# Signals each native tick; never advances clocks or moves production nodes.
class NativeTickProbe:
	extends Node
	signal tick_finished
	func _init() -> void:
		process_physics_priority = 120
		process_mode = Node.PROCESS_MODE_ALWAYS
	func _physics_process(_delta: float) -> void:
		tick_finished.emit()

var _native_probe: NativeTickProbe
var _capture_pending: bool = false
var _road_only: bool = false
var _proof_diagnostics: int = 0

func _run() -> void:
	if not _read_options(): quit(1); return
	root.size = Vector2i(540, 1170)
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	if _capture_live and not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root)) == OK, "create separate ignored actual L3 portrait directory"):
		quit(1); return
	print("Ruined House actual route scope: loadout=%s profile=%s IDs=%s; initial zero ammo, ordinary primary, independent smoke tails, two15HP boss pools; TEST ONLY preceding prefix/unlocks/profile/L4 destination" % [_loadout_name, _profile_id, _loadout])
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_l2_fixture_bytes = FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l2_transition_destination.tscn")
	_cleanup()
	var failures_before: int = _failures
	if not await _run_route() and _failures == failures_before: _expect(false, "actual L3 route aborted: " + _diagnostic())
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l2_transition_destination.tscn") == _l2_fixture_bytes, "test injection preserves canonical registry and frozen L2 destination bytes")
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	if is_instance_valid(_native_probe): _native_probe.free()
	paused = false
	_cleanup()
	print("Ruined House live level smoke: %d checks, %d failures; loadout=%s profile=%s; actual authored L3 actions, synthetic preceding prefix and TEST ONLY L4 destination" % [_checks, _failures, _loadout_name, _profile_id])
	quit(0 if _failures == 0 else 1)

func _run_route() -> bool:
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
	level.completion_requested.connect(func(_id: String, completion: String) -> void: completions.append(completion))
	level.contact_exit_requested.connect(func(_id: String, exit_id: String) -> void:
		exits.append(exit_id)
		resources_at_exit["hp"] = hero.hp
		resources_at_exit["shells"] = hero.shells
		resources_at_exit["equipment"] = hero.equipment.snapshot()
	)
	hero.world_action_executed.connect(func(record: Dictionary) -> void:
		_actions.append(record.duplicate(true))
		_observe_wall_path(record)
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
	# The optional source is a real phase2 target. Prefer its actual opening;
	# one ordinary cone may also hit the nearby low machine joint.
	if not await _clear(["side_tender"]) or not await _clear(["handling_machine"]): return false
	for frame: int in range(600):
		if not _live(): return false
		if level.is_completed(): break
		await _step()
	var expected_checkpoints: Array[String] = []
	for contact: String in HOUSE_CONTACT_ORDER: expected_checkpoints.append(HouseSequence.CONTACTS[contact].checkpoint)
	expected_checkpoints.append("handling-machine-phase-two")
	_expect(checkpoints == expected_checkpoints and level.current_checkpoint().id == expected_checkpoints.back(), "three real contact checkpoints then exact HP phase checkpoint commit once in order")
	_expect(defeats.size() == 7 and defeats.slice(0, 3) == ["road_tender", "house_tender", "house_handler"] and defeats.slice(3, 5).has("apron_scout") and defeats.slice(3, 5).has("apron_handler") and defeats.slice(5).has("side_tender") and defeats.slice(5).has("handling_machine"), "all seven actual sources include optional side Tender and local machine disable without respawn/waves")
	_expect(_actors.handling_machine.get("hp") == 0.0 and _actors.handling_machine.get("max_hp") == 30.0 and _actors.handling_machine.get("boss_phase") == 2 and _boundary_records.size() == 1, "B02 keeps one totalHP30 and one earned15HP boundary before local arm disengagement")
	_expect(_tail_pending.is_empty() and _tail_completed.size() == 3, "all three defeated Tender banks finish their original independent tails")
	_expect(_state().beat == "clear" and _state().exit_open and level.is_completed() and completions == ["ruined-house-escape"] and exits.is_empty(), "actual local arm disable/tails complete once before separate breakout contact")
	for source: String in ["road_bank", "house_bank", "boss_bank", "tool_house_handler", "tool_apron_handler", "apron_scout", "boss_reach", "boss_place"]:
		for phase: String in ["warning", "lock", "active", "recovery"]:
			_expect(_native_phases.get(source, {}).has(phase), "actual native %s observed %s" % [source, phase])
	if _capture_live:
		for family: String in ["smoke", "tool", "ray", "boss-reach", "boss-place"]:
			for phase: String in ["warning", "lock", "active", "recovery"]:
				_expect(_captured.has(family + "-" + phase), "actual native source/phase capture exists: " + family + "-" + phase)
		_expect(_captured.has("clear"), "actual native local-arm-clear capture exists")
	_game.request_pause()
	await _settle()
	var aggregate: Dictionary = _game.capture_campaign_snapshot()
	_expect(not aggregate.is_empty() and _game.campaign_error.is_empty() and _game.attempts.state().completed_main == HOUSE_PREFIX + ["A2-L3"] and aggregate.level.progress.contact_exit_id.is_empty(), "actual paused shell records L3 completion with distinct unopened breakout: " + _game.campaign_error)
	if not aggregate.is_empty():
		_expect(aggregate.level.local.sequence.crossed_contacts == HOUSE_CONTACT_ORDER and aggregate.level.local.sequence.defeated_ids.size() == 7 and aggregate.level.local.sequence.boss_phase == 2, "actual aggregate retains all earned contacts/defeats/two-stage machine")
	var primary_hits: int = 0
	var dashes: int = 0
	for action: Dictionary in _actions:
		_expect(action.kind != "blast" and action.equipment_ids == _loadout and Codec.same_values(action.resolved_stats, _expected_stats), "real actions use unchanged canonical gear/stats and no blast")
		if action.kind == "primary": primary_hits += int(action.hits)
		elif action.kind == "dash": dashes += 1
	_expect(primary_hits >= 8 and dashes > 0 and hero.equipment.snapshot() == _loadout, "ordinary shared primaries and real sampled dashes supply seven targets and both15HP boss pools")
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
	for old: Node in old_nodes: _expect(not is_instance_valid(old), "actual transition frees old L3 player/scenery/target/bank/tool/cue")
	_expect(_game.player.hp == resources_at_exit.get("hp") and _game.player.shells == resources_at_exit.get("shells") and _game.player.equipment.snapshot() == resources_at_exit.get("equipment") and not _game.active_level.is_completed(), "transition preserves exact resources/gear without claiming L4 gameplay")
	return _failures == 0

func _clear(ids: Array[String]) -> bool:
	for frame: int in range(2400):
		if not _live(): return _expect(false, "encounter stopped before %s: %s" % [ids, _diagnostic()])
		if _road_only and int(_state().banks.road_bank.cycle) >= 3 and _state().banks.road_bank.status == "complete":
			return _expect(false, "focused road-only diagnostic stops at the first observed complete cycle >=3: " + _diagnostic())
		var living: Array[String] = []
		for id: String in ids:
			if float(_actors[id].get("hp")) > 0.0: living.append(id)
		if living.is_empty():
			for id: String in ids: _expect(_source_seen(id), "real target entered native warning/lock/active/recovery before its defeat: " + id)
			for settle_frame: int in range(4): await _step()
			print("Ruined House actual primary targets cleared: ", ids)
			return true
		var latest: Dictionary = _latest_actor_plan(living)
		if latest.is_empty(): latest = _latest_actor_plan(_state().active_ids)
		if not latest.is_empty():
			_used_proofs[latest.key] = true
			# A currently admitted counterpart still needs its real escape while
			# the preferred source is cooling down; leave its primary unused.
			if not await _follow_proof(latest, living.has(latest.actor_id)): return false
		elif frame % 90 == 0:
			var target: Node3D = _actors[living[0]] as Node3D
			var offset: Vector3 = _game.player.global_position - target.global_position
			offset.y = 0.0
			if offset.length() > 3.45:
				if not await _navigate_dash(target.global_position + offset.normalized() * 3.0): return false
			elif not level_actor_framed(living[0]) and not await _navigate_dash(target.global_position): return false
		await _step()
	return _expect(false, "bounded ordinary-primary bot could not clear %s: %s" % [ids, _diagnostic()])

func _advance_boss_phase(checkpoints: Array[String]) -> bool:
	for frame: int in range(2400):
		if not _live(): return false
		if _state().boss_phase == 2 and checkpoints.has("handling-machine-phase-two"):
			return _expect(_boundary_records.size() == 1 and _boundary_records[0].hp == 15.0 and _boundary_records[0].max_hp == 30.0 and _boundary_records[0].boss_phase == 1 and _boundary_records[0].transition_pending and _boundary_records[0].beat == "boss_phase_one" and _actors.handling_machine.get("hp") == 15.0 and not _boss_hits.is_empty() and _boss_hits[0].before == 30.0 and _boss_hits[0].after == 15.0 and _boss_hits[0].phase == 1 and _boss_hits[0].source_id == "boss_place" and float(_boss_hits[0].damage) > 15.0, "actual overkill consumes surplus at exact15HP and cannot bypass the earned phase/checkpoint")
		var plan: Dictionary = _latest_actor_plan(["handling_machine"])
		if not plan.is_empty():
			_used_proofs[plan.key] = true
			# Execute Reach escape/return honestly, leaving its primary opening
			# unused once so the known Place cycle is actually demonstrated.
			var attack: bool = plan.source_id == "boss_place"
			if not await _follow_proof(plan, attack): return false
		elif frame % 90 == 0:
			var target: Node3D = _actors.handling_machine as Node3D
			var offset: Vector3 = _game.player.global_position - target.global_position
			offset.y = 0.0
			if offset.length() > 3.45 and not await _navigate_dash(target.global_position + offset.normalized() * 3.0): return false
		await _step()
	return _expect(false, "bounded real boss primary did not earn the phase boundary: " + _diagnostic())

func _broadside_wall() -> bool:
	var side: float = -1.0 if _game.player.global_position.x < 0.0 else 1.0
	for attempt: int in range(18):
		if not _live(): return false
		var at: Vector3 = _game.player.global_position
		if absf(at.x) >= 1.65 and at.z > HouseFloor.WALL_AT.z + 0.55: break
		if not await _navigate_dash(Vector3(side * 2.2, 0.0, maxf(at.z, -12.0))): return false
	for attempt: int in range(18):
		if not _live(): return false
		if _game.player.global_position.z < HouseFloor.WALL_AT.z - 0.55 and _stable():
			return _expect(_wall_bypass_seen, "actual grounded dash goes around a broad side of the wall")
		if not await _navigate_dash(Vector3(side * 2.2, 0.0, -15.5)): return false
		for frame: int in range(180):
			if not _live(): return false
			if _stable(): break
			await _step()
	return _expect(false, "bounded real side dashes could not pass the authored low wall: " + _diagnostic())

func _observe_wall_path(record: Dictionary) -> void:
	if record.get("kind") != "dash": return
	var wall_z: float = HouseFloor.WALL_AT.z
	var clearance: float = HouseFloor.WALL_SIZE.x * 0.5 + 0.32
	for index: int in range(1, record.path.size()):
		var start: Vector3 = record.path[index - 1].position
		var finish: Vector3 = record.path[index].position
		if is_equal_approx(start.z, finish.z) or (start.z - wall_z) * (finish.z - wall_z) > 0.0: continue
		var crossing: Vector3 = start.lerp(finish, (wall_z - start.z) / (finish.z - start.z))
		if absf(crossing.x) >= clearance and absf(crossing.y) < 0.05: _wall_bypass_seen = true

func _actor_plan(id: String) -> Dictionary:
	var current: Dictionary = _state().exchanges.get(id, {})
	if current.is_empty(): return {}
	var source: String = String(current.get("bank_id", current.get("mechanism_id", id)))
	var proof: Dictionary = current.get("proof", {})
	if current.has("mechanism_id"): proof = _game.active_level.call("mechanism_proof", source)
	return _make_plan(source, id, current, proof)

func _latest_actor_plan(ids: Array[String]) -> Dictionary:
	var latest: Dictionary = {}
	for id: String in ids:
		if not _actors.has(id) or float(_actors[id].get("hp")) <= 0.0: continue
		var plan: Dictionary = _actor_plan(id)
		if plan.is_empty() or _used_proofs.has(plan.key): continue
		if latest.is_empty() or float(plan.reservation.lock_from_s) > float(latest.reservation.lock_from_s): latest = plan
	return latest

func _make_plan(id: String, actor_id: String, current: Dictionary, proof: Dictionary) -> Dictionary:
	if current.get("status") != "running" or not proof.get("accepted", false): return {}
	var reservation: Dictionary = _reservation(String(current.get("reservation_id", "")))
	if reservation.is_empty() or not reservation.get("armed", false): return {}
	return {"source_id": id, "actor_id": actor_id, "key": "%s:%s:%s" % [id, current.get("cycle", -1), current.reservation_id], "cycle": current.cycle, "reservation": reservation, "proof": proof.duplicate(true), "resolved_role": current.resolved_role}

func _follow_proof(plan: Dictionary, attack: bool) -> bool:
	var reservation: Dictionary = plan.reservation
	var trace_proof: bool = _road_only and _proof_diagnostics < 3
	if trace_proof:
		_proof_diagnostics += 1
		print("Road proof starts: clock=", _state().clock_s, " plan=", plan)
	var source: String = plan.source_id
	var role_key: String = "bank" if HouseSequence.TENDERS.has(plan.actor_id) else ("ray" if plan.actor_id == "apron_scout" else "tool")
	if not _expect(Codec.same_values(plan.resolved_role, _expected_roles[role_key]) and is_equal_approx(float(reservation.active_from_s) - float(reservation.lock_from_s), float(_expected_roles[role_key].lock_s)) and float(reservation.active_from_s) - float(reservation.lock_from_s) >= 1.1 - 0.00001 and plan.proof.uses_blast == false and plan.proof.uses_invulnerability == false, "actual %s proof retains shared resolved role/full1.10 lock and ordinary-primary response" % source): return false
	for segment: Dictionary in plan.proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash", "ordinary_primary"]: continue
		if trace_proof: print("Road proof segment waiting: clock=", _state().clock_s, " segment=", segment)
		while _live() and float(_state().clock_s) + 0.00001 < float(segment.start_s):
			if not _plan_current(plan) or not _replacement_plan(plan, attack).is_empty(): return true
			await _step()
		if not _live(): return false
		if not _plan_current(plan) or not _replacement_plan(plan, attack).is_empty(): return true
		if segment.kind == "ordinary_primary":
			if not attack: continue
			var id: String = plan.actor_id
			var actor: Node3D = _actors[id] as Node3D
			var current: Dictionary = _state().exchanges[id]
			if trace_proof: print("Road primary reached: clock=", _state().clock_s, " phase=", current.phase)
			if float(actor.get("hp")) <= 0.0 or current.phase != "recovery": return true
			var direction: Vector3 = actor.global_position - _game.player.global_position
			direction.y = 0.0
			var hp_before: float = float(actor.get("hp"))
			var boss_phase_before: int = int(actor.get("boss_phase")) if id == "handling_machine" else 0
			var diagnostic: Dictionary = {"plan": plan, "hero_position": _game.player.global_position, "hero_response": _game.player.get_threat_response_state(), "range": _game.player.stats.primary_range, "distance": direction.length(), "actor_hp": hp_before, "actor_phase": actor.get("phase"), "current": current, "root": _state()}
			var hits: int = _game.player.slash(direction.normalized())
			if hits <= 0: print("Ruined House zero-hit primary actual pre-action diagnostic: ", diagnostic)
			if id == "handling_machine" and hits > 0:
				var hp_after: float = float(actor.get("hp"))
				_boss_hits.append({"before": hp_before, "after": hp_after, "phase": boss_phase_before, "damage": _game.player.stats.primary_damage, "source_id": source})
				_expect(hp_after < hp_before and (hp_after >= 15.0 if boss_phase_before == 1 else hp_after >= 0.0), "ordinary primary truly damages B02 without refill or crossing first-phase threshold")
			return _expect(hits > 0, "actual %s ordinary primary reaches recovering %s" % [_loadout_name, id])
		var direction: Vector3 = segment.to - segment.from
		direction.y = 0.0
		if not await _dash(direction.normalized(), false, plan, segment): return false
		if _proof_dash_abandoned:
			if trace_proof: print("Road proof dash abandoned: clock=", _state().clock_s, " segment=", segment, " current=", _plan_current(plan), " response=", _game.player.get_threat_response_state())
			return true
	return true

func _replacement_plan(plan: Dictionary, attack: bool) -> Dictionary:
	var candidate: Dictionary = _latest_actor_plan(_state().active_ids) if attack else _actor_plan(plan.actor_id)
	if candidate.is_empty() or candidate.key == plan.key or _used_proofs.has(candidate.key): return {}
	# A later warning whose real danger begins after the complete current
	# response is not a reason to abandon this already admitted opening.
	if float(candidate.reservation.active_from_s) > float(plan.proof.response_complete_s): return {}
	return candidate if float(candidate.reservation.lock_from_s) > float(plan.reservation.lock_from_s) else {}

func _plan_current(plan: Dictionary) -> bool:
	var current: Dictionary = _state().exchanges.get(plan.actor_id, {})
	var live: Dictionary = _reservation(String(current.get("reservation_id", "")))
	return current.get("status") == "running" and current.get("cycle") == plan.cycle and current.get("reservation_id") == plan.reservation.id and not live.is_empty() and live.get("armed", false)

func level_actor_framed(id: String) -> bool:
	return _raw_camera_error(_required_points(id, _state().exchanges.get(id, {}))).is_empty()

func _source_seen(id: String) -> bool:
	var sources: Array[String] = [id]
	if HouseSequence.TENDERS.has(id):
		for bank_id: String in HouseRoot.BANK_TO_TENDER:
			if HouseRoot.BANK_TO_TENDER[bank_id] == id: sources = [bank_id]
	elif HouseSequence.HANDLERS.has(id): sources = ["tool_" + id]
	elif id == "handling_machine": sources = ["boss_reach", "boss_place"]
	for source: String in sources:
		for phase: String in ["warning", "lock", "active", "recovery"]:
			if not _native_phases.get(source, {}).has(phase): return false
	return true

func _observe_defeat(id: String) -> void:
	if not HouseSequence.TENDERS.has(id): return
	for bank_id: String in HouseRoot.BANK_TO_TENDER:
		if HouseRoot.BANK_TO_TENDER[bank_id] != id: continue
		var state: Dictionary = _banks[bank_id].call("state")
		_expect(state.status == "running" and state.phase == "recovery" and float(_actors[id].get("hp")) == 0.0 and not state.exchange.is_empty(), "ordinary Tender defeat preserves its independently running recovery tail: " + id)
		_tail_pending[bank_id] = state.duplicate(true)

func _observe_runtime() -> void:
	if not _live(): return
	var state: Dictionary = _state()
	var boss_hp: float = float(_actors.handling_machine.get("hp"))
	if boss_hp != _boss_hp_observed:
		_expect(boss_hp < _boss_hp_observed and _actors.handling_machine.get("max_hp") == 30.0, "actual B02 health only decreases across phase presentation/checkpoints")
		_boss_hp_observed = boss_hp
	for id: String in state.exchanges:
		var current: Dictionary = state.exchanges[id]
		if current.get("status") != "running" or current.get("phase") not in ["warning", "lock", "active", "recovery"]: continue
		var source: String = String(current.get("bank_id", current.get("mechanism_id", id)))
		if not _native_phases.has(source): _native_phases[source] = {}
		_native_phases[source][current.phase] = true
		var required: Array[Vector3] = _required_points(id, current)
		var key: String = "%s:%s:%s:%s" % [source, current.cycle, current.phase, required.size()]
		if not _framed_phases.has(key):
			_framed_phases[key] = true
			if current.has("bank_id"):
				var bank_points: Array = _banks[current.bank_id].call("get_required_camera_points")
				var grace_visible: bool = (_banks[current.bank_id].call("get_grace_indicator") as Node3D).get_node("GraceBackground").is_visible_in_tree()
				_expect(bank_points.size() == (9 if grace_visible else 5), "actual bank camera points include its full published rim/source and conditional grace bar")
			_expect(not required.is_empty() and _raw_camera_error(required).is_empty(), "actual raw camera fits current Hero/source/footprint/witness or visible grace points: " + key + ": " + _raw_camera_error(required))
	for bank_id: String in _tail_pending.keys():
		var before: Dictionary = _tail_pending[bank_id]
		var current: Dictionary = _banks[bank_id].call("state")
		if current.status == "running":
			if not before.get("tail_checked", false):
				_expect(current.cycle == before.cycle and Codec.same_values(current.exchange, before.exchange) and Codec.same_values(current.receipts, before.receipts) and current.last_cancel_reason.is_empty() and float(state.clock_s) <= float(before.exchange.recovery_until_s), "defeated source preserves exact bank cycle/lease/deadlines/receipts while original tail runs: " + bank_id)
				before["tail_checked"] = true
		elif current.status == "complete":
			_expect(current.cycle == before.cycle and Codec.same_values(current.exchange, before.exchange) and Codec.same_values(current.receipts, before.receipts) and current.phase == "clear" and float(state.clock_s) > float(before.exchange.recovery_until_s), "independent bank completes only after its original recovery deadline without re-emission: " + bank_id)
			_tail_completed[bank_id] = current.duplicate(true)
			_tail_pending.erase(bank_id)
		else:
			_expect(false, "defeated Tender tail was cancelled/refreshed instead of finishing: %s %s" % [bank_id, current])
			_tail_pending.erase(bank_id)

func _required_points(id: String, current: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	points.append_array(_game.call("player_camera_framing_points"))
	if _actors.has(id) and _actors[id].is_visible_in_tree() and float(_actors[id].get("hp")) > 0.0:
		_append_native_bounds(_actors[id], points)
	if current.has("bank_id") and _banks.has(current.bank_id):
		points.append_array(_banks[current.bank_id].call("get_required_camera_points"))
	elif current.get("geometry") is Dictionary and not current.geometry.is_empty() and current.phase != "recovery":
		points.append_array(_game.active_level.call("_lane_points", current.geometry))
	var witness: Dictionary = current.get("proof", {})
	if current.has("mechanism_id"): witness = _game.active_level.call("mechanism_proof", current.mechanism_id)
	if not witness.get("landing") is Vector3: witness = current.get("presentation_witness", {})
	if current.phase != "recovery":
		for key: String in ["landing", "attack_position"]:
			if witness.get(key) is Vector3: points.append_array(_game.active_level.call("_landing_points", witness[key]))
	return points

func _append_native_bounds(actor: Node3D, result: Array[Vector3]) -> void:
	var pending: Array[Node] = [actor]
	var vertices: Array[Vector3] = []
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D and node.is_visible_in_tree() and node.mesh != null:
			var mesh: MeshInstance3D = node as MeshInstance3D
			for surface: int in range(mesh.mesh.get_surface_count()):
				var arrays: Array = mesh.mesh.surface_get_arrays(surface)
				if arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
					for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]: vertices.append(mesh.global_transform * vertex)
		pending.append_array(node.get_children())
	if vertices.is_empty(): return
	var bounds := AABB(vertices[0], Vector3.ZERO)
	for vertex: Vector3 in vertices: bounds = bounds.expand(vertex)
	for index: int in range(8): result.append(bounds.get_endpoint(index))

func _raw_camera_error(points: Array[Vector3]) -> String:
	if points.is_empty(): return "Missing current native points"
	var error: String = _game.call("camera_framing_error", points)
	if not error.is_empty(): return error
	var camera: Camera3D = _game.camera
	var safe: Rect2 = _game.hud.call("combat_safe_rect")
	var dimensions: Vector2 = camera.get_viewport().get_visible_rect().size
	if dimensions.x <= 0.0 or dimensions.y <= 0.0: return "Empty actual viewport"
	for point: Vector3 in points:
		if not point.is_finite() or camera.is_position_behind(point) or not safe.has_point(camera.unproject_position(point) / dimensions): return "Actual native point outside current projected HUD-safe camera"
	return ""

func _contact(id: String, checkpoints: Array[String]) -> bool:
	if not _expect(_state().beat == id, "actual route reaches contact beat " + id): return false
	var region: Rect2 = HouseSequence.CONTACTS[id].region
	var before: int = checkpoints.size()
	for attempt: int in range(18):
		if not _live(): return false
		if _state().beat != id: break
		if not await _navigate_dash(Vector3(region.get_center().x, 0, region.get_center().y)): return false
		if _dash_touches_region(_last_dash(), region):
			for frame: int in range(180):
				if not _live(): return false
				if _state().beat != id and _stable(): break
				await _step()
			break
	if not _expect(_state().beat != id and _stable() and _dash_touches_region(_last_dash(), region), "real sampled dash crosses %s and finishes stable before further navigation" % id): return false
	return _expect(checkpoints.size() == before + 1 and checkpoints.back() == HouseSequence.CONTACTS[id].checkpoint and _game.active_level.current_checkpoint().id == checkpoints.back(), "actual contact commits exactly its authored checkpoint: " + id)

func _dash_to_exit() -> bool:
	for attempt: int in range(18):
		if _game.active_level.level_id != "A2-L3": return _expect(_game.active_level.level_id == "A2-L4" and _game.active_level.scene_file_path == HOUSE_DESTINATION, "only actual breakout navigation transitions to TEST ONLY L4")
		var region: Rect2 = HouseRoot.BREAKOUT
		if not await _navigate_dash(Vector3(region.get_center().x, 0, region.get_center().y), true): return false
		if _game.active_level.level_id != "A2-L3": return true
		if _dash_touches_region(_last_dash(), region):
			for frame: int in range(180):
				if _game.active_level.level_id != "A2-L3": return true
				await _step()
	return _expect(false, "actual breakout failed to transition: " + _diagnostic())

func _dash(direction: Vector3, allow_exit_transition: bool = false, proof_plan: Dictionary = {}, proof_segment: Dictionary = {}) -> bool:
	_proof_dash_abandoned = false
	var hero: CinderPlayer = _game.player
	var ready: bool = false
	for frame: int in range(180):
		if not _live(): return false
		if not proof_plan.is_empty() and not _proof_dash_current(proof_plan, proof_segment):
			_proof_dash_abandoned = true
			return true
		var response: Dictionary = hero.get_threat_response_state()
		if not paused and response.stable and float(response.dash_cooldown_left_s) <= 0.00001:
			ready = true
			break
		await _step()
	if not _expect(ready, "bot awaits unpaused stable shared actor and native dash cooldown"): return false
	if not proof_plan.is_empty() and not _proof_dash_current(proof_plan, proof_segment):
		_proof_dash_abandoned = true
		return true
	var before: int = _actions.size()
	if not _expect(hero.request_dash(direction), "bot uses shared accepted dash request"): return false
	for frame: int in range(180):
		for action: Dictionary in _actions.slice(before):
			if action.kind == "dash": return _expect(action.landing.is_finite() and action.landing.y > -0.05 and action.path.size() >= 2, "actual completed dash has supported sampled world landing")
		if not is_instance_valid(hero):
			if allow_exit_transition and _game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L4" and _game.active_level.scene_file_path == HOUSE_DESTINATION:
				return _expect(true, "actual breakout may transition during a dash without fabricating its unfinished world-action record")
			break
		await _step()
	return _expect(false, "shared dash did not publish a completed world action")

func _read_options() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--loadout="): _loadout_name = argument.trim_prefix("--loadout=")
		elif argument.begins_with("--profile="): _profile_id = argument.trim_prefix("--profile=")
		elif argument == "--capture-live": _capture_live = true
		elif argument == "--road-only": _road_only = true
	if not _expect(LOADOUTS.has(_loadout_name) and _profile_id in ["standard", "assisted", "challenge"], "supported existing loadout/profile selectors"): return false
	_loadout = LOADOUTS[_loadout_name].duplicate(true)
	_capture_root = HOUSE_CAPTURE_ROOT
	var resolver: CinderEquipment = Equipment.new() as CinderEquipment
	if not _expect(resolver.restore(_loadout), "selected gear IDs are implemented canonical records"): return false
	_expected_stats = resolver.resolved_stats()
	var difficulty: RefCounted = Difficulty.new()
	_expected_roles = {"ray": difficulty.call("resolve_role", RayExchange.RAW_ROLE, _profile_id, RayExchange.TIMING_FLOORS), "tool": difficulty.call("resolve_role", Weybridge.TOOL_ROLE, _profile_id, Weybridge.TOOL_FLOORS), "bank": difficulty.call("resolve_role", SmokeBank.DEFAULT_RAW_ROLE, _profile_id, SmokeBank.DEFAULT_TIMING_FLOORS)}
	for role: Dictionary in _expected_roles.values():
		if not _expect(not role.is_empty(), "shared resolver accepts selected fixed profile without raw-role retuning"): return false
	return _expect(not _capture_live or DisplayServer.get_name() != "headless", "actual native capture requires graphical engine")

func _seed(registry: CinderCampaignRegistry) -> bool:
	var preview: Node = MainScene.instantiate()
	preview.set_script(ProfileSeedGame)
	preview.set("test_profile_id", _profile_id)
	preview.set("level_scene_path", HOUSE_SCENE)
	root.add_child(preview)
	paused = true
	var hero: CinderPlayer = preview.get("player") as CinderPlayer
	var selected: bool = hero.equipment.restore(_loadout) and hero.equip_item(String(_loadout.weapon))
	if not _expect(selected and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats), "TEST ONLY existing canonical gear selected before actual combat"):
		preview.free(); return false
	hero.shells = 0 # Initial test resource only; natural reload credit stays shared.
	preview.call("resume_lab")
	for frame: int in range(8): await physics_frame
	paused = true
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var actor_state: Dictionary = hero.snapshot_state()
	var local_state: Dictionary = level.snapshot_state()
	var camera: Camera3D = preview.get("camera") as Camera3D
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": _profile_id}
	var aggregate: Dictionary = {"schema_version": 1, "level_id": "A2-L3", "scene_path": HOUSE_SCENE, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": actor_state, "level": local_state, "shell": shell_state}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var seed: Dictionary = model.state()
	seed.completed_main = HOUSE_PREFIX.duplicate()
	# Synthetic preceding catalogue unlock metadata, not actual earlier-level
	# acceptance or L3 reward/progression/runtime equipment grant.
	for id: String in _loadout.values():
		if not seed.unlocked_equipment.has(id): seed.unlocked_equipment.append(id)
	print("TEST ONLY synthetic prior catalogue unlock metadata: ", _loadout.values())
	seed.story = {"kind": "story", "level_id": "A2-L3", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var store: CinderSaveStore = Store.new(HOUSE_TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var seed_error: String = model.state_error(seed)
	var saved: bool = not actor_state.is_empty() and not local_state.is_empty() and seed_error.is_empty() and store.write_payload(seed)
	if not saved: print("Ruined House seed rejection: actor_error=%s level_error=%s runtime_error=%s model_error=%s store_error=%s actor_keys=%s level_keys=%s" % [hero.last_snapshot_error, level.last_snapshot_error, level.get("runtime_error"), seed_error, store.last_error, actor_state.keys(), local_state.keys()])
	_expect(saved, "TEST ONLY prefix throughL2 seeds real captured L3/Hero state: " + store.last_error)
	level.exit_level()
	preview.free()
	_expect(not is_instance_valid(hero) and not is_instance_valid(level), "seed Game/Hero/level freed before actual shell installation")
	return saved

func _state() -> Dictionary:
	return _game.active_level.call("encounter_state") if is_instance_valid(_game) and is_instance_valid(_game.active_level) and _game.active_level.level_id == "A2-L3" else {}

func _live() -> bool:
	return is_instance_valid(_game) and _game.campaign_error.is_empty() and is_instance_valid(_game.player) and not _game.player.dead and is_instance_valid(_game.active_level) and _game.active_level.level_id == "A2-L3" and String(_state().get("runtime_error", "")).is_empty()

func _step() -> void:
	# Render-frame waits may span several catch-up physics ticks. Keep native
	# planned dash sampling within the original strict one-tick limit instead.
	await _native_probe.tick_finished
	if is_instance_valid(_game) and paused and _game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L3" and _game.menu.page_name() == "resume" and not _game.player.dead: _game.resume_campaign()
	_observe_runtime()
	if _capture_live and not _capture_pending:
		_capture_pending = true
		_capture_after_tick()

func _capture_after_tick() -> void:
	# Screenshot work waits for the normal completed render independently of
	# the strict native action sampler. Capture still records actual current
	# state/camera/masks; it never stages a phase or forces a camera update.
	await _capture_state()
	_capture_pending = false

func _cleanup() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(HOUSE_TEST_ROOT + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HOUSE_TEST_ROOT))

func _capture_labels(state: Dictionary) -> Array[String]:
	var labels: Array[String] = []
	for id: String in state.active_ids:
		var current: Dictionary = state.exchanges[id]
		if current.get("status") != "running" or current.get("phase") not in ["warning", "lock", "active", "recovery"]: continue
		var family: String = "smoke" if HouseSequence.TENDERS.has(id) else ("ray" if id == "apron_scout" else (String(current.get("mechanism_id", "boss")) if id == "handling_machine" else "tool"))
		var label: String = family.replace("_", "-") + "-" + String(current.phase)
		if not _captured.has(label) and not labels.has(label): labels.append(label)
	if state.beat in ["ruined_house", "work_apron", "boss_phase_two"]:
		var running: int = 0
		for id: String in state.active_ids:
			if state.exchanges[id].get("status") == "running": running += 1
		var label: String = String(state.beat).replace("_", "-") + "-actual-pair"
		if running == 2 and not _captured.has(label): labels.append(label)
	if state.beat == "clear" and not _captured.has("clear"): labels.append("clear")
	return labels

func _capture_state() -> void:
	if not _capture_live or not _live() or paused: return
	var labels: Array[String] = _capture_labels(_state())
	if labels.is_empty(): return
	# Actual frame after Game camera/parent-derived masks. Never change scene,
	# camera, phase or resources for a picture; record actual mixed armed flags.
	await RenderingServer.frame_post_draw
	if not _live() or paused: return
	var state: Dictionary = _state()
	var current_labels: Array[String] = _capture_labels(state)
	var image: Image = root.get_texture().get_image()
	if not _expect(image != null and image.get_size() == Vector2i(540, 1170), "actual L3 render is native540x1170"): return
	var actor_observations: Dictionary = {}
	for id: String in state.active_ids:
		var current: Dictionary = state.exchanges[id]
		var reservation: Dictionary = _reservation(String(current.get("reservation_id", "")))
		var actor: Node3D = _actors[id]
		var rig: Node = actor.get("_visual") as Node
		actor_observations[id] = {"phase": current.get("phase", "idle"), "status": current.get("status", "idle"), "cycle": current.get("cycle", 0), "armed": reservation.get("armed", false), "source_position": Codec.vector3(actor.global_position), "hp": actor.get("hp"), "reservation_id": current.get("reservation_id", ""), "geometry": _geometry_json(current.get("geometry", {})), "readability": rig.call("readability_state") if is_instance_valid(rig) and rig.has_method("readability_state") else {}}
	var bank_observations: Dictionary = {}
	for id: String in _banks:
		var bank: Node = _banks[id]
		var current: Dictionary = bank.call("state")
		var required: Array = bank.call("get_required_camera_points")
		var indicator: Node3D = bank.call("get_grace_indicator") as Node3D
		var native_points: Array = []
		for point: Vector3 in required: native_points.append(Codec.vector3(point))
		bank_observations[id] = {"phase": current.phase, "status": current.status, "cycle": current.cycle, "geometry": _geometry_json(current.geometry), "reservation_id": current.reservation_id, "original_deadlines": _deadline_json(current.exchange), "grace_progress": current.grace_progress, "contact_since_s": current.contact_since_s, "opportunities_consumed": current.opportunities_consumed, "receipts": current.receipts, "native_required_points": native_points, "grace_visible": indicator.get_node("GraceBackground").is_visible_in_tree()}
	for label: String in labels:
		if _captured.has(label) or not current_labels.has(label): continue
		var path: String = _capture_root + "a2-l3-" + _profile_id + "-" + _loadout_name + "-" + label + ".png"
		if not _expect(image.save_png(path) == OK, "save actual native L3 state " + label): return
		_captured[label] = {"image": path, "level_id": "A2-L3", "loadout": _loadout_name, "profile": _profile_id, "beat": state.beat, "boss_phase": state.boss_phase, "clock_s": state.clock_s, "hero_position": Codec.vector3(_game.player.global_position), "hero_hp": _game.player.hp, "shells": _game.player.shells, "world_action_count": _actions.size(), "actors": actor_observations.duplicate(true), "banks": bank_observations.duplicate(true), "camera_position": Codec.vector3(_game.camera.global_position)}
		print("Actual Ruined House portrait: ", path)
	var file: FileAccess = FileAccess.open(_capture_root + "a2-l3-" + _profile_id + "-" + _loadout_name + "-evidence.json", FileAccess.WRITE)
	if _expect(file != null, "open ignored actual L3 capture metadata"):
		file.store_string(JSON.stringify({"scope": "Actual authored L3 dash/ordinary-primary route; synthetic preceding prefix/unlocks/profile and TEST ONLY L4 destination. Each mixed source reports its actual armed flag. Native pixels require separate source/readability review; no human/device/balance acceptance", "frames": _captured}, "\t", true, true))

func _deadline_json(exchange: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if exchange.has(key): result[key] = exchange[key]
	return result
