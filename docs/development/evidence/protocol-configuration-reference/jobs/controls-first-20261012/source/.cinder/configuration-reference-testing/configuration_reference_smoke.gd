extends "res://tests/scheduler_spore_reference_smoke.gd"
## SOURCE-ONLY private proposal; UNPARSED/UNEXECUTED until Root selects it.
## Override the suite: inherited native world/helpers only, never run208/527.
## TEST-only comparison metadata, getter-return mutations and private fallback
## controls. Real Player/Scheduler/capsule/codec; no HP, clock or lease seeds.

class ConfigurationProbeSource extends NativeActor:
	var getter_mode: String = ""
	var alias_on_response: bool = false
	var alias_mutations: int = 0
	var probe_trace: Array[String] = []
	var returned_configuration: Dictionary = {}

	func _ready() -> void:
		super._ready()
		# Immutable TEST-only data owned by this real source recipe. Native codec
		# validates its complete configuration; all role/body/HP data stay original.
		_configuration["comparison_fixture"] = {"scalar": "0000000000000080".hex_decode().decode_double(0), "point": [1.0, 2.0, 3.0], "label": "native configuration"}

	func clear_probe_trace() -> void:
		probe_trace.clear()

	func get_spore_native_bindings() -> Dictionary:
		probe_trace.append("bindings")
		var native: Dictionary = super.get_spore_native_bindings()
		var data: Dictionary = native.configuration.comparison_fixture
		match getter_mode:
			"bit":
				var bytes := PackedByteArray()
				bytes.resize(8)
				bytes.encode_double(0, data.point[1])
				bytes[0] = bytes[0] ^ 1
				data.point[1] = bytes.decode_double(0)
			"zero": data.scalar = 0.0
			"int": data.point[1] = 2
			"key":
				var value: Variant = data.scalar
				data.erase("scalar")
				data[StringName("scalar")] = value
			"native": data.point = Vector3(1.0, 2.0, 3.0)
			"cycle":
				var cyclic: Array = []
				cyclic.append(cyclic)
				data.point = cyclic
			"oversized": data.label = "x".repeat(Protocol.MAX_CONFIGURATION_BYTES + 1)
		returned_configuration = native.configuration
		return native

	func get_spore_response_state() -> Dictionary:
		probe_trace.append("response")
		if alias_on_response:
			alias_on_response = false
			alias_mutations += 1
			# Mutate only the prior returned deep copy during the actual later
			# owned callback. Source configuration/native resources stay untouched.
			returned_configuration.comparison_fixture.scalar = 0.0
		return super.get_spore_response_state()

	func discard_returned_probe() -> void:
		var value: Variant = returned_configuration.get("comparison_fixture", {}).get("point")
		if getter_mode == "cycle" and value is Array:
			value.clear() # Retire only the intentionally cyclic TEST return.
		returned_configuration = {}
		getter_mode = ""


class ConfigurationFallbackProtocol extends Protocol:
	var configuration_calls: int = 0
	func _same_configuration_reference(actual: Variant, expected_json: String) -> bool:
		configuration_calls += 1
		return super._same_configuration_reference(actual, expected_json)


func _run() -> void:
	create_timer(60.0, true).timeout.connect(func() -> void:
		push_error("Configuration reference focused watchdog expired")
		quit(1)
	)
	var capability = Protocol.new()
	if not capability.has_method("_same_configuration_reference"):
		_expect(false, "Root must select candidate helper before executing this NEW scope")
		_finish()
		return
	var w: Dictionary = await _configuration_world(false, false)
	if w.ready:
		_configuration_selection(w)
		_configuration_pure_differentials()
		_configuration_getter_boundaries(w)
	await _dispose(w)
	await _configuration_alias_boundary()
	await _configuration_subclass()
	_finish()


func _configuration_world(alias: bool, derived: bool) -> Dictionary:
	var w: Dictionary = await _world(false)
	if not w.ready: return w
	paused = true
	var actual_spawn: Vector3 = w.source.global_position
	w.root.remove_child(w.source)
	w.source.free()
	var raw: Node = ConfigurationProbeSource.new()
	var source: CharacterBody3D = raw as CharacterBody3D
	source.name = "ConfigurationSource"
	source.position = actual_spawn
	w.root.add_child(source)
	source.call("bind_native", w.scheduler, w.hero)
	w.source = source
	w.bindings.sources["native-source"] = source
	# Genuine new native capsule settles through actual physics, never a seeded
	# grounded flag or copied controller. No attack/field activation is requested.
	paused = false
	await _ticks(5)
	paused = true
	var protocol: CinderSchedulerSporeSourceProtocol = ConfigurationFallbackProtocol.new() if derived else Protocol.new()
	w.protocol = protocol
	w.bindings.source_protocols["native-source"] = protocol
	source.set("alias_on_response", alias)
	source.call("clear_probe_trace")
	w.ready = protocol.configure(source, w.scheduler, w.hero, "native-source", "controller", "hero", {"world_root": w.root, "floors": {"ground": w.floor}})
	_expect(w.ready, "real replacement source/Hero/Scheduler/capsule/owned codec configures: " + protocol.last_error)
	_expect(source.is_on_floor() and source.get("hp") == 20.0 and w.hero.hp == w.hero.max_hp, "source setup retains genuine native floor and original source20/Player full HP")
	return w


func _configuration_selection(w: Dictionary) -> void:
	var unit: Dictionary = _context(w)
	_expect(not unit.sources["native-source"].is_empty() and w.protocol.binding_error().is_empty(), "healthy metadata recipe still has a genuine complete native paused pair")
	var before: String = _configuration_wire(w)
	var original: Dictionary = w.source.get("_configuration").duplicate(true)
	var wire: String = Exact.stringify(original)
	var retained: Dictionary = w.protocol.get("_configuration_reference")
	var available: bool = retained.get("value") is Dictionary and retained.get("json") is String and retained.get("bits") is Dictionary
	_expect(available and not before.is_empty() and not wire.is_empty() and retained.get("json") == wire, "actual original admitted configuration enables the dedicated mirror")
	if not available: return
	_expect((w.protocol.get("_comparison_references") as Dictionary).size() == 3, "existing world/floor/body reference map remains exactly3")
	_expect(w.protocol._same_configuration_reference(original, wire) == (Exact.stringify(original) == wire), "genuine exact configuration selection agrees with literal old equality")
	for mode: String in ["missing-cache", "missing-bits", "wrong-bits", "wrong-root", "different-receipt", "wrong-receipt-type", "wrong-value"]:
		var altered: Dictionary = retained.duplicate(true)
		match mode:
			"missing-cache": altered = {}
			"missing-bits": altered.erase("bits")
			"wrong-bits": altered.bits = PackedByteArray([1, 2, 3])
			"wrong-root": altered.bits = []
			"different-receipt": altered.json = "malformed retained receipt"
			"wrong-receipt-type": altered.json = StringName(wire)
			"wrong-value": altered.value = []
		w.protocol.set("_configuration_reference", altered)
		_expect(w.protocol._same_configuration_reference(original, wire) == (Exact.stringify(original) == wire), mode + " preserves literal old fallback without granting a native bind")
		w.protocol.set("_configuration_reference", retained)
	var unrelated: Dictionary = {"unrelated": [-0.0, 1, "different"]}
	var unrelated_wire: String = Exact.stringify(unrelated)
	_expect(not unrelated_wire.is_empty() and w.protocol._same_configuration_reference(unrelated, unrelated_wire), "different expected receipt uses original actual serialization")
	var previous_json: String = w.protocol.get("_configuration_json")
	for expected: String in ["", "not an exact envelope", unrelated_wire]:
		w.protocol.set("_configuration_json", expected)
		var actual: Variant = {"native": Vector3.ZERO} if expected.is_empty() else original
		_expect(w.protocol._same_configuration_reference(actual, w.protocol.get("_configuration_json")) == (Exact.stringify(actual) == expected), "corrupt/empty private receipt retains exact legacy expression; no native admission claim")
		if expected.is_empty():
			_expect(w.protocol._same_configuration_reference(actual, expected), "unencodable actual plus empty expected is TRUE under the old expression")
	w.protocol.set("_configuration_json", previous_json)
	var after: String = _configuration_wire(w)
	_expect(not after.is_empty() and after == before and w.protocol.binding_error().is_empty(), "TEST-only cache absence/receipt controls restore exact native state and private references")
	print("CONFIGURATION_REFERENCE_SELECTION_BEFORE " + before)
	print("CONFIGURATION_REFERENCE_SELECTION_AFTER " + after)


func _configuration_pure_differentials() -> void:
	var patterns: Array[String] = ["0000000000000000", "0000000000000080", "0100000000000000", "0100000000000080", "ffffffffffff0f00", "ffffffffffff0f80", "0000000000001000", "0000000000001080", "000000000000f03f", "000000000000f0bf", "010000000000f03f", "010000000000f0bf", "ffffffffffffef7f", "ffffffffffffefff"]
	for expected_pattern: String in patterns:
		var expected_value: float = expected_pattern.hex_decode().decode_double(0)
		_expect(_reference_double_bytes(expected_value).hex_encode() == expected_pattern, "binary64 reference is constructed from genuine bytes: " + expected_pattern)
		for actual_pattern: String in patterns:
			var actual_value: float = actual_pattern.hex_decode().decode_double(0)
			_configuration_differential("scalar" + actual_pattern + "/" + expected_pattern, {"value": actual_value}, {"value": expected_value})
			for index: int in range(3):
				var point: Array = [1.0, 2.0, 3.0]
				var other: Array = point.duplicate()
				point[index] = expected_value
				other[index] = actual_value
				_configuration_differential("triplet%d" % index, {"point": other}, {"point": point})
	var typed: Array[float] = [1.0, 2.0, 3.0]
	var ordinary: Dictionary = {"point": [1.0, 2.0, 3.0], "label": "港🙂", "integer": 1}
	_configuration_differential("typed/reordered", {"integer": 1, "label": "港🙂", "point": typed}, ordinary)
	var typed_dictionary: Dictionary[String, Variant] = {"point": typed, "label": "港🙂", "integer": 1}
	_configuration_differential("typed dictionary metadata", typed_dictionary, ordinary)
	for native: Variant in [Vector3.ONE, PackedFloat64Array([1.0, 2.0, 3.0]), PackedByteArray([1, 2, 3]), StringName("港🙂"), null, true, NAN, INF, -INF]:
		_configuration_differential("hostile native/type", {"point": native, "label": "港🙂", "integer": 1}, ordinary)
	var wrong_key: Dictionary = {StringName("point"): [1.0, 2.0, 3.0], "label": "港🙂", "integer": 1}
	_configuration_differential("StringName key", wrong_key, ordinary)
	_configuration_differential("int/float", {"integer": 1.0}, {"integer": 1})
	_configuration_differential("unsafe int", {"integer": Exact.MAX_INTEGER + 1}, {"integer": Exact.MAX_INTEGER})
	var object := RefCounted.new()
	_configuration_differential("object", {"value": object}, {"value": {}})
	var called: Array = []
	var callable: Callable = func() -> void: called.append(true)
	_configuration_differential("Callable", {"value": callable}, {"value": []})
	_expect(called.is_empty(), "foreign comparison never invokes a Callable")
	var cycle: Array = []
	cycle.append(cycle)
	_configuration_differential("foreign cycle", {"value": cycle}, {"value": [[]]})
	cycle.clear()
	var shared: Array = [1.0, 2.0, 3.0]
	_configuration_differential("repeated alias", {"value": [shared, shared]}, {"value": [shared.duplicate(), shared.duplicate()]})
	_configuration_differential("empty configuration", {}, {})
	var deep: Variant = 1.0
	for index: int in range(63): deep = [deep]
	_configuration_differential("admitted depth64 root", {"value": deep}, {"value": deep})
	var too_deep: Variant = [deep]
	_configuration_differential("depth mismatch", {"value": too_deep}, {"value": deep})
	var entries: Array = []
	entries.resize(Exact.MAX_ENTRIES)
	# Entry maximum is a PURE8MiB helper control; it is not a native65KiB
	# configuration bind, and no unadmitted value is installed in the cache.
	_configuration_differential("entry bound", {"value": entries}, {"value": entries})
	var too_many: Array = entries.duplicate()
	too_many.append(null)
	_configuration_differential("over entry bound", {"value": too_many}, {"value": entries})
	var small: Dictionary = {"label": "a".repeat(60000)}
	_expect(Exact.stringify(small).to_utf8_buffer().size() <= Protocol.MAX_CONFIGURATION_BYTES, "large same-type reference fits original configuration ceiling")
	_configuration_differential("configuration-size permitted", small, small)
	_configuration_differential("oversized foreign String", {"label": "a".repeat(Protocol.MAX_CONFIGURATION_BYTES + 1)}, small)


func _configuration_differential(label: String, candidate: Variant, reference: Dictionary) -> void:
	var reference_wire: String = Exact.stringify(reference)
	_expect(not reference_wire.is_empty(), label + " reference first passes ORIGINAL complete Exact admission")
	if reference_wire.is_empty(): return
	var expected: bool = Exact.stringify(candidate) == reference_wire
	var actual: bool = Protocol._same_bits_reference(candidate, Protocol._compile_reference_bits(reference))
	_expect(actual == expected and actual == Protocol._same_closed_reference(candidate, reference), label + " compiled pure comparison equals literal original serializer and old finite comparer")


func _configuration_getter_boundaries(w: Dictionary) -> void:
	var events: Array = []
	w.source.state_changed.connect(func() -> void: events.append("state"))
	w.source.hit_resolved.connect(func(value: Dictionary) -> void: events.append(["hit", value]))
	w.scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: events.append([id, reason]))
	for mode: String in ["bit", "zero", "int", "key", "native", "cycle", "oversized"]:
		var before: String = _configuration_wire(w)
		w.protocol.last_error = "configuration-pure-retained"
		# Baseline diagnostics are deliberately retained by the pure guard.
		before = _configuration_wire(w)
		w.source.set("getter_mode", mode)
		w.source.call("clear_probe_trace")
		var error: String = w.protocol.binding_error()
		var trace: Array = w.source.get("probe_trace").duplicate()
		_expect(error == "Owned immutable source/controller/codec/configuration binding changed" and trace == ["bindings"], mode + " actual fresh getter mutation refuses at original config boundary before owned response")
		w.source.call("discard_returned_probe")
		var after: String = _configuration_wire(w)
		_expect(not before.is_empty() and not after.is_empty() and after == before and events.is_empty() and w.protocol.last_error == "configuration-pure-retained", mode + " guard preserves actual native packet/resources/clocks/diagnostics and emits no callbacks")
		w.source.call("clear_probe_trace")
		_expect(w.protocol.binding_error().is_empty() and w.source.get("probe_trace") == ["bindings", "response"], mode + " retiring only injected return recovers actual original native binding/order")
		print("CONFIGURATION_REFERENCE_GETTER " + mode + " BEFORE " + before)
		print("CONFIGURATION_REFERENCE_GETTER " + mode + " AFTER " + after)


func _configuration_alias_boundary() -> void:
	var w: Dictionary = await _configuration_world(true, false)
	if not w.ready:
		await _dispose(w)
		return
	var original: Dictionary = w.source.get("_configuration")
	var late: Dictionary = w.protocol.get("_configuration")
	var retained: Dictionary = w.protocol.get("_configuration_reference")
	var original_wire: String = Exact.stringify(original)
	var available: bool = retained.get("value") is Dictionary and retained.get("bits") is Dictionary and retained.get("json") is String
	_expect(available and not original_wire.is_empty(), "alias control requires actual staged early reference and nonempty original receipt")
	if not available or original_wire.is_empty():
		await _dispose(w)
		return
	_expect(w.source.get("alias_mutations") == 1 and original_wire == w.protocol.get("_configuration_json"), "actual later response mutates one returned alias after original wire admission")
	_expect(Exact.stringify(retained.value) == original_wire and Protocol._same_bits_reference(original, retained.bits), "early private copy/bits remain the original admitted recipe despite later alias mutation")
	_expect(Exact.stringify(late) != original_wire and late.comparison_fixture.scalar == 0.0, "old late _configuration copy remains genuinely callback-mutated; optimization does not repair it")
	_expect(w.protocol._same_configuration_reference(original, original_wire) and w.protocol.binding_error().is_empty(), "fresh current getter configuration still has the literal original equality result")
	var pair: Dictionary = {"controllers": {"controller": w.scheduler.snapshot_state(_scheduler_bindings(w))}, "players": {"hero": w.hero.snapshot_state()}}
	_expect(w.protocol.current_unit(pair).is_empty(), "impure alias recipe cannot acquire complete paired capture; original late-copy custody is preserved")
	print("CONFIGURATION_REFERENCE_ALIAS " + Exact.stringify({"original": original, "early": retained.value, "late": late, "descriptor": w.protocol.binding_state(), "mutation_count": w.source.get("alias_mutations")}))
	await _dispose(w)


func _configuration_subclass() -> void:
	var w: Dictionary = await _configuration_world(false, true)
	if w.ready:
		var before: String = _configuration_wire(w)
		_expect((w.protocol.get("_configuration_reference") as Dictionary).is_empty(), "legitimate Protocol subclass installs no exact-native configuration cache")
		var configuration: Dictionary = w.source.get("_configuration")
		var wire: String = Exact.stringify(configuration)
		_expect(w.protocol._same_configuration_reference(configuration, wire) == (Exact.stringify(configuration) == wire), "subclass preserves original literal helper fallback")
		var invalid: Dictionary = {"object": RefCounted.new()}
		_expect(w.protocol._same_configuration_reference(invalid, ""), "subclass preserves original empty/unencodable TRUE semantics")
		_expect(w.protocol.binding_error().is_empty() and int(w.protocol.get("configuration_calls")) > 0, "legitimate virtual helper signature dispatch remains supported at native binding")
		var after: String = _configuration_wire(w)
		_expect(not before.is_empty() and not after.is_empty() and after == before, "subclass pure fallback retains exact native packet and diagnostics")
	await _dispose(w)


func _configuration_wire(w: Dictionary) -> String:
	# Diagnostic native64 encoding only. No getter under mutation is invoked.
	var saved_scheduler: Dictionary = w.scheduler.snapshot_state(_scheduler_bindings(w))
	var saved_player: Dictionary = w.hero.snapshot_state()
	var saved_source: Dictionary = w.source.spore_snapshot_state(saved_scheduler, saved_player)
	if saved_scheduler.is_empty() or saved_player.is_empty() or saved_source.is_empty(): return ""
	var collision: CollisionShape3D = w.source.get_node("BodyCollision")
	var observation: Dictionary = {"paused": paused, "source": saved_source, "player": saved_player, "scheduler": saved_scheduler, "source_native": [w.source.get_instance_id(), w.source.get_script().get_instance_id(), w.source.global_transform, w.source.velocity, collision.get_instance_id(), collision.shape.get_instance_id(), Protocol._body_properties(w.source, collision)], "player_native": [w.hero.get_instance_id(), w.hero.get_script().get_instance_id(), w.hero.global_transform, w.hero.velocity], "controller_native": [w.scheduler.get_instance_id(), w.scheduler.get_script().get_instance_id(), w.scheduler.get_clock()], "floor_native": [w.floor.collision.get_instance_id(), w.floor.collision.shape.get_instance_id(), w.floor.collision.global_transform, w.floor.collision.shape.size], "descriptor": w.protocol.binding_state(), "configuration_json": w.protocol.get("_configuration_json"), "configuration": w.protocol.get("_configuration"), "diagnostics": [w.protocol.last_error, w.scheduler.last_error, w.scheduler.last_snapshot_error]}
	return Exact.stringify(_reference_observed_value(observation))


func _finish() -> void:
	print("Protocol configuration reference focused smoke: %d checks, %d failures; native configured comparator/getter alias/fallback/purity controls ONLY; no208/527 rerun, cost or gameplay claim" % [checks, failures])
	quit(0 if failures == 0 else 1)
