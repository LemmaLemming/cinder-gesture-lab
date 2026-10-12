extends RefCounted
## Pure L4 coherence over the closed known14-field local subset, adapted from
## the frozen L3 known-state contract with all boss fields/actions removed.
## Parent first validates actual saved Player, Scheduler, nine native actors,
## Ray aggregate and all four published lane snapshots, including pending2.
## Parent retains native bindings/custody, primary cadence and floor/range/LOS
## checks. Pass a copy with banks AND bank_views removed. No node queries,
## state mutations, leases, clocks, restore calls or gameplay events occur here.

const Sequence: Script = preload("res://scripts/acts/act2/london_approaches_sequence.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Actor: Script = preload("res://scripts/acts/act2/ray_scout_actor.gd")
const Mechanism: Script = preload("res://scripts/combat/lane_mechanism.gd")
const LEVEL_EPOCH: String = "A2-L4-london-approaches"
const HOUSE_EPOCH: String = LEVEL_EPOCH # Retains the existing assembly helper contract.
const WORLD_REVISION: int = 1
const MAX_CLOCK: float = 1000000000.0
const KNOWN_KEYS: Array[String] = ["sequence", "scheduler", "rays", "targets", "mechanisms", "views", "profile_id", "world_revision", "scenic_clock", "last_action_sequence", "contact_seen", "pending_checkpoints", "completion_pending", "exit_requested"]
const TARGET_IDS: Array[String] = ["garden_handler", "flood_tender", "villa_ray_handler", "villa_tender", "villa_smoke_handler", "putney_handler"]
const TOOL_IDS: Array[String] = ["tool_garden_handler", "tool_villa_ray_handler", "tool_villa_smoke_handler", "tool_putney_handler"]
const RAY_IDS: Array[String] = ["flood_scout", "villa_scout", "putney_scout"]
const ACTOR_KEYS: Array[String] = ["api_revision", "schema_version", "actor_id", "max_hp", "hp", "phase", "phase_progress", "direction", "root_position", "body_yaw"]
const MECHANISM_KEYS: Array[String] = ["api_revision", "schema_version", "mechanism_id", "configuration", "status", "phase", "cycle", "clock_s", "resolved_role", "exchange_encounter_id", "exchange", "hero_samples", "hit_ids", "last_cancel_reason"]
const VIEW_KEYS: Array[String] = ["reservation_id", "landing", "attack_position", "target_id", "primary_time_s", "response_complete_s", "equipment_ids"]


static func known_state_error(state: Dictionary) -> String:
	var error: String = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state, KNOWN_KEYS)
	if not error.is_empty(): return "L4 known envelope: " + error
	for key: String in ["sequence", "scheduler", "rays", "targets", "mechanisms", "views"]:
		if not state[key] is Dictionary: return "L4 known envelope needs dictionary " + key
	if state.profile_id not in ["assisted", "standard", "challenge"] or not Codec.is_integer(state.world_revision, WORLD_REVISION, WORLD_REVISION) or not Codec.in_range(state.scenic_clock, 0.0, MAX_CLOCK) or not Codec.is_integer(state.last_action_sequence) or not state.contact_seen is String or not state.pending_checkpoints is Array or not state.completion_pending is bool or not state.exit_requested is bool:
		return "Invalid L4 known profile/clock/cursor/intent"
	error = Sequence.new().snapshot_error(state.sequence)
	if not error.is_empty(): return error
	var stage: int = int(state.sequence.stage_index)
	var beat: String = Sequence.STAGES[stage]
	if not state.contact_seen.is_empty() and (state.contact_seen != beat or not Sequence.CONTACTS.has(beat)):
		return "L4 retained contact must name the current real contact boundary"
	if (state.completion_pending or state.exit_requested) and beat != "clear": return "L4 final intent precedes all nine earned defeats"
	if state.exit_requested and state.completion_pending: return "L4 contact exit must follow committed completion"
	if state.pending_checkpoints.size() > 1: return "L4 retains at most one pending earned boundary"
	var earned: Array[String] = []
	for contact: String in state.sequence.crossed_contacts: earned.append(Sequence.CONTACTS[contact].checkpoint)
	for checkpoint: Variant in state.pending_checkpoints:
		if not checkpoint is String or earned.is_empty() or checkpoint != earned.back(): return "L4 pending checkpoint must be the latest earned contact tail"
	if not Codec.keys_error(state.targets, TARGET_IDS).is_empty() or not Codec.keys_error(state.mechanisms, TOOL_IDS).is_empty(): return "L4 requires all six non-Ray targets and all four actual tool snapshots"
	if not state.rays.get("actors") is Dictionary or not state.rays.get("records") is Dictionary or not Codec.keys_error(state.rays.actors, RAY_IDS).is_empty() or not Codec.keys_error(state.rays.records, RAY_IDS).is_empty(): return "L4 Ray actors/cycles must retain all three authored Scouts"
	if not Codec.in_range(state.scheduler.get("clock_s"), 0.0, MAX_CLOCK) or not state.scheduler.get("encounter_id") is String or not state.scheduler.get("profile") is Dictionary or not state.scheduler.get("reservations") is Array or not Codec.is_integer(state.scheduler.get("world_revision"), WORLD_REVISION, WORLD_REVISION) or state.scheduler.world_revision != state.world_revision:
		return "L4 known coherence requires the prevalidated Scheduler envelope"
	var ended: bool = state.scheduler.encounter_id.is_empty()
	if ended:
		if beat != "clear" or state.completion_pending or not state.scheduler.profile.is_empty() or not state.scheduler.reservations.is_empty(): return "Ended L4 Scheduler must follow committed quiet clear"
	elif state.scheduler.encounter_id != LEVEL_EPOCH or state.scheduler.profile.get("id") != state.profile_id:
		return "L4 live or cloud-tail Scheduler must retain the original fixed epoch/profile"
	if not Codec.is_number(state.rays.get("clock_s")) or float(state.rays.clock_s) != float(state.scheduler.clock_s): return "L4 Ray transport must share the exact Scheduler clock"
	var targets: Dictionary = {}
	for id: String in TARGET_IDS:
		if not state.targets[id] is Dictionary: return "L4 target snapshot must be a dictionary"
		targets[id] = state.targets[id]
	for id: String in RAY_IDS:
		if not state.rays.actors[id] is Dictionary or not state.rays.records[id] is Dictionary: return "L4 requires every prevalidated Scout actor/cycle"
		targets[id] = state.rays.actors[id]
	for id: String in Sequence.ACTORS:
		error = _target_error(id, targets[id])
		if not error.is_empty(): return error
		var actor: Dictionary = targets[id]
		if (float(actor.hp) <= 0.0) != state.sequence.defeated_ids.has(id): return "L4 actor HP differs from its earned defeat prefix: " + id
		if stage < int(Sequence.DEFEAT_STAGE[id]):
			if float(actor.hp) != 30.0: return "Future L4 target cannot lose health: " + id
			# Tender phase/independent bank correspondence is checked by SmokeRules.
			if not Sequence.TENDERS.has(id) and (actor.phase != "idle" or float(actor.phase_progress) != 0.0): return "Future L4 target must retain idle cosmetics: " + id
	for id: String in RAY_IDS:
		var ray: Dictionary = state.rays.records[id]
		if not ray.has_all(["status", "cycle"]) or ray.status not in ["idle", "running", "cancelled", "complete", "defeated"] or not Codec.is_integer(ray.cycle): return "L4 requires every finite prevalidated Ray cycle"
		if stage < int(Sequence.DEFEAT_STAGE[id]) and (ray.status != "idle" or int(ray.cycle) != 0): return "Future L4 Scout must retain its unstarted driver: " + id
		if (ray.status == "defeated") != (float(targets[id].hp) <= 0.0): return "L4 Ray defeat receipt must match its real actor: " + id
		if float(targets[id].hp) < 30.0 and int(ray.cycle) < 1: return "Damaged L4 Scout requires an actual executed recovery cycle: " + id
		if ray.status == "running" and (ended or not state.sequence.active_ids.has(id)): return "Only a current L4 Scout may retain a Ray lease: " + id
	for id: String in TOOL_IDS:
		var saved: Variant = state.mechanisms[id]
		if not saved is Dictionary: return "L4 consumer snapshot must be a dictionary"
		error = _tool_error(id, saved, float(state.scheduler.clock_s))
		if not error.is_empty(): return error
		var target_id: String = _tool_target(id)
		if stage < int(Sequence.DEFEAT_STAGE[target_id]) and (saved.status != "idle" or int(saved.cycle) != 0): return "Future L4 tool must retain its unstarted cycle: " + id
		if saved.status == "running":
			if ended or not state.sequence.active_ids.has(target_id) or float(targets[target_id].hp) <= 0.0: return "Only an actual living current L4 target may retain a tool attack"
			if not state.views.has(id): return "Running L4 tool requires its framing witness"
		if float(targets[target_id].hp) < 30.0 and int(saved.cycle) < 1: return "Damaged L4 Handler requires an actual executed recovery consumer"
		if int(saved.cycle) > 0:
			if saved.exchange.source_position != targets[target_id].root_position or saved.exchange.opening_position != targets[target_id].root_position or saved.exchange.profile_id != state.profile_id or saved.exchange.world_revision != state.world_revision:
				return "L4 executed tool retains its exact anchored source/opening/profile/world"
		error = _pose_error(targets[target_id], saved)
		if not error.is_empty(): return target_id + ": " + error
	for id: Variant in state.views:
		if not id is String or not state.mechanisms.has(id) or state.mechanisms[id].status != "running" or not state.views[id] is Dictionary: return "L4 tool view cannot outlive its running consumer"
		var view: Dictionary = state.views[id]
		var own: Dictionary = state.mechanisms[id].exchange
		var target_id: String = _tool_target(id)
		if not Codec.keys_error(view, VIEW_KEYS).is_empty() or not view.reservation_id is String or view.reservation_id != own.id or view.target_id != target_id or not Codec.is_vector3(view.landing) or not Codec.is_vector3(view.attack_position) or not view.equipment_ids is Dictionary or not Codec.in_range(view.primary_time_s, 0.0, MAX_CLOCK) or not Codec.in_range(view.response_complete_s, float(view.primary_time_s), MAX_CLOCK): return "L4 view must retain its original source/target/finite response tuple"
		if float(view.primary_time_s) <= float(own.active_until_s) or float(view.response_complete_s) > float(own.recovery_until_s): return "L4 response must fit the original actual recovery interval"
	return ""


static func _target_error(id: String, actor: Dictionary) -> String:
	if not Codec.keys_error(actor, ACTOR_KEYS).is_empty() or actor.api_revision != Actor.SNAPSHOT_API_REVISION or not Codec.is_integer(actor.schema_version, Actor.SNAPSHOT_SCHEMA_VERSION, Actor.SNAPSHOT_SCHEMA_VERSION) or actor.actor_id != id or not Codec.is_number(actor.max_hp) or float(actor.max_hp) != 30.0 or not Codec.in_range(actor.hp, 0.0, 30.0) or actor.phase not in Actor.PHASES or not Codec.in_range(actor.phase_progress, 0.0, 1.0) or not Codec.is_vector3(actor.root_position) or actor.root_position != Codec.vector3(Sequence.ACTORS[id]) or not Codec.is_vector3(actor.direction) or not Codec.is_number(actor.body_yaw):
		return "L4 target must preserve its finite HP30/root/actor schema: " + id
	if (actor.phase == "defeated") != (float(actor.hp) <= 0.0): return "L4 target spent phase must match its actual HP: " + id
	if not RAY_IDS.has(id) and (actor.direction != [0.0, 0.0, 1.0] or float(actor.body_yaw) != 0.0): return "L4 fixed non-Ray target retains original +Z/zero-yaw pose: " + id
	return ""


static func _tool_error(id: String, saved: Dictionary, clock: float) -> String:
	var keys: Array[String] = MECHANISM_KEYS.duplicate()
	if saved.get("schema_version") == 2: keys.append("pending_segments")
	if not Codec.keys_error(saved, keys).is_empty() or saved.api_revision != Mechanism.API_REVISION or not Codec.is_integer(saved.schema_version, 1, 2) or saved.mechanism_id != id or saved.status not in ["idle", "running", "complete", "cancelled"] or not saved.phase is String or not Codec.is_integer(saved.cycle) or not Codec.is_number(saved.clock_s) or float(saved.clock_s) != clock or not saved.configuration is Dictionary or not saved.resolved_role is Dictionary or not saved.exchange is Dictionary or not saved.hero_samples is Dictionary or not saved.hit_ids is Array or not saved.exchange_encounter_id is String or not saved.last_cancel_reason is String:
		return "L4 consumer must retain its published schema/exact paired clock: " + id
	if saved.schema_version == 2 and not saved.pending_segments is Dictionary: return "L4 retains the complete published pending2 path dictionary"
	if saved.status == "idle":
		return "L4 unstarted consumer cannot retain a cycle/exchange/role" if int(saved.cycle) != 0 or saved.phase != "clear" or not saved.exchange.is_empty() or not saved.resolved_role.is_empty() else ""
	if int(saved.cycle) < 1 or not Codec.keys_error(saved.exchange, Mechanism.EXCHANGE_KEYS).is_empty(): return "L4 executed tool requires its original admitted exchange"
	for key: String in ["source_position", "opening_position"]:
		if not Codec.is_vector3(saved.exchange[key]): return "L4 exchange retains finite source/opening triples"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Codec.in_range(saved.exchange[key], 0.0, MAX_CLOCK): return "L4 exchange retains finite original deadlines"
	if not saved.exchange.id is String or saved.exchange.profile_id not in ["assisted", "standard", "challenge"]: return "L4 exchange retains its prevalidated lease/profile identity"
	if saved.status == "running":
		if saved.phase not in ["warning", "lock", "active", "recovery"] or saved.exchange_encounter_id != LEVEL_EPOCH: return "Running L4 consumer must retain its actual current phase/epoch"
	elif saved.phase != "clear": return "Inactive L4 consumer cannot retain an actionable phase"
	for key: String in ["windup_s", "lock_s", "active_s", "recovery_s"]:
		if not Codec.is_number(saved.resolved_role.get(key)) or float(saved.resolved_role[key]) <= 0.0: return "L4 tool requires its prevalidated finite resolved durations"
	return ""


static func _pose_error(actor: Dictionary, saved: Dictionary) -> String:
	var expected_phase: String = "defeated" if float(actor.hp) <= 0.0 else (String(saved.phase) if saved.status == "running" else "idle")
	var expected_progress: float = 1.0 if float(actor.hp) <= 0.0 else _saved_progress(saved)
	return "Tool actor phase/progress differs from its exact saved consumer clock" if actor.phase != expected_phase or float(actor.phase_progress) != expected_progress else ""


static func _saved_progress(saved: Dictionary) -> float:
	# Preserve the existing live/restore phase arithmetic and operation order.
	if saved.status != "running": return 0.0
	var key: String = {"warning": "lock_from_s", "lock": "active_from_s", "active": "active_until_s", "recovery": "recovery_until_s"}[saved.phase]
	var duration_key: String = {"warning": "windup_s", "lock": "lock_s", "active": "active_s", "recovery": "recovery_s"}[saved.phase]
	var remaining: float = maxf(float(saved.exchange[key]) - float(saved.clock_s), 0.0)
	var duration: float = float(saved.resolved_role[duration_key])
	if saved.phase == "warning": duration -= float(saved.resolved_role.lock_s)
	return clampf(1.0 - remaining / maxf(duration, 0.000001), 0.0, 1.0)


static func _tool_target(id: String) -> String:
	return id.substr(5)
