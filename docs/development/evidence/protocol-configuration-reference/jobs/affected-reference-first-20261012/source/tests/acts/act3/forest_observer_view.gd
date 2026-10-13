extends SceneTree
## Actual shared traveller / forest / nonhostile observer presentation fixture.
## This quiet custom scene has no encounters, contact exit or campaign claim.

const MainScene = preload("res://scenes/main.tscn")
const ViewPath: String = "res://scenes/acts/act3/a3_l2_scenery_view.tscn"

class PostActorBarrier:
	extends Node
	signal completed
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		completed.emit()

var _checks: int = 0
var _failures: int = 0
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _barrier: PostActorBarrier


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _expect(DisplayServer.get_name() != "headless", "quiet observer view requires an actual graphical renderer"):
		await _finish()
		return
	_game = MainScene.instantiate()
	_game.set("level_scene_path", ViewPath)
	root.add_child(_game)
	_barrier = PostActorBarrier.new()
	_game.add_child(_barrier)
	for _i: int in range(12):
		await _barrier.completed
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(_level != null and _hero != null and _level.scene_file_path == ViewPath and _hero.is_on_floor() and _hero.presentation_id == "act3_traveller", "one actual traveller stands in the new continuous quiet forest scene"):
		await _finish()
		return
	var observer: Node3D = _level.get("quiet_observer") as Node3D
	var scenery: Node3D = _level.get("scenery") as Node3D
	if not _expect(observer != null and scenery != null and String(scenery.call("runtime_error")).is_empty(), "actual observer and full forest floor/bases are live"):
		await _finish()
		return
	_expect(not observer is CollisionObject3D and not observer.is_in_group("enemies") and not observer.has_method("take_damage") and observer.get_child_count() == 1 and observer.get_child(0) is Sprite3D, "quiet original figure supplies only a native still and no combat/physical target")
	_expect((observer.get_child(0) as Sprite3D).is_visible_in_tree(), "the distant quiet projection is actually visible beside the traveller")
	await _capture("01-arrival")
	_hero.shells = 0
	var hp: float = _hero.hp
	if not _expect(_hero.request_dash(Vector3.RIGHT), "actual ordinary dash approaches the quiet figure without a new control"):
		await _finish()
		return
	for _i: int in range(120):
		if not _hero.get_committed_dash_state().active:
			break
		await _barrier.completed
	_hero.shells = 0
	_hero.slash(Vector3.LEFT)
	_expect(_hero.last_action.hits == 0 and _hero.hp == hp and not _level.is_completed(), "ordinary primary near the figure causes no hit/damage/reward/completion")
	_expect(not (observer.get_child(0) as Sprite3D).is_visible_in_tree(), "real close approach clears the projection before it can hide the traveller")
	await _capture("02-ordinary-approach")
	_game.call("open_bench")
	await process_frame
	var sun: float = float(_level.get("sun_elapsed_s"))
	var snapshot: Dictionary = _level.snapshot_state()
	for _i: int in range(4):
		await process_frame
	_expect(paused and not snapshot.is_empty() and _level.snapshot_error(snapshot).is_empty() and float(_level.get("sun_elapsed_s")) == sun, "actual manual pause freezes the owned sun/scenery envelope and validates its local state")
	await _finish()


func _capture(label: String) -> void:
	var was_paused: bool = paused
	paused = true # TEST ONLY clean actual frame without a pause overlay.
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var directory: String = ProjectSettings.globalize_path("res://.cinder/forest-observer-portraits-shared22")
	DirAccess.make_dir_recursive_absolute(directory)
	var path: String = directory + "/" + label + ".png"
	_expect(image != null and image.get_size() == Vector2i(339, 736) and image.save_png(path) == OK, "save unchanged actual339x736 " + label + " forest/observer view")
	print("OBSERVER PORTRAIT: " + path)
	paused = was_paused


func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if condition:
		print("PASS: " + message)
	else:
		_failures += 1
		push_error("FAIL: " + message)
	return condition


func _finish() -> void:
	paused = false
	var game_ref: WeakRef = weakref(_game) if is_instance_valid(_game) else null
	var hero_ref: WeakRef = weakref(_hero) if is_instance_valid(_hero) else null
	if is_instance_valid(_game):
		if is_instance_valid(_level):
			_level.exit_level()
		_game.queue_free()
	for _i: int in range(5):
		await process_frame
	if game_ref != null:
		_expect(game_ref.get_ref() == null and (hero_ref == null or hero_ref.get_ref() == null), "quiet view releases its actual world and shared actor before exit")
	print("Quiet forest observer view: %d checks; %d failures; no full-level/campaign acceptance" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
