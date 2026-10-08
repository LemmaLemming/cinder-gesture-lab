extends SceneTree
## Actual shared Game/level/player/HUD/render fixture. Anonymous source/landing
## arrangement only: no authored Sun1, physical lunge, damage or act acceptance.

const Game = preload("res://scripts/game.gd")
const Sprite = preload("res://scripts/pixel_sprite.gd")
const Cue = preload("res://scripts/cues/threat_cue.gd")
const CueMesh = preload("res://scripts/cues/cue_mesh.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")

class FixtureLevel extends CinderLevel:
	var required_points: Array = []
	var source: LabSprite
	var crest: MeshInstance3D
	var landing: MeshInstance3D
	var cue: CinderThreatCue
	var forecast: Dictionary = {}

	func _init() -> void:
		name = "AnonymousCameraFixture"
		objective_text = "SHARED CAMERA / SCRIPTED FIXTURE"
		var spawn := Marker3D.new()
		spawn.name = "PlayerSpawn"
		spawn.position = Vector3(0, 0.1, 1.6)
		add_child(spawn)
		var floor_body := StaticBody3D.new()
		floor_body.collision_layer = 1
		floor_body.collision_mask = 0
		floor_body.position = Vector3(0, -0.5, 0)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(24, 1, 24)
		collision.shape = shape
		floor_body.add_child(collision)
		add_child(floor_body)
		_mesh(floor_body, Vector3.ZERO, Vector3(24, 1, 24), Color("494c52"))
		source = Sprite.new()
		source.actor_kind = "enemy"
		source.name = "SharedNativeSourceArt"
		source.visible = false
		add_child(source)
		crest = _mesh(self, Vector3(0, 1.58, 0), Vector3(0.42, 0.1, 0.15), Color("f5e5ba"))
		crest.visible = false
		landing = _mesh(self, Vector3(0, 0.012, 1.6), Vector3(0.9, 0.024, 0.9), Color("8aa39e"))
		landing.visible = false
		cue = Cue.new()
		add_child(cue)

	func _camera_framing_points() -> Array:
		return required_points

	func _mesh(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
		var mesh := BoxMesh.new()
		mesh.size = size
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.position = position
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1.0
		instance.material_override = material
		parent.add_child(instance)
		return instance


class FixtureGame extends "res://scripts/game.gd":
	func is_lab_level() -> bool:
		return false

	func _create_level_instance() -> CinderLevel:
		return FixtureLevel.new()

var _checks: int = 0
var _failures: int = 0
var _finished: bool = false
var _game: FixtureGame
var _graphical: bool = false
var _output: String
var _captures: Array[String] = []
var _old_max_fps: int


func _initialize() -> void:
	_old_max_fps = Engine.max_fps
	_run.call_deferred()


func _run() -> void:
	create_timer(25.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded 25 second fixture watchdog")
			_finish()
	)
	_ensure_uid()
	_graphical = DisplayServer.get_name() != "headless"
	_output = "res://.cinder/camera-framing-shell-%s-%d" % ["graphical" if _graphical else "headless", OS.get_process_id()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	Engine.max_fps = 60
	root.size = Vector2i(540, 1170)
	_game = FixtureGame.new()
	root.add_child(_game)
	await _frames(3)
	# Use the public resume path once after native startup/focus notifications.
	# Normal Game focus-out/pause guards remain inherited and untouched.
	_game.resume_lab()
	paused = true
	await process_frame
	_expect(_game.active_level is FixtureLevel and _game.active_level.contract_error().is_empty() and _game.active_level.level_id.is_empty(), "real Game enters a valid anonymous level without accepted campaign fixtures")
	_expect(_game.camera.get_viewport().size == Vector2i(270, 585) and root.get_visible_rect().size == Vector2(540, 1170), "real pixel SubViewport and HUD use actual 270x585/540x1170 portrait dimensions")
	_expect((_game.camera.get_viewport().get_parent() as SubViewportContainer).texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "actual stretched portrait world retains nearest pixel filtering")
	_empty_follow()
	_native_player_quad()
	_unsupported_native()
	for sign: float in [-1.0, 1.0]:
		await _signed_forecast(sign)
	await _dynamic_hud()
	_invalid_provider()
	await _pause_reset()
	_finish()


func _empty_follow() -> void:
	var level := _game.active_level as FixtureLevel
	level.required_points = []
	_game.player.global_position = Vector3(0, 0.1, 1.6)
	_game._update_camera(0.0, true)
	var expected: Vector3 = _game.player.global_position + Vector3.UP * 0.75
	_expect(not _game.get_camera_framing_state().enabled and _game.camera.global_position == expected + Game.CAMERA_OFFSET, "default empty hook preserves exact ordinary snapped follow")
	_game.player.global_position += Vector3(0.4, 0, -0.3)
	var next: Vector3 = _game.player.global_position + Vector3.UP * 0.75
	expected = expected.lerp(next, 1.0 - exp(-0.02 / Game.CAMERA_FOLLOW_TIME_S))
	_game._update_camera(0.02)
	_expect(_game.camera.global_position == expected + Game.CAMERA_OFFSET and not _game.get_camera_framing_state().enabled, "empty hook preserves existing exponential follow without a framing correction")


func _native_player_quad() -> void:
	var sprite := _game.player.get_node("ActorSprite") as Sprite3D
	var points: Array = _game.player_camera_framing_points()
	var quad: Array = _game.camera_billboard_points(sprite)
	_expect(points.size() == 22 and quad.size() == 6 and sprite.texture is ImageTexture and sprite.material_override == null, "actual shared hero supplies capsule8/native billboard6/shadow8 corners")
	var pixel_rect: Rect2 = Rect2(sprite.offset - Vector2(sprite.texture.get_size()) * 0.5, Vector2(sprite.texture.get_size()))
	var scale: Vector3 = sprite.global_basis.get_scale()
	var centre: Vector2 = _game.camera.unproject_position(sprite.global_position) / Vector2(_game.camera.get_viewport().size)
	var height: float = _game.camera.size * float(_game.camera.get_viewport().size.y) / float(_game.camera.get_viewport().size.x)
	var expected := Rect2(centre + Vector2(pixel_rect.position.x * sprite.pixel_size * scale.x / _game.camera.size, -pixel_rect.end.y * sprite.pixel_size * scale.y / height), Vector2(pixel_rect.size.x * sprite.pixel_size * scale.x / _game.camera.size, pixel_rect.size.y * sprite.pixel_size * scale.y / height))
	var measured: Rect2 = _screen_bounds(quad)
	_expect(measured.position.distance_to(expected.position) < 0.00001 and measured.size.distance_to(expected.size) < 0.00001, "native unprojection independently matches texture/offset/pixel-size feet-anchored billboard extent")
	_expect(pixel_rect.position.y == 0.0 and sprite.offset == Vector2(0, 32) and measured.end.y - centre.y < 0.00001 and sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "actual full quad starts at the native feet pivot and grows upward without a centered proxy")
	var before: Transform3D = _game.camera.global_transform
	var actor_before: Dictionary = _game.player.snapshot_state()
	var anchor: Vector2 = _game.get_aim_anchor_normalized()
	_game.camera_framing_plan([Vector3.ZERO], _game.player.global_position + Vector3.UP * 0.75)
	_game.camera_framing_error([Vector3.ZERO])
	_game.get_camera_framing_state()
	_expect(_game.camera.global_transform == before and _same(actor_before, _game.player.snapshot_state()) and _game.get_aim_anchor_normalized() == anchor, "all public camera views leave actual actor/clocks/camera/input state untouched")


func _unsupported_native() -> void:
	var sprite := _game.player.get_node("ActorSprite") as Sprite3D
	var before: Transform3D = _game.camera.global_transform
	sprite.fixed_size = true
	_expect(_game.camera_billboard_points(sprite).is_empty() and not _game.camera_framing_plan([Vector3.ZERO], Vector3.ZERO).accepted, "unsupported fixed-size actual billboard rejects without a body-proxy fallback")
	sprite.fixed_size = false
	var overlay := ShaderMaterial.new()
	overlay.shader = Shader.new()
	overlay.shader.code = "shader_type spatial; void vertex(){ VERTEX.x += 1.0; }"
	sprite.material_overlay = overlay
	_expect(_game.camera_billboard_points(sprite).is_empty() and not _game.camera_framing_plan([Vector3.ZERO], Vector3.ZERO).accepted, "vertex-displacing material overlay rejects native billboard framing")
	sprite.material_overlay = null
	var width: float = _game.camera.size
	_game.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_expect(not _game.camera_framing_plan([Vector3.ZERO], Vector3.ZERO).accepted and not _game.camera_framing_error([Vector3.ZERO]).is_empty(), "perspective camera cannot masquerade as supported orthographic projection")
	_game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_game.camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_expect(not _game.camera_framing_plan([Vector3.ZERO], Vector3.ZERO).accepted, "unsupported KEEP_HEIGHT rejects exact native spec")
	_game.camera.keep_aspect = Camera3D.KEEP_WIDTH
	for field: String in ["h_offset", "v_offset", "frustum_offset"]:
		_game.camera.set(field, Vector2(0.1, 0) if field == "frustum_offset" else 0.1)
		_expect(not _game.camera_framing_plan([Vector3.ZERO], Vector3.ZERO).accepted and not _game.camera_framing_error([Vector3.ZERO]).is_empty(), "unsupported native " + field + " rejects in planning and current projection")
		_game.camera.set(field, Vector2.ZERO if field == "frustum_offset" else 0.0)
	_expect(_game.camera.global_transform == before and _game.camera.size == width and _game.player_camera_framing_points().size() == 22, "native rejection probes restore unchanged shared camera/hero geometry")


func _signed_forecast(sign: float) -> void:
	var level := _game.active_level as FixtureLevel
	level.cue.clear()
	level.required_points = []
	_game.player.global_position = Vector3(sign * 2.7, 0.1, 1.6)
	_game.player.velocity = Vector3.ZERO
	var source_floor := Vector3(-sign * 1.02606, 0, 2.419079)
	var start := Vector3(0, 0, -0.4)
	level.source.visible = true
	level.crest.visible = true
	level.landing.visible = true
	level.source.global_position = source_floor + Vector3.UP * 0.8
	level.crest.global_position = source_floor + Vector3.UP * 1.58
	level.landing.global_position = Vector3(sign * 2.7, 0.012, 1.6)
	level.forecast = Geometry.lane(start, source_floor, 0.42)
	level.forecast["source_position"] = source_floor
	_game._update_camera(0.0, true)
	_game._record_swipe_end(root.get_visible_rect().size * Vector2(0.78, 0.56))
	var anchor: Vector2 = _game.get_aim_anchor_normalized()
	var direction: Vector3 = _game.aim_direction(root.get_visible_rect().size * Vector2(0.35, 0.72))
	var camera_before: Transform3D = _game.camera.global_transform
	var native_width: float = _game.camera.size
	var actor_before: Dictionary = _game.player.snapshot_state()
	level.required_points = _forecast_points(level, start, source_floor)
	_expect(absf(absf(_game.player.global_position.x - source_floor.x) - 3.72606) < 0.00001 and level.cue.state().phase == "clear", "signed real hero/source separation and complete forecast exist before warning")
	_expect(not _game.camera_framing_error(level.required_points).is_empty(), "ordinary hero-centred view actually clips the signed full committed source union")
	var plan: Dictionary = _game.camera_framing_plan(level.required_points, _game.player.global_position + Vector3.UP * 0.75)
	_expect(plan.get("accepted", false) and _game.camera.global_transform == camera_before and not _game.camera_framing_error(level.required_points).is_empty(), "feasible future framing is pure and does not license the still-clipped actual view: " + plan.get("reason", ""))
	if not plan.get("accepted", false):
		return
	await _capture("%s-before-framing" % ("right" if sign > 0 else "left"))
	_game._update_camera(0.0, true)
	var state: Dictionary = _game.get_camera_framing_state()
	_expect(state.enabled and state.accepted and _game.last_camera_framing_error.is_empty() and _game.camera_framing_error(level.required_points).is_empty(), "actual Game applies the level forecast correction before presenting warning")
	_expect(_game.camera.global_basis == camera_before.basis and _game.camera.size == native_width and _game.camera.projection == Camera3D.PROJECTION_ORTHOGONAL and _game.camera.keep_aspect == Camera3D.KEEP_WIDTH, "applied signed framing retains exact native width and fixed camera basis")
	_expect(_game.get_aim_anchor_normalized() == anchor and _game.aim_direction(root.get_visible_rect().size * Vector2(0.35, 0.72)) == direction and _same(actor_before, _game.player.snapshot_state()), "held final release aim and entire actual player state remain exact after camera translation")
	_expect(_visible(level.required_points + _game.player_camera_framing_points()), "native unprojection/frustum contains full source/crest/cue endcaps/player/landing inside actual HUD-safe bounds")
	_expect(level.cue.present(level.forecast, "warning"), "real required warning cue accepts the same forecast geometry")
	var actual_cue: Array = _node_mesh_points(level.cue.get_node("RequiredFootprintOutline"))
	actual_cue.append_array(_node_mesh_points(level.cue.get_node("RequiredSourceMarker")))
	_expect(_visible(actual_cue), "actual warning outline and source mesh fit after prewarning framing")
	await _capture("%s-warning-framed" % ("right" if sign > 0 else "left"))
	for phase: String in ["lock", "active", "recovery"]:
		_expect(level.cue.present(level.forecast, phase) and _game.camera_framing_error(level.required_points).is_empty(), "retained full forecast supports actual " + phase + " cue without changing geometry")
	var framed: Transform3D = _game.camera.global_transform
	for shake: Vector3 in [Vector3(0.035, 0, 0.035), Vector3(-0.035, 0, -0.035), Vector3(0.035, 0, -0.035), Vector3(-0.035, 0, 0.035)]:
		_game.camera.global_position = framed.origin + shake
		_expect(_game.camera_framing_error(level.required_points).is_empty(), "planned headroom retains actual containment at shared bounded shake extreme")
	_game.camera.global_transform = framed
	var defensive: Dictionary = _game.get_camera_framing_state()
	defensive.accepted = false
	_expect(_game.get_camera_framing_state().accepted, "framing diagnostic getter is a defensive copy")
	await _capture("%s-recovery-framed" % ("right" if sign > 0 else "left"))


func _forecast_points(level: FixtureLevel, start: Vector3, finish: Vector3) -> Array:
	var points: Array = _game.camera_billboard_points(level.source)
	var source_quad: Array = points.duplicate()
	for point: Vector3 in source_quad:
		points.append(point + start - finish)
	var crest: Array = _node_mesh_points(level.crest)
	points.append_array(crest)
	for point: Vector3 in crest:
		points.append(point + start - finish)
	# Actual shared cue mesh AABB plus exact logical cardinal endcaps. No
	# endpoint-only lane shortcut or centered substitute for source artwork.
	var outline: ArrayMesh = CueMesh.geometry_mesh(level.forecast, false)
	points.append_array(_box_points(outline.get_aabb(), Transform3D(Basis.IDENTITY, start + Vector3.UP * Cue.FLOOR_OFFSET)))
	for centre: Vector3 in [start, finish]:
		for offset: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
			points.append(centre + offset * 0.42 + Vector3.UP * Cue.FLOOR_OFFSET)
	for phase: String in ["warning", "lock", "active", "recovery"]:
		points.append_array(_box_points(CueMesh.source_mesh(phase).get_aabb(), Transform3D(Basis.IDENTITY, finish + Vector3.UP * (Cue.FLOOR_OFFSET + 0.004))))
	points.append_array(_node_mesh_points(level.landing))
	return points


func _dynamic_hud() -> void:
	var level := _game.active_level as FixtureLevel
	var short: Rect2 = _game.hud.combat_safe_rect()
	var long_objective: String = "SHARED CAMERA FIXTURE: KEEP THE WHOLE COMMITTED SOURCE, ITS COMPLETE WARNING FOOTPRINT, SAFE LANDING AND THE PLAYER VISIBLE BELOW THIS WRAPPED OBJECTIVE AT EVERY PHASE."
	_game.hud.update_status(_game.player.hp, _game.player.max_hp, _game.player.shells, _game.player.max_shells, 0, long_objective)
	await process_frame
	var wrapped: Rect2 = _game.hud.combat_safe_rect()
	var objective := _game.hud.get("_objective_label") as Label
	_expect(wrapped.position.y > short.position.y and wrapped.position.y * root.size.y > objective.position.y + objective.size.y and objective.size.y > 45.0, "actual shaped multiline objective expands the protected HUD region")
	_game._update_camera(0.0, true)
	_expect(_game.get_camera_framing_state().accepted and _game.get_camera_framing_state().safe_rect == wrapped and _visible(level.required_points + _game.player_camera_framing_points()), "actual Game replans against current wrapped HUD bounds rather than a constant rectangle")
	await _capture("wrapped-objective-framed")
	# Real Game._process must shape the same frame's changed objective before
	# camera correction, not one frame after damage could observe clipping.
	level.objective_text = long_objective + " LIVE SAME-FRAME UPDATE."
	_game.hud.update_status(100, 100, 2, 2, 0, "SHORT")
	_game._process(0.0)
	_expect(_game.get_camera_framing_state().safe_rect == _game.hud.combat_safe_rect() and _game.camera_framing_error(level.required_points).is_empty(), "same-frame Game HUD update precedes its camera framing guard")
	_game.hud.set_level_preview(false)
	var telemetry: Rect2 = _game.hud.combat_safe_rect()
	_expect(telemetry.position.y > _game.get_camera_framing_state().safe_rect.position.y, "actual visible lab telemetry adds its measured region to the combat exclusion")
	_game._update_camera(0.0, true)
	_expect(_game.get_camera_framing_state().safe_rect == telemetry and _game.get_camera_framing_state().accepted, "framing consumes the actual telemetry visibility without fixed HUD assumptions")
	_game.hud.set_level_preview(true)


func _invalid_provider() -> void:
	var level := _game.active_level as FixtureLevel
	var width: float = _game.camera.size
	var basis: Basis = _game.camera.global_basis
	var actor_before: Dictionary = _game.player.snapshot_state()
	level.required_points = [Vector3(-4.5, 0, 0), Vector3(4.5, 0, 0)]
	_game._update_camera(0.0, true)
	_expect(not _game.get_camera_framing_state().accepted and not _game.last_camera_framing_error.is_empty() and _game.camera.size == width and _game.camera.global_basis == basis and _same(actor_before, _game.player.snapshot_state()), "infeasible explicit union diagnoses failure without zoom, rotation or actor mutation")
	for invalid: Array in [[Vector3(NAN, 0, 0)], [Vector3(1025, 0, 0)], ["non-native world corner"]]:
		level.required_points = invalid
		_game._update_camera(0.0, true)
		_expect(_game.get_camera_framing_state().enabled and not _game.get_camera_framing_state().accepted and not level.last_camera_framing_error.is_empty(), "invalid owner hook diagnoses failure instead of treating it as an empty default")
	level.required_points.resize(225)
	level.required_points.fill(Vector3.ZERO)
	_game._update_camera(0.0, true)
	_expect(not _game.get_camera_framing_state().accepted and not level.last_camera_framing_error.is_empty(), "owner world-corner count is bounded before full player geometry is appended")
	level.required_points = []
	_game._update_camera(0.0, true)
	_expect(not _game.get_camera_framing_state().enabled and _game.last_camera_framing_error.is_empty(), "explicitly cleared forecast returns to normal follow and clears stale diagnostics")


func _pause_reset() -> void:
	var actor_before: Dictionary = _game.player.snapshot_state()
	var camera_before: Transform3D = _game.camera.global_transform
	_game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(paused and _game.hud.get("_shade").visible, "actual Game focus-out path pauses simulation and presents its resume overlay")
	await create_timer(0.08, true).timeout
	_expect(_same(actor_before, _game.player.snapshot_state()) and _game.camera.global_transform == camera_before, "paused wall time cannot move the actor clocks or camera framing")
	_game.resume_lab()
	_expect(not paused and _game.get("_pointers").is_empty(), "actual resume clears the gesture chain before simulation continues")
	paused = true
	_game.reset_lab()
	await _frames(2) # process_frame is emitted before Node._process updates HUD.
	paused = true
	await process_frame
	_expect(_game.active_level is FixtureLevel and not _game.get_camera_framing_state().enabled and _game.player_camera_framing_points().size() == 22 and _game.get_aim_anchor_normalized() == Vector2(0.5, 0.5), "fresh preview reset reconstructs empty framing and real hero bounds without stale exchange/input state")
	_expect((_game.hud.get("_objective_label") as Label).text == _game.active_level.objective_text.to_upper() and not (_game.active_level as FixtureLevel).source.visible, "settled preview reset shows its own current objective without a stale unused forecast source")
	await _capture("fresh-preview-reset")


func _capture(label: String) -> void:
	if not _graphical:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = _output + "/" + label + ".png"
	_expect(image != null and image.get_size() == Vector2i(540, 1170) and image.save_png(path) == OK, "actual graphical portrait capture saved: " + label)
	if image != null:
		_captures.append(ProjectSettings.globalize_path(path))


func _visible(points: Array) -> bool:
	var safe: Rect2 = _game.hud.combat_safe_rect()
	for point: Vector3 in points:
		var projected: Vector2 = _game.camera.unproject_position(point) / Vector2(_game.camera.get_viewport().size)
		if not safe.has_point(projected) or not _game.camera.is_position_in_frustum(point) or _game.camera.is_position_behind(point):
			return false
	return true


func _screen_bounds(points: Array) -> Rect2:
	var result := Rect2()
	var first: bool = true
	for point: Vector3 in points:
		var projected: Vector2 = _game.camera.unproject_position(point) / Vector2(_game.camera.get_viewport().size)
		result = Rect2(projected, Vector2.ZERO) if first else result.expand(projected)
		first = false
	return result


func _node_mesh_points(node: MeshInstance3D) -> Array:
	return _box_points(node.get_aabb(), node.global_transform)


func _box_points(bounds: AABB, transform: Transform3D) -> Array:
	var points: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(transform * Vector3(x, y, z))
	return points


func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)


func _ensure_uid() -> void:
	var path: String = "res://tests/camera_framing_shell_smoke.gd.uid"
	if not FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))


func _finish() -> void:
	if _finished:
		return
	_finished = true
	var data: Dictionary = {"engine": Engine.get_version_info(), "graphical": _graphical, "checks": _checks, "failures": _failures, "captures": _captures, "fixture": "actual shared Game/player/HUD/cue with anonymous scripted level", "limits": "No authored Sun1, physical lunge, damage, campaign acceptance or native gesture proof; normal native focus guards retained", "native_window_focused_at_finish": DisplayServer.window_is_focused() if _graphical else false}
	var file: FileAccess = FileAccess.open(_output + "/evidence.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
	paused = false
	if is_instance_valid(_game):
		_game.free()
	Engine.max_fps = _old_max_fps
	print("Camera framing shell smoke: %d checks, %d failures; %s" % [_checks, _failures, ProjectSettings.globalize_path(_output)])
	quit(0 if _failures == 0 else 1)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
