extends "res://scripts/campaign/level.gd"
## TEST ONLY authored topology and optical gate; no encounter/damage authority.
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ROOM_TWO_OBJECTIVE: String = "TEST ONLY LATER ROOM: KEEP THE ENTIRE RESTORED PLAYER CAPSULE, FULL NATIVE BILLBOARD AND CONTACT SHADOW WITH THE ACTUAL SOURCE BELOW THIS WRAPPED OBJECTIVE. THE CONSTRUCTOR MUST STAY PRISTINE UNTIL QUIET RESTORE."
var room_index: int = 1
var clock_s: float = 0.0
var quiet_commits: int = 0
var source: MeshInstance3D
var source_mesh: BoxMesh

func restore_candidate_construction_required() -> bool:
	return true

func _on_enter_level() -> void:
	_build_source()

func _on_enter_restore_candidate(local: Dictionary, _saved_player: Dictionary) -> String:
	var error: String = _closed_error(local)
	if not error.is_empty(): return error
	room_index = local.room_index
	_build_source()
	return ""

func _build_source() -> void:
	source = MeshInstance3D.new()
	source.name = "ActualNativeRoomMarker"
	source_mesh = BoxMesh.new()
	source_mesh.size = Vector3(0.6, 1.0, 0.6)
	source.mesh = source_mesh
	add_child(source)
	_set_room_presentation()

func _set_room_presentation() -> void:
	source.position = Vector3(1.0, 0.5, 10.8 if room_index == 2 else 0.8)
	objective_text = ROOM_TWO_OBJECTIVE if room_index == 2 else "TEST ONLY FIRST ROOM"

func _physics_process(delta: float) -> void:
	clock_s += delta
	if room_index == 1 and hero.global_position.z > 10.0 and not hero.get_committed_dash_state().active:
		room_index = 2
		_set_room_presentation()

func camera_framing_points() -> Array:
	if source == null: return []
	var points: Array = []
	var aabb: AABB = source.get_aabb()
	for x: float in [aabb.position.x, aabb.end.x]:
		for y: float in [aabb.position.y, aabb.end.y]:
			for z: float in [aabb.position.z, aabb.end.z]:
				points.append(source.global_transform * Vector3(x, y, z))
	return points

func _capture_local_state() -> Dictionary:
	return {"room_index": room_index, "clock_s": clock_s}

func _closed_error(state: Dictionary) -> String:
	if not Codec.keys_error(state, ["room_index", "clock_s"]).is_empty() or not state.get("room_index") is int or state.room_index not in [1, 2] or not state.get("clock_s") is float or not Codec.in_range(state.clock_s, 0.0, 1000.0):
		return "Closed TEST ONLY room topology/clock required"
	return ""

func _mechanical_error(state: Dictionary) -> String:
	var error: String = _closed_error(state)
	if not error.is_empty(): return error
	if state.room_index != room_index or not is_instance_valid(source) or source.get_parent() != self or source.mesh != source_mesh or source_mesh.size != Vector3(0.6, 1.0, 0.6) or source.position != Vector3(1.0, 0.5, 10.8 if room_index == 2 else 0.8):
		return "Actual selected native room topology changed"
	return ""

func _local_snapshot_error(state: Dictionary) -> String:
	var error: String = _mechanical_error(state)
	if not error.is_empty() or is_restore_candidate(): return error
	# Live captures check the actual physical actor/current projection. A fresh
	# zero-clock entry is measured through its actual candidate camera as well.
	var actual_camera: Camera3D = hero.get_viewport().get_camera_3d()
	return shared_shell.camera_framing_error_for_player(camera_framing_points(), hero, actual_camera)

func _local_snapshot_error_with_player(state: Dictionary, _saved_player: Dictionary) -> String:
	# Pure mechanical/context proof only; saved optical geometry is deliberately
	# deferred to the supported actual post-quiet candidate gate, never translated.
	return _mechanical_error(state)

func _restore_local_state(state: Dictionary) -> void:
	clock_s = state.clock_s
	quiet_commits += 1
	_set_room_presentation()

func _restore_candidate_presentation_error(framing_camera: Camera3D, framing_hud: GameHUD) -> String:
	if snapshot_error({}) != "Restore validation requires an entered level outside lifecycle/state hooks" or snapshot_error_with_player({}, {}) != "Aggregate validation requires an entered level outside lifecycle/state hooks":
		return "Pure optical hook must retain the dedicated snapshot reentry barrier"
	var points: Array = camera_framing_points()
	var plan: Dictionary = shared_shell.camera_framing_plan_for_context(points, hero.global_position + Vector3.UP * 0.75, hero, framing_camera, framing_hud)
	if not plan.get("accepted", false): return String(plan.get("reason", "Actual restored full-bounds plan rejected"))
	return shared_shell.camera_framing_error_for_context(points, hero, framing_camera, framing_hud)
