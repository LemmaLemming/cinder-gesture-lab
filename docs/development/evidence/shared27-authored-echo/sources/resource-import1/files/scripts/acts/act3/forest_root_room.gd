extends "res://scripts/acts/act3/root_latcher_room.gd"
## Forest presentation of the native crescent rule room.
## It keeps the original combat court and actor/consumer unchanged.

const ForestScenery = preload("res://scripts/acts/act3/living_forest_scenery.gd")
var forest_scenery: Node3D


func _build_floor() -> void:
	forest_scenery = ForestScenery.new()
	forest_scenery.name = "LivingForestScenery"
	add_child(forest_scenery)
	forest_scenery.call("build", true)
	floor_body = forest_scenery.get("floor_body") as StaticBody3D
	var collision: CollisionShape3D = floor_body.get_node("Solid") as CollisionShape3D
	_floor_region = {"collision": collision, "safe_rect": FLOOR_RECT}


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_instance_valid(hero) and is_instance_valid(forest_scenery):
		forest_scenery.call("follow_landmarks", hero.global_position)
