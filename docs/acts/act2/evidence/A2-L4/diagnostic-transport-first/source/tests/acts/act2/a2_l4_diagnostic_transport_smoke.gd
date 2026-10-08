extends "res://tests/acts/act2/a2_l4_priority_repro.gd"
## TEST ONLY native/component diagnostic encoding regression. No Main/Shell,
## campaign seed, combat, clocks, progression or blocker-traversal credit.
## Uses the repaired converter/anomaly walker; canonical authority is unchanged.

func _run() -> void:
	var unit := Node3D.new()
	unit.name = "TestOnlyDiagnosticFloor"
	root.add_child(unit)
	LondonFloor.build(unit)
	var collision := unit.get_node("LondonApproachesDryGround/GardenStemBlocker/GroundedBlocker") as CollisionShape3D
	var box := collision.shape as BoxShape3D
	if not _expect(is_instance_valid(box), "actual authored native blocker supplies a genuine Box resource"):
		unit.free(); quit(1); return
	var native_id: int = box.get_instance_id()
	var oversized: bool = native_id < -PriorityJson.MAX_INTEGER or native_id > PriorityJson.MAX_INTEGER
	if not _expect(oversized, "actual RefCounted Box ID reproduces the native oversized-integer diagnostic boundary"):
		unit.free(); quit(1); return
	_expect(PriorityJson.stringify(native_id).is_empty() and PriorityJson.stringify({"shape_id": native_id}).is_empty(), "canonical ExactJson rejects the same raw oversized native ID")
	var vector := Vector3(0.375, 0.125, -22.6)
	var pair := Vector2(1.25, -0.5)
	var bits: Array = [0.10000000000000002, -0.0]
	var special: Array = [NAN, INF, -INF]
	var raw: Dictionary = {"shape_id": native_id, "vector": vector, "pair": pair, "finite_bits": bits, "nonfinite": special}
	var anomalies: Array[Dictionary] = []
	_pr_diagnostic_anomalies(raw, "diagnostic", anomalies)
	_expect(anomalies.size() == 4, "anomaly walker reports one genuine integer ID and three explicit nonfinite values")
	var expected_id: Dictionary = {"path": "diagnostic.shape_id", "reason": "native integer exceeds exact JSON range", "decimal": str(native_id)}
	_expect(anomalies.has(expected_id), "anomaly retains the actual ID's complete decimal text without float conversion")
	var diagnostic: Dictionary = _pr_json_value(raw)
	_expect(diagnostic.shape_id == {"diagnostic_native_integer_decimal": str(native_id)}, "repaired converter stores an explicitly diagnostic integer type and exact decimal string")
	_expect(diagnostic.vector == [vector.x, vector.y, vector.z] and diagnostic.pair == [pair.x, pair.y], "genuine finite native vector components retain their measured values")
	_expect(_pr_closed_problem(diagnostic, "diagnostic").is_empty(), "repaired diagnostic contains only closed JSON values")
	var encoded: String = PriorityJson.stringify(diagnostic)
	if not _expect(not encoded.is_empty(), "repaired native diagnostic serializes without relaxing canonical limits"):
		unit.free(); quit(1); return
	var parsed: Dictionary = PriorityJson.parse(encoded)
	if not _expect(parsed.get("accepted", false) and PriorityJson.stringify(parsed.get("value", {})) == encoded, "ExactJson roundtrip preserves the complete tagged diagnostic exactly"):
		unit.free(); quit(1); return
	var restored: Dictionary = parsed.value
	_expect(restored.shape_id.diagnostic_native_integer_decimal is String and restored.shape_id.diagnostic_native_integer_decimal == str(native_id), "decoded resource identity remains diagnostic text rather than authority or a rounded integer")
	_expect(PriorityJson.stringify(restored.finite_bits) == PriorityJson.stringify(bits), "finite float64 bits, including negative zero, survive unchanged")
	_expect(PriorityJson.stringify(restored.vector) == PriorityJson.stringify([vector.x, vector.y, vector.z]) and PriorityJson.stringify(restored.pair) == PriorityJson.stringify([pair.x, pair.y]), "native vector component bits survive the exact diagnostic transport")
	for index: int in range(special.size()):
		var classification: String = ["NAN", "+INF", "-INF"][index]
		_expect(restored.nonfinite[index] == {"diagnostic_nonfinite_float": classification}, "nonfinite observation stays an explicit diagnostic tag: " + classification)
		_expect(anomalies.has({"path": "diagnostic.nonfinite[%d]" % index, "reason": "nonfinite native diagnostic float", "classification": classification}), "anomaly records the original nonfinite classification/path: " + classification)
		_expect(PriorityJson.stringify(special[index]).is_empty() and PriorityJson.stringify({"clock_s": special[index]}).is_empty(), "canonical authority still rejects the raw nonfinite value: " + classification)
	_expect(PriorityJson.MAX_INTEGER == 9007199254740991 and not PriorityJson.stringify(PriorityJson.MAX_INTEGER).is_empty() and PriorityJson.stringify(native_id).is_empty(), "canonical integer limit is unchanged; diagnostic conversion never clamps or regrants the ID")
	_expect(PriorityJson.stringify(vector).is_empty(), "canonical authority still rejects an unconverted native vector")
	unit.free()
	_expect(not is_instance_valid(unit) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "component closure creates no combat source/cue or campaign progress")
	print("L4 diagnostic transport smoke: %d checks, %d failures; native Box ID/vector/finite bits and diagnostic-only nonfinite tags; no combat/route/authority claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
