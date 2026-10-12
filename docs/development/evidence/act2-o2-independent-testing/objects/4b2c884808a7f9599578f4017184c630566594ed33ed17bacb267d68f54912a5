extends "res://tests/projected_cue_smoke.gd"
## TEST ONLY native Cue comparison. Canonical recorded hole/LOS/custody cases
## are inherited unchanged. The large repeated-triangle case is a structural
## Cue transport receipt, explicitly not authenticated whole-Footprint clipping.


func _run() -> void:
	await _native_projection("hole")
	await _native_projection("wall")
	await _custody_checks()
	await _reference_comparison_controls()
	print("Threat cue reference comparison smoke: %d checks, %d failures; native recorded controls plus labelled structural large transport" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _reference_comparison_controls() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena)
	var sequence: Dictionary = _sequence(recorded.capture, arena.player.global_position)
	var plan: Dictionary = _plan(arena, sequence)
	_expect(plan.get("accepted", false) and Footprint.projection_error(plan, arena.scheduler, sequence, arena.world, arena.floors, arena.context).is_empty(), "reference controls start with actual recorded action and authenticated native floor projection")
	if not plan.get("accepted", false) or plan.events.is_empty():
		await _dispose(arena)
		return
	var event: Dictionary = plan.events[0]
	_reference_controls(arena, event, "canonical")
	var large: Dictionary = _large_structural_event(event)
	if large.is_empty():
		_expect(false, "large structural control needs a real finite nondegenerate recorded triangle")
		await _dispose(arena)
		return
	var wire: String = ExactJson.stringify(large)
	_expect(not wire.is_empty() and wire.to_utf8_buffer().size() > 1024 * 1024 and wire.to_utf8_buffer().size() <= ExactJson.MAX_BYTES and large.triangle_vertices.size() + large.boundary_contours[0].vertices.size() <= Cue.MAX_PROJECTED_VERTICES, "TEST ONLY repeated safe triangle has valid original Exact transport above1MiB within8MiB and Cue vertex bounds")
	if wire.is_empty() or wire.to_utf8_buffer().size() <= 1024 * 1024:
		await _dispose(arena)
		return
	var forged_plan: Dictionary = plan.duplicate(true)
	forged_plan.events[0] = large
	_expect(not Footprint.projection_error(forged_plan, arena.scheduler, sequence, arena.world, arena.floors, arena.context).is_empty(), "large structural Cue receipt cannot masquerade as original whole-Footprint authentication")
	_reference_controls(arena, large, "large structural")
	await _dispose(arena)


func _large_structural_event(event: Dictionary) -> Dictionary:
	# Retain a genuine original action record/floor. Repetition supplies bounded
	# scalar transport volume without inventing additional logical danger.
	var triangle: Array = []
	var largest_area: float = -1.0
	for index: int in range(0, event.triangle_vertices.size(), 3):
		var candidate: Array = event.triangle_vertices.slice(index, index + 3)
		var area: float = _triangle_area(candidate)
		if absf(area) > largest_area:
			largest_area = absf(area)
			triangle = candidate.duplicate(true)
	if triangle.size() != 3 or largest_area <= 0.0:
		return {}
	if _triangle_area(triangle) < 0.0:
		var last: Array = triangle[2]
		triangle[2] = triangle[1]
		triangle[1] = last
	var large: Dictionary = event.duplicate(true)
	large.triangle_vertices = []
	for _copy: int in range(4000):
		large.triangle_vertices.append_array(triangle.duplicate(true))
	var contour: Array = triangle.duplicate(true)
	contour.append(triangle[0].duplicate(true))
	large.boundary_contours = [{"hole": false, "vertices": contour}]
	large.bounds = [float(triangle[0][0]), float(triangle[0][2]), float(triangle[0][0]), float(triangle[0][2])]
	for point: Array in triangle:
		large.bounds[0] = minf(large.bounds[0], float(point[0]))
		large.bounds[1] = minf(large.bounds[1], float(point[2]))
		large.bounds[2] = maxf(large.bounds[2], float(point[0]))
		large.bounds[3] = maxf(large.bounds[3], float(point[2]))
	return large


func _triangle_area(points: Array) -> float:
	return (float(points[1][0]) - float(points[0][0])) * (float(points[2][2]) - float(points[0][2])) - (float(points[1][2]) - float(points[0][2])) * (float(points[2][0]) - float(points[0][0]))


func _reference_controls(arena: Dictionary, event: Dictionary, label: String) -> void:
	_expect(not event.triangle_vertices.is_empty() and not event.boundary_contours.is_empty(), label + " control has genuine finite native fill/contour data")
	if event.triangle_vertices.is_empty() or event.boundary_contours.is_empty(): return
	var input: Dictionary = event.duplicate(true)
	var input_point: Array = input.triangle_vertices[0]
	var input_contour: Array = input.boundary_contours[0].vertices
	var cue = Cue.new()
	arena.world.add_child(cue)
	var notifications: Array = []
	cue.state_changed.connect(func(value: Dictionary) -> void: notifications.append(value))
	_expect(cue.bind_projection(input) and cue.projection_error(event).is_empty() and notifications.is_empty(), label + " binds original validated native meshes silently, no new1MiB restriction")
	if cue.projection_state().is_empty():
		cue.queue_free()
		return
	var original_wire: String = ExactJson.stringify(event)
	input_point[0] = _one_bit(float(input_point[0]))
	input_contour.pop_back()
	input.bounds.clear()
	input.record.geometry.reach = _one_bit(float(input.record.geometry.reach))
	_expect(cue.projection_error(event).is_empty() and ExactJson.stringify(cue.projection_state()) == original_wire and not cue.projection_error(input).is_empty(), label + " original input/nested Array and record aliases cannot mutate retained event or private anchor")
	var exposed: Dictionary = cue.projection_state()
	var exposed_point: Array = exposed.triangle_vertices[0]
	exposed_point[2] = _one_bit(float(exposed_point[2]))
	exposed.record.clear()
	exposed.boundary_contours.clear()
	_expect(cue.projection_error(event).is_empty() and ExactJson.stringify(cue.projection_state()) == original_wire, label + " mutable public projection_state/nested aliases remain independent defensive copies")
	var reordered: Dictionary = {}
	var reverse_keys: Array = event.keys()
	reverse_keys.reverse()
	for key: String in reverse_keys:
		reordered[key] = event[key].duplicate(true) if event[key] is Array or event[key] is Dictionary else event[key]
	_expect(ExactJson.stringify(reordered) == original_wire and cue.projection_error(reordered).is_empty(), label + " original canonical String-key equality ignores Dictionary insertion order")
	var typed_event: Dictionary[String, Variant] = {}
	for key: String in event:
		typed_event[key] = event[key].duplicate(true) if event[key] is Array or event[key] is Dictionary else event[key]
	var typed_point: Array[float] = []
	for coordinate: Variant in event.triangle_vertices[0]:
		typed_point.append(coordinate)
	typed_event.triangle_vertices[0] = typed_point
	_expect(ExactJson.stringify(typed_event) == original_wire and cue.projection_error(typed_event).is_empty(), label + " typed container metadata remains absent from original tagged transport equality")
	_expect(event.floor_y is float and event.floor_y == 0.0, label + " actual Box floor provides genuine float zero for copied-bit/type controls")
	var negatives: Dictionary = {}
	var bad: Dictionary = event.duplicate(true)
	bad.at_s = _one_bit(float(bad.at_s))
	negatives["one-bit float"] = bad
	bad = event.duplicate(true)
	var zero := PackedByteArray()
	zero.resize(8)
	zero.encode_double(0, float(event.floor_y))
	zero[7] = zero[7] ^ 128
	bad.floor_y = zero.decode_double(0)
	negatives["opposite signed zero"] = bad
	bad = event.duplicate(true)
	bad.floor_y = int(event.floor_y)
	negatives["equal-number int versus float"] = bad
	bad = event.duplicate(true)
	var event_id: Variant = bad.event_id
	bad.erase("event_id")
	bad[StringName("event_id")] = event_id
	negatives["StringName key alias"] = bad
	bad = event.duplicate(true)
	bad.event_id = StringName(event.event_id)
	negatives["StringName scalar"] = bad
	bad = event.duplicate(true)
	bad.record = arena.player
	negatives["native live Object"] = bad
	bad = event.duplicate(true)
	var retired := Node3D.new()
	bad.record = retired
	retired.free()
	negatives["native freed Object"] = bad
	bad = event.duplicate(true)
	var cyclic_point: Array = [0.0, float(event.floor_y), 0.0]
	cyclic_point[0] = cyclic_point
	bad.triangle_vertices[0] = cyclic_point
	negatives["matched-width foreign cycle"] = bad
	bad = event.duplicate(true)
	bad.triangle_vertices.resize(ExactJson.MAX_ENTRIES + 1)
	negatives["overwide foreign shape"] = bad
	bad = event.duplicate(true)
	bad["unknown"] = {}
	negatives["extra closed branch"] = bad
	bad = event.duplicate(true)
	bad.event_id = "x".repeat(1024 * 1024 + 1)
	negatives["oversized foreign String"] = bad
	bad = event.duplicate(true)
	bad.floor_y = NAN
	negatives["nonfinite float"] = bad
	var native_before: PackedByteArray = _native_state(cue)
	for name: String in negatives:
		cue.last_error = "reference pure sentinel"
		_expect(cue.projection_error(negatives[name]) == "Expected event differs from the exact bound projection" and cue.last_error == "reference pure sentinel" and native_before == _native_state(cue) and notifications.is_empty(), label + " " + name + " refuses purely with original expected-event error precedence")
	cyclic_point.clear()
	_expect(cue.present(_shape(event), "active") and cue.projection_error(event).is_empty(), label + " foreign failures do not latch, heal or alter genuine required phase authority")
	# Working storage remains separate and guarded; this existing private-field
	# negative never reads, returns or modifies the new private reference anchor.
	var storage: Dictionary = cue.get("_projection")
	storage.at_s = _one_bit(float(storage.at_s))
	var changed_before: PackedByteArray = _native_state(cue)
	cue.last_error = "working storage sentinel"
	_expect(cue.projection_error(event) == "Bound projection event storage changed" and cue.last_error == "working storage sentinel" and changed_before == _native_state(cue), label + " working event mutation is independently rejected by unchanged storage error precedence")
	_expect(not cue.present(_shape(event), "recovery") and cue.clear() and not cue.projection_error(event).is_empty() and not cue.bind_projection(event), label + " working storage mutation cannot be healed by phase, clear or rebind")
	cue.queue_free()
