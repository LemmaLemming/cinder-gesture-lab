extends "res://tests/acts/act1/a1_l3_actor_pair.gd"
## Actual C31/C32 consumer component, ordinary primary field activation and
## complete paused environmental units. Full campaign/progression is excluded.

const SporeGrovePath: String = "res://scenes/acts/act1/a1_l3_spore_grove_component.tscn"
const SporeGuardPath: String = "res://scenes/acts/act1/a1_l3_spore_guard_component.tscn"
var component_units: Array[Dictionary] = []
var observed_spore_phases: Dictionary = {}


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "spore portrait requires the actual native renderer"):
			await _finish(); return
		capture_dir = "res://.cinder/captures/l3-spores-%d" % Time.get_ticks_usec()
		if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "native spore capture directory is writable"):
			await _finish(); return
	if not await _open_world(SporeGrovePath, "grove", Vector3(0, 0.1, 15)):
		await _finish(); return
	_watch_pair_events()
	if not await _wait(func() -> bool: return level.get("spores_ready"), "actual three living grounded C31s bind the published native protocol before a hittable mushroom exists"):
		await _finish(); return
	var field: CinderSporeField = level.get("spore_field")
	var consumer: CinderSporeRepulsion = level.get("spore_consumer")
	var actor: Act1MushroomSelenite = sources["umbrella-1"]
	consumer.reaction_started.connect(func(id: String, _episode: String) -> void: observed_spore_phases[id + "/recoil"] = true)
	if not await _swipe(Vector3.FORWARD, "native spore cluster approach"):
		await _finish(); return
	var actual_before: Dictionary = actor.get_spore_response_state()
	if not _require(actor.hp == 16.0 and actual_before.velocity != Vector3.ZERO and actual_before.phase == "none" and actor.state().approach_driving and actor.state().reservation_id.is_empty(), "genuine unharmed C31 approaches before repulsion without a fake lease or hurt flag"):
		await _finish(); return
	if not await _pause_pair("bound approaching native source") or not _quiet_component("bound approaching native source") or not await _capture("bound-approach") or not await _gui_resume_pair():
		await _finish(); return
	var hp_before: Dictionary = {}
	for id: String in level.call("current_source_ids"): hp_before[id] = sources[id].hp
	if not await _cluster_primary(field.get_node("cluster-right") as Node3D, "first finite spore release"):
		await _finish(); return
	if not _require(field.state().generation == 1 and field.state().spent_ids == ["cluster-right"] and consumer.placement_accepted(), "real ordinary primary spends one actual cluster and preserves accepted native custody"):
		await _finish(); return
	if not await _wait(func() -> bool: return actor.get_spore_response_state().phase == "recoil", "actual living C31 enters genuine recoil"):
		await _finish(); return
	if not await _pause_pair("native recoil") or not _quiet_component("native recoil") or not await _capture("recoil") or not await _gui_resume_pair():
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


func _cluster_primary(cluster: Node3D, label: String) -> bool:
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
	if not _guard_input(): return false
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
	if portrait:
		var evidence: FileAccess = FileAccess.open(capture_dir.path_join("evidence.json"), FileAccess.WRITE)
		if evidence != null: evidence.store_string(JSON.stringify({"checks": checks, "failures": failures, "swipes": swipes, "primaries": primaries, "shots": shots, "units": component_units}, "\t"))
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 NATIVE SPORE COMPONENT: %d checks, %d failures; %d real swipes/%d ordinary primaries; full campaign/guard/callback injury/fresh-recipient tests pending" % [checks, failures, swipes, primaries])
	quit(1 if failures else 0)
