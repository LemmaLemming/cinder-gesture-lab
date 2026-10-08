class_name Act2SalvageHandlerActor
extends "res://scripts/acts/act2/weybridge_scout_actor.gd"
## Compact five-legged A2-E3 presentation over the existing anchored target.
## Inherit HP30, accepted-hit/reload contract, immutable root, recovery gate and
## paused actor transport. The level and shared lane mechanism own all clocks.

const HandlerVisualScript: Script = preload("res://scripts/acts/act2/salvage_handler_visual.gd")


func _ready() -> void:
	# Do not call the Scout's _ready: it would build a second three-legged rig.
	add_to_group("enemies")
	_visual = HandlerVisualScript.new() as Node3D
	_visual.name = "HandlerRig"
	add_child(_visual)
	_render_pose(false)
	set_process(false)
	set_physics_process(false)
