extends "res://tests/authored_echo_playback_smoke.gd"
## OFFLINE / UNPARSED future control. Runs ONLY after root adopts/reviews the
## four candidate files and explicitly authorizes canonical catalogue writes.
## The accompanying Python wrapper provides process-level try/finally restore.
const ReuseProgram = preload("res://scripts/combat/replay_program.gd")
const ReusePlan = preload("res://scripts/combat/authored_enemy_sequence.gd")
const PROFILE_PATH: String = "res://data/design/difficulty_profiles.json"

class OriginalSignatureProbe extends "res://scripts/combat/authored_enemy_sequence.gd":
	var input_calls: int = 0
	var resolve_calls: int = 0

	func _input_error(sequence_id: Variant, definition: Dictionary, source_id: Variant, source_epoch: String, generation: int, profile_id: Variant, world: Dictionary) -> String:
		input_calls += 1
		return super._input_error(sequence_id, definition, source_id, source_epoch, generation, profile_id, world)

	func _resolve(definition: Dictionary, profile_id: String) -> Dictionary:
		resolve_calls += 1
		return super._resolve(definition, profile_id)

class GetterActor extends "res://tests/fixtures/authored_echo_actor.gd":
	var mutation: String = ""
	var submitted: Dictionary = {}
	var staged: Dictionary = {}
	var original_catalogue := PackedByteArray()
	var floor_shape: BoxShape3D
	var getter_calls: int = 0
	var write_error: String = ""

	func get_authored_echo_binding() -> Dictionary:
		var value: Dictionary = super.get_authored_echo_binding()
		if mutation.is_empty(): return value
		getter_calls += 1
		var mode: String = mutation
		mutation = "" # Exactly the actual source getter boundary, once.
		match mode:
			"catalogue_damage", "catalogue_windup", "catalogue_other", "floor_catalogue":
				var raw: Dictionary = JSON.parse_string(original_catalogue.get_string_from_utf8())
				for profile: Dictionary in raw.profiles:
					if profile.id == "standard" and mode in ["catalogue_damage", "floor_catalogue"]: profile.raw_damage_multiplier = 1.125
					if profile.id == "standard" and mode == "catalogue_windup": profile.windup_multiplier = 1.125
					if profile.id == "assisted" and mode == "catalogue_other": profile.raw_damage_multiplier = 0.6
				_write(JSON.stringify(raw).to_utf8_buffer())
				if mode == "floor_catalogue": _change_floor()
			"catalogue_lexical":
				var raw: PackedByteArray = original_catalogue.duplicate()
				raw.append_array("\n \t".to_utf8_buffer())
				_write(raw)
			"catalogue_unsupported":
				_write('{"schema_version":99,"profiles":[]}'.to_utf8_buffer())
			"catalogue_bom":
				var raw := PackedByteArray([239, 187, 191])
				raw.append_array(original_catalogue)
				_write(raw)
			"program_damage":
				var record: Dictionary = submitted.timeline.slots[0].events[0].record
				record.damage = _next_double(float(record.damage))
			"program_generation": submitted.generation += 1
			"program_object": submitted.definition.presentation["unexpected_object"] = self
			"program_cycle": submitted["unexpected_cycle"] = submitted
			"native_definition": value.definition.slash.visual_duration_s = _next_double(float(value.definition.slash.visual_duration_s))
			"staged_definition": staged.definition.slash.visual_duration_s = _next_double(float(staged.definition.slash.visual_duration_s))
			"floor": _change_floor()
		return value

	func _write(bytes: PackedByteArray) -> void:
		var file: FileAccess = FileAccess.open("res://data/design/difficulty_profiles.json", FileAccess.WRITE)
		if file == null:
			write_error = "Canonical catalogue write failed"
			return
		file.store_buffer(bytes)
		file.flush()
		file.close()
		if FileAccess.get_file_as_bytes("res://data/design/difficulty_profiles.json") != bytes:
			write_error = "Canonical catalogue write did not retain exact bytes"

	func _change_floor() -> void:
		var bytes := PackedByteArray()
		bytes.resize(4)
		bytes.encode_float(0, floor_shape.size.x)
		bytes.encode_u32(0, bytes.decode_u32(0) + 1)
		var size: Vector3 = floor_shape.size
		size.x = bytes.decode_float(0)
		floor_shape.size = size

	static func _next_double(value: float) -> float:
		var bytes := PackedByteArray()
		bytes.resize(8)
		bytes.encode_double(0, value)
		bytes.encode_u64(0, bytes.decode_u64(0) + 1)
		return bytes.decode_double(0)

var _original_catalogue := PackedByteArray()
var _callbacks: Array[String] = []


func _run() -> void:
	if "--allow-canonical-catalogue-mutation" not in OS.get_cmdline_user_args():
		print("REFUSED: offline future control requires reviewed adoption and its finally-restoring wrapper")
		quit(2)
		return
	_original_catalogue = FileAccess.get_file_as_bytes(PROFILE_PATH)
	if _original_catalogue.is_empty():
		print("REFUSED: exact original catalogue backup unavailable")
		quit(2)
		return
	root.size = Vector2i(540, 1170)
	var arena: Dictionary = await _arena()
	var installed: Dictionary = _install(arena)
	paused = true
	await process_frame
	if installed.is_empty():
		_restore_catalogue()
		await _dispose(arena)
		print("Authored source reuse controls setup failed: %d checks, %d failures" % [_checks, _failures])
		quit(1)
		return
	_expect(arena.scheduler.get_script() == Scheduler, "actual exact shared Scheduler Script owns the real admitted native source")
	_test_original_signatures(arena.actor.source_program())
	_watch(arena)
	for mode: String in ["normal", "staged_normal", "catalogue_damage", "catalogue_windup", "catalogue_lexical", "catalogue_other", "catalogue_unsupported", "catalogue_bom", "program_damage", "program_generation", "program_object", "program_cycle", "native_definition", "staged_definition", "floor", "floor_catalogue"]:
		_compare(arena, mode)
	var reader = ReuseProgram.new()
	var program: Dictionary = arena.actor.source_program()
	var binding: Dictionary = arena.actor.get_authored_echo_binding()
	var actual_world: Dictionary = {"world_revision": 1, "collision_fingerprint": arena.context.world_collision_fingerprint, "floor_signature": arena.context.world_floor_signature}
	_expect(reader._restore_authored_for_source_guard(program, EPOCH, GENERATION), "a fresh private reader performs full validation before its immediate binding check")
	var first: String = reader._authored_binding_error_for_source_guard(program, SOURCE_ID, EPOCH, GENERATION, "standard", binding.definition, actual_world)
	var second: String = reader._authored_binding_error_for_source_guard(program, SOURCE_ID, EPOCH, GENERATION, "standard", binding.definition, actual_world)
	_expect(first.is_empty() and second == first and ReusePlan.exact_equal(reader.snapshot_state(), program), "consumed private input cannot become a lifetime token; second call safely full-validates without changing wire")
	_expect(_restore_catalogue(), "finally-style fixture cleanup retains exact original catalogue bytes")
	await _dispose(arena)
	print("Authored source reuse controls: %d checks, %d failures; no route/performance/portrait claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_original_signatures(program: Dictionary) -> void:
	var subclass = OriginalSignatureProbe.new()
	_expect(subclass.get_script() != ReusePlan, "legitimate old-signature subclass differs from the native shared Script")
	_expect(subclass.snapshot_error(program, EPOCH, GENERATION).is_empty() and subclass.input_calls == 1 and subclass.resolve_calls == 2, "original seven/two-argument virtual overrides parse and dispatch in the same order/count")
	subclass.input_calls = 0
	subclass.resolve_calls = 0
	_expect(subclass.restore_state(program, EPOCH, GENERATION) and subclass.input_calls == 1 and subclass.resolve_calls == 2 and subclass.get("_source_guard_inputs") == null, "public subclass restore keeps its original virtual dispatch and never collects a receipt")
	var fresh_subclass = OriginalSignatureProbe.new()
	_expect(not fresh_subclass._restore_for_source_guard(program, EPOCH, GENERATION) and fresh_subclass.input_calls == 0 and fresh_subclass.resolve_calls == 0 and fresh_subclass.snapshot_state().is_empty(), "exact-native internal collection refuses subclasses before any virtual dispatch or wire commit")
	var native = ReusePlan.new()
	_expect(native._restore_for_source_guard(program, EPOCH, GENERATION) and native.get("_source_guard_inputs") == null and ReusePlan.exact_equal(native.snapshot_state(), program), "successful fresh native preparation detaches the sink before returning to any source hook")
	var malformed: Dictionary = program.duplicate(true)
	malformed.source_epoch = "different-epoch"
	var rejected = ReusePlan.new()
	_expect(not rejected._restore_for_source_guard(malformed, EPOCH, GENERATION) and rejected.get("_source_guard_inputs") == null and rejected.get("_validation_input").is_empty() and rejected.snapshot_state().is_empty(), "failed native preparation also detaches and clears every private dependency before returning")
	var public_native = ReusePlan.new()
	_expect(public_native.restore_state(program, EPOCH, GENERATION) and public_native.get("_source_guard_inputs") == null and public_native.get("_validation_input").is_empty(), "ordinary native public restore retains no source-guard receipt")


func _arena(extreme: bool = false, settle: bool = true) -> Dictionary:
	var arena: Dictionary = await super._arena(extreme, settle)
	# Replace only the unleased TEST ONLY fixture source. The new actual owner
	# is another real Playback subclass; Scheduler/Hero/world remain original.
	arena.actor.free()
	var source = GetterActor.new()
	source.name = "ActualFixedKnotC52"
	arena.world.add_child(source)
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": arena.context.world_collision_fingerprint, "floor_signature": arena.context.world_floor_signature}
	_expect(source.initialize_source(SOURCE_ID, EPOCH, GENERATION, _definition(), "standard", prepared) and source.attach_source_scheduler(arena.scheduler), "actual getter-control subclass retains native role/HP/renderer/knot resources")
	_expect(source.configure_authored("test-only/physical-echo", source.source_program(), EPOCH, GENERATION), "real controlled source configures normally before any getter mutation is armed")
	source.original_catalogue = _original_catalogue.duplicate()
	source.floor_shape = arena.floor.shape
	arena.actor = source
	return arena


func _compare(arena: Dictionary, mode: String) -> void:
	var shape: BoxShape3D = arena.floor.shape
	var original_size: Vector3 = shape.size
	var initial: Dictionary = _native_unit(arena)
	_expect(not initial.is_empty(), mode + " starts with actual paused Player/Scheduler/Playback snapshots and native source fields")
	if initial.is_empty(): return
	var before: String = Exact.stringify(initial)
	_expect(not before.is_empty(), mode + " actual pre-boundary receipt encodes completely")
	if before.is_empty(): return
	_callbacks.clear()
	var results: Array[String] = []
	for legacy: bool in [false, true]:
		var sequence: Dictionary = arena.actor.source_program()
		var staged: Dictionary = arena.actor.get_authored_echo_binding().duplicate(true) if mode in ["staged_normal", "staged_definition"] else {}
		arena.actor.submitted = sequence
		arena.actor.staged = staged
		arena.actor.getter_calls = 0
		arena.actor.write_error = ""
		arena.actor.mutation = "" if mode in ["normal", "staged_normal"] else mode
		var error: String = _legacy_source_error(arena.scheduler, arena.actor, sequence, arena.context, arena.floors, "standard", 1, staged) if legacy else arena.scheduler.authored_replay_source_error(arena.actor, sequence, arena.context, arena.floors, "standard", 1, staged)
		results.append(error)
		arena.actor.mutation = ""
		arena.actor.submitted = {}
		arena.actor.staged = {}
		# Break deliberately forged caller cycles/foreign references explicitly.
		sequence.clear()
		staged.clear()
		shape.size = original_size
		_expect(_restore_catalogue(), mode + " restores every original catalogue byte before any await/snapshot")
		_expect(arena.actor.write_error.is_empty() and (mode in ["normal", "staged_normal"] or arena.actor.getter_calls == 1), mode + " mutation occurs once inside the actual source getter")
		var after: String = Exact.stringify(_native_unit(arena))
		_expect(not after.is_empty() and _callbacks.is_empty() and after == before, mode + " pure validation preserves HP, all clocks/history, native pose/renderer/cue/resource identities and callbacks")
	_expect(results[0] == results[1], mode + " optimized decision/error equals original full-binding path: " + results[0] + " / " + results[1])
	if mode in ["normal", "staged_normal", "catalogue_lexical", "catalogue_other"]:
		_expect(results[0].is_empty(), mode + " retains the genuine original pass rather than denying changed bytes outright")
	elif mode != "catalogue_bom":
		_expect(not results[0].is_empty(), mode + " genuine forged/current-world or catalogue mismatch rejects")
	if mode == "floor_catalogue":
		_expect(results[0] == "Actual authored floor/collision guards differ", "earlier real native-world refusal wins over changed catalogue at original error boundary")


func _native_unit(arena: Dictionary) -> Dictionary:
	var bindings: Dictionary = _bindings(arena)
	var player: Dictionary = arena.player.snapshot_state()
	var scheduler: Dictionary = arena.scheduler.snapshot_state(bindings)
	var playback: Dictionary = arena.actor.snapshot_state(scheduler, bindings)
	# The released fixture's NativeCodec deliberately accepts its exact original
	# Actor Script only. Do not bypass/reconstruct that codec for this subclass.
	# These are actual public/native source fields, not a restorable actor unit.
	var source: Dictionary = {"binding": _closed_native(arena.actor.get_authored_echo_binding()), "program": arena.actor.source_program(), "native": _closed_native(arena.actor.native_descriptor()), "hp": arena.actor.hp, "max_hp": arena.actor.max_hp, "dead": arena.actor.dead, "source_hits": arena.actor.source_hits, "defeated_at_s": arena.actor.defeated_at_s, "phase": arena.actor.source_phase(), "clock_s": arena.actor.source_clock()}
	if player.is_empty() or scheduler.is_empty() or playback.is_empty(): return {}
	# Native object/resource IDs may exceed Exact JSON safe integers.
	# Decimal tags are DIAGNOSTICS ONLY; actual public packets stay exact.
	return {"player": player, "scheduler": scheduler, "playback": playback, "source": source, "native": _closed_native(arena.actor.get_enemy_apparition().native_pose()), "hp": arena.actor.hp, "transform": _closed_native(arena.actor.global_transform), "source_instance": {"native_instance_id_decimal": str(arena.actor.get_instance_id())}, "source_script": {"native_instance_id_decimal": str(arena.actor.get_script().get_instance_id())}, "mesh": {"native_instance_id_decimal": str(arena.actor.get_enemy_apparition().visual.mesh.get_instance_id())}, "material": {"native_instance_id_decimal": str(arena.actor.get_enemy_apparition().visual.material_override.get_instance_id())}}


func _closed_native(value: Variant) -> Variant:
	if value is Vector3: return Value.vector3(value)
	if value is Basis: return [Value.vector3(value.x), Value.vector3(value.y), Value.vector3(value.z)]
	if value is Transform3D: return {"basis": _closed_native(value.basis), "origin": Value.vector3(value.origin)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: String in value: result[key] = _closed_native(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_closed_native(item))
		return result
	return value


func _watch(arena: Dictionary) -> void:
	arena.actor.state_changed.connect(func(_value: Dictionary) -> void: _callbacks.append("state"))
	arena.actor.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: _callbacks.append("event"))
	arena.actor.source_hit_resolved.connect(func(_value: Dictionary) -> void: _callbacks.append("source_hit"))
	arena.actor.source_defeated.connect(func(_value: Dictionary) -> void: _callbacks.append("source_defeated"))
	arena.player.fired.connect(func(kind: String) -> void: _callbacks.append(kind))
	arena.player.died.connect(func() -> void: _callbacks.append("player_death"))
	arena.player.world_action_executed.connect(func(_value: Dictionary) -> void: _callbacks.append("player_action"))
	arena.scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _callbacks.append("cancel"))
	for cue: Node3D in arena.actor.get_cues():
		cue.state_changed.connect(func(_value: Dictionary) -> void: _callbacks.append("cue"))


func _restore_catalogue() -> bool:
	if FileAccess.get_file_as_bytes(PROFILE_PATH) == _original_catalogue: return true
	var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null: return false
	file.store_buffer(_original_catalogue)
	file.flush()
	file.close()
	return FileAccess.get_file_as_bytes(PROFILE_PATH) == _original_catalogue


func _legacy_source_error(scheduler, owner: Node3D, sequence_snapshot: Dictionary, context: Dictionary, floor_regions: Array, expected_profile_id: String = "", expected_world_revision: int = 0, staged_binding: Dictionary = {}, allow_defeated: bool = false) -> String:
	## Pure retained source/world proof. Staged values are permitted only in
	## whole-unit paused prevalidation after the parent's complete actor proof;
	## actual immutable source definition is always queried and compared.
	if not Value.keys_error(context, ["world_root", "source_id", "source_epoch", "generation", "world_collision_fingerprint", "world_floor_signature"]).is_empty() or Exact.stringify(scheduler._closed_authored_context(context)).is_empty():
		return "Closed exact authored source/world context required"
	if not scheduler._stable_id(context.source_id) or not scheduler._stable_id(context.source_epoch) or not context.generation is int or not Value.is_integer(context.generation, 1) or not context.world_collision_fingerprint is Dictionary or not context.world_floor_signature is Array: return "Typed authored source/world identity required"
	if not is_instance_valid(owner) or not owner.is_inside_tree() or not owner.is_node_ready() or owner.is_queued_for_deletion() or not owner.has_method("get_authored_echo_binding") or not owner.has_method("configure_authored"):
		return "Actual ready authored Playback/C52 lease owner required"
	var actual_script: Script = scheduler._authored_owner_script(owner)
	if actual_script == null: return "Actual authored source must inherit shared Playback"
	var root_value: Variant = context.world_root
	if typeof(root_value) != TYPE_OBJECT or not is_instance_valid(root_value) or not root_value is Node3D: return "Actual authored world root required"
	var world_root: Node3D = root_value
	if not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or owner.get_world_3d() != scheduler.get_world_3d() or world_root.get_world_3d() != scheduler.get_world_3d() or not scheduler._under_root(owner, world_root) or not scheduler._under_root(scheduler, world_root): return "Authored owner/Scheduler must share the complete actual world"
	if Exact.stringify(sequence_snapshot).is_empty(): return "Bounded exact authored program required"
	var reader = ReuseProgram.new()
	if not reader.restore_state(sequence_snapshot, context.source_epoch, context.generation) or not reader.is_authored_enemy(): return "Distinct immutable authored enemy program required"
	var plan: Dictionary = reader.state()
	var native: Variant = owner.call("get_authored_echo_binding")
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.get_script() != actual_script or not native is Dictionary or not Value.keys_error(native, ["api_revision", "source_id", "source_epoch", "generation", "definition", "alive", "knot_position"]).is_empty() or native.api_revision != "authored-echo-source-1" or not native.source_id is String or not native.source_epoch is String or not native.generation is int or not Value.is_integer(native.generation, 0) or not native.definition is Dictionary or not native.alive is bool or not native.knot_position is Vector3 or not native.knot_position.is_finite(): return "Actual pure authored source binding rejected"
	var selected: Dictionary = native
	if not staged_binding.is_empty():
		if not scheduler.get_tree().paused or not Value.keys_error(staged_binding, ["api_revision", "source_id", "source_epoch", "generation", "definition", "alive", "knot_position"]).is_empty() or staged_binding.api_revision != "authored-echo-source-1" or not staged_binding.definition is Dictionary or not staged_binding.alive is bool or not staged_binding.knot_position is Vector3 or not staged_binding.knot_position.is_finite(): return "Validated paused original actor binding required for staging"
		selected = staged_binding
	if (not selected.alive and not allow_defeated) or selected.source_id != context.source_id or native.source_id != context.source_id or selected.source_epoch != context.source_epoch or not scheduler._authored_same(selected.generation, context.generation) or plan.source_id != context.source_id: return "Actual/staged living source cycle identity differs"
	if not scheduler._authored_same(Value.vector3(selected.knot_position), Value.vector3(plan.authored.tether_position)): return "Fixed authored knot differs from the immutable endpoint"
	if staged_binding.is_empty() and (not scheduler._authored_same(Value.vector3(owner.global_position), Value.vector3(selected.knot_position)) or (owner is CharacterBody3D and (owner as CharacterBody3D).velocity != Vector3.ZERO)): return "Authored physical owner must remain stationary at its exact knot"
	var floor: Dictionary = scheduler.authored_floor_signature(world_root, floor_regions)
	var collision: Dictionary = scheduler.pure_collision_fingerprint(world_root)
	if not floor.get("accepted", false) or collision.is_empty() or not scheduler._authored_same(floor.signature, context.world_floor_signature) or not scheduler._authored_same(collision, context.world_collision_fingerprint): return "Actual authored floor/collision guards differ"
	var profile_id: String = scheduler.get("_profile").get("id", "") if expected_profile_id.is_empty() else expected_profile_id
	var revision: int = int(scheduler.get("_world_revision")) if expected_world_revision == 0 else expected_world_revision
	var world: Dictionary = {"world_revision": revision, "collision_fingerprint": collision, "floor_signature": floor.signature}
	var codec = ReusePlan.new()
	var error: String = codec.binding_error(sequence_snapshot, context.source_id, context.source_epoch, context.generation, profile_id, native.definition, world)
	if not error.is_empty(): return error
	if not staged_binding.is_empty() and not codec.binding_error(sequence_snapshot, context.source_id, context.source_epoch, context.generation, profile_id, selected.definition, world).is_empty(): return "Staged immutable source definition differs"
	return ""
