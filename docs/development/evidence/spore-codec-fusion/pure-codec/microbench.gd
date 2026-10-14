extends SceneTree
## INERT pure-codec timing draft; no native construction, frames or authority.
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Protocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const Fusion = preload("res://scripts/campaign/codec_exact_reference.gd")
const INPUT = "res://.cinder/spore-codec-microbench-prep/world-reference.exact.json"
const INPUT_SHA = "b59bd04872bb3ac56c5f632f6321c7ef65d846c4125e5c165c2f9e6c3017ca95"
const BATCHES = 8
const ITERATIONS = 128
const WARMUP = 16
const LIMIT_US = 20000000
var _value: Variant
var _mirror: Variant
var _wire: String
var _mirror_bytes: PackedByteArray
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _expect(ok: bool, label: String) -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		print("FAIL: " + label)
	return ok

func _unchanged() -> bool:
	return FileAccess.get_sha256(INPUT) == INPUT_SHA and Exact.stringify(_value) == _wire and var_to_bytes(_mirror) == _mirror_bytes

func _a(count: int) -> Dictionary:
	var matches: int = 0
	var errors: int = 0
	var started: int = Time.get_ticks_usec()
	for index: int in range(count):
		var error: String = Codec.value_error(_value)
		var matched: bool = error.is_empty() and Protocol._same_bits_reference(_value, _mirror)
		matches += int(matched)
		errors += int(not error.is_empty())
	var elapsed: int = Time.get_ticks_usec() - started
	return {"wall_us": elapsed, "matches": matches, "errors": errors}

func _b(count: int) -> Dictionary:
	var matches: int = 0
	var errors: int = 0
	var started: int = Time.get_ticks_usec()
	for index: int in range(count):
		var result: Dictionary = Fusion.checked_match(_value, _mirror)
		matches += int(result.matches)
		errors += int(not String(result.error).is_empty())
	var elapsed: int = Time.get_ticks_usec() - started
	return {"wall_us": elapsed, "matches": matches, "errors": errors}

func _run() -> void:
	var sources: Dictionary = {
		"res://scripts/campaign/exact_json.gd": "c383cbcc2391aadb4ef4c44e772ec4130038c84a7e074ea8889b56f5f08833fc",
		"res://scripts/campaign/snapshot_codec.gd": "36ac4a52b08020249e4282b2788f7e4bc9d1c4af7ad45fd50586e2385f6afbac",
		"res://scripts/campaign/codec_exact_reference.gd": "5c2e387254cc68edc636a5ff614cec707e110da50ba4a4588ce45274f70c29aa"}
	for path: String in sources:
		if not _expect(FileAccess.get_sha256(path) == sources[path], "exact selected pure source: " + path): _finish(); return
	var protocol_sha: String = FileAccess.get_sha256("res://scripts/environment/scheduler_spore_source_protocol.gd")
	if not _expect(protocol_sha in ["a01b5481e3d06f64f65973fff075c4cbe622e4a1129c1646ee228c103b8523b5", "2a624f1c3d63b262b622a9f2767a1f481ad76f2637292eb826512fe83edb1607"] and FileAccess.get_sha256(INPUT) == INPUT_SHA, "unchanged pure Protocol methods and exact captured input"): _finish(); return
	_wire = FileAccess.get_file_as_string(INPUT)
	var admitted: Dictionary = Exact.parse(_wire)
	if not _expect(admitted.get("accepted", false), "original Exact reader admits genuine captured world reference"): _finish(); return
	_value = admitted.value
	if not _expect(Codec.value_error(_value).is_empty() and Exact.stringify(_value) == _wire, "original Codec admission and literal Exact roundtrip"): _finish(); return
	_mirror = Protocol._compile_reference_bits(_value)
	_mirror_bytes = var_to_bytes(_mirror)
	var original: Dictionary = {"error": Codec.value_error(_value), "matches": Protocol._same_bits_reference(_value, _mirror)}
	if not _expect(Exact.stringify(original) == Exact.stringify(Fusion.checked_match(_value, _mirror)) and original.error == "" and original.matches == true and _unchanged(), "equal literal admitted result and unchanged input/mirror before timing"): _finish(); return
	var warm_a: Dictionary = _a(WARMUP)
	var warm_b: Dictionary = _b(WARMUP)
	if not _expect(warm_a.matches == WARMUP and warm_b.matches == WARMUP and warm_a.errors == 0 and warm_b.errors == 0 and _unchanged(), "untimed warmup returns original literal result without mutation"): _finish(); return
	var rows: Array = []
	var bounded_start: int = Time.get_ticks_usec()
	for batch: int in range(BATCHES):
		if not _expect(Time.get_ticks_usec() - bounded_start < LIMIT_US, "bounded same-process batches"): break
		var a: Dictionary
		var b: Dictionary
		if batch % 2 == 0:
			a = _a(ITERATIONS)
			b = _b(ITERATIONS)
		else:
			b = _b(ITERATIONS)
			a = _a(ITERATIONS)
		if not _expect(a.matches == ITERATIONS and b.matches == ITERATIONS and a.errors == 0 and b.errors == 0 and _unchanged(), "all literal admitted results and immutable input/mirror after batch%d" % batch): break
		rows.append({"batch": batch, "order": "AB" if batch % 2 == 0 else "BA", "iterations": ITERATIONS, "original_us": a.wall_us, "fused_us": b.wall_us})
	_expect(rows.size() == BATCHES and Time.get_ticks_usec() - bounded_start < LIMIT_US, "all alternating batches close within bound")
	for path: String in sources: _expect(FileAccess.get_sha256(path) == sources[path], "pure source bytes unchanged at closure: " + path)
	_expect(FileAccess.get_sha256("res://scripts/environment/scheduler_spore_source_protocol.gd") == protocol_sha and _unchanged(), "Protocol/input/mirror unchanged at closure")
	print("SPORE_CODEC_MICROBENCH " + JSON.stringify({"input_sha256": INPUT_SHA, "warmup_per_method": WARMUP, "batches": rows, "scope": "same-process pure-codec matched-reference cost only; no world getters/native authority/FPS"}))
	_finish()

func _finish() -> void:
	print("Spore codec microbenchmark: %d checks, %d failures; pure-codec timing only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
