extends SceneTree
## TEST actual shared Main and cosmetic capsule leaf, supplied alpha only.
## No hatch Area/contact, shared-clock vignette, exit, campaign or art claim.

const MainScene = preload("res://scenes/main.tscn")
const Capsule = preload("res://scripts/acts/act1/living_moon_capsule.gd")
var game: Node
var hero: CinderPlayer
var camera: Camera3D
var leaf: Node3D
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	game = MainScene.instantiate()
	root.add_child(game)
	hero = game.get("player") as CinderPlayer
	camera = game.get("camera") as Camera3D
	if not _expect(hero != null and camera != null, "one actual shared Main Hero/camera"):
		await _finish(); return
	game.call("resume_lab")
	await process_frame
	await process_frame
	leaf = Capsule.new()
	(game.get("world") as Node3D).add_child(leaf)
	leaf.position = Vector3(-1.5, 0.0, -3.0)
	if not _expect(_scenery_only(leaf), "capsule/cord/clinger are clockless nonphysics scenery with no actor/attack groups"):
		await _finish(); return
	var fixed: Transform3D = leaf.global_transform
	var contact: Vector3 = leaf.to_global(Capsule.HATCH_CONTACT_ANCHOR)
	var idle: Dictionary = leaf.call("presentation_state")
	if not _expect(not leaf.call("set_escape_progress", 0.5) and leaf.call("presentation_state") == idle, "positive cosmetic escape requires its actual presentation camera") or not _expect(leaf.call("set_presentation_camera", camera), "cosmetic clinger binds the real current viewport camera"):
		await _finish(); return
	for open: bool in [false, true]:
		leaf.call("set_hatch_open", open)
		for alpha: float in [0.0, 0.25, 0.5, 1.0]:
			var native: Dictionary = _unit()
			if not _expect(leaf.call("set_escape_progress", alpha), "finite parent-supplied cosmetic pose") or not _expect(_unit() == native and leaf.global_transform == fixed and leaf.to_global(Capsule.HATCH_CONTACT_ANCHOR) == contact, "visual flight preserves Hero/camera/root and real parent contact reference"):
				await _finish(); return
			var state: Dictionary = leaf.call("presentation_state")
			var points: Array = leaf.call("world_corners")
			if not _expect(state.hatch_open == open and state.escape_progress == alpha and state.clinger_visible == (alpha > 0.0) and state.cord_visible == (alpha > 0.0) and not points.is_empty() and points.all(func(p: Variant) -> bool: return p is Vector3 and p.is_finite()) and _scenery_only(leaf), "actual visible shell/cord/clinger state and finite complete visible corners"):
				await _finish(); return
	var before: Dictionary = leaf.call("presentation_state")
	for bad: float in [-0.1, 1.1, INF, NAN]:
		if not _expect(not leaf.call("set_escape_progress", bad) and leaf.call("presentation_state") == before, "invalid scalar rejects without changing cosmetic state"):
			await _finish(); return
	await _finish()


func _unit() -> Dictionary:
	return {"hero": hero.global_transform, "hp": hero.hp, "shells": hero.shells, "actions": hero.get_world_action_records(), "camera": camera.global_transform, "projection": camera.get_camera_projection(), "input": game.call("get_input_observation_state")}


func _scenery_only(node: Node) -> bool:
	if not node is Node3D or node is CollisionObject3D or node is CollisionShape3D or node is Camera3D or not node.get_groups().is_empty() or node.process_mode != Node.PROCESS_MODE_DISABLED or node.is_processing() or node.is_physics_processing(): return false
	for child: Node in node.get_children():
		if not _scenery_only(child): return false
	return true


func _expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("L5 capsule component: " + message)
	return ok


func _retain(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _retain(child, refs)


func _finish() -> void:
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		_retain(game, refs)
		game.queue_free()
	paused = false
	await process_frame
	await process_frame
	_expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "normal shared Main and every capsule descendant dispose")
	print("L5 capsule native component: %d checks, %d failures; no contact/clock/route/art claim" % [checks, failures])
	quit(0 if failures == 0 else 1)
