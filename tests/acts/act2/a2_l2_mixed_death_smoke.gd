extends "res://tests/acts/act2/a2_l2_retry_level_smoke.gd"
## Actual Standard/Heavy route to the living shelter Scout+Handler, then their
## native lethal hit, synchronous shell pause and complete dead aggregate.
## Normal initial HP; no assigned live resources/pose/phase/clock/progression.
## Existing TEST ONLY prefix/unlocks/destination remain inherited prerequisites.
## No final HP defeats, clear, shelter exit, native art or human balance claim.

const MIXED_IDS: Array[String] = ["shelter_scout", "shelter_handler"]
const MIXED_TOOL_ID: String = "tool_shelter_handler"
const MIXED_TARGET := Vector3(0.65, 0.0, -33.0)
const MIXED_REGION := Rect2(0.45, -33.2, 0.4, 0.4)
const MIXED_RESTORE_ROOT: String = "user://test-a2-l2-mixed-death-restore/"
const MIXED_PRIOR_DEFEATS: Array[String] = ["village_scout", "yard_handler", "apron_handler", "crossing_scout"]
const MIXED_FEET: Array[String] = ["foot_demo", "foot_apron", "foot_left", "foot_right"]
var _mixed_restored: CinderCampaignShell
var _mixed_refs: Array[Dictionary] = []

func _run() -> void:
	if not _read_options() or not _expect(_profile_id == "standard" and _loadout_name == "heavy" and not _capture_live, "mixed death fixture selects one Standard/Heavy route and owns no native capture"):
		quit(1)
		return
	root.size = Vector2i(540, 1170)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_l1_fixture_bytes = FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn")
	_cleanup()
	_mixed_cleanup()
	print("Weybridge mixed death scope: actual four primary defeats/four feet/four contacts, living final Scout+Handler source death, synchronous pause, full dead transport/fresh restore; normal initial HP and TEST ONLY prior prerequisites")
	var failures_before: int = _failures
	if not await _mixed_route() and _failures == failures_before: _expect(false, "actual mixed death route aborted: " + _diagnostic())
	if is_instance_valid(_fresh): _release_fixture_receiver(_fresh)
	if is_instance_valid(_mixed_restored): _release_fixture_shell(_mixed_restored)
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	paused = false
	for entry: Dictionary in _mixed_refs: _expect((entry.ref as WeakRef).get_ref() == null, "mixed death teardown frees old actual " + String(entry.label))
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn") == _l1_fixture_bytes, "mixed death test preserves canonical registry and old L1 fixture bytes")
	_cleanup()
	_mixed_cleanup()
	print("Weybridge mixed death smoke: %d checks, %d failures; actual simultaneous sources with individually observed phases, no claimed two locks/two accepted hits at one instant/final clear/native art" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _mixed_route() -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L2", "A2-L3"]:
			info.scene_path = LevelPath if info.id == "A2-L2" else NextPath
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty(), "isolated inherited TEST ONLY registry preserves canonical links") or not await _seed(registry): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json"), "actual mixed death shell uses isolated save paths"): return false
	root.add_child(_game)
	await _settle()
	_game.menu.difficulty_preference_requested.emit("standard")
	_game.resume_campaign()
	await _settle()
	if not _expect(_live() and paused, "actual shell installs Weybridge saved seed: " + _game.campaign_error): return false
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	if not _expect(hero.hp == hero.max_hp and hero.shells == 0 and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats), "actual mixed route starts at full normal HP/zero ammo with canonical Heavy equipment"): return false
	_actors = level.get("_actors").duplicate()
	if not _expect(_actors.size() == 6 and not _contains_pickup(level), "actual cast and no-pickup premise remain intact"): return false
	var defeats: Array[String] = []
	var checkpoints: Array[String] = []
	var completions: Array[String] = []
	var exits: Array[String] = []
	for actor: Node in _actors.values(): actor.connect("defeated", func(id: String) -> void: defeats.append(id))
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append(checkpoint)
		_expect(kind == "encounter", "actual contact retains shared checkpoint boundary")
	)
	level.completion_requested.connect(func(_id: String, id: String) -> void: completions.append(id))
	level.contact_exit_requested.connect(func(_id: String, id: String) -> void: exits.append(id))
	hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	_game.resume_campaign()
	if not await _clear(["village_scout"]) or not await _clear(["yard_handler"]) or not await _contact("yard_exit", checkpoints): return false
	if not await _complete_foot("foot_demo") or not await _complete_foot("foot_apron") or not await _clear(["apron_handler"]) or not await _contact("before_crossing", checkpoints): return false
	if not await _complete_foot("foot_left") or not await _complete_foot("foot_right") or not await _clear(["crossing_scout"]): return false
	if not await _contact("far_apron", checkpoints) or not await _contact("before_shelter", checkpoints): return false
	await _settle()
	var expected_checkpoints: Array[String] = []
	for contact: String in CONTACT_ORDER: expected_checkpoints.append(Sequence.CONTACTS[contact].checkpoint)
	if not _expect(_state().beat == "shelter_pair" and defeats == MIXED_PRIOR_DEFEATS and checkpoints == expected_checkpoints and _foot_completed == MIXED_FEET and completions.is_empty() and exits.is_empty(), "real first four primary defeats/four foot opportunities/four contact checkpoints reach final living mixture"): return false
	var checkpoint: Dictionary = _game.attempts.state().story.checkpoint.duplicate(true)
	_expect(checkpoint.level.progress.checkpoint_id == "weybridge-before-shelter" and checkpoint.level.local.sequence.crossed_contacts == CONTACT_ORDER and checkpoint.level.local.sequence.completed_feet == MIXED_FEET and checkpoint.level.local.sequence.defeated_ids == MIXED_PRIOR_DEFEATS, "protected retry checkpoint retains actual earned route prefix")
	# Reuse the verified no-hit route prefix; routed input belongs to the final
	# mixed-source death scope after all foot opportunities, before lethal wait.
	var actions_before: int = _actions.size()
	await _retry_swipe(Vector2(0.70, 0.65), Vector2(0.64, 0.50))
	for frame: int in range(180):
		if _actions.size() > actions_before and _last_dash().get("kind") == "dash": break
		if not _live(): return false
		await _step()
	var anchor: Vector2 = _game.get_aim_anchor_normalized()
	if not _expect(_actions.size() > actions_before and anchor.is_equal_approx(Vector2(0.64, 0.50)), "actual routed swipe after the earned safe prefix establishes completed dash and exact nondefault release anchor"): return false
	var hits: Array[Dictionary] = []
	var death_observation: Dictionary = {}
	var before_tick: Dictionary = {}
	var deaths: Array[String] = []
	var driver: Node = level.get_node("ReusedRayExchanges")
	driver.connect("hit_resolved", func(id: String, result: Dictionary) -> void:
		if id == "shelter_scout" and result.get("accepted", false): hits.append({"source_id": id, "result": result.duplicate(true), "clock_s": _state().clock_s, "lethal": hero.dead})
	)
	var tool: Node = level.get("_mechanisms")[MIXED_TOOL_ID]
	tool.connect("hit_resolved", func(id: String, cycle: int, result: Dictionary) -> void:
		if result.get("accepted", false): hits.append({"source_id": MIXED_TOOL_ID, "hero_id": id, "cycle": cycle, "result": result.duplicate(true), "clock_s": _state().clock_s, "lethal": hero.dead})
	)
	# Public hurt publication follows the actual HP change and precedes died.
	# Read the same-tick admissions/deadlines here, including any genuine lock
	# reproof since the prior physics sample; no speculative pre-tick copy wins.
	hero.fired.connect(func(kind: String) -> void:
		if kind == "hurt" and hero.hp <= 0.0: death_observation["at_lethal_hit"] = _mixed_tick()
	)
	hero.died.connect(func() -> void:
		deaths.append("actual-mixed-source-death")
		death_observation["paused"] = paused
		death_observation["hp"] = hero.hp
		death_observation["shells"] = hero.shells
		death_observation["position"] = hero.global_position
		death_observation["before_tick"] = before_tick.duplicate(true)
		death_observation["after_barrier"] = _state()
	)
	if paused: _game.resume_campaign()
	if not await _mixed_navigate_sources(): return false
	var found: bool = false
	for frame: int in range(900):
		if not _live(): return _expect(false, "hero survives actual approach until both source admissions are observed: " + _diagnostic())
		if _mixed_sources_running(_state(), true): found = true; break
		await _step()
	if not _expect(found and float(_actors.shelter_scout.get("hp")) == 30.0 and float(_actors.shelter_handler.get("hp")) == 30.0, "both living final sources hold actual armed admissions before lethal wait: " + _diagnostic()): return false
	_game.request_pause()
	await _settle()
	var before_wait: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not before_wait.is_empty() and _mixed_sources_running(_state(), true), "public pause captures the actual armed final mixture without final primary"): return false
	var action_sequence: int = int(before_wait.player.world_actions.sequence)
	_mixed_refs = _retry_old_refs(level, hero)
	_game.resume_campaign()
	# No further movement/attack input. Both actual sources own admission, cue,
	# tracking/lane geometry and damage; the normal hero loses HP naturally.
	for frame: int in range(7200):
		if hero.dead or not _live(): break
		before_tick.clear()
		before_tick.merge(_mixed_tick())
		await _step()
	await _settle()
	if not _expect(hero.dead and hero.hp == 0.0 and paused and _game.campaign_error.is_empty() and deaths == ["actual-mixed-source-death"] and death_observation.get("paused", false), "actual final source lethal hit synchronously pauses the shared shell: " + _diagnostic()): return false
	var seen: Dictionary = {}
	for hit: Dictionary in hits:
		seen[hit.source_id] = true
		var role: Dictionary = _expected_roles.ray if hit.source_id == "shelter_scout" else _expected_roles.tool
		_expect(hit.source_id in ["shelter_scout", MIXED_TOOL_ID] and float(hit.result.raw_damage) == float(role.damage) and float(hit.result.hp_damage) > 0.0 and hit.result.impulse == Vector3.ZERO, "actual accepted final source hit uses fixed Standard damage and no invented impulse")
	if not _expect(seen.has("shelter_scout") and seen.has(MIXED_TOOL_ID) and death_observation.has("at_lethal_hit") and _mixed_sources_running(death_observation.at_lethal_hit.state, false) and hits.back().lethal, "both real final sources damage the normal hero and remain admitted at the actual lethal hurt publication"): return false
	var dead: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not dead.is_empty(), "complete mixed death aggregate captures at deferred barrier: " + _game.campaign_error): return false
	if not _mixed_dead_state(dead, before_wait, death_observation): return false
	_expect(defeats == MIXED_PRIOR_DEFEATS and checkpoints == expected_checkpoints and completions.is_empty() and exits.is_empty() and int(dead.player.world_actions.sequence) == action_sequence and _game.get_aim_anchor_normalized() == anchor, "actual source death adds no action/final defeat/contact/completion or aim change")
	_expect(ExactJson.stringify(_game.attempts.state().story.snapshot) == ExactJson.stringify(dead) and ExactJson.stringify(_game.attempts.state().story.checkpoint) == ExactJson.stringify(checkpoint) and _game.attempts.state().completed_main == PREFIX and _game.attempts.state().reward_ids.is_empty(), "shell records dead story while preserving protected checkpoint/prior prefix/no new reward")
	if not await _mixed_validate_transport(dead, raw, registry): return false
	return true

func _mixed_sources_running(state: Dictionary, require_armed: bool) -> bool:
	if state.get("beat") != "shelter_pair" or state.get("active_ids") != MIXED_IDS: return false
	for id: String in MIXED_IDS:
		var current: Dictionary = state.exchanges[id]
		if current.status != "running" or current.phase not in ["warning", "lock", "active", "recovery"]: return false
		if require_armed and not _reservation(String(current.reservation_id)).get("armed", false): return false
	return true

func _mixed_tick() -> Dictionary:
	var state: Dictionary = _state()
	var reservations: Dictionary = {}
	for id: String in MIXED_IDS:
		reservations[id] = _reservation(String(state.exchanges[id].get("reservation_id", "")))
	return {"state": state, "reservations": reservations}

func _mixed_dead_state(dead: Dictionary, before_wait: Dictionary, observation: Dictionary) -> bool:
	var local: Dictionary = dead.level.local
	var scout: Dictionary = local.rays.records.shelter_scout
	var tool: Dictionary = local.mechanisms[MIXED_TOOL_ID]
	if not _expect(dead.player.resources.hp == observation.hp and dead.player.resources.shells == observation.shells and Codec.read_vector3(dead.player.motion.position) == observation.position and dead.equipment_ids == _loadout and dead.player.equipment == _loadout, "deferred death capture retains exact actual lethal resources/position/equipment"): return false
	if not _expect(local.scheduler.reservations.is_empty() and local.views.is_empty() and scout.status == "cancelled" and scout.phase == "clear" and scout.last_cancel_reason == "hero_defeated" and tool.status == "cancelled" and tool.phase == "clear" and tool.last_cancel_reason == "hero_defeated", "supported death barrier cancels running real sources and clears dangerous view custody"): return false
	_expect(local.rays.actors.shelter_scout.hp == 30.0 and local.handlers.shelter_handler.hp == 30.0 and local.rays.actors.shelter_scout.phase == "idle" and local.handlers.shelter_handler.phase == "idle" and local.handlers.shelter_handler.phase_progress == 0.0, "living final sources retain HP and commit the real cleared cosmetic state")
	_expect(local.sequence == before_wait.level.local.sequence and dead.level.progress == before_wait.level.progress and local.profile_id == "standard" and not local.completion_pending and not local.exit_requested and not dead.level.progress.completed, "death preserves earned sequence/checkpoint/profile without final progression")
	for id: String in MIXED_FEET:
		var receipt: Dictionary = local.mechanisms[id].duplicate(true)
		var old_receipt: Dictionary = before_wait.level.local.mechanisms[id].duplicate(true)
		receipt.erase("clock_s")
		old_receipt.erase("clock_s")
		_expect(receipt.status == "complete" and ExactJson.stringify(receipt) == ExactJson.stringify(old_receipt), "death preserves actual finished foot receipt/history without canceling it: " + id)
	for id: String in MIXED_IDS:
		var previous: Dictionary = observation.at_lethal_hit.state.exchanges[id]
		var reservation: Dictionary = observation.at_lethal_hit.reservations[id]
		var retained: Dictionary = scout if id == "shelter_scout" else tool
		_expect(int(retained.cycle) == int(previous.cycle) and retained.exchange.id == reservation.id, "death preserves the actual final source cycle/reservation identity: " + id)
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
			_expect(retained.exchange[key] == reservation[key], "death retains copied original source deadline: " + id + "/" + key)
		if float(retained.exchange.cooldown_until_s) > float(local.scheduler.clock_s):
			var cooldown: Dictionary = {}
			var owner_id: String = id if id == "shelter_scout" else MIXED_TOOL_ID
			for entry: Dictionary in local.scheduler.cooldowns:
				if entry.source_id == owner_id: cooldown = entry
			_expect(not cooldown.is_empty() and cooldown.ready_s == retained.exchange.cooldown_until_s, "death cancellation preserves original unexpired source cooldown: " + id)
	var driver: Node = _game.active_level.get_node("ReusedRayExchanges")
	var ray_cue: Node3D = driver.call("get_cue", "shelter_scout") as Node3D
	var tool_cue: Node3D = (_game.active_level.get("_mechanisms")[MIXED_TOOL_ID] as Node).call("get_cue") as Node3D
	for cue: Node3D in [ray_cue, tool_cue]:
		var cue_state: Dictionary = cue.call("state")
		var meshes_clear: bool = true
		for mesh: MeshInstance3D in cue.find_children("*", "MeshInstance3D", true, false):
			if mesh.is_visible_in_tree(): meshes_clear = false
		_expect(cue_state.phase == "clear" and not cue_state.source_visible and not cue_state.footprint_visible and not cue_state.active_fill_visible and meshes_clear, "actual dead source hides every danger mesh and public cue flag")
	return _expect(_game.player.snapshot_error(dead.player).is_empty() and _game.active_level.snapshot_error_with_player(dead.level, dead.player).is_empty(), "strict complete saved-player preflight accepts actual mixed death state")

func _mixed_validate_transport(dead: Dictionary, raw: Dictionary, registry: CinderCampaignRegistry) -> bool:
	var encoded: String = ExactJson.stringify(dead)
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not _expect(not encoded.is_empty() and decoded.get("accepted", false) and decoded.get("value") is Dictionary and ExactJson.stringify(decoded.value) == encoded, "ExactJson transports the complete actual dead aggregate without scalar/type loss"): return false
	var transported: Dictionary = decoded.value
	var events: Array[String] = []
	_retry_observe(_game.active_level, _game.player, events)
	_expect(_game.player.snapshot_error(transported.player).is_empty() and _game.active_level.snapshot_error_with_player(transported.level, transported.player).is_empty() and _game.attempts.record_snapshot(transported), "actual shell-bound aggregate validator accepts transported dead tuple")
	await _settle()
	_expect(ExactJson.stringify(_game.capture_campaign_snapshot()) == encoded and events.is_empty(), "paused actual dead aggregate freezes exactly with no danger/hit/action/progression events")
	if not _retry_fresh_preflight(transported): return false
	if not _expect(_game.player.restore_state(transported.player) and _game.active_level.restore_state(transported.level) and ExactJson.stringify(_game.capture_campaign_snapshot()) == encoded and events.is_empty(), "ordered actual paused dead restore remains exact and quiet"): return false
	# Whole-shell fresh installation uses the actual captured state, never a live
	# HP assignment. TEST ONLY secondary save paths keep the original story intact.
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var payload: Dictionary = _game.attempts.state()
	var store: CinderSaveStore = Store.new(MIXED_RESTORE_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and store.write_payload(payload), "secondary TEST ONLY SaveStore keeps the complete actual dead story/checkpoint: " + store.last_error): return false
	_mixed_restored = Shell.new() as CinderCampaignShell
	if not _expect(_mixed_restored.configure_runtime(raw, MIXED_RESTORE_ROOT + "campaign.json", MIXED_RESTORE_ROOT + "settings.json", MIXED_RESTORE_ROOT + "preferences.json"), "fresh actual shell receives only isolated mixed-death save"): return false
	root.add_child(_mixed_restored)
	await _settle()
	_mixed_restored.resume_campaign()
	await _settle()
	if not _expect(_mixed_restored.campaign_error.is_empty() and is_instance_valid(_mixed_restored.player) and _mixed_restored.player.dead and paused, "fresh public shell install restores actual dead hero at the paused aggregate barrier: " + _mixed_restored.campaign_error): return false
	var restored_events: Array[String] = []
	_retry_observe(_mixed_restored.active_level, _mixed_restored.player, restored_events)
	var restored: Dictionary = _mixed_restored.capture_campaign_snapshot()
	_expect(not restored.is_empty() and ExactJson.stringify(restored) == encoded and ExactJson.stringify(_mixed_restored.attempts.state().story.checkpoint) == ExactJson.stringify(payload.story.checkpoint), "fresh full shell reconstruction restores exact player/level/resources/gear/input/camera/checkpoint")
	await _settle()
	_expect(ExactJson.stringify(_mixed_restored.capture_campaign_snapshot()) == encoded and restored_events.is_empty(), "fresh paused frames retain exact dead tuple and emit no new source events")
	_release_fixture_shell(_mixed_restored)
	_mixed_restored = null
	return true

func _mixed_navigate_sources() -> bool:
	for attempt: int in range(4):
		if not _live(): return false
		var start: Vector3 = _game.player.global_position
		var landing: Variant = _last_dash().get("landing")
		if MIXED_REGION.has_point(Vector2(start.x, start.z)):
			return _expect(landing is Vector3 and landing.y > -0.05 and MIXED_REGION.has_point(Vector2(landing.x, landing.z)) and _retry_plan_clear(start, start), "actual supported completed dash enters living final tool lane and Scout reach")
		var distance: float = float(_game.player.stats.dash_distance)
		var target := Vector3(MIXED_TARGET.x, start.y, MIXED_TARGET.z)
		var offset: Vector3 = target - start
		var span: float = offset.length()
		var direct: Vector3 = start + offset.normalized() * distance
		if MIXED_REGION.has_point(Vector2(direct.x, direct.z)) and _retry_plan_clear(start, direct):
			if not await _dash(offset.normalized()): return false
			continue
		var waypoint: Vector3 = Vector3.INF
		if span > 0.0 and span <= 2.0 * distance:
			var midpoint: Vector3 = (start + target) * 0.5
			var perpendicular := Vector3(-offset.z, 0.0, offset.x) / span
			var height: float = sqrt(maxf(distance * distance - span * span * 0.25, 0.0))
			for side: float in [-1.0, 1.0]:
				var candidate: Vector3 = midpoint + perpendicular * height * side
				if _retry_plan_clear(start, candidate) and _retry_plan_clear(candidate, target) and (not waypoint.is_finite() or absf(candidate.x) < absf(waypoint.x)): waypoint = candidate
		if waypoint.is_finite():
			if not await _dash((waypoint - start).normalized()): return false
			var actual: Vector3 = _game.player.global_position
			if not await _dash(Vector3(MIXED_TARGET.x - actual.x, 0.0, MIXED_TARGET.z - actual.z).normalized()): return false
		elif not await _navigate_dash(target): return false
	var final: Vector3 = _game.player.global_position
	var final_landing: Variant = _last_dash().get("landing")
	return _expect(MIXED_REGION.has_point(Vector2(final.x, final.z)) and final_landing is Vector3 and final_landing.y > -0.05 and MIXED_REGION.has_point(Vector2(final_landing.x, final_landing.z)) and _retry_plan_clear(final, final), "bounded actual dashes land inside final source mixture: " + _diagnostic())

func _mixed_cleanup() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MIXED_RESTORE_ROOT + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MIXED_RESTORE_ROOT))
