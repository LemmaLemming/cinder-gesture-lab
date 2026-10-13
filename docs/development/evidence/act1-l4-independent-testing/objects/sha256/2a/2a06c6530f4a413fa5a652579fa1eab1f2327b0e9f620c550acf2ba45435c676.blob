extends "res://tests/acts/act1/a1_l4_curtain_greybox.gd"
## Court presentation custody over the unchanged real one-C32/input fixture.
## All scenery faults/setter probes are synchronous before native tick0 advances.
## TEST blocked/open/blocked is unearned scenery setup, never level progression.

const CourtScenePath: String = "res://scenes/acts/act1/a1_l4_court_art_preview.tscn"
const CourtRuntimePath: String = "res://scripts/acts/act1/selenite_court_presented.gd"
const CourtArtPath: String = "res://scripts/acts/act1/selenite_court_art.gd"
const CourtLandmarks: Array[String] = ["entrance-curtain", "curling-panels", "crescents", "floor", "radial-ornament"]

var art_fault_observations: Array[Dictionary] = []


func _component_scene_path() -> String:
	return CourtScenePath


func _component_runtime_path() -> String:
	return CourtRuntimePath


func _open_curtain() -> bool:
	if not await super._open_curtain(): return false
	current_scope = "court-art-one-guard"
	var art: Node3D = level.get("court_art") as Node3D
	if not _require(is_instance_valid(art) and art == level.get_node_or_null("CourtArt") and art.get_parent() == level and art.get_script() != null and art.get_script().resource_path == CourtArtPath and art.transform == Transform3D.IDENTITY and art.process_mode == Node.PROCESS_MODE_DISABLED and art.is_visible_in_tree() and not art.is_processing() and not art.is_physics_processing(), "actual court leaf retains direct identity parenting and disabled static presentation"):
		return false
	if not _require(_court_authority_nodes(art).is_empty() and String(art.call("binding_error")).is_empty(), "court scenery contains no physics/cue/controller authority and has valid actual retained resources"):
		return false
	var before: Dictionary = _court_native_observation()
	if not _require(scheduler.get_clock() == 0.0 and hero.get_world_action_clock() == 0.0 and admissions.is_empty() and world_records.is_empty() and sources[SourceID].pure_presentation_state().reservation_id.is_empty(), "scenery-only probes precede the first real warning/action tick"):
		return false
	var bounds: Dictionary = _court_landmark_bounds(art)
	if not _require(bounds.size() == CourtLandmarks.size() and _court_native_observation() == before, "all five landmarks return finite complete actual bounds without native mutation"):
		return false
	var blocked: Node3D = art.get_node_or_null("EntranceCurtain/BlockedDrapery") as Node3D
	var gathered: Node3D = art.get_node_or_null("EntranceCurtain/OpenGatheredDrapery") as Node3D
	var floor_skin: MeshInstance3D = art.get_node_or_null("QuietSilverFloorSkin") as MeshInstance3D
	if not _require(is_instance_valid(blocked) and is_instance_valid(gathered) and blocked.visible and not gathered.visible and is_instance_valid(floor_skin) and floor_skin.mesh is PlaneMesh and floor_skin.material_override is BaseMaterial3D, "actual blocked/gathered curtain and silver floor resources exist before setter/fault tests"):
		return false
	art.call("set_exit_open", true)
	var opened: bool = _require(not blocked.visible and gathered.visible and String(art.call("binding_error")).is_empty() and _court_landmark_bounds(art).size() == CourtLandmarks.size() and _court_native_observation() == before, "TEST unearned open curtain swaps only supported scenery and retains native clocks/HP/leases/receipts")
	art.call("set_exit_open", false)
	var reblocked: bool = _require(blocked.visible and not gathered.visible and String(art.call("binding_error")).is_empty() and _court_landmark_bounds(art) == bounds and _court_native_observation() == before, "TEST reblocked curtain restores the exact original landmark state without progress")
	if not opened or not reblocked: return false
	art.visible = false
	var hidden: bool = _court_fault(art, before, "hidden retained CourtArt")
	art.visible = true
	if not hidden or not _court_recovered(art, before, bounds): return false
	level.remove_child(art)
	var detached: bool = _court_fault(art, before, "detached retained CourtArt")
	level.add_child(art)
	if not detached or not _court_recovered(art, before, bounds): return false
	blocked.visible = false
	var missing_curtain: bool = _court_fault(art, before, "hidden required blocked curtain")
	blocked.visible = true
	if not missing_curtain or not _court_recovered(art, before, bounds): return false
	var held_material: BaseMaterial3D = floor_skin.material_override
	var colour: Color = held_material.albedo_color
	held_material.albedo_color = Color.BLACK if colour != Color.BLACK else Color.WHITE
	var painted_over: bool = _court_fault(art, before, "mutated retained floor material")
	held_material.albedo_color = colour
	if not painted_over or not _court_recovered(art, before, bounds): return false
	floor_skin.material_override = held_material.duplicate(true) as BaseMaterial3D
	var replaced_material: bool = _court_fault(art, before, "equivalent replacement floor material")
	floor_skin.material_override = held_material
	if not replaced_material or not _court_recovered(art, before, bounds): return false
	var held_mesh: Mesh = floor_skin.mesh
	floor_skin.mesh = held_mesh.duplicate(true) as Mesh
	var replaced_mesh: bool = _court_fault(art, before, "equivalent replacement floor mesh")
	floor_skin.mesh = held_mesh
	if not replaced_mesh or not _court_recovered(art, before, bounds): return false
	quiet_units.append({"scope": "TEST synchronous pre-admission court-art resource custody; unearned scenery setter only; no art-fidelity/full-L4/save/visual-acceptance claim", "native_clock_s": scheduler.get_clock(), "landmarks": _portable(bounds), "resource_faults": art_fault_observations.duplicate(true)})
	return true


func _court_authority_nodes(node: Node) -> Array[String]:
	var result: Array[String] = []
	if node is CollisionObject3D or node is CollisionShape3D or node is CinderThreatCue or node is CinderInteractionCue or node.is_in_group("enemies") or node.is_in_group("practice_targets") or node.is_in_group("required_cues"):
		result.append(String(node.name))
	for child: Node in node.get_children(): result.append_array(_court_authority_nodes(child))
	return result


func _court_native_observation() -> Dictionary:
	var response: Dictionary = hero.get_threat_response_state()
	response.erase("actor") # Detached query dictionary, not the actual Hero.
	return {"hero_response": response, "hero_transform": hero.global_transform, "hp": hero.hp, "shells": hero.shells, "source": sources[SourceID].pure_presentation_state(), "control": scheduler.source_control_state(sources[SourceID]), "cue": sources[SourceID].get_cue().state(), "events": events, "input": game.call("get_input_observation_state"), "records": hero.get_world_action_records(), "admissions": admissions.duplicate(true), "checkpoint": level.current_checkpoint(), "completed": level.is_completed(), "completions": completions, "checkpoints": checkpoints, "contacts": contacts}


func _court_landmark_bounds(art: Node3D) -> Dictionary:
	var result: Dictionary = {}
	for id: String in CourtLandmarks:
		var points: Variant = art.call("landmark_world_corners", id)
		if not points is Array or points.size() != 8: return {}
		for point: Variant in points:
			if not point is Vector3 or not point.is_finite(): return {}
		result[id] = points.duplicate()
	return result


func _court_fault(art: Node3D, before: Dictionary, label: String) -> bool:
	var error: String = art.call("binding_error")
	var landmark: Variant = art.call("landmark_world_corners", "entrance-curtain")
	var invalid_points: bool = landmark is Array and not landmark.is_empty()
	if invalid_points:
		invalid_points = false
		for point: Variant in landmark:
			if point is Vector3 and not point.is_finite(): invalid_points = true
	var camera_points: Array = level.camera_framing_points()
	var camera_error: String = level.last_camera_framing_error
	art_fault_observations.append({"fault": label, "binding_error": error, "camera_error": camera_error, "native_clock_s": scheduler.get_clock()})
	return _require(not error.is_empty() and invalid_points and camera_points.is_empty() and not camera_error.is_empty() and _court_native_observation() == before, label + " rejects full art/projection while native Hero/source/clock/leases/cue/input/progress remain identical")


func _court_recovered(art: Node3D, before: Dictionary, bounds: Dictionary) -> bool:
	return _require(String(art.call("binding_error")).is_empty() and _court_landmark_bounds(art) == bounds and _court_native_observation() == before, "restoring the same retained court resources recovers exact bounds and unchanged native state before any tick")
