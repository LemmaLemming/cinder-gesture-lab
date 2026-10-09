extends RefCounted

const Player = preload("res://scripts/player.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Mechanism = preload("res://scripts/combat/lane_mechanism.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")


static func create(tree: SceneTree, raw_role: Dictionary = Mechanism.DEFAULT_RAW_ROLE) -> Dictionary:
	var world := Node3D.new()
	world.name = "MechanismWorld"
	tree.root.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "Floor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	var support := CollisionShape3D.new()
	support.name = "Support"
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	support.shape = box
	floor.add_child(support)
	world.add_child(floor)
	floor.position.y = -0.5
	var hero: CinderPlayer = Player.new()
	hero.name = "Hero"
	world.add_child(hero)
	hero.shells = 0
	var scheduler: CinderThreatScheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	var mechanism: CinderLaneMechanism = Mechanism.new()
	mechanism.name = "LoadingArm"
	mechanism.position = Vector3(-1, 0, 0)
	mechanism.configure("loading-arm", Geometry.lane(Vector3(-1, 0, 0), Vector3(1, 0, 0), 0.30), Vector3.ZERO, raw_role)
	world.add_child(mechanism)
	mechanism.bind(scheduler, {"hero": hero})
	var region := {"collision": support, "safe_rect": Rect2(-10, -10, 20, 20)}
	return {"root": world, "hero": hero, "scheduler": scheduler, "mechanism": mechanism, "region": region}


static func context(arena: Dictionary, encounter_id: String) -> Dictionary:
	return {"encounter_id": encounter_id, "world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.BACK, Vector3.FORWARD], "return_directions": [Vector3.BACK, Vector3.FORWARD], "floor_regions": [arena.region]}


static func bindings(arena: Dictionary) -> Dictionary:
	return {"world_root": arena.root, "owners": {"loading-arm": arena.mechanism}, "floors": {"main-floor": arena.region}}
