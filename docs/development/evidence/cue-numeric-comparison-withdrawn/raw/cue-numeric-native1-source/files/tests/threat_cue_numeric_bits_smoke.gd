extends "res://tests/threat_cue_reference_bits_smoke.gd"
## TEST ONLY numeric-zero exact-bit candidate. Inherits all original439 native,
## subclass and hostile-tree controls; adds finite binary64 edge oracle parity.
## Production finite references remain the unchanged ExactJson bind boundary.

func _pure_bits_parity() -> void:
	super._pure_bits_parity()
	var patterns: Array = [
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 128],
		[1, 0, 0, 0, 0, 0, 0, 0],
		[1, 0, 0, 0, 0, 0, 0, 128],
		[2, 0, 0, 0, 0, 0, 0, 0],
		[2, 0, 0, 0, 0, 0, 0, 128],
		[255, 255, 255, 255, 255, 255, 15, 0],
		[255, 255, 255, 255, 255, 255, 15, 128],
		[0, 0, 0, 0, 0, 0, 16, 0],
		[0, 0, 0, 0, 0, 0, 16, 128],
		[1, 0, 0, 0, 0, 0, 16, 0],
		[1, 0, 0, 0, 0, 0, 16, 128],
		[0, 0, 0, 0, 0, 0, 240, 63],
		[1, 0, 0, 0, 0, 0, 240, 63],
		[255, 255, 255, 255, 255, 255, 239, 63],
		[0, 0, 0, 0, 0, 0, 240, 191],
		[1, 0, 0, 0, 0, 0, 240, 191],
		[255, 255, 255, 255, 255, 255, 239, 191],
		[255, 255, 255, 255, 255, 255, 239, 127],
		[255, 255, 255, 255, 255, 255, 239, 255]
	]
	var values: Array[float] = []
	for index: int in range(patterns.size()):
		var bytes := PackedByteArray(patterns[index])
		var value: float = bytes.decode_double(0)
		values.append(value)
		var round_trip := PackedByteArray()
		round_trip.resize(8)
		round_trip.encode_double(0, value)
		_expect(round_trip == bytes and not ExactJson.stringify(value).is_empty(), "finite binary64 edge%d retains exact eight native bytes and unchanged bind admission" % index)
	for index: int in range(values.size()):
		var reference: float = values[index]
		var bits: Variant = Cue._projection_float_bits(reference)
		for other: int in range(values.size()):
			_parity(values[other], reference, bits, index == other, "finite scalar pair%d/%d including signed zero, subnormals and adjacent normal values" % [index, other])
		for foreign: Variant in [0, 1, NAN, INF, -INF, Vector3.ZERO, PackedFloat64Array([reference])]:
			_parity(foreign, reference, bits, false, "finite scalar%d rejects foreign type/nonfinite value%d" % [index, typeof(foreign)])
		for coordinate: int in range(3):
			var point: Array[float] = [1.0, 2.0, 3.0]
			point[coordinate] = reference
			var point_bits: Variant = Cue._projection_float_bits(point)
			_parity(point.duplicate(), point, point_bits, true, "finite edge%d at coordinate%d retains typed triplet" % [index, coordinate])
			for other: int in range(values.size()):
				var changed: Array[float] = point.duplicate()
				changed[coordinate] = values[other]
				_parity(changed, point, point_bits, index == other, "finite triplet edge%d/%d coordinate%d" % [index, other, coordinate])
			for foreign: Variant in [0, NAN, INF, -INF]:
				var mixed: Array = [point[0], point[1], point[2]]
				mixed[coordinate] = foreign
				_parity(mixed, point, point_bits, false, "finite triplet edge%d coordinate%d rejects type/nonfinite%d" % [index, coordinate, typeof(foreign)])
