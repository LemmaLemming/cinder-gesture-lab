extends "res://scripts/acts/act1/mushroom_caverns.gd"
## A1-L4 first-beat component: one unchanged familiar spear guard on open floor.
## Reuses the owned native admission/custody/framing grammar, never the fungal
## layout builder. Formation, roundel, King and whole-level saves are unfinished.

const COURT_GUARD_ID: String = "court-curtain-guard"
const COURT_FLOOR_SIZE := Vector3(14.0, 1.0, 16.0)
const COURT_FLOOR_TRANSFORM := Transform3D(Basis.IDENTITY, Vector3(0.0, -0.5, 0.0))
const COURT_FLOOR_COLOR := Color(0.28, 0.28, 0.28, 1.0)
const COURT_SAFE_RECT := Rect2(-6.5, -7.5, 13.0, 15.0)
const COURT_SOURCE_POSITION := Vector3(0.0, 0.0, -2.0)
const UNSUPPORTED_STATE: String = "L4 entrance component has no whole court/formation/King aggregate yet"

var _court_floor: StaticBody3D
var _court_floor_visual: MeshInstance3D
var _court_floor_mesh: BoxMesh
var _court_floor_material: StandardMaterial3D
var _court_floor_visual_transform: Transform3D
var _court_floor_shape_owner: int = -1
var _court_floor_margin: float = 0.0


func _ready() -> void:
	process_physics_priority = 200
	_approach_enabled = false
	_construction_error = _component_configuration_error()
	if not _construction_error.is_empty(): return
	_court_floor = get_node_or_null("Floor") as StaticBody3D
	_floor_collision = get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	_court_floor_visual = get_node_or_null("Floor/QuietFloor") as MeshInstance3D
	if not is_instance_valid(_court_floor) or not is_instance_valid(_floor_collision) or not is_instance_valid(_court_floor_visual):
		_construction_error = "Court component needs its actual retained floor and quiet mesh"
		return
	_floor_shape = _floor_collision.shape as BoxShape3D
	_court_floor_mesh = _court_floor_visual.mesh as BoxMesh
	_court_floor_material = _court_floor_visual.material_override as StandardMaterial3D
	_floor_transform = _floor_collision.global_transform
	_court_floor_visual_transform = _court_floor_visual.global_transform
	if _court_floor.get_shape_owners().size() == 1:
		_court_floor_shape_owner = int(_court_floor.get_shape_owners()[0])
	_court_floor_margin = _floor_collision.margin
	_construction_error = _floor_error()
	if _construction_error.is_empty(): _construction_error = _scenery_error()
	if not _construction_error.is_empty(): return
	scheduler = CinderThreatScheduler.new()
	scheduler.name = "CourtThreatScheduler"
	add_child(scheduler)
	var actor: Act1MushroomSelenite = ActorScript.new()
	actor.name = "CurtainGuard"
	actor.position = COURT_SOURCE_POSITION
	if not actor.configure("C32", COURT_GUARD_ID, true, false):
		_construction_error = actor.last_error
		actor.free()
		return
	add_child(actor)
	actor.activation_guard = Callable(self, "_activation_permitted")
	actor.presentation_guard = Callable(self, "_source_presentation_error").bind(COURT_GUARD_ID)
	sources[COURT_GUARD_ID] = actor
	_retained_sources[COURT_GUARD_ID] = actor
	var collision := actor.get_node("BodyCollision") as CollisionShape3D
	_retained_collisions[COURT_GUARD_ID] = collision
	_retained_capsules[COURT_GUARD_ID] = collision.shape
	_retained_cues[COURT_GUARD_ID] = actor.get_cue()
	objective_text = _initial_objective_text()


func _component_configuration_error() -> String:
	if level_id != "A1-L4" or initial_greybox_room != 3 or enable_swarm_approach:
		return "Court entrance component requires its canonical L4 identity and one stationary guard"
	return ""


func _all_source_ids() -> Array[String]:
	return [COURT_GUARD_ID]


func current_source_ids() -> Array[String]:
	return [COURT_GUARD_ID]


func _source_spec(id: String) -> Dictionary:
	return {"role_id": "C32", "position": COURT_SOURCE_POSITION, "approach": false} if id == COURT_GUARD_ID else {}


func _encounter_id() -> String:
	return "a1_l4_curtain_entrance_greybox"


func _initial_objective_text() -> String:
	return "COURT ENTRANCE · FAMILIAR SPEAR\nREAD THE LANE · ORDINARY PRIMARY"


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if greybox_clear:
		objective_text = "COURT ENTRANCE COMPONENT CLEAR\nFORMATION AND KING REMAIN IN PRODUCTION"


func response_context(role_id: String = "") -> Dictionary:
	var context: Dictionary = super.response_context(role_id)
	context.floor_regions = [{"collision": _floor_collision, "safe_rect": COURT_SAFE_RECT}]
	return context


func scheduler_bindings() -> Dictionary:
	return {"world_root": _world_root(), "owners": sources.duplicate(), "floors": {"court-floor": {"collision": _floor_collision, "safe_rect": COURT_SAFE_RECT}}}


func _floor_error() -> String:
	if not is_instance_valid(_court_floor) or not _court_floor.is_inside_tree() or _court_floor.is_queued_for_deletion() or get_node_or_null("Floor") != _court_floor or _court_floor.get_parent() != self or _court_floor.get_script() != null or _court_floor.collision_layer != 1 or _court_floor.collision_mask != 0 or _court_floor.constant_linear_velocity != Vector3.ZERO or _court_floor.constant_angular_velocity != Vector3.ZERO or _court_floor.physics_material_override != null:
		return "Retained court StaticBody floor is unavailable or changed"
	if not is_instance_valid(_floor_collision) or not is_instance_valid(_floor_shape) or not _floor_collision.is_inside_tree() or _floor_collision.is_queued_for_deletion() or get_node_or_null("Floor/CollisionShape3D") != _floor_collision or _floor_collision.get_parent() != _court_floor:
		return "Retained court floor collision binding is unavailable"
	if _floor_collision.shape != _floor_shape or _floor_shape.size != COURT_FLOOR_SIZE or _floor_collision.global_transform != _floor_transform or _floor_transform != COURT_FLOOR_TRANSFORM or _floor_collision.transform != Transform3D.IDENTITY or _floor_collision.disabled or _floor_collision.margin != _court_floor_margin:
		return "Retained court floor geometry changed"
	if _court_floor.get_shape_owners().size() != 1 or int(_court_floor.get_shape_owners()[0]) != _court_floor_shape_owner or _court_floor.shape_owner_get_owner(_court_floor_shape_owner) != _floor_collision or _court_floor.is_shape_owner_disabled(_court_floor_shape_owner) or _court_floor.shape_owner_get_transform(_court_floor_shape_owner) != Transform3D.IDENTITY or _court_floor.shape_owner_get_shape_count(_court_floor_shape_owner) != 1 or _court_floor.shape_owner_get_shape(_court_floor_shape_owner, 0) != _floor_shape:
		return "Retained court floor native shape owner changed"
	return ""


func _scenery_error() -> String:
	if not is_instance_valid(_court_floor_visual) or not _court_floor_visual.is_inside_tree() or _court_floor_visual.is_queued_for_deletion() or get_node_or_null("Floor/QuietFloor") != _court_floor_visual or _court_floor_visual.get_parent() != _court_floor or not _court_floor_visual.is_visible_in_tree():
		return "Retained quiet court floor presentation is unavailable"
	if not is_instance_valid(_court_floor_mesh) or not is_instance_valid(_court_floor_material) or _court_floor_visual.mesh != _court_floor_mesh or _court_floor_mesh.size != COURT_FLOOR_SIZE or _court_floor_visual.material_override != _court_floor_material or _court_floor_visual.global_transform != _court_floor_visual_transform or _court_floor_visual_transform != COURT_FLOOR_TRANSFORM:
		return "Retained quiet court floor mesh/material changed"
	if _court_floor_visual.material_overlay != null or _court_floor_visual.transparency != 0.0 or _court_floor_visual.layers != 1 or _court_floor_material.get_script() != null or _court_floor_material.albedo_color != COURT_FLOOR_COLOR or _court_floor_material.albedo_texture != null or _court_floor_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or _court_floor_material.no_depth_test or _court_floor_material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or _court_floor_material.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL or _court_floor_material.next_pass != null or _court_floor_material.roughness != 1.0:
		return "Quiet court floor must retain its authored opaque gray material and depth rendering"
	return ""


func snapshot_state() -> Dictionary:
	last_snapshot_error = UNSUPPORTED_STATE
	return {}


func snapshot_state_for_presentation(_camera: Camera3D, _hud: GameHUD) -> Dictionary:
	return snapshot_state()


func _local_snapshot_error(_state: Dictionary) -> String:
	return UNSUPPORTED_STATE


func _local_snapshot_error_with_player(_state: Dictionary, _saved_player: Dictionary) -> String:
	return UNSUPPORTED_STATE


func _on_enter_restore_candidate(_local: Dictionary, _saved_player: Dictionary) -> String:
	return UNSUPPORTED_STATE
