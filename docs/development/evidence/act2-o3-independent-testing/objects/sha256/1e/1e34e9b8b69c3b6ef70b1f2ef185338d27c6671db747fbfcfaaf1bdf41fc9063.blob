extends SceneTree
## TEST ONLY pure terminal/journal codec controls. Native floor fingerprints and
## authored programs are genuine. The exchanges, contact/attempt latches and
## historical clocks below are HAND-BUILT PURE DATA, not Scheduler admissions,
## HP, native repeated cycles or authenticated gameplay history. The one actual
## Player capture is only a captured-provenance refusal control.

const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Journal = preload("res://scripts/combat/authored_echo_cycle_journal.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Cursor = preload("res://scripts/combat/replay_cursor.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Captured = preload("res://scripts/combat/replay_sequence.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const SOURCE_ID: String = "test-only/lifecycle-source"
const EPOCH: String = "test-only/lifecycle-attempt"
const HERO_ID: String = "test-only/hero"
const DISPATCH_GRACE_S: float = 0.05
const ACTIVE_MARGIN_S: float = 0.001

var _checks: int = 0
var _failures: int = 0
var _arena: Dictionary = {}
var _guards: Dictionary = {}
var _definition: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_arena = await _native_arena()
	_guards = _native_guards()
	_definition = _native_definition(_arena.source.global_position)
	_expect(_guards.collision_fingerprint.colliders.size() == 2 and _guards.floor_signature.size() == 1, "native floor/stone descriptors come from public Scheduler/Footprint queries")
	var first: Dictionary = _receipt(_program(1), 0.0, 1, "complete")
	if first.is_empty():
		await _finish()
		return
	_complete_controls(first)
	_cancel_controls(first)
	_receipt_negatives(first)
	_journal_controls(first)
	_hostile_inputs(first)
	await _captured_control(first)
	await _finish()


func _complete_controls(first: Dictionary) -> void:
	_accept_receipt(first, "PURE DATA completion retains canonical original clocks and consumed prefix")
	var wire: String = Exact.stringify(first)
	var parsed: Dictionary = Exact.parse(wire)
	_expect(parsed.get("accepted", false) and Receipt.snapshot_error(parsed.get("value", {})).is_empty() and Exact.stringify(parsed.value) == wire, "exact tagged receipt roundtrip preserves every native scalar type/bit")
	var copy: Dictionary = Receipt.validated_copy(first)
	copy.exchange.adapter.sequence.definition.raw_role.max_hp = 999.0
	copy.opportunities[0].contact = false
	copy.cursor.executed_events.clear()
	_expect(Exact.stringify(first) == wire and not copy.is_empty(), "validated copy cannot mutate original nested program/prefix/opportunity")
	var miss: Dictionary = first.duplicate(true)
	miss.opportunities[0].contact = false
	miss.opportunities[0].damage_attempted = false
	_accept_receipt(miss, "PURE DATA missed completed opportunity is consumed without a damage attempt")
	var retimed: Dictionary = _receipt(_program(1), 4.0, 2, "complete", "", "", 0.0, 0.2)
	_accept_receipt(retimed, "PURE DATA later actual-lock timetable retains full warning and inverse origin")
	var short_definition: Dictionary = _definition.duplicate(true)
	short_definition.slash.commitment_duration_s = 0.02
	short_definition.raw_role.active_s = float(short_definition.route[1].at_s) + 0.02
	var short: Dictionary = _receipt(_program(1, "standard", short_definition), 0.0, 21, "complete")
	_accept_receipt(short, "PURE DATA short commitment keeps the full dispatch-danger deadline")
	_expect(short.exchange.active_until_s == short.opportunities[0].scheduled_at_s + DISPATCH_GRACE_S + ACTIVE_MARGIN_S and short.exchange.active_until_s > short.sequence.timeline.replay_until_s, "short cosmetic/commitment end cannot truncate the original dispatch-grace window")
	var clock: float = _arena.scheduler.get_clock()
	var pose: Vector3 = _arena.source.global_position
	_arena.scheduler.last_error = "codec-request-sentinel"
	_arena.scheduler.last_snapshot_error = "codec-snapshot-sentinel"
	Receipt.snapshot_error(first)
	Journal.snapshot_error(_journal([_entry(first.sequence, "terminal", [first])]), first.terminal_at_s + 100.0)
	_expect(paused and _arena.scheduler.get_clock() == clock and _arena.source.global_position == pose and _arena.scheduler.reservations().is_empty() and _arena.scheduler.last_error == "codec-request-sentinel" and _arena.scheduler.last_snapshot_error == "codec-snapshot-sentinel", "pure history validation creates no live reservation and changes no native clock/source/diagnostic")


func _cancel_controls(first: Dictionary) -> void:
	var preview: Dictionary = _receipt(_program(1), 0.0, 3, "cancelled", "preview cancelled")
	_accept_receipt(preview, "PURE DATA unarmed cancellation contains no fabricated attack prefix")
	_expect(not preview.cursor.armed and preview.opportunities.is_empty() and preview.pending_delivery.is_empty(), "preview carries no attack/contact/pending delivery")
	_accept_receipt(_receipt(_program(1), 2.0, 4, "cancelled", "locked cancellation", "before_event"), "PURE DATA locked pre-event cancellation retains no due attack")
	for stage: String in ["present", "damage", "notify"]:
		var pending: Dictionary = _receipt(_program(1), 0.0, 5, "cancelled", "held observer cancelled", stage, 0.049)
		_accept_receipt(pending, "PURE DATA inert " + stage + " suffix retains near-grace original receipt")
		var parsed: Dictionary = Exact.parse(Exact.stringify(pending))
		_expect(parsed.get("accepted", false) and Receipt.snapshot_error(parsed.get("value", {})).is_empty(), "inert " + stage + " suffix survives exact transport")
		var bad: Dictionary = pending.duplicate(true)
		bad.opportunities[0].damage_attempted = not bad.opportunities[0].damage_attempted
		_reject_receipt(bad, stage + " cannot rewrite whether contact damage was attempted", first)
		bad = pending.duplicate(true)
		bad.pending_delivery.cue_phases[0] = "active"
		_reject_receipt(bad, "retired pending contact cannot reopen a damaging cue", first)
	var delivered: Dictionary = _receipt(_program(1), 0.0, 6, "cancelled", "cancel after notification", "delivered", 0.025)
	_accept_receipt(delivered, "PURE DATA delivered cancellation preserves attempt without pending replay")
	var later: Dictionary = delivered.duplicate(true)
	later.terminal_at_s += 0.125
	later.cancellation.cancelled_at_s = later.terminal_at_s
	_accept_receipt(later, "PURE DATA later cancellation retains its earlier frozen canonical cursor")
	var bad: Dictionary = delivered.duplicate(true)
	bad.terminal_at_s = bad.cursor_clock_s - 0.001
	bad.cancellation.cancelled_at_s = bad.terminal_at_s
	_reject_receipt(bad, "terminal cannot precede its consumed cursor", first)
	for field: String in ["index", "duplicate", "callback", "empty", "extra"]:
		bad = _receipt(_program(1), 0.0, 7, "cancelled", "held observer", "damage")
		match field:
			"index": bad.pending_delivery.events[0].event_index = 1
			"duplicate": bad.pending_delivery.events.append({"event_index": 0, "stage": "present"})
			"callback": bad.pending_delivery.state_pending = true
			"empty": bad.pending_delivery.events.clear()
			"extra": bad.pending_delivery["contact_override"] = true
		_reject_receipt(bad, "inert closed pending suffix rejects " + field, first)


func _receipt_negatives(first: Dictionary) -> void:
	for field: String in ["api", "schema_float", "generation_float", "generation_zero", "generation_skip", "source", "epoch", "extra", "missing", "outcome", "reason", "pending_complete", "early_complete", "integer_clock", "cursor_clock_bit", "cursor_phase", "prefix_omitted", "prefix_duplicate", "opportunity_omitted", "opportunity_hero", "opportunity_clock_bit", "opportunity_scheduled_bit", "opportunity_extra", "contact_integer", "prefix_extra", "prefix_scheduled_bit", "attempt_without_contact", "late_dispatch", "knot_bit", "opening_bit", "profile", "world_bit", "adapter_generation_float", "record_damage_bit", "fake_capture", "fake_gear", "fake_publication"]:
		var bad: Dictionary = first.duplicate(true)
		match field:
			"api": bad.api_revision = "foreign-terminal"
			"schema_float": bad.schema_version = 1.0
			"generation_float": bad.generation = 1.0
			"generation_zero": bad.generation = 0
			"generation_skip": bad.generation = 3
			"source": bad.source_id = "test-only/foreign-source"
			"epoch": bad.source_epoch = "test-only/foreign-epoch"
			"extra": bad["lifecycle"] = {}
			"missing": bad.erase("opportunities")
			"outcome": bad.outcome = "running"
			"reason": bad.reason = "completion cannot become cancellation"
			"pending_complete": bad.pending_delivery = {"events": [], "visual_next_cue": 0, "visuals_pending": false, "state_pending": false, "cue_phases": ["clear"]}
			"early_complete":
				bad.terminal_at_s = first.exchange.recovery_until_s - 0.001
				bad.cursor_clock_s = bad.terminal_at_s
				bad.cursor.last_advanced_clock_s = bad.terminal_at_s
			"integer_clock": bad.terminal_at_s = 4
			"cursor_clock_bit": bad.cursor_clock_s = _one_bit(bad.cursor_clock_s)
			"cursor_phase": bad.cursor.phase = "active"
			"prefix_omitted":
				bad.cursor.next_event_index = 0
				bad.cursor.executed_events.clear()
				bad.opportunities.clear()
			"prefix_duplicate":
				bad.cursor.executed_events.append(bad.cursor.executed_events[0].duplicate(true))
				bad.opportunities.append(bad.opportunities[0].duplicate(true))
				bad.cursor.next_event_index = 2
			"opportunity_omitted": bad.opportunities.clear()
			"opportunity_hero": bad.opportunities[0].hero_id = "test-only/other-hero"
			"opportunity_clock_bit": bad.opportunities[0].dispatch_clock_s = _one_bit(bad.opportunities[0].dispatch_clock_s)
			"opportunity_scheduled_bit": bad.opportunities[0].scheduled_at_s = _one_bit(bad.opportunities[0].scheduled_at_s)
			"opportunity_extra": bad.opportunities[0]["hp_after"] = 0.0
			"contact_integer": bad.opportunities[0].contact = 1
			"prefix_extra": bad.cursor.executed_events[0]["damage"] = 4.0
			"prefix_scheduled_bit": bad.cursor.executed_events[0].scheduled_at_s = _one_bit(bad.cursor.executed_events[0].scheduled_at_s)
			"attempt_without_contact": bad.opportunities[0].contact = false
			"late_dispatch":
				bad.opportunities[0].dispatch_clock_s = bad.opportunities[0].scheduled_at_s + DISPATCH_GRACE_S + 0.0001
				bad.cursor.executed_events[0].dispatch_clock_s = bad.opportunities[0].dispatch_clock_s
			"knot_bit": bad.exchange.source_position[0] = _one_bit(bad.exchange.source_position[0])
			"opening_bit": bad.exchange.opening_position[0] = _one_bit(bad.exchange.opening_position[0])
			"profile": bad.exchange.profile_id = "assisted"
			"world_bit": bad.exchange.adapter.world_collision_fingerprint.colliders[0].priority = _one_bit(bad.exchange.adapter.world_collision_fingerprint.colliders[0].priority)
			"adapter_generation_float": bad.exchange.adapter.generation = 1.0
			"record_damage_bit": bad.sequence.timeline.slots[0].events[0].record.damage = _one_bit(bad.sequence.timeline.slots[0].events[0].record.damage)
			"fake_capture": bad.sequence["capture_snapshot"] = {}
			"fake_gear": bad.sequence.timeline.slots[0].events[0].record["equipment_ids"] = {}
			"fake_publication": bad.sequence.timeline.slots[0].events[0]["record_sequence"] = 1
		_reject_receipt(bad, "closed terminal rejects " + field, first)
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		var bad: Dictionary = first.duplicate(true)
		bad.exchange[key] = _one_bit(bad.exchange[key])
		_reject_receipt(bad, "one-bit original " + key + " cannot normalize", first)
	var zero: float = _negative_zero()
	_expect(zero == 0.0 and Exact.stringify(zero) != Exact.stringify(0.0), "signed-zero control changes native bits while numerically equal")
	var parsed: Dictionary = Exact.parse(Exact.stringify({"positive": 0.0, "negative": zero, "integer": 0}))
	_expect(parsed.get("accepted", false) and Exact.stringify(parsed.value.negative) == Exact.stringify(zero) and typeof(parsed.value.integer) == TYPE_INT and typeof(parsed.value.positive) == TYPE_FLOAT, "tagged zeros preserve sign and int/float types")
	for target: String in ["origin", "admission"]:
		var bad: Dictionary = _receipt(_program(1), 0.0, 9, "cancelled", "signed-zero control")
		if target == "origin": bad.exchange.adapter.timeline_origin_s = zero
		else: bad.cursor.configured_at_s = zero
		_reject_receipt(bad, "signed-zero copied " + target + " cannot replace positive-zero bits", first)
	var cancellation: Dictionary = _receipt(_program(1), 0.0, 9, "cancelled", "original reason", "damage")
	for field: String in ["clock_bit", "reason", "hero", "extra", "float_generation", "cooldown_bit"]:
		var bad: Dictionary = cancellation.duplicate(true)
		match field:
			"clock_bit": bad.cancellation.cancelled_at_s = _one_bit(bad.cancellation.cancelled_at_s)
			"reason": bad.cancellation.reason = "different original reason"
			"hero": bad.cancellation.response_actor_id = "test-only/other-hero"
			"extra": bad.cancellation["lifecycle"] = {}
			"float_generation": bad.cancellation.generation = 1.0
			"cooldown_bit": bad.cancellation.cooldown_until_s = _one_bit(bad.cancellation.cooldown_until_s)
		_reject_receipt(bad, "original cancellation rejects " + field, first)


func _journal_controls(first: Dictionary) -> void:
	var terminal: Dictionary = _journal([_entry(first.sequence, "terminal", [first])])
	_accept_journal(terminal, first.terminal_at_s, "PURE DATA terminal generation 1 at original completion")
	_accept_journal(terminal, first.exchange.cooldown_until_s + 50.0, "PURE DATA history remains valid at later aggregate without a live historical lease")
	var second_program: Dictionary = _program(2)
	var ready: Dictionary = _journal([_entry(second_program, "cycle_ready", [first])])
	_accept_journal(ready, first.exchange.cooldown_until_s, "PURE DATA ready generation 2 waits for original full cooldown")
	var running: Dictionary = _journal([_entry(second_program, "running", [first])])
	_accept_journal(running, first.exchange.cooldown_until_s + 0.5, "PURE DATA running generation 2 keeps predecessor; live lease is parent-owned")
	var second: Dictionary = _receipt(second_program, first.exchange.cooldown_until_s + 0.25, 12, "cancelled", "cycle2 cancellation", "damage")
	var third: Dictionary = _receipt(_program(3), second.exchange.cooldown_until_s + 0.25, 13, "complete")
	var history: Dictionary = _journal([_entry(third.sequence, "terminal", [first, second, third])])
	_accept_journal(history, third.terminal_at_s, "PURE DATA complete/cancelled/complete history retains contiguous 1..3 and cooldowns")
	var parsed: Dictionary = Exact.parse(Exact.stringify(history))
	_expect(parsed.get("accepted", false) and Journal.snapshot_error(parsed.get("value", {}), third.terminal_at_s).is_empty() and Exact.stringify(parsed.value) == Exact.stringify(history), "tagged multi-generation roundtrip preserves every frozen bit/type")
	var wire: String = Exact.stringify(history)
	var copy: Dictionary = Journal.validated_copy(history, third.terminal_at_s)
	copy.sources[0].terminal_receipts[0].opportunities.clear()
	copy.sources[0].sequence.definition.raw_role.max_hp = 100000.0
	_expect(not copy.is_empty() and Exact.stringify(history) == wire, "journal copy cannot rewrite original resource recipe or retired prefix")
	_accept_journal(_journal([]), 0.0, "empty pure journal invents no native sources")
	_accept_journal(_journal([_entry(_program(1), "cycle_ready", [])]), 0.0, "PURE DATA first ready generation has no invented predecessor")
	for field: String in ["schema_float", "generation_float", "generation_zero", "start_generation2", "missing_history", "duplicate_generation", "reordered_history", "current_sequence", "source_epoch", "stage", "old_seven_keys", "extra", "source_extra", "rewritten_prefix", "retired_sequence_reuse"]:
		var bad: Dictionary = history.duplicate(true)
		match field:
			"schema_float": bad.schema_version = 1.0
			"generation_float": bad.sources[0].generation = 3.0
			"generation_zero": bad.sources[0].generation = 0
			"start_generation2": bad = _journal([_entry(second_program, "cycle_ready", [])])
			"missing_history": bad.sources[0].terminal_receipts.remove_at(0)
			"duplicate_generation": bad.sources[0].terminal_receipts[1] = first.duplicate(true)
			"reordered_history": bad.sources[0].terminal_receipts.reverse()
			"current_sequence": bad.sources[0].sequence = second_program.duplicate(true)
			"source_epoch": bad.sources[0].source_epoch = "test-only/foreign-attempt"
			"stage": bad.sources[0].stage = "defeated"
			"old_seven_keys": bad.sources[0] = {"source_id": SOURCE_ID, "source_epoch": EPOCH, "initial_generation": 1, "current_generation": 3, "current_stage": "terminal", "sequence": third.sequence, "history": [first, second, third]}
			"extra": bad["current_actor_hp"] = 100.0
			"source_extra": bad.sources[0]["current_actor_hp"] = 100.0
			"rewritten_prefix": bad.sources[0].terminal_receipts[0].cursor.executed_events.clear()
			"retired_sequence_reuse": bad = _journal([_entry(_program(2, "standard", {}, {}, SOURCE_ID, first.sequence.sequence_id), "cycle_ready", [first])])
		_reject_journal(bad, third.terminal_at_s + 100.0, "journal rejects " + field, history, third.terminal_at_s)
	_reject_journal(terminal, first.terminal_at_s - 0.001, "aggregate cannot precede terminal receipt", history, third.terminal_at_s)
	_reject_journal(ready, _one_bit_down(first.exchange.cooldown_until_s), "one-bit early aggregate cannot bypass cooldown", history, third.terminal_at_s)
	_reject_journal(running, first.exchange.cooldown_until_s - 0.001, "running generation cannot hide an early cooldown", history, third.terminal_at_s)
	_reject_journal(terminal, INF, "nonfinite aggregate rejects", history, third.terminal_at_s)
	_reject_journal(terminal, -0.01, "negative aggregate rejects", history, third.terminal_at_s)
	# These alternatives are separately canonical PURE DATA. Syntactic validity
	# must not authorize changing a fixed recipe/Hero or admitting before ready.
	var changed_definition: Dictionary = _definition.duplicate(true)
	changed_definition.raw_role.max_hp = _one_bit(changed_definition.raw_role.max_hp)
	var changed_world: Dictionary = _guards.duplicate(true)
	changed_world.world_revision = 2
	for variation: String in ["early_start", "before_retirement", "hero", "hp_recipe", "profile", "world"]:
		var program: Dictionary = _program(2)
		var start: float = first.exchange.cooldown_until_s + 0.25
		var hero: String = HERO_ID
		if variation == "early_start": start = first.exchange.cooldown_until_s - 0.01
		elif variation == "before_retirement": start = first.terminal_at_s - 0.01
		elif variation == "hero": hero = "test-only/another-hero"
		elif variation == "hp_recipe": program = _program(2, "standard", changed_definition)
		elif variation == "profile": program = _program(2, "assisted")
		elif variation == "world": program = _program(2, "standard", {}, changed_world)
		var alternate: Dictionary = _receipt(program, start, 15, "complete", "", "", 0.0, 0.0, hero)
		_accept_receipt(alternate, "independently canonical PURE DATA " + variation + " alternative")
		_reject_journal(_journal([_entry(alternate.sequence, "terminal", [first, alternate])]), alternate.terminal_at_s + 100.0, "history cannot replace " + variation, history, third.terminal_at_s)
	var other: Dictionary = _receipt(_program(1, "standard", {}, {}, "test-only/second-source", "test-only/second-sequence"), 0.0, 20, "complete")
	_accept_journal(_journal([_entry(first.sequence, "terminal", [first]), _entry(other.sequence, "terminal", [other])]), maxf(first.terminal_at_s, other.terminal_at_s), "PURE DATA unique sources retain separate cycle/playback/reservation identities")
	for collision: String in ["source", "sequence", "playback", "reservation"]:
		var altered: Dictionary = other.duplicate(true)
		if collision == "source": altered = first.duplicate(true)
		elif collision == "sequence": altered = _receipt(_program(1, "standard", {}, {}, "test-only/second-source", first.sequence.sequence_id), 0.0, 20, "complete")
		elif collision == "playback": altered.playback_id = first.playback_id
		elif collision == "reservation": altered.exchange.id = first.exchange.id
		_reject_journal(_journal([_entry(first.sequence, "terminal", [first]), _entry(altered.sequence, "terminal", [altered])]), third.terminal_at_s + 100.0, "journal refuses " + collision + " identity reuse", history, third.terminal_at_s)
	var over_sources: Array = []
	for _index: int in range(65): over_sources.append(_entry(first.sequence, "terminal", [first]))
	_reject_journal(_journal(over_sources), third.terminal_at_s + 100.0, "65 sources exceed bounded journal capacity", history, third.terminal_at_s)
	var over_history: Array = []
	for _index: int in range(65): over_history.append(first)
	_reject_journal(_journal([_entry(first.sequence, "terminal", over_history)]), third.terminal_at_s + 100.0, "65 receipts exceed bounded source history/transport capacity", history, third.terminal_at_s)
	_reject_journal(_journal([_entry(_program(65), "cycle_ready", [])]), third.terminal_at_s + 100.0, "generation 65 cannot evict history for a next cycle", history, third.terminal_at_s)


func _hostile_inputs(first: Dictionary) -> void:
	var object := RefCounted.new()
	var cycle: Dictionary = {}
	cycle["self"] = cycle
	var large: Array = []
	large.resize(16385)
	var deep: Dictionary = {}
	var tail: Dictionary = deep
	for _index: int in range(40):
		var child: Dictionary = {}
		tail["child"] = child
		tail = child
	var aliased: Array = [null]
	for _index: int in range(18): aliased = [aliased, aliased]
	for control: Dictionary in [{"name": "foreign object", "value": object}, {"name": "native vector", "value": Vector3.ZERO}, {"name": "StringName", "value": StringName("foreign")}, {"name": "nonfinite", "value": NAN}, {"name": "unsafe integer", "value": 9007199254740992}, {"name": "one-MiB string", "value": "x".repeat(1024 * 1024 + 1)}, {"name": "large container", "value": large}, {"name": "cyclic", "value": cycle}, {"name": "depth40", "value": deep}, {"name": "expanding aliases", "value": aliased}]:
		var bad: Dictionary = first.duplicate(true)
		bad.reason = control.value
		_reject_receipt(bad, control.name + " branch rejects before deepcopy", first)
		var journal: Dictionary = _journal([_entry(first.sequence, "terminal", [first])])
		bad = journal.duplicate(true)
		bad["foreign"] = control.value
		_reject_journal(bad, first.terminal_at_s, "journal " + control.name + " rejects before copying", journal, first.terminal_at_s)
	cycle.erase("self")


func _captured_control(first: Dictionary) -> void:
	var player = Player.new()
	player.name = "ActualCapturedControlPlayer"
	_arena.world.add_child(player)
	player.position = Vector3(0, 0.1, 0)
	paused = false
	await _ticks(8)
	paused = true
	await process_frame
	var capture = Capture.new()
	var epoch: String = "test-only/actual-captured-control"
	if not _expect(capture.arm(epoch, 1, 0, player.get_world_action_clock()), "actual capture control arms at a paused actor boundary"):
		return
	player.world_action_executed.connect(func(record: Dictionary) -> void:
		capture.ingest(record, epoch)
		if record.kind == "dash": player.slash(Vector3.RIGHT)
	)
	paused = false
	_expect(player.request_dash(Vector3.RIGHT), "actual public dash is only a captured-provenance control")
	for _index: int in range(60):
		await _ticks(1)
		capture.advance(player.get_world_action_clock())
	paused = true
	await process_frame
	var captured = Captured.new()
	var valid: bool = captured.configure("test-only/captured-sequence", capture.snapshot_state(), {"recognition_s": 0.12, "warning_s": 0.5, "locked_lead_s": 0.8, "inter_echo_gap_s": 0.0, "final_recovery_s": 2.0, "tether_position": player.global_position}, epoch, 1)
	_expect(valid, "captured constructor derives actual completed dash/primary: " + captured.last_error)
	if valid:
		var bad: Dictionary = first.duplicate(true)
		bad.sequence = captured.snapshot_state()
		_reject_receipt(bad, "valid actual capture cannot masquerade as an own-enemy terminal", first)
		var baseline: Dictionary = _journal([_entry(first.sequence, "terminal", [first])])
		bad = baseline.duplicate(true)
		bad.sources[0].sequence = captured.snapshot_state()
		_reject_journal(bad, first.terminal_at_s, "valid actual capture cannot replace authored journal provenance", baseline, first.terminal_at_s)


func _program(generation: int, profile: String = "standard", definition: Dictionary = {}, guards: Dictionary = {}, source_id: String = SOURCE_ID, sequence_id: String = "") -> Dictionary:
	var authored = Authored.new()
	var native: Dictionary = _definition if definition.is_empty() else definition
	var world: Dictionary = _guards if guards.is_empty() else guards
	var id: String = "test-only/lifecycle-cycle-%d" % generation if sequence_id.is_empty() else sequence_id
	if not authored.configure(id, native, source_id, EPOCH, generation, profile, world):
		_expect(false, "authored constructor prerequisite: " + authored.last_error)
	return authored.snapshot_state()


func _receipt(sequence: Dictionary, start: float, serial: int, outcome: String, reason: String = "", stage: String = "", dispatch_delay: float = 0.0, lock_delay: float = 0.0, hero_id: String = HERO_ID) -> Dictionary:
	# All timetable/contact/cancellation below is PURE DATA. Only Program/Cursor
	# data uses public constructors; no actual Scheduler lease is requested.
	if sequence.is_empty(): return {}
	var cursor = Cursor.new()
	if not _expect(cursor.configure_authored(sequence, EPOCH, sequence.generation, start), "PURE DATA canonical cursor configures"):
		return {}
	var exchange: Dictionary = _exchange(sequence, start, serial)
	var terminal: float = start + float(sequence.authored.warning_s) * 0.5
	var opportunities: Array = []
	var pending: Dictionary = {}
	if outcome == "complete" or not stage.is_empty():
		var lock: float = exchange.lock_from_s + lock_delay
		var origin: float = lock - float(sequence.authored.warning_s)
		if not _expect(cursor.arm(origin, lock), "PURE DATA cursor arms at inverse full-warning clock"):
			return {}
		exchange = _exchange(sequence, start, serial, true, lock, origin)
		var event: Dictionary = sequence.timeline.slots[0].events[0]
		var dispatch: float = origin + float(event.at_s) + dispatch_delay
		if stage == "before_event":
			terminal = exchange.active_from_s + 0.1
			cursor.advance(terminal)
		else:
			var result: Dictionary = cursor.advance(dispatch)
			if not _expect(result.get("accepted", false) and result.events.size() == 1, "PURE DATA cursor consumes exactly one own slash"):
				return {}
			opportunities.append({"event_id": event.event_id, "hero_id": hero_id, "scheduled_at_s": result.events[0].scheduled_at_s, "dispatch_clock_s": result.events[0].dispatch_clock_s, "contact": true, "damage_attempted": stage not in ["present", "damage"]})
			terminal = dispatch
			if outcome == "complete":
				terminal = exchange.recovery_until_s
				cursor.advance(terminal)
			elif stage in ["present", "damage", "notify"]:
				pending = {"events": [{"event_index": 0, "stage": stage}], "visual_next_cue": 0, "visuals_pending": false, "state_pending": false, "cue_phases": ["clear"]}
	else:
		cursor.advance(terminal)
	var cancellation: Dictionary = {} if outcome == "complete" else _cancellation(sequence, exchange, terminal, reason, hero_id)
	return {"api_revision": "authored-echo-terminal-receipt-1", "schema_version": 1, "playback_id": "test-only/playback-%d" % serial, "source_id": sequence.source_id, "hero_id": hero_id, "source_epoch": EPOCH, "generation": sequence.generation, "sequence": sequence.duplicate(true), "exchange": exchange, "outcome": outcome, "reason": reason, "terminal_at_s": terminal, "cursor_clock_s": cursor.state().last_advanced_clock_s, "cursor": cursor.snapshot_state(), "opportunities": opportunities, "pending_delivery": pending, "cancellation": cancellation}


func _exchange(sequence: Dictionary, start: float, serial: int, locked: bool = false, lock: float = 0.0, origin: float = 0.0) -> Dictionary:
	if not locked:
		lock = start + float(sequence.authored.warning_s)
		origin = start
	var danger_until: float = maxf(float(sequence.timeline.replay_until_s), float(sequence.timeline.slots[0].events[0].at_s) + DISPATCH_GRACE_S + ACTIVE_MARGIN_S)
	return {"id": "threat-%d" % serial, "source_position": sequence.authored.tether_position.duplicate(), "opening_position": sequence.authored.tether_position.duplicate(), "start_s": start, "lock_from_s": lock, "active_from_s": origin + float(sequence.timeline.playback_from_s), "active_until_s": origin + danger_until, "recovery_until_s": origin + float(sequence.timeline.tether_until_s), "cooldown_until_s": origin + float(sequence.timeline.source_ready_s), "profile_id": sequence.profile_id, "world_revision": sequence.world.world_revision, "adapter": {"kind": "authored_replay", "locked": locked, "sequence": sequence.duplicate(true), "source_id": sequence.source_id, "source_epoch": EPOCH, "generation": sequence.generation, "world_collision_fingerprint": sequence.world.collision_fingerprint.duplicate(true), "world_floor_signature": sequence.world.floor_signature.duplicate(true), "timeline_origin_s": origin, "max_dispatch_delay_s": DISPATCH_GRACE_S}}


func _cancellation(sequence: Dictionary, exchange: Dictionary, clock: float, reason: String, hero: String) -> Dictionary:
	var result: Dictionary = {"kind": "authored_replay", "id": exchange.id, "source_id": sequence.source_id, "response_actor_id": hero, "sequence_id": sequence.sequence_id, "source_epoch": EPOCH, "generation": sequence.generation, "sequence": sequence.duplicate(true), "world_collision_fingerprint": exchange.adapter.world_collision_fingerprint.duplicate(true), "world_floor_signature": exchange.adapter.world_floor_signature.duplicate(true), "timeline_origin_s": exchange.adapter.timeline_origin_s, "locked": exchange.adapter.locked, "max_dispatch_delay_s": DISPATCH_GRACE_S, "cancelled_at_s": clock, "reason": reason}
	for key: String in ["profile_id", "world_revision", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]: result[key] = exchange[key]
	return result


func _entry(sequence: Dictionary, stage: String, history: Array) -> Dictionary:
	return {"source_id": sequence.source_id, "source_epoch": sequence.source_epoch, "generation": sequence.generation, "stage": stage, "sequence": sequence, "terminal_receipts": history}


func _journal(entries: Array) -> Dictionary:
	return {"api_revision": "authored-echo-cycle-journal-1", "schema_version": 1, "sources": entries}


func _accept_receipt(value: Dictionary, label: String) -> void:
	var before: String = Exact.stringify(value)
	var error: String = Receipt.snapshot_error(value)
	_expect(error.is_empty() and Exact.stringify(value) == before, label + ("" if error.is_empty() else ": " + error))


func _reject_receipt(value: Dictionary, label: String, baseline: Dictionary) -> void:
	var before: String = Exact.stringify(baseline)
	_expect(not Receipt.snapshot_error(value).is_empty() and Receipt.validated_copy(value).is_empty() and Exact.stringify(baseline) == before, label + "; original stays untouched")


func _accept_journal(value: Dictionary, clock: float, label: String) -> void:
	var before: String = Exact.stringify(value)
	var error: String = Journal.snapshot_error(value, clock)
	_expect(error.is_empty() and Exact.stringify(value) == before, label + ("" if error.is_empty() else ": " + error))


func _reject_journal(value: Dictionary, clock: float, label: String, baseline: Dictionary, baseline_clock: float) -> void:
	var before: String = Exact.stringify(baseline)
	_expect(not Journal.snapshot_error(value, clock).is_empty() and Journal.validated_copy(value, clock).is_empty() and Journal.snapshot_error(baseline, baseline_clock).is_empty() and Exact.stringify(baseline) == before, label + "; valid history stays untouched")


func _native_arena() -> Dictionary:
	var world := Node3D.new()
	world.name = "PureLifecycleNativeWorld"
	root.add_child(world)
	var floor_body: StaticBody3D = _box(world, "Floor", Vector3(0, -0.5, 0), Vector3(24, 1, 24))
	_box(world, "ShoreStone", Vector3(0, 1, 4), Vector3(1, 2, 1))
	var source := Node3D.new()
	source.name = "DescriptorSourceOnly"
	world.add_child(source)
	source.position = Vector3(2, 0, 0)
	var scheduler = Scheduler.new()
	world.add_child(scheduler)
	scheduler.begin_encounter("standard", "test-only/lifecycle-descriptors", 1)
	await _ticks(3)
	paused = true
	await process_frame
	return {"world": world, "floor": floor_body, "source": source, "scheduler": scheduler, "floors": [{"collision": floor_body.get_child(0), "safe_rect": Rect2(-12, -12, 24, 24)}]}


func _native_guards() -> Dictionary:
	var floor_result: Dictionary = Footprint.floor_signature(_arena.world, _arena.floors)
	return {"world_revision": 1, "collision_fingerprint": _arena.scheduler.pure_collision_fingerprint(_arena.world), "floor_signature": floor_result.get("signature", [])}


func _native_definition(endpoint: Vector3) -> Dictionary:
	var travel: float = 0.4
	var commitment: float = 0.2
	return {"definition_id": "test-only/lifecycle-own-dash-slash", "definition_revision": 1, "role_id": "C52", "raw_role": {"raw_damage": 4.0, "windup_s": 1.8, "lock_s": 1.1, "active_s": travel + commitment, "recovery_s": 2.0, "attack_interval_s": 8.0, "max_hp": 40.0, "move_speed": 0.0}, "timing_floors": {"windup_s": 1.2, "lock_s": 0.9, "recovery_s": 1.6}, "recognition_s": 0.12, "route": [{"position": endpoint + Vector3.LEFT * 4.0, "at_s": 0.0}, {"position": endpoint, "at_s": travel}], "travel_clearance": {"radius_m": 0.35, "height_m": 1.5}, "slash": {"world_origin": endpoint, "direction": Vector3.FORWARD, "reach": 1.1, "cone_min_dot": 0.3, "origin_disk_radius": 0.1, "max_vertical_distance": 1.0, "los_height": 0.9, "commitment_duration_s": commitment, "visual_duration_s": 0.28}, "presentation": {"presentation_id": "test-only/lifecycle-source-art", "presentation_revision": 1}}


func _box(parent: Node3D, stable_name: String, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = stable_name
	body.collision_layer = 1
	body.collision_mask = 1
	parent.add_child(body)
	body.position = position
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body


func _one_bit(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes[0] = bytes[0] ^ 1
	return bytes.decode_double(0)


func _one_bit_down(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	for index: int in range(8):
		if bytes[index] > 0:
			bytes[index] -= 1
			break
		bytes[index] = 255
	return bytes.decode_double(0)


func _negative_zero() -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, 0.0)
	bytes[7] = 128
	return bytes.decode_double(0)


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _expect(condition: bool, description: String) -> bool:
	_checks += 1
	if condition: print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
	return condition


func _finish() -> void:
	paused = false
	if not _arena.is_empty() and is_instance_valid(_arena.world): _arena.world.queue_free()
	await process_frame
	print("Authored echo lifecycle codec smoke: %d checks, %d failures; PURE DATA history, not native admissions/HP/two-cycle proof" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
