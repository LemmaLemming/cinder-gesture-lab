extends SceneTree
## SOURCE ONLY until Integration freezes and runs this literal ignored path.
## Both trusted retained Route copies are compiled without only class_name,
## avoiding global-class duplication. No production source is selected.
const Exact = preload("res://scripts/campaign/exact_json.gd")
const BASE: String = "res://.cinder/collision-traversal-filter/"
var original: GDScript
var candidate: GDScript
var checks: int = 0
var failures: int = 0


class DecorativeSubclass extends Node3D:
	pass


class StaticSubclass extends StaticBody3D:
	pass


class GridSubclass extends GridMap:
	pass


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	original = _trusted_script("repulsion_route.original.gd.txt")
	candidate = _trusted_script("repulsion_route.candidate.gd.txt")
	if original == null or candidate == null:
		_finish()
		return
	paused = true
	var world := Node3D.new()
	world.name = "FilterDifferentialWorld"
	root.add_child(world)
	_box(world, "Floor")
	var original_empty: Dictionary = _pair(world, "plain native static body", "", 1)
	var wrapper := DecorativeSubclass.new()
	wrapper.name = "DecorativeWrapper"
	world.add_child(wrapper)
	var nonspatial := Node.new()
	nonspatial.name = "NonspatialWrapper"
	wrapper.add_child(nonspatial)
	_box(nonspatial, "NestedSubclass", true)
	for index: int in range(800):
		var decoration: Node3D
		match index % 3:
			0: decoration = DecorativeSubclass.new()
			1: decoration = MeshInstance3D.new()
			_: decoration = Area3D.new()
		decoration.name = "Decoration%d" % index
		wrapper.add_child(decoration)
	var decorated: Dictionary = _pair(world, "800 ignored nodes retain nested subclass collider", "", 2)
	_expect(not original_empty.is_empty() and decorated.get("signature", {}).get("colliders", []).size() == 2, "child enumeration survives both ignored spatial and nonspatial wrappers")

	var foreign := SubViewport.new()
	foreign.name = "ForeignWorldViewport"
	foreign.size = Vector2i(16, 16)
	foreign.own_world_3d = true
	root.add_child(foreign)
	var foreign_root := Node3D.new()
	foreign_root.name = "ForeignRoot"
	foreign.add_child(foreign_root)
	var moving_foreign := _box(foreign_root, "ForeignMovingBody")
	moving_foreign.constant_linear_velocity = Vector3.RIGHT
	var foreign_grid := GridSubclass.new()
	foreign_grid.name = "ForeignGrid"
	foreign_root.add_child(foreign_grid)
	var foreign_csg := CSGBox3D.new()
	foreign_csg.name = "ForeignCSG"
	foreign_csg.use_collision = true
	foreign_root.add_child(foreign_csg)
	_expect(foreign_root.get_world_3d() != world.get_world_3d(), "foreign-world refusal control uses an actual distinct World3D")
	_pair(world, "foreign relevant descendants remain ignored by same-world guard", "", 2)
	foreign.free()

	var csg := CSGBox3D.new()
	csg.name = "NativeCSG"
	world.add_child(csg)
	csg.use_collision = false
	_pair(world, "same-world CSG without collision", "", 2)
	csg.use_collision = true
	_pair(world, "same-world CSG collision still rejects", "Generated scenery collision has no supported stable signature")
	csg.free()
	var grid := GridSubclass.new()
	grid.name = "NativeGridSubclass"
	world.add_child(grid)
	_pair(world, "same-world empty GridMap subclass still rejects", "Generated scenery collision has no supported stable signature")
	grid.free()

	var external := _box(root, "OutsideAuthoredRoot")
	_pair(world, "full SceneTree still discovers same-world external body", "Every scenery blocker must be a fixed static body under world_root")
	external.free()
	var dynamic := CharacterBody3D.new()
	dynamic.name = "DynamicScenery"
	dynamic.collision_layer = 1
	world.add_child(dynamic)
	_pair(world, "same-world dynamic scenery still rejects", "Every scenery blocker must be a fixed static body under world_root")
	dynamic.collision_layer = 2
	_pair(world, "non-scenery body still respects layer filtering", "", 2)
	dynamic.free()
	var animated := AnimatableBody3D.new()
	animated.name = "AnimatedScenery"
	animated.collision_layer = 1
	world.add_child(animated)
	_pair(world, "same-world AnimatableBody still rejects", "Every scenery blocker must be a fixed static body under world_root")
	animated.free()

	var floor_body: StaticBody3D = world.get_node("Floor")
	floor_body.constant_linear_velocity = Vector3.RIGHT
	_pair(world, "actual static velocity getter remains effective", "Moving/removed static scenery is unsupported")
	floor_body.constant_linear_velocity = Vector3.ZERO
	var shape: BoxShape3D = (floor_body.get_node("Collision") as CollisionShape3D).shape
	var old_size: Vector3 = shape.size
	shape.size = Vector3(3.0, 1.0, 2.0)
	var mutated: Dictionary = _pair(world, "actual shape getter remains fresh", "", 2)
	_expect(Exact.stringify(mutated) != Exact.stringify(decorated), "genuine shape mutation cannot return a retained earlier signature")
	shape.size = old_size
	var unsupported := _box(world, "UnsupportedShape")
	(unsupported.get_node("Collision") as CollisionShape3D).shape = WorldBoundaryShape3D.new()
	_pair(world, "unsupported relevant shape still rejects", "Unsupported immutable scenery shape")
	unsupported.free()
	var removed := _box(world, "QueuedScenery")
	removed.queue_free()
	_pair(world, "queued relevant body still rejects before shape reads", "Moving/removed static scenery is unsupported")
	await process_frame
	_pair(world, "cleaned SceneTree returns the original decorated signature", "", 2)
	world.free()
	await process_frame
	_finish()


func _trusted_script(filename: String) -> GDScript:
	var text: String = FileAccess.get_file_as_string(BASE + filename)
	var declaration: String = "class_name CinderRepulsionRoute\n"
	_expect(text.begins_with(declaration), "retained Route starts with its exact one-line class declaration")
	if not text.begins_with(declaration): return null
	var script := GDScript.new()
	script.source_code = text.substr(declaration.length())
	var error: Error = script.reload()
	_expect(error == OK, "trusted retained Route compiles after only removal of global class registration")
	return script if error == OK else null


func _pair(world: Node3D, label: String, expected_error: String, collider_count: int = -1) -> Dictionary:
	var left: Dictionary = original.call("_collision_signature", world, world)
	var right: Dictionary = candidate.call("_collision_signature", world, world)
	var left_wire: String = Exact.stringify(left)
	var right_wire: String = Exact.stringify(right)
	_expect(not left_wire.is_empty() and not right_wire.is_empty() and left_wire == right_wire, label + " retains full exact original result/error")
	_expect(left.get("error", "") == expected_error and (left.has("signature") if expected_error.is_empty() else not left.has("signature")), label + " exercises its concrete original branch")
	if collider_count >= 0:
		_expect(left.get("signature", {}).get("colliders", []).size() == collider_count, label + " retains each genuine scenery collider")
	return left


func _box(parent: Node, name: String, scripted: bool = false) -> StaticBody3D:
	var body: StaticBody3D = StaticSubclass.new() if scripted else StaticBody3D.new()
	body.name = name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 1.0, 2.0)
	collision.shape = box
	body.add_child(collision)
	parent.add_child(body)
	return body


func _expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)


func _finish() -> void:
	print("Collision traversal exact differential: %d checks, %d failures; signatures only, no performance or gameplay credit" % [checks, failures])
	quit(0 if failures == 0 else 1)
