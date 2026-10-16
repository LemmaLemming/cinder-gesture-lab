extends "res://tests/acts/act2/fixtures/a2_l1_arrangement_reference/horsell_common_old.gd"
## TEST ONLY common eligibility constructor. Actual Horsell native configure,
## physics, route sign rule, proof, presentation and cleanup remain inherited.
## This fork has no defeat prefix and cannot enter campaign persistence.
class ForkSequence extends "res://scripts/acts/act2/horsell_sequence.gd":
	func _init() -> void:
		_beat = "fork"
		_route = ""
		_defeated.clear()

const COMPONENT_LIMIT: String = "TEST common component has no parent save/checkpoint/progress authority"
var fixture_loadout: Dictionary = {}
var refused_progress: Array[String] = []

func _on_enter_level() -> void:
	# SharedGame has created the real Player at its declared spawn. Initial
	# equipment/resources precede every native actor/Exchange configure call.
	_sequence = ForkSequence.new()
	if not hero.equipment.restore(fixture_loadout) or not hero.equip_item(String(fixture_loadout.weapon)):
		runtime_error = "Declared initial legal kit rejected"
		return
	hero.shells = 0 # Explicit initial fixture resource; never written after entry.
	super._on_enter_level()
	_update_actor_visibility()

func snapshot_state() -> Dictionary:
	last_snapshot_error = COMPONENT_LIMIT
	return {}
func snapshot_state_for_presentation(_camera: Camera3D, _hud: GameHUD) -> Dictionary:
	return snapshot_state()
func snapshot_error(_packet: Dictionary) -> String:
	return COMPONENT_LIMIT
func snapshot_error_with_player(_packet: Dictionary, _player: Dictionary) -> String:
	return COMPONENT_LIMIT
func restore_state(_packet: Dictionary) -> bool:
	last_snapshot_error = COMPONENT_LIMIT
	return false
func _on_enter_restore_candidate(_local: Dictionary, _player: Dictionary) -> String:
	return COMPONENT_LIMIT
func request_checkpoint(_id: String, _kind: String = "encounter") -> bool:
	refused_progress.append("checkpoint")
	return false
func request_completion(_id: String = "complete") -> bool:
	refused_progress.append("completion")
	return false
func request_contact_exit(_id: String, _body: Node3D) -> bool:
	refused_progress.append("contact")
	return false

func component_receipt() -> Dictionary:
	var actors: Dictionary = {}
	for id: String in _actors:
		var actor: Node3D = _actors[id]
		actors[id] = {"instance_id_decimal":str(actor.get_instance_id()),"position":actor.global_position,"hp":actor.get("hp"),"visible":actor.visible,"armed_binding":actor.call("is_armed"),"script_path":actor.get_script().resource_path}
	var bindings: Dictionary = _scheduler_bindings()
	var owners: Dictionary = {}
	for id: String in bindings.owners: owners[id] = str(bindings.owners[id].get_instance_id())
	var sequence: Dictionary = _sequence.call("snapshot_state")
	return {"sequence":sequence,"original_sequence_validation_error":_sequence.call("snapshot_error",sequence),"actors":actors,"native_owner_ids":owners,"scheduler_profile":_scheduler.call("encounter_profile"),"admitted_ids":_admitted_ids.duplicate(),"pending_defeats":_pending_defeats.duplicate(),"pending_checkpoints":_pending_checkpoints.duplicate(),"completion_pending":_completion_pending,"departure_checkpoint":_departure_checkpoint,"departure_contact_seen":_departure_contact_seen,"exit_requested":_exit_requested,"refused_progress":refused_progress.duplicate(),"runtime_error":runtime_error}

func component_native_packet() -> Dictionary:
	# Genuine paused native components only, never a CinderLevel/Shell packet.
	var actors: Dictionary = {}
	for id: String in _actors: actors[id] = _actors[id].call("snapshot_state")
	var bindings: Dictionary = _scheduler_bindings()
	return {"actors":actors,"scheduler":_scheduler.call("snapshot_state",bindings),"exchange":_exchange.call("snapshot_state",bindings),"receipt":component_receipt()}
