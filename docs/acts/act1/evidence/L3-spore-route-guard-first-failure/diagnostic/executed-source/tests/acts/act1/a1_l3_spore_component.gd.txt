extends "res://tests/acts/act1/a1_l3_actor_pair.gd"
## Actual C31/C32 consumer component, ordinary primary field activation and
## complete paused environmental units. Full campaign/progression is excluded.

const SporeGrovePath: String = "res://scenes/acts/act1/a1_l3_spore_grove_component.tscn"
const SporeGuardPath: String = "res://scenes/acts/act1/a1_l3_spore_guard_component.tscn"
var component_units: Array[Dictionary] = []
var observed_spore_phases: Dictionary = {}
var recoil_pause_requested: bool = false
var callback_capture_rejected: bool = false


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "spore portrait requires the actual native renderer"):
			await _finish(); return
		capture_dir = "res://.cinder/captures/l3-spores-%d" % Time.get_ticks_usec()
		if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "native spore capture directory is writable"):
			await _finish(); return
	if not await _open_spore_world(SporeGrovePath, "grove", Vector3(0, 0.1, 15)):
		await _finish(); return
	_watch_pair_events()
	if not await _wait(func() -> bool: return level.get("spores_ready"), "actual living grounded C31 binds the published native protocol before a hittable mushroom exists"):
		await _finish(); return
	var field: CinderSporeField = level.get("spore_field")
	var consumer: CinderSporeRepulsion = level.get("spore_consumer")
	var actor: Act1MushroomSelenite = sources["umbrella-1"]
	consumer.reaction_started.connect(func(id: String, _episode: String) -> void:
		observed_spore_phases[id + "/recoil"] = true
		callback_capture_rejected = (level.call("component_unit_state") as Dictionary).is_empty()
		recoil_pause_requested = game.call("request_pause_deferred"))
	if not await _swipe(Vector3.FORWARD, "native spore cluster approach"):
		await _finish(); return
	var actual_before: Dictionary = actor.get_spore_response_state()
	print("L3 SPORE APPROACH DIAGNOSTIC response=", actual_before, " native=", actor.pure_presentation_state(), " actor_error=", actor.last_error, " parent_approach=", level.get("last_approach_error"), " parent_encounter=", level.get("last_encounter_error"), " camera=", game.call("get_camera_framing_state"), " camera_error=", game.call("camera_framing_error", level.camera_framing_points()))
	if not _require(actor.hp == 16.0 and actual_before.velocity != Vector3.ZERO and actual_before.phase == "none" and actor.state().approach_driving and actor.state().reservation_id.is_empty(), "genuine unharmed C31 approaches before repulsion without a fake lease or hurt flag"):
		await _finish(); return
	if not await _pause_pair("bound approaching native source") or not _quiet_component("bound approaching native source") or not await _capture("bound-approach") or not await _gui_resume_pair():
		await _finish(); return
	var hp_before: Dictionary = {}
	for id: String in level.call("current_source_ids"): hp_before[id] = sources[id].hp
	if not await _cluster_primary(field.get_node("cluster-right") as Node3D, "first finite spore release", true):
		await _finish(); return
	if not _require(field.state().generation == 1 and field.state().spent_ids == ["cluster-right"] and consumer.placement_accepted(), "real ordinary primary spends one actual cluster and preserves accepted native custody"):
		await _finish(); return
	if not _require(paused and recoil_pause_requested and callback_capture_rejected and observed_spore_phases.has("umbrella-1/recoil") and actor.get_spore_response_state().phase == "recoil", "actual reaction callback rejects capture and public deferred pause preserves genuine living recoil"):
		await _finish(); return
	if not _quiet_component("native recoil") or not _spore_framing("native recoil field/source/retreat") or not await _capture("recoil") or not await _gui_resume_pair():
		await _finish(); return
	if not await _wait(func() -> bool: return actor.get_spore_response_state().phase == "retreat", "actual shared Route advances a living C31 away from the field"):
		await _finish(); return
	var retreat: Dictionary = actor.get_spore_response_state()
	if not _require(retreat.velocity != Vector3.ZERO and not actor.state().approach_driving and actor.state().reservation_id.is_empty() and actor.hp == hp_before["umbrella-1"], "actual Route owns retreat velocity while native approach/attack remain suppressed and HP unchanged"):
		await _finish(); return
	if not await _pause_pair("native moving retreat") or not _quiet_component("native moving retreat") or not await _capture("retreat") or not await _gui_resume_pair():
		await _finish(); return
	if not await _wait(func() -> bool: return actor.get_spore_response_state().phase == "hold", "living source reaches and holds its actual outside-union endpoint"):
		await _finish(); return
	var stopped: Vector3 = actor.global_position
	if not _require(_planar_distance(stopped, field.global_position) > 1.5 + float(actor.get_spore_response_state().support_radius) and actor.velocity == Vector3.ZERO, "native endpoint is outside the active field with its measured capsule support"):
		await _finish(); return
	if not await _pause_pair("native held field") or not _quiet_component("native held field") or not await _capture("hold") or not await _gui_resume_pair():
		await _finish(); return
	if not await _wait(func() -> bool: return actor.get_spore_response_state().phase == "regroup", "living source visibly regroups as the actual finite field fades"):
		await _finish(); return
	if not await _pause_pair("native regroup") or not _quiet_component("native regroup") or not await _capture("regroup") or not await _gui_resume_pair():
		await _finish(); return
	if not await _wait(func() -> bool: return actor.get_spore_response_state().phase == "none", "original native source finishes its real episode without re-granting mushroom supply"):
		await _finish(); return
	for id: String in hp_before:
		if not _require(sources[id].hp == hp_before[id] and not sources[id].dead, id + " remains alive at its original HP through the harmless environmental episode"):
			await _finish(); return
	_require(hero.hp == initial_hp and hit_events.is_empty() and field.state().generation == 1 and field.state().spent_ids == ["cluster-right"] and not level.is_completed(), "harmless component preserves Player HP and finite supply without granting campaign completion")
	await _finish()


func _open_spore_world(path: String, scope: String, spawn: Vector3) -> bool:
	await process_frame
	current_scope = scope
	sources.clear(); admissions.clear(); phase_observations.clear()
	world_records.clear(); input_observations.clear(); hit_events.clear()
	events = 0; max_preparing = 0; preparing_violation = false
	game = MainScene.instantiate()
	game.set("level_scene_path", path)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	scheduler = level.get("scheduler") as CinderThreatScheduler if level != null else null
	if not _require(level != null and hero != null and scheduler != null and level.contract_error().is_empty() and level.hero == hero and hero.global_position == spawn, scope + " isolated actual role enters through one shared Hero at its authored spawn"): return false
	sources = (level.get("sources") as Dictionary).duplicate()
	initial_hp = hero.hp
	var current_ids: Array = level.call("current_source_ids")
	if not _require(sources.size() == 4 and current_ids == (["umbrella-1"] if scope == "grove" else ["lone-guard"]), scope + " isolated spore witness retains all four sources but activates exactly its one actual role"): return false
	for id: String in sources:
		var actor: CharacterBody3D = sources[id]
		var state: Dictionary = actor.call("state")
		if not _require(state.source_id == id and state.dormant == (id not in current_ids) and not state.dead and state.hp == (24.0 if id == "lone-guard" else 16.0), id + " retains genuine role HP and actual isolated dormancy"): return false
		actor.connect("state_changed", Callable(self, "_notice_phase").bind(id))
		actor.connect("hit_resolved", Callable(self, "_notice_hit").bind(id))
	level.connect("native_admission_published", _notice_admission)
	hero.world_action_executed.connect(func(record: Dictionary) -> void: world_records.append(record.duplicate(true)); events += 1)
	game.connect("input_observed", func(observation: Dictionary) -> void: input_observations.append(observation.duplicate(true)))
	game.call("resume_lab")
	return _require(not paused, "isolated spore component uses one initial public resume and unchanged focus handling")


func _cluster_primary(cluster: Node3D, label: String, expect_pause: bool = false) -> bool:
	if not await _ready_input(label): return false
	while Time.get_ticks_msec() - last_primary_ms <= 300:
		if not _guard_input(): return false
		await process_frame
	var offset: Vector3 = cluster.global_position - hero.global_position
	offset.y = 0.0
	var direction: Vector3 = offset.normalized()
	var anchor: Vector2 = game.call("get_aim_anchor")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(cluster.is_in_group("environment_attack_targets") and offset.length() <= float(hero.equipment.resolved_stats().primary_range) and _input_safe(tap) and (game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999, label + " reaches the actual low attackable anchor with ordinary exact aim"):
		return false
	var sequence: int = _last_sequence()
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press)
	await process_frame
	if not _guard_input(): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	hero.shells = 0 # Release-only no-blast setup; normal passive reload remains.
	Input.parse_input_event(release)
	await process_frame
	if expect_pause:
		if not await _wait(func() -> bool: return paused, label + " reaches the requested public cancellation/reaction pause", 2.0, true): return false
	elif not _guard_input(): return false
	last_primary_ms = Time.get_ticks_msec()
	primaries += 1
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	return _require(records.size() == 1 and records[0].kind == "primary" and records[0].hits == 0 and records[0].direction.dot(direction) > 0.9999 and game.call("get_input_observation_state").last_observation.kind == "primary_tap" and game.call("get_aim_anchor") == anchor, label + " is one real immediate first-tap primary with no enemy hit/kill credit or blast")


func _quiet_component(label: String) -> bool:
	var unit: Dictionary = level.call("component_unit_state")
	if not _require(not unit.is_empty() and String(level.call("component_unit_error", unit)).is_empty(), label + " captures separately validated whole Player/all four actors/Scheduler/field/native coordinator units: " + String(level.get("last_component_error"))): return false
	var wire: String = Exact.stringify(unit)
	var decoded: Dictionary = Exact.parse(wire)
	var count: int = pair_events
	if not _require(decoded.get("accepted", false) and Exact.stringify(decoded.value) == wire and level.call("restore_component_unit", decoded.value), label + " quiet complete native commit follows physical -> Scheduler -> exchange -> Route order"): return false
	if not _require(Exact.stringify(level.call("component_unit_state")) == wire and pair_events == count, label + " exact quiet roundtrip preserves every original resource/clock/pose/supply without callbacks"): return false
	component_units.append({"label": label, "unit": unit.duplicate(true)})
	var id: String = "umbrella-1"
	var malformed: Array[Dictionary] = []
	var wrong: Dictionary = unit.duplicate(true)
	wrong.actors[id].repulsion.consumer_id += "-foreign"
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.actors[id].repulsion.progress = 1
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.actors[id].repulsion.direction = [0.0, 0.0, 0.0]
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.actors[id].api_revision = "act1-mushroom-selenite-2"
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.fields["component-mushroom"].clock_s += 0.000001
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.coordinator.source_protocols[id].actor_sha256 = "forged"
	malformed.append(wrong)
	for candidate: Dictionary in malformed:
		if not _require(not String(level.call("component_unit_error", candidate)).is_empty() and not level.call("restore_component_unit", candidate) and Exact.stringify(level.call("component_unit_state")) == wire and pair_events == count, label + " rejects malformed native stamp/old API/clock/custody atomically"): return false
	return true


func _spore_framing(label: String) -> bool:
	var points: Array = level.camera_framing_points()
	var actual_error: String = game.call("camera_framing_error", points)
	if not actual_error.is_empty() or not level.last_camera_framing_error.is_empty():
		print("L3 SPORE FRAMING DIAGNOSTIC ", label, " points=", points.size(), " level_error=", level.last_camera_framing_error, " actual_error=", actual_error, " planned=", game.call("get_camera_framing_state"), " source=", sources["umbrella-1"].get_spore_response_state(), " route=", level.get("spore_consumer").source_state("umbrella-1"))
	return _framing(label)


func _finish() -> void:
	if finishing: return
	finishing = true
	paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
	await create_timer(0.5, true).timeout
	if is_instance_valid(game): game.free()
	paused = false
	await process_frame
	_require(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty(), "complete component teardown removes actual enemy and environmental attack groups")
	var evidence_path: String = capture_dir.path_join("evidence.json") if portrait else "res://.cinder/l3-spore-state-%d.json" % Time.get_ticks_usec()
	var evidence: FileAccess = FileAccess.open(evidence_path, FileAccess.WRITE)
	if evidence != null:
		evidence.store_string(JSON.stringify({"checks": checks, "failures": failures, "swipes": swipes, "primaries": primaries, "shots": shots, "units": component_units}, "\t"))
		print("L3 SPORE STATE EVIDENCE ", ProjectSettings.globalize_path(evidence_path))
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 NATIVE SPORE COMPONENT: %d checks, %d failures; %d real swipes/%d ordinary primaries; full campaign/guard/callback injury/fresh-recipient tests pending" % [checks, failures, swipes, primaries])
	quit(1 if failures else 0)
