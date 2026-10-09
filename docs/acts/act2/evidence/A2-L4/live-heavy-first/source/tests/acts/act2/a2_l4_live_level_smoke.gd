extends "res://tests/acts/act2/a2_l2_live_level_smoke.gd"
## Actual L4 CampaignShell route. Reuses frozen L2 native navigation/loadout
## helpers and L3's tick120/proof/camera/tail observation contract, independently.
## Prior prefix throughL3/unlocks/profile and L5 destination are TEST ONLY.
## Only canonical initial gear and shells0 are seeded before combat; no live
## HP/transform/phase/clock assignment, pickups, blast or manufactured progress.
## Real viewport touch swipes/taps retain exact final-release aim and native
## world-action witnesses. No human/device/balance or native-art acceptance.
## --loadout=standard/heavy/slow_cargo_longstep/slow_padded_reach/quick
## --profile=standard/assisted/challenge; --capture-live requires graphics.

const LondonSequence: Script = preload("res://scripts/acts/act2/london_approaches_sequence.gd")
const LondonRoot: Script = preload("res://scripts/acts/act2/london_approaches.gd")
const LondonFloor: Script = preload("res://scripts/acts/act2/london_approaches_floor.gd")
const SmokeBank: Script = preload("res://scripts/combat/smoke_bank.gd")
const LONDON_SCENE: String = "res://scenes/acts/act2/a2_l4.tscn"
const LONDON_DESTINATION: String = "res://tests/acts/act2/fixtures/a2_l4_transition_destination.tscn"
const LONDON_TEST_ROOT: String = "user://test-a2-l4-live-level/"
const LONDON_PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5", "A2-L1", "A2-L2", "A2-L3"]
const LONDON_CONTACT_ORDER: Array[String] = ["road_entry", "villa_entry", "putney_entry"]
const LONDON_CAPTURE_ROOT: String = "res://captures/act2/a2-l4-live/"
const FROZEN_INPUTS: Array[String] = ["res://tests/acts/act2/a2_l2_live_level_smoke.gd", "res://tests/acts/act2/a2_l3_live_level_smoke.gd", "res://tests/acts/act2/fixtures/a2_l3_transition_destination.tscn"]
const QUIET_LABELS: Dictionary = {"road_entry": "quiet-garden-red-weed", "villa_entry": "quiet-flood-margin", "putney_entry": "quiet-putney-approach"}
const STAGE_LABELS: Dictionary = {"flood_margin": "flood-margin-dry-floor", "villa_scout_priority": "villa-scout-priority-fixed-wall", "villa_tender_priority": "villa-tender-priority-bleached-weed", "putney_mix": "putney-open-abutment"}
var _frozen_input_bytes: Dictionary = {}
var _banks: Dictionary = {}
var _native_phases: Dictionary = {}
var _framed_phases: Dictionary = {}
var _tail_pending: Dictionary = {}
var _tail_completed: Dictionary = {}
var _blocker_bypass_seen: Dictionary = {}
# TEST ONLY observer after authoritative Hero/Scheduler/consumer/level physics.
# It observes each native tick; it never steps clocks or moves production nodes.
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

func _run() -> void:
	if not _read_options(): quit(1); return
	root.size = Vector2i(540, 1170)
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	if _capture_live and not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root)) == OK, "create separate ignored actual L4 portrait directory"):
		quit(1); return
	print("London Approaches actual route scope: loadout=%s profile=%s IDs=%s; normal HP/initial shells0, routed native swipes/aim/ordinary primaries, all9 HP30 sources and two independent smoke tails; TEST ONLY prior prefix throughL3/unlocks/profile/L5 destination" % [_loadout_name, _profile_id, _loadout])
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	for path: String in FROZEN_INPUTS: _frozen_input_bytes[path] = FileAccess.get_file_as_string(path)
	_cleanup()
	var failures_before: int = _failures
	if not await _run_route() and _failures == failures_before: _expect(false, "actual L4 route aborted: " + _diagnostic())
	await process_frame
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "test injection preserves canonical registry bytes")
	for path: String in FROZEN_INPUTS: _expect(FileAccess.get_file_as_string(path) == _frozen_input_bytes[path], "test preserves frozen native helper/destination bytes: " + path)
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	if is_instance_valid(_native_probe): _native_probe.free()
	paused = false
	_cleanup()
	print("London Approaches live level smoke: %d checks, %d failures; loadout=%s profile=%s; actual authored L4 actions, synthetic preceding prefix and TEST ONLY L5 destination" % [_checks, _failures, _loadout_name, _profile_id])
	quit(0 if _failures == 0 else 1)

func _run_route() -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L4", "A2-L5"]:
			info.scene_path = LONDON_SCENE if info.id == "A2-L4" else LONDON_DESTINATION
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L5").is_empty(), "injected TEST ONLY L5 destination matches exported identity/contract") or not await _seed(registry): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, LONDON_TEST_ROOT + "campaign.json", LONDON_TEST_ROOT + "settings.json", LONDON_TEST_ROOT + "preferences.json"), "actual shell accepts isolated registry/save paths"): return false
	root.add_child(_game)
	await _settle()
	_game.menu.difficulty_preference_requested.emit(_profile_id)
	_game.resume_campaign()
	await _settle()
	if not _expect(_live() and _game.active_level.scene_file_path == LONDON_SCENE, "actual shell installs authored L4: " + _game.campaign_error): return false
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	var installed: Dictionary = level.snapshot_state()
	if not _expect(not installed.is_empty() and installed.local.get("profile_id") == _profile_id and _state().smoke_api_ready, "actual whole L4 snapshot/native banks retain chosen fixed profile"): return false
	if not _expect(hero.presentation_id == "act2_survivor" and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats) and hero.shells == 0, "actual L4 entry retains shared Act2 presentation/canonical gear/stats and initial shells0"): return false
	if _loadout_name == "heavy": _expect(is_equal_approx(float(hero.stats.primary_range), 1.8), "Heavy uses actual shortest shared primary reach")
	_actors = level.get("_actors").duplicate()
	_banks = level.get("_clouds").duplicate()
	if not _expect(_actors.size() == 9 and _banks.size() == 2 and level.get("_mechanisms").size() == 4 and not _contains_pickup(level), "nine HP sources, two independent banks/four stationary lanes/three Rays; no victory pickups"): return false
	for id: String in _actors:
		_expect(_actors[id].get("hp") == 30.0 and _actors[id].get("max_hp") == 30.0 and _actors[id].global_position == LondonSequence.ACTORS[id], "actual stationary source retains authored HP30/origin: " + id)
	for id: String in _banks:
		var bank: Node3D = _banks[id]
		_expect(bank.get_script() == SmokeBank and bank.get_parent() == level and bank.global_position == LondonSequence.CLOUDS[id], "published bank remains independent fixed level child: " + id)
	var defeats: Array[String] = []
	for actor: Node in _actors.values():
		actor.connect("defeated", func(id: String) -> void:
			defeats.append(id)
			_observe_defeat(id)
		)
	var checkpoints: Array[String] = []
	var completions: Array[String] = []
	var exits: Array[String] = []
	var resources_at_exit: Dictionary = {}
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append(checkpoint)
		_expect(kind == "encounter", "actual checkpoint retains its authored encounter-contact kind")
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
		_observe_blocker_path(record)
	)
	_game.resume_campaign()
	if not await _clear(["garden_handler"]) or not await _broadside_blocker("GardenStemBlocker"): return false
	_expect(defeats == ["garden_handler"] and _state().beat == "road_entry" and checkpoints.is_empty(), "garden primary and real broadside dash precede separate road contact")
	if not await _quiet_stage("road_entry") or not await _contact("road_entry", checkpoints): return false
	if not await _clear(["flood_scout", "flood_tender"]) or not await _finish_bank_tail("flood_bank"): return false
	_expect(defeats.size() == 3 and defeats.has("flood_scout") and defeats.has("flood_tender") and _state().beat == "villa_entry", "actual flood Scout/Tender defeats and unchanged tail earn villa entry")
	if not await _quiet_stage("villa_entry") or not await _contact("villa_entry", checkpoints): return false
	# The first courtyard removes its actual Ray before the remaining Handler.
	if not await _clear(["villa_scout"]) or not await _broadside_blocker("VillaLowWall") or not await _clear(["villa_ray_handler"]): return false
	_expect(defeats.find("villa_scout") < defeats.find("villa_ray_handler") and defeats.size() == 5 and _state().beat == "villa_tender_priority", "Scout-first courtyard earns direct next arrangement with no extra contact/wave")
	# The second courtyard removes the actual Tender before its Handler, while
	# retaining the original bank tail and executing counterpart escapes honestly.
	if not await _clear(["villa_tender"]) or not await _finish_bank_tail("villa_bank") or not await _clear(["villa_smoke_handler"]): return false
	_expect(defeats.find("villa_tender") < defeats.find("villa_smoke_handler") and defeats.size() == 7 and _state().beat == "putney_entry", "Tender-first courtyard preserves the next dry return and earns Putney entry")
	if not await _quiet_stage("putney_entry") or not await _contact("putney_entry", checkpoints) or not await _clear(["putney_scout", "putney_handler"]): return false
	for frame: int in range(600):
		if not _live(): return false
		if level.is_completed(): break
		await _step()
	var expected_checkpoints: Array[String] = []
	for contact: String in LONDON_CONTACT_ORDER: expected_checkpoints.append(LondonSequence.CONTACTS[contact].checkpoint)
	_expect(checkpoints == expected_checkpoints and level.current_checkpoint().id == expected_checkpoints.back(), "three real contact checkpoints commit exactly once in authored order")
	_expect(defeats.size() == 9 and defeats[0] == "garden_handler", "all nine actual HP sources are defeated without waves/respawn")
	for id: String in LondonSequence.ACTORS: _expect(defeats.count(id) == 1 and _actors[id].get("hp") == 0.0 and _actors[id].get("max_hp") == 30.0, "one actual required HP30 defeat without refill: " + id)
	_expect(_blocker_bypass_seen.size() == 2, "actual sampled capsule-clear broadside dashes pass both authored grounded blockers")
	_expect(_tail_pending.is_empty() and _tail_completed.size() == 2, "both defeated Tender banks finish their original finite independent tails")
	_expect(_state().beat == "clear" and _state().exit_open and level.is_completed() and completions == ["london-road-open"] and exits.is_empty(), "actual nine defeats/quiet banks complete once before separate Putney road contact")
	for source: String in ["flood_bank", "villa_bank", "tool_garden_handler", "tool_villa_ray_handler", "tool_villa_smoke_handler", "tool_putney_handler", "flood_scout", "villa_scout", "putney_scout"]:
		for phase: String in ["warning", "lock", "active", "recovery"]: _expect(_native_phases.get(source, {}).has(phase), "actual native %s observed %s" % [source, phase])
	if _capture_live:
		for settle_frame: int in range(8):
			if not _capture_pending and _captured.has("clear"): break
			await process_frame
		for family: String in ["smoke", "tool", "ray"]:
			for phase: String in ["warning", "lock", "active", "recovery"]: _expect(_captured.has(family + "-" + phase), "actual native source/phase portrait exists: " + family + "-" + phase)
		for beat: String in ["flood_margin", "villa_scout_priority", "villa_tender_priority", "putney_mix"]: _expect(_captured.has(beat.replace("_", "-") + "-actual-pair"), "actual mixed source portrait reports real armed flags: " + beat)
		for label: String in QUIET_LABELS.values() + STAGE_LABELS.values() + ["clear"]: _expect(_captured.has(label), "actual native scenic/stage/quiet-clear portrait exists: " + label)
	_game.request_pause()
	await _settle()
	var aggregate: Dictionary = _game.capture_campaign_snapshot()
	_expect(not aggregate.is_empty() and _game.campaign_error.is_empty() and _game.attempts.state().completed_main == LONDON_PREFIX + ["A2-L4"] and aggregate.level.progress.contact_exit_id.is_empty(), "actual paused shell records L4 completion with unopened distinct road exit: " + _game.campaign_error)
	if not aggregate.is_empty(): _expect(aggregate.level.local.sequence.crossed_contacts == LONDON_CONTACT_ORDER and aggregate.level.local.sequence.defeated_ids.size() == 9 and not aggregate.level.local.sequence.has("boss_phase"), "actual aggregate retains exact contacts/all9 defeats and ordinary-only sequence")
	var primary_hits: int = 0
	var dashes: int = 0
	for action: Dictionary in _actions:
		_expect(action.kind != "blast" and action.equipment_ids == _loadout and Codec.same_values(action.resolved_stats, _expected_stats), "real actions use unchanged canonical gear/stats and no blast")
		if action.kind == "primary": primary_hits += int(action.hits)
		elif action.kind == "dash": dashes += 1
	_expect(primary_hits >= 18 and dashes > 0 and hero.equipment.snapshot() == _loadout, "ordinary shared primaries and real sampled swipes supply nine totalHP30 targets")
	var old_nodes: Array[Node] = [level, hero, _game.fx, level.get_node("LondonApproachesDryGround"), level.get_node("LondonApproachesKit")]
	for node: Node in _actors.values(): old_nodes.append(node)
	for node: Node in _banks.values(): old_nodes.append(node)
	for node: Node in level.get("_mechanisms").values(): old_nodes.append(node)
	for cue: Node in get_nodes_in_group("required_cues"):
		if level.is_ancestor_of(cue): old_nodes.append(cue)
	_game.resume_campaign()
	if not await _dash_to_exit(): return false
	await _settle()
	_expect(_game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L5" and _game.active_level.scene_file_path == LONDON_DESTINATION, "actual Putney contact installs only injected TEST ONLY L5 destination")
	_expect(exits == ["putney-road"] and completions == ["london-road-open"], "real road exit occurs once without repeating completion")
	for old: Node in old_nodes: _expect(not is_instance_valid(old), "actual transition frees old L4 player/scenery/target/bank/tool/cue")
	_expect(_game.player.hp == resources_at_exit.get("hp") and _game.player.shells == resources_at_exit.get("shells") and _game.player.equipment.snapshot() == resources_at_exit.get("equipment") and not _game.active_level.is_completed(), "transition preserves exact resources/gear without claiming L5 gameplay")
	return _failures == 0

func _clear(ids: Array[String]) -> bool:
	for frame: int in range(2400):
		if not _live(): return _expect(false, "encounter stopped before %s: %s" % [ids, _diagnostic()])
		var living: Array[String] = []
		for id: String in ids:
			if float(_actors[id].get("hp")) > 0.0: living.append(id)
		if living.is_empty():
			for id: String in ids: _expect(_source_seen(id), "real target entered native warning/lock/active/recovery before its defeat: " + id)
			for settle_frame: int in range(4): await _step()
			print("London Approaches actual primary targets cleared: ", ids)
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

func _broadside_blocker(id: String) -> bool:
	var blocker: Dictionary = {}
	for item: Dictionary in LondonFloor.BLOCKERS:
		if item.id == id: blocker = item
	if not _expect(not blocker.is_empty(), "actual floor names the authored broadside blocker: " + id): return false
	if _blocker_bypass_seen.has(id): return _expect(true, "earlier real proof dash already passed capsule-clear around " + id)
	var side: float = -1.0 if _game.player.global_position.x < 0.0 else 1.0
	var clearance: float = float(blocker.size.x) * 0.5 + CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
	var front: float = float(blocker.at.z) + float(blocker.size.z) * 0.5 + 0.55
	var back: float = float(blocker.at.z) - float(blocker.size.z) * 0.5 - 0.55
	for attempt: int in range(18):
		if not _live(): return false
		var at: Vector3 = _game.player.global_position
		if absf(at.x) >= clearance + 0.15 and at.z > front: break
		if not await _navigate_dash(Vector3(side * 2.2, 0.0, maxf(at.z, front + 0.15))): return false
	for attempt: int in range(18):
		if not _live(): return false
		if _game.player.global_position.z < back and _stable(): return _expect(_blocker_bypass_seen.has(id), "actual grounded capsule-clear dash passes the broad side of " + id)
		if not await _navigate_dash(Vector3(side * 2.2, 0.0, back - 0.4)): return false
		for frame: int in range(180):
			if not _live(): return false
			if _stable(): break
			await _step()
	return _expect(false, "bounded real side swipes could not pass authored blocker: " + id + ": " + _diagnostic())

func _observe_blocker_path(record: Dictionary) -> void:
	if record.get("kind") != "dash": return
	for blocker: Dictionary in LondonFloor.BLOCKERS:
		var wall_z: float = blocker.at.z
		var clearance: float = float(blocker.size.x) * 0.5 + CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
		for index: int in range(1, record.path.size()):
			var start: Vector3 = record.path[index - 1].position
			var finish: Vector3 = record.path[index].position
			if is_equal_approx(start.z, finish.z) or (start.z - wall_z) * (finish.z - wall_z) > 0.0: continue
			var crossing: Vector3 = start.lerp(finish, (wall_z - start.z) / (finish.z - start.z))
			if absf(crossing.x) >= clearance and absf(crossing.y) < 0.05: _blocker_bypass_seen[blocker.id] = record.sequence

func _finish_bank_tail(id: String) -> bool:
	for frame: int in range(360):
		if not _live(): return false
		if _tail_completed.has(id): return _expect(not _tail_pending.has(id), "actual unchanged finite tail finished before leaving its portrait: " + id)
		var plan: Dictionary = _latest_actor_plan(_state().active_ids)
		if not plan.is_empty():
			_used_proofs[plan.key] = true
			if not await _follow_proof(plan, false): return false
		await _step()
	return _expect(false, "original admitted bank tail did not finish on real ticks: " + id + ": " + _diagnostic())

func _quiet_stage(beat: String) -> bool:
	if not _expect(_state().beat == beat and _tail_pending.is_empty(), "actual earned quiet stage retains no unfinished Tender tail: " + beat): return false
	if not _capture_live: return true
	# There are no active attacks here; render settling cannot delay a proof.
	for frame: int in range(8):
		if not _live(): return false
		await _step()
		await process_frame
		if not _capture_pending and _captured.has(QUIET_LABELS[beat]): return true
	return _expect(_captured.has(QUIET_LABELS[beat]), "actual quiet authored view completed normally: " + beat)

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
	var source: String = plan.source_id
	var role_key: String = "bank" if LondonSequence.TENDERS.has(plan.actor_id) else ("ray" if LondonSequence.RAYS.has(plan.actor_id) else "tool")
	if not _expect(Codec.same_values(plan.resolved_role, _expected_roles[role_key]) and is_equal_approx(float(reservation.active_from_s) - float(reservation.lock_from_s), float(_expected_roles[role_key].lock_s)) and float(reservation.active_from_s) - float(reservation.lock_from_s) >= 1.1 - 0.00001 and plan.proof.uses_blast == false and plan.proof.uses_invulnerability == false, "actual %s proof retains shared resolved role/full1.10 lock and ordinary-primary response" % source): return false
	for segment: Dictionary in plan.proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash", "ordinary_primary"]: continue
		while _live() and float(_state().clock_s) + 0.00001 < float(segment.start_s):
			if not _plan_current(plan) or not _replacement_plan(plan, attack).is_empty(): return true
			await _step()
		if not _live(): return false
		if not _plan_current(plan) or not _replacement_plan(plan, attack).is_empty(): return true
		if segment.kind == "ordinary_primary":
			if not _expect(float(segment.start_s) == float(plan.proof.primary_time_s) and float(segment.end_s) == float(plan.proof.response_complete_s) and float(plan.proof.response_complete_s) == float(plan.proof.primary_time_s) + float(_expected_stats.primary_cooldown) and float(segment.start_s) > float(reservation.active_until_s) and float(segment.end_s) <= float(reservation.recovery_until_s), "native proof retains the complete original canonical primary cadence inside recovery"): return false
			if not attack: continue
			var id: String = plan.actor_id
			var actor: Node3D = _actors[id] as Node3D
			var current: Dictionary = _state().exchanges[id]
			if float(actor.get("hp")) <= 0.0 or current.phase != "recovery": return true
			var direction: Vector3 = actor.global_position - _game.player.global_position
			direction.y = 0.0
			var hp_before: float = float(actor.get("hp"))
			var diagnostic: Dictionary = {"plan": plan, "hero_position": _game.player.global_position, "hero_response": _game.player.get_threat_response_state(), "range": _game.player.stats.primary_range, "distance": direction.length(), "actor_hp": hp_before, "actor_phase": actor.get("phase"), "current": current, "root": _state()}
			var hits: int = _routed_primary(direction.normalized())
			if hits <= 0: print("London Approaches zero-hit primary actual pre-action diagnostic: ", diagnostic)
			return _expect(hits > 0 and float(actor.get("hp")) < hp_before, "actual %s ordinary primary truly damages recovering %s" % [_loadout_name, id])
		var direction: Vector3 = segment.to - segment.from
		direction.y = 0.0
		if not await _dash(direction.normalized(), false, plan, segment): return false
		if _proof_dash_abandoned:
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
	if LondonSequence.TENDERS.has(id):
		for bank_id: String in LondonRoot.BANK_TO_TENDER:
			if LondonRoot.BANK_TO_TENDER[bank_id] == id: sources = [bank_id]
	elif LondonSequence.HANDLERS.has(id): sources = ["tool_" + id]
	for source: String in sources:
		for phase: String in ["warning", "lock", "active", "recovery"]:
			if not _native_phases.get(source, {}).has(phase): return false
	return true


func _observe_defeat(id: String) -> void:
	if not LondonSequence.TENDERS.has(id): return
	for bank_id: String in LondonRoot.BANK_TO_TENDER:
		if LondonRoot.BANK_TO_TENDER[bank_id] != id: continue
		var state: Dictionary = _banks[bank_id].call("state")
		_expect(state.status == "running" and state.phase == "recovery" and float(_actors[id].get("hp")) == 0.0 and not state.exchange.is_empty(), "ordinary Tender defeat preserves its independently running recovery tail: " + id)
		_tail_pending[bank_id] = state.duplicate(true)

func _observe_runtime() -> void:
	if not _live(): return
	var state: Dictionary = _state()
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
	var region: Rect2 = LondonSequence.CONTACTS[id].region
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
	return _expect(checkpoints.size() == before + 1 and checkpoints.back() == LondonSequence.CONTACTS[id].checkpoint and _game.active_level.current_checkpoint().id == checkpoints.back(), "actual contact commits exactly its authored checkpoint: " + id)

func _dash_to_exit() -> bool:
	for attempt: int in range(18):
		if _game.active_level.level_id != "A2-L4": return _expect(_game.active_level.level_id == "A2-L5" and _game.active_level.scene_file_path == LONDON_DESTINATION, "only actual Putney road navigation transitions to TEST ONLY L5")
		var region: Rect2 = LondonRoot.BREAKOUT
		if not await _navigate_dash(Vector3(region.get_center().x, 0, region.get_center().y), true): return false
		if _game.active_level.level_id != "A2-L4": return true
		if _dash_touches_region(_last_dash(), region):
			for frame: int in range(180):
				if _game.active_level.level_id != "A2-L4": return true
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
	if not _routed_swipe(direction): return false
	for frame: int in range(180):
		for action: Dictionary in _actions.slice(before):
			if action.kind == "dash": return _expect(action.landing.is_finite() and action.landing.y > -0.05 and action.path.size() >= 2, "actual completed dash has supported sampled world landing")
		if not is_instance_valid(hero):
			if allow_exit_transition and _game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L5" and _game.active_level.scene_file_path == LONDON_DESTINATION:
				return _expect(true, "actual breakout may transition during a dash without fabricating its unfinished world-action record")
			break
		await _step()
	return _expect(false, "shared dash did not publish a completed world action")

func _screen_delta(direction: Vector3) -> Vector2:
	var right: Vector3 = _game.camera.global_basis.x
	var down: Vector3 = _game.camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	return Vector2(direction.dot(right.normalized()), direction.dot(down.normalized())) * 120.0

func _routed_swipe(direction: Vector3) -> bool:
	var before: int = int(_game.get_input_observation_state().sequence)
	var start: Vector2 = Vector2(0.5, 0.60) * root.get_visible_rect().size
	var end: Vector2 = start + _screen_delta(direction)
	if not _expect(_game.screen_to_direction(end - start).is_equal_approx(direction.normalized()), "actual camera maps selected native dash to exact swipe direction"): return false
	var press := InputEventScreenTouch.new()
	press.index = 13; press.pressed = true; press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 13; drag.position = end; drag.relative = end - start
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 13; release.position = end
	root.push_input(release, true)
	var input: Dictionary = _game.get_input_observation_state()
	var dash: Dictionary = _game.player.get_committed_dash_state()
	return _expect(int(input.sequence) == before + 1 and input.last_observation.get("kind") == "swipe_release" and _game.get_aim_anchor_normalized().is_equal_approx(end / root.get_visible_rect().size) and dash.get("active", false) and dash.direction.is_equal_approx(direction.normalized()), "real routed swipe commits shared dash and exact final-release anchor")

func _routed_primary(direction: Vector3) -> int:
	var before: int = _actions.size()
	var input_before: int = int(_game.get_input_observation_state().sequence)
	var position: Vector2 = _game.get_aim_anchor() + _screen_delta(direction)
	if not _expect(_game.aim_direction(position).is_equal_approx(direction.normalized()), "actual first-tap aim derives from last swipe final release"): return 0
	var press := InputEventScreenTouch.new()
	press.index = 14; press.pressed = true; press.position = position
	root.push_input(press, true)
	var release := InputEventScreenTouch.new()
	release.index = 14; release.position = position
	root.push_input(release, true)
	var input: Dictionary = _game.get_input_observation_state()
	if not _expect(int(input.sequence) == input_before + 1 and input.last_observation.get("kind") == "primary_tap" and input.last_observation.get("accepted", false) and _actions.size() == before + 1 and _actions.back().kind == "primary", "real routed first tap immediately publishes one ordinary primary, no blast"): return 0
	return int(_actions.back().hits)

func _input_json() -> Dictionary:
	var value: Dictionary = _game.get_input_observation_state()
	var anchor: Vector2 = value.anchor_normalized
	value.anchor_normalized = [anchor.x, anchor.y]
	if not value.last_observation.is_empty():
		for key: String in ["screen_position_normalized", "anchor_normalized"]:
			var point: Vector2 = value.last_observation[key]
			value.last_observation[key] = [point.x, point.y]
		value.last_observation.direction = Codec.vector3(value.last_observation.direction)
	return value

func _read_options() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--loadout="): _loadout_name = argument.trim_prefix("--loadout=")
		elif argument.begins_with("--profile="): _profile_id = argument.trim_prefix("--profile=")
		elif argument == "--capture-live": _capture_live = true
	if not _expect(LOADOUTS.has(_loadout_name) and _profile_id in ["standard", "assisted", "challenge"], "supported existing loadout/profile selectors"): return false
	_loadout = LOADOUTS[_loadout_name].duplicate(true)
	_capture_root = LONDON_CAPTURE_ROOT
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
	preview.set("level_scene_path", LONDON_SCENE)
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
	var aggregate: Dictionary = {"schema_version": 1, "level_id": "A2-L4", "scene_path": LONDON_SCENE, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": actor_state, "level": local_state, "shell": shell_state}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var seed: Dictionary = model.state()
	seed.completed_main = LONDON_PREFIX.duplicate()
	# Synthetic preceding catalogue unlock metadata, not actual earlier-level
	# acceptance or L4 reward/progression/runtime equipment grant.
	for id: String in _loadout.values():
		if not seed.unlocked_equipment.has(id): seed.unlocked_equipment.append(id)
	print("TEST ONLY synthetic prior catalogue unlock metadata: ", _loadout.values())
	seed.story = {"kind": "story", "level_id": "A2-L4", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var store: CinderSaveStore = Store.new(LONDON_TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var seed_error: String = model.state_error(seed)
	var saved: bool = not actor_state.is_empty() and not local_state.is_empty() and seed_error.is_empty() and store.write_payload(seed)
	if not saved: print("London Approaches seed rejection: actor_error=%s level_error=%s runtime_error=%s model_error=%s store_error=%s actor_keys=%s level_keys=%s" % [hero.last_snapshot_error, level.last_snapshot_error, level.get("runtime_error"), seed_error, store.last_error, actor_state.keys(), local_state.keys()])
	_expect(saved, "TEST ONLY prefix throughL3 seeds real captured L4/Hero state: " + store.last_error)
	level.exit_level()
	preview.free()
	_expect(not is_instance_valid(hero) and not is_instance_valid(level), "seed Game/Hero/level freed before actual shell installation")
	return saved

func _state() -> Dictionary:
	return _game.active_level.call("encounter_state") if is_instance_valid(_game) and is_instance_valid(_game.active_level) and _game.active_level.level_id == "A2-L4" else {}

func _live() -> bool:
	return is_instance_valid(_game) and _game.campaign_error.is_empty() and is_instance_valid(_game.player) and not _game.player.dead and is_instance_valid(_game.active_level) and _game.active_level.level_id == "A2-L4" and String(_state().get("runtime_error", "")).is_empty()

func _step() -> void:
	# Render-frame waits may span several catch-up physics ticks. Keep native
	# planned dash sampling within the original strict one-tick limit instead.
	await _native_probe.tick_finished
	if is_instance_valid(_game) and paused and _game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L4" and _game.menu.page_name() == "resume" and not _game.player.dead: _game.resume_campaign()
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
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LONDON_TEST_ROOT + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LONDON_TEST_ROOT))

func _capture_labels(state: Dictionary) -> Array[String]:
	var labels: Array[String] = []
	for id: String in state.active_ids:
		var current: Dictionary = state.exchanges[id]
		if current.get("status") != "running" or current.get("phase") not in ["warning", "lock", "active", "recovery"]: continue
		var family: String = "smoke" if LondonSequence.TENDERS.has(id) else ("ray" if LondonSequence.RAYS.has(id) else "tool")
		var label: String = family + "-" + String(current.phase)
		if not _captured.has(label) and not labels.has(label): labels.append(label)
	if STAGE_LABELS.has(state.beat):
		var running: int = 0
		for id: String in state.active_ids:
			if state.exchanges[id].get("status") == "running": running += 1
		var pair_label: String = String(state.beat).replace("_", "-") + "-actual-pair"
		if running == 2 and not _captured.has(pair_label): labels.append(pair_label)
		if running > 0 and not _captured.has(STAGE_LABELS[state.beat]): labels.append(STAGE_LABELS[state.beat])
	if QUIET_LABELS.has(state.beat) and _tail_pending.is_empty() and not _captured.has(QUIET_LABELS[state.beat]): labels.append(QUIET_LABELS[state.beat])
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
	var hero_points: Array[Vector3] = []
	hero_points.assign(_game.call("player_camera_framing_points"))
	if not _expect(_raw_camera_error(hero_points).is_empty(), "actual post-draw full Hero stays HUD-safe"): return
	if not _expect(image != null and image.get_size() == Vector2i(540, 1170), "actual L4 render is native540x1170"): return
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
		var path: String = _capture_root + "a2-l4-" + _profile_id + "-" + _loadout_name + "-" + label + ".png"
		if not _expect(image.save_png(path) == OK, "save actual native L4 state " + label): return
		_captured[label] = {"image": path, "level_id": "A2-L4", "loadout": _loadout_name, "profile": _profile_id, "beat": state.beat, "clock_s": state.clock_s, "hero_position": Codec.vector3(_game.player.global_position), "hero_hp": _game.player.hp, "shells": _game.player.shells, "world_action_count": _actions.size(), "input": _input_json(), "actors": actor_observations.duplicate(true), "banks": bank_observations.duplicate(true), "camera_position": Codec.vector3(_game.camera.global_position), "camera_size": _game.camera.size}
		print("Actual London Approaches portrait: ", path)
	var file: FileAccess = FileAccess.open(_capture_root + "a2-l4-" + _profile_id + "-" + _loadout_name + "-evidence.json", FileAccess.WRITE)
	if _expect(file != null, "open ignored actual L4 capture metadata"):
		file.store_string(JSON.stringify({"scope": "Actual authored L4 dash/ordinary-primary route; synthetic preceding prefix/unlocks/profile and TEST ONLY L5 destination. Each mixed source reports its actual armed flag. Actual viewport touch swipes/taps and final-release aim are recorded. Native pixels require separate source/readability review; no human/device/balance acceptance", "frames": _captured}, "\t", true, true))

func _deadline_json(exchange: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if exchange.has(key): result[key] = exchange[key]
	return result
