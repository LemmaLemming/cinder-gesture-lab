extends SceneTree
## TEST ONLY bank-material and segment-depth probes in the actual MainScene
## --a2-art-preview. Paused hero poses and one synthetic transformed BoxMesh
## are geometry fixtures, not executed swipes, Scout combat or route acceptance.
## Private owned bank callbacks are exercised explicitly for this narrow test.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"
const ThreatCue: Script = preload("res://scripts/cues/threat_cue.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _expect(OS.get_cmdline_user_args().has("--a2-art-preview"), "bank fixture explicitly requires --a2-art-preview; no live encounter is substituted"):
		_finish()
		return
	var game: Node = _new_preview()
	var other_game: Node = _new_preview()
	await process_frame
	paused = true
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var other_level: CinderLevel = other_game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var camera: Camera3D = game.get("camera") as Camera3D
	if not _expect(is_instance_valid(level) and is_instance_valid(other_level) and is_instance_valid(hero) and is_instance_valid(camera), "actual preview creates ready level, shared hero and fixed camera"):
		game.free()
		other_game.free()
		_finish()
		return
	_expect(level.level_id == "A2-L1" and level.hero == hero and level.find_child("HorsellThreatScheduler", true, false) == null, "actual art preview has canonical identity and no live combat scheduler")
	var banks: Array[MeshInstance3D] = _banks(level)
	var other_banks: Array[MeshInstance3D] = _banks(other_level)
	_expect(banks.size() == 10 and other_banks.size() == 10, "each actual preview owns the ten authored bank surfaces")
	var material_ids: Dictionary = {}
	for bank: MeshInstance3D in banks + other_banks:
		var material: StandardMaterial3D = bank.material_override as StandardMaterial3D
		_expect(is_instance_valid(material) and not material_ids.has(material.get_instance_id()), "each bank in both scene instances owns a distinct readability material")
		if is_instance_valid(material):
			material_ids[material.get_instance_id()] = true
	var arrival: MeshInstance3D = level.get_node("DryGround/ArrivalEndBank/BankSurface") as MeshInstance3D
	_test_segment_depth(level, arrival)
	var cue: CinderThreatCue = ThreatCue.new() as CinderThreatCue
	cue.name = "TestOnlyProtectedRequiredCue"
	level.add_child(cue)
	var lane: Dictionary = Geometry.lane(Vector3(0, 0, 3.18), Vector3(0.7, 0, 3.18), 0.31)
	_expect(cue.present(lane, "lock") and cue.is_in_group("required_cues"), "TEST ONLY locked lane uses the real shared required-cue API")
	var cue_before: Dictionary = _cue_state(cue)
	# A paused legal-floor pose isolates rendering. No live actor is teleported
	# through an encounter, and no executed world-action record is manufactured.
	hero.global_position = Vector3(0, 0.02, 3.25)
	var physical_before: Dictionary = _physical_state(level, hero)
	level.call("_apply_readability")
	var arrival_material: StandardMaterial3D = arrival.material_override as StandardMaterial3D
	_expect(is_equal_approx(arrival_material.albedo_color.a, 0.12) and arrival_material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "actual foreground arrival bank fades to authored alpha through material ALPHA")
	_expect(_physical_state(level, hero) == physical_before, "readability preserves actual bank/floor/body/collider transforms, shapes and collision masks")
	_expect(_cue_state(cue) == cue_before, "bank fading preserves shared locked geometry, required meshes, colors, alpha and visibility")
	_expect(_all_opaque(other_banks), "fading one scene leaves every bank material in the other scene opaque")
	for iteration: int in range(3):
		level.call("_apply_readability")
	_expect(arrival.material_override == arrival_material and _physical_state(level, hero) == physical_before, "repeated derived updates retain material identity and physical state")
	hero.global_position = Vector3(-1, 0.02, 0)
	physical_before = _physical_state(level, hero)
	level.call("_apply_readability")
	_expect(_all_opaque(banks), "moving the TEST ONLY protected pose clear restores every bank's opaque material mode and alpha")
	_expect(_physical_state(level, hero) == physical_before and _cue_state(cue) == cue_before, "opacity restoration leaves actual collision and the shared required cue unchanged")
	_expect(hero.get_world_action_records().is_empty() and not level.is_completed(), "geometry probes emit no player action or campaign completion")
	game.free()
	other_game.free()
	_expect(not is_instance_valid(level) and not is_instance_valid(hero) and not is_instance_valid(arrival) and not is_instance_valid(cue), "preview cleanup frees the actual bank, hero and owned required cue")
	_finish()


func _new_preview() -> Node:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	return game


func _test_segment_depth(level: CinderLevel, bank: MeshInstance3D) -> void:
	var origin: Vector3 = bank.to_global(Vector3(0, 0, 2))
	_expect(level.call("_bank_blocks_point", bank, origin, bank.to_global(Vector3(0, 0, -2))), "actual bank blocks a protected point beyond its physical box")
	_expect(not level.call("_bank_blocks_point", bank, origin, bank.to_global(Vector3(0, 0, 1))), "bank beyond the protected point is rejected despite lying on the same ray")
	_expect(not level.call("_bank_blocks_point", bank, bank.to_global(Vector3(5, 0, 2)), bank.to_global(Vector3(5, 0, -2))), "parallel segment outside the actual bank bounds does not obscure")
	var probe := MeshInstance3D.new()
	probe.name = "TestOnlyTransformedBankBoxProbe"
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 1.0, 0.6)
	probe.mesh = box
	probe.position = Vector3(8, 2, -4)
	probe.rotation = Vector3(0.1, 0.47, -0.08)
	probe.scale = Vector3(1.2, 0.8, 1.4)
	level.add_child(probe)
	origin = probe.to_global(Vector3(0, 0, 2))
	_expect(level.call("_bank_blocks_point", probe, origin, probe.to_global(Vector3(0, 0, -2))), "TEST ONLY rotated and scaled BoxMesh uses its actual global transform")
	_expect(not level.call("_bank_blocks_point", probe, origin, probe.to_global(Vector3(0, 0, 1))), "transformed probe also rejects a bank behind the protected endpoint")
	probe.free()


func _banks(level: CinderLevel) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for candidate: Node in level.get_node("DryGround").find_children("BankSurface", "MeshInstance3D", true, false):
		result.append(candidate as MeshInstance3D)
	return result


func _all_opaque(banks: Array[MeshInstance3D]) -> bool:
	for bank: MeshInstance3D in banks:
		var material: StandardMaterial3D = bank.material_override as StandardMaterial3D
		if not is_instance_valid(material) or not is_equal_approx(material.albedo_color.a, 1.0) or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			return false
	return not banks.is_empty()


func _physical_state(level: CinderLevel, hero: CinderPlayer) -> Dictionary:
	var bodies: Array[Dictionary] = []
	for candidate: Node in level.get_node("DryGround").get_children():
		var body: StaticBody3D = candidate as StaticBody3D
		if body == null:
			continue
		var shapes: Array[Dictionary] = []
		for child: Node in body.get_children():
			if child is CollisionShape3D:
				shapes.append({"transform": child.global_transform, "disabled": child.disabled, "shape": _shape_state(child.shape)})
		var surface: MeshInstance3D = body.get_node_or_null("BankSurface") as MeshInstance3D
		bodies.append({"id": String(body.name), "transform": body.global_transform, "layer": body.collision_layer, "mask": body.collision_mask, "shapes": shapes, "surface_transform": surface.global_transform if surface != null else Transform3D.IDENTITY})
	var collision: CollisionShape3D = hero.get_node("BodyCollision") as CollisionShape3D
	return {"bodies": bodies, "floor_regions": level.call("floor_regions"), "hero_transform": hero.global_transform, "hero_velocity": hero.velocity, "hero_layer": hero.collision_layer, "hero_mask": hero.collision_mask, "hero_collision": collision.global_transform, "hero_shape": _shape_state(collision.shape)}


func _shape_state(shape: Shape3D) -> Dictionary:
	var result: Dictionary = {"instance": shape.get_instance_id()}
	if shape is BoxShape3D:
		result["size"] = shape.size
	elif shape is CapsuleShape3D or shape is CylinderShape3D:
		result["radius"] = shape.get("radius")
		result["height"] = shape.get("height")
	return result


func _cue_state(cue: CinderThreatCue) -> Dictionary:
	var meshes: Array[Dictionary] = []
	for candidate: Node in cue.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = candidate as MeshInstance3D
		var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		meshes.append({"transform": mesh.global_transform, "visible": mesh.visible, "mesh": mesh.mesh.get_instance_id() if mesh.mesh != null else 0, "material": material.get_instance_id(), "color": material.albedo_color, "transparency": material.transparency})
	return {"state": cue.state(), "transform": cue.global_transform, "meshes": meshes}


func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
	return condition


func _finish() -> void:
	paused = false
	print("Horsell bank readability smoke: %d checks, %d failures; TEST ONLY art-preview geometry, no live route acceptance" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
