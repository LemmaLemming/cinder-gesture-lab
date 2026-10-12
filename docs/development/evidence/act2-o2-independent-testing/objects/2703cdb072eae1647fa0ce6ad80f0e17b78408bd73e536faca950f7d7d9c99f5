extends SceneTree

const PlayerScript: GDScript = preload("res://scripts/player.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")

class DamageTarget:
	extends Node3D
	var hp: float = 100.0
	var before_damage: Callable
	func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
		if before_damage.is_valid():
			before_damage.call()
		var loss: float = minf(hp, amount)
		hp -= loss
		return {"accepted": true, "hp_damage": loss}

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	_world_box(arena, Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	await _dash_roundtrip(arena)
	await _attack_and_invalid_checks(arena)
	await _reload_and_knockback_checks(arena)
	await _cancel_and_death_checks(arena)
	await _callback_boundary_checks(arena)
	paused = false
	arena.queue_free()
	await process_frame
	print("Player snapshot smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _dash_roundtrip(arena: Node3D) -> void:
	var wall: StaticBody3D = _world_box(arena, Vector3(1.5, 1, 0), Vector3(0.3, 2, 4))
	var original: CinderPlayer = _player(arena)
	await _ticks(4)
	_expect(original.snapshot_state().is_empty() and original.last_snapshot_error.contains("paused"), "live capture is rejected outside the paused shell barrier")
	paused = true
	for id: String in ["CLOTH-J2", "CLOTH-P1", "CLOTH-S2", "WEAPON-03"]:
		_expect(original.equip_item(id), "legal gear selected before snapshot: " + id)
	original.hp = 13.25
	original.blast(Vector3.FORWARD)
	paused = false
	_expect(original.request_dash(Vector3.RIGHT), "physical dash begins toward blocking scenery")
	_expect(not original.request_dash(Vector3.BACK), "second physical dash is buffered")
	_expect(original.equip_item("WEAPON-04"), "weapon replacement waits for the active action")
	await _ticks(4)
	paused = true
	var captured: Dictionary = original.snapshot_state()
	_expect(not captured.is_empty() and not captured.world_actions.pending_dash.is_empty() and captured.motion.queued_dash == [0.0, 0.0, 1.0] and captured.pending_weapon == "WEAPON-04", "snapshot retains unfinished route, buffered direction and pending weapon")
	_expect(captured.resources.hp == 13.25 and captured.resources.shells == 1 and float(captured.clocks.reload_s) > 0.0, "snapshot retains low HP, spent ammo and partial reload")
	var transported: Dictionary = _json(captured)
	_expect(Codec.value_error(transported).is_empty() and Codec.same_values(captured, transported), "full mid-dash snapshot is finite JSON with no vector/resource references")
	var restored: CinderPlayer = _player(arena)
	var restore_events: Array[String] = []
	_connect_events(restored, restore_events)
	_expect(restored.snapshot_error(transported).is_empty() and restored.restore_state(transported), "fresh shared actor accepts the transported mid-dash state")
	_expect(restore_events.is_empty() and Codec.same_values(captured, restored.snapshot_state()), "restore reproduces actor state without emitting actions/equipment/death events")
	var before_pause: Dictionary = restored.snapshot_state()
	var broken_path: Dictionary = before_pause.duplicate(true)
	broken_path.world_actions.pending_dash.path[-1]["position"] = [99.0, 0.0, 99.0]
	_expect(not restored.restore_state(broken_path) and Codec.same_values(before_pause, restored.snapshot_state()), "mismatched partial route endpoint rejects without changing the resumed actor")
	broken_path = before_pause.duplicate(true)
	broken_path.world_actions.pending_dash.path[-1]["time_s"] = -1.0
	_expect(not restored.restore_state(broken_path) and Codec.same_values(before_pause, restored.snapshot_state()), "invalid partial route clock rejects atomically")
	await create_timer(0.08).timeout
	_expect(Codec.same_values(before_pause, restored.snapshot_state()) and paused, "restored actor clocks, pose and partial path stay frozen while paused")
	# Accepted dictionaries and returned snapshots must never alias live state.
	transported.resources["hp"] = 1.0
	transported.world_actions.pending_dash.path[0]["position"] = [999.0, 0.0, 999.0]
	var exposed: Dictionary = restored.snapshot_state()
	exposed.equipment["weapon"] = "WEAPON-01"
	exposed.world_actions.pending_dash.resolved_stats["dash_speed"] = 999.0
	_expect(Codec.same_values(before_pause, restored.snapshot_state()), "restore input and snapshot result are defensive nested copies")
	paused = false
	await _ticks(38)
	paused = true
	var uninterrupted: Dictionary = original.snapshot_state()
	var resumed: Dictionary = restored.snapshot_state()
	_expect(not uninterrupted.is_empty() and not resumed.is_empty(), "both continued actors remain snapshot-valid")
	_expect(_same_continuation(uninterrupted, resumed), "restored collision-shortened and buffered dashes preserve actual path, landing, resources and remaining clocks")
	var actions: Array[Dictionary] = restored.get_world_action_records()
	_expect(actions.size() == 3 and actions[1].kind == "dash" and actions[1].blocked and actions[1].collision_shortened and actions[2].kind == "dash", "resumed accepted routes publish one real completion each after the original blast")
	_expect(restore_events.count("world") == 2 and restore_events.count("equipment") == 1 and restored.equipment.snapshot().weapon == "WEAPON-04", "restored continuation neither replays history nor duplicates the deferred weapon replacement")
	_expect(actions[1].equipment_ids.weapon == "WEAPON-03" and actions[2].equipment_ids.weapon == "WEAPON-04", "dash snapshots retain gear from their respective actual execution starts")
	original.queue_free()
	restored.queue_free()
	wall.queue_free()
	paused = false
	await process_frame


func _attack_and_invalid_checks(arena: Node3D) -> void:
	var original: CinderPlayer = _player(arena)
	var target := DamageTarget.new()
	arena.add_child(target)
	target.position = Vector3(1.4, 0.02, 0)
	target.add_to_group("practice_targets")
	await _ticks(3)
	_expect(original.slash(Vector3.RIGHT) == 1 and original.blast(Vector3.RIGHT) == 1 and _near(target.hp, 38.0), "attacks deal their ordinary immediate damage before saving")
	original.hp = 7.75
	_expect(original.equip_item("WEAPON-02"), "active attack retains a pending weapon")
	paused = true
	var snapshot: Dictionary = _json(original.snapshot_state())
	_expect(snapshot.phases.logical == "blast" and float(snapshot.phases.logical_left_s) > 0.0 and snapshot.world_actions.history.size() == 2, "mid-attack snapshot distinguishes commitment clocks from already resolved damage")
	var restored: CinderPlayer = _player(arena)
	var events: Array[String] = []
	_connect_events(restored, events)
	_expect(restored.restore_state(snapshot) and events.is_empty() and _near(target.hp, 38.0), "mid-attack restore creates no damage or signals")
	var valid: Dictionary = restored.snapshot_state()
	var bad_cases: Array[Dictionary] = []
	var bad: Dictionary = valid.duplicate(true)
	bad["schema_version"] = true
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad["actor_type"] = "OtherPlayer"
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.erase("resources")
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.equipment["shoes"] = "CLOTH-J0"
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.equipment["weapon"] = "WEAPON-05"
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.resources["hp"] = float(valid.resources.max_hp) + 1.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.resources["shells"] = 0.5
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.resources["dead"] = true
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.motion["velocity"] = [NAN, 0.0, 0.0]
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.motion["facing"] = [2.0, 0.0, 0.0]
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.motion["basis"] = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.clocks["primary_cooldown_s"] = -1.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.clocks["dash_left_s"] = 0.1
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.phases["visual_left_s"] = 50.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad["pending_weapon"] = "CLOTH-P0"
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.world_actions.history[0]["damage"] = 999.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.world_actions.history[0].resolved_stats["primary_range"] = 999.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.world_actions.history[1]["sequence"] = 1
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.world_actions.history[0]["direction"] = Vector3.RIGHT
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.presentation["frame"] = 99
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad["extra_perk"] = "unimplemented"
	bad_cases.append(bad)
	for index: int in range(bad_cases.size()):
		_expect(not restored.snapshot_error(bad_cases[index]).is_empty() and not restored.restore_state(bad_cases[index]) and not restored.last_snapshot_error.is_empty() and Codec.same_values(valid, restored.snapshot_state()) and events.is_empty(), "malformed snapshot %d rejects atomically without state/events changes" % index)
	_expect(restored.restore_state(valid) and restored.restore_state(valid) and _near(restored.hp, 7.75) and _near(restored.max_hp, 100.0) and _near(restored.stats.primary_damage, 20.0), "repeated restoration preserves low HP and recomputes gear without compounded stats")
	paused = false
	_expect(not restored.restore_state(valid) and restored.last_snapshot_error.contains("paused"), "unpaused restore is rejected")
	await _ticks(20)
	paused = true
	_expect(_near(target.hp, 38.0) and events.count("world") == 0 and events.count("equipment") == 1 and restored.equipment.snapshot().weapon == "WEAPON-02", "finishing restored attack only completes its original clock/pending swap without reexecuting damage")
	_expect(_same_continuation(original.snapshot_state(), restored.snapshot_state()), "uninterrupted and restored attack commitments/cooldowns match")
	original.queue_free()
	restored.queue_free()
	target.queue_free()
	paused = false
	await process_frame


func _reload_and_knockback_checks(arena: Node3D) -> void:
	var original: CinderPlayer = _player(arena)
	await _ticks(3)
	original.blast(Vector3.FORWARD)
	original.hp = 9.125
	await _ticks(62)
	paused = true
	var snapshot: Dictionary = _json(original.snapshot_state())
	_expect(snapshot.resources.shells == 1 and float(snapshot.clocks.reload_s) > 1.0 and float(snapshot.clocks.reload_s) < 1.15, "real partial reload is captured just before replenishing one shell")
	var restored: CinderPlayer = _player(arena)
	_expect(restored.restore_state(snapshot) and _near(restored.hp, 9.125) and restored.shells == 1, "near-reload restore preserves ammo and low health")
	paused = false
	await _ticks(12)
	paused = true
	_expect(restored.shells == 2 and original.shells == 2 and _same_continuation(original.snapshot_state(), restored.snapshot_state()), "reload resumes its original deadline and does not grant extra shells")
	original.queue_free()
	restored.queue_free()
	paused = false
	await process_frame

	original = _player(arena)
	await _ticks(3)
	original.take_damage(22.0, Vector3(5.0, 3.0, -2.0))
	await _ticks(2)
	paused = true
	snapshot = _json(original.snapshot_state())
	_expect(float(snapshot.clocks.knockback_left_s) > 0.0 and float(snapshot.clocks.invulnerability_s) > 0.0 and snapshot.motion.velocity[1] > 0.0, "hurt snapshot retains airborne impulse and both remaining deadlines")
	restored = _player(arena)
	_expect(restored.restore_state(snapshot), "airborne knockback state restores")
	paused = false
	await _ticks(20)
	paused = true
	_expect(_same_continuation(original.snapshot_state(), restored.snapshot_state()), "knockback, gravity, invulnerability and hurt pose continue without another hit")
	original.queue_free()
	restored.queue_free()
	paused = false
	await process_frame


func _cancel_and_death_checks(arena: Node3D) -> void:
	for lethal: bool in [false, true]:
		var original: CinderPlayer = _player(arena)
		await _ticks(3)
		original.request_dash(Vector3(0.37, 0.0, -0.91))
		await _ticks(3)
		if lethal:
			original.set("_invulnerable", 0.0)
			original.take_damage(200.0, Vector3(1.0, 0.0, 0.0))
		else:
			original.cancel_world_action_capture()
		paused = true
		var snapshot: Dictionary = _json(original.snapshot_state())
		_expect(snapshot.world_actions.pending_dash.is_empty() and float(snapshot.clocks.dash_left_s) > 0.0 and snapshot.resources.dead == lethal, "cancel/death snapshot keeps motion distinct from discarded capture")
		var restored: CinderPlayer = _player(arena)
		var events: Array[String] = []
		_connect_events(restored, events)
		_expect(restored.restore_state(snapshot) and events.is_empty(), "cancel/death restore does not manufacture completion or another death")
		paused = false
		await _ticks(18)
		paused = true
		_expect(restored.get_world_action_records().is_empty() and events.count("world") == 0 and _same_continuation(original.snapshot_state(), restored.snapshot_state()), "cancelled or dead partial movement never becomes a captured completed action")
		if lethal:
			_expect(restored.dead and restored.hp == 0.0 and _near(restored.get_world_action_clock(), snapshot.world_actions.clock_s), "restored death remains frozen with zero HP")
		original.queue_free()
		restored.queue_free()
		paused = false
		await process_frame


func _callback_boundary_checks(arena: Node3D) -> void:
	var player: CinderPlayer = _player(arena)
	await _ticks(3)
	paused = true
	var before: Dictionary = player.snapshot_state()
	paused = false
	var target := DamageTarget.new()
	arena.add_child(target)
	target.position = Vector3(1.4, 0.02, 0)
	target.add_to_group("practice_targets")
	var guarded: Array[bool] = []
	target.before_damage = func() -> void:
		paused = true
		guarded.append(player.snapshot_state().is_empty() and not player.restore_state(before) and player.last_snapshot_error.contains("transactions"))
		paused = false
	player.world_action_executed.connect(func(_record: Dictionary) -> void:
		paused = true
		guarded.append(player.snapshot_state().is_empty() and not player.restore_state(before) and player.last_snapshot_error.contains("transactions"))
		paused = false
	)
	player.slash(Vector3.RIGHT)
	_expect(guarded == [true, true] and _near(target.hp, 80.0), "paused callbacks inside hit resolution and world publication cannot capture or restore a partial action")
	paused = true
	_expect(not player.snapshot_state().is_empty(), "deferred paused capture is available after the initiating action returns")
	player.queue_free()
	target.queue_free()
	paused = false
	await process_frame


func _same_continuation(left: Dictionary, right: Dictionary) -> bool:
	if left.is_empty() or right.is_empty():
		return false
	# Contact recovery on a recreated CharacterBody is engine-owned. Compare
	# the complete public snapshot numerically, with subpixel physics tolerance.
	return _close_values(left, right)


func _close_values(left: Variant, right: Variant) -> bool:
	if Codec.is_number(left) and Codec.is_number(right):
		return absf(float(left) - float(right)) < 0.0005
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: String in left:
			if not right.has(key) or not _close_values(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _close_values(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right


func _json(snapshot: Dictionary) -> Dictionary:
	var decoded: Variant = JSON.parse_string(JSON.stringify(snapshot))
	_expect(decoded is Dictionary and not snapshot.is_empty(), "snapshot survives real JSON stringify/parse")
	return decoded as Dictionary


func _connect_events(player: CinderPlayer, events: Array[String]) -> void:
	player.fired.connect(func(_kind: String) -> void: events.append("fired"))
	player.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: events.append("resolved"))
	player.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("world"))
	player.equipment_changed.connect(func(_id: String) -> void: events.append("equipment"))
	player.died.connect(func() -> void: events.append("died"))


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
	await process_frame


func _player(arena: Node3D) -> CinderPlayer:
	var player: CinderPlayer = PlayerScript.new()
	player.position = Vector3(0, 0.02, 0)
	arena.add_child(player)
	return player


func _world_box(parent: Node3D, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = position
	return body


func _near(left: Variant, right: Variant) -> bool:
	return absf(float(left) - float(right)) < 0.00001


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
