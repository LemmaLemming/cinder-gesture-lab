class_name CinderAuthoredEchoTerminalReceipt
extends RefCounted
## Pure reduced terminal transport at ORIGINAL frozen clocks. No live lease,
## native source authentication, history mutation, rendering or damage authority.
## A structurally valid copied receipt still needs actual parent/Scheduler custody.

const Program = preload("res://scripts/combat/replay_program.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Cursor = preload("res://scripts/combat/replay_cursor.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const API_REVISION: String = "authored-echo-terminal-receipt-1"
const MAX_CLOCK_S: float = 1000000.0
const MAX_DISPATCH_DELAY_S: float = 0.05
# Matches the canonical Scheduler replay active-end policy; NOT a copied-clock
# tolerance. Scheduler integration must retain this exact deadline derivation.
const REPLAY_TIME_MARGIN_S: float = 0.001
const TIME_EPSILON_S: float = Program.TIME_EPSILON_S
const MAX_BYTES: int = 1024 * 1024
const MAX_DEPTH: int = 32
const MAX_NODES: int = 65536
const MAX_CONTAINER_ENTRIES: int = 16384
const KEYS: Array[String] = ["api_revision", "schema_version", "playback_id", "source_id", "hero_id", "source_epoch", "generation", "sequence", "exchange", "outcome", "reason", "terminal_at_s", "cursor_clock_s", "cursor", "opportunities", "pending_delivery", "cancellation"]
const EXCHANGE_KEYS: Array[String] = ["id", "source_position", "opening_position", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision", "adapter"]
const ADAPTER_KEYS: Array[String] = ["kind", "locked", "sequence", "source_id", "source_epoch", "generation", "world_collision_fingerprint", "world_floor_signature", "timeline_origin_s", "max_dispatch_delay_s"]
const OPPORTUNITY_KEYS: Array[String] = ["event_id", "hero_id", "scheduled_at_s", "dispatch_clock_s", "contact", "damage_attempted"]
const PENDING_KEYS: Array[String] = ["events", "visual_next_cue", "visuals_pending", "state_pending", "cue_phases"]
const CANCELLATION_KEYS: Array[String] = ["kind", "id", "source_id", "response_actor_id", "sequence_id", "source_epoch", "generation", "sequence", "world_collision_fingerprint", "world_floor_signature", "profile_id", "world_revision", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "timeline_origin_s", "locked", "max_dispatch_delay_s", "cancelled_at_s", "reason"]


static func snapshot_error(receipt: Dictionary) -> String:
	# Bound ALL foreign branches before any canonical reader can deep-copy them.
	var error: String = transport_error(receipt)
	if error.is_empty():
		error = Codec.keys_error(receipt, KEYS)
	if not error.is_empty(): return error
	if receipt.api_revision != API_REVISION or not receipt.schema_version is int or receipt.schema_version != 1 or not receipt.generation is int or not Codec.is_integer(receipt.generation, 1):
		return "Typed authored terminal receipt API/schema/generation required"
	for key: String in ["playback_id", "source_id", "hero_id", "source_epoch"]:
		if not stable_id(receipt[key]): return "Stable terminal identity required: " + key
	if not receipt.sequence is Dictionary or not receipt.exchange is Dictionary or not receipt.cursor is Dictionary or not receipt.opportunities is Array or not receipt.pending_delivery is Dictionary or not receipt.cancellation is Dictionary or not receipt.outcome is String or receipt.outcome not in ["complete", "cancelled"] or not receipt.reason is String or receipt.reason.length() > 512:
		return "Closed reduced terminal program/exchange/prefix/outcome required"
	if not clock_valid(receipt.terminal_at_s) or not clock_valid(receipt.cursor_clock_s) or float(receipt.cursor_clock_s) > float(receipt.terminal_at_s):
		return "Frozen native cursor clock cannot exceed original terminal clock"
	if receipt.sequence.get("api_revision") != Authored.API_REVISION:
		return "Captured/foreign programs are not authored terminal receipts"
	var reader = Program.new()
	if not reader.restore_state(receipt.sequence, receipt.source_epoch, receipt.generation) or not reader.is_authored_enemy():
		return "Distinct canonical authored program required: " + reader.last_snapshot_error
	var plan: Dictionary = reader.snapshot_state()
	if plan.source_id != receipt.source_id: return "Terminal source differs from its authored program"
	var cursor_reader = Cursor.new()
	error = cursor_reader.snapshot_error(receipt.cursor, receipt.sequence, receipt.source_epoch, receipt.generation, receipt.cursor_clock_s)
	if not error.is_empty(): return "Invalid frozen terminal cursor: " + error
	error = _exchange_error(receipt, plan)
	if not error.is_empty(): return error
	var events: Array = _events(plan)
	if receipt.opportunities.size() != receipt.cursor.executed_events.size() or receipt.opportunities.size() > events.size():
		return "Every consumed canonical event retains one target opportunity"
	for index: int in range(receipt.opportunities.size()):
		var value: Variant = receipt.opportunities[index]
		var prefix: Dictionary = receipt.cursor.executed_events[index]
		if not value is Dictionary or not Codec.keys_error(value, OPPORTUNITY_KEYS).is_empty() or value.event_id != events[index].event_id or value.hero_id != receipt.hero_id or not clock_valid(value.scheduled_at_s) or not clock_valid(value.dispatch_clock_s) or not Authored.exact_equal(value.scheduled_at_s, prefix.scheduled_at_s) or not Authored.exact_equal(value.dispatch_clock_s, prefix.dispatch_clock_s) or float(value.dispatch_clock_s) - float(value.scheduled_at_s) > MAX_DISPATCH_DELAY_S + TIME_EPSILON_S or not value.contact is bool or not value.damage_attempted is bool or (value.damage_attempted and not value.contact):
			return "Exact bounded event/target/contact/attempt prefix required"
	if receipt.outcome == "complete":
		if not receipt.reason.is_empty() or not receipt.cancellation.is_empty() or not receipt.pending_delivery.is_empty() or not receipt.cursor.armed or receipt.cursor.phase != "complete" or receipt.cursor.next_event_index != events.size() or not Authored.exact_equal(receipt.cursor_clock_s, receipt.terminal_at_s) or float(receipt.terminal_at_s) < float(receipt.exchange.recovery_until_s):
			return "Completion requires full delivered prefix at its real original completion clock"
	else:
		if receipt.reason.is_empty(): return "Original cancellation reason required"
		error = _cancellation_error(receipt, plan)
		if not error.is_empty(): return error
	return _pending_error(receipt, events.size())


static func validated_copy(receipt: Dictionary) -> Dictionary:
	return receipt.duplicate(true) if snapshot_error(receipt).is_empty() else {}


static func transport_error(value: Variant) -> String:
	# One global traversal budget also bounds cycles/aliased expanding trees.
	# No object access, native-vector coercion or deepcopy occurs during this walk.
	var budget: Array[int] = [MAX_NODES, MAX_BYTES]
	var error: String = _walk(value, 0, budget)
	if not error.is_empty(): return error
	var wire: String = Exact.stringify(value)
	return "" if not wire.is_empty() and wire.to_utf8_buffer().size() <= MAX_BYTES else "Authored history exceeds exact one-MiB transport capacity"


static func stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128: return false
	for character: String in value:
		if not character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_./:-": return false
	return true


static func clock_valid(value: Variant) -> bool:
	return value is float and is_finite(value) and value >= 0.0 and value <= MAX_CLOCK_S


static func _exchange_error(receipt: Dictionary, plan: Dictionary) -> String:
	var exchange: Dictionary = receipt.exchange
	if not Codec.keys_error(exchange, EXCHANGE_KEYS).is_empty() or not _reservation_id(exchange.id) or not exchange.adapter is Dictionary:
		return "Closed original authored exchange required"
	var adapter: Dictionary = exchange.adapter
	if not Codec.keys_error(adapter, ADAPTER_KEYS).is_empty() or adapter.kind != "authored_replay" or not adapter.locked is bool or not Authored.exact_equal(adapter.sequence, receipt.sequence) or adapter.source_id != receipt.source_id or adapter.source_epoch != receipt.source_epoch or not Authored.exact_equal(adapter.generation, receipt.generation) or not Authored.exact_equal(adapter.max_dispatch_delay_s, MAX_DISPATCH_DELAY_S) or not clock_valid(adapter.timeline_origin_s):
		return "Exact original authored adapter/program/cycle required"
	if not Authored.exact_equal(exchange.source_position, plan.authored.tether_position) or not Authored.exact_equal(exchange.opening_position, plan.authored.tether_position) or exchange.profile_id != plan.profile_id or not Authored.exact_equal(exchange.world_revision, plan.world.world_revision) or not Authored.exact_equal(adapter.world_collision_fingerprint, plan.world.collision_fingerprint) or not Authored.exact_equal(adapter.world_floor_signature, plan.world.floor_signature):
		return "Exact original fixed knot/profile/world guards required"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not clock_valid(exchange[key]): return "Finite exact native exchange deadline required: " + key
	if not Authored.exact_equal(exchange.start_s, receipt.cursor.configured_at_s) or float(exchange.start_s) > float(receipt.cursor_clock_s) or receipt.cursor.armed != adapter.locked:
		return "Original exchange admission/arming must match its frozen cursor"
	var warning: float = float(plan.authored.warning_s)
	var origin: float = adapter.timeline_origin_s
	if adapter.locked:
		if float(exchange.lock_from_s) < float(exchange.start_s) + warning or not Authored.exact_equal(origin, float(exchange.lock_from_s) - warning) or not Authored.exact_equal(receipt.cursor.armed_at_s, exchange.lock_from_s) or not Authored.exact_equal(receipt.cursor.timeline_origin_s, origin):
			return "Original actual lock retains full warning and exact inverse origin"
	elif not Authored.exact_equal(origin, exchange.start_s) or not Authored.exact_equal(exchange.lock_from_s, float(exchange.start_s) + warning):
		return "Original unarmed preview retains its warning and timeline origin"
	var danger_until: float = float(plan.timeline.replay_until_s)
	for event: Dictionary in _events(plan):
		danger_until = maxf(danger_until, float(event.at_s) + MAX_DISPATCH_DELAY_S + REPLAY_TIME_MARGIN_S)
	var expected: Dictionary = {"active_from_s": origin + float(plan.timeline.playback_from_s), "active_until_s": origin + danger_until, "recovery_until_s": origin + float(plan.timeline.tether_until_s), "cooldown_until_s": origin + float(plan.timeline.source_ready_s)}
	for key: String in expected:
		if not Authored.exact_equal(exchange[key], expected[key]): return "Original authored deadline differs from canonical timeline: " + key
	if not (float(exchange.start_s) < float(exchange.lock_from_s) and float(exchange.lock_from_s) < float(exchange.active_from_s) and float(exchange.active_from_s) < float(exchange.active_until_s) and float(exchange.active_until_s) < float(exchange.recovery_until_s) and float(exchange.cooldown_until_s) >= float(exchange.recovery_until_s)):
		return "Original authored phases/cooldown lost finite order"
	return ""


static func _cancellation_error(receipt: Dictionary, plan: Dictionary) -> String:
	var cancellation: Dictionary = receipt.cancellation
	if not Codec.keys_error(cancellation, CANCELLATION_KEYS).is_empty(): return "Closed original authored cancellation required"
	var exchange: Dictionary = receipt.exchange
	var adapter: Dictionary = exchange.adapter
	var expected: Dictionary = {"kind": "authored_replay", "id": exchange.id, "source_id": receipt.source_id, "response_actor_id": receipt.hero_id, "sequence_id": plan.sequence_id, "source_epoch": receipt.source_epoch, "generation": receipt.generation, "sequence": receipt.sequence, "world_collision_fingerprint": adapter.world_collision_fingerprint, "world_floor_signature": adapter.world_floor_signature, "timeline_origin_s": adapter.timeline_origin_s, "locked": adapter.locked, "max_dispatch_delay_s": adapter.max_dispatch_delay_s, "cancelled_at_s": receipt.terminal_at_s, "reason": receipt.reason}
	for key: String in ["profile_id", "world_revision", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		expected[key] = exchange[key]
	return "" if Authored.exact_equal(cancellation, expected) else "Cancellation must preserve original exchange/target/time/reason exactly"


static func _pending_error(receipt: Dictionary, event_count: int) -> String:
	var pending: Dictionary = receipt.pending_delivery
	var entries: Array = []
	if not pending.is_empty():
		if receipt.outcome != "cancelled" or not Codec.keys_error(pending, PENDING_KEYS).is_empty() or not pending.events is Array or pending.events.is_empty() or pending.events.size() > receipt.opportunities.size() or not pending.visual_next_cue is int or pending.visual_next_cue != 0 or not pending.visuals_pending is bool or pending.visuals_pending or not pending.state_pending is bool or pending.state_pending or not pending.cue_phases is Array or pending.cue_phases.size() != event_count:
			return "Cancelled history retains only a genuine inert delivery suffix"
		for phase: Variant in pending.cue_phases:
			if not phase is String or phase != "clear": return "Inert terminal suffix cannot license a damaging cue"
		entries = pending.events
	var first: int = receipt.opportunities.size() - entries.size()
	for index: int in range(entries.size()):
		var entry: Variant = entries[index]
		if not entry is Dictionary or not Codec.keys_error(entry, ["event_index", "stage"]).is_empty() or not entry.event_index is int or entry.event_index != first + index or not entry.stage is String or entry.stage not in ["present", "damage", "notify"] or (index > 0 and entry.stage != "present"):
			return "Inert stages must be the original contiguous canonical suffix"
	for index: int in range(receipt.opportunities.size()):
		var opportunity: Dictionary = receipt.opportunities[index]
		var before_damage: bool = index >= first and entries[index - first].stage in ["present", "damage"]
		if opportunity.damage_attempted != (opportunity.contact and not before_damage):
			return "Frozen stage must truthfully preserve each consumed damage attempt"
	return ""


static func _events(plan: Dictionary) -> Array:
	var result: Array = []
	for slot: Dictionary in plan.timeline.slots:
		for event: Dictionary in slot.events: result.append(event)
	return result


static func _reservation_id(value: Variant) -> bool:
	if not stable_id(value) or not value.begins_with("threat-"): return false
	var suffix: String = value.substr(7)
	if suffix.length() > 16 or not suffix.is_valid_int(): return false
	var serial: int = suffix.to_int()
	return serial >= 1 and serial <= Codec.MAX_SAFE_INTEGER and value == "threat-%d" % serial


static func _walk(value: Variant, depth: int, budget: Array[int]) -> String:
	budget[0] -= 1
	budget[1] -= 16
	if depth > MAX_DEPTH or budget[0] < 0 or budget[1] < 0: return "Authored history exceeds depth/node/byte budget"
	match typeof(value):
		TYPE_NIL, TYPE_BOOL:
			return ""
		TYPE_INT:
			return "" if value >= -Codec.MAX_SAFE_INTEGER and value <= Codec.MAX_SAFE_INTEGER else "Authored history integer exceeds safe exact range"
		TYPE_FLOAT:
			return "" if is_finite(value) else "Authored history requires finite numbers"
		TYPE_STRING:
			if value.length() > MAX_BYTES: return "Authored history string exceeds byte capacity"
			budget[1] -= value.to_utf8_buffer().size()
			return "" if budget[1] >= 0 else "Authored history exceeds byte capacity"
		TYPE_ARRAY:
			if value.size() > MAX_CONTAINER_ENTRIES: return "Authored history array exceeds entry capacity"
			for entry: Variant in value:
				var error: String = _walk(entry, depth + 1, budget)
				if not error.is_empty(): return error
		TYPE_DICTIONARY:
			if value.size() > MAX_CONTAINER_ENTRIES: return "Authored history dictionary exceeds entry capacity"
			for key: Variant in value:
				if not key is String: return "Authored history keys must be native Strings"
				var error: String = _walk(key, depth + 1, budget)
				if error.is_empty(): error = _walk(value[key], depth + 1, budget)
				if not error.is_empty(): return error
		_:
			return "Foreign object/native type is not authored history JSON"
	return ""
