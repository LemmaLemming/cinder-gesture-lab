extends SceneTree
## Actual Horsell combat/route fixture. The saved Act1 prefix and next destination
## are TEST ONLY prerequisites, not Act1/Act2-L2 gameplay or campaign acceptance.
## The bot reads public witnesses and uses actual dash/primary actions. It never
## moves a live actor by assignment, forces recovery, or emits progression requests.
## Select with --route=left/right/both and --loadout=standard/heavy/slow_cargo_longstep/
## slow_padded_reach/quick, --profile=standard/assisted/challenge (default standard).
## --capture-live requires the graphical portrait view. The profile provider is
## TEST ONLY and resolves the chosen fixed epoch through normal level entry.

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
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"
const NextPath: String = "res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn"
const TEST_ROOT: String = "user://test-a2-l1-live-level/"
const PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5"]
const FORK_REGION: Rect2 = Rect2(-2.8, -14.2, 5.6, 3.8)
const DEPARTURE_REGION: Rect2 = Rect2(-2.5, -20.7, 5.0, 1.5)
const EXIT_REGION: Rect2 = Rect2(-2.5, -30.15, 5.0, 1.6)
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
var _route: String = ""
var _routes: Array[String] = ["left", "right"]
var _loadout_name: String = "heavy"
var _loadout: Dictionary = LOADOUTS["heavy"].duplicate(true)
var _expected_stats: Dictionary = {}
var _profile_id: String = "standard"
var _expected_role: Dictionary = {}
var _capture_live: bool = false
var _captured: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _read_options():
		quit(1)
		return
	if _capture_live:
		root.size = Vector2i(540, 1170)
		if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_ROOT)) == OK, "create ignored live portrait capture directory"):
			quit(1)
			return
	print("Horsell live fixture scope: routes=%s loadout=%s profile=%s existing IDs=%s; initial zero ammo, ordinary primary only; TEST ONLY prefix/destination/profile provider" % [_routes, _loadout_name, _profile_id, _loadout])
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	for route: String in _routes:
		var failures_before: int = _failures
		if not await _run_route(route):
			if _failures == failures_before:
				_expect(false, "live %s route aborted: %s" % [route, _diagnostic()])
			break
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "test injection leaves canonical registry bytes unchanged")
	if is_instance_valid(_game):
		_game.free()
	paused = false
	_cleanup()
	print("Horsell live level smoke: %d checks, %d failures; routes=%s loadout=%s profile=%s; TEST ONLY prefix/destination/profile provider, authored L1 actions" % [_checks, _failures, _routes, _loadout_name, _profile_id])
	quit(0 if _failures == 0 else 1)


func _run_route(route: String) -> bool:
	_cleanup()
	_route = route
	_actions.clear()
	_used_proofs.clear()
	_actors.clear()
	_captured.clear()
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw["levels"]:
		if info["id"] in ["A2-L1", "A2-L2"]:
			info["scene_path"] = LevelPath if info["id"] == "A2-L1" else NextPath
			info["readiness"] = "accepted"
			info["accepted_commit"] = "b".repeat(40)
			info["api_revision"] = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L2").is_empty(), "injected next level is explicitly TEST ONLY and preserves canonical route/identity") or not await _seed(registry):
		return false
	_game = Shell.new() as CinderCampaignShell
	_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json")
	root.add_child(_game)
	await _settle()
	_game.menu.difficulty_preference_requested.emit(_profile_id)
	_expect(_game.get_difficulty_preference() == _profile_id, "public settings selects the same fresh preference as the TEST ONLY saved fixed epoch")
	_game.resume_campaign()
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and _game.active_level != null and _game.active_level.has_method("encounter_state"), "actual Horsell installs with the public encounter-state observer: " + _game.campaign_error):
		return false
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	var installed: Dictionary = level.snapshot_state()
	if not _expect(not installed.is_empty() and installed["local"]["profile_id"] == _profile_id and Codec.same_values(installed["local"]["exchange"]["configuration"]["resolved_role"], _expected_role), "actual shell restores the selected canonical fixed profile and role"):
		return false
	if not _expect(hero.presentation_id == "act2_survivor" and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats) and hero.shells == 0, "%s route starts with canonical %s stats, empty ammo and Act2 presentation" % [route, _loadout_name]):
		return false
	if _loadout_name == "heavy":
		_expect(is_equal_approx(float(hero.stats.primary_range), 1.8), "default Heavy baseline uses the actual shortest shared primary reach")
	for node: Node in get_nodes_in_group("enemies"):
		if level.is_ancestor_of(node):
			_actors[String(node.get("actor_id"))] = node
	if not _expect(_actors.size() == 7 and not _contains_pickup(level), "seven authored stationary targets include one unchosen alternative; no pickup supplies the victory"):
		return false
	var defeats: Array[String] = []
	for actor: Node in _actors.values():
		actor.connect("defeated", func(id: String) -> void: defeats.append(id))
	var checkpoints: Array[String] = []
	var completions: Array[String] = []
	var exits: Array[String] = []
	var resources_at_exit: Dictionary = {}
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append(checkpoint)
		_expect(kind == "encounter", "live authored checkpoint uses the shared encounter boundary")
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
	for id: String in ["arrival", "road_east", "road_west"]:
		if not await _clear([id]):
			return false
	_expect(_state()["beat"] == "fork" and checkpoints == ["horsell-arrival-clear", "horsell-road-clear"], "three actual primary defeats preserve sequential road encounters and their checkpoint order")
	var chosen_region: Rect2 = Rect2(-2.7, -13.3, 2.5, 2.2) if route == "left" else Rect2(0.2, -13.3, 2.5, 2.2)
	if not await _dash_to_region(chosen_region):
		return false
	var fork_dash: Dictionary = _last_dash()
	var landing: Vector3 = fork_dash.get("landing", Vector3.INF)
	_expect(landing.is_finite() and FORK_REGION.has_point(Vector2(landing.x, landing.z)) and (landing.x < 0.0) == (route == "left") and _state()["active_ids"] == ["common_" + route], "actual completed dash landing selects only the %s common approach" % route)
	if not await _clear(["common_" + route]):
		return false
	_expect(checkpoints == ["horsell-arrival-clear", "horsell-road-clear", "horsell-reunion"] and _state()["active_ids"] == ["departure_a", "departure_b"], "selected common clear rejoins and activates the logical final pair")
	var unchosen: String = "common_right" if route == "left" else "common_left"
	_expect(float(_actors[unchosen].get("hp")) == 30.0 and not defeats.has(unchosen), "unchosen common target is not mandatory or silently defeated")
	if not await _dash_to_region(DEPARTURE_REGION, false, true):
		return false
	_expect(checkpoints.size() == 4 and checkpoints[3] == "horsell-before-departure" and level.current_checkpoint()["id"] == checkpoints[3], "actual before-departure contact records one distinct checkpoint before final combat")
	var departure_response: Dictionary = hero.get_threat_response_state()
	_expect(_dash_touches_region(_last_dash(), DEPARTURE_REGION) and departure_response.get("stable", false) and float(departure_response.get("commitment_remaining_s", 1.0)) <= 0.00001, "actual last completed dash crosses the departure strip and checkpoint verification occurs at a stable finished landing")
	if not await _clear(["departure_a", "departure_b"]):
		return false
	await _settle()
	_expect(defeats.slice(0, 4) == ["arrival", "road_east", "road_west", "common_" + route] and defeats.size() == 6 and defeats.has("departure_a") and defeats.has("departure_b"), "exact six authored defeats occur, with either final-pair order and no padded wave")
	_expect(_state()["beat"] == "clear" and _state()["exit_open"] and level.is_completed() and completions == ["horsell-scouts-clear"], "real final pair clear opens Woking and requests once-only completion")
	await _capture_state()
	if _capture_live:
		for phase: String in ["warning", "lock", "active", "recovery", "first-pair", "pair-committed", "clear"]:
			_expect(_captured.has(phase), "actual live story captured " + phase)
	_game.request_pause()
	await _settle()
	var aggregate: Dictionary = _game.capture_campaign_snapshot()
	_expect(_game.campaign_error.is_empty() and not aggregate.is_empty() and _game.attempts.state()["completed_main"] == PREFIX + ["A2-L1"] and aggregate["level"]["progress"]["contact_exit_id"].is_empty(), "shell durably records actual L1 clear while authored exit remains separate: " + _game.campaign_error)
	var primary_hits: int = 0
	var dashes: int = 0
	for action: Dictionary in _actions:
		_expect(action["kind"] != "blast", "empty-ammo completion never depends on a blast")
		_expect(action["equipment_ids"] == _loadout and Codec.same_values(action["resolved_stats"], _expected_stats), "executed world action retains the selected canonical IDs/stats")
		if action["kind"] == "primary":
			primary_hits += int(action["hits"])
		elif action["kind"] == "dash":
			dashes += 1
	_expect(primary_hits >= 6 and dashes > 0 and hero.equipment.snapshot() == _loadout, "real shared %s primary hits and sampled dashes supply every defeat without equipment/pickup changes" % _loadout_name)
	var old_nodes: Array[Node] = [level, hero, _game.fx, level.get_node("DryGround"), level.get_node("HorsellHeathKit")]
	for actor: Node in _actors.values():
		old_nodes.append(actor)
	for cue: Node in get_nodes_in_group("required_cues"):
		if level.is_ancestor_of(cue):
			old_nodes.append(cue)
	_game.resume_campaign()
	if not await _dash_to_region(EXIT_REGION, true):
		return false
	await _settle()
	_expect(_game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L2" and _game.active_level.scene_file_path == NextPath, "actual Woking contact installs the injected TEST ONLY destination through the shared shell")
	_expect(exits.size() == 1 and completions == ["horsell-scouts-clear"] and resources_at_exit.size() == 3, "actual contact emits one exit and does not repeat the level completion")
	for old: Node in old_nodes:
		_expect(not is_instance_valid(old), "transition frees the old actual Horsell actor/floor/scenery/required cue")
	_expect(_game.player.hp == resources_at_exit.get("hp") and _game.player.shells == resources_at_exit.get("shells") and _game.player.equipment.snapshot() == resources_at_exit.get("equipment") and not _game.active_level.is_completed(), "transition preserves exact contact resources/gear and does not manufacture next-level gameplay/completion")
	_game.free()
	_game = null
	paused = false
	print("Horsell live route completed: ", route, " loadout=", _loadout_name, " profile=", _profile_id)
	return _failures == 0


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
	var aggregate: Dictionary = {"schema_version": 1, "level_id": "A2-L1", "scene_path": LevelPath, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": actor_state, "level": local_state, "shell": shell_state}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var seed: Dictionary = model.state()
	seed["completed_main"] = PREFIX.duplicate()
	# Synthetic prior catalogue unlocks in this TEST ONLY saved-story seed. They
	# certify neither Act1 play nor a new Horsell reward/runtime equipment grant.
	for id: String in _loadout.values():
		if not seed["unlocked_equipment"].has(id):
			seed["unlocked_equipment"].append(id)
	print("TEST ONLY synthetic prior catalogue unlocks for selected seed gear: ", _loadout.values())
	seed["story"] = {"kind": "story", "level_id": "A2-L1", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var store: CinderSaveStore = Store.new(TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var seed_error: String = model.state_error(seed)
	var valid: bool = not actor_state.is_empty() and not local_state.is_empty() and seed_error.is_empty()
	var saved: bool = valid and store.write_payload(seed)
	if not saved:
		print("Horsell seed rejection: actor_error=%s level_error=%s runtime_error=%s model_error=%s store_error=%s actor_keys=%s level_keys=%s" % [hero.last_snapshot_error, level.last_snapshot_error, level.get("runtime_error"), seed_error, store.last_error, actor_state.keys(), local_state.keys()])
	_expect(saved, "TEST ONLY Act1 prefix seeds real captured Horsell/player state: " + store.last_error)
	preview.free()
	_expect(not is_instance_valid(hero) and not is_instance_valid(level), "seed MainScene and actor are freed before actual shell installation")
	return saved


func _clear(ids: Array[String]) -> bool:
	var seen_admitted: Dictionary = {}
	for frame: int in range(1800):
		if not _live():
			return _expect(false, "live encounter stopped before clearing %s: %s" % [ids, _diagnostic()])
		var living: Array[String] = []
		for id: String in ids:
			if float(_actors[id].get("hp")) > 0.0:
				living.append(id)
		if living.is_empty():
			if ids.size() == 2:
				_expect(seen_admitted.has(ids[0]) and seen_admitted.has(ids[1]), "both final Scout actors enter actual local admission")
			print("Horsell targets cleared through primary: ", ids)
			return true
		var state: Dictionary = _state()
		for admitted: String in state["admitted_ids"]:
			seen_admitted[admitted] = true
		var latest: Dictionary = _latest_proof(living)
		if not latest.is_empty():
			var proof_key: String = "%s:%s" % [latest["actor_id"], latest["cycle"]]
			_used_proofs[proof_key] = true
			if not await _follow_proof(latest, living):
				return false
		elif frame % 90 == 0:
			var target: Node3D = _actors[living[0]] as Node3D
			var offset: Vector3 = _game.player.global_position - target.global_position
			offset.y = 0.0
			if offset.length() > 3.45:
				if not await _navigate_dash(target.global_position + offset.normalized() * 3.0):
					return false
		await _step()
	return _expect(false, "bounded bot found no complete ordinary-primary response for %s: %s" % [ids, _diagnostic()])


func _latest_proof(ids: Array[String]) -> Dictionary:
	var latest: Dictionary = {}
	for id: String in ids:
		var state: Dictionary = _state()["exchanges"].get(id, {})
		var key: String = "%s:%s" % [id, state.get("cycle", -1)]
		if state.get("status") != "running" or not state.get("armed", false) or not state.get("proof_available", false) or _used_proofs.has(key):
			continue
		if latest.is_empty() or float(state["exchange"]["lock_from_s"]) > float(latest["exchange"]["lock_from_s"]):
			latest = state
	return latest


func _follow_proof(state: Dictionary, ids: Array[String]) -> bool:
	var exchange: Dictionary = state["exchange"]
	var id: String = state["actor_id"]
	if not _expect(float(exchange["active_from_s"]) - float(exchange["lock_from_s"]) >= 1.1 - 0.00001 and is_equal_approx(float(exchange["active_from_s"]) - float(exchange["lock_from_s"]), float(_expected_role["lock_s"])) and Codec.same_values(state["resolved_role"], _expected_role) and state["proof"].get("accepted", false), "live %s tracking commit retains full1.10 lock, canonical role and an actual response witness" % _profile_id):
		return false
	for segment: Dictionary in state["proof"]["path"]:
		if segment["kind"] not in ["escape_dash", "positioning_dash", "ordinary_primary"]:
			continue
		while _live() and float(_state()["clock_s"]) + 0.00001 < float(segment["start_s"]):
			var replacement: Dictionary = _latest_proof(ids)
			if not replacement.is_empty() and float(replacement["exchange"]["lock_from_s"]) > float(exchange["lock_from_s"]):
				return true # A fresh union proof replaces this older planned response.
			await _step()
		if not _live():
			return false
		if segment["kind"] == "ordinary_primary":
			var actor: Node3D = _actors[id] as Node3D
			if float(actor.get("hp")) <= 0.0:
				return true
			var actual: Dictionary = _state()["exchanges"].get(id, {})
			if actual.get("phase") != "recovery":
				return true # A cancelled/expired exchange grants no test opening.
			var direction: Vector3 = actor.global_position - _game.player.global_position
			direction.y = 0.0
			var driver: Node = _game.active_level.get_node("HorsellRayExchanges")
			var gate_open: bool = driver.call("damage_window_open", id)
			var opening: Node3D = driver.call("get_opening_cue", id)
			var before_slash: Dictionary = {
				"requested_actor_id": id, "planned_cycle": state["cycle"],
				"actor": {"hp": actor.get("hp"), "phase": actor.get("phase"), "phase_progress": actor.get("phase_progress"), "position": actor.global_position, "visible": actor.is_visible_in_tree()},
				"hero_position": _game.player.global_position, "distance": direction.length(), "range": _game.player.stats.primary_range,
				"hero_response": _game.player.get_threat_response_state().duplicate(true),
				"scheduler_clock_s": _state()["clock_s"], "planned_primary_time_s": segment["start_s"],
				"planned_exchange": exchange.duplicate(true), "planned_proof": state["proof"].duplicate(true),
				"current_driver": driver.call("state", id), "gate_open": gate_open,
				"opening_cue": opening.call("state") if is_instance_valid(opening) else {},
				"admission_errors": _state().get("admission_errors", {}).duplicate(true),
			}
			var hits: int = _game.player.slash(direction.normalized())
			if hits <= 0:
				print("Horsell zero-hit primary before-action diagnostic: ", before_slash)
			return _expect(hits > 0, "public witness affords a real %s ordinary-primary housing hit" % _loadout_name)
		var direction: Vector3 = segment["to"] - segment["from"]
		direction.y = 0.0
		if not await _dash(direction.normalized()):
			return false
	return true


func _dash_to_region(region: Rect2, allow_exit_transition: bool = false, accept_departure_checkpoint: bool = false) -> bool:
	for attempt: int in range(18):
		if _game.active_level.level_id != "A2-L1":
			return _expect(allow_exit_transition and _game.active_level.level_id == "A2-L2" and _game.active_level.scene_file_path == NextPath, "only final Woking navigation may transition to the TEST ONLY destination")
		var at: Vector3 = _game.player.global_position
		if accept_departure_checkpoint and _departure_checkpoint_stable():
			return true
		if not accept_departure_checkpoint and region.has_point(Vector2(at.x, at.z)):
			return true
		if not await _navigate_dash(Vector3(region.get_center().x, 0, region.get_center().y), allow_exit_transition):
			return false
		if accept_departure_checkpoint and _dash_touches_region(_last_dash(), region):
			return await _wait_for_departure_checkpoint()
	return _expect(false, "actual swipe bot failed to land in authored region %s: %s" % [region, _diagnostic()])


func _departure_checkpoint_stable() -> bool:
	var response: Dictionary = _game.player.get_threat_response_state()
	return _state().get("departure_checkpoint", false) and response.get("stable", false) and float(response.get("commitment_remaining_s", 1.0)) <= 0.00001


func _wait_for_departure_checkpoint() -> bool:
	# Completed publication precedes the normal landing settle. A real crossing
	# must finish its stable checkpoint before the bot may ask for another dash.
	for frame: int in range(180):
		if not _live():
			return _expect(false, "live encounter stopped while settling actual departure contact: " + _diagnostic())
		if _departure_checkpoint_stable():
			return true
		await _step()
	return _expect(false, "actual departure crossing did not reach a stable public checkpoint: " + _diagnostic())


func _dash_touches_region(record: Dictionary, region: Rect2) -> bool:
	if record.get("kind") != "dash" or not record.get("path") is Array:
		return false
	for sample: Dictionary in record["path"]:
		var point: Variant = sample.get("position")
		if point is Vector3 and point.is_finite() and point.y > -0.05 and point.y < 0.2 and region.has_point(Vector2(point.x, point.z)):
			return true
	return false


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
		if _state()["beat"] == "fork" and FORK_REGION.has_point(Vector2(predicted.x, predicted.z)) and (predicted.x < 0.0) != (_route == "left"):
			continue # A navigation swipe must not choose the opposite actual branch.
		var distance: float = Vector2(predicted.x - goal.x, predicted.z - goal.z).length_squared()
		if distance < score:
			best = direction
			score = distance
	if not _expect(best != Vector3.ZERO, "actual scenery leaves a navigation swipe"):
		return false
	return await _dash(best, allow_exit_transition)


func _dash(direction: Vector3, allow_exit_transition: bool = false) -> bool:
	var hero: CinderPlayer = _game.player
	var ready: bool = false
	for frame: int in range(180):
		if not _live():
			return false
		var response: Dictionary = hero.get_threat_response_state()
		if not paused and response["stable"] and float(response["dash_cooldown_left_s"]) <= 0.00001:
			ready = true
			break
		await _step()
	if not _expect(ready, "bot awaits an unpaused stable actor and actual dash cooldown"):
		return false
	var before: int = _actions.size()
	if not _expect(hero.request_dash(direction), "bot uses the shared accepted dash request"):
		return false
	for frame: int in range(180):
		for action: Dictionary in _actions.slice(before):
			if action["kind"] == "dash":
				var landing: Vector3 = action["landing"]
				return _expect(landing.is_finite() and landing.y > -0.05 and action["path"].size() >= 2, "actual completed dash has a supported sampled world landing")
		if not is_instance_valid(hero):
			if allow_exit_transition and _game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L2" and _game.active_level.scene_file_path == NextPath:
				return _expect(true, "actual Woking contact may transition during a dash without inventing its unfinished world-action record")
			break
		await _step()
	return _expect(false, "shared dash did not publish a completed world action")


func _state() -> Dictionary:
	return _game.active_level.call("encounter_state") if _game.active_level.level_id == "A2-L1" else {}


func _live() -> bool:
	return is_instance_valid(_game) and _game.campaign_error.is_empty() and is_instance_valid(_game.player) and not _game.player.dead and _game.active_level.level_id == "A2-L1" and String(_state().get("runtime_error", "")).is_empty()


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
	if is_instance_valid(_game) and paused and _game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L1" and _game.menu.page_name() == "resume" and not _game.player.dead:
		_game.resume_campaign()
	await _capture_state()


func _read_options() -> bool:
	var route_option: String = "both"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--route="):
			route_option = argument.trim_prefix("--route=")
		elif argument.begins_with("--loadout="):
			_loadout_name = argument.trim_prefix("--loadout=")
		elif argument.begins_with("--profile="):
			_profile_id = argument.trim_prefix("--profile=")
		elif argument == "--capture-live":
			_capture_live = true
	if not _expect(route_option in ["left", "right", "both"] and LOADOUTS.has(_loadout_name) and _profile_id in ["standard", "assisted", "challenge"], "supported route/loadout/profile selector"):
		return false
	_routes.assign(["left", "right"] if route_option == "both" else [route_option])
	_loadout = LOADOUTS[_loadout_name].duplicate(true)
	var resolver: CinderEquipment = Equipment.new() as CinderEquipment
	if not _expect(resolver.restore(_loadout), "selector names only implemented canonical equipment IDs"):
		return false
	_expected_stats = resolver.resolved_stats()
	_expected_role = Difficulty.new().resolve_role(RayExchange.RAW_ROLE, _profile_id, RayExchange.TIMING_FLOORS)
	if not _expect(not _expected_role.is_empty(), "shared resolver accepts the selected profile with unchanged authored raw role/timing floors"):
		return false
	return _expect(not _capture_live or DisplayServer.get_name() != "headless", "live portrait capture requires a graphical engine session")


func _capture_state() -> void:
	if not _capture_live or not _live() or paused:
		return
	var state: Dictionary = _state()
	var labels: Array[String] = []
	for id: String in state["active_ids"]:
		var exchange: Dictionary = state["exchanges"][id]
		var phase: String = String(exchange.get("phase", ""))
		if phase in ["warning", "lock", "active", "recovery"] and not _captured.has(phase):
			labels.append(phase)
	if state["beat"] == "departure" and state["admitted_ids"].has("departure_a") and state["admitted_ids"].has("departure_b") and float(_actors["departure_a"].get("hp")) > 0.0 and float(_actors["departure_b"].get("hp")) > 0.0 and not _captured.has("first-pair"):
		labels.append("first-pair")
	if _pair_committed(state) and not _captured.has("pair-committed"):
		labels.append("pair-committed")
	if state["beat"] == "clear" and not _captured.has("clear"):
		labels.append("clear")
	if labels.is_empty():
		return
	# Draw the current actual scene without pausing, teleporting, changing poses
	# or re-requesting a proof. This adds only normal render time to the bot.
	await RenderingServer.frame_post_draw
	if not _live() or paused:
		return
	state = _state()
	var phases: Dictionary = {}
	for id: String in state["active_ids"]:
		phases[id] = state["exchanges"][id].get("phase", "clear")
	var image: Image = root.get_texture().get_image()
	if not _expect(image.get_size() == Vector2i(540, 1170), "actual live portrait texture is native 540x1170"):
		return
	for label: String in labels:
		if _captured.has(label):
			continue
		# A phase can change while drawing. Label only the state actually rendered.
		if label in ["warning", "lock", "active", "recovery"] and not phases.values().has(label):
			continue
		if label == "first-pair" and (state["beat"] != "departure" or not state["admitted_ids"].has("departure_a") or not state["admitted_ids"].has("departure_b") or float(_actors["departure_a"].get("hp")) <= 0.0 or float(_actors["departure_b"].get("hp")) <= 0.0):
			continue
		if label == "pair-committed" and not _pair_committed(state):
			continue
		if label == "clear" and state["beat"] != "clear":
			continue
		var path: String = CAPTURE_ROOT + "a2-l1-" + _profile_id + "-" + _loadout_name + "-" + _route + "-" + label + ".png"
		if not _expect(image.save_png(path) == OK, "save actual live portrait " + label):
			return
		var exchanges: Dictionary = {}
		for id: String in state["active_ids"]:
			var current: Dictionary = state["exchanges"][id]
			var footprint: Dictionary = current.get("geometry", {})
			var witness: Dictionary = current.get("presentation_witness", {})
			exchanges[id] = {"phase": current["phase"], "status": current["status"], "armed": current["armed"], "cycle": current["cycle"], "source": Codec.vector3(current["source_position"]), "geometry": {"from": Codec.vector3(footprint["from"]), "to": Codec.vector3(footprint["to"]), "radius": footprint["radius"]} if not footprint.is_empty() else {}, "landing": Codec.vector3(witness["landing"]) if witness.has("landing") else [], "attack_position": Codec.vector3(witness["attack_position"]) if witness.has("attack_position") else []}
			var rig: Node = _actors[id].get_node("ScoutRig")
			exchanges[id]["readability"] = rig.call("readability_state")
		var bank_alpha: Dictionary = {}
		for surface: Node in _game.active_level.get_node("DryGround").find_children("BankSurface", "MeshInstance3D", true, false):
			bank_alpha[String(surface.get_parent().name)] = (surface.material_override as StandardMaterial3D).albedo_color.a
		_captured[label] = {"image": path, "route": _route, "loadout": _loadout_name, "profile": _profile_id, "beat": state["beat"], "clock_s": state["clock_s"], "phases": phases.duplicate(), "hero_position": Codec.vector3(_game.player.global_position), "world_action_count": _actions.size(), "exchanges": exchanges, "bank_alpha": bank_alpha}
		print("Actual live portrait: ", path)
	var metadata: FileAccess = FileAccess.open(CAPTURE_ROOT + "a2-l1-" + _profile_id + "-" + _loadout_name + "-" + _route + "-evidence.json", FileAccess.WRITE)
	if _expect(metadata != null, "open ignored actual live capture metadata"):
		metadata.store_string(JSON.stringify({"scope": "actual authored L1 bot actions; TEST ONLY prefix/destination; no human balance or later-level acceptance", "frames": _captured}, "\t", true, true))


func _pair_committed(state: Dictionary) -> bool:
	if state.get("beat") != "departure":
		return false
	var armed: bool = false
	for id: String in ["departure_a", "departure_b"]:
		if not state["admitted_ids"].has(id) or float(_actors[id].get("hp")) <= 0.0 or state["exchanges"][id].get("status") != "running":
			return false
		armed = armed or state["exchanges"][id].get("armed", false)
	return armed


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
