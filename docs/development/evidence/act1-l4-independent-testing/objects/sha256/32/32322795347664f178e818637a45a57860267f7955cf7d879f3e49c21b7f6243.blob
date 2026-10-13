extends SceneTree
## Pure data/reader fixture using actual native collision/floor descriptors.
## No enemy consumer, renderer, damage, reservation or encounter acceptance.

const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Program = preload("res://scripts/combat/replay_program.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Captured = preload("res://scripts/combat/replay_sequence.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const SOURCE_ID: String = "test-only/mirror-root"
const EPOCH: String = "test-only/mirror-attempt-1"
const GENERATION: int = 7
const SEQUENCE_ID: String = "test-only/mirror-cycle-7"

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena: Dictionary = await _arena()
	var guards: Dictionary = _world_guards(arena)
	_expect(guards.collision_fingerprint.colliders.size() == 2 and guards.floor_signature.size() == 1, "world guard comes from actual native floor and shore-stone bodies, not a fabricated official descriptor")
	var definition: Dictionary = _definition(arena.source.global_position)
	var sequence = Authored.new()
	_expect(sequence.configure(SEQUENCE_ID, definition, SOURCE_ID, EPOCH, GENERATION, "standard", guards), "one own C52 route/slash configures against real native descriptors: " + sequence.last_error)
	if sequence.snapshot_state().is_empty():
		await _dispose(arena)
		print("Authored enemy sequence smoke: %d checks, %d failures" % [_checks, _failures])
		quit(1)
		return
	_test_geometry_and_role(sequence, definition, guards)
	_test_transport(sequence, definition, guards)
	_test_malformed(sequence, definition, guards)
	_test_hostile_foreign_inputs(sequence, definition, guards)
	_test_native_binding(sequence, definition, arena)
	await _test_pause_and_captured_reader(sequence, arena)
	await _dispose(arena)
	print("Authored enemy sequence smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_geometry_and_role(sequence, definition: Dictionary, guards: Dictionary) -> void:
	var native: Dictionary = sequence.state()
	var slot: Dictionary = native.timeline.slots[0]
	var event: Dictionary = slot.events[0]
	var record: Dictionary = event.record
	_expect(native.provenance == "enemy_authored" and not native.has("capture_snapshot") and native.source_id == SOURCE_ID and native.generation == GENERATION, "own enemy provenance retains exact source/cycle and contains no Player capture")
	_expect(slot.route.size() == 2 and slot.route[0].position == definition.route[0].position and slot.route[1].position == definition.route[1].position and native.authored.tether_position == definition.route[1].position, "absolute own route and genuine native endpoint position retain original Y without translation")
	_expect(event.kind == "enemy_slash" and event.event_ordinal == 1 and not event.has("record_sequence") and event.event_id == SEQUENCE_ID + "/cycle-7/slash", "one stable authored slash is not a fake Player publication or third captured slot")
	_expect(record.world_origin == definition.slash.world_origin and record.direction == definition.slash.direction and record.geometry.reach == definition.slash.reach and record.geometry.cone_min_dot == definition.slash.cone_min_dot, "slash preserves independent source-owned direction and cone geometry")
	_expect(event.at_s == slot.dash_until_s and event.commitment_until_s == slot.end_s and native.timeline.tether_from_s == slot.end_s and slot.omitted_idle_s == 0.0, "no arbitrary idle padding or reassociated commitment endpoint enters timeline")
	_expect(native.timeline.source_ready_s == maxf(native.timeline.tether_until_s, native.timeline.playback_from_s + definition.raw_role.attack_interval_s) and native.timeline.source_ready_s > native.timeline.tether_until_s, "long source interval retains ordinary active-origin cooldown after endpoint recovery")
	_expect(record.visual_duration_s == definition.slash.visual_duration_s and record.source_attack_interval_s == definition.raw_role.attack_interval_s and not record.has("equipment_ids") and not record.has("cooldown_s"), "enemy ornament/interval are source-owned with no Player loadout or cosmetic ratio")
	var encoded_record: Dictionary = sequence.snapshot_state().timeline.slots[0].events[0].record
	_expect(Authored.action_record_error(encoded_record).is_empty() and Authored.decode_action_record(encoded_record).world_origin == record.world_origin, "typed action codec decodes its own native geometry")
	_expect(not Player.world_action_record_error(encoded_record, 100.0).is_empty() and not Captured.new().snapshot_error(sequence.snapshot_state(), EPOCH, GENERATION).is_empty(), "Player action and captured-only Sequence refuse own-enemy data")
	for profile_id: String in ["assisted", "standard", "challenge"]:
		var per_profile = Authored.new()
		var accepted: bool = per_profile.configure("test-only/profile-" + profile_id, definition, SOURCE_ID, EPOCH, GENERATION, profile_id, guards)
		var expected: Dictionary = Difficulty.new().resolve_role(definition.raw_role, profile_id, definition.timing_floors)
		_expect(accepted and Authored.exact_equal(per_profile.snapshot_state().resolved_role, expected), "fresh raw role resolves exactly once for " + profile_id)
		if accepted:
			var plan: Dictionary = per_profile.state()
			_expect(plan.timeline.slots[0].events[0].record.damage == expected.damage and plan.authored.locked_lead_s == expected.lock_s and plan.authored.final_recovery_s == expected.recovery_s, profile_id + " preserves resolved damage/full lock/recovery without changing route or gesture data")
	var max_cycle = Authored.new()
	_expect(max_cycle.configure("test-only/max-safe-cycle", definition, SOURCE_ID, EPOCH, Codec.MAX_SAFE_INTEGER, "standard", guards) and max_cycle.snapshot_state().generation == Codec.MAX_SAFE_INTEGER, "maximum exact safe cycle integer remains an integer without lossy record identity")
	var too_large = Authored.new()
	_expect(not too_large.configure("test-only/over-safe-cycle", definition, SOURCE_ID, EPOCH, Codec.MAX_SAFE_INTEGER + 1, "standard", guards), "cycle integer beyond exact transport range rejects")


func _test_transport(sequence, definition: Dictionary, guards: Dictionary) -> void:
	var original: Dictionary = sequence.snapshot_state()
	var wire: String = Exact.stringify(original)
	var parsed: Dictionary = Exact.parse(wire)
	var fresh = Authored.new()
	_expect(parsed.get("accepted", false) and fresh.restore_state(parsed.get("value", {}), EPOCH, GENERATION) and Authored.exact_equal(fresh.snapshot_state(), original), "exact tagged fresh restore preserves every scalar bit/type/route/action without native work")
	_expect(fresh.binding_error(original, SOURCE_ID, EPOCH, GENERATION, "standard", definition, guards).is_empty(), "actual expected source definition/profile/world context agrees at binding boundary")
	var copy: Dictionary = fresh.state()
	copy.definition.raw_role.raw_damage = 999.0
	copy.timeline.slots[0].route[0].position = Vector3(99, 0, 99)
	copy.timeline.slots[0].events[0].record.damage = 999.0
	var encoded_copy: Dictionary = fresh.snapshot_state()
	encoded_copy.world.floor_signature.clear()
	_expect(Authored.exact_equal(fresh.snapshot_state(), original), "native/JSON getters are defensive through nested definition, route, record and world")
	var alternate_definition: Dictionary = definition.duplicate(true)
	alternate_definition.slash.visual_duration_s = _one_bit(alternate_definition.slash.visual_duration_s)
	var alternate = Authored.new()
	_expect(alternate.configure(SEQUENCE_ID, alternate_definition, SOURCE_ID, EPOCH, GENERATION, "standard", guards), "a separately declared one-bit visual definition is syntactically valid new data")
	_expect(not fresh.restore_state(alternate.snapshot_state(), EPOCH, GENERATION) and Authored.exact_equal(fresh.snapshot_state(), original), "existing immutable owner refuses a valid-but-different one-bit definition atomically")
	_expect(not fresh.binding_error(alternate.snapshot_state(), SOURCE_ID, EPOCH, GENERATION, "standard", definition, guards).is_empty(), "internally valid alternate definition is not authority for the actual source")
	var alternate_profile = Authored.new()
	_expect(alternate_profile.configure(SEQUENCE_ID, definition, SOURCE_ID, EPOCH, GENERATION, "assisted", guards) and not fresh.binding_error(alternate_profile.snapshot_state(), SOURCE_ID, EPOCH, GENERATION, "standard", definition, guards).is_empty(), "internally valid alternate resolved profile cannot replace actual current profile")
	var reader = Program.new()
	_expect(reader.restore_state(original, EPOCH, GENERATION) and reader.is_authored_enemy() and Authored.exact_equal(reader.snapshot_state(), original), "program reader selects typed authored API without changing the captured module")
	var reader_copy: Dictionary = reader.state()
	reader_copy.timeline.slots.clear()
	_expect(reader.state().timeline.slots.size() == 1 and Program.TIME_EPSILON_S == Captured.TIME_EPSILON_S, "reader copy is defensive and common derived boundary epsilon remains compatible")
	var unknown: Dictionary = original.duplicate(true)
	unknown.api_revision = "unregistered-recording"
	_expect(not reader.restore_state(unknown, EPOCH, GENERATION) and not Program.new().snapshot_error(unknown, EPOCH, GENERATION).is_empty() and Authored.exact_equal(reader.snapshot_state(), original), "unknown program API cannot replace configured provenance")


func _test_malformed(sequence, definition: Dictionary, guards: Dictionary) -> void:
	var original: Dictionary = sequence.snapshot_state()
	for target: String in ["definition", "damage", "clock", "profile", "cycle", "cycle_type", "source", "epoch", "world", "third_slot", "capture", "gear", "publication", "blast"]:
		var bad: Dictionary = original.duplicate(true)
		match target:
			"definition": bad.definition.raw_role.raw_damage = _one_bit(bad.definition.raw_role.raw_damage)
			"damage": bad.timeline.slots[0].events[0].record.damage = _one_bit(bad.timeline.slots[0].events[0].record.damage)
			"clock": bad.timeline.slots[0].events[0].at_s = _one_bit(bad.timeline.slots[0].events[0].at_s)
			"profile": bad.profile_id = "assisted"
			"cycle": bad.generation += 1
			"cycle_type": bad.generation = float(bad.generation)
			"source": bad.source_id = "test-only/other-root"
			"epoch": bad.source_epoch = "test-only/other-attempt"
			"world": bad.world.collision_fingerprint.colliders[0].priority = _one_bit(bad.world.collision_fingerprint.colliders[0].priority)
			"third_slot": bad.timeline.slots.append(bad.timeline.slots[0].duplicate(true))
			"capture": bad["capture_snapshot"] = {}
			"gear": bad.timeline.slots[0].events[0].record["equipment_ids"] = {}
			"publication": bad.timeline.slots[0].events[0]["record_sequence"] = 1
			"blast": bad.timeline.slots[0].events[0].kind = "blast"
		var rejected: bool = not sequence.restore_state(bad, EPOCH, GENERATION)
		_expect(rejected and Authored.exact_equal(sequence.snapshot_state(), original), "one-bit/foreign " + target + " cannot mutate an immutable saved plan")
	var bad_definition: Dictionary = definition.duplicate(true)
	bad_definition.slash.world_origin += Vector3.RIGHT * 0.01
	_reject_definition("endpoint origin discontinuity rejects without snapping", bad_definition, guards)
	bad_definition = definition.duplicate(true)
	bad_definition.raw_role.move_speed = 1.0
	_reject_definition("physical moving owner is unsupported", bad_definition, guards)
	bad_definition = definition.duplicate(true)
	bad_definition.raw_role["difficulty_schema"] = 1
	_reject_definition("already-resolved input cannot compound difficulty", bad_definition, guards)
	bad_definition = definition.duplicate(true)
	bad_definition.route[1].at_s += 0.1
	_reject_definition("arbitrary active idle cannot be inserted", bad_definition, guards)
	bad_definition = definition.duplicate(true)
	bad_definition.slash.direction = Vector3.ZERO
	_reject_definition("zero direction rejects", bad_definition, guards)
	bad_definition = definition.duplicate(true)
	bad_definition.slash.reach = INF
	_reject_definition("nonfinite geometry rejects", bad_definition, guards)
	bad_definition = definition.duplicate(true)
	bad_definition.definition_revision = float(bad_definition.definition_revision)
	_reject_definition("exact integer identity is not silently converted", bad_definition, guards)
	var record: Dictionary = original.timeline.slots[0].events[0].record.duplicate(true)
	record["completed_at_s"] = 1.0
	_expect(not Authored.action_record_error(record).is_empty() and Authored.decode_action_record(record).is_empty(), "typed action rejects fabricated Player completion/publication fields")
	record = original.timeline.slots[0].events[0].record.duplicate(true)
	record.geometry.los.collision_mask = 2
	_expect(not Authored.action_record_error(record).is_empty(), "different native scenery-ray policy rejects")
	var within_transport: Dictionary = original.timeline.slots[0].events[0].record.duplicate(true)
	within_transport.damage = _one_bit(within_transport.damage)
	_expect(Authored.action_record_error(within_transport).is_empty(), "standalone finite action syntax does not pretend to authenticate role-derived damage")


func _test_hostile_foreign_inputs(sequence, definition: Dictionary, guards: Dictionary) -> void:
	var original: Dictionary = sequence.snapshot_state()
	var cyclic: Dictionary = definition.duplicate(true)
	cyclic.raw_role.max_hp = cyclic.raw_role
	_reject_definition("cyclic raw-role leaf rejects before deepcopy", cyclic, guards)
	cyclic.raw_role.max_hp = 40.0 # Break deliberate reference cycle.
	cyclic = definition.duplicate(true)
	cyclic.presentation.presentation_revision = cyclic.presentation
	_reject_definition("cyclic presentation leaf rejects before deepcopy", cyclic, guards)
	cyclic.presentation.presentation_revision = 1
	var bad: Dictionary = definition.duplicate(true)
	var foreign := Node3D.new()
	bad.raw_role.raw_damage = foreign
	_reject_definition("foreign live object in closed numeric branch rejects", bad, guards)
	foreign.free()
	_reject_definition("freed foreign object handle rejects without cast/access", bad, guards)
	bad.raw_role.raw_damage = 4.0
	bad = definition.duplicate(true)
	var oversized: Array = []
	oversized.resize(Authored.MAX_INPUT_ENTRIES + 1)
	bad.timing_floors.windup_s = oversized
	_reject_definition("oversized foreign branch is never copied", bad, guards)
	bad = definition.duplicate(true)
	bad.slash.world_origin = [2.0, 0.0, 0.0]
	_reject_definition("constructor accepts vectors only at explicit native locations", bad, guards)
	var hostile_world: Dictionary = guards.duplicate(true)
	hostile_world.floor_signature = [hostile_world]
	_expect(not Authored.new().configure(SEQUENCE_ID, definition, SOURCE_ID, EPOCH, GENERATION, "standard", hostile_world), "cyclic world JSON rejects at bounded traversal before deepcopy")
	hostile_world.floor_signature = [] # Break deliberate reference cycle.
	var expansion: Array = [0.0]
	for _index: int in range(17):
		expansion = [expansion, expansion]
	hostile_world = guards.duplicate(true)
	hostile_world.collision_fingerprint.colliders = [{"foreign": expansion}]
	_expect(not Authored.new().configure(SEQUENCE_ID, definition, SOURCE_ID, EPOCH, GENERATION, "standard", hostile_world), "aliased expanding tree rejects at global node/byte budget before deepcopy")
	hostile_world = guards.duplicate(true)
	hostile_world.floor_signature[0].shape_path = "x".repeat(Authored.MAX_INPUT_BYTES + 1)
	_expect(not Authored.new().configure(SEQUENCE_ID, definition, SOURCE_ID, EPOCH, GENERATION, "standard", hostile_world), "oversized transport string rejects without unbounded UTF8/deepcopy work")
	var malformed: Dictionary = original.duplicate(true)
	malformed["foreign"] = malformed
	_expect(not sequence.restore_state(malformed, EPOCH, GENERATION) and Authored.exact_equal(sequence.snapshot_state(), original), "cyclic malformed saved transport rejects atomically")
	malformed.erase("foreign")


func _test_native_binding(sequence, definition: Dictionary, arena: Dictionary) -> void:
	var original: Dictionary = sequence.snapshot_state()
	var before: Dictionary = _world_guards(arena)
	var actual_priority: float = arena.floor.collision_priority
	arena.floor.collision_priority = _one_bit32(actual_priority)
	var changed: Dictionary = _world_guards(arena)
	_expect(not Authored.exact_equal(changed, before) and not sequence.binding_error(original, SOURCE_ID, EPOCH, GENERATION, "standard", definition, changed).is_empty(), "one actual native float32 collider bit invalidates source-world binding")
	arena.floor.collision_priority = actual_priority
	_expect(sequence.binding_error(original, SOURCE_ID, EPOCH, GENERATION, "standard", definition, _world_guards(arena)).is_empty(), "actual exact original native world restores binding without rewriting sequence")
	var floors: Array = [{"collision": arena.floor.get_child(0), "safe_rect": Rect2(-10, -10, 20, 20)}]
	var domain: Dictionary = Footprint.floor_signature(arena.world, floors)
	var narrower: Dictionary = before.duplicate(true)
	narrower.floor_signature = domain.signature
	_expect(not sequence.binding_error(original, SOURCE_ID, EPOCH, GENERATION, "standard", definition, narrower).is_empty(), "actual authored safe-domain change rejects even with unchanged collision bodies")
	_expect(not sequence.binding_error(original, SOURCE_ID, EPOCH, GENERATION + 1, "standard", definition, before).is_empty() and not sequence.binding_error(original, "test-only/other-root", EPOCH, GENERATION, "standard", definition, before).is_empty(), "actual expected current source/cycle cannot be substituted by copied identity")
	_expect(Authored.exact_equal(sequence.snapshot_state(), original), "all native binding queries preserve immutable source recipe and transport")


func _test_pause_and_captured_reader(sequence, arena: Dictionary) -> void:
	var before: Dictionary = sequence.snapshot_state()
	var clock: float = arena.scheduler.get_clock()
	var pose: Vector3 = arena.source.global_position
	arena.scheduler.last_error = "request sentinel"
	arena.scheduler.last_snapshot_error = "snapshot sentinel"
	await create_timer(0.05, true).timeout
	_expect(arena.scheduler.get_clock() == clock and arena.source.global_position == pose and Authored.exact_equal(sequence.snapshot_state(), before), "paused native clock/source and immutable constructor data do not advance")
	_world_guards(arena)
	_expect(arena.scheduler.last_error == "request sentinel" and arena.scheduler.last_snapshot_error == "snapshot sentinel" and arena.scheduler.reservations().is_empty(), "real native descriptor queries do not reserve/cancel or change diagnostics")
	var player = Player.new()
	player.name = "ActualSharedPlayer"
	arena.world.add_child(player)
	player.position = Vector3(0, 0.1, 0)
	paused = false
	await _ticks(8)
	paused = true
	await process_frame
	var capture = Capture.new()
	_expect(capture.arm("program/captured", 1, 0, player.get_world_action_clock()), "captured reader compatibility fixture arms actual Player records")
	player.world_action_executed.connect(func(record: Dictionary) -> void:
		capture.ingest(record, "program/captured")
		if record.kind == "dash":
			player.slash(Vector3.RIGHT)
	)
	paused = false
	_expect(player.request_dash(Vector3.RIGHT), "compatibility capture starts one actual public dash")
	for _index: int in range(60):
		await _ticks(1)
		capture.advance(player.get_world_action_clock())
	paused = true
	await process_frame
	capture.advance(player.get_world_action_clock())
	var captured = Captured.new()
	var valid: bool = captured.configure("program/actual-captured", capture.snapshot_state(), {"recognition_s": 0.12, "warning_s": 0.5, "locked_lead_s": 0.8, "inter_echo_gap_s": 0.0, "final_recovery_s": 2.0, "tether_position": player.global_position}, "program/captured", 1)
	_expect(valid, "captured-only constructor still derives actual completed dash/primary: " + captured.last_error)
	if valid:
		var reader = Program.new()
		_expect(reader.restore_state(captured.snapshot_state(), "program/captured", 1) and not reader.is_authored_enemy() and reader.state() == captured.state(), "same program reader preserves real captured branch without fake records")
		var enemy_reader = Program.new()
		enemy_reader.restore_state(before, EPOCH, GENERATION)
		_expect(not enemy_reader.restore_state(captured.snapshot_state(), "program/captured", 1) and Authored.exact_equal(enemy_reader.snapshot_state(), before), "configured authored reader cannot switch to valid captured provenance")
		_expect(not reader.restore_state(before, EPOCH, GENERATION) and Authored.exact_equal(reader.snapshot_state(), captured.snapshot_state()), "configured captured reader cannot switch to valid authored provenance")


func _definition(endpoint: Vector3) -> Dictionary:
	var travel_s: float = 0.4
	var commitment_s: float = 0.2
	return {"definition_id": "test-only/own-dash-slash", "definition_revision": 1, "role_id": "C52", "raw_role": {"raw_damage": 4.0, "windup_s": 1.8, "lock_s": 1.1, "active_s": travel_s + commitment_s, "recovery_s": 2.0, "attack_interval_s": 8.0, "max_hp": 40.0, "move_speed": 0.0}, "timing_floors": {"windup_s": 1.2, "lock_s": 0.9, "recovery_s": 1.6}, "recognition_s": 0.12, "route": [{"position": endpoint + Vector3.LEFT * 4.0, "at_s": 0.0}, {"position": endpoint, "at_s": travel_s}], "travel_clearance": {"radius_m": 0.35, "height_m": 1.5}, "slash": {"world_origin": endpoint, "direction": Vector3.FORWARD, "reach": 1.1, "cone_min_dot": 0.3, "origin_disk_radius": 0.1, "max_vertical_distance": 1.0, "los_height": 0.9, "commitment_duration_s": commitment_s, "visual_duration_s": 0.28}, "presentation": {"presentation_id": "test-only/own-enemy-art", "presentation_revision": 1}}


func _arena() -> Dictionary:
	var world := Node3D.new()
	world.name = "AuthoredSequenceNativeWorld"
	root.add_child(world)
	var floor_body: StaticBody3D = _box(world, "DryFloor", Vector3(0, -0.5, 0), Vector3(24, 1, 24))
	_box(world, "ShoreStone", Vector3(0, 1, 4), Vector3(1, 2, 1))
	var source := Node3D.new()
	source.name = "TestOnlyStationarySource"
	world.add_child(source)
	source.position = Vector3(2, 0, 0)
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	scheduler.begin_encounter("standard", "test-only/constructor", 1)
	await _ticks(3)
	paused = true
	await process_frame
	return {"world": world, "floor": floor_body, "source": source, "scheduler": scheduler, "floors": [{"collision": floor_body.get_child(0), "safe_rect": Rect2(-12, -12, 24, 24)}]}


func _world_guards(arena: Dictionary) -> Dictionary:
	var floor_result: Dictionary = Footprint.floor_signature(arena.world, arena.floors)
	return {"world_revision": 1, "collision_fingerprint": arena.scheduler.pure_collision_fingerprint(arena.world), "floor_signature": floor_result.get("signature", [])}


func _box(parent: Node3D, stable_name: String, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = stable_name
	body.collision_layer = 1
	body.collision_mask = 1
	parent.add_child(body)
	body.position = position
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body


func _reject_definition(label: String, definition: Dictionary, guards: Dictionary) -> void:
	var fresh = Authored.new()
	_expect(not fresh.configure(SEQUENCE_ID, definition, SOURCE_ID, EPOCH, GENERATION, "standard", guards) and fresh.snapshot_state().is_empty(), label + " and leaves fresh state empty")


func _one_bit(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes[0] = bytes[0] ^ 1
	return bytes.decode_double(0)


func _one_bit32(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, value)
	bytes[0] = bytes[0] ^ 1
	return bytes.decode_float(0)


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _dispose(arena: Dictionary) -> void:
	paused = false
	arena.world.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
