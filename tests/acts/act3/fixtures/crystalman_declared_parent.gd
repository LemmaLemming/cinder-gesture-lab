extends "res://scripts/acts/act3/crystalman_level.gd"
## TEST ONLY representative native production state, never a route-clear proof.
## Earlier regular/phase receipts below are DECLARED TEST HISTORY. No previous
## native owner exists or is canceled/filtered; current native unit is genuine.
## This fixture is never registered in canonical production or used as evidence
## that the three preceding enemies/earlier tether were actually defeated.
@export_range(2,4) var test_stage: int = 2

func _on_enter_level() -> void:
	if not last_configuration_error.is_empty(): return
	_active=true
	_stage=test_stage
	_regular_metadata={"source_ids":["l5-offered-echo","l5-plain-stalker","l5-plain-echo"],"deaths":{},"completed_at_actor_s":0.0,"completed_at_unit_s":0.0,"disposition":"whole_unit_disposal","journal_sha256":"0".repeat(64)}
	var locations: Array=[Vector3(-0.7,0,29.5),Vector3(1.2,0.1,18),Vector3(-0.7,0,17.5)]
	for index: int in range(3):
		_regular_metadata.deaths[_regular_metadata.source_ids[index]]={"clock_s":0.0,"source_position":Value.vector3(locations[index])}
	for capacity: int in range(1,maxi(1,test_stage-1)):
		var ids: Array=[1] if capacity==1 else [1,2]
		_phase_metadata.append({"accepted":true,"reason":"","phase_id":"capture-one" if capacity==1 else "capture-two","capacity":capacity,"generation":1,"sequence_id":"crystalman-rule/sequence-1","completed_at_actor_s":0.0,"completed_at_unit_s":0.0,"retirement_slot_ids":ids,"retirement_sha256":"0".repeat(64),"sequence_sha256":"0".repeat(64),"projection_sha256":"0".repeat(64),"delivered_attack_count":capacity,"tether_hits":1,"disposition":"whole_unit_disposal"})
	for index: int in range(test_stage+1): _record_entry(index)
	if test_stage<4: _install_capture(test_stage-1)
	else: _exit_state="available"
	if not scenery.call("present_stage",test_stage): _fail("Declared TEST scenery recipient declined")
	_update_presentation()
