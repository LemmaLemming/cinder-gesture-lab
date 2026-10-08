extends SceneTree
## Actual Weybridge route through the shared CampaignShell. The preceding
## completed prefix/unlocks/profile and destination are TEST ONLY prerequisites,
## not evidence of Act1, Horsell or L3 gameplay/canonical acceptance.
## The bot observes actual proofs and requests real dashes/ordinary primaries.
## No live HP/ammo/transform/phase assignment or manufactured progression.
## --loadout=standard/heavy/slow_cargo_longstep/slow_padded_reach/quick
## --profile=standard/assisted/challenge; --capture-live requires native graphics.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ProfileSeedGame: Script = preload("res://tests/acts/act2/fixtures/a2_l1_profile_seed_game.gd")
const Shell: Script = preload("res://scripts/campaign/shell.gd")
const Registry: Script = preload("res://scripts/campaign/registry.gd")
const Attempts: Script = preload("res://scripts/campaign/attempts.gd")
const Store: Script = preload("res://scripts/campaign/save_store.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Equipment: Script = preload("res://scripts/equipment.gd")
const Difficulty: Script = preload("res://scripts/combat/difficulty.gd")
const RayExchange: Script = preload("res://scripts/acts/act2/ray_scout_exchange.gd")
const Sequence: Script = preload("res://scripts/acts/act2/weybridge_sequence.gd")
const Weybridge: Script = preload("res://scripts/acts/act2/weybridge.gd")
const Mechanism: Script = preload("res://scripts/combat/lane_mechanism.gd")
const LevelPath: String = "res://scenes/acts/act2/a2_l2.tscn"
const NextPath: String = "res://tests/acts/act2/fixtures/a2_l2_transition_destination.tscn"
const TEST_ROOT: String = "user://test-a2-l2-live-level/"
const PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5", "A2-L1"]
const CONTACT_ORDER: Array[String] = ["yard_exit", "before_crossing", "far_apron", "before_shelter"]
const LOADOUTS: Dictionary = {
	"standard": {"weapon": "WEAPON-01", "jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0"},
	"heavy": {"weapon": "WEAPON-03", "jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0"},
	"slow_cargo_longstep": {"weapon": "WEAPON-03", "jacket": "CLOTH-J1", "pants": "CLOTH-P2", "shoes": "CLOTH-S2"},
	"slow_padded_reach": {"weapon": "WEAPON-03", "jacket": "CLOTH-J1", "pants": "CLOTH-P1", "shoes": "CLOTH-S0"},
	"quick": {"weapon": "WEAPON-02", "jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0"},
}
const CAPTURE_ROOT: String = "res://captures/act2/live/"
var _checks: int = 0
var _failures: int = 0
var _game: CinderCampaignShell
var _actors: Dictionary = {}
var _actions: Array[Dictionary] = []
var _used_proofs: Dictionary = {}
var _canonical: String = ""
var _l1_fixture_bytes: String = ""
var _loadout_name: String = "heavy"
var _loadout: Dictionary = LOADOUTS.heavy.duplicate(true)
var _expected_stats: Dictionary = {}
var _profile_id: String = "standard"
var _expected_roles: Dictionary = {}
var _capture_live: bool = false
var _captured: Dictionary = {}
var _foot_completed: Array[String] = []
var _foot_phases: Dictionary = {}
var _foot_primaries: Dictionary = {}
var _paired_seen: Dictionary = {}
var _proof_dash_abandoned: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not _read_options():
		quit(1)
		return
	root.size = Vector2i(540, 1170)
	if _capture_live and not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_ROOT)) == OK, "create ignored native portrait directory"):
		quit(1)
		return
	print("Weybridge actual route scope: loadout=%s profile=%s IDs=%s; initial zero ammo, ordinary primary, four HP-free foot cycles; TEST ONLY prefix/unlocks/profile/destination" % [_loadout_name, _profile_id, _loadout])
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_l1_fixture_bytes = FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn")
	_cleanup()
	var failures_before: int = _failures
	if not await _run_route() and _failures == failures_before:
		_expect(false, "actual L2 route aborted: " + _diagnostic())
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn") == _l1_fixture_bytes, "test injection preserves canonical registry and existing L1 fixture bytes")
	if is_instance_valid(_game): _game.free()
	_game = null
	paused = false
	_cleanup()
	print("Weybridge live level smoke: %d checks, %d failures; loadout=%s profile=%s; actual authored L2 actions, synthetic prior prefix and TEST ONLY L3 destination" % [_checks, _failures, _loadout_name, _profile_id])
	quit(0 if _failures == 0 else 1)

func _run_route() -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L2", "A2-L3"]:
			info.scene_path = LevelPath if info.id == "A2-L2" else NextPath
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L3").is_empty(), "injected TEST ONLY L3 scene uses matching exported identity and shared level contract") or not await _seed(registry): return false
	_game = Shell.new() as CinderCampaignShell
	_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json")
	root.add_child(_game)
	await _settle()
	_game.menu.difficulty_preference_requested.emit(_profile_id)
	_game.resume_campaign()
	await _settle()
	if not _expect(_live() and _game.active_level.scene_file_path == LevelPath, "actual CampaignShell installs Weybridge: " + _game.campaign_error): return false
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	var installed: Dictionary = level.snapshot_state()
	if not _expect(not installed.is_empty() and installed.local.profile_id == _profile_id and Codec.same_values(installed.local.rays.configuration.resolved_role, _expected_roles.ray), "actual shell restores the chosen fixed canonical profile/role"): return false
	if not _expect(hero.presentation_id == "act2_survivor" and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats) and hero.shells == 0, "real L2 entry retains Act2 presentation, canonical selected gear/stats and initial zero ammo"): return false
	if _loadout_name == "heavy": _expect(is_equal_approx(float(hero.stats.primary_range), 1.8), "Heavy uses actual shortest shared primary reach")
	_actors = level.get("_actors").duplicate()
	if not _expect(_actors.size() == 6 and _state().mechanisms.size() == 7 and not _contains_pickup(level), "six authored HP targets and three tool/four foot mechanisms; no victory pickups"): return false
	var defeats: Array[String] = []
	for actor: Node in _actors.values(): actor.connect("defeated", func(id: String) -> void: defeats.append(id))
	var checkpoints: Array[String] = []
	var completions: Array[String] = []
	var exits: Array[String] = []
	var resources_at_exit: Dictionary = {}
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append(checkpoint)
		_expect(kind == "encounter", "actual contact checkpoint uses shared encounter boundary")
	)
	level.completion_requested.connect(func(_id: String, completion: String) -> void: completions.append(completion))
	level.contact_exit_requested.connect(func(_id: String, exit_id: String) -> void:
		exits.append(exit_id)
		resources_at_exit["hp"] = hero.hp
		resources_at_exit["shells"] = hero.shells
		resources_at_exit["equipment"] = hero.equipment.snapshot()
	)
	hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	_game.resume_campaign()
	if not await _clear(["village_scout"]) or not await _clear(["yard_handler"]): return false
	_expect(defeats == ["village_scout", "yard_handler"] and _state().beat == "yard_exit" and checkpoints.is_empty(), "village Scout then lone yard Handler are real defeats before the first contact")
	if not await _contact("yard_exit", checkpoints): return false
	if not await _complete_foot("foot_demo"): return false
	_expect(_state().beat == "apron_pair" and defeats.size() == 2, "isolated foot completes without an attack/HP defeat")
	if not await _complete_foot("foot_apron") or not await _clear(["apron_handler"]): return false
	_expect(_paired_seen.has("foot_apron") and _state().beat == "before_crossing", "actual apron Handler and foot are admitted together before the next boundary")
	if not await _contact("before_crossing", checkpoints): return false
	if not await _complete_foot("foot_left") or not await _complete_foot("foot_right") or not await _clear(["crossing_scout"]): return false
	_expect(_paired_seen.has("foot_left") and _paired_seen.has("foot_right") and _state().beat == "far_apron", "two actual alternating foot patches coexist with the short crossing Scout encounter")
	if not await _contact("far_apron", checkpoints) or not await _contact("before_shelter", checkpoints): return false
	if not await _clear(["shelter_scout", "shelter_handler"]): return false
	await _settle()
	var expected_checkpoints: Array[String] = []
	for contact: String in CONTACT_ORDER: expected_checkpoints.append(Sequence.CONTACTS[contact].checkpoint)
	_expect(checkpoints == expected_checkpoints and level.current_checkpoint().id == expected_checkpoints.back(), "exact four actual contact checkpoints commit in authored order")
	_expect(defeats.slice(0, 4) == ["village_scout", "yard_handler", "apron_handler", "crossing_scout"] and defeats.size() == 6 and defeats.has("shelter_scout") and defeats.has("shelter_handler"), "six HP defeats follow the canonical prefix and either final mixed-pair order")
	_expect(_foot_completed == ["foot_demo", "foot_apron", "foot_left", "foot_right"], "four actual completed foot opportunities retain exact order")
	_expect(_state().beat == "clear" and _state().exit_open and level.is_completed() and completions == ["weybridge-crossing-clear"] and exits.is_empty(), "actual six defeats/four feet open shelter and complete once before separate exit contact")
	if _capture_live:
		for frame: int in range(90): await _step() # Normal scene time; exit has already opened.
		for label: String in ["ray-warning", "ray-lock", "ray-active", "ray-recovery", "tool-warning", "tool-lock", "tool-active", "tool-recovery", "foot-demo-active", "foot-apron-active", "foot-left-active", "foot-right-active", "apron-combination", "shelter-mix", "clear", "collapse"]:
			_expect(_captured.has(label), "actual native story capture exists: " + label)
	_game.request_pause()
	await _settle()
	var aggregate: Dictionary = _game.capture_campaign_snapshot()
	_expect(not aggregate.is_empty() and _game.campaign_error.is_empty() and _game.attempts.state().completed_main == PREFIX + ["A2-L2"] and aggregate.level.progress.contact_exit_id.is_empty(), "shell records actual L2 clear with distinct unentered exit: " + _game.campaign_error)
	if not aggregate.is_empty(): _expect(aggregate.level.local.sequence.completed_feet == _foot_completed and aggregate.level.local.sequence.crossed_contacts == CONTACT_ORDER, "paused actual aggregate contains all earned feet and contacts")
	var primary_hits: int = 0
	var dashes: int = 0
	for action: Dictionary in _actions:
		_expect(action.kind != "blast" and action.equipment_ids == _loadout and Codec.same_values(action.resolved_stats, _expected_stats), "actual action uses unchanged selected canonical stats with no blast")
		if action.kind == "primary": primary_hits += int(action.hits)
		elif action.kind == "dash": dashes += 1
	_expect(primary_hits >= 6 and dashes > 0 and hero.equipment.snapshot() == _loadout, "ordinary shared primary and sampled dashes supply all six HP defeats")
	var old_nodes: Array[Node] = [level, hero, _game.fx, level.get_node("DryGround"), level.get_node("WeybridgeSceneryKit"), level.get_node("OneVisibleGiantFoot")]
	for actor: Node in _actors.values(): old_nodes.append(actor)
	for node: Node in level.get("_mechanisms").values(): old_nodes.append(node)
	for cue: Node in get_nodes_in_group("required_cues"):
		if level.is_ancestor_of(cue): old_nodes.append(cue)
	_game.resume_campaign()
	if not await _dash_to_exit(): return false
	await _settle()
	_expect(_game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L3" and _game.active_level.scene_file_path == NextPath, "actual shelter contact installs only the injected TEST ONLY L3 destination")
	_expect(exits == ["weybridge-shelter"] and completions == ["weybridge-crossing-clear"], "real shelter contact exits once without repeating completion")
	for old: Node in old_nodes: _expect(not is_instance_valid(old), "actual transition frees old L2 player/scenery/actor/floor/foot/mechanism/cue")
	_expect(_game.player.hp == resources_at_exit.get("hp") and _game.player.shells == resources_at_exit.get("shells") and _game.player.equipment.snapshot() == resources_at_exit.get("equipment") and not _game.active_level.is_completed(), "transition preserves exact resources/gear without claiming L3 gameplay")
	return _failures == 0

func _clear(ids: Array[String]) -> bool:
	var seen_running: Dictionary = {}
	for frame: int in range(2400):
		if not _live(): return _expect(false, "encounter stopped before %s: %s" % [ids, _diagnostic()])
		var living: Array[String] = []
		for id: String in ids:
			if float(_actors[id].get("hp")) > 0.0: living.append(id)
		if living.is_empty():
			for id: String in ids: _expect(seen_running.has(id), "actual target entered a running exchange: " + id)
			for settle_frame: int in range(4): await _step()
			print("Weybridge actual primary targets cleared: ", ids)
			return true
		for id: String in living:
			if _state().exchanges[id].get("status") == "running": seen_running[id] = true
		var latest: Dictionary = _latest_actor_plan(living)
		if not latest.is_empty():
			_used_proofs[latest.key] = true
			if not await _follow_proof(latest, true): return false
		elif frame % 90 == 0:
			var target: Node3D = _actors[living[0]] as Node3D
			var offset: Vector3 = _game.player.global_position - target.global_position
			offset.y = 0.0
			if offset.length() > 3.45 and not await _navigate_dash(target.global_position + offset.normalized() * 3.0): return false
		await _step()
	return _expect(false, "bounded ordinary-primary bot could not clear %s: %s" % [ids, _diagnostic()])

func _complete_foot(id: String) -> bool:
	var before_primary: int = _primary_count()
	var phases: Dictionary = _foot_phases.get(id, {})
	_foot_phases[id] = phases
	for frame: int in range(2400):
		if not _live(): return _expect(false, "foot opportunity stopped: " + _diagnostic())
		var state: Dictionary = _state()
		var actual: Dictionary = state.mechanisms[id]
		if actual.status == "complete" and state.foot_id != id:
			_foot_completed.append(id)
			_foot_phases[id] = phases
			_foot_primaries[id] = _primary_count() - before_primary
			_expect(_primary_count() == before_primary, "actual foot opportunity needs no primary/HP attack: " + id)
			_expect(phases.has("lock") and phases.has("active") and phases.has("recovery"), "actual visible foot traverses lock/active/recovery: " + id)
			_expect(actual.geometry.get("kind") == "circle" and actual.source_position == Sequence.FEET[id] and actual.hit_ids.is_empty(), "actual foot uses its authored circular source and proved movement avoids a swept hit: " + id)
			print("Weybridge actual HP-free foot completed: ", id)
			return true
		if state.foot_id != id: return _expect(false, "unexpected authored foot order for " + id + ": " + _diagnostic())
		if actual.status == "running":
			phases[actual.phase] = true
			var target_id: String = "apron_handler" if id == "foot_apron" else ("crossing_scout" if id in ["foot_left", "foot_right"] else "")
			if not target_id.is_empty() and state.exchanges[target_id].status == "running" and _reservation(String(state.exchanges[target_id].reservation_id)).get("armed", false): _paired_seen[id] = true
		var plan: Dictionary = _mechanism_plan(id, "")
		if not plan.is_empty() and not _used_proofs.has(plan.key):
			_used_proofs[plan.key] = true
			if not await _follow_proof(plan, false): return false
		elif frame % 90 == 0 and actual.status != "running":
			var at: Vector3 = Sequence.FEET[id]
			var counterpart: String = "apron_handler" if id == "foot_apron" else ("crossing_scout" if id in ["foot_left", "foot_right"] else "")
			if not counterpart.is_empty() and float(_actors[counterpart].get("hp")) > 0.0 and _game.player.global_position.distance_to(_actors[counterpart].global_position) > 3.45:
				# The pair's real target must also be close enough for admission.
				# A foot-only approach can stop while the Handler/Scout stays idle.
				at = _actors[counterpart].global_position
			var offset: Vector3 = _game.player.global_position - at
			offset.y = 0.0
			if offset.length() > 3.45 and not await _navigate_dash(at + offset.normalized() * 3.0): return false
		await _step()
	return _expect(false, "bounded bot found no actual completed foot opportunity %s: %s" % [id, _diagnostic()])

func _observe_runtime() -> void:
	if not _live(): return
	var state: Dictionary = _state()
	var foot: String = state.foot_id
	if not foot.is_empty() and state.mechanisms[foot].status == "running":
		if not _foot_phases.has(foot): _foot_phases[foot] = {}
		_foot_phases[foot][state.mechanisms[foot].phase] = true
		var target: String = "apron_handler" if foot == "foot_apron" else ("crossing_scout" if foot in ["foot_left", "foot_right"] else "")
		if not target.is_empty() and state.exchanges[target].status == "running" and _reservation(String(state.exchanges[target].reservation_id)).get("armed", false): _paired_seen[foot] = true

func _latest_actor_plan(ids: Array[String]) -> Dictionary:
	var latest: Dictionary = {}
	for id: String in ids:
		var current: Dictionary = _state().exchanges.get(id, {})
		var plan: Dictionary = _mechanism_plan("tool_" + id, id) if Sequence.HANDLERS.has(id) else _make_plan(id, id, current, current.get("proof", {}))
		if plan.is_empty() or _used_proofs.has(plan.key): continue
		if latest.is_empty() or float(plan.reservation.lock_from_s) > float(latest.reservation.lock_from_s): latest = plan
	return latest

func _mechanism_plan(id: String, actor_id: String) -> Dictionary:
	var current: Dictionary = _state().mechanisms.get(id, {})
	var proof: Dictionary = _game.active_level.call("mechanism_proof", id)
	return _make_plan(id, actor_id, current, proof)

func _make_plan(id: String, actor_id: String, current: Dictionary, proof: Dictionary) -> Dictionary:
	if current.get("status") != "running" or not proof.get("accepted", false): return {}
	var reservation: Dictionary = _reservation(String(current.get("reservation_id", "")))
	if reservation.is_empty() or not reservation.get("armed", false): return {}
	return {"source_id": id, "actor_id": actor_id, "key": "%s:%s:%s" % [id, current.get("cycle", -1), current.reservation_id], "cycle": current.cycle, "reservation": reservation, "proof": proof.duplicate(true), "resolved_role": current.resolved_role}

func _follow_proof(plan: Dictionary, attack: bool) -> bool:
	var reservation: Dictionary = plan.reservation
	var source: String = plan.source_id
	var role_key: String = "foot" if Sequence.FEET.has(source) else ("tool" if source.begins_with("tool_") else "ray")
	if not _expect(Codec.same_values(plan.resolved_role, _expected_roles[role_key]) and is_equal_approx(float(reservation.active_from_s) - float(reservation.lock_from_s), float(_expected_roles[role_key].lock_s)) and float(reservation.active_from_s) - float(reservation.lock_from_s) >= 1.1 - 0.00001, "actual %s witness retains selected shared role and full1.10 lock" % source): return false
	for segment: Dictionary in plan.proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash", "ordinary_primary"]: continue
		while _live() and float(_state().clock_s) + 0.00001 < float(segment.start_s):
			if not _plan_current(plan): return true
			var replacement: Dictionary = _replacement_plan(plan, attack)
			if not replacement.is_empty(): return true
			await _step()
		if not _live(): return false
		if not _plan_current(plan): return true
		if not _replacement_plan(plan, attack).is_empty(): return true
		if segment.kind == "ordinary_primary":
			if not attack: continue # HP-free foot witness; all movement is real.
			var id: String = plan.actor_id
			var actor: Node3D = _actors[id] as Node3D
			var current: Dictionary = _state().exchanges[id]
			if float(actor.get("hp")) <= 0.0 or current.phase != "recovery": return true
			var direction: Vector3 = actor.global_position - _game.player.global_position
			direction.y = 0.0
			var before: Dictionary = {"plan": plan, "hero_position": _game.player.global_position, "hero_response": _game.player.get_threat_response_state(), "range": _game.player.stats.primary_range, "distance": direction.length(), "actor_hp": actor.get("hp"), "actor_phase": actor.get("phase"), "current": current, "root": _state()}
			var hits: int = _game.player.slash(direction.normalized())
			if hits <= 0: print("Weybridge zero-hit primary actual pre-action diagnostic: ", before)
			return _expect(hits > 0, "actual %s ordinary primary reaches recovering %s" % [_loadout_name, id])
		var direction: Vector3 = segment.to - segment.from
		direction.y = 0.0
		if not await _dash(direction.normalized(), false, plan, segment): return false
		if _proof_dash_abandoned: return true
	return true

func _replacement_plan(plan: Dictionary, attack: bool) -> Dictionary:
	var candidate: Dictionary = _latest_actor_plan(_state().active_ids) if attack else _mechanism_plan(plan.source_id, "")
	if candidate.is_empty() or candidate.key == plan.key or _used_proofs.has(candidate.key): return {}
	return candidate if float(candidate.reservation.lock_from_s) > float(plan.reservation.lock_from_s) else {}

func _plan_current(plan: Dictionary) -> bool:
	var current: Dictionary = _state().mechanisms.get(plan.source_id, {}) if _state().mechanisms.has(plan.source_id) else _state().exchanges.get(plan.source_id, {})
	var live: Dictionary = _reservation(String(current.get("reservation_id", "")))
	return current.get("status") == "running" and current.get("cycle") == plan.cycle and current.get("reservation_id") == plan.reservation.id and not live.is_empty() and live.get("armed", false)

func _proof_dash_current(plan: Dictionary, segment: Dictionary) -> bool:
	if not _plan_current(plan) or not _replacement_plan(plan, not String(plan.actor_id).is_empty()).is_empty(): return false
	# One native physics tick accounts for sampling an authored planned start;
	# extra readiness/cooldown waiting abandons this proof instead of moving late.
	var sample_s: float = 1.0 / float(Engine.physics_ticks_per_second)
	return float(_state().clock_s) <= float(segment.start_s) + sample_s + 0.00001

func _reservation(id: String) -> Dictionary:
	var scheduler: Node = _game.active_level.get("_scheduler") as Node
	return scheduler.call("reservation_state", id) if is_instance_valid(scheduler) and not id.is_empty() else {}

func _contact(id: String, checkpoints: Array[String]) -> bool:
	if not _expect(_state().beat == id, "actual route reaches contact beat " + id): return false
	var region: Rect2 = Sequence.CONTACTS[id].region
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
	return _expect(checkpoints.size() == before + 1 and checkpoints.back() == Sequence.CONTACTS[id].checkpoint and _game.active_level.current_checkpoint().id == checkpoints.back(), "contact commits exactly its authored checkpoint: " + id)

func _dash_to_exit() -> bool:
	for attempt: int in range(18):
		if _game.active_level.level_id != "A2-L2": return _expect(_game.active_level.level_id == "A2-L3" and _game.active_level.scene_file_path == NextPath, "only shelter navigation transitions to TEST ONLY L3")
		var region: Rect2 = Weybridge.SHELTER_EXIT
		if not await _navigate_dash(Vector3(region.get_center().x, 0, region.get_center().y), true): return false
		if _game.active_level.level_id != "A2-L2": return true
		if _dash_touches_region(_last_dash(), region):
			for frame: int in range(180):
				if _game.active_level.level_id != "A2-L2": return true
				await _step()
	return _expect(false, "actual shelter contact failed to transition: " + _diagnostic())

func _stable() -> bool:
	var response: Dictionary = _game.player.get_threat_response_state()
	return response.get("stable", false) and float(response.get("commitment_remaining_s", 1.0)) <= 0.00001

func _dash_touches_region(record: Dictionary, region: Rect2) -> bool:
	if record.get("kind") != "dash" or not record.get("path") is Array: return false
	var points: Array[Vector2] = []
	for sample: Dictionary in record.path:
		var point: Variant = sample.get("position")
		if not point is Vector3 or not point.is_finite() or point.y < -0.05 or point.y > 0.2: return false
		points.append(Vector2(point.x, point.z))
		if region.has_point(points.back()): return true
	var corners: Array[Vector2] = [region.position, region.position + Vector2(region.size.x, 0), region.end, region.position + Vector2(0, region.size.y)]
	for index: int in range(1, points.size()):
		for edge: int in range(4):
			if Geometry2D.segment_intersects_segment(points[index - 1], points[index], corners[edge], corners[(edge + 1) % 4]) != null: return true
	return false

func _primary_count() -> int:
	var count: int = 0
	for action: Dictionary in _actions:
		if action.kind == "primary": count += 1
	return count

func _read_options() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--loadout="): _loadout_name = argument.trim_prefix("--loadout=")
		elif argument.begins_with("--profile="): _profile_id = argument.trim_prefix("--profile=")
		elif argument == "--capture-live": _capture_live = true
	if not _expect(LOADOUTS.has(_loadout_name) and _profile_id in ["standard", "assisted", "challenge"], "supported existing loadout/profile selectors"): return false
	_loadout = LOADOUTS[_loadout_name].duplicate(true)
	var resolver: CinderEquipment = Equipment.new() as CinderEquipment
	if not _expect(resolver.restore(_loadout), "selected equipment IDs are implemented canonical records"): return false
	_expected_stats = resolver.resolved_stats()
	var difficulty: RefCounted = Difficulty.new()
	_expected_roles = {"ray": difficulty.call("resolve_role", RayExchange.RAW_ROLE, _profile_id, RayExchange.TIMING_FLOORS), "tool": difficulty.call("resolve_role", Weybridge.TOOL_ROLE, _profile_id, Weybridge.TOOL_FLOORS), "foot": difficulty.call("resolve_role", Mechanism.DEFAULT_RAW_ROLE, _profile_id, Mechanism.DEFAULT_TIMING_FLOORS)}
	for role: Dictionary in _expected_roles.values():
		if not _expect(not role.is_empty(), "shared resolver accepts fixed profile without retuning role"): return false
	return _expect(not _capture_live or DisplayServer.get_name() != "headless", "native capture requires graphical engine session")

func _capture_state() -> void:
	if not _capture_live or not _live() or paused: return
	var labels: Array[String] = _capture_labels(_state())
	if labels.is_empty(): return
	# Render only actual current scene state; no phase/pose/clock assignment.
	await RenderingServer.frame_post_draw
	if not _live() or paused: return
	var state: Dictionary = _state()
	var current_labels: Array[String] = _capture_labels(state)
	var image: Image = root.get_texture().get_image()
	if not _expect(image.get_size() == Vector2i(540, 1170), "actual L2 render is native540x1170"): return
	var actor_observations: Dictionary = {}
	for id: String in state.active_ids:
		var current: Dictionary = state.exchanges[id]
		var reservation: Dictionary = _reservation(String(current.get("reservation_id", "")))
		var rig: Node = _actors[id].get_node("HandlerRig" if Sequence.HANDLERS.has(id) else "ScoutRig")
		actor_observations[id] = {"phase": current.phase, "status": current.status, "cycle": current.cycle, "armed": reservation.get("armed", false), "source_position": Codec.vector3(_actors[id].global_position), "hp": _actors[id].get("hp"), "reservation_id": current.get("reservation_id", ""), "geometry": _geometry_json(current.get("geometry", {})), "readability": rig.call("readability_state")}
	var foot_observation: Dictionary = {}
	if not String(state.foot_id).is_empty():
		var foot_state: Dictionary = state.mechanisms[state.foot_id]
		var reservation: Dictionary = _reservation(String(foot_state.get("reservation_id", "")))
		var proof: Dictionary = _game.active_level.call("mechanism_proof", state.foot_id)
		foot_observation = {"id": state.foot_id, "phase": foot_state.phase, "status": foot_state.status, "cycle": foot_state.cycle, "armed": reservation.get("armed", false), "geometry": _geometry_json(foot_state.geometry), "opening_position": Codec.vector3(foot_state.opening_position), "landing": Codec.vector3(proof.landing) if proof.has("landing") else [], "attack_position": Codec.vector3(proof.attack_position) if proof.has("attack_position") else []}
	for label: String in labels:
		if _captured.has(label) or not current_labels.has(label): continue
		var path: String = CAPTURE_ROOT + "a2-l2-" + _profile_id + "-" + _loadout_name + "-" + label + ".png"
		if not _expect(image.save_png(path) == OK, "save actual native L2 state " + label): return
		var kit: Node = _game.active_level.get_node("WeybridgeSceneryKit")
		var collapse: Node3D = kit.get_node("DistantArtilleryTripodCollapse") as Node3D
		_captured[label] = {"image": path, "level_id": "A2-L2", "loadout": _loadout_name, "profile": _profile_id, "beat": state.beat, "clock_s": state.clock_s, "hero_position": Codec.vector3(_game.player.global_position), "hero_hp": _game.player.hp, "shells": _game.player.shells, "world_action_count": _actions.size(), "actors": actor_observations.duplicate(true), "foot": foot_observation.duplicate(true), "tableau_state": kit.get_meta("tableau_state", ""), "tableau_progress": kit.get_meta("tableau_progress", 0.0), "collapse_visible": collapse.is_visible_in_tree(), "collapse_progress": collapse.get_meta("collapse_progress", 0.0)}
		print("Actual Weybridge portrait: ", path)
	var file: FileAccess = FileAccess.open(CAPTURE_ROOT + "a2-l2-" + _profile_id + "-" + _loadout_name + "-evidence.json", FileAccess.WRITE)
	if _expect(file != null, "open ignored actual L2 capture metadata"):
		file.store_string(JSON.stringify({"scope": "actual authored L2 dash/primary bot; synthetic preceding prefix/unlocks/profile and TEST ONLY L3 destination; mixed states report each actual armed flag, never imply two armed locks; no human balance or future-level acceptance", "frames": _captured}, "\t", true, true))

func _capture_labels(state: Dictionary) -> Array[String]:
	var labels: Array[String] = []
	for id: String in state.active_ids:
		var current: Dictionary = state.exchanges[id]
		if current.status == "running" and current.phase in ["warning", "lock", "active", "recovery"]:
			var label: String = ("tool-" if Sequence.HANDLERS.has(id) else "ray-") + String(current.phase)
			if not _captured.has(label) and not labels.has(label): labels.append(label)
	var foot: String = state.foot_id
	if not foot.is_empty() and state.mechanisms[foot].status == "running" and state.mechanisms[foot].phase == "active":
		var label: String = foot.replace("_", "-") + "-active"
		if not _captured.has(label): labels.append(label)
	if state.beat == "apron_pair" and state.mechanisms.foot_apron.status == "running" and state.exchanges.apron_handler.status == "running" and not _captured.has("apron-combination"): labels.append("apron-combination")
	if state.beat == "shelter_pair" and state.exchanges.shelter_scout.status == "running" and state.exchanges.shelter_handler.status == "running" and not _captured.has("shelter-mix"): labels.append("shelter-mix")
	if state.beat == "clear":
		if not _captured.has("clear"): labels.append("clear")
		var collapse: Node3D = _game.active_level.get_node("WeybridgeSceneryKit/DistantArtilleryTripodCollapse") as Node3D
		if collapse.is_visible_in_tree() and float(collapse.get_meta("collapse_progress", 0.0)) >= 0.65 and not _captured.has("collapse"): labels.append("collapse")
	return labels

func _geometry_json(shape: Dictionary) -> Dictionary:
	if shape.is_empty(): return {}
	if shape.get("kind") == "circle": return {"kind": "circle", "origin": Codec.vector3(shape.origin), "radius": shape.radius}
	return {"kind": "lane", "from": Codec.vector3(shape.from), "to": Codec.vector3(shape.to), "radius": shape.radius}

func _seed(registry: CinderCampaignRegistry) -> bool:
	var preview: Node = MainScene.instantiate()
	preview.set_script(ProfileSeedGame)
	preview.set("test_profile_id", _profile_id)
	preview.set("level_scene_path", LevelPath)
	root.add_child(preview)
	paused = true
	var hero: CinderPlayer = preview.get("player") as CinderPlayer
	# TEST ONLY initial equipment selection before the first physics frame. The
	# resolver validates every canonical slot; the public weapon equip refreshes
	# the player's derived stats and visuals. This is not a live clothing bench.
	var selected: bool = hero.equipment.restore(_loadout) and hero.equip_item(String(_loadout["weapon"]))
	if not _expect(selected and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats), "fixture seeds existing %s through the shared equipment resolver before combat" % _loadout_name):
		preview.free()
		return false
	hero.shells = 0 # Initial test resource, before any combat; natural reload remains.
	preview.call("resume_lab")
	for frame: int in range(8):
		await physics_frame
	paused = true
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var actor_state: Dictionary = hero.snapshot_state()
	var local_state: Dictionary = level.snapshot_state()
	var camera: Camera3D = preview.get("camera") as Camera3D
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": _profile_id}
	var aggregate: Dictionary = {"schema_version": 1, "level_id": "A2-L2", "scene_path": LevelPath, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": actor_state, "level": local_state, "shell": shell_state}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var seed: Dictionary = model.state()
	seed["completed_main"] = PREFIX.duplicate()
	# Synthetic prior catalogue unlocks in this TEST ONLY saved-story seed. They
	# certify neither earlier-level play nor a Weybridge reward/runtime grant.
	for id: String in _loadout.values():
		if not seed["unlocked_equipment"].has(id):
			seed["unlocked_equipment"].append(id)
	print("TEST ONLY synthetic prior catalogue unlocks for selected seed gear: ", _loadout.values())
	seed["story"] = {"kind": "story", "level_id": "A2-L2", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var store: CinderSaveStore = Store.new(TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var seed_error: String = model.state_error(seed)
	var valid: bool = not actor_state.is_empty() and not local_state.is_empty() and seed_error.is_empty()
	var saved: bool = valid and store.write_payload(seed)
	if not saved:
		print("Weybridge seed rejection: actor_error=%s level_error=%s runtime_error=%s model_error=%s store_error=%s actor_keys=%s level_keys=%s" % [hero.last_snapshot_error, level.last_snapshot_error, level.get("runtime_error"), seed_error, store.last_error, actor_state.keys(), local_state.keys()])
	_expect(saved, "TEST ONLY Act1/Horsell prefix seeds real captured Weybridge/player state: " + store.last_error)
	preview.free()
	_expect(not is_instance_valid(hero) and not is_instance_valid(level), "seed MainScene and actor are freed before actual shell installation")
	return saved


func _navigate_dash(goal: Vector3, allow_exit_transition: bool = false) -> bool:
	var hero: CinderPlayer = _game.player
	var best: Vector3 = Vector3.ZERO
	var score: float = INF
	var excluded: Array[RID] = [hero.get_rid()]
	for floor: Dictionary in _game.active_level.call("floor_regions"):
		excluded.append((floor["body"] as StaticBody3D).get_rid())
	var collision: CollisionShape3D = hero.get_node("BodyCollision") as CollisionShape3D
	# TEST ONLY read-only route planning. The predicted point selects a swipe;
	# real request_dash, collision and completed world-action landing remain truth.
	for index: int in range(64):
		var angle: float = TAU * float(index) / 64.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collision.shape
		query.transform = collision.global_transform
		query.motion = direction * float(hero.stats.dash_distance)
		query.collision_mask = 1
		query.margin = 0.001
		query.exclude = excluded
		var cast: PackedFloat32Array = hero.get_world_3d().direct_space_state.cast_motion(query)
		var fraction: float = cast[0] if cast.size() == 2 else 0.0
		if fraction * float(hero.stats.dash_distance) < 0.12:
			continue
		var predicted: Vector3 = hero.global_position + query.motion * fraction
		var distance: float = Vector2(predicted.x - goal.x, predicted.z - goal.z).length_squared()
		if distance < score:
			best = direction
			score = distance
	if not _expect(best != Vector3.ZERO, "actual scenery leaves a navigation swipe"):
		return false
	return await _dash(best, allow_exit_transition)


func _dash(direction: Vector3, allow_exit_transition: bool = false, proof_plan: Dictionary = {}, proof_segment: Dictionary = {}) -> bool:
	_proof_dash_abandoned = false
	var hero: CinderPlayer = _game.player
	var ready: bool = false
	for frame: int in range(180):
		if not _live():
			return false
		if not proof_plan.is_empty() and not _proof_dash_current(proof_plan, proof_segment):
			_proof_dash_abandoned = true
			return true
		var response: Dictionary = hero.get_threat_response_state()
		if not paused and response["stable"] and float(response["dash_cooldown_left_s"]) <= 0.00001:
			ready = true
			break
		await _step()
	if not _expect(ready, "bot awaits an unpaused stable actor and actual dash cooldown"):
		return false
	if not proof_plan.is_empty() and not _proof_dash_current(proof_plan, proof_segment):
		_proof_dash_abandoned = true
		return true
	var before: int = _actions.size()
	if not _expect(hero.request_dash(direction), "bot uses the shared accepted dash request"):
		return false
	for frame: int in range(180):
		for action: Dictionary in _actions.slice(before):
			if action["kind"] == "dash":
				var landing: Vector3 = action["landing"]
				return _expect(landing.is_finite() and landing.y > -0.05 and action["path"].size() >= 2, "actual completed dash has a supported sampled world landing")
		if not is_instance_valid(hero):
			if allow_exit_transition and _game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L3" and _game.active_level.scene_file_path == NextPath:
				return _expect(true, "actual shelter contact may transition during a dash without inventing its unfinished world-action record")
			break
		await _step()
	return _expect(false, "shared dash did not publish a completed world action")


func _state() -> Dictionary:
	return _game.active_level.call("encounter_state") if _game.active_level.level_id == "A2-L2" else {}


func _live() -> bool:
	return is_instance_valid(_game) and _game.campaign_error.is_empty() and is_instance_valid(_game.player) and not _game.player.dead and _game.active_level.level_id == "A2-L2" and String(_state().get("runtime_error", "")).is_empty()


func _diagnostic() -> String:
	return "%s hero=%s state=%s" % [_game.campaign_error, _game.player.global_position, _state()] if is_instance_valid(_game) else "no shell"


func _last_dash() -> Dictionary:
	for index: int in range(_actions.size() - 1, -1, -1):
		if _actions[index]["kind"] == "dash":
			return _actions[index]
	return {}


func _step() -> void:
	await physics_frame
	await process_frame
	if is_instance_valid(_game) and paused and _game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L2" and _game.menu.page_name() == "resume" and not _game.player.dead:
		_game.resume_campaign()
	_observe_runtime()
	await _capture_state()


func _contains_pickup(level: Node) -> bool:
	var pending: Array[Node] = [level]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is LabWeaponPickup:
			return true
		pending.append_array(node.get_children())
	return false


func _settle() -> void:
	for frame: int in range(4):
		await process_frame


func _cleanup() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))


func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
	return condition
