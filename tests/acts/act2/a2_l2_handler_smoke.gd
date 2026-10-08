extends SceneTree
## TEST ONLY bound shared Player/Effects and isolated Handler/foot cosmetics.
## Real lane recovery gates real primaries; paused exact actor/component restore
## and synthetic portrait bounds do not certify the authored L2 route or balance.

const PlayerScript: Script = preload("res://scripts/player.gd")
const EffectsScript: Script = preload("res://scripts/effects.gd")
const ActorScript: Script = preload("res://scripts/acts/act2/salvage_handler_actor.gd")
const VisualScript: Script = preload("res://scripts/acts/act2/salvage_handler_visual.gd")
const FootScript: Script = preload("res://scripts/acts/act2/giant_foot_visual.gd")
const SchedulerScript: Script = preload("res://scripts/combat/threat_scheduler.gd")
const MechanismScript: Script = preload("res://scripts/combat/lane_mechanism.gd")
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const ACTOR_ID: String = "A2-L2:fixture-handler"
const ENCOUNTER_ID: String = "A2-L2:handler-target-fixture"
const SUPPORTS: Array[String] = ["FrontLeftSupport", "FrontRightSupport", "MiddleLeftSupport", "MiddleRightSupport", "RearSupport"]
var _checks: int = 0
var _failures: int = 0
var _fixtures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_real_primary_gate_and_reload()
	if not OS.get_cmdline_user_args().has("--pair-only"):
		await _test_exact_actor_pose_and_cutaway()
		await _test_foot_dynamic_geometry()
	print("A2-L2 isolated Handler/foot smoke: %d checks, %d failures; no authored route/native portrait claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _create() -> Dictionary:
	_fixtures += 1
	var viewport := SubViewport.new()
	viewport.name = "HandlerFixture%d" % _fixtures
	viewport.size = Vector2i(540, 1170)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "DryFixtureFloor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.position.y = -0.5
	var support := CollisionShape3D.new()
	support.name = "DrySupport"
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	support.shape = box
	floor.add_child(support)
	world.add_child(floor)
	var hero: CinderPlayer = PlayerScript.new()
	hero.name = "SharedHero"
	hero.position = Vector3(0, 0, -1)
	world.add_child(hero)
	_expect(hero.equip_item("WEAPON-03"), "bound fixture uses canonical shortest-reach Heavy primary")
	hero.shells = 0
	var effects: PixelEffects = EffectsScript.new()
	world.add_child(effects)
	hero.fx = effects
	var scheduler: CinderThreatScheduler = SchedulerScript.new()
	world.add_child(scheduler)
	_expect(scheduler.begin_encounter("standard", ENCOUNTER_ID), "isolated parent begins actual fixed shared encounter")
	var actor: Node3D = ActorScript.new() as Node3D
	actor.name = "HandlerRoot"
	world.add_child(actor)
	_expect(bool(actor.call("configure", hero, effects, ACTOR_ID)), "Handler inherits bound Player/Effects and immutable authored target")
	var mechanism: CinderLaneMechanism = MechanismScript.new()
	mechanism.name = "ActualHandlerLane"
	_expect(mechanism.configure("handler-arm", Geometry.lane(Vector3.ZERO, Vector3(0, 0, 3.8), 0.31), Vector3.ZERO), "actual fixed Handler lane uses the published stationary consumer")
	world.add_child(mechanism)
	_expect(mechanism.bind(scheduler, {"hero": hero}), "actual mechanism binds the same shared hero/scheduler world")
	var region: Dictionary = {"collision": support, "safe_rect": Rect2(-9.998, -9.998, 19.996, 19.996)}
	var context: Dictionary = {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.LEFT, Vector3.RIGHT], "return_directions": [Vector3.LEFT, Vector3.RIGHT], "floor_regions": [region]}
	var gate: Callable = func() -> bool:
		if paused or not is_instance_valid(mechanism) or not is_instance_valid(scheduler) or mechanism.is_queued_for_deletion() or not mechanism.is_visible_in_tree() or not mechanism.get_cue().is_visible_in_tree():
			return false
		var state: Dictionary = mechanism.state()
		var retained: Dictionary = scheduler.reservation_state(state.reservation_id)
		var cue: Dictionary = mechanism.get_cue().state()
		return state.status == "running" and state.phase == "recovery" and not retained.is_empty() and retained.state == "recovery" and cue.phase == "recovery" and cue.geometry == state.geometry and scheduler.get_clock() > float(retained.active_until_s) and scheduler.get_clock() <= float(retained.recovery_until_s)
	_expect(bool(actor.call("bind_damage_window", gate)), "incoming primary gate reads actual retained scheduler recovery and required cue")
	mechanism.state_changed.connect(func(state: Dictionary) -> void:
		if float(actor.get("hp")) > 0.0:
			actor.call("present_phase", "idle" if state.phase == "clear" else state.phase, 0.0, Vector3.BACK)
	)
	return {"viewport": viewport, "world": world, "hero": hero, "effects": effects, "actor": actor, "mechanism": mechanism, "scheduler": scheduler, "context": context, "gate": gate, "bindings": {"world_root": world, "owners": {"handler-arm": mechanism}, "floors": {"dry-floor": region}}}


func _test_real_primary_gate_and_reload() -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var actor: Node3D = arena.actor
	var hero: CinderPlayer = arena.hero
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	var anchor: Vector3 = actor.global_position
	_expect(get_nodes_in_group("enemies") == [actor] and not actor.is_in_group("practice_targets") and not actor.is_physics_processing() and not _contains_collision(actor), "one anchored Handler target has no duplicate group or independent physics clock")
	actor.call("present_phase", "recovery", 0.3, Vector3.BACK)
	_expect(hero.slash(Vector3.BACK) == 0 and float(actor.get("hp")) == 30.0, "fake recovery art cannot bypass the bound actual reservation gate")
	await create_timer(float(hero.stats.primary_cooldown) + 0.03).timeout
	var defeats: Array[String] = []
	var cancelled_before_progress: Array[bool] = []
	var reentrant_rejects: Array[bool] = []
	actor.connect("defeated", func(id: String) -> void:
		defeats.append(id)
		mechanism.clear("fixture_target_defeated")
		cancelled_before_progress.append(scheduler.reservations().is_empty())
		reentrant_rejects.append(not bool(actor.call("take_damage", 3.0, Vector3.ZERO).accepted))
	)
	var answer: Dictionary = mechanism.start("hero", arena.context)
	_expect(answer.get("accepted", false) and not answer.get("proof", {}).get("uses_blast", true), "actual stationary lane admits ordinary-primary proof without blast")
	if not answer.get("accepted", false):
		push_error(str(answer))
		await _dispose(arena)
		return
	_expect(hero.slash(Vector3.BACK) == 0 and float(actor.get("hp")) == 30.0, "real warning keeps incoming ordinary-primary gate closed")
	_expect(await _until_phase(mechanism, "lock"), "actual shared deadlines reach lock")
	await _test_actual_pair_roundtrip(arena)
	_expect(hero.slash(Vector3.BACK) == 0 and float(actor.get("hp")) == 30.0, "restored actual lock remains closed to a real ordinary primary")
	_expect(await _until_phase(mechanism, "active"), "actual shared deadlines enter active")
	_expect(hero.slash(Vector3.BACK) == 0 and float(actor.get("hp")) == 30.0, "ground-reaching active arm is not an incoming attack opening")
	_expect(await _until_phase(mechanism, "recovery"), "actual active interval naturally exposes recovery")
	await create_timer(float(hero.stats.primary_cooldown) + 0.03).timeout
	hero.shells = 0
	_expect(hero.slash(Vector3.BACK) == 1 and float(actor.get("hp")) == 6.0 and actor.global_position == anchor, "real no-ammo shortest-reach Heavy primary accepts24 at fixed low tool mount")
	await create_timer(float(hero.stats.primary_cooldown) + 0.03).timeout
	hero.shells = 0
	paused = true
	var before: Dictionary = hero.snapshot_state()
	paused = false
	_expect(hero.slash(Vector3.BACK) == 1 and float(actor.get("hp")) == 0.0, "second real primary accepts only remaining6HP")
	paused = true
	var after: Dictionary = hero.snapshot_state()
	paused = false
	var credited: float = float(before.clocks.reload_s) + float(hero.stats.primary_hit_reload_credit)
	var earns_shell: bool = credited >= float(hero.stats.shell_reload)
	_expect(defeats == [ACTOR_ID] and cancelled_before_progress == [true] and reentrant_rejects == [true] and actor.get("phase") == "defeated", "lethal result commits one guarded defeat and cancels actual lane before progression")
	_expect(after.resources.shells == (1 if earns_shell else 0) and after.clocks.reload_s == (0.0 if earns_shell else credited), "retained living-before-hit target earns exact once-per-killing-action shared reload credit")
	var rejected: Dictionary = actor.call("take_damage", 100.0, Vector3.ZERO)
	_expect(not rejected.accepted and rejected.hp_damage == 0.0 and not rejected.target_alive_before_hit and defeats.size() == 1, "spent Handler rejects duplicate accepted-hit/death/reload classification")
	_expect(bool(actor.call("release_damage_window", arena.gate)) and not bool(actor.call("take_damage", 1.0, Vector3.ZERO).accepted), "released bound gate remains closed")
	await _dispose(arena)
	_expect(not is_instance_valid(actor) and get_nodes_in_group("enemies").is_empty(), "owned cleanup frees Handler rig and target group")


func _test_actual_pair_roundtrip(arena: Dictionary) -> void:
	paused = true
	await process_frame
	var actor: Node3D = arena.actor
	var hero: CinderPlayer = arena.hero
	var scheduler: CinderThreatScheduler = arena.scheduler
	var mechanism: CinderLaneMechanism = arena.mechanism
	var pair: Dictionary = {"hero": hero.snapshot_state(), "actor": actor.call("snapshot_state"), "scheduler": scheduler.snapshot_state(arena.bindings), "mechanism": mechanism.snapshot_state(arena.bindings)}
	var encoded: String = ExactJson.stringify(pair)
	var parsed: Dictionary = ExactJson.parse(encoded)
	_expect(not encoded.is_empty() and parsed.get("accepted", false) and ExactJson.stringify(parsed.get("value", {})) == encoded, "paused actor/player/scheduler/mechanism transport preserves exact typed values")
	if not parsed.get("accepted", false):
		paused = false
		return
	var saved: Dictionary = parsed.value
	var old_clock: float = scheduler.get_clock()
	var transforms: Dictionary = _mesh_transforms(actor.get_node("HandlerRig"))
	var phases: Array[String] = []
	mechanism.state_changed.connect(func(state: Dictionary) -> void: phases.append(state.phase))
	var errors: Array[String] = [hero.snapshot_error(saved.hero), actor.call("snapshot_error", saved.actor), scheduler.snapshot_error(saved.scheduler, arena.bindings), mechanism.snapshot_error(saved.mechanism, arena.bindings, saved.scheduler)]
	var valid: bool = true
	for error: String in errors: valid = valid and error.is_empty()
	if not valid: print("Handler pair component diagnostics hero/actor/scheduler/mechanism: ", errors, " capture_errors=", [hero.last_snapshot_error, actor.get("last_snapshot_error"), scheduler.last_snapshot_error, mechanism.last_snapshot_error], " sizes=", [saved.hero.size(), saved.actor.size(), saved.scheduler.size(), saved.mechanism.size()])
	_expect(valid, "whole exact paused pair prevalidates before mutation")
	_expect(hero.restore_state(saved.hero) and bool(actor.call("restore_state", saved.actor)) and scheduler.restore_state(saved.scheduler, arena.bindings) and mechanism.restore_state(saved.mechanism, arena.bindings), "actual hero then actor then scheduler then mechanism restore quietly")
	var restored: Dictionary = {"hero": hero.snapshot_state(), "actor": actor.call("snapshot_state"), "scheduler": scheduler.snapshot_state(arena.bindings), "mechanism": mechanism.snapshot_state(arena.bindings)}
	_expect(ExactJson.stringify(restored) == encoded and scheduler.get_clock() == old_clock and phases.is_empty() and _mesh_transforms(actor.get_node("HandlerRig")) == transforms, "restored lock retains exact clock/HP/history/geometry/heading with no cue phase event")
	paused = false


func _test_exact_actor_pose_and_cutaway() -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var actor: Node3D = arena.actor
	var rig: Node3D = actor.get_node("HandlerRig") as Node3D
	var chassis: Node3D = rig.get_node("FiveLegChassis") as Node3D
	var feet: Array[Vector3] = []
	for support: String in SUPPORTS:
		var foot: MeshInstance3D = chassis.get_node(support + "/GroundedFoot") as MeshInstance3D
		feet.append(foot.global_position)
	_expect(feet.size() == 5 and _distinct_points(feet) and _feet_grounded(chassis) and not _contains_collision(rig) and not rig.is_in_group("enemies"), "five separate grounded supports form a collider-free cosmetic rig")
	_expect(not rig.has_node("ThreeLegChassis") and not rig.has_node("TrackingMirrorSwivel"), "Handler builds no second Scout chassis or ray apparatus")
	rig.call("pose", "lock", 0.25, Vector3.BACK)
	var lever: MeshInstance3D = rig.get_node("FiveLegChassis/TelescopingToolLever") as MeshInstance3D
	var folded_height: float = (lever.mesh as CylinderMesh).height
	rig.call("pose", "active", 0.0, Vector3.BACK)
	var full_reach: AABB = _world_mesh_bounds(rig.get_node("FiveLegChassis/GrappleClaw"))
	_expect(full_reach.end.z >= 3.79 and full_reach.end.z <= 3.83 and absf(full_reach.get_center().x) < 0.05, "first active claw mesh reaches fixed+Z3.8 endpoint without lateral tracking")
	_expect((lever.mesh as CylinderMesh).height > folded_height + 1.0 and _cache_matches_mesh(rig, lever), "real extended cylinder height rebuilds its actual cached hull")
	paused = true
	var hero_bytes: String = ExactJson.stringify((arena.hero as CinderPlayer).snapshot_state())
	var base: Dictionary = actor.call("snapshot_state")
	var events: Array[String] = []
	actor.connect("defeated", func(id: String) -> void: events.append(id))
	for phase: String in ["idle", "warning", "lock", "active", "recovery", "defeated"]:
		var saved: Dictionary = base.duplicate(true)
		saved.phase = phase
		saved.phase_progress = 0.375
		saved.body_yaw = PI * 0.5
		saved.hp = 0.0 if phase == "defeated" else 30.0
		var encoded: String = ExactJson.stringify(saved)
		var parsed: Dictionary = ExactJson.parse(encoded)
		_expect(parsed.get("accepted", false) and bool(actor.call("restore_state", parsed.value)) and ExactJson.stringify(actor.call("snapshot_state")) == encoded, "exact paused Handler tuple restores " + phase)
		var expected_meshes: Dictionary = _mesh_transforms(rig)
		var fresh: Node3D = ActorScript.new() as Node3D
		arena.world.add_child(fresh)
		_expect(bool(fresh.call("configure", arena.hero, arena.effects, ACTOR_ID)) and bool(fresh.call("restore_state", parsed.value)), "fresh bound Handler reconstructs " + phase)
		_expect(_mesh_transforms(fresh.get_node("HandlerRig")) == expected_meshes and float(fresh.get_node("HandlerRig").call("get_body_yaw")) == saved.body_yaw, "fresh " + phase + " restore matches all real meshes and planted heading")
		fresh.free()
	_expect(events.is_empty() and ExactJson.stringify((arena.hero as CinderPlayer).snapshot_state()) == hero_bytes, "all pose/defeat restoration is silent and leaves exact shared player unchanged")
	var stable: Dictionary = actor.call("snapshot_state")
	var invalid: Dictionary = stable.duplicate(true)
	invalid.body_yaw = TAU
	_expect(not bool(actor.call("restore_state", invalid)) and actor.call("snapshot_state") == stable, "invalid heading rejects before mutating Handler snapshot or pose")
	var camera: Camera3D = _camera(arena.world)
	var other: Node3D = VisualScript.new() as Node3D
	arena.world.add_child(other)
	rig.call("restore_pose", "recovery", 0.25, Vector3.BACK, 0.0)
	other.call("restore_pose", "recovery", 0.25, Vector3.BACK, 0.0)
	var copies: Dictionary = _owned_material_ids(rig)
	_expect(not copies.is_empty() and _ids_disjoint(copies, _owned_material_ids(other)), "Handler cutaway owns isolated material copies per instance")
	var hood: MeshInstance3D = rig.get_node("FiveLegChassis/LowHandlerCase/LowFacetedHood") as MeshInstance3D
	var points: Array[Vector3] = _synthetic_silhouette(camera, hood.global_position)
	var resources: Dictionary = _resource_ids(rig)
	_expect(bool(rig.call("apply_readability", camera, points)) and not (rig.call("readability_state") as Dictionary).faded_panels.is_empty() and _all_panels_opaque(other), "actual triangle/depth cutaway fades a synthetic occluded silhouette without affecting another Handler")
	for iteration: int in range(12):
		var phase: String = ["warning", "lock", "active", "recovery"][iteration % 4]
		rig.call("pose", phase, 0.1 + 0.05 * iteration, Vector3.BACK)
		var yaw: float = float(rig.call("get_body_yaw"))
		_expect(bool(rig.call("restore_pose", phase, 0.1 + 0.05 * iteration, Vector3.BACK, yaw)) and _cache_matches_mesh(rig, lever), "changed " + phase + " arm keeps refreshed real mesh hull")
		rig.call("clear_readability")
		_expect(_all_panels_opaque(rig) and bool(rig.call("apply_readability", camera, points)) and _resource_ids(rig) == resources and _owned_material_ids(rig) == copies, "repeated pose/cutaway/clear reuses meshes/materials and restores original opacity")
	rig.call("clear_readability")
	_expect(_all_panels_opaque(rig) and not (rig.call("readability_state") as Dictionary).context_available, "explicit clear discards derived context and restores every original panel material")
	_expect(bool(actor.call("restore_state", base)) and bool(actor.call("release_damage_window", arena.gate)), "paused earlier live target can release its bound owner once")
	paused = false
	actor.call("present_phase", "recovery", 0.0, Vector3.BACK)
	_expect((arena.hero as CinderPlayer).slash(Vector3.BACK) == 0 and float(actor.get("hp")) == 30.0, "released live Handler never becomes an ungated manual recovery target")
	await _dispose(arena)


func _test_foot_dynamic_geometry() -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var foot_source: CinderLaneMechanism = MechanismScript.new()
	foot_source.position = Vector3(2, 0, 0)
	_expect(foot_source.configure("fixture-foot", Geometry.circle(foot_source.position, 1.1), foot_source.position), "foot cosmetic binds to a genuine fixed published circle source")
	arena.world.add_child(foot_source)
	_expect(foot_source.bind(arena.scheduler, {"hero": arena.hero}), "same shared scheduler owns the footprint, with no visual authority")
	var foot: Node3D = FootScript.new() as Node3D
	foot_source.add_child(foot)
	var source_before: Dictionary = foot_source.state()
	var camera: Camera3D = _camera(arena.world)
	var shaft: MeshInstance3D = foot.get_node("VisibleTripodLimb/SlidingOxidisedLeg") as MeshInstance3D
	foot.call("pose", "lock", 0.8, Vector3.BACK)
	var lifted_height: float = (shaft.mesh as CylinderMesh).height
	foot.call("pose", "active", 0.0, Vector3.BACK)
	_expect((shaft.mesh as CylinderMesh).height > lifted_height + 0.8 and _cache_matches_mesh(foot, shaft), "actual foot shaft length change refreshes derived mesh triangles")
	_expect(not _contains_collision(foot) and not foot.is_in_group("enemies") and not foot.has_method("take_damage") and not foot.is_physics_processing(), "visible foot has no collider/HP target/private timer or damage process")
	var points: Array[Vector3] = _synthetic_silhouette(camera, shaft.global_position)
	var resources: Dictionary = _resource_ids(foot)
	_expect(bool(foot.call("apply_readability", camera, points)) and not (foot.call("readability_state") as Dictionary).faded_panels.is_empty(), "real changed foot shaft contributes derived foreground cutaway")
	for phase: String in ["warning", "lock", "active", "recovery"]:
		foot.call("pose", phase, 0.35, Vector3.BACK)
		_expect(_cache_matches_mesh(foot, shaft) and bool(foot.call("restore_pose", phase, 0.35, Vector3.BACK, 0.0)), "quiet supplied " + phase + " foot pose rebuilds the real cylinder hull")
		foot.call("clear_readability")
		_expect(_all_panels_opaque(foot) and _resource_ids(foot) == resources and foot_source.state() == source_before, "foot pose/clear preserves exact stationary circle/source and allocated materials")
	foot_source.clear("fixture_exit")
	await _dispose(arena)


func _camera(world: Node3D) -> Camera3D:
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 7.2
	world.add_child(camera)
	camera.global_position = Vector3(0, 18, 13)
	camera.look_at(Vector3(0, 0.75, 0))
	return camera


func _synthetic_silhouette(camera: Camera3D, behind_part: Vector3) -> Array[Vector3]:
	# TEST ONLY camera-facing player-size quad behind the actual source part.
	# Its depth is deliberately synthetic; no actual gameplay landing is claimed.
	var center: Vector3 = behind_part - camera.global_basis.z * 2.0
	var points: Array[Vector3] = []
	for x: float in [-0.54, 0.54]:
		for y: float in [-0.72, 0.72]:
			points.append(center + camera.global_basis.x * x + camera.global_basis.y * y)
	return points


func _mesh_transforms(node: Node) -> Dictionary:
	var result: Dictionary = {}
	for mesh: MeshInstance3D in _meshes(node):
		result[String(node.get_path_to(mesh))] = mesh.global_transform
	return result


func _meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	_collect_meshes(node, result)
	return result


func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_meshes(child, result)


func _world_mesh_bounds(node: Node3D) -> AABB:
	var result: AABB = AABB()
	var first: bool = true
	for part: MeshInstance3D in _meshes(node):
		for surface: int in range(part.mesh.get_surface_count()):
			var arrays: Array = part.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				var point: Vector3 = part.global_transform * vertex
				if first:
					result = AABB(point, Vector3.ZERO)
					first = false
				else:
					result = result.expand(point)
	return result


func _cache_matches_mesh(rig: Node3D, part: MeshInstance3D) -> bool:
	var cached: Dictionary = {}
	for panel: Dictionary in rig.get("_readability_panels"):
		if panel.part == part:
			cached = panel
			break
	if cached.is_empty():
		return false
	var actual := PackedVector3Array()
	for surface: int in range(part.mesh.get_surface_count()):
		actual.append_array(part.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
	return cached.vertices == actual and not (cached.indices as PackedInt32Array).is_empty()


func _resource_ids(rig: Node3D) -> Dictionary:
	var result: Dictionary = {}
	var retained_materials: Array[int] = []
	for material: StandardMaterial3D in rig.get("_materials"):
		retained_materials.append(material.get_instance_id())
	result["$retained_materials"] = retained_materials
	result["$nodes"] = _node_count(rig)
	for part: MeshInstance3D in _meshes(rig):
		var ids: Array[int] = [part.get_instance_id(), part.mesh.get_instance_id()]
		if part.material_override != null:
			ids.append(part.material_override.get_instance_id())
		for surface: int in range(part.mesh.get_surface_count()):
			var material: Material = part.get_surface_override_material(surface)
			if material != null:
				ids.append(material.get_instance_id())
		result[String(rig.get_path_to(part))] = ids
	return result


func _owned_material_ids(rig: Node3D) -> Dictionary:
	var result: Dictionary = {}
	for panel: Dictionary in rig.get("_readability_panels"):
		for entry: Dictionary in panel.materials:
			result[entry.material.get_instance_id()] = true
	return result


func _ids_disjoint(a: Dictionary, b: Dictionary) -> bool:
	for id: int in a:
		if b.has(id):
			return false
	return true


func _all_panels_opaque(rig: Node3D) -> bool:
	for panel: Dictionary in rig.get("_readability_panels"):
		for entry: Dictionary in panel.materials:
			var material: StandardMaterial3D = entry.material
			if material.albedo_color != entry.base_color or material.transparency != entry.base_transparency:
				return false
	return true


func _node_count(node: Node) -> int:
	var count: int = 1
	for child: Node in node.get_children():
		count += _node_count(child)
	return count


func _contains_collision(node: Node) -> bool:
	if node is CollisionObject3D or node is CollisionShape3D:
		return true
	for child: Node in node.get_children():
		if _contains_collision(child):
			return true
	return false


func _feet_grounded(chassis: Node3D) -> bool:
	for name: String in SUPPORTS:
		var bound: AABB = _world_mesh_bounds(chassis.get_node(name + "/GroundedFoot") as Node3D)
		if absf(bound.position.y) > 0.000001:
			return false
	return true


func _distinct_points(points: Array[Vector3]) -> bool:
	for a: int in range(points.size()):
		for b: int in range(a + 1, points.size()):
			if points[a] == points[b]:
				return false
	return true


func _until_phase(mechanism: CinderLaneMechanism, wanted: String) -> bool:
	for tick: int in range(480):
		if mechanism.state().phase == wanted:
			return true
		await _ticks(1)
	return false


func _ticks(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _dispose(arena: Dictionary) -> void:
	paused = false
	(arena.mechanism as CinderLaneMechanism).clear("fixture_exit")
	(arena.scheduler as CinderThreatScheduler).end_encounter("fixture_exit")
	(arena.actor as Node3D).call("cleanup")
	(arena.effects as PixelEffects).clear()
	(arena.viewport as SubViewport).queue_free()
	await process_frame
	# Native audio retirement runs outside the node deletion frame. Let the
	# final .09s primary stream drain before this narrow-only process quits.
	await create_timer(0.15).timeout


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
