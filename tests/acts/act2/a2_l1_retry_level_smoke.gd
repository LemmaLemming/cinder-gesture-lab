extends "res://tests/acts/act2/a2_l1_live_level_smoke.gd"
## Real authored departure checkpoint, paired pause and ray-death/public retry.
## Inherited TEST ONLY prefix/unlocks/profile/destination seed remains explicit.
## Live transforms, HP, phases, defeats and progression are never assigned.
## Defaults to left/Standard/Heavy; --route=right/both and Challenge are supported.
## Native clocks and exact-json-1 transport retain exact comparisons.
## Historical decimal-transport failures remain evidence; no tolerance is added.

const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")

## TEST ONLY midpoint keeps both actual tracking endcaps readable. Equal-radius
## circle intersections choose real fixed-distance dash waypoints, not a pose.
const RETRY_PAIR_REGION: Rect2 = Rect2(-0.2, -24.5, 0.4, 0.4)
const RETRY_PAIR_TARGET: Vector3 = Vector3(0.0, 0.0, -24.3)
const RETRY_PAIR_IDS: Array[String] = ["departure_a", "departure_b"]
const RETRY_CHECKPOINT_ID: String = "horsell-before-departure"


func _run() -> void:
	if not _read_options():
		quit(1)
		return
	var selected_route: bool = false
	for argument: String in OS.get_cmdline_user_args():
		selected_route = selected_route or argument.begins_with("--route=")
	if not selected_route:
		_routes.assign(["left"])
	if not _expect(_profile_id in ["standard", "challenge"], "paired retry fixture selects a two-source profile; Assisted deliberately has a one-source budget"):
		quit(1)
		return
	if not _expect(not _capture_live, "retry fixture is a scoped encounter/save test; existing live fixture owns portrait captures"):
		quit(1)
		return
	root.size = Vector2i(540, 1170)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	print("Horsell retry scope: routes=%s loadout=%s profile=%s; actual first four primary clears/contact, paired pause, actual ray death/public retry; inherited TEST ONLY seed" % [_routes, _loadout_name, _profile_id])
	for route: String in _routes:
		var failures_before: int = _failures
		if not await _retry_route(route):
			if _failures == failures_before:
				_expect(false, "authored retry route aborted: " + _diagnostic())
			break
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "retry injection leaves canonical registry bytes unchanged")
	if is_instance_valid(_game):
		_game.free()
		_game = null
	paused = false
	_cleanup()
	print("Horsell authored retry smoke: %d checks, %d failures; no forced HP/position/phase, no authored final clear or later-level gameplay" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _retry_route(route: String) -> bool:
	_cleanup()
	_route = route
	_actions.clear()
	_actors.clear()
	_used_proofs.clear()
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw["levels"]:
		if info["id"] in ["A2-L1", "A2-L2"]:
			info["scene_path"] = LevelPath if info["id"] == "A2-L1" else NextPath
			info["readiness"] = "accepted"
			info["accepted_commit"] = "b".repeat(40)
			info["api_revision"] = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty(), "TEST ONLY registry preserves canonical links") or not await _seed(registry):
		return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json"), "retry shell uses isolated inherited fixture save paths"):
		return false
	root.add_child(_game)
	await _settle()
	_game.menu.difficulty_preference_requested.emit(_profile_id)
	_game.resume_campaign()
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and is_instance_valid(_game.active_level) and paused, "real Horsell installs at the paused saved seed: " + _game.campaign_error):
		return false
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	_expect(hero.shells == 0 and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats), "real route begins with canonical selected stats and zero ammo")
	for node: Node in get_nodes_in_group("enemies"):
		if level.is_ancestor_of(node):
			_actors[String(node.get("actor_id"))] = node
	if not _expect(_actors.size() == 7 and not _contains_pickup(level), "actual authored cast contains no victory pickup"):
		return false
	var defeats: Array[String] = []
	var checkpoints: Array[String] = []
	var checkpoint_resources: Dictionary = {}
	var completions: Array[String] = []
	var exits: Array[String] = []
	for actor: Node in _actors.values():
		actor.connect("defeated", func(id: String) -> void: defeats.append(id))
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append(checkpoint)
		_expect(kind == "encounter", "real contact/clear emits the authored encounter boundary")
		if checkpoint == RETRY_CHECKPOINT_ID:
			checkpoint_resources["hp"] = hero.hp
			checkpoint_resources["shells"] = hero.shells
			checkpoint_resources["equipment"] = hero.equipment.snapshot()
	)
	level.completion_requested.connect(func(_id: String, id: String) -> void: completions.append(id))
	level.contact_exit_requested.connect(func(_id: String, id: String) -> void: exits.append(id))
	hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	_game.resume_campaign()
	var actions_before_swipe: int = _actions.size()
	await _retry_swipe(Vector2(0.70, 0.65), Vector2(0.64, 0.50))
	for frame: int in range(180):
		if _actions.size() > actions_before_swipe and _last_dash().get("kind") == "dash":
			break
		await _step()
	if not _expect(_actions.size() > actions_before_swipe and _game.get_aim_anchor_normalized().is_equal_approx(Vector2(0.64, 0.50)), "routed screen swipe completes a real dash and establishes a nondefault final-release anchor"):
		return false
	var release_anchor: Vector2 = _game.get_aim_anchor_normalized()
	for id: String in ["arrival", "road_east", "road_west"]:
		if not await _clear([id]):
			return false
	var chosen_region: Rect2 = Rect2(-2.7, -13.3, 2.5, 2.2) if route == "left" else Rect2(0.2, -13.3, 2.5, 2.2)
	if not await _dash_to_region(chosen_region) or not await _clear(["common_" + route]):
		return false
	var first_four: Array[String] = ["arrival", "road_east", "road_west", "common_" + route]
	_expect(defeats == first_four and _state()["beat"] == "departure", "first four actual ordinary-primary defeats reach the authored departure pair")
	if not await _dash_to_region(DEPARTURE_REGION, false, true):
		return false
	await _settle()
	var checkpoint: Dictionary = _game.attempts.state()["story"]["checkpoint"].duplicate(true)
	if not _expect(_game.campaign_error.is_empty() and checkpoint["level"]["progress"]["checkpoint_id"] == RETRY_CHECKPOINT_ID and checkpoints == ["horsell-arrival-clear", "horsell-road-clear", "horsell-reunion", RETRY_CHECKPOINT_ID], "real departure contact durably records the exact fourth authored checkpoint: " + _game.campaign_error):
		return false
	_expect(_dash_touches_region(_last_dash(), DEPARTURE_REGION) and _departure_checkpoint_stable(), "checkpoint follows the actual completed contact-crossing dash at a stable landing")
	_expect(checkpoint["level"]["local"]["departure_checkpoint"] and checkpoint["level"]["local"]["sequence"]["defeated_ids"] == first_four and not checkpoint["level"]["progress"]["completed"], "saved checkpoint retains the four clears without final completion")
	_expect(checkpoint["player"]["resources"]["hp"] == checkpoint_resources.get("hp") and checkpoint["player"]["resources"]["shells"] == checkpoint_resources.get("shells") and checkpoint["equipment_ids"] == checkpoint_resources.get("equipment"), "authored checkpoint stores the actual initiating contact HP/ammo/gear without refill")
	_expect(checkpoint["shell"]["anchor_normalized"] == [release_anchor.x, release_anchor.y] and int(checkpoint["shell"]["input_sequence"]) > 0, "authored checkpoint carries the actual nondefault release anchor and input observer")
	if paused:
		_game.resume_campaign()
	if not await _retry_navigate_pair():
		return false
	print("Horsell retry stage: actual central landing %s" % hero.global_position)
	var warning: Dictionary = await _retry_pause_pair("warning", checkpoint)
	if warning.is_empty():
		return false
	print("Horsell retry stage: warning pause/exact transport checked; failures=%d" % _failures)
	_game.resume_campaign()
	await _step()
	var locked: Dictionary = await _retry_pause_pair("lock", checkpoint)
	if locked.is_empty():
		return false
	print("Horsell retry stage: lock pause/exact transport checked; failures=%d" % _failures)
	var driver: Node = level.get_node("HorsellRayExchanges")
	var ray_hits: Array[Dictionary] = []
	var deaths: Array[String] = []
	driver.connect("hit_resolved", func(id: String, result: Dictionary) -> void:
		if result.get("accepted", false):
			ray_hits.append({"actor_id": id, "result": result.duplicate(true)})
	)
	hero.died.connect(func() -> void: deaths.append("actual-ray-death"))
	var preference: String = "challenge" if _profile_id == "standard" else "standard"
	_game.menu.difficulty_preference_requested.emit(preference)
	_expect(_game.get_difficulty_preference() == preference and _state()["exchanges"]["departure_a"]["resolved_role"]["difficulty_profile"] == _profile_id, "changing only the public future preference preserves the live fixed pair profile")
	var old_refs: Array[Dictionary] = _retry_old_refs(level, hero, driver)
	var sequence_before_death: int = int(locked["player"]["world_actions"]["sequence"])
	_game.resume_campaign()
	# Deliberately give no further movement/attack input: the actual tracked ray
	# resolves its own source/cue/geometry and eventually kills the unchanged hero.
	print("Horsell retry stage: resumed with no input; waiting for actual ray death")
	for frame: int in range(7200):
		if hero.dead or not _live():
			break
		await _step()
	await _settle()
	if not _expect(hero.dead and hero.hp == 0.0 and deaths == ["actual-ray-death"] and not ray_hits.is_empty() and paused and _game.campaign_error.is_empty(), "actual required rays cause death and the shared shell pauses at its deferred boundary: " + _diagnostic()):
		return false
	print("Horsell retry stage: actual ray death observed; accepted hits=%d" % ray_hits.size())
	for hit: Dictionary in ray_hits:
		_expect(RETRY_PAIR_IDS.has(hit["actor_id"]) and float(hit["result"]["raw_damage"]) == float(_expected_role["damage"]) and float(hit["result"]["hp_damage"]) > 0.0, "death damage comes from an actual fixed-profile departure ray")
	var dead: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not dead.is_empty(), "actual ray-death aggregate remains capturable: " + _game.campaign_error):
		return false
	_expect(int(dead["player"]["world_actions"]["sequence"]) == sequence_before_death and defeats == first_four and completions.is_empty() and exits.is_empty(), "waiting for ray death invents no attack, defeat, completion or exit")
	_expect(Codec.same_values(_game.attempts.state()["story"]["checkpoint"], checkpoint) and _game.attempts.state()["completed_main"] == PREFIX, "death pause preserves the protected authored checkpoint and campaign prefix")
	_game.request_retry()
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and paused and _game.menu.page_name() == "resume" and not _game.player.dead, "public death retry installs the alive authored checkpoint and remains paused: " + _game.campaign_error):
		return false
	var retried: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not retried.is_empty() and Codec.same_values(retried, checkpoint), "public retry restores the entire exact authored checkpoint aggregate"):
		return false
	_expect(retried["player"]["resources"] == checkpoint["player"]["resources"] and retried["equipment_ids"] == checkpoint["equipment_ids"] and retried["player"]["equipment"] == checkpoint["player"]["equipment"], "retry restores exact saved HP/ammo/gear rather than fresh resources")
	_expect(retried["shell"] == checkpoint["shell"] and _game.get_aim_anchor_normalized() == release_anchor, "retry restores saved input/observer/camera and the exact final release anchor")
	_expect(retried["level"]["local"]["profile_id"] == _profile_id and _game.get_difficulty_preference() == preference and Codec.same_values(retried["level"]["local"]["exchange"]["configuration"]["resolved_role"], _expected_role), "retry restores saved fixed profile independently of the newer public preference")
	for entry: Dictionary in old_refs:
		_expect((entry["ref"] as WeakRef).get_ref() == null, "retry frees old actual " + String(entry["label"]))
	_expect(_game.attempts.state()["completed_main"] == PREFIX and checkpoints.size() == 4 and defeats == first_four and completions.is_empty() and exits.is_empty() and _state()["beat"] == "departure" and not _game.active_level.is_completed(), "retry grants no extra progression and reopens the actual uncleared final pair")
	for id: String in RETRY_PAIR_IDS:
		_expect(float(retried["level"]["local"]["exchange"]["actors"][id]["hp"]) == 30.0, "retry retains the actual untouched " + id + " housing")
	print("Horsell retry stage: public authored checkpoint retry checked; failures=%d" % _failures)
	_actors.clear()
	_game.free()
	_game = null
	paused = false
	return true


func _retry_navigate_pair() -> bool:
	for attempt: int in range(4):
		if not _live():
			return _expect(false, "live encounter stopped before the actual pair midpoint landing: " + _diagnostic())
		var hero: CinderPlayer = _game.player
		var start: Vector3 = hero.global_position
		var landing: Variant = _last_dash().get("landing")
		if RETRY_PAIR_REGION.has_point(Vector2(start.x, start.z)):
			return _expect(landing is Vector3 and landing.y > -0.05 and RETRY_PAIR_REGION.has_point(Vector2(landing.x, landing.z)) and _retry_plan_clear(start, start), "actual completed supported dash lands in the central pair region")
		var distance: float = float(hero.stats.dash_distance)
		var target := Vector3(RETRY_PAIR_TARGET.x, start.y, RETRY_PAIR_TARGET.z)
		var offset: Vector3 = target - start
		var span: float = offset.length()
		var direct: Vector3 = start + offset.normalized() * distance
		if RETRY_PAIR_REGION.has_point(Vector2(direct.x, direct.z)) and _retry_plan_clear(start, direct):
			if not await _dash(offset.normalized()):
				return false
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
			if not await _dash((waypoint - start).normalized()):
				return false
			# Re-aim from the actual completed first dash, retaining collision and
			# engine rounding rather than assigning the planned waypoint/endpoint.
			var actual: Vector3 = _game.player.global_position
			var final_direction := Vector3(RETRY_PAIR_TARGET.x - actual.x, 0.0, RETRY_PAIR_TARGET.z - actual.z).normalized()
			if not await _dash(final_direction):
				return false
		else:
			# A distant start or bank-blocked intersection gets one normal actual
			# approach dash; the next bounded attempt recomputes both circles.
			if not await _navigate_dash(target):
				return false
	var final_position: Vector3 = _game.player.global_position
	var final_landing: Variant = _last_dash().get("landing")
	return _expect(RETRY_PAIR_REGION.has_point(Vector2(final_position.x, final_position.z)) and final_landing is Vector3 and final_landing.y > -0.05 and RETRY_PAIR_REGION.has_point(Vector2(final_landing.x, final_landing.z)) and _retry_plan_clear(final_position, final_position), "bounded real dash construction ends at the supported central pair landing: " + _diagnostic())


func _retry_plan_clear(start: Vector3, finish: Vector3) -> bool:
	var hero: CinderPlayer = _game.player
	var collision: CollisionShape3D = hero.get_node("BodyCollision") as CollisionShape3D
	var radius: float = float((collision.shape as CapsuleShape3D).radius) + 0.01
	var supported: bool = false
	var excluded: Array[RID] = [hero.get_rid()]
	for floor: Dictionary in _game.active_level.call("floor_regions"):
		excluded.append((floor["body"] as StaticBody3D).get_rid())
		var rect: Rect2 = (floor["safe_rect"] as Rect2).grow(-radius)
		if rect.has_point(Vector2(start.x, start.z)) and rect.has_point(Vector2(finish.x, finish.z)):
			supported = true # One convex actual floor supports this whole segment.
	if not supported:
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	var virtual_pose: Transform3D = collision.global_transform
	virtual_pose.origin += start - hero.global_position
	query.transform = virtual_pose
	query.motion = finish - start
	query.collision_mask = 1
	query.margin = 0.001
	query.exclude = excluded
	# Same TEST ONLY no-floor-RID cast as the inherited navigation planner.
	# Floors stay in actual shared-player collision during both executed dashes.
	if query.motion == Vector3.ZERO:
		return hero.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
	var cast: PackedFloat32Array = hero.get_world_3d().direct_space_state.cast_motion(query)
	return cast.size() == 2 and cast[0] == 1.0


func _retry_pause_pair(stage: String, checkpoint: Dictionary) -> Dictionary:
	var found: bool = false
	for frame: int in range(600):
		if not _live():
			break
		if _retry_pair_phase(_state(), stage):
			found = true
			break
		await _step()
	if not _expect(found, "actual departure pair reaches " + stage + " before pause: " + _diagnostic()):
		return {}
	_game.request_pause()
	await _settle()
	var saved: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(paused and _game.campaign_error.is_empty() and not saved.is_empty() and _retry_pair_phase(_state(), stage), "public pause retains the actual paired " + stage + " tuple: " + _game.campaign_error):
		return {}
	var local: Dictionary = saved["level"]["local"]
	var clock: float = float(local["scheduler"]["clock_s"])
	_expect(local["exchange"]["clock_s"] == clock, "paired " + stage + " driver/scheduler capture clocks are exact")
	for id: String in RETRY_PAIR_IDS:
		var record: Dictionary = local["exchange"]["records"][id]
		_expect(record["sample"]["clock_s"] == clock and Codec.same_values(record["sample"]["position"], saved["player"]["motion"]["position"]), "paired " + stage + " sample matches the same authoritative saved player/clock")
		if record["exchange"]["adapter"]["locked"]:
			_expect(float(record["exchange"]["active_from_s"]) - float(record["exchange"]["lock_from_s"]) >= 1.1 - 0.00001 and is_equal_approx(float(record["exchange"]["active_from_s"]) - float(record["exchange"]["lock_from_s"]), float(_expected_role["lock_s"])), "paused pair retains the full resolved immutable lock")
		var driver: Node = _game.active_level.get_node("HorsellRayExchanges")
		var cue: Node = driver.call("get_cue", id)
		var cue_state: Dictionary = cue.call("state")
		_expect(cue.is_visible_in_tree() and cue_state["phase"] == record["phase"] and cue_state["source_visible"] and cue_state["footprint_visible"] and not cue_state["active_fill_visible"], "paused " + stage + " retains actual required source/capsule presentation")
	_expect(_game.player.snapshot_error(saved["player"]).is_empty() and _game.active_level.snapshot_error_with_player(saved["level"], saved["player"]).is_empty(), "full saved-player preflight accepts the actual paired " + stage + " aggregate")
	_expect(not _game.active_level.snapshot_error_with_player(saved["level"], checkpoint["player"]).is_empty(), "paired " + stage + " rejects the independently valid checkpoint player's different actual position")
	await _settle()
	var frozen: Dictionary = _game.capture_campaign_snapshot()
	_expect(not frozen.is_empty() and frozen["level"]["local"]["scheduler"]["clock_s"] == clock and frozen["player"]["world_actions"]["clock_s"] == saved["player"]["world_actions"]["clock_s"] and Codec.same_values(frozen, saved), "paused render frames freeze the whole paired " + stage + " aggregate exactly")
	var encoded: String = ExactJson.stringify(saved)
	if _expect(not encoded.is_empty(), "paired " + stage + " encodes the finite aggregate with exact-json-1"):
		var decoded: Dictionary = ExactJson.parse(encoded)
		if _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "paired " + stage + " decodes the exact-json-1 aggregate: " + String(decoded.get("reason", ""))):
			var transported: Dictionary = decoded["value"]
			_expect(ExactJson.stringify(transported) == encoded, "exact-json-1 paired " + stage + " preserves the entire native aggregate")
			var json_player_error: String = _game.player.snapshot_error(transported["player"])
			var json_level_error: String = "saved-player preflight rejected before local proof"
			if json_player_error.is_empty():
				json_level_error = _game.active_level.snapshot_error_with_player(transported["level"], transported["player"])
			_expect(transported["level"]["local"]["scheduler"]["clock_s"] == clock and transported["level"]["local"]["exchange"]["clock_s"] == clock, "exact-json-1 paired " + stage + " clocks retain exact native values")
			_expect(json_player_error.is_empty() and json_level_error.is_empty(), "strict exact-json-1 paired " + stage + " full saved-player/local preflight: player=" + json_player_error + " local=" + json_level_error)
	_expect(Codec.same_values(_game.attempts.state()["story"]["checkpoint"], checkpoint), "ordinary paired " + stage + " pause cannot replace the authored retry checkpoint")
	return saved


func _retry_pair_phase(state: Dictionary, stage: String) -> bool:
	if state.get("beat") != "departure":
		return false
	var any_warning: bool = false
	var any_lock: bool = false
	for id: String in RETRY_PAIR_IDS:
		var record: Dictionary = state.get("exchanges", {}).get(id, {})
		if record.get("status") != "running" or record.get("phase") not in ["warning", "lock"]:
			return false
		any_warning = any_warning or record.get("phase") == "warning"
		any_lock = any_lock or record.get("phase") == "lock"
	# Authored stagger permits one warning beside its partner's immutable lock.
	return any_warning if stage == "warning" else any_lock


func _retry_old_refs(level: Node, hero: Node, driver: Node) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	var nodes: Array[Node] = [level, hero, _game.fx, driver, level.get_node("DryGround"), level.get_node("HorsellHeathKit")]
	for index: int in range(6):
		nodes.append(level.get_node("HorsellHeathKit/NonhostileWitness_%d" % index))
	nodes.append(level.get_node("HorsellHeathKit/HarmlessDistantEruption"))
	for actor: Node in _actors.values():
		nodes.append(actor)
	for cue: Node in get_nodes_in_group("required_cues"):
		if level.is_ancestor_of(cue):
			nodes.append(cue)
	for node: Node in nodes:
		refs.append({"label": String(node.name), "ref": weakref(node)})
	return refs


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
