extends SceneTree

const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const CueMesh: GDScript = preload("res://scripts/cues/cue_mesh.gd")
const ThreatScript: GDScript = preload("res://scripts/cues/threat_cue.gd")
const InteractionScript: GDScript = preload("res://scripts/cues/interaction_cue.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	_boundary_checks()
	await _threat_checks(arena)
	await _interaction_checks(arena)
	paused = false
	arena.queue_free()
	await process_frame
	print("Shared cue smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _boundary_checks() -> void:
	var circle: Dictionary = Geometry.circle(Vector3(3, 2, -4), 1.7)
	var points: Array[Vector3] = CueMesh.boundary(circle)
	var all_on_radius: bool = true
	for point: Vector3 in points:
		all_on_radius = all_on_radius and _near(point.length(), 1.7) and point.y == 0.0
	_expect(points.size() == CueMesh.SEGMENTS and all_on_radius, "circle outline samples the supplied radius in its anchor plane")
	_expect(_near(_extent(points, Vector3.RIGHT).x, -1.7) and _near(_extent(points, Vector3.RIGHT).y, 1.7), "circle spans its complete logical diameter")
	for direction: Vector3 in [Vector3.RIGHT, Vector3.FORWARD, Vector3(0.6, 0, 0.8)]:
		var origin := Vector3(-2, 0.4, 3)
		var length: float = 4.2
		var radius: float = 0.63
		var lane: Dictionary = Geometry.lane(origin, origin + direction * length, radius)
		points = CueMesh.boundary(lane)
		var along: Vector2 = _extent(points, direction)
		var side: Vector2 = _extent(points, Vector3(-direction.z, 0, direction.x))
		_expect(_near(along.x, -radius) and _near(along.y, length + radius), "cardinal/continuous lane includes both round endcaps beyond from/to")
		_expect(_near(side.x, -radius) and _near(side.y, radius), "lane width follows its radius around the exact committed direction")
		var on_capsule: bool = true
		for point: Vector3 in points:
			var closest: Vector3 = direction * clampf(point.dot(direction), 0.0, length)
			on_capsule = on_capsule and _near(point.distance_to(closest), radius)
		_expect(on_capsule, "both endcaps and sides lie on the authoritative swept capsule boundary")
		_expect(not _vertices(CueMesh.geometry_mesh(lane, true)).is_empty() and not _vertices(CueMesh.geometry_mesh(lane, false)).is_empty(), "each complete lane builds active fill and warning outline")
	var stationary: Dictionary = Geometry.lane(Vector3(8, 1, 3), Vector3(8, 1, 3), 0.5)
	_expect(CueMesh.boundary(stationary) == CueMesh.boundary(Geometry.circle(Vector3.ZERO, 0.5)), "zero-length lane retains its full circular footprint")
	for radius: float in [0.0, 0.43, 2.0]:
		var cone: Dictionary = Geometry.cone(Vector3(7, 0.2, 4), Vector3.RIGHT, 2.0, 0.7, radius)
		points = CueMesh.boundary(cone)
		var backward: Vector2 = _extent(points, Vector3.RIGHT)
		_expect(_near(backward.x, -radius) and _near(backward.y, 2.0), "cone preserves supplied origin disk radius and full forward reach")
		var reach_count: int = 0
		var rear_count: int = 0
		for point: Vector3 in points:
			if _near(point.length(), 2.0) and point.normalized().dot(Vector3.RIGHT) >= 0.7 - 0.00001:
				reach_count += 1
			if _near(point.length(), radius) and point.dot(Vector3.RIGHT) < 0.0:
				rear_count += 1
		_expect(reach_count >= CueMesh.SEGMENTS and (radius == 0.0 or rear_count > 0), "cone arc and rear disk use the geometry's exact angular/radius parameters")
		var filled: PackedVector3Array = _vertices(CueMesh.geometry_mesh(cone, true))
		_expect(not filled.is_empty() and _near(_extent_packed(filled, Vector3.RIGHT).y, 2.0), "active cone does not lose its longest radial reach")
	var wide_cone: Dictionary = Geometry.cone(Vector3.ZERO, Vector3.BACK, 1.0, 0.0, 0.2)
	_expect(not _vertices(CueMesh.geometry_mesh(wide_cone, false)).is_empty(), "supported half-plane cone renders without degenerate-angle failure")


func _threat_checks(arena: Node3D) -> void:
	var cue: CinderThreatCue = ThreatScript.new()
	_expect(not cue.present(Geometry.circle(Vector3.ZERO, 1.0), "warning") and cue.state().phase == "clear", "unready threat presentation rejects without state mutation")
	var parent := Node3D.new()
	parent.position = Vector3(50, 3, -20)
	parent.rotation.y = 0.73
	parent.scale = Vector3(2, 3, 4)
	arena.add_child(parent)
	parent.add_child(cue)
	var changes: Array[Dictionary] = []
	var artwork := Node3D.new()
	artwork.name = "ActOwnedArmArtwork"
	parent.add_child(artwork)
	cue.state_changed.connect(func(value: Dictionary) -> void:
		changes.append(value.duplicate(true))
		artwork.visible = value.phase != "clear"
		value.geometry.clear()
		value.phase = "tampered"
	)
	var shape: Dictionary = Geometry.cone(Vector3(2, 0.15, -3), Vector3(0.6, 0, 0.8), 3.4, 0.55, 0.37)
	shape["untrusted_metadata"] = {"object": artwork}
	_expect(cue.present(shape, "warning"), "nonenemy act arm accepts the same required warning grammar")
	_expect(cue.is_in_group("required_cues") and not cue.is_in_group("cosmetic_effects") and cue.state().required, "threat signal has required classification without a cosmetic suppression switch")
	_expect(cue.global_position.is_equal_approx(shape.origin) and cue.global_basis.is_equal_approx(Basis.IDENTITY), "world-space geometry stays undistorted under translated/rotated/scaled act parents")
	_expect(cue.state().geometry == CueMesh.canonical_geometry(shape) and not cue.state().geometry.has("untrusted_metadata"), "state retains only authoritative parameters and ignores arbitrary caller metadata")
	var returned: Dictionary = cue.state()
	returned.geometry.reach = 0.001
	returned.phase = "active"
	shape.reach = 500.0
	_expect(cue.state().phase == "warning" and _near(cue.state().geometry.reach, 3.4), "getter, signal and caller dictionaries cannot mutate committed cue state")
	var outline: MeshInstance3D = cue.get_node("RequiredFootprintOutline")
	var fill: MeshInstance3D = cue.get_node("RequiredFootprintFill")
	var source: MeshInstance3D = cue.get_node("RequiredSourceMarker")
	var warning_outline: PackedVector3Array = _vertices(outline.mesh)
	var warning_source: PackedVector3Array = _vertices(source.mesh)
	_expect(outline.visible and not fill.visible and source.visible, "warning shows its complete outline and source without active fill")
	var outline_material: StandardMaterial3D = outline.material_override
	_expect(not outline_material.no_depth_test and outline_material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and outline.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "required floor cues retain depth occlusion, nearest filtering and no decorative shadows")
	var committed: Dictionary = cue.state().geometry
	_expect(cue.present(committed, "lock") and changes.size() == 2, "external lock immediately commits a distinct state once")
	_expect(_vertices(outline.mesh) == warning_outline and _vertices(source.mesh) != warning_source and not fill.visible, "lock preserves the same footprint while changing source shape independently of color")
	var locked_source: PackedVector3Array = _vertices(source.mesh)
	_expect(cue.present(committed, "lock") and changes.size() == 2, "repeated unchanged lock does not republish or advance a phase")
	var changed_geometry: Dictionary = committed.duplicate(true)
	changed_geometry.origin += Vector3.RIGHT
	_expect(not cue.present(changed_geometry, "active") and cue.state().phase == "lock" and _vertices(outline.mesh) == warning_outline, "committed lock cannot silently retarget or replace its authoritative footprint")
	_expect(cue.present(committed, "active") and outline.visible and fill.visible and source.visible, "external active phase releases visible complete danger fill immediately")
	_expect(_vertices(source.mesh) != locked_source and _vertices(outline.mesh) == warning_outline, "active shape differs from lock without changing committed danger outline")
	var frozen: Dictionary = cue.state()
	paused = true
	await create_timer(0.08).timeout
	_expect(cue.state() == frozen and changes.size() == 3 and fill.visible, "pause leaves required cue state exactly aligned with its external owner")
	paused = false
	await create_timer(0.08).timeout
	_expect(cue.state() == frozen and changes.size() == 3, "cue has no autonomous timer to expire active danger")
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 4, 4)
	collision.shape = box
	wall.add_child(collision)
	arena.add_child(wall)
	wall.global_position = cue.global_position + Vector3(0.8, 0.7, 0)
	await physics_frame
	_expect(cue.state() == frozen and _vertices(outline.mesh) == warning_outline, "actual scenery does not remove authoritative footprint geometry via decorative LOS clipping")
	_expect(cue.present(committed, "recovery") and not outline.visible and not fill.visible and source.visible, "recovery removes danger footprint/fill while retaining a distinct source opening/settling marker")
	_expect(changes.size() == 4 and _vertices(source.mesh) != locked_source and artwork.visible, "authored art receives recovery through the public state callback")
	var lane: Dictionary = Geometry.lane(Vector3(-2, 0, 1), Vector3(2, 0, 1), 0.45)
	lane["source_position"] = lane.to
	_expect(cue.present(lane, "recovery") and cue.global_position == lane.from, "moving-source recovery keeps the committed lane's original world anchor")
	_expect(cue.state().geometry == Geometry.lane(lane.from, lane.to, lane.radius) and cue.state().source_position == lane.to and (source.global_position - Vector3.UP * (ThreatScript.FLOOR_OFFSET + 0.004)).is_equal_approx(lane.to), "explicit actual landing moves only the source marker and never retargets lane geometry")
	var unchanged: Dictionary = cue.state()
	var invalid_shapes: Array[Dictionary] = [Geometry.circle(Vector3.ZERO, 0.0), Geometry.circle(Vector3(NAN, 0, 0), 1.0), Geometry.cone(Vector3.ZERO, Vector3(1, 1, 0), 2.0, 0.5, 0.1), Geometry.cone(Vector3.ZERO, Vector3.RIGHT, 2.0, 1.0, 0.1), Geometry.lane(Vector3.ZERO, Vector3(1, 1, 1), 0.4), {"kind": "rectangle"}]
	for invalid: Dictionary in invalid_shapes:
		_expect(not cue.present(invalid, "warning") and cue.state() == unchanged and not cue.last_error.is_empty(), "invalid geometry rejects atomically before visible state/mesh changes")
	lane.source_position = Vector3(INF, 0, 0)
	_expect(not cue.present(lane, "recovery") and cue.state() == unchanged, "nonfinite source override rejects without losing valid committed geometry")
	_expect(not cue.present(committed, "windup") and cue.state() == unchanged, "unknown phase cannot silently substitute a warning or active state")
	var reentrant_results: Array[bool] = []
	cue.state_changed.connect(func(_value: Dictionary) -> void: reentrant_results.append(cue.cancel()))
	_expect(cue.present(committed, "warning") and reentrant_results == [false] and cue.state().phase == "warning", "nested callbacks cannot replace committed presentation mid-notification")
	var before_clear: int = changes.size()
	_expect(cue.cancel() and cue.state().phase == "clear" and not outline.visible and not fill.visible and not source.visible and not artwork.visible, "cancel visibly removes all required warning parts and informs act artwork")
	_expect(cue.clear() and changes.size() == before_clear + 1 and outline.mesh == null and fill.mesh == null and source.mesh == null, "idempotent clear releases geometry without a duplicate state notification")
	var other: CinderThreatCue = ThreatScript.new()
	arena.add_child(other)
	_expect(other.present(Geometry.circle(Vector3.ZERO, 1.0), "active") and not fill.visible, "separate cue instances keep independent state/materials")
	_expect(not cue.has_method("take_damage") and not cue.has_signal("attack_hit") and cue.process_mode == Node.PROCESS_MODE_INHERIT, "presentation adds no attack/damage API or independent pause policy")
	other.queue_free()
	wall.queue_free()
	parent.queue_free()
	await process_frame


func _interaction_checks(arena: Node3D) -> void:
	var cue: CinderInteractionCue = InteractionScript.new()
	_expect(not cue.present("available") and cue.state().state == "clear", "unready interaction presentation rejects atomically")
	arena.add_child(cue)
	var changes: Array[Dictionary] = []
	var authored := Node3D.new()
	authored.name = "ActOwnedClothRoundel"
	arena.add_child(authored)
	cue.state_changed.connect(func(value: Dictionary) -> void:
		changes.append(value.duplicate(true))
		authored.visible = value.visible and value.state != "spent"
		value.state = "tampered"
	)
	var marker: MeshInstance3D = cue.get_node("RequiredInteractionMarker")
	_expect(cue.present("available") and cue.is_in_group("required_cues") and cue.state().required and marker.visible, "available attack marker is a required local cue through the supported default trigger")
	var available_attack: PackedVector3Array = _vertices(marker.mesh)
	var returned: Dictionary = cue.state()
	returned.state = "spent"
	_expect(cue.state().state == "available" and cue.state().trigger == "attack" and authored.visible, "public interaction state/callback copies cannot change internal state")
	_expect(cue.present("available", "attack") and changes.size() == 1, "unchanged interaction state does not duplicate art notifications")
	_expect(cue.present("active", "attack") and _vertices(marker.mesh) != available_attack, "attack activation changes local marker geometry as well as value")
	var active_attack: PackedVector3Array = _vertices(marker.mesh)
	_expect(cue.present("spent", "attack") and marker.visible and not authored.visible and _vertices(marker.mesh).size() < available_attack.size(), "spent attack leaves a restrained broken marker instead of an available target cue")
	var spent_attack: PackedVector3Array = _vertices(marker.mesh)
	for visual_state: String in ["available", "active", "spent"]:
		_expect(cue.present(visual_state, "contact"), "contact supports every shared interaction state")
		var contact: PackedVector3Array = _vertices(marker.mesh)
		var attack: PackedVector3Array = available_attack if visual_state == "available" else (active_attack if visual_state == "active" else spent_attack)
		_expect(contact != attack and _extent_packed(contact, Vector3.RIGHT).y > _extent_packed(attack, Vector3.RIGHT).y, "contact remains a broad open approach shape distinct from the attackable-part diamond")
	var frozen: Dictionary = cue.state()
	paused = true
	await create_timer(0.06).timeout
	_expect(cue.state() == frozen and marker.visible, "paused interaction remains in the authoritative externally supplied state")
	paused = false
	await create_timer(0.06).timeout
	_expect(cue.state() == frozen, "interaction has no local pulse/expiry clock that changes logical availability")
	for invalid: Array in [["hidden", "attack"], ["warning", "attack"], ["available", "tap_prompt"], ["active", "enemy"]]:
		_expect(not cue.present(invalid[0], invalid[1]) and cue.state() == frozen and not cue.last_error.is_empty(), "invalid state/trigger rejects before replacing the current marker")
	var nested: Array[bool] = []
	cue.state_changed.connect(func(_value: Dictionary) -> void: nested.append(cue.present("spent", "attack")))
	_expect(cue.present("available", "contact") and nested == [false] and cue.state().trigger == "contact", "interaction callback cannot reenter an unfinished state publication")
	var marker_material: StandardMaterial3D = marker.material_override
	_expect(not marker_material.no_depth_test and marker_material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and not cue.has_method("take_damage") and not cue.has_signal("collected"), "required interaction art is pixel-filtered, occluded normally and adds no damage/reward mechanism")
	var change_count: int = changes.size()
	_expect(cue.cancel() and cue.state().state == "clear" and not marker.visible and not authored.visible, "interaction cancellation removes the cue and updates authored art")
	_expect(cue.clear() and changes.size() == change_count + 1 and marker.mesh == null, "interaction clear is idempotent and releases its mesh")
	var other: CinderInteractionCue = InteractionScript.new()
	arena.add_child(other)
	_expect(other.present("active", "attack") and not marker.visible and cue.state().state == "clear", "interaction instances do not share mutable visual state")
	other.queue_free()
	cue.queue_free()
	authored.queue_free()
	await process_frame


func _vertices(mesh: Mesh) -> PackedVector3Array:
	if mesh == null or mesh.get_surface_count() == 0:
		return PackedVector3Array()
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func _extent(points: Array[Vector3], direction: Vector3) -> Vector2:
	var result := Vector2(INF, -INF)
	for point: Vector3 in points:
		result.x = minf(result.x, point.dot(direction))
		result.y = maxf(result.y, point.dot(direction))
	return result


func _extent_packed(points: PackedVector3Array, direction: Vector3) -> Vector2:
	var result := Vector2(INF, -INF)
	for point: Vector3 in points:
		result.x = minf(result.x, point.dot(direction))
		result.y = maxf(result.y, point.dot(direction))
	return result


func _near(left: float, right: float) -> bool:
	return absf(left - right) < 0.00001


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
