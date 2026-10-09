extends RefCounted
## Pure L3 coherence over the closed known17-field subset of a local aggregate.
## Parent validates the final envelope and every native/public component schema,
## saved Player/input, exact admitted primary cadence, floor/range/LOS support,
## and the eventual published bank snapshots. No bank fields or API are guessed.
## Pass local.duplicate() with only banks removed, after nested prevalidation.
## This helper does not mutate input, query native nodes, allocate leases, restore
## actors, emit events or establish a complete playable/transport acceptance.

const Sequence: Script = preload("res://scripts/acts/act2/ruined_house_sequence.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Actor: Script = preload("res://scripts/acts/act2/ray_scout_actor.gd")
const Mechanism: Script = preload("res://scripts/combat/lane_mechanism.gd")
const HOUSE_EPOCH: String = "A2-L3-ruined-house"
const WORLD_REVISION: int = 1
const MAX_CLOCK: float = 1000000000.0
const KNOWN_KEYS: Array[String] = ["sequence", "scheduler", "rays", "targets", "mechanisms", "views", "profile_id", "world_revision", "scenic_clock", "last_action_sequence", "contact_seen", "pending_checkpoints", "completion_pending", "exit_requested", "boss_phase_pending", "boss_next_action", "boss_ready_s"]
const TARGET_IDS: Array[String] = ["road_tender", "house_tender", "house_handler", "apron_handler", "handling_machine", "side_tender"]
const TOOL_IDS: Array[String] = ["tool_house_handler", "tool_apron_handler", "boss_reach", "boss_place"]
const ACTOR_KEYS: Array[String] = ["api_revision", "schema_version", "actor_id", "max_hp", "hp", "phase", "phase_progress", "direction", "root_position", "body_yaw"]
const MECHANISM_KEYS: Array[String] = ["api_revision", "schema_version", "mechanism_id", "configuration", "status", "phase", "cycle", "clock_s", "resolved_role", "exchange_encounter_id", "exchange", "hero_samples", "hit_ids", "last_cancel_reason"]
const VIEW_KEYS: Array[String] = ["reservation_id", "landing", "attack_position", "target_id", "primary_time_s", "response_complete_s", "equipment_ids"]


static func known_state_error(state: Dictionary) -> String:
	var error: String = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state, KNOWN_KEYS)
	if not error.is_empty(): return "L3 known envelope: " + error
	for key: String in ["sequence", "scheduler", "rays", "targets", "mechanisms", "views"]:
		if not state[key] is Dictionary: return "L3 known envelope needs dictionary " + key
	if state.profile_id not in ["assisted", "standard", "challenge"] or not Codec.is_integer(state.world_revision, WORLD_REVISION, WORLD_REVISION) or not Codec.in_range(state.scenic_clock, 0.0, MAX_CLOCK) or not Codec.is_integer(state.last_action_sequence) or not state.contact_seen is String or not state.pending_checkpoints is Array or not state.completion_pending is bool or not state.exit_requested is bool or not state.boss_phase_pending is bool or state.boss_next_action not in ["reach", "place"] or not Codec.in_range(state.boss_ready_s, 0.0, MAX_CLOCK):
		return "Invalid L3 known profile/clock/cursor/intent"
	error = Sequence.new().snapshot_error(state.sequence)
	if not error.is_empty(): return error
	var stage: int = int(state.sequence.stage_index)
	var beat: String = Sequence.STAGES[stage]
	if not state.contact_seen.is_empty() and (state.contact_seen != beat or not Sequence.CONTACTS.has(beat)):
		return "L3 retained contact must name the current real contact boundary"
	if (state.completion_pending or state.exit_requested) and beat != "clear": return "L3 final intent precedes earned local arm disengagement"
	if state.exit_requested and state.completion_pending: return "L3 contact exit must follow committed completion"
	if state.pending_checkpoints.size() > 1: return "L3 retains at most one pending earned boundary"
	var earned: Array[String] = []
	for contact: String in state.sequence.crossed_contacts: earned.append(Sequence.CONTACTS[contact].checkpoint)
	if stage >= 7: earned.append("handling-machine-phase-two")
	for checkpoint: Variant in state.pending_checkpoints:
		if not checkpoint is String or earned.is_empty() or checkpoint != earned.back(): return "L3 pending checkpoint must be the latest earned contact/phase tail"
	if not Codec.keys_error(state.targets, TARGET_IDS).is_empty() or not Codec.keys_error(state.mechanisms, TOOL_IDS).is_empty(): return "L3 requires all six non-Ray targets and all four known tool snapshots"
	if not state.rays.get("actors") is Dictionary or not state.rays.get("records") is Dictionary or not Codec.keys_error(state.rays.actors, ["apron_scout"]).is_empty() or not Codec.keys_error(state.rays.records, ["apron_scout"]).is_empty(): return "L3 Ray actor/cycle belongs only to the apron Scout"
	if not Codec.in_range(state.scheduler.get("clock_s"), 0.0, MAX_CLOCK) or not state.scheduler.get("encounter_id") is String or not state.scheduler.get("profile") is Dictionary or not state.scheduler.get("reservations") is Array or not Codec.is_integer(state.scheduler.get("world_revision"), WORLD_REVISION, WORLD_REVISION) or state.scheduler.world_revision != state.world_revision:
		return "L3 known coherence requires the prevalidated Scheduler envelope"
	var ended: bool = state.scheduler.encounter_id.is_empty()
	if ended:
		if beat != "clear" or state.completion_pending or not state.scheduler.profile.is_empty() or not state.scheduler.reservations.is_empty(): return "Ended L3 Scheduler must follow committed quiet clear"
	elif state.scheduler.encounter_id != HOUSE_EPOCH or state.scheduler.profile.get("id") != state.profile_id:
		return "L3 live or cloud-tail Scheduler must retain the original fixed epoch/profile"
	if not Codec.is_number(state.rays.get("clock_s")) or float(state.rays.clock_s) != float(state.scheduler.clock_s): return "L3 Ray transport must share the exact Scheduler clock"
	var targets: Dictionary = {}
	for id: String in TARGET_IDS:
		if not state.targets[id] is Dictionary: return "L3 target snapshot must be a dictionary"
		var wrapped: Dictionary = state.targets[id]
		if id == "handling_machine":
			if not Codec.keys_error(wrapped, ["version", "actor", "boss_phase", "transition_pending", "tool_action"]).is_empty() or not wrapped.version is int or wrapped.version != 1 or not wrapped.actor is Dictionary or not wrapped.boss_phase is int or wrapped.boss_phase not in [1, 2] or not wrapped.transition_pending is bool or wrapped.tool_action not in ["reach", "place"]:
				return "L3 B02 requires its complete original phase/action wrapper"
			targets[id] = wrapped.actor
		else: targets[id] = wrapped
	if not state.rays.actors.apron_scout is Dictionary or not state.rays.records.apron_scout is Dictionary: return "L3 requires the prevalidated apron Scout actor/cycle"
	targets["apron_scout"] = state.rays.actors.apron_scout
	for id: String in Sequence.ACTORS:
		error = _target_error(id, targets[id])
		if not error.is_empty(): return error
		var actor: Dictionary = targets[id]
		if (float(actor.hp) <= 0.0) != state.sequence.defeated_ids.has(id): return "L3 actor HP differs from its earned defeat prefix: " + id
		var first_stage: int = 6 if id == "handling_machine" else int(Sequence.DEFEAT_STAGE[id])
		if stage < first_stage:
			if float(actor.hp) != 30.0: return "Future L3 target cannot lose health: " + id
			# Tender phase/independent bank correspondence is deliberately parent-owned.
			if not Sequence.TENDERS.has(id) and (actor.phase != "idle" or float(actor.phase_progress) != 0.0): return "Future known L3 target must retain idle cosmetics: " + id
	var ray: Dictionary = state.rays.records.apron_scout
	if not ray.has_all(["status", "cycle"]) or ray.status not in ["idle", "running", "cancelled", "complete", "defeated"] or not Codec.is_integer(ray.cycle): return "L3 requires the finite prevalidated Ray cycle"
	if stage < 4 and (ray.status != "idle" or int(ray.cycle) != 0): return "Future apron Scout must retain its unstarted driver"
	if (ray.status == "defeated") != (float(targets.apron_scout.hp) <= 0.0): return "L3 Ray defeat receipt must match its real actor"
	if ray.status == "running" and (ended or not state.sequence.active_ids.has("apron_scout")): return "Only the current apron Scout may retain a Ray lease"
	var boss: Dictionary = state.targets.handling_machine
	var boss_actor: Dictionary = targets.handling_machine
	if state.boss_phase_pending != boss.transition_pending: return "L3 root and B02 must retain the same pending threshold"
	if stage < 6:
		if boss.boss_phase != 1 or float(boss_actor.hp) != 30.0 or boss.transition_pending: return "Future B02 must retain its untouched first phase"
	elif stage == 6:
		if boss.boss_phase != 1 or float(boss_actor.hp) < 15.0 or boss.transition_pending != (float(boss_actor.hp) == 15.0): return "B02 phase1 retains its exact HP15 closed threshold"
		# HP15+pending remains legal when the same tick killed the Hero. No
		# checkpoint, phase commit or health refill occurs inside this pure helper.
	else:
		if boss.boss_phase != 2 or float(boss_actor.hp) > 15.0 or boss.transition_pending: return "B02 phase2 cannot refill health or retain first-phase intent"
	var ready: float = 0.0
	var running_boss: String = ""
	for id: String in TOOL_IDS:
		var saved: Variant = state.mechanisms[id]
		if not saved is Dictionary: return "L3 known consumer snapshot must be a dictionary"
		error = _tool_error(id, saved, float(state.scheduler.clock_s))
		if not error.is_empty(): return error
		var target_id: String = _tool_target(id)
		var first_stage: int = 6 if id.begins_with("boss_") else int(Sequence.DEFEAT_STAGE[target_id])
		if stage < first_stage and (saved.status != "idle" or int(saved.cycle) != 0): return "Future L3 tool must retain its unstarted cycle: " + id
		if saved.status == "running":
			if ended or not state.sequence.active_ids.has(target_id) or float(targets[target_id].hp) <= 0.0: return "Only an actual living current L3 target may retain a tool attack"
			if not state.views.has(id): return "Running L3 known tool requires its framing witness"
			if id.begins_with("boss_"):
				if not running_boss.is_empty(): return "Reach and Place cannot retain simultaneous B02 leases"
				running_boss = id
		if id.begins_with("boss_") and int(saved.cycle) > 0:
			ready = maxf(ready, float(saved.exchange.cooldown_until_s))
		if not id.begins_with("boss_"):
			if float(targets[target_id].hp) < 30.0 and int(saved.cycle) < 1: return "Damaged L3 Handler requires its actual executed recovery consumer"
			error = _pose_error(targets[target_id], saved)
			if not error.is_empty(): return target_id + ": " + error
	if float(state.boss_ready_s) != ready: return "B02 shared tool deadline must equal the exact maximum retained admitted cooldown"
	if float(boss_actor.hp) < 30.0 and ready == 0.0: return "B02 damage/phase threshold requires an actually executed known tool cycle"
	if not running_boss.is_empty():
		var action: String = running_boss.substr(5)
		if boss.tool_action != action or state.boss_next_action != action: return "Running B02 must select its one actual Reach/Place action"
		error = _pose_error(boss_actor, state.mechanisms[running_boss])
	else:
		# Selection may change during a pure-preview attempt before any accepted
		# cycle; no equivalence with the latest executed/next action is invented.
		var expected_phase: String = "defeated" if float(boss_actor.hp) <= 0.0 else "idle"
		var expected_progress: float = 1.0 if float(boss_actor.hp) <= 0.0 else 0.0
		error = "B02 idle/spent pose differs from its actual inactive tools" if boss_actor.phase != expected_phase or float(boss_actor.phase_progress) != expected_progress else ""
	if not error.is_empty(): return error
	for id: Variant in state.views:
		if not id is String or not state.mechanisms.has(id) or state.mechanisms[id].status != "running" or not state.views[id] is Dictionary: return "L3 known view cannot outlive its running tool"
		var view: Dictionary = state.views[id]
		var own: Dictionary = state.mechanisms[id].exchange
		var target_id: String = _tool_target(id)
		if not Codec.keys_error(view, VIEW_KEYS).is_empty() or not view.reservation_id is String or view.reservation_id != own.id or view.target_id != target_id or not Codec.is_vector3(view.landing) or not Codec.is_vector3(view.attack_position) or not view.equipment_ids is Dictionary or not Codec.in_range(view.primary_time_s, 0.0, MAX_CLOCK) or not Codec.in_range(view.response_complete_s, float(view.primary_time_s), MAX_CLOCK): return "L3 known view must retain its original source/target/finite response tuple"
		if own.source_position != targets[target_id].root_position or own.opening_position != targets[target_id].root_position: return "L3 known tool source and ordinary-primary mount must retain the actual anchored target"
		if float(view.primary_time_s) <= float(own.active_until_s) or float(view.response_complete_s) > float(own.recovery_until_s): return "L3 known response must fit the original actual recovery interval"
	return ""


static func _target_error(id: String, actor: Dictionary) -> String:
	if not Codec.keys_error(actor, ACTOR_KEYS).is_empty() or actor.api_revision != Actor.SNAPSHOT_API_REVISION or not Codec.is_integer(actor.schema_version, Actor.SNAPSHOT_SCHEMA_VERSION, Actor.SNAPSHOT_SCHEMA_VERSION) or actor.actor_id != id or not Codec.is_number(actor.max_hp) or float(actor.max_hp) != 30.0 or not Codec.in_range(actor.hp, 0.0, 30.0) or actor.phase not in Actor.PHASES or not Codec.in_range(actor.phase_progress, 0.0, 1.0) or not Codec.is_vector3(actor.root_position) or actor.root_position != Codec.vector3(Sequence.ACTORS[id]) or not Codec.is_vector3(actor.direction) or not Codec.is_number(actor.body_yaw):
		return "L3 target must preserve its finite HP30/root/actor schema: " + id
	if (actor.phase == "defeated") != (float(actor.hp) <= 0.0): return "L3 target spent phase must match its actual HP: " + id
	if id != "apron_scout" and (actor.direction != [0.0, 0.0, 1.0] or float(actor.body_yaw) != 0.0): return "L3 fixed non-Ray target retains original +Z/zero-yaw pose: " + id
	return ""


static func _tool_error(id: String, saved: Dictionary, clock: float) -> String:
	var keys: Array[String] = MECHANISM_KEYS.duplicate()
	if saved.get("schema_version") == 2: keys.append("pending_segments")
	if not Codec.keys_error(saved, keys).is_empty() or saved.api_revision != Mechanism.API_REVISION or not Codec.is_integer(saved.schema_version, 1, 2) or saved.mechanism_id != id or saved.status not in ["idle", "running", "complete", "cancelled"] or not saved.phase is String or not Codec.is_integer(saved.cycle) or not Codec.is_number(saved.clock_s) or float(saved.clock_s) != clock or not saved.configuration is Dictionary or not saved.resolved_role is Dictionary or not saved.exchange is Dictionary or not saved.hero_samples is Dictionary or not saved.hit_ids is Array or not saved.exchange_encounter_id is String or not saved.last_cancel_reason is String:
		return "L3 known consumer must retain its published schema/exact paired clock: " + id
	if saved.schema_version == 2 and not saved.pending_segments is Dictionary: return "L3 retains the complete published pending2 path dictionary"
	if saved.status == "idle":
		return "L3 unstarted consumer cannot retain a cycle/exchange/role" if int(saved.cycle) != 0 or saved.phase != "clear" or not saved.exchange.is_empty() or not saved.resolved_role.is_empty() else ""
	if int(saved.cycle) < 1 or not Codec.keys_error(saved.exchange, Mechanism.EXCHANGE_KEYS).is_empty(): return "L3 executed known tool requires its original admitted exchange"
	for key: String in ["source_position", "opening_position"]:
		if not Codec.is_vector3(saved.exchange[key]): return "L3 known exchange retains finite source/opening triples"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Codec.in_range(saved.exchange[key], 0.0, MAX_CLOCK): return "L3 known exchange retains finite original deadlines"
	if not saved.exchange.id is String or saved.exchange.profile_id not in ["assisted", "standard", "challenge"]: return "L3 known exchange retains its prevalidated lease/profile identity"
	if saved.status == "running":
		if saved.phase not in ["warning", "lock", "active", "recovery"] or saved.exchange_encounter_id != HOUSE_EPOCH: return "Running L3 known consumer must retain its actual current phase/epoch"
	else:
		if saved.phase != "clear": return "Inactive known L3 consumer cannot retain an actionable phase"
	for key: String in ["windup_s", "lock_s", "active_s", "recovery_s"]:
		if not Codec.is_number(saved.resolved_role.get(key)) or float(saved.resolved_role[key]) <= 0.0: return "L3 known tool requires its prevalidated finite resolved durations"
	return ""


static func _pose_error(actor: Dictionary, saved: Dictionary) -> String:
	var expected_phase: String = "defeated" if float(actor.hp) <= 0.0 else (String(saved.phase) if saved.status == "running" else "idle")
	var expected_progress: float = 1.0 if float(actor.hp) <= 0.0 else _saved_progress(saved)
	return "Known tool actor phase/progress differs from its exact saved consumer clock" if actor.phase != expected_phase or float(actor.phase_progress) != expected_progress else ""


static func _saved_progress(saved: Dictionary) -> float:
	# Identical arithmetic/order to Weybridge's saved-progress and live phase
	# helper. Never use wall time, Scheduler stepping or copied-clock epsilon.
	if saved.status != "running": return 0.0
	var key: String = {"warning": "lock_from_s", "lock": "active_from_s", "active": "active_until_s", "recovery": "recovery_until_s"}[saved.phase]
	var duration_key: String = {"warning": "windup_s", "lock": "lock_s", "active": "active_s", "recovery": "recovery_s"}[saved.phase]
	var remaining: float = maxf(float(saved.exchange[key]) - float(saved.clock_s), 0.0)
	var duration: float = float(saved.resolved_role[duration_key])
	if saved.phase == "warning": duration -= float(saved.resolved_role.lock_s)
	return clampf(1.0 - remaining / maxf(duration, 0.000001), 0.0, 1.0)


static func _tool_target(id: String) -> String:
	return "handling_machine" if id.begins_with("boss_") else id.substr(5)
