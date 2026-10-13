extends RefCounted
## Stable authored collision names for cross-instance scheduler transport tests.

const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Equipment = preload("res://scripts/equipment.gd")


static func create(tree: SceneTree) -> Dictionary:
	var world := Node3D.new()
	world.name = "ThreatWorld"
	tree.root.add_child(world)
	var actor := CharacterBody3D.new()
	actor.name = "Hero"
	actor.collision_layer = 4
	actor.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.45
	collision.shape = capsule
	collision.position.y = 0.73
	actor.add_child(collision)
	world.add_child(actor)
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	var source_a := Node3D.new()
	source_a.name = "SourceA"
	var source_b := Node3D.new()
	source_b.name = "SourceB"
	world.add_child(source_a)
	world.add_child(source_b)
	var floor := StaticBody3D.new()
	floor.name = "Floor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	var floor_collision := CollisionShape3D.new()
	floor_collision.name = "Support"
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(20, 1, 20)
	floor_collision.shape = floor_box
	floor.add_child(floor_collision)
	world.add_child(floor)
	floor.position.y = -0.5
	var wall := StaticBody3D.new()
	wall.name = "Wall"
	wall.collision_layer = 1
	wall.collision_mask = 0
	var wall_collision := CollisionShape3D.new()
	wall_collision.name = "Solid"
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(0.2, 2, 5)
	wall_collision.shape = wall_box
	wall.add_child(wall_collision)
	world.add_child(wall)
	wall.position = Vector3(7, 1, 0)
	return {"root": world, "actor": actor, "scheduler": scheduler, "source_a": source_a, "source_b": source_b, "floor": floor, "wall": wall, "floor_region": {"collision": floor_collision, "safe_rect": Rect2(-10, -10, 20, 20)}}


static func bindings(arena: Dictionary) -> Dictionary:
	return {"world_root": arena["root"], "owners": {"scout-a": arena["source_a"], "scout-b": arena["source_b"]}, "floors": {"main-floor": arena["floor_region"]}}


static func response(arena: Dictionary) -> Dictionary:
	var stats: Dictionary = Equipment.new().resolved_stats()
	return {"actor": arena["actor"], "stats": stats, "stable": true, "world_revision": 1, "commitment_remaining_s": 0.0, "dash_cooldown_left_s": 0.0, "primary_cooldown_left_s": 0.0, "recognition_s": 0.1, "primary_commitment_s": float(stats["primary_cooldown"]) * (0.13 / 0.3), "attack_input_margin_s": 0.02, "escape_directions": [Vector3.LEFT, Vector3.RIGHT], "return_directions": [Vector3.LEFT, Vector3.RIGHT], "floor_regions": [arena["floor_region"]]}


static func threat(windup: float = 0.6, active: float = 0.4) -> Dictionary:
	var role: Dictionary = Difficulty.new().resolve_role({"raw_damage": 10.0, "windup_s": windup, "lock_s": 0.2, "active_s": active, "recovery_s": 1.2, "attack_interval_s": 1.6, "max_hp": 30.0, "move_speed": 2.6}, "standard", {"windup_s": windup, "lock_s": 0.2, "recovery_s": 1.2})
	return {"role": role, "geometry": Geometry.circle(Vector3.ZERO, 0.8), "source_stationary": true, "opening_stationary": true, "opening_position": Vector3.ZERO, "cooldown_remaining_s": 0.0}
