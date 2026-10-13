extends RefCounted
## TEST ONLY native fixture codec2. Saved generation/program/history is fully
## prevalidated without HP mutation; actual managed generation is prepared by
## public Playback, then true physical HP -> Scheduler3 -> Playback2 commits.
## This source codec is never independent historical admission authentication.
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Journal = preload("res://scripts/combat/authored_echo_cycle_journal.gd")
const API: String = "authored-echo-lifecycle-fixture-native-2"
const ACTOR_PATH: String = "res://tests/fixtures/authored_echo_lifecycle_actor.gd"
const KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "source_epoch", "generation", "sequence", "native", "hp", "max_hp", "alive", "source_hits", "defeated_at_s", "physical", "phase", "clock_s", "lifecycle"]


func capture(actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> Dictionary:
	if not _boundary(actor).is_empty(): return {}
	var hook: Dictionary = actor.get_authored_echo_binding()
	var result: Dictionary = {"api_revision": API, "schema_version": 2, "source_id": hook.source_id, "source_epoch": hook.source_epoch, "generation": hook.generation, "sequence": actor.source_program(), "native": actor.native_descriptor(), "hp": actor.hp, "max_hp": actor.max_hp, "alive": not actor.dead, "source_hits": actor.source_hits, "defeated_at_s": actor.defeated_at_s, "physical": {"position": Value.vector3(actor.global_position), "basis": _basis(actor.global_basis)}, "phase": actor.source_phase(), "clock_s": actor.source_clock(), "lifecycle": playback.get("lifecycle", {}).duplicate(true)}
	actor.source_snapshot_error = record_error(result, actor, player, scheduler, playback)
	return result if actor.source_snapshot_error.is_empty() else {}


func record_error(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> String:
	var error: String = _boundary(actor)
	if error.is_empty(): error = Receipt.transport_error(snapshot)
	if not error.is_empty(): return error
	if not Value.keys_error(snapshot, KEYS).is_empty() or snapshot.api_revision != API or not snapshot.schema_version is int or snapshot.schema_version != 2 or not snapshot.generation is int or not Value.is_integer(snapshot.generation, 1, 64): return "Closed native lifecycle codec2/generation required"
	var hook: Dictionary = actor.get_authored_echo_binding()
	if snapshot.source_id != hook.source_id or snapshot.source_epoch != hook.source_epoch or not snapshot.sequence is Dictionary or not _same(snapshot.native, actor.native_descriptor()): return "Actual retained source/script/resource identity differs"
	# Construct the prospective saved-generation program against known native
	# raw definition/profile/world, not a gen1 immutable reader forced to accept2.
	var reader = Authored.new()
	if not reader.restore_state(snapshot.sequence, snapshot.source_epoch, snapshot.generation): return reader.last_snapshot_error
	error = reader.binding_error(snapshot.sequence, hook.source_id, snapshot.source_epoch, snapshot.generation, actor.source_profile(), actor.source_definition(), actor.prepared_world())
	if not error.is_empty(): return error
	if not snapshot.hp is float or not snapshot.max_hp is float or not _same(snapshot.max_hp, actor.max_hp) or not Value.in_range(snapshot.hp, 0.0, snapshot.max_hp) or not snapshot.alive is bool or snapshot.alive != (snapshot.hp > 0.0) or not snapshot.source_hits is int or not Value.is_integer(snapshot.source_hits, 0, 2): return "Exact native partial HP/death/hit lifecycle required"
	if snapshot.alive and snapshot.defeated_at_s != null: return "Living source cannot have a defeat tombstone"
	if not snapshot.clock_s is float or not Receipt.clock_valid(snapshot.clock_s): return "Exact current aggregate source clock required"
	if not snapshot.alive and (not snapshot.defeated_at_s is float or not Value.in_range(snapshot.defeated_at_s, 0.0, snapshot.clock_s) or snapshot.source_hits != 2): return "Real second hit defeat retains its original clock"
	if not snapshot.physical is Dictionary or not Value.keys_error(snapshot.physical, ["position", "basis"]).is_empty() or not _same(snapshot.physical.position, Value.vector3(hook.knot_position)) or not _same(snapshot.physical.basis, _basis(Basis.IDENTITY)): return "Actual HP owner remains at the exact immutable fixed knot"
	if player.get("actor_type") != "CinderPlayer" or not player.get("resources") is Dictionary or not _same(scheduler.get("clock_s"), snapshot.clock_s) or not _same(playback.get("clock_s"), snapshot.clock_s): return "Complete exact Player/source/Scheduler/Playback unit required"
	if playback.get("api_revision") != "authored-echo-playback-2" or playback.get("source_id") != snapshot.source_id or playback.get("source_epoch") != snapshot.source_epoch or not _same(playback.get("generation"), snapshot.generation) or not _same(playback.get("sequence"), snapshot.sequence) or not playback.get("lifecycle") is Dictionary or not _same(playback.lifecycle, snapshot.lifecycle): return "Actual Playback2 current program/lifecycle differs"
	if not scheduler.get("schema_version") is int or scheduler.schema_version != 3 or not scheduler.get("authored_source_cycles") is Dictionary: return "Actual typed Scheduler3 whole journal required"
	error = Journal.snapshot_error(scheduler.authored_source_cycles, snapshot.clock_s)
	if not error.is_empty(): return error
	var current: Dictionary = {}
	for entry: Dictionary in scheduler.authored_source_cycles.sources:
		if entry.source_id == snapshot.source_id:
			if not current.is_empty(): return "Duplicate native source history"
			current = entry
	if current.is_empty() or not _same(current, snapshot.lifecycle): return "Source/native/Playback/Scheduler history must be one exact current entry"
	if not playback.get("status") is String or playback.status not in ["cycle_ready", "running", "complete", "cancelled"]: return "Supported native lifecycle phase required"
	var phase: String = "defeated" if not snapshot.alive else (String(playback.get("cursor", {}).get("phase", "")) if playback.status == "running" else playback.status)
	if not snapshot.phase is String or snapshot.phase != phase: return "Saved source phase must join its actual current lifecycle"
	if snapshot.alive and playback.status == "cancelled" and playback.get("reason") == "authored_source_defeated": return "Actual source-defeat cancellation cannot revive a living native HP target"
	if not snapshot.alive:
		if playback.status == "cancelled":
			if playback.get("reason") != "authored_source_defeated" or not _same(playback.get("cancelled_at_s"), snapshot.defeated_at_s) or current.stage != "terminal" or current.terminal_receipts.is_empty() or not _same(current.terminal_receipts[-1].terminal_at_s, snapshot.defeated_at_s): return "Dead native source retains its original cancellation/terminal receipt at a later outer clock"
		elif playback.status != "cycle_ready" or current.stage != "cycle_ready":
			return "A dead prospective source retains its real ready stage without inventing admission or a terminal receipt"
	# Existing live custody cannot use the physical codec to rewind HP/hit/death.
	# A fresh idle shell or the distinct public prepared recipe may stage saved
	# physical data; that recipe is not exposed as an earned terminal receipt.
	var recipe: Dictionary = actor.get_authored_cycle_restore_recipe()
	if recipe.is_empty() and actor.state().get("status", "idle") != "idle":
		if not _same(actor.hp, snapshot.hp) or actor.dead == snapshot.alive or actor.source_hits != snapshot.source_hits or not _same(actor.defeated_at_s, snapshot.defeated_at_s): return "Existing native source cannot roll back physical HP/death/hit history"
	return ""


func staged_binding(snapshot: Dictionary, actor) -> Dictionary:
	if not _boundary(actor).is_empty() or not Receipt.transport_error(snapshot).is_empty() or not Value.keys_error(snapshot, KEYS).is_empty() or snapshot.api_revision != API or not snapshot.schema_version is int or snapshot.schema_version != 2 or not snapshot.generation is int or not Value.is_integer(snapshot.generation, 1, 64) or not snapshot.alive is bool or not snapshot.hp is float or not Value.in_range(snapshot.hp, 0.0, actor.max_hp) or snapshot.alive != (snapshot.hp > 0.0) or not _same(snapshot.native, actor.native_descriptor()): return {}
	var hook: Dictionary = actor.get_authored_echo_binding()
	if snapshot.source_id != hook.source_id or snapshot.source_epoch != hook.source_epoch or not snapshot.sequence is Dictionary: return {}
	var reader = Authored.new()
	if not reader.restore_state(snapshot.sequence, snapshot.source_epoch, snapshot.generation) or not reader.binding_error(snapshot.sequence, hook.source_id, snapshot.source_epoch, snapshot.generation, actor.source_profile(), actor.source_definition(), actor.prepared_world()).is_empty(): return {}
	if not snapshot.physical is Dictionary or not Value.keys_error(snapshot.physical, ["position", "basis"]).is_empty() or not _same(snapshot.physical.position, Value.vector3(hook.knot_position)) or not _same(snapshot.physical.basis, _basis(Basis.IDENTITY)): return {}
	hook.generation = snapshot.generation
	hook.alive = snapshot.alive
	return hook


func restore_physical(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> bool:
	if not _boundary(actor).is_empty(): return false
	actor.source_snapshot_error = record_error(snapshot, actor, player, scheduler, playback)
	if not actor.source_snapshot_error.is_empty() or actor.get_authored_cycle_generation() != snapshot.generation or not _same(actor.source_program(), snapshot.sequence): return false
	var recipe: Dictionary = actor.get_authored_cycle_restore_recipe()
	if not recipe.is_empty():
		var terminal: Dictionary = snapshot.lifecycle.terminal_receipts[-1] if playback.status in ["complete", "cancelled"] else {}
		if not Value.keys_error(recipe, ["playback_id", "lifecycle", "terminal_receipt"]).is_empty() or recipe.playback_id != playback.playback_id or not _same(recipe.lifecycle, snapshot.lifecycle) or not _same(recipe.terminal_receipt, terminal) or not actor.get_authored_cycle_terminal_receipt().is_empty(): return false
	# Parent already preflighted the whole unit and used the PUBLIC fresh managed
	# generation preparation. Never heal/rearm/equip or reconstruct the renderer.
	actor.hp = snapshot.hp
	actor.dead = not snapshot.alive
	actor.source_hits = snapshot.source_hits
	actor.defeated_at_s = snapshot.defeated_at_s
	if actor.dead: actor.remove_from_group("enemies")
	else: actor.add_to_group("enemies")
	return true


func verify_phase(snapshot: Dictionary, actor) -> bool:
	if not _boundary(actor).is_empty() or staged_binding(snapshot, actor).is_empty(): return false
	return actor.source_phase() == snapshot.phase and _same(actor.source_clock(), snapshot.clock_s) and _same(actor.hp, snapshot.hp) and actor.dead != snapshot.alive and actor.source_hits == snapshot.source_hits and _same(actor.defeated_at_s, snapshot.defeated_at_s) and actor.get_authored_cycle_generation() == snapshot.generation and _same(actor.source_program(), snapshot.sequence)


static func _boundary(actor) -> String:
	if typeof(actor) != TYPE_OBJECT or not is_instance_valid(actor) or not actor is Node3D or not actor.is_inside_tree() or not actor.is_node_ready() or not actor.get_tree().paused: return "Ready native source at paused complete boundary required"
	var script: Variant = actor.get_script()
	if not script is Script or script.resource_path != ACTOR_PATH: return "Actual fixture2 source Script required"
	return actor.source_native_error()


static func _basis(value: Basis) -> Array:
	return [Value.vector3(value.x), Value.vector3(value.y), Value.vector3(value.z)]


static func _same(left: Variant, right: Variant) -> bool:
	return Authored.exact_equal(left, right)
