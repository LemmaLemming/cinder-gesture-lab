extends "res://tests/threat_cue_reference_comparison_smoke.gd"
## Selected targeted native exact-comparison experiment; no speedup claimed.
## Original325 controls are inherited; no historical execution credited here.

class PreflightMutationCue extends "res://scripts/cues/threat_cue.gd":
	var preflight_calls: int = 0
	func projection_binding_error(event: Dictionary) -> String:
		var error: String = super.projection_binding_error(event)
		preflight_calls += 1
		if error.is_empty():
			# A legitimate subclass mutates a finite input after super preflight.
			# Original structural Cue behavior is retained; whole-plan provenance
			# remains the actual caller's separate responsibility.
			var bytes := PackedByteArray()
			bytes.resize(8)
			bytes.encode_double(0, float(event.at_s))
			bytes[0] = bytes[0] ^ 1
			event.at_s = bytes.decode_double(0)
		return error


var _bits_finished: bool = false
var _bits_watchdog: BitsWatchdog

class BitsWatchdog:
	extends Node
	signal expired
	var deadline_ms: int
	var fired: bool = false
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		deadline_ms = Time.get_ticks_msec() + 240000
	func _process(_delta: float) -> void:
		if not fired and Time.get_ticks_msec() >= deadline_ms:
			fired = true
			expired.emit()

func _run() -> void:
	_bits_watchdog = BitsWatchdog.new()
	_bits_watchdog.expired.connect(func() -> void:
		if not _bits_finished:
			_expect(false, "Cue bits experiment exceeded monotonic240s process-observed watchdog; no completion credit")
			quit(1))
	root.add_child(_bits_watchdog)
	await _native_projection("hole")
	await _native_projection("wall")
	await _custody_checks()
	await _reference_comparison_controls()
	_pure_bits_parity()
	await _subclass_and_future_native_guards()
	_bits_finished = true
	_bits_watchdog.free()
	print("Cue reference bits smoke: %d checks, %d failures; pure exact oracle plus actual inherited native controls" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _pure_bits_parity() -> void:
	var negative_zero: float = PackedByteArray([0, 0, 0, 0, 0, 0, 0, 128]).decode_double(0)
	var typed_point: Array[float] = [0.0, -2.0, 3.0]
	var typed_mapping: Dictionary[String, Variant] = {"point": typed_point, "label": "π月"}
	var references: Array = [null, true, false, 0, -1, 0.0, negative_zero, 1.0, "π月", [], {}, [0.0, -2.0, 3.0], [0.0, 1.0], [0.0, 1.0, 2.0, 3.0], [0, 1.0, "mixed"], {"point": [0.0, -2.0, 3.0], "nested": [[], {"zero": negative_zero, "yes": true}]}, typed_mapping]
	for index: int in range(references.size()):
		var reference: Variant = references[index]
		_expect(not ExactJson.stringify(reference).is_empty(), "pure oracle reference%d passes unchanged whole Exact bounds" % index)
		var bits: Variant = Cue._projection_float_bits(reference)
		var copy: Variant = reference.duplicate(true) if reference is Array or reference is Dictionary else reference
		_parity(copy, reference, bits, true, "closed value%d and ignored typed metadata" % index)
		_parity(Vector3.ZERO, reference, bits, false, "native Vector3 versus closed reference%d" % index)
	var reference: Dictionary = {"point": [0.0, -2.0, 3.0], "time": 1.0, "label": "finite", "nested": {"ready": true}}
	var bits: Variant = Cue._projection_float_bits(reference)
	var reversed: Dictionary = {"nested": reference.nested.duplicate(true), "label": "finite", "time": 1.0, "point": typed_point}
	_parity(reversed, reference, bits, true, "String dictionary insertion order and typed point Array")
	var candidates: Dictionary = {}
	var bad: Dictionary = reference.duplicate(true)
	bad.point[0] = negative_zero
	candidates["coordinate opposite signed zero"] = bad
	bad = reference.duplicate(true)
	bad.time = _one_bit(1.0)
	candidates["scalar one-bit float"] = bad
	bad = reference.duplicate(true)
	bad.point[2] = _one_bit(3.0)
	candidates["coordinate one-bit float"] = bad
	bad = reference.duplicate(true)
	bad.point[0] = 0
	candidates["coordinate equal int versus float"] = bad
	bad = reference.duplicate(true)
	bad.time = 1
	candidates["scalar equal int versus float"] = bad
	bad = reference.duplicate(true)
	bad.point = PackedFloat64Array([0.0, -2.0, 3.0])
	candidates["native packed numeric Array"] = bad
	bad = reference.duplicate(true)
	bad.point[1] = NAN
	candidates["nonfinite coordinate"] = bad
	bad = reference.duplicate(true)
	bad.time = INF
	candidates["nonfinite scalar"] = bad
	bad = reference.duplicate(true)
	var saved: Variant = bad.nested.ready
	bad.nested.erase("ready")
	bad.nested[StringName("ready")] = saved
	candidates["nested StringName key alias"] = bad
	bad = reference.duplicate(true)
	bad.label = StringName("finite")
	candidates["StringName scalar"] = bad
	bad = reference.duplicate(true)
	bad.point.resize(ExactJson.MAX_ENTRIES + 1)
	candidates["foreign overwide shape"] = bad
	bad = reference.duplicate(true)
	bad.label = "x".repeat(ExactJson.MAX_BYTES + 1)
	candidates["foreign oversized String"] = bad
	var cyclic_point: Array = [0.0, -2.0, 3.0]
	cyclic_point[1] = cyclic_point
	bad = reference.duplicate(true)
	bad.point = cyclic_point
	candidates["matched-width foreign cycle"] = bad
	var live := Node3D.new()
	bad = reference.duplicate(true)
	bad.nested = live
	candidates["live Object"] = bad
	var freed := Node3D.new()
	bad = reference.duplicate(true)
	bad.nested = freed
	freed.free()
	candidates["freed Object"] = bad
	for label: String in candidates:
		# Never Exact.stringify hostile candidates; the finite reference bounds
		# both original and proposed traversals. No fabricated accepted token.
		_parity(candidates[label], reference, bits, false, label)
	cyclic_point.clear()
	live.free()


func _parity(candidate: Variant, reference: Variant, bits: Variant, expected: bool, label: String) -> void:
	var original: bool = Cue._same_projection_reference(candidate, reference)
	var proposed: bool = Cue._same_projection_bits(candidate, bits)
	_expect(original == expected and proposed == original, "private pure original two-argument oracle parity: " + label)


func _subclass_and_future_native_guards() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena)
	var sequence: Dictionary = _sequence(recorded.capture, arena.player.global_position)
	var plan: Dictionary = _plan(arena, sequence)
	_expect(plan.get("accepted", false) and not plan.events.is_empty(), "new native controls use actual completed Player/whole-Footprint event")
	if not plan.get("accepted", false) or plan.events.is_empty():
		await _dispose(arena)
		return
	var event: Dictionary = plan.events[0]
	var hero_before: Dictionary = arena.player.snapshot_state()
	var clock_before: float = arena.scheduler.get_clock()
	var input: Dictionary = event.duplicate(true)
	var subclass := PreflightMutationCue.new()
	arena.world.add_child(subclass)
	_expect(subclass.bind_projection(input) and subclass.preflight_calls == 1 and not ExactJson.stringify(input).is_empty(), "legitimate derived virtual preflight keeps its original post-super finite input mutation")
	_expect(subclass.get_script() != Cue and subclass.get("_projection_reference_bits").is_empty() and subclass.projection_error(input).is_empty() and subclass.projection_error(event) == "Expected event differs from the exact bound projection", "derived Cue retains original comparer fallback and bound modified input, without native plan authority")
	_expect(subclass.present(_shape(input), "active") and subclass.projection_error(input).is_empty(), "derived native phase/source/mesh custody remains available after structural fallback")
	for kind: String in ["future_lock_mesh", "callback_material"]:
		var cue = _bound(arena.world, event)
		_expect(cue.present(_shape(event), "warning") and cue.projection_error(event).is_empty(), kind + " starts actual intact warning resources")
		if kind == "future_lock_mesh":
			var meshes: Dictionary = cue.get("_projection_meshes")
			var mesh: ArrayMesh = meshes["lock"]
			var arrays: Array = mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			_expect(not vertices.is_empty(), "future lock source marker has actual native vertices")
			if not vertices.is_empty():
				vertices[0].x += 0.0001
				arrays[Mesh.ARRAY_VERTEX] = vertices
				mesh.clear_surfaces()
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		else:
			var callback_errors: Array[String] = []
			cue.state_changed.connect(func(value: Dictionary) -> void:
				if value.phase == "lock":
					(cue.get_node("RequiredSourceMarker").material_override as StandardMaterial3D).no_depth_test = true
					callback_errors.append(cue.projection_error(event))
			)
			_expect(cue.present(_shape(event), "lock") and callback_errors.size() == 1 and not callback_errors[0].is_empty(), "synchronous actual phase material mutation is rejected inside callback without changing original present ordering")
		var state_before: Dictionary = cue.state()
		cue.last_error = "pure native sentinel"
		_expect(not cue.projection_error(event).is_empty() and cue.last_error == "pure native sentinel" and cue.state() == state_before, kind + " current native guard remains pure despite matching cached scalar bits")
		_expect(not cue.present(_shape(event), "active") and cue.state() == state_before and cue.clear() and not cue.projection_error(event).is_empty(), kind + " later phase/clear cannot heal changed future native resource or material")
	_expect(hero_before == arena.player.snapshot_state() and clock_before == arena.scheduler.get_clock(), "new pure/native controls retain actual Player and Scheduler clocks/resources")
	await _dispose(arena)


func _bound(parent: Node3D, event: Dictionary) -> Node3D:
	var cue: Node3D = super._bound(parent, event)
	_expect(cue.get_script() == Cue and cue.get("_projection_reference_bits") is Dictionary and not cue.get("_projection_reference_bits").is_empty(), "actual canonical bound Cue enables private bits branch before native custody checks")
	return cue
