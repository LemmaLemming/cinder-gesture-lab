extends RefCounted
## Pure cross-field rules for the complete L3 local19 aggregate. Caller first
## prevalidates the actual saved Player, Scheduler, seven actors, Ray, four
## tools and each published bank via snapshot_error(..., staged, saved_player).
## Caller also derives canonical admission equipment/full primary cadence and
## checks actual floor/range/LOS/camera support. This helper never reads nodes,
## steps clocks, mutates input, restores state or emits gameplay events.
## KnownRules receives a copy with BOTH banks and bank_views removed.

const Sequence: Script = preload("res://scripts/acts/act2/ruined_house_sequence.gd")
const KnownRules: Script = preload("res://scripts/acts/act2/ruined_house_snapshot_rules.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Bank: Script = preload("res://scripts/combat/smoke_bank.gd")
const Level: Script = preload("res://scripts/campaign/level.gd")
const BANK_IDS: Array[String] = ["road_bank", "house_bank", "boss_bank"]
const BANK_TO_TENDER: Dictionary = {"road_bank": "road_tender", "house_bank": "house_tender", "boss_bank": "side_tender"}
const BANK_RADIUS: float = 1.05
const BANK_KEYS: Array[String] = ["api_revision", "schema_version", "bank_id", "configuration", "hero_id", "status", "phase", "cycle", "clock_s", "encounter_id", "resolved_role", "exchange", "domain", "sample", "trace", "processed_count", "pending_stage", "contact_since_s", "processed_clock_s", "receipts", "last_cancel_reason"]
const CONFIGURATION_KEYS: Array[String] = ["bank_id", "geometry", "opening_position", "raw_role", "timing_floors", "contact"]
const LOCAL_KEYS: Array[String] = ["sequence", "scheduler", "rays", "targets", "mechanisms", "views", "profile_id", "world_revision", "scenic_clock", "last_action_sequence", "contact_seen", "pending_checkpoints", "completion_pending", "exit_requested", "boss_phase_pending", "boss_next_action", "boss_ready_s", "banks", "bank_views"]
const OUTER_KEYS: Array[String] = ["api_revision", "schema_version", "level_id", "scene_path", "local_snapshot_version", "progress", "local"]
const PROGRESS_KEYS: Array[String] = ["completed", "completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind", "checkpoint_ids"]


static func smoke_state_error(state: Dictionary) -> String:
	var error: String = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state, LOCAL_KEYS)
	if not error.is_empty(): return "L3 full local envelope: " + error
	if not state.banks is Dictionary or not state.bank_views is Dictionary or not Codec.keys_error(state.banks, BANK_IDS).is_empty(): return "L3 requires the three complete independent bank snapshots"
	var known: Dictionary = state.duplicate()
	known.erase("banks")
	known.erase("bank_views")
	error = KnownRules.known_state_error(known)
	if not error.is_empty(): return error
	var stage: int = int(state.sequence.stage_index)
	var ended: bool = state.scheduler.encounter_id.is_empty()
	var hero_id: String = ""
	for id: String in BANK_IDS:
		if not state.banks[id] is Dictionary: return "L3 bank snapshot must be a dictionary: " + id
		var saved: Dictionary = state.banks[id]
		error = _bank_error(id, saved, state)
		if not error.is_empty(): return error
		if hero_id.is_empty(): hero_id = saved.hero_id
		elif saved.hero_id != hero_id: return "L3 independent banks must retain the same actual saved shared Hero ID"
		var tender_id: String = BANK_TO_TENDER[id]
		var actor: Dictionary = state.targets[tender_id]
		var first_stage: int = int(Sequence.DEFEAT_STAGE[tender_id])
		if stage < first_stage and (saved.status != "idle" or int(saved.cycle) != 0): return "Future L3 bank must retain its unstarted cycle: " + id
		if saved.status == "running":
			if ended or (stage == 8 and not state.completion_pending): return "Running L3 bank cannot survive an ended/committed clear"
			# Prior admitted banks survive their Tender's earned defeat. Optional
			# side Tender can also remain alive at clear; only existing tails are
			# allowed there. The parent stops all future start commands at clear.
			if not state.bank_views.has(id): return "Running L3 bank needs its original framing witness: " + id
		if float(actor.hp) < 30.0:
			if int(saved.cycle) < 1: return "Damaged L3 Tender requires an actual admitted bank cycle: " + tender_id
			# The latest snapshot has only the latest cycle. Its contact receipts
			# concern damage TO the Hero, never incoming primary hits. For the
			# first cycle, a retained native active-to-recovery segment proves a
			# real reload boundary even after cancellation/clock advancement.
			# Subsequent warning/lock cycles may retain earlier reload damage.
			if int(saved.cycle) == 1 and not _retains_recovery_boundary(saved): return "First-cycle Tender damage requires an actual retained reload boundary: " + tender_id
		var expected_phase: String = "defeated" if float(actor.hp) <= 0.0 else (String(saved.phase) if saved.status == "running" else "idle")
		var expected_progress: float = 1.0 if float(actor.hp) <= 0.0 else _saved_progress(saved)
		if actor.phase != expected_phase or float(actor.phase_progress) != expected_progress: return "L3 Tender pose differs from its independent bank/original exact clock: " + tender_id
	for id: Variant in state.bank_views:
		if not id is String or not state.banks.has(id) or state.banks[id].status != "running" or not state.bank_views[id] is Dictionary: return "L3 bank view cannot outlive its running independent bank"
		error = _view_error(id, state.bank_views[id], state.banks[id])
		if not error.is_empty(): return error
	return ""


static func _bank_error(id: String, saved: Dictionary, state: Dictionary) -> String:
	if not Codec.keys_error(saved, BANK_KEYS).is_empty() or saved.api_revision != Bank.API_REVISION or not Codec.is_integer(saved.schema_version, 1, 1) or saved.bank_id != id or not saved.hero_id is String or saved.hero_id.is_empty() or saved.status not in ["idle", "running", "complete", "cancelled"] or not Codec.is_integer(saved.cycle) or not Codec.is_number(saved.clock_s) or float(saved.clock_s) != float(state.scheduler.clock_s) or not saved.encounter_id is String or not saved.configuration is Dictionary or not saved.exchange is Dictionary or not saved.resolved_role is Dictionary or not saved.trace is Array:
		return "L3 bank must retain the published schema/exact paired clock: " + id
	var config: Dictionary = saved.configuration
	var target: Array = state.targets[BANK_TO_TENDER[id]].root_position
	if not Codec.keys_error(config, CONFIGURATION_KEYS).is_empty() or config.bank_id != id or not config.geometry is Dictionary or not Codec.is_vector3(config.opening_position) or config.opening_position != target:
		return "L3 bank configuration must retain its actual anchored Tender opening: " + id
	var expected_geometry: Dictionary = {"kind": "circle", "origin": Codec.vector3(Sequence.CLOUDS[id]), "radius": BANK_RADIUS}
	if config.geometry != expected_geometry: return "L3 bank must retain its authored anchored radius1.05 circle: " + id
	if saved.status == "idle":
		return "Unstarted L3 bank cannot retain an executed exchange/role/epoch" if int(saved.cycle) != 0 or saved.phase != "clear" or not saved.exchange.is_empty() or not saved.resolved_role.is_empty() or not saved.encounter_id.is_empty() else ""
	if int(saved.cycle) < 1 or not Codec.keys_error(saved.exchange, Bank.EXCHANGE_KEYS).is_empty(): return "Executed L3 bank needs its original admitted exchange: " + id
	var own: Dictionary = saved.exchange
	if not own.id is String or not Codec.is_vector3(own.source_position) or own.source_position != expected_geometry.origin or not own.geometry is Dictionary or own.geometry != expected_geometry or not Codec.is_vector3(own.opening_position) or own.opening_position != target or own.profile_id != state.profile_id or own.world_revision != state.world_revision or saved.encounter_id != KnownRules.HOUSE_EPOCH:
		return "L3 bank must retain original circle/source/opening/profile/world/epoch: " + id
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Codec.in_range(own[key], 0.0, KnownRules.MAX_CLOCK): return "L3 bank requires finite original deadlines: " + id
	for key: String in ["windup_s", "lock_s", "active_s", "recovery_s"]:
		if not Codec.is_number(saved.resolved_role.get(key)) or float(saved.resolved_role[key]) <= 0.0: return "L3 bank requires its prevalidated resolved phase durations: " + id
	if saved.status == "running":
		if saved.phase not in ["warning", "lock", "active", "recovery"]: return "Running L3 bank needs its exact actionable phase: " + id
		var expected_phase: String = "warning" if float(saved.clock_s) < float(own.lock_from_s) else ("lock" if float(saved.clock_s) < float(own.active_from_s) else ("active" if float(saved.clock_s) <= float(own.active_until_s) else "recovery"))
		if saved.phase != expected_phase: return "L3 bank phase differs from its original exact deadlines: " + id
		var matched: bool = false
		for lease: Dictionary in state.scheduler.reservations:
			if lease.source_id == id and lease.id == own.id: matched = true
		if not matched: return "Running L3 bank requires its actual staged Scheduler lease: " + id
	elif saved.phase != "clear": return "Inactive L3 bank cannot retain actionable cosmetics: " + id
	return ""


static func _view_error(id: String, view: Dictionary, saved: Dictionary) -> String:
	var own: Dictionary = saved.exchange
	if not Codec.keys_error(view, KnownRules.VIEW_KEYS).is_empty() or not view.reservation_id is String or view.reservation_id != own.id or view.target_id != BANK_TO_TENDER[id] or not Codec.is_vector3(view.landing) or not Codec.is_vector3(view.attack_position) or not view.equipment_ids is Dictionary or not Codec.in_range(view.primary_time_s, 0.0, KnownRules.MAX_CLOCK) or not Codec.in_range(view.response_complete_s, float(view.primary_time_s), KnownRules.MAX_CLOCK):
		return "L3 bank view must retain its original finite source/Tender response tuple: " + id
	if float(view.primary_time_s) <= float(own.active_until_s) or float(view.response_complete_s) > float(own.recovery_until_s): return "L3 bank response must fit the original full recovery interval: " + id
	return ""


static func _retains_recovery_boundary(saved: Dictionary) -> bool:
	for segment: Variant in saved.trace:
		if segment is Dictionary and Codec.is_number(segment.get("start_s")) and Codec.is_number(segment.get("end_s")) and float(segment.start_s) <= float(saved.exchange.active_until_s) and float(segment.end_s) > float(saved.exchange.active_until_s): return true
	return false


static func _saved_progress(saved: Dictionary) -> float:
	# Same operation order as the existing known/live phase-progress mapping.
	# Copied clocks/deadlines use strict equality above; no clock epsilon.
	if saved.status != "running": return 0.0
	var deadline_key: String = {"warning": "lock_from_s", "lock": "active_from_s", "active": "active_until_s", "recovery": "recovery_until_s"}[saved.phase]
	var duration_key: String = {"warning": "windup_s", "lock": "lock_s", "active": "active_s", "recovery": "recovery_s"}[saved.phase]
	var remaining: float = maxf(float(saved.exchange[deadline_key]) - float(saved.clock_s), 0.0)
	var duration: float = float(saved.resolved_role[duration_key])
	if saved.phase == "warning": duration -= float(saved.resolved_role.lock_s)
	return clampf(1.0 - remaining / maxf(duration, 0.000001), 0.0, 1.0)


static func progress_error(outer: Dictionary) -> String:
	# CinderLevel calls this before local component preflight. Guard the shape
	# and finite earned sequence without assuming nested schemas are validated.
	var error: String = Codec.value_error(outer, -1)
	if error.is_empty(): error = Codec.keys_error(outer, OUTER_KEYS)
	if not error.is_empty(): return "L3 outer progression envelope: " + error
	if outer.api_revision != Level.API_REVISION or not Codec.is_integer(outer.schema_version, Level.SNAPSHOT_SCHEMA_VERSION, Level.SNAPSHOT_SCHEMA_VERSION) or outer.level_id != "A2-L3" or outer.scene_path != "res://scenes/acts/act2/a2_l3.tscn" or not Codec.is_integer(outer.local_snapshot_version, 1, 1) or not outer.local is Dictionary or not outer.progress is Dictionary: return "L3 progression must retain its authored CinderLevel identity"
	var local: Dictionary = outer.local
	var progress: Dictionary = outer.progress
	if not Codec.keys_error(local, LOCAL_KEYS).is_empty() or not local.sequence is Dictionary or not local.pending_checkpoints is Array or not local.completion_pending is bool or not local.exit_requested is bool or not Codec.keys_error(progress, PROGRESS_KEYS).is_empty() or not progress.completed is bool or not progress.checkpoint_ids is Dictionary: return "L3 progression needs the closed local/history dictionaries"
	for key: String in ["completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind"]:
		if not progress[key] is String: return "L3 progression ID/kind must be a string"
	error = Sequence.new().snapshot_error(local.sequence)
	if not error.is_empty(): return error
	var stage: int = int(local.sequence.stage_index)
	var clear: bool = stage == 8
	if (local.completion_pending or local.exit_requested) and not clear: return "L3 final progress intent precedes actual arm disengagement"
	if local.exit_requested and local.completion_pending: return "L3 exit cannot precede committed completion"
	if progress.completed != (clear and not local.completion_pending) or progress.completion_id != ("ruined-house-escape" if progress.completed else "") or progress.contact_exit_id != ("excavation-breakout" if local.exit_requested else ""): return "L3 completion/contact differs from its actual earned escape"
	var expected: Dictionary = {}
	var ordered: Array[String] = []
	for contact: String in local.sequence.crossed_contacts:
		var id: String = Sequence.CONTACTS[contact].checkpoint
		expected[id] = "encounter"
		ordered.append(id)
	if stage >= 7:
		expected["handling-machine-phase-two"] = "boss_phase"
		ordered.append("handling-machine-phase-two")
	if local.pending_checkpoints.size() > 1: return "L3 retains at most one pending earned checkpoint"
	for pending: Variant in local.pending_checkpoints:
		if not pending is String or ordered.is_empty() or pending != ordered.back(): return "L3 pending checkpoint must be the latest earned contact/phase tail"
		expected.erase(pending)
	var current: String = ordered[expected.size() - 1] if not expected.is_empty() else ""
	var kind: String = expected[current] if not current.is_empty() else ""
	if progress.checkpoint_ids != expected or progress.checkpoint_id != current or progress.checkpoint_kind != kind: return "L3 checkpoint history/current kind differs from the exact earned prefix"
	return ""
