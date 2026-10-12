extends SceneTree
## Exact finite JSON-value transport + real versioned file persistence.
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var clock: float = 0.0
	for _tick: int in range(6):
		clock += 1.0 / 60.0
	var rounded: float = JSON.parse_string(JSON.stringify(clock, "", true, true))
	_expect(_bits(clock) != _bits(rounded), "installed decimal parser reproduces the genuine six-tick clock bit loss")
	var negative_zero: float = "0000000000000080".hex_decode().decode_double(0)
	var tiny: float = "0100000000000000".hex_decode().decode_double(0)
	var original: Dictionary = {"reservation": {"start_s": clock, "clock_s": clock, "active_s": clock + 0.45}, "vector": [Vector3(0, -0.005078136455267668, -0.5).y, 0.0, 1.0], "zero": negative_zero, "tiny": tiny, "integer": 9007199254740991, "negative": -9007199254740991, "array": [true, false, null, "float64", ["integer", "2"]], "text": "quote\"\\\n世界", "": {"api_revision": "reserved-looking-user-value"}}
	var text: String = Exact.stringify(original)
	var result: Dictionary = Exact.parse(text)
	_expect(result.accepted and _same(original, result.get("value")), "exact JSON preserves finite scalar bits/types and nested ordinary strings/containers")
	_expect(Exact.stringify(original) == text, "encoding is deterministic for identical native values")
	var controls: String = ""
	for code: int in range(1, 32):
		controls += String.chr(code)
	var strings: Dictionary = {controls: controls, "replacement": "�", "nul_literal": "\\u0000", "literal": "\\v", "mixed": "\\" + String.chr(11) + "\\\\v" + String.chr(11)}
	var string_result: Dictionary = Exact.parse(Exact.stringify(strings))
	_expect(string_result.accepted and _same(strings, string_result.get("value")), "representable control keys/values, replacement characters and literal backslash-v strings retain their values")
	var runs: Array = []
	for count: int in range(6):
		runs.append("\\".repeat(count) + String.chr(11))
		runs.append("\\".repeat(count) + "v")
	var run_result: Dictionary = Exact.parse(Exact.stringify(runs))
	_expect(run_result.accepted and _same(runs, run_result.get("value")), "zero-to-five slash runs distinguish actual vertical tabs from ordinary literal v")
	_expect(_bits(result.value.zero) == _bits(negative_zero) and _bits(result.value.tiny) == _bits(tiny), "negative zero and the smallest finite subnormal survive without decimal parsing")
	var corpus: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 238497
	for _index: int in range(2048):
		var bytes := PackedByteArray()
		bytes.resize(8)
		for index: int in range(8):
			bytes[index] = rng.randi_range(0, 255)
		var value: float = bytes.decode_double(0)
		if is_finite(value):
			corpus.append(value)
	var many: Dictionary = Exact.parse(Exact.stringify(corpus))
	_expect(many.accepted and _same(corpus, many.get("value")), "two thousand seeded finite binary64 samples retain all bits")
	for value: Variant in [NAN, INF, -INF, Vector3.ZERO, &"name", {1: "key"}, 9007199254740992]:
		_expect(Exact.stringify(value).is_empty(), "nonclosed/nonfinite/out-of-range source values reject")
	var deep: Array = []
	var nested: Array = deep
	for _index: int in range(65):
		var child: Array = []
		nested.append(child)
		nested = child
	_expect(Exact.stringify(deep).is_empty(), "deep source values reject before unbounded recursion")
	for node: Variant in [["float64", "000000000000f07f"], ["float64", "000000000000f87f"], ["float64", "GG00000000000000"], ["float64", "00"], ["integer", "+1"], ["integer", "01"], ["integer", "9007199254740992"], ["null", false], ["boolean", 1], ["object", "res://scripts/player.gd"], ["dictionary", [["a", ["integer", "1"]], ["a", ["integer", "2"]]]], ["dictionary", [[1, ["null"]]]]]:
		var malformed: String = JSON.stringify({"api_revision": Exact.API_REVISION, "schema_version": 1, "value": node})
		_expect(not Exact.parse(malformed).accepted, "malformed/duplicate/unsupported exact nodes reject quietly")
	_expect(not Exact.parse("broken").accepted and not Exact.parse(JSON.stringify({"api_revision": "other", "schema_version": 1, "value": ["null"]})).accepted, "unknown envelope and malformed JSON cannot masquerade as null data")
	_expect(not Exact.parse(JSON.stringify({"api_revision": Exact.API_REVISION, "schema_version": true, "value": ["null"]})).accepted, "boolean schema cannot masquerade as an integral format version")
	for oversized: String in ["99999999999999999999", "-99999999999999999999", "9".repeat(100000)]:
		_expect(not Exact.parse(JSON.stringify({"api_revision": Exact.API_REVISION, "schema_version": 1, "value": ["integer", oversized]})).accepted, "oversized integer text rejects before native overflow conversion")
	_expect(not Exact.parse("[".repeat(200) + "0" + "]".repeat(200)).accepted, "raw nesting rejects before parser tree allocation")
	_expect(not Exact.parse("[" + "0,".repeat(Exact.MAX_ENTRIES) + "0]").accepted, "raw excessive container entries reject before parser tree allocation")
	var nul_text: String = JSON.stringify({"api_revision": Exact.API_REVISION, "schema_version": 1, "value": ["string", "placeholder"]}).replace("\"placeholder\"", "\"\\u0000\"")
	_expect(not Exact.parse(nul_text).accepted, "unrepresentable Unicode NUL rejects before parser replacement/diagnostics")
	await _file_checks(original)
	print("Exact JSON smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _file_checks(original: Dictionary) -> void:
	var path: String = "user://exact-json-smoke-%d.json" % Time.get_ticks_usec()
	var store = Store.new(path)
	var published: bool = store.write_payload(original)
	_expect(published, "real version2 save publishes an exact generation: " + store.last_error)
	if not published:
		return
	var reopened = Store.new(path)
	_expect(_same(original, reopened.read_payload()), "reopened physical save preserves the exact genuine reservation clock and all scalar types")
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(envelope.get("format_version") == 2 and Exact.parse(envelope.get("payload_json", "")).accepted, "published save declares the exact transport version")
	var next: Dictionary = original.duplicate(true)
	next.reservation.clock_s += 1.0 / 60.0
	_expect(store.write_payload(next) and store.generation == 2, "second exact generation preserves valid prior backup")
	var bad: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	bad.store_string("interrupted")
	bad.close()
	_expect(_same(original, reopened.read_payload()) and reopened.loaded_backup, "interrupted primary recovers the prior exact clock generation")
	# Legacy compatibility is explicitly not a reconstruction of lost bits.
	var legacy: Dictionary = {"clock_s": 0.25, "name": "legacy", "count": 2}
	var encoded: String = JSON.stringify(legacy, "", true, true)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"format_version": 1, "generation": 7, "payload_json": encoded, "sha256": encoded.sha256_text()}))
	file.close()
	var loaded: Dictionary = reopened.read_payload()
	_expect(loaded.get("clock_s") == 0.25 and loaded.get("name") == "legacy" and reopened.generation == 7, "valid legacy decimal generation still loads with its historical semantics")
	_expect(reopened.write_payload(original) and reopened.generation == 8 and _same(original, reopened.read_payload()), "next write upgrades a loaded legacy save without refreshing resources or clocks")
	var before: Dictionary = reopened.read_payload()
	_expect(not reopened.write_payload({"clock": INF}) and _same(before, reopened.read_payload()), "invalid new save leaves the complete published generation untouched")
	var near_limit: Dictionary = {"a": "\\".repeat(4194256)}
	_expect(Exact.stringify(near_limit).to_utf8_buffer().size() == Exact.MAX_BYTES - 1, "escaped-string fixture reaches the exact transport byte boundary")
	var boundary_written: bool = reopened.write_payload(near_limit)
	_expect(boundary_written and reopened.read_payload().get("a") == near_limit.a, "near-limit escaped payload publishes and reopens within the bounded file envelope")
	for suffix: String in ["", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	await process_frame

func _bits(value: float) -> String:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	return bytes.hex_encode()

func _same(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right):
		return false
	if left is float:
		return _bits(left) == _bits(right)
	if left is Array:
		if left.size() != right.size():return false
		for index: int in range(left.size()):
			if not _same(left[index], right[index]):return false
		return true
	if left is Dictionary:
		if left.size() != right.size():return false
		for key: Variant in left:
			if not right.has(key) or not _same(left[key], right[key]):return false
		return true
	return left == right

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
