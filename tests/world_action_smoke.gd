extends SceneTree

const PlayerScript: GDScript = preload("res://scripts/player.gd")

class DamageTarget:
	extends Node3D
	var hp: float = 100.0
	var accepts: bool = true
	func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
		if not accepts:
			return {"accepted": false, "hp_damage": 0.0}
		var loss: float = minf(hp, amount)
		hp -= loss
		return {"accepted": true, "hp_damage": loss}

var _failures: int = 0
var _checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	_world_box(arena, Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	await _dash_checks(arena)
	await _attack_checks(arena)
	await _pause_cancel_checks(arena)
	arena.queue_free()
	await process_frame
	print("World action smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _dash_checks(arena: Node3D) -> void:
	var wall: StaticBody3D = _world_box(arena, Vector3(1.5, 1, 0), Vector3(0.3, 2, 4))
	var player: CinderPlayer = _player(arena)
	await create_timer(0.08).timeout
	var start: Vector3 = player.global_position
	_expect(not player.request_dash(Vector3.ZERO) and player.get_world_action_records().is_empty(), "rejected zero-direction request publishes no movement")
	_expect(player.request_dash(Vector3.RIGHT) and player.get_world_action_records().is_empty(), "accepted dash publishes only when physics finishes")
	await create_timer(0.25).timeout
	var records: Array[Dictionary] = player.get_world_action_records()
	_expect(records.size() == 1, "collision-shortened dash publishes exactly once")
	if records.size() == 1:
		var dash: Dictionary = records[0]
		_expect(dash.kind == "dash" and dash.origin == "player_direct" and dash.sequence == 1 and dash.schema_version == 1, "completed dash has versioned direct-player identity and ordered sequence")
		_expect((dash.world_origin as Vector3).distance_to(start) < 0.001 and (dash.landing as Vector3).distance_to(player.global_position) < 0.001, "dash samples actual world start and collision-shortened landing")
		_expect(float(dash.distance) > 0.5 and float(dash.distance) < 1.3 and dash.blocked and dash.collision_shortened, "wall contact records actual short travel without extending dash distance")
		_expect(_near(dash.resolved_stats.dash_distance, 2.7) and _near(dash.resolved_stats.dash_duration, 0.18) and dash.equipment_ids.weapon == "WEAPON-01", "movement carries its original resolved stats and equipment IDs")
		_expect(_valid_path(dash) and (dash.path as Array).size() > 3, "resolved route contains ordered actual physics samples with matching endpoints")
		var remains_before_wall: bool = true
		for sample: Dictionary in dash.path:
			remains_before_wall = remains_before_wall and (sample.position as Vector3).x < 1.1
		_expect(remains_before_wall, "recorded path does not pass through blocking scenery")
	await create_timer(0.15).timeout
	_expect(player.request_dash(Vector3.RIGHT), "cooldown admits another dash at the wall")
	await create_timer(0.25).timeout
	records = player.get_world_action_records()
	_expect(records.size() == 2 and float(records[-1].distance) < 0.01 and records[-1].blocked, "fully blocked but completed dash still publishes its truthful landing")
	player.queue_free()
	wall.queue_free()
	await process_frame

	player = _player(arena)
	await create_timer(0.08).timeout
	var published: Array[Dictionary] = []
	player.world_action_executed.connect(func(record: Dictionary) -> void:
		published.append(record.duplicate(true))
		record["direction"] = Vector3.ZERO
		(record.equipment_ids as Dictionary)["weapon"] = "observer_mutation"
	)
	_expect(player.request_dash(Vector3(0.37, 0, -0.91)), "continuous first dash is accepted")
	_expect(not player.request_dash(Vector3.BACK) and published.is_empty(), "buffered request is not an executed/completed movement record")
	await create_timer(0.62).timeout
	records = player.get_world_action_records()
	_expect(records.size() == 2 and published.size() == 2, "two chained dashes publish once per actual completion")
	if records.size() == 2:
		_expect((records[0].direction as Vector3).dot(Vector3(0.37, 0, -0.91).normalized()) > 0.999999 and (records[1].direction as Vector3).is_equal_approx(Vector3.BACK), "completed records preserve exact continuous and buffered directions")
		_expect(records[0].sequence == 1 and records[1].sequence == 2 and (records[1].world_origin as Vector3).distance_to(records[0].landing) < 0.01, "chain records are ordered and second route begins at actual first landing")
		_expect(float(records[1].started_at_s) >= float(records[0].completed_at_s) and _valid_path(records[0]) and _valid_path(records[1]), "chained paths retain distinct simulation intervals and samples")
		_expect(records[0].equipment_ids.weapon == "WEAPON-01" and (records[0].direction as Vector3).length() > 0.99, "signal mutation cannot alter internally retained records")
		(records[0].path as Array)[0]["position"] = Vector3(999, 0, 999)
		(records[0].resolved_stats as Dictionary)["dash_distance"] = 999
		var reread: Array[Dictionary] = player.get_world_action_records()
		_expect((reread[0].path[0].position as Vector3).length() < 1 and _near(reread[0].resolved_stats.dash_distance, 2.7), "accessor protects nested paths and stat snapshots from caller mutation")
		_expect(player.get_world_action_records(1).size() == 1 and player.get_world_action_records(2).is_empty(), "sequence cursor returns only subsequently published records")
	player.queue_free()
	await process_frame

func _attack_checks(arena: Node3D) -> void:
	var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, -1), Vector3(0.23, 0, -0.97), Vector3(-0.81, 3, 0.34)]
	for index: int in range(directions.size()):
		var player: CinderPlayer = _player(arena)
		player.set_physics_process(false)
		player.position = Vector3(0.4, 0.02, -0.7)
		var legacy_fired: Array[String] = []
		player.fired.connect(func(kind: String) -> void: legacy_fired.append(kind))
		player.slash(directions[index])
		player.blast(directions[index])
		var records: Array[Dictionary] = player.get_world_action_records()
		_expect(records.size() == 2 and legacy_fired == ["slash", "blast"], "direction%d preserves accepted primary/blast and existing fired events" % index)
		if records.size() == 2:
			var expected: Vector3 = Vector3(directions[index].x, 0, directions[index].z).normalized()
			_expect((records[0].direction as Vector3).dot(expected) > 0.999999 and (records[1].direction as Vector3).dot(expected) > 0.999999, "direction%d records exact aim without artwork quantization" % index)
			_expect(records[0].kind == "primary" and records[1].kind == "blast" and (records[0].world_origin as Vector3).is_equal_approx(player.global_position), "direction%d records actual floor source and action order" % index)
			_expect(_near(records[0].geometry.reach, 2.0) and _near(records[1].geometry.reach, 3.1) and _near(records[0].geometry.cone_min_dot, 0.05) and _near(records[1].geometry.cone_min_dot, 0.5), "direction%d resolves independent primary/blast cones" % index)
			_expect(records[0].geometry.los.collision_mask == 1 and _near(records[0].geometry.los.height, 0.7) and _near(records[0].geometry.origin_disk_radius, 0.1) and _near(records[0].geometry.max_vertical_distance, 1.4), "direction%d declares the same scenery/height/source-disk policy as hits" % index)
			_expect(records[0].damage_timing == "instant_at_execution" and records[0].started_at_s == records[0].completed_at_s and _near(records[0].commitment_duration_s, 0.13) and _near(records[1].commitment_duration_s, 0.10), "direction%d separates immediate damage from logical commitment clocks" % index)
			_expect(not records[0].has("aim_anchor") and records[0].origin == "player_direct" and records[0].equipment_ids.size() == 4, "direction%d excludes screen input and retains four-slot direct-player provenance" % index)
		_expect(player.last_action == {"kind": "blast", "hits": 0, "damage": 42.0, "reach": 3.1}, "direction%d preserves the legacy hit summary" % index)
		player.queue_free()
		await process_frame

	var player: CinderPlayer = _player(arena)
	player.set_physics_process(false)
	var target := DamageTarget.new()
	arena.add_child(target)
	target.position = Vector3(1.5, 0.02, 0)
	target.add_to_group("enemies")
	_expect(player.slash(Vector3.RIGHT) == 1 and _near(target.hp, 80), "accepted primary still deals damage immediately")
	_expect(player.slash(Vector3.LEFT) == 0 and player.get_world_action_records().size() == 1, "cooldown-rejected primary emits no world action")
	_expect(player.blast(Vector3.RIGHT) == 1 and _near(target.hp, 38) and player.shells == 1, "accepted blast still deals immediate damage and spends one shell")
	_expect(player.blast(Vector3.LEFT) == 0 and player.get_world_action_records().size() == 2, "cooldown-rejected blast emits no world action")
	player.set("_blast_cd", 0.0)
	player.shells = 0
	_expect(player.blast(Vector3.RIGHT) == 0 and player.get_world_action_records().size() == 2, "empty follow-up ammo emits no attack or replacement primary")
	player.set("_slash_cd", 0.0)
	target.accepts = false
	_expect(player.slash(Vector3.RIGHT) == 0 and player.get_world_action_records().size() == 3 and player.get_world_action_records()[-1].hits == 0, "executed primary is recorded even when its target rejects damage")
	player.set("_slash_cd", 0.0)
	player.slash()
	_expect((player.get_world_action_records()[-1].direction as Vector3).is_equal_approx(Vector3.RIGHT), "zero attack vector records retained facing")
	for index: int in range(70):
		player.set("_slash_cd", 0.0)
		player.slash(Vector3.LEFT)
	var history: Array[Dictionary] = player.get_world_action_records()
	_expect(history.size() == CinderPlayer.MAX_WORLD_ACTION_RECORDS and int(history[0].sequence) > 1 and int(history[-1].sequence) - int(history[0].sequence) == history.size() - 1, "history is finite with monotonic sequences after older records roll off")
	player.queue_free()
	target.queue_free()
	await process_frame
	player = _player(arena)
	player.set_physics_process(false)
	_expect(player.equip_item("WEAPON-03"), "idle weapon replacement is available before accepted action")
	player.slash(Vector3.RIGHT)
	var heavy: Dictionary = player.get_world_action_records()[0]
	_expect(heavy.equipment_ids.weapon == "WEAPON-03" and _near(heavy.damage, 24) and _near(heavy.geometry.reach, 1.8) and _near(heavy.cooldown_s, 0.375), "records capture the actually selected weapon's resolved geometry and timing")
	player.equipment.equip("WEAPON-01")
	_expect(player.get_world_action_records()[0].equipment_ids.weapon == "WEAPON-03" and _near(player.get_world_action_records()[0].damage, 24), "later equipment changes cannot rewrite an executed action")
	player.queue_free()
	await process_frame
	player = _player(arena)
	player.set_physics_process(false)
	player.action_resolved.connect(func(kind: String, _hits: int, _damage: float) -> void:
		if kind == "slash":
			player.blast(Vector3.LEFT)
	)
	player.slash(Vector3.RIGHT)
	var nested: Array[Dictionary] = player.get_world_action_records()
	_expect(nested.size() == 2 and nested[0].kind == "primary" and nested[1].kind == "blast" and nested[0].sequence == 1 and nested[1].sequence == 2, "legacy action_resolved callback cannot publish a nested blast before its initiating primary")
	_expect((nested[0].direction as Vector3).is_equal_approx(Vector3.RIGHT) and (nested[1].direction as Vector3).is_equal_approx(Vector3.LEFT), "nested actions retain their actual independent world directions")
	player.queue_free()
	await process_frame

func _pause_cancel_checks(arena: Node3D) -> void:
	var player: CinderPlayer = _player(arena)
	await create_timer(0.08).timeout
	player.request_dash(Vector3.FORWARD)
	await create_timer(0.05).timeout
	paused = true
	var clock: float = player.get_world_action_clock()
	var position: Vector3 = player.global_position
	await create_timer(0.15).timeout
	_expect(_near(player.get_world_action_clock(), clock) and player.global_position.is_equal_approx(position) and player.get_world_action_records().is_empty(), "pause freezes simulation clock, path movement and incomplete publication")
	paused = false
	await create_timer(0.22).timeout
	var records: Array[Dictionary] = player.get_world_action_records()
	_expect(records.size() == 1 and float(records[0].completed_at_s) - float(records[0].started_at_s) < 0.21 and _valid_path(records[0]), "resume finishes one path without counting paused wall time")
	player.queue_free()
	await process_frame

	player = _player(arena)
	await create_timer(0.06).timeout
	player.request_dash(Vector3.RIGHT)
	await create_timer(0.05).timeout
	player.cancel_world_action_capture()
	await create_timer(0.22).timeout
	_expect(player.get_world_action_records().is_empty() and player.last_dash_distance > 2.6, "cancelled recording publishes no invented completion and does not modify motion")
	player.queue_free()
	await process_frame

	player = _player(arena)
	await create_timer(0.06).timeout
	player.request_dash(Vector3.RIGHT)
	await create_timer(0.04).timeout
	player.set("_invulnerable", 0.0)
	player.take_damage(200, Vector3.ZERO)
	clock = player.get_world_action_clock()
	await create_timer(0.22).timeout
	_expect(player.dead and player.get_world_action_records().is_empty() and _near(player.get_world_action_clock(), clock), "death discards unfinished movement without completion or later clock advance")
	_expect(not player.request_dash(Vector3.RIGHT) and player.slash(Vector3.RIGHT) == 0 and player.blast(Vector3.RIGHT) == 0 and player.get_world_action_records().is_empty(), "dead-player requests publish no actions")
	player.queue_free()
	await process_frame
	player = _player(arena)
	_expect(player.get_world_action_records().is_empty() and _near(player.get_world_action_clock(), 0), "fresh reset instance starts without stale history or fabricated movement")
	player.queue_free()
	await process_frame

func _valid_path(record: Dictionary) -> bool:
	var samples: Array = record.path
	if samples.size() < 2 or not (samples[0].position as Vector3).is_equal_approx(record.world_origin) or not (samples[-1].position as Vector3).is_equal_approx(record.landing):
		return false
	var previous: float = float(record.started_at_s)
	for sample: Dictionary in samples:
		if float(sample.time_s) < previous:
			return false
		previous = float(sample.time_s)
	return _near(samples[0].time_s, record.started_at_s) and _near(samples[-1].time_s, record.completed_at_s)

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

func _near(actual: Variant, expected: Variant) -> bool:
	return absf(float(actual) - float(expected)) < 0.00001

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
