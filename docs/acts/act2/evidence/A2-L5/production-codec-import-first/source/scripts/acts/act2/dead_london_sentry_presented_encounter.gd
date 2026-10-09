extends "res://scripts/acts/act2/dead_london_sentry_encounter.gd"
## TMP ONLY cosmetic derivative of the owned parent. Requires frozen codec V1 e66d5cf9
## factory API `_new_actor`; not compatible with old parent552.
## Native cadence/gate/cue/source/HP/progression and codec remain inherited.
const PresentedActor: Script = preload("res://scripts/acts/act2/dead_london_sentry_presented_actor.gd")

func _new_actor() -> Node3D:
	return PresentedActor.new() as Node3D

func configure(shared_hero: CinderPlayer, shared_effects: PixelEffects, shared_scheduler: CinderThreatScheduler, actual_bait: RefCounted, actual_root: Node3D, floors: Dictionary, context: Dictionary, joint_at: Vector3, foot_at: Vector3, guard: Callable) -> bool:
	if not super.configure(shared_hero, shared_effects, shared_scheduler, actual_bait, actual_root, floors, context, joint_at, foot_at, guard): return false
	if not bool(get_actor().call("bind_cosmetic_foot", _foot_visual)):
		cleanup()
		return false
	return project_native_cosmetics()

func _sync_presentation() -> void:
	super._sync_presentation()
	if _live(): project_native_cosmetics()

func project_native_cosmetics() -> bool:
	## Actual restored Foot must be posed by parent consumer commit first.
	## Does not invoke _sync_presentation/Actor.present_phase, re-lock, re-sample
	## bait, refresh native deadlines, publish cues or change a saved body yaw.
	if not _live(): return false
	return bool(get_actor().call("project_consumer_cosmetics", get_ray().call("state"), get_joint_cue().state()))

func _restore_cosmetic_projection() -> void:
	# Inherited quiet commit has already posed actual Foot and restored the exact
	# Joint. Project only actual Ray/boss/cue; preserve Actor saved body_yaw.
	project_native_cosmetics()
