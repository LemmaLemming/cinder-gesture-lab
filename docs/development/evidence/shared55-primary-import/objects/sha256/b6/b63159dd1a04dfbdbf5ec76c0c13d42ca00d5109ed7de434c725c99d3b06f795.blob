extends SceneTree
## TEST ONLY native Shell constructor/restore candidates, never act acceptance.
## The saved actor is captured at its actual spawn without a pose/resource edit.
## Donor separation uses actual public dashes, not a transform or clock proxy.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Player = preload("res://scripts/player.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Framing = preload("res://scripts/presentation/camera_framing.gd")
const LEVEL_PATH: String = "res://tests/fixtures/restore_candidate_level.tscn"
const LONG_OBJECTIVE: String = "TEST ONLY CANDIDATE: KEEP THE COMPLETE ACTUAL PLAYER BODY, BILLBOARD AND CONTACT SHADOW BELOW THIS REAL MULTILINE OBJECTIVE."

var game: CinderCampaignShell
var candidate: Dictionary = {}
var checks: int = 0
var failures: int = 0
var finished: bool = false
var test_root: String
var registry_bytes: String
var old_fps: int
var old_audio: AudioBusLayout


func _initialize() -> void:
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	test_root = "user://test-camera-candidate-framing-%d/" % OS.get_process_id()
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "bounded native fixture watchdog")
			_finish())
	root.size = Vector2i(540, 1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	registry_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var raw: Dictionary = JSON.parse_string(registry_bytes)
	for entry: Dictionary in raw.levels:
		if entry.id == "A1-L1":
			entry.scene_path = LEVEL_PATH
			entry.readiness = "accepted"
			entry.accepted_commit = "a".repeat(40)
			entry.api_revision = Registry.API_REVISION
	game = Shell.new()
	if not _guard(game.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "isolated TEST ONLY registry/configuration uses the actual Shell"):
		_finish(); return
	root.add_child(game)
	await _frames(4)
	if not _guard(paused and game.player == null and game.active_level == null and game.menu.page_name() == "title", "fresh actual Title owns a ready camera/HUD but no installed Player"):
		_finish(); return

	# Actual normal constructor first; its pristine native unit is the save.
	var seed: Dictionary = game._prepare("A1-L1", Equipment.STARTER)
	if not _guard(not seed.is_empty(), "actual Shell constructor creates a real Player, floor and recipient: " + game.campaign_error):
		_finish(); return
	var saved: Dictionary = game._capture(seed.player, seed.level, game._fresh_shell_state())
	_expect(not saved.is_empty() and seed.level.normal_entries == 1, "capture preserves actual initial physical pose/resources without editing the saved actor")
	game._dispose(seed)
	if saved.is_empty():
		_finish(); return
	candidate = game._prepare_snapshot(saved)
	if not _guard(not candidate.is_empty(), "whole saved unit constructs and quietly restores a genuine hidden native candidate: " + game.campaign_error):
		_finish(); return
	_expect(candidate.level.normal_entries == 0 and candidate.level.restore_entries == 1 and candidate.level.quiet_commits == 1 and candidate.level.is_restore_candidate(), "restored candidate remains nonplayable; its actual restore hook ran once")
	_expect(not candidate.container.visible and candidate.viewport.own_world_3d and candidate.camera == candidate.viewport.get_camera_3d(), "candidate retains its hidden container, independent native World3D and current stage camera")
	_expect(candidate.player.get_world_3d() != game.camera.get_world_3d() and candidate.player.get_viewport() == candidate.camera.get_viewport(), "actual candidate actor/camera share their own world, distinct from the empty Title world")
	_expect(_same(saved.player, candidate.player.snapshot_state()), "quiet constructor preserves the exact captured physical body, resources and action state")
	var required: Array = _recipient_points(candidate.level)
	if not _guard(required.size() == 8, "required source points come from the actual retained native recipient Box" ):
		_finish(); return
	_probe_candidate(required, "fresh Title")
	_expect(not game.camera_framing_plan(required, candidate.player.global_position).accepted, "legacy no-argument path still honestly refuses Title's null installed Player")
	_native_projection_control(required)
	_viewport_and_hud_controls(required)
	_invalid_controls(required)
	# Retire the paused probe before genuine donor simulation. A hidden staged
	# candidate is never left running merely because its container is hidden.
	game._dispose(candidate)
	candidate = {}

	# Public actual Begin/Resume installs another topology. The candidate never
	# becomes Game.player; actual native simulation alone separates the donor.
	game.menu.begin_story_requested.emit()
	await _frames(5)
	if not _guard(is_instance_valid(game.player) and game.campaign_error.is_empty(), "actual public Begin installs the separate native donor: " + game.campaign_error):
		_finish(); return
	game.resume_campaign()
	await create_timer(0.15).timeout
	if not _guard(not paused and game.active_level.open_future_room(), "public Resume and genuine fixture transition create installed room 2"):
		_finish(); return
	for index: int in range(2):
		if not _guard(game.player.request_dash(Vector3.LEFT), "actual public donor dash %d is accepted" % (index + 1)):
			_finish(); return
		await create_timer(0.75).timeout
		if not _guard(not paused and not game.player.get_committed_dash_state().active, "actual donor dash completes without a focus override or synthetic deadline"):
			_finish(); return
	game.request_pause()
	await _frames(5)
	if not _guard(paused and game.menu.page_name() == "pause" and game.campaign_error.is_empty(), "public deferred Pause captures a whole native donor tick"):
		_finish(); return
	candidate = game._prepare_snapshot(saved)
	if not _guard(not candidate.is_empty() and _same(saved.player, candidate.player.snapshot_state()), "earlier saved physical actor reconstructs quietly against the different installed donor: " + game.campaign_error):
		_finish(); return
	required = _recipient_points(candidate.level)
	_expect(game.active_level.room_index == 2 and candidate.level.room_index == 1 and game.player.global_position.x < -5.0, "earlier hidden room 1 and physically separated installed room 2 coexist without alias rewrites")
	_probe_candidate(required, "different installed donor")
	_expect(not game.camera_framing_plan(required, candidate.player.global_position).accepted, "legacy union honestly includes the distant donor and cannot substitute for the candidate view")
	_live_equivalence()
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == registry_bytes, "TEST ONLY metadata leaves actual production registry bytes unchanged")
	_finish()


func _probe_candidate(required: Array, label: String) -> void:
	var before: Dictionary = _receipt()
	var points: Array = game.player_camera_framing_points_for(candidate.player, candidate.camera)
	var plan: Dictionary = game.camera_framing_plan_for_player(required, candidate.player.global_position + Vector3.UP * 0.75, candidate.player, candidate.camera)
	var error: String = game.camera_framing_error_for_player(required, candidate.player, candidate.camera)
	_expect(points.size() == 22, label + ": actual capsule, billboard and contact shadow all contribute native bounds")
	_expect(_actual_components_present(points), label + ": mandatory bounds retain independently measured capsule corners, native triangle vertices and shadow corners")
	_expect(plan.get("accepted", false) and plan.get("point_count", 0) == required.size() + points.size(), label + ": finite source/player union is planned without appending donor bounds")
	_expect(plan.get("width") == game.camera.size and plan.get("basis") == candidate.camera.global_basis and plan.get("safe_rect") == game.hud.combat_safe_rect(), label + ": fit uses actual fixed camera and current shared HUD")
	_expect(_receipt() == before, label + ": points/plan/current-error queries change no aliases, physical state, camera, focus, input, world or saved attempt (current error: " + error + ")")
	if not points.is_empty():
		points[0] = Vector3.INF
		_expect(game.player_camera_framing_points_for(candidate.player, candidate.camera)[0].is_finite(), label + ": returned bounds have independent value custody")
	if plan.get("accepted", false):
		plan["focus"] = Vector3.INF
		_expect(game.camera_framing_plan_for_player(required, candidate.player.global_position + Vector3.UP * 0.75, candidate.player, candidate.camera).focus.is_finite(), label + ": returned plans have independent value custody")
	_expect(_receipt() == before, label + ": mutating query results cannot mutate the native unit")


func _native_projection_control(required: Array) -> void:
	var plan: Dictionary = game.camera_framing_plan_for_player(required, candidate.player.global_position + Vector3.UP * 0.75, candidate.player, candidate.camera)
	if not _guard(plan.get("accepted", false), "actual candidate accepts a fit before independent native projection control"):
		return
	var initial: Transform3D = candidate.camera.global_transform
	# Explicit TEST ONLY application after query purity was already proven. The
	# API itself never applies this plan. Native Camera3D supplies the oracle.
	candidate.camera.global_position = plan.camera_position
	var all_points: Array = required.duplicate()
	all_points.append_array(game.player_camera_framing_points_for(candidate.player, candidate.camera))
	var safe: Rect2 = game.hud.combat_safe_rect()
	var contained: bool = true
	for point: Vector3 in all_points:
		var normalized: Vector2 = candidate.camera.unproject_position(point) / Vector2(candidate.viewport.size)
		contained = contained and safe.has_point(normalized) and not candidate.camera.is_position_behind(point)
	_expect(contained and game.camera_framing_error_for_player(required, candidate.player, candidate.camera).is_empty(), "actual native projection of the complete union independently fits below HUD after explicit plan application")
	_expect(candidate.camera.global_basis == initial.basis and candidate.camera.size == game.camera.size, "applying a proposed translation retains fixed native basis/width")
	candidate.camera.global_transform = initial


func _viewport_and_hud_controls(required: Array) -> void:
	var original_size: Vector2i = candidate.viewport.size
	var original_stretch: bool = candidate.container.stretch
	var original: Dictionary = _receipt()
	# TEST ONLY native aspect control after the untouched real Shell case.
	# SubViewport.size is writable only without the parent's stretch override:
	# https://docs.godotengine.org/en/latest/classes/class_subviewport.html
	candidate.container.stretch = false
	candidate.viewport.size = Vector2i(270, 700)
	var before: Dictionary = _receipt()
	var changed: Dictionary = game.camera_framing_plan_for_player(required, candidate.player.global_position, candidate.player, candidate.camera)
	_expect(candidate.viewport.size == Vector2i(270, 700) and candidate.viewport.size != game.camera.get_viewport().size and changed.get("accepted", false) and _receipt() == before, "labelled native viewport aspect control fits without touching the donor viewport or query state")
	candidate.viewport.size = original_size
	candidate.container.stretch = original_stretch
	_expect(_receipt() == original, "native TEST ONLY aspect control restores the exact original Shell viewport/container and whole unit")
	var short_rect: Rect2 = game.hud.combat_safe_rect()
	game.hud.update_status(100.0, 100.0, 0, 2, 0, LONG_OBJECTIVE)
	var wrapped: Rect2 = game.hud.combat_safe_rect()
	before = _receipt()
	var fitted: Dictionary = game.camera_framing_plan_for_player(required, candidate.player.global_position, candidate.player, candidate.camera)
	_expect(wrapped.position.y > short_rect.position.y and fitted.get("accepted", false) and fitted.safe_rect == wrapped, "explicit candidate fit uses the real newly wrapped shared objective exclusion")
	_expect(_receipt() == before, "framing queries do not relayout HUD or alter the paused native actor while reading its expanded exclusion")


func _invalid_controls(required: Array) -> void:
	var before: Dictionary = _receipt()
	_expect(not game.camera_framing_plan_for_player(["foreign point"], Vector3.ZERO, candidate.player, candidate.camera).accepted, "non-native world point is rejected")
	_expect(not game.camera_framing_plan_for_player(required, Vector3(NAN, 0, 0), candidate.player, candidate.camera).accepted, "nonfinite desired focus is rejected")
	_expect(not game.camera_framing_error_for_player([], candidate.player, candidate.camera).is_empty(), "current-containment query requires actual source bounds")
	var too_many: Array = []
	too_many.resize(Framing.MAX_POINTS + 1)
	too_many.fill(Vector3.ZERO)
	_expect(not game.camera_framing_plan_for_player(too_many, Vector3.ZERO, candidate.player, candidate.camera).accepted, "bounded point capacity fails closed")
	var not_ready: CinderPlayer = Player.new()
	var absent_camera := Camera3D.new()
	_expect(game.player_camera_framing_points_for(not_ready, absent_camera).is_empty() and not game.camera_framing_plan_for_player(required, Vector3.ZERO, not_ready, absent_camera).accepted, "real but unready native player/camera fail honestly")
	not_ready.free()
	absent_camera.free()
	_expect(game.player_camera_framing_points_for(candidate.player, game.camera).is_empty(), "ready Title camera in a foreign native world cannot frame the candidate actor")
	_expect(_receipt() == before, "all malformed and foreign bindings reject before any native state mutation")
	var extra := Camera3D.new()
	extra.projection = candidate.camera.projection
	extra.keep_aspect = candidate.camera.keep_aspect
	extra.size = candidate.camera.size
	candidate.stage.add_child(extra)
	extra.global_transform = candidate.camera.global_transform
	extra.current = false
	_expect(game.player_camera_framing_points_for(candidate.player, extra).is_empty(), "equivalent same-world camera fails unless it is the actual current native camera")
	extra.free()
	var width: float = candidate.camera.size
	candidate.camera.size = width - 1.0
	_expect(not game.camera_framing_plan_for_player(required, Vector3.ZERO, candidate.player, candidate.camera).accepted, "narrowing candidate camera width violates actual shared projection policy")
	candidate.camera.size = width
	var transform: Transform3D = candidate.camera.global_transform
	candidate.camera.rotate_y(0.1)
	_expect(game.player_camera_framing_points_for(candidate.player, candidate.camera).is_empty(), "candidate basis drift fails closed")
	candidate.camera.global_transform = transform
	var sprite: Sprite3D = candidate.player.get_node("ActorSprite")
	var billboard: int = sprite.billboard
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_expect(game.player_camera_framing_points_for(candidate.player, candidate.camera).is_empty(), "unsupported actual sprite policy cannot silently use a physical-only proxy")
	sprite.billboard = billboard
	_expect(_receipt() == before, "restoring explicit TEST ONLY invalid preconditions leaves the original candidate unit exact")


func _live_equivalence() -> void:
	var required: Array = _recipient_points(game.active_level)
	var before: Dictionary = _receipt()
	var focus: Vector3 = game.player.global_position + Vector3.UP * 0.75
	_expect(game.player_camera_framing_points() == game.player_camera_framing_points_for(game.player, game.camera), "same actual installed actor/camera yields identical legacy and explicit native bounds")
	_expect(game.camera_framing_plan(required, focus) == game.camera_framing_plan_for_player(required, focus, game.player, game.camera), "same actual installed actor/camera yields identical legacy and explicit plans, including honest rejection")
	_expect(game.camera_framing_error(required) == game.camera_framing_error_for_player(required, game.player, game.camera), "same actual installed actor/camera yields identical current-containment errors")
	_expect(_receipt() == before, "legacy equivalence probes preserve the whole donor/candidate pair")


func _recipient_points(level: CinderLevel) -> Array:
	var body: CharacterBody3D = level.get("recipient")
	var shape: CollisionShape3D = body.get_node("ImmutableBodyCollision")
	if not shape.shape is BoxShape3D:
		return []
	var size: Vector3 = (shape.shape as BoxShape3D).size
	return _corners(AABB(-size * 0.5, size), shape.global_transform)


func _actual_components_present(points: Array) -> bool:
	var collision: CollisionShape3D = candidate.player.get_node("BodyCollision")
	var capsule: CapsuleShape3D = collision.shape
	var physical: Array = _corners(AABB(Vector3(-capsule.radius, -capsule.height * 0.5, -capsule.radius), Vector3(capsule.radius * 2.0, capsule.height, capsule.radius * 2.0)), collision.global_transform)
	var sprite: Sprite3D = candidate.player.get_node("ActorSprite")
	var vertices: PackedVector3Array = sprite.generate_triangle_mesh().get_faces()
	var scale: Vector3 = sprite.global_basis.get_scale()
	for vertex: Vector3 in vertices:
		physical.append(sprite.global_position + candidate.camera.global_basis.x * vertex.x * scale.x + candidate.camera.global_basis.y * vertex.y * scale.y)
	var shadow: MeshInstance3D = candidate.player.get_node("ContactShadow")
	physical.append_array(_corners(shadow.get_aabb(), shadow.global_transform))
	for point: Vector3 in physical:
		if not points.has(point): return false
	return physical.size() == 22


func _corners(box: AABB, transform: Transform3D) -> Array:
	var result: Array = []
	for x: int in range(2):
		for y: int in range(2):
			for z: int in range(2):
				result.append(transform * (box.position + box.size * Vector3(x, y, z)))
	return result


func _receipt() -> Dictionary:
	var result: Dictionary = {"paused": paused, "focus": root.has_focus(), "aliases": [_id(game.player), _id(game.camera), _id(game.world), _id(game.active_level)], "shell": Exact.stringify(game._shell_state()), "attempt": Exact.stringify(game.attempts.state()), "input": game.get_input_observation_state(), "anchor": game.get_aim_anchor_normalized(), "framing": game.get_camera_framing_state(), "error": game.last_camera_framing_error, "installed_camera": [game.camera.global_transform, game.camera.size, game.camera.current, game.camera.get_viewport().size], "hud": game.hud.combat_safe_rect(), "candidate": _unit_receipt(candidate)}
	if is_instance_valid(game.player):
		result["donor"] = {"player": Exact.stringify(game.player.snapshot_state()), "level": game.active_level.get("room_index"), "authority": game.active_level.call("authority_state")}
	return result


func _unit_receipt(unit: Dictionary) -> Dictionary:
	var actor: CinderPlayer = unit.player
	var body: CollisionShape3D = actor.get_node("BodyCollision")
	var sprite: Sprite3D = actor.get_node("ActorSprite")
	var shadow: MeshInstance3D = actor.get_node("ContactShadow")
	return {"player": Exact.stringify(actor.snapshot_state()), "authority": unit.level.authority_state(), "native": [actor.global_transform, body.global_transform, sprite.global_transform, shadow.global_transform, _id(body.shape), _id(sprite.texture), _id(shadow.mesh), _id(shadow.material_override)], "camera": [unit.camera.global_transform, unit.camera.size, unit.camera.current, unit.camera.near, unit.camera.far, unit.camera.cull_mask], "world": [_id(actor.get_world_3d()), _id(unit.viewport.world_3d), unit.stage.get_child_count(), actor.get_child_count(), unit.level.get_child_count()], "viewport": [unit.viewport.size, unit.viewport.own_world_3d, unit.container.visible, unit.container.stretch, unit.container.stretch_shrink, unit.container.size]}


func _id(value: Variant) -> int:
	return value.get_instance_id() if is_instance_valid(value) else 0


func _same(left: Variant, right: Variant) -> bool:
	var text: String = Exact.stringify(left)
	return not text.is_empty() and text == Exact.stringify(right)


func _frames(count: int) -> void:
	for _index: int in range(count): await process_frame


func _guard(ok: bool, note: String) -> bool:
	_expect(ok, note)
	return ok


func _expect(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + note)


func _finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(game):
		if not candidate.is_empty(): game._dispose(candidate)
		game.free()
	paused = false
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps
	AudioServer.set_bus_layout(old_audio)
	print("Camera candidate framing smoke: %d checks, %d failures; TEST ONLY native Shell hidden restore recipient/live equivalence; no authored level or native OS gesture claim" % [checks, failures])
	quit(1 if failures else 0)
