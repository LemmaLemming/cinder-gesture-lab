class_name CinderAuthoredEchoCycleJournal
extends RefCounted
## Closed pure source-cycle history. Parsing never authenticates actual source,
## Script, Scheduler/Hero handles, native admission or historical callbacks.

const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Program = preload("res://scripts/combat/replay_program.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const API_REVISION: String = "authored-echo-cycle-journal-1"
const MAX_SOURCES: int = 64
const MAX_TERMINAL_RECEIPTS: int = 64
const KEYS: Array[String] = ["api_revision", "schema_version", "sources"]
const SOURCE_KEYS: Array[String] = ["source_id", "source_epoch", "generation", "stage", "sequence", "terminal_receipts"]


static func snapshot_error(journal: Dictionary, aggregate_clock_s: float) -> String:
	# Includes Exact.stringify <= one MiB; no deep copies before whole-tree bounds.
	var error: String = Receipt.transport_error(journal)
	if error.is_empty(): error = Codec.keys_error(journal, KEYS)
	if not error.is_empty(): return error
	if journal.api_revision != API_REVISION or not journal.schema_version is int or journal.schema_version != 1 or not journal.sources is Array or journal.sources.size() > MAX_SOURCES or not Receipt.clock_valid(aggregate_clock_s):
		return "Closed bounded authored source journal and native aggregate clock required"
	var source_ids: Dictionary = {}
	var sequence_ids: Dictionary = {}
	var playback_ids: Dictionary = {}
	var reservation_ids: Dictionary = {}
	for value: Variant in journal.sources:
		if not value is Dictionary or not Codec.keys_error(value, SOURCE_KEYS).is_empty() or not Receipt.stable_id(value.source_id) or not Receipt.stable_id(value.source_epoch) or not value.generation is int or not Codec.is_integer(value.generation, 1, MAX_TERMINAL_RECEIPTS) or not value.stage is String or value.stage not in ["running", "terminal", "cycle_ready"] or not value.sequence is Dictionary or not value.terminal_receipts is Array or value.terminal_receipts.size() > MAX_TERMINAL_RECEIPTS:
			return "Typed closed source identity/stage/program/history required"
		if source_ids.has(value.source_id): return "Each stable source has exactly one journal entry"
		source_ids[value.source_id] = true
		if value.sequence.get("api_revision") != Authored.API_REVISION:
			return "Captured/foreign programs are not authored source cycles"
		var reader = Program.new()
		if not reader.restore_state(value.sequence, value.source_epoch, value.generation) or not reader.is_authored_enemy():
			return "Current journal program must be canonical enemy authored: " + reader.last_snapshot_error
		var current: Dictionary = reader.snapshot_state()
		if current.source_id != value.source_id: return "Current source program differs from the journal entry"
		var required_count: int = value.generation if value.stage == "terminal" else value.generation - 1
		if value.terminal_receipts.size() != required_count:
			return "Terminal generations must be the complete contiguous history from one"
		var previous: Dictionary = {}
		for index: int in range(value.terminal_receipts.size()):
			var terminal: Variant = value.terminal_receipts[index]
			if not terminal is Dictionary: return "Closed terminal receipt required"
			error = Receipt.snapshot_error(terminal)
			if not error.is_empty(): return "Invalid original terminal history: " + error
			if terminal.generation != index + 1 or terminal.source_id != value.source_id or terminal.source_epoch != value.source_epoch or float(terminal.terminal_at_s) > aggregate_clock_s or not _same_recipe(terminal.sequence, current):
				return "History must retain every generation and fixed source recipe/profile/world"
			if not previous.is_empty() and (terminal.hero_id != previous.hero_id or float(terminal.exchange.start_s) < float(previous.exchange.cooldown_until_s) or float(terminal.exchange.start_s) < float(previous.terminal_at_s) or float(terminal.exchange.cooldown_until_s) < float(previous.exchange.cooldown_until_s)):
				return "Next admission cannot replace Hero, bypass original cooldown or precede retirement"
			if sequence_ids.has(terminal.sequence.sequence_id) or playback_ids.has(terminal.playback_id) or reservation_ids.has(terminal.exchange.id):
				return "Sequence, playback and reservation identities cannot reuse retired identities"
			sequence_ids[terminal.sequence.sequence_id] = true
			playback_ids[terminal.playback_id] = true
			reservation_ids[terminal.exchange.id] = true
			previous = terminal
		if value.stage == "terminal":
			if not Authored.exact_equal(previous.sequence, value.sequence): return "Current terminal program must be the last exact original receipt"
		elif sequence_ids.has(current.sequence_id):
			return "A prepared/admitted cycle must use a fresh sequence identity"
		else:
			sequence_ids[current.sequence_id] = true
		if value.stage in ["running", "cycle_ready"] and not previous.is_empty() and aggregate_clock_s < float(previous.exchange.cooldown_until_s):
			return "Next-generation preparation/admission waits for original actual cooldown"
	return ""


static func validated_copy(journal: Dictionary, aggregate_clock_s: float) -> Dictionary:
	return journal.duplicate(true) if snapshot_error(journal, aggregate_clock_s).is_empty() else {}


static func _same_recipe(left: Dictionary, right: Dictionary) -> bool:
	# Called only after both whole programs passed their canonical readers.
	for key: String in ["source_id", "source_epoch", "profile_id", "definition", "resolved_role", "world", "authored"]:
		if not Authored.exact_equal(left[key], right[key]): return false
	return true
