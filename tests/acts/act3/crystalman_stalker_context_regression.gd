extends SceneTree
## Direct regression for the unchanged flat Stalker render-binding branch.
## The parent priority test covers the nested branch through real snapshots.
const MainScene = preload("res://scenes/main.tscn")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size = Vector2i(340,736)
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path","res://scenes/acts/act3/a3_l1_stalker_room.tscn")
	root.add_child(game)
	await process_frame
	await process_frame
	game.call("open_bench")
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var camera: Camera3D = game.get("camera") as Camera3D
	var source: Node3D = level.get("stalker") as Node3D
	check(paused and source!=null and level.get_parent()==hero.get_parent(),"Original flat source/level/Hero binding is actual")
	var positive: Dictionary = source.call("current_render_framing_points_for_context",game,hero,camera)
	check(String(positive.get("error","missing")).is_empty() and not positive.get("points",[]).is_empty(),"Original native current camera/render context remains accepted")
	var before: PackedByteArray = var_to_bytes([hero.snapshot_state(),source.call("state"),camera.global_transform])
	var foreign := Camera3D.new()
	foreign.name = "ForeignNoncurrentCamera"
	hero.get_parent().add_child(foreign)
	var rejected: Dictionary = source.call("current_render_framing_points_for_context",game,hero,foreign)
	check(not String(rejected.get("error","")).is_empty() and rejected.get("points",[]).is_empty() and var_to_bytes([hero.snapshot_state(),source.call("state"),camera.global_transform])==before,"Actual noncurrent camera is rejected without native mutation")
	foreign.free()
	var old: WeakRef = weakref(level)
	level.exit_level()
	game.queue_free()
	await process_frame
	await process_frame
	check(old.get_ref()==null,"Normal old flat level cleanup remains complete")
	print("Crystalman flat Stalker render regression: %d checks/%d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
