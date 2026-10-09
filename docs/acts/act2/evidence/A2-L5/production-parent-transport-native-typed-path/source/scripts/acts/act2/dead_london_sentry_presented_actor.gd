extends "res://scripts/acts/act2/dead_london_sentry_actor.gd"
## TMP ONLY owned presentation adapter. Existing source/HP/gate/snapshot methods
## remain inherited. Actor root, native group and saved body_yaw are unchanged.
const PresentedVisual: Script = preload("res://scripts/acts/act2/dead_london_sentry_visual.gd")

func _ready() -> void:
	# Preserve the actual base actor construction contract; swap only its rig.
	add_to_group("enemies")
	_visual = PresentedVisual.new() as Node3D
	_visual.name = "DyingSentryRig"
	add_child(_visual)
	_render_pose(false)
	set_process(false)
	set_physics_process(false)

func get_cosmetic_rig() -> Node3D:
	return _visual if is_instance_valid(_visual) and _visual.is_inside_tree() and not _visual.is_queued_for_deletion() else null

func bind_cosmetic_foot(actual_visual: Node3D) -> bool:
	var rig: Node3D = get_cosmetic_rig()
	return rig != null and bool(rig.call("bind_near_foot", actual_visual))

func project_consumer_cosmetics(ray: Dictionary, opening: Dictionary) -> bool:
	## Call after actual Foot pose and actual native cue. Pure derived cosmetics
	## work live/paused and inside publication; never call Actor.present_phase
	## during quiet restore or replace the saved warning-entry body yaw.
	var rig: Node3D = get_cosmetic_rig()
	if rig == null or not ray.get("phase") is String or not ray.get("direction") is Vector3 or not opening.get("state") is String:
		return false
	var visual_phase: String = "idle" if ray.phase == "clear" else ray.phase
	var progress: Variant = ray.get("phase_progress")
	if not progress is float and not progress is int: return false
	if not String(rig.call("restore_pose_error", visual_phase, float(progress), ray.direction, float(rig.call("get_body_yaw")))).is_empty(): return false
	if boss_phase not in [1, 2] or opening.state not in ["clear", "available", "active", "spent"]: return false
	# All input checks precede either physical panel/hinge update. These methods
	# emit no signals, introduce no clocks and preserve actual source identity.
	return bool(rig.call("set_ray_pose", visual_phase, float(progress), ray.direction)) and bool(rig.call("set_brace_pose", boss_phase, opening.state))

func cleanup() -> void:
	var rig: Node3D = get_cosmetic_rig()
	if rig != null: rig.call("release_near_foot")
	super.cleanup()
