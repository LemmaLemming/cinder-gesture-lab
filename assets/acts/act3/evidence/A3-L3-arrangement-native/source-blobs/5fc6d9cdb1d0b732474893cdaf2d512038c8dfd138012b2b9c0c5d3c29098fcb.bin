extends "res://scripts/acts/act3/mirror_sea_level.gd"
## TEST ONLY declared east court; no earned parent prefix, save or progression.
## Requires the separately approved/promoted parent arrangement implementation.
@export var ece_changed: bool = true
@export var ece_restore_only: bool = false
const ECE_SAVE_LIMIT: String = "TEST east component has no canonical parent route/save/progress authority"
var ece_native_deaths: Array[String] = []

func _on_enter_level() -> void:
	if not last_configuration_error.is_empty(): return
	var selector := Arrangement.new(_arrangement_definition)
	var descriptor: Dictionary = selector.select_fresh("challenge") if ece_changed else {"schema_version": 1, "profile": "challenge", "recipe_id": LEGACY_RECIPE_IDS.challenge, "order": ARRANGEMENT_SOURCE_IDS.duplicate()}
	var error: String = selector.last_error if descriptor.is_empty() else _select_arrangement(descriptor, not ece_changed)
	if error.is_empty() and not threat_scheduler.begin_encounter("challenge", ENCOUNTER_ID, WORLD_REVISION): error = threat_scheduler.last_error
	if error.is_empty() and not _install_source(EAST_ID, not ece_restore_only): error = last_configuration_error
	if not error.is_empty():
		_fail(error)
		return
	_active = not ece_restore_only
	scenery.call("show_sun", 0, "stable")
	_update_presentation()

func _advance_entry() -> bool: return false
func _all_cleared() -> bool: return false
func _dispatch_pending_checkpoint() -> void: pass
func request_completion(_completion_id: String = "complete") -> bool: return false
func request_contact_exit(_exit_id: String, _body: Node3D) -> bool: return false
func request_checkpoint(_checkpoint_id: String, _boundary_kind: String = "encounter") -> bool: return false
func _on_echo_died(id: String) -> void:
	if id == EAST_ID and sources.has(id) and sources[id].dead and sources[id].hp == 0.0: ece_native_deaths.append(id)

func _update_presentation(quiet: bool = false) -> void:
	super._update_presentation(quiet)
	# Empty prefix remains empty. Only the TEST scenic landmark anchor is set
	# to this explicitly declared court; native sources/visibility stay intact.
	if is_instance_valid(hero) and is_instance_valid(scenery): scenery.call("follow_landmarks", Vector3(hero.global_position.x, 0, -3.0 + 0.4))
	objective_text = "TEST EAST ECHO COMPONENT\nORDINARY ESCAPE / USEFUL RETURN / REAL KNOT"

func snapshot_state() -> Dictionary:
	last_snapshot_error = ECE_SAVE_LIMIT
	return {}
func snapshot_state_for_presentation(_camera: Camera3D, _hud: GameHUD) -> Dictionary:
	last_snapshot_error = ECE_SAVE_LIMIT
	return {}
func snapshot_error(_saved: Dictionary) -> String: return ECE_SAVE_LIMIT
func snapshot_error_with_player(_saved: Dictionary, _player: Dictionary) -> String: return ECE_SAVE_LIMIT
func restore_state(_saved: Dictionary) -> bool:
	last_snapshot_error = ECE_SAVE_LIMIT
	return false
func _local_snapshot_error(_saved: Dictionary) -> String: return ECE_SAVE_LIMIT
func _local_snapshot_error_with_player(_saved: Dictionary, _player: Dictionary) -> String: return ECE_SAVE_LIMIT
func _on_enter_restore_candidate(_saved: Dictionary, _player: Dictionary) -> String: return ECE_SAVE_LIMIT

func ece_native_pair() -> Dictionary:
	if not get_tree().paused or not sources.has(EAST_ID): return {}
	var player: Dictionary = hero.snapshot_state()
	var bindings: Dictionary = scheduler_bindings()
	var scheduler: Dictionary = threat_scheduler.snapshot_state(bindings)
	var playback: Dictionary = sources[EAST_ID].call("snapshot_state", scheduler, bindings)
	var source: Dictionary = sources[EAST_ID].call("capture_source", player, scheduler, playback)
	return {} if player.is_empty() or scheduler.is_empty() or playback.is_empty() or source.is_empty() else {"player": player, "source": source, "scheduler": scheduler, "playback": playback}

func ece_preflight(data: Dictionary, paired: bool) -> String:
	var error: String = Receipt.transport_error(data)
	if error.is_empty(): error = Value.keys_error(data, ["player", "source", "scheduler", "playback"])
	if not error.is_empty(): return error
	for key: String in ["player", "source", "scheduler", "playback"]:
		if not data[key] is Dictionary: return "Complete typed actual component native units required"
	if not data.playback.get("generation") is int or data.source.get("source_id") != EAST_ID: return "Exact actual east source/generation required"
	error = hero.snapshot_error(data.player)
	if error.is_empty(): error = sources[EAST_ID].call("source_record_error", data.source, data.player, data.scheduler, data.playback)
	if not error.is_empty(): return error
	var staged: Dictionary = scheduler_bindings()
	staged["hero_positions"] = {"hero": Value.read_vector3(data.player.motion.position)}
	staged["owner_positions"] = {}; staged["owner_velocities"] = {}; staged["owner_collision_states"] = {}
	staged["authored_owner_bindings"] = {EAST_ID: sources[EAST_ID].call("staged_source_binding", data.source, data.player, data.scheduler, data.playback)}
	staged["authored_cycle_playback_ids"] = {EAST_ID: data.playback.playback_id}
	error = threat_scheduler.snapshot_error(data.scheduler, staged)
	if not error.is_empty(): return error
	if data.scheduler.get("schema_version") != 3 or data.scheduler.get("encounter_id") != ENCOUNTER_ID or not Authored.exact_equal(data.scheduler.get("world_revision"), WORLD_REVISION): return "Actual native managed component Scheduler3/world required"
	if paired:
		var context: Dictionary = _echo_records[EAST_ID].context.duplicate(true)
		context.generation = data.playback.generation
		error = sources[EAST_ID].call("snapshot_error", data.playback, threat_scheduler, data.scheduler, staged, {"hero": hero}, [_floor], context)
	return error

func ece_prepare_pair(data: Dictionary) -> String:
	if not ece_restore_only or _active or not get_tree().paused or sources[EAST_ID].call("source_cycles_managed") or not sources[EAST_ID].call("get_authored_cycle_restore_recipe").is_empty(): return "Prepare only this fresh paused untracked component recipient"
	var error: String = ece_preflight(data, false)
	if not error.is_empty(): return error
	var context: Dictionary = _echo_records[EAST_ID].context.duplicate(true)
	context.generation = data.playback.generation
	if not sources[EAST_ID].call("prepare_authored_restore", data.playback, threat_scheduler, {"hero": hero}, [_floor], context): return String(sources[EAST_ID].get("source_snapshot_error")) + "; " + String(sources[EAST_ID].get("last_error"))
	return ece_preflight(data, true)

func ece_commit_pair(data: Dictionary) -> String:
	if not ece_restore_only or _active or not get_tree().paused: return "Commit only a prepared paused test component; it cannot become a parent attempt"
	var error: String = ece_preflight(data, true)
	if not error.is_empty(): return error
	if not hero.restore_state(data.player): return hero.last_snapshot_error
	var source: Node3D = sources[EAST_ID]
	if not source.call("restore_source_physical", data.source, data.player, data.scheduler, data.playback): return String(source.get("source_snapshot_error"))
	var bindings: Dictionary = scheduler_bindings()
	if not threat_scheduler.restore_state(data.scheduler, bindings): return threat_scheduler.last_snapshot_error
	var context: Dictionary = _echo_records[EAST_ID].context.duplicate(true)
	context.generation = data.playback.generation
	if not source.call("restore_state", data.playback, threat_scheduler, data.scheduler, bindings, {"hero": hero}, [_floor], context) or not source.call("verify_restored_source_phase", data.source): return String(source.get("last_snapshot_error")) + "; " + String(source.get("source_snapshot_error"))
	return "" if Authored.exact_equal(ece_native_pair(), data) else "Quiet actual component native pair differs after complete commit"

func _on_exit_level() -> void:
	# This TEST-only ordinary-entry recipient has no campaign candidate flag.
	# Dispose a partially committed native restore wholesale; never reuse it.
	if ece_restore_only and is_instance_valid(threat_scheduler) and sources.has(EAST_ID):
		var source: Node3D = sources[EAST_ID]
		var control: Dictionary = threat_scheduler.source_control_state(source)
		if not control.is_empty() and not control.reservations.is_empty() and control.outside_transaction and not source.call("get_authored_cycle_restore_recipe").is_empty():
			if source.call("state").get("status") == "running": source.call("cancel", "test_component_whole_discard")
			else: threat_scheduler.cancel_owner(source, "test_component_unfinished_whole_discard")
	super._on_exit_level()
