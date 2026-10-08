extends RefCounted
## TEST ONLY native stationary source resources/lifecycle codec. The parent
## independently validates Player, Scheduler and Playback before any commit.
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const API: String = "authored-echo-fixture-native-1"
const ACTOR_PATH: String = "res://tests/fixtures/authored_echo_actor.gd"
const KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "source_epoch", "generation", "sequence", "native", "hp", "max_hp", "alive", "source_hits", "defeated_at_s", "physical", "phase", "clock_s"]


func capture(actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> Dictionary:
	var boundary: String = _boundary(actor)
	if not boundary.is_empty():
		return {}
	actor.source_snapshot_error = ""
	var binding: Dictionary = actor.get_authored_echo_binding()
	var snapshot: Dictionary = {"api_revision": API, "schema_version": 1, "source_id": binding.source_id, "source_epoch": binding.source_epoch, "generation": binding.generation, "sequence": actor.source_program(), "native": actor.native_descriptor(), "hp": actor.hp, "max_hp": actor.max_hp, "alive": not actor.dead, "source_hits": actor.source_hits, "defeated_at_s": actor.defeated_at_s, "physical": {"position": Value.vector3(actor.global_position), "basis": _basis(actor.global_basis)}, "phase": actor.source_phase(), "clock_s": actor.source_clock()}
	actor.source_snapshot_error = record_error(snapshot, actor, player, scheduler, playback)
	return snapshot if actor.source_snapshot_error.is_empty() else {}


func record_error(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> String:
	var error: String = _boundary(actor)
	if not error.is_empty():
		return error
	if Exact.stringify(snapshot).is_empty() or not Value.keys_error(snapshot, KEYS).is_empty() or not snapshot.api_revision is String or snapshot.api_revision != API or not snapshot.schema_version is int or snapshot.schema_version != 1:
		return "Closed exact stationary native source envelope required"
	var binding: Dictionary = actor.get_authored_echo_binding()
	if not snapshot.source_id is String or not snapshot.source_epoch is String or snapshot.source_id != binding.source_id or snapshot.source_epoch != binding.source_epoch or not snapshot.generation is int or snapshot.generation != binding.generation or not _same(snapshot.sequence, actor.source_program()) or not _same(snapshot.native, actor.native_descriptor()):
		return "Retained actual source/script/resources/immutable definition/cycle differs"
	if not snapshot.hp is float or not snapshot.max_hp is float or not _same(snapshot.max_hp, actor.max_hp) or not Value.in_range(snapshot.hp, 0.0, snapshot.max_hp) or not snapshot.alive is bool or snapshot.alive != (snapshot.hp > 0.0) or not snapshot.source_hits is int or not Value.is_integer(snapshot.source_hits, 0, 1):
		return "Finite exact source HP/lifecycle/hit count required"
	if not snapshot.clock_s is float or not Value.in_range(snapshot.clock_s, 0.0, 1000000.0):
		return "Finite exact aggregate source clock required"
	if snapshot.alive and snapshot.defeated_at_s != null:
		return "Living source cannot retain a defeat tombstone"
	if not snapshot.alive and (not snapshot.defeated_at_s is float or not Value.in_range(snapshot.defeated_at_s, 0.0, float(snapshot.clock_s)) or snapshot.source_hits != 1):
		return "Defeated source must retain its exact actual once-hit clock"
	if not snapshot.physical is Dictionary or not Value.keys_error(snapshot.physical, ["position", "basis"]).is_empty() or not _same(snapshot.physical.position, Value.vector3(binding.knot_position)) or not _same(snapshot.physical.basis, _basis(Basis.IDENTITY)):
		return "Saved actual HP source stays at immutable fixed knot"
	if not player.get("actor_type") is String or player.actor_type != "CinderPlayer" or not player.get("resources") is Dictionary or not scheduler.get("clock_s") is float or not playback.get("clock_s") is float or not snapshot.clock_s is float or not _same(snapshot.clock_s, scheduler.clock_s) or not _same(snapshot.clock_s, playback.clock_s):
		return "Whole actual Player/Scheduler/Playback clock pair required"
	if not playback.get("api_revision") is String or playback.api_revision != "authored-echo-playback-1" or not playback.get("source_id") is String or not playback.get("source_epoch") is String or playback.source_id != snapshot.source_id or playback.source_epoch != snapshot.source_epoch or not _same(playback.get("generation"), snapshot.generation) or not _same(playback.get("sequence"), snapshot.sequence) or not playback.get("cursor") is Dictionary or not playback.get("status") is String or playback.status not in ["running", "cancelled", "complete"] or not playback.cursor.get("phase") is String:
		return "Original authored program and exact phase owner required"
	var expected_phase: String = "defeated" if not snapshot.alive else (String(playback.cursor.get("phase", "")) if playback.status == "running" else String(playback.status))
	if not snapshot.phase is String or snapshot.phase != expected_phase:
		return "Native source phase must join actual retained Playback phase"
	if not snapshot.alive:
		if playback.status != "cancelled" or playback.reason != "authored_source_defeated" or not _same(playback.cancelled_at_s, snapshot.defeated_at_s) or not playback.get("cancellation") is Dictionary or playback.cancellation.get("kind") != "authored_replay":
			return "Defeated source requires its actual Scheduler cancellation tombstone"
	return ""


func staged_binding(snapshot: Dictionary, actor) -> Dictionary:
	if not _boundary(actor).is_empty() or Exact.stringify(snapshot).is_empty() or not Value.keys_error(snapshot, KEYS).is_empty() or not snapshot.api_revision is String or snapshot.api_revision != API or not snapshot.schema_version is int or snapshot.schema_version != 1 or not snapshot.alive is bool or not snapshot.hp is float or not Value.in_range(snapshot.hp, 0.0, actor.max_hp) or snapshot.alive != (snapshot.hp > 0.0) or not _same(snapshot.sequence, actor.source_program()) or not _same(snapshot.native, actor.native_descriptor()):
		return {}
	var binding: Dictionary = actor.get_authored_echo_binding()
	if not snapshot.source_id is String or not snapshot.source_epoch is String or snapshot.source_id != binding.source_id or snapshot.source_epoch != binding.source_epoch or not _same(snapshot.generation, binding.generation) or not snapshot.physical is Dictionary or not Value.keys_error(snapshot.physical, ["position", "basis"]).is_empty() or not _same(snapshot.physical.position, Value.vector3(binding.knot_position)) or not _same(snapshot.physical.basis, _basis(Basis.IDENTITY)):
		return {}
	binding.alive = snapshot.alive
	return binding


func restore_physical(snapshot: Dictionary, actor, player: Dictionary, scheduler: Dictionary, playback: Dictionary) -> bool:
	if not _boundary(actor).is_empty():
		return false
	actor.source_snapshot_error = record_error(snapshot, actor, player, scheduler, playback)
	if not actor.source_snapshot_error.is_empty():
		return false
	# The actual immutable native definition/resources and fixed pose were
	# already checked; do not touch the renderer or execute source callbacks.
	actor.hp = snapshot.hp
	actor.dead = not snapshot.alive
	actor.source_hits = snapshot.source_hits
	actor.defeated_at_s = snapshot.defeated_at_s
	if actor.dead:
		actor.remove_from_group("enemies")
	else:
		actor.add_to_group("enemies")
	return true


func verify_phase(snapshot: Dictionary, actor) -> bool:
	if not _boundary(actor).is_empty() or Exact.stringify(snapshot).is_empty() or not Value.keys_error(snapshot, KEYS).is_empty() or staged_binding(snapshot, actor).is_empty() or not snapshot.phase is String or not snapshot.clock_s is float or not Value.in_range(snapshot.clock_s, 0.0, 1000000.0) or not _same(snapshot.max_hp, actor.max_hp) or not _same(snapshot.source_hits, actor.source_hits) or not _same(snapshot.defeated_at_s, actor.defeated_at_s):
		return false
	actor.source_snapshot_error = ""
	if actor.source_snapshot_error.is_empty() and (actor.source_phase() != snapshot.phase or not _same(actor.source_clock(), snapshot.clock_s) or actor.hp != snapshot.hp or actor.dead == snapshot.alive):
		actor.source_snapshot_error = "Commit actual Scheduler/Playback before joining source phase"
	return actor.source_snapshot_error.is_empty()


static func _boundary(actor) -> String:
	if typeof(actor) != TYPE_OBJECT or not is_instance_valid(actor) or not actor is Node3D or not actor.is_inside_tree() or not actor.is_node_ready() or not actor.get_tree().paused:
		return "Native source codec requires paused deferred parent boundary"
	var script: Script = actor.get_script() as Script
	if script == null or script.resource_path != ACTOR_PATH:
		return "Actual retained native fixture script required; no caller proxy"
	return actor.source_native_error()


static func _basis(value: Basis) -> Array:
	return [Value.vector3(value.x), Value.vector3(value.y), Value.vector3(value.z)]


static func _same(left: Variant, right: Variant) -> bool:
	return Authored.exact_equal(left, right)
