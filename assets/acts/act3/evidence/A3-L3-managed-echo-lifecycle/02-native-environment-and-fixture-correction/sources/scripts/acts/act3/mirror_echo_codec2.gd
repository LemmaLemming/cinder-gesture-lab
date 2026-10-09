class_name CinderAct3MirrorEchoCodec2
extends RefCounted
## Opt-in managed source transport. The public Playback owns generation and
## earned cycle history; this codec owns the same native HP/hit receipt prefix.
## Whole-unit preflight precedes public preparation, then Hero -> physical
## source -> Scheduler3 -> Playback2 -> native phase verification.

const SourceValue = preload("res://scripts/campaign/snapshot_codec.gd")
const EnemyPlan = preload("res://scripts/combat/authored_enemy_sequence.gd")
const PhaseReader = preload("res://scripts/combat/replay_cursor.gd")
const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Journal = preload("res://scripts/combat/authored_echo_cycle_journal.gd")
const API: String = "act3-mirror-echo-source-2"
const ACTOR_PATH: String = "res://scripts/acts/act3/mirror_echo.gd"
const MAX_SOURCE_HITS: int = 4096
const KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "source_epoch", "generation", "sequence", "native", "hp", "max_hp", "alive", "source_hits", "hit_receipts", "defeated_at_s", "physical", "phase", "clock_s", "lifecycle"]
const HIT_KEYS: Array[String] = ["clock_s", "hp_before", "hp_damage", "hp_after", "phase", "generation"]
const READY_KEYS: Array[String] = ["api_revision", "schema_version", "playback_id", "presentation_id", "source_id", "hero_id", "source_epoch", "generation", "sequence", "status", "clock_s", "lifecycle"]
const PLAYBACK_KEYS: Array[String] = ["api_revision", "schema_version", "playback_id", "presentation_id", "sequence", "source_epoch", "generation", "source_id", "hero_id", "reservation_id", "exchange", "status", "reason", "cancelled_at_s", "cancellation", "clock_s", "cursor", "opportunities", "lifecycle"]


func capture(actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> Dictionary:
	var error: String = _boundary(actor)
	if error.is_empty() and not actor.source_cycles_managed():
		error = "Source2 capture requires explicit actual managed cycle opt-in"
	if error.is_empty() and not playback.get("lifecycle") is Dictionary:
		error = "Complete actual Playback2 lifecycle required for source capture"
	if not error.is_empty():
		if _actual_actor(actor):
			actor.source_snapshot_error = error
		return {}
	var binding: Dictionary = actor.get_authored_echo_binding()
	var snapshot: Dictionary = {"api_revision": API, "schema_version": 2, "source_id": binding.source_id, "source_epoch": binding.source_epoch, "generation": binding.generation, "sequence": actor.source_program(), "native": actor.native_descriptor(), "hp": actor.hp, "max_hp": actor.max_hp, "alive": not actor.dead, "source_hits": actor.source_hits, "hit_receipts": actor.source_hit_receipts(), "defeated_at_s": actor.defeated_at_s, "physical": {"position": SourceValue.vector3(actor.global_position), "basis": _basis(actor.global_basis)}, "phase": actor.source_phase(), "clock_s": actor.source_clock(), "lifecycle": playback.lifecycle.duplicate(true)}
	actor.source_snapshot_error = record_error(snapshot, actor, player, scheduler, playback)
	return snapshot.duplicate(true) if actor.source_snapshot_error.is_empty() else {}


func record_error(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> String:
	var error: String = _boundary(actor)
	if error.is_empty():
		error = _closed_error(snapshot)
	if not error.is_empty():
		return error
	# Bound every foreign aggregate before readers or retained history copies.
	for unit: Dictionary in [player, scheduler, playback]:
		error = Receipt.transport_error(unit)
		if not error.is_empty():
			return error
	var binding: Dictionary = actor.get_authored_echo_binding()
	if not Receipt.stable_id(snapshot.source_id) or not Receipt.stable_id(snapshot.source_epoch) or snapshot.source_id != binding.source_id or snapshot.source_epoch != binding.source_epoch or not snapshot.sequence is Dictionary or not _same(snapshot.native, actor.native_descriptor()):
		return "Actual production source/script/native porcelain and fixed-knot custody differs"
	# A fresh gen1 recipient must validate the prospective saved program against
	# its immutable native recipe without privately changing its current reader.
	var reader = EnemyPlan.new()
	if not reader.restore_state(snapshot.sequence, snapshot.source_epoch, snapshot.generation):
		return reader.last_snapshot_error
	error = reader.binding_error(snapshot.sequence, binding.source_id, snapshot.source_epoch, snapshot.generation, actor.source_profile(), actor.source_definition(), actor.prepared_world())
	if not error.is_empty():
		return error
	var program: Dictionary = reader.snapshot_state()
	if not snapshot.max_hp is float or not _same(snapshot.max_hp, float(program.resolved_role.max_hp)) or not _same(snapshot.max_hp, actor.max_hp) or not snapshot.hp is float or not SourceValue.in_range(snapshot.hp, 0.0, snapshot.max_hp) or not snapshot.alive is bool or snapshot.alive != (snapshot.hp > 0.0) or not snapshot.source_hits is int or not SourceValue.is_integer(snapshot.source_hits, 0, MAX_SOURCE_HITS) or not snapshot.hit_receipts is Array or snapshot.hit_receipts.size() != snapshot.source_hits:
		return "Exact production HP/lifecycle and complete bounded accepted-hit prefix required"
	if not Receipt.clock_valid(snapshot.clock_s):
		return "Finite exact current source aggregate clock required"
	if not snapshot.physical is Dictionary or not SourceValue.keys_error(snapshot.physical, ["position", "basis"]).is_empty() or not _same(snapshot.physical.position, SourceValue.vector3(binding.knot_position)) or not _same(snapshot.physical.basis, _basis(Basis.IDENTITY)):
		return "Actual HP owner must retain its exact fixed knot and identity basis"
	if player.get("actor_type") != "CinderPlayer" or not player.get("resources") is Dictionary or not player.get("world_actions") is Dictionary or not Receipt.clock_valid(player.world_actions.get("clock_s")) or not Receipt.clock_valid(scheduler.get("clock_s")) or not Receipt.clock_valid(playback.get("clock_s")) or not _same(snapshot.clock_s, player.world_actions.clock_s) or not _same(snapshot.clock_s, scheduler.clock_s) or not _same(snapshot.clock_s, playback.clock_s):
		return "Independent Hero/source/Scheduler3/Playback2 require the exact same native tick"
	if not scheduler.get("profile") is Dictionary or scheduler.profile.get("id") != program.profile_id:
		return "Saved Scheduler profile differs from the native source recipe"
	if playback.get("api_revision") != "authored-echo-playback-2" or playback.get("source_id") != snapshot.source_id or playback.get("source_epoch") != snapshot.source_epoch or not _same(playback.get("generation"), snapshot.generation) or not _same(playback.get("sequence"), snapshot.sequence) or not playback.get("lifecycle") is Dictionary or not _same(playback.lifecycle, snapshot.lifecycle):
		return "Source2 and actual Playback2 must share one exact program/generation/history"
	if not scheduler.get("schema_version") is int or scheduler.schema_version != 3 or not scheduler.get("authored_source_cycles") is Dictionary:
		return "Typed complete Scheduler3 authored source journal required"
	error = Journal.snapshot_error(scheduler.authored_source_cycles, snapshot.clock_s)
	if not error.is_empty():
		return error
	var current: Dictionary = {}
	for entry: Dictionary in scheduler.authored_source_cycles.sources:
		if entry.source_id == snapshot.source_id:
			if not current.is_empty():
				return "Duplicate production source history"
			current = entry
	if current.is_empty() or not _same(current, snapshot.lifecycle):
		return "Source/Playback/Scheduler must retain the same complete unique lifecycle entry"
	error = _playback_error(snapshot, playback)
	if not error.is_empty():
		return error
	error = _hits_error(snapshot, playback)
	if not error.is_empty():
		return error
	error = _death_error(snapshot, playback)
	if not error.is_empty():
		return error
	error = _recipe_error(snapshot, playback, actor)
	if not error.is_empty():
		return error
	# A fresh idle recipient or the public exact preparation may stage old HP.
	# An existing live custodian cannot use source transport to rewrite it.
	if actor.get_authored_cycle_restore_recipe().is_empty() and actor.state().get("status", "idle") != "idle":
		if not _same(actor.hp, snapshot.hp) or actor.dead == snapshot.alive or actor.source_hits != snapshot.source_hits or not _same(actor.defeated_at_s, snapshot.defeated_at_s) or not _same(actor.source_hit_receipts(), snapshot.hit_receipts):
			return "Existing actual source cannot rewind or rewrite physical HP/death/hit history"
	return ""


func _playback_error(snapshot: Dictionary, playback: Dictionary) -> String:
	if not playback.get("status") is String or playback.status not in ["cycle_ready", "running", "complete", "cancelled"] or not playback.get("schema_version") is int or not SourceValue.is_integer(playback.schema_version, 1, 3) or not Receipt.stable_id(playback.get("playback_id")) or not Receipt.stable_id(playback.get("hero_id")):
		return "Typed supported managed Playback phase and identity required"
	var keys: Array[String] = READY_KEYS.duplicate() if playback.status == "cycle_ready" else PLAYBACK_KEYS.duplicate()
	if playback.status != "cycle_ready":
		if playback.schema_version == 3:
			keys.append("projection")
		if playback.has("pending_delivery"):
			keys.append("pending_delivery")
	if not SourceValue.keys_error(playback, keys).is_empty() or (playback.status == "cycle_ready" and playback.schema_version != 1) or (playback.schema_version == 1 and playback.has("pending_delivery")) or (playback.schema_version == 2 and not playback.has("pending_delivery")) or (playback.has("pending_delivery") and (not playback.pending_delivery is Dictionary or playback.pending_delivery.is_empty())) or (playback.schema_version == 3 and (not playback.projection is Dictionary or playback.projection.is_empty())):
		return "Managed conditional fields cannot invent or discard a current receipt"
	if playback.status == "running" and not playback.get("cursor") is Dictionary:
		return "Running source requires its complete typed current cursor"
	var phase: String = "defeated" if not snapshot.alive else (String(playback.get("cursor", {}).get("phase", "")) if playback.status == "running" else playback.status)
	if not snapshot.phase is String or snapshot.phase != phase:
		return "Source lifecycle phase must join this saved managed Playback"
	var stage: String = "terminal" if playback.status in ["complete", "cancelled"] else playback.status
	if snapshot.lifecycle.stage != stage:
		return "Current source stage must join its actual ready/running/terminal history"
	for past: Dictionary in snapshot.lifecycle.terminal_receipts:
		if past.hero_id != playback.hero_id:
			return "Every original source generation retains the same Hero"
	if playback.status == "cycle_ready":
		return "" # Closed READY_KEYS contains no current exchange/cursor/receipt.
	if not playback.cursor is Dictionary or not playback.exchange is Dictionary or not playback.opportunities is Array or not playback.cancellation is Dictionary or not playback.reason is String:
		return "Complete current exchange/cursor/prefix/cancellation fields required"
	if playback.status == "running":
		var phase_reader = PhaseReader.new()
		var error: String = phase_reader.snapshot_error(playback.cursor, snapshot.sequence, snapshot.source_epoch, snapshot.generation, snapshot.clock_s)
		if not error.is_empty():
			return error
		if not playback.reason.is_empty() or playback.cancelled_at_s != null or not playback.cancellation.is_empty() or not _same(playback.exchange.get("start_s"), playback.cursor.configured_at_s):
			return "Running source retains exact admission clocks without a terminal cancellation"
		return ""
	var terminal: Dictionary = snapshot.lifecycle.terminal_receipts[-1]
	if terminal.outcome != playback.status or terminal.playback_id != playback.playback_id or terminal.exchange.id != playback.reservation_id or not _same(terminal.exchange, playback.exchange) or terminal.reason != playback.reason or not _same(terminal.cursor, playback.cursor) or not _same(terminal.opportunities, playback.opportunities) or not _same(terminal.pending_delivery, playback.get("pending_delivery", {})) or not _same(terminal.cancellation, playback.cancellation) or not _same(playback.cancelled_at_s, terminal.terminal_at_s if terminal.outcome == "cancelled" else null):
		return "Terminal source retains the original frozen exchange/prefix/inert suffix"
	return ""


func _hits_error(snapshot: Dictionary, playback: Dictionary) -> String:
	var previous_hp: float = snapshot.max_hp
	var previous_clock: float = 0.0
	var previous_generation: int = 1
	var terminals: Array = snapshot.lifecycle.terminal_receipts
	for raw: Variant in snapshot.hit_receipts:
		if not raw is Dictionary or not SourceValue.keys_error(raw, HIT_KEYS).is_empty() or not raw.clock_s is float or not SourceValue.in_range(raw.clock_s, previous_clock, snapshot.clock_s) or not raw.hp_before is float or not _same(raw.hp_before, previous_hp) or not raw.hp_damage is float or not SourceValue.in_range(raw.hp_damage, 0.0, previous_hp) or raw.hp_damage <= 0.0 or not raw.hp_after is float or not _same(raw.hp_after, float(raw.hp_before) - float(raw.hp_damage)) or raw.hp_after < 0.0 or not raw.phase is String or raw.phase not in ["recovery", "complete"] or not raw.generation is int or not SourceValue.is_integer(raw.generation, previous_generation, snapshot.generation):
			return "Every hit retains exact ordered HP/clock/phase/native generation values"
		var sequence: Dictionary
		var cursor: Dictionary
		if raw.generation <= terminals.size():
			var terminal: Dictionary = terminals[raw.generation - 1]
			sequence = terminal.sequence
			cursor = terminal.cursor
			if terminal.outcome == "cancelled" and raw.clock_s > terminal.terminal_at_s:
				return "No source hit can occur after its actual generation cancellation"
			if raw.phase == "complete" and (terminal.outcome != "complete" or raw.clock_s < terminal.terminal_at_s):
				return "Late complete hit requires that generation's actual completed knot"
		elif raw.generation == snapshot.generation and playback.status == "running":
			sequence = snapshot.sequence
			cursor = playback.cursor
		else:
			return "A ready or unadmitted current generation cannot invent a source hit"
		# A completed knot may be hit after its frozen terminal clock, but never
		# after a later generation's actual admission changed the native phase.
		var next_start: Variant = null
		if raw.generation < terminals.size():
			next_start = terminals[raw.generation].exchange.start_s
		elif raw.generation < snapshot.generation and playback.status == "running":
			next_start = playback.exchange.get("start_s")
		if next_start != null and (not Receipt.clock_valid(next_start) or raw.clock_s > next_start):
			return "Historical source hit cannot follow next-generation admission"
		if not cursor.get("armed") is bool or not cursor.armed or not Receipt.clock_valid(cursor.get("configured_at_s")) or not Receipt.clock_valid(cursor.get("timeline_origin_s")) or not Receipt.clock_valid(cursor.get("armed_at_s")):
			return "Accepted hit requires its own original armed canonical cursor clocks"
		var phase_reader = PhaseReader.new()
		if not phase_reader.configure_authored(sequence, snapshot.source_epoch, raw.generation, cursor.configured_at_s) or not phase_reader.arm(cursor.timeline_origin_s, cursor.armed_at_s):
			return "Accepted hit requires its original generation's canonical cursor"
		var phase: Dictionary = phase_reader.advance(raw.clock_s)
		if not phase.get("accepted", false) or phase.get("phase") != raw.phase:
			return "Accepted hit phase must derive from its own generation's original clocks"
		if previous_hp <= 0.0:
			return "No source hit may follow a genuine lethal transaction"
		previous_hp = raw.hp_after
		previous_clock = raw.clock_s
		previous_generation = raw.generation
	return "" if _same(previous_hp, snapshot.hp) else "Saved HP must equal the complete accepted-hit prefix"


func _death_error(snapshot: Dictionary, playback: Dictionary) -> String:
	if snapshot.alive:
		if snapshot.defeated_at_s != null or (playback.status == "cancelled" and playback.reason == "authored_source_defeated"):
			return "A living actual source cannot retain source-defeat transport"
		return ""
	if not Receipt.clock_valid(snapshot.defeated_at_s) or snapshot.defeated_at_s > snapshot.clock_s or snapshot.hit_receipts.is_empty() or not _same(snapshot.defeated_at_s, snapshot.hit_receipts[-1].clock_s) or snapshot.hit_receipts[-1].generation != snapshot.generation:
		return "Dead source retains its genuine current-generation lethal hit clock"
	if playback.status not in ["cancelled", "complete"]:
		return "This production source has no damaging running or ready dead state"
	var terminal: Dictionary = snapshot.lifecycle.terminal_receipts[-1]
	if playback.status == "cancelled":
		if playback.reason != "authored_source_defeated" or not _same(playback.cancelled_at_s, snapshot.defeated_at_s) or terminal.reason != "authored_source_defeated" or not _same(terminal.terminal_at_s, snapshot.defeated_at_s) or snapshot.hit_receipts[-1].phase != "recovery":
			return "Recovery defeat retains its original reason/lethal clock at later aggregate ticks"
	elif snapshot.hit_receipts[-1].phase != "complete" or terminal.outcome != "complete" or not playback.cancellation.is_empty() or playback.cancelled_at_s != null:
		return "Post-complete defeat preserves actual complete history without a manufactured tombstone"
	return ""


func _recipe_error(snapshot: Dictionary, playback: Dictionary, actor) -> String:
	var recipe: Dictionary = actor.get_authored_cycle_restore_recipe()
	if recipe.is_empty():
		return ""
	var terminal: Dictionary = snapshot.lifecycle.terminal_receipts[-1] if playback.status in ["complete", "cancelled"] else {}
	if not SourceValue.keys_error(recipe, ["playback_id", "lifecycle", "terminal_receipt"]).is_empty() or recipe.playback_id != playback.playback_id or not _same(recipe.lifecycle, snapshot.lifecycle) or not _same(recipe.terminal_receipt, terminal) or not actor.get_authored_cycle_terminal_receipt().is_empty():
		return "Public fresh restore recipe must match exact saved history without earned native terminal authority"
	return ""


func staged_binding(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> Dictionary:
	if not record_error(snapshot, actor, player, scheduler, playback).is_empty():
		return {}
	var binding: Dictionary = actor.get_authored_echo_binding()
	binding.generation = snapshot.generation
	binding.alive = snapshot.alive
	return binding


func restore_physical(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> bool:
	if not _actual_actor(actor):
		return false
	actor.source_snapshot_error = record_error(snapshot, actor, player, scheduler, playback)
	if not actor.source_snapshot_error.is_empty():
		return false
	if not actor.source_cycles_managed() or actor.get_authored_cycle_generation() != snapshot.generation or not _same(actor.source_program(), snapshot.sequence):
		actor.source_snapshot_error = "Public managed generation/program preparation must precede physical source commit"
		return false
	actor._apply_source_lifecycle(snapshot)
	return true


func verify_phase(snapshot: Dictionary, actor) -> bool:
	if not _boundary(actor).is_empty() or not _closed_error(snapshot).is_empty() or not actor.source_cycles_managed():
		return false
	var binding: Dictionary = actor.get_authored_echo_binding()
	var exact: bool = _same(snapshot.source_id, binding.source_id) and _same(snapshot.source_epoch, binding.source_epoch) and _same(snapshot.generation, actor.get_authored_cycle_generation()) and _same(snapshot.sequence, actor.source_program()) and _same(snapshot.native, actor.native_descriptor()) and _same(snapshot.physical, {"position": SourceValue.vector3(actor.global_position), "basis": _basis(actor.global_basis)}) and _same(snapshot.hp, actor.hp) and _same(snapshot.max_hp, actor.max_hp) and _same(snapshot.alive, not actor.dead) and _same(snapshot.source_hits, actor.source_hits) and _same(snapshot.hit_receipts, actor.source_hit_receipts()) and _same(snapshot.defeated_at_s, actor.defeated_at_s) and _same(snapshot.phase, actor.source_phase()) and _same(snapshot.clock_s, actor.source_clock())
	actor.source_snapshot_error = "" if exact else "Commit actual Scheduler3/Playback2 before verifying native source phase/lifecycle"
	return exact


static func _closed_error(snapshot: Dictionary) -> String:
	var error: String = Receipt.transport_error(snapshot)
	if not error.is_empty():
		return error
	if not SourceValue.keys_error(snapshot, KEYS).is_empty() or snapshot.api_revision != API or not snapshot.schema_version is int or snapshot.schema_version != 2 or not snapshot.generation is int or not SourceValue.is_integer(snapshot.generation, 1, 64) or not snapshot.lifecycle is Dictionary:
		return "Closed exact production Mirror Echo source2 schema and managed generation required"
	return ""


static func _actual_actor(actor) -> bool:
	if typeof(actor) != TYPE_OBJECT or not is_instance_valid(actor) or not actor is CinderReplayPlayback:
		return false
	var script: Script = actor.get_script() as Script
	return script != null and script.resource_path == ACTOR_PATH


static func _boundary(actor) -> String:
	if not _actual_actor(actor) or not actor.is_inside_tree() or not actor.is_node_ready() or actor.is_queued_for_deletion() or not actor.get_tree().paused:
		return "Actual production Echo requires paused deferred boundary; no caller proxy"
	return actor.source_native_error()


static func _basis(value: Basis) -> Array:
	return [SourceValue.vector3(value.x), SourceValue.vector3(value.y), SourceValue.vector3(value.z)]


static func _same(left: Variant, right: Variant) -> bool:
	return EnemyPlan.exact_equal(left, right)
