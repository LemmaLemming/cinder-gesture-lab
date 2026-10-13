extends SceneTree
## Focused initial loading fixture. Parent/core/adapter/scene published together
## for the new-resource import and dev.py execution. Fresh Main loading only;
## no earned route, attack, whole-save/Retry or production transition credit.
## No Hero/source/equipment/HP/body/camera writes. --portrait is optional and
## deliberately distinct from Main's preview-and-quit --capture selector.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const StalkerScript = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const ROOM: String = "res://scenes/acts/act3/a3_l4_false_paradise.tscn"
const FIRST_ID: String = "l4-rest-stalker"
const SAVE_LIMIT: String = "False Paradise has no complete whole-parent codec: Save, Continue, checkpoint dispatch and fresh Retry restoration are unsupported"
const FLOOR_RECT := Rect2(-7, -14, 14, 78)

class PostActorBarrier extends Node:
	signal observed
	var waiting: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		if waiting:
			waiting = false
			observed.emit()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting:
			_wake.call_deferred()
	func _wake() -> void:
		if waiting:
			waiting = false
			observed.emit()

var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _scheduler: CinderThreatScheduler
var _scenery: Node3D
var _first: CinderAct3SunboundStalker
var _exit_cue: CinderInteractionCue
var _barrier: PostActorBarrier
var _kit: Dictionary = {}
var _hero_hp: float = 0.0
var _events: Array[String] = []
var _checks: int = 0
var _failures: int = 0
var _portrait_enabled: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--portrait" and not _portrait_enabled:
			_portrait_enabled = true
		else:
			_expect(false, "only one optional --portrait selector is supported", argument)
			await _finish()
			return
	if _portrait_enabled and not _expect(DisplayServer.get_name() != "headless", "--portrait requires native graphical rendering"):
		await _finish()
		return
	if not await _open():
		await _finish()
		return
	if not await _first_entry():
		await _finish()
		return
	if not await _completed_pause():
		await _finish()
		return
	if _save_refusal() and _foreign_camera_rejection():
		await _portrait()
	await _finish()


func _open() -> bool:
	# Default real Main first, then public fresh replacement of its paused lab.
	_game = MainScene.instantiate()
	root.add_child(_game)
	_game.call("open_bench") # Pause before yielding a native physics tick.
	var old_level: CinderLevel = _game.get("active_level") as CinderLevel
	var old_hero: CinderPlayer = _game.get("player") as CinderPlayer
	if not _expect(paused and old_level != null and old_hero != null and _game.call("is_lab_level") and get_nodes_in_group("enemies").is_empty(), "real initial Main has an enemy-free paused lab replacement boundary"):
		return false
	var old_refs: Array[WeakRef] = []
	_weakrefs(old_level, old_refs)
	_weakrefs(old_hero, old_refs)
	for group: String in ["practice_targets", "lab_weapons"]:
		for node: Node in get_nodes_in_group(group):
			if _game.is_ancestor_of(node):
				_weakrefs(node, old_refs)
	if not _expect(_game.call("load_level_scene", ROOM), "public Main fresh load selects the authored False Paradise scene", String(_game.get("level_load_error"))):
		return false
	_game.call("open_bench") # The replacement remains paused before any tick.
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(paused and _level != null and _hero != null and _level != old_level and _hero != old_hero and _level.scene_file_path == ROOM and _level.level_id == "A3-L4" and _level.local_snapshot_version == 1 and _level.contract_error().is_empty(), "fresh native parent retains A3-L4 identity/local1 and its intended authored scene"):
		return false
	_scenery = _level.get("scenery") as Node3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	_exit_cue = _level.get("exit_cue") as CinderInteractionCue
	if not _expect(_scenery != null and _scheduler != null and _exit_cue != null and _scheduler.get_script() == SchedulerScript and _scheduler.get_parent() == _level and _scenery.get_parent() == _level and String(_level.call("runtime_error")).is_empty(), "actual ready parent/scenery/one Scheduler bind without a configuration error", String(_level.call("runtime_error"))):
		return false
	var schedulers: Array[Node] = []
	_find_script(_game, SchedulerScript, schedulers)
	var state: Dictionary = _level.call("state")
	var sources: Dictionary = _level.get("sources")
	if not _expect(_level.global_transform == Transform3D.IDENTITY and _level.spawn_position() == Vector3(0, 0.1, 58) and _hero.global_position == _level.spawn_position() and _hero.presentation_id == "act3_traveller" and _hero.hp == _hero.max_hp and not _hero.dead and schedulers.size() == 1 and schedulers[0] == _scheduler and _scheduler.get_clock() == 0.0 and _scheduler.encounter_profile().get("id") == "standard" and _scheduler.reservations().is_empty() and sources.is_empty() and not is_instance_valid(_level.get("root_network")) and state.route.entries.is_empty() and state.echo_records.is_empty() and get_nodes_in_group("enemies").is_empty(), "paused fresh spawn58 is identity1, Standard clock0, one actual Scheduler and no premature source/core/Echo/helper"):
		return false
	_hero_hp = _hero.hp
	_kit = _hero.equipment.snapshot()
	_barrier = PostActorBarrier.new()
	_game.add_child(_barrier)
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _events.append("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _events.append("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _events.append("exit"))
	if not _floor_bindings(false):
		return false
	for _i: int in range(5):
		await process_frame # Actual paused queue cleanup; no source tick.
	var released: bool = true
	for retained: WeakRef in old_refs:
		released = released and retained.get_ref() == null
	return _expect(released and get_nodes_in_group("practice_targets").is_empty() and get_nodes_in_group("lab_weapons").is_empty() and paused and _scheduler.get_clock() == 0.0 and _hero.get_world_action_records().is_empty(), "old native lab/Hero/targets/weapons release while the fresh parent stays at clock0")


func _floor_bindings(first_installed: bool) -> bool:
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var body: StaticBody3D = _scenery.get("floor_body") as StaticBody3D
	var collision: CollisionShape3D = body.get_node_or_null("Solid") as CollisionShape3D if body != null else null
	if not _expect(body != null and collision != null and collision.shape is BoxShape3D and body.get_class() == "StaticBody3D" and body.get_script() == null and body.get_parent() == _scenery and body.global_transform == Transform3D(Basis.IDENTITY, Vector3(0, -0.5, 25)) and body.collision_layer == 1 and body.collision_mask == 0 and body.constant_linear_velocity == Vector3.ZERO and body.constant_angular_velocity == Vector3.ZERO and collision.get_parent() == body and collision.transform == Transform3D.IDENTITY and not collision.disabled and (collision.shape as BoxShape3D).size == Vector3(14, 1, 78), "native permanent14×1×78 static floor retains exact layer/body/shape/transform"):
		return false
	var floor: Dictionary = bindings.get("floors", {})
	var actors: Dictionary = bindings.get("actors", {})
	var owners: Dictionary = bindings.get("owners", {})
	var expected_owner: bool = (owners.size() == 1 and owners.get(FIRST_ID) == _first) if first_installed else owners.is_empty()
	if not _expect(bindings.get("world_root") == _level.get_parent() and _hero.get_parent() == bindings.world_root and actors.size() == 1 and actors.get("hero") == _hero and floor.size() == 1 and floor.has("firm-garden") and floor["firm-garden"].collision == collision and floor["firm-garden"].safe_rect == FLOOR_RECT and expected_owner, "public Scheduler bindings join this actual Hero/world, permanent floor and exactly the entitled native owners"):
		return false
	var signature: Dictionary = _scheduler.authored_floor_signature(bindings.world_root, floor.values())
	return _expect(signature.get("accepted", false) and signature.signature.size() == 1 and signature.signature[0].safe_rect == [-7.0, -14.0, 14.0, 78.0] and signature.signature[0].top_y == 0.0, "actual Scheduler derives the canonical continuous safe-floor signature", String(signature.get("reason", "")))


func _first_entry() -> bool:
	_game.call("resume_lab")
	if not _expect(not paused, "public Main resumes the actual fresh parent"):
		return false
	for _i: int in range(48):
		if int(_level.call("seen_entry", "offered-rest")) == 0:
			var sources: Dictionary = _level.get("sources")
			_first = sources.get(FIRST_ID) as CinderAct3SunboundStalker
			var state: Dictionary = _level.call("state")
			if not _expect(_hero.is_on_floor() and absf(_hero.global_position.x) < 0.000001 and absf(_hero.global_position.z - 58.0) < 0.000001 and sources.size() == 1 and _first != null and _first.get_script() == StalkerScript and _first.get_parent() == _level and _first.state().stable_id == FIRST_ID and _first.hp == _first.max_hp and _first.hp > 0.0 and not _first.dead and _first.is_in_group("enemies") and _first.collision_layer == 2 and _first.collision_mask == 1 and state.route.entries.size() == 1 and state.route.entries[0].id == "offered-rest" and state.route.entries[0].beat == 1 and state.route.entries[0].hero_position == [0.0, _hero.global_position.y, 58.0] and get_nodes_in_group("enemies").size() == 1 and get_nodes_in_group("enemies")[0] == _first, "actual grounded entry installs only the genuine living first Stalker without relocating Hero or fabricating progress"):
				return false
			_first.hit_resolved.connect(func(_result: Dictionary) -> void: _events.append("hit"))
			var shape: CollisionShape3D = _first.get_node_or_null("BodyCollision") as CollisionShape3D
			if not _expect(shape != null and shape.shape is CapsuleShape3D and not shape.disabled and _no_later_entitlement(state) and _exit_cue.state().state == "clear" and not _exit_cue.state().visible and _hero.get_world_action_records().is_empty(), "first native capsule/clear exit remain genuine; no premature later court, Echo, low-root core, helper or player action"):
				return false
			return _floor_bindings(true)
		if not await _tick():
			return false
	return _expect(false, "finite ordinary grounded spawn reaches the first entry", str(_level.call("state")))


func _no_later_entitlement(state: Dictionary) -> bool:
	if is_instance_valid(_level.get("root_network")) or not state.root_network.is_empty() or not state.echo_records.is_empty() or not state.route.deaths.is_empty() or not state.route.retired_sources.is_empty() or state.disengaged or state.completed or state.exit_state != "clear" or not state.contact.is_empty() or state.sun.started or state.sun.anchor_s != null or state.persistence_supported or state.checkpoint_dispatch_supported:
		return false
	for entry: String in ["beauty-source", "plain-path", "root-court", "garden-release"]:
		if int(_level.call("seen_entry", entry)) != -1:
			return false
	for id: String in ["l4-beauty-root", "l4-plain-echo", "l4-plain-root", "l4-garden-helper"]:
		if not state.sources.has(id) or state.sources[id].installed or state.sources[id].retired or not state.sources[id].source.is_empty():
			return false
	return true


func _tick() -> bool:
	if paused:
		return _expect(false, "ordinary fresh loading cannot tick during an unexpected pause")
	_barrier.waiting = true
	await _barrier.observed
	var error: String = String(_level.call("runtime_error"))
	var operands: Dictionary = {"paused": paused, "pause_requested": _game.call("is_pause_requested"), "runtime_error": error, "clock_s": _scheduler.get_clock(), "hp": _hero.hp, "expected_hp": _hero_hp, "dead": _hero.dead, "kit_exact": _hero.equipment.snapshot() == _kit, "actions": _hero.get_world_action_records(), "events": _events.duplicate()}
	return _expect(not paused and error.is_empty() and _scheduler.get_clock() <= 0.8 and _hero.hp == _hero_hp and not _hero.dead and _hero.equipment.snapshot() == _kit and _hero.get_world_action_records().is_empty() and _events.is_empty(), "bounded post-actor initial ticks preserve actual runtime/HP/kit and execute no attack/progress dispatch", str(operands))


func _completed_pause() -> bool:
	if not _expect(_game.call("request_pause_deferred"), "public Main requests pause after the complete native entry tick"):
		return false
	for _i: int in range(4):
		await process_frame
	if not _expect(paused and not _game.call("is_pause_requested"), "public deferred pause completes at the native barrier"):
		return false
	var before: Dictionary = _observation()
	for _i: int in range(5):
		await process_frame
	var union: Dictionary = _level.call("camera_framing_union", "", [], true, false)
	var error: String = String(_game.call("camera_framing_error", union.get("points", [])))
	return _expect(before == _observation() and String(union.get("error", "")).is_empty() and not union.get("points", []).is_empty() and error.is_empty() and _hero.hp == _hero_hp and _events.is_empty(), "completed pause freezes real Hero/source/Scheduler/input/current camera and retains actual initial portrait containment", error)


func _save_refusal() -> bool:
	var before: Dictionary = _observation()
	var player: Dictionary = _hero.snapshot_state()
	var unit: Dictionary = _level.snapshot_state()
	var ordinary_error: String = _level.last_snapshot_error
	var camera: Camera3D = _hero.get_viewport().get_camera_3d()
	var hud: GameHUD = _game.get("hud") as GameHUD
	var presentation: Dictionary = _level.snapshot_state_for_presentation(camera, hud)
	return _expect(not player.is_empty() and unit.is_empty() and presentation.is_empty() and ordinary_error == SAVE_LIMIT and _level.last_snapshot_error == SAVE_LIMIT and before == _observation() and not _level.is_completed() and _level.current_checkpoint() == {"id": "", "kind": ""}, "genuine paused Hero capture succeeds while unfinished whole-parent Save explicitly refuses without mutation or checkpoint credit", _level.last_snapshot_error)


func _foreign_camera_rejection() -> bool:
	var camera: Camera3D = _hero.get_viewport().get_camera_3d()
	var hud: GameHUD = _game.get("hud") as GameHUD
	var union: Dictionary = _level.call("camera_framing_union", "", [], true, false)
	var before: Dictionary = _observation()
	var positive: String = String(_game.call("camera_framing_error_for_context", union.get("points", []), _hero, camera, hud))
	# TEST ONLY foreign native sibling, with no property/camera alias writes.
	# The original current camera is already installed before this new node.
	var foreign := Camera3D.new()
	foreign.name = "UnselectedForeignCameraFixture"
	(_level.get_parent() as Node3D).add_child(foreign)
	var game_error: String = String(_game.call("camera_framing_error_for_context", union.get("points", []), _hero, foreign, hud))
	var source: Dictionary = _first.current_render_framing_points_for_context(_game, _hero, foreign)
	var scenery: Dictionary = _scenery.call("likeness_framing_points", foreign)
	var ok: bool = positive.is_empty() and foreign.get_script() == null and foreign.get_viewport() == camera.get_viewport() and foreign.get_world_3d() == camera.get_world_3d() and not foreign.is_current() and foreign.get_viewport().get_camera_3d() == camera and not game_error.is_empty() and not String(source.get("error", "")).is_empty() and source.get("points", []).is_empty() and not String(scenery.get("error", "")).is_empty() and scenery.get("points", []).is_empty() and before == _observation()
	foreign.free()
	return _expect(ok and before == _observation(), "supported Game/source/scenery APIs reject an actual foreign noncurrent native Camera without changing current bindings or state", game_error)


func _observation() -> Dictionary:
	var camera: Camera3D = _hero.get_viewport().get_camera_3d()
	return {"level": _level.call("state"), "hero_transform": _hero.global_transform, "hp": _hero.hp, "kit": _hero.equipment.snapshot(), "response": _hero.get_threat_response_state(), "actions": _hero.get_world_action_records(), "scheduler_clock": _scheduler.get_clock(), "leases": _scheduler.reservations(), "source": _first.state() if is_instance_valid(_first) else {}, "exit_cue": _exit_cue.state(), "scenery": _scenery.call("presentation_state"), "floor_transform": (_scenery.get("floor_body") as StaticBody3D).global_transform, "camera_instance": camera.get_instance_id(), "camera_transform": camera.global_transform, "camera_size": camera.size, "input": _game.call("get_input_observation_state"), "events": _events.duplicate()}


func _portrait() -> bool:
	if not _portrait_enabled:
		return true
	_game.call("resume_lab") # Real public UI/input resume; no replacement HUD.
	if not _expect(not paused, "public resume clears the native pause overlay for the optional portrait"):
		return false
	paused = true # Disclosed TEST ONLY render freeze; no intervening world tick.
	var before: Dictionary = _observation()
	await process_frame
	await RenderingServer.frame_post_draw
	var union: Dictionary = _level.call("camera_framing_union", "", [], true, false)
	var error: String = String(_game.call("camera_framing_error", union.get("points", [])))
	var image: Image = root.get_texture().get_image()
	var directory: String = ProjectSettings.globalize_path("res://.cinder/a3-l4-false-paradise-initial-portraits")
	var path: String = directory.path_join("fresh-offered-rest.png")
	var ok: bool = String(union.get("error", "")).is_empty() and error.is_empty() and before == _observation() and image != null and image.get_size() == Vector2i(339, 736)
	if ok:
		ok = DirAccess.make_dir_recursive_absolute(directory) == OK and image.save_png(path) == OK
	if ok:
		print("PORTRAIT: " + path)
	# Retain this disclosed freeze until immediate public exit; no extra play.
	return _expect(ok, "unchanged actual339×736 initial portrait, public overlay clear and frozen render only", error)


func _find_script(node: Node, script: Script, result: Array[Node]) -> void:
	if node.get_script() == script:
		result.append(node)
	for child: Node in node.get_children():
		_find_script(child, script, result)


func _weakrefs(node: Node, result: Array[WeakRef]) -> void:
	result.append(weakref(node))
	for child: Node in node.get_children():
		_weakrefs(child, result)


func _close() -> void:
	if not is_instance_valid(_game):
		return
	var old: Array[WeakRef] = []
	_weakrefs(_game, old)
	if is_instance_valid(_level):
		_level.exit_level() # Normal public whole-parent retirement, not fake completion.
		if is_instance_valid(_scheduler) and is_instance_valid(_first) and is_instance_valid(_exit_cue):
			var cue: CinderThreatCue = _first.get_node_or_null("RequiredThreatCue") as CinderThreatCue
			_expect(_scheduler.reservations().is_empty() and not _first.is_physics_processing() and cue != null and cue.state().phase == "clear" and _exit_cue.state().state == "clear" and _level.hero == null and _level.shared_shell == null and _events.is_empty(), "public parent exit synchronously closes actual first-source leases/cues/processing and disarms level bindings")
	if is_instance_valid(_barrier):
		_barrier.waiting = false
	_game.queue_free()
	paused = false
	for _i: int in range(5):
		await process_frame
	var released: bool = true
	for retained: WeakRef in old:
		released = released and retained.get_ref() == null
	_expect(released and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("practice_targets").is_empty() and get_nodes_in_group("lab_weapons").is_empty(), "normal native queue disposal releases every old-world descendant/Hero/source/cue before replacement")
	_game = null
	_level = null
	_hero = null
	_scheduler = null
	_scenery = null
	_first = null
	_exit_cue = null
	_barrier = null


func _finish() -> void:
	await _close()
	await create_timer(0.15, true, false, true).timeout # Finite actual audio drain.
	print("False Paradise initial loading: %d checks; failures: %d. Fresh Main entry, unfinished-save refusal, foreign-camera rejection and disposal only; no earned route/mechanics/wholeSave/Retry/production transition acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok
