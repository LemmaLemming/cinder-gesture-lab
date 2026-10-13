extends "res://scripts/acts/act2/weybridge_scout_actor.gd"
## Genuine ordinary-primary HP target. Emitted clouds are independent owners;
## this actor never damages the Hero or controls cloud/lease deadlines.
const TenderVisual: Script = preload("res://scripts/acts/act2/canister_tender_visual.gd")

func _ready() -> void:
	add_to_group("enemies")
	_visual = TenderVisual.new() as Node3D
	_visual.name = "TenderRig"
	add_child(_visual)
	_render_pose(false)
	set_process(false)
	set_physics_process(false)
