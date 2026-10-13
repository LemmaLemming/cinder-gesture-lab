class_name CinderAct3MirrorEchoCodec
extends RefCounted
## Owned stationary HP/resource custody. The parent first validates the actual
## Hero, then this source, staged Scheduler and complete canonical Playback.
## Quiet commit order: Hero -> source -> Scheduler -> Playback -> phase verify.

const ExactTransport = preload("res://scripts/campaign/exact_json.gd")
const SourceValue = preload("res://scripts/campaign/snapshot_codec.gd")
const EnemyPlan = preload("res://scripts/combat/authored_enemy_sequence.gd")
const PhaseReader = preload("res://scripts/combat/replay_cursor.gd")
const API: String = "act3-mirror-echo-source-1"
const ACTOR_PATH: String = "res://scripts/acts/act3/mirror_echo.gd"
const MAX_SOURCE_HITS: int = 4096
const KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "source_epoch", "generation", "sequence", "native", "hp", "max_hp", "alive", "source_hits", "hit_receipts", "defeated_at_s", "physical", "phase", "clock_s"]
const HIT_KEYS: Array[String] = ["clock_s", "hp_before", "hp_damage", "hp_after", "phase"]


func capture(actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> Dictionary:
	var error: String = _boundary(actor)
	if not error.is_empty():
		if _actual_actor(actor):
			actor.source_snapshot_error = error
		return {}
	var binding: Dictionary = actor.get_authored_echo_binding()
	var snapshot: Dictionary = {"api_revision": API, "schema_version": 1, "source_id": binding.source_id, "source_epoch": binding.source_epoch, "generation": binding.generation, "sequence": actor.source_program(), "native": actor.native_descriptor(), "hp": actor.hp, "max_hp": actor.max_hp, "alive": not actor.dead, "source_hits": actor.source_hits, "hit_receipts": actor.source_hit_receipts(), "defeated_at_s": actor.defeated_at_s, "physical": {"position": SourceValue.vector3(actor.global_position), "basis": _basis(actor.global_basis)}, "phase": actor.source_phase(), "clock_s": actor.source_clock()}
	actor.source_snapshot_error = record_error(snapshot, actor, player, scheduler, playback)
	return snapshot.duplicate(true) if actor.source_snapshot_error.is_empty() else {}


func record_error(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> String:
	var error: String = _boundary(actor)
	if not error.is_empty():
		return error
	if ExactTransport.stringify(snapshot).is_empty() or not SourceValue.keys_error(snapshot, KEYS).is_empty() or not snapshot.api_revision is String or snapshot.api_revision != API or not snapshot.schema_version is int or snapshot.schema_version != 1:
		return "Closed exact production Mirror Echo source envelope required"
	var binding: Dictionary = actor.get_authored_echo_binding()
	var program: Dictionary = actor.source_program()
	if not snapshot.source_id is String or not snapshot.source_epoch is String or snapshot.source_id != binding.source_id or snapshot.source_epoch != binding.source_epoch or not snapshot.generation is int or snapshot.generation != binding.generation or not _same(snapshot.sequence, program) or not _same(snapshot.native, actor.native_descriptor()):
		return "Retained actual source/native resources/immutable authored definition/generation differs"
	if not snapshot.max_hp is float or not _same(snapshot.max_hp, float(program.resolved_role.max_hp)) or not _same(snapshot.max_hp, actor.max_hp) or not snapshot.hp is float or not SourceValue.in_range(snapshot.hp, 0.0, snapshot.max_hp) or not snapshot.alive is bool or snapshot.alive != (snapshot.hp > 0.0) or not snapshot.source_hits is int or not SourceValue.is_integer(snapshot.source_hits, 0, MAX_SOURCE_HITS) or not snapshot.hit_receipts is Array or snapshot.hit_receipts.size() != snapshot.source_hits:
		return "Finite exact HP, lifecycle and complete accepted-hit receipt prefix required"
	if not snapshot.clock_s is float or not SourceValue.in_range(snapshot.clock_s, 0.0, 1000000.0):
		return "Finite exact source aggregate clock required"
	if not snapshot.physical is Dictionary or not SourceValue.keys_error(snapshot.physical, ["position", "basis"]).is_empty() or not _same(snapshot.physical.position, SourceValue.vector3(binding.knot_position)) or not _same(snapshot.physical.basis, _basis(Basis.IDENTITY)):
		return "Saved actual HP target must remain at its fixed native knot and identity basis"
	if not player.get("actor_type") is String or player.actor_type != "CinderPlayer" or not player.get("resources") is Dictionary or not player.get("world_actions") is Dictionary or not player.world_actions.get("clock_s") is float or not scheduler.get("clock_s") is float or not playback.get("clock_s") is float or not _same(snapshot.clock_s, player.world_actions.clock_s) or not _same(snapshot.clock_s, scheduler.clock_s) or not _same(snapshot.clock_s, playback.clock_s):
		return "Independent saved Hero/Scheduler/Playback must share the exact source clock"
	if not scheduler.get("profile") is Dictionary or scheduler.profile.get("id") != program.profile_id:
		return "Saved Scheduler profile must retain this source's resolved authored program"
	if not playback.get("api_revision") is String or playback.api_revision != "authored-echo-playback-1" or not playback.get("source_id") is String or not playback.get("source_epoch") is String or playback.source_id != snapshot.source_id or playback.source_epoch != snapshot.source_epoch or not _same(playback.get("generation"), snapshot.generation) or not _same(playback.get("sequence"), snapshot.sequence) or not playback.get("cursor") is Dictionary or not playback.cursor.get("phase") is String or not playback.get("status") is String or playback.status not in ["running", "cancelled", "complete"] or not playback.get("exchange") is Dictionary:
		return "Original canonical authored Playback owner, generation and phase required; idle is unsupported by shared28"
	var exchange: Dictionary = playback.exchange
	if not exchange.get("active_until_s") is float or not exchange.get("recovery_until_s") is float or not SourceValue.in_range(exchange.active_until_s, 0.0, 1000000.0) or not SourceValue.in_range(exchange.recovery_until_s, float(exchange.active_until_s), 1000000.0):
		return "Actual retained exchange recovery deadlines required"
	var expected_phase: String = "defeated" if not snapshot.alive else (String(playback.cursor.phase) if playback.status == "running" else String(playback.status))
	if not snapshot.phase is String or snapshot.phase != expected_phase:
		return "Owned source lifecycle phase must join complete saved Playback phase"
	error = _hits_error(snapshot, playback)
	if not error.is_empty():
		return error
	if snapshot.alive:
		if snapshot.defeated_at_s != null:
			return "Living source cannot retain a defeat clock"
	else:
		if not snapshot.defeated_at_s is float or not SourceValue.in_range(snapshot.defeated_at_s, 0.0, snapshot.clock_s) or snapshot.hit_receipts.is_empty() or not _same(snapshot.defeated_at_s, snapshot.hit_receipts[-1].clock_s):
			return "Defeated source must retain its actual lethal receipt clock"
		if playback.status == "cancelled":
			if playback.get("reason") != "authored_source_defeated" or not _same(playback.get("cancelled_at_s"), snapshot.defeated_at_s) or not _same(snapshot.clock_s, snapshot.defeated_at_s) or not playback.get("cancellation") is Dictionary or playback.cancellation.get("kind") != "authored_replay":
				return "Recovery defeat requires its genuine exact-clock cancellation tombstone; late cancelled transport is unsupported by shared28"
		elif playback.status == "complete":
			# Fully complete Playback has no future damage or held lease. A later
			# ordinary lethal hit does not fabricate a cancellation/generation.
			if snapshot.hit_receipts[-1].phase != "complete" or playback.cursor.phase != "complete" or not playback.get("cancellation") is Dictionary or not playback.cancellation.is_empty() or playback.get("cancelled_at_s") != null:
				return "Post-complete defeat must retain actual complete Playback without a manufactured cancellation"
			if not scheduler.get("reservations") is Array:
				return "Complete Scheduler reservation array required"
			for record: Variant in scheduler.reservations:
				if not record is Dictionary or record.get("source_id") == snapshot.source_id:
					return "Defeated complete owner cannot retain an active reservation"
		else:
			return "Defeated owner cannot retain a damaging running Playback"
	# A fresh independently configured same-cycle actor can accept old state;
	# an already running/terminal actual owner cannot heal or rewrite its hits.
	var actual: Dictionary = actor.state()
	if not actual.is_empty() and actual.get("status") != "idle":
		var prefix: Array = actor.source_hit_receipts()
		if snapshot.source_hits < prefix.size() or (actor.dead and snapshot.alive):
			return "Existing actual source cannot rewind hits or revive its defeated lifecycle"
		for index: int in range(prefix.size()):
			if not _same(snapshot.hit_receipts[index], prefix[index]):
				return "Existing actual source accepted-hit history cannot be rewritten"
	return ""


func _hits_error(snapshot: Dictionary, playback: Dictionary) -> String:
	var previous_hp: float = snapshot.max_hp
	var previous_clock: float = 0.0
	for raw: Variant in snapshot.hit_receipts:
		if not raw is Dictionary or not SourceValue.keys_error(raw, HIT_KEYS).is_empty() or not raw.clock_s is float or not SourceValue.in_range(raw.clock_s, previous_clock, snapshot.clock_s) or not raw.hp_before is float or not _same(raw.hp_before, previous_hp) or not raw.hp_damage is float or not SourceValue.in_range(raw.hp_damage, 0.0, previous_hp) or raw.hp_damage <= 0.0 or not raw.hp_after is float or not _same(raw.hp_after, float(raw.hp_before) - float(raw.hp_damage)) or raw.hp_after < 0.0 or not raw.phase is String or raw.phase not in ["recovery", "complete"]:
			return "Every accepted source hit must retain its exact ordered HP transaction"
		# Use the public pure Cursor's exact phase derivation, including its
		# published native boundary behavior. Do not clone timing arithmetic or
		# let a receipt create/reprove any physical lease/opportunity.
		if not playback.cursor.get("armed") is bool or not playback.cursor.armed or not playback.cursor.get("configured_at_s") is float or not playback.cursor.get("timeline_origin_s") is float or not playback.cursor.get("armed_at_s") is float:
			return "Accepted hit requires the actual saved armed cursor clocks"
		var phase_reader = PhaseReader.new()
		if not phase_reader.configure_authored(snapshot.sequence, snapshot.source_epoch, snapshot.generation, playback.cursor.configured_at_s) or not phase_reader.arm(playback.cursor.timeline_origin_s, playback.cursor.armed_at_s):
			return "Accepted hit requires this actual armed authored cursor"
		var phase: Dictionary = phase_reader.advance(raw.clock_s)
		if not phase.get("accepted", false) or phase.get("phase") != raw.phase:
			return "Accepted knot hit must join this canonical authored recovery/completion phase"
		if previous_hp <= 0.0:
			return "No accepted hit may follow a genuine lethal source transaction"
		previous_hp = raw.hp_after
		previous_clock = raw.clock_s
	if not _same(previous_hp, snapshot.hp):
		return "Saved HP must equal the complete accepted-hit receipt prefix"
	return ""


func staged_binding(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> Dictionary:
	if not record_error(snapshot, actor, player, scheduler, playback).is_empty():
		return {}
	var binding: Dictionary = actor.get_authored_echo_binding()
	binding.alive = snapshot.alive
	return binding


func restore_physical(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> bool:
	if not _actual_actor(actor):
		return false
	actor.source_snapshot_error = record_error(snapshot, actor, player, scheduler, playback)
	if not actor.source_snapshot_error.is_empty():
		return false
	# Parent has independently prevalidated Hero/Scheduler/Playback before
	# entering this no-yield commit. Historical receipts are trusted aggregate
	# data, not independent authentication of a Player action or damage claim.
	return actor._apply_source_lifecycle(snapshot)


func verify_phase(snapshot: Dictionary, actor) -> bool:
	if not _boundary(actor).is_empty() or ExactTransport.stringify(snapshot).is_empty() or not SourceValue.keys_error(snapshot, KEYS).is_empty() or snapshot.get("api_revision") != API or not snapshot.get("schema_version") is int or snapshot.schema_version != 1:
		return false
	var binding: Dictionary = actor.get_authored_echo_binding()
	var exact: bool = _same(snapshot.source_id, binding.source_id) and _same(snapshot.source_epoch, binding.source_epoch) and _same(snapshot.generation, binding.generation) and _same(snapshot.sequence, actor.source_program()) and _same(snapshot.native, actor.native_descriptor()) and _same(snapshot.physical, {"position": SourceValue.vector3(actor.global_position), "basis": _basis(actor.global_basis)}) and _same(snapshot.hp, actor.hp) and _same(snapshot.max_hp, actor.max_hp) and _same(snapshot.alive, not actor.dead) and _same(snapshot.source_hits, actor.source_hits) and _same(snapshot.hit_receipts, actor.source_hit_receipts()) and _same(snapshot.defeated_at_s, actor.defeated_at_s) and _same(snapshot.phase, actor.source_phase()) and _same(snapshot.clock_s, actor.source_clock())
	actor.source_snapshot_error = "" if exact else "Commit actual Scheduler/Playback before verifying complete source phase/lifecycle"
	return exact


static func _actual_actor(actor) -> bool:
	if typeof(actor) != TYPE_OBJECT or not is_instance_valid(actor) or not actor is CinderReplayPlayback:
		return false
	var script: Script = actor.get_script() as Script
	return script != null and script.resource_path == ACTOR_PATH


static func _boundary(actor) -> String:
	if not _actual_actor(actor) or not actor.is_inside_tree() or not actor.is_node_ready() or actor.is_queued_for_deletion() or not actor.get_tree().paused:
		return "Actual production Echo requires paused deferred parent boundary; no caller proxy"
	return actor.source_native_error()


static func _basis(value: Basis) -> Array:
	return [SourceValue.vector3(value.x), SourceValue.vector3(value.y), SourceValue.vector3(value.z)]


static func _same(left: Variant, right: Variant) -> bool:
	return EnemyPlan.exact_equal(left, right)
