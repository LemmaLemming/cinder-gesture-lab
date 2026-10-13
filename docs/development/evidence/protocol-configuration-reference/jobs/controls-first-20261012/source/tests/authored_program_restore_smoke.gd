extends "res://tests/authored_enemy_sequence_smoke.gd"
## Actual authored/captured readers; supplements the original native descriptors
## with error precedence and atomic immutable-reader restore controls.

func _test_transport(sequence, definition: Dictionary, guards: Dictionary) -> void:
	super._test_transport(sequence, definition, guards)
	var original: Dictionary = sequence.snapshot_state()
	var reader = Program.new()
	_expect(reader.restore_state(original, EPOCH, GENERATION), "authored restore control installs actual pure program")
	var immutable_reader = reader.get("_reader")
	for repeat: int in range(3):
		_expect(reader.restore_state(original, EPOCH, GENERATION) and is_same(reader.get("_reader"), immutable_reader) and reader.last_error.is_empty() and reader.last_snapshot_error.is_empty(), "identical restore retains actual immutable reader identity and clears diagnostics")
	var invalids: Array = []
	var bad: Dictionary = original.duplicate(true)
	bad.generation = float(GENERATION)
	invalids.append(bad)
	bad = original.duplicate(true)
	bad.timeline.source_ready_s += 0.000000001
	invalids.append(bad)
	bad = original.duplicate(true)
	bad.definition.raw_role.raw_damage = -0.0
	invalids.append(bad)
	bad = original.duplicate(true)
	bad.api_revision = StringName(Authored.API_REVISION)
	invalids.append(bad)
	for malformed: Dictionary in invalids:
		var independent = Program.new()
		var expected: String = independent.snapshot_error(malformed, EPOCH, GENERATION)
		_expect(not expected.is_empty(), "independent legacy validation rejects malformed authored control")
		_expect(not independent.restore_state(malformed, EPOCH, GENERATION) and independent.last_snapshot_error == expected and independent.snapshot_state().is_empty(), "fresh invalid authored restore preserves validation precedence and empty public state")
		_expect(not reader.restore_state(malformed, EPOCH, GENERATION) and reader.last_snapshot_error == expected and is_same(reader.get("_reader"), immutable_reader) and Authored.exact_equal(reader.snapshot_state(), original), "configured invalid authored restore preserves validation precedence, identity and full immutable state")
	var altered: Dictionary = definition.duplicate(true)
	altered.slash.visual_duration_s = _one_bit(altered.slash.visual_duration_s)
	var other = Authored.new()
	_expect(other.configure(SEQUENCE_ID, altered, SOURCE_ID, EPOCH, GENERATION, "standard", guards), "alternate authored immutable definition is separately valid")
	var direct = Authored.new()
	direct.restore_state(original, EPOCH, GENERATION)
	var direct_result: bool = direct.restore_state(other.snapshot_state(), EPOCH, GENERATION)
	_expect(not direct_result and not reader.restore_state(other.snapshot_state(), EPOCH, GENERATION) and reader.last_snapshot_error == direct.last_snapshot_error and Authored.exact_equal(reader.snapshot_state(), original), "valid alternate authored definition preserves original immutable rejection and state")
	_expect(reader.restore_state(original, EPOCH, GENERATION) and reader.last_snapshot_error.is_empty(), "rejected controls do not poison subsequent genuine identical restore")
